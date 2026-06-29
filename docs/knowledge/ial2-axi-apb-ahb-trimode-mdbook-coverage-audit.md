---
id: ial2-axi-apb-ahb-trimode-mdbook-coverage-audit
title: IAL2 AXI/APB/AHB tri-mode mdBook coverage selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.689?"
  - "where is the IAL2 AXI APB AHB tri-mode mdBook plan recorded?"
  - "does AHB currently have IAL2 .ahb support?"
  - "which mdBook chapters should document IAL2 protocol intent?"
date: 2026-06-29
status: current
tags: [ial2, axi, apb, ahb, mdbook, documentation, profile-alias, task-tree]
evidence: docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/SUMMARY.md; docs/book/src/14-feature-backlog.md; docs/book/src/15a-ial2-new-protocol-support.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; fsm/amba_requester.fsm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.689|16-ial2-protocol-platform-intent|16a-ial2-axi|16b-ial2-apb|16c-ial2-ahb|no `ppif/\*ahb\*`|unsupported_ial2_alias_suffix|protocol\.amba_requester|\.690|\.691|\.692|\.693' docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md bin/fsmgen perl/FSM/Support/RegressionCorpus.pm fsm/amba_requester.fsm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.689` selects a documentation-only
follow-on plan for IAL2 AXI, APB, and AHB mdBook coverage across three modes:
user-friendly guided, more-control, and raw/full-control.

The selected mdBook targets are
`docs/book/src/16-ial2-protocol-platform-intent.md`,
`docs/book/src/16a-ial2-axi.md`, `docs/book/src/16b-ial2-apb.md`, and
`docs/book/src/16c-ial2-ahb.md`. Follow-on leaves `.690`, `.691`, `.692`, and
`.693` own the scaffold, AXI, APB, and AHB documentation slices.

AXI and APB have shipped IAL2 `.ppif` examples, with selected `.axi` and
`.apb` profile aliases. AHB currently has only the direct
`fsm/amba_requester.fsm` support-accounted protocol seed; no AHB IAL2
`.ppif` or `.ahb` behavior is shipped, and `.ahb` remains a known unsupported
future alias suffix.
