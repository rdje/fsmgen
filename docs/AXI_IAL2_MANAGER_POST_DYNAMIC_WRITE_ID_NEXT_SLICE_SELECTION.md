# AXI IAL2 Manager Post-Dynamic-Write-ID Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.224` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.224`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.225`, generated dynamic read
transaction-ID capture and `RID` response matching readiness audit.

The `.223` slice shipped the first behavior-bearing dynamic transaction-ID
path for one write transaction consumed by explicit `response-demux.write`.
That covered write `BID` matching, generated selected-ID/busy state,
single-active ownership, completion pulse, release, runtime assertions, and
support-accounted schedule/check/semantic/HDL reachability.

The next exact owner should not expand write behavior first. Multiple dynamic
write transactions, mixed dynamic/static write demux, same-cycle recapture,
and dynamic same-ID ordering all need queue or arbitration decisions. The
smallest symmetric feature-completeness question is whether the already-shipped
read response-demux substrate can support one dynamic read transaction, and
which read scope is safe as the first contract.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Why A Readiness Audit First

Dynamic read matching is not a direct mirror of the dynamic write shape.
Before selecting parser/report syntax or generated behavior, the next audit
must settle:

- whether the first dynamic read response-demux shape is `response-scope
  single-beat`, `response-scope burst-last`, or a staged contract selection;
- whether request-ID capture uses the admitted read request boundary and the
  family request-ID source such as `ARID`;
- whether the first read shape uses single-active selected-ID/busy state like
  `.223` or needs queue state before any generated read behavior;
- how raw accepted read response events, `RID`, and optional `RLAST` compose
  into generated completion pulses;
- whether existing single-beat read-data capture, last-beat read-data capture,
  burst-length, runtime validation, and multi-beat output-bank behavior can
  consume dynamic read completion pulses in the first slice or must remain
  residue;
- what assertions and diagnostics are required for unmatched dynamic `RID`,
  busy ownership, early/late `RLAST`, same-cycle recapture, and unsupported
  dynamic/static mixtures;
- what report vocabulary should parallel
  `bounded_dynamic_write_bid_demux_contract` without over-claiming queue,
  scoreboard, or read-data reassembly support.

The audit should read the existing generated read response-demux single-beat
and burst-last behavior, read-data capture families, burst/runtime-validation
families, dynamic transaction-ID metadata behavior, the `.222` contract
selection, the `.223` generated write behavior, and the AXI manager generator
state/rule/assertion helpers before selecting the implementation path.

## Candidate Outcomes For `.225`

The audit may select one of these outcomes:

1. public contract selection for the first bounded dynamic read response-demux
   scope;
2. direct bounded implementation if the existing read contract is already
   precise enough and no new report/static selection is needed;
3. a lower-layer prerequisite if IAL1/IAL0/SystemVerilog cannot carry the
   needed storage, pulse, assertion, or report shape safely;
4. a narrower report/static cleanup if `.223` left stale dynamic-ID residue
   that would mislead the read audit.

The audit must not implement behavior directly unless it first creates a later
exact owner with acceptance criteria and validation scope.

## Explicit Non-Goals For `.225`

The readiness audit does not implement:

- dynamic read response matching;
- new PPIF syntax;
- multiple dynamic write or read transactions;
- mixed dynamic/static response demux;
- same-cycle release and recapture;
- dynamic same-ID ordering;
- queue or scoreboard behavior;
- read-data routing over dynamic IDs;
- direct backend behavior;
- VHDL behavior.

## Validation For This Selector

Because `.224` is selector-only, validation is documentation and continuity
focused:

- regenerate and check the Knowledge Map;
- build the mdBook;
- run the doctrine driver;
- run docs path and memory architecture gates;
- run `git --no-pager diff --check`.

## Rollback

Rollback is documentation-only: revert this selector, the `.224` task-tree
frontier update, live docs/status sync, Memory, and Knowledge Map. No generated
runtime behavior, public parser behavior, or support-accounting catalog entry
is changed by this selector.
