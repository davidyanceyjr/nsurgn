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

run_shellcheck_if_available() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    return 0
  fi

  (
    cd "$ROOT" || exit 1
    shellcheck -x \
      bin/nsurgn \
      lib/cli.sh \
      lib/commands.sh \
      lib/doctor.sh \
      lib/errors.sh \
      lib/scan.sh \
      lib/util.sh \
      test/smoke.sh
  ) || fail 'shellcheck failed'
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
run_stderr_only_status 2 "$NSURGN" --group nope list
run_stderr_only_status 2 "$NSURGN" --format nope list
run_stderr_only_status 2 "$NSURGN" --group
run_stderr_only_status 2 "$NSURGN" --format
run_stderr_only_status 2 "$NSURGN" does-not-exist
run_stderr_only_status 2 "$NSURGN" help extra
run_stderr_only_status 2 "$NSURGN" version extra
run_stderr_only_status 2 "$NSURGN" --help extra
run_stderr_only_status 2 "$NSURGN" --version extra
run_stderr_only_status 2 "$NSURGN" doctor extra
run_stderr_only_status 2 "$NSURGN" list extra
run_stderr_only_status 2 "$NSURGN" inspect
run_stderr_only_status 2 "$NSURGN" inspect one two
run_stderr_only_status 2 "$NSURGN" ps
run_stderr_only_status 2 "$NSURGN" ps one two
run_stderr_only_status 2 "$NSURGN" report one two
run_stderr_only_status 2 "$NSURGN" map one two
run_stderr_only_status 1 "$NSURGN" list
run_stderr_only_status 1 "$NSURGN" inspect "$$"
run_stderr_only_status 1 "$NSURGN" ps "$$"
run_stderr_only_status 1 "$NSURGN" report
run_stderr_only_status 1 "$NSURGN" map

escaped="$(nsurgn_tsv_escape $'a\tb')"
[ "$escaped" = 'a\tb' ] || fail "unexpected tab escaping: ${escaped}"

escaped="$(nsurgn_tsv_escape $'a\nb')"
[ "$escaped" = 'a\nb' ] || fail "unexpected newline escaping: ${escaped}"

escaped="$(nsurgn_tsv_escape $'a\rb')"
[ "$escaped" = 'a\rb' ] || fail "unexpected carriage-return escaping: ${escaped}"

escaped="$(nsurgn_tsv_escape 'a\b')"
[ "$escaped" = 'a\\b' ] || fail "unexpected backslash escaping: ${escaped}"

escaped="$(nsurgn_join_by_tab "a\\b" $'x\ty\rz\nq' -)"
expected=$'a\\\\b\tx\\ty\\rz\\nq\t-'
[ "$escaped" = "$expected" ] || fail "unexpected TSV row escaping: ${escaped}"

line_count="$(printf '%s\n' "$escaped" | wc -l | awk '{ print $1 }')"
[ "$line_count" -eq 1 ] || fail "expected one physical TSV line, got ${line_count}"

run_shellcheck_if_available

printf 'ok - scaffold smoke tests passed\n'
