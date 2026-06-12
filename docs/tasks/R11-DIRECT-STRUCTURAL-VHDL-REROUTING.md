# R11-DIRECT-STRUCTURAL-VHDL-REROUTING: Direct VHDL Rerouting Through StructuralRTLIR

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute selected direct VHDL emission through `StructuralRTLIR` once the direct
structural surface and VHDL validation environment are sufficient for a safe
slice.

## Non-Goals

- Do not change behavior while this tree remains `proposed`.
- Do not include broader SystemVerilog rerouting; that has a separate proposed
  owner.
- Do not claim full aggregate record/array VHDL support or GHDL validation
  availability.
- Do not use raw HDL-string parsing as the rerouting contract.

## Acceptance Criteria

- A selector/readiness leaf identifies the exact direct VHDL reroute target,
  required structural prerequisites, and validation limits before code changes.
- Any implementation leaf emits only the selected VHDL portion from
  `StructuralRTLIR` and preserves existing supported behavior.
- Focused VHDL/backend tests plus available broader gates prove no unintended
  output drift; GHDL-dependent claims remain blocked unless the tool is
  available.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING`
  Status: `proposed`
  Goal: `Reroute selected direct VHDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1`

- ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1`
  Status: `pending`
  Goal: `Select the first direct VHDL StructuralRTLIR reroute target.`
  Acceptance: `The selector records current VHDL coverage, missing structural prerequisites, first safe VHDL target, focused fixtures, validation gates including GHDL availability status, rollback boundary, and docs/contracts to update before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | `pending` | Proposed owner only; activate only when roadmap/PNT selects direct VHDL rerouting and its validation limits are understood. |

## Decisions

- `2026-06-12`: Track direct VHDL rerouting separately from SystemVerilog
  rerouting because VHDL support and external GHDL validation have distinct
  prerequisites and risk.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
