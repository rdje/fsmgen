---
id: ial2-ahb-requester-generalized-busy-count-range-readiness-audit
title: A reusable literal AHB requester BUSY count range of 2 through 16 is ready for contract selection
answers:
  - "what BUSY count range follows exact four in the AHB requester?"
  - "why is 16 selected as the generalized AHB BUSY count maximum?"
  - "does AHB itself limit consecutive BUSY transfers to 16?"
  - "which BUSY counts were simulated in the generalized range audit?"
  - "what counter widths do AHB BUSY counts 5 8 and 16 use?"
  - "will FSMGen add a fixture for every AHB BUSY count?"
  - "what does IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1 select?"
  - "does the generalized BUSY range audit change current behavior?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, busy, count-range, readiness, runtime, verilator, mcp]
evidence: docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md; docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester_busy_insert_four.ppif; t/1535-ial2-ahb-requester-four-busy-insert.t; docs/IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'literal 2\.\.16|92 files|7,016,808|count 5|count 8|count 16|max_beats=16|qualified BUSY' docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_READINESS_AUDIT.md docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md
---

Audit `.1` selects proposed no-behavior contract `.2` for canonical literal
`busy-beats` values `2..16`, with absence remaining exact-one. Current public
behavior stays `2..4` until a later contract and implementation commit.

The repo-local Arm AHB specification constrains where BUSY occurs and requires
fixed-length bursts to finish with `SEQ`, but does not impose a numeric BUSY-
cycle maximum. Sixteen is therefore FSMGen's bounded-profile choice: it aligns
with the requester's declared `max_beats=16` design class and exercises the
existing five-bit local length/status boundary. Counts above 16 remain future
product expansion, not protocol-illegal behavior.

The lowerer is already generic. Counts 5, 8, and 16 derive widths 3, 4, and 5;
the qualified `>1` decrement and `==1` clear/resume rules contain no exact-four
branch. A 46-assertion disposable structural/report/real read-only MCP/
diagnostic probe passes. Generated all-assertion Verilator runtime passes count
5 continuous plus 32-clock ready/grant stalls, count 8 continuous, and count 16
continuous plus both stalls. Each run observes exactly N qualified BUSY events,
one episode, four data beats, stable pending state, one resumed `SEQ`, and zero
final count.

The 92-file/7,016,808-byte same-volume workspace was removed exactly. The
selected contract keeps existing source bytes and 332/373/56 split 28/28
support accounting unchanged and requires no catalog fixture per admitted
count. Dynamic/policy/random/symbolic counts, multiple insertion points,
generic priority, HIAL/VIAL, VHDL, scale, and decision `0020` remain separate.
