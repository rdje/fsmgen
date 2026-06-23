---
id: ial2-mixed-dynamic-static-read-rlast-response-demux-readiness-audit
title: Mixed dynamic/static read RLAST response-demux readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.278 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.279?"
  - "is mixed dynamic/static read RLAST response-demux ready for direct implementation?"
  - "why does mixed dynamic/static read RLAST need contract selection first?"
  - "what diagnostic does mixed dynamic/static read burst-last currently emit?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.278|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.279|MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT|mixed dynamic/static read burst-last|mixed dynamic/static ID matching supports response_scope single-beat only|last_signal|static concrete branch' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.278` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.279`, public contract selection for
bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.

The audit found the lower substrate close but not ready for direct behavior:
the mixed read state plan, static-ID reservation, raw active/unique-match
assertions, and all-dynamic `last_signal` normalization already exist, but
the static concrete completion guard is single-beat shaped today and must be
contracted before implementation.

The current fail-closed diagnostic for adding `response-scope burst-last` and
a one-bit `last-signal` to the `.276` mixed read sample is:

```text
response_demux.read mixed dynamic/static ID matching supports response_scope single-beat only in this slice
```

`.279` must select raw `RID` beat ownership versus final `RID && RLAST`
completion semantics, static final-beat behavior, report vocabulary,
diagnostics, sample/support-accounting names, validation gates, rollback, and
explicit residue before any generator or HDL behavior changes.
