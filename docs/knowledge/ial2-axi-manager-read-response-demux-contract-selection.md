---
id: ial2-axi-manager-read-response-demux-contract-selection
title: AXI read response demux contract uses response-scope single-beat
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.38 select?"
  - "what is the read response-demux syntax?"
  - "what comes after read response-demux contract selection?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.39?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.40?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, contract, parser, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.38|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.39|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.40|response-scope single-beat|response_demux\\.read|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.38` selected the bounded public read
response-demux contract:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The first scope is explicitly single-beat/non-burst. `response-event` must
equal top-level `read-complete` and means the raw accepted read response
transfer under the explicit opt-in. Read demux requires positive-width read
ID-family metadata, read transaction metadata, and explicit read
`auto-id-lifecycle` metadata.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.39` shipped parser/report metadata and
static validation for the selected read arm, with generated read `.isf`,
`.fsm`, and HDL behavior unchanged. It reports `response_demux.read` with
`generated_behavior: false` and `generated_read_rid_demux` residue.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.40` is next: audit generated read `RID`
demux behavior readiness. Read-data interleaving/reassembly, bursts, per-ID
queues, full-manager behavior, and VHDL remain future exact-owner work.
