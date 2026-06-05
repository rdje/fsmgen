# COMPOSITION-TYPE-BACKLOG-EXHAUSTION: Composition And Type Backlog Exhaustion

## Metadata

- Tree ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
- Status: `active`
- Roadmap lane: `Composition` / `Aggregate Types And Data`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Exhaust the combined Composition/type backlog by selecting and completing
bounded, reviewable leaves until no executable Composition/type backlog item
remains or a real prerequisite blocker is reached.

## Non-Goals

- Do not treat this broad tree as permission to change behavior without a
  selected executable leaf.
- Do not widen public composition, type, aggregate, or VHDL contracts without
  synchronized mdBook/public documentation and focused regression coverage.
- Do not bypass the existing R11/R14 audit evidence; use it as the starting
  boundary for each selected leaf.

## Acceptance Criteria

- Every Composition/type backlog item named in the remaining-work inventory is
  represented as a leaf or explicit deferral/blocker.
- The current frontier always points to one executable next leaf.
- Each behavior-bearing leaf updates source, tests, public docs/mdBook, and
  downstream-visible contracts as warranted.
- Focused validation passes for each leaf; broader gates run when the blast
  radius warrants them.
- Each completed leaf is committed through `COMMIT.md` before selecting the
  next one.

## Task Tree

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
  Status: `active`
  Goal: `Exhaust the Composition/type backlog through bounded task-scoped leaves.`
  Children: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`
  Status: `done`
  Goal: `Activate the Composition/type backlog tree and inventory the named leaves.`
  Acceptance: `The tree exists, is active in docs/TASK_TREE.md, and lists every Composition/type item from the remaining-work inventory.`
  Verification: `passed: memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`
  Status: `pending`
  Goal: `Select the first executable Composition/type implementation or deferral leaf from evidence.`
  Acceptance: `Existing R11/R14 audit evidence and the mdBook backlog are reviewed, one bounded next behavior/doc/test slice is selected, and the selected leaf is either made executable in this tree or explicitly deferred with a prerequisite.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`
  Status: `pending`
  Goal: `Broaden the shared-datapath route/storage/protocol contract where one exact contract can be proven.`
  Acceptance: `One specific route, storage, protocol, contributor, or lifting rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`
  Status: `pending`
  Goal: `Broaden reusable standalone-DT module interface/export or lookup surfaces.`
  Acceptance: `One exact reusable-module, lookup, package/import, enable-control, or debug-reporting contract is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`
  Status: `pending`
  Goal: `Evaluate top-boundary convention widening and hidden child-to-child/public re-export policy.`
  Acceptance: `One exact convention widening, re-export, conflict, interface-bundle, or protocol-group rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`
  Status: `pending`
  Goal: `Broaden generated-child top instantiation beyond the shipped spawn and parameterized blocking-do patterns.`
  Acceptance: `One exact generated-child top surface is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`
  Status: `pending`
  Goal: `Broaden spawn/blocking-do parameter and value binding surfaces.`
  Acceptance: `One exact static value, parameter, binding, package, aggregate, or specialization rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`
  Status: `pending`
  Goal: `Close remaining repeat-body child-activation variants that intersect Composition/type behavior.`
  Acceptance: `One exact undrained, multi-pending, cross-domain, nested, or binding-related repeat-body child-activation variant is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`
  Status: `pending`
  Goal: `Select and implement or defer the next portable type-core contract.`
  Acceptance: `One exact enum-as-type, fixed-array, array-of-record, signedness/state-model, inference, or backend-neutral type contract is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`
  Status: `pending`
  Goal: `Broaden aggregate member/index autogrowth from partial use.`
  Acceptance: `One exact member/index autogrowth proof surface is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`
  Status: `pending`
  Goal: `Broaden aggregate runtime operators and subaggregate operand support.`
  Acceptance: `One exact aggregate operator, runtime expression position, scalar/aggregate mixing rule, or mismatch rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`
  Status: `pending`
  Goal: `Broaden backend-owned struct/record default lowering policy.`
  Acceptance: `One exact aggregate-like value class is selected for backend-owned lowering or explicit fail-closed deferral, with docs and regression coverage.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`
  Status: `pending`
  Goal: `Track VHDL aggregate lowering and VHDL generic-map lowering prerequisites.`
  Acceptance: `The VHDL-backed Composition/type work is either activated under a VHDL backend owner or explicitly blocked behind that prerequisite with the book and task tree synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` | `pending` | The broad backlog is active, but the next code-bearing slice must be selected from evidence before implementation starts. |

## Evidence To Reuse

- `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
- `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
- `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
- `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
- `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
- `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
- `AGGREGATE-AUTOGROWTH-FROM-USAGE`
- `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
- `RICHER-AGGREGATE-OPERATORS`
- `ISF-SPAWN-IN-REPEAT` and later repeat-body child-activation trees

## Decisions

- `2026-06-05`: Activate this tree as the user-selected focus after the
  remaining-work inventory. It owns the combined Composition/type bullet until
  exhaustion.
- `2026-06-05`: Start with an evidence-led selection leaf because the shipped
  R11 audit trees explicitly deferred new implementation until a precise
  route/storage/protocol, reusable-module, portable-type, VHDL, or architecture
  contract is selected.

## Open Questions

- Which exact leaf is first: owned by `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`
  and not blocking that evidence selection.

## Blockers

- VHDL aggregate and generic-map lowering remain blocked until the full VHDL
  backend/composition target is active enough to validate generated behavior.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners` | `activated by the remaining-work ownership slice` |

## Changelog

- `2026-06-05`: Created active Composition/type backlog exhaustion tree.
