---
id: ial1-verification-observation-contract-selection
title: The first IAL1 verification source feature is passive observation metadata
answers:
  - "what IAL1 verification source feature was selected first?"
  - "what owns the ISF observe metadata implementation?"
  - "what is the IAL1 verification observation contract?"
  - "does observe metadata generate UVM or VHDL?"
  - "what does ISF-VERIFICATION-OBSERVATION-METADATA own?"
date: 2026-06-16
status: current
tags: [ial1, isf, verification, observation, task-tree]
evidence: docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md; docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md; docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md
reverify: rg -n 'IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION|IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION|IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION|ISF-VERIFICATION-OBSERVATION-METADATA|observe NAME|verification_observations|passive_monitor|passive UVM monitor skeleton|--emit-verification-output uvm-passive-monitor|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8' docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` selected the first IAL1
verification-specific source feature: actor-level passive observation metadata.

The selected source form is
`(observe NAME (role passive_monitor) (signals SIG...))`. It is report-only:
implementation `.1` now populates `verification_observations[]` in schedule
JSON and must not emit scheduled `.fsm`, HDL, UVM, VHDL, scoreboard, coverage,
or VIP artifacts.

Implementation shipped in `ISF-VERIFICATION-OBSERVATION-METADATA.1`.
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` then selected a bounded passive
UVM monitor skeleton package as the first SV/UVM output target derived from
`verification_observations[]`. `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`
then selected the public verification-output surface for that skeleton, and
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8` now implements the explicit
`--emit-verification-output uvm-passive-monitor --verification-outdir DIR`
mode for `.isf` sources with passive observations. The observation metadata
itself remains schedule-report metadata; generated artifacts require the
explicit verification-output command.
