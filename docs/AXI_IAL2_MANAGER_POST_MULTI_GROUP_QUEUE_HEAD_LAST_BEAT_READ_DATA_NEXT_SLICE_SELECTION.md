# AXI IAL2 Manager Post Multi-Group Queue-Head Last-Beat Read-Data Next Slice Selection

Status: selected next slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.131`

Date: `2026-06-15`

## Purpose

This selector follows `.130`, generated scalar last-beat `RDATA`/`RRESP`
capture for multiple generated read burst-last concrete same-ID queue-head
groups, and chooses the next exact AXI manager feature-completeness owner.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.132`:
generated report-only raw-`ARLEN` burst-length capture for multi-group
queue-head scalar last-beat read-data.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.130` behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- `.129` readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md`
- `.127` multi-group multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.124` multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.121` one-group queue-head multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- `.117` one-group queue-head report-only raw-`ARLEN` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`
- `.119` one-group queue-head runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- current response-demux, same-ID queue, read-data coverage, burst-length,
  report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head and read-data PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.130` public sample is the current scalar multi-group shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
    - concrete_id: 5
      transactions: [r2, r3]
      depth: 2
  read_data.read.capture_scope: last_beat
  read_data.read.burst_length_source: rlast_only
  read_data.read.burst_length_validation: not_generated
  read_data.read.transactions: [r0, r1, r2, r3]
  read_data.read.generated_outputs: 8
  read_data.read.generated_rules: 4
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
    arlen_or_beat_count_validation
```

The `.117` one-group queue-head report-only raw-`ARLEN` sample shows the
artifact family that should be generalized next:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
  read_data.read.capture_scope: last_beat
  read_data.read.burst_length_source: arlen_signal
  read_data.read.burst_length_validation: report_only
  generated_burst_length_inputs: [axi0_arlen]
  generated_burst_length_storage:
    [axi0_r0_arlen_q, axi0_r1_arlen_q]
  generated_burst_length_rules:
    [axi0_r0_burst_length_capture, axi0_r1_burst_length_capture]
  read_data.residue:
    generated_beat_count_validation
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
```

The `.119` one-group queue-head runtime-validation sample adds expected-beat
storage, beat-count storage, beat-count rules, and assertions:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.generated_rules: 8
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
```

The `.127` multi-group multi-beat sample already proves that raw-`ARLEN`
capture artifacts can be generated for `r0`, `r1`, `r2`, and `r3` when the
selected shape is multi-beat output-bank capture.

## Code Findings

The `.130` implementation intentionally permits multiple generated queue-head
groups for scalar `capture_scope last-beat` only when `burst_length` metadata
is absent. Any multi-group scalar shape with `burst_length` metadata still
uses the exact-one-group diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head coverage
requires exactly one depth-2 concrete same-ID read queue group in this slice
```

Raw-`ARLEN` capture is a smaller next owner than runtime validation:

- the report-only path generates only the shared `axi0_arlen` input, one raw
  `ARLEN` storage register per covered transaction, and one request-guarded
  capture rule per covered transaction;
- the existing storage/rule generation already iterates over covered
  transactions and has proven four-transaction output in the `.127`
  multi-group multi-beat sample;
- runtime validation additionally requires expected-beat storage, beat-count
  storage, matched-read-beat count rules, and bound/over-count/early-`RLAST`/
  missing-final-`RLAST` assertions for every covered transaction.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.132`, generated report-only
raw-`ARLEN` burst-length capture for multi-group queue-head scalar last-beat
read-data.

The `.132` implementation boundary is:

- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at computed depth `2`;
- `read_data.read capture_scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- `burst_length` metadata with `source arlen`, signal width `8`, `encoding
  axlen-plus-one`, `capture request`, and `validation report-only`;
- complete per-transaction scalar `data_output` and `status_output` bindings
  for every covered transaction;
- generated raw-`ARLEN` input, per-transaction raw-`ARLEN` storage, and
  per-transaction request-guarded capture rules for all covered transactions;
- preserve `.130` no-`burst_length` scalar multi-group behavior, `.127`
  multi-group multi-beat behavior, `.124` response-demux-only behavior, and
  `.115` / `.117` / `.119` one-group scalar queue-head behavior;
- at selection time, keep runtime-validation multi-group scalar behavior, deeper queues,
  same-family mixed auto-ID plus concrete queue-head demux, write/read
  single-beat multi-group behavior, packed outputs, direct backend, and VHDL
  deferred.

## Why This Slice

Report-only raw-`ARLEN` capture is the smallest useful expansion after `.130`.
It keeps the scalar last-beat payload/status behavior and queue topology
unchanged while proving the multi-group burst-length artifact surface for all
covered transactions. It also leaves runtime beat-count/`RLAST` assertions as
a clean follow-up owner after raw-`ARLEN` storage and reporting are verified;
that follow-up was later shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.135`.

## Validation Gates For .132

The implementation slice should run:

- focused syntax checks for the touched Perl module, support catalog, and
  tests;
- generator and PPIF/CLI coverage for a new public support-accounted
  multi-group scalar last-beat report-only raw-`ARLEN` PPIF sample;
- direct schedule/check/semantic/HDL probes for the new sample;
- preservation probes for `.130`, `.127`, `.124`, `.117`, `.119`, and `.115`
  samples;
- a negative runtime-validation multi-group scalar probe that remained
  fail-closed until a later owner selected it;
- support-accounting corpus gates if a new sample is added;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, stale `.132` active
  scan, stale `.133` done scan, and positive `.133` frontier scan.

## Rollback Boundary

Because `.131` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.

## Deferred Work

The following remained outside `.131` and `.132` at selection time:

- deeper concrete same-ID issue-order queues;
- same-family mixed auto-ID plus concrete queue-head demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
