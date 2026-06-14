# AXI IAL2 Manager Beat-Count/RLAST Runtime Validation First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.69`

This slice ships the first behavior-bearing generated AXI read-data
beat-count and `RLAST` validation path for explicit last-beat `read-data`
contracts with ARLEN-based `burst-length` metadata.

## Public Contract

The public `.ppif` parser and in-process contract normalizer now accept both
validation modes under `read-data.read.burst-length`:

```text
(validation report-only)
(validation runtime-assertion)
```

`report-only` remains metadata and raw-ARLEN capture only. It does not
generate expected-count storage, beat counters, or runtime assertions.

`runtime-assertion` is generated validation behavior. It is accepted only with
the existing last-beat read-data, generated burst-last response-demux, source
`arlen`, width-8 signal, `axlen-plus-one` encoding, request capture, and
`max-beats 1..256` constraints.

The runnable public fixture is:

```text
ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif
```

Its burst-length clause is:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

## Generated IAL1

For each covered read transaction, the generator adds one expected-beat-count
register, one matched-read-beat counter, an initialization rule, and a matched
response-beat increment rule.

For the `r0` transaction in the public fixture, generated IAL1 includes:

```text
(var axi0_r0_expected_beats_q (width 5))
(var axi0_r0_read_beat_count_q (width 5))

(rule axi0_r0_beat_count_init axi0_r0_request
  (axi0_r0_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r0_read_beat_count_q 0))

(rule axi0_r0_read_beat_count
  (& (& axi0_read_complete
        (& axi0_r0_auto_id_busy_q (== axi0_rid axi0_r0_auto_id_q)))
     (! axi0_r0_request))
  (axi0_r0_read_beat_count_q (+ axi0_r0_read_beat_count_q 5'd1)))
```

The expected count is `ARLEN + 1`, sliced to the generated counter width. The
increment rule counts every accepted read response beat whose `RID` matches
the active selected ID for the transaction. The guard excludes the same
transaction's request event so one rule initializes a new transaction while
the other only increments an already-active transaction.

## Runtime Assertions

The generated assertion transaction emits four assertions per covered read
transaction:

```text
axi0_r0_arlen_within_max
axi0_r0_read_beat_before_expected_count
axi0_r0_rlast_on_expected_beat
axi0_r0_expected_final_beat_has_rlast
```

The checks cover:

- request-time ARLEN bound against configured `max-beats`;
- any matched beat arriving after the expected count is exhausted;
- `RLAST` asserted before the expected final beat;
- the expected final beat arriving without `RLAST`.

For the public `max-beats 16` fixture, the scheduled `.fsm` ARLEN-bound
assertion uses a strict less-than comparison:

```text
(axi0_read_data_beat_count_checks_assert_0 assert
  (=> axi0_r0_request (< axi0_arlen 8'd16))
  "axi0 r0 ARLEN is within configured max beats")
```

The strict comparison avoids strict-mode ambiguity with assignment syntax and
keeps the SystemVerilog comparison width-clean. The generated SystemVerilog
lowers the assertions to clocked properties disabled during reset.

## Schedule Report

For the runtime-assertion fixture, schedule JSON reports:

```text
read_data:
  read:
    burst_length_validation: runtime_assertion
    beat_count_validation_generated_behavior: true
    expected_beat_count_encoding: arlen_plus_one
    beat_count_match_source: response_demux_matched_read_beat
    beat_count_width: 5
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
    generated_beat_count_assertions:
      - axi0_r0_arlen_within_max
      - axi0_r0_read_beat_before_expected_count
      - axi0_r0_rlast_on_expected_beat
      - axi0_r0_expected_final_beat_has_rlast
      - axi0_r1_arlen_within_max
      - axi0_r1_read_beat_before_expected_count
      - axi0_r1_rlast_on_expected_beat
      - axi0_r1_expected_final_beat_has_rlast
```

Per-transaction report entries also name that transaction's expected-count
storage, beat-count storage, initialization rule, increment rule, and
assertion names.

The runtime-assertion read-data residue removes:

```text
generated_beat_count_validation
```

and keeps:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

## Report-Only Compatibility

The existing report-only fixture remains behavior-identical except for the
wider accepted validation vocabulary. It still reports:

```text
burst_length_validation: report_only
```

and does not report generated beat-count validation state, rules, or
assertions. Its read-data residue still includes
`generated_beat_count_validation`.

## Support Accounting

The runtime-assertion fixture is support-accounted for strict check JSON and
normalized semantic JSON:

```text
intent.ppif_axi_manager_capacity_status_read_data_burst_length_runtime_assertion
```

Strict check JSON and semantic JSON preserve the public `.ppif` source path
and match that corpus entry.

## Deferred Work

This slice intentionally leaves these behaviors out of scope:

- multi-beat payload storage and reassembly;
- per-beat public outputs;
- `RRESP` aggregation across a burst;
- public beat-index outputs;
- per-ID read-data queues;
- queued/blocking policy and full-manager profile aliases;
- direct backend lowering;
- VHDL backend/reroute behavior.

The next selected task-tree leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.70`, a selector for the next exact AXI
manager feature-completeness owner after generated beat-count/RLAST runtime
validation.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-69-runtime.sv ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif
```
