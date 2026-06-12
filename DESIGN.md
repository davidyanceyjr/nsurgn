# nsurgn v1.0 Architecture and Interface Design

This document translates `SPEC.md` into an implementation-oriented design for the v1.0 Bash CLI.

## 1. Design Goals

`nsurgn v1.0` should be a read-only, runtime-independent Linux CLI that discovers namespace artifacts from `/proc`, models them consistently, and emits output that is safe for operators and scripts.

Primary architectural drivers:

- Bash-oriented implementation.
- `/proc` and standard Linux utilities only.
- Raw tab-separated stdout by default.
- Diagnostics, warnings, and hints on stderr only.
- One scan model shared by all discovery and inspection commands.
- Evidence-based classification without runtime identity claims.
- Graceful handling of vanished PIDs and permission-limited metadata.

## 2. High-Level Architecture

```text
bin/nsurgn
  |
  |-- cli and option parsing
  |-- scan engine
  |     |-- proc discovery
  |     |-- namespace reader
  |     |-- process metadata reader
  |     |-- host profile resolver
  |     |-- grouping engine
  |     |-- leader selector
  |     `-- scorer/classifier
  |
  |-- target resolver
  |     |-- artifact id: A1
  |     |-- host pid: 18342
  |     `-- explicit host pid: pid:18342
  |
  |-- commands
  |     |-- list
  |     |-- inspect
  |     |-- ps
  |     |-- report
  |     |-- map
  |     |-- doctor
  |     |-- version
  |     `-- help
  |
  `-- renderers
        |-- raw
        |-- table
        |-- text
        |-- json
        `-- ndjson
```

The scan engine owns facts. Commands own selection and command-specific views. Renderers own formatting only.

## 3. Dependency Direction

Dependencies should flow inward toward normalized records:

```text
/proc readers -> process records -> artifact records -> command views -> renderers
```

Command implementations should not perform their own ad hoc `/proc` scraping unless the command requires metadata that the shared scan does not collect. If new metadata becomes common across commands, it belongs in the scan engine.

## 4. Proposed Repository Layout

Initial implementation may keep fewer files, but these are the intended boundaries:

```text
bin/
  nsurgn

lib/
  cli.sh
  errors.sh
  proc.sh
  scan.sh
  namespace.sh
  process.sh
  host.sh
  group.sh
  leader.sh
  classify.sh
  target.sh
  render_raw.sh
  render_table.sh
  render_text.sh
  render_json.sh
  util.sh

test/
  fixtures/
  unit/
  integration/
```

If v1 starts as a single executable, keep functions grouped by the same boundaries so extraction remains mechanical.

## 5. Scan Workspace

Because Bash is weak at nested data structures, the scan engine should write normalized records to a per-invocation temporary workspace.

Suggested files:

```text
process.tsv
process_cgroup.tsv
process_cgroup_summary.tsv
process_mountinfo.tsv
process_mount_summary.tsv
artifact.tsv
artifact_process.tsv
classification_reason.tsv
scan_limitation.tsv
```

The workspace is internal and not a public interface. It still should use stable, documented field order so tests can inspect it directly.

The workspace must be cleaned up on normal exit and common signals.

## 6. Internal Record Contracts

Internal records are tab-separated. Missing values use `-`. Fields that may contain tabs, newlines, or carriage returns use the same escaping rules as raw output.

Hint fields use `none` when all source families relevant to that hint were
readable, or not applicable, and no known hint was found. They use `-` when a
relevant source family was unavailable, unreadable, vanished, or partial and no
higher-precedence readable evidence matched.

### 6.1 `process.tsv`

```text
host_pid
ppid
uid
user
state
start_time
ns_pid
pid_ns
mnt_ns
net_ns
user_ns
uts_ns
ipc_ns
cgroup_ns
time_ns
cgroup_hint
runtime_hint
root_path
root_target
exe_path
comm
cmdline
read_status
namespace_read_status
status_read_status
stat_read_status
cmdline_read_status
comm_read_status
cgroup_read_status
root_read_status
exe_read_status
```

`read_status` is `ok`, `permission-denied`, or `vanished` and summarizes
process scan viability. Source-specific fields are `ok`, `permission-denied`,
or `vanished` unless that source reader defines partial-read semantics.
`partial` is not valid for these v1.0 `process.tsv` source fields; mountinfo
partial reads are represented by `mountinfo_read_status`.

`root_path` is the procfs symlink path `/proc/<pid>/root`. `root_target` is
the readable `readlink` value of that path and is the only root field used for
host-root equality or difference checks.

The source-specific status fields cover public process sources used by output,
scoring, hints, target resolution, and classification explanation:

- `namespace_read_status` covers `/proc/<pid>/ns/*` namespace links.
- `status_read_status` covers `/proc/<pid>/status`.
- `stat_read_status` covers `/proc/<pid>/stat`.
- `cmdline_read_status` covers `/proc/<pid>/cmdline`.
- `comm_read_status` covers `/proc/<pid>/comm`.
- `cgroup_read_status` covers `/proc/<pid>/cgroup`.
- `root_read_status` covers `/proc/<pid>/root`.
- `exe_read_status` covers `/proc/<pid>/exe`.

When one of these source-specific failures affects requested output, scoring,
hints, target resolution, or classification explanation, emit a matching
limitation row.

### 6.2 `process_cgroup.tsv`

One row is emitted for each parseable, non-blank `/proc/<pid>/cgroup` line.
Processes with missing, unreadable, vanished, empty, or unparseable cgroup input
have no `process_cgroup.tsv` rows; their source status remains in
`process.tsv`.

```text
host_pid
line_index
cgroup_version
hierarchy_id
controllers
normalized_controllers
path
contributes_to_group_key
```

`line_index` is one-based in procfs read order. `cgroup_version` is `v2` for the
unified line whose hierarchy ID is `0` and controllers field is empty; otherwise
it is `v1`. `controllers` preserves the procfs controllers field exactly.
`normalized_controllers` is the comma-joined, bytewise-sorted controller list for
v1 rows and `-` for v2 rows. `path` preserves the cgroup path text after the
empty-path-as-`/` rule from `SPEC.md` section 9.6.

`contributes_to_group_key` is `true` for the row or rows used to build the
`--group cgroup` key for that process and `false` for other parsed rows. When a
v2 row is present, only the first v2 row contributes. Otherwise, all parsed v1
rows contribute after controller/path normalization and sorting.

This file is the source of truth for cgroup path evidence used by cgroup hints,
cgroup-derived runtime hints, scoring, classification reasons, inspect/report
`cgroup path` rows, JSON `cgroup_paths`, and NDJSON `cgroup_path` records.

### 6.3 `process_cgroup_summary.tsv`

One row is emitted for every process that has a viable `process.tsv` row.

```text
host_pid
cgroup_read_status
cgroup_group_key
cgroup_hint
runtime_hint
path_count
```

`cgroup_read_status` mirrors `process.tsv`. `cgroup_group_key` is the exact
per-process key from `SPEC.md` section 9.6, including `cgroup:unknown` when the
source is missing, unreadable, empty after blank lines, vanished, or contains no
parseable line. `cgroup_hint` and `runtime_hint` are the highest-precedence hints
derived from cgroup paths only, using `none` and `-` with the standard hint-field
rules. `path_count` is the number of `process_cgroup.tsv` rows for the process.

The grouping engine uses `cgroup_group_key` for `--group cgroup`. The
classification engine may combine the cgroup-derived `runtime_hint` with
higher-precedence or lower-precedence hint families as defined by `SPEC.md`.

### 6.4 `process_mountinfo.tsv`

One row is emitted for each parseable `/proc/<pid>/mountinfo` line. Processes
with permission-denied, vanished, empty, fully unparseable, or partial input with
no parseable rows have no `process_mountinfo.tsv` rows; their read status remains
in `process_mount_summary.tsv`.

```text
host_pid
line_index
mount_id
parent_id
major_minor
root
mount_point
mount_options
optional_fields
filesystem_type
mount_source
super_options
```

`line_index` is one-based in procfs read order. The parser uses the first
literal ` - ` separator and the field rules from `SPEC.md` section 13.2.
`optional_fields` preserves any pre-separator optional fields as one escaped
space-separated value, or `-` when no optional fields are present. These records
preserve only parsed fields; unparseable mountinfo lines are not retained.

This file is the source of truth for mount-derived evidence, including overlay
or snapshotter hints, Kubernetes projected or serviceaccount hints, related
classification reasons, and mount-derived runtime hints.

### 6.5 `process_mount_summary.tsv`

One row is emitted for every process that has a viable `process.tsv` row.

```text
host_pid
root_path
root_target
mountinfo_read_status
mount_count
overlay_or_snapshotter
kubernetes_projected
runtime_hint
```

`root_path` and `root_target` mirror `process.tsv` for the same host PID.
`mountinfo_read_status` is `ok`, `partial`, `permission-denied`, or `vanished`.
`mount_count` is the count of parseable `process_mountinfo.tsv` rows only when
`mountinfo_read_status=ok`; otherwise it is `-`.

`overlay_or_snapshotter` and `kubernetes_projected` use `true`, `false`, or `-`
with the semantics from `SPEC.md` section 13.2. When `mountinfo_read_status` is
not `ok`, both fields are `-`, and classification must not infer mount-derived
evidence or runtime hints from partial, unreadable, or vanished mountinfo.

`runtime_hint` is the mount-derived runtime hint for this process only. It uses
`snapshotter`, `kubernetes`, `none`, or `-` according to the standard hint-field
rules and the precedence rules in `SPEC.md` section 10.5.

Renderers select the appropriate process summary for public mount output: target
commands use the resolved target or leader process defined by the command
contract, and broad artifact output uses the artifact leader unless a command
section explicitly says otherwise.

### 6.6 `artifact.tsv`

```text
artifact_id
group_key
pid_ns
mnt_ns
net_ns
user_ns
uts_ns
ipc_ns
cgroup_ns
time_ns
classification
score
leader_pid
leader_ns_pid
process_count
runtime_hint
cgroup_hint
leader_command
leader_reason
```

Artifact IDs are assigned after command visibility filtering and the artifact
sort defined in `SPEC.md` section 12.3. They are valid only for the current
invocation.

Artifact namespace fields are aggregate artifact-level values from `SPEC.md`
section 9. Each field is a namespace ID string, `mixed`, or `-`. A field is
`mixed` when member processes contain two or more known namespace IDs for that
namespace type. Member-level namespace values remain in `process.tsv` and are
used for process-scoped evidence and detailed inspection.

### 6.7 `artifact_process.tsv`

```text
artifact_id
host_pid
role
```

`role` is `leader` or `member`.

### 6.8 `classification_reason.tsv`

```text
artifact_id
reason_code
score_delta
detail
```

Reason codes should be stable lower-case identifiers such as `pid_ns_differs`, `runtime_hint_containerd`, or `nested_pid_init`.

`score_delta` is the numeric contribution from this reason, or `-` for
classification evidence and flags that do not directly affect score. Scored
reason codes must be emitted at most once per artifact for each v1.0 scoring
signal. When multiple member processes expose the same scored signal, `detail`
should contain representative evidence instead of multiplying `score_delta`.

### 6.9 `scan_limitation.tsv`

```text
severity
code
pid
path
source
read_status
message
```

One row is emitted for each scan limitation that affects requested output,
scoring, hints, target resolution, classification explanation, or user-visible
diagnostics.

`severity` is `warning` or `error`. `warning` is used for limitations where the
command can still produce the requested primary result. `error` is used for
limitations that prevent the requested primary result or directly explain a
nonzero exit code.

`code` is a stable lower-case identifier such as `permission_denied`,
`process_vanished`, `partial_read`, `missing_namespace`, or
`host_root_unavailable`.

`pid` is the host PID associated with the limitation, or `-` when the limitation
is scan-level rather than process-scoped. `path` is the procfs or filesystem
path associated with the limitation, or `-` when there is no single path.
`source` identifies the source family associated with source-specific read
failures, such as `namespace`, `status`, `stat`, `cmdline`, `comm`, `cgroup`,
`root`, `exe`, `mountinfo`, or `host-root`; it is `-` when no single source
family applies. `read_status` is `permission-denied`, `vanished`, or `partial`
for source-specific read failures and `-` when the limitation is not tied to a
source read status. `message` is the human-readable explanation.

All raw `limitation` rows, JSON `scan_limitation` objects, NDJSON
`limitation` records, and stderr warning diagnostics are projections from this
file. Stderr warnings are rendered from rows with `severity=warning` unless
`--quiet` suppresses non-critical warnings. Fatal errors and usage errors may be
emitted directly on stderr before a scan workspace exists, but scan-derived
diagnostics must use `scan_limitation.tsv`.

## 7. Stdout and Stderr Contract

`stdout` is reserved for the selected command output.

`stderr` is reserved for:

- warnings,
- permission notes,
- hints,
- verbose scan details,
- usage errors,
- fatal errors.

No warning, banner, progress message, or hint may be written to stdout in `raw`, `json`, or `ndjson` mode.

`doctor`, `help`, and `version` still write their primary command output to stdout. Failures and warnings remain on stderr.

## 8. Output Formats

### 8.1 `raw`

Default format. A tab-separated record stream intended for pipes, scripts, and parsers.

Rules:

- one record per physical line,
- literal tab between fields,
- no header by default,
- no color,
- no alignment padding,
- no wrapping,
- no decoration,
- missing values as `-`,
- diagnostics on stderr only.

Escaping:

```text
tab              -> \t
newline          -> \n
carriage return  -> \r
backslash        -> \\
```

`/proc/<pid>/cmdline` NUL separators are converted to single spaces before field escaping.

### 8.2 `table`

Human-facing aligned summaries. Opt-in.

Table output may include headers. It should remain readable in typical
terminals, but correctness must not depend on terminal width.

Table output is not a parse contract. Renderers may choose column order,
spacing, padding, wrapping, truncation, and color as long as every required fact
from `SPEC.md` section 15.2 is present when available and diagnostics stay on
stderr. Acceptance tests should check required facts and absence of diagnostics
on stdout, not exact whitespace snapshots.

### 8.3 `text`

Human-facing labeled reports. Opt-in.

Text output is appropriate for `inspect`, `report`, `map`, `doctor`, `help`, and `version`.

Text output is not a parse contract. Renderers may choose heading text, section
order, indentation, blank lines, wrapping, and prose wording as long as every
required fact from `SPEC.md` section 15.3 is labeled clearly enough for a human
operator. Scripts must use raw, JSON, or NDJSON.

### 8.4 `json`

Structured document output. Opt-in.

JSON output must use valid JSON string escaping and must not require `jq`, Python, or another external generator.

JSON string escaping contract:

- double quote (`"`) is emitted as `\"`,
- backslash (`\`) is emitted as `\\`,
- tab is emitted as `\t`,
- newline is emitted as `\n`,
- carriage return is emitted as `\r`,
- backspace is emitted as `\b`,
- form feed is emitted as `\f`,
- other representable ASCII control characters `0x01` through `0x1f` are
  emitted as lowercase `\u00xx` escapes,
- printable bytes are emitted unchanged except where JSON requires escaping.

Proc metadata is normalized before JSON escaping:

- `/proc/<pid>/cmdline` NUL separators are converted to single spaces, matching
  raw output behavior,
- literal NUL bytes are source-reader concerns because Bash strings cannot
  preserve them; v1.0 readers must normalize known NUL-delimited fields before
  handing values to renderers,
- an empty but readable `cmdline` is an empty JSON string,
- missing or unreadable metadata is represented by the schema's missing value
  for that field, not by a fabricated string,
- no control character may be omitted solely because Bash cannot print it
  literally.

### 8.5 `ndjson`

Structured record stream. Opt-in.

Each line must be one complete JSON object. This is most useful for `list`,
`ps`, and relationship records from `map`.

## 9. Command Output Contracts

Raw field order is part of the v1 command contract once implemented.

### 9.1 `list`

Default raw fields:

```text
artifact_id
classification
score
leader_pid
leader_ns_pid
process_count
runtime_hint
leader_command
```

### 9.2 `ps <artifact-id|pid>`

Default raw fields:

```text
host_pid
ns_pid
ppid
user
state
command
```

### 9.3 `inspect <artifact-id|pid>`

Default raw output must be key-value records because the shape is not naturally tabular:

```text
section	key	value
```

Required sections:

```text
target
leader
classification
namespace
cgroup
process
evidence
limitation
mount
```

Required scalar rows:

```text
target	input	<original-target>
target	input_type	artifact-id|host-pid
target	artifact_id	<artifact-id>
target	host_pid	<host-pid>
leader	host_pid	<host-pid>
leader	ns_pid	<ns-pid-or-missing>
leader	reason	<nested-pid-init|oldest-process|lowest-host-pid>
leader	command	<escaped-command-or-missing>
leader	comm	<escaped-comm-or-missing>
leader	exe_path	<path-or-missing>
leader	root_path	<path-or-missing>
leader	root_target	<resolved-root-target-or-missing>
classification	label	<classification>
classification	score	<score>
classification	runtime_hint	<runtime-hint-or-none-or-missing>
classification	cgroup_hint	<cgroup-hint-or-none-or-missing>
mount	root_path	<path-or-missing>
mount	root_target	<resolved-root-target-or-missing>
mount	mountinfo_read_status	ok|partial|permission-denied|vanished
mount	mount_count	<count-or-missing>
mount	overlay_or_snapshotter	true|false|-
mount	kubernetes_projected	true|false|-
```

Mount summary semantics:

- `mountinfo_read_status` is `ok` only when `/proc/<pid>/mountinfo` is opened
  and read to completion for the selected target process.
- `mountinfo_read_status` is `permission-denied` when opening or reading
  `/proc/<pid>/mountinfo` fails because access is denied.
- `mountinfo_read_status` is `vanished` when the target process or proc entry
  disappears before a coherent read can be completed.
- `mountinfo_read_status` is `partial` only when at least one parseable
  mountinfo line was captured but the read ended early or was interrupted before
  the file was read to completion.
- `mount_count` is the number of parseable mountinfo lines after a full
  successful read. When `mountinfo_read_status` is not `ok`, `mount_count` is
  missing (`-`) even if partial lines were captured.

Mountinfo parser rules:

- Each `/proc/<pid>/mountinfo` line is parsed using the first literal ` - `
  separator. Lines without this separator are unparseable and do not contribute
  to `mount_count`.
- Pre-separator fields are split on ASCII whitespace. A parseable line has at
  least six pre-separator fields: `mount_id`, `parent_id`, `major_minor`,
  `root`, `mount_point`, and `mount_options`.
- Any additional pre-separator fields after `mount_options` and before ` - `
  are `optional_fields`. v1.0 preserves them as parser input for mount evidence
  matching, but does not render them as standalone inspect rows.
- Post-separator fields are split on ASCII whitespace. A parseable line has at
  least three post-separator fields: `filesystem_type`, `mount_source`, and
  `super_options`.
- v1.0 mount summary derivation may use only `mount_point`,
  `optional_fields`, `filesystem_type`, and `mount_source`. It must not infer
  overlay, snapshotter, projected-volume, or serviceaccount evidence from
  unparsed text outside those fields.

Mount evidence rules:

- `overlay_or_snapshotter` is `true` when any parseable mountinfo row has
  `filesystem_type=overlay`, `filesystem_type=fuse-overlayfs`,
  `mount_source=overlay`, or a `mount_source` or `mount_point` path component
  equal to `overlay`, `overlayfs`, `snapshots`, or `snapshotter`.
- `overlay_or_snapshotter` is `false` when `mountinfo_read_status=ok` and no
  parseable row matches the overlay or snapshotter rule.
- `kubernetes_projected` is `true` when any parseable mountinfo row has
  `filesystem_type=tmpfs` and an `optional_fields` value beginning with
  `shared:` and a `mount_point` path component equal to `kube-api-access`, or
  when any parseable row has `filesystem_type=tmpfs` or
  `filesystem_type=projected` and a `mount_point` path component equal to
  `serviceaccount`, `secrets`, or `kube-api-access`.
- `kubernetes_projected` is `false` when `mountinfo_read_status=ok` and no
  parseable row matches the Kubernetes projected-volume rule.
- Path-component comparisons are exact, case-sensitive comparisons after
  splitting `mount_source` and `mount_point` on `/`. Empty components are
  ignored. These rules do not perform substring matching.
- When a boolean is `true`, classification may emit a matching reason such as
  `mount_overlay_snapshotter` or `mount_kubernetes_projected`, using the parsed
  fields above as evidence detail.

Unreadable or incomplete mountinfo behavior:

- When `mountinfo_read_status` is `permission-denied`, `vanished`, or
  `partial`, the `mount` rows still render.
- When `mountinfo_read_status` is not `ok`, `mount_count`,
  `overlay_or_snapshotter`, and `kubernetes_projected` are missing (`-`), and
  classification must not infer mount-derived evidence or runtime hints from
  partial, unreadable, or vanished mountinfo.
- The unreadable or incomplete read is recorded as a limitation row using the
  target PID and the read status.

For each namespace type, emit these rows using the namespace type in the key:

```text
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.target	<namespace-id-mixed-or-missing>
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.host	<namespace-id-or-missing>
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.differs	true|false|-
```

When the target artifact namespace value is `mixed`, render `mixed` in the
`.target` row and `-` in the corresponding `.differs` row.

Repeated scalar values repeat the same `section` and `key`, one row per value:

```text
cgroup	path	<cgroup-path>
```

Repeated objects use one-based indexes in the key. Required process rows:

```text
process	<index>.host_pid	<host-pid>
process	<index>.ns_pid	<ns-pid-or-missing>
process	<index>.ppid	<ppid-or-missing>
process	<index>.uid	<uid-or-missing>
process	<index>.user	<user-or-missing>
process	<index>.state	<state-or-missing>
process	<index>.start_time	<start-time-or-missing>
process	<index>.read_status	ok|permission-denied|vanished
process	<index>.comm	<escaped-comm-or-missing>
process	<index>.command	<escaped-command-or-missing>
process	<index>.exe_path	<path-or-missing>
process	<index>.root_path	<path-or-missing>
process	<index>.root_target	<resolved-root-target-or-missing>
```

Required evidence rows for each classification reason:

```text
evidence	<index>.code	<reason-code>
evidence	<index>.score_delta	<integer-or-missing>
evidence	<index>.detail	<escaped-detail>
```

Required limitation rows for each limitation:

```text
limitation	<index>.severity	warning|error
limitation	<index>.code	<limitation-code>
limitation	<index>.pid	<host-pid-or-missing>
limitation	<index>.path	<path-or-missing>
limitation	<index>.source	<source-family-or-missing>
limitation	<index>.read_status	<read-status-or-missing>
limitation	<index>.message	<escaped-message>
```

These rows are rendered from `scan_limitation.tsv`. Missing `pid`, `path`,
`source`, and `read_status` values use `-`. Source-specific read failures that
affect requested output must include the same source family and read status used
by the corresponding process, mount summary, or host-profile source field.

### 9.4 `report [<artifact-id|pid>]`

Default raw output must also use:

```text
section	key	value
```

When reporting multiple artifacts, include `artifact_id`:

```text
artifact_id	section	key	value
```

When `report` is called with a target, raw output uses the same three-column
contract as `inspect`. When `report` is called without a target, raw output uses
the four-column multi-artifact contract and repeats the `inspect` section/key
contract for each reported artifact.

Multi-artifact `report` may emit scan-level rows before artifact rows. Scan rows
use `-` as the artifact ID:

```text
-	scan	group_mode	<group-mode>
-	scan	host_pid	<host-pid>
-	scan	process_count	<count>
-	scan	artifact_count	<count>
-	scan	include_host	true|false
```

### 9.5 `map [<artifact-id|pid>]`

Default raw fields:

```text
left_artifact_id
relationship
namespace_type
namespace_id
right_artifact_id
detail
```

Relationship generation, visibility, duplicate suppression, and record ordering
follow `SPEC.md` section 13.5.

## 10. Structured Output Contracts

Structured output is a public CLI contract. JSON and NDJSON render the same
scan facts used by raw, table, and text output, but they use nested objects
where that is clearer than positional fields.

### 10.1 Compatibility Rules

All structured records include:

```text
schema_version
command
```

For v1.0, `schema_version` is:

```text
nsurgn.output.v1
```

Rules:

- producers may add new object fields in v1.x;
- producers must not remove or rename v1.0 fields without a schema version change;
- consumers must ignore unknown fields;
- enum values may be extended, so consumers must handle unknown values;
- unavailable or unreadable scalar values are `null`;
- empty collections are `[]`;
- PIDs, counts, scores, and score deltas are JSON numbers;
- namespace IDs are JSON strings without the namespace type wrapper, for
  example `4026531836`;
- an artifact-level namespace value may be the string `mixed` when member
  processes have multiple known values for that namespace type;
- command lines and paths are JSON strings with standard JSON escaping;
- hint fields use `none` only for known no-hint values; they use `null` when
  a relevant source family was unavailable, unreadable, vanished, or partial and
  no higher-precedence readable evidence matched;
- diagnostics still go to stderr and must not be interleaved with JSON or NDJSON on stdout.

Known enum values:

```text
cgroup_hint: kubepods, docker, crio, libpod, containerd, lxc, machine.slice,
             container-id, none
classification: host, isolated, namespace-managed, container-like, anomalous
group_mode: profile, strict, pid, mnt, net, cgroup
input_type: artifact-id, host-pid
leader_reason: nested-pid-init, oldest-process, lowest-host-pid
namespace_type: pid, mnt, net, user, uts, ipc, cgroup, time
read_status: ok, partial, permission-denied, vanished
runtime_hint: kubernetes, docker, crio, podman, containerd, lxc, systemd,
              unshare, snapshotter, container-id, none
severity: warning, error
record_type: scan_context, artifact, artifact_summary, namespace_difference,
             namespace_profile, cgroup_path, mount_summary,
             classification_reason, process, relationship, limitation
```

### 10.2 Common Types

The objects below define required v1.0 structured fields. Examples show typical
values, not all possible enum combinations. Additional fields may be added in
v1.x according to section 10.1.

`scan_context`:

```json
{
  "group_mode": "profile",
  "host_pid": 1,
  "include_host": false,
  "process_count": 42,
  "artifact_count": 3,
  "limitations": []
}
```

Required fields: `group_mode`, `host_pid`, `include_host`, `process_count`,
`artifact_count`, and `limitations`. `limitations` contains `scan_limitation`
objects. Scan-level limitations use `pid: null` when they do not belong to one
process.

`namespace_profile`:

```json
{
  "pid": "4026531836",
  "mnt": "mixed",
  "net": "4026531840",
  "user": "4026531837",
  "uts": "4026531838",
  "ipc": "4026531839",
  "cgroup": "4026531835",
  "time": null
}
```

Required fields: `pid`, `mnt`, `net`, `user`, `uts`, `ipc`, `cgroup`, and
`time`. Each value is a namespace ID string, `mixed`, or `null`.

`namespace_difference`:

```json
{
  "namespace_type": "pid",
  "host_id": "4026531836",
  "target_id": "4026532901",
  "differs": true
}
```

Required fields: `namespace_type`, `host_id`, `target_id`, and `differs`.
`host_id` and `target_id` use the same value rules as `namespace_profile`.
`differs` is `true`, `false`, or `null` when either side is missing or mixed in
a way that prevents a stable equality decision.

`artifact_summary`:

```json
{
  "artifact_id": "A1",
  "classification": "container-like",
  "score": 13,
  "leader_pid": 18342,
  "leader_ns_pid": 1,
  "process_count": 4,
  "runtime_hint": "kubernetes",
  "cgroup_hint": "kubepods",
  "leader_command": "nginx -g daemon off;",
  "leader_reason": "nested-pid-init"
}
```

Required fields: `artifact_id`, `classification`, `score`, `leader_pid`,
`leader_ns_pid`, `process_count`, `runtime_hint`, `cgroup_hint`,
`leader_command`, and `leader_reason`. Missing scalar values are `null`;
known no-hint values are `none`.

`source_statuses`:

```json
{
  "namespace": "ok",
  "status": "ok",
  "stat": "ok",
  "cmdline": "ok",
  "comm": "ok",
  "cgroup": "ok",
  "root": "ok",
  "exe": "ok"
}
```

Required fields: `namespace`, `status`, `stat`, `cmdline`, `comm`, `cgroup`,
`root`, and `exe`. Values use the `read_status` enum, except `partial` is valid
only for source readers that define partial-read semantics. For v1.0, the
required partial-read source is `mountinfo_read_status` in `mount_summary`.

`process_record`:

```json
{
  "host_pid": 18342,
  "ns_pid": 1,
  "ppid": 18301,
  "uid": 101,
  "user": "nginx",
  "state": "S",
  "start_time": 12345678,
  "command": "nginx -g daemon off;",
  "comm": "nginx",
  "exe_path": "/usr/sbin/nginx",
  "root_path": "/proc/18342/root",
  "root_target": "/",
  "read_status": "ok",
  "source_statuses": {
    "namespace": "ok",
    "status": "ok",
    "stat": "ok",
    "cmdline": "ok",
    "comm": "ok",
    "cgroup": "ok",
    "root": "ok",
    "exe": "ok"
  }
}
```

Required fields: `host_pid`, `ns_pid`, `ppid`, `uid`, `user`, `state`,
`start_time`, `command`, `comm`, `exe_path`, `root_path`, `root_target`,
`read_status`, and `source_statuses`. `read_status` summarizes process scan
viability; source-specific failures are represented in `source_statuses` and
matching `scan_limitation` objects when the failure affects requested output,
scoring, hints, target resolution, or classification explanation.

`mount_summary`:

```json
{
  "root_path": "/proc/18342/root",
  "root_target": "/",
  "mountinfo_read_status": "ok",
  "mount_count": 37,
  "overlay_or_snapshotter": false,
  "kubernetes_projected": true
}
```

Required fields: `root_path`, `root_target`, `mountinfo_read_status`,
`mount_count`, `overlay_or_snapshotter`, and `kubernetes_projected`.
`mountinfo_read_status` is `ok`, `partial`, `permission-denied`, or `vanished`.
When `mountinfo_read_status` is not `ok`, `mount_count`,
`overlay_or_snapshotter`, and `kubernetes_projected` are `null`.

`classification_reason`:

```json
{
  "code": "pid_ns_differs",
  "score_delta": 3,
  "detail": "pid namespace differs from host"
}
```

Required fields: `code`, `score_delta`, and `detail`.

`scan_limitation`:

```json
{
  "severity": "warning",
  "code": "permission_denied",
  "pid": 18342,
  "path": "/proc/18342/root",
  "source": "root",
  "read_status": "permission-denied",
  "message": "cannot read target root"
}
```

Required fields: `severity`, `code`, `pid`, `path`, `source`, `read_status`,
and `message`. `pid`, `path`, `source`, or `read_status` may be `null` for
limitations that are not tied to one proc source. Source-specific read failures
that affect public output must identify the source whenever the source is known.

`target_resolution`:

```json
{
  "input": "A1",
  "input_type": "artifact-id",
  "artifact_id": "A1",
  "host_pid": 18342
}
```

Required fields: `input`, `input_type`, `artifact_id`, and `host_pid`.

`artifact_detail`:

```json
{
  "summary": {
    "artifact_id": "A1",
    "classification": "container-like",
    "score": 13,
    "leader_pid": 18342,
    "leader_ns_pid": 1,
    "process_count": 4,
    "runtime_hint": "kubernetes",
    "cgroup_hint": "kubepods",
    "leader_command": "nginx -g daemon off;",
    "leader_reason": "nested-pid-init"
  },
  "namespace_profile": {
    "pid": "4026532901",
    "mnt": "4026532902",
    "net": "4026532905",
    "user": "4026531837",
    "uts": "4026532903",
    "ipc": "4026532904",
    "cgroup": "4026532906",
    "time": null
  },
  "host_namespace_profile": {
    "pid": "4026531836",
    "mnt": "4026531841",
    "net": "4026531840",
    "user": "4026531837",
    "uts": "4026531838",
    "ipc": "4026531839",
    "cgroup": "4026531835",
    "time": null
  },
  "namespace_differences": [],
  "cgroup_paths": [],
  "mount": {
    "root_path": "/proc/18342/root",
    "root_target": "/",
    "mountinfo_read_status": "ok",
    "mount_count": 37,
    "overlay_or_snapshotter": false,
    "kubernetes_projected": true
  },
  "processes": [],
  "classification_reasons": [],
  "limitations": []
}
```

Required fields: `summary`, `namespace_profile`, `host_namespace_profile`,
`namespace_differences`, `cgroup_paths`, `mount`, `processes`,
`classification_reasons`, and `limitations`.

`relationship`:

```json
{
  "left_artifact_id": "A1",
  "relationship": "shares-namespace",
  "namespace_type": "net",
  "namespace_id": "4026532905",
  "right_artifact_id": "A2",
  "detail": "same network namespace"
}
```

Required fields: `left_artifact_id`, `relationship`, `namespace_type`,
`namespace_id`, `right_artifact_id`, and `detail`. `namespace_id` is a known
namespace ID string. Relationships must not be emitted for missing or `mixed`
namespace values because no stable shared namespace identity exists.

### 10.3 JSON Command Documents

`nsurgn --format json list`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "list",
  "scan": {
    "group_mode": "profile",
    "host_pid": 1,
    "include_host": false,
    "process_count": 42,
    "artifact_count": 3,
    "limitations": []
  },
  "artifacts": []
}
```

`scan` is a `scan_context`; `artifacts` contains `artifact_summary` objects.

`nsurgn --format json inspect <artifact-id|pid>`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "inspect",
  "scan": {
    "group_mode": "profile",
    "host_pid": 1,
    "include_host": false,
    "process_count": 42,
    "artifact_count": 3,
    "limitations": []
  },
  "target": {
    "input": "A1",
    "input_type": "artifact-id",
    "artifact_id": "A1",
    "host_pid": 18342
  },
  "artifact": {
    "summary": {
      "artifact_id": "A1",
      "classification": "container-like",
      "score": 13,
      "leader_pid": 18342,
      "leader_ns_pid": 1,
      "process_count": 4,
      "runtime_hint": "kubernetes",
      "cgroup_hint": "kubepods",
      "leader_command": "nginx -g daemon off;",
      "leader_reason": "nested-pid-init"
    },
    "namespace_profile": {
      "pid": "4026532901",
      "mnt": "4026532902",
      "net": "4026532905",
      "user": "4026531837",
      "uts": "4026532903",
      "ipc": "4026532904",
      "cgroup": "4026532906",
      "time": null
    },
    "host_namespace_profile": {
      "pid": "4026531836",
      "mnt": "4026531841",
      "net": "4026531840",
      "user": "4026531837",
      "uts": "4026531838",
      "ipc": "4026531839",
      "cgroup": "4026531835",
      "time": null
    },
    "namespace_differences": [],
    "cgroup_paths": [],
    "mount": {
      "root_path": "/proc/18342/root",
      "root_target": "/",
      "mountinfo_read_status": "ok",
      "mount_count": 37,
      "overlay_or_snapshotter": false,
      "kubernetes_projected": true
    },
    "processes": [],
    "classification_reasons": [],
    "limitations": []
  }
}
```

`scan` is a `scan_context`, `target` is a `target_resolution`, and `artifact`
is an `artifact_detail`.

`nsurgn --format json ps <artifact-id|pid>`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "ps",
  "scan": {
    "group_mode": "profile",
    "host_pid": 1,
    "include_host": false,
    "process_count": 42,
    "artifact_count": 3,
    "limitations": []
  },
  "target": {
    "input": "A1",
    "input_type": "artifact-id",
    "artifact_id": "A1",
    "host_pid": 18342
  },
  "artifact": {
    "artifact_id": "A1",
    "classification": "container-like",
    "score": 13,
    "leader_pid": 18342,
    "leader_ns_pid": 1,
    "process_count": 4,
    "runtime_hint": "kubernetes",
    "cgroup_hint": "kubepods",
    "leader_command": "nginx -g daemon off;",
    "leader_reason": "nested-pid-init"
  },
  "processes": []
}
```

`scan` is a `scan_context`, `target` is a `target_resolution`, `artifact` is
an `artifact_summary`, and `processes` contains `process_record` objects.

`nsurgn --format json report [<artifact-id|pid>]`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "report",
  "scan": {
    "group_mode": "profile",
    "host_pid": 1,
    "include_host": false,
    "process_count": 42,
    "artifact_count": 3,
    "limitations": []
  },
  "target": null,
  "artifacts": []
}
```

When `report` is called with a target, `target` is a `target_resolution`
object and `artifacts` contains exactly one artifact detail object.

`nsurgn --format json map [<artifact-id|pid>]`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "map",
  "scan": {
    "group_mode": "profile",
    "host_pid": 1,
    "include_host": false,
    "process_count": 42,
    "artifact_count": 3,
    "limitations": []
  },
  "target": null,
  "relationships": []
}
```

`scan` is a `scan_context`; `target` is either `null` or a
`target_resolution`; `relationships` contains `relationship` objects.

`doctor`, `version`, and `help` may support JSON, but v1.0 only requires
stable structured schemas for `list`, `inspect`, `ps`, `report`, and `map`.

### 10.4 NDJSON Record Streams

NDJSON output writes one complete JSON object per line. Each object includes:

```text
schema_version
command
record_type
```

`list` emits one `artifact` record per listed artifact. `artifact` is an
`artifact_summary`:

```jsonl
{"schema_version":"nsurgn.output.v1","command":"list","record_type":"artifact","artifact":{"artifact_id":"A1","classification":"container-like","score":13,"leader_pid":18342,"leader_ns_pid":1,"process_count":4,"runtime_hint":"kubernetes","cgroup_hint":"kubepods","leader_command":"nginx -g daemon off;","leader_reason":"nested-pid-init"}}
```

`ps` emits one `process` record per visible process in the resolved artifact.
`process` is a `process_record`:

```jsonl
{"schema_version":"nsurgn.output.v1","command":"ps","record_type":"process","artifact_id":"A1","process":{"host_pid":18342,"ns_pid":1,"ppid":18301,"uid":101,"user":"nginx","state":"S","start_time":12345678,"command":"nginx -g daemon off;","comm":"nginx","exe_path":"/usr/sbin/nginx","root_path":"/proc/18342/root","root_target":"/","read_status":"ok","source_statuses":{"namespace":"ok","status":"ok","stat":"ok","cmdline":"ok","comm":"ok","cgroup":"ok","root":"ok","exe":"ok"}}}
```

`map` emits one `relationship` record per relationship. `relationship` is the
common `relationship` object:

```jsonl
{"schema_version":"nsurgn.output.v1","command":"map","record_type":"relationship","relationship":{"left_artifact_id":"A1","relationship":"shares-namespace","namespace_type":"net","namespace_id":"4026532905","right_artifact_id":"A2","detail":"same network namespace"}}
```

`inspect` and `report` emit detail records in stable section form. Namespace
profile records include `profile_scope` set to `artifact` or `host`. Cgroup path
records contain one `path` string per visible cgroup path:

```jsonl
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"artifact_summary","artifact":{"artifact_id":"A1","classification":"container-like","score":13,"leader_pid":18342,"leader_ns_pid":1,"process_count":4,"runtime_hint":"kubernetes","cgroup_hint":"kubepods","leader_command":"nginx -g daemon off;","leader_reason":"nested-pid-init"}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"namespace_profile","artifact_id":"A1","profile_scope":"artifact","namespace_profile":{"pid":"4026532901","mnt":"4026532902","net":"4026532905","user":"4026531837","uts":"4026532903","ipc":"4026532904","cgroup":"4026532906","time":null}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"namespace_profile","artifact_id":"A1","profile_scope":"host","namespace_profile":{"pid":"4026531836","mnt":"4026531841","net":"4026531840","user":"4026531837","uts":"4026531838","ipc":"4026531839","cgroup":"4026531835","time":null}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"namespace_difference","artifact_id":"A1","namespace_difference":{"namespace_type":"pid","host_id":"4026531836","target_id":"4026532901","differs":true}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"cgroup_path","artifact_id":"A1","path":"/kubepods.slice/pod123"}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"mount_summary","artifact_id":"A1","mount":{"root_path":"/proc/18342/root","root_target":"/","mountinfo_read_status":"ok","mount_count":37,"overlay_or_snapshotter":false,"kubernetes_projected":true}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"classification_reason","artifact_id":"A1","classification_reason":{"code":"pid_ns_differs","score_delta":3,"detail":"pid namespace differs from host"}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"process","artifact_id":"A1","process":{"host_pid":18342,"ns_pid":1,"ppid":18301,"uid":101,"user":"nginx","state":"S","start_time":12345678,"command":"nginx -g daemon off;","comm":"nginx","exe_path":"/usr/sbin/nginx","root_path":"/proc/18342/root","root_target":"/","read_status":"ok","source_statuses":{"namespace":"ok","status":"ok","stat":"ok","cmdline":"ok","comm":"ok","cgroup":"ok","root":"ok","exe":"ok"}}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"limitation","artifact_id":"A1","limitation":{"severity":"warning","code":"permission_denied","pid":18342,"path":"/proc/18342/root","source":"root","read_status":"permission-denied","message":"cannot read target root"}}
```

The same record types are used by `report`; `report` repeats records for each
reported artifact. A `scan_context` record may be emitted first for commands
where scan metadata is useful:

```jsonl
{"schema_version":"nsurgn.output.v1","command":"report","record_type":"scan_context","scan":{"group_mode":"profile","host_pid":1,"include_host":false,"process_count":42,"artifact_count":3,"limitations":[]}}
```

## 11. Command Flow

### 11.1 `list`

```text
parse options
scan visible processes
build artifacts
filter host artifacts unless --include-host
render artifact summaries
```

### 11.2 `inspect`

```text
parse target
scan visible processes
if target is host PID, resolve from full visible process scan
if target is artifact ID, filter host artifacts unless --include-host
if target is artifact ID, assign IDs and resolve against assigned IDs
render target metadata, namespace comparison, leader reason, and evidence
```

### 11.3 `ps`

```text
parse target
scan visible processes
if target is host PID, resolve from full visible process scan
if target is artifact ID, filter host artifacts unless --include-host
if target is artifact ID, assign IDs and resolve against assigned IDs
render process records for the artifact or PID-derived artifact
```

### 11.4 `report`

```text
scan visible processes
if no target, filter host artifacts unless --include-host
if target is host PID, resolve from full visible process scan
if target is artifact ID, filter host artifacts unless --include-host
if target is artifact ID, assign IDs and resolve against assigned IDs
render detailed artifact report and scan limitations
```

### 11.5 `map`

```text
scan visible processes
if no target, filter host artifacts unless --include-host
if target is host PID, resolve from full visible process scan
if target is artifact ID, filter host artifacts unless --include-host
if target is artifact ID, assign IDs and resolve against assigned IDs
derive shared namespace relationships using SPEC.md section 13.5
render relationship records or text summary
```

## 12. Major Design Decisions

### 12.1 Default to Raw TSV

Defaulting to raw TSV makes `nsurgn` useful in Unix pipelines without requiring flags, parsers, or runtime dependencies.

Tradeoff: interactive users must request `--format table` or `--format text` for presentation output.

### 12.2 Use One Scan Per Invocation

Each command performs one coherent scan and resolves artifacts within that scan.

Tradeoff: artifact IDs remain ephemeral and may differ between commands. This matches the spec and avoids persistent state.

### 12.3 Include User Namespace in Default Profile Grouping

Default `--group profile` groups by PID, mount, network, and user namespace. These are the major namespace differences that cause artifacts to appear in default `list` output. UTS, IPC, cgroup, and time namespace differences remain evidence for scoring, inspection, reporting, and strict grouping, but they do not trigger default listing by themselves.

Tradeoff: user namespace differences may split some workloads that would otherwise share PID, mount, and network namespaces, but that split is useful because user namespace isolation materially changes privilege interpretation.

### 12.4 Use Temp-File Records Internally

Temp-file records are simpler, more inspectable, and more testable than trying to model nested structures in Bash arrays.

Tradeoff: implementation must manage cleanup and avoid exposing internal files as a stable public API.

### 12.5 Keep Renderers Isolated

Renderers are the only place that should know about raw escaping, table alignment, JSON escaping, or NDJSON record construction.

Tradeoff: command views need to provide enough normalized data for every renderer.

### 12.6 Keep Public Scores Comparable

`SPEC.md` defines the v1.0 scoring table as normative. The scan engine should
compute `score` from those numeric signals only, counting each numeric signal at
most once per artifact, while keeping non-numeric rows as classification reasons
or flags.

Tradeoff: adding new public score weights requires a spec update, but scripts
and operators can compare scores across v1.0 implementations and invocations.

## 13. Acceptance Fixture Plan

Acceptance fixtures should exercise the resolved v1.0 behavior from `SPEC.md`
without turning the fixture set into production implementation. The fixture set
must include positive cases that trigger the behavior and important near-miss,
failure, or visibility cases where the spec distinguishes them.

Fixture names may vary, but each fixture should identify the source behavior it
covers and keep `/proc` input files small enough for focused review.

| Area | Positive fixtures | Near-miss, failure, or visibility fixtures | Expected acceptance checks |
|---|---|---|---|
| Anomaly trigger: runtime-backed artifact with host root | Artifact with at least one major namespace difference, readable member `root_target` equal to host root, and a runtime hint from cgroup, mountinfo, or runtime evidence. | Same runtime hint and host root but no major namespace difference; same major namespace difference and host root but no runtime hint; unreadable `root_target` with otherwise matching evidence. | Classification is `anomalous` only for the positive fixture and includes `anomaly_runtime_hint_host_root`; near-misses are not `anomalous` and expose limitations for unreadable metadata where applicable. |
| Anomaly trigger: root differs without mount namespace difference | Process with a major namespace difference outside mount namespace, readable member `root_target` differing from host root, and mount namespace equal to the host profile. | Differing root target with mount namespace also differing; same root target with host mount namespace; unreadable `mountinfo` or `root_target`; minor-only namespace difference. | Classification is `anomalous` only for the positive fixture and includes `anomaly_root_diff_without_mnt_ns`; missing required evidence never satisfies the trigger. |
| Anomaly trigger: runtime hint without PID or mount isolation | Artifact with a known major namespace difference, PID and mount namespace IDs equal to host profile, and at least one runtime hint. | Runtime hint with no major namespace difference; runtime hint with PID or mount namespace isolation; unreadable PID or mount namespace; minor-only namespace difference. | Classification is `anomalous` only for the positive fixture and includes `anomaly_runtime_hint_without_pid_mnt_ns`; spoofable runtime evidence alone is insufficient. |
| Anomaly trigger: nested PID init with deleted executable | Member process with nested PID namespace init evidence, executable path ending in `(deleted)`, and artifact PID namespace differing from host profile. | Deleted executable without nested PID init; nested PID init with non-deleted executable; unreadable `exe`; PID namespace equal to host profile. | Classification is `anomalous` only for the positive fixture and includes `anomaly_nested_pid_init_deleted_exe`; unreadable executable metadata is a limitation, not anomaly evidence. |
| Target visibility | Host PID target resolving to a host-equivalent artifact hidden from default broad output; host PID target resolving to a minor-only cgroup grouped artifact; artifact hidden by default but visible with `--include-host`. | Artifact ID target for a hidden default artifact without `--include-host`; artifact ID target after visibility changes alter ID assignment; nonexistent host PID target. | Host PID targets resolve from the full visible process scan; artifact ID targets resolve only after command visibility filtering; hidden artifact ID targets fail according to `SPEC.md` section 16.3. |
| Exit-code materiality | Broad command with ordinary unreadable `root`, `exe`, `mountinfo`, `cmdline`, `status`, or `cgroup` represented as limitations while primary output remains coherent. | Targeted command where unreadable metadata prevents target resolution or primary output; targeted command where primary output exists but requested detail is materially incomplete; vanished target process; vanished non-target member during broad scan. | Exit codes follow `SPEC.md` section 16.3: non-material broad limitations stay `0`, material incomplete targeted detail exits `6`, unresolved vanished targets exit `4` or `7` as applicable, and ordinary vanished non-target members in broad scans remain limitations unless coherent primary output cannot be produced. |
| Hint availability | Artifact with no matching hint and all relevant cgroup, mountinfo, command, process name, and executable source families readable. | Same no-hint artifact with one relevant source family unreadable, vanished, or partial; artifact with unreadable lower-precedence source but a higher-precedence readable hint. | Hint fields emit `none` only for known no-hint values; they emit missing values when a relevant source family prevents knowing that no hint exists, unless a higher-precedence readable hint matched. Limitation rows identify the unavailable source family. |
| Host root target failure | Default host profile with readable `/proc/1/root`; `--host-pid` profile with readable `/proc/<host-pid>/root`; artifact root comparisons against that readable target. | Default host root unreadable; `--host-pid` root unreadable; host PID vanishes before root target read; otherwise matching root anomaly evidence without a readable host-profile root target. | Host root failure disables root equality and difference evidence for the scan, emits a scan limitation, and changes the exit code only when requested target detail or explanation materially depends on root comparison. |
| JSON and NDJSON string rendering | Command output containing quotes, backslashes, tabs, newlines, carriage returns, empty readable strings, missing values, ordinary printable command lines, and command-line NUL separators normalized to spaces. | Missing or unreadable metadata for fields that otherwise contain strings; empty readable `cmdline` distinct from missing `cmdline`; multiple NDJSON records with escaped fields. | JSON documents and every NDJSON record parse successfully with tools available in the test environment; escapes follow section 8.4; NDJSON emits one complete JSON object per line. These checks must not add a production runtime dependency on `jq`, Python, or external JSON generators. |
| Map relationships | Artifacts sharing network namespace; artifacts sharing mount namespace; grouped artifacts sharing cgroup when `--group cgroup` is selected; strict-group artifacts sharing UTS, IPC, cgroup, or time namespace. | Artifacts with no shared major namespaces; duplicate relationship candidates; missing namespace IDs; hidden host-equivalent peer in default broad output; host PID target that resolves to a hidden artifact. | `map` emits only `shares-namespace` rows; no self-relationships or duplicate identity rows are emitted; targeted map includes only rows involving the target artifact; peer visibility follows `SPEC.md` section 12.4. |
| Raw escaping parity | Raw fields containing tabs, newlines, carriage returns, backslashes, and `/proc/<pid>/cmdline` NUL separators. | Missing values and empty readable values in adjacent fields. | Raw output uses section 8.1 escaping and keeps one record per physical line with literal tab separators between fields. |
| Human table/text contracts | `list`, `ps`, and `map` table output containing the minimum facts from `SPEC.md` section 15.2; `inspect`, `report`, `map`, `doctor`, `version`, and `help` text output containing the minimum facts from section 15.3. | Narrow terminal width; long command strings; missing optional metadata; warnings or limitations present; no map relationships. | Required facts are present in human output, diagnostics are absent from stdout, missing values remain understandable, no exact whitespace or section-order snapshot is required, and scripts are documented to use raw, JSON, or NDJSON. |

Acceptance tests should validate both output content and parseability. JSON and
NDJSON parseability checks are test-environment requirements only; renderers
must still construct valid output using the Bash implementation rules in
section 8.4.

Human output acceptance checks validate required content and readability only.
They must not fail solely because spacing, wrapping, column width, section
order, or wording changed while the required facts remain present.

## 14. Risks and Follow-Up Design Work

JSON and NDJSON rendering in Bash is the highest-risk formatting area. The implementation needs a small, heavily tested JSON string escaper.

Raw escaping must be tested with command lines and paths containing tabs, newlines, carriage returns, and backslashes.

The JSON and NDJSON schemas are now defined for discovery and inspection commands. `doctor`, `version`, and `help` can add structured schemas later if needed.

The first implementation milestone should keep `raw` and basic human
help/version/doctor stable before adding richer renderers. Human renderer
polish can evolve without breaking v1.0 as long as the required table/text facts
remain present.
