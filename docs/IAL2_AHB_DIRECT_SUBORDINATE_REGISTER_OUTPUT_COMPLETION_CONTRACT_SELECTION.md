# IAL2 AHB Direct Subordinate Register-Output Completion Contract Selection

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.7`

Date: 2026-07-23

Implementation status: `.8` now ships this exact contract. See
`docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md`.

## Outcome

The selected direct-seed repair keeps the existing four states and existing
phase/storage registers, but changes their assignment intent from D-input-
named `<=` to Q-output-named `<-`. Successful `ACCESS` and final
`ERROR_COMPLETE` then dispatch a simultaneously accepted active phase through
those registers exactly as `.5` intended, without a pending bank, relaunch
state, extra ready-low cycle, or combinational alias.

This is smaller and cleaner than the separated register-input bank considered
after `.6`. A disposable strict-lowering and four-scenario Verilator probe
proves the Q-named shape is warning-clean and behaviorally exact. `.8` now owns
and ships implementation. `.7` changed no seed, generated HDL, runtime, support,
artifact, port, generated IAL2 role, backend, AXI/APB/VHDL behavior, or
decision `0020` activity.

## Why Q-Named Assignment Is The Correct Boundary

FSMGen's documented sequential assignment intents are materially different:

```text
A <= expr   A names the combinational D-input / next-value mux output
A <- expr   A names the registered Q / flop output
```

The failed `.6` dispatcher used the first form. Its current write predicate
read `write_q`, while same-cycle capture replaced that combinational signal
with the next phase's `HWRITE`. A following read therefore suppressed the
completing write.

With Q-named `<-`, lowering instead emits the equivalent of:

```systemverilog
reg write_q;
reg write_q_next;

assign access_reg_data_q_hwdata_en =
  access_en & current_success_predicate & write_q;

always_comb begin
  write_q_next = write_q;
  if (write_q_hwrite_en)
    write_q_next = HWRITE;
end

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    write_q <= 0;
  else
    write_q <= write_q_next;
end
```

The current predicate sees registered `write_q` for the entire cycle.
Same-cycle capture changes only `write_q_next`, which becomes Q after the
completion edge. `addr_q`, `size_q`, `wait_ctr`, and `reg_data_q` use the same
explicit Q-named intent so their source-level read/write meaning is uniform.

## Selected Source-Level Change

`.8` must convert every explicit persistent-state assignment in the direct
seed from `<=` to `<-` for:

- `addr_q`;
- `write_q`;
- `size_q`;
- `wait_ctr`; and
- `reg_data_q`.

The existing decrement operations already give `wait_ctr` registered-output
behavior; spelling all direct loads as `<-` makes that intent explicit and
consistent.

No new register or state is selected. The source remains the four-state
`IDLE`/`ACCESS`/`UNSUPPORTED`/`ERROR_COMPLETE` fixture with the same eleven
ports/signals reported by strict check and support identity
`protocol.ahb_lite_subordinate`.

## Selected Completion Dispatcher

On a successful word/address-zero `ACCESS` completion and in final
`ERROR_COMPLETE`, the next-address decision is:

```text
if HSEL && HREADY && HTRANS == NONSEQ:
    addr_q   <- HADDR
    write_q  <- HWRITE
    size_q   <- HSIZE
    wait_ctr <- wait_cycles
    next_state = ACCESS
else if HSEL && HREADY && HTRANS == SEQ:
    wait_ctr <- wait_cycles
    next_state = UNSUPPORTED
else:
    next_state = IDLE
```

`IDLE`, `BUSY`, an unselected presentation, or `HREADY=0` captures nothing and
returns to `IDLE`, preserving the direct fixture's bounded policy. Direct
admission from `IDLE` uses the same Q-named loads. Unsupported size/address
still enters the existing two-cycle ERROR path; it is not a successful
completion and does not accept a new phase on its first ready-low ERROR cycle.

## Timing And HWDATA Ownership

There is no relaunch state and no new stall. On a ready completion edge:

1. the current read/write effect evaluates from registered current
   `addr_q`/`write_q`/`size_q` and live current data-phase `HWDATA`;
2. the bus accepts the selected active next address/control phase;
3. the Q registers take their separately computed next values at the edge; and
4. the following cycle is directly `ACCESS` or `UNSUPPORTED` for that accepted
   phase.

HWDATA is never address-phase captured. A completing write consumes its
current live HWDATA. The next write's HWDATA is presented after the acceptance
edge and held by the manager through any existing ready-low wait cycles until
its own completion.

`wait_cycles=N` retains the existing direct timing: the new `ACCESS` or
`UNSUPPORTED` state observes `wait_ctr=N` immediately after the acceptance
edge, produces N counted wait cycles, then follows the existing success or
two-cycle ERROR response. The rejected relaunch candidate added one avoidable
ready-low cycle; the selected Q-named shape does not.

## Final ERROR, SEQ, And Cancellation

The first ERROR cycle remains ready-low and accepts no address phase. In final
`ERROR_COMPLETE`, HRESP/HREADYOUT remain `1/1` for the prior transfer while:

- active NONSEQ atomically loads the next current phase and enters `ACCESS`;
- active SEQ loads its wait count and enters `UNSUPPORTED`, producing a later
  independent two-cycle ERROR;
- IDLE, BUSY, unselected input, or `HREADY=0` enters `IDLE` without capture.

The old ERROR response therefore remains exactly two cycles. The following
phase begins with HRESP cleared by its own state policy after the edge.

## Feasibility Evidence And Rejected Alternative

The warning-clean Q-named disposable candidate preserves four states and
passes these exact generated-HDL outcomes:

```text
success + active NONSEQ read:
  bus_accepts=2 captures=2 completions=2 errors=0
  sampled_write=0 storage=0x11111111

final ERROR + active NONSEQ write:
  bus_accepts=2 captures=2 completions=2 errors=2
  storage=0xaaaaaaaa

success + active SEQ:
  bus_accepts=2 captures=2 completions=2 errors=2
  storage=0x55555555

final ERROR + IDLE:
  bus_accepts=1 captures=1 completions=1 errors=2
  storage=0x00000000
```

The first separated-bank candidate was functionally correct for the first two
scenarios, but its pending fields also used D-input-named `<=`. Reading those
combinational mux outputs during `RELAUNCH` formed a structural cross-state
loop:

```text
current ACCESS predicate
  -> pending capture enable/mux
  -> RELAUNCH current-register mux
  -> current ACCESS predicate
```

Verilator reported `UNOPTFLAT`, and the relaunch path added one ready-low cycle
(five instead of four in the same success harness). That candidate is rejected;
`.8` must not add its pending fields or fifth state.

## Exactly-Once And `.8` Proof Contract

t/1520 must become repair proof with four runtime scenarios matching the
outcomes above. Its structural assertions must prove:

- all five persistent-state loads use source-level `<-`;
- emitted `write_q` is a `register_out` Q signal with separate
  `write_q_next` feedback/capture muxing;
- current write completion reads Q `write_q` while capture writes
  `write_q_next`;
- `ACCESS` and `ERROR_COMPLETE` contain the exact NONSEQ/SEQ dispatcher; and
- no pending/relaunch register or state exists.

Each bus acceptance must correspond to exactly one internal capture and one
later completion, with at most one storage effect. A held third active phase
during a ready-low data phase is not accepted until the next ready edge; on
that edge it may replace the completing phase through the same Q/next split.
This is normal one-address/one-data overlap, not a general outstanding queue.

## Preservation Boundary

`.8` may change only the direct seed, t/1520 and its harness, current direct-
seed docs/book/facts, task/Memory, and directly affected validation evidence.
It must preserve:

- module, port, source path, artifact, support identity, four-state cardinality,
  eleven-signal strict-check result, and absence of a new report surface;
- word/address-zero NONSEQ behavior, unsupported SEQ/size/address policy,
  wait counting, reset/default outputs, reads/writes, and two-cycle ERROR;
- generated IAL2 subordinate/requester/interconnect phase repair and paired
  runtimes; and
- direct requester/interconnect seeds, broader AHB, general queues/outstanding
  transfers, AXI/APB/VHDL, and decision 0020 inactivity.

Focused validation must include strict/check/HDL generation, warning-clean
Verilator build and all four t/1520 runtimes, direct support accounting,
generated t/1519 preservation, current-doc truth, mdBook, Knowledge Map,
memory, paths, diff, and doctrines under the 4-GiB descendant cap where heavy.

## Rollback

Rollback removes this record/fact and restores `.7` to pending. A later `.8`
rollback must restore the direct seed and t/1520 together to the current-loss
audit state, including the `.6` register-input mux assertions. It must not
leave completion-edge capture on D-input-named registers or the rejected
UNOPTFLAT bank/relaunch shape.
