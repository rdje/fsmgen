---
id: ial1-sv-uvm-passive-monitor-skeleton-selection
title: The first SV/UVM verification output target is a passive monitor skeleton
answers:
  - "what did IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4 select?"
  - "what is the first SV/UVM verification output target?"
  - "does FSMGen generate UVM monitor code yet?"
  - "what owns public CLI artifact support for SV/UVM verification output?"
  - "why choose a passive UVM monitor skeleton first?"
  - "what CLI surface will emit the passive UVM monitor skeleton?"
date: 2026-06-26
status: current
tags: [ial1, isf, verification, sv-uvm, uvm, monitor, task-tree]
evidence: docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md; docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md; docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md; docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION|IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION|passive UVM monitor skeleton|<actor>_observation_uvm_pkg|--emit-verification-output uvm-passive-monitor|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8|verification_observations' docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/TASK_TREE.md MEMORY.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` selected the first SV/UVM
verification output target: a passive UVM monitor skeleton package derived only
from shipped `verification_observations[]` metadata.

The selected future artifact family is:

```text
uvm/<actor>_observation_uvm_pkg.sv
```

The selected package may declare inert UVM 1.2 snapshot item and monitor
classes for each observation, but it must not sample a DUT interface, publish
transactions, infer events, build an agent, generate a scoreboard, generate
coverage, or emit reusable VIP behavior.

No SV/UVM code generation ships in `.4`. Frontier `.7` selected the public
surface for the first implementation:
`--emit-verification-output uvm-passive-monitor --verification-outdir DIR
source.isf`, writing `DIR/uvm/<actor>_observation_uvm_pkg.sv` and
`DIR/verification-output-manifest.json`. Implementation remains deferred to
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8`.
