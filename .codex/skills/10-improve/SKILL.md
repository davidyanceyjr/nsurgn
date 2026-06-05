---

name: 10-improve
description: Use when the user wants to improve, optimize, tune, profile, benchmark, refactor, reduce technical debt, improve maintainability, or evaluate performance and scalability. This skill owns performance-focused testing and refactoring-centered work. Do not use for functional testing, incidental implementation refactors, review-only cleanup, deployment, or incident response.
---

# Performance and Maintainability

## Purpose

This skill helps improve software performance, scalability, and long-term maintainability without changing intended behavior. Use it to identify bottlenecks, validate performance claims, guide safe refactoring, reduce technical debt, and make systems easier to understand, change, and operate.

This skill is the primary owner when performance, refactoring, technical debt reduction, or maintainability improvement is the main objective. It does not own incidental refactors needed to implement a feature or cleanup limited to making an active change reviewable.

## When to use

* Use when the task asks to make code faster, lighter, more scalable, or more resource-efficient.
* Use when profiling CPU, memory, I/O, database access, network calls, latency, throughput, startup time, or build time.
* Use when reviewing or planning refactors that improve structure, readability, modularity, or change safety.
* Use when reducing technical debt, duplication, complexity, fragile dependencies, or hard-to-maintain code paths.
* Use when refactoring or maintainability improvement is the main deliverable, even if production code changes are required.
* Use when validating whether a system can handle expected load, growth, data volume, or concurrency.
* Use when designing, implementing, running, or analyzing performance tests, load tests, benchmarks, or scalability tests.
* Use when performance regressions, inefficient algorithms, excessive queries, memory leaks, or slow workflows are central to the task.

## When not to use

* Do not use when the user is asking for ordinary feature implementation; use `04-build/SKILL.md`.
* Do not use when the main task is functional test planning, regression suites, correctness validation, or bug verification; use `05-test/SKILL.md`.
* Do not use when the main task is production incident response, alert triage, log analysis, or reliability diagnostics; use `09-operate/SKILL.md`.
* Do not use when the main task is system architecture unless performance or maintainability tradeoffs are central; use `02-design/SKILL.md`.
* Do not use when the main task is CI/CD, deployment, cloud configuration, containers, or rollback; use `11-release/SKILL.md`.
* Do not use for security hardening unless performance or maintainability is the main concern; use `08-secure/SKILL.md`.
* Do not use for incidental refactoring required to complete feature or bug implementation; use `04-build/SKILL.md`.
* Do not use for cleanup limited to review readiness, formatting, linting, or static-analysis findings; use `07-review/SKILL.md`.

## Inputs to look for

* Current behavior, intended behavior, and constraints that must not change.
* Performance goal, service-level target, budget, or pain point.
* Baseline measurements, benchmark results, traces, profiles, logs, or reproducible examples.
* Relevant code paths, data size, workload shape, traffic pattern, concurrency level, and environment.
* Known bottlenecks, regressions, hotspots, slow queries, memory growth, or resource limits.
* Maintainability concerns such as duplication, coupling, complexity, unclear ownership, or fragile abstractions.
* Risk tolerance, compatibility requirements, rollout constraints, and acceptable tradeoffs.

## Procedure

1. **Clarify the objective.** Determine whether the task is about performance, scalability, maintainability, or a combination. Separate measurable goals from vague goals such as “make it better” or “clean this up.”

2. **Establish a baseline.** Prefer evidence over intuition. Design, implement, and execute the smallest representative performance test, load test, benchmark, or scalability test when no useful baseline exists. Record workload, environment, concurrency, duration, and relevant measurements.

3. **Identify the limiting factor.** Locate the likely bottleneck or maintainability constraint. Consider algorithmic complexity, database access patterns, serialization, network calls, locking, memory allocation, caching, batching, build configuration, dependency boundaries, and code structure.

4. **Choose the smallest safe intervention.** Prefer targeted changes with clear benefit and limited blast radius. Avoid broad rewrites unless the current design prevents meaningful improvement or carries unacceptable maintenance cost.

5. **Preserve behavior.** Keep public contracts, data formats, side effects, error handling, and compatibility stable unless the user explicitly asks for a breaking change. Note any behavior changes clearly.

6. **Improve structure deliberately.** For refactoring, reduce duplication, isolate responsibilities, simplify control flow, name concepts clearly, remove dead code, and make dependencies explicit. Avoid abstractions that do not yet pay for themselves.

7. **Validate and analyze the result.** Compare before/after measurements or structural improvements. For performance work, analyze latency, throughput, memory, CPU, query count, saturation, errors, or other relevant deltas and explain whether the target was met. For maintainability work, show simpler ownership, reduced complexity, clearer interfaces, or safer extension points.

8. **Document tradeoffs.** State what improved, what may worsen, what assumptions were made, and what follow-up work remains. Include risks such as cache invalidation, higher memory use, reduced readability, migration cost, or operational complexity.

## Expected outputs

* A focused performance or maintainability diagnosis.
* A prioritized list of bottlenecks, risks, or debt items.
* A proposed optimization, refactor plan, or safe implementation patch.
* Before/after reasoning using measurements where available.
* Performance-test, load-test, benchmark, or scalability-test design, implementation, execution results, and analysis when performance validation is central.
* Complexity, resource, scalability, or maintainability tradeoff notes.
* Validation steps such as benchmarks, profiling commands, regression checks, or review checklist.
* Clear separation between immediate changes and optional future improvements.

## Quality checks

* The recommendation is tied to a measurable problem or explicit maintainability concern.
* The proposed change preserves intended behavior unless a behavior change is requested.
* The solution targets the actual bottleneck instead of guessing from style preferences.
* The work avoids unnecessary rewrites, speculative abstractions, and premature optimization.
* Performance claims include baseline and comparison data when possible.
* Refactoring improves readability, cohesion, coupling, testability, or change safety.
* Risks and tradeoffs are stated plainly.
* Related lifecycle work is deferred to the appropriate skill instead of duplicated here.

## Anti-patterns

* Avoid optimizing code without a baseline, profile, benchmark, or clear reasoning.
* Avoid broad rewrites when a narrow fix would address the bottleneck.
* Avoid treating style cleanup as maintainability improvement unless it reduces real friction.
* Avoid adding caching, concurrency, batching, or async behavior without considering correctness and failure modes.
* Avoid hiding complexity behind premature abstractions.
* Avoid improving one metric while silently harming correctness, debuggability, security, or operability.
* Avoid framework-specific tuning manuals unless the user’s task requires a specific tool or runtime.
* Avoid mixing performance work with unrelated feature changes.

## Related skills

* `04-build/SKILL.md` — use only when production code must be written or modified beyond refactoring or tuning.
* `07-review/SKILL.md` — use only when cleanup is limited to review readiness, formatting, linting, static analysis, or source-control workflow.
* `05-test/SKILL.md` — use only when functional tests, regression suites, correctness validation, or bug verification are a major part of the task.
* `02-design/SKILL.md` — use only when performance or maintainability requires changing major system boundaries or architecture.
* `03-contract/SKILL.md` — use only when data models, API contracts, schemas, or integration boundaries must change.
* `09-operate/SKILL.md` — use only when diagnosing production reliability issues, alerts, incidents, logs, or runtime failures.
* `11-release/SKILL.md` — use only when deployment, infrastructure, CI/CD, containers, or rollout mechanics are central.
* `08-secure/SKILL.md` — use only when optimization or refactoring affects authentication, authorization, secrets, permissions, or vulnerability risk.
* `06-document/SKILL.md` — use only when the main deliverable is documentation such as performance notes, refactor rationale, or maintenance guidance.
