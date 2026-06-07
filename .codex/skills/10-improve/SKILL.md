---

name: 10-improve
description: Use when the user wants to improve, optimize, tune, profile, benchmark, refactor, reduce technical debt, improve maintainability, or evaluate performance and scalability. This skill owns performance-focused testing and refactoring-centered work. Do not use for functional testing, incidental implementation refactors, review-only cleanup, deployment, or incident response.
---

# Performance and Maintainability

## Purpose

Use this skill to improve performance, scalability, or long-term maintainability without changing intended behavior. It owns optimization, profiling, benchmarking, refactoring, technical debt reduction, and performance-focused validation when those are the main objective.

Do not use it for incidental cleanup inside ordinary feature work, review-only formatting, general functional testing, deployment, incident response, or security hardening unless performance or maintainability is the central concern.

## When to use

* Make code faster, lighter, more scalable, or more resource-efficient.
* Profile, benchmark, or performance-test CPU, memory, I/O, database access, network calls, latency, throughput, startup time, or build time.
* Plan or perform refactors that improve structure, readability, cohesion, coupling, testability, or change safety.
* Reduce duplication, complexity, fragile dependencies, unclear ownership, or hard-to-maintain code paths.
* Validate capacity, concurrency, growth, load, regressions, inefficient algorithms, excessive queries, memory growth, or slow workflows.

## Route elsewhere

* `04-build/SKILL.md` — ordinary feature work or bug fixes where refactoring is incidental.
* `05-test/SKILL.md` — functional test planning, regression suites, correctness validation, or bug verification.
* `07-review/SKILL.md` — review readiness, formatting, linting, static analysis, or source-control hygiene.
* `09-operate/SKILL.md` — production incidents, alerts, logs, or reliability diagnostics.
* `11-release/SKILL.md` — deployment, CI/CD, containers, infrastructure, rollout, or rollback.
* `08-secure/SKILL.md` — security hardening unless optimization or refactoring is the main concern.
* `02-design/SKILL.md` or `03-contract/SKILL.md` — major architecture, API, schema, or integration-boundary changes when those are the primary task.
* `06-document/SKILL.md` — documentation is the primary deliverable.

## Inputs to look for

* Current behavior, intended behavior, compatibility constraints, and risk tolerance.
* Performance goal, service-level target, resource budget, or maintainability pain point.
* Baseline measurements, traces, profiles, logs, benchmarks, or reproducible examples.
* Relevant code paths, data size, workload shape, traffic pattern, concurrency, and environment.
* Known bottlenecks, regressions, slow queries, memory growth, coupling, duplication, or fragile abstractions.

## Procedure

1. **Clarify the objective.** Separate performance, scalability, and maintainability goals. Turn vague requests such as "make it better" into concrete outcomes where possible.

2. **Establish a baseline.** Prefer evidence over intuition. When no useful baseline exists, design and run the smallest representative benchmark, profile, load test, or structural assessment. Record workload, environment, duration, concurrency, and measurements.

3. **Find the limiting factor.** Look for the actual bottleneck or maintenance constraint: algorithmic complexity, query patterns, serialization, network calls, locking, allocation, caching, batching, build configuration, dependency boundaries, or code structure.

4. **Choose the smallest safe intervention.** Prefer targeted changes with clear benefit and limited blast radius. Avoid broad rewrites unless the current design blocks meaningful improvement or carries unacceptable maintenance cost.

5. **Preserve behavior.** Keep public contracts, data formats, side effects, error handling, and compatibility stable unless the user explicitly asks for a breaking change. Call out any behavior change clearly.

6. **Improve structure deliberately.** Reduce duplication, isolate responsibilities, simplify control flow, name concepts clearly, remove dead code, and make dependencies explicit. Add abstractions only when they remove real complexity.

7. **Validate the result.** Compare before and after. For performance work, analyze latency, throughput, memory, CPU, query count, saturation, errors, or other relevant deltas. For maintainability work, show simpler ownership, lower complexity, clearer interfaces, or safer extension points.

8. **Document tradeoffs.** State what improved, what may worsen, assumptions made, residual risks, and follow-up work. Consider cache invalidation, memory use, readability, migration cost, debuggability, security, and operational complexity.

## Expected outputs

* A focused performance or maintainability diagnosis.
* A prioritized list of bottlenecks, risks, or debt items.
* A proposed optimization, refactor plan, or behavior-preserving patch.
* Before/after reasoning with measurements when performance claims are made.
* Validation steps such as benchmarks, profiles, regression checks, or review checklist.
* Clear tradeoffs and separation between immediate work and optional follow-up.

## Quality bar

* Recommendations tie to evidence, a measurable problem, or a specific maintainability concern.
* Intended behavior is preserved unless the user requests otherwise.
* The work targets the real bottleneck or debt source instead of style preferences.
* The change avoids unnecessary rewrites, speculative abstractions, and premature optimization.
* Lifecycle work that belongs to another skill is routed there instead of duplicated here.
