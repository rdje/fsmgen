# AXI IAL2 Manager Post Dynamic Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.366`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.366` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.367`, public contract selection for the
first single-active dynamic read same-cycle release-and-recapture boundary.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence

`.365` proved the smallest same-cycle recapture shape on the write side. The
selected single-active dynamic write `BID` demux now has disjoint
capture-only, release-only, and release-and-recapture update ownership. It
keeps response matching on the pre-update selected ID, captures the new request
ID only for the next cycle, reports
`same_cycle_release_recapture_policy`, and replaces request-not-busy with an
idle-or-releasing assertion role.

The remaining write-side candidates are larger than the first read sibling:

- multiple dynamic write request widening changes same-cycle sibling request
  policy, active selected-ID uniqueness, and request no-active-same-ID checks;
- mixed dynamic/static write recapture must also preserve static concrete-ID
  exclusions and static busy ownership; and
- static busy recapture should follow, not define, the first post-dynamic-write
  recapture policy.

The single-active dynamic read response-demux paths are the closest symmetric
siblings. Current generated read behavior still reports request-not-busy for
both public single-active read scopes:

- `ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` uses
  `RID` matching and `bounded_dynamic_read_rid_demux_contract`;
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
  uses `RID && RLAST` completion and
  `bounded_dynamic_read_rid_rlast_demux_contract`.

Those read paths share selected-ID and busy ownership with the write path, but
they are not a pure mechanical copy. The read side has two already-shipped
single-active response scopes, and read-data captures consume generated
response-demux completion pulses through the scalar single-beat and last-beat
dynamic read-data samples. A read recapture contract must therefore settle the
public scope and payload-preservation expectations before implementation.

## Selected .367 Scope

`.367` should be a contract-selection slice for single-active dynamic read
same-cycle release-and-recapture. It should read:

- `.366`, `.365`, `.364`, and `.363`;
- single-active dynamic read `RID` behavior and public sample;
- single-active dynamic read burst-last `RID && RLAST` behavior and public
  sample;
- dynamic read-data scalar single-beat and scalar last-beat behavior that
  consumes generated read completion pulses;
- current dynamic read response-demux normalizer, report, generated rule, and
  assertion helpers;
- focused t/1437 and t/1438 expectations for dynamic read/read-data report
  surfaces;
- current support-accounting, README, ROADMAP_V2, mdBook, Memory, task tree,
  and Knowledge Map.

The contract selection should decide:

- whether the first behavior owner covers only single-beat `RID`, covers
  burst-last `RID && RLAST` in the same behavior leaf, or splits those scopes;
- whether the existing source syntax and support-accounted samples remain
  unchanged;
- report vocabulary for read-side
  `same_cycle_release_recapture_policy`, `release_recapture_rule`,
  `release_recapture_source`, and `release_recapture_transaction`;
- whether `bounded_dynamic_read_rid_demux_contract` and
  `bounded_dynamic_read_rid_rlast_demux_contract` keep their current mode
  strings with additive same-cycle vocabulary;
- the generated update shape for capture-only, release-only, and
  release-and-recapture cycles, including the rule priority assumptions needed
  to keep response matching on the pre-update selected ID;
- the assertion replacement for covered read scopes, from request-not-busy to
  idle-or-releasing semantics, while preserving response active-match and
  completion-active assertions;
- read-data payload preservation expectations for existing generated
  completion-pulse consumers;
- focused validation and preservation gates; and
- rollback, docs, Knowledge Map, direct-backend deferral, and VHDL deferral.

## Non-Goals

`.367` should not implement behavior. It should not widen multiple dynamic
read or write request policy, mixed dynamic/static read or write recapture,
static busy recapture, read-data payload recapture beyond preservation
expectations, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL, or
full AXI manager behavior.
