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
  Status: `done`
  Goal: `Specify specialization and binding for reusable ISF definitions.`
  Acceptance: `Widths, depths, reset policy, interface mapping, parameter
  override domains, generated names, and report provenance have a bounded
  public contract.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-LIBRARIES.2: specify library binding model`

- ID: `ISF-LIBRARIES.3`
  Status: `done`
  Goal: `Implement import resolution for reusable ISF libraries.`
  Acceptance: `The parser/lowerer can resolve imported reusable definitions
  from configured search roots, rejects ambiguous or missing definitions, and
  preserves provenance in scheduled artifacts and reports.`
  Verification: `prove -l t/1230-isf-library-import-resolution.t
  t/1116-isf-public-schedule-report-key-family-audit.t
  t/1121-isf-public-cli-schedule-report-audit.t
  t/1131-isf-public-top-level-discovery-audit.t
  t/1139-isf-public-lower-result-metadata-audit.t
  t/1140-isf-public-schedule-report-metadata-audit.t
  t/1142-isf-public-guidance-metadata-audit.t
  t/1112-isf-public-interface-contract.t
  t/1144-isf-public-tested-by-metadata-audit.t
  t/1154-isf-public-facade-return-metadata-audit.t
  t/1156-isf-public-lower-result-file-shape-audit.t
  t/1183-ci-regression-tier-selection.t`;
  `./bin/ci-regression isf --no-book`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-LIBRARIES.3: implement library import resolution`

- ID: `ISF-LIBRARIES.4`
  Status: `active`
  Goal: `Ship the first reusable FIFO library fixture.`
  Acceptance: `A parameterized FIFO actor library fixture can be imported,
  specialized, lowered to scheduled `.fsm`, and generated to HDL with focused
  assertions for storage, enqueue/dequeue behavior, full/empty flags, and
  reset behavior.`
  Children: `ISF-LIBRARIES.4.1`, `ISF-LIBRARIES.4.2`,
  `ISF-LIBRARIES.4.3`
  Verification: `pending; see child leaves`
  Commit: `pending; see child leaves`

- ID: `ISF-LIBRARIES.4.1`
  Status: `done`
  Goal: `Wire resolved library actor instances through generated tops.`
  Acceptance: `A library actor use emits a generated composition top, binds
  same-name clock/reset through the existing system-port auto-wiring path,
  links bound inputs/outputs directly to the library child instance, and
  reaches SystemVerilog generation. Unsupported system-name remapping fails
  before backend parsing.`
  Verification: `prove -l t/1231-isf-library-generated-top.t
  t/1230-isf-library-import-resolution.t
  t/1216-isf-generated-composition-top.t
  t/1217-isf-generated-composition-schedule-report.t
  t/1122-isf-public-cli-outdir-lowering-audit.t
  t/1144-isf-public-tested-by-metadata-audit.t
  t/1183-ci-regression-tier-selection.t`;
  `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `ISF-LIBRARIES.4.1: wire library generated tops`

- ID: `ISF-LIBRARIES.4.2`
  Status: `pending`
  Goal: `Author the first reusable FIFO actor library fixture.`
  Acceptance: `The repo contains an importable FIFO actor library fixture with
  explicit shipped parameters, bindings, reset behavior, and documented
  limitations that match current ISF expressiveness.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LIBRARIES.4.3`
  Status: `pending`
  Goal: `Prove FIFO fixture lowering and HDL generation.`
  Acceptance: `The FIFO fixture lowers through library import, generated top,
  scheduled `.fsm`, schedule report, and SystemVerilog generation with focused
  checks for the behavior that current ISF can express.`
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
| 1 | `ISF-LIBRARIES.4.2` | `pending` | Library actor instances now reach generated top/HDL; the next slice should author the reusable FIFO fixture within the current ISF expressiveness boundary. |

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

Source roots:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Rules:

- A `.isf` compile/report entry source root may be an `(actor ...)` root, as
  today. Imported file-backed or same-source reusable descriptions may provide
  `(library name ...)` roots.
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

## ISF-LIBRARIES.2 Specialization / Binding Model

First shipped specialization target:

- The first concrete reusable definition kind is an exported `actor`.
- `(use alias.actor as instance ...)` creates one specialized actor instance in
  the importing actor.
- The exported library actor remains immutable. Parameter overrides and
  bindings are instance-local; two uses of the same exported actor may use
  different parameters and different parent signals.
- Standalone exported `transaction` and `drive` definitions remain planned but
  deferred. They need an owning actor, storage, reset, interface, and conflict
  context before their specialization can be public.

Actor parameter declarations:

```lisp
(actor fifo
  (params
    (WIDTH 8)
    (DEPTH 16))
  ...)
```

Rules:

- Reusable actor parameters use one optional actor-local `(params ...)` clause.
- Parameter names must be non-empty scalar HDL-identifier-compatible names and
  unique within the actor.
- The first model requires a default value for every actor parameter.
- Use-site overrides use at most one nested `(params (NAME value) ...)` block.
  Override names must be unique and must match declared actor parameters.
- Missing overrides use actor defaults. Unknown overrides, duplicate overrides,
  duplicate declarations, malformed declarations, malformed override blocks,
  and multiple `params` blocks fail closed before scheduled `.fsm` emission.
- The first value domain matches the shipped spawn-parameter boundary: scalar
  decimal literals, exact-width numeric literals, and aggregate/list literals
  when the formal default is also aggregate/list-shaped. Symbolic constants are
  rejected until ISF has an explicit constant/symbol surface for library use.

Parameter use:

- Parameters may drive compile-time library specialization slots: interface
  widths, storage depths, watchdogs, repeat counts that must be static, and
  generated child `+params`.
- If a parameter appears in a context the lowerer cannot prove static or cannot
  carry to scheduled `.fsm`, lowering fails with a diagnostic naming the
  parameter and use-site instance.
- Derived widths should be authored explicitly until ISF has a shipped derived
  parameter expression surface. For example, a FIFO library may expose
  `PTR_WIDTH` rather than relying on an unshipped `clog2(DEPTH)` form.

Clock and reset binding:

```lisp
(use fifo_lib.fifo as rx_fifo
  (bind
    (clock clk)
    (reset rst_n)))
```

Rules:

- If the reusable actor declares `(clock name)`, the use site must bind that
  clock with one `(clock parent_signal)` entry.
- If the reusable actor declares `(reset ...)`, the use site must bind that
  reset with one `(reset parent_signal)` entry.
- The reusable actor owns reset kind and polarity. A later overrideable reset
  policy can be added as a distinct feature, but first-shipped library use
  should not silently change sync/async or active-low/active-high behavior.
- Missing required clock/reset bindings, duplicate clock/reset bindings, and
  reset-policy override attempts fail closed before scheduled `.fsm` emission.

Interface binding:

```lisp
(use fifo_lib.fifo as rx_fifo
  (bind
    (input push push_i)
    (input pop pop_i)
    (input data_in data_i)
    (output data_out data_o)
    (output full full_o)
    (output empty empty_o)))
```

Rules:

- Every public interface port on the exported actor must be bound exactly once
  in the first shipped model.
- Binding entries use `(direction library_port parent_signal)`.
- `direction` must match the exported actor interface direction.
- `library_port` must name a public port declared by the exported actor.
- `parent_signal` must name a visible importing-actor interface signal or a
  later explicitly declared local signal surface. Until such a local signal
  surface ships, first implementation should require importing-actor interface
  signals.
- Widths are checked after parameter overrides are applied. Known widths must
  match exactly; no implicit truncation, extension, or slicing is performed by
  the library binder.
- Duplicate bindings, unbound ports, unknown ports, direction mismatches,
  unknown parent signals, and width mismatches fail closed.

Generated names:

- The authored instance name is the stable logical identity in diagnostics and
  reports.
- Instance names are actor-local and must be unique across all library uses and
  any other generated-child instance namespace that shares the generated top.
- The first deterministic specialized child module name should be
  `<importing_actor>__<instance>`.
- The first deterministic specialized child scheduled `.fsm` basename should be
  `<importing_actor>__<instance>.fsm`.
- Library namespaces containing dots are sanitized only for generated artifact
  names; diagnostics and reports should preserve the authored library/export
  names.
- A generated name collision, after sanitization, must fail closed rather than
  silently renaming the instance.

Schedule report provenance:

- Successful reports should expose a bounded `library_uses` array once the
  feature ships.
- Each entry should expose `library`, `alias`, `export`, `kind`, `instance`,
  `module`, `scheduled_fsm`, `parameters`, and `bindings`.
- Parameter entries should expose `name`, `source` (`default` or `override`),
  and stringified `value`.
- Binding entries should expose `role` (`clock`, `reset`, `input`, or
  `output`), `library_name`, and `parent_name`; interface bindings should also
  expose `width` after specialization.
- The report must not expose raw parser nodes, raw library resolver state, raw
  LoweringIR internals, or private generated-top planning objects.

Rejected cases:

- malformed actor-local parameter declarations or use-site override blocks;
- duplicate actor parameter declarations or duplicate use-site overrides;
- unknown override names or unsupported value shapes;
- parameter use in unsupported non-static contexts;
- missing, duplicate, or policy-changing clock/reset bindings;
- missing, duplicate, unknown, or direction-mismatched interface bindings;
- width mismatches after parameter specialization;
- duplicate instance names or sanitized generated-name collisions;
- unknown parent binding signals; and
- attempts to use standalone transaction/drive exports before their binding
  model ships.

## ISF-LIBRARIES.3 Import Resolution Implementation

Shipped behavior:

- Actor roots may carry one `(imports ...)` clause and one or more `(use ...)`
  clauses.
- Imported library roots use `(library name ...)` with an `(exports ...)`
  clause. The first supported export kind is `actor`.
- `parse_file(...)` resolves external library files from the importing source
  directory, `FSMLIB` entries, and the current directory. For a library name
  such as `common.pulse`, the resolver checks both `common.pulse.isf` and
  `common/pulse.isf` under each root.
- `parse_source(...)` can resolve same-source library roots, but external file
  resolution requires `parse_file(...)` so the resolver has a source directory.
- Use-site parameter overrides and clock/reset/interface bindings are validated
  during parsing. Missing libraries, missing exports, unknown parameters,
  missing port bindings, direction mismatches, unknown parent signals, and
  width mismatches fail closed before scheduler handoff.
- Lowering emits one specialized child scheduled `.fsm` file per resolved
  library actor use. The child module/file name uses
  `<importing_actor>__<instance>`.
- Schedule reports now include a top-level `library_uses` array. Entries expose
  bounded library/export/instance identity, generated child artifact names,
  parameter source/value summaries, and binding summaries.
- Generated tops now include library actor instances. Same-name library
  clock/reset bindings use the existing system-port auto-wiring path; explicit
  system-name remapping remains fail-closed until the composition backend
  supports it.

Remaining boundary:

- Library actor instances are resolved, emitted as reviewable scheduled child
  `.fsm` artifacts, wired into generated tops, and reachable through
  SystemVerilog generation when system clock/reset names match.
- Standalone transaction and drive exports still fail closed.
- Symbolic parameter values and derived parameter expressions remain deferred.
- The first FIFO fixture remains under `ISF-LIBRARIES.4`; it must stay inside
  current ISF expressiveness or explicitly log any missing FIFO language
  features as follow-up leaves.
- Library actor system clock/reset name remapping remains deferred; the
  current generated-top path requires same-name system ports.

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
- `2026-05-14`: The first reusable-definition specialization model targets
  exported actors. Use-site `(params ...)` overrides are instance-local,
  clock/reset/interface bindings are explicit, generated names use the
  `<importing_actor>__<instance>` shape, and successful reports should expose
  bounded `library_uses` provenance.

## Open Questions

- Should a later whole-file import section be added after actor-scoped imports
  ship?
- What is the first bounded public shape for reusable transaction templates
  outside a reusable actor, if any?
- Which library catalog metadata should be machine-readable at first ship:
  source path, exported definitions, parameter schemas, tests, limitations, or
  all of those?

## Blockers

- No known design blocker remains for authoring the first FIFO fixture, but
  the fixture must respect the current same-name system-port boundary and the
  current lack of broad memory/array FIFO primitives.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-LIBRARIES` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-LIBRARIES.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-LIBRARIES.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-LIBRARIES.3` | `prove -l t/1230-isf-library-import-resolution.t t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1154-isf-public-facade-return-metadata-audit.t t/1156-isf-public-lower-result-file-shape-audit.t t/1183-ci-regression-tier-selection.t` | `passed; 12 files, 29 tests` |
| `2026-05-14` | `ISF-LIBRARIES.3` | `./bin/ci-regression isf --no-book` | `passed; 138 files, 469 tests` |
| `2026-05-14` | `ISF-LIBRARIES.3` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-LIBRARIES.4.1` | `prove -l t/1231-isf-library-generated-top.t t/1230-isf-library-import-resolution.t t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t` | `passed; 7 files, 18 tests` |
| `2026-05-14` | `ISF-LIBRARIES.4.1` | `./bin/ci-regression isf --no-book` | `passed; 139 files, 472 tests` |
| `2026-05-14` | `ISF-LIBRARIES.4.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARIES` | `R14: log proposed ISF library support` | Proposed tree created from the FIFO/library design discussion. |
| `ISF-LIBRARIES.1` | `ISF-LIBRARIES.1: specify library import model` | Public library terminology, source roots, import/use shape, namespaces, export kinds, and diagnostics boundary. |
| `ISF-LIBRARIES.2` | `ISF-LIBRARIES.2: specify library binding model` | Actor parameter declarations, use-site overrides, clock/reset/interface binding, generated names, report provenance, and rejected cases. |
| `ISF-LIBRARIES.3` | `ISF-LIBRARIES.3: implement library import resolution` | Parser/lowerer resolve exported library actors from source-dir/FSMLIB/cwd roots, emit specialized child scheduled `.fsm`, and project `library_uses` report metadata. |
| `ISF-LIBRARIES.4.1` | `ISF-LIBRARIES.4.1: wire library generated tops` | Generated top wiring for resolved library actor instances; same-name system ports use auto-wiring and remapping fails closed. |

## Changelog

- `2026-05-14`: Created the proposed ISF libraries/imports task tree.
- `2026-05-14`: Activated the ISF library tree and specified the first public
  library/import model.
- `2026-05-14`: Specified the first specialization and binding model for
  imported reusable actor definitions.
- `2026-05-14`: Implemented the first library import-resolution slice:
  actor-scoped imports, exported actor uses, parameter/binding diagnostics,
  specialized scheduled child artifacts, and bounded `library_uses` reports.
- `2026-05-14`: Implemented generated top wiring for resolved library actor
  instances and proved CLI SystemVerilog generation for the wrapper path.
