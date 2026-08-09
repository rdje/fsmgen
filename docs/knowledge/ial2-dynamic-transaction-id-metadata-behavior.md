---
id: ial2-dynamic-transaction-id-metadata-behavior
title: Dynamic transaction-ID parser/report metadata is shipped for AXI manager PPIF
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.219 ship?"
  - "does PPIF accept id dynamic?"
  - "what does (id dynamic) report?"
  - "are dynamic AXI transaction IDs generated in HDL?"
  - "what is dynamic_transaction_id_behavior residue?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, transaction-id, dynamic, ppif, metadata]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/book/src/16aa-ial2-axi-manager-capacity-status.md; ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.219|DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR|axi_manager_capacity_status_dynamic_transaction_id|id dynamic|dynamic_transaction_id_behavior|request_id_source|response_id_signal|selected_not_generated' docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.219` shipped metadata-first dynamic
transaction-ID support for AXI manager capacity/status `.ppif` sources.

The PPIF parser accepts exactly transaction-local `(id dynamic)`. The
normalizer requires a matching positive-width `id-families` entry with
request-ID and response-ID signals, then reports `policy: dynamic`,
`family`, `family_width`, `request_id_source`, `response_id_signal`,
`ownership: user_supplied`, and `implementation_status:
selected_not_generated`.

The public sample
`ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif` is
support-accounted for schedule JSON, strict check JSON, and semantic JSON.

For this metadata-only source, dynamic ID capture, response matching, ordering,
and read-data routing remain residue. Other checked-in sources explicitly
select bounded dynamic response-demux, issue-order-queue, and read-data shapes;
their behavior comes from those additional clauses, not from `(id dynamic)`
alone. Broader combinations, arbitrary queues, and general scoreboards remain
outside the supported contract.
