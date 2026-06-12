# Documentation Footprint Reduction Plan

## Objective

Reduce the combined implementation footprint of `SPEC.md` and `DESIGN.md` while preserving enough public contract, internal design detail, and traceability to implement `nsurgn` v1.0.

`SPEC.md` does not need to be the single source. The desired end state is a small, navigable document set where each detail has one clear home.

## Scope

In scope:

- `SPEC.md` public product and CLI contract.
- `DESIGN.md` implementation-facing architecture, records, algorithms, and output contracts.
- Cross-references between the two documents.
- Removal of repeated explanatory prose that does not help implementation.

Out of scope:

- Production code changes.
- New technical behavior.
- Validation of the technical correctness of existing v1 decisions beyond preserving stated contracts.
- Durable historical documentation beyond this working plan.

## Working Targets

- Prefer a combined `SPEC.md` + `DESIGN.md` footprint that is materially smaller than the current `137,052` bytes.
- Treat size as a guardrail, not the primary quality measure. The primary requirement is implementability from the remaining docs.
- Keep `SPEC.md` focused on externally visible behavior and conformance.
- Keep `DESIGN.md` focused on internal representation, algorithms, command flow, and renderer contracts.
- Delete duplicated explanation instead of moving it when the target document already contains the same implementation fact.

## Current Findings To Resolve

1. `SPEC.md` section 10.5 is the largest bloat hotspot.

   Action: split the section into compact public evidence rules in `SPEC.md` and implementation-facing normalization details in `DESIGN.md`, then remove duplicated tables or prose.

   Preserve in `SPEC.md`: accepted evidence concept, classification impact, precedence, externally observable behavior, and conformance-sensitive enums.

   Preserve in `DESIGN.md`: parsing sequence, hint normalization mechanics, source-family availability handling, and implementation tables that are needed by code.

2. `SPEC.md` section 10.3 repeats classification rules.

   Action: keep one compact rule set in `SPEC.md` with labels, score thresholds, selector sets, and precedence. Remove repeated prose summaries that restate the same model.

   Preserve in `DESIGN.md`: classification reason record shape and any implementation notes needed to emit reasons consistently.

3. `SPEC.md` section 16.3 mixes public exit-code contract with command metadata materiality detail.

   Action: keep stable exit codes and precedence in `SPEC.md`. Move or compress command-by-command metadata materiality detail into `DESIGN.md` only if it is needed for implementation; otherwise replace it with a shorter rule.

4. `SPEC.md` sections 12.3 and 12.4 contain repeated artifact ID and target-resolution prose.

   Action: reduce these sections to normative target syntax, resolution order, visibility behavior, and error outcomes.

   Preserve implementation details in `DESIGN.md` only when they affect scan records, lookup flow, or command output.

5. `SPEC.md` section 13.5 repeats target visibility rules for `map`.

   Action: make `map` reference the shared target-resolution section instead of restating it.

   Preserve in `map`: relationship generation, relationship enum, namespace types, duplicate suppression, ordering, and output shape.

6. `SPEC.md` sections 22 and 23 are README/design-position material.

   Action: delete these sections from `SPEC.md` or fold only essential framing into Purpose/Product Boundary.

   Do not move broad explanatory prose into `DESIGN.md` unless it helps implementation.

7. `DESIGN.md` already owns many implementation contracts and is also large.

   Action: when moving material out of `SPEC.md`, first check whether `DESIGN.md` already contains equivalent material. Prefer deduplication over relocation.

## Edit Sequence

### Pass 1: Define Document Ownership

- Add or refine a short ownership note near the top of each document.
- `SPEC.md`: public v1 behavior, CLI contract, output guarantees, error contract, acceptance criteria.
- `DESIGN.md`: implementation architecture, scan workspace, internal records, command flow, structured output schemas, fixture plan.
- Avoid claiming either file is a single source for all details.

Stop condition: a reader can tell where public contract ends and implementation guidance begins.

### Pass 2: Reduce Classification And Evidence Sections

- Edit `SPEC.md` sections 10.3 and 10.5 first.
- Collapse repeated classification prose into one authoritative public rule set.
- Move or reference implementation-only evidence normalization details only when `DESIGN.md` does not already cover them.
- Keep cross-references precise enough that an implementer can find the implementation detail.

Stop condition: classification behavior remains implementable, but repeated narrative and oversized matching detail are removed from `SPEC.md`.

### Pass 3: Reduce CLI Target And Map Duplication

- Edit `SPEC.md` sections 12.3, 12.4, and 13.5 together.
- Make target resolution a shared rule.
- Make command sections reference shared target behavior instead of restating it.
- Keep command-specific output and error behavior local to each command.

Stop condition: `map` no longer duplicates target visibility rules, and target syntax/resolution remains explicit.

### Pass 4: Reduce Error And Metadata Detail

- Edit `SPEC.md` section 16.3.
- Keep exit code values, meanings, and precedence.
- Replace the metadata materiality matrix with a compact rule or move only implementation-critical portions into `DESIGN.md`.

Stop condition: public exit behavior is preserved without carrying a large test/design matrix in the public spec.

### Pass 5: Remove README And Positioning Tail Sections

- Edit `SPEC.md` sections 22 and 23.
- Fold essential product framing into sections 1 and 2 if needed.
- Delete examples or positioning prose that does not drive implementation.

Stop condition: `SPEC.md` ends with acceptance criteria or a similarly implementation-relevant section.

### Pass 6: Review `DESIGN.md` For Net Footprint

- Search `DESIGN.md` for new or existing duplicate material after `SPEC.md` edits.
- Remove relocated material when an equivalent design contract already exists.
- Keep one implementation-facing home for each table, record shape, or algorithm.

Stop condition: the combined footprint is smaller, not just shifted from `SPEC.md` into `DESIGN.md`.

## Validation Checks

Run after each major pass:

```sh
wc -c SPEC.md DESIGN.md
wc -l SPEC.md DESIGN.md
rg -n "^(#{1,6})\\s+" SPEC.md DESIGN.md
```

Run before considering the plan complete:

```sh
rg -n "evidence|classification|target resolution|materiality|README-Oriented|Design Position" SPEC.md DESIGN.md
```

Manual review checklist:

- Every externally visible CLI behavior still appears in `SPEC.md` or is directly referenced from it.
- Every implementation-critical algorithm/table has one clear home.
- No command section repeats shared target-resolution behavior.
- Exit-code values and precedence remain explicit.
- `README-Oriented Summary` and `Design Position` no longer remain as standalone spec tail sections unless intentionally retained with a shorter implementation purpose.
- The combined byte and line counts decrease from the starting point: `137,052` bytes and `3,440` lines.

## Risks And Controls

- Risk: deleting evidence details may remove implementation-critical behavior.
  Control: before deletion, confirm whether equivalent detail exists in `DESIGN.md`; if not, move only the compact implementation requirement.

- Risk: reducing `SPEC.md` may make public conformance ambiguous.
  Control: keep externally visible labels, scores, selectors, precedence, error outcomes, and output guarantees in `SPEC.md`.

- Risk: moving content into `DESIGN.md` may preserve the same context bloat.
  Control: measure combined size after each pass and prefer deduplication over relocation.

## Completion Criteria

The findings are resolved when:

- The combined documentation footprint is materially reduced from the current baseline.
- `SPEC.md` is focused on the public v1 contract and no longer carries large implementation tables or README-style tail sections.
- `DESIGN.md` carries only implementation details needed to build the system, without duplicated spec prose.
- A future implementation pass can identify public behavior, internal records, classification logic, target resolution, command flow, output contracts, and error behavior without reading repeated sections.
