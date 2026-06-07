# Handoff Brief

## Objective
Carry forward a fully normative v1.0 exit-code contract for `nsurgn`, replacing the current non-binding wording in `SPEC.md` section 16.3 where exit codes are described as "Suggested exit codes".

## Scope And Non-Goals
Scope is limited to CLI process exit behavior for v1.0 commands and global option handling.

Non-goals:

- No implementation work has been performed.
- No tests have been written.
- No changes have been made to `SPEC.md` or `DESIGN.md`.
- No broader error-message wording redesign is included beyond exit-code semantics.

## Current State
Source artifacts inspected:

- `SPEC.md` defines the product boundary, command set, error philosophy, common error classes, and currently suggested exit codes.
- `DESIGN.md` defines stdout/stderr separation, command output contracts, structured output behavior, and one-scan-per-invocation command flow.
- `AGENTS.md` requires resumable handoffs to be written to `.codex/handoffs/current.md`.

Established gap:

- `SPEC.md` section 16.3 uses "Suggested exit codes", so exit behavior is not yet a normative CLI contract.

Working tree note:

- `AGENTS.md` already had user changes before this handoff. Those changes were not modified.

## Established Decisions And Traceability
Normative exit-code design to carry into the spec:

| Code | Name | Normative meaning | Applies to |
|---:|---|---|---|
| 0 | `success` | Command completed its requested operation. Warnings, non-critical scan limitations, and partial metadata visibility do not change the exit code unless the command's primary requested target or output could not be produced. | All commands |
| 1 | `general-error` | A runtime failure occurred that is not covered by a more specific v1.0 exit code. This is the fallback error code and should be rare in implemented command paths. | All commands |
| 2 | `usage-error` | Invalid command, invalid option, missing required argument, invalid argument format, unsupported `--group` value, unsupported `--format` value, or invalid option/argument combination. | CLI parsing and target syntax validation |
| 3 | `permission-denied` | Required metadata for the requested operation or target could not be read because of permissions, procfs restrictions, or equivalent access denial, and the command cannot produce the requested primary result. Non-critical unreadable metadata that is represented as a warning or limitation does not use this code. | Discovery, inspection, target-specific commands, `doctor` only when diagnostics cannot run meaningfully |
| 4 | `target-not-found` | A host PID target does not exist or is not visible in the current scan. Applies to numeric PID targets and explicit `pid:<pid>` targets. | `inspect`, `ps`, `report`, `map` with PID target |
| 5 | `artifact-not-found` | An artifact ID target does not resolve in the current scan. Artifact IDs are ephemeral and must be resolved only within the command's current scan. | `inspect`, `ps`, `report`, `map` with artifact target |
| 6 | `partial-success` | The command produced its primary requested output, but material portions of the requested result are incomplete because of scan limitations, vanished processes, or unreadable optional evidence. Use only when the limitation affects requested target/detail completeness enough that scripts should distinguish it from clean success. | Discovery and inspection commands |
| 7 | `process-changed` | A requested target process or material member process disappeared or changed during the command in a way that prevents a coherent result from being produced. Ordinary background PID churn during broad scans should be represented as warnings or limitations, not this code, unless it invalidates the requested result. | Target-specific commands and scan operations |
| 8 | `unsupported-platform` | The command cannot run meaningfully because the platform lacks required Linux procfs behavior, `/proc` is unavailable, required namespace links are unavailable for the current process, or required standard utilities for the command are missing. | All commands, especially `doctor` |

Precedence when multiple conditions occur:

1. `usage-error` wins before scanning or target resolution.
2. `unsupported-platform` wins when the environment cannot support meaningful execution.
3. `target-not-found` and `artifact-not-found` win for unresolved explicit targets.
4. `permission-denied` wins when access denial prevents the requested primary result.
5. `process-changed` wins when process churn prevents a coherent requested result.
6. `partial-success` applies when primary output exists but material requested detail is incomplete.
7. `general-error` is the fallback for errors not covered above.
8. `success` applies when no higher-precedence condition applies.

Command-specific decisions:

- `doctor` exits `0` when diagnostics complete, even if warnings are found.
- `doctor` exits nonzero only when diagnostics cannot run meaningfully; use `8` for unsupported platform or missing required Linux feature, `3` for access denial that prevents diagnostics, and `1` for other runtime failures.
- `help`, `--help`, `version`, and `--version` exit `0` when output is printed successfully.
- Invalid commands and invalid options always exit `2`.
- In `raw`, `json`, and `ndjson` modes, diagnostics and warnings remain on stderr regardless of exit code.
- Exit code semantics are independent of output format.
- `--quiet` may suppress non-critical warnings, but must not change exit-code selection.
- `--verbose` may add stderr diagnostics, but must not change exit-code selection.

Acceptance criteria for the normative contract:

- `SPEC.md` no longer describes exit codes as suggested.
- Each code `0` through `8` has one stable name and one normative meaning.
- Precedence is documented for multi-error cases.
- `doctor` warning behavior remains compatible with the existing spec.
- Host PID target failures and artifact ID target failures remain distinct.
- Partial broad-scan PID churn is distinguishable from target-invalidating process changes.
- Output format does not affect exit-code semantics.

## Changed Artifacts
- Added `.codex/handoffs/current.md`.

## Checks And Evidence
Commands run:

- `sed -n '1,220p' .codex/skills/12-handoff/SKILL.md`
- `sed -n '1,220p' .codex/skills/03-contract/SKILL.md`
- `find .codex -maxdepth 3 -type f -print`
- `git diff -- AGENTS.md SPEC.md DESIGN.md`
- `mkdir -p .codex/handoffs`

Observed evidence:

- `git diff -- AGENTS.md SPEC.md DESIGN.md` showed only a pre-existing `AGENTS.md` change adding persistent handoff scratchpad instructions.
- No implementation or validation commands were run.

## Risks, Blockers, And Open Questions
- The normative exit-code design is not yet inserted into `SPEC.md`; until that edit happens, the source spec still says "Suggested exit codes".
- No owner is established in the available source artifacts.

## Immediate Next Action And Owner
Owner: Unknown

Replace `SPEC.md` section 16.3 with the normative exit-code contract from this handoff.

## Resume Notes
Before acting on this handoff, verify current truth from the working tree with `git status --short` and inspect any newer changes to `SPEC.md`, `DESIGN.md`, and `.codex/handoffs/current.md`.
