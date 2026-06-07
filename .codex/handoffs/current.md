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
- Do not define exit-code materiality; that is Chunk 5.
- Do not revisit completed Chunk 1 evidence matching, Chunk 2 anomaly
  triggers, or Chunk 3 target visibility unless a direct contradiction blocks
  map semantics.

## Current State

Established source facts:

- Current branch is `main`, tracking `origin/main`.
- Latest pushed commit before this handoff was `9d1d304 Clarify target
  visibility rules`.
- `SPEC_GAPS_PLAN.md` is the active coordination artifact. `SPEC_GAPS.md` is
  retained as the deprecated source gap inventory.
- Completed Chunk 1, Chunk 2, and Chunk 3 plan sections have been removed from
  `SPEC_GAPS_PLAN.md`.
- `SPEC_GAPS_PLAN.md` now shows Chunk 4 as the next active implementation
  slice after Chunk 0.
- `SPEC_GAPS_PLAN.md` has an uncommitted maintenance edit replacing later
  dependency references to "Chunk 3 target visibility rules" with
  "`SPEC.md` section 12.4 target visibility rules."
- `SPEC.md` section 12.4 defines target resolution and visibility for
  `inspect`, `ps`, `report`, and `map`.
- `SPEC.md` section 13.5 currently gives only high-level `map` behavior plus
  Chunk 3 visibility wording. It does not define relationship enum values,
  namespace-type scope, pairwise shape, duplicate suppression, or deterministic
  ordering.
- `DESIGN.md` has a JSON `relationship` object example with fields
  `left_artifact_id`, `relationship`, `namespace_type`, `namespace_id`,
  `right_artifact_id`, and `detail`, but the normative map semantics are not
  fully defined in `SPEC.md`.

Source gap facts for Chunk 4:

- `GAP-7/S1`: Define v1.0 relationship enum values. Source recommendation:
  use `shares-namespace`; use `differs-namespace` only if the map view
  intentionally emits contrast rows.
- `GAP-7/S2`: Define namespace types included in map generation. Source
  recommendation: emit relationship rows for PID, mount, network, and user
  namespaces by default; include UTS, IPC, cgroup, and time only when required
  by the map contract or grouping mode.
- `GAP-7/S3`: Define relationship shape as pairwise artifact rows grouped by
  namespace ID, omit self-relationships, and suppress duplicates by
  `(left_artifact_id, relationship, namespace_type, namespace_id,
  right_artifact_id)`.
- `GAP-7/S4`: Apply the target visibility rules from `SPEC.md` section 12.4 to
  untargeted, `--include-host`, and targeted map output.
- `GAP-7/S5`: Define deterministic ordering for raw, JSON, and NDJSON:
  namespace type order, namespace ID bytewise, left artifact sort order, right
  artifact sort order, relationship enum order, then detail bytewise.

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
- `DESIGN.md` section 10.3: JSON command document for `map` and the current
  `relationship` object example.
- `DESIGN.md` section 11.5: current `map` command-flow pseudocode.

## Changed Artifacts

- `SPEC_GAPS_PLAN.md`: uncommitted maintenance edit replacing completed Chunk 3
  dependency wording with references to `SPEC.md` section 12.4.
- `.codex/handoffs/current.md`: overwritten with this handoff.

No Chunk 4 implementation edits have been made yet.

## Checks And Evidence

Commands run while preparing this handoff:

- `git status --short --branch` showed `## main...origin/main` plus modified
  `SPEC_GAPS_PLAN.md`.
- `sed -n '60,115p' SPEC_GAPS_PLAN.md`
- `sed -n '245,275p' SPEC_GAPS.md`
- `sed -n '990,1040p' SPEC.md`
- `sed -n '620,845p' DESIGN.md`
- `git diff -- SPEC_GAPS_PLAN.md`

Checks from the previous Chunk 3 commit:

- `git diff --check` passed.
- `test/smoke.sh` passed with `ok - scaffold smoke tests passed`.

## Risks, Blockers, And Open Questions

Open Chunk 4 decisions to encode:

- Whether v1.0 should emit only `shares-namespace` rows or also
  `differs-namespace` contrast rows.
- Exact namespace-type inclusion rule for major namespaces versus minor
  namespaces.
- Exact raw, JSON, and NDJSON record ordering after artifact visibility and ID
  assignment.
- Whether `DESIGN.md` relationship object examples need to change after the
  normative `SPEC.md` rule is written.

## Immediate Next Action And Owner

Owner: Unknown

Draft and apply the `SPEC.md` section 13.5 relationship enum for `GAP-7/S1`.

## Resume Notes

Use `03-contract` only if defining the map record shape becomes the main work.
Use `05-test` only after moving from map rule definition to `GAP-7/S6` fixture
planning.
