#!/usr/bin/env bash

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
NSURGN="${ROOT}/bin/nsurgn"

# shellcheck source=lib/util.sh
. "${ROOT}/lib/util.sh"
# shellcheck source=lib/errors.sh
. "${ROOT}/lib/errors.sh"
# shellcheck source=lib/scan.sh
. "${ROOT}/lib/scan.sh"

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

run_pid_enumeration_contract() {
  local tmpdir output expected

  tmpdir="$(mktemp -d)"
  mkdir -p "${tmpdir}/1" "${tmpdir}/2" "${tmpdir}/10" "${tmpdir}/abc"
  : >"${tmpdir}/3"
  mkdir -p "${tmpdir}/123abc"

  output="$(nsurgn_scan_enumerate_pids "$tmpdir")" || {
    rm -rf "$tmpdir"
    fail 'PID enumeration failed'
  }

  expected=$'1\n2\n10'
  [ "$output" = "$expected" ] || {
    rm -rf "$tmpdir"
    fail "unexpected PID enumeration output: ${output}"
  }

  rm -rf "${tmpdir}/2"
  nsurgn_scan_enumerate_pids "$tmpdir" >/dev/null || {
    rm -rf "$tmpdir"
    fail 'PID enumeration should tolerate missing proc entries'
  }

  rm -rf "$tmpdir"
}

run_namespace_reader_contract() {
  local tmpdir output expected row field_count

  tmpdir="$(mktemp -d)"
  mkdir -p "${tmpdir}/42/ns"
  ln -s 'pid:[1001]' "${tmpdir}/42/ns/pid"
  ln -s 'mnt:[1002]' "${tmpdir}/42/ns/mnt"
  ln -s 'net:[1003]' "${tmpdir}/42/ns/net"
  ln -s 'user:[1004]' "${tmpdir}/42/ns/user"
  ln -s 'uts:[1005]' "${tmpdir}/42/ns/uts"
  ln -s 'ipc:[1006]' "${tmpdir}/42/ns/ipc"
  ln -s 'cgroup:[1007]' "${tmpdir}/42/ns/cgroup"
  {
    printf 'Name:\tworker\n'
    printf 'State:\tS (sleeping)\n'
    printf 'PPid:\t24\n'
    printf 'Uid:\t1000\t1000\t1000\t1000\n'
    printf 'NSpid:\t42\t7\t1\n'
  } >"${tmpdir}/42/status"
  printf '42 (worker) S 24 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 123456 0\n' >"${tmpdir}/42/stat"

  output="$(nsurgn_scan_parse_namespace_id pid 'pid:[4026531836]')" || {
    rm -rf "$tmpdir"
    fail 'namespace ID parsing failed'
  }
  [ "$output" = '4026531836' ] || {
    rm -rf "$tmpdir"
    fail "unexpected namespace ID: ${output}"
  }

  if nsurgn_scan_parse_namespace_id pid 'mnt:[4026531836]' >/dev/null; then
    rm -rf "$tmpdir"
    fail 'namespace ID parser accepted mismatched type'
  fi

  output="$(nsurgn_scan_namespace_profile_fields "$tmpdir" 42)" || {
    rm -rf "$tmpdir"
    fail 'namespace profile read failed'
  }
  expected=$'ok\t1001\t1002\t1003\t1004\t1005\t1006\t1007\t-'
  [ "$output" = "$expected" ] || {
    rm -rf "$tmpdir"
    fail "unexpected namespace profile: ${output}"
  }

  output="$(nsurgn_scan_namespace_profile_fields "$tmpdir" 99)" || {
    rm -rf "$tmpdir"
    fail 'vanished namespace profile read failed'
  }
  expected=$'vanished\t-\t-\t-\t-\t-\t-\t-\t-'
  [ "$output" = "$expected" ] || {
    rm -rf "$tmpdir"
    fail "unexpected vanished namespace profile: ${output}"
  }

  row="$(nsurgn_scan_write_process_namespace_row "$tmpdir" 42)" || {
    rm -rf "$tmpdir"
    fail 'process namespace row write failed'
  }
  field_count="$(printf '%s\n' "$row" | awk -F '\t' '{ print NF }')"
  [ "$field_count" -eq 31 ] || {
    rm -rf "$tmpdir"
    fail "expected 31 process fields, got ${field_count}"
  }
  printf '%s\n' "$row" | awk -F '\t' '
    $1 == "42" &&
    $2 == "24" &&
    $3 == "1000" &&
    $5 == "S" &&
    $6 == "123456" &&
    $7 == "1" &&
    $8 == "1001" &&
    $14 == "1007" &&
    $15 == "-" &&
    $23 == "ok" &&
    $24 == "ok" &&
    $25 == "ok" &&
    $26 == "ok" { found=1 }
    END { exit found ? 0 : 1 }
  ' || {
    rm -rf "$tmpdir"
    fail "unexpected process namespace row: ${row}"
  }

  output="$(nsurgn_scan_read_status_fields "$tmpdir" 42)" || {
    rm -rf "$tmpdir"
    fail 'status metadata read failed'
  }
  expected=$'ok\t24\t1000\tS\t1'
  [ "$output" = "$expected" ] || {
    rm -rf "$tmpdir"
    fail "unexpected status metadata: ${output}"
  }

  output="$(nsurgn_scan_read_stat_fields "$tmpdir" 42)" || {
    rm -rf "$tmpdir"
    fail 'stat metadata read failed'
  }
  expected=$'ok\t123456'
  [ "$output" = "$expected" ] || {
    rm -rf "$tmpdir"
    fail "unexpected stat metadata: ${output}"
  }

  rm -rf "$tmpdir"
}

run_host_profile_reader_contract() {
  local tmpdir actual row expected_status

  tmpdir="$(mktemp -d)"
  mkdir -p "${tmpdir}/1/ns" "${tmpdir}/7/ns" "${tmpdir}/8/ns" "${tmpdir}/9/ns" "${tmpdir}/scan"
  NSURGN_SCAN_DIR="${tmpdir}/scan"
  : >"${NSURGN_SCAN_DIR}/scan_limitation.tsv"
  : >"${NSURGN_SCAN_DIR}/host_profile.tsv"

  ln -s 'pid:[1001]' "${tmpdir}/1/ns/pid"
  ln -s 'mnt:[1002]' "${tmpdir}/1/ns/mnt"
  ln -s 'net:[1003]' "${tmpdir}/1/ns/net"
  ln -s 'user:[1004]' "${tmpdir}/1/ns/user"
  ln -s 'uts:[1005]' "${tmpdir}/1/ns/uts"
  ln -s 'ipc:[1006]' "${tmpdir}/1/ns/ipc"
  ln -s 'cgroup:[1007]' "${tmpdir}/1/ns/cgroup"

  ln -s 'pid:[7001]' "${tmpdir}/7/ns/pid"
  ln -s 'mnt:[7002]' "${tmpdir}/7/ns/mnt"
  ln -s 'net:[7003]' "${tmpdir}/7/ns/net"
  ln -s 'user:[7004]' "${tmpdir}/7/ns/user"

  nsurgn_scan_read_host_profile "$tmpdir" 1 2>/dev/null || {
    rm -rf "$tmpdir"
    fail 'default host profile read failed'
  }
  row="$(cat "${NSURGN_SCAN_DIR}/host_profile.tsv")"
  printf '%s\n' "$row" | awk -F '\t' '
    $1 == "1" &&
    $2 == "1001" &&
    $5 == "1004" &&
    $8 == "1007" &&
    $9 == "-" &&
    $10 == "ok" { found=1 }
    END { exit found ? 0 : 1 }
  ' || {
    rm -rf "$tmpdir"
    fail "unexpected default host profile row: ${row}"
  }

  nsurgn_scan_read_host_profile "$tmpdir" 7 2>/dev/null || {
    rm -rf "$tmpdir"
    fail 'override host profile read failed'
  }
  row="$(cat "${NSURGN_SCAN_DIR}/host_profile.tsv")"
  printf '%s\n' "$row" | awk -F '\t' '$1 == "7" && $2 == "7001" && $5 == "7004" && $10 == "ok" { found=1 } END { exit found ? 0 : 1 }' || {
    rm -rf "$tmpdir"
    fail "unexpected override host profile row: ${row}"
  }

  actual=0
  nsurgn_scan_read_host_profile "$tmpdir" 99 2>/dev/null || actual="$?"
  [ "$actual" -eq "$NSURGN_EXIT_PROCESS_CHANGED" ] || {
    rm -rf "$tmpdir"
    fail "expected vanished host profile exit ${NSURGN_EXIT_PROCESS_CHANGED}, got ${actual}"
  }

  mkdir "${tmpdir}/8/ns/pid"
  ln -s 'mnt:[8002]' "${tmpdir}/8/ns/mnt"
  ln -s 'net:[8003]' "${tmpdir}/8/ns/net"
  ln -s 'user:[8004]' "${tmpdir}/8/ns/user"
  actual=0
  nsurgn_scan_read_host_profile "$tmpdir" 8 2>/dev/null || actual="$?"
  [ "$actual" -eq "$NSURGN_EXIT_PERMISSION_DENIED" ] || {
    rm -rf "$tmpdir"
    fail "expected permission host profile exit ${NSURGN_EXIT_PERMISSION_DENIED}, got ${actual}"
  }

  ln -s 'pid:[9001]' "${tmpdir}/9/ns/pid"
  ln -s 'mnt:[9002]' "${tmpdir}/9/ns/mnt"
  ln -s 'net:[9003]' "${tmpdir}/9/ns/net"
  actual=0
  nsurgn_scan_read_host_profile "$tmpdir" 9 2>/dev/null || actual="$?"
  [ "$actual" -eq "$NSURGN_EXIT_UNSUPPORTED_PLATFORM" ] || {
    rm -rf "$tmpdir"
    fail "expected unsupported host profile exit ${NSURGN_EXIT_UNSUPPORTED_PLATFORM}, got ${actual}"
  }

  expected_status="$(awk -F '\t' 'END { print $1 ":" $2 ":" $6 }' "${NSURGN_SCAN_DIR}/scan_limitation.tsv")"
  [ "$expected_status" = 'error:missing_namespace:-' ] || {
    rm -rf "$tmpdir"
    fail "unexpected final host limitation status: ${expected_status}"
  }

  rm -rf "$tmpdir"
  NSURGN_SCAN_DIR=''
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
run_stderr_only_status 2 "$NSURGN" --host-pid nope list
run_stderr_only_status 2 "$NSURGN" --group
run_stderr_only_status 2 "$NSURGN" --format
run_stderr_only_status 2 "$NSURGN" --host-pid
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
run_stderr_only_status 1 "$NSURGN" --host-pid "$$" list
run_stderr_only_status 1 "$NSURGN" --host-pid "$$" inspect "$$"
run_stderr_only_status 1 "$NSURGN" --host-pid "$$" ps "$$"
run_stderr_only_status 1 "$NSURGN" --host-pid "$$" report
run_stderr_only_status 1 "$NSURGN" --host-pid "$$" map

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

run_pid_enumeration_contract
run_namespace_reader_contract
run_host_profile_reader_contract
run_shellcheck_if_available

printf 'ok - scaffold smoke tests passed\n'
