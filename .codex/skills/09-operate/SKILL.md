---

name: 09-operate
description: Use when the user wants to operate, diagnose, monitor, alert, troubleshoot, investigate incidents, improve logs, metrics, dashboards, reliability checks, operational diagnostics, or runbook procedures and mitigations. Do not use for CI/CD construction, feature implementation, documentation-only runbook editing, or performance tuning unless reliability diagnosis is the main task.
---

# Observability and Reliability

## Purpose

This skill helps the model understand, diagnose, and improve how a system behaves in real or production-like environments. It focuses on visibility, reliability, incident handling, operational signals, failure analysis, and practical recovery guidance.

Use this skill to reason from symptoms to causes, design monitoring coverage, improve alert quality, create diagnostic workflows, or define the diagnostic, mitigation, escalation, and verification content of runbooks. Keep the work operational and evidence-driven. Defer runbook formatting, organization, editing, and durable publication to `06-document/SKILL.md`.

## When to use

* Use when the task involves logs, metrics, traces, dashboards, alerts, SLOs, SLIs, error budgets, or production diagnostics.
* Use when investigating incidents, outages, degraded service, recurring failures, flaky production behavior, or unknown runtime errors.
* Use when defining or improving the operational procedures, diagnostic checks, mitigations, escalation paths, health checks, or verification steps in runbooks.
* Use when defining what should be monitored before or after a release.
* Use when analyzing operational symptoms such as high error rates, timeouts, queue buildup, failed jobs, saturation, restarts, or unhealthy dependencies.

## When not to use

* Do not use when the main task is building CI/CD pipelines, deployment automation, infrastructure provisioning, or rollback mechanics; use `11-release/SKILL.md`.
* Do not use when the main task is implementing application features or refactoring production code; use `04-build/SKILL.md`.
* Do not use when the main task is performance tuning, profiling, or capacity optimization unless framed as reliability diagnosis; use `10-improve/SKILL.md`.
* Do not use for test planning or regression testing unless tests are being used to verify reliability behavior; use `05-test/SKILL.md`.
* Do not use for security incidents, threat analysis, or vulnerability response unless the reliability impact is the focus; use `08-secure/SKILL.md`.
* Do not use when the runbook procedures are already defined and the main task is formatting, organizing, editing, or publishing them; use `06-document/SKILL.md`.

## Inputs to look for

* Reported symptoms, error messages, timestamps, affected users, affected services, and scope of impact.
* Logs, metrics, traces, alerts, dashboard screenshots, health checks, deployment history, and recent configuration changes.
* Service dependencies, data stores, queues, third-party APIs, infrastructure components, and network boundaries.
* Existing SLOs, SLIs, alert rules, escalation policies, runbooks, and incident notes.
* Environment details such as production, staging, region, cluster, version, release, container, host, or cloud service.
* Known constraints such as acceptable downtime, data loss tolerance, compliance requirements, and on-call process.

## Procedure

1. **Clarify the operational objective.** Determine whether the task is diagnosis, monitoring design, alert improvement, incident response, reliability validation, or creation of technical operational runbook content.

2. **Establish impact and timeline.** Identify what is broken, who is affected, when it started, whether it is ongoing, and whether the issue correlates with deployments, traffic changes, dependency failures, configuration changes, or infrastructure events.

3. **Separate symptoms from causes.** Treat alerts, error messages, and user reports as signals, not conclusions. Avoid assuming root cause until supported by evidence.

4. **Inspect signals systematically.** Check logs for error patterns, metrics for rate/saturation/latency changes, traces for slow or failing spans, and health checks for dependency or service status. Compare failing and healthy periods.

5. **Map the failure path.** Trace the request, job, event, or data flow through relevant components. Identify where behavior first diverges from expected operation.

6. **Prioritize likely causes.** Rank hypotheses by evidence, blast radius, timing, and reversibility. Prefer explanations that match both the symptom and the timeline.

7. **Recommend safe actions.** Suggest containment, rollback, restart, failover, traffic shift, dependency isolation, feature flag changes, queue draining, or configuration correction only when appropriate. Call out risk and verification steps.

8. **Define verification.** State which signal proves recovery: error rate reduction, latency normalization, queue depth decline, successful health checks, restored user workflow, or stable dependency behavior.

9. **Improve observability and operational guidance.** Identify missing logs, metrics, traces, labels, correlation IDs, dashboard panels, alert thresholds, or runbook procedures that would make future diagnosis and mitigation faster.

10. **Capture follow-up work.** Separate immediate remediation from long-term reliability improvements such as better alerting, dependency isolation, retry policy changes, capacity safeguards, or failure-mode tests.

## Expected outputs

* Incident diagnosis summary with impact, timeline, evidence, likely cause, and confidence level.
* Troubleshooting plan with ordered checks, commands or queries when useful, and expected observations.
* Monitoring plan with key SLIs, metrics, logs, traces, dashboards, and alert conditions.
* Alert review with noisy, missing, duplicate, or low-signal alerts identified.
* Evidence-based operational runbook content with diagnostics, escalation, mitigation, verification, and rollback guidance.
* Post-incident follow-up list separating immediate fixes from preventive improvements.

## Quality checks

* The answer distinguishes observed facts, hypotheses, and recommended actions.
* The proposed diagnosis fits the reported timeline and all known symptoms.
* Alerting recommendations are actionable and tied to user impact or service health.
* Metrics include enough context: rate, errors, duration, saturation, traffic volume, dependency status, and labels/dimensions where relevant.
* Runbook steps are safe, ordered, reversible where possible, and include verification.
* The output avoids pretending certainty when evidence is incomplete.
* Follow-up work is scoped and does not drift into unrelated architecture, testing, or deployment detail.

## Anti-patterns

* Avoid jumping from an alert directly to a root cause without evidence.
* Avoid treating logs as the only source of truth when metrics or traces are needed.
* Avoid vague advice such as “check the logs” without specifying what to look for.
* Avoid alert rules that trigger on harmless noise, single transient failures, or symptoms without user impact.
* Avoid dashboards that show raw infrastructure data but omit service-level health.
* Avoid recommending restarts, rollbacks, or failovers without explaining risk and verification.
* Avoid mixing incident response with broad redesign unless the user asks for prevention work.
* Avoid hiding uncertainty; state what is known, unknown, and needed next.

## Related skills

* `11-release/SKILL.md` — use only when deployment mechanics, CI/CD, environment configuration, containers, cloud operations, or rollback implementation are the main task.
* `10-improve/SKILL.md` — use only when profiling, tuning, scalability validation, refactoring, or technical debt reduction is the main task.
* `05-test/SKILL.md` — use only when reliability needs to be verified through test plans, regression tests, failure-mode tests, or automated validation.
* `08-secure/SKILL.md` — use only when the incident or diagnostic task involves security controls, vulnerabilities, abuse, secrets, authentication, authorization, or threat response.
* `04-build/SKILL.md` — use only when the solution requires production code creation or modification.
* `06-document/SKILL.md` — use when operational procedures are already defined and the main task is formatting, organizing, editing, or durably publishing the runbook without inventing procedures.
