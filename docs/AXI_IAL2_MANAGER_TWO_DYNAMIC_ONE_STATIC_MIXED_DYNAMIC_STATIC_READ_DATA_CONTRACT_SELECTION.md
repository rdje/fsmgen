# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.360`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.360` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.361`, direct generated behavior for
bounded scalar single-beat read-data over the generated
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux shipped by `.344`.

The selected contract composes the existing `.344` response-demux public shape
with the existing scalar `read-data.read` surface. The implementation should
admit only this exact no-`burst_length` single-beat boundary, then reuse the
normalized scalar read-data capture path. It must not add a second raw `RID`
matcher in the read-data path.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shape

The `.361` implementation owner should add one support-accounted public PPIF
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

The sample should keep the `.344` transactions and single-beat response-demux
shape:

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
    (response-scope single-beat)
    (transaction-completion generated)))
```

The selected read-data arm is scalar single-beat only:

```lisp
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))))
```

The selected intent name and source object should be:

```text
axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data
axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-read-data
```

The support-accounting identity, coverage key, and focused behavior label are:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli
mixed_dynamic_static_read_data_multi_dynamic
```

## Public Boundary

`.361` should implement only scalar single-beat read-data over the already
generated `.344` two-dynamic-plus-one-static mixed dynamic/static read
response-demux:

- exactly two read transactions use `(id dynamic)`;
- exactly one read transaction uses concrete static ID `3`;
- `response-demux.read.transaction-completion` is `generated`;
- `response-demux.read.transaction_completion_source` is
  `generated_multi_mixed_dynamic_static_read_demux`;
- `response-demux.read.response_scope` is `single_beat`;
- `read-data.read.completion-source` is `response-demux`;
- `read-data.read.capture-scope` is `single-beat`;
- no `last-signal`, `status-policy`, or `burst_length` metadata is present;
- `read-data.read.transactions` binds the generated two-dynamic-plus-one-static
  read demux transaction set exactly once; and
- generated completion signal count matches the covered transaction count.

The `.361` implementation must not add the `.347` burst-last sibling, `.350`
scalar last-beat behavior, raw `ARLEN` burst-length capture, runtime
beat-count/`RLAST` validation, multi-beat output banks, broader mixed
cardinalities, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, or full-manager behavior.

## Transaction Coverage Contract

Read-data coverage should be derived from the response-demux report metadata
already emitted by `.344`:

```text
dynamic_transactions: [r0, r1]
static_transactions: [r2]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The covered transaction list is the ordered dynamic transaction list followed
by the ordered static transaction list. In this bounded slice that is exactly
`r0, r1, r2`.

The generated completion signal list must have the same length and order as
the covered transaction list. The coverage helper should build the
transaction-to-completion mapping from those lists:

```text
r0 -> axi0_r0_complete
r1 -> axi0_r1_complete
r2 -> axi0_r2_complete
```

Missing, duplicate, or extra `read-data.read.transaction` bindings should
remain diagnosed by the existing normalization layer once the coverage branch
admits the exact covered set.

## Completion And Capture Semantics

Read-data capture consumes generated completion pulses. It does not re-match
raw `RID`, does not inspect static ID reservations directly, and does not
create a second ownership decision.

For the selected sample, each completion pulse is a matched raw single-beat
`RID` response for either the captured dynamic ID or the selected concrete
static ID. The read-data capture rules should be:

```text
axi0_r0_complete -> capture axi0_rdata/axi0_rresp into r0 outputs
axi0_r1_complete -> capture axi0_rdata/axi0_rresp into r1 outputs
axi0_r2_complete -> capture axi0_rdata/axi0_rresp into r2 outputs
```

The generated IAL1 review artifact should declare shared generated inputs
`axi0_rdata` and `axi0_rresp`, per-transaction scalar data/status outputs,
and one scalar capture rule per covered transaction.

## Report Contract

The response-demux report remains owned by `.344`:

```text
response_demux.mode =
  bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_demux.read.mode =
  bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_demux.read.transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux
response_demux.read.transaction_completion_semantics =
  matched_dynamic_or_static_concrete_id_single_beat
response_demux.read.dynamic_transactions = r0, r1
response_demux.read.static_transactions = r2
response_demux.read.static_id_exclusions = 4'd3
response_demux.read.active_dynamic_ids_must_be_unique = true
```

The selected single-beat read-data report should keep the existing scalar
mode:

```yaml
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
    interleaving_policy: single_beat_by_rid
    data_signal: axi0_rdata
    data_width: 32
    status_signal: axi0_rresp
    status_width: 2
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_rdata
      - axi0_r0_rresp
      - axi0_r1_rdata
      - axi0_r1_rresp
      - axi0_r2_rdata
      - axi0_r2_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
      - axi0_r2_read_data_capture
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_rdata
        status_output: axi0_r0_rresp
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_rdata
        status_output: axi0_r1_rresp
      - transaction: r2
        completion_signal: axi0_r2_complete
        data_output: axi0_r2_rdata
        status_output: axi0_r2_rresp
  residue:
    - rlast_completion
    - bursts
    - multi_beat_read_data_reassembly
```

Generated scalar read-data outputs are selected in transaction order:

```text
axi0_r0_rdata
axi0_r0_rresp
axi0_r1_rdata
axi0_r1_rresp
axi0_r2_rdata
axi0_r2_rresp
```

Each read-data capture rule must be guarded only by that transaction's
generated single-beat completion pulse.

## Diagnostics And Fail-Closed Boundaries

`.361` should widen the multiple mixed dynamic/static read-data transaction
coverage predicate only for:

- `transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux`;
- `response_scope = single_beat`;
- `capture_scope = single-beat`;
- no `burst_length` metadata;
- exactly two dynamic read transactions followed by exactly one concrete static
  read transaction; and
- one generated completion signal per covered transaction.

The user-facing diagnostic should be updated to mention the selected
two-dynamic-plus-one-static scalar single-beat read-data shape. Unsupported
capture scopes, missing or duplicate transaction bindings, incomplete
transaction coverage, burst-last/last-beat behavior, raw `ARLEN`,
report-only/runtime validation, multi-beat output banks, broader mixed
cardinalities, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, and full-manager behavior must
continue to fail closed unless already owned by adjacent completed leaves.

## Validation Plan

The `.361` behavior slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and
  `t/248-regression-corpus-accounting.t`;
- guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for
  the selected public sample;
- schedule JSON assertions for the `.344` response-demux mode/source plus the
  selected scalar single-beat read-data fields;
- strict check JSON support-accounting for the selected public sample;
- focused `t/1438` coverage for `mixed_dynamic_static_read_data_multi_dynamic`,
  with CLI JSON skipped only if the RAM guard trips at the default cutoff;
- `t/248-regression-corpus-accounting.t`;
- preservation checks for `.344`, `.347`, `.350`, `.357`, the two-static and
  three-static mixed scalar read-data samples, and representative all-dynamic
  read-data; and
- Knowledge Map, mdBook, memory architecture, diff whitespace, and doctrine
  gates.

If guarded direct or focused probes trip host-memory cutoffs before assertion
output, `.361` should record the caveat and use the narrowest guarded rerun
that still validates parser/report/ISF/FSM behavior without exceeding the
documented RAM-guard policy.

## Rollback

Rollback for `.360` is documentation-only: revert this contract-selection doc
plus the task-tree, MEMORY, README, ROADMAP, mdBook, and Knowledge Map updates.
The selected behavior remains unimplemented until `.361`, so generated
artifacts and support accounting stay at the `.359` state.

