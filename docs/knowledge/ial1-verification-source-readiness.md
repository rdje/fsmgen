---
id: ial1-verification-source-readiness
title: IAL1 verification primitives are not enough for first-class verification-code generation
answers:
  - "are existing IAL1 verification primitives enough for generated verification code?"
  - "what did the IAL1 verification source readiness audit decide?"
  - "why not generate UVM directly from assert assume cover?"
  - "what is the next IAL1 verification-code generation prerequisite?"
  - "what IAL1 source feature comes before SV/UVM verification generation?"
date: 2026-06-16
status: current
tags: [ial1, isf, verification, sv-uvm, vhdl, task-tree]
evidence: docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md
reverify: rg -n 'Source Readiness Audit|observation contract|not enough|insufficient|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3' docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` decided that the existing IAL1
verification primitives are enough for the current inline SystemVerilog
assertion/property path, but not enough for first-class generated verification
artifacts such as UVM monitors, agents, scoreboards, coverage collectors,
reusable VIP, or VHDL-oriented verification outputs.

The next prerequisite is `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`: select
a bounded IAL1 verification-specific source/report feature family, expected to
start with passive observation roles and source identity for future generated
monitors/checkers. SV/UVM output, VHDL output, direct IAL2 routing, and public
CLI/artifact contracts stay behind later selector leaves.

