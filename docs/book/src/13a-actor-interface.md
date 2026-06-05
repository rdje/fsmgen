# Actor and Interface

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
  (domain bus  (clock bus_clk)))
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

The implementation is intentionally artifact-first. `lower(...)` does not turn
one `.fsm` module into a hidden multi-clock state machine. It partitions the
actor into one ordinary scheduled `.fsm` per declared domain, using
`<actor>__domain_<domain>.fsm` names, then emits `<actor>_top.fsm` as a
composition source. The top instantiates each domain module with `?fsmc` and
owns only wiring plus explicit CDC child interfaces.

For example, an actor named `clock_domain_event_crossing` with domains `bus`
and `core` emits these review artifacts:

```text
clock_domain_event_crossing__domain_bus.fsm
clock_domain_event_crossing__domain_core.fsm
clock_domain_event_crossing_top.fsm
```

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
    (from bus  rx_done_bus)
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
  (activation worker (from core) (to bus)))
```

`worker` names a declared transaction in the destination domain (`bus`); the
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
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input  start (domain core))
    (output done  (domain core))
    (input  din    (width 8) (domain bus))
    (output result (width 8) (domain bus))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
```

This lowers to `cross_domain_activation__domain_core.fsm` (the caller),
`cross_domain_activation__domain_bus.fsm` (`worker`), and
`cross_domain_activation_top.fsm`, which instantiates both domain modules and the
two CDC children
`cross_domain_activation__cdc_activation_worker_start` and
`...__cdc_activation_worker_done`. Plain HDL generation emits all five modules
(two domain modules, two CDC children, the top).

The handshake mirrors the event-crossing source idiom on both directions:

- The caller (`core`) awaits `worker_start_ready` (the start CDC ready), drives a
  one-cycle `worker_start` request, then blocks on the `worker_done` pulse.
- The start CDC synchronizes the request `core → bus` and emits a one-cycle
  `worker_start` pulse in the destination, which gates `worker`'s entry.
- On completion, `worker` awaits `worker_done_ready`, drives a one-cycle
  `worker_done` request, which the done CDC synchronizes `bus → core` and pulses
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
`(do)` placements beyond those shipped contexts remain deferred.

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
(reset (rst_n async active_low))       ;; explicit
(reset rst)                            ;; sync, active_high (no _n suffix)
```

Reset name convention: `*_n` or `*_b` suffix → `active_low`. Otherwise `active_high`.

If a legacy single-clock actor omits `(reset ...)`, the parser normalizes its
reset to asynchronous active-low `rst_n`. Explicit flat `(reset name)` keeps
the shipped synchronous reset shorthand.

**Lowering to .fsm**:
| ISF | .fsm |
|-----|------|
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst)` |
| `(reset rst_n)` | `(sreset rst_n)` |

For the multi-domain source model, reset ownership lives inside each domain
entry:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
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

Ports become `.fsm` `+size` declarations and module ports. Inferred scheduler
storage is not emitted a second time when it shares a name with a declared port.

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

## Actor-Owned Storage

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width PTR_W))
  (var occupancy (width 3))
  (bank data (width DATA_W) (depth DEPTH)))
```

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
so a control/status register powers up at a specified default instead of all-0s — the
common need for a **register map** (CSR block):

```lisp
(storage
  (var ctrl   (width 8) (reset 1))     ;; control register powers up enabled
  (var mode   (width 8) (reset 16))    ;; mode field's reset default
  (var status (width 8)))              ;; status powers up at 0 (no (reset …))
```

`(reset V)` (a non-negative integer literal that fits the width) emits the `+size` carrier
`(NAME width (reset V))`, and the generated HDL reset block assigns the register that value
(`ctrl <= 1` instead of `ctrl <= 0`). When no `(reset V)` is given the register resets to
all-0s, exactly as before (fully backward-compatible). `(reset V)` is a hardware power-up
value — distinct from the transaction-local init-on-entry `(default V)`/`(init V)` on a
`(local …)`. A per-element bank `(reset V)`, and an over-width or non-integer reset value,
fail closed.

A complete register-map actor — two CSRs that power up at their specified defaults and are
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
    (var ctrl (width 8) (reset 1))      ;; control register powers up at 1
    (var mode (width 8) (reset 16)))    ;; mode register powers up at 16
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
| `{drive}_{param}` | 1 | Per-parameter signal, wired to actual value |
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
