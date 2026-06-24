# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.401`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.401` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.402`, public contract selection for
one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, HDL, or
runtime behavior changes in this selector.

## Inputs Read

The selector is based on:

- `.400` multiple mixed write recapture behavior;
- `.399` two-static mixed write recapture contract selection;
- `.398` broader mixed recapture readiness audit;
- `.389` one-dynamic plus one-static mixed write recapture behavior;
- `.318` one-dynamic plus three-static mixed write response-demux behavior;
- `.341` two-dynamic-plus-one-static mixed write response-demux behavior;
- multiple mixed dynamic/static write/read/read-`RLAST` behavior records;
- current response-demux normalization, state builders, release/recapture,
  assertion, and report helpers; and
- guarded schedule probes for the selected two-static sample, one-static
  preservation sample, three-static preservation sample, and
  two-dynamic-plus-one-static preservation sample.

## Decision

The next exact owner is the three-static mixed write recapture contract:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.402
```

The selected public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

This is the smallest post-`.400` behavior-bearing direction because it keeps
the same write-only, one-dynamic cardinality as `.400` and adds only one more
concrete static sibling. It exercises the same static busy recapture family,
but must pin the three-static report and guard contract before implementation.

## Contract Questions For `.402`

`.402` must select the exact public contract for:

- preserving public syntax and support-accounting identity;
- preserving `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`;
- preserving `generated_multi_mixed_dynamic_static_demux`;
- preserving `matched_dynamic_or_static_concrete_id`;
- preserving `w0` dynamic transaction coverage and `w1`/`w2`/`w3` static
  transaction coverage;
- preserving static-ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- reporting dynamic recapture under
  `response_demux.write.dynamic_capture.transactions[0]`;
- reporting static recapture under list-shaped
  `response_demux.write.static_capture[]` entries for `w1`, `w2`, and `w3`;
- using `generated_multi_mixed_dynamic_static_demux_completion` as the
  release-recapture source;
- making release-only rules exclude same-transaction same-cycle requests;
- making dynamic release-recapture block all admitted static sibling requests
  and all static concrete IDs;
- making each static release-recapture block the admitted dynamic request and
  both admitted sibling static requests;
- replacing the selected `w0`/`w1`/`w2`/`w3` request-not-busy assertions with
  idle-or-releasing assertion names; and
- preserving onehot0, static-ID exclusion, response active-match, pairwise
  unique-match, and completion-active assertions.

## Deferred Alternatives

Two-dynamic-plus-one-static mixed write recapture is intentionally not next.
It adds multiple active dynamic selected-ID ownership, active dynamic-ID
uniqueness, and no-active-same-ID request checks on top of static concrete-ID
reservation and mixed recapture.

Broader mixed read recapture is also not next. It adds single-beat vs
burst-last `RID`/`RLAST` completion source differences plus read-data,
raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
preservation.

Validation retry after RAM-guard cutoffs is not a feature owner. The `.400`
slice has syntax checks and guarded schedule probes for the selected and
preserved write shapes, while the heavier focused/projection attempts remain
recorded as host-memory-limited interactive validation caveats.

Static-busy-only recapture outside selected mixed samples, helper/report
cleanup, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation For This Selector

Selector closeout requires Knowledge Map generation/check, mdBook build,
memory architecture check, diff whitespace check, and doctrine checks. No
behavior-bearing command is required beyond the `.400` preservation probes
already recorded.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.402` selection record, fact card, task-tree advancement, live-doc updates,
and resume pointer update; generated behavior remains at `.400`.
