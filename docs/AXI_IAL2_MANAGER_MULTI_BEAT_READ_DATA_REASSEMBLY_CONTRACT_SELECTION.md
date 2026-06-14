# AXI IAL2 Manager Multi-Beat Read-Data Reassembly Contract Selection

Status: selected public contract; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.71`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This selector chooses the first public multi-beat AXI read-data reassembly and
output contract after generated beat-count/`RLAST` runtime validation.

The selected contract is a bounded per-beat output bank. It does not select a
packed burst vector or scalar `RRESP` aggregation. The first behavior owner
can fill one data lane and one status lane per accepted matched response beat,
then use the already-generated transaction completion pulse as the validity
strobe for the coherent bank.

This keeps the first contract reviewable and avoids inventing a lossy
all-beat response-status policy.

## Selected Public Syntax

Extend the existing `read-data` read arm with a new capture scope and a
per-transaction output-bank shape:

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
      (length-output axi0_r0_read_beats))
    (transaction r1
      (data-output-prefix axi0_r1_beat_rdata)
      (status-output-prefix axi0_r1_beat_rresp)
      (valid-mask-output axi0_r1_beat_valid)
      (length-output axi0_r1_read_beats))))
```

`capture-scope multi-beat` means the read-data owner captures every accepted
read response beat whose `RID` matches an active generated transaction, not
only the last beat.

`completion-source response-demux` remains mandatory. The surrounding
`response-demux.read` arm must use `response-scope burst-last`,
`transaction-completion generated`, and a one-bit `last-signal`, because the
generated transaction completion pulse remains the coherent-bank validity
strobe.

`burst-length` is mandatory for this first multi-beat contract. It must use
the shipped ARLEN shape and must select `(validation runtime-assertion)`.
Report-only length metadata is not enough for generated reassembly because it
would allow length mismatches to silently corrupt the output bank.

`status-policy per-beat` means each captured beat carries its own `RRESP`
lane. The selector intentionally does not choose a scalar aggregate status
such as first-error or max-severity.

`interleaving multi-beat-by-rid` means generated read-data reassembly uses the
same active-transaction plus `RID` match source as generated read response
demux. Different generated auto-ID read transactions may receive interleaved
beats. Same-ID generated auto-ID concurrency remains prevented by the shipped
same-ID avoidance behavior, and concrete-ID same-ID queues remain deferred.

For each transaction:

- `data-output-prefix PREFIX` generates one width-`data_signal_width` output
  lane per beat, named `PREFIX_0` through `PREFIX_(max_beats - 1)`;
- `status-output-prefix PREFIX` generates one width-2 output lane per beat,
  named `PREFIX_0` through `PREFIX_(max_beats - 1)`;
- `valid-mask-output NAME` generates one width-`max_beats` bit mask whose bit
  `i` marks lane `i` valid for the completed burst;
- `length-output NAME` generates one output whose width is the beat-count
  counter width for inclusive range `0..max_beats`;
- the existing generated transaction completion pulse remains the validity
  strobe for consuming the bank and mask.

The selected output lane index is zero-based. Lane 0 is the first accepted
matched read beat after the corresponding request. The expected final lane is
`length_output - 1`, and generated runtime validation already checks that
`RLAST` appears there.

## Static Contract

The parser/report metadata owner must enforce:

- `capture-scope multi-beat` is accepted only under `(read-data (read ...))`;
- `completion-source` must be `response-demux`;
- the surrounding read response-demux must be generated `response_scope
  burst_last` with a one-bit `last_signal`;
- `status-policy` must be `per-beat`;
- `interleaving` must be `multi-beat-by-rid`;
- `burst-length` is required and must be the ARLEN-based shape already
  selected by `.62`;
- `burst-length.validation` must be `runtime-assertion`;
- `max-beats` remains in `1..256`;
- every generated read response-demux auto transaction must have exactly one
  multi-beat transaction binding;
- each transaction binding must use `data-output-prefix`,
  `status-output-prefix`, `valid-mask-output`, and `length-output`;
- generated lane names, valid masks, length outputs, generated storage, and
  existing generated names must be collision-free;
- legacy last-beat transaction fields `data-output` and `status-output` are
  not accepted for `capture-scope multi-beat`;
- packed burst outputs, scalar `RRESP` aggregation outputs, custom lane
  counts, non-ARLEN length sources, report-only validation, same-ID concrete
  queues, queued/blocking policy, and VHDL behavior fail closed.

The shipped `single-beat` and `last-beat` capture scopes remain valid and
unchanged.

## Report Contract

The parser/report metadata slice should keep schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and report the
selected shape without claiming generated reassembly behavior yet:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    beat_match_source: response_demux_matched_read_beat
    data_signal: axi0_rdata
    data_signal_direction: generated_input
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_direction: generated_input
    status_signal_width: 2
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
    transactions:
      - transaction: r0
        data_output_prefix: axi0_r0_beat_rdata
        generated_data_outputs:
          - axi0_r0_beat_rdata_0
          - ...
        status_output_prefix: axi0_r0_beat_rresp
        generated_status_outputs:
          - axi0_r0_beat_rresp_0
          - ...
        valid_mask_output: axi0_r0_beat_valid
        valid_mask_width: 16
        length_output: axi0_r0_read_beats
        length_output_width: 5
```

The metadata slice should keep `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` in residue until generated
behavior ships. When a later behavior owner emits storage, rules, and outputs,
it may remove `multi_beat_read_data_reassembly` and `per_beat_outputs`.
`rresp_aggregation` remains residue until a scalar aggregate status policy is
explicitly selected.

## Selected Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.72
```

`.72` owns parser/report metadata and static validation for the selected
multi-beat read-data reassembly/output contract. It must not generate
multi-beat storage, output lanes, valid masks, length outputs, or reassembly
rules yet. It may add a checked-in `.ppif` sample only if generated `.isf`,
generated `.fsm`, HDL, support-accounting source identity, check JSON source
identity, and normalized semantic JSON source identity remain controlled and
explicitly verified.

## Future Behavior Boundary

After `.72` ships parser/report metadata, later exact owners may implement:

- generated per-transaction beat storage;
- generated per-beat data/status output lanes;
- generated valid-mask and length outputs;
- matched-beat capture rules indexed by per-transaction beat count;
- residue movement for `multi_beat_read_data_reassembly` and
  `per_beat_outputs`;
- optional scalar `RRESP` aggregation, only after a separate public policy
  selector;
- concrete-ID same-ID queues and broader per-ID ordering, only after exact
  ownership.

## Validation Gates For `.71`

Because `.71` is selection only, validation should run at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.71` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the active frontier to `.71`
with `.70` having selected multi-beat reassembly/output contract selection
but no concrete public syntax recorded.
