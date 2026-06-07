#!/usr/bin/env bash

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
NSURGN="${ROOT}/bin/nsurgn"

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

run_ok() {
  "$@" >/dev/null || fail "expected success: $*"
}

run_status() {
  local expected="$1"
  shift
  local actual=0

  "$@" >/dev/null 2>/dev/null || actual="$?"
  [ "$actual" -eq "$expected" ] || fail "expected exit ${expected}, got ${actual}: $*"
}

run_ok "$NSURGN" help
run_ok "$NSURGN" --help
run_ok "$NSURGN" version
run_ok "$NSURGN" --version
run_ok "$NSURGN" doctor
run_status 2 "$NSURGN" --group nope list
run_status 2 "$NSURGN" does-not-exist
run_status 1 "$NSURGN" list

printf 'ok - scaffold smoke tests passed\n'
