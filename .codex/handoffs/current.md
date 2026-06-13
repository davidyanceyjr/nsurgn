# Handoff Brief

Handoff Status: active

## Objective
Continue M3 artifact discovery work after completing deterministic leader selection.

## Current State
- Current branch is `m3-artifact-list`.
- `.codex/plans/m3-artifact-list-plan.md` defines scoped M3 slices through first raw `nsurgn list` output.
- M3.1 group key construction is complete for `profile`, `strict`, `pid`, `mnt`, and `net`.
- M3.2 artifact namespace aggregation is complete for namespace-based grouping modes.
- M3.3 deterministic leader selection is complete in `lib/scan.sh`.
- `nsurgn_scan_build_artifacts` now reads the host PID namespace from `host_profile.tsv`, prefers nested PID namespace init candidates, then lowest known `start_time`, then lowest eligible host PID.
- `artifact.tsv` now populates `leader_pid`, `leader_ns_pid`, and `leader_reason`; `leader_command` remains `-` until command/cmdline readers exist.
- `artifact_process.tsv` now marks the selected member as `leader` and other members as `member`.
- `--group cgroup` remains parsed but artifact building is skipped until cgroup summary records exist.
- Internal placeholder artifact IDs `G1`, `G2`, etc. remain; public `A*` IDs are deferred to M3.5.
- Scoring, classification, visibility sorting, public artifact IDs, and real `list` output are still not implemented.

## Changed Artifacts
- `lib/scan.sh`: adds host PID namespace lookup, per-group leader tracking, deterministic leader field population, and leader/member role writing.
- `test/smoke.sh`: adds direct leader-selection smoke tests for nested PID namespace init, oldest-process selection with host PID tie-break, and lowest-host-PID fallback while ignoring vanished members.
- `.codex/plans/m3-artifact-list-plan.md`: marks M3.3 complete and updates current state.
- `.codex/handoffs/current.md`: refreshed for the next continuation action.

## Checks And Evidence
- Ran `bash -n lib/scan.sh test/smoke.sh`; result: passed.
- Ran `./test/smoke.sh`; result: `ok - scaffold smoke tests passed`.
- Smoke coverage now includes:
  - nested PID namespace init winning over older process and lower host PID;
  - oldest known `start_time` winning when no nested PID init candidate exists;
  - equal `start_time` tie broken by lowest host PID;
  - missing `start_time` fallback to lowest eligible host PID;
  - vanished process excluded from leader eligibility;
  - leader role written to `artifact_process.tsv`.

## Risks, Blockers, And Open Questions
- `leader_command` is intentionally still missing because command/cmdline readers are not implemented yet.
- No `classification_reason.tsv` rows are emitted yet.
- `runtime_hint`, `cgroup_hint`, `classification`, and `score` remain placeholders.
- Public command-scoped artifact IDs and real raw `list` output remain deferred.

## Immediate Next Action And Owner
Owner: Unknown. Implement M3.4 minimal scoring and classification from `.codex/plans/m3-artifact-list-plan.md`.
