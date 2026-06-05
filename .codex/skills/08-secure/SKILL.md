---

name: 08-secure
description: Use when the user wants to secure, threat model, harden, review auth, review permissions, handle secrets, assess vulnerabilities, remediate security issues, evaluate dependency risk, create security tests, or patch security risks. Do not use for general implementation, testing, or deployment unless security controls or risks are the main focus.
---

# Security Engineering

## Purpose

This skill helps identify, reduce, and validate software security risks across design, code, configuration, dependencies, and operations. Use it to make security reasoning explicit, prioritize realistic threats, and produce practical remediation steps without turning every engineering task into a full security review.

It owns security-driven vulnerability remediation, including applying patches and validating them when patching is the central task. It may use implementation support without surrendering ownership of the security-centered patch.

## When to use

* Use when designing or reviewing authentication, authorization, access control, session handling, permissions, or identity flows.
* Use when analyzing threats, abuse cases, trust boundaries, sensitive data handling, secrets, encryption, or input/output validation.
* Use when reviewing code, configuration, dependencies, infrastructure, APIs, or workflows for vulnerabilities.
* Use when patching a known vulnerability or evaluating whether a reported issue is exploitable.
* Use when creating security tests, hardening guidance, or security acceptance criteria.

## When not to use

* Do not use for general feature implementation where security is not the main concern.
* Do not use for ordinary test planning unless the tests are specifically security-focused.
* Do not use for deployment automation unless security controls, permissions, secrets, or environment hardening are central.
* Do not use for performance, reliability, or observability work unless those issues create or expose security risk.
* Do not use as a substitute for legal, compliance, privacy, or formal audit advice.

## Inputs to look for

* System purpose, user roles, privilege levels, assets, sensitive data, and business impact.
* Architecture, data flows, trust boundaries, external integrations, APIs, storage, and deployment environment.
* Authentication, authorization, session, token, secret, key, certificate, and permission model.
* Relevant code, configuration, dependency manifests, infrastructure definitions, logs, or vulnerability reports.
* Threat assumptions, attacker capabilities, known constraints, acceptable risk, and required security standards.
* Existing controls, monitoring, tests, incident history, and patch or rollback constraints.

## Procedure

1. Define the security scope. Identify the asset, operation, user role, data type, environment, and boundary being reviewed. State what is in scope and what is intentionally out of scope.

2. Map the trust model. Identify callers, services, storage systems, external dependencies, privileged paths, unauthenticated paths, and places where data crosses trust boundaries.

3. Identify realistic threats. Consider broken access control, injection, unsafe deserialization, insecure direct object references, credential leakage, weak session handling, insufficient validation, dependency compromise, insecure defaults, and privilege escalation. Focus on threats that match the actual system.

4. Evaluate existing controls. Check whether the system authenticates the right actor, authorizes every sensitive action, validates untrusted input, protects secrets, limits exposure, logs security-relevant events, and fails safely.

5. Prioritize findings by risk. Estimate likelihood, impact, exploitability, affected users or data, compensating controls, and exposure. Separate confirmed vulnerabilities from hypotheses and hardening opportunities.

6. Remediate the risk. Prefer narrow, actionable changes: stricter authorization checks, safer APIs, parameterized queries, schema validation, secret rotation, dependency upgrades, least-privilege permissions, secure defaults, rate limits, audit logging, or defense-in-depth controls. Apply the patch when requested and security remediation is central.

7. Define validation. Provide security tests, regression checks, abuse cases, review steps, or manual verification needed to prove the issue is fixed and does not reappear.

8. Document residual risk. State unresolved assumptions, tradeoffs, monitoring needs, follow-up work, and any risk that remains after mitigation.

## Subagent delegation

Subagents are optional. Use them only when independent threat perspectives, disjoint attack surfaces, bounded evidence collection, or a second review of high-risk findings has a concrete advantage. Keep tasks read-only unless a narrowly scoped patch with a disjoint write scope is explicitly assigned. Do not expose secrets or unnecessary sensitive data, and do not delegate live operations or destructive actions.

For each delegation, state the expected advantage and explicitly invoke `08-secure/SKILL.md` in a bounded, self-contained prompt with sanitized inputs, scope, and expected output. Prohibit recursive delegation and unsupported severity, risk acceptance, remediation-complete claims, evidence, statuses, or ownership changes. The parent must review and integrate results, validate exploitability and severity, own final security conclusions, resolve contradictions, and close completed agents promptly.

Faster models may perform inventory or known-pattern checks with objective acceptance criteria. Threat synthesis, severity, remediation acceptance, and ambiguous or high-risk conclusions require stronger reasoning or parent completion. Model choice never lowers the evidence or review standard.

## Expected outputs

* Threat model, abuse-case list, or security review summary.
* Prioritized vulnerability findings with severity, evidence, impact, and remediation.
* Secure design recommendations for auth, access control, data protection, secrets, or trust boundaries.
* Patch plan with implementation guidance and validation steps.
* Applied security patch or remediation with validation evidence when requested.
* Security test cases, regression checks, or acceptance criteria.
* Risk notes distinguishing confirmed issues, assumptions, and hardening opportunities.

## Quality checks

* The review identifies assets, actors, trust boundaries, and sensitive operations before listing fixes.
* Findings are specific, evidence-based, and tied to realistic exploit paths.
* Recommendations are actionable and scoped to the system rather than generic security advice.
* Authentication and authorization are treated separately.
* Secrets, tokens, credentials, keys, certificates, and environment variables are not exposed in output.
* Severity reflects actual impact and likelihood, not just theoretical weakness.
* Validation steps prove the control works and include negative or abuse-case testing where appropriate.
* Residual risks and assumptions are explicit.

## Anti-patterns

* Avoid treating every bug as a security vulnerability without a plausible exploit path.
* Avoid giving generic checklists that ignore the system’s architecture and data flow.
* Avoid recommending encryption, rate limiting, or zero trust as vague catch-all fixes.
* Avoid focusing only on input validation while missing authorization, secrets, and privilege boundaries.
* Avoid exposing or repeating sensitive values found in code, logs, screenshots, or configuration.
* Avoid overloading general implementation or deployment tasks with security review unless security is central.
* Avoid claiming compliance, audit readiness, or complete safety from a limited review.

## Related skills

* `01-understand/SKILL.md` — use only when security requirements, user roles, constraints, or acceptance criteria are unclear.
* `02-design/SKILL.md` — use only when security concerns require changes to system boundaries, component responsibilities, or high-level design.
* `03-contract/SKILL.md` — use only when the security work depends on API contracts, schemas, data models, or integration boundaries.
* `04-build/SKILL.md` — use only for implementation support around a security-owned patch or when ordinary implementation, rather than vulnerability remediation, is central.
* `05-test/SKILL.md` — use only when broader non-security test planning is needed around the security change.
* `11-release/SKILL.md` — use only when deployment permissions, secrets management, cloud controls, CI/CD security, or rollback are central.
* `09-operate/SKILL.md` — use only when security logging, alerting, incident investigation, or operational diagnostics are required.
* `10-improve/SKILL.md` — use only when security fixes introduce major performance or maintainability tradeoffs.
* `06-document/SKILL.md` — use only when producing formal security notes, runbooks, decision records, or user-facing security documentation.
