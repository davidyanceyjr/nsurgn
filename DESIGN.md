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
artifact.tsv
artifact_process.tsv
classification_reason.tsv
scan_warning.tsv
```

The workspace is internal and not a public interface. It still should use stable, documented field order so tests can inspect it directly.

The workspace must be cleaned up on normal exit and common signals.

## 6. Internal Record Contracts

Internal records are tab-separated. Missing values use `-`. Fields that may contain tabs, newlines, or carriage returns use the same escaping rules as raw output.

Hint fields use `none` when the relevant metadata was readable and no known hint
was found. They use `-` when the relevant metadata was unavailable or unreadable.

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
exe_path
comm
cmdline
read_status
```

`read_status` is `ok`, `partial`, `permission-denied`, or `vanished`.

### 6.2 `artifact.tsv`

```text
artifact_id
group_key
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

### 6.3 `artifact_process.tsv`

```text
artifact_id
host_pid
role
```

`role` is `leader` or `member`.

### 6.4 `classification_reason.tsv`

```text
artifact_id
reason_code
score_delta
detail
```

Reason codes should be stable lower-case identifiers such as `pid_ns_differs`, `runtime_hint_containerd`, or `nested_pid_init`.

### 6.5 `scan_warning.tsv`

```text
severity
code
pid
path
message
```

Warnings are rendered to stderr unless `--quiet` suppresses non-critical warnings.

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

Table output may include headers. It should remain readable in typical terminals, but correctness must not depend on terminal width.

### 8.3 `text`

Human-facing labeled reports. Opt-in.

Text output is appropriate for `inspect`, `report`, `map`, `doctor`, `help`, and `version`.

### 8.4 `json`

Structured document output. Opt-in.

JSON output must use valid JSON string escaping and must not require `jq`, Python, or another external generator.

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
classification	label	<classification>
classification	score	<score>
classification	runtime_hint	<runtime-hint-or-none-or-missing>
classification	cgroup_hint	<cgroup-hint-or-none-or-missing>
mount	root_path	<path-or-missing>
mount	mountinfo_read_status	ok|partial|permission-denied|vanished
mount	mount_count	<count-or-missing>
mount	overlay_or_snapshotter	true|false|-
mount	kubernetes_projected	true|false|-
```

For each namespace type, emit these rows using the namespace type in the key:

```text
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.target	<namespace-id-or-missing>
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.host	<namespace-id-or-missing>
namespace	<pid|mnt|net|user|uts|ipc|cgroup|time>.differs	true|false|-
```

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
process	<index>.read_status	ok|partial|permission-denied|vanished
process	<index>.comm	<escaped-comm-or-missing>
process	<index>.command	<escaped-command-or-missing>
process	<index>.exe_path	<path-or-missing>
process	<index>.root_path	<path-or-missing>
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
limitation	<index>.message	<escaped-message>
```

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
- namespace IDs are JSON strings without the namespace type wrapper, for example `4026531836`;
- command lines and paths are JSON strings with standard JSON escaping;
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
             classification_reason, process, relationship, limitation
```

### 10.2 Common Types

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

`namespace_profile`:

```json
{
  "pid": "4026531836",
  "mnt": "4026531841",
  "net": "4026531840",
  "user": "4026531837",
  "uts": "4026531838",
  "ipc": "4026531839",
  "cgroup": "4026531835",
  "time": null
}
```

`namespace_difference`:

```json
{
  "namespace_type": "pid",
  "host_id": "4026531836",
  "target_id": "4026532901"
}
```

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
  "read_status": "ok"
}
```

`classification_reason`:

```json
{
  "code": "pid_ns_differs",
  "score_delta": 3,
  "detail": "pid namespace differs from host"
}
```

`scan_limitation`:

```json
{
  "severity": "warning",
  "code": "permission_denied",
  "pid": 18342,
  "path": "/proc/18342/root",
  "message": "cannot read target root"
}
```

`target_resolution`:

```json
{
  "input": "A1",
  "input_type": "artifact-id",
  "artifact_id": "A1",
  "host_pid": 18342
}
```

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
  "processes": [],
  "classification_reasons": [],
  "limitations": []
}
```

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

`nsurgn --format json inspect <artifact-id|pid>`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "inspect",
  "scan": {},
  "target": {},
  "artifact": {}
}
```

`scan` is a `scan_context`, `target` is a `target_resolution`, and `artifact`
is an `artifact_detail`.

`nsurgn --format json ps <artifact-id|pid>`:

```json
{
  "schema_version": "nsurgn.output.v1",
  "command": "ps",
  "scan": {},
  "target": {},
  "artifact": {},
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
  "scan": {},
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
  "scan": {},
  "target": null,
  "relationships": []
}
```

`scan` is a `scan_context`; `target` is either `null` or a
`target_resolution`; `relationships` contains `relationship` objects.

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

`doctor`, `version`, and `help` may support JSON, but v1.0 only requires
stable structured schemas for discovery and inspection commands.

### 10.4 NDJSON Record Streams

NDJSON output writes one complete JSON object per line. Each object includes:

```text
schema_version
command
record_type
```

`list` emits one `artifact` record per listed artifact:

```json
{"schema_version":"nsurgn.output.v1","command":"list","record_type":"artifact","artifact":{}}
```

`ps` emits one `process` record per visible process in the resolved artifact:

```json
{"schema_version":"nsurgn.output.v1","command":"ps","record_type":"process","artifact_id":"A1","process":{}}
```

`map` emits one `relationship` record per relationship:

```json
{"schema_version":"nsurgn.output.v1","command":"map","record_type":"relationship","relationship":{}}
```

`inspect` and `report` emit detail records in stable section form:

```json
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"artifact_summary","artifact":{}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"namespace_difference","artifact_id":"A1","namespace_difference":{}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"classification_reason","artifact_id":"A1","classification_reason":{}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"process","artifact_id":"A1","process":{}}
{"schema_version":"nsurgn.output.v1","command":"inspect","record_type":"limitation","artifact_id":"A1","limitation":{}}
```

The same record types are used by `report`; `report` repeats records for each
reported artifact. A `scan_context` record may be emitted first for commands
where scan metadata is useful:

```json
{"schema_version":"nsurgn.output.v1","command":"report","record_type":"scan_context","scan":{}}
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
resolve target against current scan
render target metadata, namespace comparison, leader reason, and evidence
```

### 11.3 `ps`

```text
parse target
scan visible processes
resolve target against current scan
render process records for the artifact or PID-derived artifact
```

### 11.4 `report`

```text
scan visible processes
resolve optional target
render detailed artifact report and scan limitations
```

### 11.5 `map`

```text
scan visible processes
derive shared namespace relationships
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

## 13. Risks and Follow-Up Design Work

JSON and NDJSON rendering in Bash is the highest-risk formatting area. The implementation needs a small, heavily tested JSON string escaper.

Raw escaping must be tested with command lines and paths containing tabs, newlines, carriage returns, and backslashes.

The JSON and NDJSON schemas are now defined for discovery and inspection commands. `doctor`, `version`, and `help` can add structured schemas later if needed.

The first implementation milestone should keep `raw` and basic human help/version/doctor stable before adding richer renderers.
