# AXI IAL2 Manager Dynamic Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.371`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.371` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.372`, direct generated behavior for
single-active dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Selected Public Shape

The behavior owner reuses the existing support-accounted burst-last dynamic
read response-demux public sample and source syntax:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

No new source marker is required. The selected behavior applies only when the
public shape has:

- exactly one selected read transaction with `(id dynamic)`;
- explicit `response-demux.read`;
- `response-scope burst-last`;
- one-bit `last-signal`;
- raw read response event `axi0_read_complete`;
- generated transaction completion for the dynamic read transaction;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- no multiple dynamic read transactions; and
- no mixed dynamic/static read transactions.

Scalar last-beat read-data, report-only raw-`ARLEN`, runtime
beat-count/`RLAST`, and multi-beat output-bank samples that layer on this same
one-dynamic/no-static burst-last response-demux are preservation consumers.
They may inherit the shared response-demux selected-ID lifetime and report
vocabulary, but they must not gain new payload outputs, new burst-length
syntax, new beat-count semantics, or separate payload recapture rules in this
first behavior owner.

## Selected Behavior Contract

FSMGen should continue to capture the read-family request ID source at the
admitted read request, match raw accepted `RID` response beats against the
active captured ID, and pulse the generated completion only when the matched
beat also has `RLAST`.

The widened same-cycle boundary is:

- capture-only: when an admitted read request occurs while the dynamic slot is
  idle, capture `ARID` and set busy;
- matched non-last beat: when a raw accepted beat matches the captured `RID`
  but `RLAST` is low, keep the dynamic slot active, do not pulse completion,
  do not release, and do not recapture;
- release-only: when the generated `RID && RLAST` completion occurs while the
  dynamic slot is busy and no same-cycle request for that transaction occurs,
  clear busy; and
- final release-and-recapture: when the generated `RID && RLAST` completion
  occurs while the slot is busy and a same-cycle request for that transaction
  also occurs, pulse completion, capture the new `ARID`, and leave busy
  asserted.

The final response match uses the pre-update selected ID and busy state. The
recapture update owns the next-cycle selected ID and busy state. Matched
non-last beats are raw-response consumers only; they are not release or
recapture events.

## Report Contract

Schedule, check, and semantic JSON should preserve the existing mode strings:

```text
response_demux.mode = bounded_dynamic_read_rid_rlast_demux_contract
response_demux.read.mode = bounded_dynamic_read_rid_rlast_demux_contract
```

The read dynamic-capture report should add explicit same-cycle vocabulary:

```yaml
dynamic_capture:
  release_recapture_rule: axi0_r0_dynamic_id_release_recapture
  same_cycle_release_recapture_policy: single_active_dynamic_read
  release_recapture_source: generated_dynamic_demux_last_beat_completion
  release_recapture_transaction: r0
```

The response-demux completion source remains last-beat-specific:

```text
transaction_completion_source = generated_dynamic_demux_last_beat
transaction_completion_semantics = matched_dynamic_id_and_last_signal
```

The existing last-beat read-data and burst/runtime/multi-beat report
vocabulary should remain payload-compatible:

```text
completion_validity = generated_dynamic_read_response_demux_last_beat_completion_pulse
beat_match_source = response_demux_matched_read_beat
beat_count_match_source = response_demux_matched_read_beat
```

Only the shared response-demux dynamic-capture and generated-assertion
vocabulary should change for those preservation consumers.

## Assertion Contract

The old burst-last single-active dynamic read request-not-busy assertion is too
narrow for this selected boundary. `.372` should replace or supersede it with a
condition equivalent to:

```text
admitted_dynamic_read_request -> (!dynamic_busy_q || generated_rid_rlast_completion)
```

The selected assertion name should match the single-beat read recapture
vocabulary:

```text
axi0_r0_dynamic_request_idle_or_releasing
```

The response active-match assertion remains raw-read-response based and must
not require `RLAST`:

```text
axi0_read_dynamic_response_active_match
```

The completion-active assertion remains required:

```text
axi0_r0_dynamic_completion_active
```

Multiple-dynamic active-ID uniqueness, mixed dynamic/static onehot0 and static
ID exclusion assertions, static busy release-recapture, dynamic same-ID queues,
and scoreboard assertions remain outside this first burst-last read owner.

## Validation Contract

`.372` should cover:

- generated `.isf` rule/update shape for capture-only, release-only, matched
  non-last, and final release-and-recapture cycles;
- scheduled `.fsm` lowering without same-target conflicts;
- schedule/check/semantic JSON report vocabulary for the burst-last response
  demux sample;
- SystemVerilog generation where RAM permits;
- focused preservation for scalar last-beat dynamic read-data;
- focused preservation for dynamic report-only raw-`ARLEN`, runtime
  beat-count/`RLAST`, and multi-beat output-bank samples;
- preservation that multiple dynamic and mixed dynamic/static burst-last read
  response-demux samples still use their existing request assertions until
  separately selected;
- preservation for single-beat read recapture and dynamic write recapture; and
- Knowledge Map, mdBook, memory, diff, and doctrine gates.

## Deferred Boundaries

Multiple dynamic request widening, multiple dynamic burst-last recapture, mixed
dynamic/static recapture, static busy recapture, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.
