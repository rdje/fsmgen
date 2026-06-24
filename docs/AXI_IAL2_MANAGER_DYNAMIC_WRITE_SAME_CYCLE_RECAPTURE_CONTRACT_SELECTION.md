# AXI IAL2 Manager Dynamic Write Same-Cycle Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.364`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.364` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.365`, direct generated behavior for
single-active dynamic write `BID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Selected Public Shape

The first behavior owner reuses the existing support-accounted public sample
and source syntax:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

No new source marker is required for the first boundary. The selected contract
applies only when the existing public shape has:

- exactly one selected write transaction with `(id dynamic)`;
- explicit `response-demux.write`;
- raw response event `axi0_write_complete`;
- generated transaction completion for the dynamic write transaction;
- no write `auto_id_lifecycle`;
- no `same_id_ordering.write`; and
- no mixed dynamic/static, multiple dynamic, queue, scoreboard, read, or
  read-data behavior in this first owner.

## Selected Behavior Contract

For the single-active dynamic write transaction, FSMGen should continue to
capture the write-family request ID source at the admitted write request,
match accepted `BID` responses against the active captured ID, and pulse the
generated transaction completion from the match.

The widened same-cycle boundary is:

- capture-only: when an admitted write request occurs while the dynamic slot is
  idle, capture `AWID` and set busy;
- release-only: when the generated completion occurs while the dynamic slot is
  busy and no same-cycle request for that transaction occurs, clear busy;
- release-and-recapture: when the generated completion occurs while the slot
  is busy and a same-cycle request for that transaction also occurs, pulse the
  generated completion, capture the new `AWID`, and leave busy asserted.

The response match uses the pre-update selected ID and busy state. The
recapture update owns the next-cycle selected ID and busy state. This avoids
using the newly captured `AWID` to match the response that caused the release.

## Report Contract

Schedule, check, and semantic JSON should preserve the existing mode:

```text
response_demux.mode = bounded_dynamic_write_bid_demux_contract
response_demux.write.mode = bounded_dynamic_write_bid_demux_contract
```

The write dynamic-capture report should add explicit same-cycle vocabulary:

```yaml
dynamic_capture:
  same_cycle_release_recapture_policy: single_active_dynamic_write
  release_recapture_source: generated_dynamic_demux_completion
  release_recapture_transaction: w0
```

The generated behavior report should continue to name the selected-ID and busy
storage. It should also report the generated update rules that implement the
three selected cases. Exact rule names may be selected by `.365`, but they
must distinguish capture-only, release-only, and release-and-recapture in the
report or generated artifact list.

## Assertion Contract

The old request-not-busy assertion is too narrow for this selected behavior.
`.365` should replace or supersede the single-active dynamic write assertion
role with a condition equivalent to:

```text
admitted_dynamic_write_request -> (!dynamic_busy_q || generated_completion)
```

The completion-active assertion remains required:

```text
generated_completion -> dynamic_busy_q
```

The response active-match assertion remains required for the raw write
response event. Multiple-dynamic active-ID uniqueness, request no-active-same
ID, static-ID exclusions, and mixed request onehot0 assertions remain outside
this first single-active behavior owner.

## Validation Contract

`.365` should cover:

- generated `.isf` rule/update shape for capture-only, release-only, and
  release-and-recapture;
- scheduled `.fsm` lowering without same-target conflicts;
- schedule/check/semantic JSON report vocabulary;
- SystemVerilog generation where RAM permits;
- focused preservation for existing single-active dynamic write behavior
  outside the same-cycle case;
- preservation for single-active dynamic read, multiple all-dynamic write/read,
  mixed dynamic/static write/read, two-dynamic-plus-one-static mixed shapes,
  read-data, queue-head, capacity/status, and support-accounting surfaces; and
- Knowledge Map, mdBook, memory, diff, and doctrine gates.

## Deferred Boundaries

Multiple dynamic write request widening, mixed dynamic/static write recapture,
static busy recapture, read `RID`/`RLAST` recapture, read-data payload capture,
dynamic same-ID queues, scoreboards, queued/blocking policy, profile aliases,
direct backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.
