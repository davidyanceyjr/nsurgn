# Handoff Brief

## Objective

Resume v1.0 spec gap resolution at `SPEC_GAPS_PLAN.md` Chunk 2: Anomaly
Determinism. The bounded objective is to make `anomalous` classification
testable before fixture, acceptance-test, or production implementation work
depends on it.

## Scope And Non-Goals

Scope:

- `SPEC_GAPS_PLAN.md` Chunk 2 only.
- Source slices: `GAP-1/S1`, `GAP-1/S2`, `GAP-1/S3`.
- Primary edit target: `SPEC.md` section 10.3.
- Secondary edit target only if needed: `DESIGN.md` classification reason or
  internal record language.

Non-goals:

- Do not implement production Bash code.
- Do not add fixtures yet; `GAP-1/S4` belongs to later fixture work.
- Do not change score weights from `SPEC.md` section 10.2.
- Do not revisit Chunk 1 evidence-matching rules unless a direct contradiction
  blocks Chunk 2.

## Current State

Established source facts:

- Repository branch `main` is synchronized with `origin/main`.
- Latest commit is `0c26ac3 Clarify v1 evidence matching rules`.
- `SPEC_GAPS_PLAN.md` is the active coordination artifact. `SPEC_GAPS.md` is
  deprecated but retained as the source gap inventory.
- Chunk 1 has been completed and recorded in `SPEC_GAPS_PLAN.md`: `SPEC.md`
  section 10.5 now contains a normative evidence-matching table for v1.0 score
  and hint signals.
- `DESIGN.md` mount evidence reason-code examples were aligned to underscore
  identifiers used by the normative spec table.
- `SPEC.md` section 10.3 still defines `anomalous` as major namespace
  difference plus broad "concerning, inconsistent, incomplete, or
  hard-to-explain evidence" language, without a finite v1.0 trigger table.

## Established Decisions And Traceability

Relevant completed Chunk 1 decisions:

- Cgroup keyword matches are case-sensitive and evaluated within path
  components after splitting on `/`.
- Lowercase hex container-like IDs use the path-component token regex
  `(^|[^0-9a-f])[0-9a-f]{32,64}([^0-9a-f]|$)`.
- Deleted executable evidence is based on raw `/proc/<pid>/exe` `readlink`
  values ending with `" (deleted)"`; display `exe_path` strips the suffix and
  reason detail preserves it.
- `unshare` evidence is limited to `comm=unshare`, first command argument
  basename `unshare`, or executable basename `unshare`.

Relevant next source requirements:

- `GAP-1/S1`: Define a finite v1.0 anomalous trigger table in `SPEC.md`
  section 10.3. Each row should include trigger name, required evidence,
  reason code, artifact/process scope, and an example.
- `GAP-1/S2`: State unreadable metadata is a limitation by default, not
  anomalous evidence. It can set `anomalous` only when combined with a specific
  trigger from the v1.0 trigger table.
- `GAP-1/S3`: Add spoofability handling for process metadata, cgroup paths, and
  runtime hints. Spoofable metadata can contribute evidence and reasons, but
  cannot by itself create an anomaly unless matched with namespace or
  filesystem inconsistency.

Relevant source locations:

- `SPEC_GAPS_PLAN.md` Chunk 2: objective, scope, dependencies, and stop
  condition.
- `SPEC_GAPS.md` Gap 1: source inventory and resolution slices.
- `SPEC.md` section 10.3: current classification rule language and insertion
  point for the finite anomalous trigger table.
- `SPEC.md` section 10.5: completed evidence matching table to reuse for reason
  code and evidence-source terminology.

## Changed Artifacts

- `.codex/handoffs/current.md`: overwritten with this handoff.

No other files have been changed since commit `0c26ac3`.

## Checks And Evidence

Commands run while preparing this handoff:

- `git status --short --branch`
- `git log -1 --oneline`
- `sed -n '85,145p' SPEC_GAPS_PLAN.md`
- `sed -n '20,80p' SPEC_GAPS.md`
- `sed -n '552,610p' SPEC.md`

Observed evidence:

- `git status --short --branch` showed `## main...origin/main` before writing
  this handoff.
- Latest commit observed: `0c26ac3 Clarify v1 evidence matching rules`.

Checks from the completed Chunk 1 work:

- `git diff --check` passed.
- `test/smoke.sh` passed with `ok - scaffold smoke tests passed`.

## Risks, Blockers, And Open Questions

Open Chunk 2 decisions to encode in the spec:

- Exact finite anomalous trigger names and required evidence.
- Stable reason codes for each anomalous trigger.
- Whether each trigger is artifact-scoped or process-scoped.
- Examples for each trigger.
- Which unreadable-metadata near misses must remain limitations instead of
  anomalies.
- How spoofable process metadata, cgroup paths, and runtime hints interact with
  namespace or filesystem inconsistency.

## Immediate Next Action And Owner

Owner: Unknown

Draft and apply the `SPEC.md` section 10.3 finite v1.0 anomalous trigger table
for `GAP-1/S1`, including trigger names, required evidence, reason codes,
artifact/process scope, and examples.

## Resume Notes

Use `01-understand` for the anomaly rule clarification. Use `05-test` only when
the work moves from rule definition to fixture or acceptance-test planning.
