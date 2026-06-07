# Handoff Brief

## Objective
Preserve the current understanding of the `nsurgn` repository specification and implementation state so another session can continue from the specification assessment.

## Scope And Non-Goals
Scope: repo-level specification understanding for `nsurgn` v1.0, including `SPEC.md`, `DESIGN.md`, current Bash scaffold, and smoke-test evidence.

Non-goals: no implementation work, no architecture redesign, no readiness verdict, no release or merge status claim.

## Current State
The repo specification is understandable and coherent at the product level. `SPEC.md` defines `nsurgn v1.0` as a read-only Linux Bash CLI for discovering visible process namespace artifacts from `/proc`, grouping them, selecting deterministic leaders, classifying them with evidence-based labels, and emitting stable raw/table/text/JSON/NDJSON output without making runtime identity claims.

`DESIGN.md` translates the specification into implementation boundaries: shared scan engine, target resolver, command views, renderers, and internal TSV workspace records.

The current implementation is an M1 scaffold. Implemented behavior includes help, version, doctor, CLI option validation, exit-code constants, TSV escaping, and scan workspace creation. Core v1.0 behavior is not implemented yet: `/proc` discovery, namespace/profile parsing, grouping, leader selection, classification, target resolution, command-specific output, and structured renderers.

The scoring model decision has been recorded in `SPEC.md` and `DESIGN.md`: the v1.0 scoring table is normative for the public `score` field, each numeric signal contributes at most once per artifact, and classification labels still use rule evidence rather than score alone.

The working tree has documentation changes in `SPEC.md`, `DESIGN.md`, and this handoff scratchpad.

## Established Decisions And Traceability
Primary source artifacts:
- `SPEC.md`: product contract and v1.0 acceptance criteria.
- `DESIGN.md`: implementation-oriented design and output contracts.
- `AGENTS.md`: context and handoff operating notes.

Established spec decisions:
- v1.0 is read-only and must not mutate filesystems, control target processes, execute in target namespaces, or depend on runtime APIs.
- Default host profile source is `/proc/1/ns/*`, overrideable with `--host-pid`.
- Default grouping mode is `--group profile`, using PID, mount, network, and user namespaces.
- Host-equivalent artifacts are hidden by default; major namespace differences are PID, mount, network, and user.
- Runtime and cgroup matches are evidence, not proof.
- Artifact IDs are ephemeral per invocation.
- The v1.0 scoring table in `SPEC.md` section 10.2 is normative for public score calculation. Numeric rows contribute to `score` at most once per artifact; non-numeric rows are classification evidence or flags.
- Exit-code semantics are normative in `SPEC.md` section 16.3.

Potential spec tightening identified:
- Define `anomalous` evidence more testably.
- Decide whether `doctor --format json|ndjson` should produce structured output, TSV fallback, or a usage/deferred behavior.
- Add milestone-specific acceptance criteria so M2/M3 can proceed without carrying the entire v1.0 contract at once.

## Changed Artifacts
Changed by this handoff:
- `SPEC.md`
- `DESIGN.md`
- `.codex/handoffs/current.md`

No production code changes were made during the specification assessment or scoring-model clarification.

## Checks And Evidence
Commands run:
- `git diff --check`
- `test/smoke.sh`

Result:
- `git diff --check` passed.
- Passed with output: `ok - scaffold smoke tests passed`

Other evidence:
- `lib/commands.sh` routes `list`, `inspect`, `ps`, `report`, and `map` through `nsurgn_cmd_scaffolded_scan_command`, which currently calls `nsurgn_not_implemented`.
- `lib/scan.sh` creates the internal scan workspace files but does not yet perform discovery, grouping, leader selection, scoring, or classification.

## Risks, Blockers, And Open Questions
Open questions are specification-tightening items listed above. No source-established blocker or owner-issued status was found.

Unsupported claims:
- Any claim that v1.0 core discovery is implemented is unsupported because the command paths currently return “not implemented”.
- Any release-readiness or merge-readiness claim is unsupported because no source artifact establishes that status.

## Immediate Next Action And Owner
Owner: Unknown

Atomic next action: Define `anomalous` evidence in `SPEC.md` section 10.3 with testable criteria.

## Resume Notes
If continuing implementation, start from the milestone sequence in `SPEC.md` section 19. The likely next engineering milestone is M2, but that is a downstream implementation decision, not established by this handoff.
