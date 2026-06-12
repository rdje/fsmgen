# R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY: Direct Port Dependency Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY`
- Status: `proposed`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Represent direct-root port dependency connectivity in `StructuralRTLIR` with a
machine-readable structural contract when a future selector proves the exact
first safe slice.

## Non-Goals

- Do not change behavior while this tree remains `proposed`.
- Do not claim generated-enable assignment-record source/target connectivity;
  that shipped under `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`.
- Do not include output-drive/always-block consumers, direct instances/links,
  full direct module rerouting, or VHDL rerouting unless a later activated leaf
  explicitly widens this tree.
- Do not use raw HDL-string parsing as the connectivity contract.

## Acceptance Criteria

- A selector leaf identifies the exact direct port dependency family, schema,
  fixtures, and validation matrix before code changes.
- Any implementation leaf populates the selected connectivity as structured
  data and keeps compatibility surfaces stable unless a compatibility-specific
  owner approves a change.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY`
  Status: `proposed`
  Goal: `Represent direct port dependency connectivity in StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1`

- ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1`
  Status: `pending`
  Goal: `Select the first direct port dependency connectivity slice.`
  Acceptance: `The selector records source facts, target structural schema, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before any behavior-bearing direct port dependency connectivity change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | `pending` | Proposed owner only; activate only when the roadmap/PNT flow selects direct port dependency connectivity. |

## Decisions

- `2026-06-12`: Track direct port dependency connectivity separately from
  generated-enable net source/target connectivity and output-drive consumers
  so the future schema can stay reviewable and machine-readable.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
