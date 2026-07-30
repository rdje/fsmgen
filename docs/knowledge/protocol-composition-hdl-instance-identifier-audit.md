---
id: protocol-composition-hdl-instance-identifier-audit
title: HDL child instance identifiers need one portable origin-aware policy
answers:
  - "why does APB multi-peripheral HDL fail on interconnect?"
  - "which composition paths can emit reserved child instance names?"
  - "how should authored HDL instance keywords be handled?"
  - "how should generated HDL instance keywords be renamed?"
  - "what does PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1 decide?"
  - "does AHB still emit a reserved interconnect instance label?"
  - "are AXI composition instance labels currently legal?"
  - "what VHDL instance-identifier risk is known?"
date: 2026-07-30
status: current
tags: [composition, identifier, systemverilog, vhdl, apb, ahb, axi, isf]
evidence: docs/PROTOCOL_COMPOSITION_HDL_INSTANCE_IDENTIFIER_AUDIT.md; docs/decisions/0027-hdl-instance-identifiers-use-a-portable-origin-aware-policy.md; docs/tasks/PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.md; perl/FSM/Composition/Parser.pm; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm
reverify: scratch=.artifacts/tmp/protocol-identifier-reverify; trap 'rm -rf "$scratch"' EXIT; mkdir -p "$scratch"; ! ./bin/fsmgen --quiet --strict --verify-hdl --output "$scratch/apb.sv" ppif/apb_composition_multi_peripheral.ppif; rg -n 'apb_interconnect interconnect \(' "$scratch/apb.sv"; ./bin/fsmgen --quiet --strict --verify-hdl --output "$scratch/ahb.sv" ppif/ahb_interconnect.ppif; ./bin/fsmgen --quiet --strict --verify-hdl --output "$scratch/axi.sv" ppif/axi_read_transaction_composition.ppif
---

Current parsers and helpers validate child instance labels by spelling only;
the structural SystemVerilog and VHDL emitters then render them unchanged.
APB generates the SystemVerilog keyword `interconnect`, while direct C4,
spawn, reusable-library, and ATL paths can carry an authored keyword. AHB's
generated interconnect label is the legal `fabric`, and the audited fixed AXI
labels are legal.

Focused Verilator probes reject `interconnect` through public APB, direct C4,
library-use, and spawn routes. The VHDL emitter accepts the syntax-shaped VHDL
keyword `process` and emits it as an entity label; full VHDL composition support
for the probed shapes currently stops at an earlier bounded target gate, and no
VHDL parser is installed in the active tool profile.

Decision `0027` selects one portable keyword union. Authored labels fail closed
without silent renaming; generated labels use a stable allocator, with a
keyword seed first receiving `_instance`, ordinary collisions using the role,
and numeric suffixes resolving any remainder. Proposed `.2` owns implementation
and the explicit APB report delta from `interconnect` to
`interconnect_instance`.
