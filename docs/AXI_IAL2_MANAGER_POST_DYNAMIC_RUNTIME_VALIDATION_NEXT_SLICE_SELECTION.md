# AXI IAL2 Manager Post Dynamic Runtime Validation Next-Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.241`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.242`, readiness audit for generated
dynamic multi-beat read-data output-bank behavior over the selected
single-active dynamic read runtime-validation boundary.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in this selector.

## Evidence Read

The selector read or used:

- `.240` dynamic runtime-validation behavior.
- `.239` dynamic runtime-validation readiness audit.
- `.238` dynamic report-only burst-length behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last `RID && RLAST` response-demux behavior.
- Non-dynamic multi-beat output-bank precedents for auto-ID, concrete
  queue-head, multiple/mixed queue-head, and same-family mixed auto-ID plus
  concrete queue-head response-demux.
- Current read-data response-demux coverage, runtime assertion helper,
  output-bank, report, residue, support-accounting, and focused dynamic test
  surfaces.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

The shipped dynamic runtime sample now provides the same prerequisite shape
that prior non-dynamic lanes used before their multi-beat output-bank audits:

```text
response_demux.read.response_scope: burst_last
response_demux.read.transaction_completion_source:
  generated_dynamic_demux_last_beat
read_data.read.capture_scope: last_beat
read_data.read.burst_length_validation: runtime_assertion
read_data.read.beat_count_validation_generated_behavior: true
read_data.read.beat_count_match_source: response_demux_matched_read_beat
read_data.residue:
  multi_beat_read_data_reassembly
  per_beat_outputs
  rresp_aggregation
```

The `.238` report-only dynamic sample remains supported and keeps
`generated_beat_count_validation` residue. Dynamic multi-beat output banks
remain explicitly fail-closed today.

## Why `.242` Is The Next Owner

The remaining residue on the `.240` runtime sample is the same user-visible
read-data residue that prior queue-head and mixed lanes resolved after runtime
validation: multi-beat reassembly, per-beat outputs, and scalar status
aggregation. The project already has:

- a bounded dynamic last-beat response-demux completion source;
- dynamic raw matched-`RID` beat counting through
  `response_demux_matched_read_beat`;
- request-time expected-beat initialization from `ARLEN + 1`;
- generated scalar runtime assertions for ARLEN bounds, extra beats, early
  `RLAST`, and missing final `RLAST`;
- non-dynamic output-bank lowering for per-beat payload/status lanes, valid
  masks, length outputs, lane capture rules, request-time clearing, and
  worst-observed scalar `RRESP` aggregation; and
- a bounded dynamic focused suite that can absorb the next dynamic-family
  sample without returning to oversized monolithic tests as the routine gate.

The next safe step is audit, not direct behavior, because dynamic multi-beat
output banks still need an exact public boundary for capture scope, output
binding names, lane capture source, completion-vs-beat counting, diagnostics,
support accounting, report vocabulary, preservation probes, and rollback.

## Scope For `.242`

`.242` should decide whether the next owner can directly implement dynamic
multi-beat output banks, needs a public contract/report selector first,
requires lower cleanup, or should defer behind a narrower prerequisite.

The audit should cover:

- one transaction-local dynamic read transaction only;
- generated dynamic `response-demux.read` with `response-scope burst-last`,
  one-bit `last-signal`, and generated transaction completion;
- `read-data.read capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `interleaving multi-beat-by-rid`;
- `burst-length source arlen`, width-8 signal, `axlen-plus-one`, request
  capture, bounded `max-beats`, and `validation runtime-assertion`;
- transaction bindings for `data-output-prefix`, `status-output-prefix`,
  `valid-mask-output`, `length-output`, and optional
  `status-aggregate-output`;
- lane capture from raw matched dynamic read beats, not the final
  `RID && RLAST` completion pulse;
- report preservation of dynamic completion validity while adding
  output-bank shape, lane output, valid-mask, length-output, and aggregation
  fields; and
- exact diagnostics and fail-closed boundaries.

## Non-Goals

`.241` changes no behavior.

`.242` must not implement behavior unless it explicitly creates a later
implementation owner. It must keep these out of scope unless separately
selected: multiple dynamic read/write transactions, mixed dynamic/static
demux, same-cycle recapture, dynamic same-ID ordering, queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL.

## Validation

Selector closeout validation for `.241`:

```sh
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

`.242` should define direct schedule/check/semantic/HDL probes, focused
dynamic validation, support-accounting checks, preservation probes for `.238`
and `.240`, docs, Knowledge Map, memory, doctrine, and temporary-artifact
cleanup requirements for any later behavior owner.

## Rollback

Rollback for `.241` is limited to this selector record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No behavior-bearing file is part of this selector.
