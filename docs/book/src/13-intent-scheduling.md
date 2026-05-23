# Intent Scheduling Format (`.isf`)

The Intent Scheduling Format abstracts cycle counting away from the author.

You describe **what** happens — the compiler infers **when** and produces
explicit cycle-accurate `.fsm`.

```text
IAL1 .isf → LoweringIR → Emitter::FSM → IAL0 .fsm → SystemVerilog / Verilog
                    → Emitter::JSON → Schedule Report
```

## Intent Abstraction Layers

FSMGen treats explicit `.fsm` as **Intent Abstraction Layer 0** (`IAL0`).

Layer 0 is still an abstraction above HDL, but it is the cycle-authored review
artifact: DTs, assignment operators, state and non-state regions, mux-selector
semantics, and exact runtime behavior are visible there.

Current `.isf` constructs form **Intent Abstraction Layer 1** (`IAL1`).

Layer 1 describes scheduling intent: transactions, rules, drives, samples, waits,
repeats, child calls, spawned child activation, and constraints.

The Layer 1 contract is that lowering produces reviewable Layer 0 `.fsm` unless a targeted
diagnostic rejects the construct first.

Higher layers are intentionally reserved, not assumed.

A future `IAL2` would
need its own semantic level, such as reusable protocol-level intent objects
(`APB read transaction`, `AXI burst`, and similar) or platform/resource mapping
decisions above individual transactions.

It should not be introduced for
aliases, macros, syntax sugar, or wrappers that have no distinct runtime model.

Any future layer must lower through the same chain: clear source semantics,
clear lower-layer mapping, and clear runtime behavior.

## Design Principles

- **No register vocabulary**. You work with variables, ports, and expressions.
  The scheduler decides storage class (wire, flop, counter).
- **No magic merging**. One `(drive ...)` = one cycle. Timing is predictable.
- **Handshake-free activation**. `(on port)` fires when the port is true AND
  the actor can accept. The ready side (`can_accept`) is implicit.
- **Variables are first-class**. `(sample ...)`, `(update ...)` — just like
  programming language variables. The scheduler handles persistence.
- **Constants are structural**. Actor-level `(constants ...)` are compile-time
  symbols for lowering decisions and emitted `.fsm` `+constants`; they are not
  runtime ports and not overrideable `params`.
- **Parameters are specialization defaults**. Actor-level `(params ...)`
  values emit as scheduled `.fsm` `+params` and schedule-report
  `actor_params[]`; scalar defaults and aggregate/list default leaves may use
  enum members, and they are not runtime payload wires. Generated
  activation-site scalar parameter overrides and aggregate/list override leaves
  may also use enum members, which resolve to literal generated-top bindings.
  Actor-local scalar parameter defaults that resolve to non-negative integer
  literals may also be used as static `(wait NAME)` counts in the owning
  actor schedule.
- **Every construct has semantics**. A construct is not considered shipped just
  because the parser accepts it. It needs a documented lowering path into
  scheduled `.fsm`, a runtime meaning in terms of cycles, activation, storage,
  and conflicts, targeted diagnostics for unsupported forms, and regression
  coverage for the accepted behavior.
- **Programming-language shape, RTL meaning**. ISF intentionally borrows
  familiar control-flow shape for transactions, including existing `when`,
  `repeat`, `wait`, `while`, and `until` forms. That source shape must never
  hide the hardware contract: every accepted construct still lowers to
  explicit scheduled `.fsm` states, decision points, counters, handshakes, or
  DTs.
- **Arity follows intent**. Forms with fixed hardware roles keep exact arity so
  malformed source fails early. Forms whose meaning is naturally list-like or
  associative may be variadic when that improves expressiveness, but only with
  deterministic lowering, malformed-boundary diagnostics, tests, and public
  documentation.
- **Compile-time issues are explicit**. Parser and lowering failures are raised,
  and the schedule report carries a `compile_issues` field. Broader conflict,
  deadlock, and resource diagnostics are still being expanded.

## Quick Example

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65535)

  (interface
    (input  start)
    (output done)
    (input  req_addr  (width 32))
    (output PADDR   (width 32))
    (input  PREADY))

  (drive (psel val)   (PSEL val))
  (drive (penable val) (PENABLE val))

  (transaction apb_transfer
    (on start
      (sample req_addr as addr))
    (drive setup_phase)
    (drive penable 1)
    (await PREADY)
    (complete done)
    (latency (min 2) (max 16))))
```

Latency bounds can use named actor constants or actor-local scalar parameter
defaults when the values are static:

```lisp
(actor bounded_worker
  (constants
    (MIN_LAT 2)
    (MAX_LAT 16))
  (interface
    (input start)
    (output done))
  (transaction step
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max MAX_LAT))))
```

The actor parameter form uses the same lowering path:

```lisp
(actor parameter_bounded_worker
  (params
    (MIN_LAT 2)
    (MAX_LAT 5'd16))
  (interface
    (input start)
    (output done))
  (transaction step
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max MAX_LAT))))
```

The scheduler resolves `MIN_LAT` and `MAX_LAT` before emitting the existing
latency counter logic. The generated `.fsm` contains the resolved integer
guard and timeout values, while `actor_constants[]` or `actor_params[]` still
reports the authored actor-local declaration. Transaction parameters, runtime
signals, expressions, unknown symbols, zero-valued constants, and zero-valued
or non-scalar actor parameters remain invalid latency bounds.

## Pipeline

```
ISF Source (.isf)
    │
    ▼
FSM::Adapter::ISF     ← Lispish parser
    │
    ▼
FSM::Scheduler::ISF::LoweringIR   ← typed IR
    │
    ├──► Emitter::FSM   → .fsm text → fsmgen → SystemVerilog
    └──► Emitter::JSON  → schedule report
```

The schedule report is generated from the same IR as the `.fsm` text.

The current APB report shape is regression-covered.

The bounded downstream-facing
ISF API contract is advertised through `--capability-manifest` at
`embedding.isf_public_interface` and described in
[docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](../../ISF_PUBLIC_INTERFACE_CONTRACT.md).

That contract's `live_document_paths` metadata advertises the full Intent
Scheduling book chapter set from [Summary](SUMMARY.md), plus the canonical
[Feature Backlog](14-feature-backlog.md) and
[Reference Map](90-reference-map.md), so downstream consumers can discover the
same user-facing ISF documentation surface from the manifest.

The self-contained SPECFORGE-style integration handoff is
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
and is included later in this book as the downstream integration chapter.

It must stay synchronized with the live spec, this book, public contract,
manifest metadata, tests, and implementation behavior.

That contract is live documentation: it evolves in the same slice as public ISF
parser, scheduler, CLI, lower-result, or schedule-report changes, and those
feature slices must move the matching public contract and manifest audit tests
with the implementation.

The public adapter and scheduler constructors reject malformed option lists and unsupported
option names, require exact class invocants, and currently accept only `debug`.

The parser facade validates method receivers before private internals are used,
then validates
`parse_file(...)` and `parse_source(...)` argument counts and defined-scalar
shape before private parsing begins; `parse_file(...)` also requires a readable
`.isf` file path.

The scheduler facade validates method receivers and the
public actor shell before calling private LoweringIR, and the manifest
advertises the required `actor_name`, `transactions`, and `interface` shell keys
plus their public value shapes without freezing the full raw actor hash.

The current parser handoff also advertises a bounded `interface` subshape:
`inputs` and `outputs` arrays whose port entries expose unique non-empty scalar
`name` and positive integer `width`, with omitted source widths normalized to
`1`.

Duplicate port names across either direction are rejected before
actor-shell return.

It also advertises a bounded transaction-entry shell: `transactions` entries expose
unique non-empty scalar `name` and a `clauses` array while the clause payload
contents remain private scheduler input.

Duplicate transaction names are
rejected before actor-shell return.

It also advertises `actor_name` as the
non-empty scalar identifier preserved from the ISF actor root.

Current actor timing handoff metadata is bounded too: omitted legacy
single-clock actor timing defaults to clock `clk`, async active-low reset
`rst_n`, and watchdog `65535`; with `clock-domains`, `clock` and `reset`
expose the selected default-domain timing, and reset is null only when that
domain omits reset.

Rule entries are bounded as unique non-empty scalar
`name`, optional `when`, and `actions` array shells while rule payload contents
remain private scheduler input.

Duplicate rule names are rejected before
actor-shell return.

Drive definitions are bounded as a drive-name-keyed hash whose
entries carry `params` and `body` arrays while drive body payload contents
remain private scheduler input.

Duplicate drive names are rejected before
actor-shell return instead of overwriting an earlier drive body.

Parameterized drive declarations also reject duplicate parameter names before actor-shell
return.

The facade-shape metadata for those
receiver, argument, path, and actor-shell boundaries is audited as exact across
direct and manifest views, including bounded scalar diagnostics for public
facade boundary failures.

The manifest also advertises the public facade
return containers: parser facades return scheduler-consumable actor hashes,
`lower(...)` returns the bounded lower-result hash, and `report(...)` returns
schedule-report JSON.

Assigned scheduler counters in the
`*_wd`, `*_cc`, and `*_cnt` naming families are reported as `counter` storage
with the width inferred by the lowering IR.

The advertised contract object is
JSON-round-trip audited so downstream tooling can consume the manifest metadata
as portable discovery data, and defensive-copy audited so caller mutation does
not pollute later contract builds.

It is live, not a frozen API schema; exact
audits describe the currently advertised surface.

Its identity and stability
metadata plus its
top-level discovery list are audited as exact across direct and manifest views,
and its advertised
entrypoint, CLI option, method-name, and constructor-option lists are audited as
exact and duplicate-free.

Its lower-result and schedule-report discovery
metadata are audited as exact, as is the downstream guidance list that explains
the current bounded-public stance.

Its `tested_by` provenance list is also
audited as exact repo-local metadata.

CLI success-shape metadata is audited for
the schedule JSON, `--outdir`, plain HDL-generation, and accepted strict
HDL-generation paths.

Both capability-manifest CLI spellings are audited to emit the same ISF contract
payload.

The current APB schedule report is also checked against the advertised
public key families, and successful reports advertise and keep an empty
`compile_issues` array when no nonfatal issues exist.

Schedule reports carry `schema_version: 1` as a payload version separate from the
`embedding.isf_public_interface` contract metadata version.

Report evolution is additive only when new keys or value-family members are advertised in the
public contract metadata and covered by focused tests and docs in the same
slice; removing, renaming, changing type, or changing semantics requires a
`schema_version` bump plus migration or deprecation documentation.

Nonfatal conflict issues now project into `compile_issues` as bounded objects with stable code/severity,
target/domain, `proof_status`, reason text, and capped source summaries.

Accepted fan-in groups now project as bounded `compatible_fanin_groups`
entries.

Successful priority and resource arbitration decisions now project as
bounded `priority_resolutions` and `resource_arbitration` entries that describe
static lowering decisions, not per-cycle runtime traces.

Transaction port bindings now project as bounded `transaction_port_bindings` entries with
binding site, owner, target transaction, port role/name, scalar actor signal
where applicable, formatted actor expression, width, and generated handoff
signal names where applicable.

Raw assignment provenance, private assignment indexes, and activation proof internals remain
private.

Public substitutes are the bounded source summaries in
`compile_issues[]`, compatible fan-in facts in `compatible_fanin_groups[]`,
priority/resource summaries in `priority_resolutions[]` and
`resource_arbitration[]`, binding summaries in `transaction_port_bindings[]`,
aggregate access summaries such as `bank_accesses[]`, and counts such as
`dt_blocks[].assignments`; the report does not serialize raw assignment lists.

Parent schedule reports also do not embed recursive child reports.

Multi-file review stays bounded to the lower-result `files` map, the named generated
artifacts, `actor_network`, `generated_composition`, `library_uses[]`, and
`clock_domains[]` / `crossings[]`.

Shipped transaction stages now project into `transaction_stages` with authored names, generated
state, and ready/valid endpoints.

Shipped bounded eventual contracts project
into `temporal_contracts` with trigger state, observed signal, cycle bound,
generated storage signal names, reset policy, overlap policy, and assertion
projection status.

The current projection value is
`systemverilog_sticky_fail`: SystemVerilog HDL checks the generated sticky
fail bit under `` `ifndef SYNTHESIS``, while Verilog output stays
assertion-free.

Monitor equations and backend assertion text remain private
report internals.

The lower-result `files` map is checked for both
single-file and multi-file lowering, including scheduled `.fsm` basename keys
and matching scheduled-text roots.

The in-memory `parse_source(...)` facade is
also checked against `parse_file(...)` on a real fixture.

APB DT block order
is locked across generated `.fsm` text and schedule-report `dt_blocks` so
hash-backed drive definitions do not create review-artifact churn; the manifest
also advertises the DT ordering policy, and that scheduled-artifact ordering
metadata is audited as exact.

Rule-trigger fan-in schedule reports are also
covered so generated `rule_trigger_fanin` DTs and one-bit trigger-source
storage stay visible to downstream consumers.

DT selector logic remains
combinational; assignment families decide the selected target behavior:
`=` drives combinational mux outputs, `<-` and `<=` drive sequential/flopped
targets, and `<1` requests a one-cycle delayed pulse whether they appear in
state or non-state DT blocks.

The manifest advertises those operator families
through `dt_assignment_operator_family_map`.

Rule guards lower through non-state DT DTE headers in scheduled `.fsm` review
artifacts, so the guard activates the whole rule DT once instead of being
repeated on every action.

Generated names in schedule reports and generated artifacts are deterministic
for the same source and FSMGen version and may be used for report-local or
artifact-local joins when a public field explicitly references the same name.

They are not a semantic string grammar; downstream consumers should use
bounded metadata fields such as owner, role, kind, instance, binding, storage
role, and generated-composition summaries instead of parsing generated name
spelling.

Schedule-report `dt_blocks`
`assignments` values are assignment counts, not payload lists, and the manifest
advertises that shape through `schedule_report_dt_assignments_shape`.

Schedule-report DT `kind` values are currently `drive`, `latency_counter`,
`rule`, `rule_trigger_fanin`, and `temporal_contract_monitor`, and the
manifest advertises that family through `schedule_report_dt_kind_values`.

Inferred-storage `kind` values are `counter` or `register`, and optional
`role` values describe stable scheduler purpose when evidence is known.

The current role family is `activation_done_handoff`,
`activation_start_handoff`, `actor_storage`, `completion_pulse`,
`data_register`, `dynamic_wait_counter`, `drive_payload`, `drive_request`,
`extract_field`, `latency_counter`, `repeat_counter`,
`rule_trigger_payload_source`, `rule_trigger_source`, `sample_alias`,
`temporal_contract_monitor`, `transaction_port`, `transaction_port_binding`,
`trigger_done_observe`, and `watchdog_counter`.

Runtime dynamic waits use
`dynamic_wait_counter` for generated sampled-count storage.

Rule-trigger source pulses use `rule_trigger_source`, and per-input trigger payload-source
storage uses `rule_trigger_payload_source`.

Generated activation start/done
handoff storage uses `activation_start_handoff` and
`activation_done_handoff` when those one-bit generated handoff signals appear
in `inferred_storage[]`.

Generated activation port-binding handoffs use
`transaction_port_binding`, and generated rule-trigger completion observation
uses `trigger_done_observe`.

Transaction-local port storage uses `transaction_port` when a declared port is
materialized in the scheduled `.fsm` review artifact.

Temporal-contract pending/fail registers and age counters share the
`temporal_contract_monitor` role; `temporal_contracts[]` names the specific
pending, counter, and fail signals for each contract.

Optional positive integer `width` values belong to declared actor-owned storage, inferred
counters, and register storage with known ISF width evidence.

Declared typed actor-owned storage may also expose optional `type` and `type_kind` summaries;
the full type shape remains in the scheduled `.fsm` `+types`/`+size` review
artifact.

Transaction summaries expose emitted scheduled-state names in `states`, and
`count` equals that array length; transaction summaries are sorted lexically by
name while each `states` array keeps scheduled `.fsm` state emission order.

Transaction stage summaries advertise `ready_valid_barrier` as their current
kind, and temporal contract summaries advertise `bounded_eventually`, `fail`
overlap policy, and `systemverilog_sticky_fail` assertion projection as their
current value families.

Reset summaries advertise `async`/`sync`
kind values and `active_high`/`active_low` polarity values. Configured and
defaulted legacy single-clock resets report as hashes; reset is JSON null only
when a selected default clock-domain omits reset.

Interface count summaries count input and output ports by direction for single-clock reports;
multi-domain reports count generated-top public ports including domain
clocks/resets and actor interface ports.

`state_count` counts scheduled `.fsm`
state blocks in the current report scope; multi-domain generated-top reports
use zero and put domain-local counts in `clock_domains[]`.

Report `source` and
`scheduled_fsm` are actor-derived basenames, `clock` is the actor clock signal
or selected default-domain clock, and omitted legacy single-clock clocks report
as `clk`. `watchdog` is scalar after parser defaults; omitted watchdog clauses
report as `65535`, and actor-level watchdog constants or actor scalar
parameters report as their resolved positive integer while the declaration
remains visible in `actor_constants[]` or `actor_params[]`.

The ISF live-document path list is
audited across direct and manifest views so recovery pointers stay repo-local
and present.

The public `--emit-schedule-json` path is audited to emit the same
report as the in-process scheduler with clean stderr.

The public `--outdir`
path is audited to write multi-file scheduled `.fsm` artifacts matching the
in-process lower-result file map.

Single-clock multi-file schedule reports are
currently parent-scoped, and multi-domain reports describe the generated top
while projecting bounded domain/crossing metadata through `clock_domains[]`
and `crossings[]`.

That scope is advertised in the manifest.

Reusable library actor uses now project through a bounded `library_uses` schedule-report array
with library/export/instance identity, generated child artifact names,
parameter source/value summaries, and explicit binding summaries.

The lower-result `files` map can include specialized library-child scheduled
`.fsm` artifacts and a generated top that wires library actor instances through
the normal composition/HDL path.

Same-name clock/reset bindings can be omitted when the parent and child clock
names match and the reset name/kind/polarity matches. FSMGen records the
inferred binding in the schedule report and uses system-port auto-wiring.

Differently named reusable-actor clock/reset bindings emit
explicit generated-top links to the child system ports, for example
`(clk rx.lib_clk)`; the child actor still owns reset kind and polarity.

This is signal-name remapping inside the one-clock library-binding model, not
clock-domain-crossing support.

Multi-clock, asynchronous, and interacting
clock domains use the actor-scoped named-domain source model tracked in
[ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md).

The parser now accepts
that metadata and the scheduler validates an internal domain partition, while
public multi-domain `lower(...)` now emits one normal single-clock scheduled
`.fsm` artifact per declared domain plus a generated top that wires domain
modules and explicit CDC child interfaces for accepted event crossings.

Public `report(...)` now exposes those domain artifacts and accepted event crossings
in schedule JSON, and plain HDL generation for accepted event-crossing actors
now emits the generated top plus concrete acknowledged-event CDC child modules
for accepted crossings on SystemVerilog/Verilog-family targets when each
emitted domain artifact satisfies the current scheduled `.fsm` clock/reset HDL
contract.

The file-backed `isf/clock_domain_dual_event_crossing.isf` fixture now covers two
opposite-direction event crossings in one top, proving repeated CDC child
generation without adding payload or ordering semantics.

Direct cross-domain reads, writes, triggers, activations, bindings, and multi-domain
drive reuse remain illegal unless a shipped CDC primitive or protocol actor
owns the crossing semantics.

The plain single-clock `file.isf` CLI path is audited to reach generated HDL with clean
stderr, including when the advertised `--strict` flag is present.

Transaction summaries include the generated state families used by the current scheduler, including
control-flow and data-operation states.

Transaction-local `while` and `until`
loops now project through bounded `transaction_loops` schedule-report entries
with transaction name, loop kind, normalized condition text, generated decision
states, body start, body states, exit state, and body clause count.

## Current Limitations

The consolidated backlog for deferred user-visible work is
[Feature Backlog](14-feature-backlog.md).

The closed shipped surface for ISF
type aliases, enum members, aggregate storage carriers, scalar aggregate
leaves, examples, lowering artifacts, diagnostics, and explicit deferrals is
[Types, Enums, And Aggregates](13j-type-enum-aggregate.md).

The ISF-specific current limitations are:

- Reusable library imports currently ship the resolver/review-artifact slice:
  actor-scoped `(imports ...)`, `(use ...)`, exported actor resolution,
  use-site parameter and binding validation, specialized child scheduled
  `.fsm` artifacts, generated top wiring for same-name system ports, HDL
  reachability for the covered generated-top path, bounded `library_uses`
  report metadata, actor-owned fixed storage declarations, and
  expression-valued rule guards for direct fire predicates, plus a
  conservative disjoint-rule proof for same-target FIFO-style rule writes,
  and pointer-selected `(store <bank-name> <index> <value>)` / `(load
  <bank-name> <index> as <target>)` access for actor-owned banks.

  The checked-in `isf/fifo_data_path.isf` datapath fixture now proves that
  store/load surface through file-backed strict schedule JSON parity,
  scheduled `.fsm` structure, and plain plus strict HDL generation.

  The checked-in `isf/fifo_controller.isf` fixture separately proves the
  controller-only occupancy/full/empty and pointer-update matrix through the
  same strict schedule JSON and HDL handoff paths without claiming data-bank
  storage or `data_out` transfer behavior.

  The first reusable FIFO fixture is now shipped as `isf/common/fifo.isf`,
  with `isf/fifo_library_use.isf` proving the file-backed import/use source.

  It is fixed to `DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`,
  and covers push-only, pop-only, simultaneous push+pop, idle cycles,
  pointer-selected bank access, 2-bit pointer wrap, occupancy values 0
  through 4, and full/empty derivation.

  It also reaches generated-top SystemVerilog through the CLI.

  The promoted fixture regression also proves strict schedule JSON parity,
  strict `--outdir` emission of the importer, specialized child, and
  generated-top scheduled `.fsm` artifacts, fixed parameter and binding
  provenance in `library_uses[]`, and both plain and strict generated-top HDL
  generation.

  Reusable library clock/reset bindings now support parent/child name
  remapping through explicit generated-top links.

  That remapping is a single-clock-domain name binding only.

  Actor top-level interface widths, actor-owned scalar storage widths, and
  actor-owned bank widths may use actor-local scalar parameter defaults that
  resolve to positive integers. Use-site FIFO interface shape, bank depth,
  generated-top respecialization, arbitrary-depth generation beyond the first
  `DEPTH=4` fixture, automatic non-zero reset values, standalone
  transaction/drive exports, package/imported constants beyond actor-local
  constants, derived parameter expressions, and nested library imports remain
  backlog work.
- `(do ...)` and `(spawn ...)` targets must resolve to declared same-actor
  transactions before scheduled `.fsm` emission. They bind named start/done
  signals in scheduled `.fsm`. Spawn and blocking `do` parameter declaration,
  validation, child `+params` emission, per-instance override preservation, and
  generated-top application are shipped for the static `(params ...)` surface,
  including actor-local constants as resolved static override values.
  Actor/transaction parameter values, runtime-signal values, arbitrary
  expressions, and richer generated-child surfaces remain backlog work.
- Transaction-local `(ports ...)` declarations are parser-public metadata and
  can use positive literal widths or actor-local scalar parameter defaults
  that resolve to positive integers. They can be bound at activation sites
  with scalar, literal, or list-expression input `(bind ...)` sources. `do`
  supports input and output bindings in the parent await state. `spawn`
  supports input and output bindings through hidden generated-top handoffs and
  parent binding DTs. Rule `trigger` supports input bindings through per-rule
  payload source signals before trigger fan-in. Bindings are direction- and
  known-width-checked, actor input writes are rejected, actor output readback
  is rejected, and rule-trigger output bindings plus explicit
  snapshot-vs-live timing selection remain backlog.
- Width-bearing actor interface ports, transaction-local ports, and
  actor-owned storage entries may use scalar type aliases through `(type
  NAME)`, mutually exclusive with `(width N)` or `(width PARAM)`.

  Actor-owned storage variables may also use packed `list` or `record`
  aliases as whole-root aggregate carriers.

  Local aliases come from actor-local `(types ...)`; package-qualified
  aliases come from existing `.fsm` packages imported with `(imports (package
  NAME) ...)`.

  Lowered scheduled `.fsm` preserves `+types`, `+import`, typed `+size`
  entries, and embedded package roots.

  Actor-local `(enums ...)` are preserved as `+enums` declaration artifacts.

  Actor constants may use local enum members such as `mode.BUSY` or package
  enum members such as `shared.mode.BUSY`; those constants preserve the
  authored token in `+constants` and schedule reports while resolving to
  non-negative integer values for static waits and existing static
  activation-parameter overrides.

  Scalar actor parameter defaults, scalar leaves inside actor aggregate/list
  parameter defaults, generated child transaction scalar parameter defaults,
  scalar leaves inside generated child transaction aggregate/list parameter
  defaults, direct transaction `set` RHS scalar values, scalar operands
  inside transaction `set` RHS expressions, transaction
  `when`/`while`/`until` condition expression operands, direct transaction
  `when`/`while`/`until` scalar conditions, transaction `switch` branch
  values, scalar rule assignment RHS values and scalar operands inside rule
  assignment RHS expressions, scalar operands inside rule guard expressions,
  scalar drive body RHS values and scalar operands inside drive body RHS
  expressions, and named drive-call scalar actual values may also use local
  and package-qualified enum members.

  Drive-call actual expressions may use enum members as scalar operands too,
  inline drive assignment RHS scalar values and scalar operands inside inline
  drive RHS expressions may use enum members, and scalar activation parameter
  overrides for spawn, generated blocking `do`, and rule `trigger` may use
  enum members as static specialization values.

  Scalar leaves inside those activation aggregate/list parameter override
  values may use enum members too.

  Reusable-library use-site parameter overrides may also use enum members as
  scalar values or scalar leaves inside compatible aggregate/list override
  values; those use-site enum members resolve to literal generated-top
  bindings and `library_uses[]` report values.

  Transaction `switch` selectors and branch values may use enum members;
  dotted enum selectors lower through computed `.fsm` selector syntax such as
  `?(mode.BUSY)`.

  Direct transaction `when`/`while`/`until` conditions may also use local or
  package-qualified enum members.

  For example, `(when mode.BUSY (set fire 1))`, `(while mode.BUSY (set busy
  1))`, and `(until shared.mode.BUSY (complete done))` are accepted as
  standalone scalar enum conditions.

  They lower through computed `.fsm` selector syntax, so the review artifact
  uses selectors such as `?(mode.BUSY)` or `?(shared.mode.BUSY)`.

  Enum members also remain valid as scalar operands inside condition
  expressions, for example `(when (== mode_in mode.BUSY) (set fire 1))`.

  Rule guards may also use local or package enum members directly, either in
  shorthand form `(rule fire_when_busy mode.BUSY ...)` or long-form `(rule
  fire_when_busy (when shared.mode.BUSY) ...)`.

  These standalone enum rule guards lower to the non-state DT header guard,
  such as `<mode.BUSY` or `<shared.mode.BUSY`, and strict HDL generation
  accepts that review artifact.

  Transaction `set` RHS clauses may read scalar aggregate leaves from
  declared aggregate storage carriers directly or as operands inside
  transaction `set` RHS expressions, transaction `when`/`while`/`until`
  conditions may read scalar aggregate leaves directly or as operands inside
  condition expressions, and direct transaction `set` targets may write
  scalar aggregate leaves on those same carriers.

  Direct aggregate condition leaves lower through computed `.fsm` selector
  syntax.

  Transaction `switch` selectors and branch values may also read scalar
  aggregate leaves; aggregate selectors lower through computed `.fsm`
  selector syntax such as `?(frame.mode)` or `?(lanes[1])`.

  Rule assignment scalar RHS values and scalar operands inside rule
  assignment RHS expressions may also read scalar aggregate leaves from those
  carriers, and rule assignment targets may write scalar aggregate leaves
  from those carriers.

  Rule guard scalar values and expressions may read scalar aggregate leaves
  too, for example `(rule fire_when_flag frame.flag ...)` or `(rule
  fire_when_lane (when lanes[1]) ...)`; standalone aggregate rule guards
  lower to non-state DT header guards such as `<frame.flag` or `<lanes[1]`.

  Named drive body scalar RHS values and scalar operands inside RHS
  expressions may read scalar aggregate leaves from those carriers, and named
  drive body targets may write scalar aggregate leaves on those carriers.

  Named drive-call scalar actual values and operands inside actual
  expressions may also read scalar aggregate leaves from those carriers.

  Inline drive assignment scalar RHS values and operands inside RHS
  expressions may read scalar aggregate leaves too, and inline drive targets
  may write scalar aggregate leaves on those carriers.

  Enum members in expression operator position, set targets, rules outside
  scalar trigger parameter overrides, rule guard or transaction condition
  expression operator position, rule assignment expression operator position,
  drive targets, drive body RHS expression operator position, inline drive
  assignment RHS expression operator position, drive-call expression operator
  position, and other non-shipped contexts remain backlog, as do aggregate
  paths outside transaction `set` RHS values, direct transaction `set`
  targets, transaction condition scalar values/expression operands,
  transaction `switch` selectors/branch values, rule assignment target
  tokens, rule assignment RHS values/expression operands, rule guard scalar
  values/expression operands,

  drive target tokens, or drive body RHS scalar values/expression operands,
  inline drive target tokens, inline drive assignment RHS scalar
  values/expression operands, or drive-call actual scalar values/expression
  operands, subaggregate operands/updates, and aggregate
  interface/transaction/bank carriers.
- `(resources ...)` is structurally validated by the parser and now has one
  enforced resource kind: `rule_slot`, a one-cycle mutual-exclusion slot for
  rule users under the `priority` arbiter.

  Future kinds such as `output_bundle`, `interface_bundle`, `named_drive`,
  `transaction_start`, `child_instance`, and `storage_port` remain backlog
  until their lowering contracts are explicit.

  The accepted `round_robin` value remains parser metadata until round-robin
  lowering ships.

  The parser and `embedding.isf_public_interface` contract share the same
  resource catalog, including the current status and meaning of each kind.

  `(priority ...)` is structurally validated and currently enforced for
  same-target rule/rule data conflicts, priority-arbitrated `rule_slot`
  resources, and the lowerable rule-over-transaction same-target data case.

  Transaction-over-rule priority remains deferred because scheduled `.fsm`
  review text does not yet expose a state-active predicate that can safely
  guard a non-state rule DT assignment.
- Deprecated `(handshake name (valid signal) (ready signal))` metadata is
  structurally validated and then ignored; direct `(on port ...)` activation
  plus generated `can_accept` is the current model.
- Actor-level `(phase ...)` and `(stage ...)` metadata is structurally
  validated, parser-carried, and report-visible through `actor_phases[]` and
  `actor_stages[]`, but it is not executable scheduler behavior. Transaction
  `(phase ...)` lowers as a pass-through marker state. The first transaction
  `(stage ...)` subset now lowers as a top-level ready/valid barrier:
  `(stage name (ready ready_signal) (valid valid_signal))`. The older
  `(input ready_signal)`/`(output valid_signal)` spelling remains accepted as
  an alias. The valid endpoint is still a normal transaction drive, so
  existing same-target conflict checks apply if another owner writes it.
  Broader stage forms still fail closed until their runtime semantics are
  specified.
- Unsupported transaction clause heads now fail closed during lowering instead
  of being silently dropped. This includes the removed `(assign ...)` keyword
  and unsupported nested body forms in `when`, `switch`, and `repeat`.
- Rule actions are structurally validated as `(set port value-or-expression)`,
  `(port value-or-expression)`, `(trigger transaction)`, or
  `(priority over other_rule)`. `set` is the canonical explicit scalar setter;
  `(port expr)` remains rule shorthand. Rule trigger targets must resolve to a
  declared transaction in the same actor before parser handoff returns.
- `(shift_right ...)` accepts an explicit `(width N)` option when the shifted
  register width is not declared elsewhere. The option is an assertion and
  must agree with any known register width. Values with no known or explicit
  width now fail closed instead of emitting a placeholder `WIDTH` expression.
- `(assemble ...)` derives target width when every part width is known. It
  also infers exactly one missing part width when the target width and every
  sibling part width prove a positive remainder. Two or more unknown part
  widths may still lower as a reviewable concat expression, but they are not
  used as width evidence. Known target-width disagreements or non-positive
  inferred remainders fail closed.
- `(extract ...)` accepts an ordered `(widths N...)` option when field widths
  are not declared elsewhere. It also infers exactly one missing destination
  field width when the source word width and every sibling field width prove a
  positive remainder. Accepted `extract` source now emits exact descending
  slices only; multiple unknown field widths, non-positive inferred
  remainders, or source/field width disagreement fail closed before scheduled
  `.fsm` emission.
- The first `(contract ...)` temporal assertion subset is implemented for
  top-level `(contract name (eventually signal within cycles))`. The older
  nested `(eventually signal (within cycles))` spelling remains accepted as an
  alias. The `cycles` token may be a positive integer literal or a declared
  actor constant or actor-local scalar parameter default that resolves to a
  positive integer; transaction parameters, runtime expressions, zero-valued
  constants, and zero-valued or non-scalar actor parameters remain invalid.
  Both forms lower to an arm state plus an always-on monitor DT with pending,
  age, and sticky-fail storage, and reports expose the resolved bound in
  `temporal_contracts[].within_cycles`.
  Nested contracts and richer temporal forms still fail closed instead of being
  dropped from the scheduled `.fsm`.
- Transaction `(latency (min N) (max M))` accepts positive decimal literals,
  declared actor constants, and actor-local scalar parameter defaults that
  resolve to positive integers. Static symbols are resolved before the
  existing latency counter lowering path, so generated guards, timeout checks,
  inferred counter widths, and report-visible storage roles match the
  equivalent literal bounds. Transaction parameters, runtime interface
  signals, unknown symbolic names, arbitrary expressions, zero-valued
  constants, and zero-valued or non-scalar actor parameters fail closed.
