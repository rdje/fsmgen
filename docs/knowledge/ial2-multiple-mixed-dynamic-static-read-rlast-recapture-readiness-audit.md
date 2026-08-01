---
id: ial2-multiple-mixed-dynamic-static-read-rlast-recapture-readiness-audit
title: Two-static mixed read RLAST recapture readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.413 decide?"
  - "is one dynamic plus two static mixed read burst-last recapture ready for contract selection?"
  - "what source should two-static mixed read RLAST recapture use?"
  - "what must be preserved for two-static mixed read RLAST recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, readiness]
evidence: >-
  docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md;
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.413|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.414|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|axi0_r0_dynamic_request_not_busy|axi0_r0_dynamic_request_idle_or_releasing|static_capture\\[\\]|raw non-final' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.413` selects `.414`, public contract
selection for one-dynamic-plus-two-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture.

The audit found no parser, PPIF syntax, support-accounting, IAL1/HDL
lowering, or report-schema prerequisite. The public burst-last sample already
exists, and the read recapture marker already supports one dynamic plus two
static read states; the normalizer simply leaves the multi-mixed burst-last
branch unmarked today.

The selected release-recapture source should be:

```text
generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

The contract must preserve raw non-final `RID` behavior, scalar read-data,
raw-`ARLEN`, runtime beat-count/`RLAST` validation, multi-beat output banks,
the one-static burst-last recapture report shape, and the three-static and
two-dynamic read burst-last no-recapture boundaries.
