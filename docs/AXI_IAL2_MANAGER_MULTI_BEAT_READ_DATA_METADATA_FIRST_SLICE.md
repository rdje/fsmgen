# AXI IAL2 Manager Multi-Beat Read-Data Metadata First Slice

Status: implemented parser/report metadata and static validation; generated
multi-beat reassembly/output behavior remains deferred.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.72`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md)

## What Shipped

The public `.ppif` parser now accepts `read-data.read` with
`(capture-scope multi-beat)` and the selected output-bank transaction shape:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))))
```

The support-accounted sample is:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

The new sample participates in strict check JSON, normalized semantic JSON,
schedule JSON, and HDL verification through
`FSM::Support::RegressionCorpus`.

## Static Validation

The parser and normalizer fail closed for unsupported variants:

- `capture-scope multi-beat` requires `completion-source response-demux`;
- the surrounding `response-demux.read` must use generated
  `response_scope burst_last` with a one-bit `last_signal`;
- `status-policy` must be `per-beat`;
- `interleaving` must be `multi-beat-by-rid`;
- `burst-length` is mandatory and must be ARLEN based;
- `burst-length.validation` must be `runtime-assertion`;
- transaction bindings must use `data-output-prefix`,
  `status-output-prefix`, `valid-mask-output`, and `length-output`;
- legacy `data-output` / `status-output` transaction clauses are rejected
  under `capture-scope multi-beat`;
- generated lane names, valid-mask outputs, length outputs, ARLEN storage,
  expected-count storage, beat-count storage, and existing generated names
  must be collision-free;
- transaction coverage must exactly match the generated read response-demux
  auto transactions.

Unsupported packed outputs, scalar `RRESP` aggregation fields, alternate
length sources, report-only validation, same-ID concrete queues, queued or
blocking policy, and VHDL behavior remain rejected or residue.

## Report Shape

Schedule JSON now reports:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    beat_match_source: response_demux_matched_read_beat
    status_policy: per_beat
    status_aggregation: none
    interleaving_policy: multi_beat_by_rid
    burst_length_source: arlen_signal
    burst_length_validation: runtime_assertion
    beat_storage: per_transaction_generated
    output_shape: per_beat_output_bank
    valid_output: per_transaction_valid_mask
    length_output: per_transaction_beat_count
    multi_beat_reassembly_generated_behavior: false
```

Per transaction, the report lists the data/status output prefixes, generated
lane names `PREFIX_0` through `PREFIX_(max_beats - 1)`, valid-mask output
and width, length output and width, ARLEN storage, expected-count storage,
beat-count storage, and validation rules/assertions.

Actual generated artifacts remain intentionally narrower than the selected
public contract:

- generated inputs include `axi0_arlen`, plus existing `RID`/`RLAST` inputs
  from response demux;
- generated storage/rules/assertions include raw-ARLEN capture and
  beat-count/`RLAST` runtime validation;
- generated `RDATA`/`RRESP` payload inputs, per-beat data/status outputs,
  valid masks, length outputs, and payload capture/reassembly rules are not
  emitted yet.

`read_data.residue` remains:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

## Validation Evidence

Focused `.72` validation includes:

- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`

The focused tests prove the public fixture is accepted, check JSON and
semantic JSON keep source identity and support accounting, HDL verification
passes, fail-closed diagnostics reject unsupported variants, and generated
payload outputs remain deferred.

## Selected Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.73
```

`.73` owns a generated multi-beat read-data reassembly/output behavior
readiness audit before adding storage, per-beat output lanes, valid masks,
length outputs, capture rules, residue movement, direct backend behavior, or
VHDL behavior.

## Rollback

Reverting `.72` removes the public multi-beat `.ppif` fixture, parser and
normalizer support, report metadata, support accounting, tests, and docs. The
previous runtime-assertion burst-length and report-only behavior remain
unchanged by the slice.
