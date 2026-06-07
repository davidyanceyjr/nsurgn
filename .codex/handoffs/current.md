# Handoff Brief

## Objective
Continue resolving the remaining specification gaps in `SPEC_GAPS_PLAN.md` after
Gap 1, Gap 6, and Gap 7 were resolved.

## Scope And Non-Goals
Scope remains documentation/specification work in `SPEC.md`, `DESIGN.md`, and
`SPEC_GAPS_PLAN.md` unless the next worker deliberately chooses to inspect
implementation conformance. The gap plan tracks documentation/specification
gaps and does not define missing behavior by itself.

## Current State
Gap 1 is completed in `SPEC_GAPS_PLAN.md` and has normative coverage in:

- `SPEC.md` sections 9, 10.3, 10.5, 12.3, and 13.5.
- `DESIGN.md` sections 6.2, 9.3, and 10.

The Gap 1 decision is that artifact-level namespace values are aggregate values
per namespace type: a single known namespace ID, `mixed`, or missing.
Artifact-scoped classification, sorting, target detail, output summaries, and
`map` relationships use artifact-level namespace values. A `mixed` value does
not satisfy equality or difference tests and does not generate map
relationships. Member namespace profiles remain available for `inspect`, `ps`,
limitations, and process-scoped classification evidence. Raw, JSON, NDJSON, and
internal artifact records represent mixed artifact-level namespace values as
`mixed`.

Gap 6 is completed in `SPEC_GAPS_PLAN.md` and has normative coverage in
`SPEC.md` sections 15.4 and 15.5, and `DESIGN.md` section 10.

Gap 7 is completed in `SPEC_GAPS_PLAN.md` and has normative coverage in
`SPEC.md` sections 15.2, 15.3, and 21, and `DESIGN.md` sections 8.2, 8.3, 13,
and 14.

Remaining unresolved gaps are Gap 2 through Gap 5. The plan's suggested
resolution order starts with Gap 2 and Gap 3 together: per-field read
limitations and generic `partial` semantics.

## Changed Artifacts
- `SPEC.md`: Gap 1 mixed artifact namespace profile behavior, classification
  consequences, artifact ID sorting treatment, and `map` relationship
  suppression rules added.
- `DESIGN.md`: Gap 1 internal artifact namespace fields and raw inspect/report
  mixed namespace rendering rules added.
- `SPEC_GAPS_PLAN.md`: Gap 1 marked completed with resolution; suggested
  resolution order updated.
- `.codex/handoffs/current.md`: updated to this handoff.

## Checks And Evidence
- `git diff --check` passed.
- All `DESIGN.md` fenced `json` examples and `jsonl` NDJSON examples parse with
  Python's standard `json` module.
- Placeholder scan found no live `DESIGN.md` structured payload placeholders;
  remaining placeholder matches are historical text in `SPEC_GAPS_PLAN.md`.

## Risks, Blockers, And Open Questions
Gap 2 through Gap 5 remain unresolved and may require coordinated edits across
source-specific read statuses, `partial` semantics, hint aggregation, and host
root target failure behavior. Gap 1 now relies on source-specific status and
missing-value behavior that are partially represented in structured output but
still owned by the remaining Phase 1 gaps.

Ownership is not assigned in source material.

## Immediate Next Action And Owner
Owner: Unknown. Inspect `SPEC_GAPS_PLAN.md` Gap 2 and Gap 3 and the referenced
`SPEC.md` and `DESIGN.md` sections to identify the smallest patch for
source-specific read limitations and `partial` semantics.
