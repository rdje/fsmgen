# ISF Downstream Integration Specification

Status: `bounded_public`
Document version: `2026-05-16`
ISF source specification: `.isf` specification v0.6
Primary audience: SPECFORGE and other tools that emit, validate, inspect, or
consume FSMGen Intent Scheduling Format sources and reports.

This is the single downstream-facing integration contract for the current
`.isf` surface. A consumer should be able to implement against this document
without reading the mdBook, Perl modules, task trees, or tests first. Those
artifacts remain the implementation evidence and evolution history; this file
packages the current public contract in one place.

Synchronization invariant: this document must stay truthful with respect to
the live `.isf` spec, the mdBook, the public contract, the manifest metadata,
the regression tests, and the codebase itself. A mismatch between this file and
implementation behavior is a project bug. Do not update this file as an
aspirational design note; update it only with the same slice that changes the
source language, diagnostics, lowering behavior, public facade, schedule JSON,
generated artifacts, fixtures, or documented deferrals.

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
  clock/reset HDL contract.
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
- Future `.isf` changes must update this document, the public contract, tests,
  and book content in the same implementation slice.

## 2. Integration Pipeline

The current semantic pipeline is:

```text
SPECFORGE IntentIR
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
- No higher layer is currently shipped. Protocol-level intent objects above
  individual transactions are future work.

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
  otherwise.
- Actor constants and static wait counts use non-negative integer literals.
- Numeric and exact-width integer literals are accepted where this document
  says scalar numeric literals are accepted.
- Runtime expression positions may use scalar tokens, numeric/exact-width
  literals, or non-empty list expressions. List expressions use the same
  Lisp-like operator-first shape consumed by the scheduled `.fsm` expression
  formatter.
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
(watchdog positive_integer)
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
(clock clk)
(reset rst_n)
(reset (rst_n async active_low))
(watchdog 65536)
```

Rules:

- `(clock name)` names the actor clock for legacy single-domain actors.
- `(reset name)` defaults to synchronous reset.
- Reset names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List reset form may include `sync`, `async`, `active_low`, or `active_high`.
- Async reset lowers to `.fsm` `areset`; sync reset lowers to `.fsm` `sreset`.
- `(watchdog N)` is the actor default for `(await ...)`; per-await watchdog
  overrides are supported with `(await port (watchdog M))`.

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
  targets when each domain artifact satisfies the scheduled `.fsm` clock/reset
  HDL contract.

## 8. Interface, Storage, Constants

Interface:

```lisp
(interface
  (input  name)
  (input  name (width N))
  (output name)
  (output name (width N)))
```

Rules:

- Width defaults to `1`.
- Directions are `input` or `output`.
- Port names are unique across both directions.
- `(domain NAME)` is accepted on interface entries when named domains are in
  use.
- Malformed directions, duplicate names, nested names, and non-positive widths
  fail closed.

Constants:

```lisp
(constants
  (WAIT_ZERO 0)
  (WAIT_TWO 2)
  (WAIT_ONE 4'd1))
```

Rules:

- Constants are actor-scoped and compile-time only.
- Names are unique HDL identifiers.
- Values are non-negative integer literals.
- Constants are emitted into scheduled `.fsm` `+constants`.
- Constants may be used as static `(wait NAME)` counts.
- Actor or transaction `params` are not wait constants.

Actor-owned storage:

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width 2))
  (bank data (width 8) (depth 4)))
```

Rules:

- `(var ...)` and `(variable ...)` declare fixed-width actor-owned scalar
  state.
- `(bank ...)` declares a fixed-depth actor-owned storage bank.
- Widths and depths are positive integer literals.
- Storage names must not collide with interface ports, clock/reset names, or
  generated scheduler names.
- Banks lower to deterministic scalar storage entries such as `data_0`,
  `data_1`, `data_2`, and `data_3`.
- Schedule reports expose declared storage through `inferred_storage`.

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
- Unknown overrides, duplicate overrides, symbolic parameter values, and shape
  mismatches fail closed for reusable-library `use` sites.
- Schedule reports expose actor parameter defaults through `actor_params[]`
  entries with `name` and JSON-safe default `value`. These are static
  specialization defaults, not runtime payloads.
- Every exported actor clock/reset/interface endpoint must be explicitly bound
  at the use site.
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
- No parameter-driven interface/storage elaboration yet.
- No memory-array backend emission yet.
- No automatic non-zero reset values yet.
- No standalone transaction or drive exports yet.
- No nested library imports from library actors yet.

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
(repeat count body...)
(switch selector branch...)
(set target expr)
(update target expr)
(store bank index value)
(load bank index as target)
(shift_left reg bit)
(shift_right reg bit)
(shift_right reg bit (width N))
(assemble part... as target)
(extract word as field...)
(extract word as field... (widths N...))
(do transaction [(params ...)] [(bind ...)])
(spawn transaction as instance [(params ...)] [(bind ...)] [(domain NAME)])
(await_all done_port)
(await_any done_port)
(complete port)
(latency (min N) (max M))
(stage ...)
(contract ...)
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
  not accept activation-site parameter overrides.

### 11.2 Transaction Ports And Bindings

Transaction ports:

```lisp
(ports
  (input addr (width 8))
  (output data (width 8)))
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
- Width defaults to `1`.
- Port names are unique across directions.
- Input bindings may pass scalar signals, numeric/exact-width literals, or
  non-empty list expressions.
- Output bindings name scalar writable actor-side targets.
- `do` and `spawn` support input and output bindings.
- Rule `trigger` supports input bindings only because a rule does not wait for
  transaction completion.
- Width mismatches fail closed when width evidence is known.
- Reports expose `transaction_port_bindings[]`.

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
```

Await waits for a port and uses the actor watchdog unless overridden.

Wait:

```lisp
(wait 3)
(wait WAIT_TWO)
(wait count_signal)
(wait (+ count_a count_b))
```

Rules:

- Static literal/constant waits are accepted, including zero.
- Runtime scalar waits are accepted when the count source has known positive
  width and the predecessor-edge split is implemented.
- Runtime expression waits are accepted when every operand has known width and
  the expression width helper derives a positive result width.
- Transaction `params` are not wait-count constants.
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
- Unsupported nested clauses fail closed.
- Runtime waits inside supported inline contexts are shipped for the covered
  predecessor and pending-sample cases.
- Reports expose loop metadata through `transaction_loops[]`.

### 11.5 Data Manipulation

Supported forms:

```lisp
(set target expr)
(update target expr)
(shift_left reg bit)
(shift_right reg bit)
(shift_right reg bit (width N))
(assemble part... as target)
(extract word as field...)
(extract word as field... (widths N...))
```

Rules:

- `set` is the scalar setter shared by rules and transactions.
- `update` is the older transaction-local assignment spelling.
- Shift/extract/assemble forms use known width evidence and fail closed on
  contradictory or missing width evidence where exact lowering requires it.
- `extract` emits concrete slices, not placeholder bounds.

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
  actor-local constants, or compatible aggregate/list literals whose scalar
  leaves are literals or actor-local constants.
- Actor constants resolve to literal values before generated-top emission.
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

Current shipped ISF accepts the first scalar type-alias subset:

```lisp
(types
  (type byte (bits 8))
  (type flag bit))

(imports
  (package shared))

(interface
  (input data_in (type byte))
  (output data_out (type shared.byte)))

(storage
  (var accum (type byte)))

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
- `(type NAME)` and `(width N)` are mutually exclusive.
- `NAME` may be local (`byte`) or package-qualified (`shared.byte`).
- Lowered scheduled `.fsm` preserves review artifacts with `+types`,
  `+import`, typed `+size` entries, and embedded imported package roots so CLI
  HDL generation remains self-contained.
- Unknown aliases and aliases that resolve to aggregate `list` or `record`
  types fail closed in this scalar-only slice.
- Actor-local `(enums ...)` declarations are preserved into scheduled `.fsm`
  as `+enums`, but no ISF expression or value context consumes enum members
  yet.

Typed aggregate carrier/update semantics are not shipped yet. Existing
aggregate support beyond declaration artifacts is limited to compatible
aggregate/list literal parameter values and scalarized actor-owned bank/storage
lowering.

### 11.7 Blocking Do, Spawn, Await Sync

Blocking `do`:

```lisp
(do child)
(do child (params ...) (bind ...))
```

Rules:

- Local unparameterized `do` rewires the child entry to `child_start` and waits
  for `child_done`.
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

### 11.8 Stages, Contracts, Latency

Stage:

```lisp
(stage phase_name
  (ready ready_signal)
  (valid valid_signal))
```

Current shipped stage kind is `ready_valid_barrier`.

Temporal contract:

```lisp
(contract name
  (eventually signal within N))
```

Current shipped temporal contract kind is `bounded_eventually`. Reports expose
contract monitor metadata. Assertion projection is currently
`systemverilog_sticky_fail`: SystemVerilog HDL generation emits a
verification-only assertion from the generated sticky fail bit under
`` `ifndef SYNTHESIS``. Verilog output remains assertion-free.

Latency:

```lisp
(latency (min N) (max M))
```

Rules:

- `min` and `max` are positive integers.
- Duplicate options and `min > max` fail closed.
- Latency metadata lowers to counters/error checks where supported and reports
  through `dt_blocks[]`.

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
- Rule triggers emit one-cycle delayed per-rule trigger sources.
- Multiple rules triggering the same local transaction lower through a
  deterministic trigger fan-in DT unless the target is generated.
- Parameterized triggers use generated child activation instances.
- Rule-trigger output bindings remain rejected.

Resource arbitration:

```lisp
(resources
  (resource rule_slot
    (kind exclusive)
    (arbiter priority)
    (users rule_a rule_b)))
```

Rules:

- Current enforced resource kind is `rule_slot` with `priority` arbitration.
- Reports expose `resource_arbitration[]`.
- Additional resource kinds may be cataloged as backlog but are not enforced
  unless listed as enforced by the public contract.

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
transaction_stages
temporal_contracts
bank_accesses
transaction_port_bindings
dt_blocks
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
parse. SPECFORGE-style consumers should use explicit bounded fields such as
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
  `generated_composition`, `library_uses[]`, and `clock_domains[]` /
  `crossings[]`.
- SPECFORGE-style integrations should report bugs with the runnable source,
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
- `clock`: actor/default-domain clock name.
- `reset`: null or object with `name`, `kind`, and `polarity`.
- `watchdog`: null or scalar watchdog limit.
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
actor_params[]: name, value
inferred_storage[] required: name, kind
inferred_storage[] optional: role, width
transactions[]: name, states, count
transaction_waits[]: transaction, cycles, count_kind, count_source,
  entry_state, exit_state, counter_signal, counter_width
transaction_loops[]: transaction, kind, condition, entry_state,
  decision_states, body_start, body_states, exit_state, body_clause_count
transaction_stages[]: transaction, name, kind, state, ready, valid
temporal_contracts[]: transaction, name, kind, trigger, signal,
  within_cycles, pending_signal, counter_signal, fail_signal,
  overlap_policy, reset_policy, assertion_projection
bank_accesses[]: kind, owner, owner_kind, container_kind, container_name,
  bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings[]: site_kind, owner, owner_kind, target_transaction,
  role, port, actor_signal, actor_expression, width, instance, parent_port,
  child_port, start_signal, done_signal, trigger_source, payload_source
dt_blocks[]: name, kind, assignments
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
generated_composition.kind: activation_generated_top, spawn_generated_top
inferred_storage.kind: counter, register
inferred_storage.role: activation_done_handoff, activation_start_handoff,
  actor_storage, completion_pulse, data_register, dynamic_wait_counter,
  drive_payload, drive_request, extract_field, latency_counter,
  repeat_counter, rule_trigger_payload_source, rule_trigger_source,
  sample_alias, temporal_contract_monitor, transaction_port,
  transaction_port_binding, trigger_done_observe, watchdog_counter
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
- Rule-trigger output bindings.
- Direct cross-domain access without a shipped crossing primitive.
- Width mismatch where width evidence is known.
- Parameter override unknown names, duplicate names, symbolic values, and
  incompatible aggregate/list shapes.
- Unknown scalar type aliases, `(width ...)` plus `(type ...)` on the same
  declaration, package import aliases, and aggregate type aliases used in the
  scalar-only type subset.
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
isf/full_featured.isf
isf/clock_domain_event_crossing.isf
isf/clock_domain_dual_event_crossing.isf
isf/common/fifo.isf
isf/fifo_library_use.isf
```

Recommended downstream smoke commands:

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --outdir /tmp/isf-build isf/spawn_parent.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_event_crossing.isf
./bin/fsmgen --outdir /tmp/isf-cdc isf/clock_domain_dual_event_crossing.isf
./bin/fsmgen --capability-manifest
```

Recommended FSMGen regression commands for integration contract changes:

```bash
prove -Iperl t/1112-isf-public-interface-contract.t \
  t/1115-isf-public-interface-cli-manifest-audit.t \
  t/1120-isf-public-live-document-path-audit.t \
  t/1144-isf-public-tested-by-metadata-audit.t \
  t/1255-isf-schedule-report-golden-matrix.t \
  t/1257-isf-scalar-type-aliases.t

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
- Parameter-driven interface widths or storage dimensions.
- Derived parameter expressions and package/imported constants beyond current
  actor-local constants.
- General memory-array HDL emission for actor-owned banks.
- Arbitrary CDC, payload CDC, reset CDC, level sampling across domains, or
  FIFO-like cross-domain storage.
- Direct cross-domain reads/writes/triggers/activations/bindings.
- Rule-trigger output bindings.
- Direct `(on ...)` activation parameter overrides.
- Snapshot-vs-live binding timing selection beyond the shipped binding timing.
- A formal frozen EBNF grammar artifact or JSON Schema artifact. This document
  and the manifest are the current integration contract; a machine grammar or
  schema should be produced by a future task if required.

## 19. Integration Guidance

For a SPECFORGE-style producer:

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
- Use actor constants for static wait-count symbols.
- Treat every fail-closed diagnostic as a source-generation bug.
- Use `--emit-schedule-json` in tests to confirm schedule/report shape.
- Use generated `.fsm` as the human review artifact before HDL.
- Use `--capability-manifest` to check the current bounded public contract.

For a downstream analyzer:

- Consume schedule JSON key families listed here.
- Preserve unknown keys for forward compatibility.
- Do not depend on raw Perl object internals.
- Do not infer support from parser-carried private clause payloads.
- Treat `compile_issues[]` as nonfatal warnings on successful reports.
- Treat missing artifacts or diagnostics as integration failures, not partial
  success.

## 20. Source Of Truth And Evolution

This file is the canonical human downstream integration document for `.isf`.
It is intentionally duplicated into the mdBook by include, not by a second copy.
It must always remain synchronized with the live docs, the book, the
machine-readable public contract, and the shipped implementation.

Supporting artifacts:

- `docs/ISF_SPEC.md`: detailed live language and lowering specification.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict issue-reporting protocol for
  locally reproducible downstream bug reports.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live public facade/report contract.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm`: machine-readable contract
  owner advertised through the capability manifest.
- `docs/ISF_LIBRARY_CATALOG.md`: shipped reusable library catalog.
- `docs/book/src/13-intent-scheduling.md` and child chapters: tutorial and
  explanatory user documentation.
- `t/`: regression and audit evidence.

Evolution rule:

Any future change to public ISF syntax, parser facade behavior, scheduler
facade behavior, lower-result shape, schedule-report shape, diagnostics, or
downstream guidance must update this file in the same commit as the behavior
change.

Minimum same-slice update set for downstream-visible ISF behavior changes:

- source/parser/lowering/report/emitter code that implements the behavior;
- focused regression coverage;
- `docs/ISF_SPEC.md`;
- this file;
- the relevant mdBook chapter or included book page;
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `perl/FSM/Support/ISFPublicInterfaceContract.pm` when public facade, report,
  manifest, live-doc, or tested-by metadata changes;
- `docs/ISF_LIBRARY_CATALOG.md` when reusable library semantics change;
- owning task tree and live recovery docs.
