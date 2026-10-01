---
id: isf-generated-input-first-compile-failure
title: Generated mixed-state whole copies expose an illegal typed composition wire
answers:
  - "why did the first generated record-input runtime compile fail?"
  - "is generated mixed-state whole-copy runtime qualified?"
  - "where is the generated mixed-state typed wire defect owned?"
date: 2026-10-01
status: current
tags: [isf, record-ports, composition, backend, defects, runtime]
evidence: docs/audits/record-input-generated-observation-20261001/manifest.json; docs/audits/record-input-generated-observation-20261001/diagnosis.json; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm; t/167-structural-connection-expr-helpers.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/record-input-generated-observation-20261001/verify.py
---

SEM .60.4.3.2.5.4.3.1 preserves and diagnoses fresh spent generated_input_oct01
under the committed exact observer. Verilator rejects the first named-domain
SystemVerilog whole-copy compile: the typed composition wire contains nested
authored two_state bit members. No simulation or later pair executes.
StructuralRTLIREmitter::_render_net_line prefixes wire to the aggregate typedef;
TypeDeclarationSupport preserves the authored leaf state models. Unchanged
strict public source re-emission reproduces both compiler-reported declaration
and member locations. T167's old structural-only oracle expects the illegal
mixed-state wire. Declaration repair .5.4.3.2 is now structurally qualified with exact old-emitter
RED and complete public-product controls, preserving the typedef on a variable
carrier. Fresh corrected observation compiles and passes both named-domain
families and compiles ordinary blocking SystemVerilog, closing this reached
declaration rejection. Complete runtime remains open: the blocking test has a
separately diagnosed late-hold oracle error under .3.3.1-.2. See the generated
blocking binding fact for its partial scope.

Original complete admission/stage/results/arguments/bounds/summary/cleanup,
source and producer Git identities before/after and full TAP are sealed.
Only outer stderr's exact active repository prefix is projected away; its
original hash and complete stage record remain. Normal temporary cleanup
removed compiled HDL/binaries; separately labeled re-emission is diagnosis,
not captured original compiled bytes. Independent selected workspace/command
census is absent. Successful native calls deliberately emit no PID context,
so individual successful-child PID absence is not independently measured.
Native failure events and diagnostic gaps are empty; historical EPERM is
unattributed. The pre-result success-verifier draft is explicitly unqualified.

Actual retained rejection, complete identities and public re-emission provide
re-derivation. Hostile saved result/bounds/coverage/target/identity/native/gap
and cleanup mutations provide independent falsification. Immutable archive,
fixed source/bench, producer Git blobs, scheduled repair, task/book/response
and Git provide durability. Saved reverify executes no HDL or native fixture.
