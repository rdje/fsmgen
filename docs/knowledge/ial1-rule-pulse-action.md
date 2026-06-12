---
id: ial1-rule-pulse-action
title: IAL1 rules can emit bounded one-cycle pulse actions
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.29 ship?"
  - "can an IAL1 rule emit a one-cycle pulse?"
  - "what is the IAL1 rule pulse action?"
  - "how does (pulse TARGET) lower?"
date: 2026-06-12
status: current
tags: [ial1, isf, rule, pulse, ial2, response-demux]
evidence: perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1181-isf-rule-action-boundary.t; t/1168-isf-rule-guard-factoring.t; t/1207-isf-assignment-provenance-inventory.t; t/1208-isf-compatible-fanin-classification.t; docs/ISF_SPEC.md; docs/book/src/13g-rules.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: prove -Iperl t/1181-isf-rule-action-boundary.t t/1168-isf-rule-guard-factoring.t t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` shipped a bounded IAL1 rule-owned
pulse action:

```text
(rule NAME GUARD
  (pulse TARGET))
```

`TARGET` must name a scalar actor output or scalar actor storage variable. The
parser rejects malformed pulse actions and input/non-output/non-storage pulse
targets before lowering.

The lowerer emits the action as a one-cycle delayed pulse:

```text
(<1 (TARGET 1))
```

For actor outputs, the `.fsm` emitter uses the normal output marker:

```text
(<1 (TARGET> 1))
```

The assignment provenance source kind is `rule_pulse_action`, the operator is
`<1`, and the domain is `pulse`. Compatible fan-in treats rule pulse actions
like completion pulses rather than sticky flopped data writes.

This action is the IAL1 prerequisite selected by the AXI write `BID`
response-demux behavior audit so generated demux rules can pulse transaction
completion names without bypassing the layered IAL2 -> IAL1 -> IAL0 ->
SystemVerilog path.
