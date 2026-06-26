# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.520`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.520` implements multi-beat output banks over
generated mixed dynamic/static read burst-last same-ID `issue-order-queue`
runtime-validation read-data.

The supported shape is deliberately narrow:

- exactly one dynamic read transaction and one concrete static read
  transaction;
- exactly one generated mixed dynamic/static same-ID queue with depth 2;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` is generated with `response-scope burst-last`,
  one-bit `last-signal`, and transaction completion source
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- `read-data.read` uses `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation (policy
  worst-observed)`, and `interleaving multi-beat-by-rid`;
- each covered transaction supplies data/status output prefixes, a scalar
  status aggregate output, a valid-mask output, and a length output; and
- `burst-length` uses source `arlen`, width-8 signal, `axlen-plus-one`
  encoding, request capture, and `validation runtime-assertion`.

Broader mixed queue cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-output generation, external converter
dependencies, and VHDL remain future exact-owner work.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

It is registered as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat_pipeline_cli
```

## Contract

The PPIF source is the multi-beat sibling of the `.518` runtime-validation
sample:

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
mode: bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report uses:

```text
mode: bounded_multi_beat_read_data_contract
completion_validity: generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
capture_scope: multi_beat
interleaving_policy: multi_beat_by_rid
burst_length_source: arlen_signal
burst_length_validation: runtime_assertion
beat_count_match_source: response_demux_matched_read_beat
beat_match_source: response_demux_matched_read_beat
output_shape: per_beat_output_bank
valid_output: per_transaction_valid_mask
length_output: per_transaction_beat_count
status_aggregation: worst_observed
residue: []
```

## Generated Outputs

For each covered transaction, FSMGen emits:

- 16 `RDATA` lane outputs, such as `axi0_r1_beat_rdata_15`;
- 16 `RRESP` lane outputs, such as `axi0_r1_beat_rresp_15`;
- one scalar worst-observed `RRESP` aggregate output, such as `axi0_r1_rresp`;
- one valid mask, such as `axi0_r1_beat_valid`; and
- one length output, such as `axi0_r1_read_beats`.

Each request clears that transaction's output bank, scalar aggregate, valid
mask, and length output. Each raw matched read beat captures the current
`RDATA` and `RRESP` into the lane indexed by the transaction's generated
read-beat counter, advances the valid mask, updates the length output, and
updates the scalar aggregate when the current `RRESP` is worse.

The same runtime-validation substrate from `.518` is retained: raw `ARLEN`
capture, expected-beat storage, read-beat counters, and four beat-count/`RLAST`
assertions per covered transaction.

## Validation

Validation for this slice includes syntax checks for the changed generator,
language-surface, parser test, and generator test files. A guarded schedule JSON
probe for the new PPIF stopped before a runtime result because host memory was
already above the 88% RAM-guard cutoff. No unguarded retry or cutoff raise was
used.

Focused support-accounting, capability-manifest, Knowledge Map, mdBook,
docs-path, memory-architecture, diff, and doctrine gates are recorded in the
owning task-tree verification log.

## Rollback

Rollback is localized to the `.520` slice:

- remove the multi-beat PPIF sample and support-accounting entry;
- remove the `multi-beat` runtime-assertion boundary from the mixed
  dynamic/static issue-order queue read-data coverage branch;
- remove the focused parser/generator/support-accounting tests for the
  multi-beat sample;
- revert the report/static-rule and public-surface prose updates for selected
  mixed queue multi-beat output banks; and
- remove this behavior record and its Knowledge Map fact card.

The `.514` scalar mixed queue read-data behavior, `.516` report-only raw-`ARLEN`
behavior, `.518` runtime-validation behavior, dynamic issue-order queue
multi-beat behavior, and ordinary mixed response-demux multi-beat behavior remain
independent.
