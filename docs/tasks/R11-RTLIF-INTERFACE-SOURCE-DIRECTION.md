# R11-RTLIF-INTERFACE-SOURCE-DIRECTION: `.rtlif` Interface-Source Direction

## Metadata

- Tree ID: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Audit shipped .rtlif behavior and decide whether a stronger interface-source contract is needed now.`
  Acceptance: `The audit records shipped evidence, current documentation truth, remaining gaps, and one implementation direction or deferral decision before any .rtlif behavior change.`
  Verification: `passed: focused .rtlif composition evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2: decide rtlif direction`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2` | `done` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` selected `.rtlif` interface-source direction as the next bounded R11 frontier, and a decision audit happened before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a narrow `.rtlif` interface-source direction tree after
  the R11 composition-contract audit passed. The next safe step is a decision
  audit because the existing `.rtlif` surface is already regression-backed as
  typed port metadata and embedded-root metadata, but the roadmap still asks
  whether a stronger interface-source contract should sit above it.
- `2026-05-24`: Keep `.rtlif` as the canonical low-level external-RTL
  interface metadata contract for now. It already has regression-backed
  sidecar and embedded roots, compact and verbose ports, `data` / `clock` /
  `reset` roles, semantic parameter/generic declarations, package-qualified
  defaults, per-instance overrides, diagnostics, failure summaries, and
  composition/IR propagation. Do not introduce a stronger interface-source
  language yet; that should wait for a concrete portable type, package/import,
  shared-datapath, or reusable-module requirement that cannot be represented
  honestly by the current `.rtlif` metadata layer.

## Open Questions

- None. `.2` owns the evidence-gathering decision and may record a deferral if
  a stronger contract depends on a future type/package/interface lane.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2` | `prove -Iperl t/88-rtlif-typed-port-contract.t t/89-composition-embedded-rtlif-roots.t t/117-composition-rtlif-metadata-diagnostics.t t/118-composition-rtlif-root-diagnostics.t t/119-composition-rtlif-type-diagnostics.t t/120-composition-rtlif-token-diagnostics.t t/121-composition-rtlif-width-diagnostics.t t/122-composition-rtlif-duplicate-port-diagnostics.t t/123-composition-rtlif-empty-port-diagnostics.t t/124-composition-rtlif-flatness-diagnostics.t t/125-composition-embedded-rtlif-duplicate-diagnostics.t t/255-composition-missing-rtl-metadata-diagnostic-context.t t/291-composition-rtl-child-source-shape-diagnostics.t`; `prove -Iperl t/272-composition-package-imports.t t/274-package-aggregate-values.t t/275-composition-top-aggregate-values.t t/292-composition-generated-child-parameter-overrides.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: .rtlif suite Files=13, Tests=68; parameter/package suite Files=4, Tests=21; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1: select rtlif direction` | `selection slice` |
| `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2` | `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2: decide rtlif direction` | `audit and documentation truth-sync slice` |

## Changelog

- `2026-05-24`: Created active `R11` `.rtlif` interface-source direction tree
  and selected `.2` as the evidence-gathering decision frontier.
- `2026-05-24`: Completed `.2`, kept `.rtlif` as the canonical low-level
  external-RTL interface metadata contract, and deferred any stronger
  interface-source language until a concrete future type/package/reuse need
  justifies it.
