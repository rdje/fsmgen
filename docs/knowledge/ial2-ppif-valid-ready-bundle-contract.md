---
id: ial2-ppif-valid-ready-bundle-contract
title: IAL2 PPIF Valid-Ready bundle contract selection
answers:
  - "what contract should future multi-channel .ppif use?"
  - "should multi-channel PPIF generate one .isf or several .isf files?"
  - "what is the PPIF valid-ready bundle report schema?"
  - "can a multi-channel PPIF pick the first channel as HDL entry?"
  - "how should PPIF bundles expose generated IAL1 and IAL0 artifacts?"
date: 2026-06-12
status: current
tags: [ial2, ppif, valid-ready, bundle, contract]
evidence: docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md; docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.md
reverify: rg -n "valid_ready_bundle.v1|generated_ial1 =|generated_ial0 =|first channel wins|aggregate bundle" docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md docs/decisions/0017-ppif-valid-ready-bundle-contract.md
---

Multi-channel `.ppif` Valid-Ready support uses an aggregate bundle contract
over per-channel generated artifacts. Each
`valid-ready-channel` object remains one channel-level intent object and emits
its own reviewable generated `.isf` actor plus generated `.fsm` artifacts.

The selected future report schema is
`fsmgen.ial2.protocol_intent.valid_ready_bundle.v1`. The aggregate result
should expose arrays such as `generated_ial1.items[]`,
`generated_ial0.items[]`, and report-level `channels[]`; the current
single-object `.ppif` result shape remains stable until an explicit
compatibility owner changes it.

`IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1` ships the bounded report,
`--outdir`, and `--check --json` subset for this contract. The selected
contract forbids arbitrary "first channel wins" HDL or semantic selection.
Default HDL generation and aggregate semantic JSON for a multi-channel bundle
remain fail-closed until a future wrapper/top actor, explicit entry-selection,
or aggregate semantic owner lands.
