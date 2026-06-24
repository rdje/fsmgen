---
id: ial2-two-dynamic-one-static-read-demux-readiness
title: Two-dynamic/one-static mixed read demux readiness selects contract
answers:
  - "can two-dynamic-plus-static mixed read response demux be implemented directly?"
  - "what comes after two-dynamic-plus-static mixed write response-demux?"
  - "why does two-dynamic-plus-static mixed read demux need contract selection?"
  - "what is the next owner for two-dynamic-plus-static mixed read response-demux?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.342|IAL2-FEATURE-COMPLETENESS-FRONTIER\.343|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT|mixed dynamic/static read demux only when there is exactly one dynamic|response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction|bounded_multi_mixed_dynamic_static_read_rid_demux_contract' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.342` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.343`, public contract selection for
bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat
`RID` response-demux.

Direct implementation is premature in `.342` because mixed read admission and
construction are still singular on the dynamic side: the current path accepts
exactly one dynamic read transaction plus one, two, or three concrete static
read transactions, while the two-dynamic-plus-static read shape needs an
owned public report/assertion contract.

The lower substrate is close after `.341`: the shared mixed assertion helper
can express multi-dynamic no-active-same-ID checks, active selected-ID
uniqueness, static-ID exclusions, response active/unique-match assertions, and
completion-active assertions. `.251` also already proves multiple all-dynamic
read single-beat selected-ID capture and matching.

`.343` should select the sample stem, support identity, behavior label,
transaction order, static ID, report mode, completion source, dynamic capture
ownership, `active_dynamic_ids_must_be_unique`, onehot0 mixed read request
policy, assertion names, diagnostics, validation, residue, rollback, and next
frontier before any parser, generator, PPIF sample, support-accounting, test,
JSON, or HDL behavior changes.
