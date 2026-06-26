---
id: ial1-verification-output-public-surface-selection
title: The first verification-output public surface is an explicit UVM passive monitor command
answers:
  - "what did IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7 select?"
  - "what is the first verification-output CLI command?"
  - "where will passive UVM monitor skeleton artifacts be written?"
  - "does FSMGen claim UVM compile support for the skeleton?"
  - "what owns implementation of the UVM passive monitor skeleton output?"
date: 2026-06-26
status: current
tags: [ial1, isf, verification, sv-uvm, uvm, cli, artifacts, task-tree]
evidence: docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md; docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION|--emit-verification-output uvm-passive-monitor|--verification-outdir|verification-output-manifest.json|uvm_passive_monitor_skeleton|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8' docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/TASK_TREE.md MEMORY.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` selected the first public
verification-output surface:

```text
./bin/fsmgen --emit-verification-output uvm-passive-monitor \
  --verification-outdir DIR source.isf
```

The selected implementation target accepts `.isf` sources with shipped passive
`verification_observations[]` metadata only. It will write:

```text
DIR/uvm/<actor>_observation_uvm_pkg.sv
DIR/verification-output-manifest.json
```

The canonical manifest/capability target id is
`uvm_passive_monitor_skeleton`. The selected support-accounting entry is
`feature.isf_verification_observation_uvm_passive_monitor_skeleton`.

FSMGen does not claim UVM compile support for this first skeleton surface. The
selected validation boundary is artifact-shape and inert-behavior testing until
a later task-tree owner selects a tracked UVM-aware compile environment.

Implementation is owned by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8`; no generated verification
files ship in `.7`.
