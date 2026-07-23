# IAL2 AXI manager initiator — post-AR next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.27` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded, explicitly armed **one-transfer AXI4 manager R read-data
channel acceptor** as the next increment after the AR driver ships.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.28`, a behavior-neutral readiness audit.
It must fix exact arming, RREADY, payload capture, beat-only completion,
schedule, artifact/report, diagnostics, proof, and implementation-owner
boundaries before public contract selection.

One accepted arm owns one physical `RVALID && RREADY` transfer. The primitive
captures raw RID, RDATA, RRESP, and RLAST, clears READY/active ownership on that
acceptance edge, and emits one later beat-accepted done pulse. It does **not**
claim that RLAST was high, that all beats described by ARLEN arrived, that RID
matches an issued ARID, that RRESP is successful, or that the read transaction
completed.

## Live evidence and repository boundary

The newly shipped AR primitive supplies the transmitter-owned half of the
read path:

```text
one admitted command
  -> stable ARVALID + address/ID/length/size/burst
  -> exactly one accepted AR request
  -> ar_done = request accepted only
```

Its report deliberately says `includes_read_response = false`. A complete
manager must accept every R beat implied by that request; the repository still
has no bus-side `AxiR*` generator and no generated manager-owned RREADY actor.

The tracked AXI evidence fixes the dependency boundary. RVALID can appear only
after an accepted read request, but the subordinate must not wait for RREADY
before asserting it. The manager may assert RREADY before RVALID or wait until
later. Once RVALID is asserted, the subordinate holds the response/data until
the handshake. Therefore an explicitly armed eager-READY receiver is legal,
deadlock-safe, and structurally analogous to the shipped B acceptor.

`AxiBResponseAcceptor` provides a proven receiver architecture: one idle arm,
READY asserted independently of VALID, acceptance-over-arm priority, captured
payload, six states, exact one-transfer cardinality, and stable capture. The R
payload and completion model differ: B has one response per write transaction,
whereas R can contain multiple beats and RLAST marks the final one. The R
primitive can reuse the schedule shape but must use **beat** vocabulary and
must not inherit B's response-complete implication.

`AxiManagerCapacityStatus` already contains extensive abstract read lifecycle,
RID demux, RLAST, raw ARLEN, runtime beat-count validation, scalar/multi-beat
RDATA capture, and RRESP aggregation. It does not supply this missing physical
channel actor: its generated families consume authored abstract request/
completion events and read-data inputs, and do not establish a small reusable
explicit-arm RREADY boundary. Integration requires an adapter/composition and
an outstanding/ID policy, so it is larger than the missing primitive.

Decision `0020` remains a director-gated North Star. The R acceptor is another
bus-side role block that a later protocol-neutral read transactor can compose;
this selector does not activate that interface.

## Why one R beat is the smallest honest unit

### It adds the next missing physical capability

AR now issues requests. A one-transfer R acceptor adds manager-owned RREADY and
physical response/data capture without inventing cross-channel transaction
state. It is smaller than a full read composition and independently reusable
for a later fixed-single-beat or repeated multi-beat coordinator.

### Explicit arming preserves ownership

An always-ready receiver could consume an R beat with no locally owned request
or storage handoff. An arm token maps one caller-owned receive operation to one
handshake and one stable captured result. A later coordinator decides when to
arm, whether to rearm for another beat, and when the transaction is complete.

### Beat completion avoids a false RLAST claim

A first-slice acceptor cannot infer completion merely from accepting one beat.
It therefore captures RLAST raw and reports **beat accepted**. Later
composition can constrain ARLEN to zero and require RLAST, or can compare
ARLEN+1 with repeated accepted beats and RLAST. The primitive supports both
directions without prematurely choosing one.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Explicitly armed one-transfer R beat acceptor | Reuses proven B receiver ownership/schedule while adding the missing manager RREADY and raw RID/RDATA/RRESP/RLAST capture. Honest beat-only done semantics avoid false full-read claims. | **Selected; `.28` readiness audit.** |
| Immediate AR+R fixed-single-beat full-read composition | Requires the new R actor, AR/R coordination, fixed ARLEN/SIZE/BURST coupling, retained ARID/RID match, RLAST policy, data/status result, structural top, and full completion in one slice. | Deferred until the R primitive ships. |
| AR-to-capacity/status adapter | Must map physical request/beat events and IDs into the abstract 9,773-line family and select an outstanding policy; does not itself add RREADY. | Deferred. |
| AR request-legality/fixed-single-beat refinement | Useful inside a coherent composition, but adds validation/fixed metadata without closing the missing physical response channel. | Deferred to full-read readiness. |
| Multi-beat R receiver tied to ARLEN | Requires counters, repeated rearming or streaming ownership, RLAST validation, RRESP aggregation, storage/output policy, and timeout/error semantics. | Deferred; build from the beat primitive. |
| Multiple outstanding/back-to-back reads | Requires request/response queues, ID allocation/order/demux, and beat interleaving policy. | Deferred. |
| AR `.axi` alias | Adds spelling rather than read-response behavior; the alias remains intentionally narrow. | Deferred. |
| Protocol-neutral read interface | Decision `0020`; not PNT-eligible until director activation. | Preserved, not activated. |

## Exact `.28` readiness owner

`.28` must audit, without changing behavior:

- tracked R-channel directions, valid/ready and read-dependency anchors, RLAST,
  RRESP, and Issue-L signal/width evidence;
- exact first-slice scope: one armed R transfer versus a fixed-single-beat
  transaction, with beat-only completion fixed unless source evidence and
  schedule proof justify a narrower alternative;
- likely inputs arm/RVALID/RID4/RDATA32/RRESP2/RLAST and outputs
  RREADY/captured-RID4/captured-RDATA32/captured-RRESP2/captured-RLAST/busy/
  beat-done, subject to exact audit spelling;
- `subordinate-to-manager` role, explicit reset, idle-only arm admission,
  eager post-arm RREADY, unarmed behavior, already-high/delayed/held-high
  RVALID, stable capture, command-while-busy, reset, and exactly-once behavior;
- whether the B acceptor's corrected six-state acceptance-over-arm schedule
  reuses exactly after expanding the payload, including assignment/priorities;
- raw RLAST and RRESP exposure, no implicit success, no implicit transaction
  completion, and no RID/ARID comparison inside the primitive;
- generated IAL1/IAL0 artifacts, report schema/static/beat scope/residue,
  semantic root, CLI/outdir/verify-HDL, fail-closed diagnostics, executable
  proof, every implementation owner, support/manifest counts, validation, and
  rollback; and
- explicit deferral of AR/R composition, fixed request coupling, repeated or
  multi-beat reception, ARLEN/RLAST validation, RRESP aggregation, ID match,
  capacity integration, outstanding/queues/demux, aliases, decision `0020`,
  verification output, direct/backend/VHDL, AHB, and APB behavior.

## Preserved boundaries

This selector changes no behavior. It does not alter the shipped AR/AW/W/B
actors, write compositions, or capacity/status families. It adds no R parser,
generator, source, support identity, manifest claim, test, alias, artifact, or
HDL. The mandatory path remains:

```text
IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL
```

## Validation and rollback

This documentation-only slice is validated with Knowledge Map generation and
checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the
full doctrine gate.

Rollback removes this selector/fact, restores `.27` to active, removes `.28`,
and restores task-index/book/Memory pointers. No behavior rollback is needed.
