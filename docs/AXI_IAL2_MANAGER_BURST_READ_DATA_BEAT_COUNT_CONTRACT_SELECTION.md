# AXI IAL2 Manager Burst Read-Data Beat-Count Contract Selection

Status: selected public contract; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.62`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This selector chooses the first public beat-count/depth contract for future
AXI burst read-data work.

The generated last-beat capture path can identify the matching transaction
when `RLAST` is asserted, but full multi-beat reassembly needs an expected
beat count, a bounded storage depth, and diagnostics for length mismatch before
it can be implemented honestly. This slice selects only that public contract.
It does not parse the syntax, generate beat counters, allocate storage,
assemble payloads, aggregate `RRESP`, or change HDL.

## Selected Public Syntax

Extend the existing last-beat `read-data` read arm with one optional
`burst-length` clause:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation report-only))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The first selected source is AXI `ARLEN`, not a generic expected-count signal,
because AXI already carries burst length on the read address channel. The
selected encoding is `axlen-plus-one`: expected beats are `ARLEN + 1`.

`max-beats` is mandatory with `source arlen`. It gives later generated storage
or validation owners a fixed upper bound and lets the parser reject impossible
or ambiguous unbounded reassembly contracts. For AXI4, the selected static
range is:

```text
1 <= max-beats <= 256
```

`capture request` means the future generated behavior must sample the ARLEN
signal at the matching logical read transaction request boundary. The current
capacity/status contract already has per-transaction read request events; the
first behavior owner must bind length capture to those events, not to response
beats.

`validation report-only` means the next parser/report slice records the
selected length contract but does not generate counters, assertions, missing
beat checks, extra beat checks, early `RLAST` checks, late `RLAST` checks, or
storage.

## Static Contract

The parser/report metadata owner must enforce:

- `burst-length` is accepted only under `(read-data (read ...))`;
- the first supported `burst-length` source is exactly `arlen`;
- `source arlen` requires exactly one `(signal NAME (width 8))`;
- `encoding` is required and must be `axlen-plus-one`;
- `capture` is required and must be `request`;
- `max-beats` is required, positive, and no greater than `256`;
- `validation` is required and must be `report-only` in the first metadata
  slice;
- the surrounding read-data contract must use `capture-scope last-beat`,
  `completion-source response-demux`, `status-policy last-beat`, and
  `interleaving last-beat-by-rid`;
- the surrounding response demux must still use generated
  `response_scope burst_last`;
- duplicate `burst-length` clauses, unknown subclauses, missing subclauses,
  non-AXI widths, invalid bounds, and unsupported sources fail closed.

The shipped last-beat contract remains valid without `burst-length`; it keeps
`burst_length_source: rlast_only` and `burst_length_validation:
not_generated`. The new shape is an opt-in structural contract for future
bounded reassembly.

## Report Contract

The next metadata slice should keep the existing `read_data.generated_behavior:
true` for the shipped last-beat capture behavior. The new beat-count/depth
metadata is additive and report-only:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
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

The metadata slice should move residue from the vague
`arlen_or_beat_count_validation` bucket to explicit future owners:

```text
generated_burst_length_capture
generated_beat_count_validation
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

It must not claim full reassembly, storage, per-beat output coverage, all-beat
`RRESP` aggregation, per-ID queues, or direct backend lowering.

## Selected Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.63
```

`.63` owns parser/report metadata and static validation for this
`burst-length` contract. It should add a checked-in `.ppif` sample or extend
the last-beat sample only if generated `.isf`, generated `.fsm`, HDL,
support-accounting source identity, check JSON source identity, and normalized
semantic JSON source identity remain controlled and explicitly verified.

## Future Behavior Boundary

Later behavior owners may use the `.63` metadata to:

- declare `ARLEN` as a generated input;
- capture the transaction's expected beat count on the request event;
- validate `RLAST` against the expected beat count;
- produce a length output or internal length state;
- allocate bounded per-transaction beat storage;
- assemble all read-data beats;
- aggregate all-beat `RRESP`;
- add per-ID queues for different-ID interleaving.

Those are not selected for `.63`. They remain future exact-owner work.

## Explicit Deferrals

This selector does not select:

- generic expected-beat-count signals;
- fixed-depth-only burst contracts without `ARLEN`;
- generated counters or beat-index state;
- generated missing/extra/early/late `RLAST` validation;
- per-beat outputs or packed burst outputs;
- full read-data reassembly;
- all-beat `RRESP` aggregation;
- same-ID concrete issue-order queues;
- different-ID per-ID reassembly queues;
- queued or blocking submission policy;
- profile aliases or full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Validation Gates For `.62`

Because `.62` is selection only, validation should run at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.62` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the frontier to `.62`, with
`.61` having selected beat-count/depth contract selection but no concrete
public `burst-length` contract recorded.
