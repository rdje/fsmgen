# AXI IAL2 Manager Dynamic Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.233` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.233`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.234`, direct bounded implementation
of scalar dynamic read-data capture over generated single-active dynamic read
response-demux.

No new public syntax is needed before behavior. The next owner should reuse the
existing `read-data.read` contract:

- `completion-source response-demux`;
- `capture-scope single-beat` with `interleaving single-beat-by-rid`;
- `capture-scope last-beat` with `status-policy last-beat` and
  `interleaving last-beat-by-rid`;
- one `(transaction NAME ...)` binding for the same single dynamic read
  transaction covered by generated dynamic `response-demux.read`.

The selected implementation must remain scalar. It may capture `RDATA` and
`RRESP` into the transaction-bound data/status outputs using the generated
dynamic completion pulse as the guard. It must not implement dynamic
burst-length capture, beat-count/runtime validation, multi-beat output banks,
multiple dynamic reads, mixed dynamic/static demux, same-cycle recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior, or
VHDL.

## Evidence Read

The audit read or probed:

- `.232` post-dynamic-read-RLAST selector.
- `.231` generated dynamic read burst-last/`RID && RLAST` behavior.
- `.227` generated dynamic read single-beat `RID` behavior.
- `.223` generated dynamic write `BID` behavior.
- `.219` metadata-first dynamic transaction-ID behavior.
- Existing read-data public contract and behavior records:
  `AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION`,
  `AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE`,
  `AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION`, and
  `AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE`.
- Current parser/generator code for dynamic transaction rejection,
  read-data normalization, response-demux transaction coverage, scalar
  read-data capture rules, dynamic response-demux state, and reports.
- Focused tests and public PPIF samples for dynamic read response-demux and
  non-dynamic single-beat/last-beat read-data.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

Live probes confirmed:

- `ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` reports
  `bounded_dynamic_read_rid_demux_contract`, one dynamic read transaction, one
  generated completion signal, and
  `transaction_completion_source: generated_dynamic_demux`.
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
  reports `bounded_dynamic_read_rid_rlast_demux_contract`, one dynamic read
  transaction, one generated completion signal, and
  `transaction_completion_source: generated_dynamic_demux_last_beat`.
- `ppif/axi_manager_capacity_status_read_data.ppif` reports
  `bounded_single_beat_read_data_contract`, generated `RDATA`/`RRESP` inputs,
  per-transaction scalar outputs, and capture rules guarded by generated
  response-demux completion pulses.
- `ppif/axi_manager_capacity_status_read_data_last_beat.ppif` reports
  `bounded_last_beat_read_data_contract`, `burst_length_source: rlast_only`,
  `burst_length_validation: not_generated`, and scalar last-beat capture rules
  guarded by generated last-beat completion pulses.

## Why Direct Implementation Is Ready

The dynamic read demux and scalar read-data substrates already meet the
requirements for a bounded scalar implementation:

- generated dynamic read demux produces one transaction completion pulse for
  the selected single dynamic read transaction;
- scalar read-data capture already treats the generated completion pulse as
  the validity strobe and assigns ordinary held `RDATA`/`RRESP` outputs;
- the existing syntax already requires explicit transaction-bound data/status
  outputs and generated response-demux completion as the source;
- the existing dynamic read demux state exposes selected-ID/busy match
  semantics for the response-demux rule, so scalar read-data does not need a
  separate raw response match expression;
- non-dynamic single-beat and last-beat behavior documents already define the
  generated input/output/rule/report boundary.

The only lower-layer change needed by `.234` is bounded routing through the
existing read-data coverage helper and dynamic interaction gate. That is small
enough for direct implementation because `.234` can stay limited to exactly
one dynamic read transaction and scalar capture scopes.

## Selected Scope For `.234`

`.234` should:

- relax the current `read_data.read` plus dynamic read-ID rejection only for
  this selected shape;
- add read-data response-demux coverage for
  `transaction_completion_source: generated_dynamic_demux` and
  `generated_dynamic_demux_last_beat`;
- require exactly one dynamic read transaction, exactly one generated
  completion signal, and a matching single `read-data` transaction binding;
- support `capture-scope single-beat` only with dynamic read
  `response-scope single_beat`;
- support `capture-scope last-beat` only with dynamic read
  `response-scope burst_last`, one-bit `last-signal`, and
  `status-policy last-beat`;
- keep `burst_length` absent for the dynamic last-beat implementation in this
  slice;
- report dynamic-specific completion-validity vocabulary for the selected
  generated dynamic completion pulse;
- add one public PPIF sample for scalar single-beat dynamic read-data and one
  public PPIF sample for scalar last-beat dynamic read-data;
- update support accounting, focused parser/generator tests,
  schedule/check/semantic/default-HDL probes, README, roadmap, mdBook, Memory,
  and Knowledge Map.

## Non-Goals

`.233` changes no parser, generator, PPIF sample, support-accounting catalog,
validation, generated artifact, test, or HDL behavior.

`.234` must not enable:

- dynamic `burst_length` metadata;
- dynamic beat-count/runtime validation;
- dynamic multi-beat output banks;
- multiple dynamic read/write transactions;
- mixed dynamic/static response demux;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- queues or scoreboards;
- direct backend behavior;
- HDL behavior outside the selected SystemVerilog path;
- VHDL.

## Validation For `.234`

The behavior owner must run focused checks that cover the changed surfaces,
including:

```sh
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/248-regression-corpus-accounting.t
```

It must also run support-accounting, direct schedule/check/semantic/default-HDL
probes for both new dynamic read-data samples, mdBook, Knowledge Map, memory,
diff whitespace, and `scripts/check_doctrines.sh`.

## Rollback

Rollback for `.233` is limited to this audit record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No behavior-bearing file is part of this audit.

Rollback for a later `.234` implementation must remove only the dynamic
read-data coverage branch, public samples/support entries/tests, generated
artifact expectations, and docs introduced by that implementation while
preserving existing dynamic response-demux and non-dynamic read-data behavior.
