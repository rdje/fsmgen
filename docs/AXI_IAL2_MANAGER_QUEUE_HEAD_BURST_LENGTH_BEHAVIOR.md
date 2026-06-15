# AXI IAL2 Manager Queue-Head Burst-Length Behavior

Status: shipped.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.117`

## Summary

This slice ships generated raw-`ARLEN` burst-length capture for the bounded
read burst-last concrete same-ID queue-head last-beat read-data shape.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.119` later ships generated queue-head
beat-count/`RLAST` runtime validation for the sibling
`validation runtime-assertion` shape; this document remains the report-only
burst-length behavior note.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_last_beat_same_id_queue_head_burst_length.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
```

## Supported Shape

The supported boundary is intentionally narrow:

- one read response-demux family with `response-scope burst-last`;
- one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth 2;
- generated queue-head response-demux completion pulses qualified by `RLAST`;
- `read-data.read.capture-scope last-beat`;
- `read-data.read.completion-source response-demux`;
- `read-data.read.status-policy last-beat`;
- `read-data.read.interleaving last-beat-by-rid`;
- `read-data.read.burst-length` with `source arlen`, width 8,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation report-only`.

Queue-head burst-length capture is report-only in this slice. For the
runtime-validation sibling, see
[AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md).

## Generated Behavior

FSMGen emits `axi0_arlen` as a generated width-8 input alongside the existing
last-beat payload/status inputs:

```lisp
(input axi0_arlen (width 8))
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

Each covered read transaction gets raw-`ARLEN` storage:

```lisp
(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))
```

The raw `ARLEN` value is captured on the corresponding transaction request,
not on the response beat:

```lisp
(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))

(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

The last-beat `RDATA`/`RRESP` capture remains guarded by the generated
queue-head last-beat completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

## Report Contract

The schedule report keeps the queue-head last-beat completion-validity value
and adds the generated burst-length fields:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_validity:
      generated_queue_head_response_demux_last_beat_completion_pulse
    burst_length_source: arlen_signal
    burst_length_signal: axi0_arlen
    burst_length_signal_direction: generated_input
    burst_length_signal_width: 8
    burst_length_encoding: axlen_plus_one
    burst_length_capture: transaction_request
    burst_length_validation: report_only
    burst_length_generated_behavior: true
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
      - axi0_arlen
    generated_burst_length_storage:
      - axi0_r0_arlen_q
      - axi0_r1_arlen_q
    generated_burst_length_rules:
      - axi0_r0_burst_length_capture
      - axi0_r1_burst_length_capture
```

Existing report values remain stable for the auto-ID burst-length sample,
queue-head last-beat read-data without burst-length metadata, queue-head
single-beat read-data, auto-ID last-beat read-data, auto-ID multi-beat
read-data, the queue-head runtime-validation burst-length sample, and read
burst-last queue-head demux.

## Deferred

The report-only slice still fail-closes or defers:

- multi-beat queue-head read-data;
- deeper or multiple duplicate concrete-ID groups;
- mixed same-family auto-ID plus concrete queue-head response demux;
- generalized per-ID queues;
- direct backend lowering;
- VHDL.

## Validation

The slice was validated with focused generator and PPIF/CLI tests; direct
schedule JSON, strict check JSON, strict semantic JSON, and `--verify-hdl`
coverage for the new public sample; regression checks for the existing
queue-head/read-data/burst-length samples; support accounting; mdBook;
documentation path audit; Knowledge Map generation/check; memory
architecture; diff hygiene; README numbering; and stale-frontier scans.
