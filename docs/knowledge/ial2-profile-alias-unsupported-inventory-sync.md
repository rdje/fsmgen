---
id: ial2-profile-alias-unsupported-inventory-sync
title: IAL2 unsupported alias inventory now includes SMBus and I2S candidates
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.538 change?"
  - "does the capability manifest list .smbus and .i2s as unsupported aliases?"
  - "which aliases were unsupported before the first .axi implementation?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.539?"
  - "which suffixes are unsupported first-slice IAL2 aliases?"
date: 2026-06-26
status: historical
tags: [ial2, ppif, profile-alias, capability-manifest, unsupported-inventory]
evidence: docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md; docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.538|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.539|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.540|unsupported_first_slice_aliases|\\.smbus|\\.i2s|\\.axi|shipped_suffixes' docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-profile-alias-unsupported-inventory-sync.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.538` synchronizes the public capability
manifest unsupported-alias inventory as it stood before the first alias
implementation. At `.538`, `.pif`, `.ppi`, `.axi`, `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, and `.i2s` were all unsupported in the first IAL2
public file-surface slice.

This card is historical after `.540` and `.554`: FSMGen now accepts the
selected `.axi` AXI AW Valid-Ready profile-alias sample and the selected `.apb`
APB requester-transfer profile-alias sample. `.smbus`, `.i2s`, `.chi`, `.ace`,
`.ahb`, `.atb`, `.pif`, and `.ppi` remain unsupported.
