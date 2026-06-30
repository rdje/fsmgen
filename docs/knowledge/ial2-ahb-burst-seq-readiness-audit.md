---
id: ial2-ahb-burst-seq-readiness-audit
title: AHB burst SEQ readiness selects subordinate contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.750 select?"
  - "is AHB burst SEQ ready for direct implementation?"
  - "which AHB burst SEQ owner follows IAL2-FEATURE-COMPLETENESS-FRONTIER.750?"
  - "why is subordinate SEQ contract selection needed before implementation?"
  - "does IAL2-FEATURE-COMPLETENESS-FRONTIER.750 change behavior?"
date: 2026-06-30
status: current
tags: [ial2, ahb, burst, seq, readiness, contract-selection]
evidence: docs/IAL2_AHB_BURST_SEQ_READINESS_AUDIT.md; docs/IAL2_POST_AHB_AGGREGATE_ALIAS_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.750|IAL2-FEATURE-COMPLETENESS-FRONTIER\.751|ahb_burst_seq_support_deferred|supported-transfer nonseq|subordinate-side `SEQ`|generated IAL1 routes SEQ to ERROR|Requester generation' docs/IAL2_AHB_BURST_SEQ_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.750` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.751`, a no-behavior public contract
selection for first bounded subordinate-side AHB burst `SEQ` support.

Direct implementation is not ready in `.750`: the current subordinate source
syntax still reports `supported-transfer nonseq`, the generated subordinate
routes `SEQ` to the selected two-cycle ERROR path, and source-backed AHB facts
require `SEQ` to relate to a preceding burst transfer rather than behave as an
independent access.

Requester burst generation is not the next blocker because the bounded
requester already emits first-beat `NONSEQ`, later-beat `SEQ`, address
progression/wrap state, and response handling. Aggregate propagation should
follow the subordinate/interconnect contract once the endpoint behavior and
report/residue movement are selected.
