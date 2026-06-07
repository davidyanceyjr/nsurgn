# nsurgn v1.0 Specification

Project: `nsurgn`
Meaning: namespace surgeon
Release scope: v1.0 foundation
Primary platform: Linux
Primary interface: command-line utility
Core dependency posture: Linux procfs and standard Linux utilities

---

## 1. Purpose

`nsurgn` is a Linux-native command-line utility for discovering, modeling, classifying, inspecting, and reporting visible Linux namespace artifacts.

Linux does not expose containers as first-class kernel objects. It exposes processes, namespaces, cgroups, mounts, root filesystem views, file descriptors, signals, and process metadata through `/proc` and related Linux interfaces.

`nsurgn v1.0` establishes the foundation required for all later capabilities:

- process discovery,
- namespace reading,
- host profile comparison,
- artifact grouping,
- leader selection,
- classification,
- target resolution,
- process listing,
- reporting,
- environment diagnostics,
- stable output and error behavior.

`nsurgn v1.0` must report kernel-visible facts and evidence. It must not claim that an artifact is definitely a Docker container, Podman container, Kubernetes pod, Flatpak sandbox, Chrome sandbox, systemd-nspawn instance, bubblewrap process, `unshare` process, or hand-built namespace environment.

Runtime and cgroup evidence may be displayed as evidence. It must be framed as evidence, not proof.

---

## 2. Product Boundary

`nsurgn v1.0` is a read-only discovery and inspection release.

It must not mutate artifact filesystems, control target processes, execute commands in target namespaces, or depend on runtime APIs.

The v1.0 boundary is intentional. Later features rely on the correctness of artifact grouping and leader selection. If the model is wrong, later operational commands can act on the wrong target. v1.0 therefore proves the model first.

---

## 3. Goals

### 3.1 Discover Namespace Artifacts

`nsurgn` should group visible processes by namespace relationships and supporting Linux metadata.

Default discovery should surface namespace artifacts that differ meaningfully from the host profile. For default discovery, meaningful namespace differences are PID, mount, network, or user namespace differences. It should not dump every PID by default.

### 3.2 Classify Honestly

The tool should use evidence-based classifications:

- `host`
- `isolated`
- `namespace-managed`
- `container-like`
- `anomalous`

It must not state that a process group is definitely a container unless the operator provides external confirmation.

### 3.3 Explain the Linux Substrate

Reports should expose:

- namespace IDs,
- host namespace differences,
- cgroup hints,
- process relationships,
- leader selection reasons,
- classification reasons,
- visible process metadata,
- target root path when readable.

### 3.4 Stay Runtime Independent

Core functionality must not depend on:

- Docker
- Podman
- Kubernetes
- containerd APIs
- CRI-O APIs
- `kubectl`
- `crictl`
- `ctr`
- `nerdctl`
- `runc` APIs
- `jq`
- Python
- Go dependencies
- third-party SDKs

### 3.5 Provide Scriptable Output

The command line interface should be useful for both humans and scripts.

v1.0 should support:

- tab-separated raw record streams,
- readable terminal tables,
- structured JSON output,
- line-oriented NDJSON output where appropriate,
- stable exit codes,
- clear error messages.

---

## 4. Non-Goals

`nsurgn v1.0` is not:

- a Docker replacement,
- a Podman replacement,
- a Kubernetes client,
- a CRI client,
- a container runtime,
- a workload scheduler,
- a container image manager,
- a sandbox,
- a privilege escalation tool,
- a filesystem repair tool,
- a process control tool,
- a command execution wrapper,
- a memory injection tool,
- a shellcode framework,
- a ptrace injection framework,
- a complete forensic suite,
- proof that a workload is a container.

---

## 5. Target Users

Primary users:

- Linux systems engineers
- SREs
- platform engineers
- security engineers
- incident responders
- Kubernetes node debuggers
- runtime engineers
- infrastructure operators
- Linux forensic analysts

Expected familiarity:

- Linux processes
- `/proc`
- namespaces
- cgroups
- mount namespaces
- PID namespaces
- host PIDs versus namespace PIDs
- privilege boundaries

---

## 6. Core Concepts

### 6.1 Process

The fundamental unit of observation is the Linux process. Every artifact discovered by `nsurgn` is composed of one or more visible host PIDs.

### 6.2 Namespace Profile

A namespace profile is the tuple of namespace IDs associated with a process.

Canonical tuple:

```text
pid_ns
mnt_ns
net_ns
user_ns
uts_ns
ipc_ns
cgroup_ns
time_ns
```

Not every kernel exposes every namespace type. Missing namespace fields should be handled gracefully.

### 6.3 Host Profile

The host profile is the namespace profile used as the baseline for comparison.

Default host profile source:

```text
/proc/1/ns/*
```

The operator may override this baseline with:

```text
--host-pid <pid>
```

### 6.4 Artifact

An artifact is an inferred operational unit composed of one or more processes related by shared namespace membership and supporting metadata.

An artifact is not a kernel object.

An artifact may correspond to:

- a container,
- a pod component,
- a systemd service with private namespaces,
- an LXC guest,
- a build sandbox,
- a manually created `unshare` environment,
- a test harness,
- a compromised process namespace,
- something else.

### 6.5 Leader

The leader is the best representative process for an artifact.

Leader selection order:

1. Prefer a process that is PID 1 inside a nested PID namespace.
2. Otherwise, prefer the oldest process in the artifact.
3. Otherwise, prefer the lowest host PID.

Leader selection must be deterministic for a fixed artifact member set.

Eligibility:

- A vanished process is not eligible to be leader.
- A process with `read_status` `ok`, `partial`, or `permission-denied` is
  eligible when its host PID is known.
- Missing metadata prevents a process from satisfying the rule that needs that
  metadata, but does not prevent fallback selection by host PID.

Namespace PID source:

- The namespace PID is read from the `NSpid:` line in `/proc/<pid>/status` when
  available.
- If `NSpid:` has multiple numeric values, use the last value as the process PID
  in its innermost visible PID namespace.
- If `NSpid:` is absent or unreadable, the namespace PID is unknown.

Nested PID namespace init detection:

- A process is a nested PID namespace init candidate when its PID namespace ID is
  known, differs from the host profile PID namespace ID, and its namespace PID is
  `1`.

Tie-breaks:

1. Among nested PID namespace init candidates, choose the candidate with the
   lowest known `start_time` from `/proc/<pid>/stat`. If no candidate has known
   `start_time`, or if candidates tie, choose the lowest host PID.
2. For oldest-process selection, choose the eligible process with the lowest
   known `start_time`. If multiple eligible processes share that `start_time`,
   choose the lowest host PID.
3. For lowest-host-PID fallback, choose the lowest known host PID among eligible
   processes.

Leader reason values:

```text
nested-pid-init
oldest-process
lowest-host-pid
```

If no eligible process remains after vanished processes are excluded, broad
discovery omits that artifact and records a scan limitation when possible.
Target-specific commands whose requested artifact loses all eligible members
must fail with `process-changed`.

The leader is used for:

- artifact identity,
- default inspection target,
- process metadata summary,
- target root reporting,
- classification evidence.

### 6.6 Target Root

The target root is the filesystem view exposed by:

```text
/proc/<leader_pid>/root
```

v1.0 may report this path when readable. It must not use it for mutation.

---

## 7. Data Sources

v1.0 may read:

```text
/proc/<pid>/ns/*
/proc/<pid>/status
/proc/<pid>/stat
/proc/<pid>/cmdline
/proc/<pid>/comm
/proc/<pid>/cgroup
/proc/<pid>/root
/proc/<pid>/exe
/proc/<pid>/mountinfo
```

v1.0 may use standard Linux utilities when available:

```text
readlink
stat
ps
awk
sed
grep
sort
uniq
find
```

The implementation must tolerate:

- vanished PIDs,
- permission-denied reads,
- missing namespace files,
- unreadable root or executable links,
- procfs restrictions such as `hidepid`,
- kernel differences across distributions.

---

## 8. Discovery Model

Discovery steps:

1. Enumerate visible numeric PIDs under `/proc`.
2. For each PID, read namespace links and process metadata.
3. Build a namespace profile for each process.
4. Determine the host namespace profile.
5. Group processes according to the selected grouping mode.
6. Select a leader for each group.
7. Score each group.
8. Classify each group.
9. Hide `host` artifacts from default `list` output.
10. Display namespace artifacts that differ meaningfully from the host profile.

For default discovery, an artifact differs meaningfully from the host profile when its PID, mount, network, or user namespace differs from the host profile. UTS, IPC, cgroup, and time namespace differences are still recorded and reported as evidence, but by themselves do not cause an artifact to appear in default `list` output.

---

## 9. Grouping Modes

### 9.1 `--group profile`

Default.

Group by:

```text
pid_ns + mnt_ns + net_ns + user_ns
```

Rationale:

This balances usefulness and noise. PID, mount, network, and user namespaces are strong workload-boundary signals without fragmenting on weaker namespace differences by default.

### 9.2 `--group strict`

Group by the full namespace tuple:

```text
pid_ns + mnt_ns + net_ns + user_ns + uts_ns + ipc_ns + cgroup_ns + time_ns
```

Useful for forensic precision.

### 9.3 `--group pid`

Group by PID namespace.

Useful for understanding nested PID namespace relationships.

### 9.4 `--group mnt`

Group by mount namespace.

Useful for filesystem-view investigation.

### 9.5 `--group net`

Group by network namespace.

Useful for network isolation mapping.

### 9.6 `--group cgroup`

Group by cgroup-derived hints.

Useful when namespace isolation is weak but cgroup structure is meaningful.

The cgroup group key is derived from `/proc/<pid>/cgroup` for each visible PID.
Every visible PID must receive exactly one cgroup group key.

Parsing rules:

- Parse each cgroup line as `hierarchy_id:controllers:path`, splitting only on
  the first two colons. The remaining text is the cgroup path.
- Treat an empty path as `/`.
- Preserve path text exactly as reported by procfs after the empty-path rule.
  Do not resolve symlinks, infer runtime names, or rewrite path components.
- Ignore blank lines.

Key selection rules:

1. If a unified cgroup v2 line is present, use the first line whose hierarchy
   ID is `0` and whose controllers field is empty. The group key is:

   ```text
   cgroup:v2:<path>
   ```

2. Otherwise, use all parsed cgroup v1 lines. For each line, split controllers
   on comma, sort controller names bytewise, rejoin them with comma, and pair
   that controller list with the path. Sort the pairs bytewise by controller
   list and then path. The group key is:

   ```text
   cgroup:v1:<controllers>=<path>[;<controllers>=<path>...]
   ```

3. If `/proc/<pid>/cgroup` is missing, unreadable, empty after blank lines are
   ignored, or contains no parseable line, use:

   ```text
   cgroup:unknown
   ```

If a process has both a unified cgroup v2 line and cgroup v1 lines, the v2 key
wins. The v1 lines remain evidence but do not affect the cgroup group key.

`--group cgroup` changes only group identity. It does not change the
classification model or default visibility rules. A cgroup-grouped artifact is
classified from the aggregate evidence of its member processes. It is hidden
from default `list` output when the aggregate has no known PID, mount, network,
or user namespace difference from the host profile. Minor-only namespace
differences and cgroup path differences remain reportable evidence, and become
visible in `list` when `--include-host` is used or when the artifact is targeted
explicitly by a command that accepts a PID or artifact target.

---

## 10. Classification Model

### 10.1 Labels

#### `host`

No known major namespace difference from the host profile. Hidden by default.

For classification, major namespace types are PID, mount, network, and user.
UTS, IPC, cgroup, and time namespace differences are minor namespace
differences. Minor-only differences are recorded as evidence, but they do not
make an artifact non-host by themselves.

#### `isolated`

Differs from host in one or more major namespace types, but does not have enough evidence to infer origin, runtime backing, or anomaly.

Major namespace types:

- PID
- mount
- network
- user

#### `namespace-managed`

Appears intentionally isolated by Linux namespace tooling or host service management, without strong container runtime or platform backing evidence.

This label may be supported by evidence such as a nested PID namespace init process, `systemd` cgroup context, `unshare`-style process metadata, private mount namespaces, or other host-managed namespace patterns.

#### `container-like`

Has namespace isolation plus cgroup, runtime, container ID, overlay, snapshotter, or Kubernetes-style hints.

This is a probability-oriented label, not proof.

#### `anomalous`

Has major namespace isolation plus namespace, process, filesystem, permission, or metadata patterns that are unusual, inconsistent, or difficult to explain from visible evidence.

This label means the artifact deserves operator attention. It is not a claim that the artifact is malicious.

### 10.2 Scoring Model

The scoring table is normative for v1.0. Implementations must compute the
public `score` field from the numeric point signals in this table so that
sorting, raw output, JSON, and NDJSON remain comparable across implementations.
The score is the sum of detected numeric signals for the artifact. Each numeric
signal may contribute at most once per artifact, even when multiple member
processes expose the same signal. Process-scoped signals apply when one or more
member processes exposes the signal; the corresponding classification reason
should identify representative evidence such as a PID, path, namespace type, or
matched metadata value.

Rows without numeric points are classification evidence or flags; they do not
add directly to the score.

Implementations may emit additional classification reasons when visible
evidence supports them, but v1.0 implementations must not introduce additional
public score weights without a spec update. Classification still uses the rule
evidence in section 10.3; score alone must not determine the label.

| Signal | Points |
|---|---:|
| PID namespace differs from host | +3 |
| Mount namespace differs from host | +3 |
| Network namespace differs from host | +2 |
| User namespace differs from host | +2 |
| UTS namespace differs from host | +1 |
| IPC namespace differs from host | +1 |
| Cgroup namespace differs from host | +1 |
| Time namespace differs from host | +1 |
| Process is PID 1 inside nested PID namespace | +4 |
| Cgroup path contains `kubepods` | +4 |
| Cgroup path contains `containerd` | +4 |
| Cgroup path contains `docker` | +4 |
| Cgroup path contains `crio` | +4 |
| Cgroup path contains `libpod` | +4 |
| Cgroup path contains `lxc` | +3 |
| Cgroup path contains `machine.slice` | +2 |
| Cgroup path contains long hex container-like ID | +2 |
| Root filesystem differs from host root | +2 |
| Mountinfo contains overlay or snapshotter hints | +3 |
| Mountinfo contains Kubernetes projected or serviceaccount mounts | +2 |
| Executable path is deleted | +2 |
| Nested PID namespace init without runtime hints | namespace-managed evidence |
| Contradictory or hard-to-explain isolation evidence | anomalous flag |

### 10.3 Classification Rules

Classification uses both score and rule evidence. Score communicates evidence strength; labels communicate the most useful operator-facing category. Score alone must not determine the label.

Classification must be deterministic for a fixed scan result. The classifier
uses only namespace IDs and evidence visible in the current scan. Missing or
unreadable metadata must be represented as a limitation or reason, but it must
not be treated as proof that a namespace differs from the host profile.

Non-host labels require at least one known major namespace difference from the
host profile. If no PID, mount, network, or user namespace is known to differ
from the host profile, the artifact is classified as `host`, even when minor
namespace differences or non-namespace hints are present.

When an artifact has one or more known major namespace differences, choose the
primary label by this precedence:

1. `anomalous`
2. `container-like`
3. `namespace-managed`
4. `isolated`

Higher-precedence labels do not discard lower-precedence evidence. For example,
an artifact with container runtime hints and unusual inconsistent metadata is
classified as `anomalous`, while the runtime hints remain visible in the
classification reasons.

```text
host:
  no known PID, mount, network, or user namespace difference from the host
  profile

anomalous:
  one or more known major namespace differences plus concerning, inconsistent,
  incomplete, or hard-to-explain evidence

container-like:
  one or more known major namespace differences plus strong runtime, platform,
  cgroup, filesystem, overlay, snapshotter, or Kubernetes-style evidence

namespace-managed:
  one or more known major namespace differences plus evidence of deliberate
  Linux namespace tooling or host service management, without anomalous evidence
  or strong runtime or platform backing

isolated:
  one or more known major namespace differences, but insufficient evidence for
  anomalous, container-like, or namespace-managed

nested PID namespace with ns pid 1:
  strong evidence for namespace-managed unless anomalous evidence or
  runtime/platform evidence selects a higher-precedence primary label
```

### 10.4 Classification Limitation

A process group can look container-like without being a container. A process group can also be a real container while hiding runtime hints. A process group can be intentionally namespace-managed without being runtime-backed. `nsurgn` reports evidence, not certainty.

### 10.5 Evidence and Hint Normalization

Hints are normalized summaries of visible evidence. They are not runtime
identity claims. Classification reasons are the detailed evidence records used
to explain scoring and labels; hints are compact fields intended for list,
report, JSON, and NDJSON consumers.

Hint fields are single-valued:

- `runtime_hint` reports the highest-precedence runtime or platform hint.
- `cgroup_hint` reports the highest-precedence cgroup-path hint.
- Additional matched evidence must be emitted as classification reasons instead
  of being concatenated into a composite hint.

Canonical missing and no-hint values:

- In raw output and internal TSV records, unavailable or unreadable scalar values
  use `-`.
- In JSON and NDJSON output, unavailable or unreadable scalar values use `null`.
- Empty repeated values use no rows in raw output and an empty array in JSON.
- Hint fields use `none` when relevant metadata was readable and no known hint
  was found.
- Hint fields use the missing scalar value when relevant metadata was not
  available to evaluate.

Canonical `cgroup_hint` values:

```text
kubepods
docker
crio
libpod
containerd
lxc
machine.slice
container-id
none
```

Canonical `runtime_hint` values:

```text
kubernetes
docker
crio
podman
containerd
lxc
systemd
unshare
snapshotter
container-id
none
```

Evidence matching is normative for v1.0. The table below defines the searched
field, match rule, case sensitivity, emitted classification reason code, score
delta, and hint effect for every v1.0 scoring and hint signal. A scored reason
code may contribute to an artifact score at most once per artifact, even when
multiple member processes match it.

For cgroup keyword matching, split each cgroup path on `/` and ignore empty
components. Keyword matches are case-sensitive matches for the exact byte
sequence within one path component; they do not join text across path
separators. Runtime and cgroup keyword matches are case-sensitive lowercase
unless this spec explicitly names a mixed-case token such as `machine.slice`.
The container-like ID rule is a
path-component token rule: after splitting on `/`, a component matches when it
contains a token matching `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`. The
matched hex token itself must be lowercase.

For deleted executable detection, read `/proc/<pid>/exe` with `readlink`. The
signal matches only when the raw `readlink` value ends with the exact suffix
`" (deleted)"`. Display fields that show `exe_path` should strip that suffix
and show the executable path; classification reason detail must preserve the raw
`readlink` value including the suffix.

For `cmdline` matching, `/proc/<pid>/cmdline` NUL separators are normalized to
single spaces before applying the rules below. The first command argument is
the text before the first normalized space.

| Signal | Searched field | Match rule | Case sensitivity | Reason code | Score delta | Hint effect |
|---|---|---|---|---|---:|---|
| PID namespace differs from host | artifact namespace profile | Known PID namespace ID differs from the host profile PID namespace ID. | N/A | `pid_ns_differs` | +3 | none |
| Mount namespace differs from host | artifact namespace profile | Known mount namespace ID differs from the host profile mount namespace ID. | N/A | `mnt_ns_differs` | +3 | none |
| Network namespace differs from host | artifact namespace profile | Known network namespace ID differs from the host profile network namespace ID. | N/A | `net_ns_differs` | +2 | none |
| User namespace differs from host | artifact namespace profile | Known user namespace ID differs from the host profile user namespace ID. | N/A | `user_ns_differs` | +2 | none |
| UTS namespace differs from host | artifact namespace profile | Known UTS namespace ID differs from the host profile UTS namespace ID. | N/A | `uts_ns_differs` | +1 | none |
| IPC namespace differs from host | artifact namespace profile | Known IPC namespace ID differs from the host profile IPC namespace ID. | N/A | `ipc_ns_differs` | +1 | none |
| Cgroup namespace differs from host | artifact namespace profile | Known cgroup namespace ID differs from the host profile cgroup namespace ID. | N/A | `cgroup_ns_differs` | +1 | none |
| Time namespace differs from host | artifact namespace profile | Known time namespace ID differs from the host profile time namespace ID. | N/A | `time_ns_differs` | +1 | none |
| Process is PID 1 inside nested PID namespace | member process `ns_pid` and PID namespace | A member process has `ns_pid=1` and the artifact PID namespace differs from the host profile PID namespace. | N/A | `nested_pid_init` | +4 | none |
| Cgroup path contains `kubepods` | member process cgroup path | Any cgroup path component contains the exact byte sequence `kubepods`. | case-sensitive | `cgroup_kubepods` | +4 | `cgroup_hint=kubepods`, `runtime_hint=kubernetes` |
| Cgroup path contains `containerd` | member process cgroup path | Any cgroup path component contains the exact byte sequence `containerd`. | case-sensitive | `cgroup_containerd` | +4 | `cgroup_hint=containerd`, `runtime_hint=containerd` |
| Cgroup path contains `docker` | member process cgroup path | Any cgroup path component contains the exact byte sequence `docker`. | case-sensitive | `cgroup_docker` | +4 | `cgroup_hint=docker`, `runtime_hint=docker` |
| Cgroup path contains `crio` | member process cgroup path | Any cgroup path component contains the exact byte sequence `crio` or `cri-o`. | case-sensitive | `cgroup_crio` | +4 | `cgroup_hint=crio`, `runtime_hint=crio` |
| Cgroup path contains `libpod` | member process cgroup path | Any cgroup path component contains the exact byte sequence `libpod`. | case-sensitive | `cgroup_libpod` | +4 | `cgroup_hint=libpod`, `runtime_hint=podman` |
| Cgroup path contains `lxc` | member process cgroup path | Any cgroup path component contains the exact byte sequence `lxc`. | case-sensitive | `cgroup_lxc` | +3 | `cgroup_hint=lxc`, `runtime_hint=lxc` |
| Cgroup path contains `machine.slice` | member process cgroup path | Any cgroup path component contains the exact byte sequence `machine.slice`. | case-sensitive | `cgroup_machine_slice` | +2 | `cgroup_hint=machine.slice`, `runtime_hint=systemd` |
| Cgroup path contains long hex container-like ID | member process cgroup path | A cgroup path component contains a lowercase hex token matching `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`. | case-sensitive | `cgroup_container_id` | +2 | `cgroup_hint=container-id`, `runtime_hint=container-id` |
| Root filesystem differs from host root | member process `root_path` | A readable `/proc/<pid>/root` target differs from the readable host-profile root target. | N/A | `root_fs_differs` | +2 | none |
| Mountinfo contains overlay or snapshotter hints | member process mountinfo | Any parseable mountinfo row matches the overlay or snapshotter rule below. | case-sensitive | `mount_overlay_snapshotter` | +3 | `runtime_hint=snapshotter` when no higher-precedence runtime hint is present |
| Mountinfo contains Kubernetes projected or serviceaccount mounts | member process mountinfo | Any parseable mountinfo row matches the Kubernetes projected or serviceaccount rule below. | case-sensitive | `mount_kubernetes_projected` | +2 | `runtime_hint=kubernetes` when no higher-precedence cgroup-derived runtime hint is present |
| Executable path is deleted | member process `/proc/<pid>/exe` raw `readlink` value | Raw `readlink` value ends with the exact suffix `" (deleted)"`. | case-sensitive | `exe_deleted` | +2 | none |
| Nested PID namespace init without runtime hints | artifact evidence | `nested_pid_init` matched and no cgroup, mountinfo, or `unshare` runtime hint matched for the artifact. | N/A | `nested_pid_init_without_runtime` | - | namespace-managed evidence |
| `unshare` command name | member process `comm` | `comm` equals `unshare`. | case-sensitive | `unshare_comm` | - | `runtime_hint=unshare` when no higher-precedence runtime hint is present |
| `unshare` first command argument | member process `cmdline` | First command argument has basename `unshare`. | case-sensitive | `unshare_cmdline` | - | `runtime_hint=unshare` when no higher-precedence runtime hint is present |
| `unshare` executable path | member process `exe_path` | Basename of the displayed executable path is `unshare`. | case-sensitive | `unshare_exe_path` | - | `runtime_hint=unshare` when no higher-precedence runtime hint is present |

Cgroup hint precedence is:

1. `kubepods`
2. `docker`
3. `crio`
4. `libpod`
5. `containerd`
6. `lxc`
7. `machine.slice`
8. `container-id`

When multiple cgroup hints match, use the first match in the precedence order
above for `cgroup_hint` and its cgroup-derived `runtime_hint`. Emit
classification reasons for additional matches.

Runtime hint precedence is:

1. The selected cgroup-derived runtime hint, if any.
2. Kubernetes projected or serviceaccount mount evidence.
3. Overlay or snapshotter mount evidence.
4. `unshare`-style executable or command metadata.

For overlay or snapshotter mount evidence, parse `/proc/<pid>/mountinfo` using
the fields before and after the first literal ` - ` separator. The signal
matches when any parseable row has `filesystem_type=overlay`,
`filesystem_type=fuse-overlayfs`, `mount_source=overlay`, or a `mount_source`
or `mount_point` path component exactly equal to `overlay`, `overlayfs`,
`snapshots`, or `snapshotter`.

For Kubernetes projected or serviceaccount mount evidence, parse
`/proc/<pid>/mountinfo` the same way. The signal matches when any parseable row
has `filesystem_type=tmpfs`, an optional field beginning with `shared:`, and a
`mount_point` path component exactly equal to `kube-api-access`; or when any
parseable row has `filesystem_type=tmpfs` or `filesystem_type=projected` and a
`mount_point` path component exactly equal to `serviceaccount`, `secrets`, or
`kube-api-access`.

---

## 11. v1.0 Command Set

v1.0 defines only foundational read-only commands.

```text
nsurgn list
nsurgn inspect <artifact-id|pid>
nsurgn ps <artifact-id|pid>
nsurgn report [<artifact-id|pid>]
nsurgn map [<artifact-id|pid>]
nsurgn doctor
nsurgn version
nsurgn help
nsurgn --help
```

Global `--help` must be equivalent to `help`.

Invalid commands and invalid options must fail with a usage error.

---

## 12. Global CLI Specification

### 12.1 Syntax

```bash
nsurgn [global-options] <command> [command-options] [arguments]
```

### 12.2 Global Options

```text
--group <mode>       Grouping mode: profile, strict, pid, mnt, net, cgroup
--format <format>    Output format: raw, table, text, json, ndjson
--verbose            Print resolved paths and decision details
--quiet              Suppress non-critical warnings
--no-color           Disable color output
--host-pid <pid>     Use specific PID as host namespace profile reference
--include-host       Include host-classified artifacts
--version            Print version
--help               Show help
```

### 12.3 Artifact Identifier

Artifacts receive ephemeral IDs per command invocation:

```text
A1
A2
A3
...
```

Artifact IDs are assigned after a command's scan has built artifact groups,
selected leaders, classified artifacts, and applied the command's artifact
visibility filter such as default host hiding or `--include-host`.

Before ID assignment, sort the artifacts visible to that command by:

1. score descending,
2. classification rank: `anomalous`, `container-like`, `namespace-managed`,
   `isolated`, `host`,
3. leader host PID ascending, with missing leader PID sorting after known leader
   PIDs,
4. group key bytewise ascending,
5. full namespace tuple bytewise ascending.

IDs are then assigned sequentially as `A1`, `A2`, `A3`, and so on.

Commands accepting `<artifact-id|pid>` should accept:

```text
A1
18342
pid:18342
```

Rules:

- `A1` means artifact ID.
- A numeric value means host PID.
- `pid:18342` explicitly means host PID.

Artifact ID targets are resolved only against the current command's scan after
that command has applied its grouping mode, host profile, and visibility
options. `inspect A1`, `ps A1`, `report A1`, and `map A1` are conveniences for
operator workflows that run a target command from a fresh `list` observation and
accept that the ID is resolved against the target command's own current scan;
they are not durable references to a workload.

Artifact IDs are not persistent across invocations. The only stability promise is
that identical scan facts, command, grouping mode, host profile, and visibility
options produce the same artifact IDs within the same `nsurgn` version. Changed
scan facts, ordering, grouping, host profile, or visibility options may cause a
previous artifact ID to resolve to a different current artifact or to fail to
resolve. Scripts must not store artifact IDs as durable references. Scripts
should prefer `pid:<host_pid>` targets, structured output fields, or
re-resolving artifacts from a fresh `nsurgn list` result.

---

## 13. Command Specifications

### 13.1 `nsurgn list`

List isolated, namespace-managed, container-like, or anomalous artifacts.

Default behavior:

- hide host-equivalent processes,
- hide ordinary host services with no meaningful isolation,
- do not dump every PID.

Example:

```bash
sudo nsurgn list
```

Example output:

```text
A1	container-like	13	18342	1	4	kubernetes	nginx -g daemon off;
A2	anomalous	7	22110	1	2	none	./worker
A3	isolated	5	9051	-	1	systemd	systemd-resolved
```

### 13.2 `nsurgn inspect <artifact-id|pid>`

Show detailed metadata for one artifact or PID.

Required output:

- resolved target,
- leader host PID,
- classification and score,
- namespace profile,
- host namespace differences,
- cgroup paths,
- command line,
- executable path when readable,
- target root when readable,
- leader selection reason,
- classification reasons.

### 13.3 `nsurgn ps <artifact-id|pid>`

List visible processes in an artifact.

Required output:

- host PID,
- namespace PID when available,
- parent PID,
- user or UID,
- process state,
- command.

### 13.4 `nsurgn report [<artifact-id|pid>]`

Produce a detailed read-only report.

Without a target, report all non-host artifacts found by default discovery.

With a target, report only that artifact or PID.

Required content:

- artifact summary,
- process table,
- namespace comparison,
- cgroup hints,
- mount summary when readable,
- classification evidence,
- permission limitations encountered during scan.

### 13.5 `nsurgn map [<artifact-id|pid>]`

Show namespace relationships among visible artifacts.

The map should help answer:

- which artifacts share PID namespaces,
- which artifacts share mount namespaces,
- which artifacts share network namespaces,
- which artifacts are split only by less central namespaces,
- how the selected grouping mode affects the result.

The output may be textual in v1.0. It does not need to be graphical.

### 13.6 `nsurgn doctor`

Report whether the local system can support v1.0 discovery and inspection.

Required checks:

- `/proc` is mounted,
- namespace links are readable for at least the current process,
- required standard utilities are available,
- current user is root or non-root,
- other-user process visibility appears complete or limited,
- likely procfs restrictions are detected where practical.

`doctor` should exit zero if diagnostics complete, even when warnings are found. It should exit nonzero only when diagnostics cannot run meaningfully.

### 13.7 `nsurgn version`

Print version information.

Required output:

- `nsurgn` version,
- release channel or build identifier when available.

### 13.8 `nsurgn help`

Print command help.

Help output must:

- show only v1.0 commands,
- avoid promising out-of-scope behavior,
- include examples for common read-only workflows,
- explain that artifact IDs are ephemeral,
- steer scripts and repeatable workflows toward `pid:<host_pid>` or structured
  fields from fresh command output.

---

## 14. Interface Quality

The interface must be:

- fast,
- clear,
- safe,
- scriptable,
- predictable,
- useful to Linux operators,
- copy-pasteable.

The interface should provide:

- good help text,
- readable tables,
- meaningful errors,
- minimal decoration,
- restrained color.

The interface must avoid:

- animation,
- spinner noise,
- fragile dashboards,
- unnecessary Unicode,
- overdone color,
- terminal-size-dependent correctness,
- `ncurses` behavior,
- mouse interaction.

Human-readable output should fit typical terminals, but correctness must not depend on terminal width.

---

## 15. Output Modes

### 15.1 Raw Output

Default output mode.

Raw output is a tab-separated record stream intended for pipes, scripts, and parsers.

Raw output requirements:

- one record per line,
- fields separated by literal tab characters,
- no header by default,
- no color,
- no alignment padding,
- no wrapping,
- no decoration,
- warnings and diagnostics on stderr only.

Fields containing tabs, newlines, or carriage returns must be escaped or normalized so each output record remains one physical line.

`inspect` raw output must use stable section records:

```text
section	key	value
```

`report` raw output with a target must use the same three-column section
records as `inspect`. `report` raw output without a target must prefix each
artifact record with the artifact ID:

```text
artifact_id	section	key	value
```

Scan-level rows in multi-artifact `report` raw output use `-` as the artifact
ID. Repeated scalar values repeat the same section and key. Repeated objects use
one-based indexes in the key, such as `process	1.host_pid	18342`.

### 15.2 Table Output

Table output is opt-in for human-facing summaries.

Table output should be readable and stable enough for operators, but scripts should prefer raw, JSON, or NDJSON output.

### 15.3 Text Output

Text output is opt-in for detailed human reports.

Text output should favor explicit labels and short sections.

### 15.4 JSON Output

JSON output should expose the same facts as human output using stable field names.

JSON output for discovery and inspection commands must be a single valid JSON
document with:

- `schema_version` set to `nsurgn.output.v1`,
- `command` set to the executed command name,
- command-specific objects or arrays for artifacts, processes, reports, or relationships,
- unavailable scalar values represented as `null`,
- empty collections represented as `[]`,
- diagnostics and warnings kept on stderr.

The v1.0 structured schema is defined in `DESIGN.md`. v1.x releases may add
fields, but must not remove or rename v1.0 fields without changing
`schema_version`.

### 15.5 NDJSON Output

NDJSON output may be used for stream-like artifact or process records.

Each line must be a complete JSON object.

Each NDJSON record must include:

- `schema_version`,
- `command`,
- `record_type`.

NDJSON is required for `list`, `ps`, and `map`. `inspect` and `report` may use
section-oriented records for detailed output.

---

## 16. Error Handling

### 16.1 Error Philosophy

Errors should be specific and actionable.

Bad:

```text
failed
```

Good:

```text
error: cannot read /proc/18342/root: permission denied
hint: run as root or check procfs restrictions
```

### 16.2 Common Error Classes

#### Permission Denied

```text
error: cannot read /proc/18342/root: permission denied
```

#### Process Disappeared

```text
warning: pid 18379 disappeared during scan
```

#### Target Missing

```text
error: target pid 18342 does not exist
```

#### Artifact Not Found

```text
error: artifact A1 does not resolve in current scan
hint: rerun nsurgn list; artifact IDs are per-invocation
```

When an explicit artifact ID target does not resolve, the command must emit this
error class, exit `5`, keep stdout empty in `raw`, `json`, and `ndjson` modes,
and include the rerun hint on stderr.

#### Unsupported Platform

```text
error: this command requires Linux procfs
```

### 16.3 Exit Codes

Exit code semantics are normative for v1.0. Each exit code has one stable
name and one stable meaning:

| Code | Name | Meaning |
|---:|---|---|
| 0 | `success` | The command completed its requested operation. Warnings, non-critical scan limitations, and partial metadata visibility do not change the exit code unless the command's primary requested target or output could not be produced. |
| 1 | `general-error` | A runtime failure occurred that is not covered by a more specific v1.0 exit code. This is the fallback error code and should be rare in implemented command paths. |
| 2 | `usage-error` | The invocation contains an invalid command, invalid option, missing required argument, invalid argument format, unsupported `--group` value, unsupported `--format` value, or invalid option/argument combination. |
| 3 | `permission-denied` | Required metadata for the requested operation or target could not be read because of permissions, procfs restrictions, or equivalent access denial, and the command cannot produce the requested primary result. Non-critical unreadable metadata that is represented as a warning or limitation does not use this code. |
| 4 | `target-not-found` | A host PID target does not exist or is not visible in the current scan. This applies to numeric PID targets and explicit `pid:<pid>` targets. |
| 5 | `artifact-not-found` | An artifact ID target does not resolve in the current scan. Artifact IDs are ephemeral and must be resolved only within the command's current scan. |
| 6 | `partial-success` | The command produced its primary requested output, but material portions of the requested result are incomplete because of scan limitations, vanished processes, or unreadable optional evidence. Use this only when the limitation affects requested target or detail completeness enough that scripts should distinguish it from clean success. |
| 7 | `process-changed` | A requested target process or material member process disappeared or changed during the command in a way that prevents a coherent result from being produced. Ordinary background PID churn during broad scans should be represented as warnings or limitations, not this code, unless it invalidates the requested result. |
| 8 | `unsupported-platform` | The command cannot run meaningfully because the platform lacks required Linux procfs behavior, `/proc` is unavailable, required namespace links are unavailable for the current process, or required standard utilities for the command are missing. |

When multiple conditions occur, exit codes use this precedence:

1. `usage-error` wins before scanning or target resolution.
2. `unsupported-platform` wins when the environment cannot support meaningful execution.
3. `target-not-found` and `artifact-not-found` win for unresolved explicit targets.
4. `permission-denied` wins when access denial prevents the requested primary result.
5. `process-changed` wins when process churn prevents a coherent requested result.
6. `partial-success` applies when primary output exists but material requested detail is incomplete.
7. `general-error` is the fallback for errors not covered above.
8. `success` applies when no higher-precedence condition applies.

Command-specific requirements:

- `doctor` exits `0` when diagnostics complete, even if warnings are found.
- `doctor` exits nonzero only when diagnostics cannot run meaningfully: use `8`
  for unsupported platform or missing required Linux feature, `3` for access
  denial that prevents diagnostics, and `1` for other runtime failures.
- `help`, `--help`, `version`, and `--version` exit `0` when output is printed successfully.
- Invalid commands and invalid options always exit `2`.
- Exit code semantics are independent of output format.
- In `raw`, `json`, and `ndjson` modes, diagnostics and warnings remain on stderr regardless of exit code.
- `--quiet` may suppress non-critical warnings, but must not change exit-code selection.
- `--verbose` may add stderr diagnostics, but must not change exit-code selection.

---

## 17. Privilege Requirements

Some discovery may work unprivileged.

Likely readable:

```text
/proc/<pid>/status
/proc/<pid>/cmdline
/proc/<pid>/ns/*
```

Possibly restricted:

```text
/proc/<pid>/root
/proc/<pid>/exe
/proc/<pid>/mountinfo
```

Most complete results usually require root.

Recommended message when non-root:

```text
warning: running without root; results may be incomplete
```

Behavior varies by kernel, procfs mount options, LSMs, namespace configuration, and distribution defaults.

---

## 18. Security Considerations

`nsurgn v1.0` treats process metadata as untrusted.

Safety requirements:

- Process names and command lines may lie.
- Cgroup paths and runtime hints may be spoofed or non-standard.
- Namespace grouping may be ambiguous.
- Host PID visibility may be incomplete.
- Environment data may expose secrets and is not part of v1.0 output.
- Reports must frame runtime hints as evidence, not proof.
- Commands must not build executable shell strings from process metadata.
- Commands must handle vanished PIDs gracefully.

---

## 19. Implementation Milestones

Recommended milestones:

```text
M1: help, version, doctor, and test harness
M2: PID validation and namespace reading
M3: artifact grouping and list command
M4: inspect command with host comparison
M5: ps command
M6: report command
M7: map command
M8: structured output
M9: output polish and man page
M10: integration tests and release candidate
```

Each milestone should add or update automated coverage.

---

## 20. Testing Strategy

### 20.1 Unit Tests

Test parsing functions using fixtures:

```text
fixtures/proc/<pid>/status
fixtures/proc/<pid>/stat
fixtures/proc/<pid>/cmdline
fixtures/proc/<pid>/cgroup
fixtures/proc/<pid>/mountinfo
fixtures/proc/<pid>/ns/*
```

Test cases:

- namespace ID parsing,
- cgroup hint parsing,
- command line null-byte handling,
- namespace profile creation,
- host profile comparison,
- leader selection,
- score calculation,
- classification,
- target resolution,
- output formatting,
- error formatting.

Target resolution cases:

- Identical scan facts, command, grouping mode, host profile, and visibility
  options assign the same artifact ID.
- Changed scan facts, artifact ordering, grouping mode, host profile, or
  visibility options do not preserve old artifact ID meaning. A previous ID may
  resolve only to the current command's artifact with that ID, or fail if no
  current artifact has that ID.
- An unresolved artifact ID target emits `artifact-not-found`, exits `5`, keeps
  stdout empty in `raw`, `json`, and `ndjson`, and writes the artifact-ID rerun
  hint to stderr.

### 20.2 Integration Tests

Use Linux tools where available:

```text
unshare
mount
ip netns
systemd-run
```

Scenarios:

1. Plain host process.
2. Process in a new PID namespace.
3. Process in a new mount namespace.
4. Process in a new network namespace.
5. Process in PID, mount, UTS, and IPC namespaces.
6. Process with a cgroup path containing a runtime hint.
7. Process with no runtime hint but namespace isolation.
8. Process that exits during scan.
9. Process with unreadable metadata.
10. Non-root execution with partial procfs visibility.

### 20.3 Compatibility Matrix

Target:

- Debian
- Ubuntu
- Fedora
- Rocky / Alma / RHEL-like systems
- Arch
- Alpine
- cgroup v1 systems
- cgroup v2 systems
- Kubernetes worker nodes

---

## 21. Acceptance Criteria

`nsurgn v1.0` is acceptable when it:

- Runs as a Bash-oriented Linux CLI.
- Requires no container runtime.
- Discovers namespace artifacts from `/proc`.
- Builds namespace profiles for visible processes.
- Compares target namespaces to the host profile.
- Groups artifacts by the selected grouping mode.
- Selects an artifact leader deterministically.
- Classifies artifacts using evidence-based labels.
- Lists artifacts with useful summaries.
- Inspects a PID or artifact.
- Shows related processes.
- Produces a detailed report.
- Shows namespace relationships.
- Provides system diagnostics.
- Supports raw stream, human, and structured output modes.
- Handles vanished PIDs gracefully.
- Provides stable exit codes.
- Avoids `eval`.
- Treats process metadata as untrusted text.
- Passes ShellCheck where reasonably possible, or documents justified exceptions.
- Has automated tests covering normal and failure paths.

---

## 22. README-Oriented Summary

```text
Discovery:
  nsurgn list

Inspection:
  nsurgn inspect <artifact-id|pid>
  nsurgn ps <artifact-id|pid>
  nsurgn report [<artifact-id|pid>]
  nsurgn map [<artifact-id|pid>]

Environment diagnostics:
  nsurgn doctor

Utility:
  nsurgn version
  nsurgn help
```

---

## 23. Design Position

Correct framing:

```text
This artifact shares namespaces and metadata commonly associated with containerized workloads.
```

Incorrect framing:

```text
This is definitely a Docker container.
```

Correct framing:

```text
target_root is /proc/18342/root
```

Incorrect framing:

```text
entered the container filesystem
```

The value of `nsurgn v1.0` is making the Linux substrate visible, inspectable, and explainable when higher-level runtime tooling is missing, broken, restricted, or untrusted.
