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

nsurgn_scan_run() {
  nsurgn_scan_require_proc || return "$?"
  nsurgn_scan_create_workspace || return "$?"

  if [ "${NSURGN_VERBOSE:-0}" -eq 1 ]; then
    printf 'verbose: scan workspace: %s\n' "$NSURGN_SCAN_DIR" >&2
  fi

  nsurgn_scan_enumerate_pids /proc >"${NSURGN_SCAN_DIR}/visible_pids.tsv"
  nsurgn_scan_read_host_profile /proc "$NSURGN_HOST_PID" || return "$?"
  nsurgn_scan_read_process_namespaces /proc

  # Discovery, grouping, leader selection, scoring, and classification are added
  # behind this shared workspace so commands cannot drift into ad hoc scraping.
}
