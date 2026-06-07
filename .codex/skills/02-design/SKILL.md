---
name: 02-design
description: Use when the user wants to design, structure, architect, evaluate, or decide system architecture, component boundaries, service structure, scalability approach, logical deployment constraints, major technical tradeoffs, or high-level design decisions. Do not use for detailed API contracts, database schemas, implementation, concrete deployment topology, CI/CD setup, or production troubleshooting unless design is the main task.
---

# Architecture and System Design

Use this skill to shape a software system at the architecture level: major components, ownership boundaries, interactions, quality attributes, scalability concerns, and tradeoffs. Stop at design decisions that guide later contract, build, test, release, operational, or documentation work.

## Use When

- Designing a new system, service, application, platform, or major subsystem.
- Deciding component boundaries, service boundaries, dependency direction, integration style, data ownership, or architectural responsibility.
- Comparing architectural approaches such as monolith, modular monolith, microservices, event-driven design, batch processing, serverless, or layered architecture.
- Evaluating high-level tradeoffs around simplicity, delivery speed, scalability, availability, latency, consistency, security, operability, maintainability, cost, or migration.
- Creating an architecture proposal, design review, decision summary, or design-level adoption path.

## Avoid When

- Requirements, workflows, scope, or acceptance criteria are still unclear; use `01-understand/SKILL.md`.
- The main task is detailed API contracts, schemas, database design, event formats, or integration payloads; use `03-contract/SKILL.md`.
- The main task is implementation, refactoring, testing, deployment, incident response, security review, performance tuning, or documentation polish.
- A narrow code change does not require a material architecture decision.

## Procedure

1. Frame the design problem: goal, scope, non-goals, known constraints, existing system context, and the decision being made.
2. Separate hard requirements from preferences, assumptions, implementation ideas, and proposed technologies.
3. Identify the architectural drivers that matter for this decision: scale, latency, availability, consistency, security, cost, operability, maintainability, portability, delivery risk, or team constraints.
4. Define the system boundary: users, major components, modules, services, external systems, data stores, queues, jobs, and operational boundaries.
5. Assign responsibilities clearly. For each major part, state what it owns, what it does not own, what it depends on, and what depends on it.
6. Choose interaction and data-ownership patterns. Decide whether communication is synchronous, asynchronous, event-based, batch-oriented, shared-storage-based, or API-based, and explain why.
7. Compare realistic alternatives. State benefits, costs, risks, migration implications, and failure modes; prefer the simplest design that satisfies the known constraints.
8. Address scalability, resilience, and operations only as far as architecture requires: growth paths, bottlenecks, retries, backpressure, partial failure, redundancy, recovery, observability needs, and logical deployment constraints.
9. Produce a practical recommendation with assumptions, tradeoffs, risks, open questions, and the next owning skill when work should move into contracts, build, tests, release, operations, security, performance, or docs.

## Output Shape

Prefer the smallest useful output:

- Architecture recommendation or decision summary
- Component, service, or module boundary description
- Responsibility map
- Interaction flow, dependency outline, or text-based architecture diagram
- Tradeoff comparison of viable options
- Assumptions, risks, constraints, non-goals, and open questions
- Migration or adoption path when changing an existing architecture
- Architecture-owned traceability notes when stable requirement IDs exist

## Quality Bar

- The design directly supports stated requirements and constraints.
- Boundaries and ownership are explicit enough to guide later contracts and implementation.
- Material decisions identify their driving requirements or assumptions when known.
- The recommendation explains why it fits better than realistic alternatives.
- Complexity is justified; do not default to microservices, event streaming, serverless, or distributed systems without concrete need.
- Tooling choices serve the design rather than replacing the design rationale.
- Tradeoffs, failure modes, migration risks, and unresolved assumptions are visible.
- The output stays at the architecture level and does not drift into endpoint definitions, schemas, code, concrete deployment topology, rollout mechanics, test plans, or runbooks unless the user explicitly changes the task.
