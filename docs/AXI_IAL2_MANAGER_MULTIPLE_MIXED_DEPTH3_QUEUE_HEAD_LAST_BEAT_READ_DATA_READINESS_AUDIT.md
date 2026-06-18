# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Last-Beat Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.179` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.179`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.180`, direct bounded
implementation of generated read burst-last scalar last-beat `RDATA`/`RRESP`
over multiple or mixed depth-3 concrete same-ID queue-head groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, validation, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.178` selector and temporary probe evidence;
- `.177` generated multiple/mixed depth-3 read single-beat read-data behavior;
- `.176` multiple/mixed depth-3 read-data readiness audit;
- `.174` generated multiple/mixed depth-3 response-demux behavior;
- shipped one-group depth-3 read burst-last last-beat read-data,
  burst-length, runtime-validation, and multi-beat behavior notes;
- current `_read_data_response_demux_transaction_coverage`, read-data
  normalization, generated-artifact, report, focused-test, PPIF/CLI,
  public-sample, support-accounting, README, roadmap, mdBook, task-tree,
  Memory, and Knowledge Map surfaces.

## Live Probe Findings

The adjacent `.177` single-beat read-data samples are generated over the same
queue-depth sets:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif
  boundary=generated_read_single_beat_queue_head_demux
  scope=single_beat
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  read_data_generated=1
  capture=single_beat
  completion=generated_queue_head_response_demux_completion_pulse
  outputs=12
  rules=6
  residue=rlast_completion,bursts,multi_beat_read_data_reassembly

ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
  boundary=generated_read_single_beat_queue_head_demux
  scope=single_beat
  groups=3:3:r0,r1,r2;5:2:r3,r4
  read_data_generated=1
  capture=single_beat
  completion=generated_queue_head_response_demux_completion_pulse
  outputs=10
  rules=5
  residue=rlast_completion,bursts,multi_beat_read_data_reassembly
```

The target read burst-last multiple/mixed depth-3 response-demux-only samples
are already generated:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  scope=burst_last
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  generated=1
  read_data_present=0

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  scope=burst_last
  groups=3:3:r0,r1,r2;5:2:r3,r4
  generated=1
  read_data_present=0
```

The one-group depth-3 read burst-last scalar read-data sibling is already
generated:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
  boundary=generated_read_burst_last_queue_head_demux
  scope=burst_last
  groups=3:3:r0,r1,r2
  read_data_generated=1
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  outputs=6
  rules=3
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation
```

Two temporary `/tmp` candidates added only scalar last-beat read-data bindings
to the response-demux-only multiple/mixed depth-3 samples. Both fail closed at
the current local last-beat coverage gate:

```text
/tmp/fsmgen-ial2-179-burst-last-multi-depth3-read-data.ppif
  shape=two depth-3 RID groups
  diagnostic=queue-head last-beat coverage requires one or more depth-2
    concrete same-ID read queue groups with no burst_length metadata,
    report-only burst_length metadata, or runtime-assertion burst_length
    metadata, or exactly one depth-3 concrete same-ID read queue group with
    no burst_length metadata, report-only burst_length metadata, or
    runtime-assertion burst_length metadata in this slice

/tmp/fsmgen-ial2-179-burst-last-mixed-depth3-depth2-read-data.ppif
  shape=one depth-3 RID group plus one depth-2 RID group
  diagnostic=the same queue-head last-beat coverage diagnostic
```

## Code Findings

The blocker for the selected next behavior is local to
`_read_data_response_demux_transaction_coverage`.

For `capture_scope last-beat`, the helper already:

- confirms the response-demux boundary is
  `generated_read_burst_last_queue_head_demux`;
- requires `response_scope burst_last`;
- assigns completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- accepts one-or-more depth-2 concrete same-ID read queue-head groups with no
  `burst_length`, report-only `burst_length`, or runtime-assertion
  `burst_length` metadata;
- accepts exactly one depth-3 concrete same-ID read queue-head group for those
  same metadata variants;
- flattens each accepted group's transactions into one transaction list;
- maps generated completion signals by transaction name.

It does not yet admit multiple depth-3 groups or mixed depth-3/depth-2 groups
for last-beat scalar read-data. The adjacent single-beat branch already has
the required "all groups are depth 2 or 3 and at least one group is depth 3"
predicate.

Downstream scalar read-data generation is already transaction-list driven:

- `_read_data_source_inputs` emits `RDATA` and `RRESP` for scalar capture;
- `_read_data_output_lines` emits one data/status output pair per transaction;
- `_read_data_capture_rule_lines` emits one capture rule per transaction,
  guarded by that transaction's generated completion signal;
- `_read_data_generated_artifacts` reports generated inputs, outputs, and
  rules from the same transaction list;
- `_report_read_data` projects those generated artifacts without checking
  queue depth;
- focused report helpers already accept variable last-beat transaction lists.

Therefore the direct implementation can stay local to the no-`burst_length`
last-beat read-data coverage predicate plus public samples, support accounting,
focused expectations, and documentation.

## Candidate Comparison

Read burst-last scalar last-beat read-data over multiple/mixed depth-3 groups
is the smallest safe implementation owner:

- `.174` already generates the matching read burst-last response-demux groups;
- `.159` proves one-group depth-3 scalar last-beat read-data over the same
  `generated_read_burst_last_queue_head_demux` boundary;
- `.177` proves transaction-list widening over multiple/mixed depth-3 groups;
- downstream scalar read-data artifacts and reports are not depth-specific.

Report-only raw-`ARLEN` burst-length and runtime-validation variants over the
same groups should follow only after no-`burst_length` scalar last-beat
read-data is generated. Multi-beat output-bank behavior adds per-beat payload
and status aggregation. Write-family read-data is a separate family question.
Same-family mixed auto-ID plus concrete queue-head demux still needs allocator
and queue interaction semantics. Group-local simultaneous enqueue widening
changes admission and transition behavior. Packed burst-vector outputs and
alternate full burst assembly are separate output-shape work.
Verification-output generation remains owned by the IAL1 verification-code
frontier. Direct backend and VHDL/backend-language variants remain deferred
until the SystemVerilog-backed IAL path is feature complete.

## Selected .180 Boundary

`.180` should implement only read burst-last scalar last-beat `RDATA`/`RRESP`
capture over generated read burst-last concrete same-ID queue-head
response-demux groups where every selected duplicate concrete `RID` group has
computed depth `2` or `3` and at least one group has depth `3`.

The bounded public samples should be:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
```

Expected support-accounting entries and coverage buckets should follow the
existing naming pattern:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data
ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_pipeline_cli
```

Expected generated-artifact behavior:

- the two-depth-3 sample covers `r0`/`r1`/`r2` and `r3`/`r4`/`r5`, generates
  six read-data capture rules, and emits 12 scalar last-beat data/status
  outputs;
- the mixed sample covers `r0`/`r1`/`r2` and `r3`/`r4`, generates five
  read-data capture rules, and emits 10 scalar last-beat data/status outputs;
- both samples preserve `generated_read_burst_last_queue_head_demux`,
  `completion_validity` of
  `generated_queue_head_response_demux_last_beat_completion_pulse`, one-bit
  `RLAST`-guarded completion, and `read_data.residue` of
  `multi_beat_read_data_reassembly`, `per_beat_outputs`, `rresp_aggregation`,
  and `arlen_or_beat_count_validation`.

Expected preservation matrix:

- existing depth-2 one-group and multi-group last-beat read-data samples remain
  generated and support-accounted;
- existing one-group depth-3 read burst-last last-beat read-data,
  burst-length, runtime-validation, and multi-beat samples remain generated
  and support-accounted;
- existing `.174` response-demux-only multiple/mixed depth-3 samples remain
  generated and support-accounted;
- `.177` single-beat multiple/mixed depth-3 read-data samples remain
  generated and support-accounted;
- write queue-head response-demux samples and existing HDL verification
  behavior remain unchanged.

`.180` must not enable burst-length, runtime-validation, multi-beat payload,
write-family read-data, same-family mixed auto-ID plus concrete queue-head
demux, group-local simultaneous enqueue widening, packed burst-vector outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, or another backend-language variant.

## Validation Gates For .180

The implementation should run syntax checks for touched Perl modules and
focused tests, direct schedule/check/semantic/verify-HDL probes for the two
new public samples, preservation probes for existing depth-2 last-beat
read-data, one-group depth-3 last-beat read-data, `.174` response-demux-only
multiple/mixed depth-3 samples, and `.177` single-beat read-data samples,
focused generator and PPIF/CLI tests, regression-corpus accounting, Knowledge
Map generation/check, mdBook build, docs path audit, memory architecture
check, diff hygiene, README numbering, and stale/positive frontier scans.

## Rollback Boundary

Because `.179` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.180` owns the future behavior change and must
keep implementation localized to no-`burst_length` scalar last-beat read-data
coverage unless its own evidence selects a smaller prerequisite first.
