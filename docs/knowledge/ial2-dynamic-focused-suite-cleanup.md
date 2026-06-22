---
id: ial2-dynamic-focused-suite-cleanup
title: Dynamic transaction-ID family has bounded focused validation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.236 add?"
  - "how do I run the bounded dynamic transaction-ID validation?"
  - "which test covers dynamic transaction-ID behavior without the AXI manager monoliths?"
  - "what is the next IAL2 frontier after dynamic focused validation?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.237?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.238?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, validation, tests, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-data-behavior.md; docs/knowledge/ial2-post-dynamic-read-data-next-slice-selection.md; docs/knowledge/ial2-feature-completeness-priority.md; docs/knowledge/ial2-dynamic-burst-length-readiness-audit.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.236|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.237|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.238|t/1438-axi-ial2-manager-dynamic-transaction-id-focused|dynamic burst-length capture|dynamic raw-ARLEN|metadata-only transaction-local|dynamic write BID|dynamic read burst-last' docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.236` added
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, a bounded focused
test for the shipped dynamic transaction-ID family from `.219` through `.234`.

The target covers metadata-only dynamic IDs, generated dynamic write `BID`
response-demux, generated dynamic read single-beat `RID` response-demux,
generated dynamic read burst-last `RID`/`RLAST` response-demux, scalar dynamic
single-beat read-data capture, and scalar dynamic last-beat read-data capture.
It checks PPIF adapter parsing, generated IAL1/IAL0 invariants, report fields,
in-process SystemVerilog dynamic guards/read-data capture enables, and strict
CLI check plus semantic JSON support-accounting identity.

Run it with:

```sh
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

The broad `t/1436` and `t/1437` AXI manager suites remain intact for larger
sweeps, but this focused target is the routine closeout surface for the
shipped dynamic family.

`.236` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.237`, readiness audit for
dynamic burst-length capture over generated single-active dynamic read
last-beat response-demux and scalar dynamic read-data.

`.237` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.238`, direct bounded
implementation of report-only dynamic raw-`ARLEN` burst-length capture over
generated dynamic last-beat read-data.

`.238` now ships that dynamic report-only raw-`ARLEN` capture and leaves
dynamic runtime validation to `.239`, the next readiness audit.
