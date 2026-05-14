# ISF-LIBRARIES: Reusable ISF Libraries And Imports

## Metadata

- Tree ID: `ISF-LIBRARIES`
- Status: `active`
- Roadmap lane: `R14`
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
  Status: `active`
  Goal: `Specify and eventually implement reusable ISF libraries and imports.`
  Children: `ISF-LIBRARIES.1`, `ISF-LIBRARIES.2`, `ISF-LIBRARIES.3`,
  `ISF-LIBRARIES.4`, `ISF-LIBRARIES.5`

- ID: `ISF-LIBRARIES.1`
  Status: `done`
  Goal: `Specify the public ISF library/import model.`
  Acceptance: `The task tree and mdBook define user-facing library terms,
  source/root shapes, exported definition kinds, namespace/import rules,
  relation to existing packages/imports, and fail-closed diagnostics.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-LIBRARIES.1: specify library import model`

- ID: `ISF-LIBRARIES.2`
  Status: `pending`
  Goal: `Specify specialization and binding for reusable ISF definitions.`
  Acceptance: `Widths, depths, reset policy, interface mapping, parameter
  override domains, generated names, and report provenance have a bounded
  public contract.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.3`
  Status: `pending`
  Goal: `Implement import resolution for reusable ISF libraries.`
  Acceptance: `The parser/lowerer can resolve imported reusable definitions
  from configured search roots, rejects ambiguous or missing definitions, and
  preserves provenance in scheduled artifacts and reports.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.4`
  Status: `pending`
  Goal: `Ship the first reusable FIFO library fixture.`
  Acceptance: `A parameterized FIFO actor library fixture can be imported,
  specialized, lowered to scheduled `.fsm`, and generated to HDL with focused
  assertions for storage, enqueue/dequeue behavior, full/empty flags, and
  reset behavior.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.5`
  Status: `pending`
  Goal: `Synchronize public contract, docs, and library catalog metadata.`
  Acceptance: `The public contract advertises the shipped library/import
  surface and the library catalog lists shipped reusable definitions with
  status, parameters, tests, and limitations.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LIBRARIES.2` | `pending` | The public source model is selected; specialization and binding must be bounded before parser/lowerer implementation starts. |

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

## ISF-LIBRARIES.1 Public Library / Import Model

Public terminology:

- The user-facing term is **library**.
- Internal code may reuse existing package/search-root machinery, but public
  docs should not call reusable actors "packages" unless they are referring to
  the existing scalar/type `?pkg` system.
- Existing `.fsm`/composition `+import` and semantic `?pkg` packages remain
  scoped to constants, enums, types, and package-backed values. ISF libraries
  are a separate source-intent surface for reusable actors and transaction
  patterns.

Planned source roots:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Rules:

- A `.isf` source root may be an `(actor ...)` root, as today, or a planned
  `(library name ...)` root once the feature ships.
- A library name is a non-empty HDL-identifier-compatible dotted namespace such
  as `common.fifo` or `vendor.ip.fifo`.
- A library body may contain exported reusable definitions and private helper
  definitions.
- The first implementation target is exported actors. Standalone reusable
  transaction templates remain planned but should not ship until their binding
  context is specified; transactions normally live inside an actor that owns
  storage, interface, reset, and conflict context.
- A library root is not a textual include. Imported definitions lower through
  reviewable scheduled `.fsm` artifacts after specialization, or fail closed
  before scheduled `.fsm` emission.

Planned import/use shape:

```lisp
(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params (WIDTH 32) (DEPTH 16))
    (bind
      (clock clk)
      (reset rst)
      (input push push_i)
      (input pop pop_i)
      (input data_in data_i)
      (output data_out data_o)
      (output full full_o)
      (output empty empty_o))))
```

Rules:

- Imports are explicit and actor-scoped in the first planned model.
- Imported definitions remain namespaced by default. Optional `as alias`
  creates a local namespace alias, not unqualified symbol pollution.
- `(use namespace.actor as instance ...)` instantiates or specializes an
  imported reusable actor into the current design scope.
- Duplicate import aliases, duplicate local instance names, missing libraries,
  missing exported definitions, and ambiguous aliases must fail closed with
  diagnostics before scheduled `.fsm` emission.
- A later whole-file import section can be considered if multiple actors in one
  source need the same library imports, but the first model keeps import scope
  local to the actor using the library.

Exported definition kinds:

- `actor`: reusable stateful actor/module intent. This is the first shipped
  target.
- `transaction`: planned reusable transaction pattern. It needs a binding
  contract for the owning actor's interface, storage, reset, and conflict
  domain before it can ship.
- `drive`: planned reusable named-drive helper inside an actor or actor
  template. It should not ship as an unscoped standalone export until the
  binding rules are clear.

Diagnostics boundary:

- Unknown root `(library ...)` remains unsupported until implementation starts.
- During implementation, parser acceptance alone is not a support claim.
  Accepted library sources must resolve imports, bind parameters/interfaces,
  lower to scheduled `.fsm`, and pass fixture-backed tests.
- Unsupported export kinds, missing exports, duplicate aliases, duplicate
  instance names, unresolved search roots, and parameter/bind mismatches must
  fail closed with targeted diagnostics.

FIFO modeling rule:

- FIFO is actor-first. The reusable FIFO owns storage, pointers, occupancy,
  flags, reset behavior, and interface timing.
- Enqueue/dequeue/flush/status may be transactions or callable operations
  inside that actor, but they do not replace the actor as the owner of FIFO
  state.
- The first library fixture should prove an imported `fifo` actor through
  specialization, scheduled `.fsm` review, schedule report visibility, strict
  HDL generation, and reset/full/empty/push/pop behavior assertions.

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
- `2026-05-14`: Planned ISF library syntax uses `(library name ...)` roots,
  actor-scoped `(imports (library name as alias))`, and `(use alias.actor as
  instance ...)` for imported actor use. Namespaced imports are the default;
  aliases do not create unqualified symbol pollution.

## Open Questions

- Should a later whole-file import section be added after actor-scoped imports
  ship?
- What is the first bounded public shape for reusable transaction templates
  outside a reusable actor, if any?
- Which library catalog metadata should be machine-readable at first ship:
  source path, exported definitions, parameter schemas, tests, limitations, or
  all of those?

## Blockers

- Implementation is blocked until `ISF-LIBRARIES.2` specifies specialization
  and binding details for parameters, clocks/resets, interfaces, generated
  names, and report provenance.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-LIBRARIES` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-LIBRARIES.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARIES` | `R14: log proposed ISF library support` | Proposed tree created from the FIFO/library design discussion. |
| `ISF-LIBRARIES.1` | `ISF-LIBRARIES.1: specify library import model` | Public library terminology, source roots, import/use shape, namespaces, export kinds, and diagnostics boundary. |

## Changelog

- `2026-05-14`: Created the proposed ISF libraries/imports task tree.
- `2026-05-14`: Activated the ISF library tree and specified the first public
  library/import model.
