# Agent Operating Notes

## Context Budget

Context window sizes may vary by model or environment. Use percentages as the source of truth. Token counts are examples for a 32k context window.

Use these thresholds to manage long-running work:

- 0-25% used, about 0-8k tokens on 32k: preserve the main thread for coordination, decisions, and integration. Use sub-agents for narrow exploration or isolated implementation when their work can stay independent.
- Around 25% used, about 8k tokens on 32k: checkpoint the session. If there are important decisions, changed files, open questions, risks, or a stage transition, create a compact `12-handoff`.
- Around 50% used, about 16k tokens on 32k: avoid broad design work or large multi-file changes unless the context has been compressed or a handoff exists.
- Around 65% used, about 20k tokens on 32k: prefer creating a handoff or restarting with summarized context. Continue only if the remaining work is narrow and well understood.
- 75%+ used, about 24k+ tokens on 32k: perform only narrow completion work, validation, or handoff preparation.

## Sub-Agent Context Strategy

Use sub-agents to preserve the main context window for decisions, integration, and user-facing state.

Before the main thread reaches the 25% soft checkpoint, consider spawning sub-agents for narrow, independent investigations or isolated implementation tasks. Sub-agents have their own context windows, so they can absorb bulky exploration without polluting the main thread.

Good sub-agent tasks:

- Explore one subsystem and return a compact summary
- Inspect test coverage around one behavior
- Analyze logs, CI output, or error traces
- Compare implementation options for a bounded decision
- Make a small change in a disjoint file scope

Each sub-agent task must include:

- A narrow objective
- Explicit scope boundaries
- Expected output format
- A compact final-answer requirement
- A clear stop condition

The main thread should import only the useful result: conclusions, evidence, changed files, risks, and recommended next action.

Do not use sub-agents as durable memory. They are disposable context for focused work. Preserve canonical session state in a handoff when approaching context limits or stage changes.

## Chunking Strategy

For broad or multi-stage work, split the task into bounded chunks before deep exploration.

A chunk should have:

- One concrete objective
- A clear scope boundary
- A stop condition
- A compact output: findings, changed files, validation, risks, and next action

Prefer chunking when:

- The work spans multiple skills, subsystems, or test suites
- Exploration may produce lots of logs or file context
- The next step depends on a decision from the current step
- The task may exceed the 25% context checkpoint

Do not carry raw chunk output forward. Preserve only the decision-relevant summary.

## Handoff Requirements

A handoff must be short and actionable. Include only:

- Objective
- Current stage
- Key decisions
- Changed files
- Validation performed
- Open questions
- Known risks
- Next action

Do not include full logs, broad summaries, repeated reasoning, or unrelated repository details.

## Persistent Handoff Scratchpad

When creating a handoff for context clearing, interruption, or session pause, write it to `.codex/handoffs/current.md`.

This file is a resumable working note, not durable project history. It may be overwritten whenever a newer handoff state is created.

When resuming from `.codex/handoffs/current.md`, treat it as a context shortcut only. Verify current truth from the working tree, `git diff`, recent commits, tests, issues, PRs, and any referenced artifacts before acting.

If a durable historical handoff is explicitly needed, write a timestamped file such as `.codex/handoffs/YYYY-MM-DD-topic.md`.

## Working Rule

Before context becomes crowded, preserve the minimum state needed for another agent or future continuation to resume safely.
