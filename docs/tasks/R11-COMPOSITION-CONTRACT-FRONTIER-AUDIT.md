# R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT: Composition Contract Frontier Audit

## Metadata

- Tree ID: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current `R11` composition-contract frontier and select the next
bounded implementation or documentation truth-sync slice from evidence.

## Non-Goals

- Do not implement broad implicit composition.
- Do not change `.rtlif`, shared-datapath, reusable module, standalone-DT,
  package/import, or type behavior during the audit selection leaf.
- Do not start code before the audit selects a concrete task-tree-owned leaf.
- Do not widen user-facing composition claims beyond what tests and mdBook
  already prove.

## Acceptance Criteria

- The audit maps current `R11` shipped coverage and remaining roadmap
  objectives across `.rtlif`, generated-child composition, explicit wiring,
  shared-datapath direction, standalone-DT/reusable module direction,
  composition policy ownership, and adjacent package/type surfaces.
- The audit selects one bounded next slice or explicitly defers R11 until a
  later roadmap lane owns the prerequisite.
- mdBook/live docs are synchronized if user-facing status or composition
  claims change.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 composition-contract frontier and select the next bounded slice.`
  Children: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the R11 composition-contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any behavior-bearing composition change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1: select R11 frontier audit`

- ID: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit the current R11 frontier and choose the next bounded composition-contract slice.`
  Acceptance: `The audit records current evidence, remaining gaps, and one next action or deferral decision before any implementation begins.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` | `pending` | `R10` is mostly done, and `R11` has several broad remaining deliverable families; an evidence-gathering audit should select one safe bounded composition-contract slice before code. |

## Decisions

- `2026-05-24`: Select an R11 frontier audit after the R10 exit audit moved
  diagnostics/provenance to `mostly done`. The R11 roadmap remains broad, so
  the next safe step is to map shipped coverage and select one bounded slice.

## Open Questions

- None. `.2` owns the R11 evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1: select R11 frontier audit` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` composition-contract frontier audit tree
  and selected `.2` as the evidence-gathering frontier.
