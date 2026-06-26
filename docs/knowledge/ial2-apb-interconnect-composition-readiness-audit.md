---
id: ial2-apb-interconnect-composition-readiness-audit
title: APB interconnect/composition is ready for contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.564 select?"
  - "is APB interconnect composition ready after APB completer?"
  - "what comes after the APB composition readiness audit?"
  - "is APB interconnect implementation ready now?"
  - "does APB composition need a prerequisite before contract selection?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, interconnect, composition, readiness, task-tree]
evidence: docs/IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT.md; docs/IAL2_POST_APB_COMPLETER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; ppif/apb_completer.ppif; ppif/apb_requester_transfer.ppif; ppif/apb_requester_transfer.apb; fsm/apb_completer.fsm; fsm/apb_tb.fsm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.564` selects `.565`, APB
interconnect/composition public contract selection.

The readiness audit finds contract selection is justified because generated
APB `.ppif` requester and completer endpoint paths now exist, and the
strict-supported lower-layer `fsm/apb_tb.fsm` target already wires
`apb_requester` to `apb_completer` through the APB bus.

`.564` does not select direct interconnect implementation. `.565` must first
choose the public source vocabulary, generated review artifacts, report and
support-accounting identities, diagnostics, validation plan, and rollback
boundary. APB completer `.apb` alias exposure, multi-register decode,
sidebands/strobes, alternate widths, back-to-back policy, direct backend,
verification-output generation, backend-language variants, AXI, and VHDL
remain deferred.
