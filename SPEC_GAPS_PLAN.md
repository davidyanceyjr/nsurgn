# nsurgn v1.0 Specification Gaps Plan

## Purpose

This file tracks unresolved specification and design gaps that block deterministic
downstream design, implementation, and acceptance testing for `nsurgn` v1.0.

Scope is limited to `SPEC.md` and `DESIGN.md`. This plan records open decisions;
it does not define the missing behavior itself.

## Resolved Context

- The former `root_path` ambiguity has been resolved in `SPEC.md` and
  `DESIGN.md`.
- `root_path` now means the procfs symlink path `/proc/<pid>/root`.
- `root_target` now means the readable `readlink` value of `root_path`.
- Root equality, root difference scoring, and root-based anomaly triggers use
  `root_target`.

## Remaining Gaps

### 1. Artifact Namespace Profile For Mixed Groups

Status: completed in `SPEC.md` sections 9, 10.3, 10.5, 12.3, and 13.5, and
`DESIGN.md` sections 6.2, 9.3, and 10.

Problem: `--group profile` has a coherent artifact namespace profile because it
groups by PID, mount, network, and user namespaces. Other grouping modes can
produce artifacts whose member processes have differing namespace IDs in fields
outside the grouping key.

Affected modes include:

- `--group pid`
- `--group mnt`
- `--group net`
- `--group cgroup`

Blocking question: when an artifact contains mixed namespace values, what
namespace profile is used by classification, renderers, target resolution, and
relationship output?

Candidate decisions to make:

- Use leader process namespace values.
- Use aggregate or mixed values.
- Split artifact namespace profile from member namespace profiles.
- Define which grouping modes can produce mixed profiles and how output marks
  that state.

Resolution:

- Artifact-level namespace values are aggregate values per namespace type:
  single known namespace ID, `mixed`, or missing.
- `--group strict` constrains every namespace type to a single value or missing.
  `--group profile` constrains PID, mount, network, and user namespaces, while
  minor namespace types may be `mixed`. `--group pid`, `mnt`, `net`, and
  `cgroup` can produce mixed values outside their grouping key.
- Artifact-scoped classification, sorting, target detail, output summaries, and
  `map` relationships use artifact-level namespace values. A `mixed` value does
  not satisfy equality or difference tests and does not generate map
  relationships.
- Member namespace profiles remain available for `inspect`, `ps`, limitations,
  and process-scoped classification evidence.
- Raw, JSON, NDJSON, and internal artifact records represent mixed
  artifact-level namespace values explicitly as `mixed`.

Source areas:

- `SPEC.md` section 9, grouping modes.
- `SPEC.md` section 10, classification and scoring.
- `SPEC.md` section 12, target resolution and artifact IDs.
- `DESIGN.md` section 6, internal TSV records.

### 2. Per-Field Read Limitations

Problem: `process.tsv` has one `read_status`, but process data comes from many
independently readable sources.

Sources include:

- namespace links
- `status`
- `stat`
- `cmdline`
- `comm`
- `cgroup`
- `root`
- `exe`
- `mountinfo`

Blocking question: how should v1.0 represent which specific source was missing,
unreadable, partial, or affected by process churn?

Candidate decisions to make:

- Add per-source read status fields.
- Keep one aggregate `read_status` and add limitation rows for every source.
- Define command-specific materiality using source-specific limitation records.

Source areas:

- `DESIGN.md` section 6.1, `process.tsv`.
- `DESIGN.md` section 10, structured output contracts.
- `SPEC.md` section 16.3, metadata materiality and exit codes.

### 3. `partial` Read Semantics

Problem: `read_status` allows `partial`, but only `mountinfo_read_status=partial`
has concrete operational semantics.

Blocking question: which proc readers can emit `partial`, and what exact
condition produces it?

Candidate decisions to make:

- Restrict `partial` to `mountinfo`.
- Define `partial` for multi-field readers such as `status`.
- Remove `partial` from generic process read status and represent partial
  source reads through source-specific statuses.

Source areas:

- `DESIGN.md` section 6.1, `process.tsv`.
- `DESIGN.md` section 9.3, mountinfo parser behavior.
- `SPEC.md` section 16.3, exit-code materiality.

### 4. Hint `none` Versus Missing

Problem: hints use `none` when relevant metadata was readable and no known hint
was found, and `-` or `null` when unavailable. Runtime hints can come from mixed
sources with mixed readability.

Hint sources include:

- cgroup paths
- mountinfo
- command line
- comm
- executable path

Blocking question: when some hint sources are readable and others are not, when
should an artifact hint be `none` versus missing?

Candidate decisions to make:

- Define hint availability per source and aggregate hint state.
- Treat `none` as valid only when all relevant hint sources were readable.
- Allow `none` when at least one source was readable and no hint matched, while
  exposing unreadable sources as limitations.

Source areas:

- `SPEC.md` section 10.5, hint sources and precedence.
- `DESIGN.md` section 6, process and artifact records.
- `DESIGN.md` section 10, JSON and NDJSON output examples.

### 5. Host-Profile Root Target Failure Behavior

Problem: namespace host profile source is defined as `/proc/1/ns/*` or
`--host-pid`, but root comparison rules require a readable host-profile
`root_target`.

Blocking question: what happens when the host root target is unreadable, the
host PID vanishes, or `--host-pid` lacks root metadata?

Candidate decisions to make:

- Define the host root source for default and `--host-pid` cases.
- Define whether unreadable host root disables all root comparison evidence.
- Define limitation rows and exit-code materiality for host root failures.

Source areas:

- `SPEC.md` section 6.4, host profile.
- `SPEC.md` section 6.6, target root.
- `SPEC.md` section 10.3, anomaly triggers.
- `SPEC.md` section 16.3, metadata materiality.

### 6. JSON And NDJSON Completeness

Status: completed in `SPEC.md` sections 15.4 and 15.5, and `DESIGN.md`
section 10.

Problem: `DESIGN.md` gives schema examples and common types, but some command
objects and detail arrays are placeholders or illustrative. Structured output
acceptance is blocked unless completeness is defined or explicitly deferred.

Blocking question: are full JSON and NDJSON schemas required for v1.0 now, or
are raw output contracts the only strict acceptance target for the current
milestone?

Candidate decisions to make:

- Fully specify JSON and NDJSON required fields per command.
- Mark selected objects as illustrative and exclude them from acceptance tests.
- Define a milestone boundary for raw output first, then structured output.

Resolution:

- Raw, JSON, and NDJSON are strict public contracts for `list`, `inspect`,
  `ps`, `report`, and `map`.
- `doctor`, `version`, and `help` structured schemas remain optional for v1.0
  unless an implementation chooses to emit structured output for them.
- `DESIGN.md` section 10 now defines required fields for structured common
  types and command documents, and replaces placeholder NDJSON payload objects
  with concrete records.
- Missing scalars use `null`, known no-hint values use `none`, mixed
  artifact-level namespace values use the string `mixed`, and source-specific
  read statuses are carried in structured process and limitation objects.

Source areas:

- `DESIGN.md` section 10, JSON and NDJSON output contracts.
- `DESIGN.md` section 14, acceptance fixture plan.
- `SPEC.md` section 14, output modes.

### 7. Human `table` And `text` Contracts

Status: completed in `SPEC.md` sections 15.2, 15.3, and 21, and `DESIGN.md`
sections 8.2, 8.3, 13, and 14.

Problem: human `table` and `text` modes are required, but minimum fields and
layout constraints are loose. Contract tests need a stable acceptance boundary.

Blocking question: what minimum fields are required for `table` and `text`
modes, and are exact layouts part of the public v1.0 contract?

Candidate decisions to make:

- Define exact table columns and text sections for each command.
- Define only minimum fields and leave formatting non-contractual.
- Treat raw, JSON, and NDJSON as strict contracts while table/text remain
  human-oriented best-effort output.

Resolution:

- `table` and `text` are stable human output modes, not stable parse formats.
- v1.0 defines minimum required facts by command.
- Exact spacing, wrapping, width, section order, prose wording, and layout are
  non-contractual.
- Scripts and repeatable workflows must use raw, JSON, or NDJSON.
- Acceptance fixtures validate required facts, stdout/stderr separation, and
  readability without exact human-layout snapshots.

Source areas:

- `SPEC.md` section 14, output modes.
- `SPEC.md` section 13, command behavior.
- `DESIGN.md` section 10, stdout output contracts.

## Suggested Resolution Order

1. Resolve per-field read limitations and generic `partial` semantics together.
2. Resolve hint aggregation semantics.
3. Resolve host root target failure behavior.

## Resolution Plan

### Phase 0. Confirm Current Specification Baseline

Objective: separate already-resolved material from true blockers before editing
normative source files.

Scope:

- Review only `SPEC.md`, `DESIGN.md`, and this file.
- Do not inspect implementation conformance in this phase.
- Do not change behavior definitions in this file; use it only to track the
  resolution workflow.

Deliverables:

- A short status note in this file for each gap: `open`, `partially covered`,
  or `ready to patch`.
- A list of exact `SPEC.md` and `DESIGN.md` sections to patch for each gap.
- A decision owner if one exists; otherwise mark `owner: unresolved`.

Acceptance:

- Every remaining gap has a clear source-of-truth target section.
- No gap is carried forward only as a broad concern without a concrete patch
  location.

### Phase 1. Resolve Scan Fact Semantics First

Objective: define the internal facts that classification, target resolution,
renderers, and acceptance tests consume.

Gaps covered:

- Gap 1: Artifact namespace profile for mixed groups.
- Gap 2: Per-field read limitations.
- Gap 3: `partial` read semantics.
- Gap 4: Hint `none` versus missing.
- Gap 5: Host-profile root target failure behavior.

Recommended decisions:

1. Artifact namespace profile:
   - Define an artifact-level namespace value per namespace type as either a
     single known namespace ID, `mixed`, or missing.
   - Use a single known artifact namespace value for artifact-scoped
     classification, sorting, target resolution details, and `map`
     relationships.
   - When the value is `mixed`, artifact-scoped evidence that requires equality
     or difference for that namespace does not match; process-scoped evidence
     may still match using member process values.
   - Preserve member namespace profiles for `inspect`, `ps`, limitations, and
     process-scoped anomaly triggers.
   - Mark mixed namespace state explicitly in raw, JSON, and NDJSON outputs.

2. Per-source read limitations:
   - Keep aggregate `process.read_status` as a scan viability summary.
   - Add source-specific status fields for all proc sources that affect public
     output or classification: namespace links, `status`, `stat`, `cmdline`,
     `comm`, `cgroup`, `root`, `exe`, and `mountinfo`.
   - Emit limitation rows for source-specific failures when the missing source
     affects requested output, scoring, hints, target resolution, or
     classification explanation.
   - Define command-specific materiality in `SPEC.md` section 16.3 in terms of
     source-specific statuses instead of only aggregate process status.

3. `partial` semantics:
   - Restrict generic `process.read_status` to `ok`,
     `permission-denied`, and `vanished` unless a concrete aggregate partial
     condition is defined.
   - Keep `partial` only for source readers with explicit operational
     semantics. For v1.0, `mountinfo_read_status=partial` is the required case.
   - If another multi-field reader later needs `partial`, it must define the
     exact syscall or parser condition, what captured fields remain usable, and
     whether classification may use them.

4. Hint aggregation:
   - Track hint availability by source family: cgroup, mountinfo, command
     metadata, executable metadata, and process name metadata.
   - Emit `none` only when every source family relevant to that hint was either
     readable and matched no hint, or not applicable to that hint type.
   - Emit missing (`-` in raw, `null` in JSON/NDJSON) when any relevant source
     family was unreadable, vanished, or partial and no higher-precedence hint
     matched from readable evidence.
   - Still emit source limitation rows so consumers can distinguish "no hint"
     from "hint not knowable".

5. Host root target:
   - Define the host root source as `/proc/1/root` by default and
     `/proc/<host-pid>/root` when `--host-pid` is supplied.
   - If the host root target is unreadable, vanished, or permission denied,
     disable all root comparison evidence for the scan.
   - Emit a scan-level limitation for host root failures.
   - Treat host root failure as `partial-success` only when the requested
     command depends materially on root comparison detail; otherwise return
     success with limitations.

Patch targets:

- `SPEC.md` sections 6.2, 6.3, 6.4, 6.6, 8, 9, 10.3, 10.5, 12.3, 12.4,
  13.5, and 16.3.
- `DESIGN.md` sections 5, 6.1, 6.2, 6.4, 6.5, 9.3, 10.2, 10.3, and 10.4.

Acceptance:

- Classification rules say exactly whether they consume artifact-scoped or
  process-scoped facts.
- Mixed namespace values are represented consistently in internal records and
  structured output.
- Every public source used for scoring or hints has an observable read status.
- `partial` appears only where operational semantics are defined.
- Host root failures cannot accidentally create root equality or root
  difference evidence.

### Phase 2. Resolve Public Output Contract Boundaries

Objective: define which renderer outputs are strict v1.0 contracts and which
are human-oriented presentation.

Gaps covered:

- Gap 6: JSON and NDJSON completeness.
- Gap 7: Human `table` and `text` contracts.

Recommended decisions:

1. Structured output completeness:
   - Make raw, JSON, and NDJSON strict public contracts for `list`, `inspect`,
     `ps`, `report`, and `map`.
   - Keep `doctor`, `version`, and `help` structured schemas optional for v1.0
     unless a command already emits JSON or NDJSON.
   - Replace placeholder `{}` examples in `DESIGN.md` section 10 with required
     field lists or references to common object definitions.
   - Define how `mixed`, missing, `none`, and source-specific read statuses
     appear in every structured object that can expose those facts.

2. Human output boundaries:
   - Treat `table` and `text` as stable human output, not strict parse targets.
   - Define minimum required facts per command, but leave exact spacing,
     wrapping, column width, and section ordering non-contractual unless already
     specified elsewhere.
   - State that scripts must use raw, JSON, or NDJSON.
   - Add acceptance checks for presence of required facts, no diagnostics on
     stdout, and readability under ordinary terminal widths; do not snapshot
     exact human layouts except for smoke tests.

Patch targets:

- `SPEC.md` sections 13, 14, 15.2, 15.3, 15.4, 15.5, and 21.
- `DESIGN.md` sections 7, 8.2, 8.3, 8.4, 8.5, 9, 10, and 13.

Acceptance:

- JSON documents and NDJSON records have no placeholder required objects.
- All strict structured output fields have defined missing-value behavior.
- Table and text tests can validate required content without relying on brittle
  spacing.
- The specification clearly tells script authors which formats are stable parse
  contracts.

### Phase 3. Patch Source Documents

Objective: turn the selected decisions into normative source text.

Order:

1. Patch `SPEC.md` concept definitions and classification semantics.
2. Patch `DESIGN.md` internal record contracts to match those concepts.
3. Patch `SPEC.md` command, output, and exit-code sections.
4. Patch `DESIGN.md` renderer and structured schema sections.
5. Update `DESIGN.md` acceptance fixture plan for the new edge cases.
6. Return to this file and mark each gap resolved with the commit or patch
   summary.

Acceptance:

- `SPEC.md` and `DESIGN.md` use the same terms for artifact namespace values,
  member namespace values, source statuses, hint availability, and root target
  failures.
- No required behavior exists only in this gap plan.
- Every resolved gap points to the normative section that now owns the behavior.

### Phase 4. Add Acceptance Coverage Plan

Objective: define enough test fixtures to prevent regressions when implementation
starts or resumes.

Required fixture additions:

- Mixed namespace artifact under `--group pid`, `--group mnt`, `--group net`,
  and `--group cgroup`.
- Source-specific unreadable metadata for each public proc source.
- Partial mountinfo with parseable early rows that must not drive
  classification.
- Hint aggregation cases where some sources are unreadable and no hint matches.
- Host root target unreadable, vanished, and permission denied cases.
- Structured output examples for `mixed`, `none`, missing, and source-specific
  read statuses.
- Human table/text smoke cases that verify required facts without exact layout
  coupling.

Acceptance:

- Each fixture has positive and near-miss expectations.
- Exit-code expectations are explicit for broad commands and targeted commands.
- Raw, JSON, and NDJSON checks cover parseable facts and missing-value
  behavior.

### Phase 5. Close The Gap Register

Objective: make this file either unnecessary or a short historical checklist.

Closure criteria:

- All seven gaps are marked resolved.
- `SPEC.md` and `DESIGN.md` contain the normative behavior.
- Acceptance fixture plan covers each resolved gap.
- Any deferred behavior is moved to a follow-up section with an explicit
  non-v1.0 boundary.

Final action:

- Either delete this file after the normative sources are patched, or replace
  it with a brief resolution summary that links each original gap to its owning
  `SPEC.md` or `DESIGN.md` section.

## Notes

- No owner is assigned in source material.
- No implementation or tests have been inspected for conformance to these gaps.
- This file should be updated or removed as gaps are resolved in `SPEC.md` and
  `DESIGN.md`.
