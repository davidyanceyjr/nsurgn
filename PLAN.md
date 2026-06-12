# Spec/Design Gap Resolution Plan

## Purpose

Resolve the current `SPEC.md` and `DESIGN.md` gaps in small, reviewable slices
so implementation can proceed against finite contracts.

## Scope

This plan covers documentation-contract work only:

- `SPEC.md`
- `DESIGN.md`
- follow-up validation against the documented contracts

It does not inspect or change production code, tests, or runtime behavior.

## Slice 1: Canonical Evidence Workspace Records

Status: Resolved in `DESIGN.md`.

### Objective

Add internal workspace record contracts for cgroup paths, parsed mountinfo, and
mount summaries.

### Findings Covered

- Internal cgroup path records are missing.
- Internal mountinfo and mount summary records are missing.

### Document Changes

- In `DESIGN.md` section 5, add the new workspace files to the scan workspace
  file list.
- In `DESIGN.md` section 6, add canonical tab-separated record contracts for:
  - parsed cgroup lines or process cgroup paths
  - parsed mountinfo rows, if retained after parsing
  - per-artifact or per-leader mount summaries
- Define field order, missing value handling, source read status linkage, and
  which records feed grouping, scoring, hints, inspect, report, JSON, and NDJSON.

### Decisions Required

- Whether cgroup records are process-scoped only, artifact-scoped only, or both.
- Whether mount summaries are derived for every member process or only the
  selected leader/target process.
- Whether parsed mountinfo rows are persisted in the workspace or only reduced
  to mount summary records.

### Stop Condition

`DESIGN.md` names every internal record needed to derive cgroup group keys,
cgroup path output, cgroup hints, mount-derived hints, mount summaries, and
related limitations without reparsing from unrelated renderers.

### Resolution

- Added `process_cgroup.tsv`, `process_cgroup_summary.tsv`,
  `process_mountinfo.tsv`, and `process_mount_summary.tsv` to the scan
  workspace.
- Defined process-scoped cgroup path rows and cgroup summary rows as the source
  for `--group cgroup`, cgroup hints, runtime hints, scoring, classification
  reasons, and cgroup path output.
- Defined parsed mountinfo rows and mount summary rows as the source for
  mount-derived hints, classification reasons, and public mount summaries.

### Validation

- `rg` confirms cgroup path and mount summary consumers have an internal source.
- `git diff --check` passes.

## Slice 2: Limitation Contract Normalization

Status: Resolved in `DESIGN.md`.

### Objective

Normalize limitation shape across internal records, raw output, JSON, and NDJSON.

### Findings Covered

- `scan_warning.tsv` omits `source` and `read_status` while structured
  `scan_limitation` requires them.

### Document Changes

- Rename or redefine `scan_warning.tsv` in `DESIGN.md` as the canonical internal
  limitation record.
- Include `severity`, `code`, `pid`, `path`, `source`, `read_status`, and
  `message` consistently, with allowed missing values.
- Align raw `limitation` rows, JSON `scan_limitation`, NDJSON limitation records,
  and stderr warning behavior with the same source fields.

### Decisions Required

- Whether non-warning limitation severities are valid in v1.0.
- Whether stderr warnings are rendered from the same limitation records or from
  a separate warning-only projection.

### Stop Condition

Every limitation-producing source has one canonical internal representation, and
all public formats are documented as projections from it.

### Resolution

- Renamed the internal workspace file from `scan_warning.tsv` to
  `scan_limitation.tsv`.
- Defined one canonical limitation row shape with `severity`, `code`, `pid`,
  `path`, `source`, `read_status`, and `message`.
- Kept v1.0 limitation severities finite as `warning` and `error`.
- Defined stderr scan warnings as a warning-only projection from
  `scan_limitation.tsv`; direct fatal and usage errors may still be emitted
  before a scan workspace exists.
- Aligned raw `limitation` rows with JSON `scan_limitation` objects and NDJSON
  `limitation` records by carrying the same source and read-status fields.

### Validation

- Search for `scan_warning`, `scan_limitation`, `limitation`, `source`, and
  `read_status` and confirm the contracts no longer conflict.
- `git diff --check` passes.

## Slice 3: Finite Classification Predicates

Status: Resolved in `SPEC.md` and `DESIGN.md`.

### Objective

Make `container-like` and `namespace-managed` label selection finite and
implementation-ready.

### Findings Covered

- Label selection is not deterministic enough for implementation.

### Document Changes

- In `SPEC.md` section 10.3, replace open-ended label prose with finite
  predicates for `container-like` and `namespace-managed`.
- Tie each predicate to existing evidence codes, source fields, and known
  metadata states.
- Keep existing precedence: `anomalous`, `container-like`,
  `namespace-managed`, `isolated`.
- In `DESIGN.md`, ensure `classification_reason.tsv`, JSON, and NDJSON examples
  can represent each finite predicate.

### Decisions Required

- Which exact cgroup, mountinfo, runtime, filesystem, process, and namespace
  evidence codes select `container-like`.
- Which exact evidence codes select `namespace-managed` when higher-precedence
  labels do not apply.
- Whether `machine.slice` is always container-like evidence, namespace-managed
  evidence, or depends on accompanying namespace facts.

### Stop Condition

For a fixed scan result, each non-host artifact has exactly one primary label
without relying on phrases such as "strong evidence" or "host-managed patterns."

### Resolution

- Replaced open-ended `container-like` and `namespace-managed` label prose with
  finite selector predicates in `SPEC.md` section 10.3.
- Defined `container-like` selectors as runtime cgroup keyword, cgroup
  container-ID, overlay/snapshotter mountinfo, and Kubernetes mountinfo reason
  codes.
- Defined `namespace-managed` selectors as nested PID init,
  nested-PID-init-without-runtime, `machine.slice`, and exact `unshare`
  metadata reason codes.
- Decided `cgroup_machine_slice` is namespace-managed evidence by itself, not
  container-like evidence. Higher-precedence anomaly or container-like
  selectors still control the primary label when present.
- Updated `DESIGN.md` so `classification_reason.tsv`, raw evidence rows, JSON,
  and NDJSON can carry every selector reason code, and added acceptance fixture
  coverage for selectors and precedence.

### Validation

- Review the classification section against the scoring table and evidence table.
- Confirm all label-selecting evidence can be emitted as classification reasons.
- `git diff --check` passes.

## Slice 4: Missing Namespace Group-Key Semantics

Status: Resolved in `SPEC.md` and `DESIGN.md`.

### Objective

Define how missing namespace IDs participate in grouping keys.

### Findings Covered

- Missing namespace values in grouping keys are underspecified.

### Document Changes

- In `SPEC.md` section 9, define group-key formation when one or more namespace
  IDs are missing for `profile`, `strict`, `pid`, `mnt`, and `net`.
- State whether missing values coalesce, remain process-distinct, or use a
  source-specific fallback.
- Align artifact-level namespace aggregation, sorting, map relationship behavior,
  and limitation behavior with the chosen rule.
- In `DESIGN.md`, update `artifact.tsv` and any grouping engine notes if needed.

### Decisions Required

- Whether all missing values for the same grouping mode share one group key.
- Whether a process with a missing grouped namespace ID can be grouped with a
  process whose corresponding namespace ID is known.
- Whether missing grouped namespace IDs should emit limitations that affect exit
  codes for each command.

### Stop Condition

An implementer can construct the same group key for every visible PID, including
partial namespace reads, without inference outside the spec.

### Resolution

- Defined namespace-based group-key construction for missing grouped namespace
  IDs in `SPEC.md` section 9.
- Missing grouped namespace IDs use an internal process-distinct
  `unknown:<host-pid>` group-key component.
- Missing grouped namespace IDs do not coalesce with known namespace IDs or with
  other missing values from different host PIDs.
- Missing ungrouped namespace IDs do not affect group identity.
- Public artifact-level namespace fields still use missing values, not internal
  unknown tokens.
- Internal unknown group-key tokens do not participate in map relationship
  generation.
- Missing grouped namespace IDs emit limitations when the source failure is
  known and affects grouping, sorting, target resolution detail, map
  relationships, or namespace explanation; exit-code impact follows the
  existing command materiality rules.
- Updated `DESIGN.md` `artifact.tsv` `group_key` semantics and acceptance
  fixture coverage.

### Validation

- Check `SPEC.md` sections 9, 12.3, 12.4, and map relationship rules for
  consistency.
- `git diff --check` passes.

## Slice 5: Host-PID Target Artifact ID Semantics

Status: Complete in `SPEC.md` and `DESIGN.md`.

### Objective

Define artifact ID behavior for host PID targets that resolve hidden artifacts.

### Findings Covered

- Host-PID target command flow does not explicitly assign artifact IDs even
  though target records include `artifact_id`.

### Document Changes

- In `SPEC.md` section 12.4, define whether a host PID target that resolves a
  hidden artifact receives an `artifact_id` in targeted output.
- If it receives an ID, define the visibility set and sort order used for that
  targeted invocation.
- If it does not receive an ID, update raw, JSON, and NDJSON target contracts to
  allow a missing artifact ID for host PID target output.
- Mirror the decision in `DESIGN.md` target resolution, inspect/report/map raw
  contracts, JSON, and NDJSON examples.

### Decisions Required

- Whether targeted host PID output uses full-scan artifact ID assignment,
  target-only synthetic ID assignment, or missing artifact IDs.
- Whether `--include-host` changes the artifact ID shown for the same host PID
  target.

### Stop Condition

`inspect`, `ps`, `report`, and `map` have one documented artifact ID behavior
for host PID targets, including hidden artifacts.

### Resolution

- Defined host PID targets as using a target-scoped output artifact set.
- Assigned the resolved host PID target artifact `A1` for targeted output,
  including when the artifact is hidden from default broad output.
- Defined `--include-host` as not changing the target artifact ID for the same
  host PID target.
- Defined targeted `map` peer artifact IDs as assigned after the target artifact
  using normal artifact sort among peers visible to the command's visibility
  mode.
- Kept artifact ID targets on the existing visibility-filtered ID assignment
  path; they do not use target-scoped assignment.
- Mirrored the decision in `DESIGN.md` raw target records, JSON
  `target_resolution`, targeted `map` semantics, command flows, and acceptance
  fixture coverage.

### Validation

- Search all `target_resolution`, `target artifact_id`, and host PID target
  examples for consistency.
- `git diff --check` passes.

## Slice 6: Cross-Format Consistency Pass

Status: Resolved in `SPEC.md`, `DESIGN.md`, and this plan.

### Objective

Verify the updated contracts are consistent across raw, JSON, NDJSON, and human
output descriptions.

### Findings Covered

- All findings after slices 1-5, as an integration pass.

### Document Changes

- Update examples whose fields changed because of slices 1-5.
- Ensure required field lists match example objects and raw records.
- Add or adjust acceptance fixture rows in `DESIGN.md` for the resolved gaps.

### Decisions Required

- None expected. Any new unresolved contract issue should become a new finding
  instead of being silently resolved in this pass.

### Stop Condition

The docs describe one coherent v1.0 contract for scan workspace records,
classification, grouping, target resolution, and public output formats.

### Resolution

- Added an explicit structured `cgroup_path` common type in `DESIGN.md` and
  aligned NDJSON `cgroup_path` records to use it.
- Clarified that JSON `artifact_detail.cgroup_paths` contains `cgroup_path`
  objects backed by `process_cgroup.tsv`.
- Clarified `map` relationship endpoint ordering as current-invocation artifact
  ID assignment so host PID targeted `map` keeps the target artifact as `A1`
  while peer artifacts are assigned after it.
- Rechecked limitation, cgroup, mount, classification, grouping, and target
  contracts across raw, JSON, NDJSON, and human-output descriptions.

### Validation

- `git diff --check` passes.
- `rg` checks show no stale names or contradictory field lists.
- A reader can trace each public cgroup, mount, limitation, classification,
  grouping, and target field back to a documented internal or source record.

## Suggested Order

1. Slice 1, because cgroup and mount records feed grouping, scoring, hints, and
   output.
2. Slice 2, because later slices need one limitation shape for missing or
   unreadable metadata.
3. Slice 3, because finite classification depends on the evidence contracts.
4. Slice 4, because grouping semantics affect artifact IDs and visibility.
5. Slice 5, because target artifact ID behavior depends on grouping and
   visibility semantics.
6. Slice 6, because examples and cross-format contracts should be checked after
   the substantive decisions are made.
