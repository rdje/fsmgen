---
id: ial2-ahb-exact-two-paired-busy-composition-readiness-audit
title: Exact-two requester BUSY composes cleanly with one BUSY-parking subordinate
answers:
  - "is exact-two paired AHB BUSY composition implementation-ready?"
  - "does exact-two requester BUSY preserve subordinate parking state?"
  - "what does the exact-two paired BUSY runtime audit prove?"
  - "does exact-two paired BUSY need a generator repair?"
  - "will exact-two paired BUSY semantic introspection use MCP?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, runtime, readiness, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_requester_busy_insert_two.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1521-ial2-ahb-requester-two-busy-insert.t; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1513-ial2-ahb-paired-busy-composition.t t/1521-ial2-ahb-requester-two-busy-insert.t
---

A disposable candidate that changes the shipped one-subordinate exact-one
paired source only to select `amba_requester_busy_insert_two` and add
`(busy-beats 2)` generates through the existing three-child `ahb_tb` pipeline.
It retains numeric requester-child `busy_insertion.beats=2` and subordinate plus
aggregate `parks_on=[busy]`.

Generated-HDL runtime proves one BUSY transition episode with exactly two
qualified BUSY events, stable requester pending fields and beat counters,
stable subordinate continuation/phase/storage and interconnect data ownership,
one resumed `SEQ`, four data beats, clean status, and final storage
`32'h44332211`. Existing t/1513 and assertion-enabled t/1521 pass together.

No lower-layer repair or new generator is required. The audit selects a
separate no-behavior public contract leaf for one generic source before an
alias. Any future support-accounted source must use the existing strict
check/schedule/normalized-semantic-JSON/read-only
`fsmgen_semantic_introspect` contract, without a feature-specific API or raw
private internals. Two-subordinate exact-two composition and broader BUSY work
remain separate.
