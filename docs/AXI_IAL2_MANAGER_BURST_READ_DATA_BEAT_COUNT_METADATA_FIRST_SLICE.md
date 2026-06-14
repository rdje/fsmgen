# AXI IAL2 Manager Burst Read-Data Beat-Count Metadata First Slice

Status: shipped parser/report metadata and static validation; generated
behavior unchanged.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.63`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)

## What Shipped

The public `.ppif` parser now accepts one optional `burst-length` clause under
last-beat read-data contracts:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```

The sample remains an explicit last-beat `RDATA`/`RRESP` capture contract. It
requires generated burst-last read response demux, keeps generated capture
rules driven by generated last-beat transaction completion pulses, and records
ARLEN beat-count metadata only in the schedule report.

## Static Validation

The parser and generator reject:

- duplicate `burst-length` clauses;
- missing or unknown `burst-length` subclauses;
- unsupported sources other than `arlen`;
- malformed or non-8-bit `signal` clauses;
- unsupported encodings other than `axlen-plus-one`;
- unsupported capture boundaries other than `request`;
- missing, zero, or greater-than-256 `max-beats`;
- unsupported validation modes other than `report-only`;
- `burst-length` under single-beat `read-data`;
- last-beat `read-data` paired with non-`burst_last` read response demux;
- signal-name collisions, including collisions with existing generated or
  declared AXI ID/read-data signals.

## Report Contract

Schedule JSON keeps `read_data.generated_behavior: true` because generated
last-beat `RDATA`/`RRESP` capture already ships. The new length contract is
additive:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    burst_length_source: arlen_signal
    burst_length_signal: axi0_arlen
    burst_length_signal_direction: generated_input
    burst_length_signal_width: 8
    burst_length_encoding: axlen_plus_one
    burst_length_capture: transaction_request
    max_beats: 16
    burst_length_generated_behavior: false
    burst_length_validation: report_only
    beat_storage: none
    valid_output: none
    length_output: none
```

The generated artifact lists remain scoped to the shipped last-beat capture:

```text
generated_inputs:
  - axi0_rdata
  - axi0_rresp
generated_rules:
  - axi0_r0_read_data_capture
  - axi0_r1_read_data_capture
```

`axi0_arlen` is not listed as a generated input, generated rule dependency,
`.fsm` signal, or HDL port in this slice.

The read-data residue is now explicit for opt-in ARLEN metadata:

```text
generated_burst_length_capture
generated_beat_count_validation
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

The no-`burst-length` last-beat sample remains valid and continues to report
`burst_length_source: rlast_only` with `burst_length_validation:
not_generated`.

## Generated Artifact Boundary

No generated `.isf`, generated `.fsm`, or HDL behavior changed for the
existing last-beat read-data sample. The new burst-length sample intentionally
generates the same IAL1/IAL0/HDL behavior as the existing last-beat sample,
except for public source identity and schedule-report metadata.

The new sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_data_burst_length
```

It passes check JSON and normalized semantic JSON with public `.ppif` source
identity and the unchanged generated module name `axi0_capacity_status`.

## Deferred Behavior

This slice does not generate:

- ARLEN capture registers;
- expected-beat counters;
- missing/extra/early/late `RLAST` validation;
- beat storage;
- per-beat or packed-burst outputs;
- full read-data reassembly;
- all-beat `RRESP` aggregation;
- per-ID read-data queues;
- direct backend lowering;
- VHDL backend behavior.

Those remain future exact-owner work.

## Validation

Focused validation:

- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`

Additional pre-commit validation should include support-accounting/check JSON,
normalized semantic JSON, mdBook, Knowledge Map, memory architecture, and diff
gates because this slice adds a checked-in `.ppif` sample and a corpus entry.

## Rollback

Reverting this slice removes the public `burst-length` parser/report metadata,
the checked-in sample, the support-accounting entry, and the explicit
ARLEN-specific read-data residue. The existing no-`burst-length` last-beat
read-data capture behavior from `.60` remains intact.
