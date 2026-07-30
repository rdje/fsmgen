---
id: ial2-post-import-map-next-owner-selection
title: Chapter 16c AHB busy-count residue synchronization follows the import-map refresh
answers:
  - "what follows the identifier-era bin/fsmgen import-map refresh?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.840 select?"
  - "where was the stale mdBook claim that AHB counts beyond four were unshipped corrected?"
  - "why was the Chapter 16c AHB busy-count residue stale?"
date: 2026-07-30
status: current
tags: [ial2, ahb, selector, mdbook, documentation, busy-count]
evidence: docs/IAL2_POST_IMPORT_MAP_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/16c-ial2-ahb.md; docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
reverify: rg -n 'canonical decimal literal counts `2\.\.16`|Literal counts `2\.\.16`|Canonical decimal literal values `2\.\.16`|Implementation `\.3` now ships canonical decimal literal|counts `5\.\.16` reuse|Counts above 16' docs/book/src/16c-ial2-ahb.md && rg -n 'canonical decimal literal integer in 2\.\.16|values 2\.\.16' perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
---

Parent selector `.840` selected no-behavior
`MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1` after the identifier-era import map is
synchronized.

At selection time, Chapter 16c repeatedly recorded the shipped canonical
decimal `busy-beats` range `2..16`, including the deliberate absence of a
public fixture per count, but one later future/residue bullet said counts
beyond four were outside the shipped surface. The lowerer and canonical
behavior record independently confirmed `2..16`; the bullet was stale.

The selected leaf was authorized to synchronize only that residue wording
after separate clean activation. Exact-one-through-four fixtures, accounting,
code, generated artifacts, runtime behavior, values above 16, and every
broader owner remained fixed.

Clean selector commit `6e1c73d8c` activates only
`MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1` through continuity changes. The stale
Chapter 16c bullet and every product behavior remain unchanged during
activation.

After clean activation commit `76a7424fa`, the child corrects only the stale
bullet. Chapter 16c now distinguishes exact-one-through-four catalog fixtures
from canonical literal counts `5..16` that reuse the shipped lowerer without
per-count fixtures. Counts above 16 and symbolic/policy/runtime/random or
multiple-point insertion remain deferred; product behavior and accounting do
not change.
