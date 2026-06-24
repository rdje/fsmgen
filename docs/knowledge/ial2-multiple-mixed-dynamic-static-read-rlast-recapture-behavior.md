---
id: ial2-multiple-mixed-dynamic-static-read-rlast-recapture-behavior
title: Two-static mixed read RLAST recapture behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.415 ship?"
  - "how is one dynamic plus two static mixed read burst-last recapture reported?"
  - "what assertions changed for shipped two-static mixed read RLAST recapture?"
  - "does two-static mixed read RLAST recapture widen three-static or two-dynamic shapes?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.415|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|axi0_r0_dynamic_id_release_recapture|axi0_r1_static_busy_release_recapture|axi0_r2_static_busy_release_recapture|axi0_r2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.415` ships
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The response-demux report now adds final-beat recapture fields to
`response_demux.read.dynamic_capture.transactions[0]` for `r0`, using
`mixed_dynamic_static_dynamic_read` and
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`.

The report also adds list-shaped `response_demux.read.static_capture[]`
entries for `r1` and `r2`, using `mixed_dynamic_static_static_read` and the
same final-beat release-recapture source.

Generated assertions replace the `r0`, `r1`, and `r2` request-not-busy
assertions with idle-or-releasing assertions while preserving onehot0,
static-ID exclusions, raw `RID` active-match, pairwise raw `RID`
unique-match, and completion-active assertions.

The one-dynamic/one-static mixed read RLAST recapture report keeps singular
`static_capture`, the three-static burst-last read report remains un-widened,
and the two-dynamic-plus-one-static burst-last read report remains
un-widened.
