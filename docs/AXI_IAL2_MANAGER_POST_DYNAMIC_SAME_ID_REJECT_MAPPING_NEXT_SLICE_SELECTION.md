# AXI IAL2 Manager Post Dynamic Same-ID Reject Mapping Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.439`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.439` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.440`, readiness audit for single-active
dynamic same-ID reject mapping over the existing generated single-active
dynamic response-demux assertions.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior, backend-language
variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector is based on:

- `.438` generated dynamic same-ID reject enforcement mapping behavior;
- `.437` generated reject mapping readiness audit;
- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior;
- `.434` public dynamic same-ID policy contract and `.433` dynamic same-ID
  policy readiness audit;
- `.365`, `.368`, and `.372` single-active dynamic write, read single-beat,
  and read burst-last same-cycle release-and-recapture behavior records;
- current `AxiManagerCapacityStatus` response-demux report surfaces for
  single-active dynamic, multi-active dynamic, and mixed dynamic/static shapes;
- current focused `t/1436`, `t/1437`, and `t/1438` expectation surfaces for
  dynamic same-ID policy diagnostics and generated dynamic response-demux
  assertions;
- support-accounted dynamic and mixed response-demux samples, including the
  new `.438` dynamic read same-ID reject sample;
- concrete same-ID queue-head records and the explicit `.434` decision that
  dynamic issue-order queues and dynamic scoreboards are not public policy
  values yet;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Decision

The next exact owner is an audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.440
```

The audit should decide whether the existing single-active dynamic
`*_dynamic_request_idle_or_releasing` assertions are sufficient public
enforcement for selected `(dynamic-id-reuse reject)` on single-active dynamic
write/read response-demux families.

Single-active dynamic response-demux differs from the `.438` covered
multi-active shapes. It has exactly one dynamic transaction in the selected
family and generated assertions such as:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_r0_dynamic_request_idle_or_releasing
axi0_write_dynamic_response_active_match
axi0_read_dynamic_response_active_match
axi0_w0_dynamic_completion_active
axi0_r0_dynamic_completion_active
```

It does not expose the `.438` coverage pair:

```text
*_dynamic_request_no_active_same_id
*_dynamic_active_id_unique
```

That means direct mapping should not reuse the `.438` report contract without a
new audit. `.440` should either select a single-active-specific generated
reject mapping contract, such as enforcement through generated
idle-or-releasing assertions, or keep the current fail-closed behavior and
select another prerequisite.

## Scope For `.440`

`.440` should cover only:

- single-active dynamic write `BID` response-demux;
- single-active dynamic read single-beat `RID` response-demux;
- single-active dynamic read burst-last `RID && RLAST` response-demux;
- report fields, residue movement, diagnostics, validation gates, and rollback
  boundary for those single-active shapes;
- whether a follow-on behavior slice can change acceptance without adding new
  generated rules, storage, assertions, HDL, runtime behavior, direct backend
  behavior, backend-language variants, queues, scoreboards, or VHDL.

The audit should preserve the `.438` multi-active mapping as-is and should not
weaken the current fail-closed diagnostics for one-dynamic mixed dynamic/static
response-demux shapes.

## Deferred Work

The following remain outside `.439` and should remain outside `.440` unless the
audit explicitly selects a later owner:

- one-dynamic mixed dynamic/static reject mapping;
- dynamic `issue-order-queue` and dynamic `scoreboard` source policy values;
- dynamic per-ID queues, scoreboards, request arbitration, overflow handling,
  or ambiguity tracking;
- direct backend behavior, backend-language variants, VHDL behavior, and new
  generated HDL.

## Validation For `.439`

Because `.439` is a selector, validation is documentation and continuity
focused:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No Perl, `prove`, `fsmgen`, HDL, schedule/check/semantic JSON, or generated
artifact behavior is expected to change in this slice.

## Rollback

Rollback for `.439` is this docs-only selector commit. Reverting it removes
the `.440` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
