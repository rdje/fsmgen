# Intent Scheduling Format (`.isf`) — Specification v0.6

Source material:
- [docs/INTENT_SCHEDULING_BRAINSTORM.md](INTENT_SCHEDULING_BRAINSTORM.md)
- [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/book/src/13-intent-scheduling.md](book/src/13-intent-scheduling.md)
- [docs/book/src/13h-lowering-reference.md](book/src/13h-lowering-reference.md)

## 1. Purpose and Positioning

```text
SPECFORGE IntentIR -> .isf -> scheduled .fsm -> SystemVerilog / Verilog
```

`.isf` is a Lisp-ish hardware intent format above explicit cycle-authored
`.fsm`. Authors describe transactions, drives, waits, simple control flow, and
data movement. FSMGen lowers that intent into explicit scheduled `.fsm` text,
then uses the ordinary `.fsm` pipeline for HDL generation.

Cycles are not hidden. They are inferred into a generated `.fsm` artifact and a
schedule JSON report that can be reviewed.
ISF intentionally borrows familiar programming-language control-flow shape for
transaction authoring. Existing forms such as `when`, `repeat`, `wait`,
`while`, `until`, `do`, and spawned-child activation should still read
naturally to authors. That source shape does not change the hardware contract:
every shipped form must lower to explicit RTL intent with reviewable scheduled
`.fsm` states, decision points, counters, handshakes, or DTs.

## 1.1 Intent Abstraction Layers

FSMGen uses the following terminology when discussing intent levels:

- `.fsm` is **Intent Abstraction Layer 0** (`IAL0`). It is explicit
  cycle-authored hardware intent. It owns DT structure, assignment operators,
  state and non-state activation regions, mux-selection semantics, and exact
  runtime behavior. It is the semantic audit artifact produced before HDL.
- Current `.isf` is **Intent Abstraction Layer 1** (`IAL1`). It is scheduling
  intent above `.fsm`: transactions, rules, drives, samples, waits, repeats,
  transaction composition, spawned-child activation, and constraints lower into
  reviewable `IAL0` `.fsm`.

Additional layers are not assumed. A future `IAL2` should be introduced only
if it carries a real semantic level that is not merely nicer spelling for
existing ISF constructs. Plausible reasons include reusable protocol-level
intent objects, such as an authored APB read or AXI burst operation, or
platform/resource mapping decisions above individual transactions. Weak
reasons include aliases, macro wrappers, syntax sugar, or any form that lacks
a distinct runtime model. Every layer must preserve a clear lowering chain and
runtime semantics.

## 1.2 Construct Shipping Rule

An ISF construct is shipped only when its syntax, lowering, and runtime
semantics are all explicit. Parser acceptance alone is not support.

For every current or future construct, the public contract must answer:
- what source shape is accepted and what malformed shape fails closed;
- what scheduled `.fsm` artifact is emitted, or which targeted diagnostic is
  raised before emission;
- what the runtime behavior means in cycles, activation, storage, handshakes,
  conflicts, and completion;
- what schedule-report or review-artifact visibility downstream consumers can
  rely on; and
- what focused regression or fixture proves the behavior.

If one of those answers is not ready, the construct remains deferred, backlog,
or fail-closed compatibility input rather than a shipped ISF feature.
The downstream integration handoff in
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
must be updated in the same slice as any downstream-visible syntax,
diagnostic, lowering, public facade, schedule-report, generated-artifact, or
deferral change. A mismatch between that handoff, this spec, the mdBook, the
public contract, tests, or code is a bug.

## 2. CLI Contract

`bin/fsmgen` accepts `.isf` inputs anywhere it accepts a source path:

```bash
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
```

Current CLI behavior:
- `.isf` source lookup uses the same source resolver family as `.fsm` lookup.
- `--emit-schedule-json` emits the scheduler report and exits before HDL
  generation.
- Without `--emit-schedule-json`, a single generated `.fsm` file is written to a
  temporary file and fed into the normal `.fsm` pipeline.
- The plain single-clock `file.isf` path is expected to reach generated HDL
  with clean stderr on success. Accepted multi-domain event-crossing actors
  lower through generated domain/top artifacts and now reach generated
  SystemVerilog/Verilog-family HDL containing the generated top plus concrete
  acknowledged-event CDC child when each emitted domain artifact satisfies the
  current scheduled `.fsm` clock/reset HDL contract.
- `--strict` is accepted on the plain `file.isf` path and still routes through
  scheduled `.fsm` generation before HDL output.
- If lowering produces multiple `.fsm` files, `--outdir DIR` writes every file
  there and the parent actor file is fed into the normal pipeline.
- The public `--outdir` path is expected to write scheduled `.fsm` file content
  matching the in-process lower-result `files` map.

The live downstream-consumer API contract for these CLI surfaces, the
`FSM::Adapter::ISF` / `FSM::Scheduler::ISF` in-process facades, and the bounded
schedule-report key families is
[docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md). Its
machine-readable form is advertised through
`--capability-manifest -> embedding.isf_public_interface`. That contract must
evolve in the same slice as any implementation change that widens or changes
the public ISF surface; it is not a frozen API schema. Its identity/stability
metadata and
`public_top_level_presence_keys` list are audited as exact discovery data across
direct and manifest views. Its advertised entrypoint lists are also audited as
exact and duplicate-free across those views, and its ISF-specific CLI option
list is audited the same way. Its parser and scheduler method-name metadata is
also audited as exact and duplicate-free, as is its public constructor option
metadata. Its lower-result discovery metadata is audited as exact across direct
and manifest views too. Its schedule-report metadata fields and downstream
guidance list are audited as exact across the same views. Its `tested_by`
provenance metadata is also audited as an exact repo-local test list.
Its lower-result file sub-shape metadata is audited as exact for scheduled
`.fsm` basenames and scheduled text roots.
Its shareable-resource catalog metadata is audited as exact for current
arbiter names, resource kinds, shipped/backlog status, and meaning text.
Its schedule-report transaction-ordering metadata is audited as exact for the
lexically sorted transaction list and emitted-order per-transaction states.
Its CLI success-shape metadata is audited as exact for the schedule JSON,
`--outdir`, and plain HDL-generation paths.
Its strict CLI success-shape metadata is audited as exact for accepted
`--strict file.isf` HDL generation.
Its in-process facade return-shape metadata is audited as exact for
`parse_file(...)`, `parse_source(...)`, `lower(...)`, and `report(...)`.

The public adapter and scheduler constructors require the exact
`FSM::Adapter::ISF` or `FSM::Scheduler::ISF` class invocant and currently
accept only the `debug` option. Malformed invocants, option lists, and
unsupported option names are rejected before object creation.
The public parser and scheduler facade methods require object receivers returned
by their corresponding `new(...)` constructors before private internals are
used. The public parser facade methods also validate their argument shape:
`parse_file(...)` requires one defined scalar path naming a readable `.isf`
file, and `parse_source(...)` requires defined scalar source text and source
label values.
The public scheduler facade methods validate the actor shell before lowering:
`lower(...)` and `report(...)` require one actor hash with scalar `actor_name`,
array `transactions`, and hash `interface` fields.
The machine-readable contract publishes that required handoff shell as
`actor_shell_required_keys`; other raw actor fields are still private parser
output.
It also publishes the shell value shapes: scalar `actor_name`, array
`transactions`, and hash `interface`.
The current bounded parser handoff also advertises the `interface` subshape:
`inputs` and `outputs` are arrays, and each public port entry has unique
non-empty scalar `name` plus positive integer `width`, with omitted source
widths normalized to `1`.
It also advertises the transaction-entry shell: `transactions` is an array of
entries with scalar `name` and `clauses` array fields. Those shapes are
live-contract metadata for scheduler-consumable actors, not a freeze of the
full raw actor hash or the private transaction clause payloads.
The actor identity shape is also explicit: `actor_name` is a non-empty scalar
identifier preserved from the ISF actor root.
Current actor timing fields are explicit too: `clock` is a non-empty scalar
when configured, `reset` is null when omitted or a hash with scalar `name`,
`kind`, and `polarity`, and `watchdog` is null when omitted or a positive
integer.
Current rule entries are advertised as a bounded shell: `rules` is an array of
entries with scalar `name`, optional `when`, and `actions` array fields. Rule
condition/action payload contents remain private scheduler input.
Current actor-level drive definitions are advertised as a bounded shell:
`drives` is a hash keyed by drive name, and each entry has `params` and `body`
array fields. Body entries are parser-validated scalar `(port value)` pairs;
detailed drive semantics remain private scheduler input.
The same contract publishes the public return containers: parser facades return
scheduler-consumable actor hash references, `lower(...)` returns a hash
reference with the advertised lower-result keys, and `report(...)` returns the
schedule-report JSON string.
The contract's facade-shape metadata for these receiver, argument, path, and
actor-shell boundaries is audited as exact across direct and manifest views.
Public facade boundary failures are advertised as bounded scalar diagnostics
before object creation, private parsing, or private lowering/reporting begins.
For single-clock multi-file lowering, the current schedule report is
parent-scoped. Child scheduled `.fsm` text is exposed through the lower-result
`files` map rather than folded into the report. For multi-domain
clock-domain lowering, the schedule report describes the generated top at the
top level and exposes bounded domain/crossing metadata through
`clock_domains[]` and `crossings[]`.

## 3. Source Root

The public compile/report entry root is:

```lisp
(actor name
  actor_clause...)
```

The active parser accepts one actor root from the Lispish source for the
compile/report entry actor and normalizes the Lispish nested-head shape into
canonical `(actor name ...)`. Imported sources may additionally provide
`(library name ...)` roots as described in [3.1](#31-reusable-library-imports).
Accepted parser output preserves `name` as the public actor-shell
`actor_name`; nested or otherwise non-scalar actor names are rejected before the
parser returns an actor shell.

Supported actor clauses:
- `(clock name)`
- `(reset name)` or `(reset (name async active_low))`
- `(watchdog N)`
- `(interface ...)`
- actor-level `(params ...)` for reusable library actors
- actor-level `(constants (NAME value) ...)` for non-negative integer
  compile-time constants
- actor-level `(imports ...)` and `(use ...)` for the first reusable library
  import-resolution slice
- actor-level `(drive ...)` definitions
- `(transaction name ...)`
- `(rule name condition action...)`
- `(rule name (when condition) action...)`
- `(resources ...)`
- `(priority ...)`

Actor-shell singleton clauses are not mergeable. At most one `(clock ...)`,
`(reset ...)`, `(watchdog ...)`, `(interface ...)`, `(params ...)`,
`(constants ...)`, `(imports ...)`, `(resources ...)`, and `(storage ...)`
clause may appear in an actor.
Duplicate singleton clauses are rejected before the parser returns an actor
shell instead of letting later clauses overwrite earlier public fields.

Actor constants:

```lisp
(constants
  (WAIT_ZERO 0)
  (WAIT_TWO 2)
  (WAIT_ONE 4'd1))
```

`(constants ...)` is the first shipped ISF constant/symbol surface. It is
actor-scoped, compile-time only, and currently accepts unique HDL-identifier
names with non-negative integer literal values. Decimal literals and
exact-width integer literals are accepted through the same shared integer
literal support used elsewhere in FSMGen. Constants are emitted into scheduled
`.fsm` as `+constants`, appear in schedule reports as `actor_constants[]`, and
are the first legal symbolic source for static `(wait NAME)` counts. Actor or
transaction `params` are not wait-count constants because they are overrideable
specialization values; using them to choose a fixed generated wait-state count
would make later overrides disagree with the emitted schedule.

Additional actor clauses with mixed parser/scheduler behavior:
- actor-level `(phase name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor phase
  names are rejected.
- actor-level `(stage name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor stage
  names are rejected. Actor phase/stage metadata is parser-carried and
  schedule-report visible through `actor_phases[]` and `actor_stages[]`, but
  it still does not add generated `.fsm`, generated composition-top, or HDL
  behavior.
- `(resources ...)`, structurally validated as resource entries with
  `(arbiter priority|round_robin)` plus optional `(kind ...)` and
  `(users ...)`; `rule_slot` + `priority` resources are scheduler-enforced.
- actor-level `(priority lhs over rhs)`

Deprecated compatibility:
- `(handshake name (valid signal) (ready signal))`-style metadata is
  deprecated compatibility input. The parser validates a scalar name and
  exactly one scalar `valid` property plus one scalar `ready` property, rejects
  duplicate handshake names, then ignores the metadata. The current activation
  model is direct `(on port ...)` plus the scheduler-created `can_accept`
  signal. Legacy handshake metadata will not gain lowering semantics;
  malformed legacy forms point authors toward `(on ...)`, generated
  `can_accept`, or transaction `(stage ...)` for ready/valid barriers.

## 3.1 Reusable Library Imports

Reusable ISF libraries are source-intent roots for tested reusable design
descriptions. They are not textual includes. Imported definitions still lower
through scheduled `.fsm` review artifacts before any HDL backend sees them.
The shipped reusable-definition catalog lives in
[docs/ISF_LIBRARY_CATALOG.md](ISF_LIBRARY_CATALOG.md). The machine-readable
ISF public contract advertises that path, the catalog entry key family, and
the current shipped definitions through `library_catalog_paths`,
`library_catalog_entry_keys`, and `shipped_library_definitions`.

The first shipped library root shape is:

```lisp
(library common.pulse
  (exports
    (actor pulse_actor))

  (actor pulse_actor
    ... reusable actor body ...))
```

The first shipped export kind is `actor`. Standalone `transaction` and `drive`
exports are still deferred because they need an owning actor, storage, reset,
interface, and conflict context before their runtime semantics are public.
Unsupported export kinds fail closed.

Actor roots import and use exported actors with actor-scoped clauses:

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

Import aliases are explicit local namespaces. Without `as alias`, the dotted
library name is the namespace prefix, so `common.pulse.pulse_actor` remains
namespaced rather than unqualified. Duplicate aliases and duplicate use-site
instance names fail closed.

Reusable actor parameters are declared with one actor-level `(params ...)`
clause. Parameter names must be unique HDL identifiers and every parameter has
a default value:

```lisp
(actor pulse_actor
  (params
    (WIDTH 1))
  ...)
```

Use-site overrides are instance-local. Missing overrides use the exported
actor default. Unknown overrides, duplicate overrides, unsupported symbolic
values, and override shapes that do not match aggregate/list defaults fail
closed. The first value domain is scalar decimal literals, exact-width numeric
literals in the shipped ISF parameter syntax, and compatible aggregate/list
literals. Schedule reports expose actor parameter defaults through
`actor_params[]` entries with each authored parameter `name` and JSON-safe
default `value`. These entries describe static specialization defaults; they
are not runtime ports and do not replace generated-composition parameter
binding reports for activation or library use sites.

Bindings are explicit. A reusable actor with a clock or reset must bind that
signal at the use site. Reset kind and polarity remain owned by the reusable
actor in this slice; the use site binds the parent reset signal but does not
change sync/async or polarity semantics. Every exported actor interface port
must be bound exactly once with matching direction and matching known width.
No implicit truncation, extension, or slicing is performed by the library
binder.

Resolution rules:

- Same-source `(library ...)` roots can be resolved by both `parse_file(...)`
  and `parse_source(...)`.
- `parse_file(...)` also resolves external library files from the importing
  source directory, each `FSMLIB` entry, and the current directory.
- For a dotted namespace such as `common.pulse`, both `common.pulse.isf` and
  `common/pulse.isf` are candidate file names under each root.
- `parse_source(...)` has no general external-file search root unless its
  source label is a real file path; use `parse_file(...)` for file-backed
  library resolution.

Lowering emits one specialized child scheduled `.fsm` artifact for each
resolved library actor use. The deterministic module and file basename are
`<importing_actor>__<instance>` and `<importing_actor>__<instance>.fsm`.
When a library actor use is present, lowering also emits a generated top
`<importing_actor>_top.fsm` that instantiates the importing actor and each
library child actor. Bound library inputs are linked from top inputs directly
to the library instance, and bound library outputs drive the corresponding top
outputs. Same-name clock/reset bindings use the existing generated-composition
system-port auto-wiring path. When the library actor's authored clock or reset
name differs from the importing actor's bound parent signal, the generated top
emits explicit Lisp-ish composition links such as `(clk rx.lib_clk)` or
`(rst_n rx.lib_rst_n)`. The reusable actor still owns reset kind and polarity;
the binding remaps only the signal identity seen at the parent boundary. This
is not multi-clock-domain support. The current ISF scheduler still models one
clock domain for an actor/generated top; multi-clock, asynchronous, and
interacting clock-domain semantics remain unspecified and out of scope here.
Successful schedule reports expose a bounded top-level `library_uses` array
with `library`, `alias`, `export`, `kind`, `instance`, `module`,
`scheduled_fsm`, `parameters`, and `bindings`. Parameter summaries expose
`name`, `source`, and stringified `value`. Binding summaries expose `role`,
`library_name`, `parent_name`, and `width`; clock/reset bindings use JSON null
for `library_name`, and reset/clock width is `1`.

Current boundary: `ISF-LIBRARIES.5` resolves reusable actors, validates
parameters and bindings, emits child scheduled `.fsm` artifacts, wires library
actor instances into generated tops for same-name system ports, reaches
SystemVerilog generation for the covered generated-top path, reports bounded
provenance, records the real FIFO requirements, adds the first actor-owned
storage declaration surface, lets rule
guards be scalar or list expressions for direct FIFO fire predicates, and
accepts same-target rule writes when direct contradictory guard facts prove
that the writes cannot fire in the same cycle. A depth-4 FIFO-controller
matrix now lowers through scheduled `.fsm`, schedule JSON, and SystemVerilog
with actor-maintained pointer/occupancy/full/empty state. The first FIFO
datapath surface now implements `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` for actor-owned fixed-depth banks in rules and
supported transaction contexts. The first reusable FIFO library fixture is
now shipped as [isf/common/fifo.isf](../isf/common/fifo.isf), exported as
`common.fifo.fifo`, with [isf/fifo_library_use.isf](../isf/fifo_library_use.isf)
as the file-backed import/use fixture. That fixture reaches generated-top
SystemVerilog through the CLI and checks the specialized FIFO child parameter
bindings, scalarized data entries, pointer-gated accepted push/pop selectors,
and generated top wiring.
The public catalog/contract synchronization slice is shipped as
`ISF-LIBRARIES.5`: [docs/ISF_LIBRARY_CATALOG.md](ISF_LIBRARY_CATALOG.md)
lists the shipped reusable definition with status, parameters, interface,
storage, semantics, tests, and limitations, and the machine-readable public
contract mirrors the bounded discovery metadata.

A depth-1 element is not considered a FIFO for this library catalog; it is a
register/holding element and would hide the real storage and concurrency
requirements. The shipped reusable FIFO actor target is fixed-shape
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`. Those parameters
are provenance and binding evidence in this fixture; the current parser still
requires concrete integer interface widths and storage widths/depths. The
actor has actor-owned storage, read and write pointers, occupancy state,
actor-maintained flags, reset ownership, and first-class handling of the four
request cases every cycle: no request, push without pop, pop without push,
and push with pop. Push-only is accepted when the FIFO is not full, pop-only
is accepted when the FIFO is not empty, simultaneous push+pop derives its
read-fire and write-fire predicates from the same pre-cycle
occupancy/full/empty snapshot, and idle preserves state. Depth 4 gives the
fixture concrete review points: 2-bit pointer wrap, occupancy values 0
through 4, and full/empty derivation.
`full` is maintained by the actor and is `1` exactly when occupancy is 4;
`empty` is maintained by the actor and is `1` exactly when occupancy is 0.
Transaction `(when condition body...)` remains ordered
control flow; it must not be used to pretend FIFO ports are concurrent when a
push and pop request arrive in the same cycle. The storage primitive needed
for that target is now available as actor-owned fixed storage:
`(var name (width N))` for pointer/occupancy state, with `(variable ...)` as
the verbose scalar-storage alias.
Hardware components modeled by ISF are persistent regions, not software
processes that die when work is done. Actors, transactions, DTs, and rules can
be inactive, but while the design is powered, clocked, and released from reset
their logic remains present. FIFO write and read behavior should therefore be
modeled as concurrently evaluable actor logic that interacts with shared
controller state. The write pointer names the entry selected for the next
accepted push; the read pointer names the entry selected for the next accepted
pop; for the first depth-4 target both pointers wrap from entry 3 back to
entry 0. The reusable FIFO fixture models the internal data bank through
`(bank data (width 8) (depth 4))`, `(store data wr_ptr data_in)`, and
`(load data rd_ptr as data_out)`.
Parameter-driven interface widths, arbitrary-depth memory-backed FIFO
generation beyond the first `DEPTH=4` fixture, automatic non-zero reset values
such as empty=1, standalone transaction/drive exports, package/imported
constants beyond actor-local constants, derived parameter expressions, and
library actors that import other libraries remain deferred.

## 4. Clock, Reset, Watchdog

```lisp
(clock clk)
(reset rst_n)
(reset (rst_n async active_low))
(watchdog 65536)
```

Reset rules:
- Clock names must be scalar when a `(clock ...)` clause is present.
- `(clock ...)`, `(reset ...)`, and `(watchdog ...)` are actor-level
  singleton clauses; duplicates are rejected before actor-shell return.
- ISF currently supports one actor clock domain. A non-`clk` name is just an
  authored signal name for that single domain, not a second or interacting
  clock domain.
- Flat `(reset name)` defaults to synchronous reset.
- Names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List form may include `async`, `active_low`, or `active_high`.
- Reset names must be scalar when a `(reset ...)` clause is present.
- Async resets lower to `.fsm` `(areset name)`.
- Sync resets lower to `.fsm` `(sreset name)`.

Multi-clock boundary:
- Legacy `(clock name)` ISF actors have one clock domain per actor/generated
  top.
- Library clock/reset bindings and generated-top system-port links are
  signal-name binding inside the one-domain library-binding model. They do
  not create a second clock domain and they do not model clock-domain crossing
  behavior.
- ISF now accepts parser metadata for named domains and builds an internal
  scheduler partition. Public `lower(...)` emits one domain scheduled `.fsm`
  artifact per declared domain plus a generated multi-domain top that wires
  explicit CDC child-interface artifacts for accepted event crossings.
  Schedule-report projection now exposes bounded domain and crossing metadata.
  Generated HDL for accepted event-crossing actors now emits the generated top
  and concrete acknowledged-event CDC child for SystemVerilog/Verilog-family
  targets when each emitted domain artifact satisfies the current scheduled
  `.fsm` clock/reset HDL contract.
- Direct reads or writes between domains are not accepted by implication. A
  shipped CDC primitive or protocol actor must provide specified runtime
  behavior, lowering, diagnostics, and report metadata before such crossings
  are legal.
- Asynchronous reset trees are not DTs. FSMGen does not use ISF DT logic to
  build arbitrary asynchronous reset gating.

Selected source model and current implementation status:
- Named domains are actor-scoped. The parser now accepts the selected
  actor-level `(clock-domains ...)` block as metadata for the domain
  partitioning handoff:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain bus  (clock bus_clk)))
```

- Existing `(clock clk)` remains the shorthand for one implicit actor domain
  named `default`.
- Actor source must not mix `(clock ...)` with `(clock-domains ...)`, and must
  not mix actor-level `(reset ...)` with `(clock-domains ...)`.
- A multi-domain actor must declare unique domain names, scalar clock names,
  and exactly one default domain. A single-domain block has an implicit
  default.
- Interface ports, actor-owned storage entries, transactions, rules, and
  child instances may only reference actor-declared domain names through
  `(domain NAME)` annotations. Omitted domain references inherit the actor
  default domain when `(clock-domains ...)` is present.
- Domain annotations are accepted on interface ports, storage entries,
  transactions, rules, reusable `use` instances, and generated child
  activations:

```lisp
(interface
  (input start (domain core))
  (output bus_done (domain bus)))
(storage
  (var core_reg (width 1) (domain core)))
(transaction bus_tx
  (domain bus)
  ...)
(rule core_rule
  (domain core)
  ...)
(use lib.actor as rx
  (domain bus)
  (bind ...))
(spawn worker as w0
  (domain core))
```

- Drives do not own domains; they inherit the domain of their activation site.
  Reusing one drive body from multiple domains is rejected until a later
  feature defines safe cross-domain drive reuse.
- Transactions and rules are indivisible domain-owned regions. One
  transaction or rule may not be split across multiple domains.
- Interface-port or child-instance domain annotations are ownership metadata,
  not CDC primitives. They do not legalize direct cross-domain reads, writes,
  triggers, activations, or bindings.
- Malformed domain combinations fail closed: unknown domain references,
  duplicate domain names, duplicate or missing default domain markers in a
  multi-domain actor, duplicate clock names that pretend to be distinct
  domains, and any direct unowned crossing are rejected before lowering.
- Single-domain `(clock-domains ...)` sources can still lower through the
  existing single-clock scheduled `.fsm` path. Multi-domain sources build a
  validated internal domain partition, then public `lower(...)` returns
  domain-specific scheduled `.fsm` artifacts named
  `<actor>__domain_<domain>.fsm` and a generated `<actor>_top.fsm` top
  artifact.
- Schedule reports for multi-domain sources describe the generated top at the
  top level and expose each domain artifact through `clock_domains[]`; legal
  event crossings appear in `crossings[]`. The plain HDL path for accepted
  event-crossing actors emits the generated top and concrete acknowledged-event
  CDC child for SystemVerilog/Verilog-family targets when each emitted domain
  artifact satisfies the current scheduled `.fsm` clock/reset HDL contract.

Selected reset ownership model and current implementation status:
- Existing actor-level `(clock clk)` plus optional actor-level `(reset ...)`
  remains the shipped shorthand for one implicit domain named `default`.
- An actor using `(clock-domains ...)` must put reset ownership inside each
  domain entry and must not also use actor-level `(reset ...)`:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
```

- Each domain owns zero or one reset. A domain with no reset clause has no
  generated reset for its clocked state.
- Domain reset payloads reuse the shipped reset value rules: flat
  `(reset name)` is synchronous with inferred polarity; list forms may include
  `async`, `active_low`, or `active_high`; and reset names must be scalar.
- A synchronous reset is sampled only on the owning domain clock edge.
- An asynchronous reset is a direct external reset pin for the owning domain's
  clocked state. It is not a data signal, handshake, or CDC primitive.
- The same reset signal may be named by multiple domains only when
  synchronous/asynchronous kind and polarity match exactly. Such fanout
  describes one external reset pin reaching multiple domains; it does not
  synchronize data between them.
- Child reset bindings connect the child local-domain reset pin to a signal in
  the selected parent domain or to an explicitly shared external reset pin
  under the same kind/polarity rules.
- Malformed reset combinations fail closed: duplicate domain reset clauses,
  actor-level `(reset ...)` mixed with `(clock-domains ...)`, expression-valued
  reset names, conflicting reset reuse, DT-generated async reset gating, and
  treating reset assertion/deassertion as an ordinary cross-domain event.

Selected crossing primitive and current implementation status:
- The first legal cross-domain interaction is an acknowledged single-bit event
  channel. It carries no data payload:

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

- `(crossings ...)` is actor-scoped and references only domains declared in
  `(clock-domains ...)`.
- `(from DOMAIN SIGNAL)` names the source-domain event request signal.
- `(to DOMAIN SIGNAL)` names the generated destination-domain one-cycle event
  pulse.
- `(ready SIGNAL)` names the generated source-domain ready signal. Source
  logic may request a new event only when ready is true.
- Source and destination domains must be different declared domains.
- The primitive has at most one outstanding event. After an accepted source
  event, ready deasserts until an acknowledgement returns from the destination
  domain.
- The destination pulse occurs after synchronizer/acknowledgement latency. No
  same-cycle relationship is promised between source request and destination
  pulse.
- The generated top represents the primitive as an explicit CDC child
  interface with source clock/reset, destination clock/reset, request, ready,
  and pulse ports. Schedule reports expose the generated CDC instance/module
  names, endpoint domains/signals, single-outstanding acknowledgement policy,
  and no-payload policy. The generated HDL path recognizes the ISF-generated
  CDC metadata and emits a concrete acknowledged-event synchronizer child; it
  does not infer HDL for arbitrary external `?rtl` children.
- Payload transfer, multi-bit data, level sampling, reset crossing, and
  FIFO-like storage remain outside this first primitive.
- Direct cross-domain reads, writes, triggers, activations, parent/child
  bindings, and reset assertion/deassertion events remain rejected unless a
  shipped crossing primitive or protocol actor owns that path.

Selected lowering artifact strategy and current implementation status:
- Current multi-domain lowering builds an internal domain partition that groups
  interface endpoints, storage, transactions, rules, reusable library uses, and
  generated child activations by declared domain. It rejects direct unowned
  cross-domain reads, writes, triggers, activations, bindings, and multi-domain
  drive reuse before emission.
- Current multi-domain artifact emission emits one domain-local scheduled
  `.fsm` artifact per declared domain, named
  `<actor>__domain_<domain>.fsm`.
- Each domain `.fsm` remains a normal single-clock scheduled module. Its
  `+system` clause uses only the domain clock and that domain's reset policy.
- A domain `.fsm` contains only domain-owned interface endpoints, storage,
  transactions, rules, child activations, generated helper signals, and
  generated event primitive endpoints for that domain.
- No domain `.fsm` directly references another domain's local state, generated
  helper, transaction, rule, or port.
- A generated top artifact named `<actor>_top.fsm` owns inter-module wiring.
  It instantiates domain modules and explicit CDC child interfaces through
  `?rtl`/`?rtlif` entries. It must not hide clocked behavior in top-level DT
  logic.
- The acknowledged event primitive emits an explicit generated CDC child
  interface with source clock/reset, destination clock/reset, request, ready,
  and pulse ports. It is not an ordinary single-domain `.fsm` state chain.
- Schedule-report metadata for domain artifacts and crossing artifacts is
  shipped. Multi-domain reports use the generated top as the top-level report
  scope, keep top-level `state_count` at zero, and put domain-local state
  counts plus artifact names under `clock_domains[]`. Plain HDL generation for
  accepted event-crossing actors emits the generated top and concrete
  acknowledged-event CDC child on SystemVerilog/Verilog-family targets when
  each emitted domain artifact satisfies the current scheduled `.fsm`
  clock/reset HDL contract.

Watchdog rules:
- `(watchdog N)` is the actor default for every `(await ...)`.
- `N` must be a positive integer.
- `(await port (watchdog M))` overrides the default for that wait.
- Await states decrement an inferred watchdog counter and transition to a
  timeout state at zero.

## 5. Interface

```lisp
(interface
  (input  name)
  (input  name (width N))
  (output name)
  (output name (width N)))
```

Default width is `1`. Interface entries lower into `.fsm` `+size` entries.
Accepted parser output exposes the interface handoff as `inputs` and `outputs`
arrays with unique non-empty scalar port `name` and positive integer `width`
entries. Malformed directions, duplicate names across either direction, nested
names, and non-positive or non-integer widths are rejected before the parser
returns an actor shell.
`(interface ...)` is an actor-level singleton clause; repeated interface blocks
are rejected instead of merged or overwritten.
If an inferred scheduler storage name matches a declared interface port, the
declared port entry is kept and the inferred duplicate is suppressed.
Output ports are marked as public outputs by the `.fsm` emitter when assigned
from drive/rule output paths.

### 5.1 Actor-Owned Storage

Actors may declare internal persistent state with a singleton `(storage ...)`
clause:

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width 2))
  (var occupancy (width 3))
  (bank data (width 8) (depth 4)))
```

The first shipped storage forms are:

- `(var name (width N))`: a fixed-width actor-owned internal scalar variable.
- `(variable name (width N))`: verbose alias for `(var ...)`.
- `(bank name (width N) (depth N))`: a fixed-depth actor-owned storage bank.

All widths and depths are positive integer literals in the current shipped
surface. Parameter-derived widths/depths, actor constants as storage dimension
symbols, dynamic storage depth, and memory-array backend emission remain
deferred.

Storage banks lower to deterministic scalar storage element names in the
scheduled `.fsm` review artifact. For example,
`(bank data (width 8) (depth 4))` declares `data_0`, `data_1`, `data_2`, and
`data_3`, each 8 bits wide. This scalarized lowering is intentional for the
first FIFO work: it lets the `DEPTH=4` fixture use four concrete storage
entries and reach the existing scalar signal/flop SystemVerilog backend before
generalized indexed storage syntax or memory-array emission is shipped.

Declared storage is internal actor state, not an interface port. A storage
signal must not collide with an interface port, actor clock/reset signal, or
generated scheduler signal such as `can_accept`. Missing width/depth options,
duplicate logical storage names, duplicate scalarized element names, and
duplicate `(storage ...)` clauses fail closed before scheduler handoff.

Lowering emits declared storage signals in scheduled `.fsm` `+size`. The
lowerer also carries their widths as normal width evidence so updates and data
operations can reuse the existing expression and mux paths. Schedule reports
include declared storage entries in `inferred_storage` with kind `register`,
role `actor_storage`, and positive integer `width`. Used storage signals reach
SystemVerilog generation through the existing scalar assignment path.
The report `kind` is the generated storage class; authored scalar storage uses
the normalized scalar storage kind. `(state ...)` and `(register ...)` are not
accepted storage entry spellings.

### 5.2 Actor-Owned Bank Access

The first shipped source surface for actor-owned bank data access is explicit
action syntax:

```lisp
(store <bank-name> <index> <value>)
(load <bank-name> <index> as <target>)
```

Rules and supported transaction contexts accept these actions when
`<bank-name>` names a declared actor-owned `(bank ...)` storage entry. The
word `bank` in the grammar is a placeholder for an authored bank name; it is
not a literal token. An actor may declare multiple banks, and the second item
in each `store` or `load` selects which bank is accessed.
`store` is bank-only: it writes a selected entry of a declared bank. Scalar
actor-owned storage is written with the explicit setter `(set lhs expr)`.
Existing transaction `(update lhs expr)` remains supported as the older
transaction-local spelling, and ordinary rule assignments such as `(wr_ptr 1)`
remain supported shorthand. The setter word is shared, but the runtime region
is still owned by context: a rule `set` is actor-level concurrent logic guarded
by the rule's non-state DT enable, while transaction `set` is an ordered
transaction step that becomes part of the transaction state sequence.

`(store data wr_ptr data_in)` means: write `data_in` into the actor-owned bank
entry selected by `wr_ptr`. For a fixed-depth scalarized bank, lowering emits
one guarded update per bank entry. With depth 4, the scheduled `.fsm` review
artifact makes the selected entry visible through guards equivalent to
`wr_ptr == 0`, `wr_ptr == 1`, `wr_ptr == 2`, and `wr_ptr == 3` on `data_0`,
`data_1`, `data_2`, and `data_3`.

`(load data rd_ptr as data_out)` means: read the actor-owned bank entry
selected by `rd_ptr` into `data_out`. Lowering uses the same scalarized entry
family to build a mux-equivalent set of guarded assignments from `data_0`
through `data_3` into the target.

The first timing contract is read-before-write for same-cycle store and load
against the same bank. A load observes the current bank entry value from the
cycle snapshot. A store updates the selected bank entry for the following
cycle. If a later design needs write-first behavior, bypass behavior, or a
collision diagnostic, that must be an explicit future option or construct.

The first implementation requires:
- `bank` names a declared actor-owned `(bank ...)`;
- `index` is a scalar signal or literal token whose value domain is checked
  against the fixed bank depth where possible;
- `value` has bank-entry width or enough width evidence to reject mismatch
  before scheduled `.fsm` emission;
- `target` is a scalar storage or interface target with width compatible with
  the bank entry when width evidence is available;
- malformed arity, unknown banks, non-bank storage names, unsupported dynamic
  depth, width mismatch, and unsupported same-target conflicts fail closed with
  targeted diagnostics; and
- schedule reports expose bounded `bank_accesses` metadata so downstream
  consumers can see which owner accesses a generated storage bank, the
  selected index token, scalarized entries, width/depth, and the
  read-before-write same-cycle policy.

## 6. Drive Definitions and Calls

Drive definitions are actor-level reusable output phases.

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

Drive call:

```lisp
(drive setup_phase)
(drive scl 1)
```

Current lowering:
- Accepted parser output exposes drives as a hash of shell entries keyed by
  unique non-empty drive name. Each entry contains `params` and `body` arrays.
  Duplicate drive names, nested or otherwise non-scalar drive names, duplicate
  parameter names, and nested or otherwise non-scalar parameter names are
  rejected before the parser returns an actor shell. Body entries are
  structurally validated as scalar `(port value)` pairs before parser return;
  richer body-expression semantics are not frozen as a public API by the
  actor-shell drive-shape metadata.
- Each drive definition becomes a non-state DT block named `-drive_name`.
- Each drive call becomes one scheduled state.
- The call asserts `drive_name_start`.
- Parameterized calls also assign one inferred parameter signal per formal,
  such as `scl_val`.
- Named drive calls use exact positional arity: a drive with `N` formal
  parameters requires exactly `N` actual values at every known drive call.
  Missing actuals and extra actuals fail closed during lowering instead of
  leaving parameter signals unbound or silently ignoring values.
- Drive-call actuals may be scalar tokens or composed `.fsm` expression forms.
  Argument-level composition is part of the Lisp-like ISF surface, so a call
  such as `(drive mosi (& tx_byte[7] shift_enable))` lowers to a composed
  scheduled `.fsm` expression instead of requiring a temporary variable.
- Hash-backed drive DT emission is deterministic: drive definitions are emitted
  lexically by drive name after transaction/rule-created DTs and any generated
  rule-trigger fan-in DTs.
- Drive DT assignments use flopped output assignment (`<-`) by default, so a
  drive call consumes one state and the driven port updates on the next clock.
- When a generated scheduled `.fsm` assignment targets a declared actor output,
  the LHS uses the normal `.fsm` output marker, such as `scl>`, `done>`, or
  `rdata>`, for all assignment families.
- DT selector logic is combinational. Assignment families decide the target
  behavior selected by that logic: `=` assignments drive combinational mux
  outputs, `<-` and `<=` assignments drive sequential/flopped targets, and
  `<1` assignments request one-cycle delayed pulses whether they appear in a
  state DT `(state_name ...)` or a non-state DT `(-name ...)`.
- The machine-readable ISF public contract advertises those operator families
  through `dt_assignment_operator_family_map`.
- Adjacent drive calls are not merged. To drive several ports in the same
  cycle, put those port-value pairs in one drive definition.

## 7. Transactions

```lisp
(transaction name
  clause...)
```

Accepted parser output exposes transactions as an array of shell entries with
unique non-empty scalar `name` and `clauses` array fields. Duplicate, nested,
empty, or otherwise non-scalar transaction names are rejected before the parser
returns an actor shell. Clause payload contents remain scheduler input and are
not frozen as a public API by the actor-shell transaction-shape metadata.

Author-facing mental model: a transaction is task-like because it consumes
cycles and can own formal boundaries. Transaction `(ports ...)` declarations
act as formal data/control ports, and activation sites pass scalar, literal,
or list-expression runtime payloads through explicit `(bind ...)` blocks. The
compiler owns the lower-level handoff signals, mux selectors, and generated-top
bridge wiring. This is still static hardware, not a stack-allocated SV task
call: every activation lowers to scheduled `.fsm` states, persistent handoff
signals, and reviewable
assignments. Parameter overrides are narrower than port bindings: spawned child
transactions and blocking `do` generated child activations support
transaction-local `params` and per-instance `(params (NAME value) ...)`
overrides through the generated composition path, and those overrides
specialize static child instances. Parameterized rule triggers use the same
static-specialization model: they specialize generated child activation
instances rather than mutate a shared transaction body. Direct `(on ...)`
entry activation does not accept activation-site parameter overrides: it is the
transaction's own guard, not a separate caller-owned instance. Parameter
declarations on a directly entered transaction still apply as defaults for
that transaction definition; per-activation specialization requires a
generated activation form such as `spawn`, parameterized blocking `do`, or
parameterized rule `trigger`.

The activation-site parameter shape is the same explicit block already used by
spawned children. It is shipped for spawn, blocking `do`, and rule `trigger`:

```lisp
(do child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))

(trigger child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))
```

Those `params` values are static specialization values, not runtime payload
actuals. Runtime-varying data/control values must use transaction ports and
`(bind ...)`. A parameterized blocking `do` elaborates a generated child
activation instance and waits for that instance's `done` handoff. If two
activation sites override the same transaction parameter with different
values, the implementation must specialize distinct logical child instances or
cloned scheduled regions. It must not lower the parameter as a mutable runtime
signal shared by every activation of the transaction.

Actor-local constants are accepted as static activation parameter override
values. A constant name may appear as a scalar override value, or as a scalar
leaf inside an aggregate/list override value, for generated activation forms
that already support `(params ...)`: spawn, parameterized blocking `do`, and
parameterized rule `trigger`. The lowerer resolves constants to literal values
before generated-top emission, so generated `?fsmc` parameter overrides remain
self-contained. Unknown names, actor parameters, transaction parameters,
runtime signals, and arbitrary expressions remain fail-closed until a later
task explicitly ships a wider value source.

The parameterized rule-trigger contract follows the same specialization rule.
It elaborates a generated child activation instance named
`{rule}_{transaction}_trigger_{ordinal}` for each lexical parameterized trigger
site, applies the overrides on that generated `?fsmc` instance, and preserves
the shipped rule-trigger pulse and input payload timing through generated
handoff DTs. Rule-trigger output bindings remain unsupported because rules do
not wait for transaction completion.

Direct `(on ...)` activation has no corresponding `(params ...)` source shape.
The only legal nested body clauses in `(on port body...)` are
`(sample port as name)` entries. A source such as
`(on start (params (WIDTH 16)))` is unsupported and must fail closed instead of
being interpreted as either a runtime assignment or a static specialization
site. Authors who need runtime-varying values at entry should sample or read
ports; authors who need static specialization should move the reusable work
behind a generated activation site.

Current transaction clauses:
- `(on port body...)`
- `(when condition body...)`
- `(drive name args...)`
- `(await port)` and `(await port (watchdog N))`
- `(sample port as name)`
- `(wait N)` for an unconditional exact-cycle delay with a non-negative static
  literal, actor constant, bounded runtime scalar count, or bounded runtime
  expression count
- `(while cond body...)`
- `(until cond body...)`
- `(repeat count body...)`
- `(switch signal (value body...)...)`, with optional `(default body...)` or
  `(_ body...)` fallback branch
- `(set var expr)`
- `(update var expr)`
- `(shift_left reg bit)`
- `(shift_right reg bit)`
- `(assemble part... as var)`
- `(extract word as field...)`
- `(extract word as field... (widths N...))`
- `(do transaction [(params (NAME value) ...)] [(bind ...)])`
- `(spawn transaction as instance [(params (NAME value) ...)] [(bind ...)])`
- `(trigger transaction [(params (NAME value) ...)] [(bind ...)])`
- `(await_all done_port)`
- `(await_any done_port)`
- `(complete port)`
- `(latency (min N) (max M))`

Unsupported transaction clause heads now fail closed during lowering instead
of being silently ignored. The same applies inside currently lowered body
contexts: `when` bodies, `switch` branches, and `repeat` bodies each have a
bounded supported subset matching the shipped lowerer. Deferred-but-recognized
`(contract ...)` and transaction `(stage ...)` clauses keep their more specific
diagnostics.

### 7.1 Activation

`(on port ...)` creates an entry/idle state guarded by scalar `port`.
The only supported inline body clauses inside `(on ...)` are
`(sample port as name)` forms; other activation-body forms fail closed during
lowering instead of being ignored.
`(on ...)` does not accept `(params ...)` because it is not a separate
activation instance. Transaction-local `params` on the same transaction remain
definition defaults, not per-entry overrides.

The scheduler also creates `can_accept` and asserts it in entry states. This is
the current replacement for the old handshake-ready spelling. Deprecated
`(handshake name (valid signal) (ready signal))` metadata is compatibility-only:
the parser validates a scalar name, exactly one scalar `valid`, and exactly one
scalar `ready`, but the scheduler does not lower old handshake semantics. This
is an explicit compatibility policy, not an unfinished lowering path.

Samples inside `(on ...)` lower to guarded D-input assignments (`<=`) on the
entry transition.

`(when condition ...)` may be used as the first transaction clause as an
activation guard. It may also appear later as inline branching.

### 7.1.1 Transaction Ports and Actor Pin Access

Transaction port declarations and activation-time bindings are now accepted.
Actor pin access is available through those bindings: actor inputs may be read,
actor outputs may be written, and actor output readback is rejected. Input
bindings may now be scalar signals, numeric/exact-width literals, or non-empty
list expressions. Bounded schedule-report binding provenance is shipped;
broader output binding shapes remain deferred follow-on work after
[docs/tasks/ISF-PORT-BINDING.md](tasks/ISF-PORT-BINDING.md) and
[docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md](tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md).

The public direction remains an ISF-level surface, not an author-facing escape
hatch to low-level `.fsm` handoff wiring. A transaction declares directional
data/control ports locally. Activation sites bind those ports to scalar actor
variables, actor-owned storage, or actor top-level pins with exact direction
and width checks. Authors should not manually create transaction payload wires,
bridge ports, generated-top handoff nets, or start-payload signals just to
connect transactions; the compiler lowers the ISF boundary into explicit
scheduled `.fsm` handoff assignments and reviewable generated-top wiring.

Shipped transaction declaration shape:

```lisp
(transaction read_word
  (ports
    (input  addr (width 32))
    (output data (width 32)))
  ...)
```

Each transaction may contain at most one `(ports ...)` clause. Each port entry
is `(input name)`, `(output name)`, `(input name (width N))`, or
`(output name (width N))`, where `name` is a scalar HDL identifier and `N` is
a positive integer literal. Omitted width means 1. Port names are unique across
both directions within the transaction. The parser returns the normalized
transaction-shell shape:

```lisp
ports = {
  inputs  => [ { name => "addr", width => 32 }, ... ],
  outputs => [ { name => "data", width => 32 }, ... ],
}
```

The `(ports ...)` declaration is not forwarded as a scheduler body clause. A
declaration by itself does not create behavior; behavior comes from transaction
states/rules that read or write the port and from activation sites that bind
the port.

Shipped activation binding shapes:

```lisp
(do read_word
  (bind
    (input addr req_addr)
    (output data read_data)))

(spawn read_word as r0
  (bind
    (input addr req_addr)
    (output data read_data)))

(trigger read_word
  (bind
    (input addr (+ base_addr offset))))
```

Transaction input bindings accept scalar actor-side signals,
numeric/exact-width literals, and non-empty list expressions. Scalar sources
and expression sources whose width is known by the lowerer are width-checked
against the transaction input port. Unknown expression widths continue into
the downstream `.fsm` expression validation and HDL generation path. Every
scalar signal reference that the lowerer can identify in an input-binding
expression must be a known readable actor input, declared actor-owned storage
signal, or known transaction variable in the caller's scope; actor output
readback is rejected. Transaction output bindings remain scalar-only because
the actor-side endpoint is the writable destination.

Local `(do ...)` bindings lower into the scheduled parent `.fsm` state that
starts and awaits the child transaction. Transaction input bindings are
emitted before the generated `child_start`; output bindings copy the child
output port to the bound actor signal under the generated `child_done` guard.
Parameterized/generated `(do ...)` bindings lower through explicit
generated-top handoff ports and a parent-owned `do_port_binding` DT. Input
bindings are same-cycle parent handoff assignments; output bindings copy the
generated child output under the generated instance's `done` guard.

`(spawn ...)` bindings lower through hidden generated-top handoff ports. Input
bindings create a hidden parent output handoff and a visible child input port;
output bindings create a hidden parent input handoff from the child output
port and a reviewable parent DT assignment to the bound actor signal. The
generated top wires those handoffs explicitly. Actor signals consumed by
explicit spawn input-binding expressions are not also same-name wired into the
child instance; the explicit handoff is the data path. Spawn output-binding
assignments are owned by the parent transaction for assignment provenance and
rule/transaction conflict analysis.

Rule `(trigger ...)` bindings currently support transaction input ports only.
Each triggering rule emits a distinct payload source signal per bound input
port, and the generated trigger fan-in DT routes that payload into the
transaction port under the matching per-rule trigger source. Multiple rule
payloads for the same port therefore remain visible as guarded same-LHS
assignments instead of being silently merged. Rule-trigger output bindings
remain deferred because a rule does not await transaction completion.

The same-cycle visibility rule for this first shipped surface is: input
payloads are emitted in the same activation region as their start/trigger
handoff, and spawned child bindings are live handoff wiring through the
generated top. If authors need explicit snapshot-vs-live selection later, it
must be added as a separate source spelling rather than changing this behavior.

Actor top-level input pins are readable observations. ISF should not allow
transactions or rules to write actor inputs. Actor top-level output pins are
writable targets, but only through the same assignment, fan-in, priority,
resource, and runtime-conflict policies used for other driven LHS values.
Reading an actor output as a source value needs an explicit contract; until
that ships, authors should keep a variable for internal reuse and bind or
drive the output from that variable.

Rules that trigger transactions need a payload story as soon as transactions
have input ports. Multiple rules may trigger the same transaction in different
cycles, and sometimes in the same cycle. The implementation must not silently
merge two different payloads for the same transaction input. It must either
prove compatible fan-in, use explicit priority/resource arbitration, or emit
verification-only runtime conflict instrumentation according to the existing
conflict policy.

The shipped conflict coverage is now concrete for scalar bindings:
same-target rule/transaction conflicts involving spawned output bindings enter
the existing fail-closed rule/transaction path, while accepted spawn-output and
rule-trigger input fan-in reaches the SystemVerilog backend's verification-only
selector assertions.

### 7.2 Sampling and Variables

```lisp
(sample req_addr as addr)
```

Current lowering:
- Sample clauses are structurally validated as exactly
  `(sample port as name)` with scalar `port` and scalar `name`. This applies
  both to standalone transaction-body samples and to samples nested directly in
  `(on ...)`.
- Samples lower to `.fsm` D-input assignments (`<=`).
- The `<=` operator is intentional: the sampled name denotes the D-input /
  next-value side in the state where the sample is emitted. Lowering samples
  with `<-` would make that name denote the previous Q/output value for
  same-state consumers, especially when a drive follows the samples and its
  parameter wiring consumes a sampled alias. That would force an extra state or
  risk stale data.
- Samples in `(on ...)` fire with the entry guard.
- Samples collected before a later drive/await are piggybacked onto that next
  scheduled state.
- Samples collected before a data operation materialize in a sample state
  before the data-operation state, so the data operation reads the captured
  value rather than the previous value.
- Entry-state sample materialization and drive/await piggybacking are locked by
  [t/1100-isf-sample-piggyback.t](../t/1100-isf-sample-piggyback.t).
- The current implementation treats sampled names as inferred storage; richer
  wire-vs-register optimization is still future work.

### 7.3 Await and Timeout

```lisp
(await ready)
(await ready (watchdog 32))
```

Current lowering:
- The await state tests the current `{transaction}_wd` Q value.
- The normal transition fires when the awaited port is true.
- A timeout transition fires when the watchdog counter is zero.
- A `>0` watchdog branch schedules the watchdog decrement for the next counter
  value. The zero test and decrement branch are same-cycle DT selector
  equations, not procedural statements. The `>0` guard also avoids describing
  a zero-watchdog decrement to all ones; timeout normally exits the await state,
  but the emitted next-value selection stays blocked at zero.
- Timeout states assign `done` with a one-cycle delayed pulse (`<1`) and
  `last_error` with a flopped output assignment (`<-`).

### 7.4 Completion

```lisp
(complete done)
```

Current lowering:
- `(complete port)` is structurally validated as exactly one scalar `port`
  target before scheduled `.fsm` emission.
- `(complete port)` creates a terminal state that returns the transaction to
  idle.
- The completion port assignment lowers to `(<1 (port 1))`, producing a
  one-cycle delayed pulse rather than a sticky flopped status bit.
- Protocol/output drive phases should not also drive the same completion
  signal with `<-`, because the `.fsm` backend rejects mixed pulse-delayed and
  non-pulse sequential operators on one LHS.

### 7.5 Latency

```lisp
(latency (min 1) (max 64))
```

Current lowering:
- Latency metadata accepts one or both `(min N)` and `(max N)` options.
- `N` must be a positive integer, each option may appear at most once, and
  `min` must be less than or equal to `max` when both are present.
- The scheduler creates a transaction cycle counter, an increment source, and
  latency error wiring without adding an authored transaction state.
- A valid explicit `max` bound drives the generated counter width and max
  violation check; omitted bounds use the scheduler defaults.

### 7.6 Repeat

```lisp
(repeat beats
  (await ready)
  (sample rdata as word))
```

Current lowering:
- Repeat clauses are structurally validated as `(repeat count body...)` with a
  scalar non-empty count and at least one body clause before counter emission.
- The scheduler creates `{transaction}_cnt`.
- The repeat init state loads the count with `<=`.
- The repeat body is expanded inline.
- The repeat check state decrements with `<-` and loops while the counter is
  nonzero.
- Repeat counter width is inferred. Decimal literal counts use the minimum
  width that can represent the loaded count; named counts use the known
  interface/sample width; unknown count forms fall back to `8`.
- Top-level repeats and switch-nested repeats register the shared transaction
  counter at the widest required width.
- Repeat bodies lower named drive calls plus `await`, `sample`, `update`,
  `shift_left`, `shift_right`, `assemble`, and `extract`.

The repeat count is a runtime counter load value, not an elaboration count.
Literal counts give statically reviewable loop bounds. Named counts may be
dynamic scalar signals when their width is known, but they make transaction
latency data-dependent and require a clear zero-count policy before the loop
can be treated as fully general. Future spawn-in-repeat support must preserve
the same rule: the loop reactivates a lexically named static child instance; it
does not create one child instance per iteration.

### 7.6.1 Transaction Wait

```lisp
(wait 3)
```

`(wait N)` is the shipped unconditional transaction-local delay, distinct from
`(await cond)` and `(repeat count body...)`. It does not test an external
condition and it does not repeat a body. The shipped static count surface
accepts either a non-negative integer literal or an actor constant name that
resolves before lowering to a non-negative integer literal. The runtime count
surface accepts a known-width scalar count name or a known-width non-empty
list expression in contexts whose predecessor edge can be split safely.

Cycle semantics:
- `wait 0` means no delay. It emits no wait state, consumes no active
  transaction cycle, and advances directly to the following transaction clause.
- `wait 1` means the transaction occupies one generated wait region for one
  active clock cycle, then advances on the next state transition.
- `wait N` contributes exactly `N` active transaction cycles every time the
  clause executes.
- A wait inside a future loop contributes its full `N` cycles for each loop
  iteration that reaches it.
- The wait does not observe or consume an `(await ...)` watchdog. It is still
  ordinary transaction time and therefore counts toward transaction latency
  accounting or transaction-level monitors that count active transaction
  cycles.

The static lowering is a reviewable fixed scheduled-state chain for positive
static counts. `(wait N)` emits `N` generated `*_wait_*` states when `N > 0`;
each state advances unconditionally to the next wait state or to the following
transaction clause. `(wait 0)` emits no generated state and no
`transaction_waits[]` entry. A symbolic `(wait NAME)` first resolves `NAME`
through the actor constant table and then follows the same rule. No hidden
wait counter is introduced for this static literal/constant surface. Pending
samples collected before a positive wait piggyback onto the first generated
wait state using the same sample-assignment behavior as drive/await
piggybacking. Pending samples collected before a zero wait are preserved and
materialize on the next state-producing clause. The wait surface is accepted
at the top level of a transaction body and inside the currently shipped inline
body contexts: `when`, `switch`, `repeat`, `while`, and `until` bodies.

For the runtime surface, `(wait count_signal)` is accepted when `count_signal`
has a known unsigned width. `(wait (<op> ...))` is accepted when every signal
referenced by the non-empty list expression has known width and the
expression-width helper can derive a positive result width. Expression counts
use the same predecessor-edge snapshot contract as scalar counts. The
predecessor state gets two explicit outgoing edges: an effective count of zero
bypasses directly to the post-wait state, and a non-zero effective count
snapshots the current scalar or expression value into a generated wait counter
and enters one generated wait state. The wait state decrements that sampled
counter while active, exits when the sampled counter is `1`, and loops while
it is greater than `1`. A sampled runtime value of `K > 0` therefore consumes
exactly `K` active wait cycles, and later changes to the source scalar or
expression operands do not affect that wait occurrence.

Consecutive top-level runtime waits are supported by carrying the same
edge split through the wait chain. If the first runtime count is zero, the
activation edge immediately evaluates the next runtime wait's zero-bypass or
positive sampled-counter path. If the first wait is active, its final sampled
counter cycle (`counter == 1`) performs that same split for the next wait
without rereading the first count source and without adding an extra active
cycle.

Runtime waits are also supported after the shipped top-level predecessor
states whose advance condition is known to the scheduler. After `(await
ready)`, the ready edge splits into `ready && count != 0` and `ready && count
== 0` while the watchdog timeout edge remains intact. After `(stage ...)`, the
stage ready edge is split the same way while the valid output remains driven
by the stage state. After a top-level `repeat`, the repeat-check exit edge
`counter == 0` is split while the loop-back edge is preserved. After
`await_all`, the split is gated by the logical AND of all collected done
signals. After `await_any`, the split is gated by the logical OR of the
collected done signals. Loop decision states can also split a runtime wait
edge: a `while` true body-entry or back-edge, an `until` false back-edge, and
a loop-exit edge that falls through to a following runtime wait can all load
or bypass the generated counter while preserving the opposite loop branch.

Runtime waits inside `when` bodies are supported when no pending sample must
cross the dynamic wait. The branch true edge is split into positive-count
counter load and zero-count bypass paths, and the false edge still skips the
whole `when` body. Runtime waits inside `repeat` bodies are also supported
when no pending sample must cross the dynamic wait; generated dynamic wait
counters are registered alongside the repeat counter, and the repeat-check
loop-back/exit edges remain intact. Runtime waits inside `switch` branches are
supported for the no-pending-sample subset. If the selected switch case starts
with a runtime wait, the switch state owns that case's positive-count counter
load/entry and zero-count bypass; other explicit cases remain selectable, and
implicit fallthrough lowers as the complement of all explicit case-value
predicates. Runtime waits inside `while` bodies are supported for the
no-pending-sample subset. If the body starts with a runtime wait, both the
entry decision true path and the loop-back true path split into positive-count
counter load/entry and zero-count bypass paths, while the false path exits the
loop. Runtime waits inside `until` bodies are also supported for the
no-pending-sample subset. The initial predecessor enters or bypasses the first
body wait, the `until` true path exits, and the false loop-back path reloads
or bypasses the runtime wait for the next iteration. Runtime waits after
pending samples, after predecessor states whose edge split is not implemented
yet, and malformed, unknown-width, or parameter-backed count expressions remain
rejected.

Pending samples before top-level runtime waits are supported for the first
path-specific sample-materialization subset when the following state can carry
the zero-count sample without changing timing, such as a drive call, an await,
or a static wait state. The positive-count path matches positive static waits
by materializing samples in the first active wait state. For counts greater
than one, a second generated wait-loop state consumes the remaining sampled
counter value without repeating the sample. The zero-count path matches
`wait 0` by materializing samples in a specialized clone of the next
state-producing clause, so no hidden sample-only cycle is added and the
original following state does not double-sample after a positive wait.
Top-level runtime waits whose zero-count successor cannot yet carry pending
samples without changing timing fail closed. The same path-specific
materialization is also supported inside `when` bodies and `switch` branches
when the selected zero-count successor can carry the pending samples. The
false path of `when`, other explicit switch cases, and implicit switch
fallthrough remain unchanged. `repeat`, `while`, and `until` bodies use the
same materialization when the zero-count body successor can carry pending
samples. Repeat loop-back/exit behavior, `while` false exits, and `until` true
exits remain unchanged. Runtime waits whose selected zero-count successor
cannot yet carry pending samples without changing timing fail closed.

Diagnostics:
- `(wait)` and `(wait N extra)` are malformed arity.
- Negative literals, non-integer literals, unknown constant names,
  actor/transaction parameter names, unknown-width dynamic scalar names,
  malformed or unknown-width dynamic expressions, and unsupported dynamic wait
  contexts fail closed.
- Waits outside transaction body contexts are invalid.

Successful schedule reports expose a bounded `transaction_waits[]` summary
rather than raw lowering internals. Each entry contains `transaction`,
`cycles`, `count_kind`, `count_source`, `entry_state`, `exit_state`,
`counter_signal`, and `counter_width`. Only positive static waits and accepted
runtime waits create entries. Static waits report `count_kind` as
`static`, `cycles` as the resolved positive integer, `count_source` as the
literal or actor constant name, and `counter_signal`/`counter_width` as JSON
null. Runtime scalar waits report `count_kind` as `runtime_scalar`; runtime
expression waits report `count_kind` as `runtime_expression` and keep the
normalized expression text in `count_source`. Both runtime forms keep `cycles`
as JSON null and expose the generated counter name/width through
`counter_signal` and `counter_width`.

### 7.7 Inline Control Flow

`(when condition body...)` is structurally validated with one scalar or
list-form condition and at least one list-form body clause before branch
expansion. It creates one decision state plus body states. The true path enters
the body, and the false path skips to the first state after the whole `when`
body. Current body support includes drive, await, sample, wait, complete,
repeat, update, shift/assemble/extract data operations, and nested `when`. Nested
repeats inside `when` bodies register the shared transaction counter width like
top-level and switch-nested repeats.

This transaction clause is distinct from the rule guard spelling
`(rule name (when condition) action...)`. In a rule, `(when condition)` is a
guard clause with no body of its own; it guards the rule actions that follow
it. The preferred rule shorthand is `(rule name condition action...)`, which
normalizes to the same public `when` field as the long guard spelling.

`(switch signal (value body...)...)` is structurally validated with one scalar
signal and one or more list-form branches before branch expansion. Each branch
must provide one scalar value and at least one list-form body clause. The
scheduler then creates one decision state with one branch per unique explicit
value. Duplicate explicit values are rejected. A switch may also contain one
fallback branch, spelled `(default body...)` or `(_ body...)`. Those spellings
are aliases and are rejected if both appear in the same switch. If no authored
fallback branch is present, the scheduler emits an implicit `.fsm`
`(default (-> next_state))` fallthrough branch to the first state after the
whole switch.

The generated `.fsm` default selector means "no explicit sibling branch
predicate matched." Downstream `.fsm` lowering expands it as the logical
negation of the OR of every explicit branch predicate, such as
`!(opcode == 0 || opcode == 1)` for a two-value switch. This preserves a real
else/default branch without asking ISF to synthesize that Boolean expression
itself, and it avoids the old invalid pattern of duplicating one explicit case
such as `=0` for fallthrough.

Current branch-body support includes drive, await, sample, wait, repeat,
update, shift/assemble/extract data operations, and nested `when`. Branch
bodies exit to the first state after the whole switch, so multi-state branches
and repeat checks do not fall through into later branch bodies.

### 7.7.1 Transaction Loops

```lisp
(while (! done)
  (drive poll)
  (await ready))

(until done
  (drive step)
  (wait 1))
```

`(while cond body...)` is a shipped pre-test transaction loop. The scheduler
emits explicit generated decision states that sample `cond` once before each
possible iteration. The entry decision makes zero iterations possible: if the
sampled condition is true, control enters the body; if it is false, control
exits to the transaction clause after the whole loop. After a body iteration,
a back-edge decision samples the same condition before choosing either another
iteration or loop exit.

`(until cond body...)` is a shipped body-first transaction loop. Control enters
the body once before the first condition sample. After the body, the scheduler
emits a generated decision state that samples `cond` once. If the sampled
condition is true, control exits. If it is false, control loops back to the
body. One or more iterations are therefore required. A pre-test "run while not
done" loop should be written as `(while (! done) body...)`, not by overloading
`until`.

Loop conditions use the same scalar or list-expression condition surface as
transaction `(when ...)` and rule guards. The condition is sampled only in the
generated decision state. It is not a continuous guard over every state inside
a multi-cycle body; once the body starts, body states run according to their
own scheduled control flow until they reach the loop check or exit path.

The shipped loop source position is top-level inside a transaction body. Loop
bodies accept the current inline body subset: named drive calls, `await`,
`sample`, `complete`, `repeat`, `update`, shift/assemble/extract data
operations, actor-owned bank `store`/`load`, nested `when`, and shipped
`(wait N)` clauses. `do`, `spawn`, `await_all`, `await_any`, `stage`,
`contract`, loops nested inside loop bodies, and loops nested under
`when`/`switch`/`repeat` remain deferred until re-entry, child lifetime, and
report semantics are specified for those combinations.

Dynamic loops are ordinary persistent hardware schedule regions, not software
processes that appear or die. They may run for data-dependent or unbounded
cycle counts. They do not create an implicit timeout. Existing actor watchdog,
transaction latency, and temporal-contract mechanisms must remain explicit and
must count loop-body cycles according to their own documented active-cycle
semantics.

Malformed loop diagnostics:
- Missing condition, missing body, empty/non-list body forms, or extra
  structural wrapper forms must fail before misleading scheduled artifacts are
  emitted.
- Unsupported body clause heads must name the unsupported construct and the
  loop kind.
- Conditions must use the same scalar/list-expression condition contract as
  other ISF guards.

Successful schedule reports expose a bounded `transaction_loops[]` summary
rather than raw lowering internals. Each entry contains `transaction`, `kind`,
`condition`, `entry_state`, `decision_states`, `body_start`, `body_states`,
`exit_state`, and `body_clause_count`.
The `condition` value is the normalized condition text used in the scheduled
`.fsm` review artifact, not a raw parser node.

### 7.8 Data Manipulation

```lisp
(set var expr)
(update var expr)
(shift_left reg bit)
(shift_right reg bit)
(shift_right reg bit (width N))
(assemble header payload crc as packet)
(extract packet as header payload crc)
(extract packet as header payload crc (widths 4 8 4))
```

Current lowering:
- `set` is the canonical explicit scalar setter. It is structurally validated
  as `(set var expr)` with one scalar target `var` and one scalar or list
  expression payload. In a transaction it emits one ordered flopped assignment
  state to `var`.
- `update` remains supported as the older transaction-local spelling for the
  same flopped transaction update behavior.
- `shift_left` is structurally validated as `(shift_left reg bit)` with scalar
  `reg` and scalar `bit`, then emits a left shift plus inserted bit.
- `shift_right` is structurally validated as
  `(shift_right reg bit [(width N)])` with scalar `reg` and scalar `bit`, then
  emits a right shift plus inserted bit. When the shifted signal has a known
  interface, sampled-source, assemble-inferred, or explicit `(width N)` width,
  the insert position uses that width. Unknown-width values now fail closed
  before scheduled `.fsm` emission instead of emitting a placeholder `WIDTH`
  expression. Explicit `(width N)` is an assertion: it may fill missing width
  evidence, but it must match any already-known width for the shifted register.
- `assemble` is structurally validated as `(assemble part... as target)` with
  one or more scalar parts and one scalar target, then emits a concat
  expression into the target variable. The private width map infers the target
  width as the sum of known part widths. When every part width is known and
  the target already has a known width, the sum must match the target width or
  lowering fails closed. Unknown part widths may still be accepted for the
  reviewable concat expression, but they are not used as width evidence.
- `extract` is structurally validated as
  `(extract word as field... [(widths N...)])` with one scalar source word and
  one or more scalar destination fields. It emits one extraction state. When
  the source word and destination fields have known widths, or when the clause
  supplies an ordered `(widths N...)` list matching the field count, fields are
  assigned exact descending slices. Unknown field widths fail closed instead
  of producing placeholder slice bounds. Explicit widths must be positive
  integers and must not conflict with already known field widths. When the
  source word width is known, the sum of field widths must match it.

The emitted shift expressions use the normal `.fsm` expression surface. Raw
`<<` and `>>`, plus `shl` and `shr` aliases, are accepted as binary operators
through SystemVerilog generation, so accepted ISF shift source is not merely a
schedule-text feature. Width alignment still matters at the surrounding
assignment boundary: a 1-bit drive actual should select a 1-bit expression such
as `tx_byte[7]` rather than relying on implicit truncation from an 8-bit word.

Width evidence is transaction-local and private to lowering today. Interface
declarations seed it, sampled aliases inherit known source widths, explicit
`shift_right` and `extract` options add local evidence, and `assemble` can
infer target width from known parts. The evidence is collected from the whole
transaction clause tree before scheduled state emission, so it is not
source-order-sensitive. Schedule reports expose positive integer `width`
metadata for inferred scheduler counters and for register storage whose ISF
width evidence is known. They also expose optional `role` metadata when the
lowerer has stable scheduler evidence for the storage purpose, such as
sampled aliases, extracted fields, ordinary data registers, completion pulses,
watchdog/latency/repeat counters, and named-drive request/payload storage.

Planned width-evidence precedence for this tree is: actor interface
declaration, operation-local explicit option, sampled-alias propagation,
structural derivation from `assemble`/`extract`, then generated scheduler
storage for existing counter families. Explicit width options are author
assertions, not force-casts: they may fill unknown facts, but they must match
already-known facts for the same name. Once an operation family is migrated by
the data-width tree, that family must fail closed instead of emitting
`WIDTH`, `HIGH`, or `LOW` placeholders for accepted source.

The migrated data-operation families now follow that rule. `extract` accepts
only exact descending slices and fails when field widths are unknown, explicit
field widths conflict with known facts, or the sum of field widths disagrees
with a known source word width. `shift_right` uses a concrete insert position
from known or explicit width evidence and fails when width evidence is missing
or contradictory. `assemble` derives a target width only from fully known part
widths and rejects known target-width mismatches. `shift_left` does not need
separate width evidence for its insertion position.

## 8. Composition Between Transactions

### 8.1 Blocking Sequence

```lisp
(do child_transaction)

(do child_transaction
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)
    (output data resp)))
```

Current lowering:
- Local `do` emits an await-shaped parent state guarded by
  `child_transaction_done`.
- Local `do` rewires the child idle state to wait on
  `child_transaction_start`.
- `do` is structurally validated as
  `(do transaction [(params (NAME value) ...)] [(bind ...)])` with one scalar
  child transaction operand and at most one `params` block plus at most one
  `bind` block before child-target resolution.
- The `child_transaction` target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- The rewired child idle state enters the first non-entry child state, so the
  child body does not need to begin with a drive state.
- The child's terminal state pulses `child_transaction_done` with `<1`, matching
  the completion-pulse contract and avoiding sticky done bits across repeated
  blocking calls.
- The parent `do` state asserts `child_transaction_start` directly.
- Parameterized `do` is a generated child activation. It emits the child as a
  separate scheduled module, creates a deterministic generated instance named
  `{parent}_{child}_do_{ordinal}`, applies static parameter overrides on the
  generated top `?fsmc` instance, asserts `{instance}_start`, and awaits
  `{instance}_done`.
- Parameterized/generated `do` port bindings use explicit generated-top
  handoffs. Input handoffs are parent-owned combinational assignments; output
  handoffs are copied under the generated instance's `done` guard. The
  generated top does not auto-fanout unrelated actor public inputs into a
  generated `do` child; authors must bind intended payload ports explicitly.
- If a plain `(do child)` targets a child transaction that is already generated
  because another activation site needs generated specialization, that plain
  `do` also uses a generated child activation instance. This keeps the parent
  from referencing a child body that was skipped from the parent scheduled
  module.

### 8.2 Spawn

```lisp
(spawn child_worker as w0)
(await_all done)
```

Current lowering:
- Spawned transactions are emitted as separate child `.fsm` files.
- `spawn` is structurally validated as
  `(spawn transaction as instance [(params (NAME value) ...)])` with one
  scalar child transaction, one scalar instance name, and at most one validated
  parameter override block before spawned child collection.
- The spawned transaction target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- Each spawned child exposes `start` as an input and `done` as an output. Named
  drive calls inside a spawned child expose drive handoff outputs such as
  `<drive>_start` and `<drive>_<param>` instead of directly exporting the
  actor output driven by that drive body.
- The parent exposes per-instance `instance_start` outputs and
  `instance_done` inputs for generated-top wiring. Each spawn state asserts
  its matching `instance_start` signal.
- `await_all` and `await_any` are structurally validated as
  `(await_all done_port)` and `(await_any done_port)` with one scalar done-port
  operand before sync-state emission.
- `await_all` waits for all collected spawned done ports using one scheduled
  transition suffix guarded by their logical AND, for example
  `(-> parent_done <(& w0_done w1_done w2_done))`.
- `await_any` emits one guard per collected spawned done port and advances when
  any one of them fires.
Focused regressions cover both synchronization forms.

Top-level generated-child instantiation is now shipped for the covered
spawn and parameterized blocking `do` fixture set. Spawn and generated `do`
parameter declaration, validation, scheduled child `+params` emission,
per-instance override preservation, and generated-top application now all flow
through the normal composition pipeline. The public contract is:

- Multi-file generated-child actors expose an explicit generated `?top` source
  over the scheduled parent module and child modules.
- The scheduled parent module keeps the actor name. The generated top uses a
  distinct deterministic name, initially `<actor_name>_top`.
- The generated top re-exports the actor public interface. Per-instance
  `instance_start`/`instance_done` handoff signals are internal top wiring, not
  public top ports.
- The scheduled parent exposes `instance_start` as an output port and
  `instance_done` as an input port for each generated instance. Each generated
  child exposes `start` as an input and `done` as an output.
- The generated top wires `parent.instance_start` to `instance.start`,
  `instance.done` to `parent.instance_done`, explicit port-binding handoffs,
  and child named-drive handoff outputs to parent per-instance handoff inputs
  using canonical `?wiring` list forms such as
  `(parent.instance_start instance.start)`.
- A spawned child returns to its `start`-guarded idle state after completion and
  must not re-enter the body until the next start pulse.
- Spawn instance names are actor-local identities and must be unique. Generated
  `do` instance names use `{parent}_{child}_do_{ordinal}` and share the same
  actor-local uniqueness rule. Multiple instances of one child transaction
  share the same child module with distinct instance names.
- Spawn and generated `do` parameter overrides are emitted on the generated
  `?fsmc` instance through the existing composition `(params ...)` override
  surface.

`spawn` is static HDL composition plus runtime activation. The generated child
instance exists for the lifetime of the generated top. Executing the spawn site
asserts the instance start path; completion only returns that same instance to
idle. Reaching the same lexical spawn again, including through future
spawn-in-repeat support, reuses the same physical instance. The scheduler must
reject or sequence any path that could start a still-busy child before its
fresh done pulse is observed.

Parameterized spawn uses one optional nested `params` block after the instance
name. Parameterized blocking `do` uses the same `params` block after the child
transaction name:

```lisp
(transaction child_worker
  (params
    (WIDTH 8)
    (LANES (8'h00 8'h00)))
  ...)

(transaction parent_main
  (spawn child_worker as w0
    (params
      (WIDTH 16)
      (LANES (8'hA5 8'h3C))))
  (do child_worker
    (params
      (WIDTH 32))))
```

The shipped parameter-binding surface covers spawn and blocking `do` generated
child activations. Child transaction parameter declarations must use unique
HDL-identifier-compatible names. Overrides must use unique names declared by
the child transaction; missing overrides use child defaults. Scalar numeric
and exact-width literal overrides are width-flexible. Aggregate/list defaults
require compatible aggregate/list override shape. Actor-local constants are
currently a wait-count source, not a parameter-override value source. Malformed
forms, duplicate generated instance names, duplicate parameters, unknown
targets, unknown override names, unsupported value shapes, and parameter
declarations on non-generated transactions fail before misleading scheduled
artifacts are emitted. The scheduled child `.fsm` carries the child
transaction defaults in a direct `+params` block, and the parent lowerer IR
preserves each generated instance's override list. The generated top emits
those overrides as `?fsmc` instance `(params ...)` blocks, so the existing
composition pipeline applies them to the generated child instances.

### 8.3 Generated Composition Schedule Report Projection

The accepted schedule-report projection for generated ISF composition is a
top-level `generated_composition` field. Successful reports keep the ordinary
transaction, storage, and DT summaries parent-scoped, while this field exposes
bounded generated-top discovery metadata for generated-child composition.

For actors without a generated composition top, `generated_composition` is
`null`. For generated-child actors, the field is an object with these bounded
keys:
- `kind`: `spawn_generated_top` when every generated child activation is spawn,
  or `activation_generated_top` when another activation kind such as blocking
  `do` participates in the generated top.
- `top_module`: generated top module name, initially `<actor>_top`.
- `top_fsm`: generated top `.fsm` basename, initially `<actor>_top.fsm`.
- `parent`: object with `module` and `scheduled_fsm` for the scheduled parent.
- `children`: array of generated child module summaries. Each child entry exposes
  `transaction`, `module`, `scheduled_fsm`, and `parameters`; parameter entries
  expose `name` and stringified `default`.
- `instances`: array of generated instance summaries. Each instance entry
  exposes `instance`, `child`, `activation_kind`, `start`, `done`,
  `parameter_bindings`, and `drive_handoffs`.

Instance `start` and `done` entries expose the parent and child port names used
by the generated top. `parameter_bindings` entries expose `name`, `source`
(`default` or `override`), and stringified `value`. `drive_handoffs` entries
expose one named drive, its request link, and one payload entry per drive
parameter with `parameter`, `child_port`, `parent_port`, and `width`.

This projection is deliberately bounded. It does not expose raw LoweringIR
records, raw composition parser objects, raw `?wiring` arrays, assignment
provenance, or private port-inference internals. It is live contract metadata
that evolves with FSMGen, not a frozen full schedule-report schema.

### 8.4 Generated Composition Diagnostics

Generated composition diagnostics must be targeted before scheduled artifacts
or generated tops become misleading. Diagnostics in this family should name the
transaction, generated instance, child transaction, parameter, or generated
handoff that failed. The current accepted diagnostic families cover malformed
spawn and `do` syntax, unknown child targets, duplicate instance names, parent
actor naming conflicts, malformed or duplicate parameter
declarations/overrides, unknown override names, aggregate/scalar shape
mismatches, parameter declarations on non-generated transactions, and generated
handoff port-name conflicts.

If an actor interface already declares a port name reserved for a generated
handoff, lowering fails before the generated top is emitted. Spawn start/done
conflicts name the transaction and spawn instance. Named-drive request
conflicts also name the drive. Named-drive payload conflicts name the drive and
payload parameter. This keeps generated-composition failures source-local
instead of letting them fall through as later composition-pipeline fallout.

## 9. Rules

```lisp
(rule always_ready ready
  (valid 1)
  (trigger main_transfer))
```

The long guard spelling remains accepted for compatibility and clarity:

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

Current lowering:
- Accepted parser output exposes rules as an array of shell entries with
  unique non-empty scalar `name`, optional `when`, and `actions` array fields.
  Duplicate, nested, empty, or otherwise non-scalar rule names are rejected
  before the parser returns an actor shell. Condition and action payload
  contents remain scheduler input and are not frozen as a public API by the
  actor-shell rule-shape metadata.
- Rule actions are structurally validated before the actor shell is returned.
  Supported action shapes are `(set port expr)`, `(port expr)`,
  `(trigger transaction)`, and `(priority over other_rule)`. The explicit
  setter and shorthand assignment shapes keep `port` scalar and allow `expr`
  to use the same scalar-or-list `.fsm` RHS expression domain as transaction
  `(set var expr)` and `(update var expr)`.
- `(trigger transaction)` targets must name a declared transaction in the same
  actor. Forward references are accepted because the parser validates trigger
  targets after the full actor body is collected; missing targets fail before
  an actor shell is returned.
- Each rule emits one non-state DT block.
- A scalar condition immediately after the rule name is the preferred shorthand
  guard, and a list-expression condition may also be used when the expression
  head is a recognized expression operator. Long-form `(when condition)`
  supplies the same scalar-or-expression guard. The parser normalizes both
  spellings to the same public `when` field. Rule-local `(when condition)` is
  not the transaction control-flow form; it has no body and guards the rule
  actions that follow it.
- Expression rule guards lower through the same `.fsm` guard-expression
  surface as authored DT guards. A FIFO fire predicate can therefore be
  written directly, for example
  `(rule push_only (& push (! pop) (! full)) ...)`, and the scheduled `.fsm`
  emits `-push_only <(& push (! pop) (! full))`.
- `(set port expr)` and `(port expr)` actions lower as flopped assignments
  inside the guarded non-state DT. They keep the existing `<-` rule
  data-assignment family and do not introduce combinational or D-input-named
  rule action operators.
- Same-target rule data writes now receive a best-effort compile-time conflict
  check before scheduled `.fsm` text is treated as valid. Two rules that drive
  the same target to incompatible values fail closed with
  `isf_conflicting_rule_writes`; compatible same-target/same-value rule writes
  remain accepted. The checker also accepts same-target rule writes when their
  rule guards contain a direct contradictory fact, such as `push` versus
  `(! push)`, `pop` versus `(! pop)`, or equality facts that require a signal
  like `occupancy` or `wr_ptr` to equal two different constants, proving that
  the assignments cannot fire in the same cycle. This disjointness proof is
  intentionally conservative; guards that are not proved disjoint still use the existing
  compatible fan-in, priority-resolution, or fail-closed conflict paths.
  Rule/drive overlap is tracked internally as
  `isf_unproven_rule_drive_overlap` with `proof_status => not_doable` because
  that compile-time proof is not doable in the current analysis.
- Rule-local `(priority over other_rule)` and actor-level
  `(priority high over low)` can resolve same-target rule/rule data conflicts
  when the priority graph selects one winner for that target. The lowerer
  suppresses the lower-priority rule assignment with the inverse of the
  higher-priority rule condition. Priority cycles fail closed with
  `isf_priority_cycle_conflict`; incomparable rules still fail closed through
  the ordinary conflict diagnostic.
- Actor-level rule-over-transaction priority can resolve the covered
  same-target data case when the rule assignment and transaction-state
  assignment use the same timing operator. The lowerer keeps the winning rule
  assignment in its guarded non-state DT and adds the inverse active rule
  condition to the transaction-state assignment. Unordered rule/transaction
  conflicts fail closed with `isf_conflicting_rule_transaction_writes`.
  Priority cycles still fail with `isf_priority_cycle_conflict`. If the
  transaction is declared higher priority than the rule, lowering fails with
  `isf_priority_transaction_winner_unsupported` because the scheduled `.fsm`
  review artifact does not yet expose state-active predicates that can safely
  guard non-state rule DT assignments.
- Generated SystemVerilog includes verification-only selector assertions for
  analyzed muxes after ISF lowers through scheduled `.fsm`. Same-value
  `LHS`/`VAL` source selectors and whole-`LHS` value selectors are checked
  with `$onehot0` under `` `ifndef SYNTHESIS``; Verilog emission stays free of
  SystemVerilog assertions. The checks are derived from backend assignment
  analysis, so they cover internal generated muxes such as `next_state` as
  well as ISF-authored data targets. Standalone DT roots keep their existing
  standalone-DT multi-drive assertions rather than receiving duplicate
  selector blocks.
- `(trigger transaction)` lowers as a `<1` one-cycle delayed pulse inside the
  guarded non-state DT to a generated per-rule/per-transaction source named
  `rule_transaction`, so a rule trigger is a pulse rather than a sticky
  flopped request bit.
- If multiple rules trigger the same transaction, the scheduled `.fsm` exposes
  each rule source separately and emits one generated combinational fan-in DT
  per target transaction. That DT drives `transaction_start` from the OR of the
  rule sources without adding another cycle.
- Parameterized rule triggers use the source shape
  `(trigger transaction (params (NAME value) ...) (bind ...))`. The lowering
  creates one static generated child activation instance per lexical
  parameterized trigger site, named
  `{rule}_{transaction}_trigger_{ordinal}`, applies overrides through the
  generated top's `?fsmc` `(params ...)` block, and preserves the current
  rule-trigger timing by routing the existing per-rule trigger source and input
  payload sources through a generated handoff DT. The rule does not wait for
  the generated child `done` handoff; the parent reads that done handoff into
  an internal observer only so the generated-top endpoint is explicit.
  Rule-trigger output bindings remain rejected.
- Scheduled `.fsm` emission writes the rule guard as the non-state DT header
  DTE, for example:

```lisp
(-always_ready <ready
  (<- (valid> 1))
  (<1 (always_ready_main_transfer 1))
)

(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

Multi-rule fan-in example:

```lisp
(-r0 <a
  (<1 (r0_work 1))
)

(-r1 <b
  (<1 (r1_work 1))
)

(-work_trigger_fanin
  (= (work_start (| r0_work r1_work)))
)
```

Malformed trigger `params` blocks fail before scheduled artifacts are emitted:
more than one `params` block on one trigger action, malformed `(NAME value)`
entries, non-HDL parameter names, duplicate override names, unknown target
parameters, shape-incompatible values, unsupported non-constant symbolic or
expression override values, and generated instance name or handoff-port
collisions are all fail-closed diagnostics. A rule trigger with output
bindings remains rejected;
runtime data must continue to use input ports and `(bind ...)`.

- Inline `(priority over other_rule)` is structurally validated by the parser,
  and `other_rule` must name a declared rule in the same actor. Forward
  references are accepted because the target check runs after the full actor
  body is collected. For same-target rule/rule data conflicts, lowering uses
  this edge as target-local priority metadata.

Separate `(priority lhs over rhs)` declarations are structurally validated by
the parser, and both `lhs` and `rhs` must name declared transactions or rules
in the same actor. Forward references are accepted. Actor-level priority
metadata is enforced for same-target rule/rule data conflicts when both
targets are rules, for priority-arbitrated `rule_slot` resources when the
endpoints are bound rules of the same resource, and for the lowerable
rule-over-transaction same-target data case. Transaction-over-rule priority,
transaction/transaction priority beyond ordinary state mutual exclusion, and
broader resource arbitration remain deferred.

`(resources ...)` entries are structurally validated as resource entries with
non-empty scalar names, an `(arbiter priority|round_robin)` subclause, and
optional `(kind ...)` and `(users ...)` subclauses. Duplicate resource names,
duplicate resource subclauses, duplicate users, malformed kinds, malformed
users, and unknown `rule_slot` users are rejected before scheduled `.fsm`
emission. `(resources ...)` is an actor-level singleton clause, so repeated
resources blocks are rejected instead of merged or overwritten. Resource
semantics use a growable catalog of shareable resource kinds. The resource name
is the author-defined instance handle; the kind says what is being shared; the
`arbiter` says how requesters are selected. The table below is the current
public registry of things ISF can name as shareable resources. It deliberately
starts small and grows only when a kind has a clear lowering path, runtime
semantics, diagnostics, report surface, and regression coverage.
The same registry is owned in code by `FSM::Support::ISFResourceCatalog` and
advertised through the machine-readable ISF public contract as
`resource_arbiter_values`, `resource_kind_values`,
`resource_kind_status_map`, `resource_kind_meaning_map`,
`enforced_resource_kind_values`, and `backlog_resource_kind_values`.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | A one-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | backlog | A group of actor outputs or LHS targets that must have one owner for a cycle. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `transaction_start` | backlog | The start/request fan-in for one transaction. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |
| `storage_port` | backlog | A shared state, register, memory, or storage-port access path. |

Backlog names are parser-recognized catalog entries, not shipped runtime
behavior. A backlog kind with bound users must fail closed until its lowering
path, runtime semantics, diagnostics, report surface, and regression coverage
ship.

The shipped resource-arbitration implementation covers priority-arbitrated
`rule_slot` users. The source shape keeps binding centralized under
`(resources ...)` by extending a resource entry with `(kind rule_slot)` and
`(users rule_a rule_b ...)` subclauses. For that covered case, each bound rule
requests the resource when its normalized rule guard is true. Rule-local
`(priority over other_rule)` and actor-level `(priority lhs over rhs)` edges
choose the active winner when the endpoints are bound rules of the same
resource. The generated grant gates the whole lowered rule DT DTE, while
existing same-target priority suppression remains assignment-local. Cycles,
incomplete ordering among potentially simultaneous bound users,
ambiguous future user namespaces, unsupported resource kinds, and
`round_robin` resources with bound users fail closed. Transaction users,
named-drive users, output-target users, child-instance users, storage-port
users, multi-capacity resources, and transaction-lifetime hold/release
semantics remain deferred.

Actor-level `(phase name property...)` and `(stage name property...)` metadata
is structurally validated by the parser and carried in the actor shell for
downstream consumers, but the scheduler does not enforce actor-level phase or
stage semantics yet. That actor-level metadata is copied into `LoweringIR`
only for bounded public report projection: schedule JSON exposes
`actor_phases[]` and `actor_stages[]` entries with each authored metadata
`name` and parser-validated list-form `body`. Generated `.fsm`, generated
composition tops, and HDL do not consume that actor-level metadata today.
Transaction-level `(phase name property...)` remains the
current pass-through state marker lowering. Transaction-level
`(stage name (input ready_signal) (output valid_signal))` is the first shipped
stage-lowering subset. It is supported only as a top-level transaction clause,
with `ready_signal` bound to an actor input and `valid_signal` bound to an
actor output. It lowers to one transaction state that drives
`valid_signal = 1` while the state is active and advances only when
`ready_signal` is true in that same cycle. Pending samples immediately before
the stage materialize before the stage so a stall does not resample every
cycle. Nested stages, stage-local `(latency ...)`, `(compute ...)`, arbitrary
stage body actions, multiple ready/valid endpoints, registered-valid variants,
and skid-buffer behavior remain fail-closed/deferred. Schedule reports expose
shipped transaction stages through `transaction_stages` entries containing the
authored transaction and stage names, `kind = ready_valid_barrier`, generated
state name, ready input, and valid output.

Transaction-level `(contract name (eventually signal (within cycles)))` is the
first shipped temporal-contract subset. It is supported only as a top-level
transaction clause, with a unique contract name per transaction, `signal` bound
to a scalar actor interface input or output, and `cycles` as a positive integer
literal. Reaching the clause emits one arm state. The checked window starts on
the next cycle and lasts for the `cycles` bound. The generated scheduled `.fsm`
artifact contains the arm state plus an always-on monitor DT with pending, age,
and sticky-fail storage. Actor reset clears the monitor storage. Seeing
`signal` while pending clears the obligation; window expiry or re-arming the
same contract while pending sets the sticky fail bit. Schedule-report
`dt_blocks` classify the generated monitor as `temporal_contract_monitor`, and
`inferred_storage` reports pending/fail as registers and age as a counter.
Schedule reports also expose shipped contracts through `temporal_contracts`
entries containing the authored transaction and contract names, `kind =
bounded_eventually`, trigger state, observed signal, cycle bound, pending,
counter, and fail signal names, overlap policy, reset policy, and assertion
projection status. Raw monitor equations and backend assertion text are not
schedule-report payloads. SystemVerilog assertion text under `` `ifndef
SYNTHESIS`` remains deferred; the scheduled monitor is already the source of
truth. Historical/free-form contract bodies, global `always` implication
forms, min/max windows, dynamic bounds, same-cycle checks, nested contracts,
expression operands, and multiple outstanding obligations remain
fail-closed/deferred.

## 10. Schedule JSON Report

`--emit-schedule-json` emits the current `Emitter::JSON` surface:

```json
{
  "source": "actor_name.isf",
  "scheduled_fsm": "actor_name.fsm",
  "clock": "clk",
  "reset": {
    "name": "rst_n",
    "kind": "async",
    "polarity": "active_low"
  },
  "watchdog": "65536",
  "actor_phases": [],
  "actor_stages": [],
  "actor_params": [],
  "actor_constants": [],
  "port_count": 0,
  "inputs": 0,
  "outputs": 0,
  "state_count": 0,
  "inferred_storage": [],
  "transactions": [],
  "transaction_waits": [],
  "transaction_loops": [],
  "transaction_stages": [],
  "temporal_contracts": [],
  "bank_accesses": [],
  "transaction_port_bindings": [],
  "dt_blocks": [],
  "generated_composition": null,
  "library_uses": [],
  "compatible_fanin_groups": [],
  "priority_resolutions": [],
  "resource_arbitration": [],
  "compile_issues": [],
  "clock_domains": [],
  "crossings": []
}
```

This is a machine-readable schedule report generated from the same lowering IR
as `.fsm` output. It now has a bounded public key-family contract through
`embedding.isf_public_interface`, but it is not a frozen full schema. Current
scalar source values such as `watchdog` are preserved as parser-carried strings
in the JSON report. Assigned scheduler counters using the generated `*_wd`,
`*_cc`, and `*_cnt` naming families are reported as `kind: counter` with the
width inferred by `LoweringIR`. Transaction summaries include the generated
state families used by the current scheduler, including control-flow and
data-operation states. DT block summaries follow deterministic lowering order:
transaction/rule-created DTs first in construction order, generated
rule-trigger fan-in DTs by transaction name, then hash-backed drive DTs
lexically by drive name.

The capability-manifest ISF public contract exposes the same policy through
`scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are audited as exact paired metadata across direct and
manifest views.
The `actor_constants` array reports actor-level ISF constants in source order.
Each entry contains `name` and stringified `value`. The values are
compile-time constants; they are not runtime ports, not overrideable params,
and not hidden scheduler registers.
The `actor_params` array reports actor-level parameter defaults in source
order. Each entry contains `name` and JSON-safe default `value`. Parameter
defaults are static specialization values, not runtime ports; activation-site,
generated-child, and reusable-library override bindings remain reported by
their existing generated-composition and library-use summary families. The
capability-manifest ISF public contract advertises this shape through
`schedule_report_actor_param_keys`.
Each `dt_blocks` entry's `assignments` value is a non-negative count of
assignment forms in the matching scheduled `.fsm` DT block, not an assignment
payload list. The capability-manifest ISF public contract advertises this shape
through `schedule_report_dt_assignments_shape`.
Each `dt_blocks` entry's `kind` value is currently `drive`,
`latency_counter`, `rule`, `rule_trigger_fanin`, or
`temporal_contract_monitor`. The capability-manifest ISF public contract
advertises this value family through `schedule_report_dt_kind_values`.
Each `inferred_storage` entry's `kind` value is currently `counter` or
`register`. Optional `role` values describe stable scheduler purpose when the
lowerer has direct evidence: `actor_storage`, `completion_pulse`,
`data_register`, `dynamic_wait_counter`, `drive_payload`, `drive_request`,
`extract_field`, `latency_counter`, `repeat_counter`, `sample_alias`,
`temporal_contract_monitor`, `transaction_port_binding`,
`trigger_done_observe`, and `watchdog_counter`.
Runtime scalar and runtime expression waits use `dynamic_wait_counter` for the
generated sampled-count storage that backs zero-bypass and decrement-loop
lowering.
Generated activation port-binding handoff storage uses
`transaction_port_binding`; generated rule-trigger completion observation uses
`trigger_done_observe`.
Temporal-contract monitor storage uses that one role for the generated
pending and sticky-fail registers plus the generated age counter; the
`temporal_contracts[]` entry remains the public summary that names each signal
and its specific contract purpose.
Optional `width` values are positive integer bit widths when present and
currently appear on declared actor-owned storage, inferred scheduler counters,
and register storage with known ISF width evidence.
The capability-manifest ISF public contract advertises this through
`schedule_report_storage_kind_values`, `schedule_report_storage_role_values`,
and `schedule_report_storage_width_shape`.
Each `transactions` entry's `states` value is an emitted-order array of
scheduled state names belonging to that transaction, and `count` is a
non-negative integer equal to that array length. The capability-manifest ISF
public contract advertises this through
`schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array is sorted lexically by transaction name, and each
transaction's `states` array keeps scheduled `.fsm` state emission order. The
capability-manifest ISF public contract advertises this through
`schedule_report_transaction_ordering`.
The `transaction_waits` array reports the shipped literal `(wait N)` surface,
actor-constant `(wait NAME)` surface, bounded runtime scalar
`(wait count_signal)` surface, and bounded runtime expression
`(wait (<op> ...))` surface, including accepted top-level, `when` body,
`repeat` body, `switch` branch, `while` body, and `until` body contexts.
Positive static waits report the authored transaction name, exact resolved
cycle count, count kind/source, entry wait state, exit state after the wait
chain, and null counter metadata. Runtime waits report the authored
transaction name, null `cycles`, `runtime_scalar` or `runtime_expression`
count kind, source signal or normalized expression text, entry/exit states,
and generated counter name/width. `(wait 0)` and symbolic waits that resolve
to zero are transparent no-ops and create no entry. The capability-manifest
ISF public contract advertises the keys through
`schedule_report_transaction_wait_keys` and the count-kind values through
`schedule_report_transaction_wait_count_kind_values`.
The `transaction_loops` array reports the shipped top-level `while`/`until`
loop subset. Each entry contains the authored transaction name, loop `kind`,
normalized `condition`, loop entry state, generated decision states, body
start, generated body states, exit state, and authored body-clause count. The
capability-manifest ISF public contract advertises the keys through
`schedule_report_transaction_loop_keys`.
The `actor_phases` and `actor_stages` arrays report parser-validated
actor-level metadata without assigning runtime semantics to it. Each entry has
the authored metadata `name` and a JSON-safe copy of the list-form `body`. The
capability-manifest ISF public contract advertises those keys through
`schedule_report_actor_phase_keys` and
`schedule_report_actor_stage_keys`.
The `transaction_stages` array reports the shipped ready/valid stage subset.
Each entry has `transaction`, authored stage `name`, `kind =
ready_valid_barrier`, generated `state`, `ready` input, and `valid` output.
The capability-manifest ISF public contract advertises the keys and kind
values through `schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.
The `temporal_contracts` array reports the shipped bounded eventual contract
subset. Each entry has `transaction`, authored contract `name`, `kind =
bounded_eventually`, `trigger`, observed `signal`, `within_cycles`,
`pending_signal`, `counter_signal`, `fail_signal`, `overlap_policy`,
`reset_policy`, and `assertion_projection`. The current `overlap_policy` is
`fail`, and the current assertion projection value is `none`; monitor logic
exists in scheduled `.fsm`, but no backend assertion text is emitted yet. The
capability-manifest ISF public contract advertises the keys, kind values,
overlap values, assertion-projection values, and reset-policy shape through the
matching `schedule_report_temporal_contract_*` metadata fields.
The reset summary's `kind` value is currently `async` or `sync`, and its
`polarity` value is currently `active_high` or `active_low`. The
capability-manifest ISF public contract advertises those value families through
`schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
Configured reset summaries are hashes with the advertised reset keys; omitted
resets are reported as JSON null. The capability-manifest ISF public contract
advertises this through `schedule_report_reset_shape`.
The `clock_domains` array is empty for legacy one-clock actors. For accepted
`(clock-domains ...)` actors, each entry exposes the domain name, default
marker, clock/reset summary, scheduled domain artifact basename, local
port/storage/transaction/rule/library/child-instance names, crossing endpoint
summaries, and bounded domain state/DT counts. For multi-domain reports, the
top-level report scope is the generated top, so top-level `state_count` is
zero and domain-local counts live in `clock_domains[]`. The `crossings` array
is empty when no crossing primitive is declared. Accepted event crossings
report source/destination domains and signals, the source ready signal,
generated CDC instance/module names, `single_outstanding_acknowledged`
policy, `none` payload policy, and generated top basename. The
capability-manifest ISF public contract advertises these bounded key families
through `schedule_report_clock_domain_*` and `schedule_report_crossing_keys`.
For ordinary single-clock reports, the top-level `inputs` and `outputs`
values count interface ports by direction, and `port_count` equals their sum.
For multi-domain reports, these counts describe the generated top's public
port scope, including domain clocks/resets plus actor interface ports.
`state_count` counts scheduled `.fsm` state blocks in the current report scope;
multi-domain generated tops have no hidden scheduled states, so their
top-level `state_count` is zero. The capability-manifest ISF public contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.
The top-level `source` and `scheduled_fsm` values are actor-derived `.isf` and
`.fsm` basenames for the current report scope; for multi-domain reports,
`scheduled_fsm` is the generated `<actor>_top.fsm` artifact. `clock` is the
actor clock signal name, or the selected default-domain clock when
`clock-domains` is present, and `watchdog` is a scalar limit when configured
or null when omitted. The capability-manifest ISF public contract advertises
this through `schedule_report_source_shape`,
`schedule_report_scheduled_fsm_shape`, `schedule_report_clock_shape`, and
`schedule_report_watchdog_shape`.
Successful reports keep `compile_issues` present as an array. Reports with no
nonfatal compile issues keep it empty; the capability-manifest ISF public
contract advertises that no-issue success shape through
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issues are projected into `compile_issues` as bounded objects
with stable `code`, `severity`, `target`, `domain`, `proof_status`,
human-readable `reason`, and capped `sources` summaries. The important current
proof status is `not_doable`, used when the scheduler is explicitly flagging
that a compile-time proof is NOT doable for a case such as rule/drive overlap.
The public contract advertises the bounded issue keys, source-summary keys,
severity values, and proof-status values. Fail-closed conflicts still produce
targeted diagnostics instead of successful schedule reports.
Rejected conflict diagnostics are regression-covered for both in-process
scheduler calls and the CLI schedule-report path. They name the stable code,
target, reason, conflicting owners, source kinds, operators, and values, and
the CLI path does not emit successful schedule JSON for rejected conflicts.
Accepted compatible fan-in metadata is emitted as a top-level
`compatible_fanin_groups` array. Each group is bounded to classifier `kind`,
`domain`, target/value facts, and source summaries; raw
`assignment_provenance`, activation proof context, assignment indexes, and
priority-suppression bookkeeping remain private `LoweringIR` internals.
The public projection reports request and pulse fan-in through their
domain-specific group kinds instead of duplicating them as generic
`same_target_value` groups.
Transaction port binding provenance is emitted as a top-level
`transaction_port_bindings` array. Each entry records the binding site
(`do`, `spawn`, or `rule_trigger`), owner, target transaction, direction role,
transaction port, actor signal when the actor side is a scalar endpoint,
formatted actor expression, width, and the bounded generated signal names that
make the scheduled `.fsm` handoff reviewable. For expression-valued input
bindings, `actor_signal` is JSON null and `actor_expression` carries the
formatted source expression. Non-applicable generated signals are JSON null.
This is provenance and review support; it is not raw assignment provenance and
it does not expose private activation proof state.
Successful priority/resource decisions are emitted as top-level
`priority_resolutions` and `resource_arbitration` arrays. A
`priority_resolutions` entry records the target plus bounded winner/loser owner
names and owner kinds for target-local suppression. A `resource_arbitration`
entry records an enforced resource's name, kind, arbiter, bound rule user, and
the higher-priority rule users that can suppress that user's grant. These
entries describe the static lowering decision; they are not per-cycle runtime
grant traces.
The CLI `--emit-schedule-json` entrypoint is expected to emit the same report as
the in-process scheduler on stdout and keep stderr clean on success.
For single-clock multi-file lowerings, that report currently describes the
parent scheduled module only. For multi-domain lowerings, it describes the
generated top and projects bounded per-domain/crossing summaries.

Schema-freeze readiness is tracked separately from the current bounded public
contract. The report is contractual today through the exact metadata advertised
by `embedding.isf_public_interface`, including top-level keys, nested
key/value families, scalar policies, ordering policies, nullability rules, and
CLI/in-process parity. It is not yet a frozen whole-tree schema. New optional
keys or new value-family members may be added only with public-contract
metadata, focused tests, and documentation in the same slice.

The remaining blockers before a whole-schema freeze are explicit: decide
whether the report needs its own schema/version field, close or deliberately
defer remaining storage-role families, define generated-name stability,
decide whether assignment provenance and multi-file child summaries stay
private or become bounded public summaries, define additive/deprecation
policy, and maintain a golden fixture matrix for every advertised branch
through both in-process and CLI report paths.

## 11. Current Regression Fixtures

Representative shipped fixtures:
- [isf/apb_requester.isf](../isf/apb_requester.isf)
- [isf/burst_reader.isf](../isf/burst_reader.isf)
- [isf/full_featured.isf](../isf/full_featured.isf)
- [isf/i2c_master.isf](../isf/i2c_master.isf)
- [isf/spawn_parent.isf](../isf/spawn_parent.isf)
- [isf/clock_domain_event_crossing.isf](../isf/clock_domain_event_crossing.isf)
- [isf/spi_master.isf](../isf/spi_master.isf)
- [isf/uart_tx.isf](../isf/uart_tx.isf)
- [isf/when_test.isf](../isf/when_test.isf)
- [isf/switch_test.isf](../isf/switch_test.isf)
- [isf/common/fifo.isf](../isf/common/fifo.isf)
- [isf/fifo_library_use.isf](../isf/fifo_library_use.isf)

The current realistic fixture matrix is tracked in
[docs/tasks/ISF-FIXTURE-COVERAGE.md](tasks/ISF-FIXTURE-COVERAGE.md). That
matrix separates baseline APB quick coverage from broader `isf`-tier fixture
coverage and records which feature families each fixture owns. The
[isf/spi_master.isf](../isf/spi_master.isf) fixture now has file-backed
schedule/HDL/strict coverage as a compact SPI-like mode-0 serial-transfer
example, not as a complete SPI protocol compliance suite. It stays in the
`isf` regression tier rather than the curated quick/smoke tier.

Realistic fixtures should use documented ISF constructs. If writing a fixture
requires an awkward workaround for ordinary hardware intent, treat that as a
language-expressiveness signal: either rewrite the fixture with a documented
construct or track the missing construct in the task tree/backlog.

ISF arity policy follows the same rule. Constructs with fixed hardware roles
should keep exact arity so malformed intent is rejected early. Examples include
`(sample port as name)`, `(complete port)`, `(spawn child as instance)`, and
known drive calls whose formal list defines positional actuals. Constructs
whose semantics are naturally list-like or associative may be variadic when
that makes the source clearer, but the construct must still have deterministic
lowering, malformed-boundary diagnostics, focused or fixture coverage, and
public documentation in the same slice. Lisp-like syntax alone is not a support
claim for arbitrary argument counts.

Focused tests:
- [t/1091-isf-parser-apb-requester.t](../t/1091-isf-parser-apb-requester.t)
- [t/1092-isf-lispish-adapter.t](../t/1092-isf-lispish-adapter.t)
- [t/1093-isf-parser-full-featured.t](../t/1093-isf-parser-full-featured.t)
- [t/1094-isf-scheduler-module-header.t](../t/1094-isf-scheduler-module-header.t)
- [t/1095-isf-scheduler-burst-reader.t](../t/1095-isf-scheduler-burst-reader.t)
- [t/1096-isf-schedule-json-report.t](../t/1096-isf-schedule-json-report.t)
- [t/1097-isf-start-signal-binding.t](../t/1097-isf-start-signal-binding.t)
- [t/1098-isf-await-any-sync.t](../t/1098-isf-await-any-sync.t)
- [t/1099-isf-repeat-data-ops.t](../t/1099-isf-repeat-data-ops.t)
- [t/1100-isf-sample-piggyback.t](../t/1100-isf-sample-piggyback.t)
- [t/1101-isf-extract-slices.t](../t/1101-isf-extract-slices.t)
- [t/1102-isf-repeat-counter-widths.t](../t/1102-isf-repeat-counter-widths.t)
- [t/1103-isf-switch-branch-exits.t](../t/1103-isf-switch-branch-exits.t)
- [t/1104-isf-when-branch-exits.t](../t/1104-isf-when-branch-exits.t)
- [t/1105-isf-size-deduplication.t](../t/1105-isf-size-deduplication.t)
- [t/1106-isf-schedule-json-counter-storage.t](../t/1106-isf-schedule-json-counter-storage.t)
- [t/1107-isf-when-body-ops.t](../t/1107-isf-when-body-ops.t)
- [t/1108-isf-schedule-json-transaction-states.t](../t/1108-isf-schedule-json-transaction-states.t)
- [t/1109-isf-await-all-sync.t](../t/1109-isf-await-all-sync.t)
- [t/1110-isf-do-child-entry-rewire.t](../t/1110-isf-do-child-entry-rewire.t)
- [t/1111-isf-sample-before-data-ops.t](../t/1111-isf-sample-before-data-ops.t)
- [t/1112-isf-public-interface-contract.t](../t/1112-isf-public-interface-contract.t)
- [t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../t/1113-isf-public-interface-contract-json-roundtrip-audit.t)
- [t/1114-isf-public-interface-contract-defensive-copy-audit.t](../t/1114-isf-public-interface-contract-defensive-copy-audit.t)
- [t/1115-isf-public-interface-cli-manifest-audit.t](../t/1115-isf-public-interface-cli-manifest-audit.t)
- [t/1116-isf-public-schedule-report-key-family-audit.t](../t/1116-isf-public-schedule-report-key-family-audit.t)
- [t/1117-isf-public-lower-result-files-audit.t](../t/1117-isf-public-lower-result-files-audit.t)
- [t/1118-isf-public-parse-source-facade-audit.t](../t/1118-isf-public-parse-source-facade-audit.t)
- [t/1119-isf-deterministic-dt-block-order.t](../t/1119-isf-deterministic-dt-block-order.t)
- [t/1120-isf-public-live-document-path-audit.t](../t/1120-isf-public-live-document-path-audit.t)
- [t/1121-isf-public-cli-schedule-report-audit.t](../t/1121-isf-public-cli-schedule-report-audit.t)
- [t/1122-isf-public-cli-outdir-lowering-audit.t](../t/1122-isf-public-cli-outdir-lowering-audit.t)
- [t/1123-isf-public-cli-hdl-generation-audit.t](../t/1123-isf-public-cli-hdl-generation-audit.t)
- [t/1124-isf-public-cli-strict-mode-audit.t](../t/1124-isf-public-cli-strict-mode-audit.t)
- [t/1125-isf-public-constructor-boundary-audit.t](../t/1125-isf-public-constructor-boundary-audit.t)
- [t/1126-isf-public-parser-method-boundary-audit.t](../t/1126-isf-public-parser-method-boundary-audit.t)
- [t/1127-isf-public-scheduler-method-boundary-audit.t](../t/1127-isf-public-scheduler-method-boundary-audit.t)
- [t/1128-isf-public-multifile-schedule-report-audit.t](../t/1128-isf-public-multifile-schedule-report-audit.t)
- [t/1129-isf-public-actor-shell-contract-audit.t](../t/1129-isf-public-actor-shell-contract-audit.t)
- [t/1130-isf-public-compile-issues-success-audit.t](../t/1130-isf-public-compile-issues-success-audit.t)
- [t/1131-isf-public-top-level-discovery-audit.t](../t/1131-isf-public-top-level-discovery-audit.t)
- [t/1132-isf-public-method-receiver-boundary-audit.t](../t/1132-isf-public-method-receiver-boundary-audit.t)
- [t/1133-isf-public-constructor-receiver-boundary-audit.t](../t/1133-isf-public-constructor-receiver-boundary-audit.t)
- [t/1134-isf-public-parse-file-path-boundary-audit.t](../t/1134-isf-public-parse-file-path-boundary-audit.t)
- [t/1135-isf-public-entrypoint-metadata-audit.t](../t/1135-isf-public-entrypoint-metadata-audit.t)
- [t/1136-isf-public-cli-option-metadata-audit.t](../t/1136-isf-public-cli-option-metadata-audit.t)
- [t/1137-isf-public-method-name-metadata-audit.t](../t/1137-isf-public-method-name-metadata-audit.t)
- [t/1138-isf-public-constructor-option-metadata-audit.t](../t/1138-isf-public-constructor-option-metadata-audit.t)
- [t/1139-isf-public-lower-result-metadata-audit.t](../t/1139-isf-public-lower-result-metadata-audit.t)
- [t/1140-isf-public-schedule-report-metadata-audit.t](../t/1140-isf-public-schedule-report-metadata-audit.t)
- [t/1141-isf-public-identity-flags-metadata-audit.t](../t/1141-isf-public-identity-flags-metadata-audit.t)
- [t/1142-isf-public-guidance-metadata-audit.t](../t/1142-isf-public-guidance-metadata-audit.t)
- [t/1143-isf-public-facade-shape-metadata-audit.t](../t/1143-isf-public-facade-shape-metadata-audit.t)
- [t/1144-isf-public-tested-by-metadata-audit.t](../t/1144-isf-public-tested-by-metadata-audit.t)
- [t/1145-isf-public-scheduled-fsm-metadata-audit.t](../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
- [t/1146-isf-public-dt-assignment-metadata-audit.t](../t/1146-isf-public-dt-assignment-metadata-audit.t)
- [t/1147-isf-public-report-dt-assignment-count-audit.t](../t/1147-isf-public-report-dt-assignment-count-audit.t)
- [t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
- [t/1149-isf-public-transaction-metadata-audit.t](../t/1149-isf-public-transaction-metadata-audit.t)
- [t/1150-isf-public-reset-metadata-audit.t](../t/1150-isf-public-reset-metadata-audit.t)
- [t/1151-isf-public-report-count-metadata-audit.t](../t/1151-isf-public-report-count-metadata-audit.t)
- [t/1152-isf-public-report-scalar-metadata-audit.t](../t/1152-isf-public-report-scalar-metadata-audit.t)
- [t/1153-isf-public-cli-success-metadata-audit.t](../t/1153-isf-public-cli-success-metadata-audit.t)
- [t/1154-isf-public-facade-return-metadata-audit.t](../t/1154-isf-public-facade-return-metadata-audit.t)
- [t/1155-isf-public-cli-strict-success-metadata-audit.t](../t/1155-isf-public-cli-strict-success-metadata-audit.t)
- [t/1156-isf-public-lower-result-file-shape-audit.t](../t/1156-isf-public-lower-result-file-shape-audit.t)
- [t/1157-isf-public-report-transaction-ordering-audit.t](../t/1157-isf-public-report-transaction-ordering-audit.t)
- [t/1158-isf-public-report-dt-kind-metadata-audit.t](../t/1158-isf-public-report-dt-kind-metadata-audit.t)
- [t/1159-isf-public-report-reset-shape-metadata-audit.t](../t/1159-isf-public-report-reset-shape-metadata-audit.t)
- [t/1160-isf-public-actor-shell-value-shape-audit.t](../t/1160-isf-public-actor-shell-value-shape-audit.t)
- [t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
- [t/1162-isf-public-actor-shell-interface-shape-audit.t](../t/1162-isf-public-actor-shell-interface-shape-audit.t)
- [t/1163-isf-public-actor-shell-transaction-shape-audit.t](../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
- [t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
- [t/1165-isf-public-actor-shell-timing-shape-audit.t](../t/1165-isf-public-actor-shell-timing-shape-audit.t)
- [t/1166-isf-public-actor-shell-rule-shape-audit.t](../t/1166-isf-public-actor-shell-rule-shape-audit.t)
- [t/1167-isf-public-actor-shell-drive-shape-audit.t](../t/1167-isf-public-actor-shell-drive-shape-audit.t)
- [t/1168-isf-rule-guard-factoring.t](../t/1168-isf-rule-guard-factoring.t)
- [t/1169-isf-rule-shorthand-guard.t](../t/1169-isf-rule-shorthand-guard.t)
- [t/1171-isf-rule-trigger-fanin.t](../t/1171-isf-rule-trigger-fanin.t)
- [t/1172-isf-rule-trigger-fanin-schedule-report.t](../t/1172-isf-rule-trigger-fanin-schedule-report.t)
- [t/1173-isf-shift-right-explicit-width.t](../t/1173-isf-shift-right-explicit-width.t)
- [t/1174-isf-extract-explicit-widths.t](../t/1174-isf-extract-explicit-widths.t)
- [t/1175-isf-contract-fail-closed.t](../t/1175-isf-contract-fail-closed.t)
- [t/1176-isf-resource-priority-boundary.t](../t/1176-isf-resource-priority-boundary.t)
- [t/1177-isf-do-child-done-pulse.t](../t/1177-isf-do-child-done-pulse.t)
- [t/1178-isf-handshake-compatibility-boundary.t](../t/1178-isf-handshake-compatibility-boundary.t)
- [t/1179-isf-phase-stage-boundary.t](../t/1179-isf-phase-stage-boundary.t)
- [t/1180-isf-unsupported-transaction-clause-boundary.t](../t/1180-isf-unsupported-transaction-clause-boundary.t)
- [t/1181-isf-rule-action-boundary.t](../t/1181-isf-rule-action-boundary.t)
- [t/1182-isf-rule-trigger-target-boundary.t](../t/1182-isf-rule-trigger-target-boundary.t)
- [t/1184-isf-child-transaction-target-boundary.t](../t/1184-isf-child-transaction-target-boundary.t)
- [t/1185-isf-transaction-name-boundary.t](../t/1185-isf-transaction-name-boundary.t)
- [t/1186-isf-rule-name-boundary.t](../t/1186-isf-rule-name-boundary.t)
- [t/1187-isf-drive-name-boundary.t](../t/1187-isf-drive-name-boundary.t)
- [t/1188-isf-interface-port-boundary.t](../t/1188-isf-interface-port-boundary.t)
- [t/1189-isf-drive-parameter-boundary.t](../t/1189-isf-drive-parameter-boundary.t)
- [t/1190-isf-rule-priority-target-boundary.t](../t/1190-isf-rule-priority-target-boundary.t)
- [t/1191-isf-actor-priority-target-boundary.t](../t/1191-isf-actor-priority-target-boundary.t)
- [t/1192-isf-singleton-actor-clause-boundary.t](../t/1192-isf-singleton-actor-clause-boundary.t)
- [t/1193-isf-drive-call-arity-boundary.t](../t/1193-isf-drive-call-arity-boundary.t)
- [t/1194-isf-drive-body-boundary.t](../t/1194-isf-drive-body-boundary.t)
- [t/1195-isf-sample-clause-boundary.t](../t/1195-isf-sample-clause-boundary.t)
- [t/1196-isf-complete-clause-boundary.t](../t/1196-isf-complete-clause-boundary.t)
- [t/1197-isf-latency-clause-boundary.t](../t/1197-isf-latency-clause-boundary.t)
- [t/1198-isf-update-clause-boundary.t](../t/1198-isf-update-clause-boundary.t)
- [t/1199-isf-shift-clause-boundary.t](../t/1199-isf-shift-clause-boundary.t)
- [t/1200-isf-assemble-clause-boundary.t](../t/1200-isf-assemble-clause-boundary.t)
- [t/1201-isf-extract-clause-boundary.t](../t/1201-isf-extract-clause-boundary.t)
- [t/1202-isf-repeat-clause-boundary.t](../t/1202-isf-repeat-clause-boundary.t)
- [t/1203-isf-await-sync-clause-boundary.t](../t/1203-isf-await-sync-clause-boundary.t)
- [t/1204-isf-child-composition-clause-boundary.t](../t/1204-isf-child-composition-clause-boundary.t)
- [t/1205-isf-switch-clause-boundary.t](../t/1205-isf-switch-clause-boundary.t)
- [t/1206-isf-when-clause-boundary.t](../t/1206-isf-when-clause-boundary.t)
- [t/1207-isf-assignment-provenance-inventory.t](../t/1207-isf-assignment-provenance-inventory.t)
- [t/1208-isf-compatible-fanin-classification.t](../t/1208-isf-compatible-fanin-classification.t)
- [t/1209-isf-static-conflict-detection.t](../t/1209-isf-static-conflict-detection.t)
- [t/1210-isf-priority-conflict-resolution.t](../t/1210-isf-priority-conflict-resolution.t)
- [t/1211-isf-runtime-selector-conflict-instrumentation.t](../t/1211-isf-runtime-selector-conflict-instrumentation.t)
- [t/1212-isf-schedule-report-compile-issues-projection.t](../t/1212-isf-schedule-report-compile-issues-projection.t)
- [t/1213-isf-schedule-report-compatible-fanin-projection.t](../t/1213-isf-schedule-report-compatible-fanin-projection.t)
- [t/1214-isf-rejected-conflict-diagnostics.t](../t/1214-isf-rejected-conflict-diagnostics.t)
- [t/1215-isf-spawn-parameter-binding.t](../t/1215-isf-spawn-parameter-binding.t)
- [t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t)
- [t/1217-isf-generated-composition-schedule-report.t](../t/1217-isf-generated-composition-schedule-report.t)
- [t/1218-isf-rule-slot-resource-arbitration.t](../t/1218-isf-rule-slot-resource-arbitration.t)
- [t/1219-isf-rule-transaction-priority.t](../t/1219-isf-rule-transaction-priority.t)
- [t/1220-isf-arbitration-schedule-report.t](../t/1220-isf-arbitration-schedule-report.t)
- [t/1221-isf-rule-expression-assignment.t](../t/1221-isf-rule-expression-assignment.t)
- [t/1222-isf-rule-expression-conflict-report.t](../t/1222-isf-rule-expression-conflict-report.t)
- [t/1223-isf-stage-lowering.t](../t/1223-isf-stage-lowering.t)
- [t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t)
- [t/1225-isf-stage-contract-schedule-report.t](../t/1225-isf-stage-contract-schedule-report.t)
- [t/1226-isf-data-width-storage-report.t](../t/1226-isf-data-width-storage-report.t)
- [t/1227-isf-schedule-report-freeze-boundary.t](../t/1227-isf-schedule-report-freeze-boundary.t)
- [t/1228-isf-spi-fixture-coverage.t](../t/1228-isf-spi-fixture-coverage.t)
- [t/1229-isf-compatibility-cli-parity.t](../t/1229-isf-compatibility-cli-parity.t)
- [t/1230-isf-library-import-resolution.t](../t/1230-isf-library-import-resolution.t)
- [t/1231-isf-library-generated-top.t](../t/1231-isf-library-generated-top.t)
- [t/1232-isf-actor-storage-declarations.t](../t/1232-isf-actor-storage-declarations.t)
- [t/1233-isf-rule-expression-guards.t](../t/1233-isf-rule-expression-guards.t)
- [t/1234-isf-disjoint-rule-writes.t](../t/1234-isf-disjoint-rule-writes.t)
- [t/1235-isf-fifo-same-cycle-update-matrix.t](../t/1235-isf-fifo-same-cycle-update-matrix.t)
- [t/1236-isf-bank-access-lowering.t](../t/1236-isf-bank-access-lowering.t)
- [t/1237-isf-fifo-library-fixture.t](../t/1237-isf-fifo-library-fixture.t)
- [t/1238-isf-fifo-library-hdl-generation.t](../t/1238-isf-fifo-library-hdl-generation.t)
- [t/1239-isf-library-catalog-contract.t](../t/1239-isf-library-catalog-contract.t)
- [t/1240-isf-transaction-port-declarations.t](../t/1240-isf-transaction-port-declarations.t)
- [t/1241-isf-transaction-port-bindings.t](../t/1241-isf-transaction-port-bindings.t)
- [t/1242-isf-port-binding-conflict-semantics.t](../t/1242-isf-port-binding-conflict-semantics.t)
- [t/1243-isf-port-binding-schedule-report.t](../t/1243-isf-port-binding-schedule-report.t)
- [t/1244-isf-wait-clause-lowering.t](../t/1244-isf-wait-clause-lowering.t)
- [t/1245-isf-transaction-loop-lowering.t](../t/1245-isf-transaction-loop-lowering.t)
- [t/1246-isf-setter-syntax.t](../t/1246-isf-setter-syntax.t)
- [t/1247-isf-clock-domain-partition.t](../t/1247-isf-clock-domain-partition.t)
- [t/1248-isf-rule-trigger-parameter-binding.t](../t/1248-isf-rule-trigger-parameter-binding.t)
- [t/1249-isf-activation-parameter-constants.t](../t/1249-isf-activation-parameter-constants.t)
- [t/1250-isf-spec-focused-test-index-audit.t](../t/1250-isf-spec-focused-test-index-audit.t)
- [t/1252-isf-actor-phase-stage-report.t](../t/1252-isf-actor-phase-stage-report.t)
- [t/1253-isf-actor-param-report.t](../t/1253-isf-actor-param-report.t)
- [t/1254-isf-temporal-contract-storage-report.t](../t/1254-isf-temporal-contract-storage-report.t)

## 12. Explicitly Deferred

- Reusable ISF library behavior beyond the shipped resolver/review-artifact,
  generated-top system binding, actor-owned fixed-storage, and expression-valued
  rule-guard/disjoint-rule/FIFO-controller-matrix/bank-access/fixed FIFO
  library fixture/catalog slices:
  standalone transaction/drive exports,
  package/imported constants beyond actor-local constants, derived parameter expressions,
  parameter-derived storage dimensions, memory-array backend emission, and
  library actors that import other libraries.
- Unconditional transaction delay beyond the shipped non-negative literal,
  actor-constant, bounded runtime scalar, and bounded runtime expression
  `(wait N)` shapes: parameter-backed counts, unknown-width expressions, and
  any remaining predecessor-edge or sample-incompatible successor splits remain
  deferred until their timing and diagnostics are implemented.
- Transaction binding surfaces beyond scalar and expression-valued `do`,
  `spawn`, and rule-trigger input bindings. Rule-trigger output bindings,
  explicit snapshot-vs-live timing selection, broader static conflict
  diagnostics, richer report metadata, and full expression width inference
  remain under `ISF-PORT-BINDING` and
  `ISF-ACTIVATION-BIND-EXPRESSIONS`.
- Transaction-local loop combinations beyond the shipped top-level
  `while`/`until` subset: nested loops, loops under `when`/`switch`/`repeat`,
  and loop bodies containing `do`, `spawn`, `await_all`, `await_any`, `stage`,
  or `contract` remain deferred until re-entry, child lifetime, and report
  semantics are specified.
- Old `(handshake ...)` semantics beyond validated ignored compatibility
  parsing.
- The removed `(assign ...)` action keyword; authored transaction uses fail
  closed with a migration-specific unsupported-clause diagnostic. It is not
  auto-mapped to `(set ...)`, `(update ...)`, `(drive ...)`, rule actions, or
  `(complete ...)` because the old keyword does not carry enough timing intent.
- Broader generated-child top instantiation surfaces beyond the covered ISF
  spawn and parameterized blocking `do` patterns. The current generated top
  covers scheduled parent/child wiring, start/done handoff, explicit
  port-binding handoffs, named-drive handoff, and spawn/generated-`do`
  parameter overrides for the shipped fixture set.
- Enforced resource arbitration beyond the shipped priority-arbitrated
  `rule_slot` case: `round_robin`, `output_bundle`, `interface_bundle`,
  `named_drive`, `transaction_start`, `child_instance`, `storage_port`,
  multi-capacity resources, dynamic resource names, and transaction lifetime
  ownership remain deferred.
- Priority resolution beyond the currently shipped same-target rule/rule
  data-conflict case, rule-over-transaction data-conflict case, and
  resource-level bound-rule grant case.
- Alternate rule assignment operators beyond the shipped flopped rule
  `set`/shorthand assignment family.
- Transaction `(stage ...)` forms beyond the shipped top-level ready/valid
  barrier: nested stages, stage-local latency/compute bodies, multiple
  endpoints, registered-valid variants, and skid buffers remain deferred.
- Temporal `(contract ...)` forms beyond the shipped top-level bounded
  eventual subset.
- Rich storage-class optimization in schedule reports.
- Broad aggregate/record width inference beyond the explicitly documented ISF
  data-operation evidence model.
- Treating the schedule JSON as a fully frozen public schema beyond the bounded
  key families advertised by `embedding.isf_public_interface`.
