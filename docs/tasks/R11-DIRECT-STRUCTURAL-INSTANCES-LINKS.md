# R11-DIRECT-STRUCTURAL-INSTANCES-LINKS: Direct Instances And Links

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Audit and, when selected, represent any direct-root instance/link structural
surface in `StructuralRTLIR` without conflating it with composition-top
instances and links.

## Non-Goals

- Do not change behavior while this tree remains `proposed`.
- Do not widen composition-top `instances[]`, `declared_links[]`, or
  `resolved_links[]`; those already have their own structural contracts.
- Do not invent direct instances/links if the selector proves the current
  direct-root model should keep those arrays empty.
- Do not reroute HDL emission or alter generated-child realization under this
  owner unless a later activated leaf explicitly selects that scope.

## Acceptance Criteria

- A selector leaf determines whether direct roots have a real instance/link
  structural surface to expose or should remain explicitly empty.
- Any implementation leaf, if selected, exposes only the chosen direct
  instance/link schema with focused tests and stable public contracts.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS`
  Status: `proposed`
  Goal: `Own the direct-root instances/links StructuralRTLIR question.`
  Children: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`

- ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`
  Status: `pending`
  Goal: `Select the direct instances/links contract.`
  Acceptance: `The selector records current direct-root instance/link facts, whether implementation is warranted, the exact schema if warranted, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | `pending` | Proposed owner only; activate only when the roadmap/PNT flow selects the direct instances/links question. |

## Decisions

- `2026-06-12`: Track direct instances/links as an explicit question rather
  than assuming composition-top structural arrays should automatically apply to
  direct roots.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
