---

name: 09-operate
description: Use when the user wants to operate, diagnose, monitor, alert, troubleshoot, investigate incidents, improve logs, metrics, dashboards, reliability checks, operational diagnostics, or runbook procedures and mitigations. Do not use for CI/CD construction, feature implementation, documentation-only runbook editing, or performance tuning unless reliability diagnosis is the main task.
---

# Observability and Reliability

## Purpose

Use this skill to understand, diagnose, and improve how a system behaves in real or production-like environments. It focuses on visibility, reliability, incident handling, operational signals, failure analysis, safe recovery guidance, and evidence-driven mitigation.

Use it to reason from symptoms to causes, design monitoring coverage, improve alert quality, create diagnostic workflows, or define the diagnostic, mitigation, escalation, and verification content of runbooks. Keep the work operational. Route runbook formatting, organization, editing, and durable publication to `06-document/SKILL.md`.

## Use when

* Working with logs, metrics, traces, dashboards, alerts, SLOs, SLIs, error budgets, health checks, or production diagnostics.
* Investigating incidents, outages, degraded service, recurring failures, flaky production behavior, unknown runtime errors, or unhealthy dependencies.
* Defining or improving operational procedures, diagnostic checks, mitigations, escalation paths, runbook verification steps, or release monitoring coverage.
* Analyzing symptoms such as high error rates, timeouts, queue buildup, failed jobs, saturation, restarts, dependency failures, or traffic anomalies.

## Route elsewhere when

* CI/CD pipelines, deployment automation, infrastructure provisioning, rollback mechanics, containers, cloud operations, or environment configuration are primary: use `11-release/SKILL.md`.
* Application feature work, production code changes, or refactoring are primary: use `04-build/SKILL.md`.
* Performance tuning, profiling, capacity optimization, scalability validation, or technical debt reduction is primary unless framed as reliability diagnosis: use `10-improve/SKILL.md`.
* Test planning, regression testing, failure-mode tests, or automated validation are primary unless used to verify reliability behavior: use `05-test/SKILL.md`.
* Security incidents, threat analysis, vulnerabilities, abuse, secrets, authentication, authorization, or security controls are primary unless reliability impact is the focus: use `08-secure/SKILL.md`.
* Runbook procedures are already defined and the task is formatting, organizing, editing, or durable publication: use `06-document/SKILL.md`.

## Inputs to inspect

* Reported symptoms, error messages, timestamps, affected users, affected services, scope, impact, and whether the issue is ongoing.
* Logs, metrics, traces, alerts, dashboards, health checks, deployment history, recent configuration changes, and environment details.
* Service dependencies, data stores, queues, third-party APIs, infrastructure components, network boundaries, regions, clusters, versions, containers, hosts, and cloud services.
* Existing SLOs, SLIs, alert rules, escalation policies, runbooks, incident notes, monitoring gaps, and prior mitigations.
* Constraints such as acceptable downtime, data loss tolerance, compliance requirements, escalation process, on-call process, and rollback limits.

## Procedure

1. **Clarify objective.** Determine whether the task is diagnosis, monitoring design, alert improvement, incident response, reliability validation, or technical runbook content.

2. **Establish impact and timeline.** Identify what is broken, who is affected, when it started, whether it is ongoing, and whether it correlates with deployments, traffic changes, dependency failures, configuration changes, or infrastructure events.

3. **Separate symptoms from causes.** Treat alerts, errors, and user reports as signals, not conclusions. Do not assert root cause until evidence supports it.

4. **Inspect signals systematically.** Check logs for error patterns, metrics for rate, saturation, latency, traffic, and dependency changes, traces for slow or failing spans, and health checks for service status. Compare failing and healthy periods.

5. **Map the failure path.** Trace the request, job, event, or data flow through relevant components and identify where behavior first diverges from expected operation.

6. **Prioritize hypotheses.** Rank likely causes by evidence, blast radius, timing, user impact, and reversibility. Prefer explanations that match both symptoms and timeline.

7. **Recommend safe actions.** Suggest containment, rollback, restart, failover, traffic shift, dependency isolation, feature-flag changes, queue draining, or configuration correction only when appropriate. State risk and verification steps.

8. **Define recovery verification.** Name the signal that proves recovery, such as lower error rate, normalized latency, declining queue depth, passing health checks, restored user workflow, or stable dependency behavior.

9. **Improve observability and guidance.** Identify missing logs, metrics, traces, labels, correlation IDs, dashboard panels, alert thresholds, escalation paths, or runbook procedures that would speed future diagnosis and mitigation.

10. **Capture follow-up work.** Separate immediate remediation from long-term reliability improvements such as better alerting, dependency isolation, retry policy changes, capacity safeguards, or failure-mode tests.

## Expected outputs

* Incident diagnosis summaries with impact, timeline, evidence, likely cause, confidence, and uncertainty.
* Troubleshooting plans with ordered checks, commands or queries when useful, expected observations, and next evidence needed.
* Monitoring plans with SLIs, metrics, logs, traces, dashboards, labels, dimensions, and alert conditions.
* Alert reviews identifying noisy, missing, duplicate, low-signal, or user-impact-disconnected alerts.
* Operational runbook content with diagnostics, escalation, mitigation, verification, and rollback guidance.
* Post-incident follow-up lists separating immediate fixes from preventive improvements.

## Quality standard

* Distinguish observed facts, hypotheses, unknowns, and recommended actions.
* Ensure the diagnosis fits the reported timeline, symptoms, impact, and available signals.
* Do not jump from an alert, log line, or user report directly to root cause without evidence.
* Specify what to inspect in logs, metrics, traces, dashboards, and health checks; avoid vague “check the logs” guidance.
* Tie alerting recommendations to user impact, service health, SLOs, or actionable failure modes.
* Include enough metric context: rate, errors, duration, saturation, traffic volume, dependency status, and relevant labels or dimensions.
* Keep runbook steps safe, ordered, reversible where possible, and paired with verification.
* Call out uncertainty, incomplete evidence, risks, and the next data needed.
* Avoid recommending restarts, rollbacks, failovers, or broad redesign without explaining risk, scope, and recovery verification.
* Keep follow-up work scoped and avoid drifting into unrelated architecture, testing, deployment, or implementation detail.
