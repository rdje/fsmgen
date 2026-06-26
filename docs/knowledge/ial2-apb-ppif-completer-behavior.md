---
id: ial2-apb-ppif-completer-behavior
title: APB completer is shipped as a PPIF source shape
answers:
  - "does FSMGen support an APB completer .ppif source?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.562 implement?"
  - "what APB completer PPIF behavior is shipped?"
  - "what report schema does APB completer use?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, completer, behavior, task-tree]
evidence: docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_completer.ppif; ppif/apb_completer.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/Support/RegressionCorpus.pm; t/1471-ial2-apb-completer.t; t/1470-ial2-apb-profile-alias.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/apb_completer.ppif && ./bin/fsmgen --strict --check --json ppif/apb_completer.ppif && ./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer.ppif && prove -Iperl t/1471-ial2-apb-completer.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.562` ships the first APB `.ppif`
completer behavior. The public sample is `ppif/apb_completer.ppif`, using
`(profile apb)` and one `(apb-completer apb_completer ...)` object.

The APB completer `.ppif` source generates review artifacts
`apb_completer.isf` and `apb_completer.fsm` through IAL1 before IAL0, then
reaches the existing HDL path with module `apb_completer`.

The IAL2 report schema is
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and support accounting matches
`intent.ppif_apb_completer`.

The shipped subset models setup detection `PSEL && !PENABLE`, runtime
`wait_cycles`, one address-0 32-bit register, mapped read/write behavior, and
`PSLVERR` for unmapped addresses. The generated IAL1 uses an internal
`apb_complete_done_q` terminal bit; it does not add a public APB done port.

The later `IAL2-FEATURE-COMPLETENESS-FRONTIER.569` slice also exposes this
same bounded completer through `ppif/apb_completer.apb`, support-accounted as
`intent.apb_profile_alias_completer`.

APB multi-peripheral interconnect/decode, sidebands, alternate widths,
multi-register decode, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, and VHDL remain
future owners.
