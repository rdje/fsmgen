---
id: ial2-dynamic-same-id-policy-metadata-readiness-audit
title: Dynamic same-ID reject policy can ship as metadata-first support
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.435 select?"
  - "can dynamic-id-reuse reject parser support be implemented directly?"
  - "does .435 map dynamic same-ID reject to generated response-demux assertions?"
  - "what is the next implementation for dynamic same-ID policy?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, parser, report, audit]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.435|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.436|DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT|dynamic_same_id_reject_policy|dynamic-id-reuse reject' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.435` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.436`, direct metadata-first parser/report
support for `(dynamic-id-reuse reject)`.

The first implementation should add the public syntax, normalized report
metadata, focused diagnostics, a metadata-only PPIF sample, and
support-accounting. It should not map the policy to generated dynamic
response-demux no-active-same-ID assertions yet; response-demux plus dynamic
same-ID policy remains fail-closed until a later owner selects that report
mapping or behavior.
