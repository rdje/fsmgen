# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.176` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.176`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.177`, direct bounded
implementation of generated read single-beat scalar read-data over multiple
or mixed depth-3 concrete same-ID queue-head groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.175` selector and temporary probe evidence;
- the `.174` generated multiple/mixed depth-3 queue-head response-demux
  behavior and `.173` readiness audit;
- shipped one-group depth-3 read single-beat read-data behavior;
- shipped multi-group depth-2 read single-beat read-data behavior;
- current `_read_data_response_demux_transaction_coverage`, read-data
  normalization, generated-artifact, report, focused-test,
  support-accounting, README, roadmap, mdBook, task-tree, Memory, and
  Knowledge Map surfaces.

## Live Probe Findings

The adjacent public samples are already generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
  queues=3:r0/r1:d2,5:r2/r3:d2
  read_data_generated=1
  transactions=r0/r1/r2/r3
  read_data.residue=rlast_completion,bursts,multi_beat_read_data_reassembly

ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
  queue=3:r0/r1/r2:d3
  read_data_generated=1
  transactions=r0/r1/r2
  read_data.residue=rlast_completion,bursts,multi_beat_read_data_reassembly
```

Two temporary `/tmp` read single-beat candidates failed closed at the current
single-beat read-data coverage gate:

```text
/tmp/fsmgen_ial2_read_single_beat_multi_depth3_read_data_probe.ppif
  shape=two depth-3 RID groups
  diagnostic=queue-head single-beat coverage requires one or more depth-2
    concrete same-ID read queue groups or exactly one depth-3 concrete
    same-ID read queue group in this slice

/tmp/fsmgen_ial2_read_single_beat_mixed_depth3_depth2_read_data_probe.ppif
  shape=one depth-3 RID group plus one depth-2 RID group
  diagnostic=queue-head single-beat coverage requires one or more depth-2
    concrete same-ID read queue groups or exactly one depth-3 concrete
    same-ID read queue group in this slice
```

The temporary probes were deleted after inspection.

## Code Findings

The blocker for the selected first payload slice is local to
`_read_data_response_demux_transaction_coverage`.

For `capture_scope single-beat`, that helper already:

- confirms the response-demux boundary is
  `generated_read_single_beat_queue_head_demux`;
- accepts one-or-more depth-2 read queue-head groups;
- accepts exactly one depth-3 read queue-head group;
- flattens each accepted group's transactions into a transaction list;
- maps generated completion signals by transaction name.

The remaining depth-3 restriction is the exact-one-group
`$single_beat_depth3_coverage` predicate. After coverage admits a transaction
list, read-data normalization, generated artifact enumeration, report
projection, and focused test helpers are transaction-list driven. They already
handle both four-transaction depth-2 multi-group read-data and three-transaction
depth-3 one-group read-data.

## Candidate Comparison

Read single-beat scalar read-data over multiple/mixed depth-3 groups is the
smallest safe implementation owner:

- it reuses the `.174` generated read single-beat response-demux groups;
- it reuses the shipped scalar `RDATA`/`RRESP` read-data substrate;
- it needs no `RLAST`, burst-length, runtime-validation, multi-beat output
  bank, scalar `RRESP` aggregation, or burst payload assembly work.

Read burst-last scalar last-beat read-data over multiple/mixed depth-3 groups
is adjacent but adds `RLAST` and burst-length metadata variants. Multi-beat
output-bank behavior adds runtime beat-count validation and per-beat output
arrays. Same-family mixed auto-ID plus concrete queue-head demux still needs
allocator/queue interaction semantics. Group-local simultaneous enqueue
widening changes the admission and transition model. Packed burst-vector
outputs and alternate full-burst assembly are separate output-shape work.
Verification-output generation is owned by the IAL1 verification-code
frontier. Direct backend and VHDL/backend-language variants remain deferred
until the SystemVerilog-backed IAL path is feature complete.

## Selected .177 Boundary

`.177` should implement only read single-beat scalar `RDATA`/`RRESP`
read-data over generated read single-beat concrete same-ID queue-head
response-demux groups where every selected duplicate concrete `RID` group has
computed depth `2` or `3` and at least one group has depth `3`.

The bounded public samples should be:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif
ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
```

Expected support-accounting entries and coverage buckets should follow the
existing naming pattern:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data
intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data
ial2_ppif_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_pipeline_cli
```

Expected generated-artifact behavior:

- the two-depth-3 sample covers `r0`/`r1`/`r2` and `r3`/`r4`/`r5`, generates
  six read-data capture rules, and emits 12 scalar data/status outputs;
- the mixed sample covers `r0`/`r1`/`r2` and `r3`/`r4`, generates five
  read-data capture rules, and emits 10 scalar data/status outputs;
- both samples preserve `generated_read_single_beat_queue_head_demux`,
  `completion_validity: generated_queue_head_response_demux_completion_pulse`,
  and `read_data.residue` of `rlast_completion`, `bursts`, and
  `multi_beat_read_data_reassembly`.

Expected preservation matrix:

- existing read single-beat depth-2 one-group, depth-2 multi-group, and
  one-depth-3 read-data samples remain generated and support-accounted;
- `.174` response-demux-only multiple/mixed depth-3 samples remain generated
  and support-accounted;
- read burst-last last-beat read-data, burst-length, runtime-validation,
  multi-beat output-bank, write-family response-demux, and existing HDL
  verification behavior remain unchanged.

`.177` must not enable read burst-last read-data over multiple/mixed depth-3
groups, burst-length, runtime-validation, multi-beat payload, write-family
read-data, same-family mixed auto-ID plus concrete queue-head demux,
group-local simultaneous enqueue widening, packed burst-vector outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, or another backend-language variant.

## Validation Gates For .177

The implementation should run syntax checks for the touched Perl modules and
focused tests, direct schedule/check/semantic/verify-HDL probes for the two
new public samples, preservation probes for existing single-beat read-data and
`.174` response-demux samples, focused generator and PPIF/CLI tests,
regression-corpus accounting, Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, diff hygiene, README numbering,
and stale/positive frontier scans.

## Rollback Boundary

Because `.176` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.177` owns the future behavior change and must
keep its implementation localized to read single-beat scalar read-data
coverage unless its own evidence selects a smaller prerequisite first.
