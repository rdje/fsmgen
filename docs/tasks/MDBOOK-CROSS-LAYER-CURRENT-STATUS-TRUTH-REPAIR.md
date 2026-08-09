# MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR: Remove stale live-status narration from Chapter 11

## Metadata

- Tree ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR`
- Status: `proposed`
- Roadmap lane: `project documentation / cross-layer current truth`
- Created: `2026-08-09`
- Last updated: `2026-08-09`
- Owner: repo-local workflow

## Origin

The IAL2 mdBook coherence audit found Chapter 11 still calls
`BACKEND-API-VALIDATION-FRONTIER.104` the active backend/API frontier, says a
historical GHDL-unavailable leaf defines the current validation boundary, and
later says roadmap priority returned to `IAL2-FEATURE-COMPLETENESS-FRONTIER.197`.
Those live-status claims predate the current HIAL/VIAL decisions and task-tree
frontiers. They are independently reproducible but outside the selected
IAL2/AXI documentation tree.

## Goal

Make Chapter 11 describe durable shipped API/backend contracts and current
bounded residue without embedding obsolete task-frontier narration.

## Non-Goals

- Do not change backend, API, VHDL, GHDL, OSVVM, HIAL, VIAL, or MCP behavior.
- Do not infer the current qualification boundary from tool installation alone;
  reconcile decision, task, report, test, and runtime evidence first.

## Task Tree

- ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR`
  Status: `proposed`
  Goal: `Replace stale Chapter 11 live-status narration with durable shipped-contract truth.`
  Children: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR.1`

- ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR.1`
  Status: `pending`
  Goal: `Audit and repair the stale Chapter 11 backend/API/VHDL status passages.`
  Acceptance: `On clean activation, reconcile Chapter 11 lines around the historical .104/.102/.197 claims with current BACKEND-API task history, decisions 0032/0051, HIAL/VIAL .15 qualification evidence, capability manifests, tests, and actual tool profiles. Replace volatile active-frontier narration with durable shipped capability and residue statements; update any directly dependent book prose; build the book and pass path/doctrine gates without changing behavior.`
  Verification: `Pending. Discovery evidence: current Chapter 11 names historical active frontiers at lines 2517..2527 and 2890..2897; MEMORY.md records later .15.5-.15.7 GHDL/OSVVM qualification and decision 0051.`
  Commit: `pending activation`

## Decisions

- `2026-08-09`: Track this separately from IAL2 AXI coherence because it spans
  backend/API and HIAL/VIAL qualification truth.

## Blockers

- Clean explicit activation after the current selected tree completes or parks.
