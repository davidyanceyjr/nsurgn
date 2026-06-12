# Handoff Brief

## Objective
Resume implementation planning/execution for `nsurgn` M1/M2 using `PLAN` as the next-session scope.

## Scope And Non-Goals
Scope is limited to the implementation slices documented in `PLAN`:

- M1: help, version, doctor, and test harness.
- M2: PID validation and namespace reading.

Non-goals for the next session:

- Do not implement artifact grouping before M3.
- Do not implement artifact IDs, leader selection, scoring, classification, or real `list` output before M3.
- Do not broaden JSON/NDJSON renderer work beyond M1/M2 needs.
- Do not add cgroup grouping, mountinfo evidence, root comparison, or runtime hints in M2 except as missing future fields.

## Current State
Source facts from the current session:

- `SPEC.md` defines the v1.0 product behavior, milestones, CLI contract, output guarantees, error contract, and acceptance criteria.
- `DESIGN.md` defines the Bash implementation architecture, internal TSV workspace records, command flow, renderer contracts, structured output schemas, and fixture planning.
- `PLAN` now exists and is the intended next-session scope for M1/M2 implementation.
- Current scaffold includes `bin/nsurgn`, `lib/cli.sh`, `lib/commands.sh`, `lib/doctor.sh`, `lib/errors.sh`, `lib/scan.sh`, `lib/util.sh`, and `test/smoke.sh`.
- The scaffold already has CLI parsing, help/version/doctor dispatch, scan workspace setup, and not-implemented scan commands.
- `lib/scan.sh` already creates the intended internal TSV workspace files, including `process.tsv`, `artifact.tsv`, `artifact_process.tsv`, `classification_reason.tsv`, and `scan_limitation.tsv`.

Worktree state observed before this handoff:

- `.codex/handoffs/current.md` modified by this handoff update.
- `PLAN` is new and untracked.
- `DESIGN.md`, `lib/commands.sh`, `lib/util.sh`, and `test/smoke.sh` were already modified in the worktree; those changes were not inspected or changed as part of this handoff update.

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
Changed in this session:

- `PLAN`: added M1/M2 implementation plan.
- `.codex/handoffs/current.md`: replaced with this handoff brief.

Existing modified files not changed by this handoff update:

- `DESIGN.md`
- `lib/commands.sh`
- `lib/util.sh`
- `test/smoke.sh`

## Checks And Evidence
Read during this session:

- `PLAN`
- `SPEC.md`
- `DESIGN.md`
- `.codex/skills/06-document/SKILL.md`
- `.codex/skills/12-handoff/SKILL.md`

Commands/evidence:

- `git status --short` showed existing modified files plus new `PLAN`.
- No tests were run after creating `PLAN`.
- No production code was changed by this handoff request.

## Risks, Blockers, And Open Questions
Open questions carried in `PLAN`:

- Should M2 helper functions be split immediately or kept in `lib/scan.sh` until extraction is justified?
- Should ShellCheck be required in the test harness or only run opportunistically when installed?
- What is the cleanest test-only way to inspect the scan workspace without creating public debug output?

Known risk:

- M2 can expand quickly if cgroup, mountinfo, root, exe, renderer, grouping, or classification work is pulled in early. Keep M2 focused on PID enumeration, host profile reading, namespace reading, minimal process metadata, and internal limitations.

## Immediate Next Action And Owner
Owner: Unknown. Implement the first M1 slice from `PLAN`: CLI contract hardening for help/version/doctor/global-option usage behavior.

## Resume Notes
Before editing, re-check `git status --short` and inspect the existing modified files so user or prior-session changes are preserved. Use `PLAN` as the scope guard for next work.
