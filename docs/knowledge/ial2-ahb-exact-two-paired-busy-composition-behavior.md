---
id: ial2-ahb-exact-two-paired-busy-composition-behavior
title: Generic exact-two paired AHB BUSY composition ships with semantic and MCP parity
answers:
  - "does FSMGen ship an exact-two paired AHB BUSY composition?"
  - "what source pairs the exact-two requester with BUSY parking?"
  - "what does t1523 prove?"
  - "does the exact-two paired source support semantic JSON and MCP introspection?"
  - "does exact-two paired BUSY require a new generator?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, semantics, mcp, runtime]
evidence: docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t; t/data/ahb_exact_two_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1523-ial2-ahb-exact-two-paired-busy-composition.t
---

`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`
ships one generic three-child `ahb_tb` composition. It reuses the exact-two
requester, HBURST-aware byte-lane BUSY-parking subordinate, interconnect, and
top generators; it is source data, not a new generator.

The requester child reports numeric `busy_insertion.beats=2`; the subordinate
and aggregate propagation report `parks_on=[busy]`. Focused t/1523 proves one
BUSY episode with exactly two qualified events, stable requester/subordinate/
interconnect ownership, counter progression two-to-one-to-zero, no BUSY data
completion, one resumed `SEQ`, four clean byte beats, and final storage
`32'h44332211`.

The same test proves strict check, schedule JSON, normalized semantic JSON, and
the real read-only `fsmgen_semantic_introspect` MCP adapter with shell access
disabled. No feature-specific MCP API or raw private payload was added. The
generic checkpoint was 317 protocol / 358 supported+strict / 41 AHB paths.
Follow-on `.5` shipped the matching alias at 318/359/42. The later
two-subordinate exact-two source/alias checkpoints reached 320/361/44. The
additive generic exact-three requester established 321/362/45, and its alias
established 322/363/46. The generic exact-three paired source established
323/364/47; its matching alias now moves current accounting to 324/365/48
split 24 `.ppif` / 24 `.ahb`. See
`IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR`.
