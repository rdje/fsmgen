
## 6. Actor Root

Supported actor clauses:

```lisp
(clock name)
(reset name)
(reset (name async active_low))
(reset (name async active_high))
(reset (name sync active_low))
(watchdog positive_integer_or_actor_constant_or_actor_scalar_parameter_or_package_constant)
(interface ...)
(params ...)
(constants ...)
(imports ...)
(use ...)
(clock-domains ...)
(crossings ...)
(storage ...)
(drive ...)
(transaction ...)
(rule ...)
(resources ...)
(priority lhs over rhs)
```

Singleton actor clauses:

```text
clock
reset
watchdog
interface
params
constants
imports
resources
storage
clock-domains
crossings
```

Parser-carried but not generally lowered today:

- Actor-level `(phase name property...)`
- Actor-level `(stage name property...)`

Those actor-level metadata clauses are report-visible through
`actor_phases[]` and `actor_stages[]`, where each entry preserves the authored
metadata `name` and parser-validated list-form `body`. They still do not add
runtime scheduler, generated `.fsm`, generated-top, or HDL semantics.

Deprecated compatibility input:

- `(handshake name (valid signal) (ready signal))` is validated for shape and
  ignored. It does not lower to ready/valid behavior. Use `(on ...)`,
  generated `can_accept`, or transaction `(stage ...)` for ready/valid
  barriers.

## 7. Timing System

Single-domain shorthand:

```lisp
;; Implicit legacy single-clock defaults when the author omits the clauses:
(clock clk)
(reset (rst_n async active_low))
(watchdog 65535)

;; Explicit reset shorthand remains available:
(reset rst_n)
```

Rules:

- A legacy single-domain actor that omits `(clock ...)` defaults to `clk`.
- A legacy single-domain actor that omits `(reset ...)` defaults to
  asynchronous active-low reset `rst_n`.
- Any actor that omits `(watchdog ...)` defaults to `65535`, exactly
  `(2^16 - 1)`.
- `(clock name)` names the actor clock for legacy single-domain actors.
- Explicit `(reset name)` keeps the shipped synchronous reset shorthand.
- Reset names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List reset form may include `sync`, `async`, `active_low`, or `active_high`.
- Async reset lowers to `.fsm` `areset`; sync reset lowers to `.fsm` `sreset`.
- `(watchdog N)` is the actor default for `(await ...)`; `N` may be a positive
  integer literal, a declared actor constant, an actor-local scalar parameter
  default, or a qualified imported package scalar constant that resolves to a
  positive integer.
- Per-await watchdog overrides are supported with `(await port (watchdog M))`;
  `M` may use the same static source set as actor-level `N`. Top-level
  transaction awaits may also use same-transaction scalar parameter defaults.
  Same-transaction parameter watchdog limits shadow actor-level static names
  and remain local lowering inputs. The current scheduled `.fsm` model has one
  watchdog counter per transaction, so distinct per-await limits in one
  transaction fail closed.

Named domains:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
```

Rules:

- Named domains are actor-scoped.
- An actor must not mix `(clock ...)` or actor-level `(reset ...)` with
  `(clock-domains ...)`.
- Domain names are unique and scalar.
- Multi-domain actors have exactly one default domain. A single-domain block
  may rely on the implicit default.
- Interface ports, storage entries, transactions, rules, library uses, and
  generated child activations may carry `(domain NAME)`.
- Omitted domain annotations inherit the actor default domain.
- Transactions and rules are indivisible domain-owned regions.
- Drives do not own domains; they inherit the activation-site domain. Reusing
  one drive from multiple domains is rejected until a safe reuse rule exists.
- Direct unowned cross-domain reads, writes, triggers, activations, bindings,
  and multi-domain drive reuse fail closed.

Event crossing primitive:

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

Rules:

- The first shipped crossing kind is a no-payload acknowledged single-bit
  event channel.
- Source and destination domains must be different declared domains.
- Multiple independent event crossings may appear in one actor. Each one emits
  a distinct generated CDC instance/module, top wiring, schedule-report entry,
  and concrete generated HDL child. This does not add payload transfer or
  ordering semantics between event channels.
- The source request may be accepted only when generated source-domain `ready`
  is true.
- At most one event is outstanding.
- The destination receives a generated one-cycle pulse after synchronizer and
  acknowledgement latency. No same-cycle relationship is promised.
- Generated HDL for accepted event crossings emits the generated top and
  concrete acknowledged-event CDC child modules for SystemVerilog/Verilog-family
  targets when each domain artifact satisfies the scheduled `.fsm` HDL
  contract. Clock-only no-reset domain artifacts are accepted by that backend.
- No-reset event crossings are accepted for lower-result review artifacts,
  schedule JSON, and plain generated HDL. Their generated CDC metadata marks
  absent source/destination resets, and generated CDC child modules omit the
  absent reset ports.

Activation crossing primitive:

```lisp
(crossings
  (activation worker (from core) (to bus)))
```

Rules:

- An activation crossing owns a blocking `(do child)` where `child` is a
  transaction declared in the destination domain and the calling transaction is
  in the source domain. The start/done handshake signals are compiler-internal,
  so only the crossing is declared (not raw event pairs).
- The shipped blocking activation contexts are: the transaction top level,
  directly inside a top-level `repeat` body, directly inside a top-level
  `when`/`switch`/`while`/`until` body, directly inside a `repeat` nested in a
  top-level `when` body or top-level `switch` branch, directly inside supported
  nested `when` chains reached from those top-level branch bodies, and directly
  inside a `repeat` under those supported nested `when` chains. In repeat/loop
  contexts the same dual-CDC handshake re-runs once per iteration.
- One activation crossing auto-generates two acknowledged-event CDC children: a
  `start` synchronizer (source → destination) and a `done` synchronizer
  (destination → source). Each reuses the no-payload acknowledged single-bit
  event primitive.
- The caller awaits the start synchronizer's `ready`, drives a one-cycle
  `<child>_start` request, and blocks on the `<child>_done` pulse; the child is
  gated on the start pulse and, on completion, awaits the done synchronizer's
  `ready` before driving a one-cycle `<child>_done`. At most one activation is
  outstanding; the `<child>_done` pulse is the acknowledgement. No same-cycle
  relationship is promised.
- The schedule report exposes an activation crossing as a `crossings` entry with
  `kind: "activation"` carrying `child`, `source_domain`, `destination_domain`,
  `start_signal`/`done_signal`, `start_instance`/`start_module`,
  `done_instance`/`done_module`, `outstanding_policy`, `payload`, and `top_fsm`.
  Each participating domain exposes a per-domain endpoint
  `{ activation, role (source|destination), start, done }`.
- Generated HDL for an accepted activation crossing emits the two domain modules,
  the two generated CDC child modules, and the generated top for
  SystemVerilog/Verilog-family targets. (Multi-domain composition tops carry the
  same pre-existing `shared_dp_export_*` lint characteristic as event crossings.)
- Fail-closed boundaries: a cross-domain `(do)` with no covering activation
  crossing, a declared-but-unused crossing (one whose `child` no transaction
  `(do)`es), a crossing whose `child` is not in the declared destination domain,
  cross-domain `(spawn)`, payload CDC, auto-generated crossings,
  repeat-contained branch contexts, nested `switch`, nested `while`, nested
  `until`, and unsupported deeper cross-domain `(do)` placements all fail
  closed.

## 8. Interface, Storage, Constants

Interface:

```lisp
(interface
  (input  name)
  (input  name (width N))
  (input  name (width PARAM))
  (input  name (width CONST))
  (output name)
  (output name (width N))
  (output name (width PARAM))
  (output name (width CONST))
  (output name (reset V))
  (output name (default V))
  (output name (width N) (reset V) (default V)))
```

Rules:

- Width defaults to `1`.
- `N` is a positive integer literal.
- `PARAM` may name an actor-local scalar parameter default that resolves to a
  positive integer; accepted parser output and scheduled `.fsm` artifacts use
  the resolved integer width while `actor_params[]` preserves the authored
  parameter declaration.
- `CONST` may name a declared actor constant that resolves to a positive
  integer; accepted parser output and scheduled `.fsm` artifacts use the
  resolved integer width while `actor_constants[]` and scheduled `+constants`
  preserve the authored constant declaration.
- Unknown symbolic width names, runtime interface signals, zero-valued or
  non-scalar actor parameters, zero-valued actor constants, arbitrary
  expressions, and non-positive literals fail closed.
- Directions are `input` or `output`.
- Port names are unique across both directions.
- `(domain NAME)` is accepted on interface entries when named domains are in
  use.
- Output ports may carry `(reset V)` and `(default V)` metadata when `V` is a
  non-negative integer literal that fits the resolved positive integer output
  width. `(reset V)` lowers to generated `.fsm` `+size` reset metadata.
  `(default V)` lowers to generated transaction idle/quiescent `<-` output
  assignments. This output metadata is rejected on inputs, type-referenced
  outputs, unresolved-width outputs, negative values, malformed arity, and
  too-wide values.
- Malformed directions, duplicate names, nested names, and unsupported widths
  fail closed.

Constants:

```lisp
(constants
  (WAIT_ZERO 0)
  (WAIT_TWO 2)
  (WAIT_ONE 4'd1)
  (BUSY_WAIT mode.BUSY)
  (REMOTE_WAIT shared.mode.BUSY))
```

Rules:

- Constants are actor-scoped and compile-time only.
- Names are unique HDL identifiers.
- Values are non-negative integer literals or enum member references.
- Enum member references use local `mode.BUSY` or package-qualified
  `shared.mode.BUSY` spelling and must resolve to non-negative integer
  literal values before lowering.
- Constants are emitted into scheduled `.fsm` `+constants`.
- Schedule reports preserve the authored value token in `actor_constants[]`.
- Constants may be used as static actor timing/count values, static
  width/depth values where documented, and existing static activation
  parameter override values.
- Actor-local scalar parameter defaults may also be used as static
  `(wait NAME)` counts when they resolve to non-negative integer literals.
  Same-transaction scalar parameter defaults may also be used as static
  `(wait NAME)` counts in that transaction when they resolve to non-negative
  integer literals; they shadow actor-level static names and remain local
  lowering inputs rather than scheduled `.fsm` actor parameters.
  Qualified imported package scalar constants may be used as static
  `(wait PACKAGE.CONSTANT)` counts when they resolve to non-negative integer
  literals.
  Generated activation use-site overrides are not wait-count constants.

Actor-owned storage:

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width PTR_W))
  (bank data (width DATA_W) (depth DEPTH)))
```

Here scalar `PTR_W`, bank width `DATA_W`, and bank `DEPTH` may be actor-local
scalar parameter defaults or declared actor constants that resolve to positive
integers.

Rules:

- `(var ...)` and `(variable ...)` declare fixed-width actor-owned scalar
  state.
- `(bank ...)` declares a fixed-depth actor-owned storage bank.
- Scalar `(var ...)` and `(variable ...)` widths are positive integer
  literals, actor-local scalar parameter defaults, or declared actor constants
  that resolve to positive integers. Unknown symbolic names, runtime interface
  signals, zero-valued or non-scalar actor parameters, zero-valued actor
  constants, and arbitrary expressions fail closed. Type aliases remain
  spelled as `(type NAME)`.
- Bank widths are positive integer literals, actor-local scalar parameter
  defaults, or declared actor constants that resolve to positive integers.
  Unknown symbolic names, runtime interface signals, zero-valued or non-scalar
  actor parameters, zero-valued actor constants, and arbitrary expressions
  fail closed.
- Bank depths are positive integer literals, actor-local scalar parameter
  defaults, or declared actor constants that resolve to positive integers.
  Unknown symbolic names, runtime interface signals, zero-valued or non-scalar
  actor parameters, zero-valued actor constants, and arbitrary expressions
  fail closed.
- Storage names must not collide with interface ports, clock/reset names, or
  generated scheduler names.
- Banks lower to deterministic scalar storage entries such as `data_0`,
  `data_1`, `data_2`, and `data_3`.
- Schedule reports expose declared storage through `inferred_storage`.
- Scalar `(var ...)` / `(variable ...)` storage entries may carry optional
  `(fields (field NAME (bits HI LO) ...))` metadata. The first shipped slice is
  metadata-only: it validates names, literal bit ranges inside the resolved
  parent width, non-overlap, optional access vocabulary, optional field reset
  metadata cross-checked against an explicit parent `(reset V)`, and inline
  enum values. It publishes the accepted map as optional
  `inferred_storage[].fields` on the parent storage entry. It does not derive
  parent resets, enforce access policy, generate assertions/register models,
  or generalize to banks, aggregate carriers, packet/flit layouts, or typed
  storage entries.
- `isf/storage_fields.isf` is the representative file-backed support-accounted
  fixture for scalar storage field metadata. Its check JSON and normalized
  semantic JSON report a matched `feature.isf_storage_field_metadata` support
  identity; schedule JSON remains the public field-map payload.
- Existing runtime field/data operations such as `set-field`, `when-field`,
  `extract`, and `assemble` remain scheduled behavior and must not be used to
  stand in for a static PDF register table.
- `isf/fifo_data_path.isf` is the representative file-backed bank datapath
  fixture for scalarized store/load behavior.
- `isf/fifo_controller.isf` is the representative file-backed controller-only
  fixture for occupancy, full/empty, and pointer update behavior.
- `isf/fifo_library_use.isf` is the representative file-backed fixed FIFO
  reusable-library fixture for import/use binding, specialized child emission,
  generated-top wiring, and fixed parameter provenance.

Bank access:

```lisp
(store bank_name index value)
(load bank_name index as target)
```

Rules:

- `store` writes a selected entry of an actor-owned bank.
- `load` reads a selected entry into `target`.
- Same-cycle store/load policy is read-before-write.
- Bank access is accepted in rules and supported transaction contexts.
- Reports expose bounded `bank_accesses[]` metadata.

## 9. Reusable Libraries

Library root:

```lisp
(library common.pulse
  (exports
    (actor pulse_actor))

  (actor pulse_actor
    ... reusable actor body ...))
```

Use site:

```lisp
(actor top
  (imports
    (library common.pulse as pulse_lib))

  (use pulse_lib.pulse_actor as rx
    (params
      (WIDTH 4))
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
```

Rules:

- The first shipped export kind is `actor`.
- Library imports are namespaced. Without `as alias`, the dotted library name
  is the namespace prefix.
- Duplicate import aliases and duplicate use-site instance names fail closed.
- Reusable actor parameters are declared by actor-level `(params ...)`.
- Use-site parameter overrides are instance-local. Missing overrides use actor
  defaults.
- Actor parameter scalar defaults and scalar leaves inside actor aggregate/list
  parameter defaults may use declared actor constants, earlier actor-local
  scalar parameter defaults, local/package-qualified enum member references,
  or qualified imported package scalar constants such as
  `shared.DEFAULT_WIDTH`. Authored constant, actor-parameter, enum, and
  qualified package-constant tokens remain visible in scheduled `.fsm`
  `+params` and `actor_params[]`, while resolved literals are recorded
  internally for scalar actor-parameter consumers. Imported package constants
  are accepted only when the package is imported, the named package
  `+constants` entry exists, and the package constant is a scalar numeric or
  exact-width literal. Unqualified imported package constants, aggregate
  package constants, package constant member/item paths, forward/self/cyclic
  actor-parameter references, and non-scalar actor-parameter references fail
  closed.
  Actor top-level interface port widths may use qualified imported package
  scalar constants when the package is imported, the named package
  `+constants` entry exists, and the constant resolves to a positive integer
  scalar. Package-constant-backed interface widths publish as resolved integer
  public port widths, scheduled `.fsm` `+size` entries, schedule-report
  evidence, and HDL port ranges. Unqualified package constants, aggregate
  package constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, zero-valued constants, runtime
  signals, and expressions fail closed.
  Actor-owned scalar storage widths may also use qualified imported package
  scalar constants under the same imported-package and positive-integer scalar
  requirements. Package-constant-backed scalar storage widths publish as
  resolved integer parser-handoff storage widths, scheduled `.fsm` `+size`
  entries, `inferred_storage[].width` report evidence, width evidence, and HDL
  register ranges. Unqualified package constants, aggregate package constants,
  package constant member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, runtime signals, and expressions fail
  closed.
  Actor-owned bank storage widths may use qualified imported package scalar
  constants under the same imported-package and positive-integer scalar
  requirements. Package-constant-backed bank widths publish as resolved
  integer parser-handoff bank widths, scheduled `.fsm` scalarized `+size`
  entries, `inferred_storage[].width`, `bank_accesses[].width`, width
  evidence, and HDL register ranges. Unqualified package constants, aggregate
  package constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, zero-valued constants, runtime
  signals, and expressions fail closed.
  Actor-owned bank storage depths may also use qualified imported package
  scalar constants under the same imported-package and positive-integer scalar
  requirements. Package-constant-backed bank depths publish as resolved
  integer parser-handoff bank depths, scheduled `.fsm` scalarized `+size`
  entries, `inferred_storage[]` storage entries, `bank_accesses[].depth` and
  `bank_accesses[].scalar_entries`, and HDL register declarations for the
  resolved scalarized family. Unqualified package constants, aggregate package
  constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, zero-valued constants, runtime
  signals, and expressions fail closed.
  Transaction-local port widths may use qualified imported package scalar
  constants under the same imported-package and positive-integer scalar
  requirements. Package-constant-backed transaction port widths publish as
  resolved integer parser-handoff port widths, scheduled `.fsm` `+size`
  entries for activation handoff storage, `transaction_port_bindings[]`
  report widths, and HDL register ranges. Unknown or unqualified package
  constants, aggregate package constants, package constant member/item paths,
  ambiguous local-enum/package-constant spellings, zero-valued constants,
  runtime signals, and expressions fail closed.
  Generated child and direct/non-generated transaction-local port widths may
  also use same-transaction scalar parameter defaults. The accepted
  `TX_PARAM` source resolves before actor constants and actor parameters, may
  derive from an earlier scalar transaction parameter default, and must
  resolve to a positive integer before parser handoff. The resolved width then
  flows through scheduled `.fsm` port `+size` declarations, generated parent
  handoff storage where applicable, `transaction_port_bindings[]` report
  widths, and HDL port/register ranges.
  Cross-transaction parameter names, aggregate/list transaction parameters,
  zero-valued transaction parameters, forward/self/cyclic transaction-parameter
  defaults, runtime signals, and expressions fail closed in this slice.
  Explicit data-operation width evidence may use qualified imported package
  scalar constants under the same imported-package and positive-integer scalar
  requirements. Package-constant-backed `shift_left` and `shift_right`
  `(width ...)` options, plus `assemble` and `extract` `(widths ...)` entries,
  publish as resolved scheduler width evidence for scheduled `.fsm` shift
  positions, assemble/extract width facts, and `inferred_storage[]` report
  widths. Same-transaction scalar parameter defaults on generated child and
  direct/non-generated transactions may also provide data-operation width
  evidence when they resolve to positive integers. Activation-site
  override-specialized data widths, unknown or unqualified package constants,
  aggregate package constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, zero-valued constants, runtime
  signals, and expressions fail closed.
  Static transaction wait counts may use same-transaction scalar parameter
  defaults or qualified imported package scalar constants when they resolve to
  non-negative integer scalars. Parameter-backed waits lower through the
  existing static wait path and remain local lowering inputs;
  package-constant-backed waits lower through the existing static wait path:
  zero counts emit no wait state and no `transaction_waits[]` entry, while
  positive counts emit fixed scheduled wait-state chains and report
  `count_kind: static`, integer `cycles`, and the authored
  `PACKAGE.CONSTANT` token in `count_source`. Non-scalar or cross-transaction
  parameters, unknown or unqualified package constants, aggregate package
  constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, runtime signals, arbitrary
  expressions, and package constants inside wait-count expressions fail
  closed.
  Actor-level and await-local watchdog limits may use qualified imported
  package scalar constants when the constant resolves to a positive integer
  scalar. Top-level await-local watchdog limits may also use
  same-transaction scalar parameter defaults that resolve to positive
  integers. Package-constant-backed
  actor-level watchdog limits publish resolved integer parser/report watchdog
  values. Package-constant-backed await-local limits and top-level
  transaction-parameter await-local limits lower through the existing watchdog
  counter path; the transaction parameters remain local lowering inputs, and
  package-authored declarations stay visible through package/import metadata
  plus embedded package `+constants` entries. Unknown or unqualified package constants,
  aggregate package
  constants, package constant member/item paths, ambiguous
  local-enum/package-constant spellings, zero-valued constants, zero-valued
  or non-scalar transaction parameters, actor-level or cross-transaction
  parameters, runtime signals, arbitrary expressions, and package constants
  inside watchdog expressions fail closed.
  Generated child transaction scalar parameter defaults and scalar leaves
  inside generated child transaction aggregate/list parameter defaults may use
  declared actor constants, actor-local scalar parameter defaults, earlier
  scalar transaction parameter defaults, local or package-qualified enum
  member references, or qualified imported package scalar constants. Actor
  constants and actor scalar parameter defaults in generated child transaction
  defaults are resolved to literal generated child `.fsm` `+params`,
  generated-composition child summaries, and default instance bindings;
  transaction-parameter dependencies, enum references, and qualified
  package-constant references preserve authored tokens in those review
  surfaces because they are child-local or carried by generated child package
  imports and embedded package roots.
  Scalar activation
  parameter overrides and scalar leaves inside activation aggregate/list
  parameter override values may also use local or package-qualified enum member
  references or qualified imported package scalar constants on generated
  activation sites. Package-constant-backed activation overrides resolve to
  literal generated-top bindings and generated-composition report values;
  unqualified package constants, aggregate package constants, and package
  member/item paths fail closed. Reusable-library use-site parameter overrides
  may also use local or package-qualified enum members or qualified imported
  package scalar constants as scalar values or scalar leaves inside compatible
  aggregate/list override values. Package-constant-backed use-site overrides
  resolve to literal generated-top/generated-composition bindings and
  `library_uses[]` report values; unqualified package constants, aggregate
  package constants, and package member/item paths fail closed. Duplicate
  overrides, unknown overrides, and shape mismatches fail closed.
- Schedule reports expose actor parameter defaults through `actor_params[]`
  entries with `name` and JSON-safe default `value`, preserving authored actor
  constant tokens, earlier actor-parameter tokens, enum tokens, and qualified
  package-constant tokens. These are static specialization defaults, not
  runtime payloads.
- Every exported actor interface endpoint must be explicitly bound at the use
  site. Exported actor clock/reset endpoints may omit explicit bindings only
  when the parent and child use the same clock name and the same reset
  name/kind/polarity; FSMGen records those same-name system bindings in
  `library_uses[].bindings[]`.
- Binding direction and known width must match.
- Lowering emits a specialized child scheduled `.fsm` artifact named
  `<importing_actor>__<instance>.fsm`.
- Lowering emits a generated top `<importing_actor>_top.fsm` when library uses
  are present.
- Reports expose `library_uses[]`.

Current shipped reusable definition:

```text
qualified name: common.fifo.fifo
source: isf/common/fifo.isf
fixture: isf/fifo_library_use.isf
kind: actor
status: shipped
parameters: DATA_WIDTH=8, DEPTH=4, PTR_WIDTH=2, OCC_WIDTH=3
interface inputs: write_req, data_in[8], read_req
interface outputs: full, empty, data_out[8]
storage: wr_ptr[2], rd_ptr[2], occupancy[3], data bank width 8 depth 4
```

Known FIFO library limitations:

- Fixed-shape `DATA_WIDTH=8`, `DEPTH=4` fixture.
- No use-site parameter-driven FIFO interface shape, bank-depth
  specialization, or generated-top respecialization yet.
- No memory-array backend emission yet.
- No automatic non-zero reset values yet.
- No standalone transaction or drive exports yet.
- No nested library imports from library actors yet.

The fixed FIFO library handoff is covered by
`t/1321-isf-fifo-library-fixture-coverage.t`. That regression proves strict
schedule JSON parity against the in-process report, generated importer,
specialized child, and top `.fsm` artifacts in `--outdir`, fixed
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3` parameter
bindings, use-site clock/reset/input/output bindings, scalarized bank entries,
pointer-gated accepted push/pop datapath paths, and plain plus strict
generated-top HDL generation. It is a fixed-shape reusable-library fixture,
not a claim for use-site parameter-derived FIFO interface shape,
bank-depth specialization, generated-top respecialization, nested imports, standalone transaction/drive
exports, arbitrary-depth generated FIFOs, memory-array backend emission, or
automatic non-zero reset values.

## 10. Drive Definitions And Calls

Simple drive:

```lisp
(drive setup_phase
  (PADDR addr)
  (PWRITE is_write)
  (PSEL 1))
```

Parameterized drive:

```lisp
(drive (scl val)
  (scl val))
```

Drive calls:

```lisp
(drive setup_phase)
(drive scl 1)
(drive scl (& bit_a bit_b))
```

Rules:

- Drive definitions are actor-level reusable output phases.
- Each drive definition becomes a non-state DT block named `-drive_name`.
- Each drive call becomes one scheduled state.
- The call asserts `drive_name_start`.
- Parameterized calls assign one inferred parameter signal per formal.
- Call arity must exactly match the drive's formal count.
- Actuals may be scalar tokens, numeric/exact-width literals, or non-empty
  list expressions.
- Drive body RHS values may be scalar tokens or non-empty list expressions.
  Expressions recursively substitute drive formals with the generated payload
  signals before drive-DT emission.
- Scalar drive body RHS values and scalar operands inside drive body RHS
  expressions may use local enum members such as `mode.BUSY` or package enum
  members such as `shared.mode.BUSY`. FSMGen resolves those members before
  lowering and preserves the authored token in the generated drive DT. Enum
  members in drive body RHS expression operator position remain deferred.
- Scalar rule assignment RHS values may use local enum members such as
  `mode.BUSY` or package enum members such as `shared.mode.BUSY`. This includes
  direct scalar RHS values and scalar operands inside RHS expressions in
  explicit `(set port value)` and shorthand `(port value)` rule assignments.
  Rule assignment expression operator-position enum members remain deferred.
- Rule guards may use local or package enum members directly as standalone
  scalar guards, for example `(rule r mode.BUSY ...)` or
  `(rule r (when shared.mode.BUSY) ...)`. Scheduled `.fsm` preserves those
  guards as non-state DT header suffixes such as `<mode.BUSY` or
  `<shared.mode.BUSY`, and strict HDL generation accepts that review artifact.
- Rule guard expressions may also use local or package enum members as scalar
  operands, for example `(rule r (== mode_in mode.BUSY) ...)` or
  `(rule r (when (& ready (== mode_in shared.mode.BUSY))) ...)`. Expression
  operator-position enum members remain deferred.
- Rule guards may also use scalar aggregate storage leaves directly, for
  example `(rule r frame.flag ...)` or `(rule r (when lanes[1]) ...)`.
  Scheduled `.fsm` preserves those guards as non-state DT header suffixes such
  as `<frame.flag` or `<lanes[1]`, and strict HDL generation accepts that
  review artifact. Subaggregate rule guards and aggregate paths in expression
  operator position remain deferred.
- Scalar drive-call actuals may also use local or package enum members.
  Drive-call actual expressions may use enum members as scalar operands.
  Enum members in drive-call expression operator position remain deferred.
- Drive DT assignments use flopped output assignment (`<-`) by default, so a
  drive call consumes one state and driven output changes on the following
  clock.
- Adjacent drive calls are not merged. To drive several ports in one cycle,
  put those port-value pairs in one drive definition.

## 11. Transactions

Transaction root:

```lisp
(transaction name
  transaction_clause...)
```

Transaction clauses currently supported:

```text
(ports ...)
(domain NAME)
(params ...)
(on port body...)
(when condition body...)
(drive name args...)
(await port)
(await port (watchdog N))
(sample port as name)
(wait count)
(while condition body...)
(until condition body...)
(repeat count body...)          ;; count may be literal, same-transaction scalar parameter, actor constant, actor scalar parameter, qualified package scalar constant, or known-width runtime name
(switch selector branch...)
(set target expr)
(update target expr)
(store bank index value)
(load bank index as target)
(shift_left reg bit)
(shift_left reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(shift_right reg bit)
(shift_right reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(assemble part... as target)
(assemble part... as target (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))
(extract word as field...)
(extract word as field... (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))
(do transaction [(domain NAME)] [(params ...)] [(bind ...)])
(spawn transaction as instance [(params ...)] [(bind ...)] [(domain NAME)])
(await_all done_port)
(await_any done_port)
(complete port)
(latency (min N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)
         (max N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
                                  ;; bounds resolve to positive integers
(stage ...)
(assert (monitor (within signal N|PARAM|CONST|PACKAGE.CONSTANT)) "name")
                                  ;; bounded-eventually monitor; window resolves to a positive integer
```

### 11.1 Entry Activation

```lisp
(on start
  (sample req_addr as addr)
  (sample req_write as is_write))
```

Rules:

- `(on port ...)` creates the transaction entry/idle state guarded by `port`.
- The scheduler creates `can_accept`, asserted in entry states.
- The only supported nested body clauses inside `(on ...)` are
  `(sample port as name)`.
- `(on start (params ...))` is not public syntax and fails closed as an
  unsupported entry-body form.
- Direct `(on ...)` activation is not a generated activation instance and does
  not accept activation-site parameter overrides. For generated activations,
  `spawn`, generated blocking `do`, and rule `trigger` overrides that target a
  generated child parameter used by the child temporal-contract window are
  accepted only when the override resolves to the same positive integer cycle
  count as the child transaction parameter default. Mismatched overrides fail
  closed until override-specialized contract-window lowering is shipped.
  Overrides that target generated child parameters used by static timing
  lowering for repeat counts, wait counts, latency bounds, or top-level
  await-local watchdog limits are accepted only when they resolve to the same
  integer value as the child transaction parameter default. Mismatches fail
  closed until per-activation static timing specialization is shipped. Each
  sub-axis emits its own targeted diagnostic (`repeat-count parameter`,
  `wait-count parameter`, `latency-bound parameter`, `watchdog-limit
  parameter`) and its own deferral phrase so the author can identify which
  deferred lane is blocking the override.

### 11.2 Transaction Ports And Bindings

Transaction ports, assuming actor-level `(params (DATA_W 8))`,
`(constants (DATA_W 8))`, or an imported package constant such as
`shared.DATA_W`:

```lisp
(ports
  (input addr (width 8))
  (output data (width DATA_W))
  (input mask (width shared.DATA_W)))
```

Activation bindings:

```lisp
(do child
  (bind
    (input addr req_addr)
    (output data resp_data)))

(spawn child as w0
  (bind
    (input addr req_addr)
    (output data resp_data)))

(trigger child
  (bind
    (input addr req_addr)))
```

Rules:

- Port directions are `input` and `output`.
- Width defaults to `1`. Explicit widths may be positive integer literals,
  actor-local scalar parameter defaults, declared actor constants, or
  qualified imported package scalar constants that resolve to positive
  integers. The parser returns resolved integer widths in the public
  transaction shell.
- Port names are unique across directions.
- Input bindings may pass scalar signals, numeric/exact-width literals, or
  non-empty list expressions.
- Input bindings may add `(timing snapshot)` when the shipped site timing is
  activation/trigger payload capture, or `(timing live)` when the shipped site
  timing is generated-top live handoff wiring. Mismatched timing selections
  fail closed; this slice does not synthesize conversion storage or new
  continuous local wiring.
- Output bindings name scalar writable actor-side targets.
- `do` and `spawn` support input and output bindings.
- Rule `trigger` supports input bindings for local and generated targets.
  Generated-child rule triggers also support scalar output bindings; the copy
  back to the actor target is guarded by the generated trigger instance's
  done-observer signal. Direct/local rule-trigger output bindings remain
  rejected because a shared local target has no rule-specific completion
  identity.
- Width mismatches fail closed when width evidence is known.
- Reports expose `transaction_port_bindings[]`, including
  `actor_endpoint_kind` so consumers can distinguish scalar endpoints,
  numeric/exact-width literal operands, and list-expression operands without
  parsing `actor_expression`, plus `binding_timing` so consumers can classify
  the transfer as `activation_region`, `generated_live_handoff`,
  `trigger_payload`, or `done_guarded`, plus `authored_timing_mode` so
  consumers can see explicit `snapshot`/`live` timing assertions without
  parsing source binding clauses. `authored_timing_mode` is JSON null when no
  explicit timing clause was authored.

### 11.3 Sampling, Await, Wait, Completion

Sampling:

```lisp
(sample port as local_name)
```

Samples become D-input/next-value assignments and either piggyback on the
current state or on the next scheduled state.

Await:

```lisp
(await ready)
(await ready (watchdog 1024))
(await ready (watchdog WD_LIMIT))
(await ready (watchdog TX_PARAM))
(await ready (watchdog timing.WD_LIMIT))
```

Await waits for a port and uses the actor watchdog unless overridden.
Actor-level and await-local watchdog constants, actor scalar parameters, and
qualified imported package scalar constants resolve before counter lowering.
Top-level await-local watchdogs may also use same-transaction scalar
parameter defaults; those parameters shadow actor-level static names and
remain local lowering inputs. Reports expose the actor watchdog scalar as the resolved integer,
while package-authored limits remain visible through package/import metadata
and embedded package `+constants` entries.

Wait:

```lisp
(wait 3)
(wait WAIT_TWO)
(wait WAIT_PARAM)
(wait TX_WAIT_PARAM)
(wait shared.WAIT_TWO)
(wait count_signal)
(wait (+ count_a count_b))
```

Rules:

- Static literal, actor-constant, actor-parameter, and qualified package
  scalar-constant waits are accepted, including zero. Same-transaction scalar
  parameter waits are also accepted in the owning transaction, including zero,
  and shadow actor-level static names.
- Runtime scalar waits are accepted when the count source has known positive
  width and the predecessor-edge split is implemented. Implemented predecessor
  splits include transaction entry, sequential states, contract arm states,
  await, stage, repeat exit, repeat-check loop-back into a leading repeat-body
  runtime wait, await_all, await_any, bank load/store states, loop decision
  states, and the false fallthrough edge of loop-control `(exit-when ...)` /
  `(continue-when ...)` states.
- Runtime expression waits are accepted when every operand has known width and
  the expression width helper derives a positive result width.
- Pending samples before accepted runtime waits materialize in the first
  active wait state on positive-count paths.

  On zero-count paths, FSMGen uses a sample-preserving clone when the
  selected successor can carry the sample without changing timing.

  Shipped sample-compatible successors include drive, await, static wait,
  completion, independent scalar setter, independent shift, independent
  assemble, independent extract, and independent bank-load and bank-store
  states, plus top-level await_all/await_any sync states, spawn states,
  transaction phase pass-through states, and ready/valid stage states, for
  top-level waits; top-level bounded-eventual contract arm states are also
  sample-compatible.

  Selected completion, independent scalar setter, independent shift,
  independent assemble, independent extract, independent bank-load, and
  independent bank-store successors are shipped for `when` bodies and
  `switch` branches.

  A scalar setter, shift, assemble state, extract state, bank-load state,
  bank-store state, sync state, spawn state, stage state, contract arm state,
  or loop decision/check state is independent only when it neither reads nor
  overwrites a pending sample alias.

  A transaction phase state is sample-compatible only as the
  scheduler-created pass-through marker for transaction `(phase ...)`: it has
  no assignments or guards, and its zero-count clone preserves the same
  pass-through transition.

  Actor-level phase metadata remains report-only.

  For sync states, that independence applies to the collected done ports; for
  spawn states, it applies to the generated start handoff.

  Consecutive top-level runtime waits carry pending samples across zero-count
  wait links with generated downstream wait-entry clones for
  zero-then-positive paths and final sample-compatible target clones for
  all-zero paths.

  Repeat, while, and until body waits can zero-bypass into independent loop
  decision/check clones that preserve the original repeat counter decrement
  or while/until condition branch behavior.
- Wait-count division and modulo expressions reject literal-zero,
  actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisors before scheduled `.fsm` emission.
  Dynamic divisor nonzero proof remains outside the shipped wait contract.
- Generated activation use-site overrides are not wait-count constants.
  Overrides of generated child wait-count parameters must preserve the child
  default value; mismatches fail closed until per-activation wait-state
  specialization is shipped.
- Non-scalar or cross-transaction parameter wait counts fail closed.
- Package wait counts must be atomic qualified package scalar constants.
  Unqualified package constants, aggregate constants, package member/item
  paths, and package constants inside wait-count expressions fail closed.
- Reports expose `transaction_waits[]`.

Completion:

```lisp
(complete done)
```

Completion emits a one-cycle delayed pulse with `<1`.

### 11.4 Control Flow

Inline branch:

```lisp
(when condition
  body...)
```

Loops:

```lisp
(while condition
  body...)

(until condition
  body...)
```

Bare known-width `while`/`until` conditions use scalar nonzero truthiness. A
condition wider than one bit is normalized before scheduled emission to an
explicit width-matched zero comparison, so values such as three-bit `4` take
the true edge and zero takes the false edge. The generated `.fsm` therefore
shows `?(!= count 3'd0)` at a three-bit `while` entry/retest or `until` check,
while a one-bit condition retains `?flag`. Expression conditions are not
rewritten by this rule, and `transaction_loops[].condition` preserves the
authored condition text.

Repeat:

```lisp
(repeat count
  body...)
```

Repeat counts are runtime counter load values, not elaboration directives.
Positive decimal literals infer the minimum counter width for that literal.
Declared positive actor constants, actor-local scalar parameter defaults, and
qualified imported package scalar constants infer width from their resolved
integer value while preserving the authored count token in the scheduled
`.fsm` load. Same-transaction scalar parameter defaults infer width from
their resolved positive integer value and load that resolved value in the
scheduled `.fsm`, because transaction parameters are local lowering inputs.
Static zero counts from literal zero, actor constants, actor scalar
parameters, same-transaction scalar parameters, or package scalar constants
lower as transparent no-op regions with no counter, repeat init/check state,
repeat-body state, or `transaction_loops[]` entry. Plain `(do child)` and
plain `(spawn child as inst)` clauses in statically zero repeat bodies are
pruned with the skipped body: no local child handoff, generated child `.fsm`,
generated top, activation instance, or loop report entry is published. A
target transaction that is otherwise live or explicitly actor-input guarded
is preserved; only the zero-count activation disappears. Syntactically valid
parameterized, bound, or domain-annotated zero-count child activations are
pruned the same way after activation subclause shape validation; their dead
payloads are not validated against child parameter, port, or domain
declarations.
Known-width
sampled/interface names use their known source width and now split the repeat
init edge: nonzero values enter the repeat body, while zero values bypass the
body and repeat check to the state after the repeat region. Unknown names,
unqualified package constants, aggregate package constants, package
member/item paths, non-scalar actor parameters, non-scalar transaction
parameters, cross-transaction parameters, malformed scalar tokens, package
constants inside repeat-count expressions, and expression-valued counts fail
closed before scheduled `.fsm` emission.
Generated child activation overrides for repeat-count transaction parameters
must preserve the child default value; mismatches fail closed until
per-activation repeat counter specialization is shipped.

Switch:

```lisp
(switch selector
  (0 body...)
  (1 body...)
  (default body...))
```

Rules:

- `when`, `repeat`, `switch`, `while`, and `until` bodies accept the supported
  transaction-body subset implemented for those contexts.
- The shipped repeat-body clause surface is named drive calls, `await`,
  `sample`, `update`, `set`, `shift_left`, `shift_right`, `assemble`,
  `extract`, actor-owned bank `store` and `load`, and shipped `wait` clauses.

  Top-level repeat bodies also accept local blocking `(do child)` when the
  child transaction remains local to the scheduled parent; the do state
  starts the child and waits for its fresh `child_done` pulse before the
  repeat check can loop.

  Repeats directly inside a top-level `when` body accept local `(do child)`
  under that same parent-module contract, plain generated-child `(do child)`
  when the target child is already emitted as a generated child by another
  activation site, and generated blocking `(do child (params ...))` with
  static parameter overrides.

  The generated nested `when` forms emit one deterministic
  `{parent}_{child}_repeat_do_{ordinal}` instance for the lexical nested do
  site, apply parameter overrides once when present, and wait for that
  instance's fresh done handoff before the branch-owned repeat check.

  Repeats directly inside a top-level `switch` branch accept the same local,
  plain generated-child `(do child)`, and generated blocking `(do child
  (params ...))` forms, with source-order samples around the nested do, one
  deterministic generated do instance for generated forms, static parameter
  application once when present, and a branch-owned repeat check gated by the
  fresh local or generated child done pulse.

  The when-contained and switch-contained generated nested `do` also accept
  `(bind ...)` when static `(params ...)` overrides are present; the
  generated top wires those input/output binding handoffs once for the
  lexical nested do site.

  The when-contained and switch-contained generated nested `do` also accept
  `(domain NAME)` as declared same-domain metadata when static `(params ...)`
  overrides are present.

  A plain local `(do child)` and a same-domain generated `(do child (params ...))`
  (with `(bind ...)`/`(domain NAME)` when static params are present) inside a
  `(repeat ...)` directly in a single `(while ...)`/`(until ...)` body lower
  (reusing the proven repeat schedule inside the loop body); a generated `do`
  instantiates its child in the `_top` composition. A plain local `(do child)`
  inside a `(repeat ...)` reached through deeper branch nesting (`when⁺ →
  repeat`, `switch → when⁺ → repeat`) also lowers. The basic `(spawn child as
  inst)` + same-body `(await_all done)` (or single-pending `(await_any done)`)
  drain also lowers inside a loop-contained or deeper-nested repeat (lowering +
  composition parity with the top-level repeat-body spawn; the same pre-existing
  full-HDL composition-wiring limitation applies). A multi-pending
  `(await_any done)` followed by a later same-body `(await_all done)` drain is
  also supported in these contexts (as at top-level / when-body / switch-branch).
  A `while`- or body-first `until`-contained repeat may also keep one or more
  generated spawns pending across one plain local blocking `(do child)` when a
  later same-body `(await_all done)` drains the exact spawned-child set before
  repeat and the surrounding loop re-entry. The
  `while`- or `until`-contained single-pending variant may use post-`do`
  `(await_any done)` instead when the effect checker proves that the
  observation completes the outstanding set. Multi-pending post-`do`
  `(await_any done)` is accepted as an observation point only when a later
  same-body `(await_all done)` drains the same pending generated children
  before repeat and loop re-entry; this rule has no public fanout cap.
  Generated `do` while spawned children are pending, missing later drains,
  cross-domain activation, and unrelated deeper placements remain fail-closed.
  Inside a loop-contained repeat, an undrained spawn emits `loop-contained
  repeat-body spawn requires same-body '(await_all done)' or single-pending
  '(await_any done)'`. A parent-body sync after the repeat exits is not a
  valid drain for repeat-body spawned children; it emits `repeat-body spawn
  cannot be drained by parent-body '(await_all done)' after the repeat exits;
  use same-body '(await_all done)' before the repeat check can loop` (with the
  authored sync form in the message). A multi-pending `(await_any done)`
  without a later `(await_all done)` emits `loop-contained repeat-body
  multi-pending await_any requires later same-body '(await_all done)' before
  the repeat check can loop` (top-level and deeper-nested forms use their
  matching context prefixes), and a cross-domain generated `do` emits `cross-domain repeat-body do remains deferred`
  (bindings/domain without static `(params ...)` emit the
  bindings/domain-require-params diagnostic); a repeat reached through an
  additional loop ancestor still emits `loop-contained repeat-body do remains
  deferred`. A plain local `(do child)`, a same-domain generated `(do child
  (params ...))`, and the basic spawn + drain subset at deeper branch nesting
  (`when⁺ → repeat`, `switch → when⁺ → repeat`) also lower (the generated `do`
  instantiates its child in the `_top`); a deeper-nested cross-domain generated
  `do` emits `cross-domain repeat-body do remains deferred` and an undrained
  deeper-nested `spawn` emits `deeper-nested repeat-body spawn requires same-body
  '(await_all done)' or single-pending '(await_any done)'`;
  the generic message remains as a safety-net fallback.

  Top-level repeat bodies also accept generated blocking `(do child)` when
  the target child is already emitted as a generated child by another
  activation site, and `(do child (params ...) [(bind ...)] [(domain NAME)])`
  with static parameter overrides, optional input/output port bindings, and
  optional declared same-domain ownership metadata.

  The generated top emits one generated do instance for the lexical do site,
  applies the parameter override once when present, wires binding handoff
  ports once when present, and records same-domain ownership for
  generated-composition and clock-domain report summaries when `(domain
  NAME)` is present.

  Samples may appear before or after repeat-body `do`; pending samples before
  `do` materialize before the do state, while pending samples after `do`
  materialize after the do state's fresh done guard and before the repeat
  check.

  Cross-domain repeat-body `do` remains deferred.

  Top-level repeat bodies also accept `(spawn child as instance [(params
  ...)] [(bind ...)] [(domain NAME)])` clauses when the same repeat body
  reaches `(await_all done)` before the repeat check can loop.

  `(await_any done)` is accepted in repeat bodies when exactly one
  repeat-body spawn is pending, so the static child cannot be restarted
  before its fresh done pulse.

  When multiple repeat-body spawns are pending, `(await_any done)` is
  accepted only as an observation point before a later same-body `(await_all
  done)` drains the same outstanding spawned children before the repeat
  check; new repeat-body `spawn` or `do` clauses before that drain remain
  rejected.

  Static parameter overrides specialize the one lexical generated child
  instance and are not per-iteration runtime values.
  If an override targets a generated child parameter consumed by static timing
  lowering, only same-value overrides are accepted; mismatches fail closed
  before generated artifacts are emitted.

  Input and output bindings reuse the same generated-top handoff model as
  top-level spawn: handoff ports are generated once for the static child
  instance.

  Optional `(domain NAME)` annotations are declared same-domain ownership
  metadata only; they do not imply CDC behavior or allow cross-domain
  activation.

  Samples may appear before or after repeat-body spawn as long as the same
  repeat body reaches same-body `await_all`, single-pending `await_any`, or
  multi-pending `await_any` followed by same-body `await_all` before the
  repeat check can loop.

  Those samples lower to an explicit sample state at their source-order
  timing point: before a later spawn state for sample-before-spawn ordering,
  or before the sync state for sample-after-spawn ordering.

  A repeat directly inside a top-level `when` body also accepts one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain
  NAME)])` sites when the same nested repeat body reaches `(await_all done)`
  before the nested repeat check can loop.

  A repeat directly inside a top-level `switch` branch accepts the same
  multiple generated-spawn plus same-body `await_all` subset.

  Both branch-contained paths may use single-pending `(await_any done)`
  directly when exactly one generated child is pending.

  Both branch-contained paths may also use multi-pending `(await_any done)`
  as an observation point when a later same-body `(await_all done)` drains
  the same outstanding generated children before the nested repeat check can
  loop.

  Those branch-contained nested spawns reuse the static generated-child
  handoff model and preserve source-order samples before the nested spawn or
  sync states.

  The top-level `when` body and top-level `switch` branch nested-repeat forms
  may also run a local plain `(do child)` while generated nested spawns
  remain pending either before or after a prior multi-pending `(await_any
  done)` observation, provided a later same-body `(await_all done)` drains
  every outstanding generated child before the nested repeat check can loop.

  That local do remains in the parent scheduled module, waits for its own
  fresh local done pulse, and does not clear the generated-spawn done set.
  Those branch-contained local-do forms may then start one or more additional
  generated nested spawns before the mandatory same-body `(await_all done)`
  drain, either with no active multi-pending `await_any` before the later
  spawn or after the local `do` follows a prior multi-pending observation.
  The later generated spawn is added to the same outstanding generated child
  set after the local child's fresh done pulse, and the later `await_all`
  drains both pre-do and post-do generated spawns before nested repeat
  re-entry. In the prior-observation form, those branch-contained local-do
  paths may also run a second post-spawn multi-pending `(await_any done)`
  observation before the mandatory same-body `(await_all done)` drain. Both
  observations leave the outstanding generated-spawn done set live, and the
  final `await_all` drains generated spawns from both sides of the local
  `do`. That same local-do do-then-spawn shape may also run a post-spawn
  multi-pending `(await_any done)` observation before the final same-body
  `(await_all done)` drain when no prior multi-pending observation is active
  before the later spawn. The post-spawn observation leaves both pre-do and
  post-do generated-spawn done handoffs live.

  The top-level `when` body and top-level `switch` branch nested-repeat
  subsets also accept a plain generated-child `(do child)` in that pending
  interval when the target child is already emitted as a generated child by
  another activation site.

  The top-level `when` body and top-level `switch` branch subsets may also
  place that generated-child do after a prior multi-pending `(await_any
  done)` observation.

  The generated do site owns one deterministic
  `{parent}_{child}_repeat_do_{ordinal}` instance, waits for that instance's
  fresh done handoff, and leaves the generated-spawn done set live for the
  later same-body `(await_all done)` drain. That plain generated-child do may
  then start one or more additional generated nested spawns before the
  mandatory same-body `(await_all done)` drain, either with no active
  multi-pending `(await_any done)` before the later spawn or after the
  generated-child `do` follows a prior multi-pending observation. The
  generated do instance must complete before the later generated spawn starts,
  and the final `await_all` drains both the pre-do and post-do generated
  spawns before nested repeat re-entry. In the prior-observation form, those
  branch-contained plain generated-child paths may also run a second
  post-spawn multi-pending `(await_any done)` observation before the mandatory
  same-body `(await_all done)` drain. Both `await_any` observations leave the
  outstanding generated-spawn done set live for that final drain.

  Top-level `when` body and top-level `switch` branch nested-repeat generated
  `(do child (params ...))` may also run in that pending interval when the
  parameter overrides are static and a later same-body `(await_all done)`
  drains every outstanding generated child before the nested repeat check can
  loop; that generated do site uses the same deterministic instance naming,
  records static generated-top parameter binding, waits for its own fresh
  done handoff, and leaves the generated spawn done set live for the later
  drain.

  When no multi-pending `(await_any done)` observation is active before the
  drain, that static-parameter generated do may also be followed by one or
  more later generated nested spawns before the mandatory same-body
  `(await_all done)` drain. The generated do instance's fresh done handoff
  gates the later spawn state, and the final drain covers both pre-do and
  post-do generated spawns before nested repeat re-entry. That same
  static-parameter generated-do do-then-spawn shape may also run a post-spawn
  multi-pending `(await_any done)` observation before the final same-body
  `(await_all done)` drain when no prior multi-pending `(await_any done)`
  observation is active before the later spawn; the observation leaves both
  pre-do and post-do generated-spawn done handoffs live.

  The top-level `when` body and top-level `switch` branch subsets may also
  place that static-parameter generated `do` after a prior multi-pending
  `(await_any done)` observation while still requiring the same later same-
  body `(await_all done)` drain.

  Top-level `when` body and top-level `switch` branch nested-repeat generated
  `(do child (params ...) (bind ...))` may run before a post-do multi-pending
  `(await_any done)` observation or after a prior multi-pending `(await_any
  done)` observation, provided the same later same-body `(await_all done)`
  drain remains before nested repeat re-entry.

  That generated do site wires generated-top input/output binding handoffs
  once, waits for its own fresh done handoff, and leaves the generated spawn
  done set live for the later drain.

  When no multi-pending `(await_any done)` observation is active before the
  drain, that bound generated do may also be followed by one or more later
  generated nested spawns before the mandatory same-body `(await_all done)`
  drain. The generated do instance's fresh done handoff gates the later spawn
  state, generated-top binding handoffs remain scoped to the do instance, and
  the final drain covers both pre-do and post-do generated spawns before
  nested repeat re-entry.

  Top-level `when` body and top-level `switch` branch nested-repeat generated
  `(do child (params ...) [(bind ...)] (domain NAME))` may also run in that
  pending interval.

  The domain annotation is declared same-domain ownership metadata only for
  the deterministic generated do instance; generated- composition/domain
  partition metadata and schedule JSON `clock_domains[].child_instances[]`
  retain that ownership without implying CDC.

  The top-level `when` body and top-level `switch` branch same-domain subsets
  may also run after a prior multi-pending `(await_any done)` observation,
  still requiring the later same-body `(await_all done)` drain before nested
  repeat re-entry.

  Top-level `when` body local `(do child)` may also run before a post-do
  multi-pending `(await_any done)` observation when a later same-body
  `(await_all done)` still drains the same generated-spawn set before nested
  repeat re-entry.

  Top-level `switch` branch local `(do child)` supports the same post-do
  multi-pending `(await_any done)` observation and later-drain contract while
  generated nested spawns remain pending before that drain.

  Top-level `when` body plain generated-child `(do child)` supports the same
  post-do multi-pending `(await_any done)` observation and later-drain
  contract while generated nested spawns remain pending before that drain.

  The generated-child do waits for its deterministic generated do instance's
  fresh done handoff.

  Top-level `switch` branch plain generated-child `(do child)` supports the
  same post-do multi-pending `(await_any done)` observation and later-drain
  contract while generated nested spawns remain pending before that drain.

  Top-level `when` body and top-level `switch` branch static-parameter
  generated `(do child (params ...))` support the same post-do multi-pending
  `(await_any done)` observation and later-drain contract while generated
  nested spawns remain pending before that drain; the generated do waits for
  its deterministic generated do instance's fresh done handoff and preserves
  static generated-top parameter binding.

  Those static-parameter generated-do subsets may also start one or more
  later generated nested spawns before the mandatory same-body `(await_all
  done)` drain, either when no multi-pending `(await_any done)` observation is
  active before the later spawn or after the generated do follows a prior
  multi-pending observation. The prior-observation form may run a second
  post-spawn multi-pending `(await_any done)` observation before that final
  drain; both observations leave the pre-do and post-do generated-spawn done
  handoffs live for the final `await_all`.

  Top-level `when` body and top-level `switch` branch static-parameter bound
  generated `(do child (params ...) (bind ...))` support the same post-do
  observation and later-drain contract while also wiring the generated-top
  input/output binding handoffs for the generated do instance.

  Those bound generated-do subsets may also start one or more later generated
  nested spawns before the mandatory same-body `(await_all done)` drain,
  either when no multi-pending `(await_any done)` observation is active before
  the later spawn or after the generated do follows a prior multi-pending
  observation. The generated do instance's fresh done handoff gates the later
  spawn state, generated-top binding handoffs stay scoped to the do instance,
  and the final drain covers both pre-do and post-do generated spawns before
  nested repeat re-entry. In the prior-observation form, a second
  post-spawn multi-pending `(await_any done)` may run before the mandatory
  final drain; both observations leave all pre-do and post-do
  generated-spawn done handoffs live for that final `await_all`.

  When no multi-pending `(await_any done)` observation is active before the
  later spawn, those bound generated-do do-then-spawn subsets may also run a
  post-spawn multi-pending `(await_any done)` observation before the
  mandatory same-body `(await_all done)` drain. The generated do instance's
  fresh done handoff gates the later spawn state, generated-top binding
  handoffs stay scoped to the do instance, and the post-spawn observation
  leaves both pre-do and post-do generated-spawn done handoffs live for the
  final drain.

  Top-level `when` body and top-level `switch` branch static-parameter
  same-domain generated `(do child (params ...) [(bind ...)] (domain NAME))`
  support the same post-do observation and later-drain contract while also
  retaining declared ownership metadata in generated-composition,
  domain-partition, and schedule-report clock-domain summaries.

  Those same-domain generated-do subsets may also be followed by one or more
  later generated nested spawns before the mandatory same-body `(await_all
  done)` drain, either when no multi-pending `(await_any done)` observation is
  active before the later spawn or after the generated do follows a prior
  multi-pending observation. The generated do instance's fresh done handoff
  gates the later spawn state, declared ownership metadata remains scoped to
  the generated do instance, and the final drain covers both pre-do and
  post-do generated spawns before nested repeat re-entry. In the
  prior-observation form, a second post-spawn multi-pending
  `(await_any done)` may run before the mandatory final drain; both
  observations leave all pre-do and post-do generated-spawn done handoffs live
  for that final `await_all`, and declared ownership metadata stays scoped to
  the generated do instance.

  Those same-domain generated-do do-then-spawn subsets may also run a
  post-spawn multi-pending `(await_any done)` observation before the
  mandatory same-body `(await_all done)` drain when no prior multi-pending
  `await_any` observation is active before the later spawn. The post-spawn
  observation does not drain the outstanding generated-spawn set, declared
  ownership metadata remains scoped to the generated do instance, and the
  final `await_all` still covers both pre-do and post-do generated spawns
  before nested repeat re-entry.

  Plain generated-child, static-parameter generated-do, bound generated-do,
  and same-domain generated-do do-then-spawn
  subsets may also run a second post-spawn multi-pending `(await_any done)`
  observation after a prior multi-pending observation before the generated do,
  provided the mandatory same-body `(await_all done)` still follows. The
  post-spawn observation does not drain the outstanding generated-spawn set;
  the final `await_all` still covers both pre-do and post-do generated spawns
  before nested repeat re-entry.

  Deeper branch/loop nesting and unsupported cross-domain activation
  placements remain fail-closed; the shipped blocking activation-crossing
  contexts are the explicit CDC contexts listed in the Named domains section.

  Cross-domain `spawn`, generated-do mismatched-domain metadata, broader
  outstanding-child semantics, `stage`, `contract`, deeper branch nesting,
  nested `while`, and nested `until` remain outside the shipped repeat-body
  subset.
- Transaction `when`/`while`/`until` condition expressions may use local enum
  members such as `mode.BUSY` or package enum members such as
  `shared.mode.BUSY` as scalar operands. Local or package enum members may
  also be used directly as standalone scalar conditions, for example
  `(when mode.BUSY ...)`, `(while mode.BUSY ...)`, or
  `(until shared.mode.BUSY ...)`. Dotted standalone enum conditions lower
  through computed `.fsm` selector syntax such as `?(mode.BUSY)` or
  `?(shared.mode.BUSY)`. Enum members in condition expression operator
  position fail closed.
- Unsupported nested clauses fail closed.
- Runtime waits inside supported inline contexts are shipped for the covered
  predecessor and pending-sample cases.
- Reports expose loop metadata through `transaction_loops[]`, and each
  `(exit-when …)` / `(continue-when …)` early-exit site through
  `loop_early_exits[]`.

### 11.5 Data Manipulation

Supported forms:

```lisp
(set target expr)
(update target expr)
(shift_left reg bit)
(shift_left reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(shift_right reg bit)
(shift_right reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(assemble part... as target)
(assemble part... as target (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))
(extract word as field...)
(extract word as field... (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))
```

Rules:

- `set` is the scalar setter shared by rules and transactions.
- `update` is the older transaction-local assignment spelling.
- Shift/extract/assemble forms use known width evidence and fail closed on
  contradictory or missing width evidence where exact lowering requires it.
  `shift_left` accepts optional `(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` as
  width evidence for the shifted register, but plain `shift_left` remains
  accepted without width evidence because left insertion does not require a
  computed MSB position. `shift_right` accepts the same explicit source set
  for its inserted-bit position. `TX_PARAM` names a same-transaction scalar
  parameter default on a generated child or direct/non-generated transaction
  and must resolve to a positive integer. `PARAM` must name an actor-local
  scalar parameter default that resolves to a positive integer, `CONST` must
  name a declared actor constant that resolves to a positive integer, and
  `PACKAGE.CONSTANT` must name a qualified imported package scalar constant
  that resolves to a positive integer.
- `assemble` can infer exactly one missing part width from a known target
  width and known sibling part widths. It also accepts one optional trailing
  `(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)` list after the target to
  supply ordered part widths, with one positive entry per part. Explicit
  assemble part widths use the same accepted static source set as
  shift/extract width options and must not conflict with known part widths.
  Two or more unknown parts still lower only as non-evidence concat operands
  unless explicit widths make them known; non-positive inferred remainders
  fail closed.
- `extract` emits concrete slices, not placeholder bounds. It can infer
  exactly one missing destination field width from a known source word width
  and known sibling field widths. Explicit `(widths ...)` entries may mix
  positive integer literals, actor-local scalar parameters, declared actor
  constants, and qualified imported package scalar constants that resolve to
  positive integers. Unknown or unqualified package constants, aggregate
  package constants, package member/item paths, ambiguous
  local-enum/package-constant spellings, runtime signals, transaction
  parameters, and expressions fail closed. Two or more unknown fields,
  non-positive inferred remainders, and known source/field total mismatches
  fail closed.

### 11.6 Transaction Parameters And Generated Activations

Transaction parameter declarations:

```lisp
(transaction worker
  (params
    (WIDTH 8))
  ...)
```

Activation parameter overrides:

```lisp
(do worker
  (params
    (WIDTH 16)))

(spawn worker as w0
  (params
    (WIDTH 16)))

(trigger worker
  (params
    (WIDTH 16)))
```

Rules:

- Parameter overrides are static specialization values, not runtime payloads.
- Runtime-varying values must use transaction ports and `(bind ...)`.
- Activation parameter override values may be scalar/exact-width literals,
  actor-local constants, actor-local scalar parameter defaults, scalar local
  or package-qualified enum members, or compatible aggregate/list literals
  whose scalar leaves are literals, actor-local constants, actor-local scalar
  parameter defaults, or local/package-qualified enum members.
- Transaction-local scalar parameter defaults and scalar leaves inside
  compatible aggregate/list defaults may use earlier scalar transaction
  parameters, actor-local constants, actor-local scalar parameter defaults, or
  local/package-qualified enum members. Actor-static names resolve to literal
  generated child `.fsm` `+params`, generated-composition child summaries, and
  default instance bindings; transaction-parameter dependencies and enum member
  defaults preserve the authored token.
- Actor constants, actor-local scalar parameter defaults, and scalar enum
  members resolve to literal values before generated-top emission, including
  matching scalar leaves inside activation aggregate/list override values.
- Reusable-library use-site overrides may use numeric/exact-width literals,
  importing-actor constants, importing-actor scalar parameter defaults, local
  enum members, package-qualified enum members, qualified imported package
  scalar constants, and compatible aggregate/list literals with those scalar
  leaves. All non-literal leaves resolve to literal values before generated-top
  emission and before `library_uses[]` report publication.
- Spawned children and parameterized/generated blocking `do` activations lower
  through generated composition.
- Parameterized rule triggers lower through generated child activation
  instances named `{rule}_{transaction}_trigger_{ordinal}`.
- Rule-trigger parameterization preserves per-rule trigger pulse and input
  payload timing through generated handoff DTs.
- Direct `(on ...)` activation has no parameter override source shape.
- Unknown parameter names, duplicate overrides, unsupported non-constant
  symbolic or expression values, and incompatible aggregate/list shapes fail
  closed.

### 11.6.1 Enum, Type, And Aggregate Boundary

Current shipped ISF accepts scalar aliases plus one aggregate storage-carrier
subset:

```lisp
(types
  (type byte (bits 8))
  (type flag bit)
  (type frame_t (record (mode (bits 2)) (flag bit))))

(imports
  (package shared))

(interface
  (input data_in (type byte))
  (output data_out (type shared.byte)))

(storage
  (var accum (type byte))
  (var frame (type frame_t)))

(transaction main
  (ports
    (input payload (type byte))))
```

Rules:

- `(types ...)` payloads map directly to `.fsm` `+types`.
- `(imports (package NAME) ...)` references existing `.fsm` `?pkg:NAME`
  package roots. Package aliases and dotted package names are not accepted in
  this first contract.
- Width-bearing actor interface ports, transaction-local ports, and
  actor-owned storage entries may use `(type NAME)` for scalar aliases.
  Actor interface ports, transaction-local ports, actor-owned scalar storage,
  and actor-owned bank storage may use actor-local scalar parameter defaults
  or declared actor constants that resolve to positive integers as
  `(width PARAM)` / `(width CONST)` sources. Actor interface ports,
  transaction-local ports, actor-owned scalar storage, and actor-owned bank
  storage widths may also use qualified imported package scalar constants as
  `(width PACKAGE.CONSTANT)` sources when the resolved value is a positive
  integer; actor-owned bank storage depths may use qualified imported package
  scalar constants as `(depth PACKAGE.CONSTANT)` sources when the resolved
  value is a positive integer.
- Actor-owned storage variables may also use `(type NAME)` when `NAME`
  resolves to a packed aggregate `list` or `record` alias. The first aggregate
  carrier subset is anchored on declared actor-owned storage roots.
- Transaction `(set target aggregate_leaf)` clauses may read scalar aggregate
  leaves from declared actor-owned aggregate storage, for example
  `frame.mode` or `lanes[0]`. The leaf path is resolved against the declared
  shape before lowering.
- Transaction `set` RHS expressions may use scalar aggregate leaves as
  operands, for example `(set mode_out (+ frame.mode mode_in))`. Aggregate
  paths are not accepted in expression operator position.
- Transaction `when`/`while`/`until` conditions may use scalar aggregate
  leaves directly or as operands inside condition expressions, for example
  `(when frame.flag (set fire 1))` or
  `(when (& ready frame.flag) (set fire 1))`. Direct aggregate condition leaves
  lower through computed `.fsm` selector syntax such as `?(frame.flag)`.
  Aggregate paths in condition expression operator position remain deferred.
- Transaction `switch` selectors and branch scalar values may read scalar
  aggregate leaves on declared actor-owned aggregate storage, for example
  `(switch frame.mode (1 (set seen 1)) (default (set seen 0)))` or
  `(switch mode_in (frame.mode (set seen 1)) (default (set seen 0)))`.
  Aggregate switch selectors lower through computed `.fsm` selector syntax
  such as `?(frame.mode)` or `?(lanes[1])`. Subaggregate selectors or branch
  values remain deferred.
- Transaction `(set aggregate_leaf value)` clauses may write scalar aggregate
  leaves on declared actor-owned aggregate storage, for example
  `(set frame.mode mode_in)` or `(set lanes[0] bit_in)`. Subaggregate targets
  such as a record member whose type is still a `list` or `record` remain
  deferred.
- Rule assignment scalar RHS values and scalar operands inside rule assignment
  RHS expressions may read scalar aggregate leaves on declared actor-owned
  aggregate storage, for example `(rule expose ready (set mode_out frame.mode))`
  or shorthand `(rule expose ready (pair_out (^ lanes[1] pair_in)))`.
- Rule assignment targets may write scalar aggregate leaves on declared
  actor-owned aggregate storage, for example
  `(rule capture ready (set frame.mode mode_in))` or shorthand
  `(rule capture ready (lanes[1] pair_in))`. Subaggregate rule targets and
  aggregate paths in rule assignment RHS expression operator position remain
  deferred.
- Rule guard expressions may read scalar aggregate leaves on declared
  actor-owned aggregate storage as scalar operands, for example
  `(rule expose (& ready frame.flag) (set fire 1))`. Standalone rule guards
  may also read scalar aggregate leaves, for example
  `(rule expose frame.flag (set fire 1))` or
  `(rule expose (when lanes[1]) (set fire 1))`; the scheduled `.fsm` preserves
  those guards as non-state DT header suffixes such as `<frame.flag` or
  `<lanes[1]`. Subaggregate guards and aggregate paths in rule guard
  expression operator position remain deferred.
- Named drive body scalar RHS values and scalar operands inside RHS expressions
  may read scalar aggregate leaves on declared actor-owned aggregate storage,
  for example `(drive publish (mode_out frame.mode))` or
  `(drive publish (mode_out (+ frame.mode mode_in)))`. Named drive body
  targets may write scalar aggregate leaves on declared actor-owned aggregate
  storage, for example `(drive capture (frame.mode mode_in))` or
  `(drive capture (lanes[1] pair_in))`. Subaggregate drive targets and
  aggregate paths in drive body RHS expression operator position remain
  deferred.
- Inline drive assignment scalar RHS values and scalar operands inside RHS
  expressions may read scalar aggregate leaves on declared actor-owned
  aggregate storage, for example `(drive inline_publish (mode_out frame.mode))`
  or `(drive inline_publish (mode_out (+ frame.mode mode_in)))`. Inline drive
  targets may write scalar aggregate leaves on declared actor-owned aggregate
  storage, for example `(drive inline_capture (frame.mode mode_in))` or
  `(drive inline_capture (lanes[1] pair_in))`. Subaggregate inline drive
  targets and aggregate paths in inline drive RHS expression operator position
  remain deferred.
- Named drive-call scalar actual values and scalar operands inside actual
  expressions may read scalar aggregate leaves on declared actor-owned
  aggregate storage, for example `(drive publish frame.mode)` or
  `(drive publish (+ frame.mode mode_in))`. Aggregate paths in drive-call
  actual expression operator position remain deferred.
- `(type NAME)` and `(width N)` are mutually exclusive.
- `NAME` may be local (`byte`) or package-qualified (`shared.byte`).
- Lowered scheduled `.fsm` preserves review artifacts with `+types`,
  `+import`, typed `+size` entries, and embedded imported package roots so CLI
  HDL generation remains self-contained.
- Unknown aliases fail closed. Aggregate aliases used on actor interface
  ports, transaction-local ports, storage banks, or any non-storage-variable
  declaration fail closed.
- Actor-local `(enums ...)` declarations are preserved into scheduled `.fsm`
  as `+enums`.
- An `(enums (NAME ...))` declaration establishes only the member-value family
  `NAME`; it does **not** also establish a scalar type alias `NAME`. Using
  `(type NAME)` on a width-bearing interface port, transaction-local port, or
  storage variable when only `(enums (NAME ...))` is declared fails closed as
  `references unknown type 'NAME'`. To use an enum name as a width-bearing
  type, co-declare a backing scalar alias `(types (type NAME (bits k)))`
  alongside `(enums (NAME ...))`. Co-declaring the same `NAME` in both
  `(types ...)` and `(enums ...)` is accepted and is the intended mechanism —
  the two occupy distinct declaration roles (the `(type)` supplies the width
  alias consumed by `(type NAME)`; the `(enums)` supplies the member values
  consumed by `NAME.MEMBER`) and is not a redeclaration conflict. The backing
  `(bits k)` width is the author's assertion and is **not** cross-validated
  against enum member magnitudes; a downstream emitter recovering a dense
  `0..N-1` enum should pick `k = ceil(log2(member_count))`. Actor-local
  `(types ...)`, `(enums ...)`, and `(constants ...)` declarations need not be
  referenced to be contract-valid — an unreferenced declaration lowers cleanly
  and is preserved in its scheduled `.fsm` review section.
- Actor constants may consume local enum members such as `mode.BUSY` and
  package enum members such as `shared.mode.BUSY`. Unknown enum families or
  members fail closed before generated artifacts are emitted.
- Direct transaction `(set target enum_member)` RHS scalar values may also
  consume local or package enum members, transaction `set` RHS expressions
  may use enum members as scalar operands, transaction `when`/`while`/`until`
  condition expressions may use enum members as scalar operands, direct
  transaction `when`/`while`/`until` scalar conditions may consume local or
  package enum members, transaction `switch` selectors or branch values may
  consume local or package enum members, and scalar drive body RHS values or
  operands inside drive body RHS expressions may consume local or package
  enum members.

  Named drive-call scalar actual values may also consume local or package
  enum members, drive-call actual expressions may use enum members as scalar
  operands, scalar actor parameter defaults and scalar leaves inside actor
  aggregate/list parameter defaults may consume declared actor constants,
  earlier scalar actor parameters, and local or package enum members,
  generated child transaction scalar parameter defaults and scalar leaves
  inside generated child transaction aggregate/list parameter defaults may
  consume declared actor constants, actor-local scalar parameter defaults,
  earlier scalar transaction parameters, and local or package enum members,
  scalar activation parameter
  overrides may consume local or package enum members, scalar leaves inside
  activation aggregate/list parameter override values may consume local or
  package enum members, reusable-library use-site parameter override values
  or leaves may consume importing-actor constants, importing-actor scalar
  parameter defaults, and local or package enum members, and scalar rule
  assignment RHS values or expression operands may consume local or package
  enum members.

  Rule guard scalar values or expression operands may consume local or
  package enum members, and inline drive assignment RHS scalar values or
  operands inside inline drive RHS expressions may consume local or package
  enum members.

  Enum members in expression operator position, targets, rules outside scalar
  trigger parameter overrides, rule guard or transaction condition expression
  operator position, rule assignment expression operator position, drive
  targets, drive body RHS expression operator position, inline drive
  assignment RHS expression operator position, drive-call expression operator
  position, and other contexts remain deferred.

Aggregate member/item access outside direct transaction `set` RHS values,
direct transaction `set` target tokens, transaction condition scalar values
or expression operands, transaction `switch` selectors or branch values, rule
assignment target tokens, rule assignment RHS values or expression operands,
rule guard scalar values or expression operands, drive target tokens, drive
body RHS scalar values/expression operands, inline drive target tokens,
inline drive assignment RHS scalar values/expression operands, or drive-call
actual scalar values/expression operands; aggregate paths in drive body RHS,
inline drive RHS, or drive-call actual expression operator position;
subaggregate operands/updates; aggregate interface or transaction ports; and
aggregate storage banks are not shipped yet.

Existing aggregate support beyond the actor-owned storage-variable carrier
and direct scalar leaf read/write context is limited to compatible
aggregate/list literal parameter values and scalarized actor-owned
bank/storage lowering.

### 11.7 Blocking Do, Spawn, Await Sync

Blocking `do`:

```lisp
(do child)
(do child (params ...) (bind ...))
```

Rules:

- Local unparameterized `do` rewires the child entry to `child_start` and waits
  for `child_done`.
- Top-level repeat bodies may use that same local `(do child)` form when the
  child remains in the parent scheduled module.

  Repeats directly inside a top-level `when` body may also use local `(do
  child)` under that contract, or plain generated-child `(do child)` when the
  target child is already emitted by another generated activation site.

  Repeats directly inside a top-level `switch` branch may use the same local
  or plain generated-child `(do child)` forms.

  Top-level `when` body and top-level `switch` branch nested repeats may also
  use static `(params ...)` on generated blocking `do`, and both top-level
  branch-contained subsets may pair those params with `(bind ...)`
  input/output handoffs.

  Both top-level branch-contained subsets may also carry same-domain `(domain
  NAME)` metadata.

  A top-level `when` body nested repeat may also use one or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  when the same nested repeat body reaches `(await_all done)` before the
  nested repeat check can loop.

  A top-level `switch` branch nested repeat may use the same multiple
  generated-spawn plus same-body `await_all` subset.

  Exactly one pending generated child in either branch-contained path may
  instead use single-pending `(await_any done)`.

  Both branch-contained paths may also use multi-pending `(await_any done)`
  only as an observation point before a later same-body `(await_all done)`
  drains those same outstanding generated children.

  Top-level `when` body and top-level `switch` branch nested repeats may also
  run local plain `(do child)` while generated nested spawns remain pending
  before or after a prior multi-pending `(await_any done)` observation, but
  only before a later same-body `(await_all done)` drain.

  Top-level `when` body and top-level `switch` branch nested repeats may
  additionally run a plain generated-child `(do child)` in that pending
  interval when the target is already emitted as a generated child elsewhere.

  The top-level `when` body and top-level `switch` branch generated-child
  subsets may also place that plain generated-child `do` after a prior
  multi-pending `(await_any done)` observation.

  The generated do instance waits for its own fresh done handoff and leaves
  the pending generated-spawn done set live for the later drain.

  Top-level `when` body and top-level `switch` branch nested repeats may also
  run static-parameter generated `(do child (params ...))` in that pending
  interval; the generated do instance carries static parameter binding, waits
  for its own fresh done handoff, and leaves the pending generated-spawn done
  set live for the later drain.

  The top-level `when` body and top-level `switch` branch subsets may also
  place that static-parameter generated `do` after a prior multi-pending
  `(await_any done)` observation while still requiring the later drain.

  Top-level `when` body nested repeats may also run static-parameter
  generated `(do child (params ...)

  (bind ...))` either before or after a prior multi-pending `(await_any
  done)` observation, provided the later drain still gates nested repeat
  re-entry.

  The generated do instance wires generated-top input/output binding handoffs
  once and leaves the pending generated-spawn done set live for the later
  drain.

  Top-level `switch` branch nested repeats may run the same static-parameter
  bound generated `do` either before a post-do multi-pending `(await_any
  done)` observation or after a prior multi-pending `(await_any done)`
  observation with the same later drain requirement.

  Top-level `when` body and top-level `switch` branch nested repeats may also
  run static-parameter same-domain generated `(do child (params ...) [(bind
  ...)] (domain NAME))` in that pending interval.

  Beyond those branch-contained spawn/generated-do subsets, a plain local
  `(do child)`, a same-domain generated `(do child (params ...))`, and the basic
  `(spawn ...)` + same-body `(await_all done)`/single-pending `(await_any done)`
  drain at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`)
  are their own shipped subset, and loop-contained repeats accept the same
  (their own shipped subset described above) — undrained spawn, multi-pending
  `(await_any done)`, and cross-domain generated `do` stay deferred in both
  contexts.

  Top-level repeat bodies may also use `(do child (params ...))` with static
  parameter overrides; that form creates one generated child activation
  instance named `{parent}_{child}_repeat_do_{ordinal}` and waits for that
  instance's done handoff before the repeat check can loop.

  When the repeat-body generated `do` includes `(bind ...)`, the generated
  top wires one set of input/output handoff ports for that lexical do
  instance.

  When it includes `(domain NAME)`, generated-composition and clock-domain
  report summaries group that lexical do instance with the declared
  same-domain owner.

  Cross-domain repeat-body `do` forms are not shipped.
- Parameterized/generated `do` creates a generated child activation instance
  named `{parent}_{child}_do_{ordinal}` and waits for that instance's done
  handoff.

Spawn:

```lisp
(spawn child as w0)
(spawn child as w0 (params ...) (bind ...))
(await_all w0_done)
(await_any w0_done)
```

Rules:

- Spawned transactions are emitted as child `.fsm` files and generated top
  instances.
- Spawn instance names are explicit and unique.
- Spawned child `start` and `done` are explicit handoffs.
- `await_all` waits for all currently pending spawned done ports.
- `await_any` waits for any currently pending spawned done port.
- The shipped repeat-body spawn subset reuses the same static generated child
  instance on every iteration. Optional `(params ...)` overrides specialize
  that static instance once in the generated top. Optional `(bind ...)` input
  and output port handoffs are also generated once for that same instance.
  Optional `(domain NAME)` annotations record declared same-domain activation
  ownership only; they are not CDC primitives and do not allow cross-domain
  activation. The same repeat body must consume pending done ports through
  `await_all`, through `await_any` when exactly one spawn is pending, or in
  the documented branch-contained nested subsets through multi-pending
  `await_any` followed by same-body `await_all`, before the repeat check can
  loop, preventing re-entry before fresh child completion.
- In the documented top-level `when` body and top-level `switch` branch
  nested subsets, a local plain `(do child)` may run while generated nested
  spawns are pending before or after a prior multi-pending `await_any`
  observation. In both cases, the local do consumes only the local child's
  fresh done pulse; it does not clear pending generated child done handoffs,
  and a later same-body `await_all` drain still gates nested repeat re-entry
  on every outstanding generated child. That same local do may also be
  followed by one or more additional generated spawns before that later
  same-body `await_all`, either with no active multi-pending `await_any`
  observation before the later spawn or after the local `do` follows a prior
  multi-pending observation. Those later spawns join the outstanding generated
  child set and must be drained with the pre-do generated spawns. In the
  prior-observation form, those local-do paths may also run a second
  post-spawn multi-pending `await_any` before the mandatory same-body
  `await_all`; both observations leave the outstanding generated-spawn done
  set live, and the final drain covers every pre-do and post-do generated
  spawn.
- In the documented top-level `when` body and top-level `switch` branch nested
  subsets, a plain generated-child `(do child)` may also run while generated
  nested spawns are pending when the target child has already been emitted as a
  generated child. In the top-level `when` body and top-level `switch` branch
  subsets, that generated-child do may also run after a prior multi-pending
  `await_any` observation. That generated do consumes only its deterministic
  generated do instance's fresh done handoff; it does not clear pending
  generated spawn handoffs, and the same later `await_all` drain still gates
  nested repeat re-entry on every outstanding generated child. That plain
  generated-child do may also be followed by one or more additional generated
  spawns before that later same-body `await_all`, either with no active
  multi-pending `await_any` observation before the later spawn or after the
  generated-child `do` follows a prior multi-pending observation. The
  generated do instance must complete before the later spawn starts. In the
  prior-observation form, the path advances directly to the mandatory
  same-body `await_all`; a second multi-pending `await_any` after the later
  spawn remains fail-closed.
- In the documented top-level `when` body and top-level `switch` branch nested
  subsets, static-parameter generated `(do child (params ...))` may also run
  while generated nested spawns are pending, including after a prior multi-
  pending `await_any` observation. That generated do carries static generated-
  top parameter binding, consumes only its deterministic generated do
  instance's fresh done handoff, does not clear pending generated spawn
  handoffs, and the same later `await_all` drain still gates nested repeat
  re-entry on every outstanding generated child. That static-parameter
  generated do may also be followed by one or more additional generated spawns
  before that later same-body `await_all`, either with no active
  multi-pending `await_any` observation before the later spawn or after the
  generated do follows a prior multi-pending observation. In the prior-
  observation form, the path advances directly to the mandatory same-body
  `await_all`; a second multi-pending `await_any` after the later spawn
  remains fail-closed.
- Samples after repeat-body spawn lower before the same-body `await_all`,
  single-pending `await_any`, or multi-pending `await_any` drain sync state
  that keeps the repeat check unreachable until outstanding spawned children
  have been observed.

### 11.8 Stages, Contracts, Latency

Stage:

```lisp
(stage phase_name
  (ready ready_signal)
  (valid valid_signal))
```

Current shipped stage kind is `ready_valid_barrier`.
FSMGen also accepts the older `(stage name (input ready_signal) (output
valid_signal))` spelling as a compatibility alias. Downstream emitters should
prefer the `ready`/`valid` form shown above. The `valid_signal` endpoint is a
normal transaction combinational drive, so it remains subject to the existing
same-target conflict checks if another rule or transaction writes that signal.

Bounded-eventually monitor (replaces the removed top-level `(contract …)` clause):

```lisp
(assert (monitor (within signal N)) "name")
```

The shipped kind is `bounded_eventually`. Assertion projection is
`systemverilog_sticky_fail`: SystemVerilog HDL generation emits a
verification-only assertion from the generated sticky fail bit under
`` `ifndef SYNTHESIS``. Verilog output remains assertion-free. `N` may be a
positive integer literal, a declared actor constant, an actor-local scalar
parameter default, a qualified imported package scalar constant, or a
same-transaction scalar parameter default on a generated child or
direct/non-generated transaction that resolves to a positive integer;
package-authored windows remain visible through package/import metadata and
embedded package `+constants` entries.

The former top-level `(contract name (eventually signal within N))` clause was
removed in favor of this form. The `temporal_contracts[]` schedule-report array is
**retained for schema-version-1 stability but is now always empty** — the
bounded-eventually intent surfaces through the immediate-check `+assert` /
`immediate_assertions` path (a same-cycle `!fail` assertion), not
`temporal_contracts[]`. Generated child contract monitors are reviewable in the
generated child scheduled `.fsm`; the parent schedule report remains
parent-scoped for child-local temporal contracts. Direct transaction
parameters remain local lowering inputs and are not promoted to actor-level
`.fsm` `+params`. Activation-site overrides on `spawn`, generated blocking
`do`, or rule `trigger` that target a generated child parameter used by the
child contract window are accepted only when the override resolves to the same
positive integer cycle count as the child transaction parameter default.
Mismatched overrides fail closed with a targeted diagnostic. Full
override-specialized contract-window lowering, runtime signals, arbitrary
expressions, unknown names, unknown or unqualified package constants,
aggregate package constants, package member/item paths, ambiguous
local-enum/package-constant spellings, zero-valued constants, and zero-valued
or non-scalar actor/transaction parameters remain invalid contract windows.
Generated child activation overrides that target transaction parameters used
by static timing lowering for repeat counts, wait counts, latency bounds, or
top-level await-local watchdog limits are accepted only when they preserve the
child default value; mismatches fail closed until per-activation static timing
specialization is shipped.

Latency:

```lisp
(latency (min N) (max M))
```

Rules:

- `min` and `max` are positive integer literals, same-transaction scalar
  parameter defaults, declared actor constants, actor-local scalar parameter
  defaults, or qualified imported package scalar constants that resolve to
  positive integers.
- Duplicate options and `min > max` fail closed.
- Same-transaction scalar parameter defaults, actor constants, actor scalar
  parameter defaults, and qualified imported package scalar constants resolve
  before the existing counter/error lowering path, so generated `.fsm` guard
  and timeout checks contain the resolved integer. Same-transaction parameters
  shadow actor-level static names and remain local lowering inputs.
- Runtime interface signals, unknown symbolic names, unknown or unqualified
  package constants, aggregate package constants, package member/item paths,
  arbitrary expressions, zero-valued constants, zero-valued or non-scalar
  actor/transaction parameters, and cross-transaction parameters remain
  invalid latency bounds.
- Generated child activation overrides for a latency-bound transaction
  parameter are accepted only when they resolve to the same positive integer
  as the child default. Mismatches fail closed until per-activation latency
  counter specialization is shipped.
- Latency metadata lowers to counters/error checks where supported and reports
  through `dt_blocks[]`/`inferred_storage[]`; there is no separate
  latency-bound source-token report field.
