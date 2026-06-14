# Handoff Brief

Handoff Status: stale

## Objective

Continue the post-M3 cgroup stage from pushed branch `m3-artifact-list` and decide the next integration step using `.codex/plans/post-m3-cgroup-and-metadata-plan.md` as the active plan.

## Scope And Non-Goals

Scope is cgroup-derived process and artifact evidence after M3 raw `list`: cgroup reader/summary records, `--group cgroup`, artifact-level cgroup/runtime hints, cgroup classification reasons, and cgroup stage finalization.

Non-goals remain runtime API dependencies, runtime identity claims, `inspect`/`ps`/`report`/`map` target behavior, mountinfo/root/exe/cmdline/comm readers, and renderer work beyond existing raw `list` behavior.

## Current State

- Current branch from `git status`: `m3-artifact-list...origin/m3-artifact-list`.
- Working tree has one uncommitted scratchpad update: `.codex/handoffs/current.md`.
- Latest commit: `9dad47d Add cgroup classification reasons`, pushed to `origin/m3-artifact-list`.
- Active plan: `.codex/plans/post-m3-cgroup-and-metadata-plan.md`, `Plan Status: active`.
- C1 procfs cgroup reader and summary: complete per active plan.
- C2 cgroup artifact grouping: complete per active plan.
- C3 artifact cgroup/runtime hint aggregation: complete per active plan.
- C4 cgroup classification reasons and labels: complete per active plan.
- C5 cgroup stage finalization: active plan still marks this `in progress`; after commit and push, the remaining integration action is not updated in the plan.

## Changed Artifacts

Commit `9dad47d` changed:

- `lib/scan.sh`: added cgroup classification reason matching from `process_cgroup.tsv`, cgroup selector score deltas, artifact-level cgroup reason deduplication, and cgroup selector label precedence.
- `test/smoke.sh`: added focused C4 coverage for kubepods, docker, container-id, machine.slice, duplicate cgroup reason suppression, host-equivalent cgroup evidence, and selector precedence.
- `.codex/plans/post-m3-cgroup-and-metadata-plan.md`: updated C1-C4 statuses to complete and C5 to in progress with validation evidence.
- `.codex/handoffs/current.md`: refreshed handoff state.

## Checks And Evidence

Checks performed before commit `9dad47d`:

- `bash -n lib/scan.sh test/smoke.sh`: passed.
- `./test/smoke.sh`: passed.
- `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`: passed.
- `./bin/nsurgn --host-pid $$ list`: passed, produced 0 visible rows.
- `./bin/nsurgn --host-pid $$ --include-host list`: passed, produced 197 rows.
- `./bin/nsurgn --host-pid $$ --group cgroup list`: passed, produced 0 visible rows.
- `./bin/nsurgn --host-pid $$ --include-host --group cgroup list`: passed, produced 34 rows.
- `git diff --check`: passed before commit.
- `git push origin m3-artifact-list`: succeeded, updating `5445e7b..9dad47d`.

## Risks, Blockers, and Open Questions ##

Risks:

- The active plan still says C5 remains in progress even though the commit and push portion has happened; if the branch is merged without updating the plan, future continuation may misread C5 as still needing commit/push work.
- Cgroup-stage validation was local only. No CI result, PR review result, or post-push remote check result is recorded in this handoff.

Blockers:

- No blocker is established by current validation.

Open Questions:

- Whether to merge `m3-artifact-list` into `main` now that commit `9dad47d` is pushed.
- Whether the next branch should focus narrowly on command metadata (`cmdline`/`comm`) or broader process metadata (`cmdline`/`comm`/`root`/`exe`).

## Immediate Next Action And Owner

Owner: Unknown. Decide whether to merge `m3-artifact-list` into `main`.
