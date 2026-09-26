---
id: isf-declared-input-preservation
title: Declared ISF inputs survive unused-port inference in ordinary and domain FSMs
answers:
  - "why did an unused actor input disappear from generated HDL?"
  - "how are unused domain inputs preserved through generated top wiring?"
  - "do semantic API and MCP reports retain unused ISF input names and widths?"
date: 2026-09-26
status: current
tags: [isf, interface, input, lowering, domains, semantics, mcp]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/1897-isf-declared-input-preservation.t; docs/book/src/13a-actor-interface.md; docs/audits/specforge-rule-admission-20260924/declared-input-preservation.json
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh -- prove -v -Iperl -It/lib t/1897-isf-declared-input-preservation.t
---

Actor input declarations previously survived lowering only as `+size` width
entries. With no scheduled read, FSM signal inference omitted the input role.
Multi-domain tops then failed strict endpoint resolution, while ordinary
actors could pass strict admission yet silently lose an unused public pin.
The retained baseline shows both outcomes through actual native reports and
materialized artifacts, including an absent vector input in ordinary HDL.

`LoweringIR::_build_parent_ir` now retains the actor interface's input roles
in `explicit_interface_ports`. The existing emitter writes `+interface`
entries; the full FSM parser registers `explicit_port_role`, which the signal
analyzer honors before usage inference. Width/type ownership remains in
`+size`. Partitioned domain actors take the same path, retaining their own
authored inputs and injected crossing inputs. Inferred storage is not added
to that interface list. Separately generated transaction children keep their
existing input selection; a parent-only unused input does not become a child
port merely because its parent declares it.

The native semantic report exposes realized inputs with their names, directions
and widths. Ordinary FSM signal analysis keeps clock/reset metadata separate;
multi-domain top signal analysis and schedule counts include the public system
pins. Domain schedule `ports.inputs` lists authored inputs, while the joined
semantic composition child's input analysis includes crossing handoffs too.
Complete check/semantic/schedule reports remain shared by the API and actual
newline MCP adapter. No new public field or schema is introduced.

T1897 verifies ordinary/named-single/domain actors, scalar/vector/symbolic
widths, allocated-domain collisions, actual exported FSMs and complete public
query parity. Its independent Verilog-family oracle toggles unused domain
pins during repeated event transfers and reset controls. A real qualified
Verilator provider is required for behavior qualification; skips are not
passes. The audit retains before/after source reports and HDL, the used-input
control comparison, exact commands, test receipts, producer hashes and fresh
book render checks. Broader activation watchdog/reachability defects remain
owned by `.32.1.3.3.3` and `.32.1.3.3.1`.
