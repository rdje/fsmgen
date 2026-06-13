---
id: ial2-axi-manager-rlast-completion-contract-selection
title: AXI RLAST contract selects burst-last response-demux metadata
answers:
  - "what AXI RLAST public syntax was selected?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.50?"
  - "what is response-scope burst-last?"
  - "does AXI RLAST completion use ARLEN or beat counts?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, bursts, response-demux, metadata, contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.51|response-scope burst-last|last-signal|generated_demux_last_beat|burst_length_source: rlast_only' docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.50` selected the first public AXI
`RLAST` completion contract as an additive read `response-demux` scope:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

`response-event` remains the raw accepted read response beat. `last-signal`
is a generated one-bit `RLAST` input. The existing transaction
`(completion NAME)` output remains the generated transaction completion pulse,
but under `burst-last` it represents the matched last beat rather than every
matched beat.

The first contract does not select generated per-transaction beat-valid
outputs, `ARLEN` ownership, beat-count metadata, missing/extra beat
validation, or multi-beat read-data reassembly. It uses `RLAST` as the
authoritative last-beat marker for this boundary.

The next active slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.51`: implement
parser/report metadata and static validation for `response-scope burst-last`
plus `last-signal`, with generated `.isf`, `.fsm`, and HDL behavior
unchanged.
