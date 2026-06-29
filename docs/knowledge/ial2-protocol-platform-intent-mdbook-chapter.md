---
id: ial2-protocol-platform-intent-mdbook-chapter
title: IAL2 protocol/platform intent mdBook chapter scaffold
answers:
  - "where is the IAL2 protocol and platform intent mdBook chapter?"
  - "what are the IAL2 guided more-control and raw/full-control documentation modes?"
  - "does IAL2 bypass generated ISF and FSM review artifacts?"
  - "what is the current AHB boundary in the IAL2 mdBook chapter?"
date: 2026-06-29
status: current
tags: [ial2, mdbook, protocol-intent, ppif, axi, apb, ahb, documentation]
evidence: docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/SUMMARY.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md
reverify: rg -n 'IAL2 Protocol And Platform Intent|IAL2 source -> generated IAL1 \.isf -> generated IAL0 \.fsm -> HDL|Guided mode|More-control mode|Raw/full-control mode|ppif/ahb_requester\.ppif|fsm/amba_requester\.fsm|16-ial2-protocol-platform-intent' docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/SUMMARY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md
---

`docs/book/src/16-ial2-protocol-platform-intent.md` is the mdBook
user-facing scaffold for IAL2 protocol/platform intent. It is linked from
`docs/book/src/SUMMARY.md`.

The chapter defines the three documentation modes as guided mode,
more-control mode, and raw/full-control mode. All modes preserve the mandatory
lowering chain through generated IAL1 `.isf` and generated IAL0 `.fsm` review
artifacts before HDL.

The current protocol map records AXI and APB as shipped bounded IAL2 `.ppif`
surfaces with selected profile aliases. AHB now has bounded generic `.ppif`
requester coverage at `ppif/ahb_requester.ppif`, plus the older direct
`fsm/amba_requester.fsm` seed. AHB `.ahb` profile aliases, completers,
subordinates, interconnect/decode, scoreboards, full-manager behavior,
verification-output generation, backend-language variants, and VHDL remain
deferred.
