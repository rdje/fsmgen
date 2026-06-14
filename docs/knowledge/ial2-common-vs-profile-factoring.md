---
id: ial2-common-vs-profile-factoring
title: IAL2 factoring should use a small common core plus proven profile vocabularies
answers:
  - "should IAL2 have common constructs shared by all protocols?"
  - "should IAL2 be only protocol-specific constructs?"
  - "how should IAL2 factor common vs protocol-specific constructs?"
  - "what is the current take on IAL2 common constructs?"
date: 2026-06-14
status: current
tags: [ial2, architecture, protocol-platform, factoring, profiles, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md
reverify: rg -n 'IAL2 factoring|common semantic core|protocol/platform vocabular|profile-local|reuse across multiple profiles|0014|0015|0018' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md docs/decisions/0018-ial-contracts-are-backend-language-neutral.md
---

The current IAL2 factoring stance is a conservative hybrid:

- keep a small common semantic core for concepts that are genuinely shared
  across protocols/platforms;
- keep profile/platform-specific vocabulary local until at least two profiles
  need the same construct with compatible semantics;
- promote a construct into common IAL2 only after reuse evidence exists and
  the abstraction does not erase protocol-specific rules that users need to
  reason about.

This avoids making IAL2 either all AXI-shaped vocabulary or an over-general
layer with leaky "common" constructs. `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`
applied this stance while selecting `.87`: AXI concrete-ID same-ID ordering
remains AXI profile vocabulary for now, and any future common construct should
be promoted only after another profile proves compatible need.
