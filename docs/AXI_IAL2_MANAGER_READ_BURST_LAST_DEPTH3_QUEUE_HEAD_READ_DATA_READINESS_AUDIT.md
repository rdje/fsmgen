# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Read-Data Readiness Audit

Status: audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.158` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.158`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.159`, direct bounded
implementation of generated scalar last-beat read-data over the generated read
burst-last depth-3 queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.157` selector for this readiness audit;
- `.156` generated read burst-last depth-3 queue-head response-demux behavior
  and implementation;
- `.153` generated read single-beat depth-3 queue-head read-data behavior;
- `.115`, `.117`, `.119`, and `.121` depth-2 read burst-last queue-head
  last-beat read-data, report-only burst-length, runtime-validation, and
  multi-beat behavior notes;
- current `_read_data_response_demux_transaction_coverage`,
  read-data source/input/output/rule/report/residue helpers, same-ID
  queue-state helpers, focused generator tests, PPIF parser/CLI tests, public
  samples, support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map.

## Live Probe Findings

The shipped `.156` sample is generated at depth `3`, has all three generated
completion pulses, and has no read-data contract:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  generated=1
  depths=3
  completions=axi0_r0_complete,axi0_r1_complete,axi0_r2_complete
  response_residue=read_data_interleaving,bursts
  read_data_mode=none
```

The existing read burst-last scalar read-data sample is generated only at
depth `2`:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2
  read_data_mode=bounded_last_beat_read_data_contract
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  inputs=axi0_rdata,axi0_rresp
  outputs=axi0_r0_last_rdata,axi0_r0_last_rresp,axi0_r1_last_rdata,axi0_r1_last_rresp
  rules=axi0_r0_read_data_capture,axi0_r1_read_data_capture
```

The read single-beat depth-3 sibling proves that the scalar read-data artifact
path already iterates three covered queue-head transactions once the coverage
gate admits the shape:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_single_beat_queue_head_demux
  depths=3
  read_data_mode=bounded_single_beat_read_data_contract
  completion=generated_queue_head_response_demux_completion_pulse
  inputs=axi0_rdata,axi0_rresp
  outputs=axi0_r0_rdata,axi0_r0_rresp,axi0_r1_rdata,axi0_r1_rresp,axi0_r2_rdata,axi0_r2_rresp
  rules=axi0_r0_read_data_capture,axi0_r1_read_data_capture,axi0_r2_read_data_capture
```

A temporary `/tmp` candidate copied the `.156` PPIF sample and added only
scalar last-beat read-data bindings for `r0`, `r1`, and `r2`. The temporary
file was removed after use. It fails closed at the current coverage gate:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head last-beat
coverage requires one or more depth-2 concrete same-ID read queue groups with
no burst_length metadata, report-only burst_length metadata, or
runtime-assertion burst_length metadata in this slice
```

Strict check JSON reports the same single error and `generated_output.emitted:
false`.

## Code Findings

The same-ID issue-order queue builder already generates the exact `.156`
depth-3 burst-last queue-head response-demux boundary:

- read family only;
- `response_scope burst_last`;
- one-bit `last_signal`;
- exactly one duplicate concrete read-ID group;
- three read transactions;
- computed queue depth `3`;
- generated completion signals for `r0`, `r1`, and `r2`.

`_read_data_response_demux_transaction_coverage` already recognizes
`capture_scope last-beat` over
`generated_read_burst_last_queue_head_demux` and assigns completion validity
`generated_queue_head_response_demux_last_beat_completion_pulse`. Its current
depth-3 exception is scoped only to the read single-beat sibling.

Downstream scalar read-data generation has no depth-specific logic:

- `_read_data_source_inputs` emits `RDATA` and `RRESP` for scalar capture;
- `_read_data_output_lines` iterates `read.transactions`;
- `_read_data_capture_rule_lines` emits one capture rule per transaction,
  guarded by that transaction's generated completion signal;
- `_read_data_generated_artifacts` reports generated inputs, outputs, and
  rules by iterating the same transaction list;
- the SystemVerilog lowerer already exposes the generated scalar outputs and
  capture enables for the depth-2 burst-last and depth-3 single-beat siblings.

Therefore the only direct behavior gate for scalar last-beat read-data over
the `.156` shape is the local coverage predicate plus its report/static
support-detail expectations and focused/public sample coverage.

## Selected .159 Boundary

`.159` should implement only:

- read family;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal` / `RLAST`;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- `read-data.read.capture-scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- scalar `RDATA`/`RRESP` output bindings for `r0`, `r1`, and `r2`;
- public PPIF sample, support-accounting, focused generator and PPIF/CLI
  tests, docs, mdBook, task tree, Memory, and Knowledge Map updates.

Expected generated artifacts include:

- generated inputs `axi0_rdata` and `axi0_rresp` in addition to existing
  `axi0_rid` and `axi0_rlast`;
- scalar outputs `axi0_r0_last_rdata`, `axi0_r0_last_rresp`,
  `axi0_r1_last_rdata`, `axi0_r1_last_rresp`, `axi0_r2_last_rdata`, and
  `axi0_r2_last_rresp`;
- capture rules `axi0_r0_read_data_capture`,
  `axi0_r1_read_data_capture`, and `axi0_r2_read_data_capture`;
- schedule report mode `bounded_last_beat_read_data_contract`;
- completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- read-data residue limited to the existing scalar last-beat deferrals:
  `multi_beat_read_data_reassembly`, `per_beat_outputs`,
  `rresp_aggregation`, and `arlen_or_beat_count_validation`.

## Deferred Work

The following remain outside `.159`:

- report-only raw-`ARLEN` burst-length over read burst-last depth-3;
- runtime beat-count/`RLAST` validation over read burst-last depth-3;
- multi-beat output-bank behavior over read burst-last depth-3;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .159

The implementation slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, focused generator tests, focused PPIF/CLI tests, and
  regression-corpus accounting;
- direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes for the new public PPIF sample;
- preservation probes or focused assertions for `.156`, depth-2 read
  burst-last last-beat read-data, depth-3 read single-beat read-data, and
  depth-2 burst-length/runtime/multi-beat siblings;
- focused generator and PPIF/CLI regressions;
- regression-corpus accounting;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and frontier scans.

## Rollback Boundary

Because `.158` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. No behavior-bearing code or public sample is
changed by this slice.
