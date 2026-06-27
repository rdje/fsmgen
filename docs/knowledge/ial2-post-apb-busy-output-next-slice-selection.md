---
id: ial2-post-apb-busy-output-next-slice-selection
title: Post APB busy-output selector chooses public-surface/import-tree sync
answers:
  - "what comes after APB requester busy output?"
  - "why is the next IAL2 APB slice a public-surface sync?"
  - "which task owns the APB import-tree and mdBook sync after busy output?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.574?"
date: 2026-06-27
status: current
tags: [ial2, apb, busy, import-tree, mdbook, task-tree]
evidence: docs/IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md; docs/BIN_FSMGEN_IMPORT_TREE.md; docs/book/src/11-extensions-and-embedding.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.573|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.574|213|212|ApbRequesterTransfer|ApbCompleter|ApbComposition|\\.apb|\\.axi' docs/IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md docs/book/src/11-extensions-and-embedding.md docs/BIN_FSMGEN_IMPORT_TREE.md docs/knowledge/bin-fsmgen-import-tree-current-baseline.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.573` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.574`, a no-behavior public-surface and
`bin/fsmgen` import-tree synchronization slice after `.572` shipped additive
APB requester `busy` output.

The selector chose documentation/import-tree synchronization before further
behavior because the live `bin/fsmgen` import probe now reaches `213`
project-owned files total, including `212` `FSM::...` `.pm` packages, while
the existing import-tree note and fact still record `206`/`205`. The mdBook
language-surface chapter also needs to describe shipped `.axi`, `.apb`, APB
requester-transfer, APB completer, fixed APB composition, and APB busy-capable
variants as bounded public surfaces instead of leaving stale unsupported-alias
wording in place.

`.574` must not change parser behavior, generator behavior, samples,
support-accounting, validation behavior, generated artifacts, tests, JSON
surfaces, HDL/runtime behavior, direct backend behavior, verification-output,
backend-language variants, AXI behavior, APB behavior, or VHDL behavior.
