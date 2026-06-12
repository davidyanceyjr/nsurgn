# Handoff Brief

## Objective
Continue the `SPEC.md` and `DESIGN.md` review for `nsurgn` v1.0 by resolving
documentation gaps that interfere with implementation.

## Current State
The working tree was clean before this handoff update. The latest commit seen
was `bd59a0d Resolve spec gap documentation`.

`SPEC_GAPS_PLAN.md` is no longer present in the repository; the prior handoff
claim that it still existed as a historical traceability register is stale.

Review scope completed in this session:

- `SPEC.md`
- `DESIGN.md`

The review found implementation-blocking or implementation-affecting gaps in
the spec/design contracts. No production code, tests, or conformance behavior
were inspected.

## Changed Artifacts
- `.codex/handoffs/current.md`: replaced the stale spec-gap closure handoff with
  this review handoff.

## Checks And Evidence
Evidence locations from the review:

- Cgroup paths are required for grouping, hints, classification, and inspect
  output, but no internal raw/parsed cgroup-path record exists:
  `SPEC.md` sections around `--group cgroup`, cgroup evidence matching, and
  `inspect`; `DESIGN.md` `process.tsv`.
- Mountinfo-derived evidence and mount summaries are required, but no internal
  mountinfo or mount-summary workspace contract exists:
  `SPEC.md` evidence table; `DESIGN.md` scan workspace and inspect mount
  summary section.
- Limitation records are inconsistent:
  `DESIGN.md` `scan_warning.tsv` omits `source` and `read_status`, while
  structured `scan_limitation` requires them and raw limitation rows specify a
  smaller shape.
- Label selection is not deterministic enough for implementation:
  `SPEC.md` makes `anomalous` finite, but `container-like` and
  `namespace-managed` rely on non-finite phrases such as strong runtime evidence
  and host service management while score alone must not determine labels.
- Missing namespace values in grouping keys are underspecified:
  the docs define artifact-level missing values but not how missing namespace
  IDs affect group-key formation for `profile`, `strict`, `pid`, `mnt`, and
  `net`.
- Host-PID target command flow does not explicitly assign artifact IDs even
  though target records include `artifact_id` and host-PID targets may resolve
  hidden artifacts.

## Risks, Blockers, And Open Questions
Blocking gaps:

- Define an internal cgroup-path record contract, such as `process_cgroup.tsv`,
  with enough data for `--group cgroup`, `inspect` cgroup paths, hints, scoring,
  and limitations.
- Define internal mountinfo/mount-summary records so classifiers and renderers
  do not duplicate parsing or infer mount-derived evidence independently.
- Normalize limitation shape across internal records, raw output, JSON, and
  NDJSON.
- Add deterministic predicates for `container-like` and `namespace-managed`.

Open questions:

- How should missing namespace IDs participate in grouping keys?
- For host-PID targets that resolve hidden artifacts, should output assign an
  `artifact_id`, and if so, relative to which visibility set and ordering?

## Immediate Next Action And Owner
Owner: Unknown. Edit `DESIGN.md` to add canonical internal record contracts for
cgroup paths, mount summaries, and limitations.

## Resume Notes
After the immediate design-contract edit, revisit `SPEC.md` to make
`container-like` and `namespace-managed` label selection finite and to define
missing-namespace grouping behavior.
