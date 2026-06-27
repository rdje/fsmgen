---
id: ial2-apb-multi-register-decode-behavior
title: APB multi-register completer decode ships for generated completer and composition sources
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.581?"
  - "does FSMGen support APB multi-register completer decode?"
  - "does .581 ship APB multi-register decode?"
  - "which APB multi-register samples are shipped?"
  - "how are APB multi-register reports shaped?"
  - "what APB multi-register residue remains?"
  - "does APB multi-register support change existing one-register samples?"
date: 2026-06-27
status: current
tags: [ial2, apb, completer, composition, multi-register, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md; ppif/apb_completer_multi_register.ppif; ppif/apb_completer_multi_register.apb; ppif/apb_composition_multi_register.ppif; ppif/apb_composition_multi_register.apb; ppif/apb_completer.ppif; ppif/apb_composition_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/13-intent-scheduling.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_completer_multi_register.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_completer_multi_register.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_register.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_register.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_register.apb && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.581` ships bounded APB multi-register
completer decode for generated APB completer and status-capable fixed
composition IAL2 surfaces.

The shipped public samples are `ppif/apb_completer_multi_register.ppif`,
`ppif/apb_completer_multi_register.apb`,
`ppif/apb_composition_multi_register.ppif`, and
`ppif/apb_composition_multi_register.apb`.

The selected source syntax is repeated `(register ...)` clauses under the
existing APB completer `(storage ...)` block. Registers are kept in source
order. Register names, data signal names, and addresses must be unique;
addresses must be decimal, width 32, and 4-byte aligned; data width remains
32; reset remains 0.

Existing one-register APB reports remain unchanged with
`bindings.storage.register` and `transfer.register`. Multi-register reports
use `bindings.storage.registers[]` and `transfer.registers[]` lists in source
order.

Multi-register completer and composition reports remove
`apb_multi_register_decode_deferred`. Multi-peripheral APB topology,
sidebands/strobes, alternate widths, byte lanes, side effects, back-to-back
policy, direct backend, verification-output, backend-language variants, AXI,
and VHDL remain deferred.
