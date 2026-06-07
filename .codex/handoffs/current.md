# Handoff Brief

## Objective
Resolve GAP-01 through GAP-08 in the `nsurgn` v1.0 spec/design so implementation can proceed with deterministic model and output contracts.

## Current State
GAP-01 through GAP-08 are resolved in documentation only. The documentation diff was reviewed after resume, and no blocking internal consistency issue was found in the changed spec/design contracts.

The repository currently has no implementation files. `rg --files` found only:

- `AGENTS.md`
- `SPEC.md`
- `DESIGN.md`

## Key Decisions
- GAP-01/GAP-02: `host` means no known PID, mount, network, or user namespace difference from the host profile. Non-host labels require at least one known major namespace difference. Label precedence is `anomalous`, `container-like`, `namespace-managed`, `isolated`.
- GAP-03: `--group cgroup` derives exactly one key per visible PID from `/proc/<pid>/cgroup`: `cgroup:v2:<path>`, `cgroup:v1:<controllers>=<path>[;...]`, or `cgroup:unknown`. Cgroup grouping changes group identity only, not classification or default visibility.
- GAP-06: Leader selection is deterministic. Vanished processes are ineligible. Namespace PID comes from the last value in `NSpid:`. Reason values are `nested-pid-init`, `oldest-process`, and `lowest-host-pid`.
- GAP-07: Hints are single-valued summaries, not runtime identity claims. Raw/internal missing scalar is `-`; JSON/NDJSON missing scalar is `null`; readable no-hint is `none`. Canonical `runtime_hint` and `cgroup_hint` enums are listed in `SPEC.md` and `DESIGN.md`.
- GAP-04/GAP-05: Artifact IDs are assigned after visibility filtering. Sort order is score descending, classification rank, leader host PID, group key, then full namespace tuple. IDs are per-invocation only; scripts should not store them as durable references.
- GAP-08: Raw `inspect` and targeted `report` use `section	key	value`; multi-artifact `report` uses `artifact_id	section	key	value`. Repeated scalars repeat rows; repeated objects use one-based indexed keys.

## Changed Artifacts
- `SPEC.md`: sections 6.5, 9.6, 10, 10.5, 12.3, and 15.1 were updated.
- `DESIGN.md`: internal record notes, known enum values, artifact ID assignment note, and sections 9.3/9.4 raw detail contracts were updated.
- `.codex/handoffs/current.md`: updated after resume review.

## Validation Performed
- `git diff --check` passed after resume.
- Stale-term search found no source-doc instances for `containerd/k8s`, `Ambiguous Artifact`, `Same namespace profile`, `Isolation without runtime`, or `no longer exists`.
- Source scan confirmed no implementation files exist yet.

## Open Questions
- Owner for approving these spec/design decisions is not established in source artifacts.
- Implementation language, project scaffold, and test strategy are not established in source artifacts.

## Immediate Next Action And Owner
Owner: Unknown

Decide the initial implementation scaffold for `nsurgn` from `SPEC.md` and `DESIGN.md`.
