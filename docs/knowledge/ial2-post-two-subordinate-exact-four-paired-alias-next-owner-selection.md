---
id: ial2-post-two-subordinate-exact-four-paired-alias-next-owner-selection
title: Generalized literal AHB requester BUSY-count readiness follows the completed exact-one-through-four family
answers:
  - "what follows the two-subordinate exact-four paired AHB alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.829 select?"
  - "are AHB requester BUSY counts above four selected next?"
  - "why not add an exact-five AHB fixture next?"
  - "does the AHB requester counter already derive widths above four?"
  - "what must the generalized BUSY count-range audit decide?"
  - "does the post-exact-four selector activate HIAL or VIAL?"
  - "does generalized BUSY count selection change public behavior?"
date: 2026-07-30
status: current
tags: [ial2, ahb, requester, busy, generalized-count, range, selector, hial, vial]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester_busy_insert_four.ppif; t/1535-ial2-ahb-requester-four-busy-insert.t; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md; docs/decisions/0020-ial2-layered-composable-transactor-roles.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.829|GENERALIZED-BUSY-COUNT-RANGE|literal integer in 2\.\.4|5=>3|332/373/56' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
---

Parent selector `.829` selects proposed
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1` after the
complete exact-one-through-four requester and paired generic/profile cadence
reaches 332 protocol / 373 supported-smoke plus strict / 56 AHB paths split 28
`.ppif` / 28 `.ahb`.

An in-memory exact-five source transform fails only at the current literal
`2..4` admission diagnostic. Existing integer-loop width derivation returns
width 3 for counts 5/7, width 4 for 8/15, and width 5 for 16/31; qualified
retirement rules have no exact-four control-flow branch. Public normalization,
static-rule reporting, residue wording, safe upper bound, assertion runtime,
diagnostics, and stable representative coverage remain unproved.

The selected no-behavior audit must choose the reusable finite literal range
from evidence rather than preselecting an arbitrary maximum. It must exercise
the first count above four and relevant width transitions, prove exact
grant-and-ready-qualified retirement plus stalls and one resumed `SEQ`, and
decide whether the public widening can ship without a catalog fixture for each
count. An exact-five-only fixture cadence is not selected.

Runtime/policy/random/symbolic counts, multiple insertion points, generic
rule/transaction priority, HIAL/VIAL, verification generation, VHDL,
portability, scale, other protocols/backends, and decision `0020` remain
separate. Selection changes no behavior; 332/373/56 split 28/28 remains current.

Clean selector commit `a2750d8a6` activates only generalized-count audit `.1`.
Activation is continuity-only; literal `2..4` and current accounting remain
unchanged while the audit determines the finite range and proof contract.

Completed audit `.1` selects proposed no-behavior contract `.2` for future
canonical literal `2..16`. Current `2..4` and 332/373/56 split 28/28 remain
unchanged until later implementation.

Clean audit commit `18f63a971` activates only contract `.2`; current behavior
and accounting remain unchanged.

Completed contract `.2` selects proposed lowerer/test-only `.3`; no per-count
public fixture is selected and current accounting remains unchanged.

Clean contract commit `7e2b436cf` activates only `.3`; current behavior and
accounting remain unchanged.

Implementation `.3` now ships the selected canonical decimal `2..16` range
with t1541 assertion/semantic/MCP/verifier proof and unchanged 332/373/56 split
28/28. Proposed parent selector `.830` owns the next clean-boundary comparison.

Clean behavior commit `2f64611ca` activates `.830` without changing public or
generated behavior.
