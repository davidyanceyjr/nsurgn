#!/usr/bin/env bash

nsurgn_dispatch() {
  case "$NSURGN_COMMAND" in
    help) nsurgn_cmd_help ;;
    version) nsurgn_cmd_version ;;
    doctor) nsurgn_cmd_doctor ;;
    list) nsurgn_cmd_scaffolded_scan_command list ;;
    inspect) nsurgn_cmd_scaffolded_scan_command inspect ;;
    ps) nsurgn_cmd_scaffolded_scan_command ps ;;
    report) nsurgn_cmd_scaffolded_scan_command report ;;
    map) nsurgn_cmd_scaffolded_scan_command map ;;
    *)
      nsurgn_usage_error "invalid command: $NSURGN_COMMAND"
      ;;
  esac
}

nsurgn_expect_arg_count() {
  local command_name="$1"
  local min_count="$2"
  local max_count="$3"
  local actual_count="${#NSURGN_ARGS[@]}"

  if [ "$actual_count" -lt "$min_count" ]; then
    nsurgn_usage_error "${command_name} requires an argument"
    return "$?"
  fi

  if [ "$actual_count" -gt "$max_count" ]; then
    nsurgn_usage_error "${command_name} accepts at most ${max_count} argument(s)"
    return "$?"
  fi
}

nsurgn_cmd_help() {
  nsurgn_expect_arg_count help 0 0 || return "$?"

  cat <<'EOF'
nsurgn - namespace surgeon

Usage:
  nsurgn [global-options] <command> [arguments]

Commands:
  list
  inspect <artifact-id|pid>
  ps <artifact-id|pid>
  report [<artifact-id|pid>]
  map [<artifact-id|pid>]
  doctor
  version
  help

Global options:
  --group <mode>       profile, strict, pid, mnt, net, cgroup
  --format <format>    raw, table, text, json, ndjson
  --verbose            Print resolved paths and decision details to stderr
  --quiet              Suppress non-critical warnings
  --no-color           Disable color output
  --host-pid <pid>     Use specific PID as host namespace profile reference
  --include-host       Include host-classified artifacts
  --version            Print version
  --help               Show help

Examples:
  nsurgn doctor
  nsurgn list
  nsurgn inspect pid:18342

Artifact IDs such as A1 are ephemeral and valid only for one command invocation.
EOF
}

nsurgn_cmd_version() {
  nsurgn_expect_arg_count version 0 0 || return "$?"

  printf 'nsurgn %s\n' "$(nsurgn_version)"
}

nsurgn_cmd_doctor() {
  nsurgn_expect_arg_count doctor 0 0 || return "$?"

  nsurgn_doctor
}

nsurgn_cmd_scaffolded_scan_command() {
  local command_name="$1"

  case "$command_name" in
    list) nsurgn_expect_arg_count "$command_name" 0 0 || return "$?" ;;
    inspect|ps) nsurgn_expect_arg_count "$command_name" 1 1 || return "$?" ;;
    report|map) nsurgn_expect_arg_count "$command_name" 0 1 || return "$?" ;;
  esac

  nsurgn_scan_run || return "$?"
  nsurgn_not_implemented "$command_name"
}
