# AXI IAL2 Manager Mixed Auto-ID Queue-Head Multi-Beat Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.207` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.207`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_auto_id_queue_head_multi_beat.sv ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
```

The sample extends the `.202` mixed runtime-validation shape from scalar
last-beat read-data to explicit per-beat output banks:

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
      (validation runtime-assertion))))
```

The covered transaction shape remains exact:

- `r0` is one read transaction with auto-ID allocation from pool `0, 1`;
- `r1` and `r2` are concrete read transactions with ID value `3`;
- `r1` and `r2` use one depth-2 same-ID issue-order queue;
- response demux is read `burst-last` with one-bit `axi0_rlast`;
- read-data capture is `multi-beat` with runtime-assertion `ARLEN`
  burst-length metadata.

## Generated Behavior

For covered transactions `r0`, `r1`, and `r2`, generation emits:

- generated inputs `axi0_rdata`, `axi0_rresp`, and `axi0_arlen`;
- raw `ARLEN` storage and request-guarded capture rules;
- expected-beat storage, read-beat counters, beat-count initialization rules,
  and matched-read-beat counter rules;
- four beat-count/`RLAST` assertions per covered transaction, for twelve
  generated assertions total;
- sixteen `RDATA` lane outputs and sixteen `RRESP` lane outputs per
  transaction;
- one valid-mask output, one read-length output, and one scalar
  worst-observed `RRESP` aggregate output per transaction;
- one request-time output-bank clear rule per transaction;
- sixteen lane-capture rules per transaction, guarded by the raw matched read
  beat and the transaction's read-beat count;
- one scalar `RRESP` aggregate update rule per transaction.

The shipped sample therefore emits 48 generated `RDATA` lane outputs, 48
generated `RRESP` lane outputs, three valid masks, three length outputs, three
scalar `RRESP` aggregate outputs, 48 lane-capture rules, three output-bank
clear rules, three scalar aggregate update rules, three raw `ARLEN` storage
signals, three expected-beat counters, six beat-count rules, and twelve
beat-count/`RLAST` assertions.

The auto-ID transaction keeps its matched-beat guard on the allocated ID:

```lisp
(& axi0_read_complete
   (& axi0_r0_auto_id_busy_q
      (== axi0_rid axi0_r0_auto_id_q)))
```

The queue-head transaction keeps its matched-beat guard on the concrete ID and
queue-head slot:

```lisp
(& axi0_read_complete
   (& (== axi0_rid 4'd3)
      axi0_read_id3_same_id_issue_order_slot0_r2_q))
```

## Report Contract

Schedule JSON reports:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.transaction_completion_source:
  generated_demux_and_queue_head_demux
read_data.mode:
  bounded_multi_beat_read_data_contract
read_data.read.completion_validity:
  generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
read_data.read.output_shape:
  per_beat_output_bank
read_data.read.burst_length_validation:
  runtime_assertion
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.read.beat_match_source:
  response_demux_matched_read_beat
read_data.residue:
  []
```

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data
ial2_ppif_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data_pipeline_cli
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, strict support, and generated module
`axi0_capacity_status`.

## Preservation

This slice preserves:

- `.202` mixed scalar runtime-validation behavior and support identity;
- `.200` mixed report-only raw-`ARLEN` behavior;
- `.197` mixed scalar read-data behavior;
- `.194` mixed response-demux-only behavior;
- adjacent pure concrete queue-head multi-beat behavior;
- existing PPIF read-data syntax;
- the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Deferred Work

The following remain outside this slice:

- group-local simultaneous enqueue widening;
- write-family read-data behavior;
- packed burst-vector outputs or alternate full burst payload assembly;
- broader concrete queue-head families beyond the selected mixed shape;
- direct backend, verification-output generation, VHDL, or backend-language
  variants.
