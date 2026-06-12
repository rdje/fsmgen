# R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS: Direct Output Consumer Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Represent direct-root output-drive and always-block consumer connectivity in
`StructuralRTLIR` as structured data when a future selector proves the exact
first safe slice.

## Non-Goals

- Do not change behavior while this tree remains `proposed`.
- Do not claim direct port dependency connectivity, direct instances/links, or
  HDL rerouting through this owner.
- Do not change generated HDL or output-drive scheduling semantics unless a
  future activated implementation leaf explicitly owns that behavior.
- Do not use rendered HDL text as the durable connectivity source of truth.

## Acceptance Criteria

- A selector leaf identifies the first output-drive/always-block consumer
  family, structural schema, fixture set, and validation matrix before code
  changes.
- Any implementation leaf populates the selected consumer connectivity in a
  machine-readable shape and preserves existing generated HDL behavior unless
  the leaf explicitly owns output changes.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS`
  Status: `proposed`
  Goal: `Represent direct output-drive and always-block consumers in StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1`

- ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1`
  Status: `pending`
  Goal: `Select the first direct output consumer connectivity slice.`
  Acceptance: `The selector records source facts, target structural schema, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before any behavior-bearing output consumer connectivity change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | `pending` | Proposed owner only; activate only when the roadmap/PNT flow selects direct output consumer connectivity. |

## Decisions

- `2026-06-12`: Track output-drive and always-block consumers separately from
  port dependencies and HDL rerouting because they may require a wider direct
  lowered/structural handoff before they are safe to expose.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
