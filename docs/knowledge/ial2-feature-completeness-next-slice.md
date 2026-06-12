---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is bounded auto-ID contract selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.21|bounded auto-ID pool|request-ID drive contract|auto_id_lifecycle|auto-ID allocation' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
transaction-envelope metadata, transaction event dispatch, and concrete
transaction ID assertion IAL2 surfaces, the next active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.21`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.21` selects the bounded AXI auto-ID
pool/request-ID drive contract before any request-ID output, allocation,
release, response demux, ordering, or VHDL behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.12` shipped the bounded AXI manager
machine-readable AST/structural logical read/write transaction-envelope
metadata slice.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.13` selected the event-dispatch
prerequisite because dynamic ID allocation and response matching need
per-transaction event provenance first.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` selected the `.15` implementation
owner after verifying that the exact OR fan-in guard shape reaches
SystemVerilog through the current lowering path.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.15` shipped transaction event dispatch,
including unique transaction-event inputs, scalar one-event compatibility, OR
fan-in guards, `transaction_event_dispatch` report metadata, and bounded IAL1
OR/negated-OR guard conflict proof support.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.16` selected AXI manager ID/response
rule-engine readiness as the next exact subset because event provenance is now
available and the next risk is deciding whether ID signal inputs, ID policy
validation, in-flight state, and response ID matching can be implemented
through the current IAL1/IAL0/SystemVerilog substrate.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.17` selected a narrow concrete-ID
assertion implementation boundary: generated IAL1 declares the used ID-family
request/response ID signals, assertion-only transaction content emits `.fsm`
`+assert` carriers, and SystemVerilog assertions emit through the existing
assertion backend.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.18` shipped that implementation boundary,
including generated ID inputs, `.fsm` `+assert` carriers, verification-only
SystemVerilog assertions, `id_response_rule_engine` report metadata, and
fail-closed duplicate concrete-event diagnostics.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.19` selected auto-ID lifecycle/readiness as
the next exact subset.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.20` completed that readiness audit. It
concluded that the IAL1/IAL0/SystemVerilog substrate can carry a bounded
scalar request-ID lifecycle, but width and existing `(id auto)` syntax alone
are not a reviewable allocation policy.

The full AXI manager is not implemented yet. ID allocation, ordering, response
matching, bursts, queued/blocking policy, `.pif`/`.ppi`/`.axi` aliases, and
VHDL remain future exact-owner work; they should not jump ahead of the `.21`
contract selector unless that selector records a stronger reason.
