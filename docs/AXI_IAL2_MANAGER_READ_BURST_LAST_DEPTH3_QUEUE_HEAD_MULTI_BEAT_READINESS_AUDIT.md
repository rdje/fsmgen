# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Multi-Beat Readiness Audit

Status: audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.167` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.167`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.168`, direct bounded
implementation of generated multi-beat read-data output-bank behavior over
exactly one read burst-last depth-3 queue-head runtime-validation group.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.166` selector that chose this audit;
- the `.165` generated read burst-last depth-3 queue-head runtime-validation
  behavior and implementation;
- the `.164` runtime-validation readiness audit;
- the `.162` report-only raw-`ARLEN` depth-3 behavior;
- the `.159` no-`burst_length` read burst-last depth-3 read-data behavior;
- the `.121` one-group depth-2 queue-head multi-beat behavior;
- the `.127` multi-group depth-2 queue-head multi-beat behavior;
- current queue-head read-data coverage gates, runtime-validation
  normalization/storage/rule/assertion/report helpers, multi-beat
  normalization/output/rule/report helpers, focused generator and PPIF/CLI
  tests, public samples, support accounting, README, roadmap, mdBook, task
  tree, Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.165` sample is generated at depth `3` with runtime validation
and leaves only the multi-beat output surface as read-data residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  mode=bounded_last_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=runtime_assertion
  beat_count=1
  beat_match=response_demux_matched_read_beat
  output_shape=
  transactions=r0,r1,r2
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
  queues=3:r0/r1/r2:d3
```

The `.162` report-only sibling remains preserved:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
  mode=bounded_last_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=report_only
  beat_count=0
  transactions=r0,r1,r2
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
  queues=3:r0/r1/r2:d3
```

The one-group depth-2 multi-beat sample proves generated per-beat output-bank
behavior over the same burst-last queue-head demux and runtime-validation
substrate:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  mode=bounded_multi_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=runtime_assertion
  beat_count=1
  beat_match=response_demux_matched_read_beat
  output_shape=per_beat_output_bank
  transactions=r0,r1
  generated_multi_beat_valid_outputs=axi0_r0_beat_valid,axi0_r1_beat_valid
  generated_multi_beat_capture_rules=32
  residue=
  queues=3:r0/r1:d2
```

The multi-group depth-2 multi-beat sample proves the downstream helpers
already flatten more than two covered transactions when the admission gate
permits the shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  mode=bounded_multi_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=runtime_assertion
  beat_count=1
  output_shape=per_beat_output_bank
  transactions=r0,r1,r2,r3
  generated_multi_beat_valid_outputs=axi0_r0_beat_valid,axi0_r1_beat_valid,axi0_r2_beat_valid,axi0_r3_beat_valid
  generated_multi_beat_capture_rules=64
  residue=
  queues=3:r0/r1:d2,5:r2/r3:d2
```

An in-memory depth-3 multi-beat candidate changed the `.165` sample to
`capture-scope multi-beat`, `status-policy per-beat`,
`interleaving multi-beat-by-rid`, per-beat output bindings, valid masks,
length outputs, and scalar `RRESP` aggregate outputs for `r0`, `r1`, and
`r2`. It failed closed at the current local coverage diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head multi-beat
coverage requires one or more depth-2 concrete same-ID read queue groups in
this slice
```

## Code Findings

The only direct blocker is the local multi-beat queue-head coverage predicate.
`_read_data_response_demux_transaction_coverage` already admits depth-3
groups for generated read single-beat queue-head read-data and generated read
burst-last last-beat read-data, including report-only and runtime-assertion
burst-length metadata. For `capture_scope multi-beat`, it currently admits
only depth-2 concrete same-ID read queue groups.

After admission, the target behavior is transaction-list driven:

- `_normalize_read_data_read` already normalizes multi-beat output prefixes,
  generated lane names, valid masks, length outputs, scalar `RRESP`
  aggregation, raw `ARLEN` metadata, beat-count storage, and runtime
  assertion metadata for every covered transaction;
- `_read_data_multi_beat_output_init_rule_lines` emits one output-bank
  clearing rule per covered transaction;
- `_read_data_capture_rule_lines` emits per-lane capture rules using
  `response_demux_matched_read_beat`, `!request_event`, and the transaction's
  beat-count storage;
- `_read_data_generated_artifacts` and `_report_read_data` collect
  multi-beat outputs, valid masks, length outputs, capture rules, aggregate
  outputs, burst-length storage, beat-count rules, and assertions by iterating
  `read.transactions`;
- `_read_data_covers_multi_beat_by_rid_interleaving` and
  `_read_data_covers_bounded_multi_beat_burst_output` remove
  `read_data_interleaving` and `bursts` residue by checking each transaction
  rather than hard-coding a two-transaction group;
- focused report helper `assert_read_data_multi_beat_report` already accepts
  an explicit `transactions => [...]` argument, so `.168` can extend coverage
  for `r0`, `r1`, and `r2` without inventing a new assertion style.

No parser, IAL1, IAL0, SystemVerilog lowerer, support-accounting framework,
or mdBook infrastructure prerequisite is evident.

## Selected .168 Boundary

`.168` should implement only:

- read family only;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`/`RLAST` metadata;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- `read-data.read.capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation (policy worst-observed)`;
- `interleaving multi-beat-by-rid`;
- `burst-length` metadata with `source arlen`, signal `axi0_arlen` width `8`,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- per-transaction `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`
  bindings for `r0`, `r1`, and `r2`;
- a public support-accounted PPIF sample, expected to be named
  `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`;
- focused generator and PPIF/CLI tests, direct schedule/check/semantic/HDL
  probes, README, roadmap, mdBook, task tree, Memory, and Knowledge Map
  updates.

Expected generated artifacts include:

- generated `axi0_rdata`, `axi0_rresp`, and `axi0_arlen` inputs;
- raw `ARLEN` storage and request-bound capture rules for `r0`, `r1`, and
  `r2`;
- expected-beat storage, read-beat counters, beat-count init/increment rules,
  and four beat-count/`RLAST` assertions per transaction;
- 16 generated `RDATA` lanes and 16 generated `RRESP` lanes for each of
  `r0`, `r1`, and `r2`;
- `axi0_r0_beat_valid`, `axi0_r1_beat_valid`, and
  `axi0_r2_beat_valid`;
- `axi0_r0_read_beats`, `axi0_r1_read_beats`, and
  `axi0_r2_read_beats`;
- scalar aggregate outputs `axi0_r0_rresp`, `axi0_r1_rresp`, and
  `axi0_r2_rresp`;
- output-bank init rules, 48 per-lane capture rules, and three scalar
  aggregate update rules.

Expected report movement:

- `read_data.mode: bounded_multi_beat_read_data_contract`;
- `read_data.read.output_shape: per_beat_output_bank`;
- `read_data.read.generated_multi_beat_capture_rules` has 48 entries;
- `read_data.residue: []`;
- `response_demux.residue: []`;
- `same_id_ordering.residue` keeps broader same-ID/per-ID residue but removes
  `read_data_interleaving` and `bursts` for the covered subset.

## Deferred Work

The following remain outside `.168`:

- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- verification-output generation;
- VHDL and other backend-language variant implementations.

## Validation Gates For .168

The implementation slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, focused generator tests, focused PPIF/CLI tests, and
  regression-corpus accounting;
- direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes for the new public depth-3 multi-beat PPIF sample;
- preservation probes or focused assertions for `.165`, `.162`, `.159`,
  depth-2 queue-head multi-beat, multi-group queue-head multi-beat, depth-3
  single-beat read-data, and write queue-head siblings;
- focused generator and PPIF/CLI regressions;
- regression-corpus accounting;
- supported-corpus path/check/semantic gates when support accounting changes;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and frontier scans.
