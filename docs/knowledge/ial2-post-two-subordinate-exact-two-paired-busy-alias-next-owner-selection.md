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
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT|3 -> 2 -> 1 -> 0|three qualified BUSY|no lower-layer repair|busy_beats must be the literal integer 2' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.812` selects proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`. The shipped
two-bit remaining counter can represent three, and its qualified non-final /
final rule split statically maps three to `3 -> 2 -> 1 -> 0` while reusing the
same pending-transfer `SEQ` handoff.

The selected audit `.1` has now supplied the missing runtime proof: one guarded
assertion-enabled binary passes continuous, 32-ready-low, and 32-grant-low
scenarios with internal `3 -> 2 -> 1 -> 0`, stable pending ownership, one
resumed `SEQ`, four data beats, and zero final count. Strict/schedule/artifact/
normalized-semantic/read-only MCP evidence also passes, so no lower-layer
repair is required. Proposed `.2` owns public contract selection. Policy/
runtime/random or multiple-point insertion, counts above three, distinct local
bus-BUSY status, broader bursts/signals, selector repairs, and decision 0020
remain separate/inactive.
