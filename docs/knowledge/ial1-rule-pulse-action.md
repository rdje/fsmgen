---
id: ial1-rule-pulse-action
title: IAL1 rule admission and bounded one-cycle pulse actions
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.29 ship?"
  - "can an IAL1 rule emit a one-cycle pulse?"
  - "what is the IAL1 rule pulse action?"
  - "how does (pulse TARGET) lower?"
  - "does an undeclared ISF rule operand create an input port?"
  - "what validates ISF rule guards and RHS reads?"
date: 2026-09-24
status: current
tags: [ial1, isf, rule, pulse, ial2, response-demux]
evidence: perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1181-isf-rule-action-boundary.t; t/1168-isf-rule-guard-factoring.t; t/1207-isf-assignment-provenance-inventory.t; t/1208-isf-compatible-fanin-classification.t; docs/ISF_SPEC.md; docs/book/src/13g-rules.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/1888-isf-rule-operand-admission.t t/1181-isf-rule-action-boundary.t t/1168-isf-rule-guard-factoring.t t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t
---

`.32.1.1` of `SEMANTIC-INTROSPECTION-MCP-FRONTIER` validates ordinary rule reads before actor-shell return.
Guards, RHS expressions, selections and bank operands resolve against actor ports/storage, parameters/constants,
enums and aggregate leaves. Unknown names cannot become input ports; transaction-private values stay private.
`FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND` identifies actor, operands and reading rules through native
check/semantic JSON, API and newline MCP. T1888 and its owning tree retain before/after and transport evidence;
the separate width-diagnostic repair remains owned by `.32.1.2`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` shipped `(rule NAME GUARD (pulse TARGET))`.
`TARGET` must be a scalar actor output or storage variable. Malformed actions and input/other targets fail before lowering.
The action lowers to the one-cycle delayed pulse `(<1 (TARGET 1))`; outputs use `(<1 (TARGET> 1))`.
Assignment provenance records source kind `rule_pulse_action`, operator `<1` and domain `pulse`.
Compatible fan-in treats it as a completion pulse, not a sticky flopped data write.
The AXI write `BID` response-demux behavior audit selected this prerequisite so rules can pulse transaction
completion names through the required IAL2 -> IAL1 -> IAL0 -> SystemVerilog chain.
