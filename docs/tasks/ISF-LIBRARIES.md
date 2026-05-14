# ISF-LIBRARIES: Reusable ISF Libraries And Imports

## Metadata

- Tree ID: `ISF-LIBRARIES`
- Status: `proposed`
- Roadmap lane: `R14 backlog`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Add a user-facing ISF library system so tested reusable ISF descriptions can be
authored once, imported into scope, specialized, and used by downstream designs
without rewriting common actors or transaction patterns.

The public term is **library**. The implementation may reuse or extend
FSMGen's existing package/import infrastructure where that is the right fit,
but the user-facing feature must make it clear that ISF libraries can contain
reusable ISF design intent, not only scalar constants or types.

## Non-Goals

- Do not implement textual includes or copy/paste macro expansion.
- Do not treat parser acceptance of a library form as a support claim before
  lowering, diagnostics, and regression coverage exist.
- Do not make a FIFO a transaction-only abstraction; a FIFO owns persistent
  storage and interface behavior.
- Do not freeze the final import syntax in this proposed tree before the first
  specification leaf compares it against existing `+import` and package
  behavior.

## Acceptance Criteria

- The ISF library source model is specified: file/root shape, exported symbols,
  namespace rules, import syntax, search roots, and duplicate-name diagnostics.
- Reusable actor and transaction definitions have a clear specialization model
  for widths, depths, reset policy, interface mapping, and generated names.
- A FIFO is modeled as a reusable actor with persistent storage, pointers,
  occupancy/full/empty behavior, and operations that may be represented as
  transactions or named callable entry points.
- Library imports lower through reviewable scheduled `.fsm` artifacts or fail
  closed with targeted diagnostics.
- Public contract metadata, schedule-report visibility, mdBook, live docs, and
  focused regressions are synchronized when implementation starts.

## Task Tree

- ID: `ISF-LIBRARIES`
  Status: `proposed`
  Goal: `Specify and eventually implement reusable ISF libraries and imports.`
  Children: `ISF-LIBRARIES.1`, `ISF-LIBRARIES.2`, `ISF-LIBRARIES.3`,
  `ISF-LIBRARIES.4`, `ISF-LIBRARIES.5`

- ID: `ISF-LIBRARIES.1`
  Status: `proposed`
  Goal: `Specify the public ISF library/import model.`
  Acceptance: `The task tree and mdBook define user-facing library terms,
  source/root shapes, exported definition kinds, namespace/import rules,
  relation to existing packages/imports, and fail-closed diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.2`
  Status: `proposed`
  Goal: `Specify specialization and binding for reusable ISF definitions.`
  Acceptance: `Widths, depths, reset policy, interface mapping, parameter
  override domains, generated names, and report provenance have a bounded
  public contract.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.3`
  Status: `proposed`
  Goal: `Implement import resolution for reusable ISF libraries.`
  Acceptance: `The parser/lowerer can resolve imported reusable definitions
  from configured search roots, rejects ambiguous or missing definitions, and
  preserves provenance in scheduled artifacts and reports.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.4`
  Status: `proposed`
  Goal: `Ship the first reusable FIFO library fixture.`
  Acceptance: `A parameterized FIFO actor library fixture can be imported,
  specialized, lowered to scheduled `.fsm`, and generated to HDL with focused
  assertions for storage, enqueue/dequeue behavior, full/empty flags, and
  reset behavior.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.5`
  Status: `proposed`
  Goal: `Synchronize public contract, docs, and library catalog metadata.`
  Acceptance: `The public contract advertises the shipped library/import
  surface and the library catalog lists shipped reusable definitions with
  status, parameters, tests, and limitations.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. It is not PNT-eligible until the active
roadmap lane selects ISF library work or the user explicitly activates it.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LIBRARIES.1` | `proposed` | The first step must define the public source model before parser or lowering work starts. |

## Design Notes

- A FIFO should be captured as an ISF actor because it owns state across
  cycles: storage array, write pointer, read pointer, occupancy, flags, and
  reset behavior. Enqueue, dequeue, flush, or status-probe behaviors may be
  transactions or callable operations on that actor.
- A library should be reusable source intent, not generated HDL pasted into a
  design. The imported definition should still lower through scheduled `.fsm`
  so users can inspect the exact cycle-level artifact.
- Libraries should support generic reusable definitions. A FIFO library is only
  useful if callers can specialize at least width, depth, reset policy, and
  interface binding without editing the library source.
- The feature should reuse existing package/search-root concepts where they
  fit, but existing semantic `?pkg` packages do not by themselves cover
  reusable ISF actors or transactions.
- A shipped library catalog should grow cautiously. Each entry needs source
  shape, parameter contract, lowering semantics, tests, and known limitations.

## Decisions

- `2026-05-14`: Use **library** as the user-facing term for reusable ISF
  design-intent collections. Internal implementation may still use packages or
  package-like resolution.
- `2026-05-14`: Model FIFO as an actor first. Transactions can describe
  operations against the FIFO actor, but they do not own the persistent FIFO
  storage by themselves.
- `2026-05-14`: The first useful implementation target is a parameterized FIFO
  actor because it exercises reusable storage, interface binding, reset
  behavior, generated scheduled `.fsm` review, and HDL reachability.

## Open Questions

- Which public syntax should import reusable ISF libraries without confusing
  them with existing `+import` semantic packages?
- Should imported library definitions be referenced by namespace every time, or
  can authors choose explicit local aliases?
- Which reusable definition kinds ship first: actors only, or actors plus
  transaction templates inside actors?

## Blockers

- None while the tree is proposed. Implementation is blocked until
  `ISF-LIBRARIES.1` specifies the public model.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-LIBRARIES` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARIES` | `R14: log proposed ISF library support` | Proposed tree created from the FIFO/library design discussion. |

## Changelog

- `2026-05-14`: Created the proposed ISF libraries/imports task tree.
