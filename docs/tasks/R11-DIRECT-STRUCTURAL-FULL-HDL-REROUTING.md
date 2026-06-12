# R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING: Full Direct HDL Rerouting

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute broader or full direct SystemVerilog module emission through
`StructuralRTLIR` once the direct structural surface can preserve generated HDL
semantics.

## Non-Goals

- Do not change behavior while this tree remains `proposed`.
- Do not duplicate the already shipped top state/standalone-DT
  generated-enable reroute from `R11-DIRECT-STRUCTURAL-HDL-REROUTING`.
- Do not include VHDL rerouting; that has a separate proposed owner.
- Do not use unmarked HDL string parsing as the rerouting contract.
- Do not remove compatibility surfaces unless a compatibility-specific owner
  approves the change.

## Acceptance Criteria

- A selector/readiness leaf proves the exact first broader SystemVerilog
  reroute target and all required `StructuralRTLIR` prerequisites before code
  changes.
- Any implementation leaf emits only the selected direct SystemVerilog HDL
  portion from `StructuralRTLIR` and preserves existing supported behavior.
- Focused HDL regression tests plus broader semantic/HDL gates prove no
  unintended output drift.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING`
  Status: `proposed`
  Goal: `Reroute broader direct SystemVerilog HDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1`

- ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1`
  Status: `pending`
  Goal: `Select the next broader direct SystemVerilog HDL reroute target.`
  Acceptance: `The selector records current reroute coverage, missing structural prerequisites, first safe broader HDL target, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | `pending` | Proposed owner only; activate only after the direct structural surface is rich enough for a broader SystemVerilog reroute. |

## Decisions

- `2026-06-12`: Track broader direct SystemVerilog rerouting separately from
  the completed top state/standalone-DT generated-enable reroute so partial
  shipped behavior is not confused with full module rerouting.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
