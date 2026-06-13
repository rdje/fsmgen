---
id: ial2-axi-manager-post-rlast-next-slice-selection
title: Post-RLAST AXI selector chooses report alignment
answers:
  - "what comes after AXI RLAST behavior?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.54?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.55?"
  - "why is AXI read-data reassembly not next after RLAST?"
  - "is there stale RLAST report text?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, report, residue, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.56|AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE|report prose|read-data/burst' docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After `.53` shipped generated burst-last `RLAST` completion behavior, `.54`
selected a narrow report-alignment slice as the next owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.55`. `.55` is now complete.

The selector found that structured schedule JSON for the burst-last sample is
correct: it reports `response_demux.read.generated_behavior: true`,
`transaction_completion_source: generated_demux_last_beat`, generated
completion signals, generated rules, generated assertions, empty
`auto_id_lifecycle.residue`, and read same-ID response-demux coverage.

The drift was in generated report prose: `enforced_static_rules` and
`unsupported_residue` still described burst-last `RLAST` as report-only and
generated burst/last-beat tracking as outside the capacity/status shell. `.55`
aligned that user-facing report text before larger feature work resumes.

Multi-beat read-data reassembly is not selected directly because the current
public `read-data` contract remains single-beat and is still rejected when
paired with `response_demux.read.response_scope burst_last`.

The next active leaf after the alignment is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.56`, the selector for the next public AXI
read-data/burst contract or readiness owner.
