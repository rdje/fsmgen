---
id: ial2-post-two-subordinate-exact-two-paired-busy-alias-next-owner-selection
title: Post-two-subordinate exact-two paired-BUSY alias selection chooses exact-three requester readiness
answers:
  - "what follows the two-subordinate exact-two paired AHB .ahb alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.812 select?"
  - "is literal busy-beats 3 the next AHB requester candidate?"
  - "does the exact-two requester counter have room for literal three?"
  - "why is exact-three requester BUSY audited before implementation?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, counter, readiness, semantics, mcp]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT|width-two|3 --continue|three qualified BUSY|busy_beats must be the literal integer 2' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.812` selects proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`. The shipped
two-bit remaining counter can represent three, and its qualified non-final /
final rule split statically maps three to `3 -> 2 -> 1 -> 0` while reusing the
same pending-transfer `SEQ` handoff.

That static fit is not runtime proof. The proposed audit must use a repo-local
disposable candidate and assertion-enabled continuous, ready-low, and
grant-low scenarios to prove exactly three qualified BUSY events, no count
consumption while stalled, stable pending ownership, one resumed `SEQ`, four
data beats, and zero final count before any public contract or implementation
is selected. Policy/runtime/random or multiple-point insertion, counts above
three, distinct local bus-BUSY status, broader bursts/signals, selector repairs,
and decision 0020 remain separate/inactive.
