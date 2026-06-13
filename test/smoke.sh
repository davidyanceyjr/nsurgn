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
  if nsurgn_scan_parse_namespace_id pid 'pid:[not-a-number]' >/dev/null; then
    rm -rf "$tmpdir"
    fail 'namespace ID parser accepted non-numeric ID'
  fi
  if nsurgn_scan_parse_namespace_id pid 'pid:4026531836' >/dev/null; then
    rm -rf "$tmpdir"
    fail 'namespace ID parser accepted malformed namespace link'
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

run_process_limitation_contract() {
  local tmpdir row limitation_summary

  tmpdir="$(mktemp -d)"
  mkdir -p "${tmpdir}/42/ns" "${tmpdir}/scan"
  NSURGN_SCAN_DIR="${tmpdir}/scan"
  : >"${NSURGN_SCAN_DIR}/scan_limitation.tsv"

  mkdir "${tmpdir}/42/ns/pid"
  ln -s 'mnt:[1002]' "${tmpdir}/42/ns/mnt"
  ln -s 'net:[1003]' "${tmpdir}/42/ns/net"
  ln -s 'user:[1004]' "${tmpdir}/42/ns/user"
  mkdir "${tmpdir}/42/status" "${tmpdir}/42/stat"

  row="$(nsurgn_scan_write_process_namespace_row "$tmpdir" 42)" || {
    rm -rf "$tmpdir"
    fail 'process limitation row write failed'
  }
  printf '%s\n' "$row" | awk -F '\t' '$23 == "permission-denied" && $24 == "permission-denied" && $25 == "permission-denied" && $26 == "permission-denied" { found=1 } END { exit found ? 0 : 1 }' || {
    rm -rf "$tmpdir"
    fail "unexpected permission-denied process row: ${row}"
  }

  nsurgn_scan_write_process_namespace_row "$tmpdir" 99 >/dev/null || {
    rm -rf "$tmpdir"
    fail 'vanished process limitation row write failed'
  }

  limitation_summary="$(awk -F '\t' '
    $1 == "warning" && $2 == "permission_denied" && $3 == "42" && $5 == "namespace" && $6 == "permission-denied" { permission_namespace=1 }
    $1 == "warning" && $2 == "permission_denied" && $3 == "42" && $5 == "status" && $6 == "permission-denied" { permission_status=1 }
    $1 == "warning" && $2 == "permission_denied" && $3 == "42" && $5 == "stat" && $6 == "permission-denied" { permission_stat=1 }
    $1 == "warning" && $2 == "process_vanished" && $3 == "99" && $5 == "namespace" && $6 == "vanished" { vanished_namespace=1 }
    $1 == "warning" && $2 == "process_vanished" && $3 == "99" && $5 == "status" && $6 == "vanished" { vanished_status=1 }
    $1 == "warning" && $2 == "process_vanished" && $3 == "99" && $5 == "stat" && $6 == "vanished" { vanished_stat=1 }
    END {
      print permission_namespace ":" permission_status ":" permission_stat ":" vanished_namespace ":" vanished_status ":" vanished_stat ":" NR
    }
  ' "${NSURGN_SCAN_DIR}/scan_limitation.tsv")"
  [ "$limitation_summary" = '1:1:1:1:1:1:6' ] || {
    rm -rf "$tmpdir"
    fail "unexpected process limitations: ${limitation_summary}"
  }

  rm -rf "$tmpdir"
  NSURGN_SCAN_DIR=''
}

make_process_row_for_group_key() {
  local host_pid="$1"
  local pid_ns="$2"
  local mnt_ns="$3"
  local net_ns="$4"
  local user_ns="$5"
  local uts_ns="$6"
  local ipc_ns="$7"
  local cgroup_ns="$8"
  local time_ns="$9"

  nsurgn_join_by_tab \
    "$host_pid" \
    1 \
    0 \
    - \
    S \
    100 \
    "$host_pid" \
    "$pid_ns" \
    "$mnt_ns" \
    "$net_ns" \
    "$user_ns" \
    "$uts_ns" \
    "$ipc_ns" \
    "$cgroup_ns" \
    "$time_ns" \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    ok \
    ok \
    ok \
    ok \
    - \
    - \
    - \
    - \
    -
}

make_process_row_for_leader() {
  local host_pid="$1"
  local pid_ns="$2"
  local start_time="$3"
  local ns_pid="$4"
  local read_status="$5"

  nsurgn_join_by_tab \
    "$host_pid" \
    1 \
    0 \
    - \
    S \
    "$start_time" \
    "$ns_pid" \
    "$pid_ns" \
    1002 \
    1003 \
    1004 \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    - \
    "$read_status" \
    ok \
    ok \
    ok \
    - \
    - \
    - \
    - \
    -
}

run_group_key_contract() {
  local row_a row_b key_a key_b expected

  expected='pid mnt net user'
  [ "$(nsurgn_scan_group_namespace_types profile)" = "$expected" ] ||
    fail 'unexpected profile namespace grouping order'
  expected='pid mnt net user uts ipc cgroup time'
  [ "$(nsurgn_scan_group_namespace_types strict)" = "$expected" ] ||
    fail 'unexpected strict namespace grouping order'
  [ "$(nsurgn_scan_group_namespace_types mnt)" = 'mnt' ] ||
    fail 'unexpected mount namespace grouping order'
  if nsurgn_scan_group_namespace_types cgroup >/dev/null; then
    fail 'cgroup namespace grouping should not be available before cgroup summaries'
  fi

  row_a="$(make_process_row_for_group_key 42 1001 1002 1003 1004 1005 1006 1007 1008)"
  key_a="$(nsurgn_scan_process_namespace_group_key profile "$row_a")" ||
    fail 'profile group key construction failed'
  [ "$key_a" = 'pid=1001+mnt=1002+net=1003+user=1004' ] ||
    fail "unexpected profile group key: ${key_a}"

  key_a="$(nsurgn_scan_process_namespace_group_key strict "$row_a")" ||
    fail 'strict group key construction failed'
  [ "$key_a" = 'pid=1001+mnt=1002+net=1003+user=1004+uts=1005+ipc=1006+cgroup=1007+time=1008' ] ||
    fail "unexpected strict group key: ${key_a}"

  row_a="$(make_process_row_for_group_key 42 - 1002 1003 1004 1005 1006 1007 1008)"
  row_b="$(make_process_row_for_group_key 43 - 1002 1003 1004 1005 1006 1007 1008)"
  key_a="$(nsurgn_scan_process_namespace_group_key profile "$row_a")" ||
    fail 'missing grouped namespace key construction failed'
  key_b="$(nsurgn_scan_process_namespace_group_key profile "$row_b")" ||
    fail 'second missing grouped namespace key construction failed'
  [ "$key_a" = 'pid=unknown:42+mnt=1002+net=1003+user=1004' ] ||
    fail "unexpected process-distinct unknown group key: ${key_a}"
  [ "$key_b" = 'pid=unknown:43+mnt=1002+net=1003+user=1004' ] ||
    fail "unexpected second process-distinct unknown group key: ${key_b}"
  [ "$key_a" != "$key_b" ] ||
    fail 'missing grouped namespace IDs coalesced across host PIDs'

  row_a="$(make_process_row_for_group_key 42 1001 - 1003 1004 1005 1006 1007 1008)"
  row_b="$(make_process_row_for_group_key 43 1001 1002 1003 1004 1005 1006 1007 1008)"
  key_a="$(nsurgn_scan_process_namespace_group_key pid "$row_a")" ||
    fail 'missing ungrouped namespace key construction failed'
  key_b="$(nsurgn_scan_process_namespace_group_key pid "$row_b")" ||
    fail 'second missing ungrouped namespace key construction failed'
  [ "$key_a" = 'pid=1001' ] ||
    fail "unexpected PID group key with missing ungrouped namespace: ${key_a}"
  [ "$key_a" = "$key_b" ] ||
    fail 'missing ungrouped namespace changed group identity'
}

run_artifact_aggregation_contract() {
  local tmpdir process_file artifact_file artifact_process_file

  tmpdir="$(mktemp -d)"
  process_file="${tmpdir}/process.tsv"
  artifact_file="${tmpdir}/artifact.tsv"
  artifact_process_file="${tmpdir}/artifact_process.tsv"

  {
    make_process_row_for_group_key 42 1001 1002 1003 1004 2001 3001 - -
    make_process_row_for_group_key 43 1001 1002 1003 1004 2002 3001 - 4001
    make_process_row_for_group_key 44 9001 9002 9003 9004 9005 9006 9007 9008
    make_process_row_for_group_key 45 - 1002 1003 1004 - - - -
  } >"$process_file"

  nsurgn_scan_build_artifacts profile "$process_file" "$artifact_file" "$artifact_process_file" ||
    fail 'artifact aggregation failed'

  awk -F '\t' 'NF != 19 { exit 1 } END { exit NR == 3 ? 0 : 1 }' "$artifact_file" ||
    fail 'expected three normalized artifact rows'
  awk -F '\t' 'NF != 3 { exit 1 } END { exit NR == 4 ? 0 : 1 }' "$artifact_process_file" ||
    fail 'expected four normalized artifact process rows'

  awk -F '\t' '
    $2 == "pid=1001+mnt=1002+net=1003+user=1004" &&
      $3 == "1001" &&
      $4 == "1002" &&
      $5 == "1003" &&
      $6 == "1004" &&
      $7 == "mixed" &&
      $8 == "3001" &&
      $9 == "-" &&
      $10 == "4001" &&
      $15 == "2" { found=1 }
    END { exit found ? 0 : 1 }
  ' "$artifact_file" ||
    fail 'expected single, mixed, and missing namespace aggregation values'

  awk -F '\t' '
    $2 == "pid=unknown:45+mnt=1002+net=1003+user=1004" &&
      $3 == "-" &&
      $4 == "1002" &&
      $5 == "1003" &&
      $6 == "1004" &&
      $7 == "-" &&
      $8 == "-" &&
      $9 == "-" &&
      $10 == "-" &&
      $15 == "1" { found=1 }
    END { exit found ? 0 : 1 }
  ' "$artifact_file" ||
    fail 'expected internal unknown group key without public unknown namespace values'

  awk -F '\t' '
    $2 == "42" && ($3 == "leader" || $3 == "member") { p42=1 }
    $2 == "43" && ($3 == "leader" || $3 == "member") { p43=1 }
    $2 == "44" && ($3 == "leader" || $3 == "member") { p44=1 }
    $2 == "45" && ($3 == "leader" || $3 == "member") { p45=1 }
    END { exit p42 && p43 && p44 && p45 ? 0 : 1 }
  ' "$artifact_process_file" ||
    fail 'expected complete artifact membership with normalized roles'

  rm -rf "$tmpdir"
}

run_artifact_leader_contract() {
  local tmpdir process_file artifact_file artifact_process_file host_profile_file

  tmpdir="$(mktemp -d)"
  process_file="${tmpdir}/process.tsv"
  artifact_file="${tmpdir}/artifact.tsv"
  artifact_process_file="${tmpdir}/artifact_process.tsv"
  host_profile_file="${tmpdir}/host_profile.tsv"
  nsurgn_join_by_tab 1 5001 5002 5003 5004 - - - - ok >"$host_profile_file"

  {
    make_process_row_for_leader 41 1001 10 2 ok
    make_process_row_for_leader 42 1001 20 1 ok
    make_process_row_for_leader 43 1001 1 3 ok
  } >"$process_file"
  nsurgn_scan_build_artifacts profile "$process_file" "$artifact_file" "$artifact_process_file" "$host_profile_file" ||
    fail 'nested-init artifact leader selection failed'
  awk -F '\t' '
    $13 == "42" && $14 == "1" && $19 == "nested-pid-init" { found=1 }
    END { exit found ? 0 : 1 }
  ' "$artifact_file" ||
    fail 'expected nested PID namespace init leader to win'
  awk -F '\t' '$2 == "42" && $3 == "leader" { found=1 } END { exit found ? 0 : 1 }' "$artifact_process_file" ||
    fail 'expected nested-init member role to be leader'

  {
    make_process_row_for_leader 51 5001 30 51 ok
    make_process_row_for_leader 52 5001 20 52 ok
    make_process_row_for_leader 53 5001 20 53 ok
  } >"$process_file"
  nsurgn_scan_build_artifacts profile "$process_file" "$artifact_file" "$artifact_process_file" "$host_profile_file" ||
    fail 'oldest-process artifact leader selection failed'
  awk -F '\t' '
    $13 == "52" && $14 == "52" && $19 == "oldest-process" { found=1 }
    END { exit found ? 0 : 1 }
  ' "$artifact_file" ||
    fail 'expected oldest process leader with host PID tie-break'
  awk -F '\t' '$2 == "52" && $3 == "leader" { found=1 } END { exit found ? 0 : 1 }' "$artifact_process_file" ||
    fail 'expected oldest-process member role to be leader'

  {
    make_process_row_for_leader 61 5001 - 61 ok
    make_process_row_for_leader 60 5001 - 60 permission-denied
    make_process_row_for_leader 59 5001 - 59 vanished
  } >"$process_file"
  nsurgn_scan_build_artifacts profile "$process_file" "$artifact_file" "$artifact_process_file" "$host_profile_file" ||
    fail 'lowest-host-pid artifact leader selection failed'
  awk -F '\t' '
    $13 == "60" && $14 == "60" && $19 == "lowest-host-pid" { found=1 }
    END { exit found ? 0 : 1 }
  ' "$artifact_file" ||
    fail 'expected lowest eligible host PID leader fallback'
  awk -F '\t' '
    $2 == "60" && $3 == "leader" { leader=1 }
    $2 == "59" && $3 == "leader" { vanished_leader=1 }
    END { exit leader && !vanished_leader ? 0 : 1 }
  ' "$artifact_process_file" ||
    fail 'expected fallback member role to ignore vanished process'

  rm -rf "$tmpdir"
}

restore_live_scan_state() {
  local previous_scan_dir="$1"
  local previous_host_pid="$2"
  local previous_host_pid_was_set="$3"

  NSURGN_SCAN_DIR="$previous_scan_dir"
  if [ "$previous_host_pid_was_set" -eq 1 ]; then
    NSURGN_HOST_PID="$previous_host_pid"
  else
    unset NSURGN_HOST_PID
  fi
}

fail_live_scan_workspace_contract() {
  local message="$1"
  local previous_scan_dir="$2"
  local previous_host_pid="$3"
  local previous_host_pid_was_set="$4"

  nsurgn_scan_cleanup
  restore_live_scan_state "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fail "$message"
}

run_live_scan_workspace_contract() {
  local scan_dir host_pid previous_scan_dir previous_host_pid host_profile_fields
  local previous_host_pid_was_set=0

  previous_scan_dir="${NSURGN_SCAN_DIR:-}"
  previous_host_pid=''
  if [ "${NSURGN_HOST_PID+x}" = x ]; then
    previous_host_pid="$NSURGN_HOST_PID"
    previous_host_pid_was_set=1
  fi
  host_pid="$$"
  NSURGN_HOST_PID="$host_pid"

  nsurgn_scan_run >/dev/null 2>/dev/null || {
    fail_live_scan_workspace_contract 'live scan workspace setup failed' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  }

  scan_dir="$NSURGN_SCAN_DIR"

  [ -d "$scan_dir" ] ||
    fail_live_scan_workspace_contract 'expected live scan workspace directory' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  [ -s "${scan_dir}/visible_pids.tsv" ] ||
    fail_live_scan_workspace_contract 'expected visible PID rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  [ -s "${scan_dir}/host_profile.tsv" ] ||
    fail_live_scan_workspace_contract 'expected host profile row' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  [ -s "${scan_dir}/process.tsv" ] ||
    fail_live_scan_workspace_contract 'expected process namespace rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  [ -s "${scan_dir}/artifact.tsv" ] ||
    fail_live_scan_workspace_contract 'expected artifact rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  [ -s "${scan_dir}/artifact_process.tsv" ] ||
    fail_live_scan_workspace_contract 'expected artifact process rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"

  if ! awk 'NF != 1 || $1 !~ /^[0-9]+$/ { exit 1 }' "${scan_dir}/visible_pids.tsv"; then
    fail_live_scan_workspace_contract 'visible PID workspace rows must be numeric' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fi

  if ! grep -Fx "$$" "${scan_dir}/visible_pids.tsv" >/dev/null; then
    fail_live_scan_workspace_contract 'expected current shell PID in live scan workspace' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fi

  host_profile_fields="$(awk -F '\t' 'NR == 1 { print NF } END { if (NR != 1) exit 1 }' "${scan_dir}/host_profile.tsv")" || {
    fail_live_scan_workspace_contract 'expected exactly one host profile row' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  }
  [ "$host_profile_fields" -eq 10 ] || {
    fail_live_scan_workspace_contract "expected 10 host profile fields, got ${host_profile_fields}" "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  }

  if ! awk -F '\t' 'NF != 31 { exit 1 } END { exit NR > 0 ? 0 : 1 }' "${scan_dir}/process.tsv"; then
    fail_live_scan_workspace_contract 'expected normalized process workspace rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fi
  if ! awk -F '\t' 'NF != 19 { exit 1 } END { exit NR > 0 ? 0 : 1 }' "${scan_dir}/artifact.tsv"; then
    fail_live_scan_workspace_contract 'expected normalized artifact workspace rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fi
  if ! awk -F '\t' 'NF != 3 { exit 1 } END { exit NR > 0 ? 0 : 1 }' "${scan_dir}/artifact_process.tsv"; then
    fail_live_scan_workspace_contract 'expected normalized artifact process workspace rows' "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
  fi

  nsurgn_scan_cleanup
  restore_live_scan_state "$previous_scan_dir" "$previous_host_pid" "$previous_host_pid_was_set"
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
run_process_limitation_contract
run_group_key_contract
run_artifact_aggregation_contract
run_artifact_leader_contract
run_live_scan_workspace_contract
run_shellcheck_if_available

printf 'ok - scaffold smoke tests passed\n'
