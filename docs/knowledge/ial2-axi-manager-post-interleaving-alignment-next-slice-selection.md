---
id: ial2-axi-manager-post-interleaving-alignment-next-slice-selection
title: AXI burst payload/output readiness follows read-data interleaving residue alignment
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.83?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.83 select?"
  - "what comes after read-data interleaving residue alignment?"
  - "why is AXI burst payload/output readiness next?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.83?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, bursts, read-data, interleaving, residue, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.83|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.84|POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION|AXI burst payload/output readiness|response_demux\\.residue: \\[bursts\\]|same_id_ordering\\.residue' docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.83` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.84`, AXI burst payload/output readiness
audit, after `.82` aligned read-data interleaving residue for the covered
generated auto-ID multi-beat-by-RID subset.

The reason is that `bursts` is now the only remaining `response_demux`
residue and remains shared with `same_id_ordering`, while the public
multi-beat sample already has burst-last `RLAST` demux, raw ARLEN capture,
beat-count/RLAST runtime validation, per-beat output banks, valid masks,
length outputs, and scalar aggregate `RRESP`.

The follow-up `.84` audit found the shipped per-beat output-bank behavior is
enough for bounded burst residue movement in the covered generated auto-ID
multi-beat subset and selected `.85`, report/static `bursts` residue
alignment. Packed/full burst assembly remains a separate deferred contract.
