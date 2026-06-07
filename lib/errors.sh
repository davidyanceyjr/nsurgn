#!/usr/bin/env bash

# shellcheck disable=SC2034

NSURGN_EXIT_SUCCESS=0
NSURGN_EXIT_GENERAL_ERROR=1
NSURGN_EXIT_USAGE_ERROR=2
NSURGN_EXIT_PERMISSION_DENIED=3
NSURGN_EXIT_TARGET_NOT_FOUND=4
NSURGN_EXIT_ARTIFACT_NOT_FOUND=5
NSURGN_EXIT_PARTIAL_SUCCESS=6
NSURGN_EXIT_PROCESS_CHANGED=7
NSURGN_EXIT_UNSUPPORTED_PLATFORM=8

nsurgn_error() {
  printf 'error: %s\n' "$*" >&2
}

nsurgn_warning() {
  if [ "${NSURGN_QUIET:-0}" -eq 0 ]; then
    printf 'warning: %s\n' "$*" >&2
  fi
}

nsurgn_hint() {
  printf 'hint: %s\n' "$*" >&2
}

nsurgn_usage_error() {
  nsurgn_error "$*"
  return "$NSURGN_EXIT_USAGE_ERROR"
}

nsurgn_not_implemented() {
  nsurgn_error "$1 is not implemented yet"
  nsurgn_hint 'the v1 scaffold currently supports help, version, doctor, and shared scan workspace setup'
  return "$NSURGN_EXIT_GENERAL_ERROR"
}
