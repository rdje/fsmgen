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
- Actor constants, scalar actor parameter defaults, and generated child
  transaction scalar parameter defaults use non-negative integer literals or
  enum member references that resolve to non-negative integers; static wait
  counts use non-negative integer literals or actor constants.
- Numeric and exact-width integer literals are accepted where this document
  says scalar numeric literals are accepted.
- Runtime expression positions may use scalar tokens, numeric/exact-width
  literals, or non-empty list expressions. List expressions use the same
  Lisp-like operator-first shape consumed by the scheduled `.fsm` expression
  formatter.
- Runtime division and modulo expressions fail closed before scheduled `.fsm`
  emission when any divisor operand is a numeric/exact-width literal zero or
  an actor-level constant that resolves to zero, including nested expression
  operands. Nonzero literal divisors, nonzero actor-constant divisors, and
  dynamic scalar divisors remain accepted; FSMGen does not yet prove arbitrary
  dynamic divisors nonzero.
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
- Constants may be used as static `(wait NAME)` counts and existing static
  activation parameter override values.
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
- Actor parameter scalar defaults and scalar leaves inside actor aggregate/list
  parameter defaults may use local or package-qualified enum member references.
  Generated child transaction scalar parameter defaults and scalar leaves
  inside generated child transaction aggregate/list parameter defaults may also
  use local or package-qualified enum member references. Scalar activation
  parameter overrides and scalar leaves inside activation aggregate/list
  parameter override values may also use local or package-qualified enum member
  references on generated activation sites. Reusable-library use-site parameter
  overrides may also use local or package-qualified enum members as scalar
  values or scalar leaves inside compatible aggregate/list override values.
  Duplicate overrides, unknown overrides, and shape mismatches fail closed.
- Schedule reports expose actor parameter defaults through `actor_params[]`
  entries with `name` and JSON-safe default `value`, preserving authored enum
  tokens. These are static specialization defaults, not runtime payloads.
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
- Wait-count division and modulo expressions reject literal-zero and
  actor-constant-zero divisors before scheduled `.fsm` emission. Dynamic
  divisor nonzero proof remains outside the shipped wait contract.
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
- The shipped repeat-body clause surface is named drive calls, `await`,
  `sample`, `update`, `set`, `shift_left`, `shift_right`, `assemble`,
  `extract`, actor-owned bank `store` and `load`, and shipped `wait` clauses.
  `do`, `spawn`, `await_all`, `await_any`, `stage`, `contract`, nested
  `while`, and nested `until` remain outside the shipped repeat-body subset.
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
- `assemble` can infer exactly one missing part width from a known target
  width and known sibling part widths. Two or more unknown parts still lower
  only as non-evidence concat operands; non-positive inferred remainders fail
  closed.
- `extract` emits concrete slices, not placeholder bounds. It can infer
  exactly one missing destination field width from a known source word width
  and known sibling field widths; two or more unknown fields, non-positive
  inferred remainders, and known source/field total mismatches fail closed.

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
  actor-local constants, scalar local or package-qualified enum members, or
  compatible aggregate/list literals whose scalar leaves are literals or
  actor-local constants or local/package-qualified enum members.
- Transaction-local scalar parameter defaults may use local or
  package-qualified enum members; generated child `.fsm` `+params` and
  generated-composition schedule reports preserve the authored enum token.
- Actor constants and scalar enum members resolve to literal values before
  generated-top emission, including scalar enum leaves inside activation
  aggregate/list override values.
- Reusable-library use-site enum member overrides resolve to literal values
  before generated-top emission and before `library_uses[]` report
  publication. Use-site overrides do not accept actor constants yet.
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
- Actor constants may consume local enum members such as `mode.BUSY` and
  package enum members such as `shared.mode.BUSY`. Unknown enum families or
  members fail closed before generated artifacts are emitted.
- Direct transaction `(set target enum_member)` RHS scalar values may also
  consume local or package enum members, transaction `set` RHS expressions may
  use enum members as scalar operands, transaction `when`/`while`/`until`
  condition expressions may use enum members as scalar operands, direct
  transaction `when`/`while`/`until` scalar conditions may consume local or
  package enum members, transaction `switch` selectors or branch values may
  consume local or package enum members, and scalar drive body RHS values or operands inside drive body RHS expressions may
  consume local or package enum members. Named drive-call scalar actual values
  may also consume local or package enum members, drive-call actual expressions
  may use enum members as scalar
  operands, scalar actor parameter defaults and scalar leaves inside actor
  aggregate/list parameter defaults may consume local or package enum members,
  generated child transaction scalar parameter defaults and scalar leaves
  inside generated child transaction aggregate/list parameter defaults may
  consume local or package enum members, scalar activation parameter overrides
  may consume local or package enum members, scalar leaves inside activation
  aggregate/list parameter override values may consume local or package enum
  members, reusable-library use-site parameter override values or leaves may
  consume local or package enum members, and scalar rule assignment RHS values
  or expression operands may consume local or package enum members. Rule guard
  scalar values or expression operands may consume local or package enum
  members, and inline drive assignment RHS scalar values or operands inside
  inline drive RHS expressions may consume local or package enum members. Enum
  members in expression operator position, targets, rules outside scalar
  trigger parameter overrides, rule guard or transaction
  condition expression operator position, rule assignment expression operator
  position, drive targets, drive body RHS expression operator position, inline
  drive assignment RHS expression operator position, drive-call expression
  operator position, and
  other contexts remain deferred.

Aggregate member/item access outside direct transaction `set` RHS values,
direct transaction `set` target tokens, transaction condition scalar values or
expression operands, transaction `switch` selectors or branch values, rule
assignment target tokens, rule assignment RHS values or expression operands,
rule guard scalar values or expression operands, drive target tokens, drive body RHS scalar
values/expression operands, inline drive target tokens, inline drive
assignment RHS scalar values/expression operands, or drive-call actual scalar
values/expression operands; aggregate paths in drive body RHS, inline drive RHS, or drive-call
actual expression operator position; subaggregate
operands/updates;
aggregate interface or transaction ports; and aggregate storage banks are not
shipped yet. Existing
aggregate support beyond the actor-owned storage-variable carrier and direct
scalar leaf read/write context is limited to compatible aggregate/list literal
parameter values and scalarized actor-owned bank/storage lowering.

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
inferred_storage[] optional: role, type, type_kind, width
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
- Rule-trigger output bindings.
- Literal-zero and actor-constant-zero divisor operands in shipped runtime
  division/modulo expression contexts.
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
  selectors or branch values, rule assignment target tokens, rule assignment RHS
  values/expression operands, rule guard scalar values/expression operands, drive target
  tokens, drive body RHS scalar values/expression operands, inline drive
  target tokens, inline drive assignment RHS scalar values/expression operands,
  or drive-call actual scalar values/expression operands, aggregate paths in
  expression operator position,
  subaggregate
  operands/updates, and
  enum member references outside
  the shipped actor-constant, actor parameter scalar default or aggregate/list
  default leaf, generated child transaction scalar parameter default or
  aggregate/list default leaf, scalar activation parameter override,
  activation aggregate/list override leaf, reusable-library use-site parameter
  override value or leaf, transaction condition scalar value or expression
  operand, transaction `set` RHS scalar/expression operand, transaction
  `switch` selector/branch-value, rule guard scalar/expression operand, rule
  assignment RHS scalar/expression operand, drive body RHS scalar/expression
  operand, inline drive RHS scalar/expression operand, and drive-call actual
  scalar/expression-operand contexts.
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

The SPI-like fixture and I2C-like fixture are bounded realistic examples, not
complete external protocol compliance suites. SPI is covered by
`t/1228-isf-spi-fixture-coverage.t`. I2C is covered by
`t/1309-isf-i2c-fixture-coverage.t`, which proves strict schedule JSON parity,
scheduled `.fsm` structure, plain and strict HDL generation, switch-branch
repeats, read-data shifting, sampled write-data bit selection from `data[7]`,
and no implicit `data_bit` input.

Recommended downstream smoke commands:

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --strict --emit-schedule-json isf/i2c_master.isf
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
  t/1302-isf-aggregate-rule-standalone-guard-values.t

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
- Proof that every dynamic division/modulo divisor is nonzero. Literal-zero
  and actor-constant-zero divisors are rejected, but arbitrary runtime scalar
  nonzero proof is not a public shipped surface yet.
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
- `docs/book/src/13-intent-scheduling.md` and child chapters, especially
  `docs/book/src/13j-type-enum-aggregate.md` and
  `docs/book/src/13k-isf-feature-support-matrix.md`: tutorial, explanatory,
  and book-facing shipped-feature support documentation. The machine-readable
  ISF public contract advertises every Intent Scheduling chapter listed in
  `docs/book/src/SUMMARY.md`, plus the canonical feature backlog and reference
  map, through `live_document_paths`.
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
