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

Later `.7` finding: the documented Q-named `<-` assignment form provides the
required current/next separation inside each existing register. `.7` selects
that warning-clean four-state realization without a pending bank/relaunch;
`.8` is reserved for implementation after `.7` commits cleanly. See
`docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md`.

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

What `.6` invalidates is `.5`'s use of D-input-named `<=` for registers that
the completing current phase also reads. The registered Q values must remain
stable while their separate next values capture. `.7` proves the smallest
realization is to use Q-named `<-` for the existing phase/storage registers:
lowering generates a distinct `*_next` mux while source reads keep seeing Q.
A D-input-named pending bank/relaunch probe was functionally correct but
rejected for a cross-state `UNOPTFLAT` loop and an avoidable ready-low cycle.

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
