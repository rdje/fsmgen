# AXI IAL2 Manager Multi-Group Queue-Head Last-Beat Read-Data Readiness Audit

Status: selected next implementation slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.129`

Date: `2026-06-15`

## Purpose

This audit follows the `.128` selector and decides whether FSMGen can safely
enable scalar last-beat read-data capture over multiple generated read
burst-last concrete same-ID queue-head groups.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.130`:
generated multi-group queue-head last-beat read-data capture.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.128` selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.127` multi-group multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.126` multi-group read-data readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`
- `.124` multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.121` one-group queue-head multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- `.115` one-group queue-head last-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- current response-demux, same-ID queue, read-data coverage, report, and
  residue code in `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head and read-data PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.127` public sample proves residue-clean multi-group queue-head
multi-beat read-data:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
    - concrete_id: 5
      transactions: [r2, r3]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.beat_match_source:
    response_demux_matched_read_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.transactions: [r0, r1, r2, r3]
  read_data.read.generated_outputs: 140
  read_data.read.generated_rules: 84
  read_data.read.burst_length_source: arlen_signal
  read_data.read.burst_length_validation: runtime_assertion
  read_data.residue: []
  response_demux.residue: []
```

The `.124` public sample remains multi-group response-demux-only:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
    - concrete_id: 5
      transactions: [r2, r3]
      depth: 2
  read_data: absent
  response_demux.residue:
    read_data_interleaving
    bursts
```

The `.121` public sample preserves one-group queue-head multi-beat read-data:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.transactions: [r0, r1]
  read_data.read.generated_outputs: 70
  read_data.read.generated_rules: 42
  read_data.residue: []
  response_demux.residue: []
```

The `.115` public sample is the current scalar last-beat queue-head shape:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.transactions: [r0, r1]
  read_data.read.generated_outputs: 4
  read_data.read.generated_rules: 2
  read_data.read.burst_length_source: rlast_only
  read_data.read.burst_length_validation: not_generated
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
    arlen_or_beat_count_validation
```

A temporary `/tmp` probe combining the `.124` two-group response-demux shape
with scalar last-beat read-data bindings for `r0`, `r1`, `r2`, and `r3`
still fails closed at the current coverage guard:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice
```

That diagnostic is the intended current blocker.

## Code Findings

`_read_data_response_demux_transaction_coverage` already describes the scalar
last-beat and multi-beat queue-head boundaries separately. Both require
`response_scope burst_last` and
`generated_read_burst_last_queue_head_demux`, and both use
`generated_queue_head_response_demux_last_beat_completion_pulse` as the
read-data completion validity.

The only local blocker for scalar multi-group last-beat capture is this guard:
non-`multi-beat` queue-head read-data must have exactly one generated queue
group. Multi-beat queue-head read-data now permits one or more groups and
flattens each depth-2 group into transaction coverage.

The scalar downstream path is ready for the selected `.130` shape:

- output bindings are transaction-local `data_output` and `status_output`
  names;
- completion-signal mapping is already one generated completion pulse per
  covered transaction;
- generated read-data capture rules iterate normalized transactions;
- generated `RDATA`/`RRESP` inputs are shared across the read family and do
  not depend on group count;
- last-beat scalar reports already include `burst_length_source rlast_only`
  and `burst_length_validation not_generated` when no `burst_length` metadata
  is supplied.

The risky widening is specifically `last-beat` plus `burst_length` metadata.
If `.130` simply permits every `last-beat` queue-head read-data contract to
flatten multiple groups, it would also enable report-only raw-`ARLEN` and
runtime beat-count/`RLAST` validation variants. Those variants generate
extra per-transaction `ARLEN`, expected-count, beat-count, and assertion
artifacts and deserve their own owners. `.130` should therefore require the
selected scalar last-beat shape to have no `burst_length` metadata.

The multi-beat output-bank path must remain separately gated by
`capture_scope multi-beat`, runtime-assertion burst-length validation, output
prefixes, valid masks, length outputs, and scalar aggregation bindings.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.130`, generated multi-group
queue-head last-beat read-data capture.

The `.130` implementation boundary is:

- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at computed depth `2`;
- `read_data.read.capture_scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- no `read_data.read.burst_length` metadata;
- per-transaction scalar `data_output` and `status_output` bindings for every
  covered read transaction;
- flatten all selected generated queue groups into the read-data transaction
  coverage set, with one generated last-beat completion signal per
  transaction;
- emit generated `RDATA`/`RRESP` inputs, per-transaction last-beat
  data/status outputs, and scalar capture rules guarded by the existing
  generated queue-head last-beat completion pulses;
- report `completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse`, every
  covered transaction binding, generated scalar outputs/rules, and the scalar
  last-beat residue set;
- preserve `.115` one-group scalar last-beat behavior, `.121` one-group
  multi-beat behavior, `.124` multi-group response-demux-only behavior, and
  `.127` multi-group multi-beat behavior.

## Deferred Work

The following remain outside `.130`:

- report-only raw-`ARLEN` multi-group queue-head last-beat read-data;
- runtime beat-count/`RLAST` validation for multi-group queue-head last-beat
  read-data;
- multi-beat output-bank variants beyond `.127`;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .130

The implementation slice should run:

- syntax checks for every touched Perl module and test;
- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- direct schedule, strict check JSON, strict semantic JSON, and `--verify-hdl`
  probes for a new public multi-group queue-head last-beat read-data sample;
- preservation probes for `.115` one-group queue-head last-beat read-data,
  `.121` one-group queue-head multi-beat read-data, `.124`
  response-demux-only multi-group queue-head behavior, and `.127`
  multi-group queue-head multi-beat read-data;
- negative probes confirming report-only raw-`ARLEN` and runtime-validation
  multi-group last-beat variants remain outside `.130`;
- support-accounting catalog/check/semantic corpus gates if a new public
  sample is added;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.129` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.
