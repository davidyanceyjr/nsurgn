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

Artifact IDs are assigned after sorting artifact groups and are valid only for the current invocation.

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

Each line must be one complete JSON object. This is most useful for `list`, `ps`, and possibly relationship records from `map`.

## 9. Command Output Contracts

The exact field names can be refined during contract work, but v1 should preserve these raw field orders once implemented.

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

Default raw output should be key-value records because the shape is not naturally tabular:

```text
section	key	value
```

Example sections:

```text
target
leader
classification
namespace
cgroup
process
evidence
limitation
```

### 9.4 `report [<artifact-id|pid>]`

Default raw output should also use:

```text
section	key	value
```

When reporting multiple artifacts, include `artifact_id`:

```text
artifact_id	section	key	value
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

## 10. Command Flow

### 10.1 `list`

```text
parse options
scan visible processes
build artifacts
filter host artifacts unless --include-host
render artifact summaries
```

### 10.2 `inspect`

```text
parse target
scan visible processes
resolve target against current scan
render target metadata, namespace comparison, leader reason, and evidence
```

### 10.3 `ps`

```text
parse target
scan visible processes
resolve target against current scan
render process records for the artifact or PID-derived artifact
```

### 10.4 `report`

```text
scan visible processes
resolve optional target
render detailed artifact report and scan limitations
```

### 10.5 `map`

```text
scan visible processes
derive shared namespace relationships
render relationship records or text summary
```

## 11. Major Design Decisions

### 11.1 Default to Raw TSV

Defaulting to raw TSV makes `nsurgn` useful in Unix pipelines without requiring flags, parsers, or runtime dependencies.

Tradeoff: interactive users must request `--format table` or `--format text` for presentation output.

### 11.2 Use One Scan Per Invocation

Each command performs one coherent scan and resolves artifacts within that scan.

Tradeoff: artifact IDs remain ephemeral and may differ between commands. This matches the spec and avoids persistent state.

### 11.3 Use Temp-File Records Internally

Temp-file records are simpler, more inspectable, and more testable than trying to model nested structures in Bash arrays.

Tradeoff: implementation must manage cleanup and avoid exposing internal files as a stable public API.

### 11.4 Keep Renderers Isolated

Renderers are the only place that should know about raw escaping, table alignment, JSON escaping, or NDJSON record construction.

Tradeoff: command views need to provide enough normalized data for every renderer.

## 12. Risks and Follow-Up Design Work

JSON and NDJSON rendering in Bash is the highest-risk formatting area. The implementation needs a small, heavily tested JSON string escaper.

Raw escaping must be tested with command lines and paths containing tabs, newlines, carriage returns, and backslashes.

The detailed JSON object schema should be finalized before implementation of `--format json` and `--format ndjson`.

The first implementation milestone should keep `raw` and basic human help/version/doctor stable before adding richer renderers.
