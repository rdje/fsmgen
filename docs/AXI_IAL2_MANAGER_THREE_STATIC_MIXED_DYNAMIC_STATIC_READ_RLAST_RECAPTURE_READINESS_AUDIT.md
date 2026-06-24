# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.421`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.421` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.422`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this audit.

## Inputs Read

The audit read:

- `.420` post three-static mixed read single-beat recapture selector;
- `.419` one-dynamic-plus-three-static mixed read single-beat recapture
  behavior;
- `.418` three-static mixed read single-beat recapture contract;
- `.415`, `.414`, and `.413` one-dynamic-plus-two-static mixed read
  burst-last recapture behavior/contract/readiness records;
- `.396` one-dynamic-plus-one-static mixed read burst-last recapture behavior;
- `.326` one-dynamic-plus-three-static mixed read burst-last response-demux
  behavior;
- `.347` two-dynamic-plus-one-static mixed read burst-last response-demux
  behavior;
- `.330`, `.333`, `.335`, and `.337` three-static read-data/raw-`ARLEN`/
  runtime/multi-beat behavior records;
- current burst-last response-demux normalization, mixed read recapture
  marker, release/release-recapture rule helpers, report/assertion projection
  helpers, focused `t/1438` burst-last expectation surfaces, support
  accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge
  Map.

## Live Baseline

The support-accounted public sample already exists and is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

A direct normalizer/report probe over the equivalent in-memory contract
reported the current baseline:

```json
{
  "baseline_completion_source": "generated_multi_mixed_dynamic_static_read_demux_last_beat",
  "baseline_dynamic_recapture_present": 0,
  "baseline_last_signal": "axi0_rlast",
  "baseline_last_signal_width": 1,
  "baseline_mode": "bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract",
  "baseline_request_not_busy_assertions": 4,
  "baseline_response_scope": "burst_last",
  "baseline_static_capture_present": 0
}
```

This confirms `.421` starts from the intended no-recapture boundary: the
existing three-static burst-last report has no `static_capture`, no
release-recapture fields under `dynamic_capture.transactions[0]`, and
request-not-busy assertions for `r0`, `r1`, `r2`, and `r3`.

## Readiness Findings

No lower parser, public syntax, support-accounting, report-schema, or IAL1/HDL
prerequisite blocks contract selection:

- `.326` already ships the public burst-last sample with
  `response-scope burst-last`, one-bit `last-signal axi0_rlast`, one dynamic
  read transaction, three pairwise-distinct concrete static read
  transactions, and generated final-beat completion pulses.
- The existing report mode is already
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`.
- The report already carries list-shaped dynamic/static transaction lists,
  `static_id_reservations`, generated demux rules, generated completions, raw
  `RID` active-match assertions, pairwise unique-match assertions, and
  completion-active assertions for `r0`/`r1`/`r2`/`r3`.
- `.415` proves the nearest two-static burst-last release-and-recapture
  report/rule/assertion contract, including the final-only release source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`.
- `.419` already widened the mixed read recapture marker body to accept one
  dynamic plus three static states; the marker projects list-shaped
  `static_capture[]` entries when invoked.
- The release-recapture rule helpers are already policy-driven: dynamic
  recapture consumes all static request blocks and static-ID exclusions, while
  static recapture consumes the dynamic request block and all sibling static
  request blocks.
- Assertion projection already switches request assertions from
  request-not-busy to idle-or-releasing when the selected state carries
  release-recapture policy metadata.

A direct marker probe on the current normalized three-static burst-last entry
confirmed the marker substrate shape if a later implementation invokes it:

```json
{
  "before": {
    "dynamic_state_count": 1,
    "has_static_state": "ARRAY",
    "static_state_count": 3
  },
  "marked_dynamic_policy": "mixed_dynamic_static_dynamic_read",
  "marked_dynamic_source": "generated_multi_mixed_dynamic_static_read_demux_last_beat_completion",
  "marked_static_capture_count": 3,
  "marked_static_sources": [
    "generated_multi_mixed_dynamic_static_read_demux_last_beat_completion",
    "generated_multi_mixed_dynamic_static_read_demux_last_beat_completion",
    "generated_multi_mixed_dynamic_static_read_demux_last_beat_completion"
  ],
  "marked_static_transactions": ["r1", "r2", "r3"]
}
```

The remaining implementation gap is deliberate selection logic, not missing
substrate:

```text
burst-last normalizer: mark mixed read recapture only for one dynamic plus two static states
focused RLAST expectation helper: expect recapture only when the static-case count is two
```

That means the next owner can directly select the public three-static
burst-last recapture contract before implementation.

## Selected Next Leaf

`.422` should select the exact public contract for one-dynamic-plus-three-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The contract selection must pin:

- public syntax preservation for
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`;
- support-accounting identity preservation;
- `mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- `last_signal: axi0_rlast` with `last_signal_width: 1`;
- `transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
- dynamic/static/mixed transaction lists for `r0`, `r1`, `r2`, and `r3`;
- static ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- generated response-demux rules and final-beat completions for all four
  transactions;
- raw non-final `RID` ownership evidence preservation for active-match,
  pairwise unique-match, read-data, raw-`ARLEN`, runtime beat-count, and
  multi-beat output-bank consumers;
- dynamic recapture fields under `dynamic_capture.transactions[0]`;
- list-shaped `static_capture[]` entries for `r1`, `r2`, and `r3`;
- `release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`;
- dynamic release-recapture guards across all three static requests and all
  three static-ID exclusions;
- static release-recapture guards across the dynamic request and both sibling
  static requests;
- release-only same-transaction request exclusions;
- idle-or-releasing assertion names for all four selected transactions;
- preservation of one-static and two-static RLAST recapture report shapes;
- preservation of two-dynamic-plus-one-static no-recapture boundaries; and
- RAM-guarded validation gates, fallback probes, rollback, docs, and Knowledge
  Map impact.

## Deferred Alternatives

Direct implementation is deferred until `.422` records the exact report,
assertion, guard, validation, rollback, and preservation contract.

Two-dynamic-plus-one-static read recapture remains deferred because it adds
active dynamic-ID uniqueness and no-active-same-ID guard composition in
addition to mixed static guard composition.

Layered recapture-specific consumer changes, static-busy-only recapture
outside selected public samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

This audit is documentation-only. Validation should cover Knowledge Map
generation/check, mdBook build, memory architecture check, docs relative path
check, diff whitespace check, and doctrine checks. No behavior-bearing test
expectation is changed by `.421`.

## Rollback

Rollback is the `.421` audit commit. Reverting it removes the readiness audit
record, fact card, task-tree advancement to `.422`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry, restoring `.421` as
the active readiness audit.
