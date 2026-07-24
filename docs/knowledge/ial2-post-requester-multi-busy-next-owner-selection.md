---
id: ial2-post-requester-multi-busy-next-owner-selection
title: Post-requester-multiple-BUSY selection chooses exact-two paired composition readiness
answers:
  - "what follows the exact-two AHB requester .ahb alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.809 select?"
  - "will FSMGen compose exact-two requester BUSY with subordinate BUSY parking?"
  - "why is exact-two paired AHB composition audited before implementation?"
  - "will future exact-two composition support semantic introspection through MCP?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, readiness, semantics, mcp]
evidence: docs/IAL2_POST_REQUESTER_MULTI_BUSY_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_requester_busy_insert_two.ppif; ppif/ahb_requester_busy_insert_two.ahb; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; docs/book/src/16c-ial2-ahb.md; MEMORY.md
reverify: rg -n 'IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT|requester_busy_beats|parks_on|fsmgen_semantic_introspect' docs/IAL2_POST_REQUESTER_MULTI_BUSY_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.809` selects proposed
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`. It will first
audit one exact-two requester plus one HBURST-aware byte-lane BUSY-parking
subordinate; it does not yet select a public source or behavior.

An in-memory candidate already preserves three children, `ahb_tb`, exact-two
requester IAL1/IAL0, numeric `busy_insertion.beats=2`, and subordinate plus
propagated `parks_on=[busy]` through existing generators. Generated-HDL runtime
must still prove two qualified BUSY events preserve requester/subordinate/
interconnect ownership and resume one pending `SEQ` exactly once.

Any later support-accounted source must expose strict check, schedule,
normalized semantic JSON, and the existing read-only
`fsmgen_semantic_introspect` MCP tool without a feature-specific API or raw
private internals. Counts beyond two, policy/runtime insertion, broader
composition, selector repairs, and decision 0020 remain separate/inactive.
