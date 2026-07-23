# IAL2 AXI manager initiator — post-full-write next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.23` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **AXI4 manager read-address (AR) channel driver** as the next
increment after the single-beat full-write composition ships.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.24`, a behavior-neutral readiness audit.
It must derive the exact AR command/channel boundary, source anchors, schedule,
report, diagnostics, proof matrix, and implementation-owner map before public
contract selection.

The selected primitive mirrors the proven AW driver shape: accept one local
read-address command while idle, atomically capture its payload, assert ARVALID
independently of ARREADY, hold ARVALID and all AR payload fields stable until
one handshake, then emit one request-issued completion pulse. It does not
accept or capture R data and does not claim read-transaction completion.

## Evidence and live boundary

The shipped write-side path is now vertically coherent:

```text
aligned command
  -> AW + W request handshakes
  -> request-done / post-request B arm
  -> one captured B response
  -> retained AWID/BID match + raw BRESP + transaction-done
```

`ppif/axi_write_transaction_composition.ppif` and guarded four-subtest `t/1503`
prove that five-child path through generated IAL1, generated IAL0, C4, and HDL.
There is no longer a smaller unfinished single-beat write edge to close.

The existing `AxiManagerCapacityStatus.pm` remains a 9,773-line abstract
capacity/status, ID, lifecycle, ordering, queue-head, response-demux, and
read-data-capture family. It does not drive AXI bus channels. Its base inputs
are abstract `write-submit`/`write-complete` and `read-submit`/`read-complete`
events; optional families add request/response ID and demux policies. Binding
the one-outstanding physical full-write transactor to this family would require
an adapter contract and would add no useful physical concurrency until the
transactor itself gains queueing or replication.

No AR driver, R acceptor, or read-transaction composition module exists under
`perl/FSM/IAL2/ProtocolIntent`. The tracked AXI Valid-Ready evidence records the
read dependency boundary: ARVALID is independent of ARREADY; a subordinate may
wait before ARREADY; RVALID depends on an accepted read address and remains
independent of manager-owned RREADY. That makes AR request issue a clean first
read-side primitive and keeps R acceptance a separate following contract.

The generic `.axi` profile alias currently accepts only the first AXI AW
Valid-Ready monitor. PPIF explicitly rejects W driver, B acceptor, AW/W request
composition, and full-write composition objects for `.axi`. Surfacing the
full-write object through that alias would improve spelling coverage but add
no initiator behavior and would skip the still-missing read-side primitives.

Decision `0020` remains accepted as a director-gated future North Star. The AR
driver is another bus-side primitive that can later sit below a shared
protocol-neutral transaction interface; this selector does not activate that
interface.

## Why AR drive is the smallest coherent increment

### It is the next missing bus-side primitive

AW drive established the exact single-address-channel pattern, and its
corrected generated schedule already proves VALID hold, payload stability,
exactly one handshake under continuously asserted READY, and one completion
pulse. AR has the same transmitter-owned address-channel transport shape. The
readiness audit can therefore reuse proven architecture without changing the
shipped AW implementation or inventing response behavior.

### Its completion meaning is narrow and honest

An AR driver's done pulse means one read-address request was accepted. It does
not mean any R beat arrived. That is the read-side analogue of the earlier
request-only write boundary, and it leaves RID/RDATA/RRESP/RLAST, single- versus
multi-beat capture, RREADY arming, and full read completion to separately
audited increments.

### The alternatives cross larger boundaries

Capacity integration needs a physical-to-abstract event/ID adapter and an
outstanding policy. R acceptance introduces four response/data fields plus
RLAST and beat ownership before any physical AR source exists. A complete read
composition requires both new primitives plus coordination. Multi-beat write
support changes AW metadata and W sequencing together. Outstanding/back-to-
back writes require queueing, ID allocation/ordering, and response correlation
beyond the current zero-depth transactor. `.axi` aliasing is additive syntax,
not the next behavioral capability. Decision `0020` cannot be activated by
PNT.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Standalone bounded AR driver | Reuses the proven corrected AW-driver architecture for the next missing transmitter-owned AXI channel. Adds one honest request-issued event without claiming R completion. | **Selected; `.24` readiness audit.** |
| Standalone R acceptor | Must choose explicit arm timing, RREADY policy, RID/RDATA/RRESP/RLAST capture, and single-/multi-beat scope before any AR source exists. | Deferred until AR drive ships. |
| Bounded single-beat read composition | Requires both AR and R primitives plus retained ARID/RID matching, data/status capture, and full completion in one step. | Deferred; decompose through AR then R. |
| Full-write to capacity/status adapter | Requires physical-to-abstract submit/completion/ID ownership and is redundant at current one-outstanding depth. | Deferred until an explicit adapter/outstanding direction is selected. |
| Multi-beat W plus AW coupling | Requires dynamic AWLEN, beat source/storage, WLAST sequencing, strobe/lane policy, and address progression. | Deferred. |
| Multiple outstanding/back-to-back writes | Requires command/response queues, ID allocation, same-/different-ID ordering, and response demux around a zero-depth transactor. | Deferred. |
| Full-write `.axi` alias | Small syntax addition but no new initiator behavior; the alias remains deliberately narrow. | Deferred behind behavioral completeness. |
| Protocol-neutral transaction interface | Decision `0020` North Star; explicitly not PNT-eligible until director activation. | Preserved, not activated. |

## Exact `.24` readiness owner

`.24` must audit, without changing behavior:

- the relevant tracked AXI read-address and read-dependency source anchors;
- the exact first-slice AR payload, including whether it mirrors AW's
  address32/ID4/LEN8/SIZE3/BURST2 set and which extended AR attributes remain
  residue;
- local command start/ready inputs, ARVALID/ARREADY direction, busy/done status,
  shared clock/reset, role spelling, and public signal names;
- idle-only admission, atomic payload capture, ARVALID independence from
  ARREADY, hold/stability, continuously-ready exactly-once cardinality, delayed
  ARREADY, reset in each phase, command-while-busy, and final idle;
- whether the corrected six-state AW schedule can be reused exactly or needs an
  AR-specific generated-ISF variation, with schedule/priority proof before
  contract spelling;
- generated IAL1/IAL0 artifact identity, report schema/sections/static rules/
  residue, semantic root, selected HDL entry, and no direct lowering;
- fail-closed profile/role/reset/width/cardinality/mixing/duplicate-name and
  `.axi` boundaries;
- parser, generator, public source, support/manifest/test, mdBook, fact,
  validation, rollback, and exact following contract-selection owners; and
- explicit deferral of R acceptance, read completion, ARID/RID correlation,
  read-data/status capture, multi-beat R, capacity integration, queues,
  extended attributes, aliases, decision `0020`, verification output, direct
  backend, backend variants/VHDL, AHB, and APB.

The audit must name the following exact public-contract-selection leaf. It may
not implement before signal vocabulary, schedule reuse, and request-only
completion ownership are fixed.

## Preserved boundaries

This selector changes no behavior and does not activate:

- any AR parser/generator/source/support/test contract;
- RREADY/R capture or read-transaction completion;
- modifications to shipped AW/W/B/request/full-write behavior;
- capacity/status integration, multiple outstanding transactions, ID
  allocation/ordering, or response demux;
- multi-beat W/R, dynamic burst metadata, narrow/unaligned lane placement, or
  extended AXI attributes;
- `.axi` alias expansion or decision `0020`'s transaction interface;
- verification-output generation, direct backend lowering, backend-language
  variants, VHDL, AHB, or APB behavior.

The mandatory chain remains:

```text
IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL
```

## Validation and rollback

This documentation-only slice is validated with Knowledge Map generation and
checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the
full doctrine gate. The shipped full-write regression is evidence read; no
behavior changed that requires rerunning it.

Rollback removes this selection note and fact card, restores `.23` to active,
removes `.24`, and restores the prior task-index/book/Memory pointers. No
parser, generator, source, test, generated artifact, runtime, or HDL rollback
is required.
