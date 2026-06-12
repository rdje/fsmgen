# R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY: Direct Structural Net Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Add machine-readable source/target connectivity to the direct
`StructuralRTLIR` surface so downstream consumers can inspect which structural
assignments, ports, and generated helper nets drive or consume each net without
parsing emitted HDL text.

## Non-Goals

- Do not change code while this tree remains `proposed`; an explicit active
  leaf must own any implementation slice.
- Do not reroute HDL emission through `StructuralRTLIR`; that is tracked by
  `R11-DIRECT-STRUCTURAL-HDL-REROUTING`.
- Do not parse arbitrary rendered HDL back into connectivity.
- Do not widen to direct instances, declared links, or resolved links unless a
  later activated leaf explicitly selects that scope.
- Do not remove the scalar `auxiliary_assignments[]` compatibility mirror.

## Acceptance Criteria

- Direct `StructuralRTLIR` has a documented, stable source/target connectivity
  schema for the selected first slice.
- The selected first slice connects generated enable assignment records to their
  driven nets and known source dependencies using structured identifiers.
- Focused direct structural tests prove the connectivity records are
  machine-readable and clone-isolated.
- Public contracts, mdBook, roadmap, Knowledge Map, and task-tree evidence are
  updated when an implementation leaf is activated.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`
  Status: `proposed`
  Goal: `Add direct StructuralRTLIR machine-readable source/target connectivity.`
  Children: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`
  Status: `pending`
  Goal: `Select the direct StructuralRTLIR source/target connectivity schema and first generated-enable connectivity slice.`
  Acceptance: `A readiness/selection slice records the exact connectivity schema, first generated-enable implementation boundary, validation plan, and documentation targets before any connectivity code changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | `pending` | Assignment records make generated enable drivers visible, but net source/target relationships still need a structural connectivity schema before implementation. |

## Decisions

- `2026-06-12`: Track direct net source/target connectivity as its own R11
  tree so it does not hide inside assignment-record work or HDL rerouting work.

## Open Questions

- None.

## Blockers

- This tree is proposed and not PNT-eligible until explicitly activated or
  selected after the current active frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed task tree.
