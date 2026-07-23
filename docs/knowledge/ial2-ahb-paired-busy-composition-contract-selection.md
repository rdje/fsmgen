---
id: ial2-ahb-paired-busy-composition-contract-selection
title: One generic AHB paired BUSY composition has an exact implementation contract
answers:
  - "what paired AHB BUSY composition does IAL2-FEATURE-COMPLETENESS-FRONTIER.793 select?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.794 implement?"
  - "what is the source path for the paired AHB BUSY composition?"
  - "how will an AHB aggregate report requester busy_insertion?"
  - "what runtime proof is required for the paired AHB BUSY composition?"
  - "what support id covers the paired AHB BUSY composition?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, busy, composition, contract, report, runtime]
evidence: docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; ppif/ahb_requester_busy_insert.ppif; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/1498-ial2-ahb-requester-busy-insert.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park|intent.ppif_ahb_interconnect_requester_busy_insert|t/1513|busy_insertion|44332211' docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.793` selects `.794`, direct implementation
of generic source
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`.
It composes `amba_requester_busy_insert` with one HBURST-aware byte-lane
subordinate declaring `(parked-transfer busy)` and the existing `ahb_tb`
interconnect/top.

Support id is
`intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park`,
coverage is
`ial2_ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli`,
expected module `ahb_tb`, semantic root `top`. Accounting targets are 311
protocol and 352 supported-smoke/strict entries.

`AhbInterconnect::_child_report` conditionally clones the requester endpoint's
`busy_insertion` block. No top-level duplicate summary is selected: requester
child `busy_insertion` plus subordinate/aggregate `parks_on = [busy]` are the
canonical paired proof. Base aggregates remain unchanged.

Focused `t/1513` plus `t/data/ahb_paired_busy_composition_tb.svt` must prove
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, requester and
subordinate state/storage hold on BUSY, four accepted beats, OKAY completion,
zero remaining, and final little-endian register value `32'h44332211`. Generic
`.ppif` ships first; alias, two-subordinate sibling, broader BUSY/status/burst,
optional signals, backends, AXI/APB, and VHDL remain deferred. Decision `0020`
remains proposed/inactive.
