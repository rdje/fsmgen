# AXI IAL2 Manager Multi-Group Queue-Head Runtime-Validation Readiness Audit

Status: selected next implementation slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.134`

Date: `2026-06-15`

## Purpose

This audit follows the `.133` selector and decides whether FSMGen can safely
enable generated beat-count/`RLAST` runtime validation for multi-group
queue-head scalar last-beat read-data.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.135`:
generated runtime-validation multi-group queue-head scalar last-beat
read-data.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.133` selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`
- `.132` report-only raw-`ARLEN` multi-group scalar behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`
- `.131` report-only raw-`ARLEN` selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.130` no-`burst_length` multi-group scalar behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- `.127` multi-group multi-beat runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.124` multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.119` one-group scalar runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- current response-demux, same-ID queue, read-data normalization,
  beat-count/`RLAST` validation, report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head and read-data PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.132` public sample proves report-only raw-`ARLEN` capture over multiple
queue-head groups:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif
  read_data.read.capture_scope: last_beat
  read_data.read.burst_length_validation: report_only
  read_data.read.transactions: [r0, r1, r2, r3]
  read_data.read.burst_length_capture_rules:
    axi0_r0_burst_length_capture
    axi0_r1_burst_length_capture
    axi0_r2_burst_length_capture
    axi0_r3_burst_length_capture
  read_data.residue:
    generated_beat_count_validation
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
```

The `.119` public sample proves scalar queue-head runtime validation for one
generated queue group:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  read_data.read.capture_scope: last_beat
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.transactions: [r0, r1]
  r0 expected/counter:
    axi0_r0_expected_beats_q
    axi0_r0_read_beat_count_q
  r1 expected/counter:
    axi0_r1_expected_beats_q
    axi0_r1_read_beat_count_q
  per-transaction assertions:
    *_arlen_within_max
    *_read_beat_before_expected_count
    *_rlast_on_expected_beat
    *_expected_final_beat_has_rlast
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation
```

The `.127` public sample proves the same runtime-validation artifact family
already iterates over multiple queue groups in the multi-beat output-bank
shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  read_data.read.capture_scope: multi_beat
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.transactions: [r0, r1, r2, r3]
  expected/counter storage:
    axi0_r0_expected_beats_q / axi0_r0_read_beat_count_q
    axi0_r1_expected_beats_q / axi0_r1_read_beat_count_q
    axi0_r2_expected_beats_q / axi0_r2_read_beat_count_q
    axi0_r3_expected_beats_q / axi0_r3_read_beat_count_q
  read_data.residue: []
```

A temporary `/tmp` probe made by changing the `.132` support-accounted sample
from `(validation report-only)` to `(validation runtime-assertion)` still
fails closed at the current scalar runtime-validation boundary:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice
```

That diagnostic is the intended current blocker before `.135`.

## Code Findings

`_read_data_response_demux_transaction_coverage` is the only known local
admission blocker for the selected behavior. It already accepts multiple
queue-head groups for:

- `capture_scope multi-beat`; and
- scalar `capture_scope last-beat` when `burst_length` metadata is absent or
  `burst_length_validation` is `report_only`.

It still rejects scalar `capture_scope last-beat` with
`burst_length_validation runtime_assertion` unless exactly one generated
depth-2 concrete same-ID read queue group is present.

The downstream runtime-validation machinery is already transaction-iterative:

- read-data normalization names `expected_beat_count_storage`,
  `beat_count_storage`, `beat_count_init_rule`,
  `beat_count_increment_rule`, and four beat-count/`RLAST` assertions per
  normalized transaction;
- raw `ARLEN` capture rules are driven from each transaction's read request
  event, preserving request-time capture semantics;
- beat-count initialization stores `ARLEN + 1` and clears the counter on the
  same request event;
- beat-count increments are guarded by the response-demux matched read beat
  and `!request_event`, preserving the existing same-cycle request/response
  boundary;
- `_read_data_response_states_by_transaction` and
  `_read_data_matched_read_beat_expr` map each read transaction to its
  queue-head response-demux state, so runtime checks use queue-head identity
  rather than only family-level `RID`; and
- `_read_data_beat_count_assertion_specs` already emits the four assertion
  conditions for every normalized transaction.

The `.135` implementation can therefore be a bounded admission widening plus
tests, samples, support accounting, report/residue updates, and documentation.
No new IAL1, IAL0, SystemVerilog, direct-backend, or VHDL prerequisite is
evident from this audit.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.135`, generated
runtime-validation multi-group queue-head scalar last-beat read-data.

The `.135` implementation boundary is:

- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at computed depth `2`;
- `read_data.read.capture_scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- `burst_length` metadata with `source arlen`, `encoding axlen-plus-one`,
  `capture request`, bounded `max-beats`, and
  `validation runtime-assertion`;
- per-transaction scalar `data_output` and `status_output` bindings for every
  covered read transaction;
- generated raw-`ARLEN` storage and request-guarded capture for every covered
  transaction;
- generated expected-beat storage, read-beat counters, initialization rules,
  matched-beat increment rules, and the four beat-count/`RLAST` assertions for
  every covered transaction;
- scalar read-data capture rules still guarded by generated queue-head
  last-beat completion pulses;
- report `burst_length_validation: runtime_assertion`, generated
  beat-count-validation artifact fields, and remove
  `generated_beat_count_validation` from `read_data.residue` for the bounded
  sample while leaving multi-beat output-bank, per-beat output, and scalar
  `RRESP` aggregation residue intact; and
- preserve `.132` report-only raw-`ARLEN` multi-group scalar behavior, `.130`
  no-`burst_length` multi-group scalar behavior, `.127` multi-group multi-beat
  behavior, `.124` response-demux-only multi-group behavior, and `.119`
  one-group scalar runtime-validation behavior.

## Deferred Work

The following remain outside `.135`:

- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL backend and reroute behavior.

## Validation Gates For .135

The implementation slice should run:

- syntax checks for every touched Perl module and test;
- direct schedule, strict check JSON, strict semantic JSON, and `--verify-hdl`
  probes for a new public multi-group queue-head scalar runtime-validation
  sample;
- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- regression-corpus accounting tests if a support-accounted sample is added;
- supported-corpus catalog/check/semantic gates;
- preservation probes for `.132`, `.130`, `.127`, `.124`, and `.119`;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.134` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.
