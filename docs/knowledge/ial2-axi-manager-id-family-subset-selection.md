---
id: ial2-axi-manager-id-family-subset-selection
title: AXI manager ID-family/static-validation subset selected
answers:
  - "what is the next AXI manager subset after capacity/status?"
  - "what should happen before AXI ID allocation or response matching?"
  - "what AXI ID-family syntax shape is selected?"
  - "does the ID-family subset implement ordering or response matching?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.8 decide?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id-family, static-validation, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'ID-family|id-families|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.8|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.9|A5\\.1|A5\\.1\\.1|A5\\.5|A5\\.6' docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the public AXI manager capacity/status `.ppif` first slice, the next
selected AXI manager subset is ID-family declaration and static validation.
It owns separate read/write ID-family widths, request/response ID signal-pair
metadata, zero-width absence semantics, static diagnostics, source anchors,
and report metadata.

The selected semantic shape is equivalent to:

```text
(id-families
  (write (width 4) (request-id AWID) (response-id BID))
  (read  (width 4) (request-id ARID) (response-id RID)))
```

`IAL2-FEATURE-COMPLETENESS-FRONTIER.8` selected an additive optional
`id_families` extension to the existing capacity/status object as the first
implementation boundary. `IAL2-FEATURE-COMPLETENESS-FRONTIER.9` shipped that
public `(id-families ...)` metadata/report slice. ID allocation,
per-transaction user-ID validation, same-ID ordering, different-ID
interleaving, `BID`/`RID` response matching, bursts, queued/blocking policy,
profile aliases, full AXI manager behavior, and VHDL remain future exact-owner
residue.
