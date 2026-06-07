---

name: 11-release
description: Use when the user wants to release, deploy, ship, roll out, roll back, fix CI/CD, create release automation, plan deployment workflows, configure environments, containers, cloud/platform settings, migration rollout, or rollback plans. Do not use for logical system architecture, ordinary application code, incident response, log analysis, or long-term observability design unless release or deployment operations are the main task.
---

# Release and Platform Operations

## Purpose

This skill guides release, deployment, and platform operations work across the software delivery lifecycle. Use it to move software safely from source control into target environments, with clear automation, configuration, environment controls, validation steps, and rollback paths.

The goal is not to document every cloud, CI/CD, or container platform. The goal is to define a practical operating process that helps the model reason about how software is built, packaged, deployed, configured, verified, and recovered.

## When to use

* Use when creating or modifying CI/CD pipelines, build workflows, deployment jobs, or release automation.
* Use when defining concrete deployment topology, platform resources, environment placement, traffic routing, or runtime configuration.
* Use when designing deployment strategy, including blue/green, canary, rolling, feature-flagged, or manual-gated releases.
* Use when working with containers, images, registries, infrastructure configuration, secrets injection, environment variables, or runtime platform setup.
* Use when planning release readiness, deployment validation, rollback, hotfix flow, or environment promotion.
* Use when diagnosing a failed deployment, broken pipeline, bad release artifact, misconfigured environment, or platform-level rollout issue.
* Use when writing or reviewing scripts whose primary purpose is building, packaging, releasing, deploying, configuring, verifying, or recovering software.

## When not to use

* Do not use for writing normal application feature code or general-purpose application scripts; use `04-build/SKILL.md`.
* Do not use for Git branching, code review hygiene, or static analysis unless they are part of release gating; use `07-review/SKILL.md`.
* Do not use for test strategy or test implementation unless the tests are deployment gates; use `05-test/SKILL.md`.
* Do not use for logical system architecture, component boundaries, or high-level architectural tradeoffs; use `02-design/SKILL.md`.
* Do not use for production incident response, alert triage, or log investigation after deployment unless the deployment process itself is the focus; use `09-operate/SKILL.md`.
* Do not use for security review unless deployment security controls, secrets, permissions, or supply-chain risks are central; use `08-secure/SKILL.md`.

## Inputs to look for

* Target environments: local, dev, test, staging, production, preview, ephemeral, or disaster recovery.
* Release trigger: push, tag, merge, schedule, manual approval, artifact promotion, or external event.
* Build inputs: source repo, language/runtime, dependency manager, build commands, package format, image build, artifact naming, and versioning.
* Deployment target: VM, container runtime, Kubernetes, serverless, managed PaaS, static hosting, package registry, database, or hybrid platform.
* Concrete topology needs: regions, clusters, networks, routing, replicas, resource placement, and platform dependencies.
* Configuration model: environment variables, config files, secrets, service accounts, feature flags, region settings, and resource limits.
* Required gates: tests, scans, approvals, change windows, migrations, backups, smoke checks, health checks, and monitoring checks.
* Rollback constraints: artifact retention, database migration reversibility, cache/state compatibility, traffic switching, and data-loss risk.
* Operational constraints: downtime tolerance, release frequency, compliance needs, cost limits, team access, and available tooling.

## Procedure

1. **Classify the release task.** Determine whether the work is pipeline creation, deployment design, environment configuration, artifact packaging, release validation, rollback planning, or troubleshooting.

2. **Map the delivery path.** Identify how code becomes a deployable artifact, where artifacts are stored, how they are promoted, and which environment receives them.

3. **Separate build from deploy.** Prefer reproducible artifacts built once and promoted across environments. Avoid rebuilding different artifacts for staging and production unless there is a clear reason.

4. **Define environment boundaries.** Clarify which configuration differs by environment and which settings must remain identical. Keep secrets out of source code and logs.

5. **Add release gates.** Include the minimum useful automated checks before deployment, such as build success, unit/integration tests, schema checks, dependency checks, image checks, or approval gates.

6. **Define topology and rollout strategy.** Translate architectural constraints into concrete platform resources, placement, routing, and runtime configuration, then choose a rollout method based on risk, downtime tolerance, traffic control, state compatibility, and rollback needs.

7. **Handle stateful changes carefully.** Treat database migrations, queues, caches, object stores, and external integrations as release risks. Prefer backward-compatible migrations and phased rollout when possible.

8. **Define verification.** Specify smoke tests, health checks, endpoint checks, synthetic checks, job status checks, or manual validation needed immediately after deployment.

9. **Define rollback or recovery.** State how to revert traffic, artifact version, configuration, migration, or feature flag state. Identify cases where rollback is unsafe and roll-forward is preferred.

10. **Automate bounded operational steps.** Use release or operational scripts for repeatable build, package, deploy, verify, and recovery actions. Keep them deterministic, parameterized, failure-aware, and separate from ordinary application behavior.

11. **Make operations repeatable.** Capture commands, scripts, pipeline stages, required approvals, environment variables, and failure handling in a form that can be reused.

12. **Assess release readiness when requested.** Conclude `RELEASE READY`, `NOT RELEASE READY`, or `BLOCKED`. Cite the target revision or artifact, required gate results, deployment and rollback readiness, unresolved risks, and blockers. Release readiness does not imply post-release production health, which requires operational evidence owned by `09-operate/SKILL.md`.

## Expected outputs

* A CI/CD workflow, concrete deployment topology, deployment plan, release checklist, platform configuration, or troubleshooting plan.
* Clear build, package, deploy, verify, and rollback steps.
* Environment-specific configuration guidance without leaking secrets.
* Release gate recommendations with rationale.
* Risk notes for migrations, permissions, secrets, dependencies, stateful services, or external integrations.
* Concrete commands or configuration snippets when the task asks for implementation-level help.
* Focused release or operational scripts when repeatable delivery actions require them.
* A concise explanation of tradeoffs when choosing among deployment strategies.
* An evidence-based `RELEASE READY`, `NOT RELEASE READY`, or `BLOCKED` conclusion when readiness is assessed.

## Quality checks

* The same artifact can be traced from source revision to deployed version.
* Required environment variables, secrets, permissions, and platform assumptions are explicit.
* Deployment steps are ordered, repeatable, and safe to automate.
* Operational scripts are scoped to delivery tasks, fail clearly, avoid embedded secrets, and do not absorb ordinary application logic.
* Failure paths are covered, including failed build, failed deployment, failed verification, and partial rollout.
* Rollback or roll-forward behavior is realistic for both stateless and stateful changes.
* The plan avoids exposing secrets in source code, logs, command history, or build output.
* Release gates are useful but not bloated with unrelated checks.
* Platform-specific guidance is limited to what the task requires.
* Concrete topology and rollout choices satisfy the system's stated architectural constraints.
* Release-readiness evidence identifies the target revision or artifact, gates, deployment and rollback readiness, risks, and blockers without claiming post-release health.

## Anti-patterns

* Avoid mixing build-time and deploy-time configuration without a clear reason.
* Avoid deploying unversioned artifacts, mutable tags, or manually patched servers without traceability.
* Avoid assuming rollback is safe when database or data-format changes are involved.
* Avoid treating staging and production as equivalent when dependencies, scale, permissions, or data differ.
* Avoid adding complex release machinery when a simpler pipeline satisfies the risk profile.
* Avoid hiding manual steps inside vague instructions such as “deploy normally” or “verify it works.”
* Avoid duplicating security, testing, observability, or implementation guidance beyond what is needed for release operations.

## Related skills

* `02-design/SKILL.md` — use only when defining logical system structure, component boundaries, or deployment constraints rather than concrete platform topology.
* `04-build/SKILL.md` — use only when the main task is application code or build-system code changes.
* `07-review/SKILL.md` — use only when branch policy, review gates, version tagging, or static analysis ownership is central.
* `05-test/SKILL.md` — use only when designing or implementing test suites, not merely adding tests as release gates.
* `08-secure/SKILL.md` — use only when secrets, permissions, supply-chain risk, authentication, authorization, or deployment security controls are central.
* `09-operate/SKILL.md` — use only when production monitoring, alerting, incident response, or runtime diagnostics are the main task.
* `10-improve/SKILL.md` — use only when deployment work is driven by performance validation, scaling limits, or maintainability refactoring.
* `06-document/SKILL.md` — use only when producing release notes, runbooks, deployment docs, or operational documentation is the main deliverable.
