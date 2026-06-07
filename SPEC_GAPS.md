# nsurgn v1.0 Blocking Spec Gaps

Status: Deprecated
Replacement: `SPEC_GAPS_PLAN.md`
Deprecated: 2026-06-07

This file is retained as the source gap inventory. Use `SPEC_GAPS_PLAN.md` as
the active coordination plan for resolving these gaps.

This note captures gaps in `SPEC.md` and `DESIGN.md` that could block stable
implementation, fixture design, or acceptance testing for the v1.0 foundation.
It is not a redesign proposal; each item should be resolved by tightening the
spec before broad implementation work depends on the behavior.

## 1. Anomaly Rules Are Not Testable

`SPEC.md` defines `anomalous` as major namespace isolation plus "concerning,
inconsistent, incomplete, or hard-to-explain evidence." That is directionally
useful, but not deterministic enough for implementation or tests.

Blocking question:

- Which exact evidence patterns set the `anomalous` flag in v1.0?

Needed clarification:

- A finite v1.0 trigger list.
- Stable reason codes for each trigger.
- Whether unreadable metadata can ever make an artifact anomalous, or only a
  limitation.
- How anomalous evidence interacts with spoofable process metadata.

Source:

- `SPEC.md` section 10.3.

Resolution slices:

- `GAP-1/S1`: Define a finite v1.0 anomalous trigger table in `SPEC.md`
  section 10.3. Each row should include trigger name, required evidence,
  reason code, whether it is artifact-scoped or process-scoped, and an example.
  Resolves the non-deterministic meaning of "concerning, inconsistent,
  incomplete, or hard-to-explain evidence."
- `GAP-1/S2`: Add the rule that unreadable metadata is a limitation by
  default, not anomalous evidence. It can set `anomalous` only when combined
  with a specific trigger from the v1.0 trigger table. Resolves ambiguity about
  permission-limited scans becoming false anomalies.
- `GAP-1/S3`: Add spoofability handling for process metadata, cgroup paths, and
  runtime hints. The spec should state that spoofable metadata can contribute
  evidence and reasons, but cannot by itself create an anomaly unless matched
  with namespace or filesystem inconsistency. Resolves the interaction between
  anomalous evidence and spoofable process metadata.
- `GAP-1/S4`: Add acceptance fixtures for every anomalous trigger and for
  near-miss cases that must not set `anomalous`. Resolves implementation and
  regression-test determinism.

## 2. Evidence Matching Needs Exact Rules

Several score and hint signals depend on text or path matching but do not yet
define exact matching rules.

Blocking questions:

- What regex defines a "32- to 64-character lowercase hexadecimal container ID"?
- Are matches case-sensitive for cgroup/runtime hints?
- What exact `exe_path` value means "executable path is deleted"?
- What command or executable patterns count as `unshare`-style metadata?

Needed clarification:

- Exact regexes or shell-compatible matching rules.
- Field scope for each remaining match: cgroup path, `comm`, `cmdline`,
  `exe_path`, or root path.
- Stable reason codes for every detection.

Source:

- `SPEC.md` sections 10.2 and 10.5.

Resolution slices:

- `GAP-2/S1`: Add a normative evidence-matching table to `SPEC.md` section
  10.5. Include signal, searched field, match rule, case sensitivity, emitted
  reason code, score delta, and hint effect. Resolves the missing field scope
  and reason-code mapping for scoring and hints.
- `GAP-2/S2`: Define the container-like hex ID rule as a path component regex,
  not a substring match. Candidate rule: `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`
  after splitting cgroup paths and relevant mount fields into components.
  Resolves the exact "32- to 64-character lowercase hexadecimal container ID"
  question while preserving lowercase-only matching.
- `GAP-2/S3`: Specify case sensitivity for cgroup and runtime hints. Recommended
  v1.0 rule: cgroup/runtime keyword matches are case-sensitive lowercase unless
  the source format is explicitly normalized before matching. Resolves
  implementation drift across Bash match operators.
- `GAP-2/S5`: Define deleted executable detection using the exact `readlink`
  output suffix for `/proc/<pid>/exe`, including whether `" (deleted)"` is
  stripped for display or preserved in evidence detail. Resolves the
  `exe_path` deleted-value ambiguity.
- `GAP-2/S6`: Define `unshare`-style metadata patterns for `comm`, `cmdline`,
  and `exe_path`, with reason codes for each accepted source. Resolves the
  command/executable pattern ambiguity.

## 3. Explicit PID Targets Should Bypass Default Visibility Filters

Default discovery hides host-equivalent artifacts. The spec also says cgroup
minor-only artifacts become visible when targeted explicitly, but the rule is not
stated generally for all target commands.

Blocking question:

- For `inspect`, `ps`, `report`, and `map`, does an explicit PID target always
  resolve even if the artifact would be hidden from default `list` output?

Needed clarification:

- A command-level rule that explicit host PID targets bypass default host hiding.
- Whether explicit artifact ID targets can ever reference hidden artifacts, given
  IDs are assigned after visibility filtering.
- Whether `--include-host` changes target resolution or only broad command
  visibility.

Source:

- `SPEC.md` sections 8, 9.6, 12.3, and 13.

Resolution slices:

- `GAP-3/S1`: Add a command-level target visibility rule: explicit host PID
  targets for `inspect`, `ps`, `report`, and `map` bypass default host hiding
  and resolve from the full visible scan. Resolves whether hidden
  host-equivalent artifacts can be inspected by PID.
- `GAP-3/S2`: Define artifact ID target scope as post-filter only. Artifact IDs
  cannot target hidden artifacts unless the command invocation used visibility
  options that assigned IDs to those artifacts. Resolves hidden-artifact ID
  ambiguity.
- `GAP-3/S3`: Define `--include-host` as a broad visibility option that affects
  artifact visibility and ID assignment, but does not change explicit PID
  resolution because PID targets already resolve from the full visible scan.
  Resolves option interaction.
- `GAP-3/S4`: Add targeted command fixtures for host-equivalent PID,
  minor-only cgroup grouped artifact, and hidden default artifact. Resolves
  command acceptance behavior across `inspect`, `ps`, `report`, and `map`.

## 4. Partial Metadata Exit Codes Need Per-Command Thresholds

The exit code table defines `partial-success`, `permission-denied`, and
`process-changed`, but the spec does not define which missing metadata is
material for each command.

Blocking questions:

- When does unreadable `root`, `exe`, `mountinfo`, `cmdline`, `status`, or
  `cgroup` change the exit code instead of becoming a limitation row?
- Which missing fields prevent the primary requested output for each command?
- Can broad `list` ever exit `partial-success`, or should it usually exit
  success with limitations?

Needed clarification:

- A command-by-command matrix for required, optional, and material metadata.
- Exit code selection examples for common permission and vanished-process cases.

Source:

- `SPEC.md` section 16.3.

Resolution slices:

- `GAP-4/S1`: Add a command-by-command materiality matrix to `SPEC.md` section
  16.3. Columns should include command, required metadata for primary output,
  optional metadata that becomes limitations, metadata whose absence can cause
  `partial-success`, and metadata whose absence can cause `permission-denied`
  or `process-changed`. Resolves missing per-command thresholds.
- `GAP-4/S2`: Define broad scan behavior for `list` and untargeted `report`.
  Recommended v1.0 rule: ordinary vanished PIDs and unreadable optional fields
  produce limitations/warnings and exit `0` unless they prevent the command from
  producing coherent artifact summaries. Resolves whether broad `list` exits
  `partial-success`.
- `GAP-4/S3`: Define targeted command behavior for `inspect`, `ps`, `report
  <target>`, and `map <target>`. Missing metadata that prevents resolving the
  requested target or its primary process set should choose `3`, `4`, `5`, or
  `7` by existing precedence; missing detailed evidence should choose `6` only
  when the primary target output is produced but materially incomplete. Resolves
  target-specific exit behavior.
- `GAP-4/S4`: Add exit-code examples for unreadable `root`, `exe`,
  `mountinfo`, `cmdline`, `status`, and `cgroup`, plus vanished target and
  vanished non-target member cases. Resolves fixture and acceptance-test
  coverage.

## 5. JSON Escaping Needs Acceptance Fixtures

The design requires valid JSON and NDJSON without `jq`, Python, or another
external generator. That is feasible in Bash only if the supported character set
and escaping behavior are tightly tested.

Blocking question:

- What exact JSON escaping behavior is required for control characters and
  untrusted proc metadata?

Needed clarification:

- Fixtures for quotes, backslashes, tabs, newlines, carriage returns, empty
  strings, missing values, and ordinary printable command lines.
- Whether unsupported control characters should be escaped, normalized, omitted,
  or represented as limitations.
- Acceptance checks that JSON and NDJSON stdout remain parseable.

Source:

- `DESIGN.md` sections 8.4, 10, and 13.

Resolution slices:

- `GAP-6/S3`: Add fixtures for quotes, backslashes, tabs, newlines, carriage
  returns, empty strings, missing values, ordinary printable command lines, and
  command-line NUL separators. Resolves acceptance coverage.
- `GAP-6/S4`: Add parseability checks for JSON document output and NDJSON
  streams using only tools allowed by the test environment, with a note that the
  production CLI must not depend on `jq`, Python, or external JSON generators.
  Resolves structured-output validation without changing runtime dependencies.

## 6. Map Relationship Semantics Are Underdefined

The `map` command has output fields and a high-level purpose, but not enough
generation rules to implement deterministic output.

Blocking questions:

- Which namespace types create relationship rows?
- Are relationships pairwise between artifacts, grouped by namespace ID, or both?
- Are host-equivalent relationships hidden by default?
- How are duplicate relationships suppressed?
- What is the sort order?

Needed clarification:

- Relationship generation rules.
- Visibility rules for host and targeted artifacts.
- Stable relationship enum values.
- Deterministic raw, JSON, and NDJSON ordering.

Source:

- `SPEC.md` section 13.5 and `DESIGN.md` section 9.5.

Resolution slices:

- `GAP-7/S1`: Define v1.0 relationship enum values. Recommended minimum:
  `shares-namespace` for same namespace IDs and `differs-namespace` only if the
  map view intentionally emits contrast rows. Resolves relationship value
  stability.
- `GAP-7/S2`: Define namespace types included in map generation. Recommended
  v1.0 rule: emit relationship rows for PID, mount, network, and user
  namespaces by default; include UTS, IPC, cgroup, and time only when explicitly
  required by the map contract or grouping mode. Resolves namespace-type scope.
- `GAP-7/S3`: Define relationship shape as pairwise artifact rows grouped by
  namespace ID, with self-relationships omitted. Emit one row per unordered
  artifact pair per namespace type and suppress duplicates by
  `(left_artifact_id, relationship, namespace_type, namespace_id,
  right_artifact_id)`. Resolves pairwise/grouped semantics and duplicate
  suppression.
- `GAP-7/S4`: Define visibility rules: untargeted `map` uses the same default
  artifact visibility as `list`; `--include-host` includes host-equivalent
  artifacts; targeted `map <pid>` uses the explicit PID bypass rule from
  `GAP-3`. Resolves host-equivalent and targeted map behavior.
- `GAP-7/S5`: Define deterministic ordering for raw, JSON, and NDJSON:
  namespace type order, namespace ID bytewise, left artifact sort order, right
  artifact sort order, relationship enum order, then detail bytewise. Resolves
  stable output ordering.
- `GAP-7/S6`: Add fixtures for shared network namespace, shared mount
  namespace, no shared major namespaces, hidden host-equivalent relationships,
  and targeted map output. Resolves map acceptance testing.
