# AXI IAL2 Manager Dynamic Read Same-Cycle Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.367`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.367` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.368`, direct generated behavior for
single-active dynamic read single-beat `RID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Selected Public Shape

The first read-side behavior owner reuses the existing support-accounted
single-beat dynamic read response-demux public sample and source syntax:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
```

No new source marker is required. The selected behavior applies only when the
public shape has:

- exactly one selected read transaction with `(id dynamic)`;
- explicit `response-demux.read`;
- `response-scope single-beat`;
- raw read response event `axi0_read_complete`;
- generated transaction completion for the dynamic read transaction;
- no `last-signal`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- no multiple dynamic read transactions; and
- no mixed dynamic/static read transactions.

The scalar single-beat dynamic read-data sample remains a preservation
consumer of the same generated completion pulse. `.368` may update the shared
response-demux state lifetime seen by that sample, but it must not add new
read-data outputs, payload matching, burst metadata, or payload recapture
semantics. Burst-last `RID && RLAST`, scalar last-beat read-data,
burst-length/runtime validation, and multi-beat output-bank shapes remain
separate owners.

## Selected Behavior Contract

For the single-active dynamic read transaction, FSMGen should continue to
capture the read-family request ID source at the admitted read request, match
accepted `RID` responses against the active captured ID, and pulse the
generated transaction completion from that match.

The widened same-cycle boundary is:

- capture-only: when an admitted read request occurs while the dynamic slot is
  idle, capture `ARID` and set busy;
- release-only: when the generated single-beat completion occurs while the
  dynamic slot is busy and no same-cycle request for that transaction occurs,
  clear busy; and
- release-and-recapture: when the generated single-beat completion occurs while
  the slot is busy and a same-cycle request for that transaction also occurs,
  pulse completion, capture the new `ARID`, and leave busy asserted.

The response match uses the pre-update selected ID and busy state. The
recapture update owns the next-cycle selected ID and busy state. This keeps
the response beat that caused the completion associated with the old captured
ID, not with the newly admitted request.

## Report Contract

Schedule, check, and semantic JSON should preserve the existing mode strings:

```text
response_demux.mode = bounded_dynamic_read_rid_demux_contract
response_demux.read.mode = bounded_dynamic_read_rid_demux_contract
```

The read dynamic-capture report should add explicit same-cycle vocabulary:

```yaml
dynamic_capture:
  release_recapture_rule: axi0_r0_dynamic_id_release_recapture
  same_cycle_release_recapture_policy: single_active_dynamic_read
  release_recapture_source: generated_dynamic_demux_completion
  release_recapture_transaction: r0
```

The existing read-data report vocabulary for the scalar single-beat
preservation consumer should remain unchanged:

```text
completion_validity = generated_dynamic_read_response_demux_completion_pulse
generated_rules = [axi0_r0_read_data_capture]
```

## Assertion Contract

The old single-active dynamic read request-not-busy assertion is too narrow for
this selected boundary. `.368` should replace or supersede it with a condition
equivalent to:

```text
admitted_dynamic_read_request -> (!dynamic_busy_q || generated_completion)
```

The selected assertion name should mirror the shipped dynamic write vocabulary:

```text
axi0_r0_dynamic_request_idle_or_releasing
```

The response active-match assertion remains raw-read-response based:

```text
axi0_read_dynamic_response_active_match
```

The completion-active assertion remains required:

```text
axi0_r0_dynamic_completion_active
```

Multiple-dynamic active-ID uniqueness, request no-active-same-ID, static-ID
exclusions, mixed request onehot0 assertions, and `RLAST`/beat-count
assertions remain outside this first single-beat read owner.

## Validation Contract

`.368` should cover:

- generated `.isf` rule/update shape for capture-only, release-only, and
  release-and-recapture;
- scheduled `.fsm` lowering without same-target conflicts;
- schedule/check/semantic JSON report vocabulary;
- SystemVerilog generation where RAM permits;
- focused preservation for current scalar single-beat dynamic read-data;
- preservation that burst-last dynamic read and scalar last-beat dynamic
  read-data still report request-not-busy until separately selected;
- preservation for dynamic write recapture, multiple all-dynamic read/write,
  mixed dynamic/static, two-dynamic-plus-one-static, burst-length/runtime,
  multi-beat, queue-head, capacity/status, and support-accounting surfaces; and
- Knowledge Map, mdBook, memory, diff, and doctrine gates.

## Deferred Boundaries

Dynamic read burst-last `RID && RLAST` recapture, scalar last-beat read-data
preservation under recapture, dynamic burst-length/runtime validation
recapture, dynamic multi-beat output-bank recapture, multiple dynamic request
widening, mixed dynamic/static recapture, static busy recapture, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.
