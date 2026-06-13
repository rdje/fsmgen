# AXI IAL2 Manager Burst Read-Data Contract Selection

Status: selected bounded public contract; no parser, generator, HDL, sample,
CLI, or test behavior changed by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.57`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This selector chooses the first public read-data contract that can be paired
with generated burst-last `RLAST` completion behavior.

The selected boundary is explicit last-beat payload/status capture. It is not
full burst reassembly. It captures the `RDATA` and `RRESP` values present on
the matched `RID` beat whose `RLAST` signal completes a transaction. It does
not capture every beat, pack a burst, count beats, validate `ARLEN`, aggregate
all `RRESP` values, or provide per-ID reassembly queues.

This is intentionally smaller than multi-beat reassembly because the generated
`response-demux` contract already owns the exact last-beat completion pulse.
The missing public contract is what data/status value that pulse may capture
and how the report must name that bounded behavior.

## Selected Public Syntax

Extend the existing `read-data` read arm with an additional capture scope:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The shipped single-beat form remains valid and unchanged:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    ...))
```

`capture-scope last-beat` means the generated read response-demux completion
pulse is the last-beat validity strobe for the transaction. The data/status
outputs hold the values sampled from the accepted matched `RID` beat where
`RLAST` is asserted.

`completion-source response-demux` remains mandatory. For last-beat capture,
the response-demux read arm must use `response-scope burst-last`, must have a
one-bit `last-signal`, and must use `transaction-completion generated`.

`status-policy last-beat` is mandatory for this capture scope. AXI carries
`RRESP` per beat; this first bounded contract does not aggregate all beat
statuses. It reports and later captures only the `RRESP` value on the last
beat. Full response aggregation needs a later exact owner.

`interleaving last-beat-by-rid` means the last beat is associated with a
transaction by generated `RID` matching. It does not claim per-beat
reassembly across interleaved different-ID bursts. Non-last beats remain
owned by response-demux matching/assertion behavior, not by read-data capture.

No `ARLEN`, expected beat count, fixed depth, packed output, per-beat output,
length output, or valid output is selected in this contract. The generated
transaction completion pulse remains the validity strobe.

## Static Contract

The first parser/report implementation must enforce:

- `read-data` remains optional and may appear at most once under
  `manager-capacity-status`;
- the first supported family subclause is still exactly one `(read ...)` arm;
- `(read ...)` supports `capture-scope single-beat` and
  `capture-scope last-beat`;
- `capture-scope single-beat` keeps the shipped syntax and report behavior;
- `capture-scope last-beat` requires `completion-source response-demux`;
- `capture-scope last-beat` requires generated read response-demux metadata
  with `response_scope burst_last`;
- `capture-scope last-beat` requires exactly one `status-policy last-beat`;
- `capture-scope single-beat` rejects `status-policy` until an exact owner
  selects a single-beat status-policy alias;
- `(data-signal NAME (width N))` still requires a positive integer width;
- `(status-signal NAME (width 2))` still requires AXI4 width `2`;
- `(interleaving last-beat-by-rid)` is required for last-beat capture;
- transaction bindings must exactly cover generated read response-demux auto
  transactions, as in the shipped single-beat contract;
- output names must be collision-free with authored names, generated
  response-demux completion names, generated auto-ID state, generated status
  outputs, and other read-data names;
- packed burst outputs, per-beat outputs, valid outputs, length outputs,
  `ARLEN`, beat-count clauses, fixed-depth clauses, `RRESP` aggregation
  clauses, and alternate interleaving policies are rejected in this first
  contract.

The implementation should keep the existing diagnostic for pairing the
current single-beat read-data shape with burst-last response demux until the
new `capture-scope last-beat` branch is parsed and normalized. After that,
the diagnostic should distinguish:

- single-beat read-data requires `response_scope single_beat`;
- last-beat read-data requires `response_scope burst_last`;
- full multi-beat read-data reassembly is still unsupported.

## Report Contract

The parser/report metadata slice should keep schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and extend the
existing `read_data` key.

For the selected parser/report metadata slice before generated behavior:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    data_signal: axi0_rdata
    data_signal_direction: generated_input
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_direction: generated_input
    status_signal_width: 2
    status_policy: last_beat
    status_aggregation: none
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    beat_storage: none
    valid_output: none
    length_output: none
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_last_rdata
        status_output: axi0_r0_last_rresp
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_last_rdata
        status_output: axi0_r1_last_rresp
  residue:
    - generated_last_beat_read_data_capture
    - multi_beat_read_data_reassembly
    - per_beat_outputs
    - rresp_aggregation
    - arlen_or_beat_count_validation
```

For the shipped single-beat scope, existing `read_data` report behavior must
remain unchanged except for any additive documentation references to the new
scope.

After a later behavior owner ships generated last-beat data/status capture,
that owner may set `read_data.generated_behavior: true`, report generated
input/output/rule artifacts, remove `generated_last_beat_read_data_capture`
from `read_data.residue`, and keep multi-beat reassembly, per-beat outputs,
`RRESP` aggregation, `ARLEN` or beat-count validation, per-ID queues, and
VHDL as residue.

## Generated Artifact Boundary

The selected next owner is parser/report metadata and static validation only:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.58
```

That owner should:

- parse and validate `capture-scope last-beat` plus
  `status-policy last-beat`;
- require generated burst-last read response-demux metadata for the new
  capture scope;
- normalize the structural last-beat read-data metadata;
- report `read_data.generated_behavior: false`;
- add a runnable `.ppif` sample or extend the burst-last sample only if
  generated `.isf`, `.fsm`, and HDL behavior remain unchanged;
- keep shipped single-beat read-data behavior intact;
- update check JSON and normalized semantic JSON support accounting;
- keep mdBook, roadmap, task tree, Knowledge Map, and memory in the same
  commit.

Generated `RDATA`/`RRESP` input declarations for the new sample,
transaction-bound last-beat output updates, generated capture rules, HDL
reachability, and residue movement require a later exact behavior owner.

## Future Behavior Boundary

A later behavior owner may use this contract to:

- declare `RDATA` and `RRESP` as generated IAL1 inputs for the burst-last
  sample;
- declare per-transaction last-beat data/status outputs with inherited widths;
- on each generated last-beat read demux completion pulse, capture
  `RDATA`/`RRESP` into the matching transaction outputs;
- keep the generated completion pulse as the validity strobe;
- report generated data-capture inputs, outputs, rules, and unchanged
  multi-beat residue;
- prove `--verify-hdl` for the public last-beat read-data sample.

That future behavior remains last-beat-only. It must not claim full burst
assembly, per-beat output coverage, `ARLEN` validation, missing/extra beat
validation, all-beat `RRESP` aggregation, per-ID response queues, or VHDL
backend behavior.

## Diagnostics Expected In The Parser/Report Slice

The parser/report implementation should reject:

- duplicate `read-data` clauses;
- missing, duplicate, or unsupported read family arms;
- capture scopes other than `single-beat` or `last-beat`;
- `capture-scope last-beat` without `completion-source response-demux`;
- `capture-scope last-beat` without generated `response_scope burst_last`;
- `capture-scope last-beat` without exactly one `status-policy last-beat`;
- `capture-scope single-beat` with `status-policy` in this first extension;
- missing or malformed `data-signal` or `status-signal` entries;
- non-positive data widths or `RRESP` widths other than `2`;
- interleaving policies other than `single-beat-by-rid` for single-beat and
  `last-beat-by-rid` for last-beat;
- duplicate, missing, unknown, or incomplete transaction bindings;
- transaction coverage that does not match generated read response-demux auto
  transactions;
- output name collisions;
- any packed output, per-beat output, valid output, length output, `ARLEN`,
  expected beat-count, fixed-depth, status aggregation, or full-reassembly
  clause.

## Validation Gates

The parser/report implementation should run at least:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Residue

Still out of scope after this selector until later exact owners:

- parser/report implementation of the selected last-beat `read-data` clause;
- generated last-beat `RDATA`/`RRESP` capture behavior;
- full multi-beat read-data reassembly;
- per-beat outputs or packed burst outputs;
- `RRESP` aggregation across all beats;
- `ARLEN`, expected beat count, or fixed-depth validation;
- missing `RLAST`, extra beats after `RLAST`, or beat-count consistency
  validation;
- different-ID multi-beat read-data reassembly queues;
- same-ID concrete-ID issue-order queues;
- subordinate read-data reordering-depth modeling;
- chunking, atomics, exclusives, or broader B3 transaction classes;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- direct backend lowering;
- VHDL backend or VHDL rerouting behavior.

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, Memory,
and Knowledge Map state. Reverting the selector removes the public contract
selection and returns the frontier to post-`RLAST` read-data contract choice.
