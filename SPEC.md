# nsurgn Version 1 Specification Draft

Status: Draft  
Version: 1  
Project name: `nsurgn`  
Project meaning: namespace surgeon

## 1. Purpose

`nsurgn` is a Linux-native command-line utility for discovering, inspecting, explaining, and entering visible Linux namespace artifacts.

Linux does not expose containers as first-class kernel objects. Linux exposes processes, namespaces, cgroups, mounts, root filesystems, file descriptors, signals, and process metadata through interfaces such as `/proc`, `/proc/<pid>/ns/`, `readlink`, `stat`, `ps`, `awk`, `sed`, `grep`, `sort`, `uniq`, `find`, `lsns`, and `nsenter`.

`nsurgn` MUST report kernel-visible facts. It MUST NOT claim that a namespace artifact is a Docker container, Podman container, Kubernetes pod, Flatpak sandbox, Chrome sandbox, systemd-nspawn instance, bubblewrap process, `unshare` process, or hand-built namespace environment.

Runtime command-line evidence MAY be displayed as evidence:

```text
command evidence: bwrap
```

Runtime identity MUST NOT be asserted as truth:

```text
type: Flatpak
```

## 2. Implementation Scope

Version 1 MUST be implemented as a production-grade Bash script.

The primary executable MUST be a single file named:

```text
nsurgn
```

The script MUST use:

```bash
#!/usr/bin/env bash
```

The implementation SHOULD use strict-ish Bash style, including careful error handling without making `/proc` races fatal to whole-command operations such as `list`.

The implementation MUST:

- Quote variables and expansions carefully.
- Use arrays for command construction.
- Validate all PID input.
- Treat process names, command lines, and arguments as untrusted text.
- Handle `/proc` races gracefully.
- Expect processes to disappear during inspection.
- Avoid parsing unstable human-formatted output when stable `/proc` data exists.
- Support test seams through environment variables.

The implementation MUST NOT:

- Use `eval`.
- Execute text read from process metadata.
- Depend on container runtime APIs.
- Require `jq`.
- Require third-party vendor tools.

Recommended internal environment override seams:

```bash
NSURGN_PROC_ROOT="${NSURGN_PROC_ROOT:-/proc}"
NSURGN_NSENTER_BIN="${NSURGN_NSENTER_BIN:-nsenter}"
NSURGN_PS_BIN="${NSURGN_PS_BIN:-ps}"
NSURGN_READLINK_BIN="${NSURGN_READLINK_BIN:-readlink}"
```

Additional seams MAY be added for `stat`, `awk`, `sed`, `grep`, `sort`, `uniq`, `find`, and terminal color detection if needed for deterministic tests.

## 3. Dependencies

`nsurgn` v1 SHOULD use only standard Linux shell utilities and kernel-provided process metadata.

Allowed dependencies:

- Bash
- `/proc`
- `readlink`
- `stat`
- `ps`
- `awk`
- `sed`
- `grep`
- `sort`
- `uniq`
- `find`
- `lsns`, if available, for diagnostics only
- `nsenter`, for `enter`

`nsurgn` MUST NOT depend on:

- Docker
- Podman
- Kubernetes
- containerd
- CRI-O
- `crictl`
- `ctr`
- `nerdctl`
- `runc` APIs
- `jq`
- Runtime-specific APIs
- Third-party vendor tools

## 4. Version 1 Goals

`nsurgn v1` MUST support:

1. Discovering visible namespace artifacts.
2. Listing namespace artifacts.
3. Inspecting namespace metadata for a PID or artifact.
4. Explaining namespace isolation evidence.
5. Showing processes belonging to an artifact.
6. Safely previewing and executing `nsenter` entry into selected namespaces.
7. Reporting local capability and dependency diagnostics.
8. Scriptable output formats.
9. A full BATS test strategy.

## 5. Version 1 Non-Goals

`nsurgn v1` MUST NOT implement:

- Docker integration
- Podman integration
- Kubernetes integration
- CRI integration
- Runtime detection as truth
- Daemon mode
- Live dashboard mode
- Curses TUI
- GUI
- Process killing
- Cgroup modification
- Mount mutation
- Network mutation
- Policy enforcement
- Plugin system
- Config file system
- YAML output
- JSON output unless strict escaping is specified in a future revision
- Persistent state database
- Orchestrator behavior
- Container runtime behavior

## 6. Command Set

Version 1 MUST define these commands:

```bash
nsurgn list
nsurgn inspect <pid|artifact-id>
nsurgn ps <pid|artifact-id>
nsurgn explain <pid|artifact-id>
nsurgn enter <pid|artifact-id>
nsurgn enter <pid|artifact-id> --dry-run
nsurgn enter <pid|artifact-id> --yes
nsurgn enter <pid|artifact-id> --shell /bin/sh
nsurgn enter --pick
nsurgn doctor
nsurgn version
nsurgn help
nsurgn --help
```

Version 1 SHOULD also support:

```bash
nsurgn list --plain
nsurgn list --tsv
nsurgn inspect <target> --kv
nsurgn explain <target> --plain
```

Global `--help` MUST be equivalent to `help`.

Invalid commands and invalid options MUST fail with `E_BAD_OPTION`.

## 7. Interface Quality

The interface MUST be:

- Fast
- Clear
- Safe
- Scriptable
- Predictable
- Useful to Linux operators
- Copy-pasteable

The interface SHOULD provide:

- Good help text
- Readable tables
- Dry-run previews
- Meaningful errors
- Minimal decoration
- Restrained color

The interface MUST avoid:

- Animation
- Spinner noise
- Fragile dashboards
- Unnecessary Unicode
- Overdone color
- Terminal-size-dependent layouts
- `ncurses` behavior
- Mouse interaction

Human-readable output SHOULD fit typical terminals, but correctness MUST NOT depend on terminal width.

## 8. Output Modes

### 8.1 Human Output

Human output is the default. It SHOULD use readable tables or labeled blocks.

Human output MAY use restrained color only when color is enabled by the rules in Section 18.

Human output is not a stable machine contract.

### 8.2 Plain Output

Plain output MUST be selected by `--plain` where supported.

Plain output MUST:

- Avoid ANSI escapes.
- Avoid decorative color.
- Keep the same information content as human output where practical.
- Remain readable in logs and copy-paste contexts.

### 8.3 TSV Output

TSV output MUST be selected by `--tsv` where supported.

`nsurgn list --tsv` MUST emit a stable header line:

```text
artifact_id	leader_pid	user	pids	mnt_ns	pid_ns	net_ns	user_ns	isolation	command
```

Additional TSV fields MAY be added only in a future version or behind an explicitly named option. Version 1 MUST keep the above field order stable.

TSV values MUST be tab-separated. Newlines and tabs in command text MUST be sanitized or escaped so each process or artifact occupies exactly one line.

TSV output MUST NOT contain ANSI escapes.

### 8.4 Key-Value Output

`inspect --kv` MUST emit stable `key=value` lines.

Example:

```text
pid=1000
artifact_id=ns-4026532887
mnt_ns=4026532887
pid_ns=4026532891
net_ns=4026532894
user_ns=4026531837
```

Values MUST be sanitized so each key-value pair occupies one line.

Key names MUST be lowercase ASCII with underscores.

Key-value output MUST NOT contain ANSI escapes.

## 9. Namespace Artifact Model

A namespace artifact is:

```text
A group of one or more visible processes that share a selected namespace signature.
```

The default namespace signature MUST include:

- Mount namespace
- PID namespace
- Network namespace
- User namespace

The implementation MUST also collect and display when available:

- UTS namespace
- IPC namespace
- Cgroup namespace
- Time namespace, if present on the system

The display artifact ID MAY use the mount namespace ID:

```text
ns-4026532887
```

However, the mount namespace alone MUST NOT be treated as the complete internal identity. Internally, the artifact signature SHOULD be complete and stable:

```text
mnt=4026532887|pid=4026532891|net=4026532894|user=4026531837
```

When two visible artifacts share a mount namespace ID but differ in the complete signature, the implementation MUST preserve them as distinct artifacts internally. The display layer SHOULD disambiguate such collisions, for example by appending a short deterministic suffix.

## 10. Namespace Reading

For each visible numeric PID under `NSURGN_PROC_ROOT`, `nsurgn` SHOULD read namespace symlinks under:

```text
${NSURGN_PROC_ROOT}/<pid>/ns/
```

Namespace symlinks typically resolve to values like:

```text
mnt:[4026532887]
```

The implementation MUST extract the numeric namespace inode from the symlink target. It MUST treat malformed, missing, unreadable, or vanished namespace links as recoverable per-PID failures during scans.

The implementation MUST validate PIDs as decimal numeric strings and MUST reject empty, negative, signed, fractional, or non-numeric PID input.

## 11. Host Namespace Comparison

Host namespace comparison is a core v1 feature.

`nsurgn` MUST compare target namespace IDs against a host baseline. The preferred baseline is PID 1:

```text
${NSURGN_PROC_ROOT}/1/ns/<type>
```

For a target process, output SHOULD include a comparison table like:

```text
NS TYPE    TARGET        HOST          STATUS
mnt        4026532887    4026531841    isolated
pid        4026532891    4026531836    isolated
net        4026532894    4026531840    isolated
user       4026531837    4026531837    shared
uts        4026532888    4026531838    isolated
ipc        4026532889    4026531839    isolated
cgroup     4026532890    4026531835    isolated
```

If PID 1 namespace links are unavailable, `nsurgn` MUST report that host comparison is unavailable and SHOULD continue with target inspection where possible.

Status values SHOULD be:

- `isolated`, when the target namespace ID differs from the host baseline.
- `shared`, when the target namespace ID matches the host baseline.
- `unknown`, when either side cannot be read.

## 12. Target Resolution

Commands accepting `<pid|artifact-id>` MUST resolve the target as follows:

1. If the target is a valid numeric PID, inspect that PID directly and derive its artifact signature.
2. If the target matches an artifact ID format such as `ns-4026532887`, scan visible artifacts and resolve the matching artifact.
3. If multiple artifacts match a display ID because of a collision, the command MUST fail with a clear ambiguity error or require a more specific future selector.

Artifact ID lookup is necessarily based on currently visible processes. `nsurgn` MUST tolerate the selected artifact disappearing between listing and later inspection.

## 13. `list` Command

`nsurgn list` MUST:

- Scan visible numeric PIDs under `/proc` or `NSURGN_PROC_ROOT`.
- Read namespace links under `/proc/<pid>/ns/`.
- Group processes by namespace signature.
- Select a representative or leader PID for each artifact.
- Show artifact ID, leader PID, user, PID count, namespace IDs or summary, isolation summary, and command evidence.
- Gracefully skip unreadable or vanished PIDs.
- Continue partial listings when individual processes disappear.
- Support `--plain`.
- Support `--tsv`.

The representative or leader PID SHOULD be the lowest visible PID in the artifact unless a better deterministic rule is implemented and documented.

The user field SHOULD be derived from stable process ownership metadata. If user name resolution fails, numeric UID MAY be displayed.

The command field SHOULD use command-line evidence from `/proc/<pid>/cmdline` where readable, falling back to process name metadata where needed. Command text MUST be sanitized for the selected output mode.

Example human output:

```text
ARTIFACT          LEADER   USER    PIDS   ISOLATION             COMMAND
ns-4026532887     1842     david   5      mnt,pid,net,uts,ipc   /usr/bin/foo
ns-4026533012     2291     david   2      mnt,pid,user          bwrap
ns-4026533220     3104     root    1      mnt,uts               systemd-nspawn
```

If no namespace artifacts are discovered, the command MUST fail with `E_EMPTY_RESULT` unless a future option explicitly permits empty success.

## 14. `inspect` Command

`nsurgn inspect <pid|artifact-id>` MUST:

- Resolve the target.
- Show process metadata.
- Show namespace IDs.
- Show host comparison.
- Show artifact signature.
- Show visible process count for the artifact.
- Support `--kv`.

Human output SHOULD include:

```text
Target:
  pid:        1000
  user:       david
  command:    /usr/bin/example

Artifact:
  id:         ns-4026532887
  pids:       5
  signature:  mnt=4026532887|pid=4026532891|net=4026532894|user=4026531837
```

`inspect --kv` MUST emit stable key names for the core fields:

```text
pid=
artifact_id=
leader_pid=
user=
pids=
signature=
mnt_ns=
pid_ns=
net_ns=
user_ns=
uts_ns=
ipc_ns=
cgroup_ns=
time_ns=
```

Fields unavailable on the local kernel MAY be omitted or emitted with an empty value, but the behavior MUST be consistent and documented in help or tests.

## 15. `explain` Command

`nsurgn explain <pid|artifact-id>` MUST provide evidence-based interpretation without runtime guessing.

It MUST:

- Resolve the target.
- Show target process evidence.
- Show namespace evidence compared to host namespaces.
- State which namespaces differ from the host baseline.
- State which namespaces appear shared with the host baseline.
- Explicitly say that `nsurgn` does not infer a container runtime.
- Suggest useful next commands.
- Support `--plain`.

Example:

```text
Target:
  pid:        1842
  user:       david
  command:    /usr/bin/bwrap --args 32 ...

Namespace evidence:
  mnt:        4026532887  differs from host
  pid:        4026532891  differs from host
  net:        4026532894  differs from host
  user:       4026531837  same as host
  uts:        4026532888  differs from host
  ipc:        4026532889  differs from host
  cgroup:     4026532890  differs from host

Interpretation:
  This process is isolated by mount, pid, net, uts, ipc, and cgroup namespaces.
  The user namespace appears to be shared with the host.
  nsurgn does not infer a container runtime.
  It reports only kernel-visible namespace facts.

Suggested actions:
  nsurgn inspect 1842
  nsurgn enter 1842 --dry-run
```

`explain` MUST NOT emit runtime labels such as `type: Docker` or `type: Flatpak`.

## 16. `ps` Command

`nsurgn ps <pid|artifact-id>` MUST:

- Resolve the target to an artifact.
- List all visible processes that match the artifact signature.
- Show PID, PPID, user, namespace summary, and command.
- Gracefully handle vanished processes.

Example:

```text
PID     PPID    USER    NS                  COMMAND
1842    1       david   mnt,pid,net,uts     /usr/bin/foo
1849    1842    david   mnt,pid,net,uts     /usr/bin/foo-worker
1850    1842    david   mnt,pid,net,uts     /bin/sh
```

The process list SHOULD be sorted by numeric PID.

## 17. `enter` Command

`nsurgn enter` is a core v1 feature.

`nsurgn enter <pid|artifact-id>` MUST:

- Resolve the target to a representative PID.
- Validate that the target PID still exists before execution.
- Build the `nsenter` command using Bash arrays.
- Show the target and command before executing unless `--yes` is supplied.
- Support `--dry-run`.
- Support `--shell`.
- Use safe default shell behavior.
- Fail with `E_NO_NSENTER` if `nsenter` is unavailable.

Default command shape:

```bash
nsenter --target "$pid" --mount --uts --ipc --net --pid -- "$shell"
```

### 17.1 User Namespace Default

`enter` MUST NOT enter the user namespace by default in v1.

Rationale: entering a user namespace can change credential mappings and permission behavior in ways that are surprising for operators. A conservative default enters mount, UTS, IPC, network, and PID namespaces while leaving user namespace entry for an explicit future option.

Version 1 MAY include a documented unsupported error for `--user` or similar if users attempt to request it:

```text
E_UNSUPPORTED: user namespace entry is unsupported in v1
```

### 17.2 Shell Resolution

Default shell resolution MUST be:

1. Use `--shell` if supplied.
2. Otherwise use `/bin/sh`.
3. Do not blindly trust `$SHELL`, because it may not exist inside the target mount namespace.

The requested shell MUST be an absolute path. If it is empty, relative, or contains unsafe line-oriented display characters, the command MUST fail with `E_BAD_SHELL`.

The implementation SHOULD NOT attempt to prove that the shell exists inside the target mount namespace before `nsenter`, because that check is not reliable from the host mount namespace. It MAY validate that the host-side path looks syntactically safe.

### 17.3 Preview

Preview output SHOULD look like:

```text
Target artifact:
  leader pid: 1842
  command:    /usr/bin/foo
  user:       david

Namespaces:
  mount:      yes
  uts:        yes
  ipc:        yes
  net:        yes
  pid:        yes
  user:       no

Command:
  nsenter --target 1842 --mount --uts --ipc --net --pid -- /bin/sh

Continue? [y/N]
```

Confirmation MUST default to no. Only an affirmative `y` or `yes`, case-insensitive, SHOULD continue.

`--yes` MUST skip the prompt but SHOULD still print the target and command unless a future quiet option is defined.

### 17.4 Dry Run

`--dry-run` MUST print the target and command without executing `nsenter`.

Example:

```text
$ nsurgn enter ns-4026532887 --dry-run

Target artifact:
  leader pid: 1842
  user:       david
  command:    /usr/bin/foo

Command:
  nsenter --target 1842 --mount --uts --ipc --net --pid -- /bin/sh
```

`--dry-run` MUST NOT require user confirmation.

### 17.5 `enter --pick`

`nsurgn enter --pick` MUST provide a no-dependency interactive picker using Bash `select`.

Example:

```text
$ nsurgn enter --pick

Select namespace artifact:

1) ns-4026532887  pid=1842  user=david  pids=5  iso=mnt,pid,net,uts,ipc
2) ns-4026533012  pid=2291  user=david  pids=2  iso=mnt,pid,user
3) ns-4026533220  pid=3104  user=root   pids=1  iso=mnt,uts

Choice:
```

Invalid selections MUST be handled cleanly without executing `nsenter`.

Optional `fzf` support is out of scope for v1 unless explicitly added as optional and non-required in a later specification.

## 18. `doctor` Command

`nsurgn doctor` MUST report:

- Whether `/proc` is mounted.
- Whether namespace links are readable.
- Whether `nsenter` is available.
- Whether `readlink`, `stat`, `ps`, `awk`, `sed`, `grep`, `sort`, `uniq`, and `find` are available.
- Whether the user is root.
- Whether unprivileged inspection appears possible.
- Likely limitations for entering namespaces.
- Warnings rather than hard failures where appropriate.

Example:

```text
System:
  /proc mounted:              ok
  nsenter available:          ok
  readlink available:         ok
  running as root:            no

Capabilities:
  read own namespaces:        ok
  read other user processes:  limited
  enter mount namespaces:     likely requires elevated privileges
  enter net namespaces:       likely requires elevated privileges

Result:
  nsurgn can inspect visible user processes.
  Some enter operations may fail without sudo or matching user namespace permissions.
```

`doctor` SHOULD exit zero if diagnostics complete, even when warnings are found. It SHOULD exit nonzero only when diagnostics cannot run meaningfully, such as when `/proc` is unavailable.

## 19. `version` and `help`

`nsurgn version` MUST print the program name and version.

Example:

```text
nsurgn 1.0.0
```

`nsurgn help` and `nsurgn --help` MUST print concise command usage, supported options, output modes, and safety notes for `enter`.

Help text MUST avoid claiming runtime detection.

## 20. Error Model

Errors MUST go to stderr. Failures MUST use nonzero exit status. Errors MUST have a predictable prefix and stable error code.

Recommended format:

```text
nsurgn: E_BAD_PID: PID must be a numeric process id: abc
```

Minimum stable error codes:

```text
E_NO_PROC          /proc is not available
E_BAD_PID          PID does not exist, is invalid, or is not numeric
E_ACCESS_DENIED    process exists but namespace links cannot be read
E_NO_NSENTER       nsenter not found
E_TARGET_GONE      target disappeared before operation completed
E_NO_ARTIFACT      artifact id not found
E_EMPTY_RESULT     no namespace artifacts discovered
E_BAD_OPTION       invalid argument
E_BAD_SHELL        requested shell is invalid or unavailable
E_UNSUPPORTED      requested operation is unsupported in v1
```

The implementation MUST NOT emit raw stack traces.

Partial listing MUST continue when individual PIDs fail. Commands targeting one specific PID MUST fail clearly if required namespace metadata cannot be read.

Suggested exit status mapping:

- `0`: success
- `1`: general failure
- `2`: bad usage or bad option
- `3`: target not found or disappeared
- `4`: access denied
- `5`: missing dependency

The exact mapping MAY change before v1 release, but tests MUST lock the final behavior.

## 21. Color and Terminal Behavior

Color MUST be restrained and status-oriented.

Color MAY be emitted only when:

- Stdout is a terminal.
- `NO_COLOR` is not set.
- The selected output mode is human.

Color MUST be disabled in:

- `--plain`
- `--tsv`
- `--kv`
- Non-terminal stdout
- Any machine-readable mode

Color meanings SHOULD be:

- Green: ok, current, matched
- Yellow: warning, limited
- Red: error
- Dim: secondary detail

The implementation MUST NOT rely on color to convey required information.

## 22. Security and Safety Model

`nsurgn` MUST NOT grant privileges. It only uses permissions already available to the invoking user.

`nsurgn enter` MAY fail due to normal Linux permission boundaries. Root privileges or Linux capabilities may be required to enter some namespaces.

The implementation MUST account for:

- `/proc` races.
- PID reuse.
- Target process disappearance.
- Unreadable namespace links.
- Untrusted command lines.
- Untrusted process names.
- Potentially hostile process metadata.

The implementation MUST NOT:

- Execute data from process metadata.
- Use `eval`.
- Mutate cgroups.
- Mutate mounts.
- Mutate networking.
- Kill processes.

Shell command construction MUST use arrays.

`enter` MUST show the exact `nsenter` argv before execution unless a future quiet mode explicitly changes this behavior.

## 23. Repository Layout

Recommended initial layout:

```text
nsurgn/
|-- nsurgn
|-- README.md
|-- SPEC.md
|-- PLAN.md
|-- TESTS.md
|-- man/
|   `-- nsurgn.1
|-- test/
|   |-- bats/
|   |-- helpers/
|   |-- fixtures/
|   `-- run-tests.sh
`-- examples/
    |-- unshare-demo.sh
    `-- namespace-lab.sh
```

For v1, the implementation SHOULD prefer one main executable Bash file named `nsurgn`. Splitting into many Bash libraries SHOULD be avoided unless complexity clearly justifies it.

## 24. BATS Test Strategy

BATS is a first-class v1 requirement.

Recommended test layout:

```text
nsurgn/
|-- nsurgn
|-- README.md
|-- SPEC.md
|-- PLAN.md
|-- TESTS.md
|-- man/
|   `-- nsurgn.1
|-- test/
|   |-- bats/
|   |   |-- 00-doctor.bats
|   |   |-- 01-help-version.bats
|   |   |-- 02-pid-validation.bats
|   |   |-- 03-namespace-read.bats
|   |   |-- 04-list.bats
|   |   |-- 05-inspect.bats
|   |   |-- 06-ps.bats
|   |   |-- 07-explain.bats
|   |   |-- 08-enter-dry-run.bats
|   |   |-- 09-output-modes.bats
|   |   |-- 10-errors.bats
|   |   `-- 20-integration-unshare.bats
|   |-- helpers/
|   |   |-- nsurgn-test-helper.bash
|   |   `-- fixture-helper.bash
|   |-- fixtures/
|   |   |-- fake-proc-basic/
|   |   |-- fake-proc-missing-ns/
|   |   `-- fake-proc-access-denied/
|   `-- run-tests.sh
```

### 24.1 Fake `/proc` Tests

Deterministic tests MUST use `NSURGN_PROC_ROOT`.

Fake `/proc` tests SHOULD cover:

- PID validation.
- Namespace link parsing.
- Artifact ID construction.
- Target resolution.
- Output formatting.
- Error rendering.
- Option parsing.
- Fake `nsenter` execution.
- Process disappearance simulation.
- Missing namespace links.
- Access-denied fixtures where feasible.

Fake helper binaries SHOULD be used through environment seams such as `NSURGN_NSENTER_BIN` and `NSURGN_READLINK_BIN`.

### 24.2 Real Integration Tests

Integration tests SHOULD cover actual Linux behavior:

- Real namespace creation using `unshare`.
- Real namespace discovery.
- Real `enter --dry-run` rendering.
- Process disappearance handling.
- Permission-limited behavior.

Integration tests MUST skip cleanly when prerequisites are unavailable:

```bash
command -v unshare >/dev/null || skip "unshare not available"
command -v nsenter >/dev/null || skip "nsenter not available"
```

Integration tests MUST NOT require Docker, Podman, Kubernetes, or any container runtime.

### 24.3 Minimum Test Target

The v1 test suite SHOULD include:

```text
40-60 BATS tests
fake /proc fixture coverage
real unshare integration tests where possible
dry-run enter tests
fake nsenter execution tests
error-path coverage
stable output-mode tests
```

### 24.4 Suggested Test Files

`00-doctor.bats` SHOULD test dependency reporting and `/proc` availability behavior.

`01-help-version.bats` SHOULD test `help`, `--help`, invalid command handling, and version output.

`02-pid-validation.bats` SHOULD test numeric PID acceptance and invalid PID rejection.

`03-namespace-read.bats` SHOULD test namespace symlink parsing for all supported namespace types.

`04-list.bats` SHOULD test artifact grouping, leader selection, TSV header stability, and vanished PID tolerance.

`05-inspect.bats` SHOULD test target resolution, host comparison, artifact signature output, and `--kv`.

`06-ps.bats` SHOULD test process membership listing and sorting.

`07-explain.bats` SHOULD test evidence wording and absence of runtime identity claims.

`08-enter-dry-run.bats` SHOULD test command construction, shell selection, user namespace exclusion, and no execution.

`09-output-modes.bats` SHOULD test ANSI suppression in plain, TSV, and key-value modes.

`10-errors.bats` SHOULD test stable error codes and stderr behavior.

`20-integration-unshare.bats` SHOULD test real namespace workflows and skip behavior.

## 25. Implementation Milestones

Recommended milestones:

```text
M1: help, version, doctor, and test harness
M2: PID validation and namespace reading
M3: artifact grouping and list command
M4: inspect command with host comparison
M5: ps command
M6: explain command
M7: enter --dry-run
M8: safe enter execution with preview and --yes
M9: enter --pick
M10: output polish and man page
M11: integration tests and release candidate
```

Each milestone SHOULD add or update BATS coverage.

## 26. Acceptance Criteria

`nsurgn v1` is acceptable when it:

- Runs as a Bash script.
- Requires no container runtime.
- Discovers namespace artifacts from `/proc`.
- Lists artifacts with useful summaries.
- Inspects a PID or artifact.
- Compares target namespaces to host namespaces.
- Explains isolation evidence without runtime guessing.
- Shows related processes.
- Previews the `nsenter` command.
- Can execute `nsenter` with explicit confirmation or `--yes`.
- Supports `--dry-run`.
- Supports scriptable output modes.
- Handles vanished PIDs gracefully.
- Provides stable error codes.
- Has BATS tests covering normal and failure paths.
- Avoids `eval`.
- Treats process metadata as untrusted text.
- Passes ShellCheck where reasonably possible, or documents justified exceptions.

## 27. Open Decisions Before Final v1

The following details SHOULD be finalized before the v1 release:

- Exact version string format.
- Exact exit status mapping.
- Whether unavailable namespace fields are omitted or emitted empty in `--kv`.
- Whether artifact ID collision disambiguation is implemented in v1 or deferred with a clear ambiguity error.
- Whether any future explicit user namespace entry option is accepted as unsupported or omitted entirely.
