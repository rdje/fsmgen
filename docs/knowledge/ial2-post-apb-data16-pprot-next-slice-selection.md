---
id: ial2-post-apb-data16-pprot-next-slice-selection
title: APB back-to-back readiness follows data16 PPROT policies
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.604?"
  - "what comes after APB data16 PPROT policies?"
  - "which task owns APB back-to-back readiness?"
  - "why choose APB back-to-back before additional PPROT policies?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, data16, back-to-back, selector, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_CONTRACT_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.604|IAL2-FEATURE-COMPLETENESS-FRONTIER\.605|APB back-to-back transfer policy readiness|apb_back_to_back_policy_deferred' docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.604` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.605`, an APB back-to-back transfer policy
readiness audit, after the shipped sideband data16 `PPROT` policy behavior.

The selector is documentation/task-tree only. It does not change APB source
acceptance, parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, direct backend,
verification-output generation, backend-language variants, AXI/AHB behavior, or
VHDL behavior.

Back-to-back is next because the selected data16 protection reports now keep
the future APB residue explicit through additional protection policies,
remaining widths, and `apb_back_to_back_policy_deferred`. Additional policies
and widths extend behavior families that already have shipped bounded
contracts. Back-to-back is the remaining timing/protocol residue that spans
requester transfer admission, completer setup admission, and fixed or
multi-peripheral composition propagation.

`.605` must audit source vocabulary candidates, public-surface boundaries,
requester queued admission, completer setup admission, composition propagation,
report/support-accounting movement, diagnostics, validation, rollback, and
direct-backend/VHDL deferral before any behavior change.
