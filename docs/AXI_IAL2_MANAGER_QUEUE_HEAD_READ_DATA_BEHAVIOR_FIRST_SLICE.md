# AXI IAL2 Manager Queue-Head Read-Data Behavior First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`

## Summary

This slice ships generated single-beat `RDATA`/`RRESP` capture when
`read-data` consumes the generated read single-beat concrete same-ID
queue-head response demux from `.110`.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
```

## Supported Shape

The implemented boundary is intentionally narrow:

- one read response-demux family with `response-scope single-beat`
- one duplicate concrete read-ID group
- exactly two read transactions in that group
- computed queue depth 2
- generated queue-head response-demux completion pulses
- `read-data.read.capture-scope single-beat`
- `read-data.read.completion-source response-demux`
- `read-data.read.interleaving single-beat-by-rid`

FSMGen now derives read-data transaction coverage from the generated
queue-head read group and completion signals instead of requiring
`response_demux.read.auto_transactions`.

## Generated Behavior

For the public sample, FSMGen emits the generated source inputs:

```lisp
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It emits per-transaction data/status outputs:

```lisp
(output axi0_r0_rdata (width 32))
(output axi0_r0_rresp (width 2))
(output axi0_r1_rdata (width 32))
(output axi0_r1_rresp (width 2))
```

The queue-head response demux remains the owner of transaction completion
pulses. Read-data capture uses those generated pulses as ordinary guarded
assignment rules:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

The schedule report marks the read-data completion validity distinctly:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    completion_validity: generated_queue_head_response_demux_completion_pulse
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_rdata
      - axi0_r0_rresp
      - axi0_r1_rdata
      - axi0_r1_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

The existing auto-ID read-data path keeps reporting
`generated_read_response_demux_completion_pulse`.

## Deferred

The slice still fail-closes or defers:

- read burst-last queue-head read-data
- last-beat or multi-beat queue-head read-data
- deeper or multiple duplicate concrete-ID groups
- mixed same-family auto-ID plus concrete queue-head response demux
- generalized per-ID queues
- direct backend lowering
- VHDL

## Validation

The slice was validated with syntax checks for the generator, support corpus,
and focused test files; direct schedule and `--verify-hdl` probes for the new
sample plus existing read-data and queue-head samples; the focused generator
suite; the focused PPIF/CLI suite; support-accounting corpus gates; mdBook,
documentation path, Knowledge Map, memory architecture, diff hygiene, README
numbering, and stale-frontier checks.
