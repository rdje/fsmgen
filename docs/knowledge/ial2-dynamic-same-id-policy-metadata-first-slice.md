---
id: ial2-dynamic-same-id-policy-metadata-first-slice
title: Dynamic same-ID reject parser/report metadata is implemented
answers:
  - "does FSMGen accept dynamic-id-reuse reject in same-id-ordering?"
  - "what does same_id_ordering.dynamic_id_reuse_policy report?"
  - "does dynamic same-ID reject generate HDL?"
  - "what PPIF sample covers dynamic same-ID reject?"
  - "what fails closed for dynamic same-ID reject policy?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, parser, report]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.436|DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE|dynamic_same_id_reject_policy|dynamic-id-reuse reject|dynamic_id_reuse_policy|intent\\.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.436` implements metadata-first support for
`(dynamic-id-reuse reject)` under `same-id-ordering`.

The public report branch is
`same_id_ordering.dynamic_id_reuse_policy.<family>` with `policy: reject`,
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`, `request_conflict_policy:
no_active_same_id`, and no generated queue or scoreboard behavior. Dynamic-only
policy uses `same_id_ordering.mode: dynamic_id_reuse_policy`; concrete plus
dynamic policy uses `id_reuse_policy`.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif`, support
accounted as
`intent.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy`.

At the `.436` metadata-first boundary, generated dynamic same-ID enforcement
and response-demux mapping were deferred. Later `.438` and `.442` slices now
cover bounded generated response-demux assertion mappings for selected
multi-active and single-active shapes. Dynamic queues, scoreboards, HDL
behavior, and VHDL behavior remain deferred.
