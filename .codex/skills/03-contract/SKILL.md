---

name: 03-contract
description: Use when the user wants to define contracts, model data, specify schemas, design APIs, review payloads, or clarify data models, database structures, API contracts, request/response formats, interface boundaries, or integration contracts. Do not use for full system architecture, business requirements, production implementation, deployment, or runtime troubleshooting unless contract or data/API design is the main task.
---

# Data, API, and Interface Design

## Purpose

This skill helps define precise, durable data structures and interface contracts across already-established system, service, module, client, database, and external-integration boundaries. Use it to turn known requirements and architectural boundaries into usable data models, APIs, schemas, contracts, and integration agreements.

The goal is to make data and interfaces clear, stable, testable, versionable, and difficult to misuse without taking over full architecture, implementation, testing, or deployment responsibilities.

## When to use

* Use when designing database tables, document structures, indexes, relationships, constraints, or migration-ready data models.
* Use when defining REST, RPC, GraphQL, event, webhook, CLI, SDK, file, or internal service interfaces.
* Use when specifying request/response shapes, validation rules, error formats, pagination, filtering, sorting, idempotency, or versioning.
* Use when clarifying interface responsibilities and contracts across established boundaries between services, modules, clients, external vendors, queues, storage layers, or data pipelines.
* Use when reviewing an existing API, schema, or integration contract for correctness, compatibility, clarity, or maintainability.
* Use when converting requirements or architecture decisions into concrete contracts that implementation teams can build against.

## When not to use

* Do not use when the task is mainly discovering business requirements; use `01-understand/SKILL.md`.
* Do not use when deciding the overall system architecture, major components, deployment topology, or scalability strategy; use `02-design/SKILL.md`.
* Do not use when service decomposition, component ownership, or module boundaries are unresolved; use `02-design/SKILL.md`.
* Do not use when writing production code unless the primary issue is contract or schema design; use `04-build/SKILL.md`.
* Do not use when the primary task is test planning, test automation, or bug verification; use `05-test/SKILL.md`.
* Do not use when the primary concern is authentication, authorization, secrets, threat modeling, or vulnerability review; use `08-secure/SKILL.md`.
* Do not use for CI/CD, cloud configuration, release automation, incident response, or log analysis.

## Inputs to look for

* Business capabilities, user workflows, acceptance criteria, existing requirements, and stable identifiers when available.
* Relevant architectural boundaries, components, consumers, producers, systems, and ownership lines.
* Existing data structures, APIs, schemas, database migrations, events, contracts, or interface documentation.
* Read/write patterns, query patterns, consistency needs, data lifecycle, retention, and archival expectations.
* Entities, relationships, identifiers, state transitions, invariants, cardinality, and validation rules.
* Consumers, clients, integrations, compatibility constraints, versioning expectations, and migration limitations.
* Error cases, failure modes, retry behavior, idempotency needs, timeout expectations, and rate limits.
* Security-sensitive fields, privacy requirements, access boundaries, and compliance constraints, without performing full security review.
* Performance-sensitive access patterns, expected scale, latency expectations, and payload size constraints, without performing full performance engineering.

## Procedure

1. **Identify the interface boundary.** Determine what is being designed: database schema, API endpoint, event contract, file format, internal module interface, external integration, or some combination. Name producers, consumers, owners, and responsibilities.

2. **Extract the domain model.** Identify core entities, fields, relationships, identifiers, state transitions, required invariants, optional data, derived data, and lifecycle rules. Separate domain facts from implementation convenience.

3. **Design the contract shape.** Define tables, documents, endpoint paths, methods, messages, events, schemas, parameters, headers, payloads, response bodies, or function signatures as appropriate. Keep names consistent, explicit, and stable. Map material contracts and schemas to the known requirement IDs they satisfy.

4. **Define validation and constraints.** Specify required fields, allowed values, formats, uniqueness rules, foreign-key or reference behavior, nullability, length limits, enum handling, temporal rules, and cross-field constraints.

5. **Model reads and writes.** Confirm that the design supports expected create, read, update, delete, search, listing, filtering, sorting, pagination, aggregation, and reporting patterns without leaking unrelated implementation details.

6. **Specify failure behavior.** Define error structures, status codes or error categories, retry guidance, idempotency behavior, conflict handling, partial success behavior, and validation error detail.

7. **Address compatibility.** Identify versioning rules, backward compatibility expectations, deprecation paths, migration needs, default values, tolerant readers, and how new fields or enum values should be handled. Tie material validation and compatibility decisions to known requirement IDs.

8. **Check integration boundaries.** Confirm ownership, source of truth, synchronization behavior, data freshness, ordering guarantees, deduplication rules, and responsibilities between systems.

9. **Flag cross-cutting concerns.** Note security, performance, observability, testing, or documentation issues that require related skills, but do not expand into those disciplines unless they are central to the task.

10. **Produce a build-ready specification.** Present the contract in a format suitable for implementation and review: concise schema, API contract, field table, endpoint list, event definition, ERD-style summary, or migration notes.

## Expected outputs

* Data model or schema proposal with entities, fields, relationships, constraints, and ownership notes.
* API or interface contract with operations, inputs, outputs, validation, errors, and compatibility rules.
* Request/response examples or event/message examples when they clarify the contract.
* Integration boundary summary showing producers, consumers, source of truth, and data flow.
* Migration or versioning notes for evolving existing contracts safely.
* Contract-owned updates to the compact traceability record for material contracts, schemas, validation rules, and compatibility decisions.
* Open questions, assumptions, risks, and tradeoffs that need confirmation before implementation.
* Review findings for existing schemas or APIs, grouped by correctness, usability, compatibility, and maintainability.

## Quality checks

* The design maps back to stated requirements or known architecture boundaries.
* Known requirement IDs are retained for material contract decisions without duplicating the full traceability record.
* Entities, fields, endpoints, messages, and relationships have clear ownership and purpose.
* Required, optional, nullable, derived, and deprecated fields are distinguishable.
* Identifiers, timestamps, states, enums, and references are consistent across the design.
* Read/write/query patterns are supported without unnecessary coupling or overfetching.
* Error handling is predictable and useful to both humans and calling systems.
* Versioning and migration behavior are explicit enough to prevent accidental breaking changes.
* The contract avoids leaking private implementation details across boundaries.
* Security- or privacy-sensitive fields are identified for deeper review when needed.
* The output is concrete enough for implementation but not overloaded with framework-specific mechanics.

## Anti-patterns

* Avoid designing APIs or schemas before the boundary, consumer, and source of truth are clear.
* Avoid mixing business problem definition, architecture selection, implementation, test planning, and deployment into this skill.
* Avoid vague fields such as `data`, `metadata`, `type`, or `status` without precise semantics.
* Avoid unbounded payloads, ambiguous nulls, inconsistent IDs, magic strings, or undocumented enum behavior.
* Avoid designing only for the happy path while ignoring validation, conflicts, retries, and partial failures.
* Avoid breaking existing consumers without explicit versioning, migration, or compatibility strategy.
* Avoid copying database internals directly into public APIs unless that coupling is intentional and justified.
* Avoid framework-specific syntax unless the user’s task already requires that framework.
* Avoid exhaustive reference material; provide the contract and the decisions needed to use it.
* Avoid inventing requirement IDs or treating general UI compatibility as API contract ownership.

## Related skills

* `01-understand/SKILL.md` — use only when requirements, workflows, acceptance criteria, or domain constraints are unclear.
* `02-design/SKILL.md` — use only when component boundaries, ownership, service decomposition, or major technical tradeoffs are unresolved.
* `04-build/SKILL.md` — use only when turning the approved contract into production code.
* `05-test/SKILL.md` — use only when creating contract tests, integration tests, regression tests, or validation plans.
* `08-secure/SKILL.md` — use only when authentication, authorization, privacy, threat modeling, secrets, or abuse resistance are central concerns.
* `10-improve/SKILL.md` — use only when schema or API choices are driven mainly by performance, profiling, scaling limits, or long-term maintainability.
* `06-document/SKILL.md` — use only when producing formal API docs, schema docs, ADRs, or long-lived integration documentation.
