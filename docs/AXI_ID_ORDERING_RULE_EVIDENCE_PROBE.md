# AXI ID/Ordering Rule Evidence Probe

Status: evidence inventory complete; no IAL2 implementation selected.

Task tree:
[docs/tasks/AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.md](tasks/AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.md).

Source artifact:
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`

Source SHA-256:
`20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`

## Purpose

This note records the first bounded source-anchor inventory for AXI
transaction IDs, ordering, outstanding concurrency, response matching, and
read/write data interleaving as future IAL2 AXI rule-engine prerequisites.

It is not a shipped feature. It does not select syntax, parser behavior,
lowering behavior, generated `.isf`, generated `.fsm`, HDL, or reusable
library artifacts.

## Extraction Method

The tracked PDF was inspected as a repo-local reference artifact:

- `pdfinfo` confirmed a 320-page, unencrypted PDF.
- `pdftotext -layout` produced temporary text extractions for `A1`, `A5`,
  `A6.4.4`, and `B3` source search.
- Rendered temporary page images were visually checked for `A5.1` ID tables
  and `A5.5` write-data Resource Plane interleaving.
- Temporary extraction and render products were kept outside the repository
  and are not tracked.

The repository keeps this curated note instead of raw extracted text. That
preserves source anchors and reviewability without embedding large
copyrighted spec text.

## Source Anchors

| Anchor | PDF page | Evidence captured | Classification |
| --- | ---: | --- | --- |
| `A1.1 About the AXI protocol` | 21 | AXI is introduced with multiple outstanding addresses and out-of-order transaction completion as core protocol capabilities. | source fact |
| `A1.2 AXI Architecture` | 22 | AXI transactions use five channel families: `AW`, `W`, `B`, `AR`, and `R`. The architecture supports address issue ahead of data, multiple outstanding transactions, and out-of-order completion. | source fact |
| `A5.1 Transaction identifiers` | 90 | AXI IDs identify ordered transaction streams. Same-ID transactions are ordered, different IDs have no general ordering restriction, and IDs let a manager issue later transactions before earlier ones complete. | source fact |
| `A5.1.1 Transaction ID signals`, Tables `A5.1` and `A5.2` | 90 | `AWID`/`BID` are the write-side ID pair, `ARID`/`RID` are the read-side ID pair, and `ID_W_WIDTH` / `ID_R_WIDTH` can range from 0 to 32 bits. If a width is zero, the corresponding ID signal is absent. | source fact; visual check |
| `A5.2 Unique ID indicator` | 91-92 | Optional `AWIDUNQ`, `BIDUNQ`, `ARIDUNQ`, and `RIDUNQ` signals mark IDs that are unique among in-flight transactions. The section defines when a transaction is outstanding and carries additional rules for Atomic transactions. | source fact |
| `A5.3 Request ordering` | 93 | Request ordering is based on `AWID`/`ARID`. Same-channel, same-ID, same-destination requests retain order; same-ID responses return in request order. No general ordering is provided across different managers, read versus write, different IDs, different Peripheral regions, or different Memory locations. | source fact |
| `A5.3.4 Manager ordering guarantees` | 94-95 | Manager guarantees are split into pre-completion observability, completion-derived observability, and response ordering. Same-manager same-ID read responses and write responses are ordered by issue order inside their respective response streams. | source fact |
| `A5.3.5 Subordinate ordering requirements` | 95-96 | Subordinates must preserve the same-ID response-order guarantees for reads and writes, and must honor the listed same-ID memory ordering cases that are needed for manager-visible guarantees. | source fact |
| `A5.3.6 Interconnect ordering requirements` | 96 | Interconnects must preserve same-ID read/write request and response ordering for the listed overlapping-location or Peripheral-region cases, and any ID manipulation must preserve the original ordering requirements. | source fact |
| `A5.3.7 Response before the endpoint` | 96-97 | Early responses are allowed only when the intermediate component preserves visibility and ID ordering; earlier same-ID responses must be satisfied before an early read or write response is issued. | source fact; future residue |
| `A5.3.8 Ordering between requests with different memory types` | 97 | Same-ID responses remain ordered regardless of cacheability. Device versus Normal Non-cacheable ordering can depend on the `Device_Normal_Independence` property. | source fact; future residue |
| `A5.4 Interconnect use of transaction identifiers` | 99 | Interconnects can append manager-unique bits to `AWID`/`ARID`, route `BID`/`RID` back to the originating manager, and strip the appended bits before returning the response. | source fact |
| `A5.5 Write data and response ordering` | 100 | Write data normally follows write request order. Credited transport Resource Planes can relax this per plane and permit data interleaving across planes. `BID` must match the corresponding `AWID`, and same-`AWID` write responses targeting different subordinates must return to the manager in request order. | source fact; visual check |
| `A5.6 Read data ordering` | 101 | `RID` must match the corresponding `ARID`. Interconnects must return same-`ARID` read data targeting different subordinates to the manager in request order. Subordinate read-data reordering depth is static and not dynamically discoverable by a manager. | source fact |
| `A5.6.1 Read data interleaving` | 101 | Read data transfers for different ID values may interleave. Managers that issue different IDs must be able to accept interleaved read data unless the relevant design-time property disables it. | source fact |
| `A5.6.2 Read data chunking` | 102 | Read data chunking can reorder chunks within a transaction and therefore needs separate future treatment if enabled. | source fact; explicit residue |
| `A6.4.4 ID use for Atomic transactions` | 116 | Atomic transactions use one AXI ID across request, write response, and read data where applicable; the ID must be representable on both write and read response sides and must be unique in flight under the listed cases. | source fact; explicit residue |
| `B3 Summary of ID constraints` | 305 | The appendix summarizes ID constraints: some transaction classes require unique-in-flight IDs, some pairs must not share in-flight IDs on the same channels, and ordering-required outstanding requests plus exclusive pairs must use the same ID. | source fact |

## Source Facts For A Future AXI Rule Engine

The first source-supported ID/order facts are:

- AXI has separate channel families for write request, write data, write
  response, read request, and read data.
- Multiple outstanding transactions and out-of-order completion are intended
  AXI capabilities, not optional sugar layered above the protocol.
- IDs are the primary mechanism for splitting a physical manager port into
  ordered logical streams.
- Write IDs and read IDs are separate interface-width families:
  `AWID`/`BID` use `ID_W_WIDTH`, while `ARID`/`RID` use `ID_R_WIDTH`.
- A manager that uses IDs expects write responses to reflect `AWID` through
  `BID` and read data to reflect `ARID` through `RID`.
- Same-ID ordering is not a single global "serialize everything" rule. The
  request-ordering guarantees are qualified by channel, destination, address
  region/location, memory type, and component role.
- Same-ID read responses and same-ID write responses are ordered by issue
  order inside their response families.
- Different IDs are the source-supported way to expose legal concurrency and
  reordering, but users or generated managers still need response matching and
  per-ID bookkeeping.
- If ordering is required where AXI gives no ordering guarantee, the manager
  must avoid issuing the later request until the earlier one has completed.
- Unique-in-flight indicators and the B3 summary create transaction-class
  rules that cannot be reduced to "pick any free ID".
- Interconnect ID widening/remapping is legal only when the original ordering
  requirements remain preserved and responses are routed back to the correct
  manager.
- Write data follows write-request order unless credited transport Resource
  Plane rules are in scope.
- Read data for different IDs may interleave, so a manager using multiple read
  IDs needs a matcher/reassembler rather than a single FIFO assumption.

## Inferred Rule-Engine Needs

These are candidate rule-engine needs inferred from the source facts, not a
selected IAL2 design:

- ID allocation and user-ID validation for both write and read ID families.
- Per-channel and per-ID outstanding scoreboards.
- A response matcher that associates `BID` with `AWID` and `RID` with `ARID`.
- Same-ID issue-order queues for read and write response families.
- A wait/stall/queue/reject policy when a requested transaction would violate
  an ordering requirement, unique-in-flight requirement, or maximum pending
  window.
- A rule table for transaction classes that require unique-in-flight IDs,
  forbid same-ID coexistence with another transaction class, or require the
  same ID.
- A read-data interleaving policy that either requires a multi-ID reassembler
  or constrains issuing when interleaving is disabled.
- A write-data sequencing policy, with Resource Plane support left as an
  explicit future extension.
- Interconnect/proxy metadata if a future IAL2 object owns ID remapping or
  manager-port routing.
- Structured feedback reasons such as `max_pending_reached`, `id_busy`,
  `unique_id_required`, `same_id_required`, `ordering_wait_required`,
  `read_interleaving_disabled`, and `unsupported_transaction_kind`.
- Generated reports and assertions that state which source-anchored rules were
  statically enforced, generated into scheduler behavior, checked at runtime,
  assumed from the environment, or left as residue.

## Explicit Abstractions For This Probe

This slice intentionally stops before design:

- No AXI manager, subordinate, or interconnect implementation.
- No IAL2 syntax, parser, lowering, `.isf`, `.fsm`, HDL, or generated
  assertions.
- No full burst model, exclusive-access model, Atomic model, cacheability
  model, protection/QoS/region model, or ACE/CHI coherency behavior.
- No Resource Plane or credited-transport implementation.
- No read-data chunking implementation.
- No exact error/status API selection.
- No max-pending default, queue-depth default, or ID allocation policy is
  selected.

## Unsupported Residue

The first future implementation or design leaf must explicitly carry these as
residue unless it selects them as owned scope:

- Full manager ordering guarantees across Device/Normal, cacheability,
  observability, shareability domains, and early-response behavior.
- Full subordinate and interconnect ordering compliance.
- Resource Plane credited-transport write-data ordering.
- Read-data chunking and chunk reassembly.
- Atomics, exclusives, Prefetch, WriteZero, WriteDeferrable, InvalidateHint,
  MTE-tag transport, UnstashTranslation, ACT, DVM, StashOnce, translation, and
  StashTranslation constraint families listed in `B3`.
- Dynamic discovery of subordinate read-data reordering depth, which the
  source says is not available.

## IAL2 Boundary Assessment

This evidence is strong enough to justify a later design/probe leaf for the
AXI rule engine behind an IAL2 manager surface. It is not yet strong enough to
justify an implementation leaf.

A future IAL2 AXI manager design is viable only if it preserves all of these
outputs:

- source anchors back to the tracked AXI reference,
- a fact/inference/abstraction/residue report,
- explicit ID-family, outstanding-window, response-matching, and interleaving
  rules,
- clear feedback when the manager cannot accept or issue a requested
  transaction,
- generated or configured IAL1/IAL0 artifacts that remain reviewable,
- and focused validation gates for ID allocation, ordering, response matching,
  backpressure, and report contracts.

## Current Conclusion

The AXI ID/order/concurrency evidence supports the user's requested direction:
the future manager should let users submit logical transactions while the
manager owns the low-level ID, ordering, outstanding, interleaving, and
response-matching obligations.

Easy mode can still expose AXI concurrency if it is backed by the same
source-anchored rule engine as Power and supervised Raw modes. The next work
must still be a new exact task-tree leaf before any IAL2 syntax, lowering, or
HDL behavior is selected.
