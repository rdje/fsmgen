---
id: ial2-ahb-requester-generalized-busy-count-range-contract-selection
title: The generalized AHB requester BUSY count contract widens one lowerer to canonical literals 2 through 16
answers:
  - "what does the generalized AHB BUSY count contract select?"
  - "which AHB requester busy-beats values will be accepted after implementation?"
  - "what is the exact future AHB requester busy-beats diagnostic?"
  - "will generalized AHB BUSY counts add one public fixture per count?"
  - "which files may the generalized AHB BUSY count implementation change?"
  - "what test owns generalized AHB requester BUSY counts 5 8 and 16?"
  - "what same-volume test gap was found in t1535?"
  - "what does IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.2 select?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, busy, count-range, contract, verification, locality]
evidence: docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_READINESS_AUDIT.md; docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1535-ial2-ahb-requester-four-busy-insert.t; docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'canonical decimal literal integer in 2\.\.16|t/1541|08dcdbc107b89a0e6733d8764660d58d7bd4f359|332/373/56|File::Temp' docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md t/1535-ial2-ahb-requester-four-busy-insert.t
---

Completed contract `.2` selects one future `AhbRequester` widening from
literal `2..4` to canonical unsigned decimal literals `2..16`. Absence remains
exact-one. The implementation adds no count-specific source or support entry,
so accounting remains 332/373/56 split 28 `.ppif` / 28 `.ahb`.

Proposed `.3` changes only normalizer admission, static-rule wording, unified
numeric residue, and focused verification. The current integer-loop width and
qualified retirement logic stay unchanged. New t1541 plus one generic
assertion-enabled testbench own boundary coverage and 5/8/16 runtime.
Malformed scalar tokens receive the exact canonical-range diagnostic; nested
reference/expression forms fail earlier at the PPIF scalar-shape gate.

Contract review first found that t1535 still created two default `File::Temp`
workspaces without a repository-derived `DIR`. Implementation review expanded
that finding across all eight touched exact-one through exact-four requester
generic/profile tests; they now use `FSM::ProjectDataLocality` explicit
workspaces and subprocess temp roots. The four paired generic/profile tests
also configure subprocess temp roots. This remains verification-local.

Implementation `.3` now ships canonical decimal literal `2..16` with focused
t1541 proof and unchanged 332/373/56 split 28/28 accounting. Canonical current
behavior lives in the generalized-count behavior record/fact.
Dynamic/policy/runtime/random/symbolic counts, multiple insertion points,
generic priority, HIAL/VIAL, VHDL, scale, and decision `0020` remain separate.

Clean contract commit `7e2b436cf` activates only `.3`; activation is
continuity-only and leaves current behavior and accounting unchanged.
