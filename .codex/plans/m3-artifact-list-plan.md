# M3 Artifact Grouping And List Plan

Source of truth:

- `SPEC.md` sections 8, 9, 10, 12.3, 12.4, 13.1, 15.1, and 16.3.
- `DESIGN.md` sections 6.6, 6.7, 9.1, 11.1, 12.6, and 13.
- Existing M1/M2 traceability in top-level `PLAN`.

Scope:

- Build artifact grouping from existing process namespace records.
- Select deterministic artifact leaders.
- Add minimal score/classification behavior needed for first `nsurgn list`.
- Assign per-invocation artifact IDs after visibility filtering.
- Replace scaffolded `list` with real default raw output.
- Add focused tests for grouping, leader selection, visibility, sorting, and raw list records.

Non-goals:

- Do not implement `inspect`, `ps`, `report`, or `map` target behavior in M3 unless needed only as shared helper preparation.
- Do not implement table, text, JSON, or NDJSON `list` output in the first `list` slice.
- Do not implement cgroup grouping until `/proc/<pid>/cgroup` summary records exist.
- Do not implement cgroup, mountinfo, root, exe, cmdline, or runtime-hint evidence before their process-level readers exist.
- Do not claim runtime identity. Labels remain evidence categories from `SPEC.md`.
- Do not remove the top-level `PLAN`; it remains useful M1/M2 history and records the M2 stop line.

## Current State

M2 is complete through commit `10c162f`. M3 artifact grouping is in progress.

Current `lib/scan.sh`:

- creates the scan workspace files, including `artifact.tsv`, `artifact_process.tsv`, and `classification_reason.tsv`;
- enumerates visible numeric PIDs;
- reads the host namespace profile;
- writes one process namespace and minimal metadata row per coherent visible process;
- builds deterministic namespace group keys for `profile`, `strict`, `pid`, `mnt`, and `net`;
- populates preliminary `artifact.tsv` rows with internal placeholder IDs, group keys, aggregate namespace fields, placeholder classification fields, and process counts;
- populates `artifact.tsv` leader fields and `artifact_process.tsv` leader/member roles using deterministic leader selection;
- records namespace/status/stat limitations.

Scan commands still call `nsurgn_cmd_scaffolded_scan_command`, run the scan, and return not-implemented behavior. `classification_reason.tsv` is created but not populated.

## Slice Status

| Slice | Status | Evidence | Next Action |
| --- | --- | --- | --- |
| M3.1 Group Key Construction | Complete | Implemented in `lib/scan.sh`; covered by `run_group_key_contract`; `./test/smoke.sh` passes at commit `275d795`. | None |
| M3.2 Artifact Namespace Aggregation | Complete | Implemented in `lib/scan.sh`; covered by `run_artifact_aggregation_contract` and live workspace checks; `./test/smoke.sh` passes at commit `275d795`. | None |
| M3.3 Deterministic Leader Selection | Complete | Implemented in `lib/scan.sh`; covered by `run_artifact_leader_contract`; `./test/smoke.sh` passes. | None |
| M3.4 Minimal Scoring And Classification | Pending | Not implemented. `classification_reason.tsv`, `classification`, `score`, and hint fields remain placeholders. | Start after M3.3 leader data is stable. |
| M3.5 Visibility, Sorting, And Artifact IDs | Pending | Not implemented. Public command-scoped `A*` IDs are not assigned. | Start after M3.4 classification and scores are stable. |
| M3.6 First Real `nsurgn list` Raw Output | Pending | Not implemented. `list` still returns scaffolded not-implemented behavior after scan. | Start after M3.5 visible artifact view exists. |

## Parallelization Notes

M3 implementation is mostly sequential because each slice establishes data that later slices consume:

- M3.2 depends on M3.1 group keys.
- M3.3 depends on M3.2 artifact membership.
- M3.4 depends on M3.2 artifact namespace aggregation and uses the same nested PID init rule as M3.3.
- M3.5 depends on M3.4 classification and scores.
- M3.6 depends on M3.1-M3.5 and should stay a thin integration slice.

Use sub-agents for bounded work that can return compact findings without changing shared state:

- Extract exact grouping, aggregation, leader, scoring, sorting, or raw-rendering contract details from `SPEC.md` and `DESIGN.md`.
- Inspect existing helper patterns in `lib/scan.sh`, `lib/commands.sh`, `lib/util.sh`, and `test/smoke.sh`.
- Draft or review fixture cases for a single M3 slice.
- Review one completed slice against its acceptance criteria and validation notes.

Parallel implementation is allowed only when file ownership and data contracts are stable:

- M3.1 implementation may run alongside a read-only contract extraction or test-fixture review.
- M3.2 tests may be drafted while M3.1 is underway, but should not be finalized until the group-key helper contract is stable.
- M3.3 and M3.4 test cases may be drafted in parallel after the M3.2 artifact row shape is stable.
- M3.6 renderer expectations may be checked against `DESIGN.md` while M3.5 is underway.

Keep each sub-agent task narrow: define the objective, source files, scope boundary, expected compact output, and stop condition. The main thread owns integration, final edits, validation, and handoff updates.

## M3.1 Group Key Construction

Goal: group `process.tsv` rows into deterministic artifact buckets for namespace grouping modes that can be supported from M2 data.

Scope:

- `--group profile`
- `--group strict`
- `--group pid`
- `--group mnt`
- `--group net`

Implementation slices:

1. Add a helper that returns the ordered namespace fields for each supported grouping mode.
2. Build one group key per process from grouped namespace values.
3. Use `unknown:<host-pid>` for missing grouped namespace IDs.
4. Serialize namespace group keys as `type=value` components joined by `+`, matching `DESIGN.md` section 6.6.
5. Keep `--group cgroup` parsed by the CLI but return a usage error or not-implemented error for scan commands until cgroup summary records exist.
6. Preserve existing process-level namespace values; do not render internal `unknown:<host-pid>` tokens as artifact namespace values.

Acceptance:

- Processes with the same known grouped namespace IDs receive the same group key.
- Missing grouped namespace IDs do not coalesce with known values or with missing values from another host PID.
- Missing ungrouped namespace IDs do not affect group identity.
- `profile`, `strict`, `pid`, `mnt`, and `net` grouping keys are deterministic.

Validation:

- Add fixture/unit-style tests that exercise group key construction directly.
- Include a missing grouped namespace test with two PIDs missing the same grouped type and confirm separate keys.
- Include a missing ungrouped namespace test and confirm grouping is unaffected.

Stop line:

- M3.1 is complete when group keys can be produced and tested without creating public artifact IDs or command output.

## M3.2 Artifact Namespace Aggregation

Goal: populate artifact-level namespace profiles and membership records from grouped process rows.

Implementation slices:

1. Aggregate grouped processes into temporary artifact buckets keyed by group key.
2. Compute each artifact namespace field as:
   - the single known namespace ID when all known member values match,
   - `mixed` when two or more known values differ,
   - `-` when no member has a known value.
3. Write `artifact_process.tsv` rows with placeholder member roles until leader selection is added.
4. Write preliminary `artifact.tsv` rows with stable group keys, namespace fields, process counts, and placeholder values for leader/classification fields.
5. Keep public artifact IDs unset or internal until the visibility and sorting slice assigns IDs.

Acceptance:

- Artifact namespace fields follow `SPEC.md` section 9 exactly.
- Internal unknown group-key tokens do not appear in artifact namespace fields.
- Process membership is complete for every process included in a group.

Validation:

- Add tests for single known value, mixed known values, and all-missing values.
- Add a profile-grouped artifact where UTS, IPC, cgroup, or time can become `mixed`.

Stop line:

- M3.2 is complete when artifact membership and namespace aggregation are correct with placeholder leader/classification fields.

## M3.3 Deterministic Leader Selection

Goal: select one leader per artifact using the v1.0 rules.

Implementation slices:

1. Detect nested PID namespace init candidates where a member has `ns_pid=1` and a known PID namespace different from the host profile PID namespace.
2. Prefer nested PID namespace init candidates.
3. Otherwise select the oldest eligible process by lowest `start_time`.
4. Otherwise select the lowest host PID.
5. Mark the selected member `leader` in `artifact_process.tsv`; all other members remain `member`.
6. Populate `leader_pid`, `leader_ns_pid`, `leader_command`, and `leader_reason` in `artifact.tsv`. Keep `leader_command` missing until command/cmdline readers exist.

Acceptance:

- Leader selection is deterministic for a fixed artifact member set.
- Nested PID namespace init wins over older process and lower host PID.
- Oldest process wins when no nested PID init candidate exists.
- Lowest host PID wins when start times are unavailable.

Validation:

- Add focused tests for each leader-selection branch.
- Include a tie case with equal or missing start times and confirm host PID ordering.

Stop line:

- M3.3 is complete when artifact records have stable leader fields but no public `list` output is required.

## M3.4 Minimal Scoring And Classification

Goal: classify artifacts using only evidence currently available from M2 process namespace data.

Implementation slices:

1. Compare artifact-level namespace IDs with the host profile for `pid`, `mnt`, `net`, `user`, `uts`, `ipc`, `cgroup`, and `time`.
2. Add score deltas for namespace differences only:
   - PID +3
   - mount +3
   - network +2
   - user +2
   - UTS +1
   - IPC +1
   - cgroup +1
   - time +1
3. Add `nested_pid_init` score/evidence where a member satisfies the nested PID namespace init rule.
4. Emit `classification_reason.tsv` rows for matched namespace difference and nested PID init evidence.
5. Classify artifacts as:
   - `host` when no known major namespace difference exists,
   - `namespace-managed` when `nested_pid_init` evidence exists and no higher-precedence selector is implemented,
   - `isolated` when at least one known major namespace difference exists and no implemented higher selector matches.
6. Set `runtime_hint` and `cgroup_hint` to `-` until relevant metadata readers can prove a hint or prove `none`.

Acceptance:

- Minor-only namespace differences score but classify as `host`.
- Major namespace differences classify as `isolated` unless nested PID init selects `namespace-managed`.
- Missing or `mixed` artifact namespace values do not count as known differences from the host profile.
- Scores use only implemented v1.0 numeric signals and do not invent weights.

Validation:

- Add tests for host, minor-only host, isolated major namespace difference, and nested PID init namespace-managed classification.
- Confirm each scored signal is emitted at most once per artifact.

Stop line:

- M3.4 is complete when artifact rows carry deterministic `classification`, `score`, hints, and reason rows for namespace-only evidence.

## M3.5 Visibility, Sorting, And Artifact IDs

Goal: assign command-scoped artifact IDs for `list` after classification and visibility filtering.

Implementation slices:

1. Apply default `list` visibility by hiding `host` artifacts.
2. Include host-classified artifacts when `--include-host` is set.
3. Sort visible artifacts by `SPEC.md` section 12.3:
   - score descending,
   - classification rank,
   - leader host PID ascending with missing after known,
   - group key bytewise ascending,
   - full namespace tuple bytewise ascending.
4. Assign `A1`, `A2`, `A3`, and so on after sorting.
5. Persist assigned IDs into the command's visible artifact view and, if useful, into `artifact.tsv` after assignment.

Acceptance:

- Default `list` hides host artifacts.
- `--include-host` changes visibility and therefore ID assignment.
- Sorting is stable for identical scan facts, command, grouping mode, host profile, and visibility options.
- Artifact IDs are not treated as durable across invocations.

Validation:

- Add tests for host hiding, include-host visibility, and ordering by score/rank/leader/group key.

Stop line:

- M3.5 is complete when a visible artifact list can be assigned stable command-scoped IDs without rendering stdout.

## M3.6 First Real `nsurgn list` Raw Output

Goal: replace scaffolded `list` behavior with real default raw output.

Implementation slices:

1. Change `nsurgn_dispatch` so `list` calls a real `nsurgn_cmd_list`.
2. Keep `inspect`, `ps`, `report`, and `map` scaffolded until their milestones.
3. Run the scan, build artifacts, classify them, filter visibility, assign IDs, and render raw list rows.
4. Render default raw fields from `DESIGN.md` section 9.1:
   - `artifact_id`
   - `classification`
   - `score`
   - `leader_pid`
   - `leader_ns_pid`
   - `process_count`
   - `runtime_hint`
   - `leader_command`
5. Keep diagnostics and warnings on stderr only.
6. Return success when broad artifact summaries are coherent, even if optional metadata is missing.

Acceptance:

- `nsurgn list` exits `0` and emits no header.
- Raw output uses literal tabs and one physical line per artifact.
- A host-only system may produce empty stdout with exit `0`.
- `--include-host list` can show host-classified artifacts when coherent.
- `--format raw list` is equivalent to default raw list output.
- Non-raw formats can remain not implemented with predictable behavior until renderer milestones.

Validation:

- Extend `test/smoke.sh` or add a focused test file for `list` raw output.
- Run `test/smoke.sh`.
- Run live smoke tests with read-only `/proc` access in the target sandbox, including `--include-host list`.

Stop line:

- M3.6 is complete when `list` has useful raw artifact summaries and all other scan commands remain predictably scaffolded.

## Deferred M3 Follow-Ups

These are intentionally outside the first real `list` slice unless the implementation reaches the M3.6 stop line cleanly:

- Split `lib/scan.sh` into `lib/group.sh`, `lib/leader.sh`, `lib/classify.sh`, and `lib/render_raw.sh` only when the code size justifies extraction.
- Add cgroup readers and `process_cgroup_summary.tsv`.
- Enable `--group cgroup`.
- Add command/cmdline, exe, root, and mountinfo readers.
- Expand scoring/classification to runtime hints, anomaly triggers, mount evidence, deleted executables, and root comparisons.
- Add JSON, NDJSON, table, or text list rendering.
- Start target resolution for `inspect`, `ps`, `report`, or `map`.

## Implementation Notes

- Prefer tested helpers that consume explicit files or rows over ad hoc parsing in command renderers.
- Keep scan facts in workspace TSV files so later commands can share one coherent scan model.
- Preserve raw escaping through `nsurgn_join_by_tab`.
- Treat `-`, `mixed`, and known namespace IDs distinctly in comparisons and sorting.
- Keep `unknown:<host-pid>` confined to group keys.
- Use `none` for hints only after every relevant source family for that hint is readable or not applicable. Until those readers exist, use `-`.

## M3 Completion Criteria

M3 is complete when:

- supported namespace grouping modes build artifact groups;
- artifact namespace profiles and member rows are written;
- leaders are selected deterministically;
- namespace-only scoring and initial classification are implemented;
- default `list` hides host artifacts and `--include-host` broadens visibility;
- raw `nsurgn list` emits parseable artifact summary rows;
- tests cover the implemented grouping, leader, classification, visibility, sorting, and raw output behavior.
