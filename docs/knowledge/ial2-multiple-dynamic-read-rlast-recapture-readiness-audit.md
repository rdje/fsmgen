---
id: ial2-multiple-dynamic-read-rlast-recapture-readiness-audit
title: Multiple dynamic read RLAST recapture needs contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.383 decide?"
  - "can multiple dynamic read burst-last recapture be implemented directly?"
  - "what is the next task after multiple dynamic read recapture audit?"
  - "why does multiple dynamic read RLAST recapture need contract selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.383|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.384|MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|generated_dynamic_demux_last_beat_completion|multi_active_unique_dynamic_read|bounded_multi_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.383` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.384`, public contract selection for
multiple all-dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, HDL, or runtime behavior.

The implementation substrate is close: dynamic read state already has
per-transaction release-recapture rule names, sibling request guards, active
same-ID guards, and idle-or-releasing assertion names. The current burst-last
multi-read branch still reports `bounded_multi_dynamic_read_rid_rlast_demux_contract`,
`generated_dynamic_demux_last_beat`, request-not-busy assertions, and no
release-recapture fields.

Contract selection is needed first to pin the last-beat release-recapture
source, assertion renames, release-only and release-recapture guard semantics,
raw non-final beat preservation, scalar last-beat read-data preservation,
raw-`ARLEN`/runtime/multi-beat preservation, validation gates, rollback, and
deferred boundaries.
