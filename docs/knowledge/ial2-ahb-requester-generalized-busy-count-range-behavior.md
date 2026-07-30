---
id: ial2-ahb-requester-generalized-busy-count-range-behavior
title: AHB requester busy-beats now accepts canonical decimal literals 2 through 16
answers:
  - "which AHB requester busy-beats values are shipped now?"
  - "does omitting AHB requester busy-beats still mean one BUSY event?"
  - "what widths do shipped AHB requester BUSY counts use?"
  - "are AHB requester BUSY counts 5 8 and 16 runtime tested?"
  - "does generalized AHB BUSY count support add a fixture for every count?"
  - "what is the shipped AHB requester busy-beats diagnostic?"
  - "did generalized BUSY count support change AHB support accounting?"
  - "which BUSY-count tests now use repository-local temporary storage?"
  - "what did IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3 ship?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, busy, count-range, behavior, verilator, mcp, locality]
evidence: docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_CONTRACT_SELECTION.md; docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1541-ial2-ahb-requester-generalized-busy-count-range.t; t/data/ahb_requester_generalized_busy_count_tb.svt; t/1535-ial2-ahb-requester-four-busy-insert.t; docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md; ROADMAP_V2.md; docs/book/src/16c-ial2-ahb.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove t/1541-ial2-ahb-requester-generalized-busy-count-range.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

Implementation `.3` ships canonical unsigned decimal `busy-beats` literals
`2..16`; absence remains exact-one. The existing integer-loop width and
qualified `>1`/`==1` retirement logic are unchanged. Reports use numeric counts
for explicit values and unified numeric residue.

Focused t1541 proves parse/report/schedule/artifact/semantic/real read-only
MCP/public-verifier surfaces and seven assertion-enabled 5/8/16 runtime
scenarios. There is no public fixture or support entry per count, so existing
source bytes and 332/373/56 split 28 `.ppif` / 28 `.ahb` accounting remain
unchanged.

All exact-one-through-four requester generic/profile tests touched by the
shared report change now use `FSM::ProjectDataLocality` for explicit
repository-local workspaces and subprocess temp configuration. The four
exact-four paired generic/profile tests configure subprocess temp roots too.
Focused runs leave `.artifacts/tmp/tests` empty.

Counts above 16, symbolic/policy/runtime/random count selection, multiple
insertion points, generic priority, HIAL/VIAL, VHDL, scale, and decision `0020`
remain separate.
