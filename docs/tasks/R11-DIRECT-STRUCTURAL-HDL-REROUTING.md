# R11-DIRECT-STRUCTURAL-HDL-REROUTING: Direct HDL Rerouting Through StructuralRTLIR

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute selected direct HDL emission through `StructuralRTLIR` once the direct
structural surface is rich enough to preserve the current generated HDL
semantics without relying on parallel string-only generation paths.

## Non-Goals

- Do not change HDL emission while this tree remains `proposed`; an explicit
  active leaf must own any implementation slice.
- Do not reroute before the required direct structural ports, nets, assignment
  records, and net source/target connectivity have been selected or proven
  sufficient for the chosen slice.
- Do not use string parsing as the rerouting contract.
- Do not broaden to VHDL, package-root HDL emission, composition HDL parity, or
  instance/link rerouting unless a later activated leaf explicitly selects that
  scope.
- Do not remove compatibility surfaces without a compatibility-specific owner.

## Acceptance Criteria

- A readiness/selection leaf identifies the first safe HDL rerouting slice and
  all required structural prerequisites.
- The selected implementation leaf, when activated, generates the chosen direct
  HDL path from `StructuralRTLIR` while preserving existing supported behavior.
- Focused HDL regression tests and broader semantic/HDL gates prove no
  unintended output drift for the selected fixtures.
- Public contracts, mdBook, roadmap, Knowledge Map, and task-tree evidence are
  updated when an implementation leaf is activated.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING`
  Status: `proposed`
  Goal: `Reroute selected direct HDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1`

- ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1`
  Status: `pending`
  Goal: `Audit direct HDL emission parity prerequisites and select the first StructuralRTLIR-rerouted HDL slice.`
  Acceptance: `A readiness/selection slice records the first reroute target, required structural fields, validation matrix, rollback boundary, and documentation targets before any HDL rerouting code changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1` | `pending` | Direct HDL currently remains emitted by the existing backend path; rerouting must wait until the StructuralRTLIR surface can represent the selected HDL slice structurally. |

## Decisions

- `2026-06-12`: Track HDL rerouting through `StructuralRTLIR` as its own R11
  tree so it is planned explicitly and not conflated with assignment records or
  source/target connectivity.

## Open Questions

- None.

## Blockers

- This tree is proposed and not PNT-eligible until explicitly activated or
  selected after the current active frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed task tree.
