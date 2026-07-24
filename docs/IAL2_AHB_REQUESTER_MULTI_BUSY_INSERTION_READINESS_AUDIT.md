# IAL2 AHB Requester Multiple-BUSY Insertion Readiness Audit

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`

Date: 2026-07-24

## Outcome

The bounded multiple-BUSY substrate is feasible, but public multiple-BUSY
contract selection is not yet safe. The audit found a pre-existing cardinality
defect in the shipped single-BUSY requester: with `HGRANT=1` and `HREADY=1`
continuously, the generated HDL keeps `HTRANS=BUSY` asserted for ten accepted
clock edges even though the public source requests one insertion and schedule
JSON reports `busy_insertion.beats=single`.

The current focused and paired regressions count changes between transfer
types, not ready-qualified BUSY edges. They therefore observe one contiguous
BUSY *episode* and four completed data beats, but do not prove the advertised
single-BUSY cardinality.

This audit selects
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2`, a no-behavior
contract selection for repairing the shipped single-BUSY event cardinality.
Multiple-BUSY syntax and behavior remain deferred until that prerequisite
ships and the audit resumes from a clean tree.

No parser, generator, source, support-accounting, capability, generated
artifact, HDL, runtime, backend, AXI, APB, or VHDL behavior changes in this
audit.

## Source-Backed Timing Boundary

The repo-local Arm AMBA 5 AHB Protocol Specification
(`docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf`)
settles two points that must not be conflated:

- Section 3.2 defines BUSY as an ignored, zero-wait transfer that retains the
  next burst transfer's address/control.
- Section 3.7 permits a fixed-length burst manager to change `HTRANS` from
  BUSY to SEQ while `HREADY` is low; after changing to SEQ, it must hold SEQ
  until `HREADY` becomes high.

Therefore the initially suspicious current transition from BUSY to SEQ during
a long ready-low interval is not by itself an AHB violation. The reproduced
defect is instead the continuously-ready case: every rising edge with
`HGRANT && HREADY && HTRANS==BUSY` is a separate accepted requester BUSY event,
and the current generator produces ten such events for the reported `single`
contract.

`HGRANT` is part of FSMGen's requester interface and existing active-address
accept predicate, while arbitration details are interconnect-defined in the
imported AMBA 5 AHB specification. This audit therefore uses the requester's
existing `HGRANT && HREADY` qualification consistently for BUSY event
retirement.

## Current Root Cause

The generated IAL1 insertion is:

```text
(when (& (== beat_index_q 2) (== busy_inserted_q 0))
  (drive transfer_busy)
  (set busy_inserted_q 1)
  (continue-when (== busy_inserted_q 1)))
```

`busy_inserted_q` records that the procedural `drive` was scheduled. It does
not record a bus acceptance. Lowering expands the drive, set, loop decision,
and later SEQ scheduling into distinct FSM states. `transfer_busy` remains the
registered output throughout those states, so continuously-ready generated HDL
exposes ten ready-qualified BUSY edges before `transfer_seq` replaces it.

Focused t/1498 and the t/1513/t/1515 paired harnesses increment BUSY count only
when `HTRANS` changes from another value. That is sufficient to prove one
contiguous episode, held fields/counters, resumed SEQ, and four data
completions, but not protocol-event cardinality.

## Disposable Runtime Matrix

All candidates were generated from the current public source's IAL1 under
`/tmp`; none changed the repository behavior. Verilator builds used generated
selector assertions for the accepted candidates.

| Probe | Ready behavior | BUSY episodes | qualified BUSY edges | data beats | Result |
| --- | --- | ---: | ---: | ---: | --- |
| shipped generated HDL | continuously high | 1 | 10 | 4 | contradicts `beats=single` |
| naive procedural ready gate | continuously high | 1 | 11 | 4 | rejected; loop control is not handshake retirement |
| selected single-event shape | continuously high | 1 | 1 | 4 | passes |
| selected single-event shape | low for 32 BUSY clocks, then high | 1 held episode | 1 after release | 4 | passes; same pending SEQ resumes |
| bounded count-two shape | continuously high | 1 contiguous episode | 2 | 4 | passes |
| bounded count-two shape | low for 32 BUSY clocks, then high | 1 held episode | 2 after release | 4 | passes; same pending SEQ resumes |

Both accepted candidates preserve `HADDR`, `HWRITE`, `HSIZE`, `HBURST`,
`HPROT`, `HWDATA`, `beat_index`, and `beats_remaining` across BUSY; BUSY does
not create address/data pending ownership, consume `HRESP`, complete a data
beat, or advance the address. The resumed SEQ is accepted once, and the INCR4
command completes with exactly four data beats and zero remaining.

## Feasible Event-Owned Shape

The single-event candidate adds a concurrent BUSY-accept rule that, on
`HGRANT && HREADY && HTRANS==BUSY`, arms the existing address-pending ownership
and drives the same pending transfer as SEQ for the following cycle. The
transaction marks the insertion one-shot and has an outer-loop BUSY gate that
prevents the procedural SEQ drive while BUSY is awaiting acceptance. This
produces one qualified BUSY event independent of generated microstate count.

The count-two feasibility candidate generalizes the same ownership boundary:

1. initialize a bounded `ahb_busy_remaining_q` before driving BUSY;
2. on each qualified non-final BUSY edge, decrement the counter and keep BUSY;
3. on the final qualified BUSY edge, clear the counter, arm
   `ahb_address_pending_q`, and drive the same pending transfer as SEQ;
4. while the counter is nonzero and BUSY is active, keep the procedural beat
   loop away from the normal SEQ drive.

Ready-low clocks do not decrement the counter. Consecutive ready-high clocks do.
The width-two literal-count candidate generated clean IAL0/SystemVerilog and
passed assertion-enabled ready-high and 32-cycle ready-low simulations. No
address/data/response ownership alias or combinational loop was observed.

## Rejected Output-Priority Route

A candidate tried to hold BUSY with a concurrent output rule declared higher
priority than the requester transaction. The scheduler accepted the priority
for overlapping storage writes, but the generated `HTRANS` unified mux still
enabled the rule's BUSY selector and the transaction drive's SEQ selector in
the same cycle. The generated assertion failed with
`selector multi-value conflict: HTRANS`.

That general rule-versus-transaction output-priority gap is not required by the
selected BUSY repair shape. It is durably routed to proposed inactive owner
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`; do not mix it into the AHB
repair.

## Selected `.2` Contract Questions

`.2` must freeze, without behavior changes:

- `busy_insertion.beats=single` as exactly one
  `HGRANT && HREADY && HTRANS==BUSY` event, not one signal transition or an
  implementation-dependent number of clocks;
- ready-low behavior, including whether the repaired bounded source chooses
  the stronger stable-BUSY-until-accept policy demonstrated here even though
  fixed-length AHB permits BUSY-to-SEQ while ready is low;
- the smallest persistent BUSY-pending/remaining state, concurrent acceptance
  rule, outer-loop gate, priorities, reset/command initialization, and direct
  mapping to the existing address-pending owner;
- exact t/1498 clock-edge counting, ready-low stability/transition proof,
  generated selector assertions, and preservation of four data beats;
- propagation to the `.ahb` alias and every paired generic/alias and
  one-/two-subordinate composition that embeds the requester;
- unchanged public syntax, object/module/artifact identities, report schema,
  support identities, and residue until a later multiple-BUSY contract; and
- validation, resource cap, documentation, rollback, and the clean handoff
  back to multiple-BUSY selection.

## Validation And Reproduction

The durable result is this record and its Knowledge Map fact. Disposable
candidate sources, HDL, harnesses, and object directories were kept outside the
repository and are not part of the product.

Current focused tests remain expected to pass because they prove BUSY episode
sequencing rather than accepted-edge cardinality. The implementation repair
must turn the disposable edge counter and ready-low scenario into tracked
regression coverage.

## Rollback

Rollback removes this audit record/fact and restores the active tree to its
pre-audit `.1` state. It does not alter shipped behavior. The pre-existing
cardinality contradiction must not be hidden by rollback; if this slice is
superseded, its replacement must preserve the reproduced evidence and own the
single-BUSY repair explicitly.
