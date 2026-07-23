---
id: ial2-ahb-two-subordinate-paired-busy-contract-selection
title: Generic two-subordinate paired AHB BUSY composition contract is frozen
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.800 select?"
  - "what is the public path for the two-subordinate paired AHB BUSY source?"
  - "what runtime proof must the two-subordinate paired AHB BUSY composition pass?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.801 own?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, contract, runtime]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md; docs/IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; t/1513-ial2-ahb-paired-busy-composition.t; t/data/ahb_paired_busy_composition_tb.svt; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.800|IAL2-FEATURE-COMPLETENESS-FRONTIER\.801|ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park|313|354|44332211|88776655|HADDR_CONTROL' docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`.800` selects `.801`, direct implementation of one additive generic `.ppif`
source that combines the shipped BUSY requester with both shipped status/control
BUSY-parking subordinates. The source has module `ahb_tb`, four children, 29
signals, exact four IAL1/five IAL0 artifacts, semantic root `top`, and one new
support entry taking accounting to 313 protocol / 354 supported-smoke+strict.

Runtime proof issues status-base-0 then control-base-4 byte `INCR4` commands.
Each must observe `NONSEQ, SEQ, BUSY, SEQ, SEQ`, selected-child state/storage
held across BUSY, unselected-child non-interference, and correct local address.
Final storage is `44332211` for status and `88776655` for control. The matching
`.ahb` alias remains a later selector; decision 0020 stays inactive.
