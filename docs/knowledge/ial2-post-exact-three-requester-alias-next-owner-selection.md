---
id: ial2-post-exact-three-requester-alias-next-owner-selection
title: AHB interconnect selector arbitration is the next owner after the exact-three requester alias
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.813 select?"
  - "why is AHB interconnect arbitration next after the exact-three requester alias?"
  - "why is exact-three paired BUSY composition not next?"
date: 2026-07-29
status: current
tags: [ial2, ahb, interconnect, selector, arbitration, correctness, roadmap, task-tree]
evidence: docs/IAL2_POST_EXACT_THREE_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md; docs/knowledge/ial2-ahb-interconnect-default-decode-output-arbitration-gap.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
reverify: rg -n 'subordinate_idle_lines|subordinate_hit_blocks|--no-assert|IAL2-FEATURE-COMPLETENESS-FRONTIER\.813|IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm t/1513-ial2-ahb-paired-busy-composition.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t docs/IAL2_POST_EXACT_THREE_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.813` selects proposed
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1` after the
exact-three requester alias establishes the 322/363/46 checkpoint.
Clean selector commit `347a85f80` satisfies the activation boundary, so that
audit child is now active.

The shipped AHB interconnect emits unconditional subordinate select/address
defaults and conditional mapped-hit select/address writes in the same `idle`
state. A mapped transfer enables both selector families; assertion-enabled
evidence stops at `selector multi-value conflict: HADDR_REGS`. Aggregate
runtime tests t/1513, t/1515, t/1523, and t/1525 all retain `--no-assert`.

Exact-three paired composition is therefore deferred until the selected audit
maps the full overlap and selects the smallest repair owner. The separate
general ISF rule-versus-transaction priority gap remains proposed because the
current requester path does not depend on that disposable mechanism.
