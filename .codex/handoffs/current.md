# Handoff Brief

## Objective

Continue v1.0 spec gap resolution after completing `SPEC_GAPS_PLAN.md` Chunk 1:
Evidence Foundation.

## Scope And Non-Goals

Scope:

- `SPEC_GAPS_PLAN.md` Chunk 2: Anomaly Determinism.
- Source slices: `GAP-1/S1`, `GAP-1/S2`, `GAP-1/S3`.
- Primary edit target: `SPEC.md` section 10.3.

Non-goals:

- Do not implement production Bash code.
- Do not add fixtures yet; `GAP-1/S4` belongs to later fixture work.
- Do not change score weights from `SPEC.md` section 10.2.

## Current State

Established source facts:

- `SPEC_GAPS_PLAN.md` is the active coordination artifact. `SPEC_GAPS.md` is
  deprecated but retained as the source gap inventory.
- Chunk 1 has been applied in `SPEC.md` section 10.5: the spec now has a
  normative evidence-matching table for v1.0 score and hint signals.
- `DESIGN.md` mount evidence reason-code examples were aligned to underscore
  identifiers used by the normative spec table.
- `SPEC_GAPS_PLAN.md` Chunk 1 now has a resolution summary.
- `SPEC.md` section 10.3 still defines `anomalous` with broad language and does
  not yet provide a finite v1.0 trigger table.

## Established Decisions And Traceability

Relevant completed Chunk 1 decisions:

- Cgroup keyword matches are case-sensitive and evaluated within path
  components after splitting on `/`.
- Lowercase hex container-like IDs use the component token regex
  `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`.
- Deleted executable evidence is based on raw `/proc/<pid>/exe` `readlink`
  values ending with `" (deleted)"`; display `exe_path` strips the suffix and
  reason detail preserves it.
- `unshare` evidence is limited to `comm=unshare`, first command argument
  basename `unshare`, or executable basename `unshare`.

Relevant next source requirements:

- `GAP-1/S1`: Define a finite v1.0 anomalous trigger table in `SPEC.md`
  section 10.3.
- `GAP-1/S2`: State unreadable metadata is a limitation by default, not
  anomalous evidence, except when combined with a specific v1.0 trigger.
- `GAP-1/S3`: Add spoofability handling for process metadata, cgroup paths, and
  runtime hints.

## Changed Artifacts

- `SPEC.md`
- `DESIGN.md`
- `SPEC_GAPS_PLAN.md`
- `.codex/handoffs/current.md`

## Checks And Evidence

Checks performed so far:

- `git diff --check` passed after the initial `SPEC.md` and `DESIGN.md` edit.

Checks still needed after this handoff update:

- Run `git diff --check` again.
- Run the repository smoke test if still available and relevant.

## Risks, Blockers, And Open Questions

Open Chunk 2 decisions:

- Exact finite anomalous trigger names and required evidence.
- Reason codes for anomalous triggers.
- Whether each trigger is artifact-scoped or process-scoped.
- Which near-miss cases must explicitly remain non-anomalous.

## Immediate Next Action And Owner

Owner: Unknown

Draft and apply the Chunk 2 `SPEC.md` section 10.3 finite anomalous trigger
table for `GAP-1/S1`, including trigger names, required evidence, reason codes,
scope, and examples.

## Resume Notes

Use `01-understand` for the anomaly rule clarification. Use `05-test` only when
the work moves from rule definition to fixture or acceptance-test planning.
