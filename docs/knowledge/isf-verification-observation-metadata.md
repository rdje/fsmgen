---
id: isf-verification-observation-metadata
title: ISF passive observation metadata ships as report-only verification intent
answers:
  - "does ISF observe metadata ship?"
  - "what does verification_observations report?"
  - "does observe metadata generate fsm or HDL?"
  - "does observe metadata generate UVM or VHDL?"
  - "what constraints apply to ISF observe metadata?"
  - "which fixture covers ISF verification observation metadata?"
date: 2026-06-16
status: current
tags: [ial1, isf, verification, observation, schedule-report]
evidence: perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl/FSM/Support/ISFPublicInterfaceContract.pm; isf/verification_observation_metadata.isf; t/1260-isf-verification-observation-metadata.t; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md; docs/ISF_SPEC.md; docs/book/src/13h-lowering-reference.md
reverify: rg -n 'verification_observations|observe NAME|passive_monitor|verification_observation_metadata|schedule_report_verification_observation' perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/LoweringIR.pm perl/FSM/Scheduler/ISF/Emitter/JSON.pm perl/FSM/Support/ISFPublicInterfaceContract.pm isf/verification_observation_metadata.isf t/1260-isf-verification-observation-metadata.t docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md docs/ISF_SPEC.md docs/book/src/13h-lowering-reference.md
---

`ISF-VERIFICATION-OBSERVATION-METADATA.1` shipped the first IAL1
verification-specific source feature: actor-level passive observation
metadata.

The accepted form is:

```lisp
(observe NAME
  (role passive_monitor)
  (signals SIG...))
```

The parser accepts the form only in a single-clock actor. `NAME` must be a
scalar HDL identifier, the role must be exactly `passive_monitor`, and
`SIG...` must be a non-empty source-ordered list of unique public actor
interface signal names. Storage names, transaction-local ports, dotted or
child endpoints, unknown signals, unsupported roles, duplicate signals, and
duplicate observation names fail closed.

The schedule report exposes the metadata through `verification_observations[]`.
Each observation entry reports `name`, `role`, inherited `clock`, `reset`, and
`signals`; each signal entry reports `name`, `direction`, and resolved scalar
`width`.

The feature is report-only. It does not generate scheduled `.fsm` carriers,
HDL, UVM, VHDL, scoreboards, coverage, reusable VIP, or public verification
output artifacts.

The supported-smoke fixture is
`isf/verification_observation_metadata.isf`; focused coverage lives in
`t/1260-isf-verification-observation-metadata.t`.
