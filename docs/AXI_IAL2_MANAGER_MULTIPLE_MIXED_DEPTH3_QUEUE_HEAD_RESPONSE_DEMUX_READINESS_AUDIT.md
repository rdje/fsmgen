# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.173` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.173`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.174`, direct bounded
implementation of generated multiple or mixed depth-3 concrete same-ID
queue-head response-demux for response-demux-only read single-beat, read
burst-last, and write families.

The next implementation can widen the local queue-head behavior admission
boundary for concrete duplicate-ID groups whose computed depth is `2` or `3`,
with at least one depth-3 group, while preserving the existing response-demux
family boundaries:

- `generated_read_single_beat_queue_head_demux`;
- `generated_read_burst_last_queue_head_demux`;
- `generated_write_bid_queue_head_demux`.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.172` selector and live probe evidence;
- the `.171` write depth-3 behavior and `.170` write depth-3 readiness audit;
- generated one-group depth-3 behavior for read single-beat, read burst-last,
  and write response-demux families;
- generated multi-group depth-2 behavior for read single-beat, read
  burst-last, and write response-demux families;
- same-ID issue-order queue admission, queue-state, transition, assertion,
  response-demux, report, and read-data coverage gates in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- focused generator and PPIF/CLI tests, public PPIF samples, support
  accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map
  surfaces.

## Live Probe Findings

Six temporary `/tmp` candidates were probed across the response-demux-only
families. All strict-check with zero diagnostics and no generated output,
remain unmatched by support accounting, and report selected queue-head
metadata while keeping `generated_same_id_queue_head_demux` residue:

```text
/tmp/fsmgen_ial2_read_single_beat_multi_depth3_probe.ppif
  family=read scope=single_beat
  generated=0 status=selected_not_generated
  queues=3:r0/r1/r2:d3,5:r3/r4/r5:d3
  residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts

/tmp/fsmgen_ial2_read_single_beat_mixed_depth3_depth2_probe.ppif
  family=read scope=single_beat
  generated=0 status=selected_not_generated
  queues=3:r0/r1/r2:d3,5:r3/r4:d2
  residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts

/tmp/fsmgen_ial2_read_burst_last_multi_depth3_probe.ppif
  family=read scope=burst_last
  generated=0 status=selected_not_generated
  queues=3:r0/r1/r2:d3,5:r3/r4/r5:d3
  residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts

/tmp/fsmgen_ial2_read_burst_last_mixed_depth3_depth2_probe.ppif
  family=read scope=burst_last
  generated=0 status=selected_not_generated
  queues=3:r0/r1/r2:d3,5:r3/r4:d2
  residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts

/tmp/fsmgen_ial2_write_multi_depth3_probe.ppif
  family=write
  generated=0 status=selected_not_generated
  queues=3:w0/w1/w2:d3,5:w3/w4/w5:d3
  residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts

/tmp/fsmgen_ial2_write_mixed_depth3_depth2_probe.ppif
  family=write
  generated=0 status=selected_not_generated
  queues=3:w0/w1/w2:d3,5:w3/w4:d2
  residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts
```

The existing preservation samples remain generated and support-accounted:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif
  boundary=generated_read_single_beat_queue_head_demux
  queue=3:r0/r1/r2:d3
  strict diagnostics=0 support_matched=1

ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  queue=3:r0/r1/r2:d3
  strict diagnostics=0 support_matched=1

ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
  boundary=generated_write_bid_queue_head_demux
  queue=3:w0/w1/w2:d3
  strict diagnostics=0 support_matched=1

ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  boundary=generated_read_single_beat_queue_head_demux
  queues=3:r0/r1:d2,5:r2/r3:d2
  strict diagnostics=0 support_matched=1

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  boundary=generated_read_burst_last_queue_head_demux
  queues=3:r0/r1:d2,5:r2/r3:d2
  strict diagnostics=0 support_matched=1

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  boundary=generated_write_bid_queue_head_demux
  queues=3:w0/w1:d2,5:w2/w3:d2
  strict diagnostics=0 support_matched=1
```

The temporary probes were deleted after inspection.

## Code Findings

The only direct generation blocker is the local shape admission test in
`_build_same_id_issue_order_queue_behavior`.

The current gate admits:

- one or more depth-2 groups for read single-beat, read burst-last, or write
  response-demux-only families;
- exactly one read single-beat depth-3 group;
- exactly one read burst-last depth-3 group;
- exactly one write depth-3 group.

It rejects multiple depth-3 groups and mixed depth-2/depth-3 group sets
because the three depth-3 predicates require `@$groups == 1`.

The downstream helpers are already group/depth driven:

- `_same_id_duplicate_concrete_groups` computes each duplicate concrete-ID
  group depth from its group size and family max-pending limit;
- queue storage, transition rules, update assignments, and assertion specs
  iterate each generated group and each group's local depth;
- response-demux state/rule/assertion helpers iterate all generated
  queue-head transactions across the selected family;
- report helpers list generated queues and generated response-demux artifacts
  per family.

The read-data coverage gate remains bounded separately. It can consume
generated read queue-head response-demux for one-or-more depth-2 groups or
exactly one depth-3 group, depending on read-data capture scope and
burst-length metadata. Therefore generating multiple/mixed depth-3
response-demux-only groups will not by itself enable read-data over those
groups.

## Selected .174 Boundary

`.174` should implement only response-demux-only concrete same-ID queue-head
groups where every selected duplicate concrete-ID group has computed depth `2`
or `3` and at least one group has depth `3`.

The bounded public samples should be:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
```

Expected support-accounting entries and coverage buckets should follow the
existing PPIF naming pattern, for example:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux
ial2_ppif_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux_pipeline_cli
```

and the corresponding names for the other five public samples.

Expected generated-artifact counts for the six public samples:

| Sample shape | Queue storage | Queue update rules | Queue assertions | Response-demux rules/completions | Response-demux assertions |
| --- | ---: | ---: | ---: | ---: | ---: |
| read single-beat two depth-3 groups | 18 | 108 | 28 | 6 | 16 |
| read single-beat mixed depth-3/depth-2 groups | 13 | 66 | 25 | 5 | 11 |
| read burst-last two depth-3 groups | 18 | 108 | 30 | 6 | 16 |
| read burst-last mixed depth-3/depth-2 groups | 13 | 66 | 27 | 5 | 11 |
| write two depth-3 groups | 18 | 108 | 28 | 6 | 16 |
| write mixed depth-3/depth-2 groups | 13 | 66 | 25 | 5 | 11 |

Expected report/residue behavior:

- `response_demux.generated_behavior = true`;
- selected family `implementation_status = generated`;
- selected family `generated_queue_behavior = 1`;
- selected family `generated_queue_behavior_boundary` is the family-specific
  boundary named above;
- generated completion signals cover every transaction in every generated
  queue group;
- `response_demux.residue` removes `generated_same_id_queue_head_demux`;
- write-family samples preserve `read_response_demux` residue.

Expected preservation matrix:

- existing one-group depth-3 read single-beat, read burst-last, and write
  samples remain generated and support-accounted;
- existing multi-group depth-2 read single-beat, read burst-last, and write
  samples remain generated and support-accounted;
- read-data, burst-length, runtime-validation, and multi-beat read-data samples
  keep their current boundaries and support accounting;
- mixed same-family auto-ID plus concrete queue-head demux remains rejected by
  the existing planner gate;
- groups deeper than depth 3 remain selected-not-generated.

`.174` should update focused generator and PPIF/CLI tests, public PPIF
samples, support-corpus accounting, regression-corpus documentation, README,
roadmap, mdBook, task tree, Memory, and Knowledge Map in the same slice.

`.174` must not enable read-data, burst-length, runtime-validation,
multi-beat payload, same-family mixed auto-ID plus concrete queue-head demux,
group-local simultaneous enqueue widening, packed outputs, alternate burst
assembly, direct backend, verification-output generation, VHDL, or another
backend-language variant.

## Validation Gates For .174

The implementation slice should run:

- syntax check for `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- focused generator and PPIF/CLI tests covering the six new public samples;
- strict schedule/check probes for the six new public samples;
- support-accounting and regression-corpus checks;
- preservation probes for the existing one-group depth-3 and multi-group
  depth-2 public samples;
- HDL verification for the new public samples where the surrounding tests use
  `--verify-hdl`;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene, README numbering, and stale/positive frontier scans.

## Rollback Boundary

Rollback for `.174` should revert the local admission widening, six public
PPIF samples, support-accounting entries, focused tests, generated behavior
documentation, mdBook updates, task-tree updates, Memory, and Knowledge Map
changes. It must preserve all behavior through `.171` and all `.173` audit
documentation.
