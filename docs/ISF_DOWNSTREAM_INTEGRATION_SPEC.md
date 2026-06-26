# ISF Downstream Integration Specification

Status: `bounded_public`
Document version: `2026-06-26`
ISF source specification: `.isf` specification v0.6
Primary audience: downstream tools that emit, validate, inspect, or consume
FSMGen Intent Scheduling Format sources and reports.

This is the single downstream-facing integration contract for the current
`.isf` / IAL1 surface, and it anchors how IAL2 sources that lower through
`.isf` interact with downstream tools. A consumer should be able to implement
against this document for IAL1 behavior without reading the mdBook, Perl
modules, task trees, or tests first. Those artifacts remain the implementation
evidence and evolution history; this file packages the current public IAL1
contract and the downstream file-surface stack in one place.

Synchronization invariant: this document must stay truthful with respect to
the live `.isf` spec, the mdBook, the public contract, the manifest metadata,
the support-accounting catalog, the regression tests, explicit deferrals, and
the codebase itself. A mismatch between this file and implementation behavior
is a project bug. Do not update this file as an aspirational design note;
update it only with the same slice that changes the source language,
diagnostics, lowering behavior, public facade, schedule JSON, generated
artifacts, fixtures, support status, or documented deferrals.

## 1. Readiness And Stability

`.isf` is defined and implemented, but it is not a frozen external standard.
The current integration status is `bounded_public`:

- Source files ending in `.isf` are accepted by `bin/fsmgen`.
- The parser and scheduler have public in-process facades.
- Accepted sources lower to explicit scheduled `.fsm` review artifacts.
- Schedule reports are emitted as JSON through `--emit-schedule-json` or the
  in-process scheduler facade.
- Single-clock accepted sources reach SystemVerilog/Verilog-family HDL through
  the normal `.fsm` backend.
- Accepted multi-domain event-crossing sources lower to generated domain/top
  artifacts and can reach SystemVerilog/Verilog-family HDL with concrete CDC
  child modules when the emitted domain artifacts satisfy the scheduled `.fsm`
  HDL contract, including clock-only no-reset domains.
- Public syntax, public lower-result shape, and public schedule-report key
  families are regression-backed.

The source/lowering contract remains bounded even though schedule JSON
`schema_version: 1` is now stable:

- Parser acceptance alone is not support.
- A construct is public only when this document gives its source shape,
  lowering behavior, runtime meaning, diagnostics boundary, report visibility,
  and regression evidence.
- Full raw parser hashes and full `LoweringIR` objects are not frozen. The
  schedule JSON schema is stable for `schema_version: 1`; use the key/value
  families described here and the machine-readable manifest for exact
  discovery.
- Future downstream-visible `.isf` or `.ppif` changes must update this
  document, the public contract, manifest metadata, support accounting, tests,
  and book content in the same implementation slice.

## 2. Integration Pipeline

The current semantic pipeline is:

```text
Downstream intent source
  -> .isf source
  -> FSM::Adapter::ISF parser
  -> FSM::Scheduler::ISF lowering
  -> scheduled .fsm review artifacts
  -> SystemVerilog / Verilog-family HDL
```

Intent abstraction levels:

- `.fsm` is Intent Abstraction Layer 0 (`IAL0`). It is explicit cycle-authored
  hardware intent and owns DT structure, assignment operators, state and
  non-state activation regions, mux-selection semantics, and exact runtime
  behavior.
- Current `.isf` is Intent Abstraction Layer 1 (`IAL1`). It is scheduling
  intent above `.fsm`: actors, transactions, drives, samples, waits, control
  flow, generated child activations, rules, storage, libraries, constraints,
  and selected clock-domain metadata lower into reviewable `.fsm`.
- `.ppif` is the first shipped Intent Abstraction Layer 2 (`IAL2`) public file
  surface. It is Protocol/Platform Intent Format source and always lowers
  through generated `.isf` before generated `.fsm`; direct IAL2-to-IAL0
  lowering is not a public contract.
- Current bounded `.ppif` coverage includes one-channel Valid-Ready sources,
  multi-channel Valid-Ready bundles, and one-object AXI manager
  capacity/status sources. Support-accounted AXI manager coverage includes
  capacity/status, ID-family metadata, transaction envelopes and fan-in,
  concrete-ID assertions, bounded auto-ID lifecycle, same-ID reject and
  issue-order-queue policy, generated auto-ID write/read response-demux,
  generated single/last/multi-beat read-data capture, burst-length/runtime
  validation, scalar `RRESP` aggregation, one-or-more read burst-last
  queue-head groups, one-or-more write queue-head groups, read single-beat and
  read burst-last queue-head response-demux including multiple/mixed depth-3
  scalar, raw-`ARLEN`, runtime-validation, and multi-beat output-bank read-data
  groups, same-family mixed auto-ID plus concrete queue-head response-demux
  with scalar, raw-`ARLEN`, runtime-validation, and multi-beat output-bank
  read-data over the selected read burst-last shape, generated single-active
  and multiple all-dynamic write/read response-demux, generated all-dynamic
  same-ID issue-order queues for selected write `BID`, read single-beat `RID`,
  and read burst-last `RID && RLAST` depth-2/depth-3 shapes, selected
  read-data, raw-`ARLEN`, runtime-validation, and multi-beat output-bank
  behavior over generated all-dynamic read burst-last issue-order queues,
  generated mixed dynamic/static response-demux families, and generated
  one-dynamic plus one-concrete-static mixed dynamic/static same-ID
  issue-order queue behavior for write `BID`, read single-beat `RID`, read
  burst-last `RID && RLAST`, paired scalar read-data over the generated mixed
  read single-beat and burst-last queue completions, report-only raw-`ARLEN`
  burst-length capture, runtime beat-count/`RLAST` validation, and
  runtime-validation multi-beat output banks over the generated mixed read
  burst-last queue completion.
- Broader mixed issue-order queue cardinality, scoreboards, group-local
  simultaneous enqueue widening, packed burst-vector outputs, alternate full
  burst payload assembly, aliases, platform clauses, full AXI manager behavior,
  direct backend lowering, verification-output generation, backend-language
  variants, and VHDL remain deferred.
- The machine-readable source of truth for shipped suffixes, layers, lowering
  order, CLI modes, and current per-suffix boundary text is
  `./bin/fsmgen --capability-manifest` under
  `language_surface.file_surfaces`. That manifest boundary, this handoff, the
  public contracts, the mdBook, the support-accounting catalog, and the
  codebase must remain lockstep for every downstream consumer.

## 3. CLI Entry Points

Supported `.isf` CLI surfaces:

```bash
./bin/fsmgen source.isf
./bin/fsmgen --strict source.isf
./bin/fsmgen --emit-schedule-json source.isf
./bin/fsmgen --outdir /tmp/isf-build source.isf
./bin/fsmgen --output /tmp/out.sv source.isf
```

CLI behavior:

- Plain `file.isf` generation lowers through scheduled `.fsm`, then runs the
  normal `.fsm` HDL path.
- `--strict file.isf` follows the same accepted-success shape and keeps stderr
  empty on success.
- `--emit-schedule-json file.isf` prints the scheduler report JSON to stdout
  and exits before HDL generation.
- `--outdir DIR file.isf` writes every lowered `.fsm` artifact by basename into
  `DIR`; for multi-file lowers, the parent/generated-top artifact is the entry
  artifact used by later generation.
- `--capability-manifest` exposes the machine-readable contract at
  `embedding.isf_public_interface`.

CLI options advertised as part of the ISF public surface:

```text
--emit-schedule-json
--outdir
--strict
```

## 4. In-Process API Entry Points

The public Perl facades are:

```perl
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $parser = FSM::Adapter::ISF->new(debug => 0);
my $actor  = $parser->parse_file('source.isf');
my $actor2 = $parser->parse_source($source_text, 'source-label.isf');

my $scheduler = FSM::Scheduler::ISF->new(debug => 0);
my $lowered   = $scheduler->lower($actor);
my $json      = $scheduler->report($actor);
```

Constructor and receiver rules:

- Constructors require the exact `FSM::Adapter::ISF` or
  `FSM::Scheduler::ISF` class invocant.
- The only public constructor option is `debug`.
- Public methods require objects returned by their matching constructors.
- `parse_file(path)` requires one defined scalar path naming a readable `.isf`
  file.
- `parse_source(text, label)` requires defined scalar source text and label.
- `lower(actor)` and `report(actor)` require one scheduler-consumable actor
  hash returned by the parser.
- Public facade boundary failures die with scalar diagnostics before private
  parser/lowering internals are used.

Lower result shape:

```text
{
  files => {
    "basename.fsm" => "scheduled .fsm source text",
    ...
  }
}
```

The `files` map is the bounded lower-result surface. File keys are `.fsm`
basenames with no directory components. File text is scheduled `.fsm` or
generated-top `.fsm` text rooted at `(?fsm:<basename-stem> ...)` or
`(?top:<basename-stem> ...)`, optionally followed by generated interface
metadata such as `?rtlif` for explicit CDC children.

## 5. Source File Model

`.isf` is Lisp-ish S-expression source. Forms use parenthesized lists, scalar
tokens, and nested list expressions. The public compile/report root is one
actor:

```lisp
(actor actor_name
  actor_clause...)
```

FSMGen rejects sources with multiple top-level `(actor ...)` roots. A sibling
actor root is not an ATL child type definition; downstream producers must keep
one compile/report entry actor until FSMGen publishes an explicit actor
type-resolution contract. Additional `(library ...)` roots remain the
accepted same-source reusable actor packaging surface.

The shipped ATL actor type-resolution source is library-qualified: `(instance
NAME of ALIAS.EXPORT)`, where `ALIAS` comes from the enclosing actor's
`(imports (library ... as ALIAS))` clause and `EXPORT` is an actor export
from that library.

Resolved qualified instances report library/export provenance on
`actor_network.instances[]` and now emit child scheduled `.fsm` artifacts
named by their `scheduled_fsm` fields.

The first generated ATL top is shipped for exactly one resolved child with
one parent trigger handoff and one parent event wait in the same clock/reset
policy.

That top is reported through `actor_network.generated_tops[]`, instantiates
the parent and child, wires public pins to the parent, wires the parent
trigger handoff to the child transaction start input discovered from the
child transaction's scalar `(on START_SIGNAL)`, and wires the child scalar
event output back to the parent event handoff input.

Downstream producers must still treat broader ATL top emission, multi-child
scheduling, data-route coupling, route mux/storage,
payload/ready/backpressure bindings, CDC, recursive actor networks, and
permanent actor grouping as unavailable until later leaves explicitly ship
them.

Imported files may also contain library roots:

```lisp
(library library.name
  library_clause...)
```

General source rules:

- Names that identify actors, ports, storage, transactions, rules, drives,
  parameters, domains, and instances are scalar HDL identifiers. Current
  accepted identifier spelling is compatible with `[A-Za-z_][A-Za-z0-9_]*`.
- Widths and depths are positive integer literals unless a specific clause says
  otherwise. Actor top-level interface port widths, actor-owned scalar storage
  widths, actor-owned bank storage widths, actor-owned bank storage depths,
  and transaction-local port widths also accept declared actor constants and
  actor-local scalar parameter defaults that resolve to positive integers.
  Actor top-level interface port widths, actor-owned scalar storage widths,
  actor-owned bank storage widths, actor-owned bank storage depths, and
  transaction-local port widths additionally accept qualified imported package
  scalar constants that resolve to positive integers; the parser handoff,
  scheduled `.fsm`, activation handoff storage where applicable, schedule
  report, and generated HDL publish the resolved integer width or depth.
  Generated child and direct/non-generated transaction-local port widths
  additionally accept same-transaction scalar parameter defaults that resolve
  to positive integers.
- Actor constants use non-negative integer literals or enum member references
  that resolve to non-negative integers. Actor parameter scalar defaults may
  also use earlier actor-local scalar parameter defaults by name, preserving
  authored tokens while resolving those names internally. Generated child
  transaction parameter defaults may use numeric/exact-width literals,
  declared actor constants, actor-local scalar parameter defaults, earlier
  scalar transaction parameter defaults, enum members, qualified imported
  package scalar constants, or compatible aggregate/list literals with those
  scalar leaf sources; actor constants and actor scalar parameter defaults are
  published as literal child/report defaults while earlier transaction
  parameter names, enum tokens, and qualified package-constant tokens stay
  authored in child review artifacts. Package-constant-backed transaction
  defaults require imported `PACKAGE.CONSTANT` scalar package `+constants`
  entries; unqualified package constants, aggregate package constants, and
  package member/item paths fail closed.
  Static wait counts use non-negative integer literals, same-transaction
  scalar parameter defaults, actor constants, actor-local scalar parameter
  defaults, or qualified imported package scalar constants. Static latency
  bounds use positive integer literals, same-transaction scalar parameter
  defaults, actor constants, actor-local scalar parameter defaults, or
  qualified imported package scalar constants. Top-level await-local watchdog
  limits use positive integer literals, same-transaction scalar parameter
  defaults, actor constants, actor-local scalar parameter defaults, or
  qualified imported package scalar constants; actor-level watchdog limits use
  the same set except transaction parameters.
- Numeric and exact-width integer literals are accepted where this document
  says scalar numeric literals are accepted.
- Runtime expression positions may use scalar tokens, numeric/exact-width
  literals, or non-empty list expressions. List expressions use the same
  Lisp-like operator-first shape consumed by the scheduled `.fsm` expression
  formatter.
- Runtime division and modulo expressions fail closed before scheduled `.fsm`
  emission when any divisor operand is a numeric/exact-width literal zero, an
  actor-level constant that resolves to zero, or an actor-local scalar
  parameter default that resolves to zero, including nested expression
  operands. Nonzero literal divisors, nonzero actor-constant divisors, nonzero
  actor-parameter divisors, and dynamic scalar divisors remain accepted;
  FSMGen does not yet prove arbitrary dynamic divisors nonzero.
- Singleton actor clauses are not mergeable. Repeating one fails closed rather
  than letting later clauses overwrite earlier fields.

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
  (output name (width CONST)))
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

## 12. Rules, Priorities, Resources

Rule forms:

```lisp
(rule name condition
  action...)

(rule name
  (when condition)
  action...)
```

Actions:

```lisp
(target expr)
(set target expr)
(store bank index value)
(load bank index as target)
(trigger transaction)
(trigger transaction (params ...) (bind ...))
(priority over other_rule_or_transaction)
```

Rules:

- Rule guards may be scalar conditions or non-empty list expressions.
- Rule DTs are non-state concurrent logic guarded by the rule condition.
- Same-target rule writes are accepted only when direct contradictory guard
  facts prove they cannot fire in the same cycle.
- Rule/rule, rule-over-transaction, and transaction-over-rule same-target data
  conflicts can be resolved by declared priority when both writes use the same
  timing operator and the priority graph has one winner. Transaction-over-rule
  lowering uses scheduled `.fsm` `(state_active STATE)` guard syntax to disable
  the lower-priority rule assignment while the winning transaction state is
  active; that guard lowers to internal state-register comparison logic, not
  downstream-visible module input ports.
- Rule triggers emit one-cycle delayed per-rule trigger sources.
- Multiple rules triggering the same local transaction lower through a
  deterministic trigger fan-in DT unless the target is generated.
- Parameterized triggers use generated child activation instances.
- Generated-child rule triggers may bind scalar output ports back to actor
  targets under the per-trigger done observer; direct/local rule-trigger output
  bindings remain rejected.

Resource arbitration:

```lisp
(resources
  (resource work
    (kind transaction_start)
    (arbiter priority)
    (users high_pri low_pri))
  (resource store_bus
    (kind storage_port)
    (arbiter priority)
    (members slot shadow)
    (users writer_a writer_b))
  (resource response_outputs
    (kind output_bundle)
    (arbiter priority)
    (members valid ready status)
    (users rule_a rule_b))
  (resource fair_response
    (kind output_bundle)
    (arbiter round_robin)
    (members valid ready status)
    (users fair_rule_a fair_rule_b))
  (resource fair_slot
    (kind rule_slot)
    (arbiter round_robin)
    (users rr_high rr_low))
  (resource fair_work
    (kind transaction_start)
    (arbiter round_robin)
    (users fair_start_a fair_start_b)))
```

Rules:

- Current enforced resource kinds are `rule_slot`, `output_bundle`,
  `transaction_start`, and `storage_port` with `priority` arbitration for
  declared rule users. All four also support bounded `round_robin`
  arbitration for declared rule users.
- A bounded `round_robin` `rule_slot`, `output_bundle`, `transaction_start`,
  or `storage_port` uses the `(users ...)` list as a circular grant order.
  FSMGen emits a generated pointer counter named
  `isf_rr_<resource>_turn`, grants the first requesting rule at or after the
  current pointer, advances the pointer only from the winning rule DT, and
  reports the pointer in `inferred_storage[]` with role
  `resource_round_robin_pointer`. The generated pointer name must not collide
  with existing actor ports, constants, parameters, declared storage, or
  generated counters.
- A `transaction_start` resource is named by the local transaction it
  arbitrates. Each listed rule user must trigger that transaction through the
  shipped non-generated rule-trigger surface. Priority suppression and
  bounded round-robin grants gate rule DTs before their per-rule trigger
  source pulses feed the generated `{transaction}_trigger_fanin` DT; the
  fan-in owner and timing stay unchanged.
- An unmembered `output_bundle` keeps the historical implicit surface: the
  bound rule users and the outputs or other LHS targets they drive describe
  the bundle intent.
- `output_bundle` resources may include `(members name...)`; every member
  must name a declared actor output port or concrete actor-owned storage
  signal. Concrete storage signals include scalar storage variables and
  scalarized bank element signals; bank roots, aggregate paths, inferred
  undeclared LHS targets, and arbitrary expressions remain outside this
  explicit member domain. When members are explicit, every listed member must
  be written by at least one bound rule user, and no bound rule user may write
  a declared actor output or actor-owned storage signal outside the list.
- `storage_port` resources with bound users require `(members name...)`; every
  member must name a concrete actor-owned storage signal. Concrete storage
  signals are scalar storage variables and scalarized bank element signals.
  Bank roots, aggregate paths, inferred undeclared LHS targets, transaction
  ports, actor input ports, and arbitrary expressions remain outside this
  explicit member domain. Every listed member must be written by at least one
  bound rule user, and no bound rule user may write a concrete actor-owned
  storage signal outside the list. Under bounded `round_robin`, the same
  mandatory member validation and `resource_arbitration[].members` report
  evidence apply while the generated pointer selects the winning bound rule
  for the cycle.
- Reports expose `resource_arbitration[]`.
- Each `resource_arbitration[]` entry includes `resource`, `kind`, `arbiter`,
  `user`, `user_kind`, `members`, and `suppressed_by`. `members` is an array
  and is empty when the resource has no explicit member list. For `priority`
  resources, `suppressed_by` names higher-priority bound rule users. For
  bounded `round_robin` resources, `suppressed_by` names the dynamic peer
  users that can block the grant for a given pointer position and request set.
- Additional resource kinds may be cataloged as backlog but are not enforced
  unless listed as enforced by the public contract. Generated-child
  transaction starts, generated-child storage arbitration, actor-network
  triggers, actor-network endpoint users, transaction users, named-drive
  users, output-target users, lifetime ownership, route mux/storage,
  `round_robin` for backlog resource kinds, and other non-selected resource
  surfaces remain outside the shipped resource-arbitration subset.

## 12.5. Static Actor Network Metadata

FSMGen now accepts bounded Actor Transfer Level (`ATL`) source surfaces owned
by the top-level actor: direct static actor declarations, compact static actor
declaration aliases, report-only static groups, selected scalar handoffs,
selected parent event/trigger handoffs, and the exact same-cycle temporary
trigger batch.

The static declarations record actor-network intent for downstream discovery;
behavior-bearing leaves add only the explicitly documented parent handoff
ports and scheduled states.

FSMGen now resolves library-qualified child actor types, emits their child
scheduled `.fsm` artifacts, and emits the first generated ATL top for the
selected one-resolved-child trigger/event subset.

The shipped source contract for ATL actor type resolution is explicit library
qualification in `(instance NAME of ALIAS.EXPORT)` or compact
`(NAME : ALIAS.EXPORT)`, not sibling actor roots and not implicit lookup of
unqualified `ACTOR_TYPE` names.

The shipped resolution subset reports metadata for that qualified form:
`type_resolution: library_actor_export`, the resolved `library`, `alias`, and
`export`, plus `module` and `scheduled_fsm` names.

It emits the child `.fsm` artifact named by `scheduled_fsm`; when the source
also has exactly one matching parent trigger/event pair, it emits the
matching `<parent>_top.fsm` and reports it through
`actor_network.generated_tops[]`.

### 12.5.1. Actor-As-Network Boundary And Direct Instances

Accepted form:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

Compact equivalent:

```lisp
(actor packet_pipe_compact
  (clock clk)
  (interface
    (input start)
    (output done))
  (reader : packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

The enclosing actor is the network boundary. Downstream emitters must not wrap
static ATL declarations in `(network ...)`; that spelling fails closed in the
current shipped surface.

The schedule report exposes this through top-level `actor_network`:

```json
{
  "kind": "static_declaration",
  "instances": [
    {
      "name": "reader",
      "actor_type": "packet_reader",
      "declaration": "actor"
    }
  ],
  "groups": [],
  "association_schedules": [],
  "group_schedules": [],
  "data_movements": [],
  "event_waits": [],
  "transaction_triggers": []
}
```

Verbose `(instance NAME of ACTOR_TYPE)` declarations report
`declaration: "actor"`. Compact `(NAME : ACTOR_TYPE)` aliases report
`declaration: "instance_alias"`. Both forms share the same validation and
metadata surface. Current fail-closed boundaries include multiple instances
outside the shipped actor-to-actor handoff or report-only group metadata
subsets, `(network ...)`, dynamic/non-scalar names, direct recursive
instantiation, qualified actor/event behavior beyond the selected single
parent-handoff event wait and single parent-handoff transaction trigger
subsets, and group scheduling behavior beyond the exact same-cycle trigger
batch subset documented below.

### 12.5.2. Drive-Body Data Movement And Endpoint Vocabulary

The broader ATL v0 contract is selected for future slices, but downstream
producers must not emit it until the corresponding support appears in the
capability manifest and this handoff:

- Endpoint-aware movement reuses existing drive bodies and drive calls. A
  drive body pair stays `(sink source)` while ATL widens each side to
  `pins.name`, `actor.port`, `actor.transaction`, `actor.event`, or
  `group.name` where a later leaf explicitly permits that endpoint kind.
- `connect`, `transfer`, and `move` are not public ATL v0 movement clauses.
  Movement is temporal scheduling intent, not a permanent actor-to-actor wire.
- Future resolved actor types use `(instance NAME of ALIAS.EXPORT)`, where
  `ALIAS` names an imported library and `EXPORT` names a library actor export.
  That qualified spelling is reserved today and fails closed before scheduled
  `.fsm` emission; unqualified `(instance NAME of ACTOR_TYPE)` stays
  metadata-only until a later leaf explicitly widens it.
- The first endpoint-movement code leaf shipped fail-closed reservation for
  unsupported qualified actor endpoint drive-body pairs, and the generated
  actor-to-actor handoff subset is now downstream-emittable for one-bit scalar
  and exact-width vector generated-child routes.

  Downstream producers may emit exactly two direct static actor instances,
  one named drive body with one `(sink_actor.endpoint source_actor.endpoint)`
  pair, and one top-level transaction drive call. For generated-child routes,
  the source endpoint must be a child output, the sink endpoint must be a
  child input, and both resolved child endpoints must have the same positive
  width.

  FSMGen rewrites the pair to generated parent handoff signals and emits
  external parent handoff ports named `source_actor_source_endpoint` for the
  source input and `sink_actor_sink_endpoint` for the sink output. The handoff
  width is one for scalar one-bit endpoints or the exact matching child
  endpoint width for vector endpoints.

  The `actor_network.data_movements[]` report keys are `kind`, `transaction`,
  `context`, `drive`, `source_instance`, `source_endpoint`, `source_signal`,
  `sink_instance`, `sink_endpoint`, `sink_signal`, `width`, `width_source`,
  `route_lifetime`, `storage`, `source`, and `sink`.

  Route lifetime is one drive-call cycle, with no storage, mux, width
  adaptation, pin movement in that actor-to-actor route, inline/expression
  movement, fan-in/fan-out, groups, CDC, or trigger/await coupling beyond the
  selected generated-child top sequence.
- The first top-level pin movement subset is now downstream-emittable. The
  accepted source form is exactly one direct static actor instance, one named
  drive body with one `(actor.endpoint pins.input_pin)` scalar pair, and one
  top-level transaction drive call. The source pin must be a scalar one-bit
  top-level actor input. FSMGen reads that input pin directly, rewrites the
  actor sink to generated handoff output `actor_endpoint`, and reports kind
  `scalar_pin_to_actor_handoff` with `source => top_level_pin`.
- The actor-to-top-level output pin direction is now downstream-emittable.
  The accepted form is exactly one direct static actor instance, one named
  drive body with one `(pins.output_pin actor.endpoint)` scalar pair, and one
  top-level transaction drive call. The output pin must be a scalar one-bit
  top-level actor output. FSMGen exposes the actor endpoint as generated
  input `actor_endpoint`, drives the existing top-level output pin, and
  reports kind `scalar_actor_to_pin_handoff` with
  `sink => top_level_pin`.
- Blocking actor-transaction orchestration is reserved as
  `(do actor.transaction)`, and nonblocking orchestration as
  `(spawn actor.transaction as NAME)`.
- Rule-level actor-transaction orchestration has a bounded parent-handoff
  subset: one top-level rule action `(trigger actor.transaction)` may target a
  declared static actor instance and lower to a generated one-cycle parent
  output handoff.
- Actor event waits use `(await actor.event)`. The shipped subset is one
  top-level transaction-body wait against a direct static actor instance,
  either alone for one actor or after one selected temporary trigger batch;
  events are one-cycle control pulses and event payloads are not supported.
- Concurrent actor groups may still use
  `(group NAME (members ACTOR...) (mode concurrent))`, but groups are static
  review metadata only. They are not required for task-scoped ATL trigger
  associations and never create permanent runtime associations or override
  fan-in, lifetime, ordering, width, or CDC safety.
- The concurrent-group implementation axis has shipped targeted diagnostics,
  report-only metadata, and the compact readability alias. Downstream
  producers may emit either direct actor-body
  `(group NAME (members ACTOR...) (mode concurrent))` declarations or compact
  `(concurrent NAME ACTOR...)` aliases for the shipped metadata subset: at
  least two already declared direct static actor instances, single-clock actor
  scope, no dynamic membership, no nested groups, and no scheduling behavior.
  Verbose groups report `declaration: "group"`; compact aliases report
  `declaration: "concurrent_alias"`.
- The first multi-actor trigger scheduling subset is now
  downstream-emittable.

  Downstream producers may emit one contiguous top-level transaction-body
  batch of `(trigger actor.transaction)` clauses targeting distinct static
  actor instances.

  FSMGen lowers the batch as one same-cycle external trigger-batch state,
  preserves per-target `actor_network.transaction_triggers[]`, and reports
  canonical batch evidence through `actor_network.association_schedules[]`.

  `actor_network.group_schedules[]` remains a schema-version-1 compatibility
  view.

  If the trigger set matches one declared static group, the compatibility
  `group` field names that group; otherwise it carries a synthetic
  transaction-scoped name such as `run_trigger_batch`.

  Downstream producers must still avoid repeated members, noncontiguous
  batches, generated child assumptions, group endpoints, data-movement
  coupling, hidden same-cycle event joins, storage/mux insertion, CDC,
  compact movement aliases, and broader fan-in/fan-out.

  If a source endpoint qualifier names a declared static group, authored
  `group.name` forms are rejected before generic enum-member handling.
  Transaction-body `(trigger group.name)`, `(await group.name)`, `(await_all
  group.name)`, `(await_any group.name)`, and rule-action
  `(trigger group.name)` fail with the ATL group-endpoint diagnostic. The
  missing downstream contract is group-level trigger arbitration/fanout, event
  aggregation, storage/lifetime, and generated-child wiring semantics.

### 12.5.3. Static Groups Versus Task-Scoped Associations

Static group declarations are review metadata unless a later leaf explicitly
selects scheduling behavior. A `(group NAME (members ACTOR...) (mode
concurrent))` declaration or compact `(concurrent NAME ACTOR...)` alias alone
reports `actor_network.groups[]` with `scheduling: "metadata_only"` and does
not run actors concurrently, create a permanent association, infer
dependencies, insert storage, or bypass CDC, width, ordering, or lifetime
checks.

Task-scoped associations are scheduled evidence created by accepted behavior,
not permanent membership. The shipped temporary trigger-batch subset reports
`actor_network.association_schedules[]` with `lifetime: "task_scoped"` for
the one parent state that pulses the selected actor triggers in the same
cycle. `actor_network.group_schedules[]` remains a schema-version-1
compatibility view of that same timing evidence.

### 12.5.4. Trigger And Event Pulses

Current ATL event-wait handoff subset: downstream producers may emit exactly
one top-level transaction-body `(await actor.event)` against a declared direct
static actor instance. The event name must be a scalar HDL identifier. The
wait may stand alone for a single static actor, or follow one selected
same-cycle temporary trigger batch. FSMGen maps that wait to a generated
one-bit parent event input named `actor_event`; for example, `reader.done`
maps to `reader_done`. The scheduled parent `.fsm` exposes that input and
waits on it. The producer of that event is external in this subset: no actor
type resolution, generated ATL child `.fsm`, generated ATL top, or event
wiring is emitted.

Schedule JSON reports accepted waits under `actor_network.event_waits[]`.
Each entry exposes `transaction`, `context`, `instance`, `event`, `signal`,
and `source`; the current source is `external_handoff`.

The selected multi-event parent-handoff subset is also supported after one
temporary trigger batch. Downstream producers may emit a contiguous,
source-ordered chain of top-level `(await actor.event)` clauses immediately
after the accepted trigger-batch state when every wait targets a distinct
triggered actor instance and the transaction segment has no ATL data
movement. FSMGen preserves the chain as sequential wait states; it does not
collapse them into a hidden same-cycle event join.

The rest of the ATL event boundary remains fail-closed.

Downstream producers must not emit nested actor-event waits, repeated waits
to one actor instance, non-batch multi-wait forms, interleaved parent work
inside the multi-wait segment, fan-in/fan-out event joins, event payloads,
cross-clock actor events, concurrent group events, or source that relies on
generated ATL child artifacts or generated ATL top event wiring until the
corresponding support is documented here and advertised in the manifest.
Repeated waits after a temporary trigger batch fail closed with a diagnostic
that names the missing event re-arm or per-event generation/lifetime contract.
Downstream producers must also not spell actor-event all-of/any-of joins with
`await_all` or `await_any` qualified operands; those sync clauses remain
generated-child completion forms in the shipped surface and now fail with a
targeted ATL event-join diagnostic when they carry actor events.

Existing unqualified local forms are unchanged: `(await signal)` remains a
local transaction wait, and rule-level `(trigger transaction)` remains a
local transaction trigger.

Dotted enum-looking names that do not name a static actor instance or static
group keep their prior diagnostics. Dotted names that do name a static group
fail with the ATL group-endpoint diagnostic.

The regression suite specifically covers the accepted source-ordered
multi-event wait form through `isf/atl_trigger_batch_multi_wait_pipeline.isf`
and keeps repeated target waits outside that subset with the targeted
event re-arm/lifetime diagnostic.

Current actor-transaction trigger handoff subset: downstream producers may
emit a top-level transaction-body `(trigger actor.transaction)` against a
static actor instance either as a single handoff or as part of the exact
temporary trigger-batch subset documented above. Downstream producers may also
emit one top-level rule action `(trigger actor.transaction)` against a static
actor instance. The target transaction name must be a scalar HDL identifier.
FSMGen maps each accepted trigger to a one-cycle parent output named `actor_transaction_start`;
for example, `reader.capture` maps to `reader_capture_start`, and a rule
action `worker.process` maps to `worker_process_start`. The scheduled parent
`.fsm` exposes and pulses that output at the trigger point, either in the
single-trigger state, in the accepted grouped trigger state, or in the guarded
rule DT. The sink of that trigger is external in this subset.

Schedule JSON reports accepted triggers under
`actor_network.transaction_triggers[]`. Each entry exposes
`owner_transaction`, `context`, `instance`, `target_transaction`, `signal`,
and `sink`; the current sink is `external_handoff`.

Downstream producers must not emit nested qualified triggers, repeated
triggers to the same actor instance, repeated rule-action qualified triggers,
fan-in/fan-out trigger structures, generated handoff signal conflicts, trigger
payloads or bindings, ready/backpressure assumptions, cross-clock actor
triggers, concurrent group endpoints, or source that relies on generated ATL
child artifacts or generated ATL top wiring outside the explicitly shipped
resolved-child subset until the corresponding support is documented here and
advertised in the manifest. Rule-action `group.name` triggers remain in that
unsupported group-endpoint category and use the same targeted diagnostic as
transaction-body group triggers.

The generated-child actor-to-actor route now has focused generated-handoff
collision coverage. Downstream producers should treat parent-declared
collisions with the selected trigger, event, data, or named-drive request
handoff names as fail-closed input; FSMGen does not support handoff
remapping, route mux/storage, fan-in/fan-out, ready/backpressure, or payload
protocols for that route.

Normal downstream `.isf` source sees those generated-handoff collisions as
parser-owned failures. FSMGen also has a lowerer defensive backstop for
malformed or mutated scheduler-facing actor metadata, so generated-top wiring
cannot reuse, suppress, or shadow those same handoff names if metadata
bypasses normal parser finalization. This is a safety backstop only, not a
new source or report feature.

### 12.5.5. Generated-Child Route Terms And Boundaries

The mdBook has an audit-backed dedicated generated-child route terminology
section for these terms. Downstream consumers should treat that book section
and this handoff as the truth sources for current route support and explicit
non-support.

The documentation precision slice now makes that book section a term-by-term
support boundary. It does not change the downstream source surface,
schedule-report contract, generated artifact shape, or shipped ATL behavior.

For downstream implementation, the current route terms mean:

- Route lifetime is one named drive-call cycle.
- Generated handoffs are deterministic parent-visible signals such as
  `reader_payload`, `writer_payload`, `reader_capture_start`, `writer_emit_start`,
  `reader_done`, `writer_done`, and `forward_payload_start`.
- Handoff remapping is not shipped; collisions with authored parent interface
  or actor-owned storage names fail closed.
- Route muxing and route storage are not shipped; the selected route set has
  one source child, one sink child, one named drive call per route, no
  route-local selector, and no route-local storage.
- Fan-in and fan-out are not shipped for route triggers, events, or data.
- Ready/backpressure is not shipped; there is no ready signal, retry,
  buffering, or replay contract.
- Payload protocols are not shipped beyond the current exact-width
  drive-call-cycle handoff value. Vector routes preserve matching child
  endpoint widths; they do not define packing, framing, ready/valid, or retry
  semantics.
- Route endpoint expressions are not shipped. The route source must be the
  scalar endpoint `reader.payload`; a source expression such as
  `(+ reader.payload 1)` fails closed before expression movement, value
  transformation, width conversion, storage, or payload protocols are
  inferred. The route sink must likewise be the scalar endpoint
  `writer.payload`; a sink expression such as `(+ writer.payload 1)` fails
  closed before expression destinations, route-side transforms, width
  conversion, storage, or payload protocols are inferred.
- The route sink-expression diagnostic is source-order independent for
  endpoint-looking route sinks. If a drive body appears before the relevant
  `(instance ...)` clauses, FSMGen defers that malformed ATL-looking sink
  expression until the full actor instance set is known, then reports the same
  ATL sink-expression diagnostic. Ordinary malformed local drive targets such
  as `((out) 1)` keep the generic drive-body scalar-head diagnostic.
- The route source-expression diagnostic is source-order independent for
  endpoint-looking route sources. If a drive body appears before the relevant
  `(instance ...)` clauses, FSMGen defers that malformed ATL-looking source
  expression until the full actor instance set is known, then reports the same
  ATL source-expression diagnostic. This does not select expression movement
  or payload behavior.
- The accepted actor-to-actor route is also source-order independent. A named route
  drive such as `forward_payload` may appear before or after the relevant
  direct static actor instances; FSMGen resolves the same scalar
  `reader.payload` to `writer.payload` route after the full actor body is
  parsed, emits the same generated ATL top handoffs, and reports the same
  `actor_network.data_movements[]` metadata.

### 12.5.6. Generated Child Artifacts And Top Data Routes

Current generated-artifact contract: the parent scheduled `.fsm` may include
the selected one-bit actor-event handoff input, selected one-cycle
actor-transaction trigger output, selected scalar data-movement handoff
ports, and selected same-cycle trigger-batch handoff outputs.

Resolved library-qualified ATL instances also emit child scheduled `.fsm`
artifacts.

FSMGen now emits generated ATL tops for the selected one-resolved-child
trigger/event subset and the selected two-resolved-child control-only
trigger/event subset, reporting them through
`actor_network.generated_tops[]`.

FSMGen still emits no generated ATL route mux, data-route storage,
generated-child data wiring beyond the selected one-child scalar and
exact-width vector pin-ingress routes, selected one-child scalar and
exact-width vector pin-egress routes, selected same-child mixed scalar/vector
pin-ingress and pin-egress route sets, and selected same-source/same-sink
scalar or exact-width vector two-child actor-to-actor route set, CDC child
wiring, payload/ready/backpressure binding, or broader HDL event wiring.

The selected generated-child actor-to-actor data route set is shipped only for
same-source/same-sink two-child shapes that use qualified trigger/event
handoffs, one named drive-call cycle per route, deterministic generated
handoffs, and matching source-output/sink-input endpoint widths. Malformed
routes or mismatched-width route shapes still fail closed before FSMGen infers
remapping, storage, muxing, fan-in/fan-out, payload adaptation, or
backpressure behavior.

The selected generated-child actor-to-actor data route remains bounded by a
simple parent input start boundary and a simple parent output completion
boundary. Output-as-start, input-as-completion, undeclared, and wider
boundary pins are targeted fail-closed cases before downstream producers can
rely on interface remapping, activation fan-in, completion fan-out, boundary
expressions, route storage, route muxing, ready/backpressure, or payload
protocols.

Downstream consumers must treat `actor_network` as discovery/review metadata
plus the explicitly reported `event_waits[]`, `transaction_triggers[]`,
`data_movements[]`, `association_schedules[]`, `group_schedules[]`, and
`generated_tops[]` entries until a later task-tree leaf documents broader
generated artifact names and report keys in this handoff.

The HDL promotion slice does not change downstream source or report
requirements: the already shipped `isf/atl_resolved_child_pipeline.isf`
generated top now has plain and strict CLI SystemVerilog coverage proving the
generated top, parent, child, and selected internal trigger/event links.

Downstream producers should not infer any broader ATL HDL wiring from that
coverage.

The first generated-child data slice is now shipped:
`isf/atl_resolved_child_pin_ingress_pipeline.isf` wires one scalar
`(worker.payload pins.payload)` route into one resolved child through the
generated top.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` and the generated-top discovery evidence
from `actor_network.generated_tops[]`; no new public report family is
exposed.

The generated child `.fsm` carries generated `+interface` role metadata for
the selected child input so HDL generation preserves the child `payload`
port.

The exact-width vector generated-child pin-ingress leaf is also shipped:
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf` wires one vector
`(worker.payload pins.payload)` route from a top-level input pin through the
parent and generated top into one resolved child input.

Downstream producers may emit that route only when the source is a declared
top-level input pin, the sink is a resolved child input endpoint, and the two
endpoint widths are the same positive value.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` with
`kind: "vector_pin_to_actor_handoff"`, `width` equal to the endpoint width,
and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; the
private generated-top data-link list is still not a public report family.

Width mismatch fails before scheduled `.fsm` emission. Downstream producers
must not rely on width adaptation, packing, truncation, extension, slicing,
route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols, or
mixed scalar/vector route behavior from this one-route vector leaf.

The exact-width vector multi-route extension of that same pin-ingress
generated top is now shipped:
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
one resolved child and one parent transaction at route-local widths 8 and 4.

Downstream producers may emit multiple named vector pin-ingress drive bodies
in the same parent transaction only when all routes target the same resolved
child, each route has a matching top-level input pin and child input width,
source pins and child inputs are unique, and drive calls are adjacent before
the child trigger. Downstream consumers should read each route from
`actor_network.data_movements[]` as `vector_pin_to_actor_handoff` with
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
Broader mixed scalar/vector route sets outside the bounded pin-ingress subset
below and width adaptation remain unshipped.

The mixed scalar/vector pin-ingress extension of that same generated top is
now shipped:
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.valid pins.valid)` through one
resolved child and one parent transaction. `payload` is an exact-width vector
route at width 8; `valid` is a scalar one-bit route.

Downstream producers may emit mixed scalar/vector pin-ingress drive bodies in
the same parent transaction only when all routes target the same resolved
child, every route uses a unique top-level input pin and child input endpoint,
vector route widths match exactly, scalar routes are one bit, and drive calls
are adjacent before the child trigger. Downstream consumers should read each
route from `actor_network.data_movements[]` with route-local `kind`, `width`,
and `width_source` values: `vector_pin_to_actor_handoff` plus
`top_level_input_pin_resolved_child_endpoint_exact_width` for vector routes,
and `scalar_pin_to_actor_handoff` plus `top_level_pin_scalar_one_bit` for
scalar routes. Width adaptation remains unshipped.

The bounded multi-route extension of that same pin-ingress generated top is now
shipped: `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
one resolved child and one parent transaction.

Downstream producers may emit multiple named scalar pin-ingress drive bodies in
the same parent transaction only when all routes target the same resolved child,
use one scalar `(child.endpoint pins.input_pin)` endpoint pair per drive body,
have unique top-level input pins and unique child input endpoints, and are
activated by adjacent argument-free top-level drive calls before the child
trigger/event wait sequence.

Downstream consumers still read every public route from
`actor_network.data_movements[]` with `kind: "scalar_pin_to_actor_handoff"` and
still discover the generated top through `actor_network.generated_tops[]`. No
new report family or public `data_links` key is exposed.

The inverse generated-child data slice is also shipped:
`isf/atl_resolved_child_pin_egress_pipeline.isf` wires one scalar
`(pins.result worker.payload)` route from one resolved child output through
the generated top to one top-level output.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` and the generated-top discovery evidence
from `actor_network.generated_tops[]`; no new public report family is
exposed.

The generated child `.fsm` carries generated `+interface` role metadata for
the selected child output so HDL generation preserves the child `payload`
port.

The exact-width vector generated-child pin-egress leaf is also shipped:
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` wires one vector
`(pins.result worker.payload)` route from one resolved child output through
the parent and generated top to one top-level output pin.

Downstream producers may emit that one-route form when the source is a
resolved child output endpoint, the sink is a declared top-level output pin,
and the two endpoint widths are the same positive value.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` with
`kind: "vector_actor_to_pin_handoff"`, `width` equal to the endpoint width,
and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; the
private generated-top data-link list is still not a public report family.

Width mismatch fails before scheduled `.fsm` emission. Downstream producers
must not rely on width adaptation, packing, truncation, extension, slicing,
route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols, or
mixed scalar/vector route behavior from this one-route vector leaf.

The exact-width vector generated-child pin-egress multi-route leaf is also
shipped:
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` wires
`(pins.result worker.payload)` at width 8 and
`(pins.status worker.status)` at width 4 from one resolved child through the
parent and generated top to two top-level output pins.

Downstream producers may emit that route-set form only when every route shares
the same resolved child and parent transaction, each route has one
argument-free drive call, the drive calls are adjacent after the child event
wait, child output endpoints and top-level output pins are unique across the
set, and every child-output/top-output pair has the same positive width.

Downstream consumers should read each route as a separate
`actor_network.data_movements[]` entry with
`kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; private
generated-top data links remain out of the public report contract.

The mixed scalar/vector pin-egress extension of that same generated top is now
shipped:
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` wires
`(pins.result worker.payload)` and `(pins.valid worker.valid)` through one
resolved child and one parent transaction. `result` is an exact-width vector
route at width 8; `valid` is a scalar one-bit route.

Downstream producers may emit mixed scalar/vector pin-egress drive bodies in
the same parent transaction only when all routes source the same resolved
child, every route uses a unique child output endpoint and top-level output
pin, vector route widths match exactly, scalar routes are one bit, and drive
calls are adjacent after the child event wait. Downstream consumers should read
each route from `actor_network.data_movements[]` with route-local `kind`,
`width`, and `width_source` values: `vector_actor_to_pin_handoff` plus
`top_level_output_pin_resolved_child_endpoint_exact_width` for vector routes,
and `scalar_actor_to_pin_handoff` plus `top_level_output_pin_scalar_one_bit`
for scalar routes. Width adaptation remains unshipped.

The first two-child generated-top data-free slice is also shipped:
`isf/atl_two_child_pipeline.isf` emits parent, reader, writer, and generated
top `.fsm` artifacts for sequential `reader.capture`/`reader.done` then
`writer.emit`/`writer.done` handoffs.

Downstream consumers should read the resolved child metadata from
`actor_network.instances[]`, trigger evidence from
`actor_network.transaction_triggers[]`, event evidence from
`actor_network.event_waits[]`, and the generated-top discovery plus per-child
wiring metadata from `actor_network.generated_tops[].children[]`.

The selected resolved-child trigger-batch generated-top slice is also
shipped: `isf/atl_two_child_trigger_batch_pipeline.isf` emits parent, reader,
writer, and generated top `.fsm` artifacts for one contiguous same-cycle
trigger batch over `reader.capture` and `writer.emit`, followed by
source-ordered waits on `reader.done` and `writer.done`.

Downstream producers may emit that exact form only when there are exactly two
resolved children, no static group declaration, no ATL data movement in the
transaction segment, and no repeated child activations or waits. Downstream
consumers should read trigger evidence from
`actor_network.transaction_triggers[]`, wait evidence from
`actor_network.event_waits[]`, task-scoped temporary association evidence from
`actor_network.association_schedules[]`, schema-version-1 compatibility
schedule evidence from `actor_network.group_schedules[]`, and generated-top
discovery from `actor_network.generated_tops[]` with kind
`resolved_children_trigger_batch_event_sequence`.

The first generated-child actor-to-actor route through that generated top is
shipped by `isf/atl_two_child_data_pipeline.isf`.

Downstream producers may emit one named drive body pair `(writer.payload
reader.payload)` between two resolved children when the parent transaction is
ordered as `trigger reader.capture`, `await reader.done`, `drive
forward_payload`, `trigger writer.emit`, `await writer.done`, then complete.

The parent exposes `reader_payload` as the generated source handoff input and
`writer_payload` as the generated sink handoff output; the generated top
wires `reader.payload` to parent `reader_payload` and parent `writer_payload`
to `writer.payload`.

Downstream consumers should read one-bit route provenance from
`actor_network.data_movements[]` with `kind: "scalar_actor_handoff"` and
generated-top discovery from `actor_network.generated_tops[]` with
`children[]`.

No new report family or public `data_links` key is exposed.

The exact-width vector generated-child actor-to-actor route is shipped by
`isf/atl_two_child_vector_data_pipeline.isf`.

Downstream producers may emit the same `(sink source)` drive-body pair between
two resolved children when the source endpoint is a child output, the sink
endpoint is a child input, and both endpoint declarations have the same
positive width. The parent source handoff, parent sink handoff, child
interface roles, generated top links, and generated HDL links use that exact
width. Schedule JSON keeps the same route entry shape and reports
`kind: "vector_actor_handoff"`, `width` equal to the endpoint width, and
`width_source: "resolved_child_endpoint_exact_width"`.

The bounded multi-route form is shipped by
`isf/atl_two_child_multi_data_pipeline.isf`.

Downstream producers may emit multiple named actor-to-actor drive bodies in
the same parent transaction only when all routes share the same resolved source
child, the same resolved sink child, one direct endpoint pair per drive body,
matching source/sink endpoint widths for each route, and one argument-free
top-level drive call per route.

The accepted route segment is contiguous: source trigger, source event wait,
all route drive calls, sink trigger, sink event wait. The shipped fixture moves
`payload` and `sideband` from `reader` to `writer` through separate route drive
calls and separate generated parent handoffs.

Downstream consumers still read every route from
`actor_network.data_movements[]`: scalar one-bit routes use
`kind: "scalar_actor_handoff"`, and exact-width vector routes use
`kind: "vector_actor_handoff"`. Generated-top discovery still uses
`actor_network.generated_tops[]` with `children[]`. No new report family or
public `data_links` key is exposed.

Downstream producers must still treat broader actor-to-actor generated-child
routes, fan-in/fan-out source or sink sets, width adaptation, route
mux/storage, CDC/reset remapping, ready/backpressure, payload protocols,
recursive actor networks, repeated triggers, trigger-batch plus data movement
coupling, groups, cross-transaction continuation, and permanent actor grouping
as deferred. A shipped route segment fails closed if
its drive calls do not follow the source event wait and precede the sink
trigger.

Downstream producers must also keep the route drive unparameterized and the
route drive call argument-free. Parameterized route drive definitions and
route drive calls with actual arguments remain fail-closed before drive
actual binding, expression movement, or payload protocols are inferred.
That same route-drive argument boundary applies to the shipped generated-top
pin-ingress and pin-egress route families; route drive calls are one-cycle
timing points, not parameterized payload-binding calls.

The route source must remain one scalar endpoint. A drive-body source
expression such as `(writer.payload (+ reader.payload 1))` remains
fail-closed before FSMGen infers expression movement, payload transformation,
storage, muxing, or backpressure behavior.

The shipped FSMGen hardening around this route keeps the downstream surface
bounded.

It adds focused fail-closed coverage for adjacent invalid shapes: the source
endpoint must be a scalar output on the source child, the sink endpoint must
be a scalar input on the sink child, every selected route drive body must
contain exactly one endpoint pair, and each route must be activated by exactly
one top-level drive call.

Downstream producers should keep emitting only the shipped same-source,
same-sink scalar or exact-width vector route set until a later spec update
explicitly widens the contract.

The shipped width hardening now accepts same-width generated-child
actor-to-actor routes. Wider source child outputs paired with one-bit sink
inputs, one-bit source outputs paired with wider sink inputs, and any other
source/sink width mismatch remain fail-closed. Downstream producers should not
assume truncation, extension, packing, slicing, payload protocols, muxing, or
storage insertion.

The shipped clock/reset hardening keeps the generated-child actor-to-actor
route in one parent clock/reset policy.

Source or sink child clock/reset mismatches fail closed until FSMGen
publishes an explicit CDC bridge or reset-remapping contract; downstream
producers should not assume generated system-port remapping, async crossing
logic, route storage, muxing, or backpressure insertion.

The shipped self-route hardening keeps the generated-child actor-to-actor
route between two distinct resolved children.

Same-child source/sink route pairs fail closed; downstream producers should
not assume self-route, loopback, child-internal bypass, storage, muxing,
fan-in/fan-out, backpressure, or payload insertion until FSMGen publishes an
explicit contract for those behaviors.

The shipped repeated-trigger hardening keeps the route sequence to one
source-child trigger and one sink-child trigger.

Extra route-child triggers fail closed; downstream producers should not
assume repeated activation, restart, pending-request merging, trigger
fan-in/fan-out, or multi-activation scheduling until FSMGen publishes an
explicit contract for those behaviors.

The shipped repeated-wait hardening keeps the same route sequence to one
source-child event wait and one sink-child event wait.

Extra route-child waits fail closed; downstream producers should not assume
event fan-in/fan-out, repeated wait sequencing, child replay, route-level
wait storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped same-parent-transaction hardening keeps the entire route sequence
inside one parent transaction.

Downstream producers must not split the source trigger, source wait, data
drive call, sink trigger, and sink wait across multiple parent transactions
or assume route continuation, pending handoff storage, transaction
rendezvous, cross-transaction scheduling, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

The shipped sink-trigger ordering hardening keeps the route data drive call
before the sink child trigger.

Downstream producers must not trigger the sink child before the drive call or
assume speculative sink activation, delayed payload delivery, route storage,
muxing, backpressure, or payload insertion until FSMGen publishes an explicit
contract for those behaviors.

The shipped sink-event-wait ordering hardening keeps the sink child event
wait after the sink child trigger.

Downstream producers must not wait on the sink child event before triggering
that child or assume pre-trigger acknowledgement, sticky event sampling,
event replay, route storage, muxing, backpressure, or payload insertion until
FSMGen publishes an explicit contract for those behaviors.

The shipped source-event-wait ordering hardening keeps the source child event
wait after the source child trigger.

Downstream producers must not wait on the source child event before
triggering that child or assume pre-trigger acknowledgement, sticky event
sampling, event replay, route storage, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

The shipped route-contiguity hardening keeps the same route as one contiguous
transaction-body segment.

Downstream producers must not interleave unrelated parent transaction clauses
between the source trigger, source event wait, data drive call, sink trigger,
and sink event wait or assume interleaved parent work, local side effects,
pre/post route sampling, route continuation, pending handoff storage, muxing,
backpressure, or payload insertion until FSMGen publishes an explicit
contract for those behaviors.

The shipped route-isolation hardening keeps that contiguous segment as the
only executable parent transaction-body work between the transaction start
condition and completion.

Downstream producers must not emit unrelated parent clauses before the source
trigger or after the sink event wait, or assume pre-route setup, post-route
sampling, local side effects, cleanup work, route continuation, pending
handoff storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped route-boundary cardinality hardening keeps that isolated route
bounded by exactly one simple `(on ...)` start condition and exactly one
simple `(complete ...)` completion pulse.

Downstream producers must not emit extra start boundaries or extra completion
boundaries around the route, or assume activation fan-in, completion fan-out,
start-condition arbitration, local setup/cleanup, route continuation, pending
handoff storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped boundary-simplicity hardening keeps those two route boundaries
body-free.

Downstream producers must not emit `(on ...)` activation-body samples or
`(complete ...)` extra payload operands around the route, or assume
activation-body sampling, completion payload/fan-out, local setup/cleanup,
route continuation, pending handoff storage, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

## 13. Scheduled `.fsm` Review Artifact

Downstream tools should treat the scheduled `.fsm` files as review artifacts
and as the input to FSMGen's HDL backend, not as a general stable AST API.
Stable machine consumption should prefer the schedule JSON and manifest key
families.

Important `.fsm` lowering conventions:

- Every accepted transaction lowers to explicit state blocks.
- Drives and rules lower to non-state DT blocks.
- `=` is combinational.
- `<-`, `<=`, and `<1` are sequential/operator families in the public contract.
- `<1` is used for one-cycle delayed pulses such as completion and rule
  trigger sources.
- Generated top files use canonical Lisp-ish `?wiring` links.
- Multi-domain accepted event-crossing actors emit domain `.fsm` artifacts, a
  generated top `.fsm`, and generated CDC child interface metadata.
- Multiple accepted event crossings in one actor emit one generated CDC child
  interface and one report entry per crossing.

Deterministic DT ordering:

```text
transaction and rule DT blocks keep construction order;
generated rule-trigger fan-in DT blocks follow rule DTs by transaction name;
hash-backed drive DT blocks are sorted lexically by drive name
```

## 14. Schedule JSON Report

`--emit-schedule-json` and `FSM::Scheduler::ISF->report(...)` expose the
bounded schedule report. Top-level keys currently advertised:

```text
schema_version
source
scheduled_fsm
clock
reset
watchdog
actor_phases
actor_stages
verification_observations
actor_params
actor_constants
port_count
inputs
outputs
state_count
inferred_storage
transactions
transaction_waits
transaction_loops
loop_early_exits
transaction_stages
temporal_contracts
bank_accesses
transaction_port_bindings
dt_blocks
actor_network
generated_composition
library_uses
compatible_fanin_groups
priority_resolutions
resource_arbitration
compile_issues
clock_domains
crossings
```

Generated names in reports and generated artifacts are deterministic for the
same source and FSMGen version. They can be used as report-local or
artifact-local identifiers when another public field explicitly references the
same name. They are not a semantic string grammar for downstream tools to
parse. Downstream consumers should use explicit bounded fields such as
`owner`, `owner_kind`, `role`, `kind`, `instance`, `parent_port`,
`child_port`, `trigger_source`, `payload_source`, storage `role`, and
generated-composition summaries. Before the whole schedule JSON schema is
frozen, generated spelling may change only in a feature-scoped slice that also
updates docs, contract metadata where applicable, and tests.

Schedule-report evolution rules:

- New top-level keys, new nested optional keys, and new advertised value-family
  members are additive only when the same slice updates public contract
  metadata, focused tests, this handoff, and the book/spec.
- Removing an advertised key, renaming a key, changing required/optional
  status, changing a value type, or changing an advertised value's meaning is
  breaking.
- Breaking schedule-report changes require a `schema_version` bump and
  migration or deprecation documentation in the same slice.
- Deprecated fields stay documented until the schema version that removes them.

Actor-level passive observation metadata is report-only. The accepted source
form is `(observe NAME (role passive_monitor) (signals SIG...))`, where
`SIG...` must name public actor interface signals in a single-clock actor.
Downstream consumers may read `verification_observations[]` to discover
authored passive monitor intent, inherited clock/reset context, and
source-ordered signal `name`/`direction`/`width` summaries. They must not infer
generated `.fsm`, HDL, UVM, VHDL, scoreboard, coverage, or VIP artifacts from
that metadata. The future first verification-output surface has now been
selected as `--emit-verification-output uvm-passive-monitor
--verification-outdir DIR source.isf`, with artifacts under `DIR/uvm/` and a
`DIR/verification-output-manifest.json` manifest, but implementation remains
owned by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8`; current releases do
not emit verification output from this metadata yet.

Golden fixture matrix:

- `t/1255-isf-schedule-report-golden-matrix.t` is the executable matrix for
  the advertised schedule-report branches.
- Each matrix case runs through both `FSM::Scheduler::ISF->report(...)` and
  `./bin/fsmgen --emit-schedule-json`, and the test requires equal payloads.
- Every advertised `schedule_report_*` contract branch has a matrix owner
  where that branch is a schedule-report payload family.
- `schedule_report_full_schema_stable` is true for schedule JSON
  `schema_version: 1`.

Assignment and child-summary boundary:

- Raw assignment provenance, private assignment indexes, and activation proof
  internals are not public schedule-report fields.
- Public substitutes are bounded summaries: `compile_issues[]` source
  summaries, `compatible_fanin_groups[]`, `priority_resolutions[]`,
  `resource_arbitration[]`, `transaction_port_bindings[]`, `bank_accesses[]`,
  and aggregate counts such as `dt_blocks[].assignments`.
- Parent reports do not embed recursive child schedule reports. Public
  multi-file detail is the `lower(...)` files map, generated `.fsm` artifacts,
  `actor_network`, `generated_composition`, `library_uses[]`, and
  `clock_domains[]` / `crossings[]`.
- Downstream integrations should report bugs with the runnable source,
  command, bundle, and observed output. They do not need to classify whether a
  failure belongs to `.fsm`, `.isf`, private provenance, or generated child
  internals.

Scalar summaries:

- `schema_version`: integer `1` for the current schedule-report payload
  shape. This is separate from the
  `embedding.isf_public_interface.schema_version` contract metadata.
- `source`: report source basename derived from the actor name with `.isf`.
- `scheduled_fsm`: scheduled `.fsm` basename for the report scope. Multi-domain
  reports use the generated `<actor>_top.fsm` artifact.
- `clock`: actor/default-domain clock name; omitted legacy single-clock
  clocks report `clk`.
- `reset`: object with `name`, `kind`, and `polarity` for configured or
  defaulted legacy single-clock resets; null only when the selected
  default-domain reset is omitted in a `(clock-domains ...)` actor.
- `watchdog`: scalar watchdog limit; omitted watchdogs report `65535`; accepted
  actor-level actor constants, actor scalar parameters, and qualified imported
  package scalar constants report as resolved integers.
- `inputs`, `outputs`, `port_count`, `state_count`: non-negative integer
  counts. Multi-domain generated-top reports use `state_count == 0` and put
  domain-local counts in `clock_domains[]`.
- `compile_issues`: array; empty on successful reports without nonfatal
  issues.

Important entry key families:

```text
actor_constants[]: name, value
actor_phases[]: name, body
actor_stages[]: name, body
verification_observations[]: name, role, clock, reset, signals
verification_observations[].signals[]: name, direction, width
actor_params[]: name, value
inferred_storage[] required: name, kind
inferred_storage[] optional: role, type, type_kind, width, fields
inferred_storage[].fields[]: name, msb, lsb, width, access, reset, enum
transactions[]: name, states, count
transaction_waits[]: transaction, cycles, count_kind, count_source,
  entry_state, exit_state, counter_signal, counter_width
transaction_loops[]: transaction, kind, condition, entry_state,
  decision_states, body_start, body_states, exit_state, body_clause_count
loop_early_exits[]: transaction, kind (exit_when|continue_when), state,
  condition, target
transaction_stages[]: transaction, name, kind, state, ready, valid
temporal_contracts[]: transaction, name, kind, trigger, signal,
  within_cycles, pending_signal, counter_signal, fail_signal,
  overlap_policy, reset_policy, assertion_projection
bank_accesses[]: kind, owner, owner_kind, container_kind, container_name,
  bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings[]: site_kind, owner, owner_kind, target_transaction,
  role, port, actor_signal, actor_expression, actor_endpoint_kind,
  binding_timing, authored_timing_mode, width, instance, parent_port,
  child_port, start_signal, done_signal, trigger_source, payload_source
dt_blocks[]: name, kind, assignments
actor_network: kind, instances, groups, association_schedules,
  group_schedules, data_movements, event_waits, transaction_triggers
actor_network.instances[]: name, actor_type, declaration
actor_network instance declaration values: actor, instance_alias
resolved actor_network.instances[] child-artifact metadata keys:
type_resolution, library, alias, export, module, scheduled_fsm
actor_network.groups[]: name, members, mode, declaration, source, scheduling
actor_network.association_schedules[]: association, kind, lifetime,
  owner_transaction, context, members, target_transactions, signals, schedule,
  dependency_policy, storage, source, sink
actor_network.group_schedules[]: group, owner_transaction, context, members,
  target_transactions, signals, schedule, dependency_policy, storage, source,
  sink
actor_network.event_waits[]: transaction, context, instance, event, signal,
  source
actor_network.transaction_triggers[]: owner_transaction, context, instance,
  target_transaction, signal, sink
library_uses[]: library, alias, export, kind, instance, module,
  scheduled_fsm, parameters, bindings
clock_domains[]: name, default, clock, reset, scheduled_fsm, ports, storage,
  transactions, rules, library_uses, child_instances, crossings, state_count,
  dt_block_count
crossings[]: name, kind, source_domain, source_signal, destination_domain,
  destination_signal, ready_signal, instance, module, outstanding_policy,
  payload, top_fsm
```

Generated composition summary:

```text
generated_composition required keys:
  kind, top_module, top_fsm, parent, children, instances

parent keys:
  module, scheduled_fsm

children[] keys:
  transaction, module, scheduled_fsm, parameters

children[].parameters[] keys:
  name, default

instances[] keys:
  instance, child, activation_kind, start, done, parameter_bindings,
  drive_handoffs

parameter_bindings[] keys:
  name, source, value

drive_handoffs[] keys:
  drive, request, payloads

payloads[] keys:
  parameter, child_port, parent_port, width
```

Known value families:

```text
reset.kind: async, sync
reset.polarity: active_high, active_low
transaction_waits.count_kind: static, runtime_scalar, runtime_expression
transaction_stages.kind: ready_valid_barrier
temporal_contracts.kind: bounded_eventually
temporal_contracts.overlap_policy: fail
temporal_contracts.assertion_projection: systemverilog_sticky_fail
bank_accesses.kind: store, load
bank_accesses.same_cycle_policy: read_before_write
transaction_port_bindings.site_kind: do, spawn, rule_trigger
transaction_port_bindings.actor_endpoint_kind: signal, literal, expression
transaction_port_bindings.binding_timing: activation_region,
  generated_live_handoff, trigger_payload, done_guarded
transaction_port_bindings.authored_timing_mode: snapshot, live, or JSON null
generated_composition.kind: activation_generated_top, spawn_generated_top
inferred_storage.kind: counter, register
inferred_storage.role: activation_done_handoff, activation_start_handoff,
  actor_storage, atl_trigger_start_handoff, completion_pulse, data_register,
  dynamic_wait_counter, drive_payload, drive_request, extract_field,
  latency_counter, repeat_counter, resource_round_robin_pointer,
  rule_trigger_payload_source, rule_trigger_source, sample_alias,
  scheduler_error_status, temporal_contract_monitor, transaction_port,
  transaction_port_binding, trigger_done_observe, watchdog_counter
inferred_storage.type/type_kind: optional bounded authored type token and
  resolved top-level type kind for declared typed actor-owned storage
dt_blocks.kind: drive, do_port_binding, latency_counter, rule,
  rule_trigger_fanin, spawn_port_binding, temporal_contract_monitor,
  trigger_generated_activation
compile_issues.severity: warning
compile_issues.proof_status: not_doable
```

Report stability rules:

- A downstream tool may rely on the listed key families and value families.
- JSON null is used for non-applicable optional fields.
- `dt_blocks[].assignments` is a non-negative assignment count, not an
  assignment payload list.
- Transaction summaries are sorted lexically by transaction name.
- Each `transactions[].states` array preserves emitted scheduled `.fsm` state
  order for that transaction.
- The full schema may grow; do not reject unknown keys unless your integration
  deliberately chooses strict mode for its own version pin.

## 15. Diagnostics And Fail-Closed Policy

FSMGen must reject unsupported or malformed public ISF forms before emitting
misleading scheduled artifacts. Downstream tools should surface diagnostics as
source errors and should not assume a malformed form was partially accepted.

Required fail-closed examples:

- Unknown actor, transaction, rule, drive, storage, domain, or resource names
  where a declaration is required.
- Duplicate singleton actor clauses.
- Duplicate names in interfaces, drives, storage, rules, transactions,
  parameters, domains, imports, or instances.
- Unsupported transaction clause heads in a lowered context.
- Unsupported `(on ...)` body forms such as `(params ...)`.
- Rule triggers targeting unknown transactions.
- Direct/local rule-trigger output bindings.
- Literal-zero, actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisor operands in shipped runtime
  division/modulo expression contexts.
- Watchdog limits that name actor-level transaction parameters,
  nested-control-flow transaction parameters, cross-transaction parameters,
  runtime interface signals, unknown symbolic names, arbitrary expressions,
  constants that resolve to zero, actor/transaction parameters that resolve to
  zero or non-scalar values, or distinct per-await limits in one transaction.
- Repeat counts that name cross-transaction parameters, unknown symbolic
  names, arbitrary expressions, malformed scalar tokens, actor/transaction
  parameters that resolve to non-scalar values, runtime names without width
  evidence, or statically zero bodies containing malformed child activation
  subclause syntax.
- Latency min/max bounds that name cross-transaction parameters, runtime
  interface signals, unknown symbolic names, arbitrary expressions, constants
  that resolve to zero, or actor/transaction parameters that resolve to zero
  or non-scalar values.
- Generated child activation overrides that change child transaction
  parameters consumed by repeat, wait, latency, or top-level await-local
  watchdog lowering. Same-value overrides are accepted; mismatches fail closed
  until per-activation static timing specialization is shipped.
- Generated child activation overrides that change child transaction
  parameters consumed by data-operation widths (`shift_left`, `shift_right`,
  `assemble`, `extract`). Same-value overrides are accepted; mismatches fail
  closed with a targeted `static-width parameter` diagnostic until
  per-activation data-op width specialization is shipped.
- Generated child activation overrides that change child transaction
  parameters consumed by transaction port widths
  (`(ports (input/output NAME (width PARAM)))`). Same-value overrides are
  accepted; mismatches fail closed with a targeted `static port-width
  parameter` diagnostic until per-activation transaction port width
  specialization is shipped.
- Cross-domain repeat-body `do`: a `(do TARGET (domain X))` annotation
  where the target transaction is in a different clock domain than the
  calling transaction now fails closed with a targeted "cross-domain
  repeat-body do remains deferred" diagnostic instead of the generic
  same-domain-feature `(params)` requirement message. Cross-domain do
  without the `(domain ...)` annotation still emits the generic
  clock-domain violation message. Cross-domain repeat-body do lowering
  itself remains backlog.
- Temporal contract windows that need activation-site override-specialized
  lowering beyond same-value generated child activation overrides,
  transaction parameters from other transactions, runtime interface signals,
  unknown symbolic names, arbitrary expressions,
  unknown or unqualified package constants, aggregate package constants,
  package member/item paths, ambiguous
  local-enum/package-constant spellings, constants that resolve to zero, or
  actor/transaction parameters that resolve to zero or non-scalar values.
- Direct cross-domain access without a shipped crossing primitive.
- Width mismatch where width evidence is known.
- Parameter override unknown names, duplicate names, symbolic values, and
  incompatible aggregate/list shapes.
- Unknown type aliases, `(width ...)` plus `(type ...)` on the same
  declaration, package import aliases, aggregate type aliases outside
  actor-owned storage variables, unknown aggregate members, out-of-range list
  indexes, aggregate storage member/item paths outside direct transaction
  `set` RHS values, direct transaction `set` target tokens, transaction
  condition scalar values or expression operands, transaction `switch`
  selectors or branch values, rule assignment target tokens, rule assignment
  RHS values/expression operands, rule guard scalar values/expression
  operands, drive target tokens, drive body RHS scalar values/expression
  operands, inline drive target tokens, inline drive assignment RHS scalar
  values/expression operands,

  or drive-call actual scalar values/expression operands, aggregate paths in
  expression operator position, subaggregate operands/updates, and enum
  member references outside the shipped actor-constant, actor parameter
  scalar default or aggregate/list default leaf, actor-constant-backed actor
  parameter default scalar or aggregate/list leaf, generated child transaction
  scalar parameter default or aggregate/list default leaf, scalar activation
  parameter override, activation aggregate/list override leaf,
  reusable-library use-site parameter override value or leaf, actor-static
  library use-site override value or leaf, package-constant-backed library
  use-site override value or leaf, transaction
  condition scalar value or expression operand, transaction `set` RHS
  scalar/expression operand, transaction `switch` selector/branch-value, rule
  guard scalar/expression operand, rule assignment RHS scalar/expression
  operand,

  drive body RHS scalar/expression operand, inline drive RHS
  scalar/expression operand, and drive-call actual scalar/expression-operand
  contexts.
- Unsupported raw `assign` compatibility forms. The removed transaction
  `(assign ...)` keyword has targeted migration guidance to existing explicit
  timing constructs; it is not accepted or auto-mapped.

Compatibility rule:

- Deprecated handshake metadata is validated for shape and ignored. It is not a
  public ready/valid lowering feature.

## 16. Conformance Fixtures And Checks

Representative shipped fixtures:

```text
isf/apb_requester.isf
isf/i2c_master.isf
isf/spi_master.isf
isf/spawn_parent.isf
isf/rule_resource_arbiter.isf
isf/full_featured.isf
isf/clock_domain_event_crossing.isf
isf/clock_domain_dual_event_crossing.isf
isf/clock_domain_no_reset_event_crossing.isf
isf/common/fifo.isf
isf/fifo_controller.isf
isf/fifo_data_path.isf
isf/fifo_library_use.isf
isf/atl_trigger_batch_pipeline.isf
isf/atl_data_route_pipeline.isf
isf/atl_pin_ingress_pipeline.isf
isf/atl_pin_egress_pipeline.isf
isf/atl_trigger_wait_pipeline.isf
isf/atl_trigger_batch_wait_pipeline.isf
isf/atl_trigger_batch_multi_wait_pipeline.isf
isf/atl_resolved_child_pipeline.isf
isf/atl_resolved_child_pin_ingress_pipeline.isf
isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
isf/atl_resolved_child_pin_egress_pipeline.isf
isf/atl_resolved_child_pin_egress_vector_pipeline.isf
isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
isf/atl_two_child_pipeline.isf
isf/atl_two_child_data_pipeline.isf
isf/atl_two_child_vector_data_pipeline.isf
isf/atl_two_child_multi_data_pipeline.isf
```

The SPI-like fixture and I2C-like fixture are bounded realistic examples, not
complete external protocol compliance suites.

SPI is covered by `t/1228-isf-spi-fixture-coverage.t`.

I2C is covered by `t/1309-isf-i2c-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, switch-branch repeats, read-data shifting, sampled write-data bit
selection from `data[7]`, and no implicit `data_bit` input.

The burst-reader fixture is covered by `t/1310-isf-burst-fixture-coverage.t`,
which proves strict schedule JSON parity, scheduled `.fsm` structure, plain
and strict HDL generation, dynamic repeat counter storage, watchdog and
latency counter roles, sampled aliases, and completion/timeout pulse fan-in.

The UART-like transmit fixture is covered by
`t/1311-isf-uart-fixture-coverage.t`, which proves strict schedule JSON
parity, scheduled `.fsm` structure, plain and strict HDL generation,
sampled-byte LSB drive selection from `byte_data[0]`, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior.

The phase fixture is covered by `t/1312-isf-phase-fixture-coverage.t`, which
proves strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, transaction phase pass-through states, no reusable
`done` drive storage, and delayed completion pulse behavior without claiming
runtime actor-level phase scheduling.

The switch fixture is covered by `t/1313-isf-switch-fixture-coverage.t`,
which proves strict schedule JSON parity, scheduled `.fsm` structure, plain
and strict HDL generation, sampled selector capture, explicit branch
dispatch, default fallthrough to completion, named-drive branch starts, and
delayed completion pulse behavior.

The when fixture is covered by `t/1314-isf-when-fixture-coverage.t`, which
proves strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, entry drive setup, two conditional decision states,
multi-step true-body drives, false-path fallthrough, compatible named-drive
start fan-in, and delayed completion pulse behavior.

The generated-composition fixture is covered by
`t/1315-isf-generated-composition-fixture-coverage.t`, which proves strict
schedule JSON parity, strict `--outdir` file emission, generated top, parent,
and child scheduled `.fsm` artifacts, start/done handoffs, named-drive
request/payload handoffs, public input fanout, `await_all` synchronization,
and strict HDL generation for the generated top, parent, and child artifacts.

This is the representative downstream handoff path for spawned
generated-child composition; it is not a protocol compliance claim.

The rule/resource fixture is covered by
`t/1316-isf-rule-resource-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, plain and strict HDL generation,
rule-over-transaction priority suppression, `rule_slot`/`priority` resource
metadata, lower-priority rule gating by a higher-priority rule, and delayed
completion pulse behavior.

Dedicated resource arbitration tests now cover the shipped priority arbiter
for `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port`,
including explicit output-bundle member-list validation,
transaction-start trigger-user validation, storage-port storage-member
validation, and `resource_arbitration[].members` report evidence. They also
cover bounded `rule_slot`/`round_robin`, `output_bundle`/`round_robin`,
`transaction_start`/`round_robin`, and `storage_port`/`round_robin` grants,
generated pointer storage metadata, report projection, and fail-closed
unsupported round-robin combinations.
The fixture above remains a `rule_slot` fixture; it does not claim
weighted, token bucket, interface-bundle, named-drive, child-instance, or
broader round-robin resource support.

The ready/valid stage and assertion-property surfaces are covered by the live
stage and property tests: `t/1179-isf-phase-stage-boundary.t`,
`t/1223-isf-stage-lowering.t`, `t/1252-isf-actor-phase-stage-report.t`,
`t/1410-isf-assert-carrier.t`, `t/1411-isf-assert-emit.t`,
`t/1412-isf-property-implication.t`,
`t/1417-isf-property-sampled-value.t`, and
`t/1418-isf-property-window-range.t`. Together they cover ready/valid stage
lowering, phase/stage report projection, assertion carriers, SystemVerilog
assertion emission, implication properties, sampled-value properties, and
window-range property parsing/lowering.

This coverage proves the shipped top-level ready/valid stage substrate and
assertion-property path; it does not claim nested stages, nested contracts,
stage-local compute, full AXI Valid-Ready protocol monitoring, source-anchor
IAL2 reports, min/max temporal monitor implementation, or broader temporal
operators.

The FIFO datapath fixture is covered by
`t/1319-isf-fifo-datapath-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, bounded `bank_accesses[]` metadata,
plain and strict HDL generation, scalarized `data_0` through `data_3` bank
storage, pointer-guarded accepted pushes, and pointer-guarded accepted pops.

This fixture covers the shipped depth-4 scalarized bank store/load surface;
it does not claim general memory-array HDL emission, write-first collision
behavior, bypassing, or arbitrary-depth parameterized FIFOs.

The FIFO controller fixture is covered by
`t/1320-isf-fifo-controller-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, compatible same-value fan-in
metadata, plain and strict HDL generation, idle cycles, push-only, pop-only,
simultaneous push+pop occupancy updates, actor-maintained full/empty flags,
and 2-bit pointer wrap.

This fixture is controller-only; it does not claim data-bank storage or
`data_out` datapath transfer behavior.

The FIFO library fixture is covered by
`t/1321-isf-fifo-library-fixture-coverage.t`, which proves strict schedule
JSON parity, generated importer/child/top scheduled `.fsm` artifacts, strict
`--outdir` file emission, fixed parameter overrides, use-site bindings,
scalarized FIFO data entries, plain and strict generated-top HDL generation,
and generated top wiring for `isf/fifo_library_use.isf`.

The ATL temporary trigger-batch fixture is covered by
`t/1324-isf-atl-fixture-coverage.t`, which proves strict schedule JSON
parity, scheduled `.fsm` structure, one same-cycle external trigger-batch
state, per-target trigger handoffs, canonical `association_schedules[]`,
compatibility `group_schedules[]`, static actor-network report metadata, and
plain plus strict HDL generation for `isf/atl_trigger_batch_pipeline.isf`.

It intentionally does not declare a permanent `(group ...)` association.

The ATL scalar data-route fixture is covered by
`t/1325-isf-atl-data-route-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, generated parent handoff ports
`producer_payload` and `consumer_payload`, one
`actor_network.data_movements[]` entry with route lifetime
`drive_call_cycle`, empty association/group schedule arrays, and plain plus
strict HDL generation for `isf/atl_data_route_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
route mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out,
CDC, ready/backpressure, or permanent actor grouping.

The ATL scalar pin-ingress fixture is covered by
`t/1326-isf-atl-pin-ingress-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, the existing top-level input source
pin `payload`, generated actor handoff output `consumer_payload`, one
`actor_network.data_movements[]` entry with kind
`scalar_pin_to_actor_handoff`, empty association/group schedule arrays, and
plain plus strict HDL generation for `isf/atl_pin_ingress_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor-to-pin egress, bidirectional pin movement, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL scalar pin-egress fixture is covered by
`t/1327-isf-atl-pin-egress-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, generated actor source handoff input
`producer_payload`, existing top-level output sink `result`, one
`actor_network.data_movements[]` entry with kind
`scalar_actor_to_pin_handoff`, empty association/group schedule arrays, and
plain plus strict HDL generation for `isf/atl_pin_egress_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
bidirectional pin movement, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent actor
grouping.

The ATL trigger-wait fixture is covered by
`t/1328-isf-atl-trigger-wait-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, one `(trigger
worker.process)` parent output pulse, one `(await worker.done)` parent event
input wait, one `actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, empty association/group/data-movement
arrays, and plain plus strict HDL generation for
`isf/atl_trigger_wait_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor type resolution, HDL child wiring, temporary trigger-batch plus event
coupling, data movement coupling, fan-in/fan-out, CDC, ready/backpressure, or
permanent actor grouping.

The ATL trigger-batch wait fixture is covered by
`t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, three same-cycle generated
trigger output pulses, one following `writer_done` event input wait,
`actor_network.association_schedules[]` temporary-association metadata,
`actor_network.group_schedules[]` compatibility metadata, one
`actor_network.event_waits[]` entry, empty data movement, and plain plus
strict HDL generation for `isf/atl_trigger_batch_wait_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor type resolution, HDL child wiring, hidden multi-event fan-in joins, data
movement coupling, CDC, ready/backpressure, or permanent actor grouping.

The ATL trigger-batch multi-event wait fixture is covered by the same test. It
proves strict schedule JSON parity, scheduled `.fsm` structure, three
same-cycle generated trigger output pulses, three following source-ordered
event input waits (`reader_done`, `filter_done`, and `writer_done`), three
`actor_network.event_waits[]` entries, one task-scoped
`association_schedules[]` entry, one compatibility `group_schedules[]` entry,
empty data movement, and plain plus strict HDL generation for
`isf/atl_trigger_batch_multi_wait_pipeline.isf`.

It intentionally remains sequential parent-handoff orchestration and does not
claim hidden same-cycle actor-event joins, repeated waits to one actor, event
payloads, generated ATL child event wiring, data route coupling, CDC,
ready/backpressure, or permanent actor grouping. Repeated waits to one
triggered actor fail closed until an event re-arm or per-event lifetime
contract exists.

The ATL resolved-child fixture is covered by
`t/1330-isf-atl-resolved-child-fixture-coverage.t`, which proves strict
schedule JSON parity, exactly three lower-result artifacts
`atl_resolved_child_pipeline.fsm`, `atl_resolved_child_pipeline__worker.fsm`,
and `atl_resolved_child_pipeline_top.fsm`, resolved
`actor_network.instances[]` metadata for `worker`, one
`actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, one `actor_network.generated_tops[]`
entry, and empty data/association/group schedule arrays for
`isf/atl_resolved_child_pipeline.isf`.

It also proves strict `--outdir` top emission and fail-closed diagnostics for
missing child transactions, non-scalar child activation, missing child event
outputs, and parent/child clock mismatches.

It intentionally does not claim multiple resolved children, trigger batches,
data-route coupling, route mux/storage, actor-event fan-in, CDC,
ready/backpressure, recursive actor networks, or permanent actor grouping.

The HDL promotion leaf keeps the same source and report contract and proves
this fixture through plain and strict CLI HDL generation, requiring the
emitted SystemVerilog to contain the generated top, scheduled parent,
resolved child, and selected internal trigger/event links.

The generated-child pin-ingress leaf extends that shipped downstream
contract: `isf/atl_resolved_child_pin_ingress_pipeline.isf` proves one
top-level input pin to one resolved child input through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, generated
child input role preservation, plain and strict CLI HDL generation, and a
fail-closed missing child input diagnostic for that route.

The generated-child exact-width vector pin-ingress leaf extends that same
downstream contract: `isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`
proves one vector top-level input pin to one vector input on the resolved
child through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_pin_to_actor_handoff` `data_movements[]` entry, generated child input
role preservation at width 8, generated-top wiring for the exact-width route,
strict outdir materialization, plain plus strict CLI HDL generation, and a
fail-closed top-input/child-input width mismatch diagnostic.

The generated-child exact-width vector pin-ingress multi-route leaf extends
that same downstream contract:
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` proves multiple
vector top-level input pins to multiple vector inputs on one resolved child
through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, two
`vector_pin_to_actor_handoff` `data_movements[]` entries, route-local widths
8 and 4, generated child input role preservation for both routed vector
signals, generated-top wiring for both exact-width handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local top-input/child-input width mismatch diagnostic.

The generated-child mixed scalar/vector pin-ingress route-set leaf extends that
same downstream contract:
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` proves one exact-width
vector top-level input pin and one scalar top-level input pin to matching
inputs on one resolved child through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_pin_to_actor_handoff` entry, one `scalar_pin_to_actor_handoff` entry,
route-local widths 8 and 1, generated child input role preservation for both
routed signals, generated-top wiring for both handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local top-input/child-input width mismatch diagnostic for the vector
route.

The generated-child pin-ingress multi-route leaf extends that same downstream
contract: `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` proves
multiple top-level input pins to multiple inputs on one resolved child through
the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, two
`scalar_pin_to_actor_handoff` `data_movements[]` entries, generated child input
role preservation for both routed scalar signals, generated-top wiring for both
pin-ingress handoffs, strict outdir materialization, plain plus strict CLI HDL
generation, and fail-closed missing-input, interleaved-drive-call, and
duplicate-source-pin diagnostics for that route set.

The generated-child pin-egress leaf extends the same downstream contract:
`isf/atl_resolved_child_pin_egress_pipeline.isf` proves one resolved child
output to one top-level output pin through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, generated
child output role preservation, plain and strict CLI HDL generation, a
fail-closed missing child output diagnostic, and a fail-closed pre-event
drive-order diagnostic for that route.

The generated-child exact-width vector pin-egress leaf extends that same
downstream contract:
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` proves one vector
output from one resolved child to one vector top-level output pin through the
generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_actor_to_pin_handoff` `data_movements[]` entry, generated child output
role preservation at width 8, generated-top wiring for the exact-width route,
strict outdir materialization, plain plus strict CLI HDL generation, and a
fail-closed child-output/top-output width mismatch diagnostic.

The generated-child exact-width vector pin-egress multi-route leaf extends
that same downstream contract:
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` proves multiple
vector outputs from one resolved child to multiple vector top-level output pins
through the generated top. The same regression proves strict schedule JSON
parity, parent/child/top `.fsm` artifacts, two
`vector_actor_to_pin_handoff` `data_movements[]` entries, generated child
output role preservation at widths 8 and 4, generated-top wiring for both
exact-width routes, strict outdir materialization, plain plus strict CLI HDL
generation, and fail-closed child-output/top-output width mismatch
diagnostics.

The generated-child mixed scalar/vector pin-egress route-set leaf extends that
same downstream contract:
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` proves one exact-width
vector resolved child output and one scalar resolved child output to matching
top-level output pins through the generated top. The same regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_actor_to_pin_handoff` entry, one `scalar_actor_to_pin_handoff` entry,
route-local widths 8 and 1, generated child output role preservation for both
routed signals, generated-top wiring for both handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local child-output/top-output width mismatch diagnostic for the vector
route.

The generated-child pin-egress multi-route leaf extends that downstream
contract without adding new source syntax:
`isf/atl_resolved_child_pin_egress_multi_pipeline.isf` proves multiple one-bit
outputs from one resolved child to multiple one-bit top-level output pins
through the generated top. The same regression proves strict schedule JSON
parity, parent/child/top `.fsm` artifacts, two
`scalar_actor_to_pin_handoff` `data_movements[]` entries, generated child
output role preservation for both routed scalar signals, generated-top wiring
for both pin-egress handoffs, strict outdir materialization, plain plus strict
CLI HDL generation, and fail-closed missing-output, interleaved-drive-call,
and duplicate-output-pin diagnostics for that route set.

The same focused regression also covers `isf/atl_two_child_pipeline.isf`:
parent/reader/writer/top `.fsm` artifacts, strict schedule JSON parity,
nested generated-top `children[]` metadata, generated-top wiring, and plain
plus strict CLI HDL generation for the data-free two-child trigger/event
subset.

The same focused regression now also covers
`isf/atl_two_child_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, `scalar_actor_handoff`
`data_movements[]` metadata, nested generated-top `children[]` metadata,
reader output and writer input `+interface` preservation, generated-top
payload wiring, plain plus strict CLI HDL generation, missing sink payload
diagnostics, and wrong-order diagnostics for the selected two-child scalar
data route.

The same focused regression now also covers
`isf/atl_two_child_vector_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, strict outdir materialization,
8-bit parent source/sink handoff ports, 8-bit generated child payload ports,
generated-top wiring, plain plus strict CLI HDL generation, and
`vector_actor_handoff` `data_movements[]` metadata with
`width_source: "resolved_child_endpoint_exact_width"` for the selected
same-width two-child vector data route.

The same focused regression now also covers
`isf/atl_two_child_multi_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, two `scalar_actor_handoff`
`data_movements[]` entries for the same reader-to-writer route segment,
generated child `+interface` preservation for both routed scalar signals,
generated-top wiring for both route handoffs, strict outdir materialization,
and plain plus strict CLI HDL generation.

Recommended downstream smoke commands:

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --strict --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --emit-schedule-json isf/burst_reader.isf
./bin/fsmgen --strict --emit-schedule-json isf/uart_tx.isf
./bin/fsmgen --strict --emit-schedule-json isf/phase_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/switch_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/when_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/spawn_parent.isf
./bin/fsmgen --strict --emit-schedule-json isf/rule_resource_arbiter.isf
./bin/fsmgen --strict --emit-schedule-json isf/stream_stage_contract.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_controller.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_data_path.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_library_use.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_data_route_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_pin_ingress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_pin_egress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_multi_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_vector_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_data_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_vector_data_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_multi_data_pipeline.isf
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
./bin/fsmgen --strict --outdir /tmp/isf-fifo-library isf/fifo_library_use.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child isf/atl_resolved_child_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress isf/atl_resolved_child_pin_ingress_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-vector isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-vector-multi isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-mixed isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-multi isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress isf/atl_resolved_child_pin_egress_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-vector isf/atl_resolved_child_pin_egress_vector_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-vector-multi isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-mixed isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-data isf/atl_two_child_data_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-vector-data isf/atl_two_child_vector_data_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-multi-data isf/atl_two_child_multi_data_pipeline.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_event_crossing.isf
./bin/fsmgen --outdir /tmp/isf-cdc isf/clock_domain_dual_event_crossing.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_no_reset_event_crossing.isf
./bin/fsmgen --capability-manifest
```

Recommended FSMGen regression commands for integration contract changes:

```bash
prove -Iperl t/1112-isf-public-interface-contract.t \
  t/1115-isf-public-interface-cli-manifest-audit.t \
  t/1120-isf-public-live-document-path-audit.t \
  t/1144-isf-public-tested-by-metadata-audit.t \
  t/1255-isf-schedule-report-golden-matrix.t \
  t/1257-isf-scalar-type-aliases.t \
  t/1258-isf-enum-member-constants.t \
  t/1259-isf-aggregate-storage-type-aliases.t \
  t/1260-isf-aggregate-storage-leaf-reads.t \
  t/1261-isf-aggregate-storage-leaf-writes.t \
  t/1262-isf-aggregate-storage-leaf-expression-reads.t \
  t/1263-isf-enum-member-set-values.t \
  t/1264-isf-enum-member-set-expression-values.t \
  t/1265-isf-enum-member-switch-branch-values.t \
  t/1266-isf-enum-member-drive-values.t \
  t/1267-isf-enum-member-drive-call-values.t \
  t/1268-isf-enum-member-drive-call-expression-values.t \
  t/1269-isf-enum-member-actor-params.t \
  t/1270-isf-enum-member-transaction-params.t \
  t/1271-isf-enum-member-activation-params.t \
  t/1272-isf-enum-member-rule-values.t \
  t/1273-isf-enum-member-rule-expression-values.t \
  t/1274-isf-enum-member-rule-guard-values.t \
  t/1275-isf-enum-member-condition-values.t \
  t/1276-isf-enum-member-activation-aggregate-params.t \
  t/1277-isf-enum-member-actor-aggregate-params.t \
  t/1278-isf-enum-member-transaction-aggregate-params.t \
  t/1279-isf-enum-member-inline-drive-values.t \
  t/1280-isf-enum-member-inline-drive-expression-values.t \
  t/1281-isf-enum-member-library-use-params.t \
  t/1282-isf-enum-member-drive-expression-values.t \
  t/1283-isf-aggregate-rule-values.t \
  t/1284-isf-aggregate-rule-expression-values.t \
  t/1285-isf-aggregate-rule-guard-values.t \
  t/1286-isf-aggregate-condition-values.t \
  t/1287-isf-aggregate-drive-values.t \
  t/1288-isf-aggregate-drive-expression-values.t \
  t/1289-isf-aggregate-drive-call-values.t \
  t/1290-isf-aggregate-drive-call-expression-values.t \
  t/1291-isf-aggregate-inline-drive-values.t \
  t/1292-isf-aggregate-inline-drive-expression-values.t \
  t/1293-isf-aggregate-switch-branch-values.t \
  t/1294-isf-aggregate-switch-selector-values.t \
  t/1295-isf-enum-member-switch-selector-values.t \
  t/1296-isf-aggregate-rule-target-values.t \
  t/1297-isf-aggregate-drive-target-values.t \
  t/1298-isf-aggregate-inline-drive-target-values.t \
  t/1299-isf-aggregate-standalone-condition-values.t \
  t/1300-isf-enum-member-standalone-condition-values.t \
  t/1301-isf-enum-member-rule-standalone-guard-values.t \
  t/1302-isf-aggregate-rule-standalone-guard-values.t \
  t/1331-isf-timing-conventions.t \
  t/1333-isf-interface-actor-param-widths.t \
  t/1334-isf-scalar-storage-actor-param-widths.t \
  t/1335-isf-bank-storage-actor-param-widths.t \
  t/1336-isf-transaction-port-actor-param-widths.t \
  t/1337-isf-bank-storage-actor-param-depths.t \
  t/1338-isf-interface-actor-constant-widths.t \
  t/1353-isf-interface-package-constant-widths.t \
  t/1339-isf-scalar-storage-actor-constant-widths.t \
  t/1354-isf-scalar-storage-package-constant-widths.t \
  t/1340-isf-bank-storage-actor-constant-widths.t \
  t/1355-isf-bank-storage-package-constant-widths.t \
  t/1341-isf-bank-storage-actor-constant-depths.t \
  t/1356-isf-bank-storage-package-constant-depths.t \
  t/1342-isf-transaction-port-actor-constant-widths.t \
  t/1343-isf-data-op-static-width-sources.t \
  t/1344-isf-assemble-static-part-widths.t \
  t/1345-isf-actor-param-actor-constants.t \
  t/1346-isf-actor-param-actor-params.t \
  t/1347-isf-transaction-param-actor-static-defaults.t \
  t/1348-isf-transaction-param-transaction-params.t \
  t/1349-isf-actor-param-package-constants.t \
  t/1350-isf-transaction-param-package-constants.t \
  t/1351-isf-activation-param-package-constants.t \
  t/1352-isf-library-use-package-constants.t \
  t/1357-isf-transaction-port-package-constant-widths.t \
  t/1358-isf-data-op-package-constant-widths.t \
  t/1359-isf-wait-package-constant-counts.t \
  t/1360-isf-repeat-package-constant-counts.t \
  t/1367-isf-data-op-transaction-param-widths.t \
  t/1369-isf-timing-param-activation-override-gates.t

./bin/ci-regression isf
mdbook build docs/book
```

## 17. Machine-Readable Discovery

The machine-readable public contract is available through:

```bash
./bin/fsmgen --capability-manifest
```

Read:

```text
embedding.isf_public_interface
```

That object advertises:

- `schema_version`
- `status`
- public entrypoints
- CLI option names
- parser and scheduler method names
- constructor option names
- lower-result shape
- schedule-report top-level key list
- schedule-report key/value families
- resource catalog values
- library catalog metadata
- live document paths
- tested-by provenance
- downstream guidance

This document is the human integration contract. The manifest is the exact
JSON-safe discovery object for automated checks. If they disagree, treat that
as a documentation bug and update them in the same slice.

## 18. Deferred Or Non-Public Surface

The following are not public shipped integration surfaces today:

- Full raw parser actor hash as a stable API.
- Full `LoweringIR` as a stable API.
- Full schedule JSON schema beyond the advertised key families.
- Textual include semantics for libraries.
- Standalone transaction or drive library exports.
- Broader interface, transaction-port, storage width, or bank-depth
  expressions beyond actor-local scalar parameter defaults and the shipped
  qualified package-scalar-constant actor interface width and actor-owned
  scalar storage width, actor-owned bank storage width, and actor-owned bank
  storage depth subsets.
- Derived parameter expressions and package/imported constants outside the
  shipped qualified actor parameter, generated-child transaction parameter
  default, generated activation override, reusable-library use-site override,
  actor interface width, actor-owned scalar storage width, actor-owned bank
  storage width, and actor-owned bank storage depth scalar-constant subsets.
- General memory-array HDL emission for actor-owned banks.
- Arbitrary CDC, payload CDC, reset CDC, level sampling across domains, or
  FIFO-like cross-domain storage.
- Direct cross-domain reads/writes/triggers/activations/bindings.
- Direct/local rule-trigger output bindings.
- Direct `(on ...)` activation parameter overrides.
- Snapshot-vs-live binding timing selection beyond the shipped binding timing.
- Proof that every dynamic division/modulo divisor is nonzero. Literal-zero,
  actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisors are rejected, but arbitrary runtime
  scalar nonzero proof and use-site-specialized parameter divisor proof are
  not public shipped surfaces yet.
- A formal frozen EBNF grammar artifact or JSON Schema artifact. This document
  and the manifest are the current integration contract; a machine grammar or
  schema should be produced by a future task if required.

## 19. Integration Guidance

For a downstream producer:

- Emit only the source forms listed in this document.
- If FSMGen behavior looks wrong, follow the strict, format-agnostic
  reproduction bundle flow in
  [docs/DOWNSTREAM_ISSUE_REPORTING.md](DOWNSTREAM_ISSUE_REPORTING.md). Do not
  guess whether the root cause is source syntax, lowering, reporting, HDL, or
  public API behavior; provide the exact FSMGen-facing artifacts and command
  transcript.
- Prefer explicit scalar names and explicit widths.
- Use transaction ports and `(bind ...)` for runtime-varying data.
- Use `(params ...)` only for static specialization on generated activation
  forms that explicitly support it.
- Use actor constants or actor-local scalar parameter defaults for static
  generated activation parameter override values.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static latency bound symbols.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static temporal-contract window
  symbols.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static actor-level watchdog limits.
- Use actor constants, actor-local scalar parameter defaults,
  same-transaction scalar parameter defaults, or qualified imported package
  scalar constants for static top-level await-local watchdog limits.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static wait-count symbols.
- Treat every fail-closed diagnostic as a source-generation bug.
- Use `--emit-schedule-json` in tests to confirm schedule/report shape.
- Use `--check --json` or `--check-json` when a downstream workflow needs a
  machine-readable pass/fail result. For `.isf` inputs, parser, lowering,
  schedule-report, and downstream semantic check failures exit nonzero while
  still emitting `success: false` JSON to stdout with the diagnostic message in
  `diagnostics[0].message`.
- Use generated `.fsm` as the human review artifact before HDL.
- Use `--capability-manifest` to check the current bounded public contract.

For a downstream analyzer:

- Consume schedule JSON key families listed here.
- Preserve unknown keys for forward compatibility.
- Do not depend on raw Perl object internals.
- Do not infer support from parser-carried private clause payloads.
- Treat `compile_issues[]` as nonfatal warnings on successful reports.
- Treat missing artifacts or diagnostics as integration failures, not partial
  success. Empty stdout from `--check --json` for an existing `.isf` input is
  a reportable FSMGen bug, not an expected downstream contract.

## 20. Source Of Truth And Evolution

This file is the canonical human downstream integration document for `.isf`
and the IAL2-to-IAL1 lowering stack used by `.ppif`. It is intentionally
duplicated into the mdBook by include, not by a second copy. It must always
remain synchronized with the live docs, the book, the machine-readable public
contracts, manifest metadata, support-accounting catalog, and shipped
implementation.

Supporting artifacts:

- `docs/ISF_SPEC.md`: detailed live language and lowering specification.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict issue-reporting protocol for
  locally reproducible downstream bug reports.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live public facade/report contract.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm`: machine-readable contract
  owner advertised through the capability manifest.
- `docs/ISF_LIBRARY_CATALOG.md`: shipped reusable library catalog.
- `docs/book/src/13-intent-scheduling.md` and child chapters, especially
  `docs/book/src/13j-type-enum-aggregate.md` and
  `docs/book/src/13k-isf-feature-support-matrix.md`: tutorial, explanatory,
  and book-facing shipped-feature support documentation. The machine-readable
  ISF public contract advertises every Intent Scheduling chapter listed in
  `docs/book/src/SUMMARY.md`, plus the canonical feature backlog and reference
  map, through `live_document_paths`.
- `t/`: regression and audit evidence.

Evolution rule:

Any future change to public ISF syntax, PPIF lowering contract, parser facade
behavior, scheduler facade behavior, lower-result shape, schedule-report shape,
diagnostics, or downstream guidance must update this file in the same commit
as the behavior change.

Minimum same-slice update set for downstream-visible ISF or PPIF behavior
changes:

- source/parser/lowering/report/emitter code that implements the behavior;
- focused regression coverage;
- `docs/ISF_SPEC.md`;
- this file;
- the relevant mdBook chapter or included book page;
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `perl/FSM/Support/LanguageSurfaceSection.pm` when shipped suffix/layer/CLI or
  per-suffix boundary metadata changes;
- support-accounting catalog/docs when supported sample or fixture coverage
  changes;
- `perl/FSM/Support/ISFPublicInterfaceContract.pm` when public facade, report,
  manifest, live-doc, or tested-by metadata changes;
- `docs/ISF_LIBRARY_CATALOG.md` when reusable library semantics change;
- owning task tree and live recovery docs.
