---

name: 07-review
description: Use when the user wants to review, inspect, lint, format, clean up, prepare a PR, manage Git workflows, branch, commit, handle pull requests, run static analysis, improve code hygiene, or get code ready for review. Do not use for main feature code, test design, deployment, runtime troubleshooting, or refactoring-centered work unless source control or review readiness is the main task.
---

# Source Control and Code Quality

## Purpose

This skill helps manage code changes safely and reviewably. It covers version control workflow, branch hygiene, commit quality, pull request preparation, code review, static analysis, formatting, linting, and code-quality checks that make implementation easier to understand, maintain, and merge.

Use this skill to keep changes organized, reduce review friction, and prevent avoidable defects from entering the codebase. It should not take over feature implementation, testing strategy, deployment, or production diagnostics.

## When to use

* Use when creating, reviewing, or improving Git branches, commits, diffs, pull requests, or merge plans.
* Use when preparing code for review through formatting, linting, static analysis, dependency checks, or cleanup.
* Use when analyzing a code review comment, proposing review feedback, or deciding whether a change is ready to merge.
* Use when splitting large changes into smaller commits or pull requests.
* Use when resolving merge conflicts, rebase issues, cherry-picks, revert plans, or release-branch hygiene.
* Use when cleanup is narrowly limited to making an active change easier to review or pass established quality gates.

## When not to use

* Do not use when the main task is writing or modifying production feature code; use `04-build/SKILL.md`.
* Do not use when the main task is designing or validating tests; use `05-test/SKILL.md`.
* Do not use when the main task is deployment, CI/CD platform setup, containers, or rollback operations; use `11-release/SKILL.md`.
* Do not use when the main task is production troubleshooting, logs, metrics, or incident response; use `09-operate/SKILL.md`.
* Do not use for formal security review unless code review is only a support activity; use `08-secure/SKILL.md`.
* Do not use when refactoring, technical debt reduction, or maintainability improvement is the main task; use `10-improve/SKILL.md`.

## Inputs to look for

* Repository status, branch name, target branch, and whether the work is local or already pushed.
* The user’s goal: commit, branch, review, merge, rebase, revert, clean up, or prepare a pull request.
* Relevant diffs, changed files, commit history, review comments, failing quality checks, or static analysis output.
* Project conventions for branch names, commit message style, formatting, linting, code owners, and pull request templates.
* Risk level of the change, affected modules, generated files, migrations, public interfaces, or dependency changes.
* Available implementation status, compact requirement traceability, and functional validation evidence.
* Whether the user wants commands, review feedback, a PR description, or a quality assessment.

## Procedure

1. **Determine the workflow state.** Identify the current branch, target branch, changed files, staged changes, untracked files, and whether there are pending conflicts or remote divergence. Avoid destructive commands unless the user explicitly requests them or the effect is clearly reversible.

2. **Classify the change.** Decide whether the work is a feature, bug fix, refactor, dependency update, configuration change, documentation update, or generated output. Use that classification to guide commit boundaries, review focus, and risk checks.

3. **Inspect change quality.** Review the diff for unrelated edits, noisy formatting, accidental files, secrets, debug code, dead code, unclear names, excessive complexity, inconsistent style, or missing documentation comments where expected by the project. When compact traceability exists, use it to find omitted requirements, unrelated changes, and unsupported completion claims without taking ownership of requirements, implementation, or test design.

4. **Check repository hygiene.** Confirm the branch is based on the correct target, commits are logically grouped, generated files are intentional, lockfiles match dependency changes, and large binary or environment-specific files are not accidentally included.

5. **Apply project quality gates.** Prefer existing project commands for formatting, linting, type checking, static analysis, dependency validation, and pre-commit hooks. When commands are unknown, infer cautiously from repository files such as package manifests, Makefiles, CI configs, or tool configs.

6. **Prepare reviewable commits.** Recommend staging only related files together. Use concise commit messages that explain what changed and why. Split unrelated work into separate commits or branches when that reduces review risk.

7. **Prepare the pull request.** Summarize intent, key changes, risk areas, validation performed, linked issues, migration notes, rollout concerns, and reviewer focus areas. Keep the PR description factual and scoped to the actual diff.

8. **Review or respond to review.** When reviewing, prioritize correctness, maintainability, clarity, security-sensitive mistakes, test impact, and compatibility. When responding, address the substance, propose concrete changes, and avoid defensive wording.

9. **Handle integration safely.** For merges, rebases, conflict resolution, cherry-picks, and reverts, explain the safest path, expected side effects, and verification steps. Preserve user work and call out commands that rewrite history.

10. **Finalize with verification.** Confirm the working tree state, quality checks run, unresolved risks, and next action: commit, push, open PR, request review, merge, or revise. When merge readiness is requested, conclude `MERGE READY`, `NOT MERGE READY`, or `BLOCKED` with concise evidence. Treat implementation and functional-validation results as review inputs, not proof of merge readiness.

## Subagent delegation

Subagents are optional. Use them only when independent diff review, disjoint file review, repository-hygiene inspection, or CI/static-analysis triage has a concrete coverage or speed advantage. Prefer read-only tasks. Any edit authority must use an explicit, disjoint file scope and must exclude Git history changes, commits, pushes, merges, rebases, destructive operations, and overlapping work.

For each delegation, state the expected advantage and explicitly invoke `07-review/SKILL.md` in a bounded, self-contained prompt with the inputs, write scope or read-only restriction, and expected output. Prohibit recursive delegation and unsupported findings, evidence, statuses, or ownership changes. The parent must review and integrate results, resolve contradictions, retain the final review findings and merge-readiness assessment, and close completed agents promptly.

Faster models may check formatting, accidental files, reference validity, or repetitive static-analysis output with objective acceptance criteria. Correctness-sensitive review and merge-readiness conclusions require stronger reasoning and parent confirmation. Model choice never lowers the evidence or review standard.

## Expected outputs

* A safe Git workflow plan with commands when appropriate.
* Clean branch, commit, rebase, merge, cherry-pick, or revert guidance.
* Review comments that are specific, actionable, and prioritized.
* A concise pull request title and description.
* A code-quality checklist tailored to the actual change.
* Identification of accidental files, unrelated changes, style issues, or review blockers.
* Static analysis, formatting, linting, or pre-commit recommendations based on project conventions.
* A `MERGE READY`, `NOT MERGE READY`, or `BLOCKED` assessment with remaining risks and validation status when readiness is requested.
* Review-readiness findings for omitted requirements, unrelated changes, or unsupported completion claims when traceability is available.

## Quality checks

* The suggested workflow preserves user work and avoids unnecessary destructive operations.
* Commands match the user’s stated goal, repository state, and target branch.
* Commit boundaries are logical and do not mix unrelated concerns.
* Review feedback is grounded in the diff, not generic preference.
* Quality checks use existing project tooling when discoverable.
* Pull request text accurately reflects the change and does not claim unperformed validation.
* Merge-readiness conclusions distinguish implementation status from functional verification and review quality.
* Generated files, lockfiles, migrations, and configuration changes are handled intentionally.
* Any history-rewriting operation, such as rebase or reset, includes a clear warning and safer alternative when appropriate.

## Anti-patterns

* Avoid rewriting history on shared branches without explicit user intent.
* Avoid suggesting `git reset --hard`, force-push, or broad cleanup commands without explaining data-loss risk.
* Avoid mixing feature work, formatting sweeps, dependency updates, and refactors in one review unless intentionally scoped.
* Avoid expanding review-focused cleanup into broader refactoring or technical debt work.
* Avoid vague review comments such as “clean this up” without a concrete reason or suggestion.
* Avoid treating lint or formatting as a substitute for correctness review.
* Avoid generating commit messages or PR descriptions that exaggerate scope or validation.
* Avoid treating code-complete status as proof that a change is tested, merge ready, releasable, or production ready.
* Avoid loading implementation, testing, deployment, or observability concerns unless they are directly needed for source-control or review quality.
* Avoid framework-specific review rules unless the repository clearly uses that framework.

## Related skills

* `04-build/SKILL.md` — use only when the task requires writing or changing production code beyond review-focused cleanup.
* `05-test/SKILL.md` — use only when test design, test creation, regression coverage, or bug verification is a primary concern.
* `08-secure/SKILL.md` — use only when review findings involve authentication, authorization, secrets, permissions, vulnerabilities, or threat modeling.
* `11-release/SKILL.md` — use only when branch workflow affects CI/CD, release automation, deployment, rollback, or environment configuration.
* `10-improve/SKILL.md` — use when refactoring, performance, scalability, technical debt, or maintainability improvement is the main task rather than review readiness.
* `06-document/SKILL.md` — use only when the task requires durable documentation such as contribution guides, review policies, changelogs, or decision records.
