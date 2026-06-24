# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.404`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.404` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.405`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this selector.

## Inputs Read

The selector is based on:

- `.403` three-static mixed dynamic/static write recapture behavior;
- `.402` three-static write recapture contract selection;
- `.401` post two-static write recapture selector;
- `.400` one-dynamic plus two-static mixed write recapture behavior;
- `.398` broader mixed recapture readiness audit;
- `.389` one-dynamic plus one-static mixed write recapture behavior;
- `.378` multiple all-dynamic write recapture behavior;
- `.341` two-dynamic-plus-one-static mixed write response-demux behavior;
- one-static, two-static, three-static, and two-dynamic-plus-one-static mixed
  write/read/read-`RLAST` behavior records;
- mixed read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  preservation records;
- current response-demux normalization, mixed dynamic/static state builders,
  dynamic/static release and release-recapture helpers, assertion/report
  helpers, focused t/1436/t1437/t1438 expectation surfaces, support
  accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge
  Map.

## Decision

The next exact owner is a readiness audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.405
```

The candidate public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

This is the nearest post-`.403` residue because it stays on the write side,
keeps the existing multi-mixed write report mode/source, and avoids read
`RID`/`RLAST`, raw non-final beat, read-data, raw-`ARLEN`, runtime-validation,
and multi-beat output-bank preservation.

It is not selected for direct contract selection yet. The current mixed
dynamic/static write recapture marker is intentionally capped at exactly one
dynamic transaction plus one, two, or three static transactions, while the
candidate sample has two dynamic transactions plus one static transaction.
That means the next owner must audit how to compose:

- multi-active dynamic write recapture policy from `.378`;
- mixed static-ID exclusion and static busy recapture policy from `.389`,
  `.400`, and `.403`;
- two dynamic `dynamic_capture.transactions[]` recapture entries;
- one list-shaped `static_capture[]` entry;
- onehot0 mixed write request policy;
- active dynamic-ID uniqueness;
- request no-active-same-ID assertions;
- static concrete-ID request/active exclusions;
- response active-match and pairwise unique-match assertions; and
- idle-or-releasing assertion replacement for all selected dynamic/static
  transactions.

## Questions For `.405`

`.405` should decide whether the two-dynamic-plus-one-static write recapture
contract can be selected directly after audit or whether a smaller helper,
report-shape, or validation prerequisite must land first.

The audit should pin the future public contract questions:

- whether dynamic recapture policy remains
  `mixed_dynamic_static_dynamic_write`, adopts
  `multi_active_unique_dynamic_write`, or needs a new combined policy string;
- whether `release_recapture_source` remains
  `generated_multi_mixed_dynamic_static_demux_completion`;
- how `response_demux.write.dynamic_capture.transactions[]` reports
  recapture fields for `w0` and `w1`;
- how `response_demux.write.static_capture[]` reports concrete static busy
  recapture for `w2`;
- whether dynamic release-recapture guards must include sibling dynamic
  request blocks, active sibling same-ID blocks, static request blocks, and
  static concrete-ID exclusions;
- whether static release-recapture guards must block both admitted dynamic
  requests;
- how release-only rules exclude only their own same-transaction same-cycle
  request;
- which request-not-busy assertions become idle-or-releasing assertions;
- how existing `request_no_active_same_id`, dynamic active-ID uniqueness,
  static-ID exclusion, response active-match, response unique-match, and
  completion-active assertions are preserved;
- which focused expectations and report checks are safe to update in the next
  behavior-bearing slice; and
- which guarded probes are required or optional under the repository RAM
  guard.

## Deferred Alternatives

Broader mixed read recapture is intentionally not next. It must preserve raw
non-final `RID` beats, final-only `RLAST` release sources, scalar read-data,
raw-`ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat output-bank
consumer contracts.

Validation retry after the `.403` RAM cutoffs is also not a feature owner. The
cutoffs are recorded and no cutoff increase is selected; `.405` may retry
guarded baseline probes only if host memory is below the default threshold.

Static-busy-only recapture outside selected mixed samples, helper/report
cleanup outside the two-dynamic-plus-one-static audit, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL,
and full AXI manager behavior remain later exact owners.

## Validation For This Selector

Selector closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.404`.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.405` selection record, fact card, task-tree advancement, live-doc updates,
and resume pointer update; generated behavior remains at `.403`.
