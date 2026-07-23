# IAL2 AXI manager initiator — post-AW+W-composition next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.19` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **single-beat AXI manager full-write transactor composition**
as the next increment after the shipped AW+W write-request composition.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.20`, a behavior-neutral readiness audit.
It must derive the exact request/response ownership, coordinator schedule,
child topology, structural artifact contract, generated-HDL proof, and owner
map before public-contract selection.

The selected direction reuses the shipped AW driver, W driver, and B response
acceptor without changing or duplicating their channel state machines. A new
response-aware coordinator and a new structural full-write top are required.
The audit must choose whether that top nests the shipped AW+W structural
composition or directly instantiates its unchanged AW, W, and request-
coordinator children beside B and a transaction coordinator. That topology
choice must be proved against the real C4 compiler before contract spelling.

This direction adds one missing semantic edge: an admitted aligned single-beat
write request is not transaction-complete until its one B response is accepted.
The shipped AW+W `write_done` remains request-channel issue completion; it must
not be silently redefined.

## Evidence and current boundary

The shipped write-side pieces now provide:

```text
one aligned command
  -> unchanged AW child -> exactly one AW handshake --+
  -> unchanged W child  -> exactly one W handshake  --+-> write_done

one explicit arm
  -> unchanged B child -> exactly one B handshake -> captured BID/BRESP -> b_done
```

The request composition already owns atomic AWADDR/AWID/WDATA/WSTRB capture,
fixed `AWLEN=0`, `AWSIZE=2`, `AWBURST=INCR`, arbitrary WSTRB including zero,
independent AW/W stalls, completion-history storage, and a selected three-child
C4 top. Its `write_done` means both request channels transferred.

The B acceptor already owns eager post-arm BREADY, exactly one B handshake,
four-bit BID capture, two-bit BRESP capture, stable captured outputs, and one
later `b_done` pulse. It deliberately does not decide when a write transaction
may arm it, whether captured BID matches the request AWID, or what public event
means the whole transaction completed.

The capacity/status generator is not a smaller continuation. It consumes
abstract `write-submit` and `write-complete` events and contains a large family
of optional transaction-ID, lifecycle, ordering, queue-head, and response-demux
contracts. In response-demux variants, top-level `write-complete` is explicitly
the raw accepted B-response event while per-transaction completion may be a
separate generated demux pulse. Automatically binding the new physical actors
to one capacity variant would therefore require a separate adapter contract,
outstanding policy, and exact event ownership; it must not be inferred here.

Decision `0020` remains a director-gated future North Star. The selected
bus-side transactor is a valid future building block beneath that interface,
but this PNT leaf cannot activate the protocol-neutral transaction layer.

## Why this is the smallest coherent next increment

All physical single-beat write-channel primitives and the coherent AW+W request
unit now exist. Completing that same write vertically requires no new AXI
channel behavior: only response arming, request/response causality, ID
correlation, and full-transaction completion around the shipped actors.

A standalone AR driver is primitive-sized, but it opens a second transaction
direction before the first direction can retire a response. An R acceptor is
larger because it must pair with AR and choose RDATA/RRESP/RID/RLAST and beat
scope. Multi-beat write behavior changes both AW metadata and W sequencing and
adds address/lane coupling. Capacity integration crosses into a broad existing
bookkeeping family. The full single-beat write composition therefore closes
the narrowest unfinished path with already-proven channel actors.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| AW+W+B single-beat full-write transactor | Reuses every shipped physical write-side actor. Adds bounded B arming, request/response causality, BID matching, response reporting, and one full-completion event. | **Selected; `.20` readiness audit.** |
| Request/response completion into capacity/status | Must choose an outstanding/ID/demux variant and define physical-to-abstract submit/completion bindings. Larger cross-generator adapter boundary. | Deferred until the bounded physical write transactor is coherent. |
| Standalone AR driver | Small primitive, but opens the read path before closing the write response path. | Deferred after the selected write closure. |
| Standalone R acceptor | Requires AR pairing plus RID/RDATA/RRESP/RLAST and single-/multi-beat ownership. | Deferred. |
| Multi-beat W plus AW/address coupling | Requires dynamic AWLEN, a beat source/counter, WLAST sequencing, strobe/lane policy, and address progression. | Deferred. |
| Protocol-neutral transaction interface | Architectural North Star from decision `0020`; explicitly not PNT-eligible until director activation. | Preserved, not activated. |

## Exact `.20` readiness owner

`.20` must audit, without changing behavior:

- the additive full-write command/status/response boundary while preserving the
  shipped request composition and B acceptor public contracts unchanged;
- whether the new top nests `axi_write_request_composition` or directly reuses
  its AW/W/request-coordinator children, including C4 child-port realization,
  clocks/resets, artifact cardinality, and selected HDL entry;
- the new response-aware coordinator's exact inputs, outputs, state, rule
  schedule, priorities, and ownership relative to the existing request
  coordinator;
- B-arm timing: at accepted aggregate command or only after both AW and W
  handshakes, including already-high BVALID, independent AW/W stalls, and AXI's
  requirement that B follows acceptance of AW and the final W beat;
- atomic preservation of the admitted four-bit AWID until response retirement
  and exact captured-BID match/error/assertion policy;
- two-bit BRESP exposure, whether protocol error becomes a separate status,
  and stable response outputs after completion;
- distinct request-issued and transaction-complete pulses, aggregate busy
  lifetime, command-while-busy handling, and no accidental queue/back-to-back
  claim;
- safe behavior for a non-conforming subordinate, reset during every phase,
  simultaneous request completion/BVALID boundaries, and exactly-once B
  acceptance/full completion;
- exact public object vocabulary, parser/generator/result/report identities,
  source anchors, diagnostics, support/manifest/test owners, only as questions
  handed to the following contract-selection leaf rather than frozen here;
- report/static/residue, IAL1/IAL0/structural artifact lists, CLI/outdir/
  semantic behavior, and mandatory no-direct-lowering chain; and
- an executable generated-HDL matrix proving aligned admission, atomic
  payload/ID retention, simultaneous/AW-first/W-first request issue, delayed
  and already-high BVALID, BID match/mismatch policy, BRESP capture, one B
  handshake and one full-completion pulse per admitted command, ignored busy
  command, and final idle.

The audit must name the following exact public-contract-selection leaf. It may
not implement while topology, arming, ID, response, or completion ownership is
still open.

## Preserved boundaries

This selector changes no behavior and does not activate:

- any parser/generator/source/support/test contract for the full-write
  composition;
- modifications to the standalone AW driver, W driver, B acceptor, or shipped
  AW+W request composition;
- capacity/status submission/completion wiring, multiple outstanding writes,
  ID allocation, response demux, or ordering queues;
- multi-beat W, dynamic AW metadata/WLAST, general burst/address generation,
  narrow/unaligned lane placement, or extended AXI attributes;
- AR/R behavior or decision `0020`'s transaction interface;
- `.axi` aliases, verification-output generation, direct backend lowering,
  backend-language variants, or VHDL behavior; or
- AHB/APB behavior.

The mandatory chain remains:

```text
IAL2 -> generated IAL1/.isf children -> generated IAL0/.fsm children
     -> generated structural .fsm top -> HDL
```

## Validation and rollback

This documentation-only slice is validated with the Knowledge Map generator
and checker, mdBook build, bounded Memory/docs-path/whitespace checks, and the
full doctrine gate. The focused AW/W/B/composition tests are evidence read; no
behavior changed that requires rerunning them.

Rollback removes this selection note and its fact card, restores `.19` to
active, removes `.20`, and restores the prior task-index/book/Memory pointers.
No parser, generator, source, test, generated artifact, or HDL rollback is
required.
