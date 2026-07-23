---
id: ial2-post-two-subordinate-paired-busy-alias-next-owner-selection
title: Post paired-BUSY-family selection prioritizes the AHB requester WRAP progression audit
answers:
  - "what follows the complete one- and two-subordinate paired AHB BUSY family?"
  - "which AHB task is selected after IAL2-FEATURE-COMPLETENESS-FRONTIER.803?"
  - "why is requester WRAP progression audited before more AHB features?"
  - "is the AHB requester WRAP progression defect proven?"
  - "does IAL2-FEATURE-COMPLETENESS-FRONTIER.804 activate the WRAP audit?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, wrap, correctness, audit, selection]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; fsm/amba_requester.fsm; t/1498-ial2-ahb-requester-busy-insert.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'wrap_mode_q|wrap_base_q|wrap_high_q|addr_step_q' perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm fsm/amba_requester.fsm && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.804|IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT' docs/IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.md docs/TASK_TREE.md MEMORY.md
---

After the one- and two-subordinate paired BUSY `.ppif`/`.ahb` families
completed, `.804` selected the existing
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT` as the next exact AHB owner. The
current generator and emitted IAL0 FSM contain two sequential `when` clauses:
the first may set `addr_q` to `wrap_base_q`, and the second may re-evaluate the
mutated address and overwrite it with `wrap_base_q + addr_step_q`.

This is a concrete source/FSM risk, not yet a runtime-proven defect. No current
generated-HDL requester test records a `WRAP4` accepted-address sequence through
the boundary. The selected audit must prove or disprove that sequence before
any repair, and any confirmed repair gets its own exact leaf.

`.804` does not activate the proposed audit while its own selector changes are
uncommitted. The pivot may occur only after `.804` commits and the repository
is clean. Policy/multiple BUSY, distinct bus-BUSY status, larger bursts,
boundary-free pipelining, optional signals, decision `0020`, and the
transaction-layer horizon remain deferred or proposed.
