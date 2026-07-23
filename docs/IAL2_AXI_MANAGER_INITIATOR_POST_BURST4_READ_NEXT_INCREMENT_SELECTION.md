# IAL2 AXI manager initiator — post-burst4-read next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.39` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **fixed-four-beat full-width AXI4 manager W burst driver** as
the next functional increment after the fixed-four read composition ships.

The immediate owner is `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.40`, a
behavior-neutral readiness audit. It must choose and prove the exact upstream
four-beat payload contract, generated IAL1 schedule, `WVALID`/payload hold and
exactly-once behavior, `WLAST` sequencing, public/report/artifact boundary, and
following contract-selection owner before behavior changes.

The leading first boundary is one explicitly started four-beat transfer with
four 32-bit data values and four 4-bit strobes captured before issue, scalar
`WLAST=0` for indices 0 through 2 and `WLAST=1` for index 3, arbitrary
backpressure between beats, one aggregate busy interval, one per-beat event
plus two-bit index, and one final done event. `.40` may revise the payload
authoring shape only if compiler or interface evidence proves a safer smaller
contract.

## Why the standalone burst W driver is the prerequisite

The write path currently ships:

```text
one command -> AxiWDriver -> one WDATA/WSTRB transfer with WLAST=1
one aligned command -> AW + one W transfer -> request-done
one aligned command -> AW + one W transfer -> one B response -> transaction-done
```

The read path now additionally ships one AR followed by four explicitly owned
R transfers. That implementation can reuse `AxiRBeatAcceptor` unchanged because
RLAST is sampled input: the coordinator re-arms the one-beat receiver and
checks the observed last sequence.

The same reuse is impossible on W. `AxiWDriver` generates `WLAST=1` internally
for every accepted command and its report explicitly bounds it to one beat.
Re-arming it four times would therefore emit four separate one-beat write data
sequences, each claiming to be final, while `AWLEN=3` would require one
four-beat sequence with only the fourth WLAST asserted. A multi-beat AW+W or
AW+W+B composition cannot honestly ship until one child owns correct W beat
and WLAST progression.

Selecting the standalone driver keeps that new invariant isolated. It does not
prematurely choose AW launch concurrency, request-join semantics, B arming, or
full-transaction completion. Once the W burst primitive is proven, a later
fixed-four AW+W request composition can pair it with unchanged `AxiAwDriver`
at `AWLEN=3`/`AWSIZE=2`/`AWBURST=INCR`; the unchanged B acceptor can then close
the full transaction in a separate slice.

## Shipped evidence

### W and write compositions

`ppif/axi_w_driver.ppif` exposes one data32/strobe4 command. Generated
`AxiWDriver` captures that payload, drives it stably with `WVALID`, hard-wires
`WLAST=1`, and guarantees exactly one W handshake and one later done pulse.
Its explicit residue says beat counters, data sequences, dynamic WLAST, and
AWLEN/AWSIZE coupling remain future work.

`AxiWriteRequestComposition` reuses that unchanged child and fixes
`AWLEN=0`, `AWSIZE=2`, and `AWBURST=INCR`. Its completion means the one AW and
one W request transfers have both occurred. `AxiWriteTransactionComposition`
adds the unchanged B acceptor and keeps request-done distinct from the later
B-backed transaction-done event. Neither composition contains latent
multi-beat W supply or WLAST behavior.

### Fixed-four read proof

`AxiReadBurst4TransactionComposition` establishes that this compiler and C4
path can own a two-bit beat index, distinct per-beat and transaction events,
held-high bus valid across ready-low re-arm bubbles, count-authoritative
retirement, and exact reset/busy recovery. Those are useful schedule and proof
patterns, but the W driver must actively select and hold an outbound payload
for each index rather than merely capture an inbound tuple.

### Capacity/status boundary

`AxiManagerCapacityStatus` already ships broad abstract response bookkeeping,
including queues, demux, burst-length validation, RRESP aggregation, and
multi-beat read output banks. It still drives no AW/W/AR transaction channels.
Binding the physical transactors to it requires a separate adapter contract for
submit/completion timing, ID authority, payload/result ownership, and one exact
capacity variant. It is not smaller than proving the missing W burst primitive.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Fixed-four full-width W burst driver | Adds the missing outbound repeated-beat primitive and isolates WLAST/payload/backpressure correctness before AW/B coordination. A fixed payload bank avoids inventing an open-ended producer protocol in the first slice. | **Selected; `.40` readiness audit.** |
| Fixed-four AW+W request composition immediately | Cannot reuse the shipped W child honestly because that child fixes WLAST high. It would mix a new W primitive contract with AW launch/join and 4-KiB legality in one slice. | Deferred until the burst W driver ships. |
| Fixed-four AW+W+B full-write transaction | Additionally adds response arming, BID correlation, and full completion. The B child exists, but the W prerequisite is still absent. | Deferred behind W then AW+W request composition. |
| Authored or bounded-dynamic read length | Extends the just-shipped coordinator but adds arbitrary count width, command metadata, dynamic 4-KiB legality, and a more general malformed-response matrix without adding the missing write capability. | Deferred after balanced fixed-four physical read/write primitives. |
| Physical-to-capacity/status adapter | Must choose event, ID, storage, backpressure, and target-variant authority. Existing capacity machinery should be reused, not copied into a physical composition. | Deferred. |
| Response aggregation/output banks inside burst4 read | Already mature in the abstract capacity/status family; duplicating it would create two storage/aggregation authorities. | Rejected as a physical-composition responsibility; future adapter work owns reuse. |
| Multiple outstanding/back-to-back reads or writes | Requires queues, allocation/reuse, ordering, BID/RID demux, buffering, and possibly interleaving. | Deferred. |
| Malformed-subordinate timeout/recovery | Introduces time policy, abort/resynchronization, and observable failure semantics; it is not a smaller normal-operation increment. | Deferred. |
| Protocol-neutral transaction interface | Decision 0020 North Star, explicitly director-gated and not PNT-eligible. | Preserved, not activated. |

## Leading bounded behavior for `.40`

The readiness audit starts from this candidate:

```text
one idle start carrying four (WDATA32, WSTRB4) tuples
  -> capture all four tuples atomically
  -> drive tuple 0 with WVALID, WLAST=0 until accepted
  -> drive tuple 1 with WVALID, WLAST=0 until accepted
  -> drive tuple 2 with WVALID, WLAST=0 until accepted
  -> drive tuple 3 with WVALID, WLAST=1 until accepted
  -> retire once, with four beat events and one final done event
```

Every strobe, including zero, remains raw and legal. There is no address in
this primitive, so alignment, 4-KiB containment, AWLEN/AWSIZE/AWBURST, and lane
placement beyond the 32-bit full-width shape remain composition concerns.

The audit must compare at least these upstream payload forms:

1. four explicitly named data/strobe command fields captured atomically;
2. one packed 128-bit data plus 16-bit strobe bank; and
3. a streaming producer valid/ready interface feeding each W beat.

The leading explicit-field form is easiest to review in PPIF and matches the
project's existing field-oriented contracts. Packed banks reduce port count
but obscure beat ownership. Streaming is the scalable end state but adds a
second handshake protocol, buffering, and producer backpressure before the
bus-side progression is proven.

## Exact `.40` readiness owner

Without changing behavior, `.40` must audit:

- exact Issue L anchors for W channel direction, per-beat handshake,
  WDATA/WSTRB stability, WLAST, burst length, and reset;
- explicit fields versus packed bank versus streaming producer, selecting one
  bounded four-beat command surface;
- exact role/profile/reset, signal names, widths, private namespace, distinct-
  name and fail-closed policy;
- whether to add `AxiWBurst4Driver` or safely generalize/reuse `AxiWDriver`,
  preserving the shipped one-beat source and behavior either way;
- atomic payload capture, two-bit index, WVALID assertion/deassertion,
  WDATA/WSTRB/WLAST stability under arbitrary WREADY stalls, consecutive
  ready-high beats, exactly four accepted transfers, busy-command ignore,
  per-beat/final events, and reset at every index;
- generated IAL1 actor structure, storage/rules or state schedule, priorities,
  compile issues, generated IAL0 artifact, HDL entry, report schema/sections,
  static rules, residue, and diagnostics;
- public PPIF object/source, parser/generator/support/manifest/test/book/fact
  owners and expected accounting deltas only after exact spelling is selected;
- strict/check/schedule/semantic/outdir/Verilator/Yosys surfaces and a
  generated-HDL matrix covering WREADY low/high/pulsed, input mutation after
  admission, all-zero and partial strobes, busy command, reset between beats,
  exact beat indices/WLAST sequence, recovery, cardinality, and final idle;
- exact contract-selection and atomic implementation leaves, validation, and
  rollback; and
- preservation of standalone single-beat W, all current write/read
  compositions, dynamic/general bursts, AW/address coupling, B completion,
  capacity integration, outstanding/queues/demux/interleaving, aliases,
  decision 0020, verification output, direct/backend/VHDL, AHB, and APB.

## Validation and rollback

This documentation-only slice is validated with Knowledge Map generation and
checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the full
doctrine gate. The shipped t/1500, t/1502, t/1503, and t/1507 behavior is read
as evidence; no behavior changes require rerunning it.

Rollback removes this selector and its fact card, restores `.39` to active,
removes `.40`, and restores task-index/book/Memory pointers. No parser,
generator, source, support, manifest, test, artifact, runtime, or HDL rollback
is required.
