---

name: 06-document
description: Use when the user wants to document, explain, write docs, edit docs, organize, publish, or review technical documentation, including requirements docs, architecture notes, API docs, runbooks, test docs, maintenance notes, and decision records. Do not use to invent runbook procedures or other technical decisions.
---

# Technical Documentation

## Purpose

This skill helps produce maintainable technical documentation across the software development lifecycle. It turns technical context into useful written artifacts for readers: requirements summaries, architecture notes, API references, runbooks, testing notes, maintenance docs, and decision records.

This skill owns documentation quality, structure, organization, editing, audience fit, and durable publication. For runbooks, it documents established operational procedures without inventing or changing troubleshooting commands, diagnostics, mitigations, escalation paths, rollback actions, or verification steps. It does not own the underlying engineering decisions, implementation, testing, deployment, security review, or incident response.

## When to use

* Use when the task is to write, revise, summarize, or organize technical documentation.
* Use when formatting, organizing, editing, or publishing established runbook procedures or when documenting requirements, workflows, architecture, APIs, interfaces, tests, releases, maintenance procedures, or decisions.
* Use when converting technical discussion, code behavior, tickets, logs, or design notes into durable written documentation.
* Use when creating onboarding docs, README content, changelog entries, troubleshooting guides, or durably published operational handoff notes from established transfer facts.
* Use when reviewing documentation for clarity, completeness, accuracy, audience fit, or stale information.

## When not to use

* Do not use when the main task is deciding system architecture; use `02-design/SKILL.md`.
* Do not use when the main task is designing schemas, APIs, or contracts; use `03-contract/SKILL.md`.
* Do not use when the main task is writing or changing production code; use `04-build/SKILL.md`.
* Do not use merely to explain code while performing implementation work; use `04-build/SKILL.md`.
* Do not use when the main task is creating or validating tests; use `05-test/SKILL.md`.
* Do not use when the main task is deploying, configuring infrastructure, or managing releases; use `11-release/SKILL.md`.
* Do not use when the main task is troubleshooting an incident or interpreting production signals; use `09-operate/SKILL.md`.
* Do not use to invent or change runbook troubleshooting commands, diagnostics, mitigations, escalation paths, rollback actions, or verification steps; use `09-operate/SKILL.md`.
* Do not use when active-work continuity, transfer packaging, handoff review, or resume context is the main task; use `12-handoff/SKILL.md`.

## Inputs to look for

* Documentation type requested: README, ADR, runbook, API docs, test plan, release notes, onboarding guide, maintenance note, or other artifact.
* Target audience: engineers, operators, reviewers, product stakeholders, security reviewers, support staff, or end users.
* Source material: requirements, tickets, code, comments, architecture notes, schemas, API examples, logs, test results, release changes, or prior docs.
* Scope and boundaries: what system, feature, component, workflow, environment, version, or decision the doc covers.
* Required format: Markdown, plain text, checklist, table, template, inline code comments, repo docs, wiki page, or changelog entry.
* Freshness signals: dates, versions, deprecated behavior, known gaps, TODOs, ownership, and links to source-of-truth material.
* An established compact traceability record when its durable publication is the requested deliverable.
* Constraints: confidentiality, compliance language, naming conventions, repository structure, style guide, and expected length.

## Procedure

1. Identify the documentation goal, audience, and artifact type. If unclear, infer the most useful format from the task and state assumptions briefly inside the document only when needed.

2. Separate documentation work from technical decision-making. Record existing decisions accurately; do not invent requirements, architecture, APIs, test results, deployment behavior, or operational guarantees.

3. Extract the source facts. Prefer explicit user-provided context, repository files, tickets, code behavior, commands, interfaces, logs, and existing docs over assumptions. When asked to publish traceability, preserve established requirement IDs, decisions, changed areas, evidence, statuses, and gaps without inventing or changing them.

4. Choose a structure that matches the artifact:

   * README: purpose, setup, usage, configuration, development, testing, troubleshooting.
   * ADR: status, context, decision, consequences, alternatives.
   * Runbook: organize provided symptoms, impact, checks, mitigation, rollback/escalation, and verification content without inventing procedures.
   * API docs: purpose, auth, endpoints, parameters, examples, errors, compatibility.
   * Test docs: scope, test types, fixtures, commands, coverage gaps, verification notes.
   * Maintenance docs: ownership, recurring tasks, dependencies, upgrade notes, known risks.

5. Write for actionability. Prefer concrete commands, paths, examples, expected outcomes, and verification steps over vague prose.

6. Keep the document compact. Include what readers need to do the job safely; defer deep technical explanation to related source files or specialized docs.

7. Mark uncertainty explicitly. Use labels such as “Assumption,” “Open question,” “TODO,” or “Needs verification” when source material is incomplete.

8. Preserve important context without duplicating entire systems. Link or refer to source-of-truth documents when appropriate instead of copying large amounts of reference material.

9. Review for consistency with existing terminology, component names, API names, environment names, and version identifiers.

10. Finish with a maintenance signal when useful: owner, last updated date, review trigger, deprecation note, or next review condition.

## Subagent delegation

Subagents are optional. Use only when disjoint sections, fact extraction, consistency or reference checks, or audience review has a concrete advantage. Assign a document, section, or read-only task.

State the advantage and explicitly invoke `06-document/SKILL.md` in a bounded prompt defining sources, scope, audience, and output. Prohibit recursive delegation and invented decisions, procedures, evidence, statuses, or ownership. The parent reviews and integrates results, resolves contradictions, owns terminology, structure, and publication, and closes agents.

Formatting, reference checks, and first-pass editing may use faster models with explicit facts and objective criteria. Contradiction analysis and final synthesis require stronger reasoning or parent completion. Model choice never lowers standards.

## Expected outputs

* A complete technical document in the requested or inferred format.
* A revised version of existing documentation with clearer structure, accurate terminology, and reduced ambiguity.
* A documentation outline or template when the user is planning but not ready for final prose.
* A gap list showing missing facts, stale sections, contradictions, or required follow-up checks.
* A concise changelog, ADR, README section, API reference section, test documentation section, maintenance note, or durably published runbook based on established operational procedures.
* A durably published compact traceability record when explicitly requested and supported by established source facts.

## Quality checks

* The document has a clear audience and purpose.
* The scope is explicit: what is covered and what is not covered.
* Technical claims are grounded in provided source material or clearly marked as assumptions.
* Published traceability preserves the owning skills' established facts and does not create engineering decisions, statuses, or evidence.
* Steps are actionable, ordered, and verifiable.
* Commands, paths, names, versions, endpoints, and environment labels are consistent.
* The document avoids duplicating responsibilities owned by architecture, API design, implementation, testing, deployment, security, observability, or performance skills.
* Stale, deprecated, uncertain, or missing information is clearly identified.
* The result is concise enough to be useful in context and durable enough to maintain.

## Anti-patterns

* Avoid inventing technical behavior to make the document feel complete.
* Avoid turning documentation into a broad tutorial when the task needs a focused operational artifact.
* Avoid copying large code blocks, schemas, logs, or config files unless they are essential examples.
* Avoid mixing unresolved design debate into final documentation without labeling it as open.
* Avoid vague phrases like “handle errors appropriately” without explaining expected behavior or escalation.
* Avoid documenting aspirational behavior as if it already exists.
* Avoid hiding risks, assumptions, deprecated behavior, or known gaps.
* Avoid spreading the same source-of-truth content across many documents without a maintenance plan.
* Avoid inventing or updating traceability facts merely to make a documentation artifact appear complete.

## Related skills

* `01-understand/SKILL.md` — use only when requirements, workflows, constraints, or acceptance criteria need to be defined before documenting them.
* `02-design/SKILL.md` — use only when architecture decisions or component boundaries need to be created or evaluated before documentation.
* `03-contract/SKILL.md` — use only when data models, schemas, endpoints, or interface contracts need to be designed before documenting them.
* `04-build/SKILL.md` — use only when production code must be written, read deeply, or changed before documentation can be accurate.
* `05-test/SKILL.md` — use only when test strategy, test cases, regression checks, or bug verification need to be created before documentation.
* `08-secure/SKILL.md` — use only when the documentation depends on security design, threat modeling, permissions, secrets, or vulnerability handling.
* `11-release/SKILL.md` — use only when deployment, CI/CD, environment configuration, release, or rollback behavior must be performed or designed.
* `09-operate/SKILL.md` — use when runbook content requires operational diagnostics, mitigations, escalation paths, rollback actions, or verification procedures to be created or changed.
* `10-improve/SKILL.md` — use only when documentation depends on profiling, tuning, scalability validation, refactoring, or technical debt analysis.
* `07-review/SKILL.md` — use only when documentation work is tied to review workflow, repository hygiene, branching, or static-analysis policy.
* `12-handoff/SKILL.md` — use when active-work continuity or resume context is the main task; documentation retains ownership of formatting, editing, organizing, and durably publishing established handoff material.
