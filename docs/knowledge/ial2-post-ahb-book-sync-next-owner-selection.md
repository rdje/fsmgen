---
id: ial2-post-ahb-book-sync-next-owner-selection
title: Source-facing FSMGEN HIR selection follows the Chapter 16c AHB book sync
answers:
  - "what follows the Chapter 16c AHB busy-count residue repair?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.841 select?"
  - "why is the source-facing FSMGEN HIR boundary next?"
  - "does HIR selection activate the host-language builder?"
  - "does HIR selection activate HIAL VIAL scale or MCP write?"
date: 2026-07-30
status: current
tags: [ial2, selector, hir, architecture, ir-policy, frontend, builder]
evidence: docs/IAL2_POST_AHB_BOOK_SYNC_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; docs/IR_POLICY.md; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.841|FSMGEN-HIR-ROADMAP-FRONTIER\.2|source-facing FSMGEN HIR|Selected Leaf Contract' docs/IAL2_POST_AHB_BOOK_SYNC_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md docs/TASK_TREE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

Parent selector `.841` selects proposed no-behavior
`FSMGEN-HIR-ROADMAP-FRONTIER.2` after the Chapter 16c AHB BUSY-count truth sync.

The selected leaf is one architecture boundary decision under
`docs/IR_POLICY.md`: it must choose whether the source-facing HIR extends an
existing `IntentHIR`-adjacent layer, creates a new named surface, or keeps a
textual IAL handoff for one bounded prototype. It also selects one first
frontend or builder and one golden fixture, without implementation.

This HIR decision precedes the proposed host-language builder because that
builder's own contract requires the HIR boundary first. HIAL/VIAL, end-to-end
scale, and beyond-read-only MCP remain broader independent proposed owners.
Every director-gated lane remains inactive. The HIR child remains proposed
until a separate clean activation commit.
