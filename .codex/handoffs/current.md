# Handoff Brief

## Objective
Continue M3 artifact discovery work after implementing namespace group keys and artifact namespace aggregation.

## Current State
- Current branch is `m3-artifact-list`.
- `.codex/plans/m3-artifact-list-plan.md` defines scoped M3 slices through first raw `nsurgn list` output.
- M3.1 group key construction is implemented in `lib/scan.sh` for `profile`, `strict`, `pid`, `mnt`, and `net`.
- Group keys serialize namespace components as `type=value` joined by `+`; missing grouped namespace IDs use internal `unknown:<host-pid>` tokens.
- M3.2 artifact aggregation is implemented in `lib/scan.sh` for namespace-based grouping modes.
- `nsurgn_scan_run` now populates `artifact.tsv` and `artifact_process.tsv` for namespace grouping modes; `--group cgroup` remains parsed but artifact building is skipped until cgroup summary records exist.
- Artifact rows currently use internal placeholder IDs `G1`, `G2`, etc.; public `A*` IDs remain deferred to M3.5.
- Leader selection, scoring/classification, visibility sorting, public artifact IDs, and real `list` output are still not implemented.

## Changed Artifacts
- `lib/scan.sh`: adds grouping-mode namespace ordering, process namespace group-key construction, artifact namespace aggregation, artifact membership writing, and scan-time artifact file population.
- `test/smoke.sh`: adds direct group-key tests, direct artifact aggregation tests, and live scan artifact workspace field-count checks.
- `.codex/handoffs/current.md`: refreshed to make M3.3 the next continuation action.

## Checks And Evidence
- Ran `./test/smoke.sh`; result: `ok - scaffold smoke tests passed`.
- Smoke coverage now includes:
  - deterministic grouping orders for `profile`, `strict`, and single-namespace modes;
  - process-distinct unknown tokens for missing grouped namespace IDs;
  - missing ungrouped namespace IDs not affecting group identity;
  - artifact namespace aggregation for single known values, `mixed`, and all-missing values;
  - internal `unknown:<host-pid>` tokens not appearing in public artifact namespace fields;
  - complete placeholder artifact membership rows.

## Risks, Blockers, And Open Questions
- `--group cgroup` remains deferred until `process_cgroup_summary.tsv` exists.
- Internal placeholder artifact IDs are intentionally not public IDs and must be replaced or hidden before real renderer output.
- Artifact membership roles are all `member` until M3.3 selects leaders.
- `runtime_hint`, `cgroup_hint`, leader command, scoring, and classification fields remain placeholders.

## Immediate Next Action And Owner
Owner: Unknown. Implement M3.3 deterministic leader selection from `.codex/plans/m3-artifact-list-plan.md`.
