---

name: 05-test
description: Use when the user wants to test, validate, verify, regress, debug tests, create tests, review coverage, improve tests, automate checks, manually validate behavior, or verify bugs. Do not use for deployment, observability, security testing, or performance testing unless general functional validation is the main task.
---

# Testing and Validation

## Purpose

This skill guides test planning, test creation, test review, and validation work across the software development lifecycle. Use it to verify that software behaves as intended, prevent regressions, reproduce bugs, and confirm fixes.

The goal is practical confidence, not exhaustive theoretical coverage. Focus on the smallest useful test set that validates requirements, important behavior, edge cases, integrations, and known risks.

## When to use

* Use when writing or improving unit, integration, end-to-end, regression, smoke, or acceptance tests.
* Use when creating a test plan, validation checklist, QA checklist, or manual test procedure.
* Use when reproducing, isolating, documenting, or verifying a bug.
* Use when reviewing existing tests for usefulness, coverage, brittleness, or maintainability.
* Use when deciding what should be tested before merging, releasing, or accepting a change.
* Use when converting requirements or acceptance criteria into concrete validation steps.

## When not to use

* Do not use when the main task is writing production feature code; use `04-build/SKILL.md`.
* Do not use when the main task is security testing, threat modeling, auth review, or vulnerability validation; use `08-secure/SKILL.md`.
* Do not use when the main task is load testing, profiling, latency tuning, or scalability validation; use `10-improve/SKILL.md`.
* Do not use when the main task is deployment, CI/CD setup, environment configuration, or rollback validation; use `11-release/SKILL.md`.
* Do not use when the main task is production troubleshooting, incident response, logs, alerts, or diagnostics; use `09-operate/SKILL.md`.
* Do not use only to document tests after the validation work is already settled; use `06-document/SKILL.md`.

## Inputs to look for

* Feature, bug, requirement, user story, or acceptance criteria being validated, including stable identifiers when available.
* Expected behavior, invalid behavior, business rules, and edge cases.
* Existing tests, test framework, fixtures, mocks, test data, and test commands.
* Changed files, affected modules, dependencies, integrations, and data paths.
* Target test level: unit, integration, end-to-end, regression, smoke, manual, or exploratory.
* Runtime environment, configuration, database state, services, external APIs, and permissions.
* Known failure reports, logs, reproduction steps, screenshots, or user impact.
* Constraints such as time, test runtime, flaky tests, missing environments, or unavailable services.
* For user-facing behavior, applicable keyboard flows, focus behavior, labels, status/error feedback, responsive layouts, browsers, devices, and platforms.

## Procedure

1. **Identify the validation target.** Determine what behavior, requirement, bug, or risk needs proof. Separate the intended behavior from implementation details. Retain known requirement and acceptance-criterion IDs and explicitly identify any uncovered items.

2. **Classify the test level.** Choose the cheapest useful level first. Prefer unit tests for isolated logic, integration tests for boundaries, end-to-end tests for critical user workflows, and manual checks only where automation is impractical or not yet worth the cost.

3. **Define expected outcomes.** Write clear pass/fail conditions before designing test cases. Include normal paths, edge cases, error paths, authorization or permission boundaries when functionally relevant, and regression cases for known bugs.

4. **Inspect existing coverage.** Reuse or extend existing tests when they already cover nearby behavior. Avoid duplicating tests that assert the same thing through a slower or more brittle path.

5. **Design focused test cases.** Keep each test centered on one behavior or risk. Use realistic fixtures and minimal setup. Prefer deterministic data over hidden global state, timing assumptions, network dependency, or order dependence. For user-facing work, add proportionate manual or automated checks for applicable keyboard flows, focus, labels, readable status/error feedback, responsive layouts, and supported browser or platform behavior.

6. **Implement or specify tests.** Follow the project’s established framework, naming conventions, fixture patterns, and assertion style. Make failures easy to diagnose by using precise assertions and readable setup.

7. **Validate failure and success.** When practical, confirm the test fails against the broken or previous behavior and passes after the fix. For bug fixes, include the smallest regression test that would have caught the issue.

8. **Run the relevant scope.** Run the narrowest test command first, then broader suites as needed. Record commands used, environment assumptions, failures, skipped tests, and any unverified areas.

9. **Analyze failures.** Distinguish product defects, test defects, data/setup issues, environmental failures, and flakes. Do not mask failures by weakening assertions unless the expected behavior was wrong.

10. **Report results clearly.** Map tests and evidence to known requirement or acceptance-criterion IDs. Mark each as `passed`, `failed`, `blocked`, `skipped`, or `unverified`, identify uncovered requirements explicitly, and conclude `FUNCTIONALLY VERIFIED`, `PARTIALLY VERIFIED`, or `BLOCKED` with concise evidence. Functional verification does not imply merge readiness or release readiness.

## Subagent delegation

Subagents are optional. Use them only when independent validation scenarios, disjoint test levels, test-case review, or failure classification has a concrete coverage or speed advantage. Separate work by test level, requirement ID, component, or environment so tasks do not overlap. Subagents may report evidence only from checks they actually performed and must not repair production code unless separately authorized under `04-build/SKILL.md`.

For each delegation, state the expected advantage and explicitly invoke `05-test/SKILL.md` in a bounded, self-contained prompt with the inputs, permitted test scope, and expected output. Assign disjoint write scopes or make the task read-only; prohibit recursive delegation and unsupported evidence, statuses, or ownership changes. The parent must review and integrate results, resolve contradictions, own consolidated functional-verification status, and close completed agents promptly.

Faster models may enumerate cases or classify clear failures with objective acceptance criteria. Ambiguous failures, complex behavioral or integration conclusions, and final verification synthesis require stronger reasoning or parent completion. Model choice never lowers the evidence or review standard.

## Expected outputs

* Test plan, test matrix, checklist, or validation strategy.
* New or revised automated tests.
* Manual QA steps with clear expected results.
* Bug reproduction steps and minimized test case.
* Bug report artifact containing environment, reproduction steps, expected result, actual result, and supporting evidence.
* Regression test confirming a fix.
* Review notes on coverage gaps, brittle tests, redundant tests, or flaky behavior.
* Test execution summary with commands, results, failures, and remaining risks.
* Validation-owned compact traceability updates with tests, evidence, verification status, and uncovered items.
* An overall `FUNCTIONALLY VERIFIED`, `PARTIALLY VERIFIED`, or `BLOCKED` conclusion when functional verification is requested.

## Quality checks

* Tests map back to requirements, acceptance criteria, changed behavior, or known risks.
* Each important behavior has a clear pass/fail signal.
* Test names describe behavior, not implementation mechanics.
* Assertions are specific enough to diagnose failure.
* Tests are deterministic and do not rely on hidden order, real time, random data, or unavailable services unless explicitly controlled.
* Test data is minimal, readable, and isolated.
* Slow or brittle tests are justified by risk.
* Regression tests would fail for the original bug.
* Manual steps are reproducible by another person.
* Reported results distinguish verified facts from assumptions.
* Every known in-scope identifier has a verification status or is explicitly identified as uncovered.
* Functional-verification conclusions do not imply merge readiness or release readiness.

## Anti-patterns

* Avoid writing tests only to increase coverage numbers without validating meaningful behavior.
* Avoid duplicating the same assertion across unit, integration, and end-to-end tests without a reason.
* Avoid over-mocking until the test no longer validates real behavior.
* Avoid snapshot-heavy tests that obscure the intended assertion.
* Avoid broad end-to-end tests for logic that can be validated with cheaper tests.
* Avoid changing production behavior to satisfy a poorly designed test.
* Avoid weakening assertions to make a test pass without resolving the underlying issue.
* Avoid ignoring flaky tests; classify and address the source of nondeterminism.
* Avoid claiming full validation when important paths, environments, or integrations were not checked.
* Avoid treating a code-complete claim as proof of verification or automatically repairing production code instead of reporting the defect.

## Related skills

* `01-understand/SKILL.md` — use only when requirements, workflows, or acceptance criteria are unclear.
* `04-build/SKILL.md` — use only when production code must be created or changed as part of the test work.
* `08-secure/SKILL.md` — use only when validation centers on threats, vulnerabilities, authentication, authorization, secrets, or abuse cases.
* `10-improve/SKILL.md` — use only when validation centers on load, latency, throughput, profiling, scalability, or refactoring safety.
* `11-release/SKILL.md` — use only when validation depends on CI/CD, deployment environments, release gates, or rollback checks.
* `09-operate/SKILL.md` — use only when validation depends on production diagnostics, incidents, logs, metrics, or alerts.
* `06-document/SKILL.md` — use only when producing formal test documentation, QA records, release notes, or long-lived validation guides.
