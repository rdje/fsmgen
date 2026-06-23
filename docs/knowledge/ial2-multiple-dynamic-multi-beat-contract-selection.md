---
id: ial2-multiple-dynamic-multi-beat-contract-selection
title: IAL2 multiple dynamic multi-beat contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.267 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.268?"
  - "what sample name was selected for multiple dynamic multi-beat output banks?"
  - "what is the public contract for multiple dynamic multi-beat output banks?"
  - "what comes after multiple dynamic multi-beat contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, multi-beat, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.267|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.268|MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION|MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR|dynamic_read_data_multi_transaction_multi_beat|bounded generated multiple dynamic multi-beat' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.267` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.268`, direct generated implementation of
bounded multiple dynamic multi-beat read-data output-bank behavior over the
generated multiple dynamic read runtime-validation boundary.

The selected public sample, now shipped by `.268`, is
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif`.
The stem is explicit because existing `dynamic_read_data_multi` samples use
`multi` for multiple dynamic read transactions, while
`dynamic_read_data_multi_beat` is the existing single-active dynamic
multi-beat sample.

The contract requires two or more all-dynamic reads, generated dynamic
burst-last response-demux, `capture-scope multi-beat`, runtime-assertion
`ARLEN` burst-length metadata, complete exactly-once output-bank bindings for
every generated dynamic read transaction, request-time output-bank
initialization, raw matched-beat lane capture, and worst-observed scalar
`RRESP` aggregation. `.267` changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifacts, tests,
JSON, or HDL behavior. `.268` later shipped the selected behavior and keeps
mixed dynamic/static demux, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL as later exact owners.
