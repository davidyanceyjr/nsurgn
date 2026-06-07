---
name: 01-understand
description: Use when the user wants to understand, clarify, explore, scope, define, or make sense of a software problem, user need, workflow, requirement, constraint, feasibility concern, acceptance criterion, or project scope. Do not use for architecture decisions, API/schema design, implementation, testing strategy, or deployment planning unless understanding the problem is the main task.
---

# Discovery and Requirements

Use this skill to turn unclear software needs into a compact, actionable problem definition. Stop at understanding: define the problem, outcomes, scope, actors, requirements, assumptions, risks, and acceptance criteria well enough for later design, contract, build, test, or documentation work.

## Use When

- Requirements, workflows, business rules, edge cases, or success criteria are unclear.
- The user asks to clarify, scope, audit ambiguity, define acceptance criteria, or prepare requirements for downstream work.
- Feasibility needs a high-level check before architecture or implementation.

## Avoid When

- The primary task is architecture, API/schema design, implementation, testing strategy, security review, deployment, incident response, or documentation polish.
- The user has already provided stable requirements and is asking for downstream execution.

## Procedure

1. Restate the problem and desired outcome in plain terms.
2. Identify actors, systems, workflow boundaries, in-scope items, out-of-scope items, and unresolved items.
3. Capture requirements as behavior and constraints, not implementation guesses. Use stable IDs such as `REQ-01` and `AC-01` when tracking multiple items helps.
4. Map the workflow only as far as needed: trigger, inputs, decisions, outputs, handoffs, permissions, state changes, and failure cases.
5. Expose assumptions, dependencies, risks, and missing decisions. Ask only blocking questions; otherwise state reasonable assumptions and continue.
6. Write concise, observable acceptance criteria using Given/When/Then or equivalent pass/fail bullets.
7. Hand off only understanding-owned facts. Suggest the next skill only when the request clearly moves into that owner’s domain.

## Output Shape

Prefer the smallest useful output:

- Problem statement and desired outcome
- Scope, actors, and boundaries
- Requirements and key business rules
- Workflow or decision outline, when useful
- Acceptance criteria
- Assumptions, risks, dependencies, and open questions

When the user asks to be grilled or ambiguity-audited, output only the blocking questions, assumptions, and decision points grouped by topic.

## Quality Bar

- Requirements are testable and avoid vague claims like “fast,” “easy,” or “support everything” unless clarified.
- Scope boundaries prevent accidental feature creep.
- User-facing criteria include material platform, accessibility, and compatibility constraints when relevant.
- Known ambiguity is visible instead of hidden inside confident wording.
- Do not drift into detailed architecture, contracts, code, or test strategy unless the user explicitly changes the task.
