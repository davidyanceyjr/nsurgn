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

run_stdout_only() {
  local tmpdir out err

  tmpdir="$(mktemp -d)"
  out="${tmpdir}/stdout"
  err="${tmpdir}/stderr"

  "$@" >"$out" 2>"$err" || {
    local actual="$?"
    rm -rf "$tmpdir"
    fail "expected success: $* exited ${actual}"
  }

  [ -s "$out" ] || {
    rm -rf "$tmpdir"
    fail "expected stdout: $*"
  }
  [ ! -s "$err" ] || {
    rm -rf "$tmpdir"
    fail "expected empty stderr: $*"
  }

  rm -rf "$tmpdir"
}

run_stderr_only_status() {
  local expected="$1"
  shift
  local tmpdir out err actual

  tmpdir="$(mktemp -d)"
  out="${tmpdir}/stdout"
  err="${tmpdir}/stderr"
  actual=0

  "$@" >"$out" 2>"$err" || actual="$?"

  [ "$actual" -eq "$expected" ] || {
    rm -rf "$tmpdir"
    fail "expected exit ${expected}, got ${actual}: $*"
  }
  [ ! -s "$out" ] || {
    rm -rf "$tmpdir"
    fail "expected empty stdout: $*"
  }
  [ -s "$err" ] || {
    rm -rf "$tmpdir"
    fail "expected stderr diagnostics: $*"
  }

  rm -rf "$tmpdir"
}

run_doctor_contract() {
  local tmpdir out err actual

  tmpdir="$(mktemp -d)"
  out="${tmpdir}/stdout"
  err="${tmpdir}/stderr"
  actual=0

  "$NSURGN" doctor >"$out" 2>"$err" || actual="$?"

  [ "$actual" -eq 0 ] || {
    rm -rf "$tmpdir"
    fail "expected doctor success, got ${actual}"
  }
  [ -s "$out" ] || {
    rm -rf "$tmpdir"
    fail 'expected doctor rows on stdout'
  }

  if grep -Eq $'^(warning|error)\t' "$out"; then
    [ -s "$err" ] || {
      rm -rf "$tmpdir"
      fail 'expected doctor warnings or errors on stderr'
    }
  fi

  rm -rf "$tmpdir"
}

run_ok "$NSURGN" help
run_ok "$NSURGN" --help
run_ok "$NSURGN" version
run_ok "$NSURGN" --version
run_doctor_contract
run_stdout_only "$NSURGN" help
run_stdout_only "$NSURGN" --help
run_stdout_only "$NSURGN" version
run_stdout_only "$NSURGN" --version
run_stderr_only_status 2 "$NSURGN" --bad-option
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
run_status 2 "$NSURGN" inspect one two
run_status 2 "$NSURGN" ps
run_status 2 "$NSURGN" ps one two
run_status 2 "$NSURGN" report one two
run_status 2 "$NSURGN" map one two
run_stderr_only_status 1 "$NSURGN" list
run_stderr_only_status 1 "$NSURGN" inspect "$$"
run_stderr_only_status 1 "$NSURGN" ps "$$"
run_stderr_only_status 1 "$NSURGN" report
run_stderr_only_status 1 "$NSURGN" map

escaped="$(nsurgn_join_by_tab "a\\b" $'x\ty\rz\nq' -)"
expected=$'a\\\\b\tx\\ty\\rz\\nq\t-'
[ "$escaped" = "$expected" ] || fail "unexpected TSV escaping: ${escaped}"

printf 'ok - scaffold smoke tests passed\n'
