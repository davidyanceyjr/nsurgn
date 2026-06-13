# Handoff Brief

Handoff Status: active

## Objective
Continue M3 artifact discovery work after completing minimal namespace-only scoring and classification.

## Current State
- Current branch is `m3-artifact-list`.
- `.codex/plans/m3-artifact-list-plan.md` defines scoped M3 slices through first raw `nsurgn list` output.
- M3.1 group key construction is complete for `profile`, `strict`, `pid`, `mnt`, and `net`.
- M3.2 artifact namespace aggregation is complete for namespace-based grouping modes.
- M3.3 deterministic leader selection is complete in `lib/scan.sh`.
- M3.4 minimal scoring and classification is complete in `lib/scan.sh`.
- `artifact.tsv` now populates namespace-only `classification`, `score`, `runtime_hint`, `cgroup_hint`, leader fields, and process counts.
- `classification_reason.tsv` now emits namespace difference reason rows and `nested_pid_init` reason rows.
- `runtime_hint` and `cgroup_hint` remain `-` until relevant metadata readers can prove hints or prove `none`.
- `leader_command` remains `-` until command/cmdline readers exist.
- `--group cgroup` remains parsed but artifact building is skipped until cgroup summary records exist.
- Internal placeholder artifact IDs `G1`, `G2`, etc. remain; public `A*` IDs are deferred to M3.5.
- Visibility filtering, sorting, public artifact IDs, and real `list` output are still not implemented.

## Changed Artifacts
- `lib/scan.sh`: adds namespace score helpers, host-profile comparison for all namespace types, classification reason writing, namespace-only score calculation, and `host`/`isolated`/`namespace-managed` classification.
- `test/smoke.sh`: adds direct classification smoke tests for host, minor-only host, isolated major namespace difference, nested PID namespace-managed classification, and missing/mixed namespace values.
- `.codex/plans/m3-artifact-list-plan.md`: marks M3.4 complete and updates current state.
- `.codex/handoffs/current.md`: refreshed for the next continuation action.

## Checks And Evidence
- Ran `bash -n lib/scan.sh test/smoke.sh`; result: passed.
- Ran `./test/smoke.sh`; result: `ok - scaffold smoke tests passed`.

## Risks, Blockers, And Open Questions
- No public command-scoped `A*` artifact IDs are assigned yet.
- Default host hiding and `--include-host` visibility behavior are not implemented yet.
- `list` still returns scaffolded not-implemented behavior after scan.
- Runtime/cgroup hints, command rendering, cgroup grouping, and non-raw output formats remain deferred.

## Immediate Next Action And Owner
Owner: Unknown. Implement M3.5 visibility filtering, stable artifact sorting, and command-scoped public artifact IDs from `.codex/plans/m3-artifact-list-plan.md`.
