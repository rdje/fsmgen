---
id: ial2-three-static-mixed-dynamic-static-read-rlast-recapture-readiness-audit
title: Three-static mixed read RLAST recapture readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.421 decide?"
  - "is three-static mixed read RLAST recapture ready for contract selection?"
  - "what blocks direct three-static mixed read RLAST recapture implementation?"
  - "what should the three-static mixed read RLAST recapture contract pin?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.421|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.422|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|multi_static3_burst_last|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|marked_static_capture_count|static_state_count|static-case count is two|contract selection' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.421` selects `.422`, public contract
selection for one-dynamic-plus-three-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture.

The audit found no lower parser, public syntax, support-accounting,
report-schema, or IAL1/HDL prerequisite. The public three-static burst-last
sample already ships with
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, one-bit
`axi0_rlast`, list-shaped transaction/static-ID fields, and generated
final-beat completions.

The current baseline remains no-recapture: no `static_capture`, no dynamic
release-recapture fields, and four request-not-busy assertions. The
recapture marker substrate already accepts one dynamic plus three static
states and projects three static capture entries when invoked with
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`.

The remaining gap is deliberate selection logic: the burst-last normalizer
marks recapture only for one dynamic plus two static states, and the focused
RLAST expectation helper expects recapture only when the static-case count is
two.

The `.422` contract must pin public syntax/support identity,
`burst_last` mode/source/semantics, `axi0_rlast`, dynamic recapture under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` for
`r1`/`r2`/`r3`, final-beat release-recapture source, raw non-final `RID`
preservation, dynamic/static guard composition, idle-or-releasing assertions,
sibling preservation, validation gates, rollback, docs, and Knowledge Map
impact before behavior changes.
