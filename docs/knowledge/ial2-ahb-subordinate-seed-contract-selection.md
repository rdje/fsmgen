---
id: ial2-ahb-subordinate-seed-contract-selection
title: AHB subordinate seed contract selects ahb_lite_subordinate direct fixture
answers:
  - "what AHB subordinate seed contract was selected?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.708 select?"
  - "what comes after AHB subordinate source fact extraction?"
  - "what comes after .708?"
  - "what is the first AHB subordinate direct seed target?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, ahb-lite, seed-selection, task-tree]
evidence: docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.708|IAL2-FEATURE-COMPLETENESS-FRONTIER\.709|ahb_lite_subordinate|protocol\.ahb_lite_subordinate|HREADYOUT|two-cycle ERROR|wait_cycles' docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.708` selected the first lower-layer AHB
subordinate seed contract.

The selected direct seed target is:

- `fsm/ahb_lite_subordinate.fsm`;
- module name `ahb_lite_subordinate`;
- support-accounting identity `protocol.ahb_lite_subordinate`;
- bounded AHB-Lite/common-AHB 32-bit single-register subordinate behavior.

The selected first-seed port set is `HSEL`, `HADDR`, `HTRANS`, `HWRITE`,
`HSIZE`, `HREADY`, `HWDATA`, fixture-local `wait_cycles`, `HREADYOUT`,
one-bit `HRESP`, and `HRDATA`.

The selected behavior accepts `NONSEQ` word transfers to address
`32'h00000000`, ignores `IDLE` and `BUSY` with zero-wait OKAY, reports
unsupported `SEQ`, unsupported sizes, and unmapped addresses with the
source-backed two-cycle ERROR response, and drives reset/idle defaults
`HREADYOUT=1`, `HRESP=0`, and `HRDATA=0`.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.709`, direct
implementation of `fsm/ahb_lite_subordinate.fsm`. IAL2 AHB
completer/subordinate `.ppif` and `.ahb` source behavior remains deferred
until after that lower-layer seed ships.
