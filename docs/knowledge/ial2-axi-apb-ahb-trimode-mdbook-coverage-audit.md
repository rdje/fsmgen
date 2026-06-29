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
evidence: docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/SUMMARY.md; docs/book/src/14-feature-backlog.md; docs/book/src/15a-ial2-new-protocol-support.md; docs/book/src/16c-ial2-ahb.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; fsm/amba_requester.fsm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.689|IAL2-FEATURE-COMPLETENESS-FRONTIER\.697|IAL2-FEATURE-COMPLETENESS-FRONTIER\.700|16-ial2-protocol-platform-intent|16a-ial2-axi|16b-ial2-apb|16c-ial2-ahb|ppif/ahb_requester\.ppif|ppif/ahb_requester\.ahb|intent\.ppif_ahb_requester|intent\.ahb_profile_alias_requester|protocol\.amba_requester' docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/16c-ial2-ahb.md perl/FSM/Support/RegressionCorpus.pm ppif/ahb_requester.ppif ppif/ahb_requester.ahb fsm/amba_requester.fsm
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
`.apb` profile aliases. After the original `.689` documentation plan, `.697`
shipped bounded AHB requester IAL2 coverage at `ppif/ahb_requester.ppif`
alongside the direct `fsm/amba_requester.fsm` protocol seed. `.700` later
shipped the bounded AHB `.ahb` profile alias at `ppif/ahb_requester.ahb`.
