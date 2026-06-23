---
id: ial2-multiple-dynamic-read-rlast-response-demux-readiness-audit
title: Multiple dynamic read RLAST demux readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.253 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.254?"
  - "is multiple dynamic read burst-last/RLAST ready for direct implementation?"
  - "why select multiple dynamic read RLAST contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.253|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.254|MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT|dynamic ID matching supports multiple dynamic read transactions only with response_scope single-beat|_normalize_response_demux_read|_response_demux_dynamic_assertion_specs_for_family' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.253` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.254`, public contract selection for
bounded multiple dynamic read burst-last/`RLAST` response-demux.

The audit does not select direct implementation yet. It found that the
state-list capture/release/rule/assertion substrate is close after `.251`, but
the public contract must first pin the all-dynamic read-family shape,
`response-demux.read response-scope burst-last`, one-bit `last-signal`
ownership, selected-ID/busy lifetime across non-last beats, raw `RID` beat
matching versus final `RID && RLAST` completion, generated assertion roles,
report vocabulary, sample/support-accounting expectations, validation,
rollback, and explicit read-data/runtime/multi-beat residue.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changed in `.253`.
