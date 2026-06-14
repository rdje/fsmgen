# AXI IAL2 Manager Post Multi-Beat Output Next Slice Selection

Status: selection complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.75`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)

## Evidence Read

The public multi-beat sample is:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

The live schedule report for that sample now confirms the shipped `.74`
output-bank behavior:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  residue:
    - rresp_aggregation
  read:
    capture_scope: multi_beat
    status_policy: per_beat
    status_aggregation: none
    output_shape: per_beat_output_bank
    valid_output: per_transaction_valid_mask
    length_output: per_transaction_beat_count
    multi_beat_reassembly_generated_behavior: true
```

The generated artifact lists include `RDATA`, `RRESP`, and `ARLEN` inputs,
per-beat data lanes, per-beat status lanes, valid-mask outputs, length
outputs, request-time output initialization rules, and one lane capture rule
per transaction per supported beat.

The current public source has no scalar aggregation spelling. The PPIF parser
accepts `status-policy per-beat` for `capture-scope multi-beat` and has no
`status-aggregation` clause. The normalizer and report hard-code
`status_aggregation: none` for multi-beat read-data. The focused tests assert
that the multi-beat report keeps only `rresp_aggregation` in read-data
residue.

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.76
```

`.76` owns public AXI multi-beat scalar `RRESP` aggregation contract
selection. It must select the source and report contract before any parser,
generator, HDL, sample, support-accounting, check JSON, semantic JSON, or
validation behavior changes.

## Why RRESP Aggregation Next

Scalar `RRESP` aggregation is now the only remaining `read_data.residue` item
for the public multi-beat sample. The preceding slices already selected and
shipped the prerequisites that aggregation can build on:

- generated burst-last read response demux and matched-read-beat expressions;
- generated raw ARLEN capture;
- generated beat-count/`RLAST` runtime validation;
- generated per-beat `RDATA` and `RRESP` output-bank lanes;
- generated valid-mask and length outputs.

Per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy,
profile aliases, full-manager behavior, direct backend work, and VHDL are
broader than the immediate read-data residue. They should remain deferred
until the scalar status contract is selected or an explicit later selector
chooses them.

Direct generated scalar aggregation behavior is still premature. The public
contract has not selected:

- the aggregation spelling;
- the scalar output binding;
- the aggregation policy;
- whether per-beat status lanes remain mandatory when scalar aggregation is
  requested;
- how aggregation interacts with valid-mask and length outputs;
- what happens when runtime validation finds missing or extra beats;
- generated artifact names and residue movement;
- parser diagnostics for unsupported combinations.

## Required Decisions For `.76`

The `.76` selector must decide:

- whether aggregation is an additive clause under the existing `read-data`
  read arm or a transaction-local binding;
- whether the first policy is last-beat status, first non-OK status, worst
  observed status, sticky non-OK status, or another source-anchored rule;
- the normalized report vocabulary for the selected policy;
- the scalar output name, direction, and fixed width;
- whether per-beat status output prefixes stay required for the first scalar
  aggregation contract;
- how the scalar output is initialized on request and updated on each matched
  read beat;
- how aggregation uses `valid_mask_output`, `length_output`, and
  beat-count/`RLAST` runtime validation;
- whether generated behavior should be a later implementation slice after
  parser/report metadata, or whether `.76` should select a smaller readiness
  audit first;
- exact diagnostics, generated artifact names, residue movement, docs,
  Knowledge Map updates, validation gates, rollback, direct-backend deferral,
  and VHDL deferral.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, SystemVerilog HDL, samples, support accounting,
check JSON, semantic JSON, or validation behavior.

`.76` should not implement per-ID read-data queues, authored concrete-ID
same-ID ordering queues, different-ID ordering beyond the already selected
`multi-beat-by-rid` output-bank behavior, queued/blocking submission policy,
profile aliases, full-manager syntax, direct backend lowering, or VHDL
backend/reroute behavior unless a future exact owner selects that work.

## Validation Gates For `.75`

Because `.75` is documentation/task-tree selection only, validation should run
at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.75` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the active frontier to `.75`
with `.74` output-bank behavior shipped but no selected next AXI manager
owner after the `rresp_aggregation` residue.
