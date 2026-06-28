---
id: ial2-post-apb-multi-peripheral-back-to-back-next-slice-selection
title: Post APB multi-peripheral back-to-back selector picks sideband-aware readiness audit
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.610?"
  - "what comes after APB multi-peripheral back-to-back propagation?"
  - "which APB back-to-back residue is next after .609?"
  - "why is APB sideband-aware back-to-back audited before implementation?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.611?"
date: 2026-06-28
status: current
tags: [ial2, apb, back-to-back, sideband, selector, task-tree]
evidence: docs/IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.610|sideband-aware APB back-to-back|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.611" docs/IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.610` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.611`, an APB sideband-aware
back-to-back timing-policy readiness audit, as the next exact IAL2/APB owner
after `.609` shipped no-sideband multi-peripheral back-to-back propagation.

The selector changes no parser, generator, sample, support-accounting,
validation, generated-artifact, JSON, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior.

The sideband-aware audit is next because selected no-sideband fixed and
multi-peripheral back-to-back paths are already shipped, while shipped
sideband/data16/protection APB families still carry explicit back-to-back
residue. Data16 and protection variants build on the sideband-aware APB
surface, and the current queued requester path stores only no-sideband request
payload fields. `.611` must therefore audit queued `PPROT`/`PSTRB` capture,
fixed and multi-peripheral propagation, completer adjacent setup admission with
byte lanes and endpoint-local policies, report/residue movement, diagnostics,
validation, and rollback before implementation.

Data16/protection back-to-back variants, deeper queues, alternate overflow,
accepted-less requester surfaces, multiple active APB transfers, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
