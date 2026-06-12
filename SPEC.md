# nsurgn v1.0 Specification

Project: `nsurgn`
Meaning: namespace surgeon
Release scope: v1.0 foundation
Primary platform: Linux
Primary interface: command-line utility
Core dependency posture: Linux procfs and standard Linux utilities

---

Document scope: this specification defines the public v1.0 product behavior,
CLI contract, output guarantees, error contract, and acceptance criteria.
Implementation architecture, internal records, command flow, renderer schemas,
and fixture planning belong in `DESIGN.md`.

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
- target root path and resolved root target when readable.

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

The host-profile root target uses the same PID as the host profile source:
`/proc/1/root` by default, or `/proc/<host-pid>/root` when `--host-pid` is
supplied. If that symlink target is unreadable, permission denied, missing, or
vanishes during the scan, host-root comparison evidence is unavailable for the
scan. In that state, root equality, root difference scoring, and anomaly
triggers that require a readable host-profile root target must not match.
Commands should emit a scan limitation for the host root failure when root
comparison could affect requested output or explanation.

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
- A process with `read_status` `ok` or `permission-denied` is eligible when its
  host PID is known.
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

The target root path is the procfs symlink path:

```text
/proc/<leader_pid>/root
```

`root_path` always means that procfs symlink path. It is stable enough for
reporting where the evidence was read from, but it is not the filesystem
identity used for root comparison.

The target root is the resolved `readlink` value of `root_path`. v1.0 reports
that value as `root_target` when readable. Root equality and difference checks
must compare `root_target` values, including the host-profile root target. If
`root_target` is unreadable, missing, or the process vanished, root comparison
evidence is unknown and must not satisfy scoring or anomaly rules.

v1.0 must not use either value for mutation.

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

Each artifact has an artifact-level namespace profile derived from its member
process namespace profiles. For each namespace type, the artifact-level value
is:

- the single known namespace ID when all member processes with a known value
  have the same value,
- `mixed` when two or more member processes have different known values, or
- missing when no member process has a known value.

Member process namespace profiles remain available for process lists,
inspection detail, limitations, and process-scoped classification evidence.
Artifact-scoped comparisons, sorting, target resolution detail, output
summaries, and `map` relationships use the artifact-level namespace profile.

For namespace-based grouping modes, each visible PID receives one deterministic
group key. For every namespace type included in the selected grouping mode:

- If the process has a known namespace ID, the key component is that namespace
  ID.
- If the process namespace ID is missing because the namespace link is absent,
  unreadable, vanished during the scan, unsupported by the kernel, or otherwise
  unknown, the key component is a process-distinct unknown token:

  ```text
  unknown:<host-pid>
  ```

The process-distinct unknown token is internal to group-key construction. It is
not a namespace ID and must not be rendered as an artifact namespace value. The
public artifact-level namespace value remains missing when no member process in
that artifact has a known value for that namespace type.

This rule means missing grouped namespace IDs do not coalesce across processes,
and a process with a missing grouped namespace ID cannot group with a process
whose corresponding namespace ID is known. When only ungrouped namespace IDs are
missing, they do not affect group identity.

If two processes have the same known grouped namespace IDs but either process is
missing one or more grouped namespace IDs, they are grouped separately unless
they are the same host PID. This avoids inferring shared namespace membership
from absence of evidence.

Missing grouped namespace IDs should emit `scan_limitation.tsv` rows when the
source failure is known and the selected command depends on grouping, sorting,
target resolution detail, map relationships, or namespace explanation. These
limitations do not by themselves change the exit code when the command can still
produce coherent primary output by using process-distinct unknown group keys.
They can contribute to `partial-success`, `permission-denied`, or
`process-changed` only under the command-specific materiality rules in section
16.3.

### 9.1 `--group profile`

Default.

Group by:

```text
pid_ns + mnt_ns + net_ns + user_ns
```

Rationale:

This balances usefulness and noise. PID, mount, network, and user namespaces are strong workload-boundary signals without fragmenting on weaker namespace differences by default.

Because the grouping key includes PID, mount, network, and user namespace IDs,
those artifact-level namespace values are single known IDs or missing. UTS, IPC,
cgroup, and time namespace values can still be `mixed` inside one
profile-grouped artifact.

### 9.2 `--group strict`

Group by the full namespace tuple:

```text
pid_ns + mnt_ns + net_ns + user_ns + uts_ns + ipc_ns + cgroup_ns + time_ns
```

Useful for forensic precision.

Because the grouping key includes the full namespace tuple, artifact-level
namespace values are single known IDs or missing.

### 9.3 `--group pid`

Group by PID namespace.

Useful for understanding nested PID namespace relationships.

Only the PID namespace is constrained by the grouping key. Mount, network, user,
UTS, IPC, cgroup, and time namespace values can be `mixed`.

### 9.4 `--group mnt`

Group by mount namespace.

Useful for filesystem-view investigation.

Only the mount namespace is constrained by the grouping key. PID, network, user,
UTS, IPC, cgroup, and time namespace values can be `mixed`.

### 9.5 `--group net`

Group by network namespace.

Useful for network isolation mapping.

Only the network namespace is constrained by the grouping key. PID, mount, user,
UTS, IPC, cgroup, and time namespace values can be `mixed`.

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
visible in `list` when `--include-host` is used. They also become visible to
target-capable commands when explicitly targeted by host PID as defined in
section 12.4.

No namespace type is constrained by the cgroup grouping key. PID, mount,
network, user, UTS, IPC, cgroup, and time namespace values can be `mixed`.

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

Appears intentionally isolated by Linux namespace tooling or host service
management, without a higher-precedence anomaly or container-like selector.

This label is selected only by the finite predicates in section 10.3.

#### `container-like`

Has namespace isolation plus cgroup, runtime, container ID, overlay, snapshotter, or Kubernetes-style hints.

This is a probability-oriented label, not proof.

#### `anomalous`

Has major namespace isolation plus one of the finite v1.0 anomaly triggers
defined in section 10.3.

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
| Matched v1.0 anomaly trigger from section 10.3 | anomalous flag |

### 10.3 Classification Rules

Classification uses both score and rule evidence. Score communicates evidence
strength; labels communicate the most useful operator-facing category. Score
alone must not determine the label.

Classification must be deterministic for a fixed scan result. The classifier
uses only namespace IDs and evidence visible in the current scan. Missing or
unreadable metadata must be represented as a limitation or reason, but it must
not be treated as proof that a namespace differs from the host profile.

Non-host labels require at least one known major namespace difference from the
host profile. If no PID, mount, network, or user namespace is known to differ
from the host profile, the artifact is classified as `host`, even when minor
namespace differences or non-namespace hints are present.

For artifact-scoped classification evidence, a `mixed` namespace value is not a
known equality or known difference from the host profile. It does not satisfy
signals that require that artifact namespace type to differ from or equal the
host profile. Process-scoped evidence may still match when a member process has
the required known namespace value and all other required process facts are
present.

When an artifact has one or more known major namespace differences, choose the
primary label by this precedence:

1. `anomalous`
2. `container-like`
3. `namespace-managed`
4. `isolated`

Higher-precedence labels do not discard lower-precedence evidence. For example,
an artifact with container runtime hints and a matched anomaly trigger is
classified as `anomalous`, while the runtime hints remain visible in the
classification reasons.

For v1.0, `anomalous` is selected only by the finite trigger table below.
Every trigger requires one or more known major namespace differences. If the
required namespace IDs or evidence fields are unknown, missing, unreadable, or
partial, the trigger does not match unless the row explicitly allows that
metadata state. Unreadable metadata is a scan limitation by default, not
anomalous evidence.

Process metadata, cgroup paths, command lines, executable names, and runtime
hints are spoofable. Spoofable evidence may contribute score, hints, and
classification reasons, but it must not create an anomaly by itself. A v1.0
anomaly trigger that uses spoofable evidence also requires a namespace or
filesystem inconsistency from the same artifact.

| Trigger | Required evidence | Reason code | Scope | Example |
|---|---|---|---|---|
| Runtime-backed artifact with host root | At least one known artifact-level major namespace difference, a readable member `root_target` equal to the readable host-profile root target, and at least one cgroup, mountinfo, or runtime hint from section 10.5. | `anomaly_runtime_hint_host_root` | artifact-scoped | A process has a Docker cgroup path and differs in the PID namespace, but `/proc/<pid>/root` resolves to the same target as the host root. |
| Root filesystem differs without mount namespace difference | A member process has at least one known major namespace difference from the host profile, that same member has a readable `root_target` that differs from the readable host-profile root target, and that same member has a known mount namespace ID equal to the host profile mount namespace ID. | `anomaly_root_diff_without_mnt_ns` | process-scoped | A process differs from the host in the user namespace and its root target differs from host root, but its mount namespace is known to be the host mount namespace. |
| Runtime hint without PID or mount isolation | At least one known artifact-level major namespace difference, a known artifact-level PID namespace ID equal to the host profile PID namespace ID, a known artifact-level mount namespace ID equal to the host profile mount namespace ID, and at least one cgroup, mountinfo, or runtime hint from section 10.5. | `anomaly_runtime_hint_without_pid_mnt_ns` | artifact-scoped | A process differs only in the network namespace while its cgroup path contains `kubepods` and both PID and mount namespaces match the host profile. |
| Nested PID init with deleted executable | A member process satisfies `nested_pid_init`, the same member process also satisfies `exe_deleted`, and that same member process has a known PID namespace that differs from the host profile PID namespace. | `anomaly_nested_pid_init_deleted_exe` | process-scoped | A process is PID 1 inside a nested PID namespace and `/proc/<pid>/exe` reads as `/tmp/worker (deleted)`. |

Important non-matches:

- Unreadable root, executable, cgroup, namespace, or mountinfo metadata does not
  satisfy a required evidence field. Emit a limitation row when possible.
- Runtime hints, cgroup paths, process names, command lines, executable
  basenames, and container-like IDs without one of the namespace or filesystem
  inconsistencies above must not select `anomalous`.
- Minor namespace differences alone must not select `anomalous`, even with
  runtime hints or unreadable metadata.

For v1.0, `container-like` is selected when all of the following are true:

1. The artifact has one or more known major namespace differences.
2. No v1.0 anomaly trigger matched.
3. At least one of these reason codes matched for the artifact:
   `cgroup_kubepods`, `cgroup_containerd`, `cgroup_docker`, `cgroup_crio`,
   `cgroup_libpod`, `cgroup_lxc`, `cgroup_container_id`,
   `mount_overlay_snapshotter`, or `mount_kubernetes_projected`.

These reason codes are the complete v1.0 container-like selector set. They
represent visible runtime, platform, cgroup, container-ID, overlay,
snapshotter, or Kubernetes-style evidence. `cgroup_machine_slice` is not
container-like evidence by itself; it is namespace-managed evidence because it
indicates systemd host service management rather than a container runtime or
platform. If a `machine.slice` artifact also matches one of the container-like
selector reason codes above, the primary label is `container-like` by
precedence and `cgroup_machine_slice` remains a classification reason.

For v1.0, `namespace-managed` is selected when all of the following are true:

1. The artifact has one or more known major namespace differences.
2. No v1.0 anomaly trigger matched.
3. No container-like selector reason code matched.
4. At least one of these reason codes matched for the artifact:
   `nested_pid_init`, `nested_pid_init_without_runtime`,
   `cgroup_machine_slice`, `unshare_comm`, `unshare_cmdline`, or
   `unshare_exe_path`.

These reason codes are the complete v1.0 namespace-managed selector set. They
represent a nested PID namespace init process, systemd-managed cgroup context,
or visible `unshare`-style process metadata. A private mount namespace,
different root filesystem, minor namespace difference, command name other than
the exact `unshare` rules in section 10.5, or unreadable metadata does not
select `namespace-managed` unless one of the selector reason codes above also
matched.

For v1.0, `isolated` is selected when the artifact has one or more known major
namespace differences and no anomalous, container-like, or namespace-managed
selector matched.

### 10.4 Classification Limitation

A process group can look container-like without being a container. A process group can also be a real container while hiding runtime hints. A process group can be intentionally namespace-managed without being runtime-backed. `nsurgn` reports evidence, not certainty.

### 10.5 Evidence and Hint Normalization

Hints are normalized summaries of visible evidence. They are not runtime
identity claims. Classification reasons are the detailed evidence records used
to explain scoring and labels; hints are compact fields intended for list,
report, JSON, and NDJSON consumers. `DESIGN.md` owns the internal record layout
that carries these facts.

Hint fields are single-valued:

- `runtime_hint` reports the highest-precedence runtime or platform hint.
- `cgroup_hint` reports the highest-precedence cgroup-path hint.
- Additional matched evidence must be emitted as classification reasons instead
  of being concatenated into a composite hint.

Canonical missing and no-hint values:

- Raw output and internal TSV records use `-` for unavailable or unreadable
  scalar values.
- JSON and NDJSON output use `null` for unavailable or unreadable scalar values.
- Empty repeated values use no rows in raw output and an empty array in JSON.
- Hint fields use `none` only when every relevant source family was readable,
  or not applicable, and no known hint was found.
- Hint fields use the missing scalar value when relevant metadata was
  unavailable and no higher-precedence readable evidence matched.

Relevant source families are cgroup for `cgroup_hint` and cgroup-derived
`runtime_hint`, mountinfo for mount-derived `runtime_hint`, and `cmdline`,
`comm`, and `exe` for `unshare`-style `runtime_hint`. Source failures that
affect requested output, scoring, target resolution, or classification
explanation must also appear as limitations.

Canonical `cgroup_hint` values are `kubepods`, `docker`, `crio`, `libpod`,
`containerd`, `lxc`, `machine.slice`, `container-id`, and `none`.

Canonical `runtime_hint` values are `kubernetes`, `docker`, `crio`, `podman`,
`containerd`, `lxc`, `systemd`, `unshare`, `snapshotter`, `container-id`, and
`none`.

Evidence matching is normative for v1.0. Scored reason codes contribute to an
artifact score at most once per artifact, even when multiple member processes
match. Score deltas are defined in section 10.2.

| Evidence | Match rule | Reason code | Hint effect |
|---|---|---|---|
| Namespace differs from host | Known artifact namespace ID differs from the host profile for `pid`, `mnt`, `net`, `user`, `uts`, `ipc`, `cgroup`, or `time`. | `<type>_ns_differs` | none |
| Nested PID namespace init | A member process has `ns_pid=1` and that same member process has a known PID namespace that differs from the host profile PID namespace. | `nested_pid_init` | none |
| Cgroup runtime keyword | A cgroup path component contains `kubepods`, `containerd`, `docker`, `crio`, `cri-o`, `libpod`, `lxc`, or `machine.slice` with case-sensitive matching. | `cgroup_kubepods`, `cgroup_containerd`, `cgroup_docker`, `cgroup_crio`, `cgroup_libpod`, `cgroup_lxc`, or `cgroup_machine_slice` | matching `cgroup_hint`; matching runtime hint: `kubernetes`, `containerd`, `docker`, `crio`, `podman`, `lxc`, or `systemd` |
| Cgroup container-like ID | A cgroup path component contains a lowercase hex token matching `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`. | `cgroup_container_id` | `cgroup_hint=container-id`, `runtime_hint=container-id` |
| Root filesystem differs | A readable member process `root_target` differs from the readable host-profile root target. | `root_fs_differs` | none |
| Overlay or snapshotter mount | A parseable mountinfo row has `filesystem_type=overlay`, `filesystem_type=fuse-overlayfs`, `mount_source=overlay`, or a `mount_source` or `mount_point` component equal to `overlay`, `overlayfs`, `snapshots`, or `snapshotter`. | `mount_overlay_snapshotter` | `runtime_hint=snapshotter` when no higher-precedence runtime hint is present |
| Kubernetes projected or serviceaccount mount | A parseable mountinfo row has `filesystem_type=tmpfs`, optional field `shared:*`, and mount point component `kube-api-access`; or has `filesystem_type=tmpfs` or `filesystem_type=projected` and mount point component `serviceaccount`, `secrets`, or `kube-api-access`. | `mount_kubernetes_projected` | `runtime_hint=kubernetes` when no higher-precedence cgroup-derived runtime hint is present |
| Deleted executable | Raw `/proc/<pid>/exe` `readlink` value ends with the exact suffix `" (deleted)"`. | `exe_deleted` | none |
| Nested PID init without runtime hints | `nested_pid_init` matched and no cgroup, mountinfo, or `unshare` runtime hint matched for the artifact. | `nested_pid_init_without_runtime` | namespace-managed evidence |
| `unshare` process metadata | `comm` equals `unshare`, first normalized `cmdline` argument has basename `unshare`, or displayed `exe_path` has basename `unshare`. | `unshare_comm`, `unshare_cmdline`, or `unshare_exe_path` | `runtime_hint=unshare` when no higher-precedence runtime hint is present |

For cgroup matching, split each path on `/`, ignore empty components, and match
within one component only. Runtime and cgroup keyword matches are
case-sensitive lowercase unless this spec explicitly names a mixed-case token
such as `machine.slice`. For `cmdline`, normalize NUL separators to single
spaces before matching and treat the text before the first normalized space as
the first command argument. Display fields that show `exe_path` strip the
`" (deleted)"` suffix, but classification reason detail preserves the raw
`readlink` value.

Cgroup hint precedence is `kubepods`, `docker`, `crio`, `libpod`,
`containerd`, `lxc`, `machine.slice`, then `container-id`. The selected
cgroup-derived runtime hint has highest runtime-hint precedence, followed by
Kubernetes mount evidence, overlay or snapshotter mount evidence, and
`unshare`-style executable or command metadata.

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

For sorting, artifact-level namespace tuple values use their public scalar
representation: namespace ID string, `mixed`, or missing. Missing namespace
values sort after known namespace ID strings and `mixed`.

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

Artifact IDs are not persistent across invocations. The only stability promise is
that identical scan facts, command, grouping mode, host profile, and visibility
options produce the same artifact IDs within the same `nsurgn` version. Changed
scan facts, ordering, grouping, host profile, or visibility options may cause a
previous artifact ID to resolve to a different current artifact or to fail to
resolve. Scripts must not store artifact IDs as durable references. Scripts
should prefer `pid:<host_pid>` targets, structured output fields, or
re-resolving artifacts from a fresh `nsurgn list` result.

### 12.4 Target Resolution And Visibility

The target-capable commands are `inspect`, `ps`, `report`, and `map`.

Target resolution uses these rules:

- Numeric PID targets and `pid:<pid>` targets are host PID targets.
- Host PID targets resolve against the full visible process scan before default
  host hiding removes host-classified artifacts from broad output.
- A host PID target may resolve to an artifact that would be hidden by default
  `list`, untargeted `report`, or untargeted `map` output.
- Artifact ID targets resolve only against artifacts that received IDs in the
  current command invocation after grouping, host profile selection, and
  artifact visibility filtering.
- Artifact ID targets cannot reference artifacts hidden from the current
  command invocation. To target a hidden host-classified artifact by artifact
  ID, the invocation must use a visibility option such as `--include-host` that
  includes that artifact before ID assignment.
- `--include-host` broadens artifact visibility and therefore affects artifact
  ID assignment, untargeted `report`, and untargeted `map` output. It does not
  change host PID target lookup because host PID targets already resolve from
  the full visible process scan.

Host PID targets use a target-scoped artifact set. The resolved target artifact
is forcibly included and assigned `A1`, even when hidden from default broad
output. `--include-host` does not change this target artifact ID. Targeted
`map` adds only visible peer artifacts that participate in emitted
relationships and assigns peer IDs after `A1` using the artifact sort from
section 12.3. Artifact ID targets do not use target-scoped ID assignment.

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

Targets resolve according to section 12.4.

Required output:

- resolved target,
- leader host PID,
- classification and score,
- namespace profile,
- host namespace differences,
- cgroup paths,
- command line,
- executable path when readable,
- target root path and resolved root target when readable,
- leader selection reason,
- classification reasons.

### 13.3 `nsurgn ps <artifact-id|pid>`

List visible processes in an artifact.

Targets resolve according to section 12.4.

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

Targets resolve according to section 12.4.

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

Without a target, `map` uses the same artifact visibility and ID assignment
rules as `list`. With a target, `map` resolves the target according to section
12.4 and renders relationships for the resolved artifact using that section's
target-scoped artifact set rules.

In v1.0, `map` emits only shared namespace relationships. The only v1.0
relationship enum value is:

```text
shares-namespace
```

`map` must not emit contrast rows such as `differs-namespace` in v1.0.

Relationship-generating namespace types are:

```text
pid
mnt
net
user
```

When `--group cgroup` is selected, `map` also generates `cgroup`
relationships. When `--group strict` is selected, `map` also generates
`uts`, `ipc`, `cgroup`, and `time` relationships. Missing or unreadable
namespace IDs do not generate relationship rows for that namespace type.
The process-distinct `unknown:<host-pid>` tokens used for grouping missing
namespace IDs are internal group-key components only; they are never namespace
IDs and must not generate relationship rows.

Relationship rows are pairwise artifact rows grouped by namespace type and
namespace ID. For every generated namespace type, find artifacts with the same
non-empty namespace ID and emit one row for each unordered pair in that group.
Do not emit self-relationships.

Artifacts whose artifact-level value for a relationship-generating namespace
type is missing or `mixed` do not participate in relationship generation for
that namespace type, because there is no stable shared namespace identity to
report.

For each relationship row:

- `left_artifact_id` is the earlier artifact by the current invocation's
  artifact ID assignment,
- `relationship` is `shares-namespace`,
- `namespace_type` is the namespace type that matched,
- `namespace_id` is the shared namespace inode string,
- `right_artifact_id` is the later artifact by the current invocation's
  artifact ID assignment,
- `detail` is stable human-readable text describing the shared namespace.

Suppress duplicate relationship rows by this identity:

```text
left_artifact_id
relationship
namespace_type
namespace_id
right_artifact_id
```

Targeted `map` output emits only relationship rows where the resolved target
artifact participates. Target visibility, hidden host PID targets, target-scoped
`A1`, peer visibility, and artifact ID target behavior are defined in section
12.4.

Raw, JSON, and NDJSON `map` relationship records must be emitted in this stable
order:

1. namespace type order: `pid`, `mnt`, `net`, `user`, `cgroup`, `uts`, `ipc`,
   `time`,
2. `namespace_id` bytewise ascending,
3. `left_artifact_id` by current invocation artifact ID assignment,
4. `right_artifact_id` by current invocation artifact ID assignment,
5. relationship enum order: `shares-namespace`,
6. `detail` bytewise ascending.

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

Fields containing tabs, newlines, carriage returns, or backslashes must be escaped so each output record remains one physical line:

```text
tab              -> \t
newline          -> \n
carriage return  -> \r
backslash        -> \\
```

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

Table output should be readable and stable enough for operators, but scripts
should prefer raw, JSON, or NDJSON output.

Table output is a stable human output mode, not a stable parse format. v1.0
requires the facts below to be present when the command can produce them, but
does not make exact spacing, padding, wrapping, column width, truncation,
alignment, color, or column order part of the public contract. Diagnostics and
warnings must still be written to stderr only.

Minimum table facts by command:

| Command | Required table facts |
|---|---|
| `list` | Artifact ID, classification, score, leader host PID, leader namespace PID when available, process count, runtime hint, and leader command. |
| `ps <target>` | Host PID, namespace PID when available, parent PID, user or UID, process state, and command. |
| `map [<target>]` | Left artifact ID, relationship, namespace type, namespace ID, right artifact ID, and relationship detail. |

`inspect` and `report` may render table sections for process lists, namespace
comparisons, classification evidence, limitations, and mount summaries. When
they use table output for these sections, the table facts must be the same facts
required for the corresponding command content in section 13. They may use text
sections for non-tabular details.

### 15.3 Text Output

Text output is opt-in for detailed human reports.

Text output should favor explicit labels and short sections.

Text output is a stable human output mode, not a stable parse format. v1.0
requires required facts to be labeled clearly enough for an operator to read,
but does not make exact heading text, section order, indentation, blank lines,
wrapping, color, or prose wording part of the public contract. Scripts and
repeatable workflows must use raw, JSON, or NDJSON instead.

Minimum text facts by command:

| Command | Required text facts |
|---|---|
| `inspect <target>` | The required output facts from section 13.2. |
| `report [<target>]` | The required content from section 13.4, including scan limitations that affect reported artifacts. |
| `map [<target>]` | The relationship facts from section 13.5 for each emitted relationship, or a clear no-relationships result when no relationship rows exist. |
| `doctor` | Each required check from section 13.6 and its result. |
| `version` | The required output facts from section 13.7. |
| `help` | The required help content from section 13.8. |

`list` and `ps` may support text output, but their v1.0 human contract is
satisfied by table output. If they implement text output, it must include the
same minimum facts as their table form.

### 15.4 JSON Output

JSON output exposes discovery and inspection facts using stable field names.

JSON output for `list`, `inspect`, `ps`, `report`, and `map` is a strict v1.0
public contract. Each command must emit one valid JSON document with:

- `schema_version` set to `nsurgn.output.v1`,
- `command` set to the executed command name,
- command-specific objects or arrays for artifacts, processes, reports, or relationships,
- unavailable scalar values represented as `null`,
- empty collections represented as `[]`,
- known no-hint values represented as `none`,
- mixed artifact-level namespace values represented as the string `mixed`,
- diagnostics and warnings kept on stderr.

The v1.0 structured schema and required fields are defined in `DESIGN.md`
section 10. v1.x releases may add fields, but must not remove or rename v1.0
fields without changing `schema_version`.

`doctor`, `version`, and `help` may support JSON, but v1.0 does not require
stable JSON schemas for those commands unless an implementation chooses to emit
structured output for them.

### 15.5 NDJSON Output

NDJSON output is a strict v1.0 public contract for `list`, `ps`, and `map`.
`inspect` and `report` may use section-oriented NDJSON records for detailed
output.

Each line must be a complete JSON object.

Each NDJSON record must include:

- `schema_version`,
- `command`,
- `record_type`.

Record payloads must use the required common types and missing-value behavior
defined in `DESIGN.md` section 10. NDJSON must emit one complete object per
physical line, with diagnostics and warnings kept on stderr.

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

- Metadata is material only when it is required to produce the command's primary
  requested output. Missing optional metadata must be represented as `null`, a
  missing scalar value, a limitation row, or a warning, according to the output
  contract for that command.
- Host-profile root failure disables root comparison evidence for the scan. It
  exits `6` only when requested target detail or explanation materially depends
  on root comparison; otherwise it is represented as a limitation or warning and
  does not change a successful primary result.
- Broad scan commands are `list`, untargeted `report`, and untargeted `map`.
  Ordinary vanished non-target PIDs and unreadable optional metadata exit `0`
  with limitations or warnings unless they prevent coherent artifact summaries
  or relationships from being produced.
- Targeted commands are `inspect <target>`, `ps <target>`, `report <target>`,
  and `map <target>`. Metadata required for target resolution, the target
  artifact namespace profile, the target process set, or the primary command
  view is material. Failure before the primary result uses `permission-denied`,
  `target-not-found`, `artifact-not-found`, or `process-changed` by precedence.
  Failure after the primary result is available uses `partial-success` only when
  requested target detail is materially incomplete.
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

Primary command materiality:

| Command shape | Primary output requires |
|---|---|
| Broad artifact summaries: `list`, untargeted `report`, untargeted `map` | Visible PID enumeration, readable host namespace profile, and enough namespace IDs, host PIDs, grouping facts, and leader-selection facts to build coherent visible artifact summaries. `map` additionally requires enough relationship-generating namespace IDs to derive requested relationships. |
| `inspect <target>` | Target resolution, target artifact leader host PID, namespace profile, host namespace comparison, classification, and score. |
| `ps <target>` | Target resolution, target artifact or PID-derived process set, host PID for each emitted process, and enough process status or fallback metadata to emit process rows. |
| `report <target>` | Target resolution, target artifact leader host PID, artifact summary, process table, and namespace comparison. |
| `map <target>` | Target resolution, target artifact namespace profile, visible peer artifact namespace profiles, and relationship rows involving the target when such rows exist. |

Metadata such as `root`, `exe`, `mountinfo`, `cmdline`, `status`, and `cgroup`
is optional when it affects only display detail, hints, mount summaries, or
classification explanation after the primary command view can still be
produced. It becomes material when the selected grouping mode, target
resolution, target process set, namespace comparison, relationship generation,
or requested target detail depends on it.

Metadata names:

- `root` means `/proc/<pid>/root`.
- `root_path` means the `/proc/<pid>/root` symlink path.
- `root_target` means the readable `readlink` value of `root_path`.
- `exe` means `/proc/<pid>/exe`.
- `mountinfo` means `/proc/<pid>/mountinfo`.
- `cmdline` means `/proc/<pid>/cmdline`.
- `status` means `/proc/<pid>/status`.
- `cgroup` means `/proc/<pid>/cgroup`.

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
- Keeps raw, JSON, and NDJSON as parseable contracts while treating table and
  text as human contracts with required facts but non-contractual layout.
- Handles vanished PIDs gracefully.
- Provides stable exit codes.
- Avoids `eval`.
- Treats process metadata as untrusted text.
- Passes ShellCheck where reasonably possible, or documents justified exceptions.
- Has automated tests covering normal and failure paths.
