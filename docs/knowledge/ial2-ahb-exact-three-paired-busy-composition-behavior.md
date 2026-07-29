---
id: ial2-ahb-exact-three-paired-busy-composition-behavior
title: Generic exact-three paired AHB BUSY composition ships with semantic and MCP parity
answers:
  - "does FSMGen ship an exact-three paired AHB BUSY composition?"
  - "what source pairs the exact-three requester with BUSY parking?"
  - "what does t1531 prove?"
  - "does exact-three paired BUSY require a new generator?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, composition, semantics, mcp, runtime]
evidence: docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; t/data/ahb_exact_three_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1531-ial2-ahb-exact-three-paired-busy-composition.t
---

`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`
ships one generic three-child `ahb_tb` composition through existing generators.
The requester reports `before_beat=2`, `beats=3`, and width-two
`3 -> 2 -> 1 -> 0` qualified retirement. The subordinate and aggregate
propagation report `parks_on=[busy]`; the fabric retains one-hot accepted-
subordinate response ownership.

Focused t/1531 proves strict/check/schedule/artifact/verifier parity,
normalized semantic JSON, real read-only shell-disabled MCP introspection, and
assertion-enabled runtime totals 5 presentations / 4 beats / 1 BUSY episode /
3 qualified BUSY events / 1 resumed `SEQ` / storage `0x44332211`. No parser,
generator algorithm, report API, or feature-specific MCP route was added.

Current accounting is 323 protocol fixtures, 364 supported-smoke/strict
fixtures, and 47 AHB IAL2 paths split 24 `.ppif` / 23 `.ahb`. The matching
alias and two-subordinate exact-three composition remain separately owned.
