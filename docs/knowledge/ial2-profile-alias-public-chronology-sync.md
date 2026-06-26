---
id: ial2-profile-alias-public-chronology-sync
title: Profile-alias public wording now marks pre-.540 history explicitly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.543 change?"
  - "are the old .axi unsupported book sections current?"
  - "where is the profile-alias public chronology clarified?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.544?"
date: 2026-06-26
status: current
tags: [ial2, profile-alias, mdbook, chronology, docs]
evidence: docs/IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.543|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.544|Historical IAL2 profile-alias|explicitly historical pre-|bounded .* AW Valid-Ready|not the definition or full scope of IAL2' docs/IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.543` makes the public profile-alias
chronology explicit after `.axi` shipped. The old `.537`/`.538` wording is
historical pre-`.540` state; current `.axi` behavior is the bounded `.540`
profile-alias sample, and the other alias candidates remain unsupported.

`.543` selects `.544`, next exact IAL2 owner selection after the public
chronology sync.
