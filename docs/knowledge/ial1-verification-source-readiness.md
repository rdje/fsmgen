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
evidence: docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md; docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md; docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md
reverify: rg -n 'Source Readiness Audit|observation contract|not enough|insufficient|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7|ISF-VERIFICATION-OBSERVATION-METADATA|observe NAME|passive_monitor|passive UVM monitor skeleton' docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` decided that the existing IAL1
verification primitives are enough for the current inline SystemVerilog
assertion/property path, but not enough for first-class generated verification
artifacts such as UVM monitors, agents, scoreboards, coverage collectors,
reusable VIP, or VHDL-oriented verification outputs.

The selected source prerequisite,
`ISF-VERIFICATION-OBSERVATION-METADATA.1`, shipped actor-level passive
observation metadata, `(observe NAME (role passive_monitor) (signals SIG...))`,
as the first IAL1 verification-specific source/report feature family.
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` selected a passive UVM monitor
skeleton package as the first SV/UVM output target. SV/UVM emission, VHDL
output, direct IAL2 routing, and public CLI/artifact contracts stay behind
later selector leaves; the next frontier leaf is
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`, which selects the public
CLI/artifact layout, report/manifest, support-accounting, and validation gates
for the selected passive UVM monitor skeleton.
