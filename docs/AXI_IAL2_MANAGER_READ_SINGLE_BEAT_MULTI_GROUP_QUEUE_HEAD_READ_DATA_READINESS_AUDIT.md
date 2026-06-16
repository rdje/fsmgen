# AXI IAL2 Manager Read Single-Beat Multi-Group Queue-Head Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.145` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.145`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.146`, implementation of generated
read-data over read single-beat multi-group queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.144` selector note:
  `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.143` read single-beat multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.113` one-group single-beat queue-head read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.127` multi-group multi-beat queue-head read-data behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.130`, `.132`, and `.135` scalar burst-last multi-group read-data behavior,
  burst-length, and runtime-validation notes
- current read-data coverage, capture, report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- PPIF read-data parser syntax in `perl/FSM/Adapter/IAL2/PPIF.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public PPIF samples, support accounting, README, roadmap, mdBook, task tree,
  Memory, and Knowledge Map fact cards.

## Live Report Probes

The shipped `.143` sample is generated response-demux-only:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  boundary=generated_read_single_beat_queue_head_demux
  scope=single_beat
  queues=2
  completions=4
  read_data=absent
```

The shipped one-group single-beat queue-head read-data sample is generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
  boundary=generated_read_single_beat_queue_head_demux
  scope=single_beat
  queues=1
  completions=2
  read_data_completion=generated_queue_head_response_demux_completion_pulse
  tx=2
```

The shipped multi-group burst-last multi-beat read-data sample remains
residue-clean:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  boundary=generated_read_burst_last_queue_head_demux
  scope=burst_last
  queues=2
  completions=4
  read_data_completion=generated_queue_head_response_demux_last_beat_completion_pulse
  output_shape=per_beat_output_bank
  tx=4
  residue=[]
```

Check JSON and semantic JSON decoded successfully for all three samples.

## Temporary Future-Shape Probe

A temporary `/tmp/fsmgen_ial2_145_read_single_multi_group_read_data_probe.ppif`
source was derived from the `.143` public sample by adding scalar single-beat
`read-data` bindings for `r0`, `r1`, `r2`, and `r3`.

The probe failed closed at the current expected boundary:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice
```

The temporary probe was removed after use.

## Code Findings

The current blocker is local to
`_read_data_response_demux_transaction_coverage`. For generated queue-head
read-data:

- `capture_scope single-beat` requires
  `generated_read_single_beat_queue_head_demux` and currently rejects more than
  one depth-2 queue group;
- `capture_scope last-beat` and `multi-beat` use
  `generated_read_burst_last_queue_head_demux` and already support selected
  one-or-more depth-2 queue-group shapes;
- completion validity for the single-beat queue-head path is already
  `generated_queue_head_response_demux_completion_pulse`;
- generated completion signals are already mapped one-for-one to queue-head
  transactions.

The parser already accepts scalar single-beat read-data transaction bindings.
The existing single-beat capture rules are transaction-local and guard scalar
`RDATA`/`RRESP` assignments by each normalized transaction completion signal.
The `.143` response-demux-only behavior already emits completion pulses for
all transactions across multiple single-beat queue groups.

No new PPIF syntax, IAL1 feature, IAL0/SystemVerilog lowerer, direct-backend,
or VHDL prerequisite is required before the bounded behavior slice.

## Selected .146 Boundary

The implementation owner should be bounded to:

- read family only;
- `response-demux.read` response-scope `single-beat`;
- generated queue-head response-demux boundary
  `generated_read_single_beat_queue_head_demux`;
- two or more duplicate concrete read-ID groups in one manager object;
- every generated queue group exactly two read transactions at computed depth
  `2`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- scalar single-beat `RDATA`/`RRESP` capture bindings for every covered
  transaction;
- `completion_validity:
  generated_queue_head_response_demux_completion_pulse`;
- support-accounted public PPIF sample derived from the `.143` shape with
  read-data bindings for `r0` through `r3`;
- report/residue support prose that removes only the now-covered
  read-data-over-multiple-read-single-beat queue-head residue.

## Diagnostics To Preserve

`.146` must preserve fail-closed diagnostics for:

- partial read-data transaction coverage;
- read-data bindings for transactions not covered by generated queue-head
  response-demux;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- missing generated completion signal metadata;
- unsupported last-beat/multi-beat widening outside already shipped
  burst-last owners;
- write-family read-data and direct backend/VHDL assumptions.

## Validation Gates For .146

The implementation slice should run:

- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- support-accounting checks, including the new public sample entry;
- direct schedule/check/semantic JSON probes for the new sample;
- generated HDL and `--verify-hdl` probes when Verilator/Yosys are available
  or guarded skips when they are not;
- preservation probes for `.143`, `.113`, `.127`, `.130`, `.132`, `.135`, and
  `.140`;
- mdBook build, Knowledge Map generation/check, memory architecture check,
  diff hygiene, README/roadmap/task-tree sync, and commit workflow gates.

## Rollback Boundary

Because `.145` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.146` must keep behavior changes narrowly
scoped to the generated single-beat queue-head read-data coverage boundary.
