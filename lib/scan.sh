#!/usr/bin/env bash

NSURGN_SCAN_DIR=''
NSURGN_NAMESPACE_TYPES='pid mnt net user uts ipc cgroup time'

nsurgn_scan_create_workspace() {
  NSURGN_SCAN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nsurgn.XXXXXX")" || return "$NSURGN_EXIT_GENERAL_ERROR"
  trap nsurgn_scan_cleanup EXIT HUP INT TERM

  : >"${NSURGN_SCAN_DIR}/visible_pids.tsv"
  : >"${NSURGN_SCAN_DIR}/host_profile.tsv"
  : >"${NSURGN_SCAN_DIR}/process.tsv"
  : >"${NSURGN_SCAN_DIR}/process_cgroup.tsv"
  : >"${NSURGN_SCAN_DIR}/process_cgroup_summary.tsv"
  : >"${NSURGN_SCAN_DIR}/process_mountinfo.tsv"
  : >"${NSURGN_SCAN_DIR}/process_mount_summary.tsv"
  : >"${NSURGN_SCAN_DIR}/artifact.tsv"
  : >"${NSURGN_SCAN_DIR}/visible_artifact.tsv"
  : >"${NSURGN_SCAN_DIR}/artifact_process.tsv"
  : >"${NSURGN_SCAN_DIR}/classification_reason.tsv"
  : >"${NSURGN_SCAN_DIR}/scan_limitation.tsv"
}

nsurgn_scan_cleanup() {
  if [ -n "${NSURGN_SCAN_DIR:-}" ] && [ -d "$NSURGN_SCAN_DIR" ]; then
    rm -rf -- "$NSURGN_SCAN_DIR"
  fi
}

nsurgn_scan_require_proc() {
  if [ ! -d /proc ] || [ ! -r /proc ]; then
    nsurgn_error 'this command requires Linux procfs'
    return "$NSURGN_EXIT_UNSUPPORTED_PLATFORM"
  fi

  if [ ! -d /proc/self/ns ]; then
    nsurgn_error 'this command requires readable namespace links under /proc/self/ns'
    return "$NSURGN_EXIT_UNSUPPORTED_PLATFORM"
  fi
}

nsurgn_scan_enumerate_pids() {
  local proc_root="${1:-/proc}"
  local proc_entry pid

  for proc_entry in "${proc_root}"/*; do
    [ -e "$proc_entry" ] || continue
    [ -d "$proc_entry" ] || continue

    pid="${proc_entry##*/}"
    nsurgn_is_uint "$pid" || continue
    printf '%s\n' "$pid"
  done | sort -n
}

nsurgn_scan_parse_namespace_id() {
  local namespace_type="$1"
  local namespace_value="$2"
  local namespace_prefix="${namespace_type}:["
  local namespace_id

  case "$namespace_value" in
    "$namespace_prefix"*']')
      namespace_id="${namespace_value#"$namespace_prefix"}"
      namespace_id="${namespace_id%]}"
      nsurgn_is_uint "$namespace_id" || return 1
      printf '%s\n' "$namespace_id"
      ;;
    *) return 1 ;;
  esac
}

nsurgn_scan_namespace_profile_fields() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local process_dir="${proc_root}/${host_pid}"
  local namespace_type namespace_path namespace_value namespace_id
  local namespace_status='ok'
  local profile_fields=()

  if [ ! -d "$process_dir" ]; then
    nsurgn_join_by_tab vanished - - - - - - - -
    return 0
  fi

  for namespace_type in $NSURGN_NAMESPACE_TYPES; do
    namespace_path="${process_dir}/ns/${namespace_type}"

    if [ ! -e "$namespace_path" ] && [ ! -L "$namespace_path" ]; then
      profile_fields+=('-')
      continue
    fi

    if namespace_value="$(readlink "$namespace_path" 2>/dev/null)"; then
      if namespace_id="$(nsurgn_scan_parse_namespace_id "$namespace_type" "$namespace_value")"; then
        profile_fields+=("$namespace_id")
      else
        profile_fields+=('-')
      fi
      continue
    fi

    profile_fields+=('-')
    if [ ! -d "$process_dir" ]; then
      namespace_status='vanished'
    elif [ "$namespace_status" != 'vanished' ]; then
      namespace_status='permission-denied'
    fi
  done

  nsurgn_join_by_tab "$namespace_status" "${profile_fields[@]}"
}

nsurgn_scan_write_limitation() {
  local severity="$1"
  local code="$2"
  local host_pid="$3"
  local path="$4"
  local source="$5"
  local read_status="$6"
  local message="$7"

  nsurgn_join_by_tab \
    "$severity" \
    "$code" \
    "$host_pid" \
    "$path" \
    "$source" \
    "$read_status" \
    "$message" >>"${NSURGN_SCAN_DIR}/scan_limitation.tsv"
}

nsurgn_scan_write_process_source_limitation() {
  local host_pid="$1"
  local source="$2"
  local read_status="$3"
  local path="$4"
  local code message

  [ -n "${NSURGN_SCAN_DIR:-}" ] || return 0
  [ -f "${NSURGN_SCAN_DIR}/scan_limitation.tsv" ] || return 0

  case "$read_status" in
    permission-denied)
      code='permission_denied'
      message="cannot read process ${source}"
      ;;
    vanished)
      code='process_vanished'
      message="process vanished while reading ${source}"
      ;;
    *) return 0 ;;
  esac

  nsurgn_scan_write_limitation warning "$code" "$host_pid" "$path" "$source" "$read_status" "$message"
}

nsurgn_scan_read_status_fields() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local process_dir="${proc_root}/${host_pid}"
  local status_path="${process_dir}/status"
  local status_line status_key status_value status_fields
  local status_values=()
  local ppid='-' uid='-' state='-' ns_pid='-'

  if [ ! -d "$process_dir" ]; then
    nsurgn_join_by_tab vanished - - - -
    return 0
  fi

  if [ ! -r "$status_path" ]; then
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished - - - -
    else
      nsurgn_join_by_tab permission-denied - - - -
    fi
    return 0
  fi

  if [ ! -f "$status_path" ]; then
    nsurgn_join_by_tab permission-denied - - - -
    return 0
  fi

  while IFS= read -r status_line; do
    status_key="${status_line%%:*}"
    status_value="${status_line#*:}"

    case "$status_key" in
      PPid)
        read -r -a status_values <<<"$status_value"
        nsurgn_is_uint "${status_values[0]:-}" && ppid="${status_values[0]}"
        ;;
      Uid)
        read -r -a status_values <<<"$status_value"
        nsurgn_is_uint "${status_values[0]:-}" && uid="${status_values[0]}"
        ;;
      State)
        read -r -a status_values <<<"$status_value"
        [ -n "${status_values[0]:-}" ] && state="${status_values[0]}"
        ;;
      NSpid)
        status_fields=-
        for status_value in $status_value; do
          nsurgn_is_uint "$status_value" && status_fields="$status_value"
        done
        [ "$status_fields" != '-' ] && ns_pid="$status_fields"
        ;;
    esac
  done <"$status_path" || {
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished - - - -
    else
      nsurgn_join_by_tab permission-denied - - - -
    fi
    return 0
  }

  nsurgn_join_by_tab ok "$ppid" "$uid" "$state" "$ns_pid"
}

nsurgn_scan_read_stat_fields() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local process_dir="${proc_root}/${host_pid}"
  local stat_path="${process_dir}/stat"
  local stat_line stat_rest start_time='-'
  local stat_values=()

  if [ ! -d "$process_dir" ]; then
    nsurgn_join_by_tab vanished -
    return 0
  fi

  if [ ! -r "$stat_path" ]; then
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished -
    else
      nsurgn_join_by_tab permission-denied -
    fi
    return 0
  fi

  if [ ! -f "$stat_path" ]; then
    nsurgn_join_by_tab permission-denied -
    return 0
  fi

  if ! IFS= read -r stat_line <"$stat_path"; then
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished -
    else
      nsurgn_join_by_tab permission-denied -
    fi
    return 0
  fi

  case "$stat_line" in
    *') '*)
      stat_rest="${stat_line##*) }"
      read -r -a stat_values <<<"$stat_rest"
      nsurgn_is_uint "${stat_values[19]:-}" && start_time="${stat_values[19]}"
      ;;
  esac

  nsurgn_join_by_tab ok "$start_time"
}

nsurgn_scan_normalize_cgroup_controllers() {
  local controllers="$1"
  local controller
  local controllers_array=()

  IFS=',' read -r -a controllers_array <<<"$controllers"
  for controller in "${controllers_array[@]}"; do
    printf '%s\n' "$controller"
  done | LC_ALL=C sort | paste -sd, -
}

nsurgn_scan_parse_cgroup_line_fields() {
  local line="$1"
  local hierarchy_id controllers path version normalized_controllers

  case "$line" in
    *:*:*) ;;
    *) return 1 ;;
  esac

  hierarchy_id="${line%%:*}"
  line="${line#*:}"
  controllers="${line%%:*}"
  path="${line#*:}"
  [ -n "$path" ] || path='/'

  if [ "$hierarchy_id" = '0' ] && [ -z "$controllers" ]; then
    version='v2'
    normalized_controllers='-'
  else
    version='v1'
    normalized_controllers="$(nsurgn_scan_normalize_cgroup_controllers "$controllers")"
  fi

  printf '%s\034%s\034%s\034%s\034%s\n' "$version" "$hierarchy_id" "$controllers" "$normalized_controllers" "$path"
}

nsurgn_scan_cgroup_component_has_container_id() {
  local component="$1"

  [[ "$component" =~ (^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$) ]]
}

nsurgn_scan_cgroup_hint_for_path() {
  local path="$1"
  local component
  local path_components=()

  IFS='/' read -r -a path_components <<<"$path"
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *kubepods*) printf '%s\n' kubepods; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *docker*) printf '%s\n' docker; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *crio*|*cri-o*) printf '%s\n' crio; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *libpod*) printf '%s\n' libpod; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *containerd*) printf '%s\n' containerd; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *lxc*) printf '%s\n' lxc; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *machine.slice*) printf '%s\n' machine.slice; return 0 ;;
    esac
  done
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    if nsurgn_scan_cgroup_component_has_container_id "$component"; then
      printf '%s\n' container-id
      return 0
    fi
  done

  printf '%s\n' none
}

nsurgn_scan_runtime_hint_for_cgroup_hint() {
  local cgroup_hint="$1"

  case "$cgroup_hint" in
    kubepods) printf '%s\n' kubernetes ;;
    docker) printf '%s\n' docker ;;
    crio) printf '%s\n' crio ;;
    libpod) printf '%s\n' podman ;;
    containerd) printf '%s\n' containerd ;;
    lxc) printf '%s\n' lxc ;;
    machine.slice) printf '%s\n' systemd ;;
    container-id) printf '%s\n' container-id ;;
    none) printf '%s\n' none ;;
    *) printf '%s\n' - ;;
  esac
}

nsurgn_scan_cgroup_reason_score_delta() {
  local reason_code="$1"

  case "$reason_code" in
    cgroup_kubepods|cgroup_containerd|cgroup_docker|cgroup_crio|cgroup_libpod) printf '%s\n' 4 ;;
    cgroup_lxc) printf '%s\n' 3 ;;
    cgroup_machine_slice|cgroup_container_id) printf '%s\n' 2 ;;
    *) return 1 ;;
  esac
}

nsurgn_scan_cgroup_reason_candidates_for_path() {
  local host_pid="$1"
  local path="$2"
  local component reason_code score_delta
  local found_kubepods=0 found_containerd=0 found_docker=0 found_crio=0
  local found_libpod=0 found_lxc=0 found_machine_slice=0 found_container_id=0
  local path_components=()

  IFS='/' read -r -a path_components <<<"$path"
  for component in "${path_components[@]}"; do
    [ -n "$component" ] || continue
    case "$component" in
      *kubepods*) found_kubepods=1 ;;
    esac
    case "$component" in
      *containerd*) found_containerd=1 ;;
    esac
    case "$component" in
      *docker*) found_docker=1 ;;
    esac
    case "$component" in
      *crio*|*cri-o*) found_crio=1 ;;
    esac
    case "$component" in
      *libpod*) found_libpod=1 ;;
    esac
    case "$component" in
      *lxc*) found_lxc=1 ;;
    esac
    case "$component" in
      *machine.slice*) found_machine_slice=1 ;;
    esac
    if nsurgn_scan_cgroup_component_has_container_id "$component"; then
      found_container_id=1
    fi
  done

  for reason_code in \
    cgroup_kubepods \
    cgroup_containerd \
    cgroup_docker \
    cgroup_crio \
    cgroup_libpod \
    cgroup_lxc \
    cgroup_machine_slice \
    cgroup_container_id; do
    case "$reason_code" in
      cgroup_kubepods) [ "$found_kubepods" -eq 1 ] || continue ;;
      cgroup_containerd) [ "$found_containerd" -eq 1 ] || continue ;;
      cgroup_docker) [ "$found_docker" -eq 1 ] || continue ;;
      cgroup_crio) [ "$found_crio" -eq 1 ] || continue ;;
      cgroup_libpod) [ "$found_libpod" -eq 1 ] || continue ;;
      cgroup_lxc) [ "$found_lxc" -eq 1 ] || continue ;;
      cgroup_machine_slice) [ "$found_machine_slice" -eq 1 ] || continue ;;
      cgroup_container_id) [ "$found_container_id" -eq 1 ] || continue ;;
    esac
    score_delta="$(nsurgn_scan_cgroup_reason_score_delta "$reason_code")" || return "$?"
    nsurgn_join_by_tab "$reason_code" "$score_delta" "pid=${host_pid},path=${path}"
  done
}

nsurgn_scan_cgroup_hint_rank() {
  local cgroup_hint="$1"

  case "$cgroup_hint" in
    kubepods) printf '%s\n' 1 ;;
    docker) printf '%s\n' 2 ;;
    crio) printf '%s\n' 3 ;;
    libpod) printf '%s\n' 4 ;;
    containerd) printf '%s\n' 5 ;;
    lxc) printf '%s\n' 6 ;;
    machine.slice) printf '%s\n' 7 ;;
    container-id) printf '%s\n' 8 ;;
    none) printf '%s\n' 99 ;;
    *) printf '%s\n' 100 ;;
  esac
}

nsurgn_scan_update_cgroup_hint_aggregate() {
  local aggregate_ref="$1"
  local candidate="${2:--}"
  local current_rank candidate_rank
  local -n aggregate_value="$aggregate_ref"

  case "$candidate" in
    kubepods|docker|crio|libpod|containerd|lxc|machine.slice|container-id|none) ;;
    *) candidate='-' ;;
  esac

  [ -n "${aggregate_value:-}" ] || aggregate_value='-'
  [ "$candidate" != '-' ] || return 0

  if [ "$aggregate_value" = '-' ]; then
    aggregate_value="$candidate"
    return 0
  fi

  [ "$candidate" != 'none' ] || return 0
  if [ "$aggregate_value" = 'none' ]; then
    aggregate_value="$candidate"
    return 0
  fi

  current_rank="$(nsurgn_scan_cgroup_hint_rank "$aggregate_value")"
  candidate_rank="$(nsurgn_scan_cgroup_hint_rank "$candidate")"
  if [ "$candidate_rank" -lt "$current_rank" ]; then
    aggregate_value="$candidate"
  fi
}

nsurgn_scan_read_cgroup_fields() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local process_dir="${proc_root}/${host_pid}"
  local cgroup_path="${process_dir}/cgroup"
  local line parsed_fields status='ok'
  local version hierarchy_id controllers normalized_controllers path
  local line_index=0 path_count=0 found_v2=0 group_key='cgroup:unknown'
  local cgroup_hint='none' runtime_hint='none' path_hint
  local current_hint_rank path_hint_rank
  local v2_path=''
  local v1_pairs=()

  if [ ! -d "$process_dir" ]; then
    nsurgn_join_by_tab vanished cgroup:unknown - - 0
    return 0
  fi

  if [ ! -r "$cgroup_path" ]; then
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished cgroup:unknown - - 0
    else
      nsurgn_join_by_tab permission-denied cgroup:unknown - - 0
    fi
    return 0
  fi

  if [ ! -f "$cgroup_path" ]; then
    nsurgn_join_by_tab permission-denied cgroup:unknown - - 0
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line_index=$((line_index + 1))
    [ -n "$line" ] || continue
    parsed_fields="$(nsurgn_scan_parse_cgroup_line_fields "$line")" || continue
    IFS=$'\034' read -r version hierarchy_id controllers normalized_controllers path <<<"$parsed_fields"
    path_count=$((path_count + 1))

    path_hint="$(nsurgn_scan_cgroup_hint_for_path "$path")"
    current_hint_rank="$(nsurgn_scan_cgroup_hint_rank "$cgroup_hint")"
    path_hint_rank="$(nsurgn_scan_cgroup_hint_rank "$path_hint")"
    if [ "$path_hint_rank" -lt "$current_hint_rank" ]; then
      cgroup_hint="$path_hint"
      runtime_hint="$(nsurgn_scan_runtime_hint_for_cgroup_hint "$cgroup_hint")"
    fi

    if [ "$version" = 'v2' ]; then
      if [ "$found_v2" -eq 0 ]; then
        found_v2=1
        v2_path="$path"
        nsurgn_scan_write_process_cgroup_row "$host_pid" "$line_index" "$version" "$hierarchy_id" "$controllers" "$normalized_controllers" "$path" true
      else
        nsurgn_scan_write_process_cgroup_row "$host_pid" "$line_index" "$version" "$hierarchy_id" "$controllers" "$normalized_controllers" "$path" false
      fi
    else
      v1_pairs+=("${normalized_controllers}=${path}")
      nsurgn_scan_write_process_cgroup_row "$host_pid" "$line_index" "$version" "$hierarchy_id" "$controllers" "$normalized_controllers" "$path" pending
    fi
  done <"$cgroup_path" || status='permission-denied'

  if [ "$status" = 'permission-denied' ]; then
    if [ ! -d "$process_dir" ]; then
      nsurgn_join_by_tab vanished cgroup:unknown - - 0
    else
      nsurgn_join_by_tab permission-denied cgroup:unknown - - 0
    fi
    return 0
  fi

  if [ "$found_v2" -eq 1 ]; then
    group_key="cgroup:v2:${v2_path}"
  elif [ "${#v1_pairs[@]}" -gt 0 ]; then
    group_key="cgroup:v1:$(printf '%s\n' "${v1_pairs[@]}" | LC_ALL=C sort | paste -sd';' -)"
  fi

  nsurgn_scan_finalize_process_cgroup_contributors "$host_pid" "$group_key"
  nsurgn_join_by_tab ok "$group_key" "$cgroup_hint" "$runtime_hint" "$path_count"
}

nsurgn_scan_write_process_cgroup_row() {
  local host_pid="$1"
  local line_index="$2"
  local cgroup_version="$3"
  local hierarchy_id="$4"
  local controllers="$5"
  local normalized_controllers="$6"
  local path="$7"
  local contributes_to_group_key="$8"

  [ -n "${NSURGN_SCAN_DIR:-}" ] || return 0
  [ -f "${NSURGN_SCAN_DIR}/process_cgroup.tsv" ] || return 0

  nsurgn_join_by_tab \
    "$host_pid" \
    "$line_index" \
    "$cgroup_version" \
    "$hierarchy_id" \
    "$controllers" \
    "$normalized_controllers" \
    "$path" \
    "$contributes_to_group_key" >>"${NSURGN_SCAN_DIR}/process_cgroup.tsv"
}

nsurgn_scan_finalize_process_cgroup_contributors() {
  local host_pid="$1"
  local group_key="$2"
  local cgroup_file
  local tmp_file

  [ -n "${NSURGN_SCAN_DIR:-}" ] || return 0
  cgroup_file="${NSURGN_SCAN_DIR}/process_cgroup.tsv"
  [ -f "$cgroup_file" ] || return 0

  tmp_file="${cgroup_file}.tmp"
  awk -F '\t' -v OFS='\t' -v host_pid="$host_pid" -v group_key="$group_key" '
    $1 == host_pid && $8 == "pending" {
      $8 = (index(group_key, "cgroup:v1:") == 1) ? "true" : "false"
    }
    { print }
  ' "$cgroup_file" >"$tmp_file" && mv -- "$tmp_file" "$cgroup_file"
}

nsurgn_scan_host_profile_has_required_namespaces() {
  local pid_ns="$1"
  local mnt_ns="$2"
  local net_ns="$3"
  local user_ns="$4"

  [ "$pid_ns" != '-' ] &&
    [ "$mnt_ns" != '-' ] &&
    [ "$net_ns" != '-' ] &&
    [ "$user_ns" != '-' ]
}

nsurgn_scan_read_host_profile() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local namespace_fields namespace_read_status
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns
  local host_ns_dir="${proc_root}/${host_pid}/ns"

  namespace_fields="$(nsurgn_scan_namespace_profile_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r namespace_read_status pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns <<<"$namespace_fields"

  nsurgn_join_by_tab \
    "$host_pid" \
    "$pid_ns" \
    "$mnt_ns" \
    "$net_ns" \
    "$user_ns" \
    "$uts_ns" \
    "$ipc_ns" \
    "$cgroup_ns" \
    "$time_ns" \
    "$namespace_read_status" >"${NSURGN_SCAN_DIR}/host_profile.tsv"

  case "$namespace_read_status" in
    ok) ;;
    permission-denied)
      nsurgn_scan_write_limitation error permission_denied "$host_pid" "$host_ns_dir" namespace permission-denied 'cannot read host namespace profile'
      nsurgn_error "cannot read host namespace profile for PID ${host_pid}: permission denied"
      return "$NSURGN_EXIT_PERMISSION_DENIED"
      ;;
    vanished)
      nsurgn_scan_write_limitation error process_vanished "$host_pid" "$host_ns_dir" namespace vanished 'host profile process vanished'
      nsurgn_error "host profile PID ${host_pid} vanished during scan"
      return "$NSURGN_EXIT_PROCESS_CHANGED"
      ;;
  esac

  if ! nsurgn_scan_host_profile_has_required_namespaces "$pid_ns" "$mnt_ns" "$net_ns" "$user_ns"; then
    nsurgn_scan_write_limitation error missing_namespace "$host_pid" "$host_ns_dir" namespace - 'host namespace profile is missing required namespace links'
    nsurgn_error "host namespace profile for PID ${host_pid} is missing required namespace links"
    return "$NSURGN_EXIT_UNSUPPORTED_PLATFORM"
  fi
}

nsurgn_scan_write_process_namespace_row() {
  local proc_root="${1:-/proc}"
  local host_pid="$2"
  local namespace_fields namespace_read_status
  local status_fields status_read_status ppid uid state ns_pid
  local stat_fields stat_read_status start_time
  local cgroup_fields cgroup_read_status cgroup_group_key cgroup_hint runtime_hint path_count
  local read_status='ok'
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns

  namespace_fields="$(nsurgn_scan_namespace_profile_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r namespace_read_status pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns <<<"$namespace_fields"
  status_fields="$(nsurgn_scan_read_status_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r status_read_status ppid uid state ns_pid <<<"$status_fields"
  stat_fields="$(nsurgn_scan_read_stat_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r stat_read_status start_time <<<"$stat_fields"
  cgroup_fields="$(nsurgn_scan_read_cgroup_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r cgroup_read_status cgroup_group_key cgroup_hint runtime_hint path_count <<<"$cgroup_fields"

  nsurgn_scan_write_process_source_limitation "$host_pid" namespace "$namespace_read_status" "${proc_root}/${host_pid}/ns"
  nsurgn_scan_write_process_source_limitation "$host_pid" status "$status_read_status" "${proc_root}/${host_pid}/status"
  nsurgn_scan_write_process_source_limitation "$host_pid" stat "$stat_read_status" "${proc_root}/${host_pid}/stat"
  nsurgn_scan_write_process_source_limitation "$host_pid" cgroup "$cgroup_read_status" "${proc_root}/${host_pid}/cgroup"

  if [ "$namespace_read_status" = 'vanished' ] ||
    [ "$status_read_status" = 'vanished' ] ||
    [ "$stat_read_status" = 'vanished' ] ||
    [ "$cgroup_read_status" = 'vanished' ]; then
    read_status='vanished'
  elif [ "$namespace_read_status" = 'permission-denied' ] ||
    [ "$status_read_status" = 'permission-denied' ] ||
    [ "$stat_read_status" = 'permission-denied' ] ||
    [ "$cgroup_read_status" = 'permission-denied' ]; then
    read_status='permission-denied'
  fi

  if [ -n "${NSURGN_SCAN_DIR:-}" ] && [ -f "${NSURGN_SCAN_DIR}/process_cgroup_summary.tsv" ]; then
    nsurgn_join_by_tab \
      "$host_pid" \
      "$cgroup_read_status" \
      "$cgroup_group_key" \
      "$cgroup_hint" \
      "$runtime_hint" \
      "$path_count" >>"${NSURGN_SCAN_DIR}/process_cgroup_summary.tsv"
  fi

  nsurgn_join_by_tab \
    "$host_pid" \
    "$ppid" \
    "$uid" \
    - \
    "$state" \
    "$start_time" \
    "$ns_pid" \
    "$pid_ns" \
    "$mnt_ns" \
    "$net_ns" \
    "$user_ns" \
    "$uts_ns" \
    "$ipc_ns" \
    "$cgroup_ns" \
    "$time_ns" \
    "$cgroup_hint" \
    "$runtime_hint" \
    - \
    - \
    - \
    - \
    - \
    "$read_status" \
    "$namespace_read_status" \
    "$status_read_status" \
    "$stat_read_status" \
    - \
    - \
    "$cgroup_read_status" \
    - \
    -
}

nsurgn_scan_read_process_namespaces() {
  local proc_root="${1:-/proc}"
  local host_pid

  while IFS= read -r host_pid; do
    [ -n "$host_pid" ] || continue
    nsurgn_scan_write_process_namespace_row "$proc_root" "$host_pid"
  done <"${NSURGN_SCAN_DIR}/visible_pids.tsv" >"${NSURGN_SCAN_DIR}/process.tsv"
}

nsurgn_scan_group_namespace_types() {
  local group_mode="$1"

  case "$group_mode" in
    profile) printf '%s\n' 'pid mnt net user' ;;
    strict) printf '%s\n' "$NSURGN_NAMESPACE_TYPES" ;;
    pid|mnt|net) printf '%s\n' "$group_mode" ;;
    cgroup) return 1 ;;
    *) return 1 ;;
  esac
}

nsurgn_scan_namespace_group_component() {
  local namespace_type="$1"
  local host_pid="$2"
  local namespace_id="$3"

  if [ "$namespace_id" = '-' ]; then
    printf '%s=unknown:%s\n' "$namespace_type" "$host_pid"
  else
    printf '%s=%s\n' "$namespace_type" "$namespace_id"
  fi
}

nsurgn_scan_process_namespace_group_key() {
  local group_mode="$1"
  local process_row="$2"
  local host_pid
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns
  local namespace_type namespace_id component
  local first=1
  local _

  IFS=$'\t' read -r \
    host_pid \
    _ \
    _ \
    _ \
    _ \
    _ \
    _ \
    pid_ns \
    mnt_ns \
    net_ns \
    user_ns \
    uts_ns \
    ipc_ns \
    cgroup_ns \
    time_ns \
    _ <<<"$process_row"

  [ -n "${host_pid:-}" ] || return 1
  nsurgn_is_uint "$host_pid" || return 1

  for namespace_type in $(nsurgn_scan_group_namespace_types "$group_mode"); do
    case "$namespace_type" in
      pid) namespace_id="$pid_ns" ;;
      mnt) namespace_id="$mnt_ns" ;;
      net) namespace_id="$net_ns" ;;
      user) namespace_id="$user_ns" ;;
      uts) namespace_id="$uts_ns" ;;
      ipc) namespace_id="$ipc_ns" ;;
      cgroup) namespace_id="$cgroup_ns" ;;
      time) namespace_id="$time_ns" ;;
      *) return 1 ;;
    esac

    component="$(nsurgn_scan_namespace_group_component "$namespace_type" "$host_pid" "$namespace_id")" || return "$?"
    if [ "$first" -eq 0 ]; then
      printf '+'
    fi
    printf '%s' "$component"
    first=0
  done
  printf '\n'
}

nsurgn_scan_update_namespace_aggregate() {
  local variable_name="$1"
  local process_value="$2"
  local -n target_value="$variable_name"
  local current_value="${target_value-}"
  local next_value

  [ "$process_value" != '-' ] || return 0

  case "$current_value" in
    ''|'-') next_value="$process_value" ;;
    "$process_value") next_value="$current_value" ;;
    mixed) next_value='mixed' ;;
    *) next_value='mixed' ;;
  esac

  target_value="$next_value"
}

nsurgn_scan_host_pid_namespace_from_profile() {
  local host_profile_file="${1:-${NSURGN_SCAN_DIR}/host_profile.tsv}"
  local _ host_pid_ns

  if [ -f "$host_profile_file" ]; then
    IFS=$'\t' read -r _ host_pid_ns _ <"$host_profile_file" || host_pid_ns='-'
  else
    host_pid_ns='-'
  fi

  [ -n "${host_pid_ns:-}" ] || host_pid_ns='-'
  printf '%s\n' "$host_pid_ns"
}

nsurgn_scan_namespace_diff_score_delta() {
  local namespace_type="$1"

  case "$namespace_type" in
    pid|mnt) printf '3\n' ;;
    net|user) printf '2\n' ;;
    uts|ipc|cgroup|time) printf '1\n' ;;
    *) return 1 ;;
  esac
}

nsurgn_scan_namespace_is_major() {
  local namespace_type="$1"

  case "$namespace_type" in
    pid|mnt|net|user) return 0 ;;
    *) return 1 ;;
  esac
}

nsurgn_scan_add_namespace_diff_score() {
  local artifact_id="$1"
  local namespace_type="$2"
  local artifact_namespace_id="$3"
  local host_namespace_id="$4"
  local reason_file="$5"
  local score_variable="$6"
  local major_diff_variable="$7"
  local score_delta

  case "$artifact_namespace_id" in
    '-'|mixed) return 0 ;;
  esac
  [ "$host_namespace_id" != '-' ] || return 0
  [ "$artifact_namespace_id" != "$host_namespace_id" ] || return 0

  score_delta="$(nsurgn_scan_namespace_diff_score_delta "$namespace_type")" || return "$?"
  printf -v "$score_variable" '%s' "$((${!score_variable} + score_delta))"
  if nsurgn_scan_namespace_is_major "$namespace_type"; then
    printf -v "$major_diff_variable" '%s' 1
  fi

  nsurgn_join_by_tab \
    "$artifact_id" \
    "${namespace_type}_ns_differs" \
    "$score_delta" \
    "host=${host_namespace_id},artifact=${artifact_namespace_id}" >>"$reason_file"
}

nsurgn_scan_write_visible_artifacts() {
  local include_host="${1:-${NSURGN_INCLUDE_HOST:-0}}"
  local artifact_file="${2:-${NSURGN_SCAN_DIR}/artifact.tsv}"
  local visible_artifact_file="${3:-${NSURGN_SCAN_DIR}/visible_artifact.tsv}"
  local tmp_file tab

  tmp_file="${visible_artifact_file}.tmp"
  tab=$'\t'
  : >"$visible_artifact_file"

  [ -f "$artifact_file" ] || return 0

  awk -F '\t' -v OFS='\t' -v include_host="$include_host" '
    function class_rank(classification) {
      if (classification == "anomalous") return 1
      if (classification == "container-like") return 2
      if (classification == "namespace-managed") return 3
      if (classification == "isolated") return 4
      if (classification == "host") return 5
      return 9
    }
    function namespace_sort_value(value) {
      if (value == "-") return "1:"
      return "0:" value
    }
    NF == 19 {
      if (!include_host && $11 == "host") next

      score = $12
      if (score !~ /^[0-9]+$/) score = 0
      leader_missing = 1
      leader_sort = 0
      if ($13 ~ /^[0-9]+$/) {
        leader_missing = 0
        leader_sort = $13
      }

      print -score,
        class_rank($11),
        leader_missing,
        sprintf("%020d", leader_sort),
        $2,
        namespace_sort_value($3),
        namespace_sort_value($4),
        namespace_sort_value($5),
        namespace_sort_value($6),
        namespace_sort_value($7),
        namespace_sort_value($8),
        namespace_sort_value($9),
        namespace_sort_value($10),
        $0
    }
  ' "$artifact_file" |
    LC_ALL=C sort -t "$tab" -k1,1n -k2,2n -k3,3n -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -k9,9 -k10,10 -k11,11 -k12,12 -k13,13 |
    cut -f 14- |
    awk -F '\t' -v OFS='\t' '
      NF == 19 {
        $1 = "A" NR
        print
      }
    ' >"$tmp_file" || {
      rm -f -- "$tmp_file"
      return 1
    }

  mv -- "$tmp_file" "$visible_artifact_file"
}

nsurgn_scan_build_artifacts() {
  local group_mode="${1:-${NSURGN_GROUP:-profile}}"
  local process_file="${2:-${NSURGN_SCAN_DIR}/process.tsv}"
  local artifact_file="${3:-${NSURGN_SCAN_DIR}/artifact.tsv}"
  local artifact_process_file="${4:-${NSURGN_SCAN_DIR}/artifact_process.tsv}"
  local host_profile_file="${5:-${NSURGN_SCAN_DIR}/host_profile.tsv}"
  local classification_reason_file="${6:-}"
  local cgroup_summary_file cgroup_file
  local process_row group_key host_pid
  local cgroup_hint cgroup_path cgroup_reason_rows cgroup_reason_row
  local reason_code reason_score_delta reason_detail
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns
  local start_time ns_pid read_status
  local artifact_index artifact_id member_pid sorted_keys leader_pid leader_ns_pid leader_reason role
  local namespace_type namespace_id group_component group_namespace_types
  local host_pid_ns host_mnt_ns host_net_ns host_user_ns host_uts_ns host_ipc_ns host_cgroup_ns host_time_ns
  local member_key classification score major_namespace_diff nested_pid_init_evidence container_like_evidence namespace_managed_evidence
  local artifact_cgroup_hint artifact_runtime_hint
  local _
  local keys=()
  local -A seen=()
  local -A process_count=()
  local -A member_pids=()
  local -A member_ns_pid=()
  local -A aggregate_pid_ns=()
  local -A aggregate_mnt_ns=()
  local -A aggregate_net_ns=()
  local -A aggregate_user_ns=()
  local -A aggregate_uts_ns=()
  local -A aggregate_ipc_ns=()
  local -A aggregate_cgroup_ns=()
  local -A aggregate_time_ns=()
  local -A nested_known_pid=()
  local -A nested_known_start_time=()
  local -A nested_unknown_pid=()
  local -A oldest_pid=()
  local -A oldest_start_time=()
  local -A fallback_pid=()
  local -A cgroup_group_key_by_pid=()
  local -A cgroup_hint_by_pid=()
  local -A cgroup_reason_rows_by_pid=()
  local -A aggregate_cgroup_hint=()
  local -A aggregate_cgroup_reason_rows=()

  if [ -n "${NSURGN_SCAN_DIR:-}" ] && [ -f "${NSURGN_SCAN_DIR}/process_cgroup_summary.tsv" ]; then
    cgroup_summary_file="${NSURGN_SCAN_DIR}/process_cgroup_summary.tsv"
  elif [ "$process_file" != "${process_file%/*}" ] && [ -f "${process_file%/*}/process_cgroup_summary.tsv" ]; then
    cgroup_summary_file="${process_file%/*}/process_cgroup_summary.tsv"
  else
    cgroup_summary_file=''
  fi

  if [ -n "$cgroup_summary_file" ]; then
    while IFS=$'\t' read -r host_pid _ group_key cgroup_hint _ _; do
      [ -n "${host_pid:-}" ] || continue
      [ -n "${group_key:-}" ] || group_key='cgroup:unknown'
      [ -n "${cgroup_hint:-}" ] || cgroup_hint='-'
      cgroup_group_key_by_pid[$host_pid]="$group_key"
      cgroup_hint_by_pid[$host_pid]="$cgroup_hint"
    done <"$cgroup_summary_file"
  fi

  if [ -n "${NSURGN_SCAN_DIR:-}" ] && [ -f "${NSURGN_SCAN_DIR}/process_cgroup.tsv" ]; then
    cgroup_file="${NSURGN_SCAN_DIR}/process_cgroup.tsv"
  elif [ "$process_file" != "${process_file%/*}" ] && [ -f "${process_file%/*}/process_cgroup.tsv" ]; then
    cgroup_file="${process_file%/*}/process_cgroup.tsv"
  else
    cgroup_file=''
  fi

  if [ -n "$cgroup_file" ]; then
    while IFS=$'\t' read -r host_pid _ _ _ _ _ cgroup_path _; do
      [ -n "${host_pid:-}" ] || continue
      [ -n "${cgroup_path:-}" ] || continue
      cgroup_reason_rows="$(nsurgn_scan_cgroup_reason_candidates_for_path "$host_pid" "$cgroup_path")" || return "$?"
      [ -n "$cgroup_reason_rows" ] || continue
      cgroup_reason_rows_by_pid[$host_pid]+="${cgroup_reason_rows}"$'\n'
    done <"$cgroup_file"
  fi

  if [ -z "$classification_reason_file" ]; then
    if [ -n "${NSURGN_SCAN_DIR:-}" ]; then
      classification_reason_file="${NSURGN_SCAN_DIR}/classification_reason.tsv"
    elif [ "$artifact_file" != "${artifact_file%/*}" ]; then
      classification_reason_file="${artifact_file%/*}/classification_reason.tsv"
    else
      classification_reason_file='classification_reason.tsv'
    fi
  fi

  if [ "$group_mode" != 'cgroup' ]; then
    group_namespace_types="$(nsurgn_scan_group_namespace_types "$group_mode")" || return "$?"
  fi
  if [ -f "$host_profile_file" ]; then
    IFS=$'\t' read -r \
      _ \
      host_pid_ns \
      host_mnt_ns \
      host_net_ns \
      host_user_ns \
      host_uts_ns \
      host_ipc_ns \
      host_cgroup_ns \
      host_time_ns \
      _ <"$host_profile_file" || {
        host_pid_ns='-'
        host_mnt_ns='-'
        host_net_ns='-'
        host_user_ns='-'
        host_uts_ns='-'
        host_ipc_ns='-'
        host_cgroup_ns='-'
        host_time_ns='-'
      }
  else
    host_pid_ns='-'
    host_mnt_ns='-'
    host_net_ns='-'
    host_user_ns='-'
    host_uts_ns='-'
    host_ipc_ns='-'
    host_cgroup_ns='-'
    host_time_ns='-'
  fi
  [ -n "${host_pid_ns:-}" ] || host_pid_ns='-'
  [ -n "${host_mnt_ns:-}" ] || host_mnt_ns='-'
  [ -n "${host_net_ns:-}" ] || host_net_ns='-'
  [ -n "${host_user_ns:-}" ] || host_user_ns='-'
  [ -n "${host_uts_ns:-}" ] || host_uts_ns='-'
  [ -n "${host_ipc_ns:-}" ] || host_ipc_ns='-'
  [ -n "${host_cgroup_ns:-}" ] || host_cgroup_ns='-'
  [ -n "${host_time_ns:-}" ] || host_time_ns='-'

  while IFS= read -r process_row; do
    [ -n "$process_row" ] || continue
    IFS=$'\t' read -r \
      host_pid \
      _ \
      _ \
      _ \
      _ \
      start_time \
      ns_pid \
      pid_ns \
      mnt_ns \
      net_ns \
      user_ns \
      uts_ns \
      ipc_ns \
      cgroup_ns \
      time_ns \
      _ \
      _ \
      _ \
      _ \
      _ \
      _ \
      _ \
      read_status \
      _ <<<"$process_row"

    if [ "$group_mode" = 'cgroup' ]; then
      group_key="${cgroup_group_key_by_pid[$host_pid]:-cgroup:unknown}"
    else
      group_key=''
      for namespace_type in $group_namespace_types; do
        case "$namespace_type" in
          pid) namespace_id="$pid_ns" ;;
          mnt) namespace_id="$mnt_ns" ;;
          net) namespace_id="$net_ns" ;;
          user) namespace_id="$user_ns" ;;
          uts) namespace_id="$uts_ns" ;;
          ipc) namespace_id="$ipc_ns" ;;
          cgroup) namespace_id="$cgroup_ns" ;;
          time) namespace_id="$time_ns" ;;
          *) return 1 ;;
        esac

        if [ "$namespace_id" = '-' ]; then
          group_component="${namespace_type}=unknown:${host_pid}"
        else
          group_component="${namespace_type}=${namespace_id}"
        fi

        if [ -n "$group_key" ]; then
          group_key+="+${group_component}"
        else
          group_key="$group_component"
        fi
      done
    fi

    if [ -z "${seen[$group_key]+x}" ]; then
      seen[$group_key]=1
      keys+=("$group_key")
      process_count[$group_key]=0
      member_pids[$group_key]=''
      aggregate_pid_ns[$group_key]='-'
      aggregate_mnt_ns[$group_key]='-'
      aggregate_net_ns[$group_key]='-'
      aggregate_user_ns[$group_key]='-'
      aggregate_uts_ns[$group_key]='-'
      aggregate_ipc_ns[$group_key]='-'
      aggregate_cgroup_ns[$group_key]='-'
      aggregate_time_ns[$group_key]='-'
      aggregate_cgroup_hint[$group_key]='-'
      aggregate_cgroup_reason_rows[$group_key]=''
    fi

    process_count[$group_key]=$((process_count[$group_key] + 1))
    member_pids[$group_key]+="${host_pid}"$'\n'
    member_key="${group_key}"$'\t'"${host_pid}"
    member_ns_pid[$member_key]="$ns_pid"
    nsurgn_scan_update_namespace_aggregate "aggregate_pid_ns[$group_key]" "$pid_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_mnt_ns[$group_key]" "$mnt_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_net_ns[$group_key]" "$net_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_user_ns[$group_key]" "$user_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_uts_ns[$group_key]" "$uts_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_ipc_ns[$group_key]" "$ipc_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_cgroup_ns[$group_key]" "$cgroup_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_time_ns[$group_key]" "$time_ns"
    nsurgn_scan_update_cgroup_hint_aggregate "aggregate_cgroup_hint[$group_key]" "${cgroup_hint_by_pid[$host_pid]:--}"
    aggregate_cgroup_reason_rows[$group_key]+="${cgroup_reason_rows_by_pid[$host_pid]:-}"

    nsurgn_is_uint "$host_pid" || continue
    case "$read_status" in
      ok|permission-denied) ;;
      *) continue ;;
    esac

    if [ -z "${fallback_pid[$group_key]+x}" ] || [ "$host_pid" -lt "${fallback_pid[$group_key]}" ]; then
      fallback_pid[$group_key]="$host_pid"
    fi

    if nsurgn_is_uint "$start_time"; then
      if [ -z "${oldest_pid[$group_key]+x}" ] ||
        [ "$start_time" -lt "${oldest_start_time[$group_key]}" ] ||
        { [ "$start_time" -eq "${oldest_start_time[$group_key]}" ] && [ "$host_pid" -lt "${oldest_pid[$group_key]}" ]; }; then
        oldest_pid[$group_key]="$host_pid"
        oldest_start_time[$group_key]="$start_time"
      fi
    fi

    if [ "$ns_pid" = '1' ] &&
      [ "$pid_ns" != '-' ] &&
      [ "$host_pid_ns" != '-' ] &&
      [ "$pid_ns" != "$host_pid_ns" ]; then
      if nsurgn_is_uint "$start_time"; then
        if [ -z "${nested_known_pid[$group_key]+x}" ] ||
          [ "$start_time" -lt "${nested_known_start_time[$group_key]}" ] ||
          { [ "$start_time" -eq "${nested_known_start_time[$group_key]}" ] && [ "$host_pid" -lt "${nested_known_pid[$group_key]}" ]; }; then
          nested_known_pid[$group_key]="$host_pid"
          nested_known_start_time[$group_key]="$start_time"
        fi
      elif [ -z "${nested_unknown_pid[$group_key]+x}" ] || [ "$host_pid" -lt "${nested_unknown_pid[$group_key]}" ]; then
        nested_unknown_pid[$group_key]="$host_pid"
      fi
    fi
  done <"$process_file"

  : >"$artifact_file"
  : >"$artifact_process_file"
  : >"$classification_reason_file"

  [ "${#keys[@]}" -gt 0 ] || return 0

  sorted_keys="$(printf '%s\n' "${keys[@]}" | LC_ALL=C sort)"
  artifact_index=1
  while IFS= read -r group_key; do
    [ -n "$group_key" ] || continue
    leader_pid='-'
    leader_reason='-'
    if [ -n "${nested_known_pid[$group_key]:-}" ]; then
      leader_pid="${nested_known_pid[$group_key]}"
      leader_reason='nested-pid-init'
    elif [ -n "${nested_unknown_pid[$group_key]:-}" ]; then
      leader_pid="${nested_unknown_pid[$group_key]}"
      leader_reason='nested-pid-init'
    elif [ -n "${oldest_pid[$group_key]:-}" ]; then
      leader_pid="${oldest_pid[$group_key]}"
      leader_reason='oldest-process'
    elif [ -n "${fallback_pid[$group_key]:-}" ]; then
      leader_pid="${fallback_pid[$group_key]}"
      leader_reason='lowest-host-pid'
    else
      continue
    fi

    artifact_id="G${artifact_index}"
    member_key="${group_key}"$'\t'"${leader_pid}"
    leader_ns_pid="${member_ns_pid[$member_key]:--}"
    artifact_cgroup_hint="${aggregate_cgroup_hint[$group_key]:--}"
    artifact_runtime_hint="$(nsurgn_scan_runtime_hint_for_cgroup_hint "$artifact_cgroup_hint")"
    score=0
    major_namespace_diff=0
    nested_pid_init_evidence=0
    container_like_evidence=0
    namespace_managed_evidence=0

    nsurgn_scan_add_namespace_diff_score "$artifact_id" pid "${aggregate_pid_ns[$group_key]}" "$host_pid_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" mnt "${aggregate_mnt_ns[$group_key]}" "$host_mnt_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" net "${aggregate_net_ns[$group_key]}" "$host_net_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" user "${aggregate_user_ns[$group_key]}" "$host_user_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" uts "${aggregate_uts_ns[$group_key]}" "$host_uts_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" ipc "${aggregate_ipc_ns[$group_key]}" "$host_ipc_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" cgroup "${aggregate_cgroup_ns[$group_key]}" "$host_cgroup_ns" "$classification_reason_file" score major_namespace_diff
    nsurgn_scan_add_namespace_diff_score "$artifact_id" time "${aggregate_time_ns[$group_key]}" "$host_time_ns" "$classification_reason_file" score major_namespace_diff

    if [ -n "${nested_known_pid[$group_key]:-}" ] || [ -n "${nested_unknown_pid[$group_key]:-}" ]; then
      nested_pid_init_evidence=1
      score=$((score + 4))
      nsurgn_join_by_tab "$artifact_id" nested_pid_init 4 "pid=${leader_pid}" >>"$classification_reason_file"
    fi

    declare -A seen_cgroup_reason=()
    while IFS= read -r cgroup_reason_row; do
      [ -n "$cgroup_reason_row" ] || continue
      IFS=$'\t' read -r reason_code reason_score_delta reason_detail <<<"$cgroup_reason_row"
      [ -n "${reason_code:-}" ] || continue
      [ -z "${seen_cgroup_reason[$reason_code]+x}" ] || continue
      seen_cgroup_reason[$reason_code]=1
      case "$reason_code" in
        cgroup_kubepods|cgroup_containerd|cgroup_docker|cgroup_crio|cgroup_libpod|cgroup_lxc|cgroup_container_id)
          container_like_evidence=1
          ;;
        cgroup_machine_slice)
          namespace_managed_evidence=1
          ;;
        *)
          continue
          ;;
      esac
      nsurgn_is_uint "$reason_score_delta" || return 1
      score=$((score + reason_score_delta))
      nsurgn_join_by_tab "$artifact_id" "$reason_code" "$reason_score_delta" "$reason_detail" >>"$classification_reason_file"
    done <<<"${aggregate_cgroup_reason_rows[$group_key]}"
    unset seen_cgroup_reason

    classification='host'
    if [ "$major_namespace_diff" -eq 1 ]; then
      if [ "$container_like_evidence" -eq 1 ]; then
        classification='container-like'
      elif [ "$nested_pid_init_evidence" -eq 1 ] || [ "$namespace_managed_evidence" -eq 1 ]; then
        classification='namespace-managed'
      else
        classification='isolated'
      fi
    fi

    nsurgn_join_by_tab \
      "$artifact_id" \
      "$group_key" \
      "${aggregate_pid_ns[$group_key]}" \
      "${aggregate_mnt_ns[$group_key]}" \
      "${aggregate_net_ns[$group_key]}" \
      "${aggregate_user_ns[$group_key]}" \
      "${aggregate_uts_ns[$group_key]}" \
      "${aggregate_ipc_ns[$group_key]}" \
      "${aggregate_cgroup_ns[$group_key]}" \
      "${aggregate_time_ns[$group_key]}" \
      "$classification" \
      "$score" \
      "$leader_pid" \
      "$leader_ns_pid" \
      "${process_count[$group_key]}" \
      "$artifact_runtime_hint" \
      "$artifact_cgroup_hint" \
      - \
      "$leader_reason" >>"$artifact_file"

    while IFS= read -r member_pid; do
      [ -n "$member_pid" ] || continue
      role='member'
      [ "$member_pid" = "$leader_pid" ] && role='leader'
      nsurgn_join_by_tab "$artifact_id" "$member_pid" "$role" >>"$artifact_process_file"
    done < <(printf '%s' "${member_pids[$group_key]}" | sort -n)

    artifact_index=$((artifact_index + 1))
  done <<<"$sorted_keys"

  return 0
}

nsurgn_scan_run() {
  nsurgn_scan_require_proc || return "$?"
  nsurgn_scan_create_workspace || return "$?"

  if [ "${NSURGN_VERBOSE:-0}" -eq 1 ]; then
    printf 'verbose: scan workspace: %s\n' "$NSURGN_SCAN_DIR" >&2
  fi

  nsurgn_scan_enumerate_pids /proc >"${NSURGN_SCAN_DIR}/visible_pids.tsv"
  nsurgn_scan_read_host_profile /proc "$NSURGN_HOST_PID" || return "$?"
  nsurgn_scan_read_process_namespaces /proc
  nsurgn_scan_build_artifacts "${NSURGN_GROUP:-profile}"

  # Leader selection, scoring, and classification are added behind this shared
  # workspace so commands cannot drift into ad hoc scraping.
  return 0
}
