# R14-ASPECT-COVERAGE-AUDIT: Confirm Every R14 ISF Aspect Is Task-Tree Owned

## Metadata

- Tree ID: `R14-ASPECT-COVERAGE-AUDIT`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Per the user directive to "ensure all R14 aspects have been captured
as task-trees — tracked and owned", audit every Intent Scheduling
Format (ISF) backlog aspect in
`docs/book/src/14-feature-backlog.md` against the
[R14 ISF Objective Coverage](../TASK_TREE.md) table and the
`docs/tasks/*.md` set, and close any genuine ownership gap by
registering a Proposed task tree.

## Audit result (2026-05-29)

The ISF backlog chapter (`## Intent Scheduling Format`) has 21 `###`
sub-sections. Cross-referencing each against the R14 ISF Objective
Coverage table:

| ISF backlog aspect | Owning tree(s) | Gap? |
| --- | --- | --- |
| Actor Network Orchestration | `ISF-ACTOR-NETWORK-ORCHESTRATION`, `ISF-ATL-*` | owned |
| IAL2 Protocol And Platform Intent Exploration | — (see note) | non-R14 exploration |
| ISF Enum, Type, And Aggregate Parity | `ISF-TYPE-AGGREGATE-PARITY` | owned |
| ISF Scalar Setter Syntax Unification | `ISF-SETTER-SYNTAX` | owned |
| Enforced Resource Arbitration | `ISF-RESOURCE-PRIORITY`, `ISF-RESOURCE-CATALOG`, `ISF-*-ROUND-ROBIN` | owned |
| Priority Resolution | `ISF-RESOURCE-PRIORITY`, `ISF-TRANSACTION-OVER-RULE-PRIORITY` | owned |
| Expression-Valued Rule Assignments | `ISF-RULE-ACTIONS` | owned |
| Transaction Stage Lowering | `ISF-STAGES-CONTRACTS` | owned |
| Transaction Unconditional Wait | `ISF-CONTROL-FLOW`, `ISF-WAIT-ZERO`, `ISF-DYNAMIC-WAIT*`, `ISF-PARAM-WAIT-COUNTS`, `ISF-WAIT-PACKAGE-CONSTANT-COUNTS` | owned |
| Transaction Dynamic Loops | `ISF-CONTROL-FLOW`, `ISF-REPEAT-*`, `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`, `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION` | owned (broader loop-contained/deeper-nested lowering recorded as future leaves of those trees) |
| Transaction Ports And Actor Pin Access | `ISF-PORT-BINDING`, `ISF-TRANSACTION-PORT-*` | owned |
| Temporal Contract Lowering | `ISF-STAGES-CONTRACTS`, `ISF-CONTRACT-*` | owned |
| Legacy Handshake Semantics | `ISF-COMPATIBILITY` | owned |
| Removed Assign Keyword | `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC`, `ISF-COMPATIBILITY` | owned |
| Full Width Inference For Data Operations | `ISF-DATA-WIDTHS`, `ISF-*-WIDTH-INFERENCE` (bounded) | **gap: no forward tree for remaining cases** |
| Richer Schedule-Report Storage Classes | `ISF-SCHEDULE-REPORTS`, `ISF-*-STORAGE-REPORTS` | owned |
| Fully Frozen Schedule JSON Schema | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE` | owned |
| ISF Realistic Fixture Matrix | `ISF-FIXTURES`, `ISF-*-FIXTURE-PROMOTION` | owned |
| ISF Reusable Libraries | `ISF-LIBRARIES`, `ISF-LIBRARY-*` | owned |
| ISF Multi-Clock And CDC Semantics | `ISF-CLOCK-DOMAINS`, `ISF-CDC-FIXTURE-MATRIX`, `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION` | owned (richer CDC primitives recorded as backlog) |

Conclusion: **all ongoing/unresolved R14 ISF aspects are task-tree
owned**, except the two cases below, which this slice resolves.

### Gap 1: Full Width Inference For Data Operations

The shipped width-inference surface (`ISF-DATA-WIDTHS`,
`ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE`,
`ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE`) infers exactly one
missing field/part. The remaining backlog (`extract`/`assemble`
with two or more unknown fields/parts; inference in additional
contexts) has no dedicated forward tree. Resolved by registering the
Proposed tree `ISF-FULL-WIDTH-INFERENCE`. Note: two-or-more-unknown
inference is fundamentally underdetermined (N unknowns, one width
equation), so the honest forward boundary is mostly "remain
fail-closed"; the proposed tree records that the aspect is owned and
will be activated only if a decidable sub-case is identified.

### Gap 2: IAL2 Protocol And Platform Intent Exploration

This aspect is, by the roadmap's own definition, **not an R14
implementation lane**. R14 is IAL1 (explicit `.isf` actor/network
authoring). The backlog text and `ROADMAP_V2.md` R14 section state
the model "becomes IAL2 only if the source model moves above explicit
actor/network syntax into protocol/platform intent inference", and
horizon item H4 assigns protocol-spec intent capture to SPECFORGE.
It is therefore tracked as an explicit non-R14 exploration in
`14-feature-backlog.md`, `ROADMAP_V2.md`, and
`docs/INTENT_SCHEDULING_BRAINSTORM.md`, and intentionally does **not**
get an R14 implementation task tree. This audit records that decision
rather than fabricating an R14 tree for horizon work.

## Non-Goals

- Do not activate or implement the registered Proposed tree in this
  slice. Proposed trees are not PNT-eligible until activated.
- No code/test/behavior change. Documentation/tracking only.

## Acceptance Criteria

- `ISF-FULL-WIDTH-INFERENCE` Proposed tree registered in
  `docs/TASK_TREE.md` Proposed section with a stub task file.
- The IAL2 non-R14 exploration decision is recorded in this audit and
  the R14 coverage section.
- t/1305 book-feature-matrix audit still passes (backlog categories
  and owner coverage unchanged in shape).
- mdBook builds clean; `git diff --check` clean; live docs synced.
- Committed via `COMMIT.md`.

## Task Tree

- ID: `R14-ASPECT-COVERAGE-AUDIT`
  Status: `done`
  Goal: `Confirm/close R14 ISF aspect task-tree ownership.`
  Children: `R14-ASPECT-COVERAGE-AUDIT.1`

- ID: `R14-ASPECT-COVERAGE-AUDIT.1`
  Status: `done`
  Goal: `Publish the coverage audit; register the ISF-FULL-WIDTH-INFERENCE Proposed tree; record the IAL2 non-R14 decision.`
  Acceptance: `Audit table published; Proposed tree registered; audits green.`
  Verification: `prove -Iperl t/1305; mdbook build docs/book; git diff --check`
  Commit: `done`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R14-ASPECT-COVERAGE-AUDIT.1` | `done` | Single doc-only leaf closing the R14 ownership precondition. |

## Decisions

- `2026-05-29`: R14 is already overwhelmingly task-tree owned via the
  R14 ISF Objective Coverage table. Rather than fabricate stub trees
  for every conceivable broader extension (which the workflow forbids
  as implementation-permission inflation), register only the one
  genuine forward gap and record the IAL2 horizon decision honestly.

## Open Questions / Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `R14-ASPECT-COVERAGE-AUDIT.1` | `prove -Iperl t/1305` (Files=1, Tests=405); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R14-ASPECT-COVERAGE-AUDIT.1` | `R14-ASPECT-COVERAGE-AUDIT.1: audit + close R14 task-tree ownership` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created to satisfy the user precondition that all R14
  aspects be task-tree owned before resuming implementation PNT.
