---
id: ial2-apb-profile-alias-behavior
title: .apb is the bounded APB requester, completer, and fixed-composition IAL2 profile-alias suffix
answers:
  - "how does the .apb IAL2 profile alias behave?"
  - "can FSMGen accept .apb files now?"
  - "does FSMGen accept .apb now?"
  - "does APB PPIF accept .apb?"
  - "does .apb expose APB completer yet?"
  - "does .apb expose APB composition yet?"
  - "what support accounting entry covers the .apb alias?"
  - "what profile does .apb require?"
  - "does .apb lower directly to .fsm?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.569 implement?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_requester_transfer.apb; ppif/apb_completer.apb; ppif/apb_composition.apb; ppif/apb_requester_transfer.ppif; ppif/apb_completer.ppif; ppif/apb_composition.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/13-intent-scheduling.md
reverify: prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`.apb` is the bounded APB IAL2 profile-alias suffix. It accepts the public
samples `ppif/apb_requester_transfer.apb`, `ppif/apb_completer.apb`, and
`ppif/apb_composition.apb`, each requiring explicit `(profile apb)`.

The alias supports exactly one requester-transfer object, exactly one completer
object, or the explicit fixed one-requester/one-completer APB composition
shape. Mixed requester/completer files without `(apb-composition ...)` still
fail closed.

The requester alias lowers through generated `apb_requester.isf` before
`apb_requester.fsm`. The completer alias lowers through generated
`apb_completer.isf` before `apb_completer.fsm`. The fixed composition alias
lowers through generated requester/completer `.isf` files, generated
`apb_requester.fsm`, `apb_completer.fsm`, and `apb_tb.fsm`, with semantic root
kind `top`. Direct IAL2-to-IAL0 lowering remains forbidden.

Support accounting records:

```text
intent.apb_profile_alias_requester_transfer
intent.apb_profile_alias_completer
intent.apb_profile_alias_composition
```

All three use `source_kind` `ial2_profile_alias`.

`.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain
unsupported aliases. APB requester busy/status, multi-register decode,
sidebands/strobes, alternate widths, multi-peripheral decode, back-to-back
policy, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain deferred.
