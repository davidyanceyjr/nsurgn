# Handoff Brief

## Objective

Resume v1.0 spec gap resolution at `SPEC_GAPS_PLAN.md` Chunk 4: Map
Semantics. The bounded objective is to make `nsurgn map` output deterministic.

## Scope And Non-Goals

Scope:

- `SPEC_GAPS_PLAN.md` Chunk 4 only.
- Source slices: `GAP-7/S1`, `GAP-7/S2`, `GAP-7/S3`, `GAP-7/S4`, `GAP-7/S5`.
- Primary edit target: `SPEC.md` section 13.5.
- Secondary edit target if needed: `DESIGN.md` map output contracts and
  section 11.5 command-flow pseudocode.

Non-goals:

- Do not add fixtures yet; `GAP-7/S6` belongs to Chunk 6 fixture work.
- Do not implement production code.
- Do not revisit completed Chunk 1 evidence matching, Chunk 2 anomaly
  triggers, or Chunk 3 target visibility unless a direct contradiction blocks
  map semantics.

## Current State

Established source facts:

- `SPEC_GAPS_PLAN.md` is the active coordination artifact. `SPEC_GAPS.md` is
  retained as the deprecated source gap inventory.
- Completed Chunk 1, Chunk 2, and Chunk 3 plan sections have been removed from
  `SPEC_GAPS_PLAN.md` in the working tree. These removals are not committed.
- `SPEC_GAPS_PLAN.md` now shows Chunk 4 as the next active implementation
  slice after Chunk 0.
- `SPEC.md` section 12.4 now defines target resolution and visibility for
  `inspect`, `ps`, `report`, and `map`.
- `SPEC.md` section 12.4 states numeric PID and `pid:<pid>` targets resolve
  from the full visible process scan before default host hiding.
- `SPEC.md` section 12.4 states artifact ID targets resolve only against
  current-invocation post-filter assigned IDs.
- `SPEC.md` section 12.4 states `--include-host` broadens artifact visibility
  and ID assignment but does not change host PID target lookup.
- `SPEC.md` section 13.5 now states untargeted `map` uses `list` visibility,
  `--include-host` includes host-classified artifacts before ID assignment, and
  targeted `map` uses section 12.4 target resolution.
- `DESIGN.md` section 11 now reflects the Chunk 3 target-resolution flow for
  `inspect`, `ps`, `report`, and `map`.

Source gap facts for next chunk:

- `GAP-7/S1`: Define v1.0 relationship enum values.
- `GAP-7/S2`: Define namespace types that generate relationship rows.
- `GAP-7/S3`: Define relationship shape as pairwise artifact rows grouped by
  namespace ID.
- `GAP-7/S4`: Apply visibility rules from Chunk 3 to untargeted,
  `--include-host`, and targeted map output.
- `GAP-7/S5`: Define deterministic ordering for raw, JSON, and NDJSON output.

## Established Decisions And Traceability

Relevant completed decisions:

- Chunk 1 established deterministic v1.0 score and hint evidence matching in
  `SPEC.md` section 10.5.
- Chunk 2 established finite v1.0 anomaly triggers in `SPEC.md` section 10.3.
- Chunk 3 established target visibility rules in `SPEC.md` section 12.4 and
  aligned command/design references.

Relevant source locations:

- `SPEC_GAPS_PLAN.md` Chunk 4: objective, source slices, planned work,
  dependencies, optional sub-agent task, and stop condition.
- `SPEC_GAPS.md` Gap 6 / `GAP-7/*`: original map relationship source slices.
- `SPEC.md` section 13.5: current map command surface and visibility text.
- `DESIGN.md` map output contract sections and section 11.5 command flow.

## Changed Artifacts

- `SPEC.md`: added section 12.4 target-resolution rules; aligned cgroup
  visibility wording and command-specific target references.
- `DESIGN.md`: aligned target-capable command pseudocode with PID versus
  artifact ID target resolution.
- `SPEC_GAPS_PLAN.md`: removed completed Chunk 1, Chunk 2, and Chunk 3 active
  plan sections; updated recommended work order to start at Chunk 4.
- `.codex/handoffs/current.md`: overwritten with this handoff.

## Checks And Evidence

Commands run:

- `git diff --check` passed after Chunk 3 edits.
- `rg -n "targeted explicitly|artifact target|bypass default|full visible process scan|include-host|section 12\\.4|Chunk 3|Target Visibility" SPEC.md DESIGN.md SPEC_GAPS_PLAN.md .codex/handoffs/current.md`
  showed no stale `SPEC.md`, `DESIGN.md`, or `SPEC_GAPS_PLAN.md` target
  visibility wording after the edits; the old Chunk 3 references were only in
  the prior handoff before this update.

## Risks, Blockers, And Open Questions

Open Chunk 4 decisions to encode:

- Exact v1.0 map relationship enum values.
- Namespace types that generate relationship rows.
- Pairwise relationship record shape and identity fields.
- Self-relationship omission and duplicate suppression.
- Deterministic ordering for raw, JSON, and NDJSON map output.

## Immediate Next Action And Owner

Owner: Unknown

Draft and apply the `SPEC.md` section 13.5 relationship enum for `GAP-7/S1`.

## Resume Notes

Use `03-contract` only if the map record shape becomes the main work. Use
`05-test` only after moving from map rule definition to `GAP-7/S6` fixture
planning.
