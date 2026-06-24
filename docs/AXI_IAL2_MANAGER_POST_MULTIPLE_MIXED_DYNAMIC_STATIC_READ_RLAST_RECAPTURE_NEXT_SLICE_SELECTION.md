# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.416`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.416` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.417`, a readiness audit for
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this selector.

## Inputs Read

The selector read the newly shipped `.415` one-dynamic-plus-two-static mixed
read burst-last recapture behavior, the `.414` contract, the `.413`
readiness audit, the `.411` one-dynamic-plus-two-static mixed read
single-beat recapture behavior, the `.396` one-dynamic/one-static mixed read
burst-last recapture behavior, the `.326` one-dynamic-plus-three-static mixed
read burst-last response-demux behavior, the `.322`
one-dynamic-plus-three-static mixed read single-beat response-demux behavior,
the `.347` two-dynamic-plus-one-static mixed read burst-last response-demux
behavior, and the broader mixed recapture records.

The selector also inspected the current read response-demux normalizer,
mixed dynamic/static state builders, release/release-recapture rule helpers,
assertion/report projection helpers, focused `t/1438` expectation surfaces,
support-accounting entries, README, ROADMAP_V2, mdBook, Memory, task tree,
and Knowledge Map.

## Live Baseline

A guarded schedule probe on the existing public three-static single-beat read
sample passed under the default RAM guard:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The guard started with host memory at 87.3% against the default 88% cutoff
and produced a 46985-byte schedule report.

The live report still has:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux
generated_assertions:
  axi0_r0_dynamic_request_not_busy
  axi0_r1_static_request_not_busy
  axi0_r2_static_request_not_busy
  axi0_r3_static_request_not_busy
static_capture: absent
dynamic_capture.transactions[0].release_recapture_rule: absent
```

This is the current public boundary: the one-dynamic-plus-three-static
single-beat demux is generated and support-accounted, but same-cycle
release-and-recapture is not yet selected for that sibling.

## Decision

The next exact owner is a readiness audit, not direct implementation.

The selected boundary is the smallest static-cardinality follow-up after the
two-static mixed read recapture family:

- `.411` proves one-dynamic-plus-two-static single-beat read recapture with
  list-shaped `static_capture[]` and composed static guards.
- `.415` proves the same two-static shape for burst-last final-beat
  recapture while preserving raw non-final `RID` and layered consumers.
- `.322` already provides the one-dynamic-plus-three-static single-beat read
  response-demux public sample, mode, support-accounting entry, generated
  completion pulses, static-ID reservations, and all pairwise raw `RID`
  unique-match assertions.
- `.403` already proves that the mixed dynamic/static recapture report and
  guard vocabulary can scale to three concrete static transactions on the
  write side.

The readiness audit is still required because the read recapture marker is
currently selected for one dynamic plus one or two static read states, while
the candidate public sample has one dynamic plus three static read states.
The audit must decide whether three-static read recapture can reuse the
existing mixed read policy strings and list-shaped static capture report, or
whether a smaller helper/report prerequisite is needed before implementation.

## Alternatives Deferred

Direct three-static implementation is deferred until `.417` records the exact
report, assertion, guard, preservation, and validation contract.

One-dynamic-plus-three-static burst-last read recapture is deferred until the
single-beat `RID` recapture sibling is audited. The burst-last shape adds
final-only release source and raw non-final `RID` preservation, so it should
not be combined with the first three-static read recapture widening.

Two-dynamic-plus-one-static read recapture remains deferred because it adds
the active dynamic-ID uniqueness and no-active-same-ID guard axis in addition
to mixed static guard composition.

Layered recapture-specific consumer changes, standalone validation retries
after RAM cutoffs, static-busy-only recapture outside selected public
samples, helper/report cleanup outside the selected audit, request
arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Selected Next Leaf

`.417` should audit whether one-dynamic-plus-three-static mixed read
single-beat `RID` same-cycle release-and-recapture can be selected directly
or requires a smaller prerequisite.

The audit must record:

- the current live report baseline for
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`;
- expected dynamic recapture fields under
  `dynamic_capture.transactions[0]`;
- expected list-shaped `static_capture[]` entries for `r1`, `r2`, and `r3`;
- whether `release_recapture_source` remains
  `generated_multi_mixed_dynamic_static_read_demux_completion`;
- release-only exclusion of same-transaction same-cycle requests;
- dynamic recapture guards across all three static requests and all three
  static-ID exclusions;
- static recapture guards across the dynamic request and both sibling static
  requests;
- request assertion renames from request-not-busy to idle-or-releasing for
  `r0`, `r1`, `r2`, and `r3`;
- preservation of onehot0, static-ID exclusion, response active-match,
  pairwise unique-match, and completion-active assertions;
- preservation of the one-static and two-static recapture report shapes and
  the two-dynamic-plus-one-static no-recapture boundary;
- RAM-guarded validation gates and fallback probes; and
- rollback and documentation boundaries.

## Validation

This selector is documentation-only. Validation should cover Knowledge Map
generation/check, mdBook build, memory architecture check, docs relative path
check, diff whitespace check, and doctrine checks. No behavior-bearing test
expectation is changed by `.416`.

## Rollback

Rollback is the `.416` selector commit. Reverting it removes the selector
record, fact card, task-tree advancement to `.417`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry, restoring `.416` as
the active next selector.
