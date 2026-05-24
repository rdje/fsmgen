# R11-RTLIF-INTERFACE-SOURCE-DIRECTION: `.rtlif` Interface-Source Direction

## Metadata

- Tree ID: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Decide the next `.rtlif` contract direction before implementation: keep the
shipped `.rtlif` family as embedded-root plus sidecar metadata, or define a
stronger interface-source contract that sits above it.

## Non-Goals

- Do not change `.rtlif` parsing, lookup, metadata, generated HDL, or
  composition behavior in the activation leaf.
- Do not design the full portable type system, package/import system, or
  shared-datapath contract in this tree.
- Do not promote speculative interface syntax beyond evidence from shipped R11
  behavior.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any `.rtlif`
  behavior-bearing work.
- The decision leaf audits the shipped `.rtlif` surfaces, mdBook/book-facing
  claims, public contract surfaces, tests, and remaining R11 roadmap goals.
- The decision leaf records one concrete direction: keep `.rtlif` as the
  low-level interface metadata family for now, introduce a stronger
  interface-source contract, or explicitly defer because a prerequisite lane
  must land first.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`
  Status: `active`
  Goal: `Decide the .rtlif interface-source direction before implementation.`
  Children: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1`,
    `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2`

- ID: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1`
  Status: `done`
  Goal: `Activate the .rtlif interface-source direction task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering decision audit before any behavior-bearing .rtlif change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1: select rtlif direction`

- ID: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2`
  Status: `pending`
  Goal: `Audit shipped .rtlif behavior and decide whether a stronger interface-source contract is needed now.`
  Acceptance: `The audit records shipped evidence, current documentation truth, remaining gaps, and one implementation direction or deferral decision before any .rtlif behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2` | `pending` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` selected `.rtlif` interface-source direction as the next bounded R11 frontier, and a decision audit should happen before code. |

## Decisions

- `2026-05-24`: Select a narrow `.rtlif` interface-source direction tree after
  the R11 composition-contract audit passed. The next safe step is a decision
  audit because the existing `.rtlif` surface is already regression-backed as
  typed port metadata and embedded-root metadata, but the roadmap still asks
  whether a stronger interface-source contract should sit above it.

## Open Questions

- None. `.2` owns the evidence-gathering decision and may record a deferral if
  a stronger contract depends on a future type/package/interface lane.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1: select rtlif direction` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` `.rtlif` interface-source direction tree
  and selected `.2` as the evidence-gathering decision frontier.
