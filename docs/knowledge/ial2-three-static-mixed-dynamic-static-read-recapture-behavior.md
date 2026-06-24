---
id: ial2-three-static-mixed-dynamic-static-read-recapture-behavior
title: Three-static mixed read recapture behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.419 ship?"
  - "how is one dynamic plus three static mixed read recapture reported?"
  - "what assertions changed for shipped three-static mixed read recapture?"
  - "does three-static mixed burst-last recapture remain deferred after .419?"
  - "what validation proved three-static mixed read recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.419|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR|axi0_r0_dynamic_id_release_recapture|axi0_r3_static_busy_release_recapture|generated_multi_mixed_dynamic_static_read_demux_completion|axi0_r3_static_request_idle_or_releasing|three-static burst-last path still has no static recapture' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.419` ships
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The response-demux report now adds recapture fields to
`response_demux.read.dynamic_capture.transactions[0]` for `r0`, using
`mixed_dynamic_static_dynamic_read` and
`generated_multi_mixed_dynamic_static_read_demux_completion`.

The report also adds list-shaped `response_demux.read.static_capture[]`
entries for `r1`, `r2`, and `r3`, using
`mixed_dynamic_static_static_read` and the same multi-mixed read
release-recapture source.

Generated assertions replace the `r0`, `r1`, `r2`, and `r3`
request-not-busy assertions with idle-or-releasing assertions while
preserving onehot0, static-ID exclusions, response active-match, pairwise
unique-match, and completion-active assertions.

Validation passed syntax checks and smaller direct normalizer/rule probes.
Guarded selected schedule and focused `t/1438` probes stopped because host
memory was already above the default 88% cutoff; no cutoff was raised. The
three-static burst-last path and two-dynamic-plus-one-static path remain
unwidened.
