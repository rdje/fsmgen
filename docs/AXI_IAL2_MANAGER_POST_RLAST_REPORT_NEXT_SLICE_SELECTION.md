# AXI IAL2 Manager Post-RLAST-Report Next Slice Selection

Status: selection complete; no parser/generator/HDL behavior changes in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.56`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This selector follows
[docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md).

## Evidence Read

The selector re-read:

- generated single-beat `RDATA`/`RRESP` capture behavior;
- generated burst-last `RLAST` completion behavior;
- the aligned `RLAST` schedule-report prose;
- live schedule reports for the read-data and burst-last samples;
- the fail-closed diagnostics that reject `read-data` with burst-last
  response demux;
- same-ID, per-ID, interleaving, burst, and full-manager residues;
- focused generator and PPIF/CLI tests;
- mdBook, roadmap, task tree, and Knowledge Map state.

The read-data sample still reports a single-beat contract:

```text
read_data.mode: bounded_single_beat_read_data_contract
read_data.read.capture_scope: single_beat
read_data.read.completion_source: response_demux
read_data.read.interleaving_policy: single_beat_by_rid
read_data.residue:
  - rlast_completion
  - bursts
  - multi_beat_read_data_reassembly
```

The burst-last sample reports generated completion behavior, but no read-data
contract:

```text
response_demux.read.response_scope: burst_last
response_demux.read.transaction_completion_source: generated_demux_last_beat
response_demux.read.transaction_completion_semantics: matched_rid_and_last_signal
read_data: null
```

The implementation still rejects the current read-data contract when paired
with burst-last response demux:

```text
read_data requires response_demux.read.response_scope single_beat in this slice
```

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.57
```

`.57` owns public burst read-data contract selection. It must choose the
source and report boundary for combining generated `RLAST` completion with
read-data behavior before any parser/report metadata or generated behavior
changes.

The selected owner is a contract selector, not direct behavior, because the
current public `read-data` shape cannot express any of these choices:

- whether burst read-data capture is last-beat-only, per-beat, packed burst,
  or an explicit unsupported capability;
- whether the source needs a new `capture-scope`, new `interleaving` value,
  new `beat-output`, or burst output binding form;
- whether `ARLEN` or a beat-count signal is required for bounded storage and
  validation;
- how `RRESP` is represented across multiple beats;
- whether missing/extra beat validation is generated or deferred;
- whether different-ID interleaving is fail-closed, assumed disabled, or
  requires per-ID queues first;
- which report residues move when a bounded burst read-data subset is selected.

## Why Not A Per-ID Queue First

Per-ID queues are still source-supported future work, but they are broader
than the immediate contract gap. The current generated auto-ID path already
avoids same-ID concurrency for generated IDs and can identify the matching
transaction at the last beat. What is missing first is the user-visible
read-data contract: what data is captured, when it is valid, and how it is
reported.

## Why Not Direct Multi-Beat Reassembly

Direct reassembly would require output shape, storage depth, beat count,
status aggregation, and interleaving semantics that are not selected yet. The
safe next step is to select the public source/report boundary and diagnostics
first, then choose parser/report metadata or behavior from that selected
contract.

## Required Decisions For `.57`

The contract selector must decide:

- source syntax under `(read-data (read ...))` or a new adjacent clause;
- whether `capture-scope` grows beyond `single-beat`;
- whether `completion-source response-demux` remains sufficient when the
  response demux completion pulse is last-beat-only;
- output binding shape for data, response status, and any valid/length
  metadata;
- whether `ARLEN`, expected beat count, or fixed bounded depth is required;
- diagnostic behavior for pairing unsupported read-data shapes with
  `response-scope burst-last`;
- report keys for generated artifacts, residues, and unsupported
  capabilities;
- validation gates and rollback.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, HDL, support accounting, check JSON, semantic JSON,
or validation behavior. It only selects the next owner.

VHDL backend/reroute behavior remains deferred until the SystemVerilog-backed
IAL path is feature complete enough to reopen backend parity.
