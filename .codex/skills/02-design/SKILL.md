---

name: 02-design
description: Use when the user wants to design, structure, architect, evaluate, or decide system architecture, component boundaries, service structure, scalability approach, logical deployment constraints, major technical tradeoffs, or high-level design decisions. Do not use for detailed API contracts, database schemas, implementation, concrete deployment topology, CI/CD setup, or production troubleshooting unless design is the main task.
---

# Architecture and System Design

## Purpose

Use this skill to design the high-level structure of a software system. It helps define major components, responsibilities, boundaries, interactions, scalability concerns, and technical tradeoffs before detailed implementation begins.

This skill owns architectural reasoning. It should produce practical design guidance that helps a team decide how the system should be shaped, not exhaustive framework documentation or low-level code.

## When to use

* Use when designing a new system, service, platform, application, or major subsystem.
* Use when deciding between architectural approaches such as monolith, modular monolith, microservices, event-driven architecture, batch processing, serverless, or layered architecture.
* Use when defining component responsibilities, service boundaries, dependency direction, integration style, or data ownership at a high level.
* Use when evaluating scalability, availability, fault tolerance, latency, consistency, extensibility, or operational tradeoffs.
* Use when creating an architecture proposal, design review, technical decision summary, or design-level adoption roadmap that defers production implementation.
* Use when redesigning system architecture or making major component, service, module, or ownership boundary decisions.

## When not to use

* Do not use when the task is mainly to define database tables, API endpoints, schemas, message formats, or request/response contracts; use `03-contract/SKILL.md`.
* Do not use when the task is mainly writing or modifying production code; use `04-build/SKILL.md`.
* Do not use when the task is mainly requirements clarification, acceptance criteria, or workflow analysis; use `01-understand/SKILL.md`.
* Do not use when the task is mainly CI/CD, containers, cloud configuration, or release automation; use `11-release/SKILL.md`.
* Do not use when the task is mainly incident diagnosis, log analysis, alerting, or production troubleshooting; use `09-operate/SKILL.md`.
* Do not use when refactoring or technical debt reduction is the central goal; use `10-improve/SKILL.md`.
* Do not use for security, performance, or documentation as standalone tasks unless they directly affect architectural decisions.

## Inputs to look for

* Business goal, user workflow, or product capability being supported.
* Known requirements, constraints, assumptions, acceptance criteria, and stable identifiers when available.
* Expected users, traffic, data volume, latency needs, availability needs, and growth expectations.
* Existing system context, current architecture, dependencies, and integration points.
* Technology constraints, team skills, hosting environment, budget, timeline, and compliance limits.
* Data ownership expectations, consistency requirements, and cross-system communication needs.
* Operational expectations such as logical deployment constraints, failure tolerance, observability, and support model.
* Explicit non-goals and areas that should not be redesigned.

## Procedure

1. **Frame the design problem.** Restate the system goal, scope, known constraints, and the architectural decision being made. Identify unclear assumptions instead of silently designing around them.

2. **Separate requirements from design choices.** Distinguish hard requirements from preferences, guesses, and implementation ideas. Do not treat a proposed technology as mandatory unless the task says it is.

3. **Identify architectural drivers.** Determine which forces matter most: simplicity, delivery speed, scalability, latency, availability, data consistency, security, cost, operability, maintainability, portability, or organizational boundaries. Map each material driver and decision to the known requirement IDs that justify it.

4. **Define system boundaries.** Identify major components, services, modules, external systems, users, data stores, queues, and operational boundaries. Keep the design at the right level of abstraction.

5. **Assign responsibilities.** For each major component, define what it owns, what it does not own, what it depends on, what depends on it, and which known requirement IDs require it.

6. **Choose interaction patterns.** Decide whether components should communicate synchronously, asynchronously, through events, through shared storage, through APIs, or through batch jobs. Explain why the choice fits the requirements.

7. **Evaluate tradeoffs.** Compare realistic alternatives. State benefits, costs, risks, failure modes, and migration implications. Prefer the simplest architecture that satisfies the known constraints.

8. **Address scalability and resilience.** Describe how the design handles growth, bottlenecks, retries, backpressure, partial failure, redundancy, recovery, and graceful degradation when relevant.

9. **Define decision boundaries for related work.** State logical deployment constraints that architecture must satisfy, then defer concrete topology, platform configuration, rollout mechanics, detailed schemas, endpoint contracts, implementation patterns, test plans, and runbooks to the appropriate related skills.

10. **Produce the design output.** Present the recommended architecture, key decisions, component responsibilities, tradeoffs, risks, assumptions, and next steps.

## Expected outputs

* High-level architecture proposal or design summary.
* Component, service, or module boundary description.
* Responsibility map showing what each major part owns.
* System interaction flow, dependency outline, or text-based architecture diagram.
* Tradeoff analysis comparing viable architectural options.
* Recommendation with assumptions, risks, constraints, and non-goals.
* Architecture-owned updates to the compact traceability record, mapping known IDs to material decisions, components, or tradeoffs.
* Migration or adoption path when changing an existing architecture.
* Open questions that must be resolved before implementation.

## Quality checks

* The design directly supports the stated requirements and constraints.
* Material decisions and components identify their driving requirement IDs when known; the skill does not duplicate the full traceability record.
* Component boundaries are clear and do not duplicate ownership.
* The recommendation explains why it is better than realistic alternatives.
* The architecture avoids unnecessary complexity for the current scale.
* Critical quality attributes are addressed: reliability, scalability, maintainability, operability, and security where relevant.
* Data ownership and integration boundaries are clear enough to guide later API and schema work.
* Failure modes and operational risks are acknowledged.
* Logical deployment constraints are clear without prescribing concrete platform topology or rollout mechanics.
* The output leaves detailed implementation, contracts, tests, deployment, and runbooks to related skills instead of absorbing them.

## Anti-patterns

* Avoid defaulting to microservices, event streaming, serverless, or distributed systems without a concrete need.
* Avoid designing from favorite tools instead of requirements and constraints.
* Avoid vague boxes such as “backend,” “processor,” or “manager” without clear responsibilities.
* Avoid mixing architecture with low-level code, endpoint definitions, or database DDL.
* Avoid pretending tradeoffs do not exist.
* Avoid optimizing for hypothetical future scale while ignoring current delivery risk.
* Avoid creating a design that no team can realistically build, operate, or migrate toward.
* Avoid hiding assumptions that materially affect the recommendation.
* Avoid requiring architecture work or inventing architectural traceability for changes that do not need a material design decision.

## Related skills

* `01-understand/SKILL.md` — use only when the problem, workflows, constraints, or acceptance criteria are unclear.
* `03-contract/SKILL.md` — use only when detailed data models, schemas, APIs, contracts, or integration payloads are needed.
* `04-build/SKILL.md` — use only when turning the approved architecture into production code.
* `08-secure/SKILL.md` — use only when threat modeling, authentication, authorization, secrets, compliance, or security controls materially affect architecture.
* `11-release/SKILL.md` — use only when concrete deployment topology, platform configuration, CI/CD, containers, rollout, or rollback mechanics are the main task.
* `09-operate/SKILL.md` — use only when monitoring, incident response, diagnostics, or reliability operations are the main task.
* `10-improve/SKILL.md` — use only when profiling, scalability validation, refactoring, or technical debt reduction is the central goal.
* `06-document/SKILL.md` — use only when converting the design into formal documentation, ADRs, diagrams, or long-lived project docs.
