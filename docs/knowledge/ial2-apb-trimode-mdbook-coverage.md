---
id: ial2-apb-trimode-mdbook-coverage
title: APB IAL2 tri-mode mdBook coverage
answers:
  - "where is the APB IAL2 mdBook chapter?"
  - "which APB examples document IAL2 guided more-control and raw/full-control modes?"
  - "what does the shipped .apb alias mean in APB IAL2 book coverage?"
  - "which APB raw/full-control example documents generated interconnect artifacts?"
date: 2026-06-29
status: current
tags: [ial2, apb, mdbook, ppif, profile-alias, documentation, interconnect]
evidence: docs/book/src/16b-ial2-apb.md; docs/book/src/SUMMARY.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'APB IAL2 Examples|ppif/apb_requester_transfer\.ppif|ppif/apb_requester_transfer\.apb|ppif/apb_composition\.ppif|ppif/apb_composition\.apb|apb_requester\.isf|apb_completer\.isf|apb_interconnect\.isf|apb_interconnect\.fsm|apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back|ial2_profile_alias|fsmgen\.ial2\.protocol_intent\.apb_completer\.v1' docs/book/src/16b-ial2-apb.md docs/book/src/SUMMARY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`docs/book/src/16b-ial2-apb.md` is the APB IAL2 mdBook chapter and is linked
from `docs/book/src/SUMMARY.md` under the IAL2 protocol/platform intent map.

The chapter documents guided mode with APB requester, completer, and fixed
composition `.ppif` examples plus selected `.apb` aliases; more-control mode
with busy/status, sideband, data16, protection, multi-register, and
back-to-back examples; and raw/full-control mode with
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
plus its `.apb` alias.

The `.apb` alias is documented as a selected profile alias over the same IAL2
model, not a separate layer. The raw/full-control outdir path documents
generated APB-specific `apb_interconnect.isf` and `apb_interconnect.fsm`
review artifacts, explicitly not a shared AXI/AHB interconnect contract.
