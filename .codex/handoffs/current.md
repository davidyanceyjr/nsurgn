# Handoff Brief

## Objective
Continue the documentation footprint reduction work for `nsurgn` v1.0 using the plan in `.codex/plans/documentation-footprint-plan.md`.

The goal is to reduce the combined implementation footprint of `SPEC.md` and `DESIGN.md` while preserving enough public contract, internal design detail, and traceability to implement v1. `SPEC.md` does not need to be the single source.

## Scope And Non-Goals
Scope:

- `SPEC.md` public product and CLI contract.
- `DESIGN.md` implementation-facing architecture, records, algorithms, command flow, and output contracts.
- Cross-references and deduplication between the two documents.

Non-goals:

- Production code changes.
- New technical behavior.
- Technical correctness validation beyond preserving existing documented contracts.
- Durable historical documentation beyond this working handoff and plan.

## Current State
A remediation plan has been created at `.codex/plans/documentation-footprint-plan.md`.

Current baseline measured from the working tree:

- `SPEC.md`: 74,239 bytes, 1,860 lines.
- `DESIGN.md`: 62,813 bytes, 1,580 lines.
- Combined: 137,052 bytes, 3,440 lines.

No edits have been made to `SPEC.md` or `DESIGN.md` yet in this plan session.

## Established Decisions And Traceability
User clarification:

- `SPEC.md` does not need to be the single source.
- The goal is a documentation footprint that allows implementation.

Plan source of truth:

- `.codex/plans/documentation-footprint-plan.md`

Findings captured in the plan:

- `SPEC.md` section 10.5 is the largest bloat hotspot and should be reduced first.
- `SPEC.md` section 10.3 repeats classification rules.
- `SPEC.md` section 16.3 mixes public exit-code contract with command metadata materiality detail.
- `SPEC.md` sections 12.3 and 12.4 repeat artifact ID and target-resolution prose.
- `SPEC.md` section 13.5 repeats target visibility rules for `map`.
- `SPEC.md` sections 22 and 23 are README/design-position material.
- `DESIGN.md` already owns many implementation contracts and should be deduplicated rather than used as a dumping ground for moved material.

## Changed Artifacts
- `.codex/plans/documentation-footprint-plan.md`: added working plan for resolving documentation footprint findings.
- `.codex/handoffs/current.md`: updated to this handoff.

## Checks And Evidence
Commands run:

- `wc -c SPEC.md DESIGN.md`
- `wc -l SPEC.md DESIGN.md`
- `git status --short`
- `sed -n '1,260p' .codex/plans/documentation-footprint-plan.md`

Observed git status before this handoff write:

- `.codex/handoffs/current.md` modified.
- `.codex/plans/` untracked.

## Risks, Blockers, And Open Questions
Risk: deleting evidence details may remove implementation-critical behavior. The plan directs checking whether equivalent detail already exists in `DESIGN.md` before deletion.

Risk: reducing `SPEC.md` could make public conformance ambiguous. The plan preserves externally visible labels, scores, selectors, precedence, error outcomes, and output guarantees in `SPEC.md`.

Risk: moving content into `DESIGN.md` could preserve the same context bloat. The plan measures combined size and prefers deduplication over relocation.

Open question: no exact target size was set by the user. The plan uses "materially smaller than 137,052 bytes" as the working size target and implementability as the primary criterion.

## Immediate Next Action And Owner
Owner: Unknown. Execute Pass 1 from `.codex/plans/documentation-footprint-plan.md` by adding or refining short document ownership notes near the top of `SPEC.md` and `DESIGN.md`.

## Resume Notes
Use `06-document` for documentation edits. Start with the plan file, then inspect the current `SPEC.md` and `DESIGN.md` before editing. After each major pass, run the validation checks listed in the plan.
