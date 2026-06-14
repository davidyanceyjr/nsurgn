# Handoff Brief

Handoff Status: active

## Objective

Finish the post-M3 cgroup stage on branch `m3-artifact-list`, using `.codex/plans/post-m3-cgroup-and-metadata-plan.md` as the active plan.

## Scope And Non-Goals

Scope is cgroup-derived process and artifact evidence after M3 raw `list`: cgroup reader/summary records, `--group cgroup`, artifact-level cgroup/runtime hints, cgroup classification reasons, and cgroup stage finalization.

Non-goals remain runtime API dependencies, runtime identity claims, `inspect`/`ps`/`report`/`map` target behavior, mountinfo/root/exe/cmdline/comm readers, and renderer work beyond the existing raw `list` behavior.

## Current State

- Current branch from `git status`: `m3-artifact-list...origin/m3-artifact-list`.
- C1 procfs cgroup reader and summary: complete per active plan.
- C2 cgroup artifact grouping: complete per active plan.
- C3 artifact cgroup/runtime hint aggregation: complete per active plan.
- C4 cgroup classification reasons and labels: complete per active plan.
- C5 cgroup stage finalization: in progress; remaining work is final diff review, commit, and merge flow.
- Working tree has modified `.codex/handoffs/current.md`, `.codex/plans/post-m3-cgroup-and-metadata-plan.md`, `lib/scan.sh`, and `test/smoke.sh`.

## Changed Artifacts

- `lib/scan.sh`: added cgroup classification reason matching from `process_cgroup.tsv`, cgroup selector score deltas, artifact-level cgroup reason deduplication, and cgroup selector label precedence.
- `test/smoke.sh`: added focused C4 coverage for kubepods, docker, container-id, machine.slice, duplicate cgroup reason suppression, host-equivalent cgroup evidence, and selector precedence.
- `.codex/plans/post-m3-cgroup-and-metadata-plan.md`: updated C1-C4 statuses to complete and C5 to in progress with validation evidence.
- `.codex/handoffs/current.md`: refreshed active handoff.

## Checks And Evidence

- `bash -n lib/scan.sh test/smoke.sh`: passed.
- `./test/smoke.sh`: passed.
- `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`: passed.
- `./bin/nsurgn --host-pid $$ list`: passed, produced 0 visible rows.
- `./bin/nsurgn --host-pid $$ --include-host list`: passed, produced 197 rows.
- `./bin/nsurgn --host-pid $$ --group cgroup list`: passed, produced 0 visible rows.
- `./bin/nsurgn --host-pid $$ --include-host --group cgroup list`: passed, produced 34 rows.

## Risks, Blockers, And Open Questions

- Open question from the active plan: whether the next branch should focus narrowly on command metadata (`cmdline`/`comm`) or broader process metadata (`cmdline`/`comm`/`root`/`exe`).
- No blocker is established by current validation.

## Immediate Next Action And Owner

Owner: Unknown. Review the final working-tree diff for unrelated or accidental changes.
