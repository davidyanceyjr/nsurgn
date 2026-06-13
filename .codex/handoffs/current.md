# Handoff Brief

## Objective
Resume `nsurgn` M1/M2 implementation from the next open slice: M2.5 Scan Limitations.

## Scope And Non-Goals
Scope remains limited to `PLAN`:

- M1: help, version, doctor, and test harness.
- M2: PID validation and namespace reading.

Non-goals remain:

- Do not implement artifact grouping before M3.
- Do not implement artifact IDs, leader selection, scoring, classification, or real `list` output before M3.
- Do not broaden JSON/NDJSON renderer work beyond M1/M2 needs.
- Do not add cgroup grouping, mountinfo evidence, root comparison, or runtime hints in M2 except as missing future fields.

## Current State
Source facts:

- `SPEC.md` remains the source of truth for v1.0 product behavior, CLI contract, output guarantees, error contract, and acceptance criteria.
- `PLAN` is the current M1/M2 implementation slice document.
- `main` is even with `origin/main`.
- Commit `89bcf25` (`m1: harden cli and doctor contracts`) was created and pushed to `origin/main`.
- Commit `67e2e07` (`dev: track m1 test harness completion`) was created and pushed to `origin/main`.
- `PLAN`, `lib/scan.sh`, `test/smoke.sh`, and `.codex/handoffs/current.md` are modified after commit `67e2e07`.
- M1.1, M1.2, M1.3, and M1.4 are marked completed in `PLAN` with commit evidence.
- M2.1 Proc PID Enumeration, M2.2 Namespace Link Reader, M2.3 Host Profile Reader, and M2.4 Minimal Process Metadata are marked completed in `PLAN` in the working tree after commit `67e2e07`.

Implementation claims established in the working tree:

- M2.1 is CODE COMPLETE: `lib/scan.sh` creates `visible_pids.tsv`, enumerates sorted numeric `/proc/<pid>` directories via `nsurgn_scan_enumerate_pids`, ignores non-process entries, and skips vanished entries.
- M2.2 is CODE COMPLETE: `lib/scan.sh` parses namespace IDs from values like `pid:[4026531836]`, reads `pid`, `mnt`, `net`, `user`, `uts`, `ipc`, `cgroup`, and `time` namespace links, represents missing namespace types as `-`, and tracks namespace read status as `ok`, `permission-denied`, or `vanished`.
- M2.3 is CODE COMPLETE: `lib/scan.sh` creates `host_profile.tsv`, reads host namespace baseline from `/proc/$NSURGN_HOST_PID/ns/*`, uses CLI-default PID `1` or parsed `--host-pid`, records fatal host-profile limitations, returns `3` for permission-denied host namespace reads, `7` for vanished host profile PID, and `8` for missing required host namespace links.
- M2.4 is CODE COMPLETE: `lib/scan.sh` reads `/proc/<pid>/status` for `PPid`, `Uid`, `State`, and `NSpid`, uses the last numeric `NSpid` as `ns_pid`, reads `/proc/<pid>/stat` field 22 as `start_time`, populates the M2 subset of `process.tsv`, and summarizes namespace/status/stat source statuses into `read_status`.
- Public scan commands remain scaffolded and return not-implemented when scan setup succeeds. Smoke tests use `--host-pid "$$"` for those scaffold assertions because this environment cannot read `/proc/1/ns`.

Open implementation slice:

- M2.5 Scan Limitations.

## Established Decisions And Traceability
Traceability:

- Use `SPEC.md` section 19 for milestone boundaries.
- Use `SPEC.md` sections 6.2, 6.3, 7, 8, 9, and 16.3 for M2 scan semantics.
- Use `DESIGN.md` sections 2-6 and 11 for module boundaries, workspace files, and command flow.
- Use `PLAN` as the immediate implementation slice document.

Established boundary:

- M2 should stop before grouping. M3 should begin with group key construction, artifact-level namespace aggregation, deterministic leader selection, scoring/classification minimum, and first real `nsurgn list` raw output.

## Changed Artifacts
Committed and pushed:

- `lib/doctor.sh`: completed M1.2 doctor contract implementation.
- `test/smoke.sh`: added M1.1/M1.2 contract coverage.
- `test/smoke.sh`: added focused M1.3 TSV escaping and physical-line coverage, tightened M1 usage-error checks to assert stderr-only diagnostics, and added optional ShellCheck execution when installed.

Modified after push:

- `PLAN`: updated M1.3/M1.4 commit evidence and marked M2.1/M2.2/M2.3/M2.4 completed in the working tree.
- `lib/scan.sh`: added `visible_pids.tsv`, `host_profile.tsv`, `NSURGN_NAMESPACE_TYPES`, PID enumeration, namespace ID parsing, namespace profile reading, host profile validation, limitation writing, status/stat metadata readers, M2 process row population, and scan-run population of visible PID, host profile, and process records.
- `test/smoke.sh`: sources scan helpers and covers fake-proc PID enumeration, namespace ID parsing, namespace profile reading, vanished process profile status, status/stat metadata parsing, M2 process row shape, invalid `--host-pid`, host profile default and override reads, and host profile fatal exit mappings.
- `.codex/handoffs/current.md`: this resume handoff.

## Checks And Evidence
Validation performed after M2.4 working-tree changes:

- `test/smoke.sh` passed.
- `bash -n bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh` passed.
- `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh` passed.
- `git diff --check` passed.

Working tree evidence at handoff creation:

- `git status --short --branch` reported `## main...origin/main` with modified `.codex/handoffs/current.md`, `PLAN`, `lib/scan.sh`, and `test/smoke.sh`.
- `git diff --stat` reported 4 changed files.

## Risks, Blockers, And Open Questions
Open questions carried in `PLAN`:

- Should M2 helper functions be split immediately or kept in `lib/scan.sh` until extraction is justified?
- Should ShellCheck be required in the test harness or only run opportunistically when installed?
- What is the cleanest test-only way to inspect the scan workspace without creating public debug output?

Known risk:

- M2 can expand quickly if cgroup, mountinfo, root, exe, renderer, grouping, or classification work is pulled in early. Keep M2 focused on PID enumeration, host profile reading, namespace reading, minimal process metadata, and internal limitations.

## Immediate Next Action And Owner
Owner: Unknown. Implement M2.5 Scan Limitations from `PLAN`.

## Resume Notes
Before further implementation, verify current truth from `git status --short`, `git diff`, `PLAN`, `lib/scan.sh`, and `test/smoke.sh`. Do not repeat M1, M2.1, M2.2, M2.3, or M2.4 unless new requirements or regressions are found.
