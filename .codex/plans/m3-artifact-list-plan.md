# M3 Artifact Grouping And List Plan

Plan Status: deprecated

Do not use this file as the active continuation plan. The active continuation plan is:

- `.codex/plans/post-m3-cgroup-and-metadata-plan.md`

## Archived Outcome

M3 covered the first artifact-backed raw `nsurgn list` milestone:

- namespace-based artifact grouping,
- artifact namespace aggregation,
- deterministic leader selection,
- namespace-only scoring and classification,
- visibility filtering and per-invocation artifact IDs,
- default raw `nsurgn list` output.

The detailed M3 implementation checklist was intentionally removed from this file to avoid future agents loading stale planning context. Use git history if the old slice-by-slice notes are needed.

## Current Continuation

Post-M3 work now lives in `.codex/plans/post-m3-cgroup-and-metadata-plan.md`.

That active plan owns cgroup-derived process and artifact evidence, `--group cgroup`, cgroup-derived hints, cgroup classification reasons, merge criteria for the current branch, and the next branch split after the cgroup stage.
