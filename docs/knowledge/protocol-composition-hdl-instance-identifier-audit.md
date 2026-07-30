---
id: protocol-composition-hdl-instance-identifier-audit
title: HDL child instance identifiers use one portable origin-aware policy
answers:
  - "why does APB multi-peripheral HDL fail on interconnect?"
  - "which composition paths can emit reserved child instance names?"
  - "how should authored HDL instance keywords be handled?"
  - "how should generated HDL instance keywords be renamed?"
  - "what does PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1 decide?"
  - "does AHB still emit a reserved interconnect instance label?"
  - "are AXI composition instance labels currently legal?"
  - "what VHDL instance-identifier risk is known?"
  - "is the portable HDL child instance identifier policy implemented?"
  - "what APB interconnect instance name is generated now?"
date: 2026-07-30
status: current
tags: [composition, identifier, systemverilog, vhdl, apb, ahb, axi, isf]
evidence: docs/PROTOCOL_COMPOSITION_HDL_INSTANCE_IDENTIFIER_AUDIT.md; docs/decisions/0027-hdl-instance-identifiers-use-a-portable-origin-aware-policy.md; docs/tasks/PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.md; perl/FSM/Support/HDLInstanceIdentifierPolicy.pm; perl/FSM/Composition/Parser.pm; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1546-hdl-instance-identifier-policy.t
reverify: scratch=.artifacts/tmp/protocol-identifier-reverify; trap 'rm -rf "$scratch"' EXIT; mkdir -p "$scratch"; ./bin/fsmgen --quiet --strict --output "$scratch/apb.sv" ppif/apb_composition_multi_peripheral.ppif; rg -n 'apb_interconnect interconnect_instance \(' "$scratch/apb.sv"; ! rg -n 'apb_interconnect interconnect \(' "$scratch/apb.sv"; verilator --lint-only --sv -Wno-fatal "$scratch/apb.sv"; yosys -q -p "read_verilog -sv -noautowire $scratch/apb.sv; synth -noabc -top apb_tb"; ./bin/fsmgen --quiet --strict --output "$scratch/ahb.sv" ppif/ahb_interconnect.ppif; rg -n 'ahb_interconnect fabric \(' "$scratch/ahb.sv"; ./bin/fsmgen --quiet --strict --output "$scratch/axi.sv" ppif/axi_write_request_composition.ppif; rg -n 'axi_aw_driver aw_driver \(' "$scratch/axi.sv"
---

The shared `HDLInstanceIdentifierPolicy` validates child instance labels
against the SystemVerilog and VHDL-2008 keyword union. SystemVerilog lookup is
case-sensitive; VHDL lookup and portable collision detection are
case-insensitive. Direct C4, spawn, reusable-library, ATL, APB/AHB
normalization, and both structural emitters call the shared contract.

Authored keywords fail at their nearest bounded source boundary with the
origin, label, reserving target, and rename guidance. Direct structural IR
callers receive the same defense before either emitter renders HDL. FSMGen does
not silently rename authored labels and does not use backend-specific escaping.

Generated labels use a stable allocator: keyword seeds receive `_instance`,
ordinary collisions use the role, and numeric suffixes resolve any remainder.
APB now emits and reports `interconnect_instance`; public APB passes Verilator
parse/lint and Yosys synthesis. AHB `fabric` and the audited fixed AXI labels
remain unchanged.
