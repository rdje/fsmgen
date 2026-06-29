---
id: ial2-post-trimode-mdbook-next-slice-selection
title: Post tri-mode mdBook selector chooses AHB IAL2 readiness audit
answers:
  - "what follows IAL2-FEATURE-COMPLETENESS-FRONTIER.693?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.695?"
  - "why is AHB the next IAL2 readiness target?"
  - "does the post tri-mode mdBook selector change behavior?"
date: 2026-06-29
status: current
tags: [ial2, ahb, task-tree, readiness, selector, mdbook]
evidence: docs/IAL2_POST_TRIMODE_MDBOOK_NEXT_SLICE_SELECTION.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/15a-ial2-new-protocol-support.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.694|IAL2-FEATURE-COMPLETENESS-FRONTIER\.695|AHB IAL2 source-shape readiness audit|fsm/amba_requester\.fsm|unsupported IAL2 alias candidate|no parser changes|no generator changes' docs/IAL2_POST_TRIMODE_MDBOOK_NEXT_SLICE_SELECTION.md docs/book/src/16c-ial2-ahb.md docs/book/src/15a-ial2-new-protocol-support.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.694` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.695`, an AHB IAL2 source-shape readiness
audit, as the next executable IAL2 owner after AXI/APB/AHB tri-mode mdBook
coverage completed.

AHB is selected because the current mdBook map exposes a useful direct
`fsm/amba_requester.fsm` seed, while AHB `.ppif`, `.ahb`, generated `.isf`,
generated `.fsm`, reports, and support-accounting surfaces are not shipped.

The selector changes no parser, generator, public source, sample,
support-accounting, suffix, generated-artifact, HDL/runtime, AXI, APB, AHB,
backend-language, verification-output, direct-backend, or VHDL behavior.
