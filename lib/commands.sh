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

nsurgn_cmd_help() {
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
  printf 'nsurgn %s\n' "$(nsurgn_version)"
}

nsurgn_cmd_doctor() {
  if [ "${#NSURGN_ARGS[@]}" -ne 0 ]; then
    nsurgn_usage_error 'doctor does not accept arguments'
    return "$?"
  fi
  nsurgn_doctor
}

nsurgn_cmd_scaffolded_scan_command() {
  local command_name="$1"

  nsurgn_scan_run || return "$?"
  nsurgn_not_implemented "$command_name"
}
