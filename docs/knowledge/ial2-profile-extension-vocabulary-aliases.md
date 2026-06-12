---
id: ial2-profile-extension-vocabulary-aliases
title: IAL2 profile extensions are vocabulary aliases
answers:
  - "can IAL2 use protocol-specific extensions like .axi?"
  - "are .axi .chi .ace .ahb .apb profile extensions allowed?"
  - "are protocol-specific IAL2 extensions separate layers?"
  - "can .axi lower directly to .fsm?"
  - "how do protocol profile extensions relate to .pif .ppi .ppif?"
date: 2026-06-12
status: current
tags: [ial2, protocol-intent, profile-extension, vocabulary, lowering]
evidence: docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md; docs/book/src/14-feature-backlog.md
reverify: rg -n "profile extensions|vocabulary/profile aliases|IAL2 -> IAL1|Direct IAL2-to-IAL0" docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md
---

Future IAL2 may support both generic protocol/platform container extensions
such as `.pif`, `.ppi`, or `.ppif` and protocol-specific profile extensions
such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, or `.i2s`.

Profile extensions are vocabulary/profile aliases over the same IAL2 model,
not separate semantic layers. They must preserve the mandatory
`IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL` lowering chain and may not lower
directly to `.fsm`.
