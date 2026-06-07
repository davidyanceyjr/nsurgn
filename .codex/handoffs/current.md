# Handoff Brief

## Objective
Resume the remaining specification gap work in `SPEC_GAPS_PLAN.md` after Gap 6
and Gap 7 were resolved.

## Scope And Non-Goals
Scope remains documentation/specification work in `SPEC.md`, `DESIGN.md`, and
`SPEC_GAPS_PLAN.md` unless the next worker deliberately chooses to inspect
implementation conformance. The gap plan tracks documentation/specification
gaps and does not define missing behavior by itself.

## Current State
Gap 6 is completed in `SPEC_GAPS_PLAN.md` and has normative coverage in:

- `SPEC.md` sections 15.4 and 15.5.
- `DESIGN.md` section 10.

The Gap 6 decision is that raw, JSON, and NDJSON are strict public contracts for
`list`, `inspect`, `ps`, `report`, and `map`; `doctor`, `version`, and `help`
structured schemas remain optional for v1.0 unless implemented. Structured
common types and command documents now define required fields, missing scalar
values use `null`, known no-hint values use `none`, mixed artifact-level
namespace values use `mixed`, and source-specific read statuses are carried in
process and limitation objects.

Gap 7 is completed in `SPEC_GAPS_PLAN.md` and has normative coverage in:

- `SPEC.md` sections 15.2, 15.3, and 21.
- `DESIGN.md` sections 8.2, 8.3, 13, and 14.

The Gap 7 decision is that `table` and `text` are stable human output modes, not
stable parse formats. v1.0 defines minimum facts by command, leaves exact layout
non-contractual, and directs scripts to raw, JSON, or NDJSON.

Remaining unresolved gaps are Gap 1 through Gap 5. The plan's suggested
resolution order starts with Gap 1, artifact namespace profile behavior for
mixed groups.

## Changed Artifacts
- `SPEC.md`: Gap 7 table/text output contract and Gap 6 JSON/NDJSON strict
  contract summary added.
- `DESIGN.md`: Gap 7 renderer guidance and Gap 6 structured common types,
  command documents, and NDJSON records added.
- `SPEC_GAPS_PLAN.md`: Gap 6 and Gap 7 marked completed with resolutions.
- `.codex/handoffs/current.md`: updated to this handoff.

## Checks And Evidence
- `git diff --check` passed.
- All `DESIGN.md` fenced `json` examples and `jsonl` NDJSON examples parse with
  Python's standard `json` module.
- Placeholder object scan found no live `DESIGN.md` structured payload
  placeholders; the only remaining `{}` match is historical text in
  `SPEC_GAPS_PLAN.md` describing the replaced placeholders.

## Risks, Blockers, And Open Questions
Gap 1 through Gap 5 remain unresolved and may require coordinated edits across
classification, grouping, read status, hint, and host root semantics. Gap 6
mentions `mixed` and source-specific statuses as structured representations,
but the underlying behavior for those facts is still owned by the remaining
Phase 1 gaps.

Ownership is not assigned in source material.

## Immediate Next Action And Owner
Owner: Unknown. Inspect `SPEC_GAPS_PLAN.md` Gap 1 and the referenced `SPEC.md`
and `DESIGN.md` sections to identify the smallest patch for mixed artifact
namespace profile behavior.
