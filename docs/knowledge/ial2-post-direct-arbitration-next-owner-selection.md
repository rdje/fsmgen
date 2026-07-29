---
id: ial2-post-direct-arbitration-next-owner-selection
title: Assertion-clean AHB lowering unlocks exact-three paired BUSY readiness
answers:
  - "what comes after direct AHB subordinate arbitration becomes assertion-clean?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.816 select?"
  - "is exact-three paired AHB BUSY composition ready to audit?"
  - "what runtime feasibility result supports exact-three paired AHB BUSY?"
  - "why are HIAL and VIAL not activated after direct AHB arbitration?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, readiness, selector]
evidence: docs/IAL2_POST_DIRECT_ARBITRATION_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_BEHAVIOR.md; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1528-ial2-ahb-requester-exact-three-busy-event.t
reverify: rg -n -- 'Status: `proposed`|qualified BUSY events|323 protocol|53,577,454|HIAL/VIAL' docs/IAL2_POST_DIRECT_ARBITRATION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.816` selects proposed
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1` after the
fabric, generated endpoint, and direct seed all became assertion-clean.

A repo-local disposable one-subordinate candidate reused the shipped
exact-three requester, byte-lane/HBURST-SEQ/BUSY-parking subordinate, and AHB
interconnect. It emitted three IAL1 plus four IAL0 artifacts, compiled with all
generated selector assertions enabled, and passed 5 presentations / 4 accepted
beats / 1 BUSY episode / 3 qualified BUSY events / 1 resumed SEQ / storage
`0x44332211`. Its exact 54-file / 53,577,454-byte workspace was removed without
residue.

This proves readiness for the audit, not shipped public behavior. The selected
leaf must freeze source/support/report/semantic-MCP/test identities and
projected 323/364/47 support accounting before a contract is chosen. Aliases,
the two-subordinate topology, counts above three, policy/status/bursts/signals,
HIAL/VIAL activation, and decision 0020 remain separate and inactive.

Clean selector commit `bc3d9eaf1` now activates only the selected `.1` audit
leaf. Activation changes continuity documentation and no public or generated
behavior.
