# AXI IAL2 Manager Post Multiple/Mixed Depth-3 Queue-Head Burst-Length Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.184` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.184`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.185`, readiness audit for
generated beat-count/`RLAST` runtime validation over the generated
multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data
shape that already has report-only raw-`ARLEN` burst-length capture.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, validation, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.183` report-only raw-`ARLEN` burst-length behavior note and
  implementation boundary;
- the `.182` readiness audit and `.181` selector;
- the `.180` no-`burst_length` multiple/mixed depth-3 scalar last-beat
  read-data behavior;
- one-group depth-3 report-only burst-length, runtime-validation, and
  multi-beat behavior notes;
- multi-group depth-2 report-only burst-length and runtime-validation
  behavior notes;
- `_read_data_response_demux_transaction_coverage`, read-data
  normalization, beat-count storage/rule/assertion helpers, generated-artifact
  projection, focused generator and PPIF/CLI expectations, public samples,
  support accounting, README, roadmap, mdBook, task tree, Memory, Knowledge
  Map, and import-tree baseline surfaces;
- remaining roadmap candidates including runtime validation and multi-beat
  payload over multiple/mixed depth-3 groups, write-family read-data,
  same-family mixed auto-ID plus concrete queue-head demux, group-local
  enqueue widening, packed outputs, alternate burst assembly,
  verification-output generation, direct backend, VHDL, and backend-language
  variants.

## Live Findings

The `.183` samples now generate report-only raw-`ARLEN` burst-length capture
over the target queue sets:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_source=arlen_signal
  burst_length_validation=report_only
  burst_length_generated_behavior=1
  transactions=6
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif
  groups=3:3:r0,r1,r2;5:2:r3,r4
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_source=arlen_signal
  burst_length_validation=report_only
  burst_length_generated_behavior=1
  transactions=5
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The live coverage gate currently admits the multiple/mixed depth-3 last-beat
shape only when `burst_length` is absent or `burst_length.validation` is
`report-only`. The runtime-assertion branch remains intentionally narrower:
it covers one or more depth-2 groups and the selected one-group depth-3
precedent, not yet the multiple/mixed depth-3 target shape.

Below that gate, runtime-validation artifacts are transaction-list driven
once coverage admits a shape:

- per-transaction expected-beat storage;
- per-transaction read-beat counter storage;
- request-time expected-beat/counter initialization rules;
- raw matched-read-beat counter increment rules;
- four beat-count/`RLAST` assertions per covered transaction;
- report fields for generated expected-beat storage, beat-count storage,
  beat-count rules, and beat-count assertions;
- removal of `generated_beat_count_validation` from `read_data.residue` only
  for generated runtime-validation shapes.

The one-group depth-3 runtime-validation precedent proves the depth-3
assertion contract. The multi-group depth-2 runtime-validation precedent proves
that the runtime-validation helpers already scale across more than one
queue-head group when the admission branch allows the transaction list.

## Candidate Comparison

Runtime beat-count/`RLAST` validation over the `.183` shape is the smallest
safe next audit:

- `.180` proves scalar last-beat read-data over depth `3,3` and `3,2` queue
  sets with no `burst_length`;
- `.183` proves report-only raw-`ARLEN` capture over the same queue sets;
- one-group depth-3 and multi-group depth-2 both follow the established
  sequence: no-`burst_length` scalar last-beat read-data, report-only
  raw-`ARLEN`, runtime validation, then multi-beat output-bank behavior;
- multi-beat payload over the multiple/mixed depth-3 groups needs generated
  runtime-validation state first because output-bank capture is indexed by the
  same beat-count machinery;
- write-family read-data remains a separate public-contract question because
  write responses do not carry `RDATA`;
- same-family mixed auto-ID plus concrete queue-head demux still needs
  allocator/queue interaction semantics;
- group-local simultaneous enqueue widening changes queue transition
  semantics and should not be mixed with beat-count validation;
- packed burst-vector outputs and alternate full burst assembly are output
  shape work beyond the current scalar and per-beat-bank models;
- verification-output generation is owned by the IAL1 verification-code
  frontier;
- direct backend, VHDL, and backend-language variants remain deferred until
  the SystemVerilog-backed IAL path is feature complete.

## Selected .185 Boundary

`.185` should audit generated beat-count/`RLAST` runtime validation over read
burst-last scalar last-beat read-data where every duplicate concrete `RID`
group has computed depth `2` or `3`, at least one group has depth `3`, and
the same transaction set is already generated by `.183` with report-only
raw-`ARLEN` burst-length metadata.

The audit should cover:

- read family only;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`/`RLAST`;
- generated read burst-last queue-head demux boundary
  `generated_read_burst_last_queue_head_demux`;
- `read-data.read.capture-scope last-beat`;
- `completion-source response-demux`;
- scalar `RDATA`/`RRESP` outputs;
- `read-data.read.burst-length` metadata with `source arlen`, signal width
  `8`, `encoding axlen-plus-one`, `capture request`, and `validation
  runtime-assertion`;
- two-depth-3 and mixed depth-3/depth-2 duplicate concrete `RID` groups;
- exact future public sample names, support-accounting entries, report
  expectations, generated-artifact expectations, tests, docs/book updates,
  rollback boundary, and preservation matrix.

`.185` must not enable multi-beat payload behavior, write-family read-data,
same-family mixed auto-ID plus concrete queue-head demux, group-local
simultaneous enqueue widening, packed burst-vector outputs, alternate burst
assembly, direct backend, verification-output generation, VHDL, or another
backend-language variant.

## Validation Gates For .185

The readiness audit should run compact schedule probes for the two `.183`
samples, one-group depth-3 runtime-validation and multi-beat samples,
multi-group depth-2 report-only/runtime-validation samples, and the `.180`
no-`burst_length` samples. It should inspect the local coverage gate,
transaction-list-driven beat-count helpers, generated-artifact/report helpers,
focused generator and PPIF/CLI expectations, public samples, support
accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map.
Temporary runtime-assertion candidates over depth `3,3` and `3,2` queue sets
may be probed in memory or under `/tmp` only.

Before commit, `.185` should run Knowledge Map generation/check, mdBook build,
docs relative-path audit, memory architecture check, diff hygiene, README
numbering, and stale/positive frontier scans. If it selects direct
implementation, the following implementation leaf should add the new public
samples, focused tests, support accounting, and HDL verification gates rather
than changing behavior inside the audit leaf.

## Rollback Boundary

Because `.184` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.185` must remain behavior-free unless it
selects a separately owned implementation leaf.
