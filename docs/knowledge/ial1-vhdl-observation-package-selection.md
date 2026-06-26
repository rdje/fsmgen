---
id: ial1-vhdl-observation-package-selection
title: The first selected VHDL verification artifact is an inert observation package
answers:
  - "what is the first selected VHDL verification artifact?"
  - "what owns VHDL observation package implementation?"
  - "what is the vhdl-observation-package target?"
  - "does the VHDL observation package generate PSL or testbench behavior?"
  - "what support-accounting entry will cover VHDL observation package output?"
date: 2026-06-26
status: current
tags: [ial1, vhdl, verification, artifact-selection, task-tree]
evidence: docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md; docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md; perl/FSM/Support/VerificationOutputsContract.pm; perl/FSM/Support/VerificationOutputsSection.pm; perl/FSM/Support/RegressionCorpus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION|vhdl-observation-package|vhdl_observation_package_skeleton|feature\\.isf_verification_observation_vhdl_package_skeleton|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.10|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.11' docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/TASK_TREE.md MEMORY.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` selected the first
VHDL-oriented verification artifact: an inert VHDL observation metadata package
skeleton.

The selected future CLI target is `vhdl-observation-package`, with canonical
target id `vhdl_observation_package_skeleton`. It consumes `.isf`
`verification_observations[]` metadata and writes
`vhdl/<actor>_observation_vhdl_pkg.vhd` plus
`verification-output-manifest.json` under the requested verification output
directory.

Implementation is owned by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11`.
The selected package is metadata-only and must not generate VHDL assertions,
PSL, testbench entities, processes, monitor behavior, sampling, publication,
scoreboards, coverage, reusable VIP, direct IAL2 protocol behavior, or any
VHDL compile/syntax/tool validation claim. The selected future
support-accounting entry is
`feature.isf_verification_observation_vhdl_package_skeleton`.
