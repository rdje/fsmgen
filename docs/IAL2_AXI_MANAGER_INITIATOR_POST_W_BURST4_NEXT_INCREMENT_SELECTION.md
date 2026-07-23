# IAL2 AXI manager initiator: next increment after the fixed-four W burst driver

Date: 2026-07-23

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.43`

Outcome: select a bounded fixed-four AW+W write-request composition; assign
the exact behavior-neutral readiness audit to `.44`.

## Scope and outcome

FSMGen now ships balanced fixed-four physical primitives on both directions:
the read composition issues one fixed LEN3/SIZE2/INCR AR request and drains
four R beats, while the additive W burst driver presents four explicit
data32/strobe4 tuples with WLAST `0/0/0/1`. The missing smallest write-side
step is no longer W progression. It is the request-level composition that
couples one address request to that four-beat payload and joins the independent
AW and W channel completions.

The selected next increment is therefore an additive fixed-four full-width
AXI4 manager AW+W write-request composition. Its leading shape reuses the
unchanged `AxiAwDriver` and unchanged `AxiWBurst4Driver`, adds one generated
request coordinator, and selects one flat generated structural top. It fixes
AWLEN to 3, AWSIZE to 2, and AWBURST to INCR. Admission must require a
four-byte-aligned address whose complete 16-byte span remains within one
4-KiB region, using the already-proven fixed-four read legality boundary.

This is request completion only. Aggregate done means both the single AW
transfer and the fourth/final W transfer have completed, in either order. It
does not mean a B response was accepted and does not claim that the write
transaction succeeded.

## Durable evidence consulted

### Shipped physical primitives

`ppif/axi_aw_driver.ppif` and `AxiAwDriver` already own one independently
backpressured AW transfer with command-side address32/ID4/LEN8/SIZE3/BURST2
metadata. The primitive can carry LEN3/SIZE2/INCR without modification; the
single-beat restriction lives in the existing composition, not in the AW
channel driver.

`ppif/axi_w_burst4_driver.ppif` and `AxiWBurst4Driver` now own the previously
missing outbound progression invariant. One idle command captures four
explicit data32/strobe4 tuples atomically, keeps WVALID asserted through four
accepted transfers, holds the current tuple under backpressure, emits WLAST
`0/0/0/1`, reports each accepted beat/index, and completes only with index 3.
Its exact generated-HDL proof is 14 handshakes, 14 beat events, and three
completed bursts across continuous READY, stalls, busy-command rejection,
reset abort, and recovery.

Neither primitive owns cross-channel launch, address-to-payload coherence, a
4-KiB guard, or aggregate request completion. Those are composition concerns.

### Shipped single-beat composition pattern

`AxiWriteRequestComposition` proves the correct architectural pattern: reuse
unchanged AW/W child generators, generate a distinct coordinator that captures
one aggregate command and remembers independent child completions, and select
a flat three-child C4 top. Its `write_done` is explicitly request completion,
not B completion. It also proves simultaneous, AW-first, and W-first joins.

That generator cannot simply be reused as the fixed-four behavior. It fixes
AWLEN to zero, instantiates `AxiWDriver`, accepts one data/strobe tuple, and
reports a single-beat policy. Generalizing it in place would risk the shipped
source and report contract. The new composition should be additive while
reusing its topology and join pattern.

`AxiWriteTransactionComposition` proves the next layering step: request
completion arms an unchanged B acceptor, then a separate coordinator publishes
transaction completion after response retirement. Folding that B layer into
the first fixed-four request slice would add response timing, BID correlation,
BRESP capture, and a second completion meaning before the new request boundary
is independently proven.

### Legality and fixed-four symmetry

`AxiReadBurst4TransactionComposition` already fixes the safe full-width
four-beat INCR legality boundary:

```text
address[1:0] == 2'b00
and aligned low12 <= 12'hff0
```

Equivalently, the complete 16-byte span must remain within one 4-KiB region.
The write request should reuse this semantic boundary and its explicit
bit-predicate strategy rather than invent a different fixed-four legality
rule. The readiness audit must decide the exact authored signal names and
literal generated assertion while preserving the same accepted/rejected
addresses, including accepting `...ff0` and rejecting aligned `...ff4`,
`...ff8`, and `...ffc`.

### Capacity/status and architecture boundaries

`AxiManagerCapacityStatus` already owns abstract capacity, ID lifecycle,
response demux, ordering queues, burst validation, and read-data storage. It
still does not drive AW/W/AR. Connecting physical request completion to that
family requires a separate adapter contract that selects one capacity variant
and resolves submit/completion timing, ID authority, payload ownership, and
backpressure. Copying those responsibilities into this physical request
composition would create competing authorities.

Decision 0020's protocol-neutral transaction interface remains the accepted
future North Star and is explicitly director-gated. The selected fixed-four
composition is a bus-side building block beneath that future interface, not an
implicit activation of it.

Decisions 0014, 0017, and 0018 continue to require reviewable generated IAL1,
aggregate generated artifacts with an explicit structural HDL entry, and a
backend-language-neutral public contract.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Fixed-four AW+W write-request composition | The two channel primitives now exist. Reusing unchanged AW and W-burst4 children plus one join coordinator isolates address/payload coherence, 4-KiB legality, independent channel timing, and request completion. | **Selected; `.44` readiness audit.** |
| Immediate fixed-four AW+W+B full-write composition | Adds B arming, BID comparison, BRESP capture, aggregate busy through response retirement, and request-versus-transaction completion. The existing single-beat layering shows this belongs after the request composition. | Deferred behind the selected request slice. |
| Authored or bounded-dynamic burst length | Requires dynamic AWLEN/count consistency, variable payload ownership, dynamic WLAST, wider counters, dynamic 4-KiB legality, and a larger proof matrix. | Deferred until the fixed-four request/full-write path is coherent. |
| Packed data/strobe banks or a streaming producer | Would replace or wrap the just-selected explicit four-tuple contract and, for streaming, add another handshake/backpressure boundary. | Deferred; the first composition reuses the shipped explicit-field child unchanged. |
| Physical-to-capacity/status adapter | Must choose submit/completion events, ID authority, storage ownership, target capacity variant, and backpressure. It is larger than composing the ready physical children. | Deferred. |
| Response aggregation or output banks | Mature abstract owners already exist in the capacity/status family; the physical request layer has no response payload to aggregate. | Rejected as a request-composition responsibility. |
| Multiple outstanding, back-to-back, queues, demux, or interleaving | Requires buffering, allocation/reuse, ordering, response correlation, and likely a capacity adapter. | Deferred. |
| Malformed-subordinate timeout/recovery | Adds time policy, abort/resynchronization, and externally visible failure semantics beyond normal request issue. | Deferred. |
| `.axi` profile-alias surfacing | Changes authoring reach but does not close the physical write-request gap; the generic `.ppif` source remains canonical. | Deferred. |
| Protocol-neutral transaction interface | Decision 0020 North Star, explicitly not PNT-eligible until director activation. | Preserved, not activated. |

## Selected leading boundary

The readiness audit starts from this behavior, without freezing syntax yet:

```text
one legal idle command carrying address32, ID4,
four explicit (WDATA32, WSTRB4) tuples
  -> capture the complete command atomically
  -> launch unchanged AW exactly once with LEN3/SIZE2/INCR
  -> launch unchanged W-burst4 exactly once
  -> allow AW and the four W transfers to progress independently
  -> remember whichever child completes first
  -> publish one request-done event only when both are complete
```

The aggregate busy interval begins at legal admission and ends with joined
request completion. A command while busy is ignored rather than queued.
Asynchronous reset aborts both paths and the coordinator without fabricating
request completion. All strobe patterns, including zero, remain legal because
the physical W child already owns raw WSTRB behavior.

The leading public status should retain visibility of the W child's accepted
beat event and two-bit index as well as aggregate request completion, but `.44`
must decide the exact exposure and signal names after auditing C4 wiring and
the existing composition conventions.

## Reuse and artifact direction

The selected implementation must not duplicate or rewrite channel behavior:

1. invoke unchanged `AxiAwDriver` with private command/status bindings;
2. invoke unchanged `AxiWBurst4Driver` with private command/status bindings;
3. generate one new fixed-four request coordinator in IAL1;
4. lower all three generated IAL1 actors to their generated IAL0 FSMs; and
5. generate one explicit flat C4 structural top as the selected semantic/HDL
   entry.

The coordinator owns legal aggregate admission, atomic payload retention,
one-shot child launch, completion history, busy/request-done/reset semantics,
and any public forwarding of beat event/index. The AW child owns AW
valid/payload stability and exactly-one handshake. The W child owns tuple
selection, WVALID stability, WLAST, four handshakes, and beat/final events.

## Exact `.44` readiness owner

Without changing behavior, `.44` must audit and fix:

- the additive public object/source, parser/result/mode/generator/schema/top/
  coordinator/support/test identities and following contract/implementation
  leaves;
- exact source anchors inherited from AW, W, burst metadata/dependency,
  WLAST, direction, and 4-KiB rules;
- manager role, shared clock/asynchronous-active-low reset, address32/ID4,
  four explicit data32/strobe4 tuples, AWREADY/WREADY, AW and W bus outputs,
  aggregate busy/request-done, and whether beat event/index are public;
- exact fixed AWLEN3/AWSIZE2/AWBURST-INCR literals and the four-byte-aligned
  16-byte-span-within-one-4-KiB admission/assertion predicate;
- atomic capture, one-shot launches, simultaneous/AW-first/W-first completion,
  AW and W stalls, continuous WREADY, zero/partial strobes, busy command,
  reset during AW-only/W-mid-burst/near-join phases, recovery, and final idle;
- unchanged-child generation calls and private bindings, new coordinator
  rules/storage/priorities/assertions, flat C4 port/net/link/child counts,
  generated IAL1/IAL0 item arrays, selected structural entry, report/static/
  residue contract, and fail-closed diagnostics;
- strict/check/schedule/semantic/outdir/Verilator/Yosys surfaces and an exact
  generated-HDL cardinality/progression proof;
- support-accounting delta, capability manifest, focused test, mdBook, fact,
  task/index/MEMORY, validation, and rollback owners; and
- preservation of the shipped standalone AW/W/W-burst4/B/AR/R sources and all
  existing compositions, plus every deferred candidate above.

The audit must choose the exact following contract-selection and atomic
implementation leaves. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in `.44`.

## Validation and rollback

This selector is documentation-only. Validate it with Knowledge Map
generation/checking, mdBook build, Memory cap, relative-path and whitespace
checks, and the doctrine gate. The shipped t/1499, t/1502, t/1503, t/1507, and
t/1508 results are evidence; no behavior changed, so this leaf does not need to
rerun their generated-HDL simulations.

Rollback removes this note and its fact card, restores `.43` to active,
removes `.44`, and restores task-index/book/MEMORY pointers. No parser,
generator, source, support, manifest, test, artifact, runtime, or HDL rollback
is required.

## Primary repository sources

- `docs/knowledge/ial2-axi-w-burst4-driver-behavior.md`
- `docs/knowledge/ial2-axi-aw-w-request-composition-first-slice.md`
- `docs/knowledge/ial2-axi-full-write-transaction-composition-first-slice.md`
- `docs/knowledge/ial2-axi-read-burst4-transaction-composition-behavior.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm`
- `perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm`
- `perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm`
- `perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `docs/book/src/16a-ial2-axi.md`
- `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`
- `docs/decisions/0017-ppif-valid-ready-bundle-contract.md`
- `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`
- `docs/decisions/0020-ial2-layered-composable-transactor-roles.md`
