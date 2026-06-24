# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.405`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.405` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.406`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this audit.

## Inputs Read

The audit is based on:

- `.404` post three-static mixed write recapture selector;
- `.403` one-dynamic plus three-static mixed write recapture behavior;
- `.400` one-dynamic plus two-static mixed write recapture behavior;
- `.389` one-dynamic plus one-static mixed write recapture behavior;
- `.378` multiple all-dynamic write recapture behavior;
- `.341` two-dynamic-plus-one-static mixed write response-demux behavior;
- the candidate public sample
  `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`;
- current support accounting, response-demux write normalization,
  dynamic/static transaction state builders, dynamic/static release-only and
  release-recapture helpers, report projection, assertion helpers, and
  focused t/1436/t1437/t1438 expectation surfaces; and
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Audit Findings

The next exact owner can select the public contract directly. A smaller
parser, source-shape, support-accounting, IAL1/IAL0, report-projection, or
assertion-substrate prerequisite was not found.

The candidate public sample is already the shipped `.341` response-demux
shape:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

It already uses explicit `response-demux.write` syntax, two dynamic write
transactions `w0`/`w1`, one concrete static write transaction `w2`, write ID
family width `4`, static concrete ID `4'd3`, generated completion source
`generated_multi_mixed_dynamic_static_demux`, and report mode
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`.

The mixed dynamic/static write state builder already constructs the guard
ingredients needed for the future behavior:

- sibling dynamic request blocks for `w0`/`w1`;
- active sibling same-ID blocks for `w0`/`w1`;
- static request blocks and static-ID exclusion blocks for dynamic captures;
- dynamic request blocks for the static `w2` busy capture;
- request idle-or-releasing assertion names for all three transactions;
- request no-active-same-ID assertions for both dynamic transactions;
- pairwise active dynamic-ID uniqueness assertion names;
- static-ID exclusion assertion names; and
- response active-match, response unique-match, and completion-active
  assertion surfaces.

The blocker for direct implementation is contract selection, not lower
substrate. The current mixed write recapture marker accepts exactly one
dynamic transaction plus one, two, or three static transactions. It therefore
does not mark the two-dynamic/one-static candidate yet. The dynamic
release-recapture rule helper also has separate branches for
`multi_active_unique_dynamic_write` guards and
`mixed_dynamic_static_dynamic_write` guards. The next contract must decide how
to compose both dynamic-sibling/no-active-same-ID guards and static request/
static-ID guards for the two-dynamic-plus-one-static shape.

Static recapture is closer: the existing static release-recapture helper
already consumes `dynamic_request_block_exprs` and
`sibling_static_request_block_exprs`; for this one-static candidate, the
future `w2` static rule only needs to block both dynamic admitted requests.

The focused report/test surface is consistent with the audit. The current
two-dynamic/one-static helper still expects:

```text
axi0_w0_dynamic_request_not_busy
axi0_w1_dynamic_request_not_busy
axi0_w2_static_request_not_busy
```

and no `static_capture` block. The previous one-dynamic mixed write
recapture slices demonstrate the intended idle-or-releasing and
`static_capture` report pattern, but `.406` must pin the exact public shape
for two dynamic capture entries plus one static capture entry before behavior
changes.

## Selected Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.406
```

It should select the public contract for the existing candidate sample with no
behavior changes. The implementation leaf should remain separate.

## Contract Questions For `.406`

`.406` should pin:

- whether dynamic recapture uses a new combined policy string or reuses one
  of the existing `mixed_dynamic_static_dynamic_write` or
  `multi_active_unique_dynamic_write` strings;
- whether `release_recapture_source` remains
  `generated_multi_mixed_dynamic_static_demux_completion`;
- whether `response_demux.write.dynamic_capture.transactions[]` carries
  release-recapture fields for both `w0` and `w1`;
- whether `response_demux.write.static_capture` is singular or list-shaped
  for the lone `w2` static transaction in this multi-mixed mode;
- the exact dynamic release-recapture guards: own admitted request, own
  generated completion, own busy state, no sibling dynamic admitted request,
  no active sibling dynamic transaction with the new `AWID`, no static
  admitted request, and `AWID != 4'd3`;
- the exact static release-recapture guard: own admitted request, own
  generated completion, own busy state, and no admitted dynamic request from
  either `w0` or `w1`;
- release-only semantics for all three transactions, excluding only their own
  same-transaction same-cycle request;
- replacement of the three request-not-busy assertions with
  `axi0_w0_dynamic_request_idle_or_releasing`,
  `axi0_w1_dynamic_request_idle_or_releasing`, and
  `axi0_w2_static_request_idle_or_releasing`;
- preservation of onehot0, request no-active-same-ID, active dynamic-ID
  uniqueness, static-ID exclusion, response active-match, pairwise
  unique-match, and completion-active assertions; and
- guarded validation expectations, RAM-guard caveats, rollback, docs,
  Knowledge Map impact, and deferred boundaries.

## Deferred Boundaries

This audit does not select broader mixed read recapture. Read-side recapture
must preserve raw non-final `RID` beats, final-only `RLAST` release sources,
read-data, raw-`ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat
output-bank consumers.

Validation retry after host-memory cutoffs is not a feature owner. A guarded
baseline schedule probe for the candidate sample was attempted under the
default RAM guard and stopped before usable output because host memory was
already above cutoff at 89.5%. The output file was empty, and no cutoff was
raised.

Static-busy-only recapture outside selected mixed samples, helper/report
cleanup outside the selected contract, request arbitration beyond onehot0,
dynamic same-ID queues, scoreboards, queued/blocking policy, profile aliases,
direct backend behavior, backend-language variants, VHDL, and full AXI
manager behavior remain later exact owners.

## Validation For This Audit

Audit closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

The only behavior-bearing probe attempted in this audit was the guarded
candidate baseline schedule JSON probe noted above; it produced no usable
output because the RAM guard stopped at host memory 89.5% against the 88%
cutoff.

## Rollback

Rollback is this docs-only audit commit. Reverting it removes only the `.405`
readiness record, fact card, task-tree advancement, live-doc updates, and
resume pointer update; generated behavior remains at `.403` for three-static
recapture and at `.341` for the two-dynamic/one-static response-demux shape.
