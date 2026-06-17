# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.155` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.155`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.156`, generated read burst-last
depth-3 concrete same-ID queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.154` post depth-3 read-data selector;
- `.153` generated read single-beat depth-3 queue-head read-data behavior;
- `.149` generated read single-beat depth-3 queue-head response-demux
  behavior;
- `.148` deeper queue-head groups readiness audit;
- `.124` generated read burst-last multi-group depth-2 response-demux
  behavior;
- `.115`, `.117`, `.119`, `.121`, `.127`, `.130`, `.132`, and `.135` read
  burst-last queue-head read-data, burst-length, runtime-validation, and
  multi-beat behavior notes;
- current same-ID queue builder, generic transition table, queue assertions,
  response-demux rule generation, response-demux assertion helpers,
  read-data coverage gates, support detail strings, focused tests, public
  samples, support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map.

## Live Probe Findings

Existing public read burst-last queue-head samples remain generated at depth
`2`:

```text
ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  queue_depths=2
  last_signal=axi0_rlast

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  queue_depths=2,2
  last_signal=axi0_rlast
```

A temporary `/tmp` read burst-last depth-3 PPIF probe was created from the
shipped read single-beat depth-3 sample by changing the response scope to
`burst-last` and adding one-bit `axi0_rlast`. The temporary source was removed
after use. It passes schedule parsing, strict check JSON, and semantic JSON,
but remains selected-not-generated:

```text
schedule_exit=pass
response_generated=0
response_impl=selected_not_generated
selected_signals=axi0_r0_complete,axi0_r1_complete,axi0_r2_complete
queue_depths=3
queue_transactions=r0,r1,r2
same_id_generated=0
same_id_impl=admitted_request_pulses_generated
response_residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts
strict_check_success=1
strict_check_diagnostics=0
semantic_success=1
```

This proves the parser, selected completion metadata, static checks, and
semantic JSON can already carry the selected depth-3 burst-last shape.

## Code Findings

The current `_build_same_id_issue_order_queue_behavior` gate admits generated
queue-head behavior only for:

- any supported depth-2 group with exactly two transactions; or
- exactly one read single-beat depth-3 group with exactly three transactions.

The temporary read burst-last depth-3 probe fails to generate only because
that local gate does not yet admit the burst-last sibling.

The downstream generation helpers are already generic over group depth and
already carry `RLAST`/last-signal semantics:

- storage and slot signal allocation iterate `0 .. depth - 1`;
- `_same_id_issue_order_queue_transition_specs` enumerates queue states and
  enqueue/dequeue transitions from the group depth and transaction list;
- queue-head rule guards use `_same_id_issue_order_queue_head_match_expr`,
  which includes `last_signal` when present;
- queue assertions iterate slots and transactions and include
  `nonlast_no_dequeue` when `last_signal` is present;
- response-demux assertion states use queue-head identity for active/unique
  assertions and queue-head guard expressions for generated pulse rules;
- report and residue helpers already iterate generated groups and carry
  `last_signal` in generated queue reports.

Therefore the next implementation is not a parser or semantic-introspection
prerequisite. It is a narrow behavior exposure through the same shared
queue-state machinery already proven by read single-beat depth-3 and read
burst-last depth-2 behavior.

## Selected .156 Boundary

`.156` should implement only:

- read family;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal` / `RLAST` metadata;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- generated queue-head completion pulses for the active head transaction only
  when raw response event, concrete `RID`, `RLAST`, and slot-0 identity all
  match;
- generated compact queue state over `slot0` through `slot2`;
- generated slot, compactness, unique-slot, response-nonempty,
  response-unique-head, non-last-no-dequeue, enqueue-space-or-dequeue, and
  duplicate-after-dequeue assertions;
- public support-accounted PPIF sample;
- focused generator and PPIF/CLI tests;
- schedule/check/semantic/generated-HDL/verify-HDL probes for the new sample;
- preservation probes for existing depth-2 read burst-last, read single-beat,
  write, read-data, burst-length, runtime-validation, and multi-beat
  queue-head samples.

## Deferred Work

The following remain outside `.156`:

- read-data over read burst-last depth-3 response-demux;
- burst-length, runtime-validation, or multi-beat read-data over read
  burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- packed burst-vector outputs or alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .156

The implementation slice should run:

- syntax checks for touched Perl modules and tests;
- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- regression corpus accounting if a public sample is added;
- direct schedule JSON, strict check JSON, strict semantic JSON, generated HDL,
  and `--verify-hdl` probes for the new sample;
- preservation probes for existing one-group and multi-group depth-2
  read burst-last queue-head samples, read single-beat depth-3 samples, write
  queue-head samples, and queue-head read-data/burst-length/runtime/multi-beat
  samples;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.155` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.

For `.156`, rollback should include the new public PPIF sample,
support-accounting entry, focused test additions, docs/book updates, and the
single gate widening that admits the selected read burst-last depth-3
queue-head response-demux shape.
