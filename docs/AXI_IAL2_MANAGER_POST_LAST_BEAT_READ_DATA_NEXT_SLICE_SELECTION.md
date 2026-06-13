# AXI IAL2 Manager Post Last-Beat Read-Data Next Slice Selection

Status: selection complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.61`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md](AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md)

## Evidence Read

The `.60` last-beat sample now reports generated burst-last read response
demux and generated last-beat read-data capture:

```text
response_demux.read.response_scope: burst_last
response_demux.read.transaction_completion_source: generated_demux_last_beat
read_data.mode: bounded_last_beat_read_data_contract
read_data.generated_behavior: true
read_data.read.burst_length_source: rlast_only
read_data.read.beat_storage: none
read_data.read.status_aggregation: none
read_data.read.valid_output: none
read_data.read.length_output: none
```

The remaining read-data residue is:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
arlen_or_beat_count_validation
```

The broader generated read response-demux and same-ID reports still carry:

```text
read_data_interleaving
bursts
concrete_id_same_id_ordering
per_id_issue_order_queues
```

Unsupported residue still keeps dynamic user-ID arbitration, per-ID same-ID
response queues, different-ID interleaving, full read-data
interleaving/reassembly, broader burst payload assembly, `RRESP` aggregation,
`ARLEN` or beat-count validation, per-beat outputs, profile aliases,
full-manager behavior, direct backend lowering, and VHDL out of the shipped
capacity/status shell.

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.62
```

`.62` owns public AXI burst read-data beat-count/depth contract selection.
It must select how the public source and report name the expected burst length
or bounded storage depth before FSMGen can honestly implement full multi-beat
read-data reassembly, per-beat outputs, all-beat `RRESP` aggregation, missing
or extra beat validation, or per-ID read-data queues.

## Why Beat-Count/Depth First

Full multi-beat reassembly is broader than the immediate next safe step. It
requires at least:

- a source of expected beat count or maximum bounded depth;
- an indexing model for accepted non-last and last beats;
- output shape for per-beat or packed data;
- status semantics for one `RRESP` per beat;
- diagnostics for missing beats, extra beats, early `RLAST`, late `RLAST`, and
  width/depth mismatches;
- a report boundary that does not claim per-ID queueing or full-manager
  behavior prematurely.

Per-beat outputs and `RRESP` aggregation are not good first owners because
both depend on the same beat-count/depth choice. Per-ID queues are also
broader than the immediate gap: generated auto-ID same-ID avoidance already
prevents same-ID concurrency for generated IDs, and generated `RID` matching
already identifies the target transaction. Different-ID interleaving can be
made precise only after the storage depth and beat-index contract is selected.

## Required Decisions For `.62`

The contract selector must decide:

- whether public syntax names an `ARLEN` signal, an expected beat-count
  signal, a fixed bounded depth, or a combination;
- whether the first selected contract is report/static metadata only or also
  selects a future generated validation behavior;
- how `RLAST` and expected count interact when they disagree;
- whether `length_output`, `valid_output`, per-beat outputs, packed burst
  outputs, or storage-only state are in scope for the first metadata slice;
- whether `RRESP` remains last-beat-only until a later aggregation owner or
  gains an explicit aggregation policy;
- whether different-ID interleaving is rejected, assumed bounded by one
  transaction per generated ID, or deferred to per-ID queues;
- what report keys, generated artifact names, residue movement, diagnostics,
  rollback, and validation gates the later parser/report metadata owner must
  use.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, SystemVerilog HDL, support accounting, check JSON,
semantic JSON, or validation behavior.

`.62` should still be a selector slice. Parser/report metadata, generated
counter/storage behavior, reassembly, per-beat outputs, `RRESP` aggregation,
per-ID queues, queued/blocking policy, profile aliases, full-manager behavior,
direct backend lowering, and VHDL remain future exact-owner work until
explicitly selected.

## Validation Gates For `.61`

Because `.61` is documentation/task-tree selection only, validation should run
at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.61` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the frontier to `.61` with
`.60` generated last-beat read-data capture shipped and no `.62` beat-count
contract owner selected.
