---
id: ial2-profile-alias-unsupported-inventory-sync
title: IAL2 unsupported alias inventory now includes SMBus and I2S candidates
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.538 change?"
  - "does the capability manifest list .smbus and .i2s as unsupported aliases?"
  - "does FSMGen now accept .axi or .smbus files?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.539?"
  - "which suffixes are unsupported first-slice IAL2 aliases?"
date: 2026-06-26
status: current
tags: [ial2, ppif, profile-alias, capability-manifest, unsupported-inventory]
evidence: docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md; docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.538|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.539|unsupported_first_slice_aliases|\\.smbus|\\.i2s|future IAL2 profile alias|shipped_suffixes' docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-profile-alias-unsupported-inventory-sync.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.538` synchronizes the public capability
manifest unsupported-alias inventory. It keeps `.pif`, `.ppi`, `.axi`, `.chi`,
`.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` unsupported in the first
IAL2 public file-surface slice.

FSMGen still does not accept `.axi`, `.smbus`, or other profile-alias files.
The shipped source suffixes remain `.fsm`, `.isf`, and `.ppif`. `.539` is the
next owner and should select the public contract for the first IAL2
profile-alias suffix before any implementation.
