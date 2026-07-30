---
id: ial2-post-import-map-next-owner-selection
title: Chapter 16c AHB busy-count residue synchronization follows the import-map refresh
answers:
  - "what follows the identifier-era bin/fsmgen import-map refresh?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.840 select?"
  - "where does the mdBook still say AHB counts beyond four are unshipped?"
  - "why is the Chapter 16c AHB busy-count residue stale?"
date: 2026-07-30
status: current
tags: [ial2, ahb, selector, mdbook, documentation, busy-count]
evidence: docs/IAL2_POST_IMPORT_MAP_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/16c-ial2-ahb.md; docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
reverify: rg -n 'canonical decimal literal counts `2\.\.16`|Literal counts `2\.\.16`|Canonical decimal literal values `2\.\.16`|Implementation `\.3` now ships canonical decimal literal|Counts beyond four' docs/book/src/16c-ial2-ahb.md && rg -n 'canonical decimal literal integer in 2\.\.16|values 2\.\.16' perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
---

Parent selector `.840` selects proposed no-behavior
`MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1` after the identifier-era import map is
synchronized.

Chapter 16c repeatedly records the shipped canonical decimal `busy-beats`
range `2..16`, including the deliberate absence of a public fixture per count,
but one later future/residue bullet still says counts beyond four are outside
the shipped surface. The lowerer and canonical behavior record independently
confirm `2..16`; the bullet is stale.

The selected leaf may synchronize only that residue wording after separate
clean activation. Exact-one-through-four fixtures, accounting, code, generated
artifacts, runtime behavior, values above 16, and every broader owner remain
unchanged.

Clean selector commit `6e1c73d8c` activates only
`MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1` through continuity changes. The stale
Chapter 16c bullet and every product behavior remain unchanged during
activation.
