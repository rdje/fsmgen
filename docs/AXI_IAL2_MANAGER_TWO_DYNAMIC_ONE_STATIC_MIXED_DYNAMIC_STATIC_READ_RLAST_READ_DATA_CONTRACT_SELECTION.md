# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.349`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.349` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.350`, direct generated behavior for scalar
last-beat read-data over generated two-dynamic-plus-one-static mixed
dynamic/static read burst-last `RID`/`RLAST` response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/semantic
JSON, or HDL behavior.

## Public Source Contract

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif
```

The selected intent name and source object are:

```text
axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data
axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last-read-data
```

The support-accounting identity, coverage key, and focused behavior label are:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli
mixed_dynamic_static_read_data_multi_dynamic_last_beat
```

The response-demux portion must remain the `.347` public shape:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id dynamic))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 3))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The selected read-data arm is scalar last-beat only:

```lisp
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))
    (transaction r2
      (data-output axi0_r2_last_rdata)
      (status-output axi0_r2_last_rresp))))
```

The selected `.350` implementation scope is exactly this scalar last-beat
read-data shape. It must not add the single-beat `.344` sibling, raw `ARLEN`
burst-length capture, runtime beat-count/`RLAST` validation, or multi-beat
output banks.

## Report Contract

The response-demux report remains owned by `.347`:

```text
response_demux.mode =
  bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.read.mode =
  bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.read.dynamic_transactions = r0, r1
response_demux.read.static_transactions = r2
response_demux.read.transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux_last_beat
response_demux.read.transaction_completion_semantics =
  matched_dynamic_or_static_concrete_id_and_last_signal
response_demux.read.last_signal = axi0_rlast
response_demux.read.static_id_exclusions = 4'd3
response_demux.read.active_dynamic_ids_must_be_unique = true
```

The selected read-data report is:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.generated_behavior = true
read_data.read.capture_scope = last_beat
read_data.read.completion_source = response_demux
read_data.read.interleaving_policy = last_beat_by_rid
read_data.read.data_signal = axi0_rdata
read_data.read.data_width = 32
read_data.read.status_signal = axi0_rresp
read_data.read.status_width = 2
read_data.read.status_policy = last_beat
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.generated_inputs = axi0_rdata, axi0_rresp
read_data.read.transactions = r0, r1, r2
read_data.read.generated_rules =
  axi0_r0_read_data_capture,
  axi0_r1_read_data_capture,
  axi0_r2_read_data_capture
read_data.residue =
  multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation,
  arlen_or_beat_count_validation
```

Generated scalar read-data outputs are selected in transaction order:

```text
axi0_r0_last_rdata
axi0_r0_last_rresp
axi0_r1_last_rdata
axi0_r1_last_rresp
axi0_r2_last_rdata
axi0_r2_last_rresp
```

Each read-data capture rule must be guarded only by that transaction's
generated final-beat completion pulse. The read-data rule must not re-match
`RID` or `RLAST`; those semantics remain owned by the response-demux completion
pulse.

## Diagnostics And Fail-Closed Boundaries

`.350` should widen the multiple mixed dynamic/static read-data transaction
coverage predicate only for:

- `transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- `response_scope = burst_last`;
- `capture_scope = last-beat`;
- no `burst_length` metadata;
- exactly two dynamic read transactions followed by exactly one concrete static
  read transaction; and
- one generated completion signal per covered transaction.

The user-facing diagnostic should be updated to mention the selected
two-dynamic-plus-one-static scalar last-beat read-data shape. Unsupported
capture scopes, missing or duplicate transaction bindings, incomplete
transaction coverage, raw `ARLEN`, report-only/runtime validation, multi-beat
output banks, broader mixed cardinalities, single-beat read-data over `.344`,
same-cycle widening, release-and-recapture, dynamic same-ID queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, profile aliases,
queued/blocking policy, and full-manager behavior must continue to fail closed.

## Validation Plan

The `.350` behavior slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and
  `t/248-regression-corpus-accounting.t`;
- guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for
  the selected public sample;
- schedule JSON assertions for the `.347` response-demux mode/source plus the
  selected scalar last-beat read-data fields;
- strict check JSON support-accounting for the selected public sample;
- focused `t/1438` coverage for
  `mixed_dynamic_static_read_data_multi_dynamic_last_beat`;
- `t/248-regression-corpus-accounting.t`;
- preservation checks for `.347`, `.344`, the two-static and three-static mixed
  scalar last-beat read-data samples, and representative all-dynamic read-data;
  and
- Knowledge Map, mdBook, memory architecture, diff whitespace, and doctrine
  gates.

If the focused `t/1438` CLI JSON path hits the default RAM guard, `.350` should
record the caveat and rerun the focused behavior with CLI JSON skipped, matching
the adjacent `.347` validation pattern.

## Rollback

Rollback for `.349` is doc-only: revert this contract-selection doc plus the
task-tree, MEMORY, README, ROADMAP, mdBook, and Knowledge Map updates. The
selected behavior remains unimplemented until `.350`, so generated artifacts and
support accounting stay at the `.347`/`.348` state.
