---
name: 12-handoff
description: Use when the user wants to handoff, hand off, transfer, resume, summarize, package, or review a bounded transfer of active technical work between people, agents, sessions, or skill owners and continuity is the main task. Do not use merely because one skill leads to another, when the underlying engineering work should be performed, or when durable documentation is the primary deliverable.
---

# Work Handoff and Continuity

## Purpose

Use this skill to package the minimum reliable context needed to continue bounded technical work across people, agents, sessions, or skill owners. It creates compact resume briefs, reviews handoffs for gaps, and reconstructs transfer context from available artifacts.

The skill preserves established facts, evidence, and owner-issued statuses. It does not perform the receiving owner's work, invent missing context, orchestrate a lifecycle, or make code-complete, verification, merge-readiness, release-readiness, production-health, or handoff-quality status claims.

## Mandatory output contract

* Output one compact `Handoff Brief`; do not add a transfer-quality score, readiness verdict, or separate review preface.
* In `Current State`, report source facts and gaps. For unsupported claims, say the claim is unsupported and why; do not replace it with `unverified`, `not ready`, or an opposite conclusion.
* In `Immediate Next Action And Owner`, give exactly one atomic action. Do not join actions into a sequence or make the action perform another skill's engineering work.
* Use only source-established owners. Otherwise write `Owner: Unknown`; never assign a plausible role or team.

## When to use

* Pause active work so another person, agent, session, or skill owner can continue it.
* Review a handoff for missing, stale, contradictory, or unsupported transfer information.
* Resume interrupted work by reconstructing a compact brief from source artifacts.

## Route elsewhere

* Do not require a formal handoff merely because one skill naturally leads to another.
* Use the relevant owning skill when the work is to create or change requirements, architecture, contracts, code, tests, security posture, performance, source control, deployment, observability, evidence, or readiness status.
* `01-understand/SKILL.md` — requirements, acceptance criteria, priority, assumptions, or unresolved problem-definition items must be defined.
* `06-document/SKILL.md` — formatting, editing, organizing, durably publishing, release notes, runbooks, or other documentation is the main task.
* Do not replace unsupported readiness claims with opposite readiness claims. Mark the source claim unsupported and identify missing owner-issued evidence.

## Inputs to look for

* Transfer boundary: bounded objective, scope, non-goals, source, intended recipient or next owner, and immediate next action.
* Traceability: requirement and acceptance-criterion IDs, decisions, contracts, stable artifact names, and evidence locations.
* Artifacts: changed files, revisions, branches, environments, issue or review context, logs, diffs, and prior notes.
* Evidence: commands or checks run, actual results, assumptions, evidence locations, unverified areas, and known gaps.
* Work state: owner-issued implementation, validation, merge, release, or production-health statuses; completed, in-progress, blocked, deferred, and out-of-scope work.
* Freshness and risk: dates, branch state, environment state, subsequent changes, contradictions, blockers, unresolved questions, and decisions awaiting an owner.

## Procedure

1. **Identify the transfer boundary.** State the source, intended recipient or next owner, bounded objective, scope, non-goals, and transfer reason. If ownership is not source-established, use `Owner: Unknown`.

2. **Inspect source artifacts.** Read the requirements, decisions, code changes, diffs, issue or review context, test results, logs, and prior notes needed for continuity. Prefer source artifacts over summaries.

3. **Classify information.** Separate established facts from assumptions, labeled inferences, stale information, contradictions, and missing context. Do not add speculative engineering risks, requirements, checks, or owners.

4. **Preserve established meaning.** Keep stable IDs, decisions, artifact names, evidence locations, and owner-issued statuses traceable. Do not upgrade, downgrade, combine, or replace statuses owned by other skills.

5. **Summarize current state.** Record completed, in-progress, blocked, deferred, and out-of-scope work. Include changed artifacts and relevant revisions without copying entire diffs, logs, schemas, or source documents.

6. **Record checks and evidence.** List checks actually performed, actual results, evidence locations, environment assumptions, and gaps. Preserve unsupported readiness claims only as unsupported source claims; do not conclude the opposite readiness status.

7. **Identify the immediate next action.** Name exactly one smallest useful continuation action. Name its owner only when established by sources; otherwise state `Owner: Unknown`. Record later needs as unresolved or deferred without ordering them.

8. **Produce the compact brief.** Always include the objective, current state, and exactly one immediate next action with established or unknown owner. Include other fields only when applicable and enough context to locate source-of-truth artifacts.

9. **Review transfer quality.** Check contradictions, unsupported claims, stale context, missing evidence, unclear ownership, hidden blockers, and ambiguity between facts and assumptions. Report gaps without grading handoff quality or readiness.

## Subagent delegation

Subagents are optional and read-only. Use one only when source context is high-risk, stale, contradictory, or unusually complex, and do not let it perform the receiving skill's work.

State the expected advantage and invoke `12-handoff/SKILL.md` in a bounded prompt containing the draft or source artifacts. Require the mandatory output contract; prohibit recursive delegation and unsupported facts, statuses, owners, readiness decisions, or ownership changes; and preserve owner-issued statuses. The parent owns the final `Handoff Brief`, resolves contradictions, selects the single immediate next action, and closes the agent promptly.

Faster models may check required fields and references against objective acceptance criteria. Contradiction analysis and final synthesis require stronger reasoning or parent completion. Model choice never lowers the evidence standard.

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

## Quality bar

* The next worker can identify the bounded objective, current state, and exactly one immediate action.
* Facts, assumptions, inferences, unknowns, stale information, contradictions, evidence, and gaps are distinguishable.
* Stable IDs, decisions, artifacts, evidence, and owner-issued statuses retain their original meaning.
* Owners, statuses, completion claims, freshness, readiness, requirements, checks, and decisions are not invented.
* The brief is compact, references source artifacts, and avoids copying large logs, diffs, schemas, or documents.
* The handoff does not perform another skill's work, prescribe a lifecycle sequence, become project management, or become durable documentation.
