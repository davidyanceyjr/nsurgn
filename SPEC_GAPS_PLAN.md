# nsurgn v1.0 Spec Gap Resolution Plan

Status: Active plan
Created: 2026-06-07
Source: `SPEC_GAPS.md`

This plan replaces `SPEC_GAPS.md` as the active coordination artifact for
closing v1.0 blocking specification gaps. `SPEC_GAPS.md` is retained as the
source gap inventory and is deprecated for ongoing planning.

The plan is intentionally ordered by dependency, not by source-document order.
Behavioral spec decisions should be resolved before fixture and acceptance-test
work depends on them.

## Coverage Confirmation

All non-deprecated gap slices currently present in `SPEC_GAPS.md` are included
below.

| Source gap | Included slices |
|---|---|
| Gap 1: Anomaly Rules Are Not Testable | `GAP-1/S1`, `GAP-1/S2`, `GAP-1/S3`, `GAP-1/S4` |
| Gap 2: Evidence Matching Needs Exact Rules | `GAP-2/S1`, `GAP-2/S2`, `GAP-2/S3`, `GAP-2/S5`, `GAP-2/S6` |
| Gap 3: Explicit PID Targets Should Bypass Default Visibility Filters | `GAP-3/S1`, `GAP-3/S2`, `GAP-3/S3`, `GAP-3/S4` |
| Gap 4: Partial Metadata Exit Codes Need Per-Command Thresholds | `GAP-4/S1`, `GAP-4/S2`, `GAP-4/S3`, `GAP-4/S4` |
| Gap 5: JSON Escaping Needs Acceptance Fixtures | `GAP-6/S3`, `GAP-6/S4` |
| Gap 6: Map Relationship Semantics Are Underdefined | `GAP-7/S1`, `GAP-7/S2`, `GAP-7/S3`, `GAP-7/S4`, `GAP-7/S5`, `GAP-7/S6` |

Note: the source file has numbering drift. The JSON escaping heading is source
gap 5 but its slices are named `GAP-6/*`; the map heading is source gap 6 but
its slices are named `GAP-7/*`. Preserve these IDs unless a separate cleanup
renumbers the source inventory and all references together.

## Execution Boundaries

- Do not implement production code while resolving this plan.
- First tighten `SPEC.md` and `DESIGN.md`; only then add fixture and acceptance
  requirements.
- Keep each chunk independently reviewable.
- Use sub-agents only for read-only extraction or consistency checks with a
  narrow stop condition.
- After each chunk, summarize only decisions, changed sections, remaining open
  questions, and next chunk. Do not carry raw source text forward.
- If context reaches the 25% soft checkpoint, write a compact handoff to
  `.codex/handoffs/current.md` before continuing.

## Chunk 0: Tracking Cleanup

Objective: make the planning state explicit before behavior changes.

Scope:

- Keep `SPEC_GAPS.md` as deprecated source inventory.
- Use this file as the active plan.
- Preserve current gap IDs, including the `GAP-6` and `GAP-7` numbering drift,
  unless renumbering is explicitly requested.

Stop condition:

- Reviewers can identify the active plan and verify that every source gap slice
  is represented here.

## Chunk 6: Acceptance Fixture Plan

Objective: convert resolved behavior into fixture and acceptance coverage.

Status: resolved in `DESIGN.md` section 13.

Source slices:

- `GAP-1/S4`
- `GAP-3/S4`
- `GAP-4/S4`
- `GAP-6/S3`
- `GAP-6/S4`
- `GAP-7/S6`

Spec/design coverage:

- `DESIGN.md` section 13 defines acceptance fixture requirements for every
  anomalous trigger and near-miss.
- It defines targeted command fixtures for host-equivalent PID, minor-only
  cgroup grouped artifact, and hidden default artifact.
- It defines exit-code examples for unreadable `root`, `exe`, `mountinfo`,
  `cmdline`, `status`, and `cgroup`, plus vanished target and vanished
  non-target member cases.
- It defines JSON/NDJSON fixtures for quotes, backslashes, tabs, newlines,
  carriage returns, empty strings, missing values, ordinary printable command
  lines, and command-line NUL separators.
- It requires parseability checks for JSON documents and NDJSON streams using
  tools available in the test environment without adding production runtime
  dependencies.
- It defines map fixtures for shared network namespace, shared mount namespace,
  no shared major namespaces, hidden host-equivalent relationships, and
  targeted map output.

Dependencies:

- Chunk 1 evidence rules.
- Chunk 2 anomaly rules.
- `SPEC.md` section 12.4 target visibility rules.
- `SPEC.md` section 13.5 map semantics.
- `SPEC.md` section 16.3 exit-code materiality.

Stop condition:

- Each resolved behavior has at least one positive fixture and one important
  near-miss, failure, or visibility fixture where applicable.

## Recommended Work Order

1. Chunk 0: Tracking Cleanup.
2. Chunk 6: Acceptance Fixture Plan. Resolved in `DESIGN.md` section 13.

## Review Checklist

- Every active slice from `SPEC_GAPS.md` appears in the coverage table.
- Every fixture slice is deferred until the behavior it tests is defined.
- Map visibility depends on target visibility instead of duplicating separate
  rules.
- Exit-code materiality references command primary output instead of raw
  metadata availability alone.
- JSON/NDJSON parseability checks remain test requirements, not production
  runtime dependencies.
