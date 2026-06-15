# AXI IAL2 Manager Multi-Group Queue-Head Read-Data Readiness Audit

Status: selected next implementation slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.126`

Date: `2026-06-15`

## Purpose

This audit follows the `.125` selector and decides how FSMGen should first
enable read-data coverage over multiple generated read burst-last concrete
same-ID queue-head groups.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.127`:
generated multi-group queue-head multi-beat read-data output-bank behavior.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.125` selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md`
- `.124` multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.123` multi-group response-demux readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `.121` queue-head multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- current response-demux, queue-head response-state, read-data coverage,
  matched-read-beat, output-bank, burst-length/runtime-validation, report, and
  residue code in `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head, burst-length, runtime-validation, and read-data PPIF
  samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.124` public sample proves multiple queue-head response-demux groups, but
has no read-data clause:

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

The `.121` public sample proves the residue-clean queue-head multi-beat
read-data shape, but only for one generated queue group:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.beat_match_source:
    response_demux_matched_read_beat
  read_data.residue: []
  response_demux.residue: []
```

An in-memory probe that combines the `.124` two-group response-demux shape with
multi-beat read-data coverage for `r0`, `r1`, `r2`, and `r3` still fails closed
at the current coverage guard:

```text
queue-head coverage requires exactly one depth-2 concrete same-ID read queue group
```

That diagnostic is the intended current blocker.

## Code Findings

`_read_data_response_demux_transaction_coverage` is the only local blocker for
the next bounded behavior. For generated queue-head read-data it currently
accepts only one `response_demux.read.same_id_issue_order_queues` entry, and
then maps the two queue transactions to their generated completion signals.

The implementation must avoid a broad, accidental widening. That helper sees
the response-demux metadata and capture scope before the later read-data
normalization validates output bindings, burst-length metadata, status
aggregation, and per-transaction coverage. A simple "flatten every group for
every capture scope" would enable last-beat, last-beat-plus-burst-length,
runtime-validation, and multi-beat paths together. The next behavior owner
must therefore gate the multi-group widening to the selected public shape.

The downstream substrate is ready for the multi-beat output-bank shape:

- `_same_id_issue_order_queue_response_states_for_family` already iterates all
  generated queue groups and returns response-state entries per transaction.
- `_read_data_response_states_by_transaction` indexes those response states by
  transaction name.
- `_read_data_matched_read_beat_expr` combines the raw read response event
  with the queue-head match expression; that match expression includes the
  concrete `RID` and active queue-head transaction state.
- beat-count/runtime-validation, output-bank init, lane capture, valid-mask,
  length-output, and scalar `RRESP` aggregation helpers iterate the normalized
  read-data transactions and use transaction-local names.
- generated queue names include the concrete ID value, while generated
  read-data outputs and storage names are transaction-local, so the existing
  naming scheme can represent multiple groups without cross-group aliases.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.127`, generated multi-group
queue-head multi-beat read-data output-bank behavior.

The `.127` implementation boundary is:

- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at computed depth `2`;
- `read_data.read.capture_scope multi_beat`;
- `completion-source response-demux`;
- `interleaving multi-beat-by-rid`;
- `status-policy per-beat`;
- ARLEN `burst_length` with `validation runtime-assertion`;
- per-transaction data/status output prefixes, valid-mask outputs, length
  outputs, and scalar `RRESP` aggregate outputs for every covered transaction;
- flatten all selected generated queue groups into the read-data transaction
  coverage set, with one generated last-beat completion signal per
  transaction and matched-read-beat state lookup by transaction;
- preserve request-time output-bank clearing, per-beat lane capture,
  valid-mask/length outputs, scalar `RRESP` aggregation, and beat-count/`RLAST`
  runtime validation for every covered transaction;
- move `read_data_interleaving` and `bursts` residue only for the covered
  multi-beat multi-group sample when the report is residue-clean;
- preserve the `.121` one-group multi-beat behavior and the `.124`
  response-demux-only multi-group behavior.

## Deferred Work

The following remain outside `.127`:

- last-beat-only read-data over multiple queue groups;
- report-only burst-length or runtime-validation-only multi-group
  queue-head read-data without the selected multi-beat output-bank bindings;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .127

The implementation slice should run:

- syntax checks for every touched Perl module and test;
- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- direct schedule, strict check JSON, strict semantic JSON, and `--verify-hdl`
  probes for a new public multi-group queue-head multi-beat read-data sample;
- preservation probes for `.121` one-group queue-head multi-beat read-data,
  `.124` response-demux-only multi-group queue-head behavior, queue-head
  last-beat, queue-head runtime-validation, and auto-ID multi-beat samples;
- support-accounting catalog/check/semantic corpus gates if a new public
  sample is added;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.126` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.
