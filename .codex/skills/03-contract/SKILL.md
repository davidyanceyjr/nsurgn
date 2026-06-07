---
name: 03-contract
description: Use when the user wants to define contracts, model data, specify schemas, design APIs, review payloads, or clarify data models, database structures, API contracts, request/response formats, interface boundaries, or integration contracts. Do not use for full system architecture, business requirements, production implementation, deployment, or runtime troubleshooting unless contract or data/API design is the main task.
---

# Data, API, and Interface Design

Use this skill to define precise, durable data structures and interface contracts across established system, service, module, client, database, and external-integration boundaries. Produce contracts that are clear, stable, testable, versionable, and difficult to misuse without taking over architecture, implementation, testing, deployment, or operations.

## Use When

- Designing database tables, document structures, indexes, relationships, constraints, or migration-ready data models.
- Defining REST, RPC, GraphQL, event, webhook, CLI, SDK, file, or internal service interfaces.
- Specifying request/response shapes, payloads, validation, errors, pagination, filtering, sorting, idempotency, or versioning.
- Clarifying producers, consumers, owners, source of truth, and responsibilities across known boundaries.
- Reviewing an existing API, schema, payload, or integration contract for correctness, compatibility, clarity, or maintainability.
- Turning requirements or architecture decisions into build-ready contracts.

## Avoid When

- Requirements, workflows, acceptance criteria, or domain rules are unclear; use `01-understand/SKILL.md`.
- System architecture, component boundaries, ownership, service decomposition, or major tradeoffs are unresolved; use `02-design/SKILL.md`.
- The main task is implementation, testing, deployment, incident response, security review, performance tuning, or documentation polish.
- The task only needs minor code-level type or interface edits without broader contract decisions.

## Procedure

1. Identify the contract boundary: database schema, API endpoint, event, message, file format, internal module interface, external integration, or a combination. Name producers, consumers, owners, source of truth, and responsibilities.
2. Extract the domain model: entities, fields, relationships, identifiers, state transitions, invariants, optional data, derived data, cardinality, lifecycle, retention, and archival rules. Separate domain facts from implementation convenience.
3. Define the contract shape: tables, documents, endpoint paths, methods, events, schemas, parameters, headers, payloads, response bodies, function signatures, or examples as appropriate. Keep names consistent, explicit, and stable.
4. Specify validation and constraints: required fields, optional fields, nullability, allowed values, formats, uniqueness, references, lengths, enums, temporal rules, cross-field rules, and deprecated fields.
5. Model reads and writes. Confirm the contract supports expected create, read, update, delete, search, listing, filtering, sorting, pagination, aggregation, reporting, consistency, and data-freshness needs without leaking unrelated implementation details.
6. Define failure behavior: error structures, status codes or categories, validation details, retry guidance, timeout expectations, idempotency, conflict handling, deduplication, ordering guarantees, partial success, and rate-limit behavior.
7. Address compatibility and evolution: versioning, backward compatibility, tolerant readers, default values, migration needs, deprecation paths, and how new fields or enum values should be handled.
8. Flag cross-cutting concerns that affect the contract, such as security-sensitive fields, privacy constraints, payload size, latency-sensitive access patterns, observability needs, or contract-test needs. Do not expand into full security, performance, testing, deployment, or documentation work unless the user changes the task.
9. Produce a build-ready specification in the smallest useful format: schema, field table, API contract, endpoint list, event definition, ERD-style summary, migration notes, or review findings. Map material contract decisions to known requirement IDs when stable IDs already exist.

## Output Shape

Prefer the smallest useful output:

- Data model or schema proposal with entities, fields, relationships, constraints, and ownership notes
- API or interface contract with operations, inputs, outputs, validation, errors, and compatibility rules
- Request/response, event, or message examples when they clarify the contract
- Integration boundary summary with producers, consumers, source of truth, and data flow
- Migration, versioning, or deprecation notes for evolving existing contracts safely
- Review findings grouped by correctness, usability, compatibility, and maintainability
- Assumptions, risks, tradeoffs, and open questions that must be resolved before implementation
- Contract-owned traceability notes when stable requirement IDs exist

## Quality Bar

- The contract maps back to stated requirements or known architecture boundaries.
- Boundaries, owners, producers, consumers, and source of truth are clear before detailed design proceeds.
- Entities, fields, endpoints, messages, relationships, identifiers, timestamps, states, enums, and references have precise semantics.
- Required, optional, nullable, derived, deprecated, and sensitive fields are distinguishable.
- Read/write/query patterns are supported without unnecessary coupling, overfetching, unbounded payloads, or ambiguous data ownership.
- Error handling, validation, conflicts, retries, partial failures, idempotency, and rate limits are predictable for humans and calling systems.
- Versioning, migration, and compatibility rules are explicit enough to prevent accidental breaking changes.
- Public contracts do not copy private implementation details unless that coupling is intentional and justified.
- Framework-specific syntax is used only when the task requires that framework.
- The output is concrete enough for implementation without drifting into code, test planning, deployment, full security review, performance engineering, or exhaustive reference material.
