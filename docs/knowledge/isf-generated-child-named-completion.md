---
id: isf-generated-child-named-completion
title: Generated child named completion preserves authored pulses and activation handshakes
answers:
  - "why did a generated child completing a named output fail to release its parent?"
  - "how are child named completion outputs combined with parent completion?"
  - "why must delayed pulses be excluded from inferred shared datapaths?"
date: 2026-09-27
status: current
tags: [isf, composition, children, completion, pulse, domains, mcp]
evidence: perl/FSM/Scheduler/ISF/ChildCompletionOutputs.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; perl/FSM/Composition/SharedDatapathCandidateBuilder.pm; t/1913-isf-generated-child-named-completion.t; t/1912-isf-multi-domain-generated-children.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1913-isf-generated-child-named-completion.t t/1912-isf-multi-domain-generated-children.t
---

Generated child ports always contained canonical done, but authored complete
only pulsed its target. Noncanonical actor outputs lacked top wiring and the
parent's activation handshake stayed low. ChildCompletionOutputs preserves the
authored delayed pulse and adds canonical done at the same terminal state.
Noncanonical actor completion outputs feed private per-instance parent inputs.
The parent exposes their OR view without another clocked stage. Its own complete
to that name moves into a private delayed pulse feeding the same view. Other
writer kinds are rejected. Explicit transaction-local ports retain binding
semantics; canonical child done stays an activation handshake. Automatic actor
completion routing bypasses the legacy suffix lookup, preventing same-spelled public inputs from gaining a driver.

Coincident named completions merge into an asserted cycle; adjacent events can
remain high across adjacent cycles. Named bit aliases retain type identity.
Repeated activation and domain-local clock/reset behavior are covered by exact
runtime pulse oracles, scheduled replay and full native/API/newline reports.
This is completion-event forwarding, not general shared-storage writer support.

Runtime also exposed false cross-instance shared-datapath assertions. Output
summaries described delayed pulses only as flops, so same-name event ports
entered ordinary shared-register inference. Lowered output-drive families now
carry nullable integer pulse_delay_cycles, derived by the runtime assignment
helper. Inference excludes an entire same-name family containing delayed pulses.
Holding-register/combinational sharing and its checks remain independently
regression-covered. This does not qualify arbitrary independent same-name
holding registers for sharing.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.46.
