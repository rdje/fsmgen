# AXI IAL2 Manager Post Multiple/Mixed Depth-3 Queue-Head Read-Data Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.178` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.178`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.179`, readiness audit for
generated read burst-last scalar last-beat read-data over multiple or mixed
depth-3 concrete same-ID queue-head groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, validation, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.177` generated multiple/mixed depth-3 read single-beat read-data
  behavior note and implementation boundary;
- the `.176` read-data readiness audit;
- the `.175` selector, `.174` response-demux behavior, and `.173` readiness
  audit;
- current read-data coverage, report, focused-test, support-accounting, PPIF
  sample, README, roadmap, mdBook, task-tree, Memory, Knowledge Map, and
  import-tree baseline surfaces;
- shipped one-group depth-3 read burst-last scalar last-beat read-data,
  burst-length, runtime-validation, and multi-beat behavior notes;
- remaining roadmap candidates including burst-length/runtime/multi-beat over
  multiple/mixed depth-3 groups, write-family read-data, mixed auto-ID,
  group-local enqueue widening, packed outputs, alternate burst assembly,
  verification-output generation, direct backend, and backend-language
  variants.

## Live Probe Findings

Compact schedule probes confirm `.177` generated the selected single-beat
read-data surface:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif
  boundary=generated_read_single_beat_queue_head_demux
  capture=single_beat
  read_data_generated=1
  depths=3,3
  residue=rlast_completion,bursts,multi_beat_read_data_reassembly

ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
  boundary=generated_read_single_beat_queue_head_demux
  capture=single_beat
  read_data_generated=1
  depths=3,2
  residue=rlast_completion,bursts,multi_beat_read_data_reassembly
```

Adjacent read burst-last multiple/mixed depth-3 samples remain generated
response-demux-only:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  capture=none
  read_data_generated=0
  depths=3,3

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  capture=none
  read_data_generated=0
  depths=3,2
```

The one-group depth-3 read burst-last scalar read-data sibling is already
generated:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
  boundary=generated_read_burst_last_queue_head_demux
  capture=last_beat
  read_data_generated=1
  depths=3
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation
```

Temporary in-memory read-data candidates over the multiple/mixed depth-3
read burst-last response-demux samples fail closed at the current local
coverage gate:

```text
queue-head last-beat coverage requires one or more depth-2 concrete same-ID
read queue groups with no burst_length metadata, report-only burst_length
metadata, or runtime-assertion burst_length metadata, or exactly one depth-3
concrete same-ID read queue group with no burst_length metadata, report-only
burst_length metadata, or runtime-assertion burst_length metadata in this slice
```

## Code Findings

The next blocker is local to
`_read_data_response_demux_transaction_coverage`.

For `capture_scope single-beat`, the helper now accepts bounded
multiple/mixed depth-3 queue-head groups after `.177`. For
`capture_scope last-beat`, it still accepts:

- one or more depth-2 concrete same-ID read queue-head groups with no
  `burst_length`, report-only raw-`ARLEN`, or runtime-assertion metadata; and
- exactly one depth-3 concrete same-ID read queue-head group for those same
  metadata variants.

It does not yet admit multiple depth-3 groups or mixed depth-3/depth-2 groups
for last-beat scalar read-data. Once coverage admits a transaction list, the
normalization, artifact enumeration, report projection, and HDL paths remain
transaction-list driven.

## Candidate Comparison

Read burst-last scalar last-beat read-data over multiple/mixed depth-3 groups
is the smallest safe next audit:

- `.174` already generates the matching read burst-last multiple/mixed
  depth-3 response-demux-only groups;
- `.177` proves the multiple/mixed depth-3 read-data transaction-list widening
  for single-beat reads;
- the one-group depth-3 read burst-last scalar read-data path is already
  generated and support-accounted.

Burst-length, runtime-validation, and multi-beat behavior over those groups
should follow only after scalar last-beat read-data over the same queue sets is
audited. Write-family read-data is a separate family question. Same-family
mixed auto-ID plus concrete queue-head demux still needs allocator/queue
interaction semantics. Group-local simultaneous enqueue widening changes the
admission and transition model. Packed burst-vector outputs and alternate full
burst assembly are output-shape work beyond the current per-transaction and
per-beat-bank model. Verification-output generation is owned by the IAL1
verification-code frontier. Direct backend and VHDL/backend-language variants
remain deferred until the SystemVerilog-backed IAL path is feature complete.

## Selected .179 Boundary

`.179` should audit generated read burst-last scalar last-beat `RDATA`/`RRESP`
over generated read burst-last concrete same-ID queue-head response-demux
groups where every selected duplicate concrete `RID` group has computed depth
`2` or `3` and at least one group has depth `3`.

The audit should cover:

- read family only;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`/`RLAST`;
- generated read burst-last queue-head demux boundary
  `generated_read_burst_last_queue_head_demux`;
- `read-data.read.capture-scope last-beat`;
- `completion-source response-demux`;
- scalar `RDATA`/`RRESP` outputs;
- two-depth-3 and mixed depth-3/depth-2 duplicate concrete `RID` groups;
- no `burst-length` metadata in the first audit scope, while explicitly
  comparing report-only and runtime-validation variants as follow-on or
  prerequisite candidates;
- exact future public sample names, support-accounting entries, report
  expectations, generated-artifact expectations, tests, docs/book updates,
  rollback boundary, and preservation matrix.

`.179` must not enable burst-length, runtime-validation, multi-beat payload,
write-family read-data, same-family mixed auto-ID plus concrete queue-head
demux, group-local simultaneous enqueue widening, packed burst-vector outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, or another backend-language variant.

## Validation Gates For .179

The readiness audit should run compact schedule probes for the existing `.177`
single-beat read-data samples, the `.174` read burst-last response-demux-only
multiple/mixed depth-3 samples, and the one-group depth-3 read burst-last
read-data sample. It should also run temporary fail-closed probes for
last-beat read-data over multiple/mixed depth-3 groups, inspect the local
coverage gate and transaction-list-driven downstream helpers, regenerate/check
the Knowledge Map, build the mdBook, run the docs path audit, run memory
architecture, diff hygiene, README numbering, and stale/positive frontier
scans.

## Rollback Boundary

Because `.178` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.179` must remain behavior-free unless it
selects a separately owned implementation leaf.
