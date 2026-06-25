# AXI IAL2 Manager Post One-Dynamic Mixed Dynamic Same-ID Reject Mapping Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.447`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.447` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.448`, readiness audit for the public
dynamic same-ID `issue-order-queue` policy contract after the bounded
`dynamic-id-reuse reject` mappings shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read:

- `.446` one-dynamic mixed dynamic/static dynamic same-ID reject mapping
  behavior;
- `.445` one-dynamic mixed report contract selection and `.444` readiness
  audit;
- `.443` post single-active selector;
- `.442` single-active dynamic same-ID reject mapping behavior;
- `.438` multi-active dynamic same-ID reject enforcement mapping behavior;
- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior;
- `.434` public dynamic same-ID policy contract;
- `.433` dynamic same-ID policy readiness audit;
- `.216` dynamic same-ID issue-order readiness audit and the concrete
  same-ID queue-head records that followed it;
- current PPIF parser diagnostics for unsupported
  `dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`
  values;
- current dynamic same-ID report fields and residue surfaces;
- public support-accounted dynamic and mixed response-demux samples;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Decision

The next exact owner is an audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.448
```

`.448` should audit the public source/report contract for dynamic same-ID
`issue-order-queue` before any parser or generated behavior change. The audit
must decide whether the next owner should select metadata-first parser/report
support for:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

and the write-family equivalent, or whether another prerequisite is needed
first.

The reject policy path is now covered for generated response-demux evidence
models:

- `.438` covers multi-active dynamic and two-dynamic-plus-one-static mixed
  shapes through no-active-same-ID plus active-ID uniqueness assertions;
- `.442` covers single-active dynamic shapes through idle-or-releasing,
  active-match, and completion-active assertions;
- `.446` covers one-dynamic mixed dynamic/static shapes through static-ID
  exclusion, mixed request onehot0, response active/unique-match, and
  completion-active assertions.

Those mappings all keep `accepted_same_id_reuse: false`,
`generated_queue_behavior: false`, and `generated_scoreboard_behavior:
false`. The remaining dynamic same-ID policy gap is accepted dynamic same-ID
reuse. That gap should be reopened as issue-order-queue contract readiness,
not as direct generated queue behavior.

## Why Issue-Order Before Scoreboard

Concrete same-ID queue-head work already provides a bounded issue-order queue
precedent: selected-not-generated metadata, admitted-request pulses, compact
queue state, queue-head response demux, and generated queue behavior over
statically enumerable concrete-ID groups.

Dynamic IDs are not statically enumerable, so dynamic issue-order queues still
need a public contract for source spelling, report fields, admission policy,
capacity/overflow behavior, response matching, residue movement, support
accounting, examples, and validation. That is smaller and more directly
connected to existing concrete queue-head work than a scoreboard policy.

Scoreboard behavior is not selected for `.448`. A dynamic scoreboard has a
different completion-tracking promise from an issue-order queue and should
remain a separate later policy/readiness owner.

## Scope For `.448`

`.448` should cover only readiness and selection. It should decide:

- whether `dynamic-id-reuse issue-order-queue` becomes an accepted source
  value before generated dynamic queue behavior;
- whether the first report status should be `selected_not_generated` with
  `accepted_same_id_reuse: false`, or whether the spelling must remain
  unsupported until a generated queue behavior slice is selected;
- how the dynamic queue policy coexists with the existing generated
  `dynamic-id-reuse reject` mappings;
- how to keep `dynamic-id-reuse scoreboard` fail-closed;
- diagnostics for unsupported dynamic queue shapes and missing dynamic
  transaction metadata;
- validation gates, rollback, docs, mdBook, support-accounting impact, and
  Knowledge Map updates for any later contract or behavior owner.

## Deferred Work

The following remain outside `.447` and `.448` unless the audit explicitly
selects a later exact owner:

- parser/report implementation of `dynamic-id-reuse issue-order-queue`;
- generated dynamic per-ID queue state, enqueue/dequeue rules, response demux,
  capacity/overflow handling, ambiguity assertions, or accepted same-ID reuse;
- dynamic `scoreboard` source policy values or generated scoreboard behavior;
- direct backend behavior, backend-language variants, VHDL behavior, and new
  generated HDL;
- public PPIF samples, support-accounting entries, tests, generated
  artifacts, schedule/check/semantic JSON, or HDL behavior in this selector.

## Validation For `.447`

Because `.447` is a selector, validation is documentation and continuity
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

Rollback for `.447` is this docs-only selector commit. Reverting it removes
the `.448` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
