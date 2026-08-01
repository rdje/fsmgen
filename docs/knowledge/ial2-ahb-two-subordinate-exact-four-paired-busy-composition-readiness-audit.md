---
id: ial2-ahb-two-subordinate-exact-four-paired-busy-composition-readiness-audit
title: Two-window exact-four paired AHB BUSY composes directly with all assertions
answers:
  - "is two-subordinate exact-four paired AHB BUSY implementation-ready?"
  - "what does the two-window exact-four paired BUSY runtime audit prove?"
  - "does two-window exact-four require a lower-layer repair?"
  - "does two-window exact-four support normalized semantic JSON and MCP?"
  - "what support counts are projected for generic two-window exact-four AHB?"
  - "what runtime follows exact-four BUSY across both AHB windows?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, two-subordinate, runtime, readiness, semantics, mcp]
evidence: >-
  docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; t/1537-ial2-ahb-exact-four-paired-busy-composition.t;
  t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t t/1537-ial2-ahb-exact-four-paired-busy-composition.t
---

A repository-derived two-window candidate selects shipped
`amba_requester_busy_insert_four`, existing status/control byte-lane/HBURST-
SEQ/BUSY-parking subordinates, and existing interconnect. Strict check, exact
4 IAL1/5 IAL0 artifacts, normalized semantic JSON, real repo-relative read-
only shell-disabled MCP, and public HDL verification pass with unmatched
disposable support.

Verilator 5.046 compiles with `--timing`, `-j 1`, and all generated assertions
enabled. Runtime proves 2 commands / 10 presentations / 8 beats / 2 BUSY
episodes / 8 qualified BUSY events / two internal `4 -> 3 -> 2 -> 1 -> 0`
retirements / 2 resumed `SEQ` / status `0x44332211` / control `0x88776655`,
with selected, unselected, requester, and fabric ownership held through BUSY.

No lower-layer repair or semantic/MCP API change is required. The audit
selects a separate generic public-contract leaf with projected 331 protocol /
372 supported+strict / 55 AHB paths split 28 `.ppif` / 27 `.ahb`. Alias,
counts above four, broader BUSY semantics, HIAL/VIAL, VHDL, verification
generation, portability, scale, and decision `0020` remain separate.

Clean audit commit `a5d162d60` activates only contract selector `.2`. This
continuity-only activation leaves public accounting at 330/371/54 split 27
`.ppif`/27 `.ahb`; the future source, support entry, t1539, and testbench remain
absent while `.2` freezes their exact contract.

Contract `.2` now freezes one topology-first generic source, its exact
support/coverage identity, four IAL1/five IAL0 artifacts, normalized semantic/
read-only-MCP parity, assertion-enabled t1539 runtime, preservation gates, and
rollback at projected 331/372/55 split 28 `.ppif`/27 `.ahb`. Pending `.3`
owns implementation; selection ships no public behavior.

Completed `.3` now ships the selected generic path. t1539 proves the exact
strict/artifact/semantic/read-only-MCP/verifier/diagnostic/runtime contract.
Parent `.828` later ships the matching byte-identical alias with t1540 parity
and no second simulation; current accounting is 332/373/56 split 28 `.ppif`/
28 `.ahb`.
