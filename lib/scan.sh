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
  local read_status='ok'
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns

  namespace_fields="$(nsurgn_scan_namespace_profile_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r namespace_read_status pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns <<<"$namespace_fields"
  status_fields="$(nsurgn_scan_read_status_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r status_read_status ppid uid state ns_pid <<<"$status_fields"
  stat_fields="$(nsurgn_scan_read_stat_fields "$proc_root" "$host_pid")"
  IFS=$'\t' read -r stat_read_status start_time <<<"$stat_fields"

  nsurgn_scan_write_process_source_limitation "$host_pid" namespace "$namespace_read_status" "${proc_root}/${host_pid}/ns"
  nsurgn_scan_write_process_source_limitation "$host_pid" status "$status_read_status" "${proc_root}/${host_pid}/status"
  nsurgn_scan_write_process_source_limitation "$host_pid" stat "$stat_read_status" "${proc_root}/${host_pid}/stat"

  if [ "$namespace_read_status" = 'vanished' ] ||
    [ "$status_read_status" = 'vanished' ] ||
    [ "$stat_read_status" = 'vanished' ]; then
    read_status='vanished'
  elif [ "$namespace_read_status" = 'permission-denied' ] ||
    [ "$status_read_status" = 'permission-denied' ] ||
    [ "$stat_read_status" = 'permission-denied' ]; then
    read_status='permission-denied'
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
    - \
    - \
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
    - \
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
  local current_value="${!variable_name}"
  local next_value

  [ "$process_value" != '-' ] || return 0

  case "$current_value" in
    ''|'-') next_value="$process_value" ;;
    "$process_value") next_value="$current_value" ;;
    mixed) next_value='mixed' ;;
    *) next_value='mixed' ;;
  esac

  printf -v "$variable_name" '%s' "$next_value"
}

nsurgn_scan_build_artifacts() {
  local group_mode="${1:-${NSURGN_GROUP:-profile}}"
  local process_file="${2:-${NSURGN_SCAN_DIR}/process.tsv}"
  local artifact_file="${3:-${NSURGN_SCAN_DIR}/artifact.tsv}"
  local artifact_process_file="${4:-${NSURGN_SCAN_DIR}/artifact_process.tsv}"
  local process_row group_key host_pid
  local pid_ns mnt_ns net_ns user_ns uts_ns ipc_ns cgroup_ns time_ns
  local artifact_index artifact_id member_pid sorted_keys
  local namespace_type namespace_id group_component group_namespace_types
  local _
  local keys=()
  local -A seen=()
  local -A process_count=()
  local -A member_pids=()
  local -A aggregate_pid_ns=()
  local -A aggregate_mnt_ns=()
  local -A aggregate_net_ns=()
  local -A aggregate_user_ns=()
  local -A aggregate_uts_ns=()
  local -A aggregate_ipc_ns=()
  local -A aggregate_cgroup_ns=()
  local -A aggregate_time_ns=()

  [ "$group_mode" != 'cgroup' ] || return 1
  group_namespace_types="$(nsurgn_scan_group_namespace_types "$group_mode")" || return "$?"

  while IFS= read -r process_row; do
    [ -n "$process_row" ] || continue
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
    fi

    process_count[$group_key]=$((process_count[$group_key] + 1))
    member_pids[$group_key]+="${host_pid}"$'\n'
    nsurgn_scan_update_namespace_aggregate "aggregate_pid_ns[$group_key]" "$pid_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_mnt_ns[$group_key]" "$mnt_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_net_ns[$group_key]" "$net_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_user_ns[$group_key]" "$user_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_uts_ns[$group_key]" "$uts_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_ipc_ns[$group_key]" "$ipc_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_cgroup_ns[$group_key]" "$cgroup_ns"
    nsurgn_scan_update_namespace_aggregate "aggregate_time_ns[$group_key]" "$time_ns"
  done <"$process_file"

  : >"$artifact_file"
  : >"$artifact_process_file"

  [ "${#keys[@]}" -gt 0 ] || return 0

  sorted_keys="$(printf '%s\n' "${keys[@]}" | LC_ALL=C sort)"
  artifact_index=1
  while IFS= read -r group_key; do
    [ -n "$group_key" ] || continue
    artifact_id="G${artifact_index}"

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
      - \
      - \
      - \
      - \
      "${process_count[$group_key]}" \
      - \
      - \
      - \
      - >>"$artifact_file"

    while IFS= read -r member_pid; do
      [ -n "$member_pid" ] || continue
      nsurgn_join_by_tab "$artifact_id" "$member_pid" member >>"$artifact_process_file"
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
  if [ "${NSURGN_GROUP:-profile}" != 'cgroup' ]; then
    nsurgn_scan_build_artifacts "${NSURGN_GROUP:-profile}"
  fi

  # Leader selection, scoring, and classification are added behind this shared
  # workspace so commands cannot drift into ad hoc scraping.
  return 0
}
