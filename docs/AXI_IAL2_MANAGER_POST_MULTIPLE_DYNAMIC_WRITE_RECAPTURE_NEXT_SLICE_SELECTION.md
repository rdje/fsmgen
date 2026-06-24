# AXI IAL2 Manager Post Multiple Dynamic Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.379`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.379` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.380`, public contract selection for
multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence

`.378` shipped the first broader multiple-dynamic recapture behavior on the
write side. That behavior proved the multi-active selected-ID/busy update
shape while preserving the existing public sample, onehot0 request policy,
active-ID uniqueness, request no-active-same-ID, response active-match,
response unique-match, and completion-active assertions.

The remaining all-dynamic read candidates are:

- multiple dynamic read single-beat `RID` response-demux; and
- multiple dynamic read burst-last `RID && RLAST` response-demux.

The single-beat read shape is the next smallest owner. It uses the same
per-transaction dynamic selected-ID and busy state as the write shape, already
has onehot0 dynamic read requests, active dynamic ID uniqueness, request
no-active-same-ID, raw response active-match, response unique-match, and
completion-active assertions, and has no `RLAST` final-beat split.

The burst-last sibling is larger and should follow later. It must preserve
matched non-final read beats, final-only generated completion/release,
scalar last-beat read-data, report-only raw-`ARLEN`, runtime
beat-count/`RLAST` validation, and multi-beat output-bank consumers. Selecting
single-beat first keeps the next contract focused on the shared multi-active
read selected-ID/busy lifecycle before that final-beat consumer stack is
changed.

No generated support-detail cleanup is required before this next selection.
`.378` already updated support prose for multiple dynamic write recapture and
keeps multiple dynamic read recapture in the future-owner boundary.

## Selected .380 Scope

`.380` should select the exact public contract for the existing
support-accounted sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The contract selection should decide and record:

- preservation of public source syntax, support-accounting identity, generated
  completion names, generated response-demux rule names, and
  `bounded_multi_dynamic_read_rid_demux_contract`;
- whether same-cycle dynamic read requests remain onehot0 for the first
  multiple-dynamic read recapture behavior;
- per-transaction report fields under
  `response_demux.read.dynamic_capture.transactions[]`, including
  `release_recapture_rule`, `same_cycle_release_recapture_policy`,
  `release_recapture_source`, and `release_recapture_transaction`;
- whether the policy value should be
  `multi_active_unique_dynamic_read` and the source should be
  `generated_dynamic_demux_completion`;
- release-only exclusion semantics for the same transaction's own same-cycle
  request;
- release-recapture guard requirements: own admitted request, own generated
  completion, own busy state, no sibling admitted request, and no active
  sibling with the new `ARID`;
- replacement of per-transaction request-not-busy assertions with
  request idle-or-releasing assertions;
- preservation of request no-active-same-ID, active-ID uniqueness, raw
  response active-match, response unique-match, and completion-active
  assertions;
- scalar single-beat multiple dynamic read-data preservation over the same
  generated completion pulses;
- validation gates, rollback, docs, mdBook, Knowledge Map, direct-backend
  deferral, backend-language deferral, and VHDL deferral.

## Deferred Boundaries

`.380` should not implement behavior. It should not select burst-last
`RID && RLAST` recapture directly, change read-data behavior beyond
preservation expectations, widen dynamic request arbitration beyond onehot0,
add mixed dynamic/static recapture, static busy recapture, dynamic same-ID
queues, scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, or full AXI manager behavior.

Multiple dynamic read burst-last recapture should remain the next read-side
candidate after the single-beat contract/behavior path is settled.

## Validation

Closeout for `.379` is documentation/doctrine oriented:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
