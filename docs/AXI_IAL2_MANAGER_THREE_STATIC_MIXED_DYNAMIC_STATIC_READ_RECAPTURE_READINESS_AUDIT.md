# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.417`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.417` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.418`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this audit.

## Inputs Read

The audit read:

- `.416` post two-static mixed read burst-last recapture selector;
- `.415` one-dynamic-plus-two-static mixed read burst-last recapture behavior;
- `.414` and `.413` two-static burst-last recapture contract/readiness
  records;
- `.411`, `.410`, and `.409` two-static single-beat recapture
  behavior/contract/readiness records;
- `.396` and `.392` one-static mixed read burst-last and single-beat
  recapture behavior;
- `.403` three-static mixed write recapture behavior;
- `.322` one-dynamic-plus-three-static mixed read single-beat response-demux
  behavior;
- `.326` one-dynamic-plus-three-static mixed read burst-last response-demux
  behavior;
- `.330`, `.333`, `.335`, and `.337` three-static read-data/raw-`ARLEN`/
  runtime/multi-beat behavior records;
- `.344` and `.347` two-dynamic-plus-one-static read response-demux behavior;
- current response-demux read normalization, mixed read state builders,
  release/release-recapture rule helpers, report/assertion projection
  helpers, focused `t/1438` expectation surfaces, support accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

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

The current no-recapture baseline is intentional and must remain true until a
later implementation owner changes it.

## Readiness Findings

No lower parser, PPIF syntax, support-accounting, report-schema, or IAL1/HDL
prerequisite blocks contract selection:

- `.322` already ships and support-accounts the public single-beat sample:
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
- The existing report mode is already the list-shaped
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`.
- Dynamic/static transaction lists, `static_id_reservations`, generated
  demux rules, generated completions, raw `RID` active-match assertions,
  pairwise unique-match assertions, and completion-active assertions already
  scale to `r0` plus `r1`/`r2`/`r3`.
- Rule emission for mixed dynamic/static dynamic recapture already consumes
  all `static_request_block_exprs` and all `static_id_block_exprs`.
- Rule emission for mixed dynamic/static static recapture already consumes
  all dynamic request blocks and all sibling static request blocks.
- Assertion projection already switches from request-not-busy to
  idle-or-releasing based on the dynamic/static release-recapture markers.
- Inside the existing mixed read recapture marker, static capture report
  projection maps over all static states and emits a list shape whenever more
  than one static capture entry exists.

The current cap is deliberate selection logic, not a missing substrate:

```text
single-beat normalizer: mark mixed read recapture only for one dynamic plus one or two static states
mixed read recapture marker: return unless static state count is one or two
focused expectation helper: treat the three-static single-beat sample as no-recapture
```

That means the next contract selection can directly pin the three-static
public contract. The later implementation owner should be small and bounded:
extend the selected marker/normalizer call to exactly one dynamic plus three
static read states and update the focused expectations for that exact public
sample.

## Selected Next Leaf

`.418` should select the exact public contract for
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The contract selection must pin:

- public syntax preservation for
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`;
- support-accounting identity preservation;
- `mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_single_beat`;
- dynamic/static/mixed transaction lists for `r0`, `r1`, `r2`, and `r3`;
- static ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- generated response-demux rules and completions for all four transactions;
- dynamic recapture fields under `dynamic_capture.transactions[0]`;
- list-shaped `static_capture[]` entries for `r1`, `r2`, and `r3`;
- `release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_completion`;
- dynamic release-recapture guards across all three static requests and all
  three static-ID exclusions;
- static release-recapture guards across the dynamic request and both sibling
  static requests;
- release-only same-transaction request exclusion;
- idle-or-releasing assertion names for all four selected transactions;
- preservation of onehot0, static-ID exclusion, response active-match,
  pairwise unique-match, and completion-active assertions;
- preservation of the one-static and two-static read recapture report shapes;
- preservation of the three-static burst-last no-recapture boundary;
- preservation of the two-dynamic-plus-one-static no-recapture boundary; and
- RAM-guarded validation gates, fallback probes, rollback, docs, and Knowledge
  Map impact.

## Deferred Alternatives

Direct implementation is deferred until `.418` records the exact report,
assertion, guard, validation, rollback, and preservation contract.

One-dynamic-plus-three-static burst-last read recapture remains deferred. It
adds final-only release source and raw non-final `RID` preservation to the
same three-static cardinality question and should follow the single-beat
contract/behavior pair.

Two-dynamic-plus-one-static read recapture remains deferred because it adds
active dynamic-ID uniqueness and no-active-same-ID guard composition in
addition to mixed static guard composition.

Layered recapture-specific consumer changes, validation retries after RAM
cutoffs, static-busy-only recapture outside selected public samples, request
arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

This audit is documentation-only. Validation should cover Knowledge Map
generation/check, mdBook build, memory architecture check, docs relative path
check, diff whitespace check, and doctrine checks. No behavior-bearing test
expectation is changed by `.417`.

## Rollback

Rollback is the `.417` audit commit. Reverting it removes the readiness audit
record, fact card, task-tree advancement to `.418`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry, restoring `.417` as
the active readiness audit.
