# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Dynamic/Static Read-Data Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.362`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.362` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.363`, readiness audit for AXI generated
dynamic and mixed dynamic/static same-cycle request/response behavior.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence

The generated dynamic and mixed dynamic/static chains now cover the selected
SystemVerilog-backed read/write response-demux and read-data behavior through
the bounded public slices:

- all-dynamic write/read response demux and read-data;
- one-dynamic plus one-, two-, and three-concrete-static mixed dynamic/static
  write/read response demux;
- two-dynamic plus one-concrete-static mixed dynamic/static write/read
  response demux; and
- scalar single-beat, scalar last-beat, report-only raw-`ARLEN`, runtime
  beat-count/`RLAST`, and runtime multi-beat output-bank read-data where those
  exact transaction sets have been selected.

The current generated dynamic/mixed contracts still report and enforce
same-cycle request policy as onehot0. Dynamic selected-ID capture requires
active dynamic IDs to be unique and emits request no-active-same-ID checks.
Static mixed transactions use busy state, static concrete-ID exclusions, and
completion-active assertions. Those rules are correct for the covered
one-request-at-a-time boundary, but they do not answer whether an admitted
request can occur in the same cycle as a generated completion, whether a
released dynamic or static slot can be re-captured in that same cycle, or
whether request and response policy can be widened without changing capacity
accounting, generated assertions, or scheduler conflict assumptions.

The repeated future-owner list in the shipped dynamic/mixed slices now has
same-cycle widening and release-and-recapture as the most local next question.
Broader arbitrary mixed cardinality, dynamic same-ID queues, scoreboards,
queued/blocking policy, direct backend behavior, backend-language variants,
and VHDL remain larger policy surfaces that should not be implemented before
the same-cycle boundary is audited.

## Selected .363 Scope

`.363` should be an audit-only slice. It should read:

- generated all-dynamic write/read response-demux behavior;
- generated mixed dynamic/static write/read response-demux behavior for one
  dynamic plus one-, two-, and three-static shapes;
- generated two-dynamic plus one-static write/read response-demux behavior;
- scalar, raw-`ARLEN`, runtime-validation, and multi-beat read-data behavior
  for the same selected dynamic/mixed transaction sets;
- current capacity accounting, transaction event dispatch, dynamic selected-ID
  capture, static busy capture/release, completion pulse generation, generated
  assertion helpers, scheduler rule conflict handling, report/static-rule prose,
  focused tests, support accounting, README, ROADMAP_V2, mdBook, task tree,
  Memory, and Knowledge Map.

The audit should decide whether the next behavior owner can safely widen
same-cycle request/response behavior directly or needs a smaller prerequisite.
It should explicitly decide:

- whether request and generated completion may be accepted in the same cycle
  for the same transaction;
- whether dynamic selected-ID release and re-capture can be generated in one
  cycle without stale `RID` matching;
- whether static busy release and re-capture can be generated in one cycle
  without double-counting capacity;
- whether onehot0 request policy remains required across mixed dynamic/static
  siblings;
- what report vocabulary and residue movement would describe any widened
  boundary;
- which public sample, if any, should own the first behavior change;
- focused validation and preservation gates; and
- rollback and VHDL deferral.

## Non-Goals

`.363` must not change parser, generator, HDL, samples, support accounting,
check JSON, semantic JSON, schedule JSON, runtime validation, or generated
artifacts. It must not implement arbitrary mixed cardinalities, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, or full AXI manager
behavior.
