---
id: ial2-ahb-exact-four-paired-busy-composition-behavior
title: Exact-four paired AHB BUSY composition ships with assertion-enabled semantic and MCP proof
answers:
  - "does FSMGen ship an exact-four paired AHB BUSY composition?"
  - "what source pairs the exact-four requester with BUSY parking?"
  - "what does t1537 prove?"
  - "does exact-four paired BUSY require a new generator?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, composition, semantics, mcp, runtime]
evidence: docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1537-ial2-ahb-exact-four-paired-busy-composition.t; t/data/ahb_exact_four_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -lv t/1537-ial2-ahb-exact-four-paired-busy-composition.t
---

The generic source
`ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`
ships one three-child `ahb_tb` composition through existing generators. The
requester reports `before_beat=2`, `beats=4`, and width-three
`4 -> 3 -> 2 -> 1 -> 0` qualified retirement. The subordinate and aggregate
propagation report `parks_on=[busy]`; the fabric retains one-hot accepted-
subordinate response ownership.

Focused t1537 proves exact support, strict/check/schedule/artifact/verifier
surfaces, normalized semantic JSON, repo-relative real MCP with
`read_only=true` and `shell_access=false`, and assertion-enabled runtime totals
5 presentations / 4 beats / 1 BUSY episode / 4 qualified BUSY events / 1
resumed `SEQ` / storage `0x44332211`. Its temporary output is repository-local
and same-volume. No parser, generator algorithm, report API, feature-specific
MCP route, or simulator integration was added.

Current accounting is 329 protocol fixtures, 370 supported-smoke/strict
fixtures, and 53 AHB IAL2 paths split 27 `.ppif` / 26 `.ahb`. The matching
alias and two-subordinate exact-four topology remain separate.

Clean behavior commit `c42347a5e` activates no-behavior parent selector
`.824`; it must choose one exact next roadmap owner before further expansion.
