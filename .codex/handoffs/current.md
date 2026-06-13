# Handoff Brief

Handoff Status: active

## Objective
Continue after completing the first real raw `nsurgn list` output for M3.

## Current State
- Current branch is `m3-artifact-list`.
- `.codex/plans/m3-artifact-list-plan.md` defines scoped M3 slices through first raw `nsurgn list` output.
- M3.1 group key construction is complete for `profile`, `strict`, `pid`, `mnt`, and `net`.
- M3.2 artifact namespace aggregation is complete for namespace-based grouping modes.
- M3.3 deterministic leader selection is complete in `lib/scan.sh`.
- M3.4 minimal scoring and classification is complete in `lib/scan.sh`.
- M3.5 visibility filtering, deterministic artifact sorting, and command-scoped public `A*` IDs are complete in `lib/scan.sh`.
- M3.6 first real default raw `nsurgn list` output is complete in `lib/commands.sh`.
- `artifact.tsv` now populates namespace-only `classification`, `score`, `runtime_hint`, `cgroup_hint`, leader fields, and process counts.
- `classification_reason.tsv` now emits namespace difference reason rows and `nested_pid_init` reason rows.
- `visible_artifact.tsv` can be populated from `artifact.tsv` with default host hiding, `--include-host` visibility, spec-defined sort keys, and sequential `A*` IDs.
- `nsurgn list` now renders raw fields: `artifact_id`, `classification`, `score`, `leader_pid`, `leader_ns_pid`, `process_count`, `runtime_hint`, and `leader_command`.
- `runtime_hint` and `cgroup_hint` remain `-` until relevant metadata readers can prove hints or prove `none`.
- `leader_command` remains `-` until command/cmdline readers exist.
- `--group cgroup` remains parsed but artifact building is skipped until cgroup summary records exist.
- Internal placeholder artifact IDs `G1`, `G2`, etc. remain in `artifact.tsv`; public `A*` IDs are assigned in the command-scoped visible artifact view.
- `inspect`, `ps`, `report`, and `map` remain scaffolded not-implemented scan commands.

## Changed Artifacts
- `lib/scan.sh`: adds namespace score helpers, host-profile comparison for all namespace types, classification reason writing, namespace-only score calculation, and `host`/`isolated`/`namespace-managed` classification.
- `lib/scan.sh`: adds `visible_artifact.tsv` workspace creation and `nsurgn_scan_write_visible_artifacts` for M3.5 visibility, sorting, and public IDs.
- `lib/commands.sh`: routes `list` to `nsurgn_cmd_list`, keeps non-raw list formats not implemented, and renders default raw artifact rows.
- `test/smoke.sh`: adds direct classification smoke tests for host, minor-only host, isolated major namespace difference, nested PID namespace-managed classification, missing/mixed namespace values, visible artifact ID assignment, and raw `list` output.
- `.codex/plans/m3-artifact-list-plan.md`: marks M3.6 complete and updates current state.
- `.codex/handoffs/current.md`: refreshed for the next continuation action.

## Checks And Evidence
- Ran `bash -n lib/scan.sh test/smoke.sh`; result: passed.
- Ran `bash -n lib/commands.sh test/smoke.sh lib/scan.sh`; result: passed.
- Ran `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`; result: passed.
- Ran `./test/smoke.sh`; result: `ok - scaffold smoke tests passed`.
- Ran `./bin/nsurgn --host-pid $$ list`; result: exit `0`, empty stdout allowed, empty stderr.
- Ran `./bin/nsurgn --host-pid $$ --include-host list`; result: exit `0`, raw host rows on stdout, empty stderr.

## Risks, Blockers, And Open Questions
- Runtime/cgroup hints, command/cmdline rendering, cgroup grouping, and non-raw output formats remain deferred.
- Command/cmdline readers are not implemented, so `leader_command` renders `-`.
- Non-raw `list` formats remain intentionally not implemented.
- Targeted commands and relationship/report rendering remain deferred.

## Immediate Next Action And Owner
Owner: Unknown. Decide the next post-M3 slice from `.codex/plans/m3-artifact-list-plan.md` deferred follow-ups.
