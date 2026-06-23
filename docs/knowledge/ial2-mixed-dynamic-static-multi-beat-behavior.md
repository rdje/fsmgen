---
id: ial2-mixed-dynamic-static-multi-beat-behavior
title: IAL2 mixed dynamic/static multi-beat output banks ship
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.291 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.291?"
  - "does mixed dynamic/static multi-beat read-data generate output banks?"
  - "which PPIF sample covers mixed dynamic/static multi-beat read-data?"
  - "does mixed dynamic/static multi-beat read-data remove read-data residue?"
  - "what is the next IAL2 slice after mixed dynamic/static multi-beat output banks?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, multi-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.291` ships generated mixed
dynamic/static multi-beat read-data output banks over generated mixed
dynamic/static read burst-last response-demux and runtime beat-count/`RLAST`
validation.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
```

The sample uses exactly one dynamic read transaction and one concrete static
read transaction, generated mixed dynamic/static `RID && RLAST` response
demux, `capture-scope multi-beat`, `status-policy per-beat`,
`status-aggregation worst-observed`, `interleaving multi-beat-by-rid`, and
runtime-assertion `burst-length` metadata.

FSMGen emits per-transaction output banks, valid masks, length outputs,
scalar worst-observed `RRESP` aggregate outputs, output-bank init rules,
per-lane raw matched-read-beat capture rules, raw `ARLEN` storage,
expected-beat storage, read-beat counters, and four runtime assertions per
covered transaction. Dynamic lane capture matches the captured dynamic `RID`;
static lane capture matches the reserved concrete `RID`.

Reports use `bounded_multi_beat_read_data_contract`, mixed last-beat
completion validity
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
`response_demux_matched_read_beat`, empty read-data residue, and
`response_demux.residue = [same_id_ordering]`.

`.291` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.292`, next mixed
dynamic/static frontier selection after generated mixed multi-beat output
banks. Multiple mixed transactions, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
backend-language variants, and VHDL remain later exact owners.
