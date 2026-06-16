# AXI IAL2 Manager Post Multi-Group Queue-Head Runtime Validation Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.136` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`

## Context

`IAL2-FEATURE-COMPLETENESS-FRONTIER.135` shipped generated
runtime-validation multi-group queue-head scalar last-beat read-data for:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

The shipped report confirms the behavior:

- `read_data.read.capture_scope: last_beat`
- `read_data.read.burst_length_validation: runtime_assertion`
- two generated depth-2 concrete same-ID read queue groups
- generated raw-`ARLEN` storage, expected-beat storage, read-beat counters,
  initialization/increment rules, and beat-count/`RLAST` assertions for
  `r0`, `r1`, `r2`, and `r3`
- `read_data.residue: multi_beat_read_data_reassembly, per_beat_outputs,
  rresp_aggregation`

The preservation probes also confirm the prior siblings remain intact:

- `.132` report-only raw-`ARLEN` multi-group scalar capture still reports
  `generated_beat_count_validation` residue;
- `.130` no-`burst_length` multi-group scalar capture still omits `axi0_arlen`;
- `.127` multi-group multi-beat output-bank behavior remains residue-clean;
- `.124` response-demux-only multi-group behavior still has no `read_data`
  section; and
- `.119` one-group scalar runtime validation keeps the two-transaction
  boundary.

## Finding

The next safest exact owner is report/static residue cleanup, not a broader
behavior expansion.

The live `.135` schedule report proves the runtime-validation behavior is
generated, but the AXI ID/order unsupported-residue detail still says
`runtime-validation last-beat read-data over multiple queue groups` remains
outside the shell. That phrase is now stale after `.135`.

The focused PPIF/parser assertion currently preserves the stale phrase:

```text
like($id_residue->{detail},
  qr/runtime-validation last-beat read-data over multiple queue groups/,
  "$owner keeps runtime-validation multi-group scalar last-beat residue prose");
```

This is documentation/report drift. It does not require parser, generator,
sample, support-accounting, generated-artifact, or HDL behavior changes.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.137`, AXI manager report/static
residue cleanup after generated runtime-validation multi-group queue-head
scalar last-beat read-data.

The `.137` implementation boundary is:

- update the capability/report static support detail so generated
  runtime-validation multi-group queue-head scalar last-beat read-data is
  described as supported, not residue;
- update focused PPIF/parser assertions to reject the stale runtime-validation
  multi-group scalar residue phrase;
- preserve live schedule behavior for `.135`, `.132`, `.130`, `.127`, `.124`,
  and `.119`;
- do not broaden deeper queues, same-family mixed auto-ID plus concrete
  queue-head demux, write-family multi-group queue-head behavior, read
  single-beat multi-group queue-head behavior, group-local enqueue semantics,
  packed burst-vector outputs, alternate payload assembly, direct backend
  lowering, VHDL backend behavior, parser syntax, support-accounting samples,
  generated artifacts, or HDL behavior.

## Deferred Outside .137

The following remain future exact-owner work:

- deeper concrete same-ID queue groups;
- same-family mixed `auto_id_lifecycle` plus concrete queue-head demux;
- write-family multi-group queue-head behavior;
- read single-beat multi-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL backend and reroute behavior.

## Validation Gates For .137

The selected implementation should run:

- syntax checks for touched Perl/test files;
- focused PPIF/parser test coverage for the static support detail;
- compact live schedule probes for `.135`, `.132`, `.130`, `.127`, `.124`,
  and `.119` samples;
- a stale-phrase scan proving the retired runtime-validation multi-group
  residue wording is absent from code/tests/docs that describe current
  support;
- mdBook, README, roadmap, task-tree, Memory, and Knowledge Map sync; and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.136` task-tree/log updates, live-doc references, Memory, and
Knowledge Map updates. It does not change parser, generator, PPIF sample,
support-accounting, generated artifact, or HDL behavior.
