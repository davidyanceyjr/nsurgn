#!/usr/bin/env bash

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
NSURGN="${ROOT}/bin/nsurgn"

# shellcheck source=lib/util.sh
. "${ROOT}/lib/util.sh"

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
run_status 2 "$NSURGN" --format nope list
run_status 2 "$NSURGN" --group
run_status 2 "$NSURGN" --format
run_status 2 "$NSURGN" does-not-exist
run_status 2 "$NSURGN" help extra
run_status 2 "$NSURGN" version extra
run_status 2 "$NSURGN" --help extra
run_status 2 "$NSURGN" --version extra
run_status 2 "$NSURGN" doctor extra
run_status 2 "$NSURGN" list extra
run_status 2 "$NSURGN" inspect
run_status 2 "$NSURGN" ps
run_status 2 "$NSURGN" report one two
run_status 2 "$NSURGN" map one two
run_status 1 "$NSURGN" list

escaped="$(nsurgn_join_by_tab "a\\b" $'x\ty\rz\nq' -)"
expected=$'a\\\\b\tx\\ty\\rz\\nq\t-'
[ "$escaped" = "$expected" ] || fail "unexpected TSV escaping: ${escaped}"

printf 'ok - scaffold smoke tests passed\n'
