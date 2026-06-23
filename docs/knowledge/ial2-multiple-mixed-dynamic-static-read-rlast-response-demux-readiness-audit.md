---
id: ial2-multiple-mixed-dynamic-static-read-rlast-response-demux-readiness-audit
title: Multiple mixed dynamic/static read RLAST readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.301 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.302?"
  - "is multiple mixed dynamic/static read burst-last response-demux ready?"
  - "what diagnostic protects multiple mixed dynamic/static read burst-last today?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.301|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.302|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT|burst-last ID matching supports exactly one dynamic read transaction and one concrete static read transaction|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.301` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.302`, public contract selection for
bounded multiple mixed dynamic/static read burst-last `RID && RLAST`
response-demux.

The audit found the lower substrate close enough for contract selection:
`.299` provides the one-dynamic plus two-static read state/report shape for
single-beat `RID`, and `.280` provides the one-dynamic plus one-static
burst-last final-completion pattern.

The current public boundary is fail-closed. A temporary probe combining the
`.299` multi-static read shape with `.280` `response-scope burst-last` syntax
fails under strict check JSON with:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static burst-last ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

`.302` must select the public/report contract before behavior changes,
including one dynamic plus two pairwise-distinct concrete static reads,
one-bit `last-signal`, candidate mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, candidate
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped mixed/static-ID reservation fields, raw `RID` assertions, final
`RID && RLAST` completion semantics, validation gates, rollback, and residue.
