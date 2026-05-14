# ISF-COMPOSITION: Generated Child Instantiation And Spawn Binding

## Metadata

- Tree ID: `ISF-COMPOSITION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Ship ISF-generated child/spawn composition as a reviewable, documented,
regression-backed flow: parent and child scheduled `.fsm` artifacts should be
usable through an explicit generated top, and spawned child parameters should
bind through validated public semantics instead of remaining deferred.

## Non-Goals

- Do not redesign the general `?top` composition language.
- Do not widen generated-child parameter semantics beyond what ISF spawn needs
  unless the existing composition contract already supports it.
- Do not make schedule JSON a fully frozen schema in this tree; report-shape
  stabilization belongs to `ISF-SCHEDULE-REPORTS`.

## Acceptance Criteria

- Current `(do transaction)` and `(spawn transaction as instance)` lowering
  behavior is inventoried against the existing composition pipeline.
- ISF has a documented authoring contract for generated child top
  instantiation and spawn parameter binding.
- Parent/child scheduled `.fsm` artifacts can be consumed by a generated
  composition/top flow without manual wiring gaps for the covered fixture set.
- Spawn parameter binding validates names, values, widths/shapes, and
  unsupported cases with targeted diagnostics.
- Schedule reports expose enough bounded metadata for downstream consumers to
  discover generated parent/child relationships without traversing raw
  scheduler internals.
- Focused tests and at least one realistic multi-file fixture cover the flow.
- ISF spec, public interface contract, mdBook, roadmap, and live docs agree.

## Task Tree

- ID: `ISF-COMPOSITION`
  Status: `active`
  Goal: `Ship generated child instantiation and spawn parameter binding for ISF.`
  Children: `ISF-COMPOSITION.1`, `ISF-COMPOSITION.2`,
  `ISF-COMPOSITION.3`, `ISF-COMPOSITION.4`, `ISF-COMPOSITION.5`,
  `ISF-COMPOSITION.6`

- ID: `ISF-COMPOSITION.1`
  Status: `pending`
  Goal: `Inventory current child/spawn lowering and composition integration gaps.`
  Acceptance: `The task file lists current emitted files, start/done wiring,
  known composition entrypoints, unsupported spawn parameter cases, and exact
  gaps before policy or implementation work starts.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.2`
  Status: `pending`
  Goal: `Specify public ISF child/spawn composition semantics.`
  Acceptance: `The tree records the accepted syntax, generated artifact
  ownership, parent/child identity rules, parameter binding rules, and rejected
  cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.3`
  Status: `pending`
  Goal: `Implement spawn parameter binding in the ISF IR/lowering path.`
  Acceptance: `Valid spawn parameter bindings preserve through lowering, and
  malformed or unsupported bindings fail before misleading scheduled artifacts
  are emitted.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.4`
  Status: `pending`
  Goal: `Implement generated top/composition handoff for ISF parent/child artifacts.`
  Acceptance: `The covered ISF multi-file output can be consumed by the
  existing generation pipeline to produce a wired parent/child top for the
  agreed fixture set.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.5`
  Status: `pending`
  Goal: `Add diagnostics and bounded schedule-report metadata.`
  Acceptance: `Composition/spawn failures are targeted, and accepted parent,
  child, instance, and binding metadata appears in bounded report fields.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.6`
  Status: `pending`
  Goal: `Add focused regressions, realistic fixture coverage, and docs.`
  Acceptance: `Tests cover valid binding, invalid binding, generated top
  handoff, schedule-report metadata, CLI behavior, and synchronized docs.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-COMPOSITION.1` | `pending` | Current child/spawn lowering and existing composition handoff points must be inventoried before public semantics are set. |

## Decisions

- `2026-05-14`: This tree owns the ISF-specific generated-child top and spawn
  parameter objective. General composition language changes remain outside this
  tree unless they are required by the ISF handoff.

## Open Questions

- Should ISF generate a composition source explicitly, or should the scheduler
  return enough structured metadata for an existing composition entrypoint to
  construct the top?
- Which parameter value domains are valid for spawned ISF children in the
  first shipped slice?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-COMPOSITION` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPOSITION` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF composition/spawn task tree.
