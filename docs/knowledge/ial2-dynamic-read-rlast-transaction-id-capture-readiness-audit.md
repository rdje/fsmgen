---
id: ial2-dynamic-read-rlast-transaction-id-capture-readiness-audit
title: Dynamic read RLAST readiness audit selects public contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.229 select?"
  - "what comes after the dynamic read RLAST readiness audit?"
  - "can dynamic read burst-last RLAST be implemented directly?"
  - "what is the next IAL2 slice after dynamic read RLAST readiness?"
  - "why does dynamic read RLAST need contract selection first?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-rlast-transaction-id-capture-contract-selection.md; docs/knowledge/ial2-post-dynamic-read-id-next-slice-selection.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-behavior.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.229|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.230|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.231|DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT|DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION|bounded dynamic read burst-last' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.229` selects `.230`, public contract
selection for bounded dynamic read burst-last/`RLAST` transaction-ID capture
and response matching.

The audit keeps behavior unchanged. Existing dynamic read support remains the
single-beat shape from `.227`; existing generated burst-last/`RLAST` behavior
remains non-dynamic. The next contract selector must decide public syntax,
last-signal ownership, admitted-request capture timing, selected-ID/busy
lifetime across non-last beats, raw response/`RID`/`RLAST` completion
semantics, generated completion/release behavior, dynamic assertions,
diagnostics, report vocabulary, generated artifact boundaries, validation,
rollback, docs, Knowledge Map impact, and residue.

The audit found no lower-layer prerequisite and no stale report/static cleanup
blocker. Direct behavior still needs contract ownership before any parser,
generator, PPIF sample, support-accounting catalog, generated artifact, test,
validation, or HDL behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.230` completed that contract selection and
selected `.231`, direct generated behavior using the existing
`response-demux.read` burst-last syntax with one dynamic read transaction.
