# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Multi-Beat Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.191` on
2026-06-19.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.191`

## Public Samples

The runnable PPIF samples are:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_depth3_multi_beat_read_data.sv ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif

./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_depth3_depth2_multi_beat_read_data.sv ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
```

The first sample covers two duplicate concrete read-ID groups: `r0`, `r1`,
and `r2` share concrete `RID` `3`, and `r3`, `r4`, and `r5` share concrete
`RID` `5`. Both groups have computed depth `3`.

The second sample covers mixed group depths: `r0`, `r1`, and `r2` share
concrete `RID` `3` with computed depth `3`, while `r3` and `r4` share
concrete `RID` `5` with computed depth `2`.

Both samples use `capture-scope multi-beat`, `completion-source
response-demux`, `status-policy per-beat`, worst-observed scalar `RRESP`
aggregation, `interleaving multi-beat-by-rid`, and runtime-assertion
`ARLEN` burst-length metadata.

## Generated Behavior

FSMGen now accepts generated multi-beat output-bank read-data behavior for
bounded multiple/mixed read burst-last concrete same-ID queue-head groups when:

- every duplicate read queue-head group has computed depth `2` or `3`;
- every depth-2 group has exactly two transactions;
- every depth-3 group has exactly three transactions;
- at least one depth-3 group is present;
- the read-data contract uses runtime-assertion `ARLEN` burst-length metadata.

For each covered transaction, generation emits:

- generated `axi0_rid`, `axi0_rlast`, `axi0_rdata`, `axi0_rresp`, and
  `axi0_arlen` inputs;
- generated queue-head burst-last response demux with one-bit `RLAST`
  completion pulses;
- raw `ARLEN` storage and request-time capture rules;
- expected-beat storage, read-beat counters, beat-count initialization and
  matched-read-beat counter rules;
- generated beat-count and `RLAST` runtime assertions;
- sixteen `RDATA` lanes and sixteen `RRESP` lanes;
- one valid-mask output, one read-length output, and one scalar
  worst-observed `RRESP` aggregate output;
- one request-time output-bank clear rule;
- sixteen lane-capture rules guarded by the raw matched queue-head read beat
  and the transaction's read-beat count;
- one scalar `RRESP` aggregate update rule.

The two-depth-3 sample emits those artifacts for six transactions, including
96 `RDATA` lanes, 96 `RRESP` lanes, six valid masks, six length outputs, six
scalar `RRESP` aggregate outputs, 96 lane-capture rules, twelve beat-count
rules, and twenty-four beat-count/`RLAST` assertions.

The mixed depth-3/depth-2 sample emits those artifacts for five transactions,
including 80 `RDATA` lanes, 80 `RRESP` lanes, five valid masks, five length
outputs, five scalar `RRESP` aggregate outputs, 80 lane-capture rules, ten
beat-count rules, and twenty beat-count/`RLAST` assertions.

## Report Contract

Schedule JSON reports:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
read_data.mode:
  bounded_multi_beat_read_data_contract
read_data.read.output_shape:
  per_beat_output_bank
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_validation:
  runtime_assertion
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.residue:
  []
response_demux.residue:
  []
```

The two-depth-3 sample reports queue depths `[3, 3]` and transactions
`[r0, r1, r2, r3, r4, r5]`. The mixed sample reports queue depths `[3, 2]`
and transactions `[r0, r1, r2, r3, r4]`.

## Support Accounting And Semantic Introspection

The public samples are support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data
```

Strict check JSON and normalized semantic JSON report those entries, the
`supported_smoke` classification, the generated module name
`axi0_capacity_status`, and their respective coverage buckets:

```text
ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_pipeline_cli
```

## Admission Boundary

The generated behavior remains limited to read-family burst-last
queue-head-demux contracts with duplicate concrete `RID` groups, depth-2 or
depth-3 group sizes matching their computed depths, at least one depth-3
group, runtime-assertion `ARLEN` metadata, and complete per-transaction
multi-beat output bindings.

This slice does not broaden parser syntax, same-family mixed auto-ID plus
concrete queue-head demux, group-local simultaneous enqueue widening, packed
burst-vector outputs, alternate full burst payload assembly, direct backend
lowering, verification-output generation, VHDL, or backend-language variants.

## Preserved Behavior

The `.186` scalar last-beat runtime-validation samples remain generated with
their existing scalar `RDATA`/`RRESP` outputs and without multi-beat output
banks. The `.183` report-only raw-`ARLEN` samples, `.180` no-`burst_length`
samples, one-depth-3 multi-beat sample, depth-2 multi-group multi-beat sample,
depth-2 multi-group runtime-validation sample, write-family queue-head
behavior, existing support-accounting identities, strict check/semantic JSON,
and HDL output remain preserved.

## Verification

The `.191` implementation was checked with syntax checks, direct schedule
JSON probes for both new PPIF samples, direct strict check JSON probes, direct
HDL verification probes, the focused AXI manager generator suite, the full
PPIF/CLI suite, regression-corpus support gates, Knowledge Map
generation/check, mdBook build, docs relative-path audit, memory-architecture
check, diff hygiene, README numbering, and stale/positive frontier scans.
