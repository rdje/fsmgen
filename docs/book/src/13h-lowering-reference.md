# Lowering Reference

Every ISF construct maps to specific `.fsm` patterns.

This chapter shows the exact generated `.fsm` for each construct.

## Actor → Module

```lisp
(actor name
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65535)
  (interface ...)
  (drive ...)
  (transaction ...))
```

↓

```lisp
(?fsm:name
  (+system (clock clk) (areset rst_n))
  (+size ... inferred signals ...)
  (transaction_states ...)
  (-drive_dt_blocks ...)
  (-can_accept_ctrl ...))
```

Single-domain `(clock-domains ...)` actors lower through the same one-clock
scheduled `.fsm` path using the declared domain clock/reset. Multi-domain
actors emit validated per-domain scheduled `.fsm` artifacts named
`<actor>__domain_<domain>.fsm` plus `<actor>_top.fsm` generated top wiring.

Accepted event crossings are represented as explicit CDC `?rtl`/`?rtlif`
child interfaces in the generated top. Schedule reports expose the generated
top scope, each domain artifact, and accepted event crossing metadata;
accepted event-crossing actors now emit SystemVerilog/Verilog-family HDL with
the generated top and concrete acknowledged-event CDC child modules for
accepted crossings when each emitted domain artifact satisfies the current
scheduled `.fsm` HDL contract, including clock-only no-reset domains.

## Multi-Domain Actor -> Domain FSMs + CDC Top

For a reset-declared two-domain actor with one event crossing:

```lisp
(actor clock_domain_event_crossing
  (clock-domains
    (domain bus  (clock bus_clk)  (reset bus_rst_n) :default)
    (domain core (clock core_clk) (reset core_rst_n)))
  (crossings
    (event byte_ready
      (from bus byte_ready_req)
      (to core byte_ready_pulse)
      (ready byte_ready_ready)))
  ...)
```

`lower(...)` emits ordinary scheduled `.fsm` files for each domain plus one
composition top:

```text
clock_domain_event_crossing__domain_bus.fsm
clock_domain_event_crossing__domain_core.fsm
clock_domain_event_crossing_top.fsm
```

The bus artifact is still a normal single-clock `.fsm`:

```lisp
(?fsm:clock_domain_event_crossing__domain_bus
  (+system
    (clock bus_clk)
    (sreset bus_rst_n))
  (+size
    (bus_start 1)
    (byte_ready_ready 1)
    (byte_ready_req 1)
    ...)
  ...)
```

The core artifact is the same shape with `core_clk`, `core_rst_n`, and the
destination pulse input. No domain artifact directly reads or writes another
domain's local signal.

The generated top owns the inter-domain wiring:

```lisp
(?top:clock_domain_event_crossing_top
  (?ports:public_io
    bus_clk
    bus_rst_n
    core_clk
    core_rst_n
    bus_start
    core_seen>
  )
  (?fsmc:bus clock_domain_event_crossing__domain_bus)
  (?fsmc:core clock_domain_event_crossing__domain_core)
  (?rtl:byte_ready_cdc clock_domain_event_crossing__cdc_event_byte_ready)
  (?wiring:domain_wiring
    /bus_start/bus.bus_start/
    /core.core_seen/core_seen/
    /bus_clk/byte_ready_cdc.source_clk/
    /core_clk/byte_ready_cdc.dest_clk/
    /bus_rst_n/byte_ready_cdc.source_reset/
    /core_rst_n/byte_ready_cdc.dest_reset/
    /bus.byte_ready_req/byte_ready_cdc.request/
    /byte_ready_cdc.ready/bus.byte_ready_ready/
    /byte_ready_cdc.pulse/core.byte_ready_pulse/
  )
)
```

Same-name domain clock/reset ports are intentionally left to the composition
system-port auto-wiring rule when the top and child use the same port name. The
CDC child uses role-specific names such as `source_clk`, `dest_clk`,
`source_reset`, and `dest_reset`, so those links are explicit.

The top embeds the generated CDC interface metadata immediately after the top
root:

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

`FSMGEN_ISF_CDC_EVENT` is the implementation marker. The normal external
`?rtl` path does not infer HDL from port shape. Only this marked metadata asks
the composition realizer to emit FSMGen's generated event-CDC module.

An actor may declare multiple independent event crossings. Each crossing emits
its own `?rtl` child, its own embedded `?rtlif` metadata root, its own bounded
`crossings[]` report entry, and its own concrete generated CDC HDL module.

The file-backed
`isf/clock_domain_dual_event_crossing.isf` fixture covers two opposite-direction
events in one generated top. This still carries no payload and creates no
ordering relationship between the event channels.

The file-backed `isf/clock_domain_no_reset_event_crossing.isf` fixture covers
domains that omit reset declarations. Lowering and schedule reports preserve
the generated CDC metadata with absent source and destination resets; plain
HDL generation emits reset-free domain modules and a generated CDC child that
omits the absent reset ports.

The generated CDC HDL is a toggle/acknowledge synchronizer. In outline, it
contains:

```verilog
assign ready = (source_ack_sync_2 == source_toggle) && !source_dest_reset_sync_2;

always @(posedge source_clk) begin
    ...
    source_ack_sync_1 <= dest_ack_toggle;
    source_ack_sync_2 <= source_ack_sync_1;
    if (request && ready) begin
        source_toggle <= ~source_toggle;
    end
end

always @(posedge dest_clk) begin
    dest_req_sync_1 <= source_toggle;
    dest_req_sync_2 <= dest_req_sync_1;
    pulse <= 1'b0;
    ...
    if (dest_req_sync_2 != dest_seen_toggle) begin
        dest_seen_toggle <= dest_req_sync_2;
        dest_ack_toggle <= dest_req_sync_2;
        pulse <= 1'b1;
    end
end
```

Reset metadata controls whether each generated `always` block has only a clock
edge or has clock plus asynchronous reset edge, and whether the condition is
active high or active low. When the opposite domain has a reset, the CDC child
synchronizes that reset-active condition before asserting source `ready` or
destination `pulse`. This avoids reporting an event while the other side is
still being reset.

The full plain `.isf` HDL path writes those generated `.fsm` artifacts to
`--outdir` or the current directory, selects `<actor>_top.fsm` as the entry
artifact, and feeds that top through the existing composition HDL pipeline.

The final SystemVerilog/Verilog-family output contains the two generated
domain modules, the generated CDC module, and the generated top module.

The source model can record domains without resets for `lower(...)`,
`report(...)`, and generated HDL. Clock-only domain artifacts emit reset-free
sequential blocks, and generated CDC children omit reset ports for endpoints
whose domains do not declare resets.

## Interface → +size

```lisp
(interface
  (input  start)
  (input  addr (width 32))
  (output done)
  (output rdata (width 32)))
```

↓

```lisp
(+size
  (start 1)
  (addr 32)
  (done 1)
  (rdata 32))
```

Declared interface ports are emitted once. If inferred scheduler storage such
as timeout/error bookkeeping has the same name as an interface port, the
inferred duplicate is suppressed.

When generated scheduled `.fsm` assigns a declared output port, the assignment
LHS carries the normal `.fsm` output marker, for example `done>` or `rdata>`.

## Reset → +system

| ISF | .fsm |
|-----|------|
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst)` |
| `(reset rst_n)` | `(sreset rst_n)` |

Reset name convention: `*_n` or `*_b` suffix infers `active_low`.

Explicit `async`/`active_low`/`active_high` override.

## `(on port ...)` → Entry State

**ISF**:
```lisp
(on start
  (sample req_addr  as addr)
  (sample req_write as is_write))
```

**Generated .fsm**:
```lisp
(apb_transfer_idle_0
  (= (can_accept 1))              ;; implicit: ready signal
  (<- (apb_transfer_wd 65534))    ;; watchdog: load max-1
  (<start                         ;; condition guard
    (<= (addr req_addr))          ;; sample: D-input capture
    (<= (is_write req_write))
    (-> apb_transfer_drive_1)))   ;; transition to first state
```

**Timing**: Idles until `start && can_accept`. Samples fire on the transition.
**Cycles**: 0 active cycles (waiting). 1 cycle for transition.

**Implicit signals**: `can_accept` (1, combinational, asserted in idle).

`(on ...)` is the transaction's own entry guard, not a generated activation
instance. It does not accept `(params ...)`; nested body clauses are limited to
`(sample port as name)`. Unsupported `(params ...)` body clauses fail with a
diagnostic that names the entry-guard/generated-activation boundary. Static
specialization must happen through generated activation forms such as `spawn`,
parameterized blocking `do`, or parameterized rule `trigger`.

## `(drive name args...)` -> One State + Non-State DT

**ISF**:
```lisp
(drive (scl val) (scl val))        ;; definition
(drive scl 1)                      ;; call
```

**Generated .fsm**:

Non-state DT block:
```lisp
(-scl
  (<- (scl> scl_val) <scl_start))  ;; flopped: next cycle scl = scl_val
```

Call state:
```lisp
(caller_state
  (= (scl_start 1))               ;; assert DT enable (combinational)
  (= (scl_val 1))                 ;; wire actual to parameter signal
  (-> next_state))                ;; always proceed
```

Actuals can be composed expression forms. For example,
`(drive scl (& bit_a bit_b))` lowers the parameter assignment as
`(= (scl_val (& bit_a bit_b)))`.

**Timing**: The `scl_start` assertion enables the non-state DT in the SAME cycle.

The DT's `<-` assignment takes effect NEXT cycle (flopped).

So `(drive scl 1)` → cycle N: assert start + wire value, cycle N+1: port changes.

**Cycles**: 1 per call. **No automatic merging.**
**Implicit signals**: `{name}_start` (1), `{name}_{param}` (1 per parameter).

## `(sample port as name)` → D-Input Assignment

**ISF**:
```lisp
(sample req_addr as addr)
```

**Generated .fsm**: Piggybacks on the current state — no separate state.
```lisp
(<= (addr req_addr))
```

Inside an `(on ...)` guard, the sample fires when the guard triggers:
```lisp
(<start
  (<= (addr req_addr))
  (-> next_state))
```

In a `(drive ...)` state, samples from preceding `(sample ...)` clauses
appear before the drive's start assertion:
```lisp
(drive_state
  (<= (val trigger))              ;; sample piggybacked
  (= (rdata_start 1))             ;; drive start
  (-> next_state))
```

**Timing**: Captures port value at the moment of transition.

The generated assignment is intentionally `<=`, not `<-`. In FSMGen's `.fsm`
assignment model, `<-` names the flop's Q/output side, while `<=` names the
D-input/next-value side. A sample needs the authored variable name to denote the
sampled next value in the state where the sample is emitted, even though the
registered value is still observed after the clock edge.

That distinction matters especially when a drive follows one or more samples
and the scheduler piggybacks those samples onto the drive state. For example:

```lisp
(sample din as hold)
(drive send hold)
```

can lower the sample and the drive parameter wiring into the same scheduled
state. With `<=`, same-state drive wiring that reads `hold` sees the sampled
D-side value. If the sample used `<-`, `hold` would mean the previous Q/output
value in that state, so the drive could receive stale data unless the scheduler
inserted an extra state. For a flow where the sampled name is consumed only in a
later state, `<-` can look equivalent, but it is not the correct general
contract for ISF sample lowering.

**Implicit signals**: None (sample creates a variable; scheduler infers register if needed).

## `(await port)` → Conditional Stall + Watchdog

**ISF**:
```lisp
(await PREADY)
```

**Generated .fsm**:
```lisp
(apb_transfer_await_3
  (<PREADY                         ;; port guard
    (-> apb_transfer_drive_4))
  (?apb_transfer_wd                ;; timeout check
    (=0 (-> apb_transfer_timeout))
    (>0 (-- apb_transfer_wd))))    ;; watchdog: decrement next value
```

**Timing**: Self-loops until `PREADY=1`. Each loop cycle checks the current
watchdog Q value and, when it is greater than zero, schedules the watchdog
decrement for the next value. The test-node branches are same-cycle selector
equations, not procedural statements executed top to bottom. The decrement is
guarded by `>0`, so the scheduled artifact does not describe a zero watchdog
underflowing to all ones. Timeout normally exits the await state, but the
lowering still keeps the counter's next-value selection aligned with the
current-Q test.
**Cycles**: 1 to watchdog_limit cycles (variable).
**Implicit signals**: `{tx}_wd` (log2(N) bits), plus timeout state.

The actor-level watchdog default and an await-local `(watchdog N)` override can
use a positive literal, declared positive actor constant, or actor-local scalar
parameter default that resolves to a positive integer. The scheduler resolves
the static value before counter-width inference and counter initialization.

Timeout state:
```lisp
(apb_transfer_timeout
  (<1 (done> 1))
  (<- (last_error> 1))
  (-> apb_transfer_idle_0))
```

## `(wait N)` -> Static Chain Or Runtime Counter

**ISF**:
```lisp
(wait 2)
```

**Generated .fsm**:
```lisp
(main_wait_1
  (-> main_wait_2))

(main_wait_2
  (-> main_drive_3))
```

The static shipped surface accepts a non-negative integer literal, an
actor-level constant name, an actor-local scalar parameter default, a
same-transaction scalar parameter default, or a qualified package scalar
constant that resolves to a non-negative integer literal. For a resolved
`N > 0`, lowering
emits exactly `N` generated `*_wait_*` states, each advancing unconditionally
to the next wait state or the following transaction clause. `(wait 0)` emits
no generated state, consumes no active transaction cycle, and falls through to
the following transaction clause. No hidden wait counter is introduced for
this static literal/constant/parameter/package-constant surface.

If samples are pending before a positive wait, they are emitted in the first
wait state:

```lisp
(main_wait_1
  (<= (addr req_addr))
  (-> main_wait_2))
```

If samples are pending before `(wait 0)`, they stay pending and are emitted on
the next state-producing clause instead.

Schedule reports expose each authored positive static wait through
`transaction_waits[]` with `transaction`, resolved integer `cycles`,
`count_kind`, `count_source`, `entry_state`, `exit_state`, `counter_signal`,
and `counter_width`. Only waits whose resolved count is greater than zero
create report entries. Static waits report `count_kind` as `static`,
`count_source` as the literal, actor constant name, actor parameter name,
transaction parameter name, or qualified package constant token, and
`counter_signal`/`counter_width` as null for the fixed-chain lowering.

Runtime scalar and runtime expression waits additionally expose their
generated sampled-count storage through `inferred_storage[]` with role
`dynamic_wait_counter` and the known counter width.

The shipped symbolic surface is `(wait NAME)`, where `NAME` is an actor-level
constant declared with `(constants (NAME value) ...)` or an actor-local scalar
parameter default declared with `(params (NAME value) ...)`, with
same-transaction scalar parameter defaults checked first in the owning
transaction. The value must resolve before lowering to a non-negative integer
literal. Once resolved, it uses the same fixed-chain lowering as a literal: a
resolved zero emits no wait state and a resolved positive count emits that
many wait states. Non-scalar transaction parameters, cross-transaction
parameters, non-scalar actor parameter defaults, and use-site override
specialization are not wait-count constants because they would require a
different fixed state chain after scheduled state emission.

The first runtime scalar surface is top-level only:

```lisp
(wait cycles)
```

The count source must be a scalar signal with a known unsigned width. The
predecessor edge is split instead of inserting a decision state:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt cycles) <(& start cycles))
  (-> main_wait_1 <(& start cycles))
  (-> main_drive_2 <(& start (== cycles 0))))

(main_wait_1
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1))))
```

The positive edge snapshots the runtime count into `main_wait_1_cnt` and
enters the generated wait state. The zero edge bypasses that state, so a
runtime zero still consumes no active wait cycle. Once the wait state is
entered, it reads only the sampled counter: a sampled value of `1` exits after
one active cycle, while values greater than `1` decrement and loop until the
counter reaches `1`.

If a top-level runtime wait has pending samples before it, the positive-count
path materializes those samples in the first active wait state. The zero-count
path goes to a sample-preserving clone of the following state, so `count == 0`
still consumes no hidden wait or sample-only cycle:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt cycles) <(& start cycles))
  (-> main_wait_1 <(& start cycles))
  (-> main_wait_1_zero_sample <(& start (== cycles 0))))

(main_wait_1
  (<= (hold din))
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1_loop))))

(main_wait_1_loop
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1_loop))))

(main_wait_1_zero_sample
  (<= (hold din))
  (= (outp_start 1))
  (= (outp_val hold))
  (-> main_done_3))
```

The original `main_drive_2` remains the positive-count successor and does not
carry the sample assignment, preventing a second sample after a positive wait.

The separate `main_wait_1_loop` state handles counts greater than one without
repeating the sample on every loop cycle. If the zero-count successor cannot
carry the pending sample without changing timing, the lowerer rejects the form
until that successor shape has an explicit materialization rule.

Completion is a sample-compatible zero-count successor because it does not read
the sampled alias. A zero-count clone of a completion state carries the pending
sample assignment, preserves the delayed completion pulse, and returns to idle
like the original completion state:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<1 (done> 1))
  (-> main_idle_0))
```

An independent scalar setter is also sample-compatible when it does not read or
overwrite the pending sample alias. The clone carries the pending sample, emits
the original setter assignment, and advances to the original setter successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<- (out> 1))
  (-> main_drive_3))
```

If the setter reads `hold`, or writes `hold`, the form remains fail-closed
because the clone would otherwise combine sample materialization and sample
consumption in one state.

An independent shift follows the same rule. The clone carries the pending
sample, emits the original shift assignment, and advances to the original shift
successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<- (reg_out> (| (<< reg_out 1) bit)))
  (-> main_drive_3))
```

If the shifted register or inserted bit is `hold`, the form remains
fail-closed for the same sample-and-consume timing reason.

An independent assemble state follows the same rule. The clone carries the
pending sample, emits the original concat assignment, and advances to the
original assemble successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<- (packet> (concat header payload)))
  (-> main_drive_3))
```

If the assembled target or any assembled part is `hold`, the form remains
fail-closed for the same sample-and-consume timing reason.

An independent extract state follows the same rule. The clone carries the
pending sample, emits the original slice assignments, and advances to the
original extract successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<= (out_header> (slice packet 15 12)))
  (<= (out_payload> (slice packet 11 4)))
  (<= (out_crc> (slice packet 3 0)))
  (-> main_drive_3))
```

If the extract source word or any destination field is `hold`, the form
remains fail-closed for the same sample-and-consume timing reason.

An independent bank-load state follows the same rule. The clone carries the
pending sample, emits the original guarded scalarized load assignments, and
advances to the original bank-load successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<- (out> data_0) <(== idx 0))
  (<- (out> data_1) <(== idx 1))
  (<- (out> data_2) <(== idx 2))
  (<- (out> data_3) <(== idx 3))
  (-> main_drive_3))
```

If the load index, selected scalarized entry name, or load target is `hold`,
the form remains fail-closed for the same sample-and-consume timing reason.

An independent bank-store state follows the same rule. The clone carries the
pending sample, emits the original guarded scalarized store assignments, and
advances to the original bank-store successor:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (<- (data_0 value) <(== idx 0))
  (<- (data_1 value) <(== idx 1))
  (<- (data_2 value) <(== idx 2))
  (<- (data_3 value) <(== idx 3))
  (-> main_drive_3))
```

If the store index, stored value, or selected scalarized entry name is `hold`,
the form remains fail-closed for the same sample-and-consume timing reason.

A top-level ready/valid stage can also carry the pending sample. The clone
keeps the original `valid` assignment and ready-gated transition:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (= (valid> 1))
  (<ready
    (-> main_drive_3)))
```

If the stage ready input or valid output is `hold`, the form remains
fail-closed for the same sample-and-consume timing reason.

A top-level bounded-eventual contract arm state can also carry the pending
sample. The clone keeps the original one-cycle arm request and advances like
the original contract arm state:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (= (main_contract_2_arm 1))
  (-> main_drive_3))
```

The monitor DT still owns pending, age, and fail storage and observes the same
arm signal. Contract arm states that would read or overwrite `hold` remain
fail-closed for the same sample-and-consume timing reason.

Top-level `await_all` and `await_any` sync states can also carry the pending
sample when their collected done ports do not read the pending sample alias.

The clone keeps the original synchronization transition:

```lisp
(parent_wait_3_zero_sample
  (<= (hold din))
  (-> parent_drive_5 <(& w0_done w1_done)))
```

For `await_any`, the clone keeps one transition per collected done port. If a
collected done port is `hold`, the form remains fail-closed for the same
sample-and-consume timing reason.

Top-level `spawn` states can carry the pending sample when the generated
start handoff does not overwrite the pending sample alias. The clone keeps the
child start pulse and advances like the original spawn state:

```lisp
(parent_wait_1_zero_sample
  (<= (hold din))
  (= (w0_start> 1))
  (-> parent_await_all_3))
```

If the generated start handoff is `hold`, the form remains fail-closed.

Blocking `do` remains a separate shape because it also owns input/output
bindings and a completion guard.

A top-level transaction `(phase ...)` marker can also carry the pending sample.

The clone preserves the original pass-through transition; actor-level phase
metadata remains report-only and unrelated to this runtime scheduling path:

```lisp
(main_wait_1_zero_sample
  (<= (hold din))
  (-> main_drive_3))
```

Consecutive top-level runtime scalar waits reuse the same split on both the
activation edge and the first wait's final sampled-counter edge. For:

```lisp
(wait first_cycles)
(wait second_cycles)
```

the predecessor of `first_cycles` contains a positive edge for the first wait,
plus a zero edge that immediately evaluates `second_cycles`:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt first_cycles) <(& start first_cycles))
  (<- (main_wait_2_cnt second_cycles) <(& start (== first_cycles 0) second_cycles))
  (-> main_wait_1 <(& start first_cycles))
  (-> main_wait_2 <(& start (== first_cycles 0) second_cycles))
  (-> main_drive_3 <(& start (== first_cycles 0) (== second_cycles 0))))
```

When the first wait has actually been entered, its final sampled-counter edge
performs the same split for the second wait:

```lisp
(main_wait_1
  (-- main_wait_1_cnt)
  (<- (main_wait_2_cnt second_cycles) <(& (== main_wait_1_cnt 1) second_cycles))
  (-> main_wait_2 <(& (== main_wait_1_cnt 1) second_cycles))
  (-> main_drive_3 <(& (== main_wait_1_cnt 1) (== second_cycles 0)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1))))
```

The second count is sampled only on the edge that enters the second wait. The
first count source is not reread after the first wait starts.

If a pending sample exists before the first consecutive runtime wait, a zero
first count carries the sample to generated path-specific clones. A positive
second count enters a second-wait clone that materializes the sample before
decrementing the sampled second counter:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt first_cycles) <(& start first_cycles))
  (-> main_wait_1 <(& start first_cycles))
  (<- (main_wait_2_cnt second_cycles) <(& start (== first_cycles 0) second_cycles))
  (-> main_wait_2_sample_from_main_wait_1 <(& start (== first_cycles 0) second_cycles))
  (-> main_wait_1_zero_sample_after_main_wait_2
      <(& start (== first_cycles 0) (== second_cycles 0))))

(main_wait_2_sample_from_main_wait_1
  (<= (hold din))
  (-- main_wait_2_cnt)
  (?main_wait_2_cnt
    (=1 (-> main_drive_3))
    (>1 (-> main_wait_2))))
```

The original `main_wait_2` remains unsampled for paths where `main_wait_1`
already materialized the sample. When both counts are zero, the
`main_wait_1_zero_sample_after_main_wait_2` clone carries the sample and the
final compatible target assignments, then advances like the original target.

Top-level runtime waits can also follow the shipped predecessor states whose
advance condition is explicit in the scheduler IR:

- After `(await ready)`, the ready edge is split into `ready && cycles` and
  `ready && cycles == 0`; the watchdog timeout transition remains in the await
  state.
- After `(stage name (ready ready) (valid valid))`, the stage state continues
  driving `valid`, and only the ready edge is split.
- After a top-level `repeat`, the repeat-check exit edge `counter == 0` is
  split, while the loop-back edge remains available.
- After `await_all`, the split condition is the AND of the collected done
  signals plus the runtime count test.
- After `await_any`, the split condition is the OR of the collected done
  signals plus the runtime count test.
- After transaction bank `load` or `store` states, the bank state keeps its
  guarded scalarized assignments, and only the unconditional advance edge is
  split into the runtime wait positive and zero-count paths.

For example, a wait after `await_all` lowers the synchronization edge and the
runtime count check into one guard:

```lisp
(parent_await_all_3
  (<- (parent_wait_4_cnt cycles) <(& w0_done w1_done cycles))
  (-> parent_wait_4 <(& w0_done w1_done cycles))
  (-> parent_done_5 <(& w0_done w1_done (== cycles 0))))
```

A wait after a bank load keeps every guarded entry assignment in the load
state and adds the runtime wait split beside those assignments:

```lisp
(main_load_1
  (<- (out> data_0) <(== idx 0))
  (<- (out> data_1) <(== idx 1))
  (<- (out> data_2) <(== idx 2))
  (<- (out> data_3) <(== idx 3))
  (<- (main_wait_2_cnt cycles) <cycles)
  (-> main_wait_2 <cycles)
  (-> main_done_3 <(== cycles 0)))
```

Runtime wait report entries keep `cycles` null because the exact count is
runtime data. Scalar counts use `count_kind` `runtime_scalar` and name the
source signal in `count_source`. Expression counts use `count_kind`
`runtime_expression` and keep the normalized expression text in
`count_source`. Both forms expose the generated counter through
`counter_signal` and `counter_width`.

A known-width expression count uses the same predecessor-edge snapshot and
zero-bypass contract. For example, `(wait (+ cycles bias))` lowers by loading
the generated counter with the expression value only on the positive-count
path:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt (+ cycles bias)) <(& start (+ cycles bias)))
  (-> main_wait_1 <(& start (+ cycles bias)))
  (-> main_drive_2 <(& start (== (+ cycles bias) 0))))
```

All signal operands referenced by the expression must have known width, and
the expression-width helper must derive a positive result width. Unknown-width
or malformed expressions fail closed before scheduled `.fsm` emission.

Runtime waits in `when` bodies are supported. With no pending sample, if the
wait is the first body state, the branch state carries the counter load and
split transitions:

```lisp
(main_when_1
  (<- (main_wait_2_cnt cycles) <(& cond cycles))
  (-> main_done_4 <(! cond))
  (-> main_wait_2 <(& cond cycles))
  (-> main_drive_3 <(& cond (== cycles 0))))
```

The false edge still skips the entire body. The true/positive edge enters the
wait with a sampled counter, and the true/zero edge bypasses the wait to the
following body state.

If pending samples appear before the `when`-body runtime wait, the true
positive path enters a sample-carrying first wait state and counts greater
than one continue through a no-resample wait loop. The true zero path bypasses
to a sample-preserving clone of the following body state when that state can
carry samples without changing timing. The false path remains an explicit skip
around the sampled body.

Runtime waits in `repeat` bodies are also supported. With no pending sample,
the generated dynamic wait counter is registered with the repeat body's other
counters, and the repeat-check loop-back/exit edges remain unchanged after the
body:

```lisp
(main_repeat_init_1
  (<= (main_cnt 2))
  (<- (main_wait_2_cnt cycles) <cycles)
  (-> main_wait_2 <cycles)
  (-> main_drive_3 <(== cycles 0)))
```

If pending samples appear before the repeat-body runtime wait, the positive
iteration path enters a sample-carrying first wait state and a no-resample
wait loop handles counts greater than one. The zero iteration path bypasses to
a sample-preserving clone of the following body state when that successor can
carry samples. The clone advances to the same repeat-check state as the
original body successor, so repeat loop-back and exit behavior remain
unchanged.

Runtime waits in `switch` branches are supported. With no pending sample, if
one case starts with a runtime wait, the switch state materializes only the
needed branch-entry split for that case. Other explicit cases remain ordinary
selectable branches, and implicit fallthrough is guarded by the complement of
all explicit case predicates:

```lisp
(main_switch_4
  (<- (main_wait_1_cnt cycles) <(& (== sel 0) cycles))
  (-> main_wait_1 <(& (== sel 0) cycles))
  (-> main_drive_2 <(& (== sel 0) (== cycles 0)))
  (?sel
    (=1 (-> main_drive_3))
  )
  (-> main_done_5 <(! (| (== sel 0) (== sel 1)))))
```

The positive selected-case path samples the runtime count and enters the wait.

The zero selected-case path bypasses the wait to the next state in that branch
body. Values not listed by the author take the guarded fallthrough edge.

If pending samples appear before the selected branch's runtime wait, the
positive selected-case path enters a sample-carrying first wait state and a
no-resample wait loop handles counts greater than one. The zero selected-case
path goes to a sample-preserving clone of the following selected-case body
state when that successor can carry samples without changing timing. Other
explicit cases and the implicit fallthrough remain unchanged.

Runtime waits in `while` bodies are supported. With no pending sample, if the
first body state is a runtime wait, both the entry decision and the back-edge
decision split the true branch into positive-count counter load/entry and
zero-count bypass paths. The false branch still exits the loop:

```lisp
(main_while_entry_1
  (<- (main_wait_2_cnt cycles) <(& keep cycles))
  (-> main_wait_2 <(& keep cycles))
  (-> main_drive_3 <(& keep (== cycles 0)))
  (-> main_done_5 <(! keep)))

(main_while_check_4
  (<- (main_wait_2_cnt cycles) <(& keep cycles))
  (-> main_wait_2 <(& keep cycles))
  (-> main_drive_3 <(& keep (== cycles 0)))
  (-> main_done_5 <(! keep)))
```

Runtime waits in `until` bodies are also supported for the no-pending-sample
subset. The first trip through the body uses the predecessor edge that enters
the body. The `until` decision's true path still exits, while the false
back-edge reloads or bypasses the wait for the next iteration:

```lisp
(main_until_check_3
  (-> main_done_4 <stop)
  (<- (main_wait_1_cnt cycles) <(& (! stop) cycles))
  (-> main_wait_1 <(& (! stop) cycles))
  (-> main_drive_2 <(& (! stop) (== cycles 0))))
```

If pending samples appear before the first `while` or `until` body runtime
wait, the positive body path uses the same sample-carrying first wait state and
no-resample wait loop. The zero body path bypasses to a sample-preserving clone
of the following body state when that successor can carry samples. `while`
false exits and `until` true exits remain unchanged, and loop-back edges keep
using the runtime count split on later iterations.

When the runtime wait is the final state-producing clause in a loop body, the
zero-count successor is the loop decision/check state itself. That state can
carry the pending sample when its counter assignment and condition do not read
or overwrite the pending alias:

```lisp
(main_wait_2_zero_sample
  (<= (hold din))
  (<- (main_cnt (- main_cnt 1)))
  (?main_cnt
    (=1 (-> main_repeat_init_1))
    (=0 (-> main_done_4))))
```

For `while` and `until`, the clone preserves the same branch behavior as the
original decision state. If the loop condition reads the pending alias, the
form remains fail-closed instead of sampling and testing that alias in the
same state.

Loop decision states can also split a following runtime wait on loop exit. For
a `while` followed by `(wait cycles)`, the true branch still loops to the
body, while the false exit branch samples or bypasses the following wait.

Runtime waits remain fail-closed when the selected zero-count successor cannot
carry pending samples without changing timing, after predecessor states whose
edge split is not implemented yet, and for malformed or unknown-width runtime
expressions.

**Timing**: exactly `N` active transaction cycles, no external condition.
**Cycles**: `N`.

## `(complete port)` → Terminal State

**ISF**:
```lisp
(complete done)
```

**Generated .fsm**:
```lisp
(apb_transfer_done_5
  (<1 (done> 1))                  ;; one-cycle delayed completion pulse
  (-> apb_transfer_idle_0))       ;; return to idle
```

**Timing**: `done` is a one-cycle delayed pulse. The pulse request is made in
the terminal state, and the generated HDL asserts `done` for one cycle at the
`<1` timing point after that request, resting low otherwise. Next cycle: idle.
**Cycles**: 1.

## `(repeat N body...)` → Counter Init + Body + Check

**ISF**:
```lisp
(repeat 8
  (drive scl 1)
  (drive scl 0))
```

`N` must be a scalar non-empty count token, and the body must contain at least
one list-form operation before the scheduler builds the repeat counter and loop
states.

**Generated .fsm**:
```lisp
(i2c_transfer_repeat_init_2
  (<= (i2c_transfer_cnt 8))       ;; load counter (D-input)
  (-> i2c_transfer_drive_3))

(i2c_transfer_drive_3              ;; body: first drive call
  (= (scl_start 1))
  (= (scl_val 1))
  (-> i2c_transfer_drive_4))

(i2c_transfer_drive_4              ;; body: second drive call
  (= (scl_start 1))
  (= (scl_val 0))
  (-> i2c_transfer_repeat_check_5))

(i2c_transfer_repeat_check_5       ;; check + loop
  (<- (i2c_transfer_cnt (- i2c_transfer_cnt 1)))   ;; decrement (Q-named)
  (?i2c_transfer_cnt
    (=1 (-> i2c_transfer_repeat_init_2))           ;; loop back
    (=0 (-> next_state))))                          ;; exit
```

**Timing**: `N × (body_cycles) + 2` (init + check). For `N=8` with 2 drives: `8×2+2=18` cycles.
**Implicit signals**: `{tx}_cnt` (inferred width). Decimal literal counts use
the minimum width that can represent the loaded count. Declared positive actor
constants and actor-local scalar parameter defaults use their resolved value
as width evidence while preserving the authored count token in the scheduled
load. Named dynamic counts use their known interface, storage, or
sample-derived width. Unknown names, non-scalar actor parameters, transaction
parameters, malformed scalar tokens, and expression-valued counts fail closed
before counter emission. Switch-nested repeats register the same transaction
counter at the widest required branch width.

Repeat bodies lower named drive calls, awaits, samples, updates, the current
data operations, local blocking `(do child)`, top-level when-body nested repeat
local or generated-child `(do child)`, generated blocking `do` for already
generated child targets or static parameterized do sites, and the
generated child-activation spawn subset with optional static `(params ...)`,
optional `(bind ...)` handoffs, and optional declared same-domain
`(domain NAME)` ownership metadata followed by same-body `await_all`, or by
same-body `await_any` when exactly one spawn is pending.

`N` is a counter load value, not a structural replication count.

A dynamic scalar count is therefore compatible with the hardware model when
its width is known, but it makes loop latency runtime-dependent and forces
the zero-count policy to be explicit. Static zero counts from literal zero,
actor constants, actor scalar parameters, same-transaction scalar parameters,
or package scalar constants lower as transparent no-op regions with no
counter, repeat init/check state, repeat-body state, or `transaction_loops[]`
entry. Plain static-zero repeat-body `do` and `spawn` child activations are
pruned with no generated child/top or local handoff artifact when their
targets are not otherwise live. Syntactically valid parameterized, bound, or
domain-annotated zero-count child activations are pruned the same way after
activation subclause shape validation. Positive same-transaction scalar parameter counts
resolve to a static load value. Known-width runtime scalar counts bypass the
body and repeat check when the runtime value is zero.

For repeat-body spawn, the generated top still instantiates one static child
instance for the lexical spawn name.

The repeat body starts that instance, waits for the same instance's done
port, and only then reaches the repeat check.

`await_any` has the same direct re-entry proof as `await_all` only when
exactly one spawn is pending.

With multiple pending spawns, `await_any` is allowed only as an observation
point before a later same-body `await_all` drains the same outstanding spawn
set.

If the spawn carries `(params ...)`, those overrides appear once on that
static generated-top child instance, not on each iteration.

If it carries `(bind ...)`, the generated parent handoff ports are also
emitted once for that static instance and wired by the generated top.

If it carries `(domain NAME)`, that name must be declared by the actor and
remain the same domain as the owning transaction and child; it only records
ownership metadata and does not add CDC behavior.

Samples after repeat-body spawn lower to an explicit sample state before the
same-body sync state, so capture timing is visible before the repeat check.

Spawning again after that pending sample remains deferred.

The same static child handoff is shipped for two narrower nested placements. A
repeat directly inside a top-level `when` body may contain one or more
generated spawns with optional static `(params ...)`, optional `(bind ...)`
handoffs, and optional declared same-domain `(domain NAME)` metadata when the
same nested repeat body reaches `(await_all done)` before the nested repeat
check can loop. A repeat directly inside a top-level `switch` branch may
contain the same multiple generated-spawn plus same-body `await_all` subset.

Both branch-contained paths may use single-pending `(await_any done)` directly
when exactly one generated child is pending. Both branch-contained paths may
also use multi-pending `(await_any done)` as an observation point only when a
later same-body `(await_all done)` drains the same outstanding generated
children before the nested repeat check can loop. Sample-before-spawn and
sample-after-spawn timing stay explicit, and the generated top still
instantiates one static child per lexical `spawn` instance.

The top-level `when` body and top-level `switch` branch nested-repeat forms
may also lower a local plain `(do child)` while generated nested spawns are
pending either before or after a prior multi-pending `await_any` observation,
before a later same-body `await_all` drain.

That local do uses the parent-module start/done contract and does not consume
the generated-spawn done set; the later `await_all` still gates the nested
repeat check on every outstanding generated child.

When no multi-pending `await_any` observation is active before the drain, that
local do may also be followed by one or more additional generated nested
spawns before the mandatory same-body `await_all` drain. The local child's
fresh done handoff gates the later spawn state, and the later `await_all`
drains both the pre-do and post-do generated-spawn done handoffs.

The top-level `when` body and top-level `switch` branch nested-repeat forms
may also lower a plain generated-child `(do child)` in that pending-spawn
interval when the target is already generated elsewhere.

That generated do starts its own deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance, waits for that instance's
fresh done handoff, and leaves pending generated-spawn done handoffs live
until the later `await_all` drain.

The same top-level branch-contained nested-repeat forms may lower
static-parameter generated `(do child (params ...))` in that interval; the
generated do instance carries the authored parameter overrides in the
generated top and still leaves pending generated-spawn done handoffs live
until the later drain.

Top-level `when` body and top-level `switch` branch nested-repeat forms may
also lower static-parameter generated `(do child (params ...)

(bind ...))` in that interval; the generated do instance wires generated-top
input/output binding handoffs once and leaves pending generated-spawn done
handoffs live until the later drain.

Top-level `when` body and top-level `switch` branch nested repeats may also
lower static-parameter same-domain generated `(do child (params ...) [(bind
...)] (domain NAME))` in that interval.

The domain annotation is declared ownership metadata for the generated do
instance; lowering keeps pending generated-spawn done handoffs live until the
later drain.

The top-level `when` body and top-level `switch` branch plain generated-child
do after prior multi-pending `await_any` subsets are shipped for this same
pending-spawn lifetime proof.

The top-level `when` body static-parameter generated do after prior
multi-pending `await_any` subset is also shipped, and the top-level `switch`
branch static-parameter analogue is shipped with the same later drain
requirement.

The top-level `when` body static-parameter bound generated do after prior
multi-pending `await_any` subset is shipped with the same later drain
requirement and generated-top binding handoffs.

The top-level `switch` branch static-parameter bound generated do after prior
multi-pending `await_any` subset is shipped with the same later drain
requirement and generated-top binding handoffs.

The top-level `when` body and top-level `switch` branch same-domain generated
do after prior multi-pending `await_any` subsets are shipped with the same
later drain requirement and declared ownership metadata in
generated-composition/ domain partition and schedule-report clock-domain
summaries.

Top-level `when` body local `(do child)` may also lower before a post-do
multi-pending `await_any` observation; lowering waits for the local child's
fresh done pulse, emits the post-do `await_any` as an observation of the
still-pending generated-spawn done set, and keeps the later same-body
`await_all` as the drain before nested repeat re-entry.

Top-level `switch` branch local `(do child)` now shares that post-do
`await_any` observation and later-drain contract.

Top-level `when` body plain generated-child `(do child)` also shares that
post-do `await_any` observation and later-drain contract; lowering waits for
the deterministic generated do instance's fresh done handoff before the
observation.

Top-level `switch` branch plain generated-child `(do child)` shares the same
post-do `await_any` observation and later-drain contract.

Top-level `when` body and top-level `switch` branch static-parameter
generated `(do child (params ...))` share that post-do `await_any`
observation and later-drain contract; lowering waits for the deterministic
generated do instance's fresh done handoff before the observation and keeps
the authored static parameter override in the generated top. Top-level
`when` body and top-level `switch` branch static-parameter bound generated
`(do child (params ...) (bind ...))` shares that post-do observation and
later-drain contract while lowering also wires the generated-top input/output
binding handoffs for the generated do instance. Top-level `when` body and
top-level `switch` branch same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))` share that post-do
observation and later-drain contract while lowering also retains declared
ownership metadata in generated-composition, domain-partition, and
schedule-report clock-domain summaries. A new nested spawn after generated
do, or after local do when a multi-pending `await_any` observation is active
before the drain, remains fail-closed.

Repeat-body local `do` does not emit a child file or generated top; it reuses
the same local start/done pulse contract as top-level local `do` and reaches
the repeat check only after the child done pulse:

```lisp
(parent_do_2
  (= (worker_start 1))
  (<worker_done
    (-> parent_repeat_check_3)))
```

Repeat-body generated `do` is shipped when the plain do target is already a
generated child, or when the do site carries static parameter overrides. It
emits one generated child instance for the lexical do site, applies any
override once in the generated top, and waits for that instance's done handoff
before the repeat check:

```lisp
(parent_do_2
  (= (parent_worker_repeat_do_0_start> 1))
  (<parent_worker_repeat_do_0_done
    (-> parent_repeat_check_3)))

(?fsmc:parent_worker_repeat_do_0 worker
  (params (WIDTH 16)))
```

When the generated form is selected only because the target child is already
generated elsewhere, the parent still uses the same generated handoff, but the
generated-top instance has no local parameter override:

```lisp
(parent_do_2
  (= (parent_worker_repeat_do_0_start> 1))
  (<parent_worker_repeat_do_0_done
    (-> parent_repeat_check_3)))

(?fsmc:parent_worker_repeat_do_0 worker)
```

Samples around repeat-body `do` lower at their source-order timing point. A
sample before `do` materializes before the child start state. A sample after
`do` materializes after the do state observes fresh child done and before the
repeat check:

```lisp
(parent_sample_2
  (<= (before status))
  (-> parent_do_3))

(parent_do_3
  (= (worker_start 1))
  (<worker_done
    (-> parent_sample_4)))

(parent_sample_4
  (<= (after status))
  (-> parent_repeat_check_5))
```

When the repeat is directly inside a top-level `when` body or directly inside
a top-level `switch` branch, the same local `do` lowering is shipped inside
the branch-owned repeat region. The branch enters the repeat only through the
selected path, the nested do asserts the local child start, and the nested
repeat check remains unreachable until the child done pulse has been observed:

```lisp
(parent_when_1
  (?cond
    (=1 (-> parent_repeat_init_2))
    (=0 (-> parent_done_7))))

(parent_sample_3
  (<= (before status))
  (-> parent_do_4))

(parent_do_4
  (= (worker_start 1))
  (<worker_done
    (-> parent_sample_5)))

(parent_sample_5
  (<= (after status))
  (-> parent_repeat_check_6))
```

For a switch branch, the selector targets the branch-owned repeat init state:

```lisp
(parent_switch_7
  (?mode
    (=0 (-> parent_repeat_init_2))
    (=1 (-> parent_sample_6))
    (default (-> parent_done_8))))
```

The `when` and `switch` nested repeat subsets accept local plain `(do
child)`, plain generated-child `(do child)` when the target is already
generated elsewhere, static-parameter generated `(do child (params ...))`,
and static-parameter generated bound `(do child (params ...)

(bind ...))`.

The generated case emits one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance, applies parameter overrides
once when present, and waits for that instance's fresh done handoff before
the nested repeat check.

The generated bound case wires generated-top input/output binding handoffs
once for that lexical nested do site.

The when-contained and switch-contained generated cases also accept `(domain
NAME)` as declared same-domain metadata when static `(params ...)` overrides
are present.

Both nested subsets reject deeper branch nesting, loop-contained repeats, and
generated/spawned nested activation beyond the documented branch-contained
generated `do` cases and the branch-contained generated-spawn cases.

Representative repeat-body spawn lowering uses the static generated instance
handoff, then an optional sample state, before the repeat check:

```lisp
(parent_spawn_2
  (= (w0_start> 1))
  (-> parent_sample_3))

(parent_sample_3
  (<= (seen status))
  (-> parent_await_all_4))

(parent_await_all_4
  (-> parent_repeat_check_5 <w0_done))

(parent_repeat_check_5
  (<- (parent_cnt (- parent_cnt 1)))
  (?parent_cnt
    (=1 (-> parent_repeat_init_1))
    (=0 (-> parent_done_6))))
```

For a repeat directly inside a top-level `when` body or top-level `switch`
branch, the representative shape is the same except the branch decision
targets the nested repeat init state. The nested repeat body may have one
or more generated spawns and optional samples around those spawns. The
branch-contained shapes may use same-body `await_all` for one or more pending
generated children, or single-pending same-body `await_any` for exactly one
pending generated child, before the nested `repeat_check` state. They may also
use multi-pending same-body `await_any` as an observation point before a later
same-body `await_all` drains those same generated children before the nested
`repeat_check` state. The
generated top applies any static parameter override, binding handoff, and
same-domain metadata once to each lexical nested spawn instance.

For the shipped top-level `when` body local-do-while-spawn-pending subset, the
local do appears between the generated spawn state and the same-body
`await_all` drain. The generated-spawn done handoff remains pending across the
local do state:

```lisp
(parent_spawn_3
  (= (w0_start> 1))
  (-> parent_do_4))

(parent_do_4
  (= (local_worker_start 1))
  (<local_worker_done
    (-> parent_sample_5)))

(parent_sample_5
  (<= (after_do status))
  (-> parent_await_all_6))

(parent_await_all_6
  (-> parent_repeat_check_7 <w0_done))
```

That shape is limited to local plain do targets in the parent scheduled module
and to a later same-body `await_all` drain. It is enabled only for repeats
directly inside top-level `when` bodies or top-level `switch` branches. The
top-level `when` body and top-level `switch` branch forms may also place the
local do after a multi-pending `await_any` observation; the observation state
branches to the local do and leaves every generated-spawn done handoff live
for the later `await_all` drain.

When a top-level `when` body or top-level `switch` branch nested repeat runs a
generated-child `do` while a generated nested spawn is still pending, lowering
keeps the two child lifetimes separate:

```lisp
(parent_spawn_2
  (= (w0_start> 1))
  (-> parent_do_3))

(parent_do_3
  (= (parent_worker_repeat_do_0_start> 1))
  (<parent_worker_repeat_do_0_done
    (-> parent_sample_4)))

(parent_sample_4
  (<= (after_do status))
  (-> parent_await_all_5))

(parent_await_all_5
  (-> parent_repeat_check_6 <w0_done))
```

The generated top instantiates both `w0` and `parent_worker_repeat_do_0`.

The blocking generated-child `do` consumes only
`parent_worker_repeat_do_0_done`; it does not clear `w0_done`, so the nested
repeat check remains unreachable until the later `await_all` drain observes
the spawned child.

The top-level `when` body and top-level `switch` branch generated-child
subsets may also place a multi-pending `await_any` observation before that
generated-child `do`: the observation branches to the generated do state, the
generated do waits only for its deterministic instance done handoff, and the
later `await_all` drain still observes every pending spawned child before the
nested repeat check.

The top-level `when` body and top-level `switch` branch static-parameter
generated pending-spawn subsets use the same state shape, with
`parent_worker_repeat_do_0` carrying the authored static parameter overrides
in the generated top.

The generated `do` still consumes only its own fresh done handoff and leaves
the spawned child done handoff live for the later drain.

In both top-level branch-contained subsets, this same static-parameter
generated do shape may also follow a prior multi-pending `await_any`
observation before the later `await_all` drain.

The top-level `when` body static-parameter bound pending-spawn subset uses
the same state shape and adds generated-top input/output binding handoffs to
`parent_worker_repeat_do_0`; those handoffs are consumed by the generated do
instance only, while the spawned child done handoff remains live for the
later drain.

The top-level `when` body and top-level `switch` branch bound forms may also
follow a prior multi-pending `await_any` observation before the later
`await_all` drain.

When the pending operation is local plain `do`, the later-spawn variant keeps
the local and generated lifetimes separate:

```lisp
(parent_spawn_2
  (= (w0_start> 1))
  (-> parent_do_3))

(parent_do_3
  (= (local_worker_start 1))
  (<local_worker_done
    (-> parent_spawn_4)))

(parent_spawn_4
  (= (w1_start> 1))
  (-> parent_await_all_5))

(parent_await_all_5
  (-> parent_repeat_check_6 <(& w0_done w1_done)))
```

The generated top instantiates `w0` and `w1`; the local worker remains in the
parent module. The later generated spawn starts only after the local done
pulse, and the nested repeat check remains unreachable until the same-body
`await_all` drains both generated children.

Multi-pending repeat-body `await_any` keeps the outstanding spawned done ports
live until a later same-body `await_all` drain:

```lisp
(parent_spawn_2
  (= (w0_start> 1))
  (-> parent_spawn_3))

(parent_spawn_3
  (= (w1_start> 1))
  (-> parent_await_any_4))

(parent_await_any_4
  (<w0_done
    (-> parent_sample_5))
  (<w1_done
    (-> parent_sample_5)))

(parent_sample_5
  (<= (after_any status))
  (-> parent_await_all_6))

(parent_await_all_6
  (-> parent_repeat_check_7 <(& w0_done w1_done)))
```

Cross-domain repeat-body `do`, cross-domain spawn, broader outstanding-child
semantics, generated/spawned nested activation beyond the documented top-level
branch-contained generated `do` cases and branch-contained spawned cases,
and deeper branch/loop forms remain fail-closed until their re-entry and
report behavior is specified.

## `(while cond body...)` / `(until cond body...)` -> Loop Decision States

**ISF**:
```lisp
(while keep
  (drive tick)
  (wait 1))

(until done_seen
  (drive tick)
  (wait 1))

(complete done)
```

**Generated .fsm shape**:
```lisp
(main_while_entry_1
  (?keep
    (=1 (-> main_drive_2))
    (=0 (-> main_drive_5))))

(main_drive_2
  (= (tick_start 1))
  (-> main_wait_3))

(main_wait_3
  (-> main_while_check_4))

(main_while_check_4
  (?keep
    (=1 (-> main_drive_2))
    (=0 (-> main_drive_5))))

(main_drive_5
  (= (tick_start 1))
  (-> main_wait_6))

(main_wait_6
  (-> main_until_check_7))

(main_until_check_7
  (?done_seen
    (=1 (-> main_done_8))
    (=0 (-> main_drive_5))))
```

`while` emits an entry decision plus a back-edge decision so zero iterations
and repeated condition sampling are both explicit in the scheduled artifact.

`until` emits the body first and checks only after the first body pass. In
both forms, the condition is sampled only in the generated decision state; it
is not a continuous guard over the body.

Schedule reports expose the loop through `transaction_loops[]`, including
`transaction`, `kind`, `condition`, `entry_state`, `decision_states`,
`body_start`, `body_states`, `exit_state`, and `body_clause_count`.

## `(when condition body...)` → Decision State

**ISF**:
```lisp
(when mode
  (drive write_path)
  (drive write_done))
```

**Generated .fsm**:
```lisp
(test_tx_when_2
  (?mode
    (=1 (-> write_body_states))    ;; true: execute body
    (=0 (-> next_top_level))))     ;; false: skip body
```

**Timing**: 1 cycle for the decision, then body cycles (if true), or skip (0 additional).

The body tail exits to the same next state that the false path skips to,
including when the `when` is nested inside a switch branch.
**Implicit signals**: None (uses existing signals in condition).

## `(switch signal (val body...)...)` → Multi-Way Decision

**ISF**:
```lisp
(switch opcode
  (0 (drive read))
  (1 (drive write)
     (drive write_done)))
```

**Generated .fsm**:
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> read_body_states))
    (=1 (-> write_body_states))
    (default (-> skip))))         ;; default: fallthrough
```

**Timing**: 1 cycle for decision, then body cycles of the matching branch.

Branch tails transition to the state after the whole switch; multi-state
branches and repeat-check exits do not fall through into later branch bodies.

The `default` selector is the `.fsm` fallback branch. It is true exactly when
the logical OR of all explicit sibling branch predicates is false. For this
example it means `!(opcode == 0 || opcode == 1)`, not another `opcode == 0`
branch. ISF authors may also write `(default body...)` or `(_ body...)` inside
the switch; that authored branch owns the fallback path and suppresses the
scheduler's implicit fallthrough branch.
**Implicit signals**: None.

## `(update var expr)` / `(shift_left reg bit [(width N)])` / `(shift_right reg bit [(width N)])` → Sequential State

**ISF**:
```lisp
(shift_left rdata sda_in)
```

**Generated .fsm**:
```lisp
(i2c_transfer_shift_6
  (<- (rdata> (| (<< rdata 1) sda_in)))  ;; Q-named output assignment
  (-> next_state))
```

**Timing**: 1 cycle. Assignment takes effect next cycle.
**Implicit signals**: None (operates on existing variables).

The generated shift expressions are ordinary `.fsm` expressions. Raw `<<` and
`>>`, plus the `shl` and `shr` aliases, pass through the downstream
SystemVerilog path as binary operators rather than schedule-only placeholders.

For `shift_right`, known signal widths are used for the inserted MSB position;
an explicit `(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` option supplies
that width when the register is not declared elsewhere. `TX_PARAM` is limited
to same-transaction scalar parameter defaults on generated child or
direct/non-generated transactions that resolve to positive integers. The
option is an assertion and must agree with any known register width. Unknown
widths fail closed instead of emitting the placeholder `WIDTH` expression.

For `shift_left`, the same optional
`(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` option supplies
register-width evidence for later data operations and report metadata. It does
not change the emitted left-shift expression, and plain `shift_left` remains
accepted without width evidence.

## `(assemble fields... as var)` / `(extract word as fields... [(widths N...)])` → Sequential State

**ISF**:
```lisp
(assemble header payload crc as packet)
```

**Generated .fsm**:
```lisp
(state
  (<- (packet (concat header payload crc)))
  (-> next_state))
```

**Timing**: 1 cycle.
**Implicit signals**: None.

When all `assemble` part widths are known, the target width is derived from
their sum. If exactly one part width is missing and the target width plus every
sibling part width is known, the missing part width is inferred as the positive
remainder and can be reused by later data operations in the same transaction.

If the target already has a known width, the final sum must match it.

Non-positive inferred remainders fail closed. Two or more unknown part widths
may still lower as a reviewable concat expression, but they do not become
width evidence.

Current `extract` lowering emits exact descending slices when the source word
and destination field widths are known. An ordered `(widths N...)` option can
provide field widths for the extract clause when those fields are not declared
elsewhere; the option count must match the field count. If exactly one
destination field width is missing and the source word width plus every sibling
field width is known, the missing width is inferred as the positive remainder
and can be reused by later data operations in the same transaction. Two or
more unknown field widths, a non-positive inferred remainder, or source/field
width disagreement fail closed before scheduled `.fsm` emission, so accepted
`extract` source no longer emits placeholder slice bounds.

## `(store <bank-name> <index> <value>)` / `(load <bank-name> <index> as <target>)` → Scalarized Bank Access

**ISF**:
```lisp
(store data wr_ptr data_in)
(load data rd_ptr as data_out)
```

Here `data` is the declared bank name. Actors may declare more than one bank;
the second item in the action selects the bank being accessed.

`store` is not a general scalar assignment form; it only writes a selected
entry of a declared bank. Use ordinary rule assignments or transaction
`update` for scalar actor-owned storage.

Rule assignments and transaction `update` are separate because they live in
different scheduling regions: rules are actor-level concurrent non-state DTs,
while transaction updates are ordered transaction states.

**Generated .fsm** for a depth-4 bank:
```lisp
(-accepted_push <push_fire
  (<- (data_0 data_in) <(== wr_ptr 0))
  (<- (data_1 data_in) <(== wr_ptr 1))
  (<- (data_2 data_in) <(== wr_ptr 2))
  (<- (data_3 data_in) <(== wr_ptr 3)))

(-accepted_pop <pop_fire
  (<- (data_out> data_0) <(== rd_ptr 0))
  (<- (data_out> data_1) <(== rd_ptr 1))
  (<- (data_out> data_2) <(== rd_ptr 2))
  (<- (data_out> data_3) <(== rd_ptr 3)))
```

**Timing**: read-before-write for same-cycle store/load on one bank. `load`
selects from the current cycle's scalarized bank values. `store` selects the
next value for the matching scalarized bank entry. Write-first or bypass
behavior requires a future explicit option.
**Implicit signals**: none beyond the declared scalarized bank entries.

Malformed access, unknown banks, non-bank storage names, literal indexes
outside fixed depth, and known width mismatches fail before scheduled `.fsm`
is accepted. Successful schedule reports include bounded `bank_accesses`
metadata for downstream tools.

The checked-in `isf/fifo_data_path.isf` fixture is the file-backed regression
for this surface; it proves strict schedule JSON parity, the scalarized
scheduled `.fsm` shape, and plain plus strict HDL generation for a depth-4
bank datapath.

## `(latency (min N) (max M))` → Verification Logic

**ISF**:
```lisp
(latency (min 2) (max 16))
```

`min` and `max` may also name a declared positive actor constant or an
actor-local scalar parameter default that resolves to a positive integer.
Named static bounds are resolved before the scheduler emits the same counter,
guard, and timeout logic used for literal bounds.

**Generated .fsm** — adds to entry state:
```lisp
(apb_transfer_idle_0
  (<- (apb_transfer_cc 0))        ;; reset counter
  ...)
```

Adds to every active state (not idle/done):
```lisp
(= (apb_transfer_inc 1))          ;; assert increment
```

Adds non-state DT:
```lisp
(-apb_transfer_cc_inc
  (<- (apb_transfer_cc (+ apb_transfer_cc 1)) <apb_transfer_inc))
```

Adds to done state:
```lisp
(?apb_transfer_cc
  (<2 (= (apb_transfer_lerr 1)))) ;; min violation check
```

**Timing**: Counter increments each active cycle. Min violation = error if done too early.

Max violation via watchdog timeout (if no `(await ...)` in transaction).
**Implicit signals**: `{tx}_cc` (inferred), `{tx}_inc` (1), `{tx}_lerr` (1).

## `(do child)` → Handshake

Local blocking `do` lowers by rewiring the child transaction inside the parent
scheduled module.

**In parent**:
```lisp
(parent_do_1
  (= (child_start 1))             ;; assert child start
  (<child_done                    ;; await done
    (-> parent_do_2)))
```

**In child (rewired)**:
```lisp
(child_idle_0                     ;; was: (<original_port ...)
  (<child_start                   ;; now: watches parent's start
    (-> child_drive_0)))

(child_done_5                     ;; terminal: pulses done
  (<1 (done> 1))
  (<1 (child_done 1))             ;; pulse parent-visible child completion
  (-> child_idle_0))
```

**Implicit signals**: `{child}_start` (1), `{child}_done` (1).

The internal `{child}_done` handoff is pulse-shaped for the same reason as the
public completion output: a parent may call the same child again, and a sticky
done bit would let the next `(do child)` observe an old completion.

Parameterized blocking `do` lowers through a generated child activation
instance instead of a local child handshake:

```lisp
(do child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)
    (output data resp)))
```

Representative parent `.fsm`:

```lisp
(parent_do_1
  (= (parent_child_do_0_start> 1))
  (<parent_child_do_0_done
    (-> parent_next_2)))

(-parent_child_do_0_port_bindings
  (= (parent_child_do_0_addr> req_addr))
  (= (resp> parent_child_do_0_data) <parent_child_do_0_done))
```

Representative generated top `.fsm`:

```lisp
(?fsmc:parent_child_do_0 child
  (params
    (WIDTH 16)))
```

The generated instance name is `{parent}_{child}_do_{ordinal}`. Input bindings
are parent-owned handoff assignments; the RHS may be a scalar signal,
numeric/exact-width literal, or non-empty list expression. Output bindings are
guarded by the generated instance's `done` pulse and keep scalar actor-side
targets. The generated top applies static parameter overrides and wires only
the explicit activation handoffs; unlike spawn, it does not auto-fanout
unrelated public actor inputs into the child instance.

Spawn lowering writes separate child `.fsm` files, a parent `.fsm` with
per-instance handoff ports, and a generated `<actor>_top.fsm` composition
source when `--outdir DIR` is used. Spawn and parameterized `do` parameter
declarations lower into child `+params` blocks, and override lists are
validated, preserved in the parent lowerer IR, and applied through generated
`?fsmc` `(params ...)` blocks in the top. The generated top wires parent start
outputs, parent done inputs, child `start`/`done` ports, explicit port-binding
handoffs, and named-drive handoff signals through the existing composition
pipeline. Schedule reports expose actor-level parameter defaults directly
through `actor_params[]` entries with `name` and JSON-safe default `value`;
use-site overrides remain reported by the generated-composition and
library-use binding summaries.

The generated child instance is static HDL. A spawn state activates that
instance through its start path; the child terminal state returns to the
start-gated idle state and waits for a later start. Reaching the same spawn
site again reuses the same instance. This is the required interpretation for
future spawn-in-repeat support as well.

Rule-trigger parameter overrides use the same static-specialization principle.

A parameterized trigger:

```lisp
(rule launch fire
  (trigger child
    (params
      (WIDTH 16))
    (bind
      (input addr req_addr))))
```

elaborates a generated child activation instance rather than changing the
shared local `child` transaction. The instance name is
`launch_child_trigger_0`. The rule DT keeps the existing `<1` pulse source and
input payload sampling behavior; a generated handoff DT drives
`launch_child_trigger_0_start` and any input handoff ports from those sources.

The generated top applies the static override through the ordinary `?fsmc`
`(params ...)` block and wires the child `done` output back to the parent for
composition consistency, while the rule itself does not wait on completion.

The parent handoff DT reads that `done` input into an internal observer signal
only to make the composition endpoint explicit; it does not change rule
control flow. Generated-child rule-trigger output bindings reuse that observer
as the guard for the output copy back to the bound scalar actor target. The
schedule report marks the generated trigger input binding as
`binding_timing: "trigger_payload"` and the output copy as
`binding_timing: "done_guarded"`. Direct/local rule-trigger output bindings
stay rejected.

## Complete Example — APB Transfer

All constructs together:

```lisp
(transaction apb_transfer
  (on start (sample req_addr as addr) (sample req_write as is_write)
            (sample req_wdata as wdata))
  (drive setup_phase)
  (drive access_phase)
  (await PREADY)
  (sample PRDATA as rdata) (sample PSLVERR as slverr)
  (drive done_phase)
  (complete done)
  (latency (min 2) (max 16)))
```

Generates 7 state DTs + non-state DTs:

```
idle_0          ← (on start ...) : guards on start, samples, can_accept
drive_1         ← (drive setup_phase)
drive_2         ← (drive access_phase)
await_3         ← (await PREADY) + watchdog
drive_4         ← (drive done_phase) with samples
done_5          ← (complete done): request one-cycle done pulse, return to idle
timeout         ← watchdog timeout
cc_inc_dt       ← latency cycle counter DT
```

In the APB requester fixture, `done_phase` owns protocol cleanup and sampled
response publication; it does not drive transaction `done`. The completion
signal is owned by `(complete done)`, because `done` is the scheduler-visible
transaction completion event rather than an APB bus signal.

Total: 7 states. Each `(drive ...)` is one state. `(await ...)` is one state.

`(sample ...)` piggybacks — no extra state.

## Phases and Stages

### Phases

```lisp
(phase setup (outputs valid rdata) (next finish))
```

Phases are named markers within a transaction. Currently lowered as
pass-through sequential states. The `(outputs ...)` declaration is
parsed but does not generate drive assignments. Phase names must be scalar,
and phase body entries must be list forms before an actor shell is returned.

**Status**: Parsed, lowered as pass-through. Future: jump targets,
conditional entry points. Needs more design discussion.

### Stages

```lisp
(stage pass_through (ready ready) (valid valid) (latency (max 3))
  (compute (valid ready)))
```

Pipeline stages with implicit valid/ready handshake. Stage names must be scalar,
and stage body entries must be list forms before an actor shell is returned.

The first shipped transaction-stage subset is intentionally smaller than the
historical free-form examples: a top-level transaction clause with one ready
input and one valid output.

Actor-level `(phase ...)` and `(stage ...)` metadata uses the same scalar-name
and list-body structural boundary, is carried in the parser actor shell for
downstream consumers, and is not semantically enforced by the scheduler yet.

That actor-level metadata is copied into the scheduling IR only for bounded
public report projection: schedule JSON exposes `actor_phases[]` and
`actor_stages[]` entries with the authored metadata name and parser-validated
list-form body. Generated `.fsm`, generated composition top, and HDL do not
consume actor-level phase/stage metadata today.

```lisp
(stage accept
  (ready ready)
  (valid valid))
```

That stage lowers to one transaction state. While the state is active, `valid`
is driven combinationally high with `=`, and the state advances only when
`ready` is true in the same cycle. If `ready` is false, the FSM remains in the
stage state and keeps `valid` asserted. Pending samples immediately before the
stage materialize before the stage so a stall does not resample every cycle.

When a runtime wait with pending samples has a zero-count path into the stage,
the generated stage clone materializes the sample, drives `valid`, and keeps
the same ready-gated transition as the original stage.

The older `(input ready)`/`(output valid)` spelling is accepted as an alias.

The valid endpoint remains a normal transaction combinational assignment, so
same-target rule/transaction conflict checks still apply.

Schedule reports expose this shipped subset through `transaction_stages`
entries with the authored transaction/stage names, `kind =
ready_valid_barrier`, generated state, ready input, and valid output.

Nested stages, stage-local `(latency ...)`, `(compute ...)`, embedded
transaction actions, multiple ready/valid endpoints, registered-valid variants,
and skid-buffer behavior remain separate backlog features until their
generated-state and runtime semantics are explicit.

**Future**: Grow toward richer pipeline registers only after the shipped
ready/valid barrier report contract is complete.

### Contracts

```lisp
(contract (always request -> eventually[1..8] grant))
```

Historical/free-form temporal assertions like that remain deferred. The first
shipped contract model is a transaction-local bounded eventual check:

```lisp
(contract response_seen
  (eventually done within 8))
```

When the transaction reaches the contract clause, lowering emits one arm state
that asserts an internal combinational arm request for that cycle. The checked
window starts on the next cycle and lasts for the specified positive integer
number of cycles. That window can be authored as a positive literal, a
declared positive actor constant, an actor-local scalar parameter default, a
qualified imported package scalar constant, or a same-transaction scalar
parameter default on a generated child or direct/non-generated transaction
that resolves to a positive integer. Direct transaction parameters are local
lowering inputs for this contract-window value domain and are not emitted as
actor-level `.fsm` `+params`. Activation-site overrides on `spawn`, generated
blocking `do`, or rule `trigger` that target a generated child parameter used
by the child contract window are accepted only when the override resolves to
the same positive integer cycle count as the child transaction parameter
default. Mismatched overrides fail closed with a targeted diagnostic; override
specialization of generated child contract windows remains deferred. If
`done` is seen before the window expires, the
obligation clears. If the window expires first, or if the same contract is
armed again while an obligation is still pending, a generated sticky fail bit
is set until actor reset.

The reviewable artifact is not SVA-only. The scheduled `.fsm` contains one arm
state plus an always-on monitor DT with pending, age, and fail storage. The
monitor DT is the source of truth; schedule reports classify it as
`temporal_contract_monitor` and report pending/fail as registers and age as a
counter. Those storage entries carry the `temporal_contract_monitor` storage
role, while bounded `temporal_contracts` entries expose the public trigger
state, observed signal, cycle bound, generated pending/counter/fail signal
names, reset policy, overlap policy, and assertion projection status.

Generated SystemVerilog now projects the fail bit into a verification-only
assertion under `` `ifndef SYNTHESIS``; the current assertion projection status
is `systemverilog_sticky_fail`. Verilog output remains assertion-free. When a
runtime wait with pending samples has a zero-count path into the contract arm
state, the generated contract clone materializes the sample and emits the same
arm request; the monitor DT remains unchanged and remains the only owner of
pending, age, and fail storage.

Unsupported bodies and nested contracts fail closed. Transaction parameter
windows, runtime-signal or expression windows, global `always` implication
forms, min/max windows, dynamic bounds, same-cycle windows, expression
operands, and multiple outstanding obligations remain deferred.

For a three-cycle window, the scheduled artifact has this shape:

```lisp
(main_contract_1
  (= (main_contract_1_arm 1))
  (-> main_done_2))

(-main_contract_1_monitor
  (<- (main_contract_1_pending 1)
      <(& main_contract_1_arm (! main_contract_1_pending)))
  (<- (main_contract_1_pending 0)
      <(| (& main_contract_1_pending done)
          (& main_contract_1_pending (! done) (== main_contract_1_age 2))))
  (<- (main_contract_1_age 0)
      <(& main_contract_1_arm (! main_contract_1_pending)))
  (<- (main_contract_1_age (+ main_contract_1_age 1))
      <(& main_contract_1_pending (! done) (! (== main_contract_1_age 2))))
  (<- (main_contract_1_fail 1)
      <(| (& main_contract_1_arm main_contract_1_pending)
          (& main_contract_1_pending (! done) (== main_contract_1_age 2)))))
```
