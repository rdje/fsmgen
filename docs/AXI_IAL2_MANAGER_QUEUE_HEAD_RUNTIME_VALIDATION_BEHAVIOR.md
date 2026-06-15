# AXI IAL2 Manager Queue-Head Runtime Validation Behavior

Status: shipped.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.119`

## Summary

This slice ships generated beat-count/`RLAST` runtime validation for the
bounded read burst-last concrete same-ID queue-head last-beat read-data shape.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
```

## Supported Shape

The supported boundary is intentionally narrow:

- read family only;
- one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth 2;
- `response-demux.read.response-scope burst-last`;
- generated queue-head response-demux completion pulses qualified by `RLAST`;
- `read-data.read.capture-scope last-beat`;
- `read-data.read.completion-source response-demux`;
- `read-data.read.status-policy last-beat`;
- `read-data.read.interleaving last-beat-by-rid`;
- `read-data.read.burst-length` with `source arlen`, width 8,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`.

The existing report-only queue-head burst-length sample remains supported and
does not generate beat counters or runtime assertions.

## Generated Behavior

FSMGen keeps request-bound raw-`ARLEN` capture:

```lisp
(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
```

Runtime validation adds expected-count and beat-count state:

```lisp
(var axi0_r0_expected_beats_q (width 5))
(var axi0_r0_read_beat_count_q (width 5))

(rule axi0_r0_beat_count_init axi0_r0_request
  (axi0_r0_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r0_read_beat_count_q 0))
```

The beat counter increments on the raw matched queue-head read beat, not on
the `RLAST`-qualified transaction completion pulse:

```lisp
(rule axi0_r0_read_beat_count
  (& (& axi0_read_complete
        (& (== axi0_rid 4'd3)
           axi0_read_id3_same_id_issue_order_slot0_r0_q))
     (! axi0_r0_request))
  (axi0_r0_read_beat_count_q (+ axi0_r0_read_beat_count_q 5'd1)))
```

Last-beat `RDATA`/`RRESP` capture remains guarded by generated queue-head
last-beat completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

Generated runtime assertions cover:

- request-time `ARLEN` bound against the configured `max-beats`;
- over-count or extra read beats;
- `RLAST` appearing before the expected final beat;
- the expected final beat missing `RLAST`.

## Report Contract

Schedule JSON reports runtime validation while preserving the queue-head
last-beat completion-validity value:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    completion_validity:
      generated_queue_head_response_demux_last_beat_completion_pulse
    burst_length_validation: runtime_assertion
    burst_length_generated_behavior: true
    beat_count_validation_generated_behavior: true
    beat_count_match_source: response_demux_matched_read_beat
    generated_expected_beat_count_storage:
      - axi0_r0_expected_beats_q
      - axi0_r1_expected_beats_q
    generated_beat_count_storage:
      - axi0_r0_read_beat_count_q
      - axi0_r1_read_beat_count_q
    generated_beat_count_rules:
      - axi0_r0_beat_count_init
      - axi0_r0_read_beat_count
      - axi0_r1_beat_count_init
      - axi0_r1_read_beat_count
```

Existing report values remain stable for report-only queue-head burst-length,
auto-ID runtime-validation burst-length, auto-ID multi-beat read-data,
queue-head last-beat read-data, queue-head single-beat read-data, and read
burst-last queue-head demux samples.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.121` later shipped generated multi-beat
read-data output-bank behavior for this bounded read burst-last concrete
same-ID queue-head demux family; see
[AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR](AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md).

## Deferred

The slice still fail-closes or defers:

- queue-head multi-beat shapes outside the bounded `.121` output-bank subset;
- deeper or multiple duplicate concrete-ID groups;
- mixed same-family auto-ID plus concrete queue-head response demux;
- generalized per-ID queues;
- direct backend lowering;
- VHDL.

## Validation

The slice was validated with focused generator and PPIF/CLI tests; direct
schedule JSON, strict check JSON, strict semantic JSON, and `--verify-hdl`
coverage for the new public sample; regression probes for existing
queue-head/read-data/burst-length samples; support accounting; mdBook;
documentation path audit; Knowledge Map generation/check; memory
architecture; diff hygiene; README numbering; and stale-frontier scans.
