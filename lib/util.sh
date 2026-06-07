#!/usr/bin/env bash

nsurgn_version() {
  printf '%s\n' '0.1.0-dev'
}

nsurgn_has_command() {
  command -v "$1" >/dev/null 2>&1
}

nsurgn_is_uint() {
  case "${1:-}" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

nsurgn_tsv_escape() {
  local value="${1-}"
  value=${value//$'\t'/\\t}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

nsurgn_join_by_tab() {
  local first=1
  local field

  for field in "$@"; do
    if [ "$first" -eq 0 ]; then
      printf '\t'
    fi
    nsurgn_tsv_escape "$field"
    first=0
  done
  printf '\n'
}
