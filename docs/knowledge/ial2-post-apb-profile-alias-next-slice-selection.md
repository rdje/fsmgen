---
id: ial2-post-apb-profile-alias-next-slice-selection
title: Post-APB profile-alias selection chooses a current public-surface sync
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.555 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.555?"
  - "what comes after the APB .apb profile alias?"
  - "which IAL2 slice follows APB .apb behavior?"
  - "why is the next IAL2 slice a public-surface sync?"
date: 2026-06-26
status: current
tags: [ial2, apb, profile-alias, public-surface, task-tree]
evidence: docs/IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/knowledge/ial2-apb-profile-alias-behavior.md; docs/knowledge/ial2-axi-profile-alias-behavior.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.555|IAL2-FEATURE-COMPLETENESS-FRONTIER\.556|public-surface sync|ppif/apb_requester_transfer\.apb|ppif/axi_aw_valid_ready\.axi|\.chi.*\.ace.*\.ahb.*\.atb.*\.smbus.*\.i2s.*\.pif.*\.ppi' docs/IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-post-apb-profile-alias-next-slice-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.555` selects `.556`, a no-behavior
public-surface sync after `.554` shipped the bounded APB `.apb` profile alias.

The selected sync must make current `.axi` behavior/fact wording stop listing
`.apb` as a currently unsupported alias. After `.554`, FSMGen accepts the
selected `.axi` sample at `ppif/axi_aw_valid_ready.axi` and the selected
`.apb` sample at `ppif/apb_requester_transfer.apb`; `.chi`, `.ace`, `.ahb`,
`.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain unsupported.

No parser, generator, sample, support-accounting, test, JSON, HDL,
direct-backend, verification-output, backend-language, or VHDL behavior is
selected by `.555`.
