---
id: isf-atl-trigger-batch-generated-top
title: ISF ATL trigger-batch generated-top boundary
answers:
  - "what is the ATL trigger-batch generated-top boundary?"
  - "which ISF fixture ships the resolved-child trigger-batch generated top?"
  - "what generated_tops kind reports a resolved-child trigger batch?"
  - "can a resolved-child ATL trigger batch emit a generated top?"
  - "what remains deferred for resolved-child trigger-batch generated tops?"
date: 2026-06-11
status: current
tags: [isf, atl, trigger-batch, generated-top, actor-network]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; isf/atl_two_child_trigger_batch_pipeline.isf; t/1330-isf-atl-resolved-child-fixture-coverage.t; docs/book/src/13f-composition.md; docs/ISF_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
reverify: prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t
---

`isf/atl_two_child_trigger_batch_pipeline.isf` is the shipped resolved-child
ATL trigger-batch generated-top fixture.

The accepted source shape has exactly two resolved children, one contiguous
transaction-body trigger batch, source-ordered waits to both triggered
children, no static group declaration, and no ATL data movement. Lowering
emits the parent `.fsm`, both resolved child `.fsm` artifacts, and one
generated ATL top.

The parent pulses both generated child start handoffs in one
`run_atl_trigger_batch_1` state, then waits sequentially for the child events.
Schedule JSON preserves `transaction_triggers[]`, `event_waits[]`,
`association_schedules[]`, and `group_schedules[]`, and reports the generated
top under `actor_network.generated_tops[]` with kind
`resolved_children_trigger_batch_event_sequence`.

Static group declarations, data movement coupled to the trigger batch,
repeated child activations or waits, non-source-ordered waits, nested
waits/triggers, CDC, payload protocols, ready/backpressure, route mux/storage,
recursive actor networks, and permanent actor grouping remain deferred.
