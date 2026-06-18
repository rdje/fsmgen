# AXI IAL2 Manager Post Write Depth-3 Queue-Head Response-Demux Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.172` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.172`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.173`, readiness audit for
generated multiple or mixed depth-3 concrete same-ID queue-head
response-demux groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.171` generated write depth-3 queue-head response-demux behavior and
  implementation boundary;
- the `.170` readiness audit that selected `.171`;
- the shipped one-group write depth-3, write multi-group depth-2, read
  single-beat depth-3, and read single-beat multi-group depth-2 schedule
  surfaces;
- current same-ID issue-order queue admission, transition, assertion,
  response-demux, report, focused-test, public-sample, support-accounting,
  README, roadmap, mdBook, task-tree, Memory, and Knowledge Map surfaces.

## Live Probe Findings

The existing write depth-3 sample is generated and support-accounted:

```text
ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_write_bid_queue_head_demux
  queue=3:w0/w1/w2:d3
  response_demux.residue without generated_same_id_queue_head_demux
```

The existing write multi-group sample remains generated for depth-2 groups:

```text
ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_write_bid_queue_head_demux
  queues=3:w0/w1:d2,5:w2/w3:d2
```

The existing read single-beat depth-3 sample is generated for exactly one
group:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_read_single_beat_queue_head_demux
  queue=3:r0/r1/r2:d3
```

The existing read single-beat multi-group sample remains generated for
depth-2 groups:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_read_single_beat_queue_head_demux
  queues=3:r0/r1:d2,5:r2/r3:d2
```

Two temporary `/tmp` write-family probes confirmed the remaining depth/group
boundary. A two-group depth-3 probe and a mixed depth-3/depth-2 probe both
strict-check with no diagnostics, report selected queue-head metadata, and
remain selected-not-generated:

```text
/tmp/fsmgen_ial2_write_multi_depth3_probe.ppif
  mode=bounded_write_bid_queue_head_demux_contract
  generated=0
  implementation_status=selected_not_generated
  queues=3:w0/w1/w2:d3,5:w3/w4/w5:d3
  response_demux.residue includes generated_same_id_queue_head_demux
  strict_check.diagnostics=0
  support_accounting.matched=0

/tmp/fsmgen_ial2_write_mixed_depth2_depth3_probe.ppif
  mode=bounded_write_bid_queue_head_demux_contract
  generated=0
  implementation_status=selected_not_generated
  queues=3:w0/w1/w2:d3,5:w3/w4:d2
  response_demux.residue includes generated_same_id_queue_head_demux
  strict_check.diagnostics=0
  support_accounting.matched=0
```

The temporary probes were deleted after inspection.

## Code Findings

The local gate is `_build_same_id_issue_order_queue_behavior` in
`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`.

It currently admits:

- any one-or-more depth-2 queue-head response-demux group shape for read
  single-beat, read burst-last, or write;
- exactly one read single-beat depth-3 group;
- exactly one read burst-last depth-3 group;
- exactly one write depth-3 group.

It does not yet admit more than one depth-3 group or a mixed
depth-2/depth-3 group set. After admission, the downstream helpers are already
group/depth driven: queue state enumeration consumes `group->{depth}`, slot
storage and update rules iterate slots and transactions, response-demux rules
iterate generated queue transactions, and report helpers list every generated
queue group.

## Candidate Comparison

Multiple or mixed depth-3 groups are the next smallest roadmap-aligned step
because the project now has both halves needed for the combination:

- one-group depth-3 behavior is generated for read single-beat, read
  burst-last, and write response-demux families;
- multi-group depth-2 behavior is generated for read single-beat, read
  burst-last, and write response-demux families.

Same-family mixed auto-ID plus concrete queue-head demux still needs explicit
allocator/queue interaction semantics. Group-local simultaneous enqueue
widening changes the admission model and must stay separate. Packed
burst-vector outputs and alternate full-burst assembly are read-data
output-shape work. Verification-output generation is owned by the IAL1
verification-code frontier. Direct backend and VHDL/backend-language variants
remain deferred until the SystemVerilog-backed IAL path is feature complete.

## Selected .173 Boundary

`.173` should audit generated multiple or mixed depth-3 concrete same-ID
queue-head response-demux readiness before any behavior change.

The audit should cover:

- response-demux-only queue-head behavior;
- read single-beat, read burst-last, and write family candidates;
- two or more duplicate concrete-ID queue groups where at least one group has
  computed depth `3`;
- mixed depth-2/depth-3 group sets;
- preservation of existing one-group depth-3 and multi-group depth-2 samples;
- whether the next behavior leaf should implement all response-demux-only
  families or a smaller first family/scope;
- exact future public sample names, support-accounting entries, report
  expectations, generated artifact expectations, tests, docs/book updates,
  rollback boundary, and preservation matrix.

`.173` must not enable read-data, burst-length, runtime-validation,
multi-beat payload, same-family mixed auto-ID plus concrete queue-head demux,
group-local simultaneous enqueue widening, packed outputs, alternate burst
assembly, direct backend, verification-output generation, VHDL, or another
backend-language variant.

## Validation Gates For .173

The readiness audit should run direct schedule/check probes for temporary
multiple depth-3 and mixed depth-2/depth-3 candidates, preservation probes for
existing one-group depth-3 and multi-group depth-2 public samples, Knowledge
Map generation/check, mdBook build, docs path audit, memory architecture
check, diff hygiene, README numbering, and stale/positive frontier scans.

## Rollback Boundary

Because `.172` is selector-only, rollback is documentation, task-tree,
Memory, and Knowledge Map state only. `.173` must remain behavior-free unless
it selects a separately owned implementation leaf.
