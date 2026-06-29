---
id: ial2-ahb-subordinate-source-fact-inventory
title: First AHB subordinate source-backed fact inventory selects seed contract owner
answers:
  - "what AHB subordinate source facts are available?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.707 extract?"
  - "what comes after AHB source-reference import?"
  - "what comes after .707?"
  - "what is needed before an AHB subordinate seed is added?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, source-reference, seed-selection, task-tree]
evidence: docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf; docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.707|IAL2-FEATURE-COMPLETENESS-FRONTIER\.708|Subordinate Interface Facts|Response Timing Facts|First-Seed Implications|docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification\.pdf' docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.707` extracted the first source-backed
AHB/AHB-Lite subordinate fact inventory from the imported Arm AMBA AHB
Protocol Specification PDF.

The inventory covers:

- subordinate interface role and selected signal groups;
- `HSELx` and `HREADY` selection/completion gating;
- address/data phase separation and wait-state insertion through
  `HREADYOUT`;
- `IDLE`, `BUSY`, `NONSEQ`, and `SEQ` transfer-type implications;
- read/write data validity and active byte-lane boundaries;
- OKAY, pending, and two-cycle ERROR response timing;
- reset and signal-validity constraints.

The selected next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.708`, lower-layer AHB subordinate seed
contract selection. `.708` must choose a bounded AHB-Lite/common-AHB direct
`.fsm` seed contract before any seed file, IAL2 AHB completer/subordinate
source, parser/generator behavior, support-accounting, manifest, test,
generated-artifact, HDL/runtime, direct-backend, verification-output,
backend-language variant, AXI, APB, or VHDL behavior changes.
