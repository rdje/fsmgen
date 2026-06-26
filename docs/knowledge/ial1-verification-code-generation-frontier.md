---
id: ial1-verification-code-generation-frontier
title: IAL1 owns the verification-code generation frontier
answers:
  - "where is IAL1 verification-code generation task-tree tracked?"
  - "where does FSMGEN verification-code generation fit now?"
  - "should verification output be part of the synthesizable RTL lane?"
  - "should verification generation start from IAL1 or IAL2?"
  - "are IAL1 verification-specific features task-tree tracked?"
  - "what owns future SV/UVM verification-code generation?"
  - "what owns the first verification-output CLI implementation?"
  - "what owns future VHDL verification-code generation?"
date: 2026-06-16
status: current
tags: [ial1, isf, verification, sv-uvm, vhdl, task-tree]
evidence: docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md; docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md; docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md; docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md; docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md; docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md; docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial1-vhdl-verification-output-selection.md; docs/knowledge/ial1-vhdl-verification-validation-substrate-selection.md; docs/knowledge/ial1-vhdl-observation-package-selection.md; docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md
reverify: rg -n 'IAL1-VERIFICATION-CODE-GENERATION-FRONTIER|IAL1 verification-specific|SV/UVM|VHDL-oriented verification|Direct IAL2-to-verification|Verification Code Generation|ISF-VERIFICATION-OBSERVATION-METADATA|observe NAME|verification_observations|passive UVM monitor skeleton|--emit-verification-output uvm-passive-monitor|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11|vhdl-observation-package|vhdl_observation_package_skeleton' docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial1-verification-code-generation-frontier.md docs/knowledge/ial1-vhdl-verification-output-selection.md docs/knowledge/ial1-vhdl-verification-validation-substrate-selection.md docs/knowledge/ial1-vhdl-observation-package-selection.md docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md
---

FSMGen verification-code generation is now owned by the active
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER` task tree.

The selected starting stance is IAL1 (`.isf`) to verification code. Frontier
`.2` found the existing IAL1 checks/properties sufficient for inline SV
assertion projection but insufficient for first-class generated verification
artifacts. Frontier `.3` selected actor-level passive observation metadata,
`(observe NAME (role passive_monitor) (signals SIG...))`, as the first IAL1
verification-specific source feature. Implementation
`ISF-VERIFICATION-OBSERVATION-METADATA.1` shipped that report-only source
contract through `verification_observations[]`. Frontier `.4` selected a
passive UVM monitor skeleton package as the first SV/UVM output target.
Frontier `.7` selected the public CLI, artifact layout, report/manifest shape,
support-accounting identity, and validation gates:
`--emit-verification-output uvm-passive-monitor --verification-outdir DIR
source.isf`. Frontier `.8` implements that first bounded inert UVM
passive-monitor skeleton output and advertises it through the capability
manifest without claiming UVM compile support. Frontier `.5` audited VHDL
assertion/testbench/PSL feasibility and selected no VHDL verification artifact
yet. Frontier `.9` selected shape-only inert-artifact validation with explicit
no-compile/no-PSL manifest claims. Frontier `.10` selected the first VHDL
artifact, an inert observation metadata package with future target
`vhdl-observation-package`; `.11` owns implementation.

Future target families are explicitly tracked, not implied: SV/UVM agents,
monitors, scoreboards, protocol checkers, coverage, reusable verification IP,
and VHDL-oriented verification artifacts each require contract-selection and
validation-substrate owners before implementation.

The next eligible verification-code-generation leaf is `.11`, implementing the
selected inert VHDL observation package target. Direct IAL2-to-verification
generation remains an audit question. It may later be selected as a direct
route, as an IAL2-to-IAL1 verification annotation handoff, or as unnecessary
for the first implementation. No implementation may assume that answer before
the audit completes.
