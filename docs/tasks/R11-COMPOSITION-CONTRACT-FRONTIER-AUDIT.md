# R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT: Composition Contract Frontier Audit

## Metadata

- Tree ID: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Audit the current R11 frontier and choose the next bounded composition-contract slice.`
  Acceptance: `The audit records current evidence, remaining gaps, and one next action or deferral decision before any implementation begins.`
  Verification: `passed: focused R11 composition evidence sweep, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2: audit R11 frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` | `done` | `R10` is mostly done, and `R11` has several broad remaining deliverable families; an evidence-gathering audit selected one safe bounded composition-contract slice before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select an R11 frontier audit after the R10 exit audit moved
  diagnostics/provenance to `mostly done`. The R11 roadmap remains broad, so
  the next safe step is to map shipped coverage and select one bounded slice.
- `2026-05-24`: The R11 evidence sweep passed across the shipped composition
  parser, `.rtlif`, standalone-DT, explicit-wiring, connect-by-name,
  generated-child, shared-datapath, assertion, runtime-HDL, and forward-IR
  surfaces. The next bounded R11 slice should be a new
  `R11-RTLIF-INTERFACE-SOURCE-DIRECTION` task tree that decides whether the
  shipped `.rtlif` family remains embedded-root plus sidecar metadata or
  whether a stronger interface-source contract should sit above it. That
  decision slice must happen before any `.rtlif` behavior change.

## Open Questions

- None. `.2` owns the R11 evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` | `prove -Iperl t/14-composition-parser.t t/82-standalone-dt-root-support.t t/83-reusable-source-path-resolution.t t/84-composition-external-fsm-child-sources.t t/85-composition-standalone-dt-children.t t/88-rtlif-typed-port-contract.t t/89-composition-embedded-rtlif-roots.t t/90-composition-single-rtl-child.t t/91-composition-multi-rtl-children.t t/92-composition-multi-rtl-connect-by-name.t t/93-composition-multi-generated-plus-rtl-children.t t/94-composition-multi-generated-plus-rtl-connect-by-name.t t/95-composition-connect-by-name-input-fanout.t t/139-composition-shared-datapath-candidate-metadata.t t/145-composition-shared-datapath-runtime-hdl.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/148-composition-shared-datapath-mixed-reexport-runtime.t t/149-composition-shared-datapath-combinational-runtime.t t/150-composition-shared-datapath-combinational-internal-runtime.t t/151-composition-shared-datapath-assertion-runtime-hdl.t t/152-composition-shared-datapath-public-fanout-register-runtime.t t/153-composition-shared-datapath-combinational-public-fanout-runtime.t t/154-standalone-dt-assertion-runtime-hdl.t t/160-composition-top-forward-ir-surface.t t/162-composition-top-structural-rtl-ir-surface.t t/165-composition-child-forward-ir-exports.t` | `passed: Files=27, Tests=175` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1: select R11 frontier audit` | `selection slice` |
| `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` | `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2: audit R11 frontier` | `audit slice; selected the .rtlif interface-source direction tree as the next R11 frontier` |

## Changelog

- `2026-05-24`: Created active `R11` composition-contract frontier audit tree
  and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, closed the tree, and selected a future
  `R11-RTLIF-INTERFACE-SOURCE-DIRECTION` tree before any `.rtlif`
  contract-change implementation.
