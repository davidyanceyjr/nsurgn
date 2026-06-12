# Handoff Brief

## Objective
Continue the documentation footprint reduction work for `nsurgn` v1.0 using the plan in `.codex/plans/documentation-footprint-plan.md`.

The goal is to reduce the combined implementation footprint of `SPEC.md` and `DESIGN.md` while preserving enough public contract, internal design detail, and traceability to implement v1. `SPEC.md` does not need to be the single source.

## Current State
Passes 1 through 6 from `.codex/plans/documentation-footprint-plan.md` have been applied.

Current measured footprint:

- `SPEC.md`: 62,840 bytes, 1,670 lines.
- `DESIGN.md`: 62,433 bytes, 1,579 lines.
- Combined: 125,273 bytes, 3,249 lines.

Baseline from the plan:

- Combined: 137,052 bytes, 3,440 lines.

Net reduction so far:

- 11,779 bytes.
- 191 lines.

## Changed Artifacts
- `SPEC.md`: added document ownership note; reduced classification repetition; compressed evidence and hint normalization; deduplicated target resolution and `map` target visibility prose; replaced the exit-code materiality matrix with compact materiality rules; removed standalone `README-Oriented Summary` and `Design Position` tail sections.
- `DESIGN.md`: added document ownership note; deduplicated repeated target-capable command flow.
- `.codex/plans/documentation-footprint-plan.md`: existing working plan remains untracked.
- `.codex/handoffs/current.md`: updated to this handoff.

## Checks And Evidence
Commands run:

- `wc -c SPEC.md DESIGN.md`
- `wc -l SPEC.md DESIGN.md`
- `rg -n "^(#{1,6})\\s+" SPEC.md DESIGN.md`
- `rg -n "evidence|classification|target resolution|materiality|README-Oriented|Design Position" SPEC.md DESIGN.md`
- `rg -n "README-Oriented|Design Position" SPEC.md DESIGN.md || true`
- `git diff --stat`

Observed results:

- Heading scan completed and section numbering now ends at `SPEC.md` section 21.
- No `README-Oriented` or `Design Position` headings remain.
- `git diff --stat`: `.codex/handoffs/current.md`, `DESIGN.md`, and `SPEC.md` changed; total `144 insertions(+), 361 deletions(-)`.

## Risks, Blockers, And Open Questions
Risk: section 10.5 is now much more compact. It preserves public matching rules and reason codes, but a future implementation pass should verify whether `DESIGN.md` needs a more detailed internal parsing table before coding.

Open question: no exact target size was set by the user. The combined docs are materially smaller, but further reduction may still be possible in `DESIGN.md`.

## Immediate Next Action And Owner
Owner: Unknown. Review the documentation diff for acceptable information loss before committing or using it as the implementation baseline.

## Resume Notes
Use `06-document` for further documentation edits. Use `07-review` if the next step is preparing or committing the change set.
