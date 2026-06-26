---
id: ial2-post-apb-alias-widening-next-slice-selection
title: APB requester busy/status contract follows shipped APB aliases
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.570 select?"
  - "what comes after APB .apb completer and composition aliases shipped?"
  - "which APB residue is next after .569?"
  - "is APB requester busy/status exposure next after alias widening?"
  - "why not APB multi-peripheral decode after .569?"
date: 2026-06-27
status: current
tags: [ial2, apb, profile-alias, requester, status, task-tree]
evidence: docs/IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_requester_transfer.apb; ppif/apb_completer.apb; ppif/apb_composition.apb; fsm/apb_requester.fsm; fsm/apb_tb.fsm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.apb && rg -n 'apb_requester_busy_status_deferred|busy' docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md fsm/apb_requester.fsm fsm/apb_tb.fsm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.570` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.571`, APB requester busy/status public
contract selection after requester-transfer, completer, fixed composition, and
bounded `.apb` alias coverage all shipped.

The next owner is a contract-selection leaf, not immediate behavior. `.571`
must decide whether the first generated IAL2 widening exposes only `busy` or
also a named status field, how requester and fixed composition source syntax
bind that status, how generated `.isf`/`.fsm` review artifacts and composition
top ports change, how reports/residue/support-accounting/docs update, and what
diagnostics/validation/rollback apply.

The current APB requester and composition IAL2 reports expose `done`,
`last_error`, and `last_read_data` while carrying
`apb_requester_busy_status_deferred`. Lower-layer hand-authored fixtures
`fsm/apb_requester.fsm` and `fsm/apb_tb.fsm` already expose `busy`, so the
next selector has concrete fixture evidence without changing behavior in
`.570`.

Multi-peripheral decode, multi-register decode, sidebands/strobes, alternate
widths, back-to-back policy, direct backend, verification-output,
backend-language variants, AXI, and VHDL remain future owners.
