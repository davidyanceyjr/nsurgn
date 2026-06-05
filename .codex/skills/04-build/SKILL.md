---

name: 04-build
description: Use when the user wants to build, implement, fix, code, debug, modify, or explain production code, including ordinary bug fixes and incidental refactoring required to complete implementation work. Do not use when Git workflow, formal test strategy, deployment, incident response, vulnerability remediation, security review, or refactoring is the primary objective.
---

# Implementation Engineering

## Purpose

Guide scoped production code creation and modification from requirements, designs, bug reports, or implementation tasks. Own implementation-level control flow, data structures, module organization, error handling, dependency use, and development-time debugging. Defer architecture, formal testing, deployment, security-centered work, and refactoring-centered work.

## When to use

* Use when asked to write, modify, debug, or explain application code.
* Use when implementing a feature, bug fix, CLI command, service method, UI behavior, library function, script, parser, adapter, or integration logic.
* Use when choosing implementation-level patterns, data structures, abstractions, or module boundaries inside an existing design.
* Use when diagnosing development-time errors, compiler failures, runtime exceptions, failing local builds, or incorrect behavior in code.
* Use when making incidental readability, structure, type-safety, dependency, or error-handling improvements needed to complete implementation work.

## When not to use

* Do not use when the main task is requirements clarification, user workflow analysis, or acceptance criteria definition.
* Do not use when the main task is high-level architecture, scalability planning, schema design, API contracts, or interface specification.
* Do not use when the main task is Git branching, pull request review process, commit hygiene, or static analysis policy.
* Do not use when the main task is test planning, test suite design, regression strategy, or bug verification.
* Do not use when the main task is formal threat modeling, vulnerability assessment, or security-driven vulnerability patching; use `08-secure/SKILL.md`.
* Do not use when the main task is CI/CD, deployment, cloud configuration, container orchestration, release planning, or rollback.
* Do not use when the main task is production incident response, monitoring, log analysis, or operational diagnostics.
* Do not use when refactoring, technical debt reduction, or maintainability improvement is the main task; use `10-improve/SKILL.md`.

## Inputs to look for

* User goal, bug report, feature request, or expected behavior.
* Existing code or a minimal repository, plus the target runtime, framework, language, and package manager.
* Known requirement or acceptance-criterion IDs, specification, architecture decisions, and contracts.
* Constraints such as compatibility, performance needs, style conventions, supported platforms, or dependency limits.
* Relevant errors, stack traces, failing commands, or reproduction steps.
* Established interfaces and files that may or may not change.
* Existing tests, lint rules, type checks, build commands, and local validation commands.
* Security-sensitive areas such as authentication, authorization, input handling, secrets, serialization, file access, or network calls.
* For user-facing changes, established interface patterns and applicable input, viewport, browser, platform, accessibility, or compatibility constraints.

## Procedure

1. **Clarify the implementation target.** Identify the concrete behavior to add, change, or fix. Distinguish required behavior from assumptions. If details are missing, make minimal safe assumptions and state them briefly. Update only the changed-files/components and implementation-status fields of available compact traceability, marking known IDs `implemented`, `partial`, `blocked`, `deferred`, or `out of scope`.

2. **Inspect or establish the project shape.** For an existing project, determine its language, framework, conventions, module boundaries, naming patterns, dependency style, and error-handling approach. For an empty or minimal repository, first confirm the specification, constraints, target runtime/platform, and known architecture or contracts. If the stack is not mandated, choose the simplest suitable option and state the decision briefly.

3. **Choose the smallest viable change or bootstrap.** Avoid redesigning unrelated areas. For greenfield work, establish only a minimal runnable structure, dependency manifest, entry point, essential local configuration, and conventional source layout; verify it before expanding. Defer architecture, missing test harnesses, baseline quality gates, CI/CD, and platform setup to their owning skills.

4. **Design implementation-level behavior.** Decide control flow, data structures, function boundaries, validation, error handling, state changes, and dependency use. Use patterns only when they reduce complexity or match existing conventions. Keep public interfaces stable unless change is required.

5. **Implement incrementally.** Write or modify code coherently. Preserve existing behavior unless the task changes it. Keep changes readable, typed where applicable, and consistent with project style.

6. **Handle edge cases deliberately.** Consider invalid or missing input, empty collections, concurrency, retries, timeouts, partial failure, cleanup, and backward compatibility when relevant.

7. **Address user-facing basics when applicable.** Follow established project patterns and proportionately consider semantic controls, keyboard operation, focus behavior, labels, readable error or status feedback, responsive behavior, and supported browser or platform compatibility. Do not turn backend-only work into a UX exercise.

8. **Debug from evidence.** For errors or broken behavior, trace from observed symptoms to likely causes. Use stack traces, failing lines, logs, reproduction steps, and invariants before proposing changes.

9. **Validate locally where possible.** Run the narrowest useful build, run, type check, lint, focused test, or reproduction command that is available. Report actual results. Do not claim formal functional verification owned by `05-test/SKILL.md`.

10. **Report implementation status.** Label the result `CODE COMPLETE`, `PARTIALLY COMPLETE`, or `BLOCKED` with concise evidence. Claim `CODE COMPLETE` only when every in-scope item is implemented and required code, configuration, migrations, and generated artifacts are internally consistent. Any blocked or deferred in-scope implementation requires `PARTIALLY COMPLETE` or `BLOCKED`; explicitly marked out-of-scope items do not prevent completion. A plan-only output cannot receive `CODE COMPLETE`. State assumptions, checks attempted, unverified behavior, blockers, and follow-up work without treating code complete as functionally verified, merge ready, release ready, or production ready.

## Expected outputs

* Production code, patch, diff, or file-level implementation plan.
* Debugging diagnosis with likely root cause and concrete fix.
* Notes on assumptions, edge cases handled, and compatibility concerns.
* Implementation-owned compact traceability updates mapping known IDs to changed files or code areas and implementation status.
* `CODE COMPLETE`, `PARTIALLY COMPLETE`, or `BLOCKED` status with concise evidence and explicit gaps.
* Clear statement of any incomplete work, unverified behavior, or required user decision.

## Quality checks

* The change directly addresses the requested behavior or bug.
* The solution fits project conventions and avoids unnecessary abstractions.
* Public interfaces, data formats, and side effects are preserved unless intentionally changed.
* Errors match the surrounding application style; code remains readable and scoped.
* Edge cases relevant to the change have been considered.
* Dependencies are justified and not added casually.
* Security-sensitive inputs are treated carefully, even when formal security review is out of scope.
* Validation steps are accurate and do not overstate what was executed.
* Every in-scope requirement is accounted for before `CODE COMPLETE` is reported.
* Blocked or deferred in-scope work prevents `CODE COMPLETE`, and plan-only output is never labeled code complete.
* Code-complete status is an implementation claim only and does not imply passed tests, merge readiness, release readiness, security, performance, or production readiness.
* The response distinguishes facts from assumptions.

## Anti-patterns

* Avoid rewriting large areas of code when a targeted fix is enough.
* Avoid inventing architecture, APIs, schemas, or requirements that belong to other skills.
* Avoid adding dependencies for trivial logic.
* Avoid abstractions that make straightforward code harder to follow.
* Avoid hiding uncertainty about uninspected code or unrun checks.
* Avoid changing behavior outside the task without calling it out.
* Avoid treating secure coding basics as a substitute for formal security engineering when security is central.
* Avoid speculative greenfield infrastructure or absorbing architecture, testing policy, quality-gate policy, deployment, or environment operations.
* Avoid claiming verification evidence owned by `05-test/SKILL.md` or using code complete as a broader readiness claim.

## Related skills

* `01-understand/SKILL.md` — use only when the requested behavior, constraints, or acceptance criteria are unclear.
* `02-design/SKILL.md` — use only when implementation requires changing high-level system structure or component boundaries.
* `03-contract/SKILL.md` — use only when database models, API contracts, schemas, or integration interfaces must be designed or changed.
* `07-review/SKILL.md` — use only when the main task involves Git workflow, pull request review, static analysis, or code hygiene process.
* `05-test/SKILL.md` — use only when creating, planning, or validating tests is a primary task.
* `08-secure/SKILL.md` — use when vulnerability remediation, authentication, authorization, secrets, threat modeling, or secure design are central.
* `11-release/SKILL.md` — use only when code changes require CI/CD, deployment, environment, container, or rollback work.
* `09-operate/SKILL.md` — use only when runtime diagnostics, logs, alerts, incidents, or reliability operations are central.
* `10-improve/SKILL.md` — use when profiling, tuning, refactoring, scalability validation, technical debt reduction, or maintainability improvement is the main goal.
* `06-document/SKILL.md` — use only when durable documentation is the main requested deliverable; explain code here when needed to perform implementation work.
