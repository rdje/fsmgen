---
id: ial2-dynamic-transaction-id-metadata-readiness-audit
title: Dynamic transaction-ID metadata readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.218 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.219?"
  - "is dynamic transaction-ID metadata ready to implement?"
  - "what should id dynamic metadata implementation cover?"
  - "does id dynamic generate response matching?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, ppif, transaction-id, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.218|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.219|DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT|id dynamic|selected_not_generated|request_id_source' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.218` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.219`, direct metadata-first `(id dynamic)`
parser/report implementation.

The `.219` implementation should accept exactly transaction-local
`(id dynamic)`, require a declared positive-width `id-families` entry with
request and response ID signals, and report `policy: dynamic`, `family`,
`family_width`, `request_id_source`, `response_id_signal`,
`ownership: user_supplied`, and `implementation_status:
selected_not_generated`.

Dynamic transaction IDs do not generate response matching in this boundary.
Capture, outstanding tracking, response demux, read-data routing, same-ID
ordering, queues, scoreboards, and HDL behavior remain deferred until explicit
later owners. Same-family behavior clauses that need those semantics must fail
closed in `.219`.
