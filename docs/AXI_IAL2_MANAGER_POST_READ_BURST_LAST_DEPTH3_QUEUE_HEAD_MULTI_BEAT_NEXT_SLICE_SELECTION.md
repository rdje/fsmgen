# AXI IAL2 Manager Post Read Burst-Last Depth-3 Queue-Head Multi-Beat Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.169` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.169`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.170`, readiness audit for
generated write-family depth-3 concrete same-ID queue-head response-demux
behavior.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.168` generated read burst-last depth-3 queue-head multi-beat
  read-data behavior and implementation;
- the `.167` readiness audit that selected `.168`;
- the `.165` runtime-validation behavior over the same read burst-last
  depth-3 queue-head group;
- the `.149`, `.153`, `.156`, `.159`, `.162`, `.165`, and `.168` depth-3
  read-family behavior notes;
- the `.108` one-group write depth-2 queue-head response-demux behavior;
- the `.140` write multi-group depth-2 queue-head response-demux behavior;
- current same-ID issue-order queue admission, transition, assertion,
  response-demux, report, focused-test, public-sample, support-accounting,
  README, roadmap, mdBook, task-tree, Memory, and Knowledge Map surfaces.

## Live Probe Findings

The existing one-group write depth-2 sample is generated:

```text
ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_write_bid_queue_head_demux
  rules=axi0_w0_response_demux,axi0_w1_response_demux
  queue=3:w0/w1:d2
  response_demux.residue=read_response_demux,read_data_interleaving,bursts
```

The existing write multi-group depth-2 sample is generated:

```text
ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_write_bid_queue_head_demux
  rules=axi0_w0_response_demux,axi0_w1_response_demux,axi0_w2_response_demux,axi0_w3_response_demux
  queue=3:w0/w1:d2
  queue=5:w2/w3:d2
  response_demux.residue=read_response_demux,read_data_interleaving,bursts
```

A temporary `/tmp` write depth-3 candidate with `w0`, `w1`, and `w2` sharing
concrete `BID` `3`, `write-max-pending 3`, `same-id-ordering.write
concrete-id-reuse issue-order-queue`, and generated write response demux
passes strict check with no diagnostics but remains selected-not-generated:

```text
/tmp/fsmgen_write_depth3_probe.ppif
  mode=bounded_write_bid_queue_head_demux_contract
  generated=0
  implementation_status=selected_not_generated
  queue=3:w0/w1/w2:d3
  response_demux.residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts
  same_id_ordering.residue=concrete_id_same_id_ordering,per_id_issue_order_queues
  strict_check.success=1
  support_accounting.matched=0
  diagnostics=0
```

## Code Findings

The local same-ID issue-order queue behavior gate currently admits:

- any one-or-more generated depth-2 group shape for read single-beat, read
  burst-last, or write response demux;
- exactly one read single-beat depth-3 group;
- exactly one read burst-last depth-3 group.

It does not yet admit a write depth-3 group. The downstream transition,
storage, assertion, and response-demux helpers are group/depth driven after
admission:

- queue state enumeration consumes `group->{depth}`;
- slot storage and assignments iterate slots and transactions;
- response assertions iterate queue groups and transaction names;
- write response-demux report helpers already accept explicit queue lists,
  completion signal lists, generated rule lists, and generated assertion
  lists.

The temporary probe therefore points at a local write depth-3 admission and
coverage boundary, but the write-specific generated transition count,
assertion naming, focused PPIF helper expectations, support-accounted public
sample, and preservation matrix should be audited before behavior changes.

## Candidate Comparison

Write depth-3 queue-head response demux is the smallest roadmap-aligned next
step because it extends an already generated write depth-2/multi-group
response-demux family and mirrors the now-shipped read depth-3 queue-state
substrate without adding read-data, burst-length, multi-beat payload, mixed
auto-ID, direct backend, or VHDL work.

Multiple or mixed depth-3 groups are broader because they combine deeper
queues with either multiple concrete IDs or mixed family behavior. Same-family
mixed auto-ID plus concrete queue-head demux requires allocator/queue
interaction semantics. Group-local simultaneous enqueue widening changes the
admission/transition model. Packed burst-vector outputs and alternate full
burst assembly are read-data output-shape work, not queue-head response-demux
work. Verification-output generation is owned by the IAL1 verification-code
frontier. Direct backend and VHDL remain deferred until the SystemVerilog-backed
IAL path is feature complete.

## Selected .170 Boundary

`.170` should audit only:

- write family only;
- generated `response-demux.write`;
- raw write response event `axi0_write_complete`;
- generated transaction completion ownership;
- generated queue-head response-demux boundary
  `generated_write_bid_queue_head_demux`;
- exactly one duplicate concrete write-ID group;
- exactly three write transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.write concrete-id-reuse issue-order-queue`;
- no read-data, burst-length, runtime-validation, multi-beat payload, read
  response-demux, or RLAST behavior;
- no same-family mixed auto-ID demux;
- no write multi-group depth-3, mixed read/write depth-3, group-local
  simultaneous enqueue widening, packed outputs, alternate burst assembly,
  direct backend, verification-output generation, VHDL, or backend-language
  variant work.

The audit should inspect whether a direct implementation can widen only the
local queue-head behavior admission boundary or whether a smaller prerequisite
is required first. It should record the exact public PPIF sample name, support
accounting entry, report schema expectations, generated artifact expectations,
focused tests, direct probes, docs/book/KM updates, rollback boundary, and
preservation matrix before any behavior-bearing change.

Expected implementation evidence to audit includes queue storage for
`slot0`/`slot1`/`slot2`, generated completion signals for `w0`/`w1`/`w2`,
write response-demux rules for all three transactions, write response
assertions over the depth-3 group, empty `generated_same_id_queue_head_demux`
residue for the covered write sample, and preservation of existing depth-2
write one-group and multi-group behavior plus all read depth-3 behavior.
