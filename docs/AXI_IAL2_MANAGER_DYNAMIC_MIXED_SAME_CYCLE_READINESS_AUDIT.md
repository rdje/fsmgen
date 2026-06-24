# AXI IAL2 Manager Dynamic/Mixed Same-Cycle Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.363`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.363` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.364`, public contract selection for the
first single-active dynamic write `BID` same-cycle release-and-recapture
boundary.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence

Current capacity admission is already same-cycle completion aware. The shared
admitted-request guard accepts a request when the direction pending count is
below `max-pending` or when a same-direction completion fan-in is present:

```text
request_event && (pending_storage < max_pending || completion_fanin)
```

The generated capacity matrix also documents and tests that submit plus
completion in the same cycle preserves occupancy, and that a full write
direction can accept a submit when a write completion occurs in that same
cycle.

Response-demux state ownership is narrower than capacity admission. Dynamic
and mixed dynamic/static capture guards require the target slot to be idle:

```text
admitted_request && !dynamic_busy_q
admitted_request && !static_busy_q
```

Release is emitted as a separate generated rule that clears the same busy bit
from the generated completion pulse:

```text
generated_completion && dynamic_busy_q -> dynamic_busy_q = 0
generated_completion && static_busy_q  -> static_busy_q = 0
```

The generated assertions intentionally match that current boundary. Dynamic
and static transactions report request-not-busy assertions; multiple dynamic
and mixed shapes additionally report onehot0 same-cycle request policy, active
dynamic selected-ID uniqueness, request no-active-same-ID checks, static
concrete-ID exclusions, response active-match, response unique-match, and
completion-active assertions.

The public behavior notes and focused tests lock in the same contract:

- single-active dynamic write/read captures are guarded by `!busy` and release
  from the generated completion pulse;
- multiple all-dynamic write/read captures block sibling same-cycle requests
  and active same-ID reuse;
- mixed dynamic/static captures block sibling dynamic/static requests and
  static concrete-ID conflicts; and
- read-data consumes generated response-demux completion pulses, so read
  payload widening should wait until the response-demux lifetime is contract
  selected.

## Audit Answers

Same-cycle request plus generated completion cannot be treated as already
supported for dynamic or mixed response-demux slots. Capacity may accept the
direction-level request, but the current generated response-demux contract
requires the selected dynamic/static slot to be idle at request capture time.
A request for a still-busy slot in the same cycle as its generated completion
therefore remains outside the shipped dynamic/mixed contract.

Dynamic release-and-recapture is the smallest behavior that can move safely,
but only after a public contract selection defines the state-transition shape.
The implementation must avoid overlapping same-target writes between capture
and release rules. It likely needs either disjoint capture/release/recapture
rules with provable guards or a single generated state-transition owner for
the selected-ID and busy state.

Static release-and-recapture should not be first. Static slots have the same
busy-state recapture problem, but mixed shapes also include static concrete-ID
exclusions and onehot0 dynamic/static sibling policy. They should follow a
successful dynamic single-slot contract rather than define the first update
semantics.

Same-cycle request-policy widening beyond onehot0 across siblings should
defer. Allowing multiple selected dynamic/static requests in one direction
touches sibling request mutual exclusion, active dynamic selected-ID
uniqueness, static-ID exclusions, direction capacity accounting, and future
queue/scoreboard policy. That is larger than release-and-recapture for one
selected slot.

Read-side payload behavior should also defer. Read-data capture is guarded by
generated completion pulses and depends on response-demux lifetime semantics.
Changing read response-demux recapture before defining payload behavior is
safe only if the first owner avoids read-data and `RLAST` complications.

## Selected .364 Scope

`.364` should select the public contract for a first single-active dynamic
write `BID` same-cycle release-and-recapture behavior over the existing
support-accounted sample:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

The contract selection should decide:

- whether the existing source syntax remains unchanged or needs an explicit
  same-cycle policy marker;
- report vocabulary for the widened boundary, including the request slot
  lifetime and generated assertion names;
- whether the behavior should keep `bounded_dynamic_write_bid_demux_contract`
  with an added same-cycle policy field or use a new mode string;
- the exact generated update shape for capture-only, release-only, and
  release-and-recapture cycles;
- how the request-not-busy and completion-active assertions change;
- focused validation for generated `.isf`, scheduled `.fsm`, schedule JSON,
  strict check JSON, semantic JSON, and HDL where RAM permits;
- preservation gates for current single-active read, multiple all-dynamic,
  mixed dynamic/static, two-dynamic-plus-one-static, read-data, queue-head,
  capacity, and support-accounting samples; and
- rollback, Knowledge Map, mdBook, direct-backend deferral, and VHDL deferral.

## Non-Goals

`.364` should not implement behavior. It should not widen multiple dynamic or
mixed dynamic/static same-cycle request policy, static release-and-recapture,
read `RID`/`RLAST` recapture, read-data capture, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, or full AXI manager behavior.
