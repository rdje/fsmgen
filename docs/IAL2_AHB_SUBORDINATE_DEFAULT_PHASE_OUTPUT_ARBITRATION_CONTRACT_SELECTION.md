# IAL2 AHB Subordinate Default/Phase Output-Arbitration Contract Selection

Task-tree owner:
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`

Date: 2026-07-29

## Outcome

The selected repair is local to generated IAL1 authored by
`FSM::IAL2::ProtocolIntent::AhbSubordinate`. It removes exactly five redundant
output writes while retaining the existing phase scheduler, values, timing,
priorities, and generic selector assertions.

Proposed child `.3` owns implementation after this contract commits cleanly.
This contract slice changes no parser, generator, public source, support
identity, report/schema, review artifact, semantic/MCP API, HDL, runtime,
backend, protocol, VHDL, or transaction-layer behavior.

## Selected Five-Write Removal

Implementation removes exactly these generated IAL1 writes:

| Rule | Removed write | Remaining output ownership |
| --- | --- | --- |
| `ahb_phase_capture` | `HRESP <- OKAY` | `HREADYOUT <- 0`; idle owns OKAY |
| `ahb_phase_capture` | `HRDATA <- 0` | `HREADYOUT <- 0`; idle owns zero data |
| `ahb_phase_hold` | `HRESP <- OKAY` | `HREADYOUT <- 0`; idle owns OKAY |
| `ahb_phase_hold` | `HRDATA <- 0` | `HREADYOUT <- 0`; idle owns zero data |
| `ahb_error_retire` | `HRDATA <- 0` | `HREADYOUT <- 1` and `HRESP <- OKAY` remain |

No other assignment changes. In particular, implementation retains:

- transaction-idle `HREADYOUT=1`, `HRESP=0`, and `HRDATA=0` defaults;
- capture/hold `HREADYOUT=0` backpressure;
- retirement `HREADYOUT=1` and explicit OKAY response;
- full `enter_data_phase`, read, write, `error_first`, and `error_complete`
  drives; and
- every declared priority and every generic same-value and multi-value
  selector assertion.

## Selected Phase Modes

Initial and ordinary selected active capture use complementary ownership:
capture owns the not-ready indication while the idle transaction owns OKAY and
zero data. While a captured phase is held, hold owns not-ready and idle again
owns OKAY and zero data. Existing different-value priority suppression keeps
the idle ready-one assignment out of both modes.

When the current transaction starts, `enter_data_phase` owns not-ready, OKAY,
and zero data. Exactly one completion drive then owns the bus: a selected read,
write success, first ERROR cycle, or final ERROR cycle. Read data and lane
masking remain unchanged.

On final ERROR plus same-edge next-phase capture, capture owns not-ready and
error retirement owns OKAY. `HRDATA` remains zero from the immediately
preceding two-cycle ERROR drives, so retirement does not need a third zero
write. On final ERROR without a next phase, retirement restores ready/OKAY and
the endpoint returns to idle. This contract does not introduce source-order
masking or weaken impossible-overlap detection.

## Assertion Family Effect

For the richest byte-lane/HBURST/SEQ/BUSY-park variant, the `HRDATA=0`
same-value family decreases from eight sources to five:

1. transaction idle;
2. `enter_data_phase`;
3. `error_complete`;
4. `error_first`; and
5. `write_hit`.

The explicit-OKAY `HRESP` family decreases from twelve sources to ten by
removing capture and hold. `HREADYOUT` families are byte-for-byte unchanged.
All remaining families and the whole-target multi-value assertions stay
enabled so any genuine non-exclusive owner still fails.

## Feasibility Proof

The richest public source,
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, was generated
into a repository-local disposable workspace. Only the selected five IAL1
lines were removed; the candidate then lowered through public `bin/fsmgen`,
compiled with Verilator, and ran the existing
`ahb_pipelined_active_transfer_audit_tb` with all assertions enabled.

The candidate completed all scenarios with the existing exact results:

| Scenario | Result |
| --- | --- |
| active success/SEQ continuation | 2 bus accepts, 2 captures, 2 completions, storage `00002211`, no response errors |
| active ERROR continuation | 2 accepts, 2 captures, 2 completions, 2 ERROR cycles, storage `000000aa` |
| ERROR-to-IDLE cancellation | 1 accept, 1 capture, 1 completion, 2 ERROR cycles, storage `00000000` |

No selector assertion fired. The disposable workspace contained exactly 47
files and 52,853,130 bytes. It was removed after evidence capture, and the
exact workspace-name residue census is empty.

All feasibility generation, lowering, compilation, and runtime commands used
the authorized `--host-max-pct 100 --process-max-rss-mb 4096` profile and did
not trip the descendant cap. The exact post-probe Stats-compatible capacity
reading was 40.8% (9.78/24.00 GiB), while the kernel pressure state was `1`
(normal). The guard's incompatible displayed percentage is not capacity
evidence.

## Implementation Gate

Proposed `.3` must:

1. remove only the selected five writes in `AhbSubordinate.pm`;
2. preserve structural coverage for base, byte-lane, SEQ, HBURST/SEQ, and
   BUSY-park variants;
3. prove base and richest direct endpoints with assertions enabled;
4. prove one-window and two-window paired generic/alias aggregates with
   assertions enabled, removing `--no-assert` only where this generated
   endpoint is the final blocker;
5. cover capture, hold/backpressure, same-edge success and ERROR continuation,
   read data, writes, SEQ, BUSY, two-cycle ERROR, and ERROR-to-IDLE cancellation;
6. retain `t/1520`'s direct-IAL0 assertion boundary under separately proposed
   `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`; and
7. prove unchanged public PPIF/AHB source bytes, syntax, ports, names, support
   accounting, reports, artifacts, normalized semantic JSON, read-only MCP,
   protocols, backends, VHDL, and decision 0020.

Focused validation includes t1475, t1482, t1486, t1490, t1494, t1513-t1516,
t1519, t1523, t1525, relevant t1518/t248/t297 coverage, syntax,
strict/check/schedule/artifact/verifier surfaces, Knowledge Map, mdBook, and
doctrines. Heavy runs use repository-derived same-volume storage and the
director-authorized macOS `--host-max-pct 100 --process-max-rss-mb 4096`
profile. Capacity is reported separately with the exact Stats-compatible Mach
formula; kernel pressure is reported from `kern.memorystatus_vm_pressure_level`.

## Non-Selections

This contract does not select:

- weaker or disabled generic selector assertions;
- generic rule/transaction priority or selector lowering changes;
- changes to transaction-idle, enter/read/write/ERROR drive values;
- a new output register, mux, state, queue, or phase;
- the separately owned hand-authored direct IAL0 seed repair;
- public syntax, reports, support, artifacts, semantic/MCP, protocol, backend,
  or VHDL expansion; or
- decision 0020.

## Rollback

Rollback of `.3` restores the five removed generated writes and all focused
assertion expectations together. It must not weaken generic assertions or
silently retain `--no-assert` where the generated endpoint is proven clean.
