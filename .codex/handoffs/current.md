# Handoff Brief

## Objective
Preserve the remaining blocking specification gaps identified while reviewing `nsurgn` v1.0 requirements, so the next worker can resolve them before downstream design, build, or test work depends on ambiguous behavior.

## Scope And Non-Goals
Scope: blocking ambiguity in `SPEC.md` and `DESIGN.md` only.

Non-goals: no implementation work, no test design, no readiness claim, and no ownership assignment beyond source-established facts.

## Current State
Resumed this handoff and resolved the first blocking gap, the overloaded
`root_path` contract. `SPEC.md` now defines `root_path` as the procfs symlink
path and `root_target` as the resolved `readlink` value used for host-root
equality and difference checks. `DESIGN.md` now carries `root_target` beside
`root_path` in the process, inspect, mount, and JSON process examples, and the
acceptance fixture wording uses `root_target` for anomaly evidence.

Remaining blocking gaps:

1. Artifact namespace profile is undefined for mixed groups. `--group profile` is coherent for PID/mount/net/user, but `--group pid`, `--group mnt`, `--group net`, and especially `--group cgroup` can group processes with differing namespace IDs in other namespace fields. Classification and output refer to a single artifact namespace profile without defining whether it uses leader values, aggregate values, first sorted member values, or mixed/multiple values.

2. Single process `read_status` is too coarse. `process.tsv` has one `read_status`, but process data comes from many independently readable sources: namespace links, `status`, `stat`, `cmdline`, `comm`, `cgroup`, `root`, `exe`, and `mountinfo`. Exit-code materiality depends on which specific metadata is missing or denied.

3. `partial` is only concretely defined for `mountinfo`. `read_status` allows `partial`, but only `mountinfo_read_status=partial` has operational semantics. Other proc readers lack exact partial-read behavior.

4. Hint `none` versus missing is underspecified for mixed readability. Hints use `none` when relevant metadata was readable and no known hint was found, and `-`/`null` when unavailable. Runtime hints can come from cgroup, mountinfo, command, comm, and exe, which may have mixed readability in one artifact.

5. Host-profile root target behavior is incomplete. Namespace host profile source is defined as `/proc/1/ns/*` or `--host-pid`, but root comparison rules require a readable host-profile root target. Behavior is not explicit when host root is unreadable, host PID vanishes, or `--host-pid` lacks root metadata.

6. JSON/NDJSON required fields are not fully closed. `DESIGN.md` gives schema examples and common types, but some command objects and detail arrays are placeholders or illustrative. This blocks structured output acceptance unless full JSON/NDJSON completeness is explicitly deferred.

7. Human `table` and `text` output are required but not contract-defined. v1.0 acceptance requires human output modes, but table/text layouts and minimum fields are loose. This blocks contract tests unless only raw/JSON/NDJSON are treated as public test contracts.

The first two remaining gaps are the most critical because they affect classification, inspect/report output, and exit-code selection.

## Established Decisions And Traceability
Source artifacts:

- `SPEC.md`: product boundary and evidence framing in sections 1-3.
- `SPEC.md`: host profile, artifact, leader, target root, data sources, grouping, classification, target resolution, output modes, and exit-code semantics in sections 6-16.
- `DESIGN.md`: scan architecture, internal TSV records, stdout/stderr contract, raw/JSON/NDJSON contracts, command flow, and acceptance fixture plan.

Relevant source locations observed during review:

- `SPEC.md` target root: section 6.6.
- `SPEC.md` grouping modes: section 9.
- `SPEC.md` classification and anomaly rules: section 10.
- `SPEC.md` target resolution and artifact IDs: section 12.
- `SPEC.md` exit codes and metadata materiality: section 16.3.
- `DESIGN.md` internal `process.tsv`, `artifact.tsv`, and `classification_reason.tsv`: section 6.
- `DESIGN.md` mountinfo status and parser behavior: section 9.3.
- `DESIGN.md` structured output contracts: section 10.

## Changed Artifacts
Modified `SPEC.md`, `DESIGN.md`, and `.codex/handoffs/current.md`.

## Checks And Evidence
Commands run:

- Read `01-understand/SKILL.md`.
- Read `12-handoff/SKILL.md`.
- Inspected `SPEC.md` and `DESIGN.md` with `sed`, `nl`, and `rg`.
- Checked git status; unrelated existing local changes were present under `.codex/skills/` plus `.gitignore`. Those were not touched.
- Reviewed `git diff -- SPEC.md DESIGN.md`.
- Ran `git diff --check -- SPEC.md DESIGN.md .codex/handoffs/current.md`; no whitespace errors were reported.

Evidence status: remaining gaps are based on local source documents only. No implementation or tests were inspected for conformance.

## Risks, Blockers, And Open Questions
Blocking decision questions:

- For grouped artifacts with mixed namespace fields, what is the artifact namespace profile used by classification and renderers?
- How should per-field read limitations be represented beyond a single process `read_status`?
- Which proc readers can emit `partial`, and what exact condition produces it?
- With mixed readable/unreadable hint sources, when is a hint value `none` versus missing?
- What is the exact host root source and failure behavior for root comparison rules?
- Are full JSON/NDJSON schemas required for v1.0 now, or deferred behind raw output milestones?
- What minimum fields are required for `table` and `text` modes if they are acceptance-tested?

## Immediate Next Action And Owner
Owner: Unknown.

Resolve the artifact namespace profile contract for mixed groups in `SPEC.md` and `DESIGN.md`.

## Resume Notes
Treat `.codex/handoffs/current.md` as a scratchpad only. Verify current truth from `SPEC.md`, `DESIGN.md`, git status, and any subsequent edits before acting.
