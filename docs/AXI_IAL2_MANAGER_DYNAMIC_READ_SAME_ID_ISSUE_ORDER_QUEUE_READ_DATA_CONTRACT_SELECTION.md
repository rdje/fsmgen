# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.466`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.466` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.467`, direct implementation of paired
bounded scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions.

The selected public contract reuses existing `read-data.read` syntax and adds
no new parser fields. It covers two support-accounted public samples:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif
```

This contract-selection slice changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Inputs Read

The selector read `.465` readiness audit, `.464` selector, `.463` generated
dynamic read burst-last queue behavior, `.462` dynamic read burst-last queue
contract, `.459` generated dynamic read single-beat queue behavior, generated
dynamic read-data behavior, multiple dynamic read-data behavior, concrete
queue-head read-data behavior, current read-data coverage/artifact/report/
residue helpers, parser/CLI and generator-test surfaces, support accounting,
README, ROADMAP_V2, mdBook, MEMORY, task tree, and Knowledge Map facts.

## Selected Source Shapes

The single-beat sample extends the shipped dynamic read single-beat queue
shape:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))

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
      (status-output axi0_r1_rresp))))
```

The burst-last sample extends the shipped dynamic read burst-last queue shape:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))

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
      (status-output axi0_r1_last_rresp))))
```

Both samples require exactly two all-dynamic read transactions, read
ID-family metadata, `read-max-pending` at least `2`, and the existing compact
runtime-ID queue state from the underlying generated dynamic read queue
behavior.

## Support Accounting

`.467` should add these support-accounting identities:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data
```

with coverage buckets:

```text
ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_pipeline_cli
```

Both should be strict-supported `supported_smoke` PPIF entries.

## Read-Data Coverage Contract

`.467` must add read-data coverage for generated dynamic read issue-order
queue completion sources:

```text
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

The coverage branch must:

- require `capture-scope single-beat` with `response-demux.read.response-scope
  single-beat` for `generated_dynamic_issue_order_queue_demux`;
- require `capture-scope last-beat`, `status-policy last-beat`, and
  `response-demux.read.response-scope burst-last` for
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- require `read-data.read.transactions` to cover exactly the two generated
  dynamic queue transactions once each;
- require one generated completion signal per covered transaction;
- reject any transaction outside the generated dynamic queue;
- reject `read-data.read.burst-length` metadata in the first implementation.

## Report Contract

The single-beat read-data report should use:

```yaml
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_completion_pulse
    interleaving_policy: single_beat_by_rid
    generated_inputs: [axi0_rdata, axi0_rresp]
    generated_outputs: [axi0_r0_rdata, axi0_r0_rresp, axi0_r1_rdata, axi0_r1_rresp]
    generated_rules: [axi0_r0_read_data_capture, axi0_r1_read_data_capture]
```

The last-beat read-data report should use:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    generated_inputs: [axi0_rdata, axi0_rresp]
    generated_outputs: [axi0_r0_last_rdata, axi0_r0_last_rresp, axi0_r1_last_rdata, axi0_r1_last_rresp]
    generated_rules: [axi0_r0_read_data_capture, axi0_r1_read_data_capture]
```

Each report must list `r0` and `r1` in source order, with each transaction
bound to its generated queue completion signal (`axi0_r0_complete` and
`axi0_r1_complete`).

The underlying response-demux report stays queue-owned:

```text
bounded_dynamic_read_rid_issue_order_queue_demux_contract
bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

For this scalar owner, `response_demux.residue` should continue to expose
`read_data_interleaving` and `bursts`. The single-beat `read_data.residue`
should retain `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`. The last-beat `read_data.residue` should
retain `multi_beat_read_data_reassembly`, `per_beat_outputs`,
`rresp_aggregation`, and `arlen_or_beat_count_validation`.

## Generated Behavior Contract

`.467` should not create new queue state. The read-data capture rules consume
the generated transaction completion pulses from the existing queue response
demux:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

The last-beat sample uses the same rule names and captures into
`axi0_r0_last_rdata`/`axi0_r0_last_rresp` and
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`.

## Diagnostics

The implementation must fail closed for:

- missing read-data bindings for generated dynamic queue transactions;
- duplicate read-data transaction bindings;
- read-data bindings for transactions outside the generated dynamic queue;
- generated completion-signal count mismatches;
- single-beat read-data over burst-last response-demux;
- last-beat read-data over single-beat response-demux;
- first-scope scalar queue read-data with `burst-length`,
  `capture-scope multi-beat`, incomplete output-bank bindings, mixed
  dynamic/static queues, broader queue cardinality, scoreboards, direct
  backend behavior, backend-language variants, or VHDL assumptions.

## Validation For `.467`

The implementation owner should run focused syntax checks for the touched Perl
and test files, support-accounting validation for the new samples, direct
schedule/check/semantic/HDL probes for both public PPIFs under the RAM guard
where appropriate, focused parser/generator tests, Knowledge Map generation/
check, mdBook build, docs path audit, memory architecture check, diff hygiene,
and `scripts/check_doctrines.sh`.

## Non-Goals

The selected `.467` implementation must not enable:

- raw `ARLEN` capture over dynamic queues;
- runtime beat-count/`RLAST` validation over dynamic queues;
- multi-beat output banks over dynamic queues;
- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants;
- VHDL.

## Rollback

Rollback for `.466` removes this selector document and fact card, reverts the
`.466` task-tree/memory/README/roadmap/mdBook updates, and returns the active
frontier to `.466`. No code or runtime behavior rollback is needed.

Rollback for the future `.467` behavior must remove only the coverage branch,
public samples, support-accounting entries, tests, docs, and Knowledge Map
card introduced for paired scalar dynamic issue-order queue read-data while
preserving generated dynamic read queue behavior and ordinary dynamic
read-data behavior.
