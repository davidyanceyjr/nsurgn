---

name: 01-understand
description: Use when the user wants to understand, clarify, explore, scope, define, or make sense of a software problem, user need, workflow, requirement, constraint, feasibility concern, acceptance criterion, or project scope. Do not use for architecture decisions, API/schema design, implementation, testing strategy, or deployment planning unless understanding the problem is the main task.
---

# Discovery and Requirements

## Purpose

This skill helps turn unclear software needs into actionable problem definitions, requirements, workflows, constraints, and acceptance criteria. Use it to understand what must be solved before choosing architecture, designing interfaces, writing code, planning tests, or deploying systems.

The goal is not to design the system in detail. The goal is to define the problem, users, outcomes, boundaries, assumptions, risks, and success conditions well enough that later SDLC work can proceed with less ambiguity.

## When to use

* Use when the task involves clarifying a product idea, feature request, user workflow, business rule, or operational need.
* Use when requirements are incomplete, conflicting, ambiguous, or mixed with premature implementation details.
* Use when defining acceptance criteria, scope boundaries, constraints, assumptions, dependencies, or non-goals.
* Use when evaluating technical feasibility at a high level before committing to design or implementation.
* Use when mapping current-state and future-state workflows, data flows, actors, triggers, or decision points.
* Use when the user asks to be grilled, challenged, interviewed, or ambiguity-audited before downstream design or implementation.
* Use when preparing requirements for handoff to architecture, API design, implementation, testing, or documentation work.

## When not to use

* Do not use when the main task is selecting system architecture, components, deployment topology, or major technical tradeoffs.
* Do not use when the main task is designing database schemas, API endpoints, contracts, or request/response formats.
* Do not use when the user is asking for production code, code modification, debugging, or build configuration.
* Do not use when the main task is creating a test plan, writing tests, or validating a completed implementation.
* Do not use when the main task is release automation, CI/CD, infrastructure, observability, or incident response.
* Do not use to produce lengthy product documentation unless requirements clarification is the core need.

## Inputs to look for

* User goals, business objectives, customer problems, or operational pain points.
* Target users, roles, personas, administrators, external systems, or affected teams.
* For user-facing work, applicable input methods, devices, viewports, browsers/platforms, and accessibility or compatibility constraints.
* Current workflow, desired workflow, edge cases, exceptions, and manual workarounds.
* Functional requirements, non-functional requirements, business rules, and compliance needs.
* Known constraints such as budget, time, platform, technology, data, staffing, policy, or migration limits.
* Existing systems, integrations, data sources, ownership boundaries, and upstream/downstream dependencies.
* Success metrics, acceptance criteria, done conditions, and explicit non-goals.
* Open questions, assumptions, risks, unknowns, and decisions that need owner confirmation.

## Procedure

1. **Identify the problem and outcome.** Restate the user’s goal in plain terms. Separate the real problem from proposed solutions, implementation guesses, and incidental details.

2. **Define scope and actors.** Identify who or what participates in the workflow: users, services, administrators, external systems, scheduled jobs, devices, or data sources. Mark what is in scope, out of scope, and unresolved.

3. **Capture requirements.** Organize requirements into functional behavior, business rules, data needs, constraints, and non-functional expectations. Preserve user wording when it affects meaning, but convert vague statements into testable requirements where possible. When multiple items need downstream tracking, assign stable, concise identifiers such as `REQ-01` and `AC-01`.

4. **Analyze workflows and data flow.** Map the current and desired process at a practical level. Note triggers, inputs, decisions, outputs, handoffs, failure cases, permissions, and state changes. Keep this at problem-definition depth; defer detailed schema and API contracts to the data/API skill.

5. **Assess feasibility and risk.** Identify technical, operational, organizational, security, privacy, performance, migration, or integration concerns that could affect viability. Keep feasibility assessment high-level unless another skill is needed.

6. **Resolve or expose ambiguity.** Ask targeted questions only when the missing information blocks useful progress. Otherwise, state reasonable assumptions and continue. Flag assumptions that require confirmation.

7. **Run a questioning pass when requested.** When the user asks to be grilled, challenged, interviewed, or ambiguity-audited, produce only the smallest useful set of blocking questions, assumptions, and decision points. Group them by requirement, workflow, constraint, risk, or acceptance criteria as appropriate. Do not proceed into architecture, contracts, testing strategy, or implementation until the blocking answers are resolved, reasonably assumed, or explicitly deferred.

8. **Write acceptance criteria.** Convert desired behavior into observable pass/fail criteria. Prefer concise scenario-style criteria using “Given / When / Then” or equivalent plain-language bullets. For user-facing software, include applicable users, input methods, supported devices or viewports, browsers or platforms, and material accessibility or compatibility constraints without inventing a broad UX standard.

9. **Prepare understanding handoff notes.** Expose known IDs, priority, assumptions, constraints, and unresolved problem-definition items. When useful, establish one compact record with `Requirement ID | Acceptance criteria | Design/contract decision | Changed files/components | Tests/evidence | Status/gap`, filling only understanding-owned facts and leaving downstream columns for their owners. Do not make downstream design, implementation, or test decisions. Use `12-handoff/SKILL.md` only when packaging or reviewing a broader active-work transfer is the main task.

## Subagent delegation

Subagents are optional. Use them only when independent, read-only analysis has a concrete advantage, such as exposing materially different requirement gaps, conflicting assumptions, omitted actors or workflows, or feasibility risks. Split work by distinct concern, actor, workflow, or source artifact; do not delegate duplicated generic brainstorming or tightly coupled synthesis.

For each delegation, state the expected advantage and explicitly invoke `01-understand/SKILL.md` in a bounded, self-contained prompt with the inputs and expected output. Keep the task read-only, prohibit recursive delegation and unsupported requirements, priorities, scope decisions, or statuses, and require independently checkable findings. The parent owns consolidated requirements, acceptance criteria, priority, scope, and final synthesis; it must review and integrate results, resolve contradictions, and close completed agents promptly.

Faster models may perform source inventory, requirement classification, or consistency checks with objective acceptance criteria. Ambiguous requirements, stakeholder tradeoffs, and final understanding synthesis require stronger reasoning or parent completion. Model choice never lowers the evidence or review standard.

## Expected outputs

* A concise problem statement and desired outcome.
* A scoped list of users, actors, systems, workflows, and boundaries.
* Functional and non-functional requirements grouped by topic or priority.
* Acceptance criteria that are specific, observable, and testable.
* When requested, a concise questioning-pass output with blocking questions, assumptions, and decision points grouped by topic.
* When useful, one compact requirements or traceability list with stable IDs, priority, assumptions, and unresolved items.
* Assumptions, constraints, risks, dependencies, and open questions.
* Optional workflow, data-flow, or decision-flow outline when useful.
* A handoff summary for architecture, API design, implementation, testing, security, performance, or documentation.

## Quality checks

* Requirements describe outcomes and behavior, not just implementation preferences.
* Scope boundaries are explicit enough to prevent accidental feature creep.
* Acceptance criteria can be verified by a human, test, demo, or operational check.
* Stable IDs improve downstream tracking and are not replaced by competing identifiers.
* User-facing acceptance criteria include material accessibility and compatibility constraints; backend-only work does not inherit irrelevant UX requirements.
* Ambiguities, assumptions, risks, and dependencies are visible instead of hidden.
* Business rules, edge cases, permissions, failure paths, and data needs are considered.
* The output is detailed enough for the next SDLC step but not overloaded with design or code.
* Related skills are suggested only when the task crosses into their ownership.

## Anti-patterns

* Avoid jumping directly from a vague request to architecture, schema, code, or deployment.
* Avoid treating a proposed solution as the confirmed problem.
* Avoid writing broad, untestable requirements such as “make it fast,” “make it user-friendly,” or “support all cases” without clarification.
* Avoid burying assumptions inside confident statements.
* Avoid duplicating responsibilities owned by architecture, API design, testing, security, or implementation skills.
* Avoid producing long product-management templates when a compact requirements brief is enough.
* Avoid creating a heavyweight traceability matrix or assigning design, implementation, or verification status during problem definition.
* Avoid asking excessive questions when reasonable assumptions would allow useful progress.

## Related skills

* `02-design/SKILL.md` — use only when requirements are stable enough to evaluate system structure, components, scalability, or major tradeoffs.
* `03-contract/SKILL.md` — use only when the task shifts to data models, schemas, APIs, contracts, or integration interfaces.
* `08-secure/SKILL.md` — use only when requirements involve authentication, authorization, privacy, secrets, abuse cases, compliance, or security risk.
* `10-improve/SKILL.md` — use only when performance, scalability validation, maintainability, or technical debt is a primary requirement.
* `05-test/SKILL.md` — use only when turning requirements into test strategy, test cases, regression checks, or validation plans.
* `06-document/SKILL.md` — use only when the main task is producing formal requirements documents, decision records, user-facing docs, or lifecycle documentation.
* `12-handoff/SKILL.md` — use only when packaging, reviewing, or resuming a broader active-work transfer is the main task; this skill retains ownership of initial requirement handoff facts.
