# Post-M3 Cgroup And Metadata Plan

Plan Status: complete

Source of truth:

- `SPEC.md` sections 9.6, 10.5, 10.6, 10.7, 12.3, 13.1, and 16.3.
- `DESIGN.md` sections 6.1, 6.2, 6.3, 6.6, 6.8, and 9.1.
- Completed M3 raw `list` behavior in `.codex/plans/m3-artifact-list-plan.md`.

Scope:

- Finish cgroup-derived process and artifact evidence after M3 raw `list`.
- Keep `list` raw output useful while preserving missing-value rules.
- Add only evidence-backed runtime and cgroup hints.
- Expand classification from namespace-only evidence to cgroup-derived evidence.
- Prepare the branch for merge after the cgroup stage is complete and verified.

Non-goals:

- Do not add runtime API dependencies.
- Do not claim runtime identity from cgroup evidence.
- Do not implement `inspect`, `ps`, `report`, or `map` target behavior in the cgroup stage.
- Do not add mountinfo, root, exe, cmdline, or comm readers in the cgroup stage unless needed for a small integration fix.
- Do not add JSON, NDJSON, table, or text renderers in the cgroup stage.

## Current Baseline

The current branch is `m3-artifact-list`.

M3 raw `list` is already implemented. The active work has moved into deferred M3 follow-ups:

- cgroup procfs reader support,
- `process_cgroup.tsv`,
- `process_cgroup_summary.tsv`,
- `--group cgroup`,
- artifact-level cgroup/runtime hints.

The M3 plan is marked stale because it predates this follow-up work and still lists cgroup support as deferred.

## Cgroup Stage Slices

### C1 Procfs Cgroup Reader And Summary

Goal: read `/proc/<pid>/cgroup` into normalized process-level cgroup records.

Implementation:

1. Parse non-blank, parseable cgroup lines into `process_cgroup.tsv`.
2. Preserve procfs line order through `line_index`.
3. Normalize v1 controller lists by bytewise sort.
4. Prefer the first v2 row for grouping when v2 is present.
5. Otherwise build a sorted v1 controller/path group key.
6. Write one `process_cgroup_summary.tsv` row for every viable process row.
7. Carry `cgroup_read_status`, `cgroup_group_key`, `cgroup_hint`, `runtime_hint`, and `path_count`.
8. Preserve limitations for vanished and permission-denied cgroup reads.

Acceptance:

- Empty or unparseable cgroup input yields `cgroup:unknown` and no path rows.
- v2 group keys take precedence over v1 rows.
- v1 group keys are deterministic across procfs line order.
- `process_cgroup.tsv` contributor flags match the selected group-key source.
- Process rows carry cgroup source status and cgroup-derived hints.

Validation:

- Focused smoke coverage for v1, v2, empty, vanished, and permission-denied reads.
- `bash -n lib/scan.sh test/smoke.sh`.
- `./test/smoke.sh`.

Status: complete. Validated with focused smoke coverage, `bash -n lib/scan.sh test/smoke.sh`, and `./test/smoke.sh`.

### C2 Cgroup Artifact Grouping

Goal: let `--group cgroup` build artifacts from `process_cgroup_summary.tsv`.

Implementation:

1. Load `cgroup_group_key` by host PID before artifact grouping.
2. Use `cgroup:unknown` when a process lacks a summary row.
3. Keep namespace aggregation independent from cgroup group identity.
4. Preserve default visibility rules: host-classified artifacts remain hidden unless `--include-host` is set.

Acceptance:

- Processes with the same cgroup summary key coalesce into the same artifact.
- Processes with different cgroup summary keys remain separate.
- Missing cgroup summaries coalesce under `cgroup:unknown` only for cgroup grouping.
- `--include-host --group cgroup list` can show coherent host-classified rows.

Validation:

- Focused smoke coverage for cgroup grouping.
- Live `./bin/nsurgn --host-pid $$ --group cgroup list`.
- Live `./bin/nsurgn --host-pid $$ --include-host --group cgroup list`.

Status: complete. Validated with focused smoke coverage, `./test/smoke.sh`, and live `list` checks for `--group cgroup`.

### C3 Artifact Cgroup And Runtime Hint Aggregation

Goal: populate artifact-level `cgroup_hint` and cgroup-derived `runtime_hint` from member process summaries.

Implementation:

1. Load per-process `cgroup_hint` from `process_cgroup_summary.tsv` for every grouping mode.
2. Aggregate member hints using the canonical cgroup hint precedence.
3. Treat missing or unavailable member hints as `-`.
4. Let known hints outrank `none`.
5. Derive artifact `runtime_hint` from the selected artifact `cgroup_hint`.
6. Keep both artifact hint fields as `-` when no relevant cgroup evidence is available.

Acceptance:

- Profile/strict/namespace-grouped artifacts can aggregate cgroup hints across member processes.
- `--group cgroup` artifacts use the same hint aggregation behavior.
- A higher-precedence cgroup hint wins over a lower-precedence hint in the same artifact.
- Missing cgroup summaries do not force artifact hints to `none`.
- Raw `list` field order remains unchanged.

Validation:

- Focused smoke coverage for mixed member hints and missing summaries.
- Existing raw `list` smoke coverage still passes.

Status: complete. Validated with focused smoke coverage for profile and cgroup grouping, plus existing raw `list` smoke coverage.

### C4 Cgroup Classification Reasons And Labels

Goal: use cgroup path evidence for classification reasons and higher-precedence labels without claiming runtime identity.

Implementation:

1. Emit artifact classification reasons for matched cgroup evidence:
   - `cgroup_kubepods`
   - `cgroup_containerd`
   - `cgroup_docker`
   - `cgroup_crio`
   - `cgroup_libpod`
   - `cgroup_lxc`
   - `cgroup_machine_slice`
   - `cgroup_container_id`
2. Emit each scored or selector reason at most once per artifact.
3. Classify artifacts with known major namespace differences and container-like cgroup evidence as `container-like`.
4. Classify artifacts with known major namespace differences and `machine.slice` evidence as `namespace-managed` unless a higher-precedence selector matches.
5. Preserve `isolated` for major namespace differences without higher-precedence selectors.
6. Preserve `host` for artifacts without known major namespace differences.

Acceptance:

- Cgroup evidence alone does not classify a host-equivalent artifact as container-like.
- Container-like cgroup evidence outranks namespace-managed and isolated when major namespace differences exist.
- `machine.slice` contributes namespace-managed evidence but not container-like evidence.
- Reason rows explain the evidence that affected hints and classification.

Validation:

- Focused smoke coverage for kubepods/docker/container-id/machine.slice selectors.
- Classification reason count checks to prevent duplicate reason rows.

Status: complete. Validated with focused smoke coverage for kubepods, docker, container-id, machine.slice, duplicate reason suppression, and cgroup selector label precedence.

### C5 Cgroup Stage Finalization

Goal: make the cgroup follow-up reviewable and mergeable.

Implementation:

1. Update stale planning notes so the completed cgroup stage has an accurate status.
2. Refresh `.codex/handoffs/current.md` only if a handoff is needed before merging.
3. Keep branch changes scoped to cgroup-derived evidence and documentation.
4. Run the full local verification set.

Acceptance:

- C1 through C4 are complete or explicitly deferred with rationale.
- No unrelated metadata-reader work is mixed into the cgroup stage.
- The working tree has no accidental files.
- The branch has current validation evidence.

Validation:

- `bash -n bin/nsurgn lib/*.sh test/smoke.sh`.
- `./test/smoke.sh`.
- `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`.
- Live raw `list` checks for default, `--include-host`, `--group cgroup`, and `--include-host --group cgroup`.

Status: complete. Final diff review found only cgroup-stage and planning/handoff artifacts. Validated on 2026-06-14 with `bash -n bin/nsurgn lib/*.sh test/smoke.sh`, `./test/smoke.sh`, `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`, `git diff --check`, and live raw `list` checks for default, `--include-host`, `--group cgroup`, and `--include-host --group cgroup`.

## Branch And Merge Plan

Keep the cgroup stage on the current `m3-artifact-list` branch until C5 is complete.

Merge to `main` only after:

- cgroup reader and summary behavior is validated,
- `--group cgroup` is validated,
- artifact-level cgroup/runtime hints are validated,
- cgroup classification reasons are either complete or explicitly deferred to the next branch,
- the stale M3 plan no longer looks like the active continuation plan,
- local syntax, smoke, shellcheck, and live list checks pass.

Recommended merge flow:

1. Review the final diff for unrelated files.
2. Commit the cgroup stage with a focused message.
3. Merge `m3-artifact-list` into `main`.
4. Create a new branch from updated `main` for the next implementation stage.

Suggested next branch:

```text
metadata-readers
```

## Next Stage Slices After Merge

These should start on a new branch after the cgroup stage lands.

### N1 Command Metadata Readers

Add `/proc/<pid>/cmdline` and `/proc/<pid>/comm` readers and populate process command fields and source statuses.

### N2 Leader Command

Use command metadata from N1 to populate `leader_command` in artifact summaries and raw `list`.

### N3 Root And Exe Readers

Add `/proc/<pid>/root` and `/proc/<pid>/exe` readers for future inspect/report evidence, root comparison, deleted executable handling, and anomaly selectors.

### N4 Mountinfo Reader And Summary

Add `process_mountinfo.tsv` and `process_mount_summary.tsv` for mount evidence and mount-derived runtime hints.

### N5 Target Resolution Preparation

Start the shared target-resolution helpers needed by `inspect`, `ps`, `report`, and `map`, without implementing all renderers at once.

## Open Questions

- Should the next branch focus narrowly on command metadata (`cmdline`/`comm`) or broader process metadata (`cmdline`/`comm`/`root`/`exe`)?
