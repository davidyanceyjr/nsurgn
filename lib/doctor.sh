#!/usr/bin/env bash

nsurgn_doctor() {
  local failed=0
  local required_util
  local namespace_link
  local namespace_read_failed=0
  local namespace_seen=0

  if [ -d /proc ] && [ -r /proc ]; then
    nsurgn_doctor_row ok proc 'mounted and readable'
  else
    nsurgn_doctor_row error proc 'missing or unreadable'
    failed=1
  fi

  if [ -d /proc/self/ns ] && [ -r /proc/self/ns ]; then
    for namespace_link in /proc/self/ns/*; do
      [ -e "$namespace_link" ] || continue
      namespace_seen=1
      if ! readlink "$namespace_link" >/dev/null 2>&1; then
        namespace_read_failed=1
      fi
    done

    if [ "$namespace_seen" -eq 1 ] && [ "$namespace_read_failed" -eq 0 ]; then
      nsurgn_doctor_row ok namespace-links 'readable for current process'
    else
      nsurgn_doctor_row error namespace-links 'missing or unreadable for current process'
      failed=1
    fi
  else
    nsurgn_doctor_row error namespace-links 'missing or unreadable for current process'
    failed=1
  fi

  for required_util in readlink stat ps awk sed grep sort uniq find; do
    if nsurgn_has_command "$required_util"; then
      nsurgn_doctor_row ok "util:${required_util}" 'available'
    else
      nsurgn_doctor_row error "util:${required_util}" 'not found'
      failed=1
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
  local status="$1"
  local check_name="$2"
  local message="$3"

  case "$status" in
    warning) nsurgn_warning "doctor ${check_name}: ${message}" ;;
    error) nsurgn_error "doctor ${check_name}: ${message}" ;;
  esac

  case "$NSURGN_FORMAT" in
    raw)
      nsurgn_join_by_tab "$status" "$check_name" "$message"
      ;;
    table|text|json|ndjson)
      nsurgn_join_by_tab "$status" "$check_name" "$message"
      ;;
  esac
}
