# ISF-TYPE-AGGREGATE-PARITY: ISF Enum, Type, And Aggregate Parity

## Metadata

- Tree ID: `ISF-TYPE-AGGREGATE-PARITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Let ISF reuse the enum, type-alias, and aggregate semantics already shipped for
`.fsm` direct roots, composition tops, and packages, without inventing a second
ISF-only type system.

## Non-Goals

- Do not create a parallel ISF type engine.
- Do not hide enum or aggregate meaning in backend-only structures that are
  absent from the lowered `.fsm` review artifacts.
- Do not ship broad inference-first aggregate growth before the declared-anchor
  and lowering contracts are explicit.
- Do not widen VHDL aggregate lowering in this tree.
- Do not treat schedule-report private parser/lowering internals as public API.

## Acceptance Criteria

- The ISF type/enum/aggregate source boundary is explicitly documented and
  synchronized across the spec, downstream handoff, mdBook, public contract
  notes, task tree, and live docs.
- ISF accepts only source forms whose meaning can be resolved through the
  existing `.fsm` package/type/symbol machinery or a documented adapter around
  that machinery.
- Accepted ISF enum/type/aggregate source lowers to reviewable scheduled `.fsm`
  text that uses the established `.fsm` declaration and aggregate semantics.
- Diagnostics reject unknown types, unresolved enum members, incompatible enum
  values, aggregate shape mismatches, and ambiguous partial updates before HDL
  generation.
- Schedule reports expose only bounded public summaries for any new accepted
  source, with public contract metadata and focused coverage updated in the
  same slice.
- Each completed leaf is validated, documented, and committed through
  [COMMIT.md](../../COMMIT.md).

## Task Tree

- ID: `ISF-TYPE-AGGREGATE-PARITY`
  Status: `active`
  Goal: `close the ISF enum/type/aggregate parity gap against the existing .fsm semantic machinery`
  Children: `ISF-TYPE-AGGREGATE-PARITY.1`, `ISF-TYPE-AGGREGATE-PARITY.2`, `ISF-TYPE-AGGREGATE-PARITY.3`, `ISF-TYPE-AGGREGATE-PARITY.4`

- ID: `ISF-TYPE-AGGREGATE-PARITY.1`
  Status: `done`
  Goal: `inventory current .fsm enum/type/aggregate support and the shipped ISF gap, then pin the first safe boundary`
  Acceptance: `task tree, spec, downstream handoff, mdBook backlog, public contract notes, and live docs state the current gap and first boundary without implying parser support that does not exist`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending`

- ID: `ISF-TYPE-AGGREGATE-PARITY.2`
  Status: `pending`
  Goal: `specify the ISF symbol-source contract for enum/type declarations and imports before parser widening`
  Acceptance: `source forms, import/source resolution, reuse of existing package/type machinery, diagnostics, lowered .fsm projection, schedule-report scope, and downstream impact are documented with focused acceptance tests identified`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-TYPE-AGGREGATE-PARITY.3`
  Status: `pending`
  Goal: `implement the first scalar type-alias reference path for ISF width-bearing declarations`
  Acceptance: `the parser/lowerer can resolve a documented scalar type alias through the selected symbol source and emit reviewable .fsm that preserves the established .fsm type semantics; unknown or aggregate aliases fail closed in this scalar-only slice`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-TYPE-AGGREGATE-PARITY.4`
  Status: `pending`
  Goal: `extend the implemented path to one declared aggregate carrier only after scalar alias resolution is stable`
  Acceptance: `one declared aggregate actor/interface or storage carrier lowers through reviewable .fsm with shape checks, focused tests, and bounded schedule-report visibility; partial aggregate updates remain deferred unless explicitly specified`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TYPE-AGGREGATE-PARITY.2` | `pending` | Source syntax and symbol resolution must be fixed before accepting any new parser forms. |

## Decisions

- `2026-05-16`: The first committed slice is an inventory and boundary slice.
  Existing `.fsm` already ships package-backed constants, enum families,
  scalar type aliases, packed list/record aliases, declared aggregate signal
  access, partial aggregate LHS writes, and shape checks on the live
  SystemVerilog paths. Current ISF accepts scalar width evidence for ports and
  actor-owned storage, numeric/exact-width parameter values, actor-local
  constants for selected static specialization values, and compatible
  aggregate/list literal parameter values, but it does not yet accept enum or
  type declarations, typed width tokens, or typed aggregate carrier/update
  semantics. The next leaf must specify the symbol-source contract before
  implementation.
- `2026-05-16`: ISF parity must reuse existing `.fsm` semantic machinery or a
  documented adapter around it. A second ISF-only type system is rejected.
- `2026-05-16`: Lowered scheduled `.fsm` remains the review artifact and
  contract. Any accepted enum/type/aggregate ISF source must be visible there
  rather than only in private lowerer data.

## Open Questions

- Which exact source form should carry ISF enum/type declarations or package
  references? This blocks parser widening and is owned by
  `ISF-TYPE-AGGREGATE-PARITY.2`.
- Should the first implemented path reference only scalar aliases, or also
  enum values in guards/assignments? This does not block the inventory slice
  but must be answered before implementation.

## Blockers

- None for the current frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-TYPE-AGGREGATE-PARITY.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TYPE-AGGREGATE-PARITY.1` | `ISF-TYPE-AGGREGATE-PARITY.1: inventory parity boundary` | `Inventory and first-boundary documentation slice.` |

## Changelog

- `2026-05-16`: Created the active task tree and completed the inventory
  content for `ISF-TYPE-AGGREGATE-PARITY.1`.
