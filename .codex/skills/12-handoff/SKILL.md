---
name: 12-handoff
description: Use when the user wants to hand off, transfer, resume, summarize, package, or review a bounded transfer of active technical work between people, agents, sessions, or skill owners and continuity is the main task. Do not use merely because one skill leads to another, when the underlying engineering work should be performed, or when durable documentation is the primary deliverable.
---

# Work Handoff and Continuity

## Purpose

This skill makes active technical work practical to continue across people, agents, sessions, or skill owners. It packages the minimum reliable context needed to resume a bounded objective, reviews existing handoffs for gaps, and reconstructs resume context from available artifacts.

The skill preserves established facts, evidence, and owner-issued statuses without changing their meaning. It does not perform the receiving owner's work, invent missing context, orchestrate a lifecycle, or make code-complete, functional-verification, merge-readiness, release-readiness, production-health, or handoff-quality status claims.

## Mandatory output contract

* Output one compact `Handoff Brief`; do not add a transfer-quality score, readiness verdict, or separate review preface.
* In `Current State`, report source facts and gaps. For an unsupported claim, write that the claim is unsupported and why; do not replace it with `unverified`, `not ready`, or another conclusion.
* In `Immediate Next Action And Owner`, give one atomic action only. Do not join actions into a sequence or make the action perform another skill's engineering work.
* Use only a source-established owner. Otherwise write `Owner: Unknown`; never assign a plausible role or team.

## When to use

* Use when pausing active work and another person, agent, session, or skill owner needs to continue it.
* Use when reviewing a handoff brief for missing, stale, contradictory, or unsupported transfer information.
* Use when resuming interrupted work and reconstructing a compact brief from available source artifacts.

## When not to use

* Do not require a formal handoff merely because one skill naturally leads to another.
* Do not use when the main task is requirements, architecture, contracts, implementation, testing, security, performance, source control, deployment, observability, or documentation work.
* Do not use to choose or enforce a complete lifecycle sequence, manage a project, or plan unrelated later work.
* Do not use when formatting, editing, organizing, or durably publishing established handoff material is the main task; use `06-document/SKILL.md`.
* Do not replace an unsupported readiness claim with an opposite readiness claim. Mark the original claim unsupported and identify the missing owner-issued evidence.

## Inputs to look for

* The bounded objective, scope, non-goals, source, intended recipient or next owner, and immediate next action.
* Existing requirement and acceptance-criterion IDs, decisions, contracts, and traceability records.
* Changed files, artifacts, revisions, branches, environments, or other location-specific context.
* Commands or checks run, actual results, evidence locations, and unverified areas.
* Owner-issued implementation, validation, merge, release, or production-health statuses.
* Completed, in-progress, blocked, deferred, and out-of-scope work.
* Assumptions, risks, blockers, unresolved questions, and decisions awaiting an owner.
* Freshness signals such as dates, revisions, branch state, environment state, or subsequent changes.

## Procedure

1. **Identify the transfer boundary.** State the source, intended recipient or next owner, bounded objective, scope, non-goals, and why work is being transferred. If an owner is unknown, label it unknown rather than assigning one.

2. **Inspect source artifacts.** Read the available requirements, decisions, code changes, diffs, issue or review context, test results, logs, and prior notes needed for continuity. Prefer source artifacts over summaries.

3. **Classify the information.** Distinguish established facts from assumptions, explicitly labeled inferences, stale information, contradictions, and missing context. Do not add speculative engineering risks, requirements, or checks.

4. **Preserve established meaning.** Retain stable IDs, decisions, artifact names, evidence locations, and owner-issued statuses exactly enough that the next worker can trace them. Do not upgrade, downgrade, combine, or replace statuses owned by other skills.

5. **Summarize current state.** Record what is completed, in progress, blocked, deferred, and out of scope. Include changed artifacts and relevant revisions without copying entire diffs, logs, schemas, or source documents.

6. **Record checks and evidence.** List commands or checks actually performed, their actual results, evidence locations, environment assumptions, and known gaps. Mark claims unsupported when no evidence is available. Preserve an unsupported readiness claim only as an unsupported source claim; do not conclude the opposite readiness status.

7. **Identify the immediate next action.** Name exactly one smallest useful continuation action. Name its owner only when established by the sources; otherwise state `Owner: Unknown`. Record later needs as unresolved or deferred without ordering them.

8. **Produce a compact resume brief.** Order the brief for actionability. Always include the objective, current state, and exactly one immediate next action with its established or unknown owner. Include other fields only when applicable and enough context to locate source-of-truth artifacts.

9. **Review transfer quality.** Check for contradictions, unsupported claims, stale context, missing evidence, unclear ownership, hidden blockers, and ambiguity between facts and assumptions. Identify missing transfer information without grading handoff quality or readiness.

## Subagent delegation

Subagents are optional and read-only. Use one only when an independent transfer-quality review has a concrete advantage because source context is high-risk, stale, contradictory, or unusually complex. Do not spawn for routine handoffs, and do not let the subagent perform the receiving skill's work.

State the expected advantage and explicitly invoke `12-handoff/SKILL.md` in a bounded, self-contained prompt containing the draft or source artifacts and expected findings. Require the mandatory output contract, prohibit recursive delegation and unsupported facts, statuses, owners, readiness decisions, or ownership changes, and preserve all owner-issued statuses. The parent must review and integrate the findings, produce the final `Handoff Brief`, select its single immediate next action, resolve contradictions, and close the completed agent promptly.

Faster models may check required-field presence and references with objective acceptance criteria. Contradiction analysis and final handoff synthesis require stronger reasoning or parent completion. Model choice never lowers the evidence or review standard.

## Expected outputs

Always include `Objective`, `Current State`, and `Immediate Next Action And Owner`. Use other sections only when applicable:

```markdown
# Handoff Brief

## Objective
## Scope And Non-Goals
## Current State
## Established Decisions And Traceability
## Changed Artifacts
## Checks And Evidence
## Risks, Blockers, And Open Questions
## Immediate Next Action And Owner
## Resume Notes
```

The brief may report missing transfer information or insufficient confidence to resume. It must identify exactly one immediate next action, use `Owner: Unknown` when ownership is not established, and must not create a handoff readiness status or reinterpret statuses owned by other skills.

## Quality checks

* The next worker can identify the bounded objective, current state, and exactly one immediate action.
* Facts, assumptions, inferences, unknowns, and stale information are distinguishable.
* Stable IDs, decisions, evidence, and owner-issued statuses retain their original meaning.
* Evidence points to actual artifacts or results instead of unsupported claims.
* Completed, blocked, deferred, and out-of-scope work is explicit where relevant.
* The immediate next action has a source-established owner or uses `Owner: Unknown`.
* The brief is compact, references source artifacts, and does not duplicate them.
* The handoff neither performs another skill's work nor prescribes a full lifecycle sequence.

## Anti-patterns

* Avoid treating every transition between skills as requiring a formal handoff.
* Avoid inventing decisions, evidence, statuses, owners, completion claims, or freshness.
* Avoid replacing an unsupported readiness claim with an opposite readiness claim.
* Avoid expanding missing context into speculative engineering risks, requirements, checks, or a sequence of next steps.
* Avoid replacing source artifacts with an unmaintainable summary.
* Avoid copying large logs, diffs, schemas, or documents instead of referencing them.
* Avoid hiding uncertainty, contradictions, missing context, or stale information.
* Avoid turning the handoff into project management, lifecycle orchestration, or durable documentation.

## Related skills

* `01-understand/SKILL.md` - use when initial requirements, acceptance criteria, priority, assumptions, or unresolved problem-definition items must be defined.
* `06-document/SKILL.md` - use when formatting, editing, organizing, or durably publishing established handoff material is the main task.
* Use the relevant owning skill when the requested work is to create or change engineering decisions, artifacts, evidence, or readiness status rather than transfer them.
