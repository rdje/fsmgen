# IAL2 AHB Subordinate Default/Phase Output-Arbitration Audit

Task-tree owner:
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`

Date: 2026-07-29

## Outcome

The generated AHB subordinate defect is independently reproduced without an
interconnect. It belongs in generated endpoint authoring in
`perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm`, not in generic selector
assertions or generic ISF priority enforcement.

The next selected leaf is proposed
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`, a no-behavior
contract selector for mutually exclusive generated endpoint output ownership.
No repair ships from this audit.

The hand-authored IAL0 seed has a different output-arbitration defect. It is
durably separated under proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`; it does not expand or pivot
the selected generated-endpoint work.

## Independent Reproduction

The richest direct public subordinate was generated from
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, compiled with
all assertions enabled, and run with the existing
`t/data/ahb_pipelined_active_transfer_audit_tb.svt` harness. It stopped at time
40 in the endpoint itself:

```text
selector same-value conflict: HRDATA 0
```

There is no requester or interconnect in that design, so the endpoint owns the
failure independently.

The current one-window paired BUSY source was also generated after the fabric
repair, compiled without `--no-assert`, and run with
`t/data/ahb_paired_busy_composition_tb.svt`. Requester and repaired-fabric
assertions admitted the run; the first failure remained the subordinate at
time 345:

```text
selector same-value conflict: HRDATA_REGS 0
```

The direct and aggregate names differ only because composition binds the
subordinate ports to the `*_REGS` child interface. Their source families and
conditions are otherwise the same.

## Complete Generated Selector Inventory

All five shipped direct PPIF subordinate variants were lowered independently
and their generated `selector_conflict_targets` metadata was decoded. Every
variant has exactly three bus-output conflict targets: `HRDATA`, `HREADYOUT`,
and `HRESP`. The larger total includes scheduler/storage targets that are not
AHB output ports.

| Variant | Total conflict targets | `HRDATA` RHS families | `HREADYOUT` RHS families | `HRESP` RHS families |
| --- | ---: | ---: | ---: | ---: |
| base word-only | 8 | 2 | 2 | 3 |
| byte-lane | 10 | 8 | 2 | 3 |
| byte-lane SEQ | 20 | 8 | 2 | 3 |
| byte-lane HBURST/SEQ | 20 | 8 | 2 | 3 |
| byte-lane HBURST/SEQ BUSY-park | 20 | 8 | 2 | 3 |

The base variant's additional targets are transaction count,
`ahb_phase_pending_q`, `error_complete_start`, `error_first_start`, and
`next_state`. Byte-lane adds `reg_data_q` and `write_hit_start`. SEQ/HBURST
variants add the applicable read-drive start pulses and `seq_*` state. With
only the three bus-output assertions changed to diagnostic logging in
disposable HDL, every remaining internal selector assertion stayed enabled
and passed both the rich direct phase-pipeline runtime and the paired BUSY
runtime.

### `HRDATA`

Every generated variant has one zero family with eight source enables, in
this deterministic order:

1. `ahb_error_retire`
2. transaction idle state
3. `ahb_phase_capture`
4. `ahb_phase_hold`
5. `enter_data_phase`
6. `error_complete`
7. `error_first`
8. `write_hit`

The base variant adds one nonzero-capable `reg_data_q` read family. Narrow
variants add seven read families: four masked byte lanes, two masked halfword
lanes, and the full-word `reg_data_q` family. Therefore `HRDATA` has:

- one eight-input same-value assertion for zero;
- a two-family multi-value assertion in the base variant; or
- an eight-family multi-value assertion in every narrow variant.

Only the zero-family assertion failed in generated endpoint runtimes. No read
family overlapped zero or another read family in the covered read, write,
success, SEQ, ERROR, BUSY, or IDLE paths.

### `HREADYOUT`

The zero family has four sources in every variant:
`ahb_phase_capture`, `ahb_phase_hold`, `enter_data_phase`, and `error_first`.

The one family has five sources in the base variant:
`ahb_error_retire`, transaction idle, `error_complete`, `read_hit`, and
`write_hit`. Narrow variants replace `read_hit` with seven lane-specific read
drives, so the one family has eleven sources.

Each variant therefore has two same-value family assertions plus one
two-family multi-value assertion. None failed in the generated runtimes. The
generated IAL0 already suppresses the transaction-idle and error-retire
`HREADYOUT <- 1` assignments while higher-priority phase capture/hold owns
`HREADYOUT <- 0`.

### `HRESP`

Generated metadata retains three lexical RHS families:

- transaction idle writes source/default `0`;
- rules and successful drives write explicit OKAY `1'b0`;
- `error_first` and `error_complete` write ERROR `1'b1`.

The explicit OKAY family has six sources in the base variant and twelve in
narrow variants. The ERROR family has two sources. Thus each generated
variant has same-value assertions for explicit OKAY and ERROR plus a
three-family multi-value assertion. Transaction-idle `0` has only one source.

Only explicit OKAY overlapped at runtime, on final ERROR plus next-phase
capture. The lexical `0`/`1'b0` families were mutually exclusive in all
covered paths because the generated IAL0 suppresses the idle response write
under phase capture/hold/error retirement. Literal canonicalization is not
needed to repair this endpoint and remains outside this task.

## Source-to-HDL Ownership Trace

`AhbSubordinate.pm` authors the complete generated output family:

- actor output defaults: `HREADYOUT=1`, `HRESP=0`, `HRDATA=0`;
- `enter_data_phase`: not-ready, OKAY, zero data;
- read drives: ready, OKAY, selected full or masked data;
- `write_hit`: ready, OKAY, zero data;
- `error_first`: not-ready, ERROR, zero data;
- `error_complete`: ready, ERROR, zero data;
- `ahb_phase_capture`: not-ready, OKAY, zero data;
- `ahb_phase_hold`: not-ready, OKAY, zero data;
- `ahb_error_retire`: ready, OKAY, zero data.

The IAL1 scheduler expands transaction output defaults into the transaction
idle state. Rule/transaction priority adds negative higher-owner guards for
different-value assignments. In the generated IAL0 this is visible on
transaction-idle `HREADYOUT` and `HRESP`, and on error-retire `HREADYOUT`.
The matching `HRDATA <- 0` assignments remain independent raw sources.

The SystemVerilog backend preserves those raw source enables in same-value
onehot0 assertions, then combines RHS families for the multi-value assertion.
This is the intended observability boundary: selecting the same value from
two owners is still multiple ownership even when the functional value happens
to agree.

## Runtime-Confirmed Overlap Modes

The richest generated direct endpoint was rerun with only its eight bus
assertions converted to diagnostic logging. All internal selector assertions
remained enabled. The ordered `HRDATA=0` vector is:

```text
{error_retire, idle, phase_capture, phase_hold,
 enter_data_phase, error_complete, error_first, write_hit}
```

Observed modes were:

| Vector | Active owners | Boundary |
| --- | --- | --- |
| `01100000` | transaction idle + `ahb_phase_capture` | initial/ordinary active address capture |
| `01010000` | transaction idle + `ahb_phase_hold` | accepted phase held before transaction relaunch |
| `10100000` | `ahb_error_retire` + `ahb_phase_capture` | final ERROR plus accepted next active phase |

The final-ERROR continuation also produced explicit-OKAY `HRESP` vector
`110000000000`, identifying `ahb_error_retire` plus `ahb_phase_capture`.
No generated `HREADYOUT` conflict occurred because different-value priority
suppression already makes those enables exclusive.

The rich direct harness completed its active success/SEQ continuation, active
ERROR continuation, and ERROR-to-IDLE cancellation scenarios when only bus
assertions logged. The paired BUSY harness likewise completed four byte
writes, one qualified BUSY presentation, resumed SEQ, and final storage
`44332211`; its only logged conflicts were idle+capture and idle+hold around
the four admitted active phases. BUSY itself caused no capture or output
overlap.

## Boundary Result Matrix

| Boundary | Result |
| --- | --- |
| initial selected ready NONSEQ/SEQ capture | generated idle+capture `HRDATA=0` overlap reproduced |
| pending/wait hold | generated idle+hold `HRDATA=0` overlap reproduced; not-ready behavior preserved |
| successful read | one selected read-data family; no zero/read or read/read overlap observed |
| successful write | one `write_hit` family; storage behavior preserved |
| first and second ERROR cycles | `error_first` then `error_complete` remain sequential and exclusive |
| final ERROR plus active continuation | retire+capture `HRDATA=0` and explicit-OKAY `HRESP` overlaps reproduced |
| SEQ continuation | accepted, captured, completed, and applied exactly once in the rich runtime |
| BUSY parking | no phase capture; burst state/storage remained parked and resumed |
| IDLE after ERROR | no manufactured next phase; cancellation completed cleanly |

## Why The Generic Priority/Assertion Layer Is Not The Repair Owner

`FSM::Scheduler::ISF::LoweringIR` deliberately treats identical-operator,
identical-RHS assignment pairs as compatible in
`_rule_assignment_pair_compatible`. Priority suppression is applied to
conflicting different-value rule/transaction pairs, not to redundant
same-value ownership. `FSM::IR::LoweredRTLIRBuilder` then intentionally emits
both same-value source assertions and whole-target multi-value assertions.

Changing either generic behavior would hide ownership errors in every ISF
actor. The generated AHB endpoint already demonstrates that generic
different-value priority suppression works: no `HREADYOUT` conflict fires.
The remaining failures are redundant or non-exclusive output authoring local
to `AhbSubordinate.pm`.

## Separately Routed Direct IAL0 Seed

`fsm/ahb_lite_subordinate.fsm` does not use the generated phase rules. Its
eight conflict targets include `HRDATA`, `HREADYOUT`, `HRESP`, `addr_q`,
`next_state`, `size_q`, `wait_ctr`, and `write_q`.

With all assertions enabled, the existing t1520 harness first stops on
`HREADYOUT` multi-value selection. Diagnostic-only bus logging while keeping
all internal assertions enabled proves three intentional conditional
overrides:

- access-state default `HREADYOUT=0` plus successful completion
  `HREADYOUT=1`;
- access-state default `HRDATA=0` plus successful read `HRDATA=reg_data_q`;
- access/unsupported-state default `HRESP=0` plus ERROR `HRESP=1`.

The functional t1520 success, active-ERROR, SEQ-to-ERROR, and ERROR-to-IDLE
scenarios all complete when only those bus assertions log. This is a distinct
direct IAL0 output-mode authoring issue, not a reason to weaken generic
assertions or broaden the selected generated-endpoint repair. Proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION` owns its future contract.

## Selected Next Contract Boundary

After this audit commits cleanly, activate only
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`. It must select an
exact generated-IAL1 output-ownership contract in `AhbSubordinate.pm` that:

- makes transaction idle, capture, hold, retire, enter, read/write success,
  and two-cycle ERROR sources mutually exclusive or removes only provably
  redundant writes;
- preserves initial capture, one-bank backpressure, wait timing, current
  completion plus next capture, read data, writes, success, ERROR, SEQ, BUSY,
  and IDLE behavior byte-for-byte where externally observable;
- keeps generic same-value and multi-value assertions enabled and unchanged;
- keeps public PPIF/AHB syntax, reports, support accounting, review artifacts,
  semantic/MCP surfaces, ports, widths, names, protocols, VHDL boundary, and
  decision 0020 unchanged;
- freezes an implementation leaf with assertion-enabled base/rich direct and
  one-/two-window paired gates, including removal of `--no-assert` only where
  the generated endpoint is the last blocker;
- preserves the separately owned direct IAL0 seed boundary and t1520 until its
  own task is selected;
- uses repository-local disposable storage, the authorized macOS
  `--host-max-pct 100 --process-max-rss-mb 4096` profile, exact
  Stats-compatible capacity reporting, separate kernel-pressure reporting,
  cleanup census, and rollback.

## Audit Behavior Boundary

This leaf changes documentation, task ownership, and durable evidence only.
No parser, generator, source language, support entry, test, tracked artifact,
report/schema, semantic/MCP API, HDL/runtime, backend, protocol, transaction,
or VHDL behavior changes.

All generation, metadata, Verilator build, and runtime commands used the
authorized macOS `--host-max-pct 100 --process-max-rss-mb 4096` profile and
completed without a descendant-cap trip. The post-audit exact
Stats-compatible reading was 49.5% (11.87/24.00 GiB); kernel pressure state was
`1` (normal). The guard's incompatible host percentage is not capacity
evidence.

The same-volume disposable audit workspace contained exactly 233 files and
210,967,439 bytes. It was removed after evidence capture, and the exact
workspace-name residue census is empty.

Focused preservation passed 34 tests across ten files in 611 wallclock
seconds: generic selector instrumentation and rule/transaction priority;
base, byte-lane, SEQ, HBURST/SEQ, and BUSY-park subordinate sources; paired
BUSY composition; rich generated phase-pipeline runtime; and the separately
owned direct-seed runtime.

The mdBook built successfully. Its generated output contained exactly 72
files and 16,031,568 bytes; it was removed after validation, and residue is
none. Knowledge Map generation/check passes at 1,014 facts and 5,155 question
keys. All doctrine gates pass.
