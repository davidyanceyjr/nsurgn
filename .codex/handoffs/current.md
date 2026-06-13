# Handoff Brief

## Objective
Resume `nsurgn` M1/M2 implementation from the next open slice after M2.5.

## Current Stage
- M1.1-M1.4 are complete.
- M2.1-M2.4 are complete and committed in `a997353` (`m2: collect process metadata`).
- M2.5 Scan Limitations is CODE COMPLETE in the working tree after `a997353`.
- Public scan commands remain scaffolded and return not-implemented after scan setup succeeds.

## Key Decisions
- M2 remains limited to PID enumeration, host namespace baseline, per-process namespace reads, minimal process metadata, and internal limitations.
- No artifact grouping, artifact IDs, leader selection, scoring, classification, cgroup grouping, mountinfo/root/exe evidence, or real public `list` output before M3.
- Process-level namespace/status/stat read failures are recorded as warning rows in `scan_limitation.tsv`; fatal host-profile failures remain error rows with the existing exit-code behavior.

## Changed Files
- `PLAN`: marks M2.5 completed in the working tree after `a997353`.
- `lib/scan.sh`: adds process-source limitation recording for namespace/status/stat failures and avoids directory-backed fake proc entries causing shell redirection noise for status/stat readers.
- `test/smoke.sh`: adds fixture coverage for permission-denied and vanished process-source limitation rows.
- `.codex/handoffs/current.md`: refreshed to this state.

## Validation Performed
- `test/smoke.sh` passed.
- `bash -n bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh` passed.
- `shellcheck -x bin/nsurgn lib/cli.sh lib/commands.sh lib/doctor.sh lib/errors.sh lib/scan.sh lib/util.sh test/smoke.sh` passed.

## Open Questions
- Should M2 helper functions be split immediately or kept in `lib/scan.sh` until extraction is justified?
- Should ShellCheck be required in the test harness or only run opportunistically when installed?
- What is the cleanest test-only way to inspect the scan workspace without creating public debug output?

## Known Risks
- M2 can expand quickly if M3 grouping/classification/output work is pulled in early. Keep the next slice narrow.

## Next Action
Review `PLAN` for M2.6 Verification Surface and M2.7 Tests, then decide whether they are complete with the current helper-based smoke coverage or need additional live-scan workspace assertions before starting M3.
