# AXI IAL2 Manager Post Single-Active Dynamic Same-ID Reject Mapping Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.443`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.443` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.444`, readiness audit for one-dynamic
mixed dynamic/static dynamic same-ID reject mapping over existing generated
mixed response-demux assertion evidence.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior, backend-language
variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector is based on:

- `.442` single-active dynamic same-ID reject mapping behavior;
- `.441` single-active report contract, `.440` readiness audit, and `.439`
  post multi-active mapping selector;
- `.438` generated multi-active dynamic same-ID reject enforcement mapping;
- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior
  and `.434` public dynamic same-ID policy contract;
- `.437` fail-closed boundaries for one-dynamic mixed dynamic/static
  response-demux;
- current `AxiManagerCapacityStatus` mixed dynamic/static write/read
  response-demux builders, response-demux assertion specs, same-ID policy
  coverage helper, and residue projection;
- the remaining focused fail-closed test row for one-dynamic mixed
  response-demux plus `dynamic-id-reuse reject`;
- public support-accounted mixed dynamic/static response-demux samples for
  write `BID`, read single-beat `RID`, and read burst-last `RID && RLAST`
  with one dynamic transaction and one, two, or three static concrete
  transactions;
- prior dynamic issue-order queue and scoreboard readiness records, which keep
  dynamic queues and scoreboards outside the current accepted policy values;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Decision

The next exact owner is an audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.444
```

`.444` should decide whether the existing one-dynamic mixed dynamic/static
response-demux assertions are sufficient public evidence for mapping selected
`same-id-ordering.<family> (dynamic-id-reuse reject)` to generated reject
metadata, or whether the current fail-closed behavior should remain until a
more precise source/report contract exists.

The remaining bounded response-demux reject gap is not dynamic queues or a
scoreboard. Multi-active all-dynamic and two-dynamic-plus-one-static mixed
shapes are covered by `.438`; single-active all-dynamic shapes are covered by
`.442`. One-dynamic mixed dynamic/static shapes still fail closed at:

```text
AXI manager capacity/status IAL2 contract response_demux.<family> dynamic-id-reuse reject generated enforcement requires generated multi-active dynamic response-demux no-active-same-ID assertions in this slice
```

That diagnostic is now intentionally conservative, because one-dynamic mixed
shapes do not have a sibling dynamic transaction and therefore do not expose
the `.438` `*_dynamic_request_no_active_same_id` plus
`*_dynamic_active_id_unique` evidence pair.

## Evidence To Audit

The existing generated one-dynamic mixed surface already reports or emits:

- `dynamic_capture.ownership: mixed_dynamic_static_unique_<family>_ids` for
  one dynamic plus one static, and
  `multi_mixed_dynamic_static_unique_<family>_ids` for one dynamic plus
  multiple static transactions;
- `static_id_conflict_policy: static_concrete_ids_reserved`;
- concrete static ID reservations/exclusions;
- dynamic request idle-or-releasing or not-busy assertions;
- mixed dynamic/static request `onehot0` assertions;
- dynamic request-not-static-ID and active-not-static-ID assertions;
- mixed response active-match and unique-match assertions;
- dynamic and static completion-active assertions.

The audit must decide whether these artifacts should form a third generated
reject report contract distinct from both `.438` multi-active no-active-same-ID
coverage and `.442` single-active idle-or-releasing coverage.

## Scope For `.444`

`.444` should cover only readiness and selection for one-dynamic mixed
dynamic/static `dynamic-id-reuse reject` mapping across:

- write `BID` response-demux;
- read single-beat `RID` response-demux;
- read burst-last `RID && RLAST` response-demux;
- one dynamic transaction plus one, two, or three concrete static
  transactions when the generated response-demux report already exposes the
  static-ID exclusion and mixed-request assertion evidence.

The audit should decide exact next ownership: public report contract
selection, direct implementation, continued fail-closed behavior, a diagnostic
cleanup prerequisite, or a narrower family/cardinality subset.

If it selects a later mapping, the audit must define report fields, residue
movement, diagnostics, validation gates, rollback, and non-goals before any
behavior changes.

## Deferred Work

The following remain outside `.443` and should remain outside `.444` unless
the audit explicitly selects a later owner:

- dynamic `issue-order-queue` and dynamic `scoreboard` source policy values;
- dynamic per-ID queues, scoreboards, broader request arbitration,
  ambiguity/overflow tracking, or accepted dynamic same-ID reuse;
- direct backend behavior, backend-language variants, VHDL behavior, and new
  generated HDL;
- parser/report changes, PPIF samples, support-accounting entries, generated
  artifacts, or tests in this selector.

## Validation For `.443`

Because `.443` is a selector, validation is documentation and continuity
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

Rollback for `.443` is this docs-only selector commit. Reverting it removes
the `.444` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
