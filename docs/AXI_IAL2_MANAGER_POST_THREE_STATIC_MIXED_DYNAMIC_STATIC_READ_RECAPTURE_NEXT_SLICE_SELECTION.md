# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.420`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.420` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.421`, readiness audit for
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test expectation,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Why This Owner Is Next

`.419` shipped the one-dynamic-plus-three-static mixed read single-beat
recapture sibling. The nearest remaining same-family hole is the already
supported one-dynamic-plus-three-static mixed read burst-last response-demux
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

That public burst-last sample already shipped in `.326` with list-shaped
transaction/static-ID fields and generated final-beat completion pulses.
The two-static burst-last sibling shipped same-cycle release-and-recapture in
`.415`, which gives the nearest final-beat report/rule/assertion precedent.

The current generator still deliberately keeps the three-static burst-last
shape outside recapture: the burst-last normalizer marks recapture only for
exactly one dynamic plus two static states, and the focused burst-last
expectation helper still expects recapture only for two static cases.

## Baseline Evidence

A direct baseline normalizer/assertion probe for the three-static burst-last
shape reported:

```json
{
  "mode": "bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract",
  "response_scope": "burst_last",
  "source": "generated_multi_mixed_dynamic_static_read_demux_last_beat",
  "static_capture_present": 0,
  "dynamic_recapture_present": 0,
  "request_not_busy_assertions": 4
}
```

This confirms the expected current boundary before `.421`: no
`static_capture`, no release-recapture fields under
`dynamic_capture.transactions[0]`, and request-not-busy assertions for
`r0`, `r1`, `r2`, and `r3`.

## Audit Scope For `.421`

The readiness audit must decide whether direct implementation is safe and, if
so, pin:

- public syntax preservation for the existing three-static burst-last sample;
- report mode `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- one-bit `last_signal: axi0_rlast`;
- `transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
- dynamic recapture under `dynamic_capture.transactions[0]` for `r0`;
- list-shaped `static_capture[]` entries for `r1`, `r2`, and `r3`;
- release-recapture source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`;
- dynamic guards across all three static requests and all three static-ID
  exclusions;
- static guards across the dynamic request and both sibling static requests;
- release-only same-transaction request exclusions;
- idle-or-releasing assertion names for all four transactions;
- preservation of raw non-final `RID` active/unique-match assertions;
- preservation of one-static and two-static RLAST recapture report shapes;
- preservation of two-dynamic-plus-one-static no-recapture boundaries; and
- validation strategy under the default RAM guard.

## Deferred Boundaries

Two-dynamic-plus-one-static read recapture, layered recapture-specific
consumer changes, static-busy-only recapture outside selected public mixed
samples, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, and full AXI manager behavior
remain later exact owners unless `.421` selects a smaller prerequisite.

## Rollback

Rollback is the `.420` selector commit. Reverting it removes the next-owner
selection, fact card, task-tree advancement to `.421`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry. No generated behavior
changes in this selector.
