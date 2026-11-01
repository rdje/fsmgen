# Actor and Interface

An actor is an IAL1 `.isf` hardware agent. Its interface, state and transactions
are scheduled into the explicit IAL0 review artifacts described in the
[lowering reference](13h-lowering-reference.md).

## Actor Declaration

```text
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65535)
  ...)
```

Every legacy single-clock actor has a clock, reset policy, and watchdog after
parser defaults are applied.

When the author omits those timing clauses, FSMGen assumes `(clock clk)`,
`(reset (rst_n async active_low))`, and `(watchdog 65535)`. The watchdog
default is exactly `(2^16 - 1)`.

Explicit `(clock ...)`, `(reset ...)`, and `(watchdog ...)` clauses override
those defaults exactly as authored.

The actor is the top-level unit — one hardware agent.

The parser treats `(clock ...)`, `(clock-domains ...)`, `(reset ...)`,
`(watchdog ...)`, `(interface ...)`, and `(storage ...)` as singleton actor
clauses. Each may appear at most once in an actor; repeated clauses are
rejected before the public actor shell is returned rather than merged or
overwritten. `(clock-domains ...)` is mutually exclusive with actor-level
`(clock ...)` and `(reset ...)`.

## Clock

```lisp
(clock clk)
```

Legacy `(clock name)` ISF actors have one clock domain per actor/generated top.

The clock name is an authored signal name for that domain; using a name other
than `clk` does not create a second domain.

If a legacy single-clock actor omits `(clock ...)`, the parser normalizes its
clock to `clk`.

The current clock clause does not declare a frequency or period. Physical-time
durations and clock-rate declarations are requested under SEM `.60.1`; their
source contract and implementation remain pending. Timing bounds currently
use the documented cycle-count forms.

Generated-top clock/reset links for reusable libraries are still
single-domain signal-name bindings. They are not clock-domain-crossing
constructs, and they do not specify synchronizers, handshakes, dual-clock
storage, or any other CDC behavior.

Multi-clock, asynchronous, and interacting clock-domain semantics are owned by
the completed `ISF-CLOCK-DOMAINS` feature tree. The parser now accepts the
selected actor-scoped named-domain metadata and the scheduler builds an
internal domain partition. Multi-domain public `lower(...)` now emits one
domain scheduled `.fsm` artifact per declared domain plus a generated top that
wires explicit CDC child-interface artifacts for accepted event crossings.

`report(...)` and `--emit-schedule-json` now expose bounded domain and
crossing metadata for that generated top. Accepted event-crossing actors now
reach generated SystemVerilog/Verilog-family HDL with the generated top and a
concrete acknowledged-event CDC child per accepted crossing when each emitted
domain artifact also satisfies the current scheduled `.fsm` clock/reset HDL
contract.

## Multi-Clock Domains

The selected authoring shape is an actor-level `(clock-domains ...)` block:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain io (clock bus_clk)))
```

Existing `(clock clk)` stays the shorthand for one implicit actor domain named
`default`. A multi-domain actor may not mix `(clock ...)` and
`(clock-domains ...)`; it needs unique domain names, scalar clock names, and
exactly one default domain. A single-domain `(clock-domains ...)` block has an
implicit default and can still lower through the existing single-clock `.fsm`
path.

Interface ports, storage entries, transactions, rules, reusable `use`
instances, and generated child activations can carry `(domain NAME)`
annotations, or inherit the default when `(clock-domains ...)` is present.

Drives inherit the domain of their activation site. None of those annotations
are CDC primitives: direct cross-domain reads, writes, triggers, activations,
bindings, or multi-domain drive reuse fail closed before emission unless a
shipped crossing primitive owns that path.

Scalar bit indexes and slices retain their declared root's clock domain,
including nested aggregate storage leaves. Foreign-domain reads fail before a
schedule is emitted. Explicit transaction formals retain their local domain
when they share an actor signal's name.

The implementation is intentionally artifact-first. `lower(...)` does not turn
one `.fsm` module into a hidden multi-clock state machine. It partitions the
actor into one ordinary scheduled `.fsm` per declared domain, using
`<actor>__domain_<domain>.fsm` names when they are collision-free, then emits `<actor>_top.fsm` as a
composition source. The top instantiates each domain parent and its generated
transaction children with `?fsmc`, and owns only wiring plus explicit CDC child
interfaces. Generated children use their owning domain's clock and reset. Their
start, completion and payload handoffs remain internal, including inherited
inputs supplied by a CDC endpoint.

For example, this child executes in `core` while the auxiliary transaction uses
its own clock:

```lisp
(actor domain_child_read
  (clock-domains
    (domain core (clock clk) (reset (rst_n async active_low)) :default)
    (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))
  (interface
    (input start) (input data (width 8))
    (output observed (width 8)) (output done)
    (input aux_start (domain aux)) (output aux_done (domain aux)))
  (transaction worker
    (ports (output result (width 8)))
    (wait 2) (set result data) (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0 (bind (output result observed)))
    (await_all done) (complete done))
  (transaction aux_tx
    (domain aux) (on aux_start) (wait 1) (complete aux_done)))
```

The generated worker has a separate review artifact. Reused instances share
its definition while retaining independent start, data and completion wiring.
Parameterized generated `do` also uses the owning domain; its bound output is
valid during the child's completion pulse, as described in
[Composition](13f-composition.md). Transaction-local payload ports take
precedence over same-name actor signals during domain validation.

A domain that contains generated children or a library instance can also use
an explicit activation crossing. Its start, done and ready handshakes stay
internal to the domain components and CDC children. The component boundary
honors those declared routes even though ordinary local child handoffs are
private. For example, the parent can join a local worker and then call a
transaction in another domain:

```lisp
(actor composed_activation
 (clock-domains
  (domain core (clock clk) (reset (rst_n async active_low)) :default)
  (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))
 (interface (input start) (output core_done) (output local_seen) (output aux_seen (domain aux)))
 (crossings (activation remote (from core) (to aux)))
 (transaction worker (wait 1) (complete local_seen))
 (transaction parent (on start) (spawn worker as job) (await_all done) (do remote) (complete core_done))
 (transaction remote (domain aux) (wait 2) (complete aux_seen)))
```

The auxiliary clock may be stopped while the local worker runs; the parent
completes only after the declared remote activation crosses and returns.
Reset and repeated activation retain the existing handshake behavior.

Generated children can read live actor storage when the child and storage owner
share a domain. Scalar, signed, packed record/list and selected bank reads use
internal owner-to-child handoffs; the owner retains the register and its reset.
These reads remain live after activation. Unowned sibling-domain access is
rejected instead of introducing an implicit crossing.

[Named child completion outputs](13f-composition.md#named-completion-outputs-in-generated-children)
also retain their authored pulses alongside the canonical activation handshake.
Library-owned outputs feed the importing FSM through readback inputs, with the
library selected into its declared domain; see [Composition](13f-composition.md).
Independent clock/reset and report qualification covers these supported paths.
Child await watchdog initialization, plain local-call reachability and
multi-domain VHDL remain separate qualification boundaries.

For example, the file-backed `clock_domain_event_crossing` actor uses the
portable domain names `source` and `core` and emits these review artifacts:

```text
clock_domain_event_crossing__domain_source.fsm
clock_domain_event_crossing__domain_core.fsm
clock_domain_event_crossing_top.fsm
```

### Logical Domains and Generated Names

Domain names are logical ISF identities. A domain named `bus` is valid even
though `bus` is an HDL keyword. The generated top uses `bus_instance` for
that child and keeps `bus` in domain annotations and schedule metadata.
Authored clocks, resets and interface pins keep their names.

The compiler allocates domain children first in declaration order, followed
by event children and activation start/done children. It reserves every public
pin, compares collisions without case, and uses the shared portable HDL
keyword policy. Keywords gain `_instance`; ordinary collisions gain `_domain`
for domain children or `_cdc` for crossing children. Further collisions gain
the first free numeric suffix. Existing legal, non-colliding names stay stable.
Domain-owned generated children are allocated afterward, reserving all those
identities. Their module/file seed is `<domain-module>__child_<source>` and their
instance seed is `<domain-instance>__<local-instance>`; collisions use the same
portable allocator. Public schedule domain names and local child-instance names
stay logical. The returned artifact map and semantic composition children expose
the physical files, modules and hardware instances.

For example, renaming `source` to `bus` in the complete event actor below
changes its child label to `bus_instance`, while the public `bus_start` pin
and event request route retain their behavior. A domain named `bus_start`
instead becomes child `bus_start_domain` because the public pin owns that
name. If public pins already occupy `bus_instance` and `bus_instance_2`, the
`bus` child becomes `bus_instance_3`.

Module/file identities are allocated separately with case-insensitive
collision checks. With domains `CORE` followed by `core`, the domain files
end in `__domain_CORE.fsm` and `__domain_core_domain.fsm`; both survive export
on a case-insensitive filesystem. Always read `clock_domains[].scheduled_fsm`
instead of reconstructing filenames from logical names.

Agents can relate logical and physical structure using the existing APIs:
take a schedule domain's `scheduled_fsm`, remove `.fsm`, and match the result
to semantic `forward_ir.intent_hir.composition_children[].module_name`.
That child supplies `instance_name` and `source_name`. Crossing reports already
expose their allocated module/instance pairs. Native queries, the clean MCP
adapter API and `fsmgen_schedule_preview` / `fsmgen_semantic_introspect` expose
the same identities; no private allocation map is needed.

The generated top keeps same-name domain clock/reset connections on the
existing composition system-port auto-wiring path. That means a domain module
whose clock port is also named `bus_clk` is not redundantly wired by an
explicit top link. CDC child ports have deliberately different names such as
`source_clk` and `dest_clk`, so the generated top wires those ports explicitly.

### Event Crossing

The first shipped crossing primitive is an acknowledged single-bit event
channel:

```lisp
(crossings
  (event rx_done
    (from source rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

The source-domain artifact sees `rx_done_ready` as an input and drives
`rx_done_bus` as a one-cycle request event. The destination-domain artifact
sees `rx_done_core` as an input pulse. The generated top wires the source
request into a CDC child, wires the CDC `ready` output back to the source
domain, and wires the CDC `pulse` output into the destination domain.

Runtime semantics are single-outstanding and acknowledged. The source side may
request a new event only while `ready` is true. After an accepted request, the
CDC child toggles a source-domain event bit, synchronizes that toggle into the
destination domain, emits one destination-clock pulse when the destination
observes a new toggle, then returns an acknowledgement toggle to the source
domain. No same-cycle relationship is promised between request and pulse, and
the primitive carries no data payload.

### Generated CDC HDL

The generated top represents the event crossing as a `?rtl` child with an
embedded `?rtlif` contract. FSMGen marks only its own event-CDC contract with
metadata parameters, for example:

```lisp
(?rtlif:clock_domain_event_crossing__cdc_event_byte_ready
  (params
    (FSMGEN_ISF_CDC_EVENT 0d1)
    (SOURCE_RESET_PRESENT 0d1)
    (SOURCE_RESET_ASYNC 0d0)
    (SOURCE_RESET_ACTIVE_HIGH 0d0)
    (DEST_RESET_PRESENT 0d1)
    (DEST_RESET_ASYNC 0d0)
    (DEST_RESET_ACTIVE_HIGH 0d0))
  source_clk:clock
  dest_clk:clock
  source_reset:reset
  dest_reset:reset
  request<:data
  ready>:data
  pulse>:data)
```

That marker is the boundary between generated CDC and ordinary external RTL.

### Activation Crossing

A blocking cross-domain `(do child)` — where the calling transaction and `child`
run in different clock domains — is owned by an activation crossing:

```lisp
(crossings
  (activation worker (from core) (to worker)))
```

`worker` names a declared transaction in the destination domain (`worker`); the
calling transaction is in the source domain (`core`). The activation start/done
handshake signals are compiler-internal, so the author declares only the
crossing — not raw event pairs. One activation crossing auto-generates **two**
acknowledged-event CDC children: a `start` synchronizer (source → destination)
carries the activation request, and a `done` synchronizer (destination → source)
carries completion back.

A complete actor:

```lisp
(actor cross_domain_activation
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain worker (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to worker)))
  (interface
    (input  start (domain core))
    (output done  (domain core))
    (input  din    (width 8) (domain worker))
    (output result (width 8) (domain worker))
    (output worker_complete (domain worker)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain worker)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
```

This lowers to `cross_domain_activation__domain_core.fsm` (the caller),
`cross_domain_activation__domain_worker.fsm` (`worker`), and
`cross_domain_activation_top.fsm`, which instantiates both domain modules and the
two CDC children
`cross_domain_activation__cdc_activation_worker_start` and
`...__cdc_activation_worker_done`. Plain HDL generation emits all five modules
(two domain modules, two CDC children, the top).

The handshake mirrors the event-crossing source idiom on both directions:

- The caller (`core`) awaits `worker_start_ready` (the start CDC ready), drives a
  one-cycle `worker_start` request, then blocks on the `worker_done` pulse.
- The start CDC synchronizes the request `core → worker` and emits a one-cycle
  `worker_start` pulse in the destination, which gates `worker`'s entry.
- On completion, `worker` awaits `worker_done_ready`, drives a one-cycle
  `worker_done` request, which the done CDC synchronizes `worker → core` and pulses
  back to release the caller.

Because the request is one cycle and gated on the CDC `ready`, a held level
cannot re-trigger `worker`; exactly one activation is outstanding at a time, and
the `done` pulse is the application-level acknowledgement. Both CDC children
reuse the acknowledged-event primitive (the same `FSMGEN_ISF_CDC_EVENT` marker,
generated module shape, and reset metadata shown above for event crossings).

A cross-domain `(do child)` is supported at the transaction top level, directly
inside any **top-level body** — a `(repeat ...)` body or a `when` / `switch` /
`while` / `until` branch body — and directly inside a `(repeat ...)` nested in a
top-level `when` body or top-level `switch` branch, or directly inside a nested
`when` chain reached from one of those top-level branch bodies, including a
`repeat` under that nested `when` chain. The same caller restructure applies in
every case (the branch/loop entry, nested repeat entry, or inner `when` branch
entry is redirected into the inserted start-ready await, so the await-ready →
one-cycle-start → dual-CDC → done handshake runs when the branch is taken; inside a
repeat or loop it re-runs each iteration and the destination worker returns to idle
between iterations ready for the next start pulse). The remaining fail-closed
boundaries are deliberate: a cross-domain `(do child)` with **no** covering activation
crossing is rejected; a **declared-but-unused** crossing (one whose `child` no
transaction actually `(do)`es) or one whose `child` is not in the declared
destination domain is rejected; and cross-domain `(spawn)` plus deeper cross-domain
`(do)` placements beyond those shipped contexts remain deferred. Declaring a
crossing alone creates no activation: a supported source-domain `(do child)`
must use it.

Normal `?rtl` children still need externally supplied RTL; FSMGen does not
invent module internals from a matching port list. When the marker is present,
the composition realizer emits a concrete Verilog-family child module beside
the generated domain modules and top.

The generated CDC module contains:

- a source-domain event toggle;
- two acknowledgement synchronizer registers in the source clock domain;
- two request synchronizer registers in the destination clock domain;
- a destination-side seen-toggle register and acknowledgement toggle; and
- a one-cycle `pulse` register in the destination clock domain.

When domain resets are present, their kind and polarity are copied into the
generated `?rtlif` metadata. The CDC child uses that metadata to choose
synchronous versus asynchronous event controls and active-high versus
active-low reset conditions. It also synchronizes the opposite side's
reset-active condition before allowing new source requests or destination
pulses, so a reset on one side does not create a spurious event on the other.

When a domain intentionally omits a reset, the generated CDC metadata marks the
absence with `SOURCE_RESET_PRESENT 0d0` or `DEST_RESET_PRESENT 0d0`. The
`isf/clock_domain_no_reset_event_crossing.isf` fixture proves that lower-result
review artifacts, in-process schedule reports, and `--emit-schedule-json`
preserve this metadata. Plain HDL generation for that fixture emits reset-free
domain modules and a generated CDC child without absent reset ports.

Plain `.isf` HDL generation now writes the generated `.fsm` artifacts and then
feeds the generated top through the normal composition HDL path. For accepted
event-crossing actors on SystemVerilog/Verilog-family targets, including
clock-only no-reset domains, the final HDL contains the domain modules, the
concrete generated CDC module, and the generated top that instantiates all of
them.

The remaining fail-closed boundaries are deliberate: direct cross-domain data
reads or writes are still illegal, multi-bit payload transfer is not part of
the event primitive, FIFO-like CDC is not inferred, reset assertion or
deassertion is not treated as a data event, and non-Verilog-family generated
top/CDC HDL targets remain outside the shipped backend scope.

## Reset

```lisp
(reset (rst_n async active_low))       ;; omitted reset default
(reset rst_n)                          ;; sync, polarity from _n → active_low
(reset (rst_n))                        ;; sync, polarity from _n
(reset (rst_n async))                  ;; async, polarity from _n
(reset (rst_n sync active_low))        ;; explicit synchronous policy
(reset (rst_n async active_low))       ;; explicit
(reset rst)                            ;; sync, active_high (no _n suffix)
```

Reset name convention: `*_n` or `*_b` suffix → `active_low`. Otherwise `active_high`.

A reset clause takes exactly one name or one list. The list accepts at most one
timing option (`sync` or `async`) and one polarity option (`active_low` or
`active_high`), in either order. Without a timing option it is synchronous.
Unknown, nested, repeated or contradictory options and extra clause operands
are errors in both ordinary and strict checking, including inside named domains.
An empty list is also an invalid option: `(reset (rst_n ()))` is rejected,
while `(reset (rst_n))` remains valid synchronous shorthand.
For example, `(reset (rst_n asnyc active_low))` fails with an unsupported-option
diagnostic; a misspelling cannot silently select synchronous hardware.

If a legacy single-clock actor omits `(reset ...)`, the parser normalizes its
reset to asynchronous active-low `rst_n`. Explicit flat `(reset name)` keeps
the shipped synchronous reset shorthand. A testbench using that shorthand must
hold reset active across a rising clock edge before checking registered outputs.
For example, assert `rst_n=0` at a falling edge, wait for the next falling edge
(which spans a rising edge), then check outputs before releasing reset. Checking
one time unit after assertion without a rising edge assumes asynchronous
behavior and does not test this contract.

### Omitted reset versus hardware without reset

Omitting a legacy actor's reset clause selects the documented `rst_n` default.
Successful ISF check/semantic JSON records clause origin separately in
`source.reset_provenance`; schedule JSON uses `reset_provenance` at its root.
For an omitted legacy reset the value is:

```json
[{"domain": null, "origin": "legacy_default"}]
```

Writing `(reset (rst_n async active_low))` instead gives `origin: "explicit"`
with the same effective reset policy and generated hardware. `explicit` means
that an ISF reset clause exists; it does not prove that all kind/polarity operands
were written, nor that a separate upstream specification states a reset.
`explicit_system_contract` describes the lowered FSM carrier, so use the
provenance field to distinguish authored ISF reset from compiler defaults.

A standalone clock-only actor is accepted through a named domain; CDC is not
required:

```lisp
(actor link_state
  (clock-domains (domain link (clock clk)))
  (interface (input start) (output done))
  (transaction main (on start) (complete done)))
```

This form selects hardware **without a reset**. Its provenance is
`[{"domain":"link","origin":"domain_absent"}]`. Schedule `reset` and semantic
reset fields are null. The emitted SystemVerilog and Verilog declare the state
register without an initializer and only clock `next_state` into it; there is
no reset branch or `initial` block. FSMGen therefore supplies no guaranteed
initial FSM state. A simulator's default value is not an initialization promise.
Clock-only direct VHDL remains outside the supported reset-bearing subset.

Storage `(reset V)` describes a hardware-reset value, not power-on
initialization. Without an effective domain reset, written storage still
updates from ordinary writes and holds its current value otherwise; read-only
storage gains no initialization or fabricated write. An explicit domain reset
supplies those reset assignments. T1980 qualifies both cases by inspecting
actual public reports and emitted SystemVerilog/Verilog, without a simulator.

Neither existing spelling represents a deferred implementation choice of reset
kind or polarity. If the source specification is silent, retain that fact in
the source model rather than treating clock-only hardware as its equivalent.
Legacy omission is suitable only if selecting the documented implementation
default is acceptable. A source adapter that requires the choice to remain
unresolved cannot express that requirement with an existing reset form.
The supplied examples, complete baseline public products, emitted HDL and
independent evidence checks are retained under
`docs/audits/specforge-unstated-reset-20260930/`; this baseline is static emission
and report qualification, not a runtime initialization test.

For multiple named domains, provenance lists every domain in authored order;
an explicit domain reset has `origin: "explicit"`. A legacy actor uses null
for `domain`. An actor hash constructed without parser evidence reports null
provenance; FSMGen does not guess from its effective reset. Failed checks and
direct `.fsm` inputs have no `source.reset_provenance` field.

The capability manifest advertises the entry keys, values and meaning through
`embedding.isf_public_interface.schedule_report_reset_provenance` and both
check/semantic report contracts' `source_optional_fields.reset_provenance`.
These values are identical through native queries, the public API and newline
MCP. Decision `0112` owns the separation between provenance and hardware policy.

**Lowering to .fsm**:
| ISF | .fsm |
|-----|------|
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst active_high)` |
| `(reset rst_n)` | `(sreset rst_n active_low)` |
| `(reset rst_b)` | `(sreset rst_b active_low)` |
| `(reset reset)` | `(sreset reset)` |
| `(reset (rst_n active_high))` | `(sreset rst_n active_high)` |

The emitter preserves the normalized ISF kind and polarity. It writes an
explicit FSM polarity when the legacy keyword default or strict FSM name
convention would misrepresent that policy. For example, ISF's flat `resetn`
has no `_n`/`_b` suffix and remains synchronous active-high, lowering to
`(sreset resetn active_high)`. The FSM naming heuristic does not reinterpret it.
Already strict-supported legacy carriers keep their spelling. See
[explicit FSM reset polarity](03-decision-trees-and-fsms.md#explicit-reset-polarity).

The same rule applies to ordinary actors and every scheduled domain. Domain
FSMs and generated CDC metadata use the same authored policy; active-low
reset on the original event-crossing fixture now reaches strict HDL faithfully.
Clock-only domains still have no reset port or reset logic. Inspect the
original fixture through the CLI:

```bash
./bin/fsmgen --strict --check --json isf/clock_domain_event_crossing.isf
./bin/fsmgen --strict --emit-semantic-json isf/clock_domain_event_crossing.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_event_crossing.isf
```

Schedule `reset` and `clock_domains[].reset` retain `name`, `kind` and
`polarity`. Ordinary normalized FSM contracts retain `reset_kind` and
`reset_active_level`. The public APIs and MCP check, semantic and schedule
queries preserve the complete native reports, including non-default reset
policies. No report schema or field family changes for this repair.

For the multi-domain source model, reset ownership lives inside each domain
entry:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain io (clock bus_clk) (reset (bus_rst_n async active_low))))
```

Each domain owns zero or one reset. A synchronous reset is sampled only on the
owning domain clock edge. An asynchronous reset is a direct external reset pin
for that domain's clocked state; ISF rules, transactions, drives, and DTs must
not generate or gate arbitrary asynchronous reset trees. Reusing one reset
signal across multiple domains is only a shared external reset pin when kind
and polarity match exactly, not a CDC primitive or data synchronizer.

## Watchdog

```lisp
(watchdog 65535)
```

Global timeout for every `(await ...)` in this actor.

If the author omits `(watchdog ...)`, the parser normalizes the watchdog to
`65535`, exactly `(2^16 - 1)`.

See [Transactions](13b-transactions.md) for per-await semantics.

**Counter width** is inferred from the limit by the current scheduler.

## Interface

```lisp
(params
  (DATA_W 32))

(interface
  (input  start)                  ;; default width 1
  (input  addr  (width 32))       ;; explicit width
  (input  wdata (width DATA_W))   ;; actor scalar parameter width
  (output done)                   ;; default width 1
  (output rdata (width DATA_W))
  (output PADDR (width 32)))
```

Port widths become `.fsm` `+size` declarations. Inferred scheduler
storage is not emitted a second time when it shares a name with a declared port.

Parameter-backed widths retain their scoped declaration in the scheduled
carrier. For example, `wdata` above has `+size` entry
`(wdata (param DATA_W))`; its parser width remains the selected default 32,
while eligible SystemVerilog declarations use `[(DATA_W - 1):0]`. Existing
numeric width fields in reports continue to describe the selected environment.
The same distinction applies to actor scalar storage, scalarized bank entry
widths and actor-parameter-backed transaction ports. An enum-backed parameter
still supplies a mutable parameter root. Bank depth remains a source-time
scalarization decision; preserving an element-width range does not make the
number of entries generic.

Actor and transaction parameter environments remain separate, including source
default and alias bindings beside their selected numeric caches. Equal default
widths do not establish a shared dependency. Named scalar types keep their own
type references. Broader override propagation, library shape specialization and
complete runtime qualification remain separate boundaries.

Declared inputs remain public even when no transaction or rule reads them.
The scheduled FSM carries their roles in `+interface`; `+size` carries their
widths. This applies to ordinary actors, a named single domain, and each
partitioned domain module. A generated top routes each input to its owning
domain without requiring a dummy read to keep the endpoint alive.

For example, `spare_bus` is an unused input that still appears as a vector
port in generated HDL:

```lisp
(actor single_unused (clock clk) (reset rst_n)
 (interface (input start) (input spare_bus (width 9)) (output done))
 (transaction work (on start) (complete done)))
```

Save this source as `.artifacts/single_unused.isf`, then inspect it with
`./bin/fsmgen --strict --emit-semantic-json .artifacts/single_unused.isf`.
`semantic.signal_analysis.inputs` includes `spare_bus` with direction `input`
and width `9`. The schedule report counts declared inputs, including unused
ones. Multi-domain top counts also include clock/reset pins; per-domain
`ports.inputs` lists the authored inputs owned by that domain. Join each
domain's `scheduled_fsm` to its semantic composition child to inspect the
realized interface, including crossing handoffs. `fsmgen_check`,
`fsmgen_semantic_introspect` and `fsmgen_schedule_preview` expose the same
native reports through the API and newline MCP adapter.

Declared outputs likewise remain public even without a transaction or rule
assignment. For example, this output has a fixed resolved width and no
invented value:

```lisp
(actor output_boundary
  (params (MECID_WIDTH 16))
  (clock clk) (reset rst_n)
  (interface (input start) (output AWMECID (width MECID_WIDTH)) (output done))
  (transaction work (on start) (complete done)))
```

The scheduled FSM carries `(output AWMECID)` in `+interface` and its width
in `+size`. Semantic `signal_analysis.outputs` and generated HDL retain the
port; no data assignment is synthesized for it. This preserves interface
identity, not a defined runtime value. Ordinary and named-domain actors use
the same role path; multi-domain tops wire each output from its owning domain.
Parent-only spare outputs do not become unrelated transaction-child ports.
Native check/semantic/schedule queries and their API/MCP projections agree.
SystemVerilog, Verilog and the supported direct VHDL subset preserve the
undriven declaration. Generic width overrides and optional presence remain
separate unsupported extensions.

An explicit `(reset V)` on an otherwise undriven output creates a register
that takes `V` on the module's hardware reset and holds it after reset. No
power-up value is promised before a reset event. Synchronous resets act on
the clock edge; asynchronous resets also act on the configured reset edge.
Both active levels follow the actor reset declaration. For example:

```lisp
(actor reset_only_output
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output tag (width 5) (reset 19))
    (output ready_flag (reset 1))
    (output done))
  (transaction tx (on start) (complete done)))
```

Here `tag` becomes 19 and `ready_flag` becomes 1 when reset is asserted; both
hold their values while transactions run. Adding `(default V)` instead adds
idle/quiescent writes, as documented above. Omitting both a reset and a writer
leaves an output undriven. Reset metadata does not create a hardware reset
port when the module's system contract has none. Clock-only sequential
processes currently generate in the Verilog targets but fail closed in the
direct VHDL converter; they are outside its reset-bearing process subset.

The shared register plan drives SystemVerilog, Verilog and the supported
direct VHDL subset. Native semantic reports and API/MCP projections include
reset-only `output_drive_families`: `multiplexer_type` is `flop`,
`default_value` is the signal itself (hold), `reset_value` carries the effective reset value,
and `driver_count` is zero because there are no authored data-driver blocks.
Empty RHS/enable lists distinguish these from ordinary data-driven outputs.

Actor port options are a closed set: `(width N)`, `(type NAME)`,
`(domain NAME)`, and output-only `(reset V)` / `(default V)`. Each option
must be a non-empty list with a scalar name and its documented arguments.
Unknown names (including the unimplemented `(present ...)`), scalar options,
empty lists and nested option names fail in both default and strict modes.
Diagnostics identify the port and offending option or malformed shape.
Duplicate options and existing width/type/domain/value checks still apply.
Native check, semantic and schedule queries, the API, and newline MCP all
refuse the same invalid source at this shared parser boundary. Check and
semantic API/MCP failures preserve diagnostics; schedule API/MCP failures
retain the documented message-only adapter error.

Interface port names are unique across both input and output directions, and
the interface block itself is a singleton actor clause.

An interface `(width ...)` may be a positive integer literal, an actor-local
scalar parameter default, or a declared actor constant that resolves to a
positive integer. The parser returns the resolved integer width, scheduled
`.fsm` `+size` uses that integer, and `+params` or `+constants` still preserves
the authored declaration for review. Unknown symbolic width names, runtime
interface signals, zero-valued or non-scalar actor parameters, zero-valued
actor constants, and arbitrary expressions fail closed.

When an actor uses `(clock-domains ...)`, a port may add `(domain NAME)` to
declare the owning domain; omitted port domains inherit the actor default
domain. The annotation is ownership metadata only, not permission for another
domain to sample or drive the port directly.

### Declared interface metadata

Successful check and semantic JSON for a directly parsed ISF source expose
`source.interface_ports`. Schedule JSON exposes `interface_ports`; each realized
`clock_domains` entry also exposes its owned declarations with the same schema.
The array contains inputs in source order, followed by outputs in source order.
Unused inputs and undriven outputs remain present. Clock/reset pins, inferred
signals and generated private handshakes are outside this declaration census.

For example, save this as `.artifacts/port_metadata.isf`:

```lisp
(actor port_metadata
  (types (type byte (bits 8)))
  (clock clk) (reset rst_n)
  (interface
    (output spare (width 2))
    (input start) (input data (type byte)) (output done))
  (transaction main (on start) (complete done)))
```

Run `./bin/fsmgen --strict --check --json .artifacts/port_metadata.isf`,
`./bin/fsmgen --strict --emit-semantic-json .artifacts/port_metadata.isf`, or
`./bin/fsmgen --emit-schedule-json .artifacts/port_metadata.isf`. The declared
port array is:

```json
[
  {"name": "start", "direction": "input", "width": 1},
  {"name": "data", "direction": "input", "width": 8,
   "type": "byte", "type_kind": "bits"},
  {"name": "spare", "direction": "output", "width": 2},
  {"name": "done", "direction": "output", "width": 1}
]
```

Named-domain entries include the resolved owning `domain`. A known empty
interface yields `[]`. Schedule metadata is `null` when a caller-created actor
has no declaration evidence; hardware inference does not fill that gap.
Unrelated source formats and failure source reports omit `source.interface_ports`.
Metadata projection preserves supplied declaration facts and their original
JSON scalar kinds on both successful and refused validation.

Each entry requires `name`, `direction` and positive `width`. Optional `type`
retains the authored local/imported alias and `type_kind` describes its resolved
kind. Scalar aliases resolve to `bit` or `bits`. Packed record inputs also
carry ordered scalar-leaf `fields` with port-relative `path`, `width`, inclusive
`lsb`/`msb`, `signed` and optional `state_model`. Nested member/item paths retain
their exact packed ranges. Record output declarations and whole copies now have bounded source/carrier
admission with mandatory physical writer checks; complete public/generated/
execution qualification and output member writes remain open. Root-list ports
remain deferred;
see [Types and Aggregates](13j-type-enum-aggregate.md).

Discovery publishes the complete schema at
`embedding.isf_public_interface.schedule_report_interface_ports` and both
check/semantic contracts' `source_optional_fields.interface_ports`.
`fsmgen_check`, `fsmgen_semantic_introspect` and `fsmgen_schedule_preview`
carry the same native reports through the API and newline MCP adapter.
Declaration metadata adds no hardware assignments, sampling or reset policy.
The maintained runnable fixture is [interface_port_metadata.isf](../../../isf/interface_port_metadata.isf).

## Actor-Owned Storage

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width PTR_W))
  (var occupancy (width 3))
  (bank data (width DATA_W) (depth DEPTH)))
```

Ordinary actors and their clock-domain partitions preserve declared storage
with explicit `(internal NAME)` roles in the generated FSM `+interface`.
Read-only and unused storage stays internal; `+size` retains widths, types
and authored reset metadata. Scalarized bank elements follow the same rule.
The role survives independent replay of the generated `.fsm`, and native,
API and MCP semantic inventories exclude these signals from public ports.
Generated transaction children read scalar, packed aggregate and scalarized
bank storage through explicit live handoffs, including inside independent
clock domains. Reads create neither public top inputs nor private child register
copies; unrelated storage is absent from the child. Updates remain visible
after activation. Full-width scalar and packed aggregate writes from a sole
generated instance use
combinational data/enable handoffs and update the owning register on the original
assignment edge. The owner alone holds its register and reset; domain crossings
are not implicit. Explicit transaction ports and transaction-local storage keep
their separate roles.

Generated-child partial/member and bank writes, plus competing parent/child
or multiple-child writers, remain refused while their contracts are qualified.
The existing `storage_port` resource arbitrates rule users; it does not supply
an implicit priority or stall policy for child transactions. See
[generated-child storage ownership](13f-composition.md) for executable examples
and the current boundaries selected by decision `0107`.

A read-only reset register needs no dummy write to preserve its ownership:

```lisp
(actor storage_readback
  (clock clk) (reset (rst_n async active_low))
  (interface (input start) (output value (width 8)) (output done))
  (storage (var status (width 8) (reset 19)))
  (transaction read_status
    (on start)
    (update value status)
    (complete done)))
```

After hardware reset, starting the transaction copies the authored status
reset value to `value`. The module has no `status` port. Ordinary writes to
other storage still use the existing register assignment path.

The shipped actor-owned storage forms are fixed-width internal scalar
variables and fixed-depth banks. The preferred scalar spelling is
`(var name (width N|PARAM|CONST))`; `(variable ...)` is the verbose alias.
When `PARAM` is used for scalar storage width, bank width, or bank depth, it
must name an actor-local scalar parameter default that resolves to a positive
integer. When `CONST` is used for scalar storage width, bank width, or bank
depth, it must name a declared actor constant that resolves to a positive
integer. A scalar entry lowers to one internal storage signal with the
authored name. A bank lowers to deterministic scalar element names in the
scheduled `.fsm` review artifact: `data_0`, `data_1`, `data_2`, and so on up
to the resolved depth.

Each private bank-element width association retains the bank declaration and
its explicit element index. The authored depth reference stays separate from
the width reference. Neither association changes the fixed resolved dimensions
or the authored reset values.

This scalarized representation is deliberate for the first reusable FIFO work.

It lets the `DEPTH=4` fixture use four concrete storage entries, 2-bit
pointers, and 3-bit occupancy state while staying on the existing scalar
signal/flop backend path. Actor-owned scalar storage widths and bank widths
may use actor-local scalar parameter defaults or declared actor constants that
resolve to positive integers. Bank depths may use actor-local scalar parameter
defaults or declared actor constants that resolve to positive integers.
Dynamic storage depth, arbitrary storage dimension expressions, and
memory-array backend emission remain future generalizations.

Pointer-selected access is available through explicit action forms such as
`(store data wr_ptr data_in)` and `(load data rd_ptr as data_out)`, which
lower through guarded scalarized entries.

### Storage reset values — register maps / CSRs

A scalar storage `var` may carry a **hardware reset value** with an optional `(reset V)`,
so hardware reset sets a control/status register to a specified value — the
common need for a **register map** (CSR block):

```lisp
(storage
  (var ctrl   (width 8) (reset 1))     ;; hardware reset enables this register
  (var mode   (width 8) (reset 16))    ;; mode field's reset default
  (var status (width 8)))              ;; no reset-only driver without an ordinary writer
```

`(reset V)` (a non-negative integer literal that fits the width) emits the `+size` carrier
`(NAME width (reset V))`, and the generated HDL reset block assigns the register that value
(`ctrl <= 1` instead of `ctrl <= 0`). A register with an ordinary writer
uses the existing zero reset default when no `(reset V)` is given. An unwritten
storage declaration without explicit reset metadata remains declared but undriven;
neither its role nor field metadata supplies an initial value. An explicitly
reset but unwritten scalar resets and holds, including when unused. A module
without a hardware reset acquires no reset-only initialization. Hardware reset
is distinct from power-up initialization and from transaction-local init-on-entry
`(default V)`/`(init V)` on a `(local …)`. A per-element bank `(reset V)`, and an over-width or non-integer reset value,
fail closed. Reset fit is checked after resolving literal, parameter, constant
and named-type widths; an 8-bit type rejects reset `256` just like `(width 8)`.

A complete register-map actor — two CSRs that reset to their specified values and are
written/read by a transaction (this lowers cleanly and passes Verilator/Yosys):

```lisp
(actor csr_block
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input wdata (width 8))
    (output done)
    (output ctrl_out (width 8))
    (output mode_out (width 8)))
  (storage
    (var ctrl (width 8) (reset 1))      ;; control register resets to 1
    (var mode (width 8) (reset 16)))    ;; mode register resets to 16
  (transaction main
    (on start)
    (set ctrl wdata)
    (set mode wdata)
    (update ctrl_out ctrl)
    (update mode_out mode)
    (complete done)))
```

Out of reset the generated HDL holds `ctrl` at `1` and `mode` at `16`; both are then
writable from `wdata` and read out on `ctrl_out`/`mode_out`.

### Declarative Storage Fields

A scalar storage `var` may also carry a checked, declarative field map. This
is metadata on the parent word. It does not generate field-level RTL, access
policy logic, assertions, or reset derivation.

```lisp
(actor csr_fields
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input wdata (width 8))
    (output done)
    (output control_out (width 8)))
  (storage
    (var control (width 8) (reset 161)
      (fields
        (field mode (bits 7 5) (access rw) (reset 5)
          (enum (IDLE 0) (RUN 5)))
        (field prio (bits 4 2) (access rw))
        (field enable (bits 0 0) (access rw) (reset 1)
          (enum (OFF 0) (ON 1))))))
  (transaction main
    (on start)
    (set control wdata)
    (update control_out control)
    (complete done)))
```

The `control` register still lowers as one 8-bit storage word. Its scheduled
`.fsm` is byte-identical to the same source without `(fields ...)`, and the
HDL reset behavior still comes only from the parent `(reset 161)`. The report
adds `inferred_storage[].fields` on the `control` storage entry so downstream
tools can see `mode`, `prio`, and `enable` without parsing comments.
The repository fixture `isf/storage_fields.isf` carries this same public
surface and is support-accounted through check JSON and normalized semantic
JSON; the field map itself remains a schedule JSON payload.

Each field uses `(field NAME (bits HI LO) ...)`; names are unique HDL
identifiers, ranges are literal and inclusive, gaps are allowed, and
overlaps or ranges outside the parent width fail closed. Optional
`(access ro|rw|wo|w1c|w0c|rc|rs|warl|wpri|reserved)` is metadata only.
A width-based scalar `var` or `variable` may also carry `(access TOKEN)` on
the word itself, with the same lowercase vocabulary. The word and its fields
state independent facts: neither inherits from the other and they need not
match. Omitting a word access omits `inferred_storage[].access`; omitting field
access omits that field's `access`. No placeholder field is needed.

```lisp
(actor storage_word_access
  (clock clk)
  (reset rst_n)
  (interface (input start) (input wdata (width 8))
             (output done) (output status_out (width 8))
             (output control_out (width 8)))
  (storage
    (var status (width 8) (reset 0) (access ro))
    (variable control (width 8) (reset 0) (access rw)
      (fields (field enable (bits 0 0) (access ro)))))
  (transaction main (on start)
    (set control wdata)
    (update status_out status)
    (update control_out control)
    (complete done)))
```

Here `status` reports word `access: "ro"` without fields. `control` reports
word `access: "rw"`, while `enable` independently reports field `access: "ro"`.
The assignment remains ordinary authored behavior; access labels do not install
write protection or read/clear logic. The public fixture
`isf/storage_word_access.isf` also demonstrates word metadata with and without
fields. Single-clock schedule/API/MCP reports retain it in `inferred_storage[]`.
Multi-domain reports retain it in each `clock_domains[].inferred_storage[]`;
the existing domain `storage` name lists remain unchanged and the generated
top has no domain-owned storage entries of its own.
Check and semantic queries validate the source and identify the supported
fixture; the metadata payload belongs to the schedule report.

Unknown tokens, duplicate options, missing/nested/extra values, banks and typed
storage fail closed with storage-specific diagnostics. Word access changes no
scheduled `.fsm`, generated HDL, hardware reset, assertions or register model.
Optional field `(reset V)` must match the corresponding bit slice of an
explicit parent storage reset. Inline `(enum (NAME VALUE)...)` metadata is
accepted when values fit the field width. Actor `(enums ...)` references,
typed storage fields, banks, aggregate carriers, packet/flit layouts, access
enforcement, generated register models, and parent reset derivation are
deferred.

Actor `var` and `variable` names must be simple HDL identifiers that are not
keywords in any shipped target. SystemVerilog keyword matching is
case-sensitive; VHDL matching is case-insensitive. For example, `cell`,
`process` and `PROCESS` are rejected with the actor, variable name, reserving
target and rename guidance. Use `value_reg` or another legal name. FSMGen does
not silently rename authored storage variables or escape them per target.

Bank names identify logical storage. `(bank cell (width 4) (depth 2))` remains
valid because its emitted elements are `cell_0` and `cell_1`; the logical name
is not emitted as a standalone HDL signal. Field metadata names likewise do
not declare separate registers. This check covers actor storage variables;
other identifier families retain their own validation contracts.

`(storage ...)` is a singleton actor clause. Storage names and scalarized
element names must not collide with interface ports, actor clock/reset signals,
or generated scheduler signals such as `can_accept`. Missing scalar storage
`(width N|PARAM|CONST)`, missing bank `(depth N|PARAM|CONST)`, duplicate
storage names, duplicate scalarized element names, unknown parameter or
constant names, runtime interface signals, zero-valued or non-scalar actor
parameters, zero-valued actor constants, arbitrary width/depth expressions,
and repeated storage clauses fail closed before scheduler handoff.

When `(clock-domains ...)` is present, storage entries may add `(domain NAME)`.

The domain applies to every scalar signal produced by that entry, including
scalarized bank elements.

Declared storage is emitted in scheduled `.fsm` `+size`, contributes width
evidence to later lowering, and appears in schedule reports as `kind:
register`, `role: actor_storage`, with positive integer `width`. Declared
typed actor-owned storage may also report the authored `type` and resolved
`type_kind`; the full shape remains in the scheduled `.fsm` review artifact.

Used storage signals reach SystemVerilog through the normal scalar assignment
path.

The report `kind` is the generated storage class; authored scalar storage uses
the normalized scalar storage kind. `(state ...)` and `(register ...)` are not
accepted storage entry spellings.

### Complete Example — APB Interface

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65535)

  (interface
    ;; Local side
    (input  start)
    (input  req_write)
    (input  req_addr  (width 32))
    (input  req_wdata (width 32))
    (output done)
    (output last_read_data (width 32))
    (output last_error)
    ;; APB bus side
    (output PADDR   (width 32))
    (output PWRITE)
    (output PWDATA  (width 32))
    (output PSEL)
    (output PENABLE)
    (input  PREADY)
    (input  PRDATA  (width 32))
    (input  PSLVERR))

  (drive (psel val)     (PSEL val))
  (drive (penable val)  (PENABLE val))
  (drive setup_phase
    (PADDR addr)
    (PWRITE wr)
    (PWDATA wdata)
    (PSEL 1)
    (PENABLE 0))

  (transaction apb_transfer
    (on start
      (sample req_addr  as addr)
      (sample req_write as wr)
      (sample req_wdata as wdata))
    (drive setup_phase)
    (drive penable 1)
    (await PREADY)
    (complete done)))
```

**Generated .fsm**:
```lisp
(?fsm:apb_requester
  (+system (clock clk) (areset rst_n))
  (+size
    (start 1) (req_write 1) (req_addr 32) (req_wdata 32)
    (done 1) (last_read_data 32) (last_error 1)
    (PADDR 32) (PWRITE 1) (PWDATA 32)
    (PSEL 1) (PENABLE 1) (PREADY 1) (PRDATA 32) (PSLVERR 1)
    ...)
  ...)
```

## Implicit Signals

These are auto-generated by the scheduler:

| Signal | Width | Purpose |
|--------|-------|---------|
| `can_accept` | 1 | Combinational: `1` in idle, `0` elsewhere |
| `{drive}_start` | 1 | Asserted by drive calls to enable the drive non-state DT |
| `{drive}_{param}` | target-derived | Per-parameter signal, wired to the actual value; its width follows the driven output (`1` for a scalar output) |
| `{transaction}_cnt` | inferred | Repeat counter |
| `{transaction}_wd` | inferred | Watchdog counter |
| `{transaction}_cc` | inferred | Latency cycle counter |

## Actor Constants Example

The `(constants ...)` clause declares actor-wide static integer
values. They are visible inside transaction bodies as scalar
operands for waits, repeat counts, latency bounds, and contract
windows.

```lisp
(actor constants_demo
  (constants
    (DELAY 8)
    (RETRY_LIMIT 3))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction tx
    (on start)
    (wait DELAY)
    (complete done)))
```

**Walkthrough.** `(constants (DELAY 8) (RETRY_LIMIT 3))` declares
two actor-wide static integers. They appear in `+constants` and
`actor_constants[]` review surfaces and the resolved values are
available internally. The transaction uses `(wait DELAY)` — the
schedule waits 8 cycles. `RETRY_LIMIT` is unused in this example;
authors can drop or wire it as the design evolves. Constants are
visible to every transaction in the actor.
