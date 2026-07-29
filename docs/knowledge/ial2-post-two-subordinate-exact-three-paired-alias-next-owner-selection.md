---
id: ial2-post-two-subordinate-exact-three-paired-alias-next-owner-selection
title: Exact-four requester BUSY counter-width readiness follows the completed exact-three paired AHB family
answers:
  - "what follows the two-subordinate exact-three paired AHB alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.822 select?"
  - "is busy-beats 4 the next bounded AHB requester candidate?"
  - "why does exact-four AHB BUSY need a readiness audit?"
  - "what is the current exact-four AHB BUSY rejection?"
  - "does the post-exact-three paired alias selector activate HIAL and VIAL?"
  - "is Verilator treated as a full event-driven SystemVerilog UVM simulator?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, counter-width, selector, hial, vial, verilator]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester_busy_insert_three.ppif; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.822|EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT|literal integer in 2\.\.3|width 2|2,313|event-capable compiled simulation' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After the exact-one/two/three requester and one-/two-window paired AHB
generic/profile cadence completed at 326/367/50 split 25/25, parent selector
`.822` chose proposed exact-four requester BUSY counter-width readiness.

A same-volume 2,313-byte exact-four transform fails closed before generation
with the selected `busy_beats` literal-`2..3` diagnostic. The generator also
hardcodes width-two `ahb_busy_remaining_q`; four is the first adjacent count
that cannot be represented. The audit must decide whether bounded width three
is sufficient or reusable minimum-width derivation is required, then prove
internal `4 -> 3 -> 2 -> 1 -> 0`, four qualified BUSY events, stalls, resumed
`SEQ`, artifacts, semantic/read-only-MCP parity, and preservation before a
separate public contract may be selected.

New BUSY policies/points/status/bursts/signals, generic priority, end-to-end
scale, decision `0020`, and HIAL/VIAL activation remain separate. HIAL/VIAL
retains portable-fast event-capable compiled Verilator versus a separately
qualified full-language/SystemVerilog-UVM simulator, with independent VHDL and
mixed-language profiles.
