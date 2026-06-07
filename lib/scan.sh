#!/usr/bin/env bash

NSURGN_SCAN_DIR=''

nsurgn_scan_create_workspace() {
  NSURGN_SCAN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nsurgn.XXXXXX")" || return "$NSURGN_EXIT_GENERAL_ERROR"
  trap nsurgn_scan_cleanup EXIT HUP INT TERM

  : >"${NSURGN_SCAN_DIR}/process.tsv"
  : >"${NSURGN_SCAN_DIR}/artifact.tsv"
  : >"${NSURGN_SCAN_DIR}/artifact_process.tsv"
  : >"${NSURGN_SCAN_DIR}/classification_reason.tsv"
  : >"${NSURGN_SCAN_DIR}/scan_warning.tsv"
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

nsurgn_scan_run() {
  nsurgn_scan_require_proc || return "$?"
  nsurgn_scan_create_workspace || return "$?"

  if [ "${NSURGN_VERBOSE:-0}" -eq 1 ]; then
    printf 'verbose: scan workspace: %s\n' "$NSURGN_SCAN_DIR" >&2
  fi

  # Discovery, grouping, leader selection, scoring, and classification are added
  # behind this shared workspace so commands cannot drift into ad hoc scraping.
}
