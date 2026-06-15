# AXI IAL2 Manager Queue-Head Last-Beat Read-Data Behavior

Status: shipped.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.115`

## Summary

This slice ships generated last-beat `RDATA`/`RRESP` capture when
`read-data` consumes the generated read burst-last concrete same-ID
queue-head response demux from `.106`.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_last_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
```

## Supported Shape

The implemented boundary is intentionally narrow:

- one read response-demux family with `response-scope burst-last`;
- one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth 2;
- generated queue-head response-demux completion pulses qualified by `RLAST`;
- `read-data.read.capture-scope last-beat`;
- `read-data.read.completion-source response-demux`;
- `read-data.read.status-policy last-beat`;
- `read-data.read.interleaving last-beat-by-rid`;
- no queue-head `burst-length` metadata in the `.115` slice.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.117` later ships report-only
queue-head raw-`ARLEN` burst-length capture for this same bounded shape; see
[AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md).
`IAL2-FEATURE-COMPLETENESS-FRONTIER.119` later ships generated
beat-count/`RLAST` runtime validation for the same bounded shape with
`validation runtime-assertion`; see
[AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md).

FSMGen derives read-data transaction coverage from the generated queue-head
read group and generated completion signals, not from auto-ID transaction
metadata.

## Generated Behavior

For the public sample, FSMGen emits generated source inputs for the matched
last read beat:

```lisp
(input axi0_rlast)
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It emits per-transaction last-beat data/status outputs:

```lisp
(output axi0_r0_last_rdata (width 32))
(output axi0_r0_last_rresp (width 2))
(output axi0_r1_last_rdata (width 32))
(output axi0_r1_last_rresp (width 2))
```

The queue-head response demux remains the owner of transaction completion
pulses. Read-data capture uses those generated last-beat queue-head pulses as
ordinary guarded assignment rules:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_last_rdata axi0_rdata)
  (axi0_r1_last_rresp axi0_rresp))
```

The generated queue-head demux rules remain `RID` plus `RLAST` plus queue-head
slot matches:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

## Report Contract

The schedule report marks this queue-head last-beat path distinctly:

```text
response_demux.read:
  response_scope: burst_last
  transaction_completion_source: generated_queue_head_demux
  generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  generated_completion_signals:
    - axi0_r0_complete
    - axi0_r1_complete

read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_validity:
      generated_queue_head_response_demux_last_beat_completion_pulse
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_last_rdata
      - axi0_r0_last_rresp
      - axi0_r1_last_rdata
      - axi0_r1_last_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

Existing report values remain stable:

- auto-ID single-beat read-data:
  `generated_read_response_demux_completion_pulse`;
- queue-head single-beat read-data:
  `generated_queue_head_response_demux_completion_pulse`;
- auto-ID last-beat read-data:
  `generated_read_response_demux_last_beat_completion_pulse`.

The static-rule and unsupported-residue prose now list generated read
burst-last queue-head last-beat read-data as supported, while keeping
multi-beat queue-head read-data deferred. Runtime queue-head burst-length
beat-count/`RLAST` validation is shipped by `.119`, and generated multi-beat
queue-head read-data output-bank behavior is selected by `.120` as `.121`.

## Deferred

The slice still fail-closes or defers:

- multi-beat queue-head read-data until the selected `.121` implementation;
- deeper or multiple duplicate concrete-ID groups;
- mixed same-family auto-ID plus concrete queue-head response demux;
- generalized per-ID queues;
- direct backend lowering;
- VHDL.

## Validation

The slice was validated with syntax checks for the generator, support corpus,
and focused test files; direct schedule, `--check --json`,
`--emit-semantic-json`, and `--verify-hdl` probes for the new public sample;
the focused generator suite; the focused PPIF/CLI suite; regression probes for
existing queue-head single-beat read-data, auto-ID last-beat read-data,
auto-ID multi-beat read-data, and read burst-last queue-head samples;
support-accounting corpus gates; mdBook, documentation path, Knowledge Map,
memory architecture, diff hygiene, README numbering, and stale-frontier
checks.
