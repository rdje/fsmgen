# IAL2 AHB Direct Subordinate Completion-Capture Substrate Audit

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.6`

Date: 2026-07-23

## Outcome

The `.5` external protocol goal remains correct, but its selected internal
realization is not safe under current direct-FSM lowering. A direct
`register_in` name is the output of a combinational next-value mux, not an
old-value-only reference to its storage flop. Assigning the following phase's
address/control to the existing `addr_q`, `write_q`, or `size_q` in `ACCESS`
can therefore change predicates and effects that are still completing the
current phase in that same combinational evaluation.

The attempted `.6` implementation failed closed before it shipped. The direct
seed, t/1520 runtime expectations, and harness were restored to the clean `.5`
baseline. This leaf adds only structural regression evidence and documentation;
there is no seed, generated HDL, runtime, support, artifact, port, report, or
generated-family behavior change.

`.7` must select a lowering-safe contract with separated current and next
address/control storage plus an explicit relaunch boundary. `.8` is reserved
for implementation after `.7` commits cleanly.

## Attempt And Deterministic Failure

The attempted repair implemented the `.5` dispatcher literally in successful
`ACCESS` completion and final `ERROR_COMPLETE`:

```text
selected NONSEQ -> addr_q/write_q/size_q/wait_ctr := live bus -> ACCESS
selected SEQ    -> wait_ctr := live bus                         -> UNSUPPORTED
otherwise                                                     -> IDLE
```

The repaired t/1520 success scenario deliberately followed the completing
word write (`HWRITE=1`, data `0x11111111`) with an accepted NONSEQ read
(`HWRITE=0`). The guarded generated-HDL run failed deterministically:

```text
success-repair sampled_write=0 storage=00000000
```

The expected current write never occurred. This is not an AHB timing
ambiguity: it is a lowered signal-ownership conflict introduced by reusing the
same register-input name for current evaluation and next capture.

## Emitted-HDL Root Cause

Current lowering emits `write_q` as the combinational input of a separate
storage flop:

```systemverilog
always_comb begin
  write_q = write_q_q;
  if (write_q_hwrite_en) begin
    write_q = HWRITE;
  end
end

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    write_q_q <= 0;
  else
    write_q_q <= write_q;
end
```

The current write side effect is enabled from that mux output:

```systemverilog
assign access_reg_data_q_hwdata_en =
  access_en & current_success_predicate & write_q;
```

When the attempted completion dispatcher enabled `write_q <- HWRITE`, the
following read's live `HWRITE=0` immediately drove the mux output low. The
current completion predicate consequently observed zero and suppressed
`reg_data_q <- HWDATA` before the clock edge.

`addr_q` and `size_q` have the same register-input mux shape and also
participate in current success/error predicates. Reusing them for simultaneous
next-phase capture can alter those predicates or introduce enable-to-mux
self-dependence. `wait_ctr` is lowered as a conventional `register_out` with a
separate next-value signal, but that does not make mixed reuse of the other
phase registers safe.

t/1520 now locks both sides of this substrate fact without changing the seed:
the current write completion enable reads `write_q`, and emitted `write_q` is
the combinational mux that live `HWRITE` overrides when its capture enable is
asserted.

## Contract Consequence

The following external requirements remain mandatory:

- every selected ready active address phase is retained exactly once;
- current write completion consumes current data-phase `HWDATA`;
- final ERROR plus active captures a continuation, while IDLE/BUSY/unselected
  cancels it;
- SEQ retains the direct fixture's unsupported policy; and
- generated IAL2 roles and decision 0020 remain outside this direct-seed work.

What `.6` invalidates is only `.5`'s no-bank/no-relaunch realization. The
current phase registers must remain untouched while their phase completes.
The smallest candidate for `.7` is a separate one-entry next address/control
bank captured on the bus-visible completion edge, followed by a dedicated
relaunch state that transfers the bank into current phase storage when no
current `ACCESS` predicate/effect is active. `.7` must decide the exact bank,
state, ready/response timing, and bounded extra stall before `.8` edits the
seed.

This remains capacity-one protocol bookkeeping, not a general queue or
multiple-outstanding architecture.

## Preservation And Verification

The failed source/test/harness attempt was restored before this audit was
documented. Focused validation must prove:

```bash
prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
```

t/1520 must continue to report the known current loss outcomes while also
matching the register-input mux structure above. Current docs, mdBook,
Knowledge Map, task state, and Memory must route the infeasible `.5` internal
contract to this audit and route future selection to `.7`.

## Rollback

Rollback removes this audit/fact and the t/1520 mux assertions, restores `.6`
as the `.5` implementation owner, and removes `.7`/`.8`. It must not retain
the failed dispatcher or claim that the no-bank realization is feasible.
