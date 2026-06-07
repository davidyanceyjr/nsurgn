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

## Chunk 1: Evidence Foundation

Objective: make score and hint evidence matching deterministic.

Source slices:

- `GAP-2/S1`
- `GAP-2/S2`
- `GAP-2/S3`
- `GAP-2/S5`
- `GAP-2/S6`

Planned spec/design work:

- Add a normative evidence-matching table to `SPEC.md` section 10.5.
- For each evidence signal, define searched field, match rule, case
  sensitivity, emitted reason code, score delta, and hint effect.
- Define the long lowercase hex ID rule as a path-component rule.
- Define cgroup and runtime keyword case sensitivity.
- Define deleted executable detection using `/proc/<pid>/exe` `readlink`
  behavior.
- Define accepted `unshare`-style metadata patterns for `comm`, `cmdline`, and
  `exe_path`.

Dependencies:

- None. This is the lowest-level blocker.

Optional sub-agent:

- Read-only task: inspect `SPEC.md` scoring/hint language and return a compact
  proposed evidence-matching matrix plus any contradictions. Do not make
  behavior decisions beyond the source text.

Stop condition:

- Every v1.0 score or hint signal referenced by these slices can be matched
  deterministically and can emit a stable reason code.

Resolution summary:

- `SPEC.md` section 10.5 now contains a normative evidence-matching table for
  v1.0 score and hint signals.
- The table defines searched fields, match rules, case sensitivity, stable
  reason codes, score deltas, and hint effects.
- Cgroup matching is defined as case-sensitive matching within path components;
  the lowercase hex container ID rule is a path-component token regex.
- Deleted executable detection is defined from the raw `/proc/<pid>/exe`
  `readlink` suffix `" (deleted)"`, with display fields stripping the suffix
  and reason detail preserving it.
- `unshare`-style evidence is limited to accepted `comm`, first-argument
  `cmdline`, and executable basename matches.
- `DESIGN.md` mount evidence reason-code examples now use the same underscore
  identifier style as the normative spec table.

## Chunk 2: Anomaly Determinism

Objective: make `anomalous` classification testable.

Source slices:

- `GAP-1/S1`
- `GAP-1/S2`
- `GAP-1/S3`

Planned spec/design work:

- Add a finite v1.0 anomalous trigger table to `SPEC.md` section 10.3.
- For each trigger, define trigger name, required evidence, reason code,
  artifact/process scope, and example.
- State that unreadable metadata is a limitation by default, not anomalous
  evidence.
- State that unreadable metadata can set `anomalous` only when combined with a
  specific v1.0 trigger.
- Define spoofability handling for process metadata, cgroup paths, and runtime
  hints.

Dependencies:

- Chunk 1 reason-code and evidence-source decisions.

Stop condition:

- Every anomaly path has deterministic required evidence, and important
  near-misses are clear enough to turn into fixtures.

Resolution summary:

- `SPEC.md` section 10.3 now defines the finite v1.0 anomaly trigger table for
  `anomalous` classification.
- Each trigger defines required evidence, stable reason code, artifact/process
  scope, and an example.
- The `anomalous` label glossary and scoring table now point to the finite
  trigger table instead of broad "hard-to-explain" language.
- Unreadable metadata is specified as a limitation by default and cannot satisfy
  anomaly evidence requirements unless a future trigger explicitly allows that
  metadata state.
- Spoofable process metadata, cgroup paths, command lines, executable names,
  and runtime hints may contribute reasons, score, and hints, but cannot create
  an anomaly without a namespace or filesystem inconsistency.

## Chunk 3: Target Visibility

Objective: define how explicit targets interact with default host hiding.

Source slices:

- `GAP-3/S1`
- `GAP-3/S2`
- `GAP-3/S3`

Planned spec/design work:

- Add a command-level target visibility rule for `inspect`, `ps`, `report`, and
  `map`.
- Define explicit host PID targets as resolving from the full visible scan,
  bypassing default host hiding.
- Define artifact ID targets as post-filter only.
- Define `--include-host` as affecting broad artifact visibility and ID
  assignment, not changing explicit PID target resolution.

Dependencies:

- None for target rules.

Stop condition:

- Numeric PID, `pid:<pid>`, and `A<N>` resolution behavior is unambiguous for
  all target-capable commands.

## Chunk 4: Map Semantics

Objective: make `nsurgn map` output deterministic.

Source slices:

- `GAP-7/S1`
- `GAP-7/S2`
- `GAP-7/S3`
- `GAP-7/S4`
- `GAP-7/S5`

Planned spec/design work:

- Define v1.0 relationship enum values.
- Define namespace types that generate relationship rows.
- Define relationship shape as pairwise artifact rows grouped by namespace ID.
- Omit self-relationships.
- Suppress duplicates using the specified relationship identity fields.
- Apply visibility rules from Chunk 3 to untargeted, `--include-host`, and
  targeted map output.
- Define deterministic ordering for raw, JSON, and NDJSON output.

Dependencies:

- Chunk 3 target visibility rules.

Optional sub-agent:

- Read-only task: inspect `SPEC.md` section 13.5 and `DESIGN.md` map output
  contracts, then return only contradictions, missing fields, and ordering
  requirements.

Stop condition:

- Raw, JSON, and NDJSON map records can be generated in a stable order from a
  fixed scan result.

## Chunk 5: Exit-Code Materiality

Objective: define when missing metadata affects command exit status.

Source slices:

- `GAP-4/S1`
- `GAP-4/S2`
- `GAP-4/S3`

Planned spec/design work:

- Add a command-by-command materiality matrix to `SPEC.md` section 16.3.
- For each command, define required metadata for primary output.
- Define optional metadata that becomes warnings or limitation rows.
- Define metadata absence that can cause `partial-success`.
- Define metadata absence that can cause `permission-denied` or
  `process-changed`.
- Define broad scan behavior for `list` and untargeted `report`.
- Define targeted behavior for `inspect`, `ps`, `report <target>`, and
  `map <target>`.

Dependencies:

- Chunk 3 target visibility rules.
- Existing command primary-output definitions in `SPEC.md` section 13.

Stop condition:

- For each command, missing `root`, `exe`, `mountinfo`, `cmdline`, `status`,
  and `cgroup` metadata can be classified as success with limitation,
  partial-success, permission-denied, process-changed, or target-not-found by
  rule.

## Chunk 6: Acceptance Fixture Plan

Objective: convert resolved behavior into fixture and acceptance coverage.

Source slices:

- `GAP-1/S4`
- `GAP-3/S4`
- `GAP-4/S4`
- `GAP-6/S3`
- `GAP-6/S4`
- `GAP-7/S6`

Planned spec/design work:

- Add acceptance fixture requirements for every anomalous trigger and near-miss.
- Add targeted command fixtures for host-equivalent PID, minor-only cgroup
  grouped artifact, and hidden default artifact.
- Add exit-code examples for unreadable `root`, `exe`, `mountinfo`, `cmdline`,
  `status`, and `cgroup`, plus vanished target and vanished non-target member
  cases.
- Add JSON/NDJSON fixtures for quotes, backslashes, tabs, newlines, carriage
  returns, empty strings, missing values, ordinary printable command lines, and
  command-line NUL separators.
- Add parseability checks for JSON documents and NDJSON streams using only
  tools allowed by the test environment.
- Add map fixtures for shared network namespace, shared mount namespace, no
  shared major namespaces, hidden host-equivalent relationships, and targeted
  map output.

Dependencies:

- Chunk 1 evidence rules.
- Chunk 2 anomaly rules.
- Chunk 3 target visibility rules.
- Chunk 4 map semantics.
- Chunk 5 exit-code materiality.

Stop condition:

- Each resolved behavior has at least one positive fixture and one important
  near-miss, failure, or visibility fixture where applicable.

## Recommended Work Order

1. Chunk 0: Tracking Cleanup.
2. Chunk 1: Evidence Foundation.
3. Chunk 2: Anomaly Determinism.
4. Chunk 3: Target Visibility.
5. Chunk 4: Map Semantics.
6. Chunk 5: Exit-Code Materiality.
7. Chunk 6: Acceptance Fixture Plan.

## Review Checklist

- Every active slice from `SPEC_GAPS.md` appears in the coverage table.
- Every fixture slice is deferred until the behavior it tests is defined.
- Map visibility depends on target visibility instead of duplicating separate
  rules.
- Exit-code materiality references command primary output instead of raw
  metadata availability alone.
- JSON/NDJSON parseability checks remain test requirements, not production
  runtime dependencies.
