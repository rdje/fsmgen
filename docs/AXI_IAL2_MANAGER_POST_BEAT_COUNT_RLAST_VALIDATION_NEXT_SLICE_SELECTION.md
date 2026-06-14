# AXI IAL2 Manager Post Beat-Count/RLAST Validation Next Slice Selection

Status: selection complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.70`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)

## Evidence Read

The `.69` runtime-validation fixture now reports generated beat-count and
`RLAST` validation behavior:

```text
read_data.read.burst_length_validation: runtime_assertion
read_data.read.beat_count_validation_generated_behavior: true
read_data.read.expected_beat_count_encoding: arlen_plus_one
read_data.read.beat_count_match_source: response_demux_matched_read_beat
```

The same runtime report removes `generated_beat_count_validation` from
`read_data.residue`, leaving exactly:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

The report-only burst-length fixture remains behavior-compatible: it keeps
`burst_length_validation: report_only`, does not emit generated beat-count
validation state, and still carries `generated_beat_count_validation` residue.

The broader read-side reports still carry read-data/interleaving and burst
residue:

```text
response_demux.residue:
  read_data_interleaving
  bursts

same_id_ordering.residue:
  concrete_id_same_id_ordering
  per_id_issue_order_queues
  read_data_interleaving
  bursts
```

The current public `.ppif` read-data parser and in-process normalizer support
last-beat outputs and ARLEN-based length metadata, but they do not yet have a
public place for:

- bounded per-beat payload storage;
- per-beat public outputs;
- a packed burst output;
- a valid output or length output;
- all-beat `RRESP` aggregation;
- explicit read-data interleaving or per-ID queue semantics.

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.71
```

`.71` owns public AXI multi-beat read-data reassembly/output contract
selection. It must choose the source and report contract before parser,
generator, HDL, support-accounting, check JSON, semantic JSON, or validation
behavior changes.

## Why Contract Selection Is Next

Generated beat-count/RLAST validation proves the manager can know the expected
beat count and can detect protocol mismatches. It still does not define what
the user receives for a burst payload.

Directly implementing reassembly would silently invent user-facing semantics
for output shape, storage ownership, length validity, and `RRESP` policy. That
would violate the existing IAL2 pattern: every public behavior-bearing slice
first records the contract and residue boundary, then parser/report metadata,
then generated behavior.

The next contract selector must decide at least:

- whether the first bounded shape is per-beat outputs, one packed burst output,
  generated internal storage only, or a smaller length/valid exposure;
- whether generated reassembly requires `(validation runtime-assertion)` or
  may also operate with `report-only` length metadata;
- how `max-beats` bounds public output width/depth and generated storage;
- whether `length-output` and `valid-output` are required, optional, or still
  deferred;
- whether `RRESP` remains last-beat-only, is aggregated by a selected policy,
  or is reported as separate per-beat status;
- whether different-ID interleaving remains deferred behind per-ID queues, is
  rejected for the first reassembly contract, or is represented as a bounded
  assumption;
- how generated artifact names, report keys, diagnostics, residue movement,
  rollback, docs, Knowledge Map, direct backend deferral, and VHDL deferral
  are recorded.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, SystemVerilog HDL, support accounting, check JSON,
semantic JSON, validation behavior, or sample fixtures.

`.71` should also be selector-only unless it explicitly proves that the public
contract was already selected elsewhere. Parser/report metadata, generated
storage, generated reassembly, per-beat outputs, packed outputs, length/valid
signals, `RRESP` aggregation, per-ID queues, queued/blocking policy, profile
aliases, full-manager behavior, direct backend lowering, and VHDL remain
future exact-owner work.

## Validation Gates For `.70`

Because `.70` is documentation/task-tree selection only, validation should run
at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.70` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the active frontier to `.70`
with `.69` generated beat-count/RLAST runtime validation shipped and no next
multi-beat reassembly/output contract owner selected.
