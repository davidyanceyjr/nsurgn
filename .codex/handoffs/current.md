# Handoff Brief

Handoff Status: active

## Objective
Continue after adding cgroup procfs readers, cgroup summaries, and `--group cgroup` artifact grouping after M3 raw `list`.

## Current State
- Current branch is `m3-artifact-list`.
- M3 first real raw `nsurgn list` output remains complete.
- Post-M3 cgroup reader slice is complete in `lib/scan.sh`.
- `process_cgroup.tsv` is now populated from `/proc/<pid>/cgroup` parseable non-blank lines.
- `process_cgroup_summary.tsv` is now populated for every process row with `cgroup_read_status`, `cgroup_group_key`, cgroup-derived hints, and path counts.
- `process.tsv` now carries `cgroup_read_status` and cgroup-derived `cgroup_hint`/`runtime_hint` fields from the cgroup reader.
- `--group cgroup` now builds artifacts from `process_cgroup_summary.tsv` group keys.
- Default cgroup-grouped `list` still hides host-classified artifacts; `--include-host --group cgroup list` shows host rows when coherent.
- `inspect`, `ps`, `report`, and `map` remain scaffolded not-implemented scan commands.

## Changed Artifacts
- `lib/scan.sh`: adds cgroup line parsing, v1 controller normalization, v2 precedence, cgroup group-key selection, cgroup hint/runtime-hint derivation from cgroup paths, cgroup summary writing, and cgroup grouping support.
- `lib/scan.sh`: changes namespace aggregate updates to use a Bash nameref so associative-array keys containing cgroup paths are safe under `set -u`.
- `test/smoke.sh`: adds cgroup reader, summary, contributor, and cgroup grouping coverage; updates process limitation expectations for cgroup source failures.
- `.codex/handoffs/current.md`: refreshed for the next continuation action.

## Checks And Evidence
- Ran `bash -n lib/scan.sh test/smoke.sh`; result: passed.
- Ran `./test/smoke.sh`; result: `ok - scaffold smoke tests passed`.
- Ran `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh`; result: passed.
- Ran `./bin/nsurgn --host-pid $$ --group cgroup list`; result: exit `0`, empty stdout allowed for hidden host artifacts.
- Ran `./bin/nsurgn --host-pid $$ --include-host --group cgroup list`; result: exit `0`, raw host rows on stdout.

## Risks, Blockers, And Open Questions
- Artifact-level `runtime_hint` and `cgroup_hint` still render `-`; cgroup-derived artifact hint aggregation and classification selectors remain deferred.
- Command/cmdline, exe, root, and mountinfo readers are not implemented.
- Non-raw `list` formats remain intentionally not implemented.
- Targeted commands and relationship/report rendering remain deferred.

## Immediate Next Action And Owner
Owner: Unknown. Decide whether the next slice should aggregate cgroup-derived artifact hints/classification reasons or add command/cmdline reader support for `leader_command`.
