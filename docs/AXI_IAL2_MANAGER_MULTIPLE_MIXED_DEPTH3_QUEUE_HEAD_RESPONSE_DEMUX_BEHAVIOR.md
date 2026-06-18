# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Response-Demux Behavior

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.174`.

Date: `2026-06-18`.

## Purpose

This slice implements the bounded response-demux-only behavior selected by
`.173`: concrete same-ID queue-head response-demux groups whose computed group
depth is `2` or `3`, with at least one depth-3 group, across:

- read single-beat response demux;
- read burst-last response demux;
- write `BID` response demux.

It adds these public `.ppif` samples:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux.ppif
ppif/axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
```

The `multi_depth3` samples contain two independent depth-3 duplicate-ID
groups. The `mixed_depth3_depth2` samples contain one depth-3 group and one
depth-2 group.

## Generated Behavior

For the covered shapes, FSMGen now generates compact one-hot queue state,
admitted request pulses, finite enqueue/dequeue/same-cycle update rules,
queue integrity assertions, generated transaction completion outputs, and
queue-head response-demux rules for every transaction in every generated
group.

The read single-beat and read burst-last samples generate `RID` demux with
these report boundaries:

```text
generated_read_single_beat_queue_head_demux
generated_read_burst_last_queue_head_demux
```

The write samples generate `BID` demux with this report boundary:

```text
generated_write_bid_queue_head_demux
```

The generated queue and response-demux artifact counts are:

| Sample shape | Queue storage | Queue update rules | Queue assertions | Response-demux rules/completions | Response-demux assertions |
| --- | ---: | ---: | ---: | ---: | ---: |
| read single-beat two depth-3 groups | 18 | 108 | 28 | 6 | 16 |
| read single-beat mixed depth-3/depth-2 groups | 13 | 66 | 25 | 5 | 11 |
| read burst-last two depth-3 groups | 18 | 108 | 30 | 6 | 16 |
| read burst-last mixed depth-3/depth-2 groups | 13 | 66 | 27 | 5 | 11 |
| write two depth-3 groups | 18 | 108 | 28 | 6 | 16 |
| write mixed depth-3/depth-2 groups | 13 | 66 | 25 | 5 | 11 |

Representative generated queue sets:

```text
read multi_depth3:        3:r0/r1/r2:d3,5:r3/r4/r5:d3
read mixed_depth3_depth2: 3:r0/r1/r2:d3,5:r3/r4:d2
write multi_depth3:       3:w0/w1/w2:d3,5:w3/w4/w5:d3
write mixed_depth3_depth2: 3:w0/w1/w2:d3,5:w3/w4:d2
```

Read burst-last demux additionally gates each transaction completion pulse with
the generated one-bit `axi0_rlast` input. Read single-beat and write demux do
not consume `RLAST`.

## Report Surface

The selected family reports generated queue-head response-demux behavior:

```yaml
response_demux:
  read:
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    queue_state_representation: compact_onehot_transaction_slots
```

or:

```yaml
response_demux:
  write:
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    queue_state_representation: compact_onehot_transaction_slots
```

The same-ID policy reports `accepted_same_id_reuse: true`,
`generated_queue_behavior: true`, and one of:

```text
generated_read_single_beat_queue_head_demux
generated_read_burst_last_queue_head_demux
generated_write_bid_queue_head_demux
```

`response_demux.residue` removes `generated_same_id_queue_head_demux` for the
covered family. Write-family samples continue to preserve
`read_response_demux` residue because this slice does not generate read
response behavior for write-only samples.

Each new public sample is support-accounted through check JSON and normalized
semantic JSON under the corresponding `intent.ppif_*` entry, for example:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux
```

## Boundaries

This slice deliberately does not enable:

- read-data over multiple/mixed depth-3 queue-head groups;
- burst-length, runtime-validation, or multi-beat read-data over those groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed outputs or alternate burst assembly;
- direct IAL2-to-backend lowering;
- verification-output generation;
- VHDL or backend-language variants.

Existing one-group depth-3 response-demux samples, multi-group depth-2
response-demux samples, depth-3 read-data/burst-length/runtime-validation/
multi-beat samples, support accounting, and HDL verification behavior remain
preserved.

## Validation

Representative commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_depth3_queue_head_demux.sv ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
```
