# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.473`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.473` implements multi-beat
read-data output banks over generated dynamic read same-ID
`issue-order-queue` runtime-validation read-data.

The supported shape remains deliberately narrow:

- exactly two read transactions;
- both read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` is generated with `response-scope burst-last`,
  one-bit `last-signal`, and transaction completion source
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` uses `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation
  worst-observed`, and `interleaving multi-beat-by-rid`;
- `read-data.read` covers exactly the two generated dynamic queue transactions
  once each with complete output-bank bindings; and
- `burst-length` uses source `arlen`, width-8 signal, `axlen-plus-one`
  encoding, request capture, bounded `max-beats`, and `validation
  runtime-assertion`.

The `.467` scalar queue read-data, `.469` report-only raw-`ARLEN`, and `.471`
runtime-validation scalar queue read-data samples remain supported. Queue
recapture widening, broader queue cardinality, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact-owner work.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

It is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat_pipeline_cli
```

## Contract

The PPIF source extends the `.471` queue runtime-validation sample by changing
the read-data shape to multi-beat output banks:

```lisp
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))
    (transaction r1
      (data-output-prefix axi0_r1_beat_rdata)
      (status-output-prefix axi0_r1_beat_rresp)
      (status-aggregate-output axi0_r1_rresp)
      (valid-mask-output axi0_r1_beat_valid)
      (length-output axi0_r1_read_beats))))
```

The response-demux remains queue-owned:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

## Generated Runtime Artifacts

The read-data report moves to the bounded multi-beat contract:

```text
mode: bounded_multi_beat_read_data_contract
capture_scope: multi_beat
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
beat_match_source: response_demux_matched_read_beat
beat_count_match_source: response_demux_matched_read_beat
output_shape: per_beat_output_bank
valid_output: per_transaction_valid_mask
length_output: per_transaction_beat_count
status_aggregation: worst_observed
status_aggregation_generated_behavior: true
multi_beat_reassembly_generated_behavior: true
burst_length_validation: runtime_assertion
residue: []
```

For the default `max-beats 16` sample, the generated path emits:

- width-8 `axi0_arlen` input metadata;
- per-transaction raw `ARLEN` storage plus expected-beat and read-beat count
  storage;
- request-time output-bank initialization for data lanes, status lanes, valid
  masks, length outputs, and scalar aggregate status outputs;
- 32 `RDATA` lane outputs named `axi0_r0_beat_rdata_0` through
  `axi0_r1_beat_rdata_15`;
- 32 `RRESP` lane outputs named `axi0_r0_beat_rresp_0` through
  `axi0_r1_beat_rresp_15`;
- valid-mask outputs `axi0_r0_beat_valid` and `axi0_r1_beat_valid`;
- length outputs `axi0_r0_read_beats` and `axi0_r1_read_beats`;
- scalar worst-observed status aggregate outputs `axi0_r0_rresp` and
  `axi0_r1_rresp`;
- 32 per-lane capture rules;
- two scalar aggregate update rules; and
- eight total beat-count/`RLAST` runtime assertions inherited from the `.471`
  runtime-validation boundary.

Lane capture uses raw accepted queue read beats whose `RID` matches the
queue-selected transaction while that transaction is busy. It does not wait for
the final `RID && RLAST` completion pulse; that pulse still defines the
generated transaction-completion validity for the response-demux boundary.

The generated IAL1 initializes each transaction output bank at request time:

```lisp
(rule axi0_r1_read_data_output_init axi0_r1_request
  (axi0_r1_beat_rdata_0 0)
  (axi0_r1_beat_rresp_0 0)
  ...
  (axi0_r1_beat_valid 0)
  (axi0_r1_read_beats 0)
  (axi0_r1_rresp 0))
```

It captures individual lanes from matched queue read beats:

```lisp
(rule axi0_r1_read_data_beat_0
  (& (& axi0_read_complete <selected queue RID match for r1>)
     (== axi0_r1_read_beat_count_q 0))
  (axi0_r1_beat_rdata_0 axi0_rdata)
  (axi0_r1_beat_rresp_0 axi0_rresp)
  (axi0_r1_beat_valid 1)
  (axi0_r1_read_beats (+ axi0_r1_read_beat_count_q 5'd1)))
```

## Validation

Validation passed for:

```text
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -c t/248-regression-corpus-accounting.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

A filtered `t/1438` run for the new multi-beat case was stopped after roughly
90 seconds without TAP in the HDL-heavy path. The strict check JSON probe was
stopped after more than 60 seconds without output in the heavy path. No
unguarded retry was run, and strict/semantic JSON or broad focused-suite
closeout is not claimed for this slice.

## Rollback

Rollback is localized to the `.473` slice:

- remove the multi-beat PPIF sample and support-accounting entry;
- restore the dynamic issue-order queue read-data burst-length admission to
  scalar last-beat report-only/runtime behavior;
- remove focused parser/dynamic/support-accounting tests for the multi-beat
  sample;
- revert report/static-rule prose updates that mention queue-backed
  runtime-assertion raw-`ARLEN` multi-beat output banks; and
- remove this behavior record and its Knowledge Map fact card.

The `.467`, `.469`, and `.471` queue read-data samples remain independent.
