---
id: ial2-apb-back-to-back-readiness-audit
title: APB back-to-back readiness selects public timing-policy contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.605?"
  - "is APB back-to-back transfer policy ready to implement?"
  - "what comes after APB back-to-back readiness?"
  - "does APB currently support back-to-back transfer admission?"
  - "what must APB back-to-back contract selection decide?"
date: 2026-06-27
status: current
tags: [ial2, apb, back-to-back, timing, readiness, contract, task-tree]
evidence: docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.605|IAL2-FEATURE-COMPLETENESS-FRONTIER\.606|APB back-to-back transfer policy|apb_back_to_back_policy_deferred|single_outstanding_transfer|queued transfer admission' docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.605` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.606`, public APB back-to-back transfer
policy contract selection, without behavior changes.

Current APB requester, completer, fixed-composition, and multi-peripheral
composition reports still carry `apb_back_to_back_policy_deferred`. The
requester report says the shipped slice models one outstanding transfer, the
requester deasserts `PSEL/PENABLE` in its terminal done phase, and no public
queued-admission source vocabulary exists. The completer admits setup through
`PSEL && !PENABLE` and models one transfer at a time. Fixed and
multi-peripheral composition propagate selected endpoint behavior but do not
select adjacent-transfer timing policy.

Back-to-back is ready for contract selection, not implementation. `.606` must
settle public vocabulary, explicit versus implicit timing policy, requester
queued-admission semantics, completer setup admission, fixed and
multi-peripheral propagation, report/support-accounting movement, diagnostics,
validation, rollback, and direct-backend/VHDL deferral before behavior work.
