# IAL2 AXI manager initiator — post-full-read next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.35` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **full-width INCR multi-beat AXI4 manager read-transaction
composition** as the next functional increment after the fixed-single-beat
full-read composition ships.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.36`, a behavior-neutral readiness audit.
It must choose and prove the smallest honest burst cardinality contract — the
leading candidate is a fixed four-beat, `ARLEN=3`, `ARSIZE=2`,
`ARBURST=INCR` composition — plus the per-beat observation surface, coordinator
schedule, error/retirement policy, artifacts, diagnostics, generated-HDL
matrix, and exact following contract-selection owner before behavior changes.

The direction remains one outstanding read with one admitted ARID. It does not
select multiple outstanding transactions, interleaving, a capacity/status
adapter, a protocol-neutral transaction interface, or broad dynamic burst
support. The shipped fixed-single-beat source and every existing child remain
unchanged.

## Why this is the next functional boundary

The initiator thread now ships complete bounded physical transactions on both
sides:

| Surface | Shipped boundary |
| --- | --- |
| Full write | One aligned AW+W request followed by one owned B response. |
| Full read | One aligned AR request followed by one owned R beat. |

The fixed read path establishes every prerequisite that was missing when
multi-beat receive was last deferred: an exactly-once AR driver, an explicitly
armed exactly-once R acceptor, causal post-AR receive ownership, retained ARID,
raw result capture, separate request/transaction completion, reset semantics,
and a flat C4 coordinator/top pattern.

The smallest behavior-bearing extension is therefore to repeat the already
owned R-beat acceptance under one request and make completion depend on a
bounded beat count plus `RLAST`. A fixed full-width INCR burst avoids inventing
a general command-side length/size/burst API in the first slice while proving
the genuinely new part: safe repeated receive ownership and truthful burst
retirement.

## Shipped facts that constrain the selection

### Physical AR/R path

`ppif/axi_read_transaction_composition.ppif` ships one aligned address32/ID4
command, fixed `ARLEN=0`/`ARSIZE=2`/`ARBURST=INCR`, unchanged AR and R children,
and a zero-state seven-rule coordinator under a 27-port three-child C4 top.
Request-done means AR acceptance; transaction-done means the one owned R beat
retired. RID and RLAST mismatches are assertion/status-visible and terminal,
while RRESP stays raw.

The standalone `AxiRBeatAcceptor` is deliberately one arm/one beat. It raises
RREADY independently of RVALID, captures RID4/RDATA32/RRESP2/RLAST1 raw,
returns idle after exactly one handshake, and emits one later beat-done pulse.
It does not claim transaction completion. Repeated use must preserve that
contract rather than silently widening it.

### Capacity/status shell

`AxiManagerCapacityStatus` already has deep abstract read capabilities:
transaction envelopes, concrete/dynamic IDs, same-ID queues, RID demux,
raw-ARLEN capture, runtime beat-count/`RLAST` assertions, per-beat output banks,
and worst-observed RRESP aggregation. Those behaviors consume authored submit,
completion, ID, and response events. They do not own a physical AR/R command
handshake or define the adapter between the new transactor and a selected
capacity variant.

This maturity argues against duplicating output-bank or queue machinery in the
physical composition. It does not make immediate integration small: an adapter
still must choose request-event timing, ID allocation authority, completion
authority, response storage ownership, backpressure, and one exact target
variant.

### Architectural constraints

- Decision 0014 continues to require IAL2 -> generated IAL1 -> generated IAL0
  -> HDL; a burst coordinator cannot lower directly.
- Decision 0015 permits profile aliases but does not make `.axi` the canonical
  source or grant aliases to unselected objects.
- Decision 0018 keeps the public contract and report backend-neutral.
- Decision 0020 is a director-gated future transaction-interface horizon. A
  raw AXI beat event/result surface remains a bus-side primitive beneath it and
  does not activate that interface.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Bounded full-width INCR multi-beat read composition | Directly extends the just-shipped AR/R path. One outstanding ID avoids queues/demux; repeated one-beat R ownership can remain explicit; fixed size/burst/cardinality can bound legality and proof. | **Selected; `.36` readiness audit.** |
| Dynamic ARLEN multi-beat read in the first slice | Useful end state, but adds arbitrary length validation, counter range, 4-KiB legality, output-consumption policy, and more error cases before repeated receive is proven. | Audit may compare it, but the leading first contract is fixed four beats. |
| Multi-beat write | Requires a new upstream per-beat WDATA/WSTRB supply/acceptance contract and dynamic/final WLAST policy before the existing W child can be sequenced. | Deferred behind the smaller inbound read-burst proof. |
| Physical transaction to capacity/status adapter | Prerequisites now exist, but event/ID/storage/backpressure authority and one target capacity variant remain unresolved; at one outstanding transaction it adds little physical capability. | Deferred until the burst-side physical event boundary is explicit. |
| Back-to-back or multiple outstanding operation | Requires admission queues, ID allocation/reuse/order, response ownership, RID/BID demux, and possibly read interleaving. | Deferred. |
| Broader request legality or attributes | Extended AR/AW attributes and generalized narrow/wrap/unaligned rules are useful but do not establish repeated-beat transaction behavior. | Deferred; the selected audit owns only fixed full-width INCR legality. |
| `.axi` aliases for initiator objects | Small mechanically, but adds spelling rather than transaction capability and must remain exact semantic parity with `.ppif`. | Deferred to a later profile-surface slice. |
| Protocol-neutral transaction interface | Decision 0020 North Star, explicitly not PNT-eligible without director activation. | Preserved, not activated. |

## Selected bounded behavior for readiness analysis

`.36` starts from the following proposed boundary and may narrow it if compiler
or protocol evidence requires:

```text
one idle aligned address32/ID4 command
  -> one AR transfer with fixed full-width INCR burst metadata
  -> one outstanding read ownership interval
  -> repeated explicitly owned raw R-beat transfers
  -> one per-beat observation event after each capture
  -> one transaction retirement when bounded count and RLAST agree
```

The leading first contract is four beats:

- `ARLEN=3`, so exactly four transfers are expected;
- `ARSIZE=2`, so each transfer is one 32-bit word;
- `ARBURST=INCR`;
- address width 32 and ID width 4;
- one retained ARID shared by all four expected R beats;
- no interleaving or second request admission; and
- a burst legality guard that includes four-byte alignment and the AXI 4-KiB
  boundary rule for the fixed four-beat span.

The audit must decide whether fixed four beats is indeed smaller and more
honest than an authored bounded `ARLEN`, and must record concrete compiler and
runtime evidence for that choice. It may not silently broaden to arbitrary
size, wrapping bursts, narrow/unaligned transfers, or multiple IDs.

## Likely reuse and new ownership

### Reuse candidates

- the unchanged `AxiArDriver`, driven with constant length/size/burst metadata;
- the unchanged `AxiRBeatAcceptor`, re-armed once per expected beat only if the
  audit proves held-high RVALID and the ready-low re-arm bubble cannot lose or
  double-accept data;
- the full-read flat C4 top/coordinator/report pattern;
- retained ARID matching and raw RID/RDATA/RRESP/RLAST capture; and
- separate request-done and transaction-done pulses.

### New behavior in the later implementation

- bounded beat index/count ownership across the burst;
- repeated R-arm generation after each non-terminal beat;
- an explicit public per-beat capture-valid/done event so raw results are not
  mistaken for a single stable transaction result;
- count/`RLAST` agreement status and assertions;
- reset/error policy at every beat position;
- fixed-burst 4-KiB boundary legality; and
- one new additive public object/source/report/support/test identity selected
  by a later contract leaf.

The first physical burst composition should not duplicate the capacity shell's
per-transaction output banks or general RRESP aggregation. The audit must
choose the smallest raw per-beat observation contract that remains usable and
backend-neutral, and keep capacity-owned storage/aggregation explicit residue.

## Error and retirement questions owned by `.36`

Multi-beat retirement cannot blindly copy the one-beat terminal policy. The
audit must prove exact outcomes for:

- matching RID and `RLAST=0` on non-final beats;
- matching RID and `RLAST=1` on the expected final beat;
- RID mismatch on an early or final beat;
- early RLAST before the expected count;
- missing RLAST at the expected count;
- non-OKAY RRESP on any beat without conflating retirement with success;
- reset before AR acceptance, after AR acceptance, and between arbitrary R
  beats; and
- RVALID held continuously across the child accept/re-arm bubble.

The preferred safety direction is to keep an error sticky and either drain the
bounded owned burst or terminally retire only where the protocol says no later
beat can legitimately arrive. `.36` must select this precisely with an
executable temporary harness; it must not leave a consumed-beat error policy
implicit.

## Exact `.36` readiness owner

Without changing shipped behavior, `.36` must audit:

- fixed-four versus authored-bounded length and choose one exact first slice;
- exact source anchors for burst length, dependency, per-beat response,
  `RLAST`, ID, signal directions, and 4-KiB boundary legality;
- public command, AR, R, raw per-beat result/event, aggregate status,
  role/reset, width, and distinct-name vocabulary;
- whether unchanged AR and repeated unchanged R child reuse is timing-safe;
- coordinator ports/storage/rules/priorities, beat count, R re-arm timing,
  request/beat/transaction pulses, busy-command behavior, and reset;
- fixed metadata and 4-KiB admission guards/assertions;
- RID/count/RLAST/RRESP error and retirement semantics, including sticky
  status and whether draining is required;
- flat C4 topology, fanout, net/link/artifact/schedule cardinality, selected
  HDL entry, report/static/residue contract, and fail-closed diagnostics;
- public check/schedule/semantic/outdir/Verilator/Yosys surfaces and an
  executable matrix covering continuous/stalled/pulsed ARREADY, already-high/
  delayed/continuously-held RVALID, all beat positions, busy commands, reset,
  raw statuses, early/missing last, ID mismatch, exact counts, and final idle;
- parser/generator/source/support/manifest/test/book/fact/task owners,
  expected support-accounting deltas, rollback, following contract-selection
  leaf, and atomic implementation leaf; and
- explicit preservation of the fixed-single-beat source, multi-beat write,
  dynamic/general bursts, output banks/aggregation, capacity integration,
  outstanding/back-to-back/queues/demux/interleaving, aliases, decision 0020,
  verification output, direct/backend/VHDL, AHB, and APB behavior.

The audit may revise the leading fixed-four topology only when source,
scheduler, C4, or executable-HDL evidence demonstrates a safer smaller
boundary. It may not implement the parser, generator, source, or runtime.

## Validation and rollback

This documentation-only slice is validated with Knowledge Map generation and
checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the full
doctrine gate. The shipped full-read/full-write tests are evidence read; no
behavior changed that requires rerunning them.

Rollback removes this selector and its fact card, restores `.35` to active,
removes `.36`, and restores task-index/book/Memory pointers. No parser,
generator, source, support, manifest, test, artifact, runtime, or HDL rollback
is required.
