---
id: ial2-post-apb-profile-alias-public-surface-sync
title: Current profile-alias surfaces list .axi, .apb, and .ahb as shipped aliases
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.556 change?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.556?"
  - "which IAL2 profile-alias suffixes are currently supported?"
  - "which IAL2 aliases remain unsupported after .apb shipped?"
  - "does the .axi behavior fact still say .apb is unsupported?"
date: 2026-06-26
status: current
tags: [ial2, profile-alias, axi, apb, public-surface, task-tree]
evidence: docs/IAL2_POST_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/knowledge/ial2-axi-profile-alias-behavior.md; docs/knowledge/ial2-apb-profile-alias-behavior.md; docs/knowledge/ial2-ahb-profile-alias-behavior.md; ppif/axi_aw_valid_ready.axi; ppif/apb_requester_transfer.apb; ppif/ahb_requester.ahb; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: perl -0ne 'if (/\.apb[^\n]*(?:remain unsupported|known unsupported)|(?:remain unsupported|known unsupported)[^\n]*\.apb|\.ahb[^\n]*(?:remain unsupported|known unsupported)|(?:remain unsupported|known unsupported)[^\n]*\.ahb/) { print "$ARGV\n"; exit 1 }' docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md docs/knowledge/ial2-axi-profile-alias-behavior.md docs/knowledge/ial2-apb-profile-alias-behavior.md docs/knowledge/ial2-ahb-profile-alias-behavior.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.556` is a no-behavior public-surface sync.
It updates current `.axi` behavior and fact wording so `.apb` is no longer
listed as currently unsupported after `.554`.

After `.700`, the current shipped IAL2 profile-alias suffixes are `.axi`,
`.apb`, and `.ahb`. `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and
`.ppi` remain unsupported. Historical pre-`.554` notes may still say `.apb`
was unsupported at their closeout date, and historical pre-`.700` notes may
still say `.ahb` was unsupported at their closeout date.
