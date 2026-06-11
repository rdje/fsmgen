---
id: isf-atl-trigger-batch-wait-boundary
title: ISF ATL trigger-batch multi-event wait boundary
answers:
  - "what is the ATL trigger-batch multi-event wait boundary?"
  - "what diagnostic reports repeated ATL actor-event waits after a trigger batch?"
  - "where is repeated trigger-batch event wait validation implemented?"
  - "why do repeated ATL waits after a trigger batch fail closed?"
date: 2026-06-11
status: current
tags: [isf, atl, trigger-batch, event-wait, diagnostics]
evidence: perl/FSM/Adapter/ISF/Parser.pm; t/1322-isf-actor-network-static.t; t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t; docs/book/src/13f-composition.md; docs/ISF_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
reverify: prove -Iperl t/1322-isf-actor-network-static.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t
---

The accepted ATL trigger-batch multi-event wait shape is parser-owned in
`FSM::Adapter::ISF::Parser`. One contiguous temporary trigger batch may be
followed immediately by contiguous, source-ordered top-level
`(await actor.event)` clauses only when every wait targets a distinct
triggered actor instance and the segment has no ATL data movement.

Repeated waits to the same triggered actor after that batch remain
fail-closed. The parser emits a targeted diagnostic that names the repeated
wait and states that repeated actor-event waits require an event re-arm or
per-event generation/lifetime contract. This prevents the second wait from
being misread as a guaranteed new child event when the current handoff is only
an external one-bit parent input.

Non-batch multi-wait forms, nested actor-event waits, hidden fan-in/fan-out
joins, payload waits, generated child event wiring, CDC, and ready/backpressure
remain outside this boundary until a later task-tree leaf publishes the
missing contracts.
