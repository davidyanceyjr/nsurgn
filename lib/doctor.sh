#!/usr/bin/env bash

nsurgn_doctor() {
  local failed=0
  local required_util

  if [ -d /proc ] && [ -r /proc ]; then
    nsurgn_doctor_row ok proc 'mounted and readable'
  else
    nsurgn_doctor_row error proc 'missing or unreadable'
    failed=1
  fi

  if [ -d /proc/self/ns ] && [ -r /proc/self/ns ]; then
    nsurgn_doctor_row ok namespace-links 'readable for current process'
  else
    nsurgn_doctor_row error namespace-links 'missing or unreadable for current process'
    failed=1
  fi

  for required_util in readlink stat ps awk sed grep sort uniq find; do
    if nsurgn_has_command "$required_util"; then
      nsurgn_doctor_row ok "util:${required_util}" 'available'
    else
      nsurgn_doctor_row warning "util:${required_util}" 'not found'
    fi
  done

  if [ "$(id -u)" -eq 0 ]; then
    nsurgn_doctor_row ok user 'running as root'
  else
    nsurgn_doctor_row warning user 'running without root; results may be incomplete'
  fi

  if [ -r /proc/1/status ]; then
    nsurgn_doctor_row ok process-visibility '/proc/1/status readable'
  else
    nsurgn_doctor_row warning process-visibility '/proc/1/status unreadable; procfs visibility may be limited'
  fi

  if [ "$failed" -eq 1 ]; then
    return "$NSURGN_EXIT_UNSUPPORTED_PLATFORM"
  fi
  return "$NSURGN_EXIT_SUCCESS"
}

nsurgn_doctor_row() {
  case "$NSURGN_FORMAT" in
    raw)
      nsurgn_join_by_tab "$1" "$2" "$3"
      ;;
    table|text|json|ndjson)
      nsurgn_join_by_tab "$1" "$2" "$3"
      ;;
  esac
}
