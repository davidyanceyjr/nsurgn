# Handoff Brief

## Objective
Resume `nsurgn` M1/M2 implementation using `PLAN` as the scope guard, without repeating completed M1 work.

## Scope And Non-Goals
Scope remains limited to the implementation slices documented in `PLAN`:

- M1: help, version, doctor, and test harness.
- M2: PID validation and namespace reading.

Non-goals remain:

- Do not implement artifact grouping before M3.
- Do not implement artifact IDs, leader selection, scoring, classification, or real `list` output before M3.
- Do not broaden JSON/NDJSON renderer work beyond M1/M2 needs.
- Do not add cgroup grouping, mountinfo evidence, root comparison, or runtime hints in M2 except as missing future fields.

## Current State
Source facts:

- `PLAN` is the current M1/M2 implementation slice document.
- `SPEC.md` remains the source of truth for v1.0 product behavior, CLI contract, output guarantees, error contract, and acceptance criteria.
- Commit `89bcf25` (`m1: harden cli and doctor contracts`) was created and pushed to `origin/main`.
- Commit `89bcf25` changed `lib/doctor.sh` and `test/smoke.sh`.
- M1.1 CLI Contract Hardening is marked completed in `PLAN` with commit evidence.
- M1.2 Doctor Contract is marked completed in `PLAN` with commit evidence.
- M1.3 Output Utility Baseline is marked completed in `PLAN` with working-tree evidence.
- M1.4 Test Harness is marked completed in `PLAN` with working-tree evidence.
- `PLAN`, `test/smoke.sh`, and `.codex/handoffs/current.md` are modified after the pushed commit to record progress, add M1.3/M1.4 coverage, and refresh this handoff.

Completed implementation claims from the prior session:

- M1.1 was reported CODE COMPLETE after hardening smoke coverage for help/version stdout, usage-error stderr/exit behavior, arity checks, invalid options, and scaffolded scan command diagnostics.
- M1.2 was reported CODE COMPLETE after tightening `doctor` checks for `/proc`, `/proc/self/ns` symlink readability, required utilities, root/non-root reporting, process visibility, stdout rows, stderr warning/error diagnostics, and unsupported-platform exit behavior.

Open implementation slices:

- M2.1 Proc PID Enumeration.

## Established Decisions And Traceability
Traceability:

- Use `SPEC.md` section 19 for milestone boundaries.
- Use `SPEC.md` sections 13.6-13.8 and 16.3 for M1 behavior.
- Use `SPEC.md` sections 6.2, 6.3, 7, 8, 9, and 16.3 for M2 scan semantics.
- Use `DESIGN.md` sections 2-6 and 11 for module boundaries, workspace files, and command flow.
- Use `PLAN` as the immediate implementation slice document.

Established boundary:

- M2 should stop before grouping. M3 should begin with group key construction, artifact-level namespace aggregation, deterministic leader selection, scoring/classification minimum, and first real `nsurgn list` raw output.

## Changed Artifacts
Committed and pushed:

- `lib/doctor.sh`: completed M1.2 doctor contract implementation.
- `test/smoke.sh`: added M1.1/M1.2 contract coverage.

Modified after push:

- `PLAN`: added completion status lines for M1.1, M1.2, M1.3, and M1.4.
- `test/smoke.sh`: added focused M1.3 TSV escaping and physical-line coverage, tightened M1 usage-error checks to assert stderr-only diagnostics, and added optional ShellCheck execution when installed.
- `.codex/handoffs/current.md`: refreshed handoff state.

## Checks And Evidence
Validation performed before commit `89bcf25`:

- `test/smoke.sh` passed.
- `bash -n lib/doctor.sh test/smoke.sh` passed.
- `shellcheck -x lib/doctor.sh test/smoke.sh` passed.

Validation performed after M1.3 working-tree changes:

- `test/smoke.sh` passed.
- `bash -n lib/util.sh test/smoke.sh` passed.
- `shellcheck -x lib/util.sh test/smoke.sh` passed.

Validation performed after M1.4 working-tree changes:

- `test/smoke.sh` passed.
- `bash -n bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh` passed.
- `git diff --check` passed.

Git evidence:

- `89bcf25 m1: harden cli and doctor contracts` is on `main` and was pushed to `origin/main`.

## Risks, Blockers, And Open Questions
Open questions carried in `PLAN`:

- Should M2 helper functions be split immediately or kept in `lib/scan.sh` until extraction is justified?
- Should ShellCheck be required in the test harness or only run opportunistically when installed?
- What is the cleanest test-only way to inspect the scan workspace without creating public debug output?

Known risk:

- M2 can expand quickly if cgroup, mountinfo, root, exe, renderer, grouping, or classification work is pulled in early. Keep M2 focused on PID enumeration, host profile reading, namespace reading, minimal process metadata, and internal limitations.

## Immediate Next Action And Owner
Owner: Unknown. Implement M2.1 Proc PID Enumeration from `PLAN`.

## Resume Notes
Before further implementation, check `git status --short`; `PLAN`, `test/smoke.sh`, and `.codex/handoffs/current.md` contain post-`89bcf25` working-tree changes. Do not repeat M1 unless new requirements or regressions are found.
