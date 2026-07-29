---
id: ial2-ahb-exact-three-paired-busy-composition-behavior
title: Exact-three paired AHB BUSY composition and profile alias ship with semantic and MCP parity
answers:
  - "does FSMGen ship an exact-three paired AHB BUSY composition?"
  - "what source pairs the exact-three requester with BUSY parking?"
  - "what does t1531 prove?"
  - "does exact-three paired BUSY require a new generator?"
  - "does the exact-three paired AHB profile alias ship?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, composition, semantics, mcp, runtime]
evidence: docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t; t/data/ahb_exact_three_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t
---

The byte-identical `.ppif` and `.ahb` paths named
`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`
ship one three-child `ahb_tb` composition through existing generators.
The requester reports `before_beat=2`, `beats=3`, and width-two
`3 -> 2 -> 1 -> 0` qualified retirement. The subordinate and aggregate
propagation report `parks_on=[busy]`; the fabric retains one-hot accepted-
subordinate response ownership.

Focused t/1531 proves strict/check/schedule/artifact/verifier parity,
normalized semantic JSON, real read-only shell-disabled MCP introspection, and
assertion-enabled runtime totals 5 presentations / 4 beats / 1 BUSY episode /
3 qualified BUSY events / 1 resumed `SEQ` / storage `0x44332211`. No parser,
generator algorithm, report API, or feature-specific MCP route was added.

Focused t/1532 proves alias byte/report/artifact/strict/schedule/semantic/MCP/
repository-local-output/HDL-verifier parity without duplicating t/1531
runtime. The later generic two-subordinate exact-three paired source established
325/366/49; its matching alias established 326/367/50. The later generic
exact-four requester moves current accounting to 327 protocol fixtures, 368
supported-smoke/strict fixtures, and 51 AHB IAL2 paths split 26 `.ppif` / 25
`.ahb`.
