# AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE: AXI Manager Rule Matrix Design Probe

## Metadata

- Tree ID: `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Classify the captured AXI Valid-Ready and ID/order source evidence into a
first bounded rule matrix for a future IAL2 AXI manager rule engine.

## Non-Goals

- Do not implement an AXI manager.
- Do not implement IAL2 syntax, parser, lowering, `.isf`, `.fsm`, HDL, tests,
  or generated artifacts.
- Do not select max-pending defaults, queue depths, ID allocation algorithms,
  channel state machines, or generated assertion syntax.
- Do not claim full AXI compliance.
- Do not re-extract the full AXI specification; this leaf classifies the
  already captured evidence and records explicit residue.

## Acceptance Criteria

- The task tree owns the rule-matrix design/probe before the matrix note is
  written.
- A repo-local design/probe note maps the captured source anchors to rule
  responsibilities: static authoring checks, generated scheduler/scoreboard
  behavior, runtime assertions, environment assumptions, and unsupported
  residue.
- The note preserves the Easy/Power/supervised Raw API direction while making
  clear that no implementation behavior is selected.
- The mdBook backlog, IAL2 evaluation, AXI manager brainstorm, task tree,
  Knowledge Map, README, and memory remain synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE`
  Status: `done`
  Goal: `Classify captured AXI evidence into a first future manager rule matrix.`
  Children: `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.1`

- ID: `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.1`
  Status: `done`
  Goal: `Write the first AXI manager source-to-rule responsibility matrix.`
  Acceptance: `Use the existing AXI Valid-Ready and ID/order evidence notes to produce a bounded rule-matrix design/probe with explicit static/scheduler/assertion/environment/residue classification and no parser/lowering/HDL implementation selected.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.1` | `done` | The first rule matrix is recorded in `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; future implementation selection needs a new exact owner. |

## Decisions

- `2026-06-12`: Start with a rule responsibility matrix only. Future syntax,
  parser, lowering, generated IAL1/IAL0, HDL behavior, and tests need later
  exact task-tree owners.
- `2026-06-12`: The matrix classifies captured evidence into static,
  scheduler, assertion, environment, and residue responsibilities, but selects
  no shipped subset or implementation behavior.

## Open Questions

- Whether the first implementation should start with Valid-Ready only, a
  narrow read/write manager subset, or an assertion/report-only rule engine
  remains future exact-owner work.

## Blockers

- None for the bounded design/probe.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.1: record AXI manager rule matrix` | Records the first AXI manager source-to-rule responsibility matrix and no-implementation status. |

## Changelog

- `2026-06-12`: Created active task tree for the first AXI manager
  source-to-rule responsibility matrix.
- `2026-06-12`: Recorded the first rule matrix and synchronized README,
  mdBook, IAL2 evaluation, AXI manager brainstorm, evidence notes, Knowledge
  Map, task tree, and memory.
