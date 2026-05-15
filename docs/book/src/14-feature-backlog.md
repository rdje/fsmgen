# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: partially shipped; broader resource kinds and arbiters remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, slices, selectors, guards, and
other bounded evidence. It does not yet promise "never declare scalar types
unless you want to" across every source position.

### Dynamic Divisor Safety Proofs

Status: partially shipped.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission. Runtime RHS expressions with dynamic divisors are emitted
as expressions; FSMGen does not yet prove every dynamic divisor nonzero.

## Aggregate Types And Data

### Automatic Aggregate Growth From Usage

Status: backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, and partial aggregate
LHS writes are supported on the current SystemVerilog path. Broad automatic
aggregate type growth from arbitrary usage is not fully shipped.

### Backend-Owned Struct/Record Default Lowering

Status: backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases on the current SystemVerilog path. Structured
record lowering is not the default for all aggregate data.

### Richer Aggregate Operators

Status: backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: matching list/record aggregate shapes support leafwise
`+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` plus word aliases before HDL lowering.
Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path.

### VHDL Aggregate Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: VHDL is recognized as a target family, but the full backend
is not implemented. Aggregate lowering beyond scalar/width-safe surfaces is
therefore not shipped.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.

## Composition

### VHDL Generic-Map Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL
generic-map lowering is not shipped.

### Broader Generated-Child Top Instantiation

Status: partially shipped; generalized surfaces remain backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths, and ISF generated-child fixtures now emit a generated
`<actor>_top.fsm` that wires the scheduled parent, scheduled children,
start/done handoffs, named-drive handoffs, explicit port-binding handoffs, and
per-instance parameter overrides for spawn and generated blocking `do`
activations through the existing composition pipeline. Broader generated-child
top surfaces beyond the covered spawn and parameterized `do` patterns remain
backlog.

### Spawn and Blocking Do Parameter Binding

Status: partially shipped; broader parameter/value surfaces remain backlog.

Goal: bind parameters through static generated child activations in
ISF-generated multi-file scheduled designs.

Current boundary: spawn and parameterized blocking `do` emit child files, a
parent scheduled `.fsm`, and a generated composition top for covered
generated-child fixtures. The ISF lowerer accepts one optional nested
`(params (NAME value) ...)` block on `(spawn child as instance ...)` and on
`(do child ...)`, accepts generated child transaction parameters from a
transaction-local `params` clause, emits child defaults as scheduled child
`+params`, validates duplicates/unknown overrides/value shapes, rejects
parameter declarations on non-generated transactions, preserves per-instance
override lists in the parent lowerer IR, and applies those overrides through
the generated top. The first value domain is scalar/exact-width literals plus
compatible aggregate/list literals. Actor-local constants are shipped for
static wait counts, but symbolic parameter override values still need their
own specialization contract before becoming valid parameter values.

### General Transaction Activation Parameter Overrides

Status: partially shipped; the original `ISF-TRANSACTION-ACTIVATION` tree is
closed for spawn and blocking `do`. Rule-trigger or direct-activation
parameter work needs a fresh explicit task-tree leaf before implementation.

Goal: extend the task-like transaction activation model so activation sites can
override declared transaction parameters where that is semantically valid.

Current boundary: transaction ports already provide formal data/control ports,
and shipped activation-site `(bind ...)` blocks pass scalar actual signals for
the supported `do`, `spawn`, and rule `trigger` subset. Spawned child
transactions and blocking `do` child activations support per-instance
`(params (NAME value) ...)` overrides through generated composition. That is
still not a general trigger-site parameter-override contract. Parameter
overrides on rule `trigger`, direct transaction activation, or other future
activation forms need explicit source shape, compile-time versus runtime
interpretation, value domain, diagnostics, lowering, report metadata, and HDL
proof before they are public syntax.

Source shape: reuse the existing explicit spawn-style
`(params (NAME value) ...)` block on activation sites that support static
specialization, while keeping runtime payloads in `(bind ...)`. This is
shipped for spawn and blocking `do`; the trigger example remains backlog:

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

Lowering rule: parameter overrides specialize hardware; they do not assign
runtime parameter signals. A parameterized blocking `do` elaborates a generated
child activation instance named `{parent}_{child}_do_{ordinal}` and waits for
that instance's `done` handoff. If two activation sites pass different
parameter values to the same transaction, the lowerer must elaborate distinct
logical child instances or cloned scheduled regions. If that cannot be done for
a given activation form, the form must fail closed with a diagnostic that tells
the author to move the value to a transaction input port and `(bind ...)` it as
runtime data.

### Spawn Inside Repeat Bodies

Status: backlog.

Goal: allow `(spawn child as name)` inside `(repeat count body...)` without
implying dynamic hardware creation.

Required contract: the lexical spawn name denotes one static child instance in
the generated top. The repeat loop may activate that instance multiple times,
but it must not elaborate one instance per iteration. The scheduler needs a
busy/re-entry rule before this can ship: either prove or insert sequencing so
each later iteration observes the child's fresh done pulse before starting it
again, or reject the loop with a targeted diagnostic.

Dynamic repeat counts are compatible with this model because `count` is a
runtime counter load value, not an elaboration count. They do make loop latency
data-dependent, and the repeat contract still needs an explicit zero-count
policy for the fully general case.

## Intent Scheduling Format

### IAL2 Protocol And Platform Intent Exploration

Status: backlog.

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). A future `IAL2`
would need to justify itself with semantics above individual transactions, not
only syntax convenience. The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

### ISF Enum, Type, And Aggregate Parity

Status: backlog.

Goal: let ISF use the same enum, type, and aggregate variable capability that
`.fsm` already exposes, without inventing a second type system.

Current boundary: ISF still uses mostly scalar width evidence and scalarized
actor-owned storage in the shipped parser/lowering path. Long term, ISF
should be able to reference enum and aggregate types from the same `.fsm` and
package-backed type machinery used by IAL0. The staged path should be:
reference existing enum/aggregate type declarations first, allow actor ports,
parameters, and actor-owned variables to carry those types second, then add
aggregate field/slice/update lowering with explicit cycle semantics and
schedule-report visibility.

The lowering artifact remains the contract. ISF enum/aggregate source should
lower to reviewable `.fsm` text that uses the established type and aggregate
semantics, not to hidden backend-only structure. Diagnostics must reject
unknown types, incompatible enum values, aggregate shape mismatches, and
ambiguous partial updates before HDL generation.

### ISF Scalar Setter Syntax Unification

Status: shipped for scalar rule and transaction assignments.

Goal: use one explicit scalar setter vocabulary across rules and transactions.

Current boundary: `(set lhs expr)` is the canonical explicit scalar setter in
rules and transactions. It schedules an assignment in the current ISF region:
in a rule it lowers under the rule non-state DT DTE, while in a transaction it
lowers as an ordered flopped transaction state. The runtime regions stay
different, but the setter verb is shared. Existing rule `(lhs expr)` remains
supported shorthand, and existing transaction `(update lhs expr)` remains
supported as the older transaction-local spelling while the ISF API continues
to evolve.

Still backlog: aggregate/field setters, bank-entry setters beyond the shipped
`store`/`load` bank access forms, actor-input write policy beyond the current
fail-closed boundary, and any non-flopped assignment family need separate
syntax, lowering, and conflict semantics.

### Enforced Resource Arbitration

Status: backlog.

Goal: lower `(resources ...)` metadata into scheduler-enforced mutual
exclusion and arbiter behavior.

Current boundary: resource metadata is structurally validated, including
supported arbiter names, resource kinds, duplicate resource rejection, and
resource-user validation for `rule_slot`. The scheduler now enforces the first
resource kind: `rule_slot`, a one-cycle mutual-exclusion slot where each bound
rule requests when its guard is true, the priority graph chooses a unique
active winner, and the generated grant gates the whole rule DT DTE without
adding a cycle.
The resource-kind catalog is owned in code by
`FSM::Support::ISFResourceCatalog` and exposed through the machine-readable
ISF public contract, so downstream consumers can distinguish shipped resource
behavior from parser-recognized backlog names without scraping prose.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | One-cycle mutual exclusion for rule users under the `priority` arbiter. |
| `output_bundle` | backlog | One-cycle ownership of a group of actor outputs or LHS targets. |
| `interface_bundle` | backlog | Ownership of a protocol-facing interface or bus bundle. |
| `named_drive` | backlog | Ownership of a reusable actor `(drive ...)` body or drive-call path. |
| `transaction_start` | backlog | Arbitration for start/request fan-in into one transaction. |
| `child_instance` | backlog | Re-entry control for a spawned child instance. |
| `storage_port` | backlog | Arbitration for shared state, register, memory, or storage-port access. |

Remaining backlog: non-`rule_slot` resource kinds, `round_robin`, transaction
lifetime ownership, named-drive users, output-target users, multi-capacity
resources, and dynamic resource names remain backlog until their reset,
hold/release, fairness, and diagnostic contracts are explicit.

### Priority Resolution

Status: partially shipped; broader cases remain backlog.

Goal: enforce actor-level and rule-local priorities when multiple rules or
transactions conflict.

Current boundary: priority declarations are structurally validated and targets
must resolve to declared rules or transactions. Same-target rule/rule data
conflicts can now be resolved by rule-local or actor-level rule priority, with
the lower-priority assignment guarded off by the higher-priority rule
condition. Actor-level rule-over-transaction priority can now resolve the
covered same-target data case by guarding the transaction-state assignment
with the inverse active rule condition. Priority cycles, incomparable rule
conflicts, unordered rule/transaction conflicts, and mixed timing conflicts
fail closed.
Rule/drive overlap is still tracked because compile-time proof is not doable.
Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction-over-rule priority, drive/rule arbitration
policy, and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: shipped for ordinary flopped rule assignments.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(set port expr)`, `(port expr)`,
`(trigger transaction)`, and `(priority over other_rule)`. Trigger targets and
priority targets remain scalar-only today. `(set port expr)` is the canonical
explicit setter; `(port expr)` remains shorthand. Both lower as flopped `<-`
rule assignments under the rule DT DTE, where `expr` may be a scalar token or
one list expression from the transaction `set`/`update`/`.fsm` RHS expression
domain.
`(trigger transaction)` lowers through a generated one-cycle source and
transaction start fan-in. `(priority over other_rule)` feeds the covered
priority/resource arbitration paths. Same-expression rule writes report as
compatible fan-in, incompatible expressions fail closed through the same
rule-write conflict diagnostic, and priority-resolved expression conflicts
project through `priority_resolutions`. Alternate rule assignment operators are
separate future features.

### Transaction Stage Lowering

Status: partially shipped.

Goal: lower transaction `(stage ...)` clauses into valid/ready pipeline-stage
logic.

Shipped subset: a top-level transaction stage of the form
`(stage name (input ready_signal) (output valid_signal))`. It lowers to one
state that drives `valid_signal = 1` while active and advances only when
`ready_signal` is true. Actor-level stage metadata remains parser-carried only;
it does not reach `LoweringIR`, schedule JSON, scheduled `.fsm`, generated
composition tops, or HDL.

Remaining backlog: nested stages, stage-local latency, compute/action bodies,
multiple ready/valid endpoints, registered-valid variants, skid-buffer
behavior, and richer stage report families for future stage kinds.

### Transaction Unconditional Wait

Status: shipped base surface, actor-constant symbolic counts, and a bounded
top-level runtime scalar count subset. Broader runtime contexts remain in the
active `ISF-DYNAMIC-WAIT` task tree.

Goal: support an unconditional cycle delay such as `(wait N)` inside a
transaction body.

Shipped contract: `(wait N)` advances only after exactly `N` active
transaction clock cycles, without checking an external condition. It is
different from `(await cond)`, which waits for a signal condition, and
different from `(repeat N body...)`, which repeats a body. The static surface
accepts non-negative integer literals and actor-level constants declared with
`(constants (NAME value) ...)`. `wait 0` and constants that resolve to zero are
transparent no-ops that emit no wait state, consume no active transaction
cycle, and create no report entry. `wait 1` occupies one generated wait state
for one active cycle and advances on the next state transition; `wait N`
contributes exactly `N` active cycles wherever it executes, including inside
`when`, `switch`, `repeat`, `while`, and `until` bodies. The bounded runtime
surface accepts `(wait count_signal)` only as a top-level transaction-body wait
when `count_signal` has known unsigned width and the predecessor edge can be
split safely.

The static lowering is a reviewable fixed scheduled-state chain. No hidden
wait counter is introduced for the static literal/constant surface. Pending
samples before a positive static wait piggyback onto the first wait state;
pending samples before a zero wait remain pending for the next
state-producing clause. The runtime scalar lowering splits the predecessor
edge: zero bypasses the generated wait state, and positive counts load a
generated counter before entering the wait state. The wait state decrements the
sampled counter and loops until the sampled value reaches `1`.
Consecutive top-level runtime waits are shipped: a zero bypass from one wait
immediately evaluates the next wait, and the final sampled-counter edge of an
active wait splits into the following wait's positive sampled-counter and zero
bypass paths.
Additional top-level predecessor kinds are shipped for `await`, `stage`,
`repeat` exit checks, `await_all`, and `await_any`; their own advance
conditions are ANDed or ORed into the runtime count split, and their unrelated
alternatives such as await timeouts or repeat loop-back edges are preserved.
Successful reports expose bounded `transaction_waits[]` entries with
transaction name, `cycles`, `count_kind`, `count_source`, entry state, exit
state, optional counter signal, and optional counter width. Static waits keep
an integer `cycles`; runtime scalar waits keep `cycles` null and expose their
source/counter metadata. Schedule reports also expose actor constants through
`actor_constants[]`.

Malformed waits such as missing counts, extra operands, negative counts,
non-integer counts, list-expression counts, unknown constant names,
actor/transaction parameter names, unknown-width dynamic names, or unsupported
dynamic contexts fail closed today.

Remaining backlog: runtime scalar waits after pending samples, inside
`when`/`switch`/`repeat`/`while`/`until` bodies, after remaining predecessor
kinds such as loop decision states whose edge split is not implemented yet,
and with expression-valued or parameter-backed counts.

Expansion order is tracked under `ISF-DYNAMIC-WAIT.3.3`: consecutive
top-level dynamic waits and the requested additional top-level predecessor
kinds are shipped, so the next frontier is inline branch/loop bodies, then
pending-sample preservation, and finally expression-valued runtime counts once
their width/type/snapshot contract is specified.

### Transaction Dynamic Loops

Status: shipped base surface; nested/child loop combinations remain backlog.

Goal: support transaction-local loops such as `(while cond body...)` and
`(until cond body...)`.

Shipped contract: `(while cond body...)` is a pre-test loop. The scheduler
emits an entry decision state and a back-edge decision state that each sample
`cond` once; true enters or repeats the body, and false exits to the next
transaction clause. Zero iterations are therefore possible. `(until cond
body...)` is a body-first loop. It executes the body once, then samples `cond`
in a generated decision state; true exits, and false loops back to the body.
That spelling means one-or-more iterations. A pre-test "run while not done"
loop should be authored as `(while (! done) body...)` rather than overloading
`until`.

Loop bodies must be non-empty and currently reuse the shipped inline-body
surface: named drive calls, `await`, `sample`, `complete`, `repeat`,
`update`, shift/assemble/extract data operations, actor-owned bank
`store`/`load`, nested `when`, and shipped `(wait N)` clauses. The first
implementation continues rejecting `do`, `spawn`, `await_all`, `await_any`,
`stage`, `contract`, and nested `while`/`until` until re-entry, child
lifetime, and reporting semantics are specified. The condition uses the same
scalar or list-expression condition surface as `when`.

These loops are persistent hardware schedule regions, not software processes.
They may be data-dependent or unbounded at runtime and do not create an
implicit timeout. Existing watchdog, latency, and temporal-contract mechanisms
remain explicit and count loop-body cycles according to their own active-cycle
semantics. Successful reports expose bounded `transaction_loops[]` entries
with transaction name, kind, normalized condition text, generated
decision/body/exit states, and body clause count.

### Transaction Ports And Actor Pin Access

Status: shipped base surface; richer output/report surfaces remain backlog.
Transaction `(ports ...)` declarations, scalar and expression-valued input
activation bindings, first actor-pin conflict/runtime coverage, and bounded
schedule-report binding provenance are shipped. The original
`ISF-PORT-BINDING` task tree is complete; expression-valued input bindings are
tracked by `ISF-ACTIVATION-BIND-EXPRESSIONS`.

Goal: make it easy to connect actor variables, actor-owned storage, and actor
top-level pins to transaction ports so rules and transactions can exchange
data/control intent without manually authoring low-level `.fsm` handoff
signals.

This should be an ISF-level source feature with explicit `.fsm` lowering, not
an author-facing escape hatch to raw handoff wiring. Transaction ports need
direction and width. Activation sites need explicit bindings. Actor input pins
are readable observations and should not be writable from ISF. Actor output
pins are writable targets, but they must use the same assignment, fan-in,
priority/resource, and runtime-conflict rules as any other driven LHS.

Authoring boundary: users should describe the transaction boundary and the
use-site binding, not generated payload wires, bridge ports, start payload
signals, or generated-top handoff nets. For example, a data-bearing
transaction declares local ports, and the caller binds those ports to actor
variables, actor-owned storage, or actor interface pins:

```lisp
(transaction apb_read
  (ports
    (input  addr (width 32))
    (output data (width 32))
    (output done))
  ...)

(do apb_read
  (bind
    (input  addr req_addr)
    (output data read_data)
    (output done read_done)))

(rule launch_read ready
  (trigger apb_read
    (bind
      (input addr (+ base_addr offset)))))
```

The compiler owns the lower-level materialization: generated `.fsm` handoff
signals, guards, mux selectors, assignments, generated-top bridge nets, and
the schedule-report provenance that lets reviewers inspect the result. That
keeps the author-facing model ergonomic while preserving the `.fsm` review
artifact as the authoritative low-level representation.

Shipped declaration shape:

```lisp
(transaction read_word
  (ports
    (input addr (width 32))
    (output data (width 32)))
  ...)
```

The parser accepts at most one `(ports ...)` clause per transaction. Each port
has direction `input` or `output`, a scalar HDL identifier name, and optional
positive integer `(width N)`; omitted width means 1. The normalized public
transaction shell has `ports.inputs[]` and `ports.outputs[]` entries with
`name` and `width`. The declaration is not a scheduler body clause; behavior
comes from transaction states/rules that use the port and activation sites
that bind it.

Shipped binding shape:

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
    (input addr req_addr)))
```

Input bindings accept scalar signals, numeric/exact-width literals, and
non-empty list expressions. Scalar and known-width expression sources are
width-checked against the transaction input port; unknown expression widths
continue through the downstream `.fsm` expression validation path. Local `do`
lowers input bindings in the state that starts the child and copies output
bindings under the generated child-done guard. Parameterized/generated `do`
lowers through explicit generated-top handoff ports and a parent-owned
`do_port_binding` DT whose output copy is done-gated. `spawn` lowers through
hidden generated-top handoff ports and reviewable parent binding DTs; actor
signals consumed by explicit spawn input-binding expressions are not also
same-name wired into the child instance. Rule `trigger` supports input
bindings only; each rule owns a distinct payload source and the trigger fan-in
DT routes payloads under the matching per-rule trigger pulse.
Rule-trigger output bindings, explicit snapshot-vs-live timing selection,
richer report fields, and broader static conflict diagnostics remain backlog.

Actor pin binding now uses the same assignment/conflict path as ordinary ISF
drives where it has shipped coverage. Spawn output bindings carry parent
transaction ownership in provenance, so a spawned child output bound to an
actor output conflicts with a same-target rule writer through the existing
rule/transaction diagnostics. Accepted spawn-output fan-in and rule-trigger
input payload fan-in remain visible as normal `.fsm` same-LHS assignments and
reach the SystemVerilog backend's verification-only selector checks.

Successful schedule reports now expose bounded `transaction_port_bindings`
entries for the shipped binding surface. Each entry records the binding site
kind, owner, target transaction, direction role, port, scalar actor signal
when applicable, formatted actor expression, width, and generated handoff names
where they exist. This is a public summary for downstream tooling, not the raw
binding or assignment-provenance internals.

### Temporal Contract Lowering

Status: backlog.

Goal: lower transaction `(contract ...)` temporal assertions into generated
checks or equivalent scheduled artifacts.

Shipped subset: a top-level transaction contract of the form
`(contract name (eventually signal (within cycles)))`. Reaching the clause
emits one arm state; the generated scheduled `.fsm` monitor tracks
pending/age/fail storage, clears on actor reset, and sets a sticky fail bit if
the signal is not seen within the window or if the same contract is armed
again while pending.

Remaining backlog: optional verification-only SystemVerilog assertion text
from the sticky fail bit, global `always` implication forms, min/max windows,
dynamic bounds, same-cycle checks, nested contracts, expression operands, and
multiple outstanding obligations.

### Legacy Handshake Semantics

Status: deprecated compatibility input with tightened validation.

Goal: keep old `(handshake ...)` source intentional without giving it new
runtime semantics.

Current boundary: deprecated handshake metadata is structurally validated and
ignored. The parser accepts a scalar handshake name plus scalar `valid`/`ready`
property entries and leaves the actor-shell handshake placeholder empty. Direct
`(on port ...)` activation plus generated `can_accept` is the current model.
Policy: keep well-formed legacy handshakes accepted and ignored for
compatibility, and do not lower them into scheduled `.fsm`, schedule JSON, or
HDL. Accepted legacy forms now require one `valid` and one `ready` property
with no duplicate handshake names. Use `(on ...)` for activation and
transaction `(stage name (input ready_signal) (output valid_signal))` for
ready/valid barriers.

### Removed Assign Keyword

Status: removed compatibility item; targeted diagnostic pending.

Goal: keep the removed `(assign ...)` transaction keyword out of the language
and guide authors to explicit timing constructs.

Current boundary: authored uses fail closed as unsupported transaction clauses.
The parser may carry the raw clause as private scheduler input, but the
scheduler rejects it in top-level transaction bodies and nested contexts such
as `when`, `switch`, or `repeat` bodies. The diagnostic is migration-specific:
do not auto-map the old keyword. Use `(set var expr)` for explicit scalar
flopped updates, `(update var expr)` for the older transaction-local spelling,
`(drive ...)` for protocol/output drives, rule `(set port expr)` or
`(port expr)` actions for rule-driven assignments, and `(complete port)` for
transaction completion. A future transaction-local combinational assignment feature would
need a new explicit construct with its own timing semantics.

### Full Width Inference For Data Operations

Status: backlog.

Goal: infer widths for data operations in more cases without requiring
explicit width options, and keep accepted lowering free of width placeholders.

Current boundary: `shift_right` accepts `(width N)` and `extract` accepts
`(widths N...)` as explicit assertions. `extract` now fails closed instead of
emitting placeholder slice bounds when field positions cannot be proven or
field totals conflict with known source width. `shift_right` now fails closed
when width evidence is missing or conflicts with an explicit option.
`assemble` now rejects known target-width mismatches, while unknown part
widths remain accepted only as non-evidence concat operands.
Schedule reports now expose positive integer `width` metadata for inferred
scheduler counters and register storage with known ISF width evidence.

### Richer Schedule-Report Storage Classes

Status: partially shipped; additional classes remain backlog.

Goal: classify inferred storage more precisely in schedule reports.

Current boundary: schedule reports expose bounded storage metadata with
optional positive integer widths when width evidence is known.
`inferred_storage[].kind` remains the coarse storage category (`counter` or
`register`). The first optional `inferred_storage[].role` slice is shipped for
storage families with stable lowering evidence: `watchdog_counter`,
`latency_counter`, `repeat_counter`, `drive_request`, `drive_payload`,
`sample_alias`, `extract_field`, `data_register`, and `completion_pulse`.

Remaining direction: keep `role` additive and omit it when evidence is
ambiguous. Additional roles, including temporal-contract monitor storage,
child `do`/`spawn` handoff storage, rule-trigger source storage, and
resource-grant/debug storage, remain backlog until each family has its own
compatibility rules, public contract metadata, and regression coverage.

### Fully Frozen Schedule JSON Schema

Status: backlog.

Goal: freeze the whole schedule JSON schema as a public contract.

Current boundary: schedule JSON is public only through bounded key families
advertised by `embedding.isf_public_interface`. The whole JSON tree is not yet
promised as permanently frozen. The conflict/fan-in projection boundary is now
defined. Nonfatal conflict issues project into `compile_issues`, and accepted
fan-in groups project into `compatible_fanin_groups`, both with bounded
summary shapes. Successful priority/resource decisions project into
`priority_resolutions` and `resource_arbitration` as bounded static lowering
summaries. Shipped transaction stages and bounded eventual contracts project
into `transaction_stages` and `temporal_contracts` with bounded public
summary shapes.

Freeze-readiness plan: the current contractual surface is the metadata
advertised by `embedding.isf_public_interface`, including top-level keys,
nested key/value families, scalar policies, ordering policies, nullability
rules, storage kind/role/width metadata, and CLI/in-process report parity.
New optional keys or value-family members may be added only when the same slice
updates contract metadata, focused tests, and user-facing docs.

Blockers before flipping `schedule_report_full_schema_stable` are: decide
whether the report needs its own schema/version field, close or explicitly
defer remaining storage-role families, define generated-name stability policy,
decide whether assignment provenance and multi-file child summaries stay
private or gain bounded public summaries, document additive/deprecation rules,
and keep a golden fixture matrix for every advertised branch.

### ISF Realistic Fixture Matrix

Status: current coverage boundary with future promotion candidates.

Goal: keep realistic protocol fixtures aligned with shipped ISF behavior,
strict-mode expectations, schedule JSON assertions, scheduled `.fsm` review
artifacts, and generated HDL reachability.

Current boundary: APB remains the quick/smoke ISF baseline for parse, scheduled
`.fsm` header, and public-contract checks. Broader realistic fixture coverage
belongs in the `isf` regression tier. The active matrix in
[ISF-FIXTURE-COVERAGE](../../tasks/ISF-FIXTURE-COVERAGE.md) now covers
`isf/spi_master.isf` as a bounded SPI-like mode-0 serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL
checks. It is not a complete SPI protocol compliance suite. Future fixture
promotions should add stable structural assertions rather than full HDL or full
schedule JSON snapshots. The SPI-like fixture intentionally stays out of the
quick/smoke tier for now; `quick` remains APB-centered for fast turnaround.

Fixture authoring policy: realistic fixtures should use documented ISF
constructs. If a fixture needs an awkward workaround to express a normal
hardware intent, treat that as an ISF expressiveness gap and track the missing
construct instead of hiding the workaround inside the test.

ISF expressiveness policy: Lisp-like syntax makes argument-level composition
and variadic constructs natural, but arity is part of the public contract.
Constructs with fixed hardware roles should keep exact arity. Constructs whose
meaning is naturally list-like or associative may accept an arbitrary number of
arguments when that keeps the source clear and the lowering remains
deterministic. Each new variadic surface needs targeted malformed-arity
diagnostics, focused or fixture coverage, and book/spec updates in the same
slice.

### ISF Reusable Libraries

Status: active feature tree under
[ISF-LIBRARIES](../../tasks/ISF-LIBRARIES.md).

Goal: let users import tested reusable ISF descriptions instead of rewriting
common actors and transaction patterns in every design. The user-facing term is
**library**. The implementation may reuse package/import infrastructure, but
ISF libraries are broader than scalar constants or type packages: they should
be able to contain reusable ISF actors, transactions, drives, and associated
constraints when those surfaces are specified.

Current boundary: the first reusable ISF library import, same-name
and remapped generated-top system binding, actor-owned fixed-storage,
expression-valued rule-guard, disjoint-rule write, FIFO-controller matrix,
bank-access, and fixed FIFO
library fixture slices have shipped. Actor roots may import library roots, use
an exported actor, validate use-site parameters and explicit bindings, emit a
specialized child scheduled `.fsm` artifact, wire the library actor through a
generated top, reach SystemVerilog generation for the covered generated-top
path, project bounded `library_uses` schedule-report metadata, declare fixed
actor-owned state/banks, author rule fire predicates as expressions, accept
same-target rule writes when direct contradictory guard facts prove
disjointness, prove a depth-4 FIFO-controller same-cycle update matrix, and
author a reusable fixed-shape FIFO actor source with bank-backed accepted
push/pop data movement that reaches generated-top SystemVerilog. Clock/reset
name remapping now works through explicit generated-top links while keeping
the reusable actor's reset kind and polarity unchanged. This remapping is
still single-clock-domain ISF behavior; multi-clock, asynchronous, and
interacting clock domains remain a separate unshipped semantics problem.

Shipped source model for actor exports:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Shipped use model for actor exports:

```lisp
(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params (WIDTH 32) (DEPTH 4))
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

The first repo-local reusable FIFO fixture uses that model through
`isf/common/fifo.isf` and `isf/fifo_library_use.isf`. The library exports
`common.fifo.fifo`; the top-level fixture imports it as `fifo_lib` and binds
the public FIFO ports to instance `u_fifo`. The generated HDL proof checks
the specialized child module, fixed parameter bindings, scalarized data
entries, pointer-gated accepted push/pop selectors, and generated top wiring.

Imports are actor-scoped in the first shipped model. Imported definitions stay
namespaced by default; `as alias` creates a local namespace alias, not
unqualified symbol pollution. The first shipped export target should be
reusable actors. Standalone transaction templates and standalone drive helpers
need their own binding rules before they become public library exports.

Shipped specialization and binding model:

```lisp
(actor fifo
  (params
    (WIDTH 8)
    (DEPTH 4))
  ...)

(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params
      (WIDTH 32)
      (DEPTH 4))
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

Actor-library parameters use unique HDL-identifier-compatible names and a
default value. Use-site overrides are instance-local and should reuse the
spawn-parameter value boundary first: scalar decimal literals, exact-width
numeric literals, and compatible aggregate/list literals. Missing overrides use
defaults; duplicate parameters, unknown overrides, unsupported symbolic values,
and unsupported non-static parameter use fail closed.

Binding is explicit. A reusable actor with a clock or reset must bind it at the
use site. Reset kind and polarity belong to the reusable actor for the first
ship; the use site should not silently change sync/async or active-high/low
semantics. Every exported actor interface port must be bound exactly once with
matching direction and matching specialized width. No implicit truncation,
extension, or slicing is performed by the binder.

Generated names are deterministic in the shipped resolver: the authored
instance name remains
the stable diagnostic/report identity, while the first specialized child module
and scheduled `.fsm` basename use `<importing_actor>__<instance>` and
`<importing_actor>__<instance>.fsm`. Successful reports expose a bounded
`library_uses` array with library/export/instance identity, parameter
source/value summaries, binding summaries, and generated artifact names without
exposing raw resolver or lowerer internals.

Resolver scope: `parse_file(...)` checks same-source library roots, then
external library files under the importing source directory, `FSMLIB` entries,
and the current directory. For a dotted namespace such as `common.fifo`, both
`common.fifo.isf` and `common/fifo.isf` are candidate file names. `parse_source`
can use same-source library roots but cannot resolve external files without a
real source path. Standalone transaction/drive exports, symbolic parameter
values, derived parameter expressions, parameter-derived storage dimensions,
memory-array backend emission, nested library imports, and multi-clock-domain
ISF semantics are still deferred.

FIFO modeling rule: a FIFO should be modeled primarily as an actor because it
owns persistent storage, pointers, occupancy, full/empty flags, reset behavior,
and interface timing across cycles. Enqueue, dequeue, flush, or status-probe
behaviors can be transactions or callable operations inside or against that
actor, but a transaction alone should not own the FIFO's persistent state.
Hardware components in ISF are persistent regions, not software processes that
die when their immediate work is done. Actors, transactions, DTs, and rules
may be inactive, but while the design is powered, clocked, and released from
reset, their logic remains present.

Shipped actor-owned storage model:

```lisp
(actor fifo
  (storage
    (var rd_ptr (width 2))
    (var wr_ptr (width 2))
    (var occupancy (width 3)))
  ...)
```

`(var name (width N))` declares one fixed-width internal actor scalar storage
value. `(variable ...)` is the verbose scalar-storage alias.
`(bank name (width N) (depth N))` remains the fixed-depth actor-owned storage
form. The FIFO-controller matrix does not use an internal bank, but the
shipped data-path probe now exercises a depth-4 bank through explicit
store/load access.

Selected data-buffer access surface:

```lisp
(store data wr_ptr data_in)
(load data rd_ptr as data_out)
```

`store` writes a value into the actor-owned bank entry selected by the index.
For the first depth-4 implementation it lowers through the existing scalarized
review artifact by guarded updates to `data_0`, `data_1`, `data_2`, and
`data_3`. `load` reads the selected bank entry into a scalar target, again
through mux-equivalent guarded assignments from the scalarized entry family.
Rules and supported transaction contexts accept these forms for declared
actor-owned banks.
`store` is intentionally bank-entry-only; scalar actor-owned storage declared
with `(var ...)` or `(variable ...)` uses the existing rule assignment and
transaction `update` surfaces.

The first same-cycle store/load policy is read-before-write. A load observes
the current cycle's bank value, while a store updates the selected entry for
the next cycle. Write-first collision behavior, explicit bypassing, or
collision diagnostics need their own future option or construct.

Successful schedule reports expose bounded `bank_accesses` metadata for these
forms: access kind, owner, container, bank name, index expression, width,
depth, scalarized entries, value or target, and the same-cycle policy. The
shipped index is a scalar signal or literal token; full list-expression indexes
remain future work.

The shipped FIFO fixture is a real FIFO actor, not a depth-1 placeholder. A
depth-1 element may be useful as a register slice or holding element, but it
does not exercise FIFO depth, pointers, or occupancy semantics. The first
fixture is fixed to `DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and
`OCC_WIDTH=3`. Those parameters are emitted as provenance and use-site binding
evidence; parameter-driven interface/storage elaboration remains future work.
The fixture explicitly models the four request cases: no request, push without
pop, pop without push, and push with pop. Push-only updates occupancy and the
write pointer when not full; pop-only updates occupancy and the read pointer
when not empty; simultaneous push+pop derives the write and read effects from
the same pre-cycle state and updates both sides atomically; idle preserves
state. Depth 4 gives the initial implementation concrete 2-bit pointer wrap,
occupancy values 0 through 4, and full/empty flag checks before arbitrary-depth
elaboration is generalized.
`full` is actor-maintained and is `1` when `occupancy == 4`; `empty` is
actor-maintained and is `1` when `occupancy == 0`. `wr_ptr` names the next
entry selected by an accepted push; `rd_ptr` names the next entry selected by
an accepted pop. For the depth-4 controller matrix both pointers wrap from
entry 3 back to entry 0.
Transaction `(when condition body...)` is ordered control flow, so using a
chain of `when` branches to model FIFO ports would be misleading. Disjoint-rule
proof for same-target FIFO-style rule writes is shipped for direct
contradictory guard facts, such as one case requiring
`(== occupancy 1)` while another requires `(== occupancy 2)`. Same-cycle
two-port controller semantics are now proven on actor-owned state, and the
fixed reusable FIFO fixture reaches generated-top SystemVerilog. Public
catalog/contract metadata is synchronized through
[docs/ISF_LIBRARY_CATALOG.md](../../ISF_LIBRARY_CATALOG.md),
`library_catalog_paths`, `library_catalog_entry_keys`, and
`shipped_library_definitions`.

### ISF Multi-Clock And CDC Semantics

Status: proposed task tree under
[ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md).

Goal: give ISF a deliberate model for designs with multiple clock domains,
asynchronous boundaries, and interacting domains.

Current boundary: ISF currently has one clock domain per actor/generated top.
Different clock signal names, library clock/reset bindings, and generated-top
system-port links are signal-name binding within that model. They are not CDC
semantics.

The future feature must define at least:

- how clock domains are declared and named;
- whether domains are actor-scoped, port-scoped, child-instance-scoped,
  transaction-scoped, rule-scoped, or some constrained combination;
- reset ownership per domain, including synchronous resets and asynchronous
  reset pins without arbitrary DT glue on async reset trees;
- which crossings are legal, such as synchronized single-bit events,
  handshakes, request/acknowledge channels, or dual-clock FIFO-style actors;
- which direct crossings fail closed;
- how the scheduler emits reviewable domain-specific `.fsm` artifacts or a
  documented multi-domain artifact; and
- what bounded schedule-report metadata and fixtures prove the behavior.

Until that contract ships, direct same-cycle reads or writes across domains
must not be inferred from ordinary signal access.

## Backends And Validation

### Full VHDL Backend

Status: backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI recognizes VHDL target spelling, but explicit VHDL
generation is not implemented.

### GHDL Validation

Status: backlog, behind active VHDL backend work.

Goal: add GHDL validation once there is an active VHDL backend.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set.
It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

## Embedding And Public APIs

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.
