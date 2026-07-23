# IAL2 AHB Two-Subordinate Paired BUSY Composition Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.801`

Date: 2026-07-23

## Outcome

FSMGen ships one bounded generic AHB aggregate that pairs the existing
single-BUSY requester with two existing HBURST-aware byte-lane subordinates.
Both the status and control subordinate park their burst context across the
requester's BUSY presentation:

```text
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

This is one new public IAL2 source over the existing generator architecture,
not a new generator. It lowers through the existing pipeline:

```text
IAL2 source
  -> amba_requester_busy_insert.isf
   + ahb_status_subordinate_byte_lane_hburst_seq.isf
   + ahb_control_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert.fsm
   + ahb_status_subordinate_byte_lane_hburst_seq.fsm
   + ahb_control_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

The bounded shape is one requester, two four-byte static windows, one 32-bit
register per subordinate, byte-only `WRAP4`/`INCR4`, and one BUSY presentation
before beat index two. This slice ships the generic `.ppif` surface only.

## Source, Windows, and Report Contract

The source is the shipped two-subordinate BUSY-park aggregate with only its
identity/anchor and requester selection changed. The requester is
`amba_requester_busy_insert` with `(busy 2'b01)` and
`(busy-before-beat 2)`. Both subordinate sources retain
`(seq-policy hburst-in-word-progressive)` and `(parked-transfer busy)`.

The static windows remain:

```text
status:  global [0,4), local address HADDR
control: global [4,8), local address HADDR - 4
```

Strict check reports module `ahb_tb`, four children, 29 top signals, and no
top-local state. Semantic JSON retains root `top`. Schedule/report JSON keeps
schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and exposes:

- requester child `busy_insertion` with BUSY encoding `2'b01`, insertion index
  two, one bounded presentation, and generated behavior;
- `parks_on = [busy]` for both status/control child SEQ policies and both
  propagated composition entries;
- BUSY-free `clears_on` for both children;
- the exact status/control windows and generated artifacts above; and
- no duplicated composition-level `busy_flow` summary.

The `.799` report repair remains in force. Parked two-subordinate sources
positively record shipped byte-only in-word `SEQ` propagation with
BUSY-in-burst parking and do not call BUSY continuation deferred. Non-parking
sources retain that deferral.

## Generated-HDL Runtime Proof

`t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` generates
`ahb_tb`, verifies its HDL, builds it with Verilator, and drives two sequential
byte `INCR4` write commands through the public command interface:

| Command | Global base | Initial data | Step | Final storage |
|---|---:|---:|---:|---:|
| status | `0` | `32'h11111111` | `32'h11111111` | `32'h44332211` |
| control | `4` | `32'h55555555` | `32'h11111111` | `32'h88776655` |

Each command observes exactly:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

The runtime proof establishes one BUSY presentation and four accepted data
beats per command. Requester address/control/data and counters hold across
BUSY. The selected subordinate holds continuation state and storage without a
BUSY data completion, while the unselected subordinate remains unchanged.
The control transaction proves global addresses `4,5,6,6,7` map to local
addresses `0,1,2,2,3`. Both commands complete with OKAY status and zero
remaining beats; status retains `32'h44332211` after control finishes.

The complete focused test passed 67 assertions across source/report,
strict/semantic/artifact/HDL, and generated-HDL runtime subtests. No new public
debug port or generator algorithm was required.

## Support and Commands

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
HDL module:    ahb_tb
child count:   4
semantic root: top
```

The corpus contains 313 protocol fixtures and 354 supported-smoke/strict
entries after this additive source.

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
prove -Iperl t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
```

## Preservation and Deferrals

The implementation is additive source/support/test/documentation data. It
does not change parser, requester, subordinate, interconnect, IAL1, IAL0, or
HDL generator algorithms. The one-subordinate paired `.ppif`/`.ahb` family,
parked two-subordinate family, and non-parking two-subordinate family retain
their existing behavior and reports.

A matching `.ahb` profile alias now ships as documented in
`docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md`.
Policy-driven or multiple BUSY insertion, distinct local bus-BUSY status, true boundary-free
active-transfer pipelining, halfword/word or wider/indefinite burst
progression, multi-word/register-bank behavior, optional AHB signals, broader
AHB manager behavior, direct backend, verification-output generation,
backend-language variants, AXI/APB behavior changes, VHDL, decision `0020`,
and the protocol-neutral transaction-layer horizon remain deferred/inactive.
