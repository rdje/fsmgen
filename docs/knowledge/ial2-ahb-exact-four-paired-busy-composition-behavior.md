---
id: ial2-ahb-exact-four-paired-busy-composition-behavior
title: Exact-four paired AHB BUSY generic and profile alias ship with semantic, MCP, and shared runtime proof
answers:
  - "does FSMGen ship an exact-four paired AHB BUSY composition?"
  - "what source pairs the exact-four requester with BUSY parking?"
  - "what does t1537 prove?"
  - "what does t1538 prove?"
  - "does the exact-four paired AHB profile alias ship?"
  - "does exact-four paired BUSY require a new generator?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, composition, semantics, mcp, runtime]
evidence: docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1537-ial2-ahb-exact-four-paired-busy-composition.t; t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t; t/data/ahb_exact_four_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -lv t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
---

The byte-identical `.ppif` and `.ahb` paths named
`ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park`
ship one three-child `ahb_tb` composition through existing generators. The
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

Focused t1538 proves alias byte/report/artifact/strict/schedule/normalized-
semantic/real read-only MCP/repository-local-output/HDL-verifier/diagnostic
parity in 4 top-level subtests and 88 nested assertions. It adds no testbench
or simulation; t1537 remains the shared assertion-enabled runtime.

Current accounting is 330 protocol fixtures, 371 supported-smoke/strict
fixtures, and 54 AHB IAL2 paths split 27 `.ppif` / 27 `.ahb`. The
two-subordinate exact-four topology remains separate.

Clean behavior commit `c42347a5e` activates no-behavior parent selector
`.824`; it must choose one exact next roadmap owner before further expansion.

Completed `.824` selected `.825`, activated only after clean selector commit
`5b601fffc`; `.825` now ships the byte-identical matching `.ahb` alias at
330/371/54. Fact
`ial2-post-exact-four-paired-composition-next-owner-selection` owns the exact
support and t1538/shared-t1537 boundary.

Clean alias behavior commit `40b8ead71` activates no-behavior selector `.826`
without changing the 330/371/54 boundary.

Completed `.826` selects proposed two-subordinate exact-four paired readiness
audit `.1` after strict/lowering/semantic/real-MCP/HDL feasibility. The audit,
not this selector, owns assertion-enabled two-command
10/8/2/8/2/`44332211`/`88776655` runtime before a public contract.

Completed two-window audit `.1` proves that exact runtime and selects pending
generic contract `.2`; the shipped one-window 330/371/54 boundary is
unchanged until a later implementation.

Contract `.2` now freezes the two-window generic source/support/t1539 boundary
at projected 331/372/55 split 28 `.ppif`/27 `.ahb` and selects pending
data-only implementation `.3`; no two-window source ships in selection.
