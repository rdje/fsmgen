# AXI IAL2 Manager Queue-Head Multi-Beat Read-Data Behavior

Status: shipped.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.121`

## Summary

This slice ships generated multi-beat read-data output-bank behavior for the
bounded read burst-last concrete same-ID queue-head demux shape.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_multi_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
```

## Supported Shape

The supported boundary is intentionally narrow:

- read family only;
- one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth 2;
- `response-demux.read.response-scope burst-last`;
- generated queue-head response-demux completion pulses qualified by `RLAST`;
- no same-family `auto-id-lifecycle` response demux;
- `read-data.read.capture-scope multi-beat`;
- `read-data.read.completion-source response-demux`;
- `read-data.read.status-policy per-beat`;
- `read-data.read.interleaving multi-beat-by-rid`;
- `read-data.read.burst-length` with `source arlen`, width 8,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- per-transaction `data-output-prefix`, `status-output-prefix`,
  `valid-mask-output`, and `length-output` bindings;
- selected scalar `RRESP` aggregation with `status-aggregation
  worst-observed` and per-transaction `status-aggregate-output` bindings.

## Generated Behavior

FSMGen keeps the generated queue-head demux and queue state from the existing
bounded read burst-last same-ID shape. The transaction completion pulses still
come from the `RLAST`-qualified queue-head response-demux rules.

The multi-beat payload capture uses the raw matched queue-head read beat, not
the `RLAST`-qualified completion pulse. Each lane guard combines the raw read
response event, concrete `RID`, active queue-head transaction identity,
`!request_event`, and the current beat-count lane index:

```lisp
(rule axi0_r0_read_beat_0_capture
  (& (& axi0_read_complete
        (& (== axi0_rid 4'd3)
           axi0_read_id3_same_id_issue_order_slot0_r0_q))
     (! axi0_r0_request)
     (== axi0_r0_read_beat_count_q 5'd0))
  (axi0_r0_beat_rdata_0 axi0_rdata)
  (axi0_r0_beat_rresp_0 axi0_rresp)
  (axi0_r0_beat_valid 16'b0000000000000001)
  (axi0_r0_read_beats 5'd1))
```

Request-time initialization clears the per-transaction output bank and scalar
status aggregate:

```lisp
(rule axi0_r0_read_data_output_init axi0_r0_request
  (axi0_r0_beat_rdata_0 32'd0)
  ...
  (axi0_r0_rresp 2'd0)
  (axi0_r0_beat_valid 16'b0)
  (axi0_r0_read_beats 5'd0))
```

Scalar `RRESP` aggregation reuses the current matched queue-head read beat and
updates the aggregate when the current response is worse than the stored
value:

```lisp
(rule axi0_r0_rresp_aggregate
  (& (& axi0_read_complete
        (& (== axi0_rid 4'd3)
           axi0_read_id3_same_id_issue_order_slot0_r0_q))
     (! axi0_r0_request)
     (< axi0_r0_rresp axi0_rresp))
  (axi0_r0_rresp axi0_rresp))
```

The generated HDL exposes the per-beat output-bank ports, valid masks, length
outputs, and scalar aggregate outputs, for example
`axi0_r0_beat_rdata_0`, `axi0_r0_beat_rresp_0`, `axi0_r0_beat_valid`,
`axi0_r0_read_beats`, and `axi0_r0_rresp`.

## Report Contract

Schedule JSON reports the queue-head multi-beat shape as generated behavior:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    completion_validity:
      generated_queue_head_response_demux_last_beat_completion_pulse
    beat_match_source: response_demux_matched_read_beat
    beat_count_match_source: response_demux_matched_read_beat
    output_shape: per_beat_output_bank
    valid_output: per_transaction_valid_mask
    length_output: per_transaction_beat_count
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: true
    generated_multi_beat_output_init_rules:
      - axi0_r0_read_data_output_init
      - axi0_r1_read_data_output_init
    generated_multi_beat_valid_outputs:
      - axi0_r0_beat_valid
      - axi0_r1_beat_valid
    generated_multi_beat_length_outputs:
      - axi0_r0_read_beats
      - axi0_r1_read_beats
  residue: []
```

`response_demux.residue` is also empty for this sample because read-data
interleaving and burst output-bank behavior are now covered for the bounded
queue-head subset. `same_id_ordering.residue` keeps the broader
`per_id_issue_order_queues` residue because generalized per-ID queue behavior
is still outside this capacity/status shell.

Existing report values remain stable for queue-head single-beat read-data,
queue-head last-beat read-data, queue-head report-only burst-length,
queue-head runtime-validation, auto-ID runtime-validation, auto-ID
multi-beat, and read burst-last queue-head demux samples.

## Deferred

The slice still fail-closes or defers:

- queue groups deeper than two slots;
- read-data consumption over more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head response demux;
- generalized per-ID issue-order queues;
- packed burst-vector outputs and alternate payload assembly;
- aggregate-only status output shapes beyond the selected scalar aggregate;
- direct backend lowering;
- VHDL.

## Validation

The slice was validated with focused generator and PPIF/CLI tests; direct
schedule JSON, strict check JSON, strict semantic JSON, and `--verify-hdl`
coverage for the new public sample; regression probes for existing
queue-head/read-data/burst-length samples; support accounting; mdBook;
documentation path audit; Knowledge Map generation/check; memory
architecture; diff hygiene; README numbering; and stale-frontier scans.
