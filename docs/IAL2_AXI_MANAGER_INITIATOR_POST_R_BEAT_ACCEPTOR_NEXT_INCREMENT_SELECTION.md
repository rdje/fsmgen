# IAL2 AXI manager initiator — post-R-beat-acceptor next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.31` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **fixed-single-beat AXI4 manager full-read transaction
composition** as the next increment after the standalone AR driver and R-beat
acceptor ship.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.32`, a behavior-neutral readiness audit.
It must prove the exact coordinator, flat structural topology, completion/error
semantics, artifacts, report, diagnostics, generated-HDL matrix, and owner map
before any public contract is selected or implemented.

The selected direction reuses the shipped `AxiArDriver` and
`AxiRBeatAcceptor` unchanged. A new read-transaction coordinator and one flat
three-child C4 top are required. One aligned command issues a deliberately
fixed request (`ARLEN=0`, `ARSIZE=2`, `ARBURST=INCR`), waits for the AR
handshake, arms the R child only after request acceptance, then retires after
exactly one captured R beat.

Completion remains truthful at both boundaries:

- request-done means the one AR request was accepted;
- transaction-done means the one owned R beat for the fixed-single-beat request
  was accepted and the bounded physical transaction retired;
- transaction-done does not mean `RRESP` was successful; and
- RID mismatch or missing `RLAST` is terminal and assertion/status-visible
  after the already-consumed beat, not a reason to hang forever waiting for an
  impossible replacement beat.

## Shipped surface audited

The initiator thread now has five standalone physical channel primitives:

| Primitive | Shipped boundary |
| --- | --- |
| AW driver | One stable AW request transfer per command. |
| W driver | One stable final W beat per command. |
| B acceptor | One explicitly armed raw BID/BRESP response per arm. |
| AR driver | One stable AR request transfer per command; done is request-only. |
| R acceptor | One explicitly armed raw RID/RDATA/RRESP/RLAST beat per arm; done is beat-only. |

It also has two write-side compositions: the bounded AW+W request join and the
bounded AW+W+B full-write transaction. The full-write implementation proves
the reusable architecture needed here: unchanged endpoint children, a distinct
coordinator, explicit constant C4 connections for fixed metadata, a flat
selected structural top, separate request/transaction completion, retained ID
correlation, raw response capture, terminal protocol-error reporting, and
generated-HDL cardinality proof.

The read side has reached the analogous prerequisite boundary:

```text
one dynamic AR command
  -> unchanged AR child -> exactly one AR handshake -> ar_done

one explicit receive arm
  -> unchanged R child -> exactly one R handshake
  -> raw RID/RDATA/RRESP/RLAST -> r_beat_done
```

The missing semantic edge is now coordination, not another channel primitive.

## AXI read dependency and completion evidence

The visually verified Issue L anchors already carried by the AR/R work fix the
safe dependency boundary:

- A2.3.2.2 (page 32): RVALID follows an accepted AR request; the subordinate
  must not wait for RREADY, while the manager may assert RREADY later;
- A2.6 (page 41): after issuing a read request, the manager must be able to
  accept the returned read data;
- A3.2.2 (page 55): RLAST marks the final read-data transfer;
- A3.3.2 (pages 62-63): every read-data transfer carries RRESP;
- A5.1.1 (page 90): ARID and RID use the same read-ID width; and
- B1.2.2 (page 281): RVALID/RID/RDATA/RRESP/RLAST are subordinate-sourced and
  RREADY is manager-sourced.

Arming the R child after AR acceptance is therefore legal even if the
subordinate has already raised RVALID: it must retain the beat until RREADY.
The bounded composition owns only one request and one response beat, so it can
retain the admitted ARID without an allocation table or queue.

For a request with `ARLEN=0`, the one accepted R transfer is the only expected
beat and must carry RLAST. The composition may consequently claim bounded
transaction retirement after accepting that beat, while still distinguishing
retirement from protocol success. Raw RRESP, ID match, and last match remain
observable results.

## Why request legality is part of composition, not a prerequisite slice

The standalone AR driver intentionally accepts dynamic LEN/SIZE/BURST fields
and leaves cross-field legality as residue. A full-read composition over a
one-beat R child must not expose that unrestricted request boundary and then
pretend one returned beat completes every request.

The safe solution is structural and already proven by the write request
composition:

```text
public command: address32 + id4
AR child constants: ARLEN=8'd0, ARSIZE=3'd2, ARBURST=2'b01
admission guard: address[1:0] == 2'b00
```

C4 already supports sized constant-to-child connections; the write
composition uses the corresponding AW constants. The read composition can
therefore reuse the dynamic standalone AR child while constraining only its
private composition instance. This closes fixed-single-beat legality locally,
preserves the standalone source unchanged, and avoids a low-value standalone
legality feature that still would not complete a read.

The readiness audit must verify whether any additional fixed-request rule is
needed beyond alignment, LEN zero, full 32-bit SIZE, INCR burst, fixed ID/data
widths, and the existing absence of extended AR attributes. It may narrow the
composition further if the generated topology or source evidence requires it;
it may not broaden to dynamic or multi-beat requests.

## Selected composition semantics

The following lifecycle is selected for `.32` to prove and refine:

| Boundary | Required meaning |
| --- | --- |
| Idle command admission | Atomically retain aligned address32 and ID4, start exactly one AR child, set aggregate busy. |
| AR acceptance | Pulse request-done exactly once, retain request ownership, and issue exactly one registered R arm. |
| R waiting | Keep aggregate busy; R child owns eager RREADY and safe already-high/delayed RVALID behavior. |
| R acceptance | Capture raw RID4/RDATA32/RRESP2/RLAST1 exactly once and compare RID to retained ARID plus RLAST to the fixed one-beat expectation. |
| Transaction retirement | Pulse transaction-done exactly once after R-child retirement, clear busy, and hold raw result/match status. |
| ID/last/status error | Preserve raw result; mismatch/missing-last is assertion/status-visible and terminal; non-OKAY RRESP is raw and terminal without an implicit success claim. |
| Busy command | Ignore rather than queue or overwrite the active transaction. |
| Reset | Cancel request/receive ownership and pending pulses without fabricating completion. |

The readiness audit must choose the exact public result/status fields and
assertion policy, but it must preserve these semantic distinctions. In
particular, it must not redefine the standalone child's `ar_done` or
`r_beat_done`, and it must not make terminal protocol-error observation depend
on a second R beat that the fixed request cannot legally produce.

## Expected reuse and new ownership

### Reused unchanged

- `AxiArDriver`, including its six-state exactly-once launch/accept schedule;
- `AxiRBeatAcceptor`, including its six-state explicit-arm/accept schedule;
- shared clock and asynchronous active-low reset;
- mandatory IAL2 -> generated IAL1 -> generated IAL0 -> HDL lowering;
- C4 structural composition and sized constant wiring; and
- the full-write proof pattern for flat endpoint/coordinator children,
  separate completion pulses, ID matching, raw response retention, reset, and
  terminal mismatch.

### New in the later implementation only

- one read-transaction coordinator actor;
- one flat three-child structural top;
- retained command/request state and AR-to-R causal handoff;
- fixed AR metadata connections and alignment admission guard;
- read request-done, transaction-done, aggregate busy, raw result, ID-match,
  and last-match report/status semantics; and
- an additive public `.ppif` object, report schema, support identity, focused
  test, and mdBook section selected only after `.32` readiness and a following
  contract-selection leaf.

Nested structural composition is unnecessary: unlike the write path, the AR
request has only one physical request channel. The expected top is directly
AR driver + R acceptor + coordinator.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Fixed-single-beat AR+R full-read composition | Both physical children now ship. Fixed metadata makes one R beat an honest transaction boundary; a three-child flat top closes the narrowest missing vertical path. | **Selected; `.32` readiness audit.** |
| Standalone AR legality/fixed-metadata feature | Can reject or constrain commands but does not coordinate or complete a read. The required fixed policy is smaller and clearer inside the selected composition. | Absorbed into composition, not selected separately. |
| Repeated/multi-beat R receiver tied to ARLEN/RLAST | Requires a counter or streaming rearm policy, multiple capture/storage policy, last/length checks, status aggregation, and reset/error handling across beats. | Deferred until the fixed one-beat vertical path is coherent. |
| AR/R-to-capacity/status adapter | The capacity family already owns abstract submit/completion, RID demux, ARLEN capture, beat validation, RDATA banks, and RRESP aggregation, but integration must choose event ownership, outstanding policy, ID routing, and a target variant. | Deferred as a larger cross-generator adapter. |
| Multiple outstanding/back-to-back reads | Requires queues, ID allocation/reuse/order, RID demux, possible interleaving, and beat ownership. | Deferred. |
| Broader burst/address generation | Requires dynamic ARLEN, beat progression/storage, RLAST validation, and narrow/unaligned policy. | Deferred. |
| `.axi` alias surfacing | Adds spelling rather than a missing transaction behavior and must remain semantic parity with `.ppif`. | Deferred. |
| Protocol-neutral transaction interface | Decision 0020 North Star; explicitly not PNT-eligible without director activation. | Preserved, not activated. |

## Existing capacity/status seam

`AxiManagerCapacityStatus` is not being bypassed or replaced. Its shipped
families provide deep abstract behavior: read submit/completion capacity,
transaction envelopes, concrete/dynamic IDs, same-ID policies and queues, RID
response demux, single/last/multi-beat data capture, raw ARLEN, runtime
beat-count/RLAST assertions, and scalar RRESP aggregation.

Those families consume authored abstract events and bus payload inputs; they
do not define the small physical AR/R ownership adapter now selected. Binding
the new physical full-read transactor to one capacity/status variant will be a
separate later choice because it must decide:

- whether command admission or AR acceptance is the abstract read-submit
  event;
- whether physical R acceptance, validated RLAST, or coordinator retirement is
  the abstract read-complete event;
- how ARID/RID ownership maps to concrete, dynamic, or queued transactions;
- whether raw result storage stays in the physical composition, the capacity
  core, or an adapter; and
- which outstanding/backpressure contract applies.

The fixed one-active composition provides a deterministic physical endpoint
for that future adapter without prematurely selecting a capacity variant.

## Exact `.32` readiness owner

`.32` must audit, without changing behavior:

- the exact fixed-single-beat command, AR channel, R channel, captured result,
  status, clock/reset, role, and source-anchor boundary;
- four-byte alignment and exact fixed `ARLEN=0`, `ARSIZE=2`, `ARBURST=INCR`
  legality, including whether a misaligned command is assertion-only or
  launch-gated plus asserted as in the write composition;
- unchanged AR/R child contracts with collision-free private bindings;
- the read coordinator's exact state/rules/priorities, AR-start/R-arm pulse
  timing, retained address/ID, busy lifetime, separate request and transaction
  done events, busy-command policy, reset, and stable result status;
- a flat three-child C4 topology, explicit constant wiring, public fanout of
  captured outputs, coordinator observation of RID/RLAST, strict compilation,
  artifact cardinality, and selected top;
- already-high/delayed/held RVALID after AR acceptance, continuous/stalled/
  pulsed ARREADY, no R arm before request acceptance, simultaneous causal
  boundaries, and exactly-once behavior;
- retained ARID/RID comparison, fixed-one-beat RLAST expectation, raw RRESP and
  RDATA exposure, generated assertions/status, and terminal handling for
  mismatched RID, missing RLAST, and non-OKAY RRESP;
- report completion vocabulary that distinguishes request accepted, beat
  accepted, bounded transaction retired, and protocol success;
- source/report/artifact/static/residue/diagnostic/CLI/outdir/semantic/
  Verilator/Yosys/generated-HDL proof owners and expected accounting changes;
- a following exact public-contract-selection leaf, atomic implementation
  owner, validation matrix, and rollback; and
- explicit preservation of dynamic/multi-beat requests, response aggregation,
  capacity integration, outstanding/queues/demux/interleaving, back-to-back
  admission, extended attributes, aliases, decision 0020, verification output,
  direct/backend/VHDL, AHB, and APB deferrals.

The readiness audit may revise topology or terminal-status details only with
concrete source/compiler proof. It may not implement behavior or broaden the
selected fixed-one-beat scope.

## Architectural boundaries

- Decision 0014 still requires generated `.isf` before generated `.fsm`; the
  structural top does not permit direct IAL2-to-IAL0 lowering.
- Decision 0015 permits future `.axi` vocabulary aliases but gives this
  composition no alias privilege.
- Decision 0018 keeps the public syntax, report, diagnostics, and mdBook
  backend-language-neutral; current Perl module names are reference
  implementation owners, not the portable semantic definition.
- Decision 0020 remains the director-gated protocol-neutral transaction-layer
  North Star. This bounded full-read composition is a bus-side building block
  beneath it and does not activate that interface.

## Preserved boundaries

This selector changes no shipped behavior. It adds no parser clause,
generator, public source, support accounting, manifest capability, test,
artifact, HDL, alias, or capacity/status wiring. The standalone AR and R actors
retain their existing dynamic-request and beat-only contracts unchanged.

The selected implementation remains bounded to one active, aligned, full-width
32-bit, fixed-single-beat INCR read with four-bit ID and raw two-bit RRESP. It
does not claim queues, multiple outstanding reads, dynamic AR metadata,
multi-beat acceptance, interleaving, response aggregation, narrow/unaligned
transfers, extended AXI attributes, or protocol-neutral transaction interfaces.

## Validation and rollback

This documentation-only slice is validated with Knowledge Map generation and
checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the full
doctrine gate. The shipped AR/R/full-write tests are evidence read; no behavior
changed that requires rerunning them.

Rollback removes this selector and its fact card, restores `.31` to active,
removes `.32`, and restores task-index/book/Memory pointers. No parser,
generator, source, support, manifest, test, artifact, runtime, or HDL rollback
is required.
