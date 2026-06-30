---
id: ial2-ahb-burst-seq-contract-selection
title: AHB burst SEQ contract selects byte-lane in-word SEQ source
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.751 select?"
  - "which source will first support AHB subordinate SEQ?"
  - "what is the first bounded AHB SEQ policy?"
  - "does AHB SEQ contract selection change behavior?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.752 own?"
date: 2026-06-30
status: current
tags: [ial2, ahb, burst, seq, contract-selection, byte-lane]
evidence: docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md; docs/IAL2_AHB_BURST_SEQ_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1482-ial2-ahb-subordinate-byte-lane.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.751|IAL2-FEATURE-COMPLETENESS-FRONTIER\.752|ahb_lite_subordinate_byte_lane_seq|seq-policy in-word-progressive|in-word `SEQ`|intent\.ppif_ahb_lite_subordinate_byte_lane_seq' docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.751` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.752`, direct implementation of a new
generic `.ppif` byte-lane subordinate source:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

The selected source adds `(seq-policy in-word-progressive)` and support
identity `intent.ppif_ahb_lite_subordinate_byte_lane_seq`. Existing word-only,
byte-lane, `.ahb` alias, requester, and aggregate behavior stays unchanged.

The first bounded `SEQ` policy supports only byte/halfword in-word
continuations with prior successful active-transfer history, expected address
progression, and stable `HWRITE`/`HSIZE`. HBURST length/wrap validation,
BUSY-in-burst behavior, multi-word/register-bank bursts, aliases, aggregate
propagation, and broader AHB behavior remain deferred.
