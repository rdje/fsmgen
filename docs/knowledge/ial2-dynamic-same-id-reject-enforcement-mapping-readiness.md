---
id: ial2-dynamic-same-id-reject-enforcement-mapping-readiness
title: Dynamic same-ID reject enforcement mapping is ready for multi-active demux shapes
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.437 select?"
  - "can dynamic-id-reuse reject map to generated response-demux assertions?"
  - "which dynamic same-ID reject shapes are first covered?"
  - "does .437 change generated HDL behavior?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, response-demux, audit]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.437|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.438|DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS|generated_no_active_same_id_reject|active_dynamic_ids_must_be_unique|dynamic_request_no_active_same_id' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.437` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.438`, a narrow generated-enforcement
report mapping for `(dynamic-id-reuse reject)`.

The first covered shapes are generated multi-active response-demux families
whose public report already exposes `dynamic_capture.same_id_conflict_policy:
active_dynamic_ids_must_be_unique`, per-dynamic-transaction
`*_dynamic_request_no_active_same_id` assertions, and pairwise
`*_dynamic_active_id_unique` assertions. That includes bounded multiple
all-dynamic write/read demux and bounded two-dynamic-plus-one-static mixed
write/read demux shapes.

`.437` changes no generated HDL or runtime behavior. Single-active dynamic
demux, one-dynamic mixed demux, dynamic queues, dynamic scoreboards, direct
backend behavior, and VHDL remain future exact-owner work.
