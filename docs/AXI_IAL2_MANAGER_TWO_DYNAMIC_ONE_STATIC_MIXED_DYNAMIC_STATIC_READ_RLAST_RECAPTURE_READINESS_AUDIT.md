# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.429`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.429` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.430`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this audit.

## Baseline

The support-accounted public response-demux sample already exists and is
unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

It uses the generated multiple mixed read burst-last response-demux contract:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal
```

Direct baseline probes on the burst-last response-demux, burst-last
read-data, and burst-last raw-`ARLEN` samples confirmed the live state:

```text
generated_assertions:
  axi0_r0_dynamic_request_not_busy
  axi0_r1_dynamic_request_not_busy
  axi0_r2_static_request_not_busy
static_capture: absent
release_recapture rules: absent
```

This confirms `.429` is an audit/contract-selection step, not a behavior
closeout.

## Readiness Findings

No lower parser or PPIF syntax prerequisite is needed. The `.347` public
sample already owns `response-scope burst-last`, a one-bit `last-signal`,
two dynamic read transactions, one concrete static read transaction, and
generated transaction completions.

No support-accounting prerequisite is needed. The sample is already in the
support catalog and focused dynamic transaction-ID coverage.

No new IAL1 or HDL lowering primitive is needed. Existing generated state,
rules, pulse outputs, assertions, scheduled FSM lowering, and SystemVerilog
lowering already carry dynamic selected-ID state, static busy state, release
rules, release-recapture rules, generated assertions, and final-beat
completion pulses.

`.427` supplied the missing read-side two-dynamic/one-static recapture
substrate for the single-beat sibling:

- `mixed_dynamic_static_multi_active_dynamic_read` is now a recognized dynamic
  release-recapture policy;
- the read mixed dynamic/static constructor stores sibling request and active
  same-ID block expressions for recapture lowering;
- the mixed read recapture marker can mark exactly two dynamic states plus
  one static state; and
- list-shaped `static_capture[]` for a single static transaction is already
  available in multi-dynamic mixed read mode.

The current implementation gap is therefore narrow and explicit: the
burst-last multi-mixed read normalizer currently marks one dynamic plus two or
three static states, but intentionally leaves the two-dynamic plus one-static
burst-last branch unmarked.

## Contract Selection Requirements

`.430` should select the exact public contract before behavior changes.

The selected behavior should keep public source syntax, support identity,
mode, scope, last-signal metadata, completion semantics, transaction lists,
static ID reservation, generated response-demux match rules, generated
completion outputs, raw non-final `RID` active-match assertions, pairwise raw
`RID` unique-match assertions, and completion-active assertions unchanged.

The dynamic report should add recapture fields to both dynamic entries:

```text
response_demux.read.dynamic_capture.transactions[]:
  r0 -> axi0_r0_dynamic_id_release_recapture
  r1 -> axi0_r1_dynamic_id_release_recapture
same_cycle_release_recapture_policy:
  mixed_dynamic_static_multi_active_dynamic_read
release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

The static report should add one list-shaped `static_capture[]` entry for
`r2`:

```text
release_recapture_rule: axi0_r2_static_busy_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

The contract must decide the exact preservation stance for burst-last
read-data, raw-`ARLEN`, runtime-validation, and multi-beat consumers before
implementation. The current audited baseline is no-recapture for those
consumer samples.

## Selected Next Leaf

`.430` is the next exact owner: public contract selection for the
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture behavior.

Direct implementation remains deferred until `.430` pins report fields,
guard composition, release-only rules, idle-or-releasing assertion names,
consumer preservation, validation gates, rollback, docs, and Knowledge Map
impact.
