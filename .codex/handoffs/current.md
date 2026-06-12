# Handoff Brief

## Objective
Tighten three pre-implementation issues in `nsurgn` v1.0 docs/scaffold before starting the next implementation milestone.

## Scope And Non-Goals
Scope is limited to the three points identified during the `SPEC.md` readiness review:

- Normalize the raw escaping contract between `SPEC.md` and `DESIGN.md`.
- Fix inaccurate mountinfo/mount-evidence cross-references in `DESIGN.md`.
- Align the scan workspace scaffold with the file names and files listed in `DESIGN.md`.

Non-goal: do not begin M2 implementation work until these three tightening items are handled.

## Current State
`SPEC.md` was reviewed for v1 implementation readiness. The conclusion from the prior session was that implementation can start, but the three tightening items above should be addressed first.

Relevant source facts:

- `SPEC.md` defines the public v1.0 contract, including output modes, exit codes, classification, grouping, target resolution, milestones, and acceptance criteria.
- `DESIGN.md` defines internal scan records, renderer contracts, structured schemas, command flow, and fixture planning.
- Current scaffold is Bash-based and includes `bin/nsurgn`, `lib/*.sh`, and `test/smoke.sh`.
- Current scan scaffold creates `scan_warning.tsv`; `DESIGN.md` expects `scan_limitation.tsv`.
- Existing smoke test currently expects `list` to return exit `1` because scan commands are scaffolded/not implemented.

## Established Decisions And Traceability
Implementation should start after the tightening pass at `SPEC.md` milestone M2: PID validation and namespace reading.

The tightening plan from the prior session:

1. Update `SPEC.md` raw escaping to include backslash escaping, matching `DESIGN.md` section 8.1.
2. Fix inaccurate `DESIGN.md` references around mountinfo/mount evidence. Use correct references for mount evidence/classification, command output requirements, and local detailed mount parser/summary behavior.
3. Update scan workspace scaffold from `scan_warning.tsv` to `scan_limitation.tsv` and create the full intended internal TSV set from `DESIGN.md`.

## Changed Artifacts
No files were changed after the readiness review except this handoff file.

Existing repository files to inspect next:

- `SPEC.md`
- `DESIGN.md`
- `lib/scan.sh`
- `test/smoke.sh`

## Checks And Evidence
Prior session inspected:

- `SPEC.md`
- `DESIGN.md`
- `bin/nsurgn`
- `lib/cli.sh`
- `lib/commands.sh`
- `lib/doctor.sh`
- `lib/errors.sh`
- `lib/scan.sh`
- `lib/util.sh`
- `test/smoke.sh`
- `git status --short --branch`

Observed branch state at that time: `main...origin/main` with no local diff shown by `git diff -- SPEC.md DESIGN.md lib/scan.sh lib/util.sh lib/cli.sh lib/commands.sh lib/errors.sh lib/doctor.sh test/smoke.sh bin/nsurgn`.

Re-verify current truth before editing because the working tree may have changed.

## Risks, Blockers, And Open Questions
Open question: the exact replacement cross-reference wording in `DESIGN.md` should be verified against current line numbers/section headings before editing.

Risk: changing workspace files before implementation may require adjusting future tests. Keep the change narrow and update smoke/unit expectations only if they directly inspect the workspace.

## Immediate Next Action And Owner
Owner: Unknown. Re-open `SPEC.md`, `DESIGN.md`, and `lib/scan.sh` to verify the three tightening targets against the current working tree.

## Resume Notes
Use `06-document` for the doc edits and `04-build` only if modifying scaffold code in `lib/scan.sh` or tests. Preserve existing user work; do not reset or revert unrelated changes.
