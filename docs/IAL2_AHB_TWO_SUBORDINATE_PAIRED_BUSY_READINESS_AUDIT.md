# IAL2 AHB Two-Subordinate Paired BUSY Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.798`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.798` confirms that the current generator can
compose the shipped BUSY-inserting requester with both shipped BUSY-parking
subordinates in the bounded two-window aggregate. Check, schedule, semantic,
review-artifact, SystemVerilog generation, and Yosys validation all pass for a
temporary four-child candidate.

The audit does **not** select the paired public source contract yet. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.799`, a smaller report-only prerequisite:
repair contradictory BUSY support wording already exposed by the shipped
two-subordinate BUSY-park `.ppif` and `.ahb` reports. After `.799`, `.800` owns
the paired public contract selection.

This ordering keeps the public introspection surface truthful before a new
source reuses it. `.798` changes no parser, generator, report, source, support
catalog, test, generated artifact, HDL/runtime behavior, backend, AXI/APB
behavior, broader AHB behavior, or VHDL behavior. Decision `0020`, the
transaction-layer horizon, and all proposed audits remain inactive.

## Evidence Read and Reverified

The audit read:

- `.797` and the complete `.782`-`.796` two-subordinate BUSY-park, requester
  BUSY, and one-subordinate paired lineage;
- the generic and alias two-subordinate BUSY-park sources, the generic and alias
  one-subordinate paired sources, and the BUSY requester sources;
- `AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, the PPIF adapter,
  support/language/capability surfaces, and focused tests t/1480, t/1492,
  t/1496, t/1497, t/1512, t/1513, t/1514, t/248, and t/297;
- README, ROADMAP_V2, the AHB mdBook chapter and feature backlog, Knowledge Map,
  task tree, Memory, proposed audits, and decision `0020`.

The audit reproduced `.797`'s in-memory candidate and then materialized the same
source only under a temporary `/tmp` audit directory. Nothing under `ppif/`,
`generated/`, `.artifacts/`, or another tracked product surface was added.

## Temporary Candidate Shape

The candidate derives only from
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`:

```text
base requester object:
  amba_requester

candidate requester object:
  amba_requester_busy_insert

added requester transfer fields:
  busy = 2'b01
  busy-before-beat = 2

requester child reference:
  amba_requester_busy_insert
```

The status and control subordinates, address map, decode, response mux, bus
wiring, wait controls, storage, HBURST policy, and BUSY parking clauses are
unchanged. The candidate identity used by the audit is provisional; `.800`
must freeze the public path, intent, anchor, support id, and coverage key.

## Public Surface Probe Results

The temporary candidate passed non-strict public check JSON with no diagnostics:

```text
success:                 true
module:                  ahb_tb
composition child count: 4
signal count:            29
state count:             0
support match:           false (expected for an untracked audit fixture)
```

Schedule JSON preserved schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and reported:

```text
IAL1:
  amba_requester_busy_insert.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry: ahb_tb
children[0].busy_insertion: one BUSY before beat 2
children[2].transfer.seq_policy.parks_on: [busy]
children[3].transfer.seq_policy.parks_on: [busy]
composition propagation for both subordinates: parks_on=[busy]
```

The address-map report remained exact:

```text
status:  base 0, size 4, limit 4
control: base 4, size 4, limit 8
```

Semantic export passed with source root `top`, module `ahb_tb`, child count 4,
29 module signals, generated HDL present, and no diagnostics. Its unmatched
support status is again expected for the temporary fixture.

Review-artifact generation wrote the exact four IAL1 and five IAL0 files above.
The generated SystemVerilog contains 21,656 lines / 1,712,866 bytes. Direct
Yosys `read_verilog -sv -noautowire; synth -noabc -top ahb_tb; stat` completed
successfully. These probes used direct macOS pressure and descendant-RSS
observation; pressure headroom stayed available and the heaviest observed
generator stayed well below the 4 GiB process ceiling.

## No Generator or Wiring Prerequisite

The current paths already provide everything the paired topology needs:

- `AhbRequester` emits the shipped one-BUSY sequence and report metadata;
- `AhbInterconnect::_child_report` now conditionally propagates
  `busy_insertion` from `.794`;
- both `AhbSubordinate` children park their burst context on BUSY;
- `_seq_policy_propagation_report` copies both parked child policies;
- the interconnect fans out requester HBURST/address/control/data;
- status decode selects `[0,4)` and forwards the absolute zero-base local
  address;
- control decode selects `[4,8)` and forwards local address `HADDR - 4`;
- ready/response/read-data muxing already handles both children; and
- the generated top uses legal instance names `requester`, `fabric`, `status`,
  and `control`.

No parser, endpoint generator, child-report propagation, interconnect topology,
phase-ownership, decode, mux, top, or HDL substrate repair is indicated.

## Exact Future Runtime Proof Is Feasible

The generated top exposes the same command/status interface as t/1513, with
separate `status_wait_cycles` and `control_wait_cycles`. It also exposes stable
hierarchical observation points:

```text
dut.comp_link_requester_HTRANS / HADDR / HWRITE / HSIZE / HBURST / HWDATA
dut.comp_link_fabric_HSEL_STATUS / HADDR_STATUS
dut.comp_link_fabric_HSEL_CONTROL / HADDR_CONTROL
dut.comp_link_fabric_HREADY / HRESP

dut.status.seq_valid_q / seq_expected_addr_q / seq_beats_remaining_q
dut.status.status_data_q
dut.control.seq_valid_q / seq_expected_addr_q / seq_beats_remaining_q
dut.control.control_data_q
```

`.800` must select a focused generated-HDL proof with two sequential byte
`INCR4` commands:

1. **Status command at address 0.** Observe
   `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2) -> SEQ(3)`, status selected,
   status context/storage held across BUSY, control context/storage unchanged,
   four data beats, OKAY/zero completion, and status final storage
   `32'h44332211` for the existing t/1513 data pattern.
2. **Control command at address 4.** Observe the same transfer sequence, control
   selected, `HADDR_CONTROL` progressing locally `0,1,2,3`, control context/
   storage held across BUSY, status storage unchanged, four data beats,
   OKAY/zero completion, and a distinct control final value (for example
   `32'h88776655` from `cmd_wdata=32'h55555555` and step `32'h11111111`).

The exact values, harness/test names, and whether to share or factor the t/1513
monitor are public-contract choices for `.800`. `.798` claims feasibility, not
an executed two-command runtime simulation.

## Report Contradiction and Root Cause

The shipped two-subordinate BUSY-park `.ppif` report currently says:

```text
ahb_broader_interconnect_decode_deferred:
  ... BUSY-in-burst continuation ... remain future work.

ahb_burst_seq_support_deferred:
  ... ships ... with BUSY-in-burst parking ...
```

The same contradiction reaches the matching `.ahb` alias because alias cleanup
does not remove `ahb_broader_interconnect_decode_deferred`.

Root cause is `AhbInterconnect::_unsupported_residue`. It computes both:

```text
$hburst_seq_policy_selected
$hburst_busy_park_selected
```

but the two-subordinate broader-interconnect detail branches only on the first.
The dedicated burst residue correctly branches on the second. The broader text
therefore retained pre-BUSY-park wording after `.782` shipped parked sources.
This is report/introspection drift, not a runtime parking defect.

## Selected `.799` Prerequisite

`.799` owns a report-only repair before `.800` selects the new source contract.
It must:

- make the two-subordinate broader-interconnect detail branch on
  `$hburst_busy_park_selected` before the generic HBURST branch;
- state positively that the selected parked sources ship byte-only
  `WRAP4`/`INCR4` propagation **with BUSY-in-burst parking** and remove only the
  contradictory BUSY-continuation deferral from that branch;
- preserve the existing BUSY-continuation deferral for the non-parking
  two-subordinate HBURST `.ppif` and `.ahb` sources;
- preserve one-subordinate reports, all residue ids, support counts, generated
  artifacts, check/schedule/semantic structure, and HDL/runtime behavior;
- lock generic parked behavior in t/1496, alias parked behavior in t/1497, and
  non-parking preservation in t/1492/t/1493;
- update the existing aggregate BUSY-park behavior/alias docs, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map without adding a new source; and
- run focused report tests plus docs/doctrine gates, then activate `.800`.

No parser, source, support accounting, generated artifact, bus behavior, paired
source, broader residue cleanup, BUSY policy/status, burst progression, optional
signal, proposed-audit, transaction-layer, backend, AXI/APB, or VHDL change is
selected.

## Why Repair Comes Before the Paired Contract

The contradiction already affects shipped user-facing schedule/report JSON.
Repairing it is smaller and independently verifiable, avoids copying false
introspection into another public source, and keeps `.800` focused on the new
source/support/runtime contract. Bundling the repair with implementation would
obscure whether report preservation or new behavior caused a regression.

## Validation

`.798` closeout uses the temporary candidate probes above, direct live residue
inspection, Knowledge Map generation/check, mdBook build, docs-relative paths,
Memory architecture, diff, and doctrine gates. No temporary candidate or
generated artifact remains after closeout.

## Rollback

Rollback is documentation-only: remove this audit/fact, restore `.798` as
active, remove `.799`/`.800`, and revert public docs, task tree, Memory, and
Knowledge Map. The temporary probe directory is disposable and untracked.
