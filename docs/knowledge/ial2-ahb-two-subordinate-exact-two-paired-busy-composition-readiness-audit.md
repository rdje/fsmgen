---
id: ial2-ahb-two-subordinate-exact-two-paired-busy-composition-readiness-audit
title: Existing AHB generators safely compose exact-two requester BUSY with both parked subordinate windows
answers:
  - "can the exact-two AHB requester compose with two BUSY-parking subordinates?"
  - "is the two-subordinate exact-two paired BUSY composition ready?"
  - "what did IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.6 prove?"
  - "does exact-two BUSY preserve both AHB subordinate windows?"
  - "does the two-subordinate exact-two candidate work through semantic JSON and MCP?"
  - "does the two-subordinate exact-two pairing need a new generator?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, readiness, semantic, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: prove -Iperl t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
---

`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.6`
proves that the existing four-child AHB aggregate architecture safely combines
`amba_requester_busy_insert_two` with both status/control HBURST-aware
byte-lane subordinates. A disposable source changed only the requester object
and child reference and added `(busy-beats 2)`.

Schedule JSON reported four children, top `ahb_tb`, exact requester/status/
control/interconnect artifacts, status `[0,4)` and control `[4,8)` windows,
numeric requester `before_beat=2`/`beats=2`, both child and propagated
`parks_on=[busy]`, and retained one-hot data-phase ownership. Strict check,
normalized semantic JSON, and a real read-only `fsmgen_semantic_introspect`
call agreed on module/root/child count; the disposable source truthfully
reported unmatched support, and MCP retained `read_only=true` plus
`shell_access=false`.

Generated HDL passed two commands: exactly two qualified BUSY events and one
resumed SEQ per command, stable requester/selected-child/unselected-child/
interconnect ownership, no BUSY data completion, four beats per window, clean
status, and final status/control storage `44332211`/`88776655`. Observed totals
were `commands=2 transfers=10 beats=8 busy=2 qualified_busy=4 resumed_seq=2`.
No generator or semantic/MCP API repair is needed. Proposed `.7` owns
no-behavior generic public-contract selection; no public source ships from the
audit.
