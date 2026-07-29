---
id: ial2-ahb-two-subordinate-exact-three-paired-busy-composition-behavior
title: FSMGen ships generic two-window exact-three paired AHB BUSY composition
answers:
  - "does FSMGen ship a two-subordinate exact-three paired AHB BUSY source?"
  - "what does t 1533 prove?"
  - "does two-window exact-three paired BUSY support semantic JSON and MCP?"
  - "what are the current AHB support counts after two-window exact-three pairing?"
  - "does two-window exact-three BUSY keep all selector assertions enabled?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, two-window, composition, behavior, runtime, semantic, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; t/data/ahb_two_subordinate_exact_three_paired_busy_composition_tb.svt
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t
---

FSMGen ships generic
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`
through existing generators. It preserves four-child `ahb_tb`, exact 4 IAL1/5
IAL0 artifacts, two static windows, width-two `3 -> 2 -> 1 -> 0`, requester
`before_beat=2`/`beats=3`, both child/propagated `parks_on=[busy]`, and one-hot
accepted-subordinate ownership.

Strict check, normalized semantic JSON, real read-only shell-disabled MCP, and
public `--verify-hdl` pass. Assertion-enabled t1533 proves 2 commands / 10
presentations / 8 beats / 2 BUSY episodes / 6 qualified BUSY events / 2 resumed
`SEQ` events / status `44332211` / control `88776655`, including stable selected,
unselected, and fabric state.

Its matching alias established 326/367/50. The generic exact-four requester
established 327/368/51; its matching alias now moves current accounting to 328
protocol / 369 supported+strict / 52 AHB paths split 26 `.ppif` / 26 `.ahb`.
Implementation `.821` ships the byte-identical
matching alias and shares t1533 assertion-enabled runtime. Broader BUSY,
HIAL/VIAL, VHDL, and verification-generation work remains separate.
