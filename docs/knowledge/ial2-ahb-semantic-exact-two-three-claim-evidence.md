---
id: ial2-ahb-semantic-exact-two-three-claim-evidence
title: AHB semantic repairs and exact-two/three claims retain distinct evidence
answers:
  - "how are Chapter 14i semantic-repair and exact-two/three claims verified?"
  - "which AHB wrap and BUSY numeric lines are current behavior?"
  - "why is the old exact-three 2 through 3 bound historical?"
  - "how are exact-one two and three BUSY runtimes separated?"
  - "how are AHB phase-pipeline and direct-seed repairs regression tested?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, wrap, pipeline, busy, exact-two, exact-three, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  fsm/amba_requester.fsm;
  perl/FSM/Adapter/IAL2/PPIF.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  ppif/ahb_requester.ppif;
  ppif/ahb_requester_busy_insert.ppif;
  ppif/ahb_requester_busy_insert_two.ppif;
  ppif/ahb_requester_busy_insert_three.ppif;
  ppif/ahb_requester_busy_insert_three.ahb;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t;
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t;
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t;
  t/1517-ial2-ahb-requester-wrap-progression-audit.t;
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t;
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t;
  t/1521-ial2-ahb-requester-two-busy-insert.t;
  t/1528-ial2-ahb-requester-three-busy-insert.t;
  t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1498-ial2-ahb-requester-busy-insert.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
  t/1517-ial2-ahb-requester-wrap-progression-audit.t
  t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
  t/1521-ial2-ahb-requester-two-busy-insert.t
  t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t
  t/1523-ial2-ahb-exact-two-paired-busy-composition.t
  t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t
  t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
  t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t
  t/1528-ial2-ahb-requester-three-busy-insert.t
  t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.8` reviews the exact 49 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1071 through
1406. Eight candidates state current numeric behavior and use derived gates.
The other 41 candidates are audit observations, selected contract inputs,
test/decision identifiers, or time-local support checkpoints and therefore
use reviewed-incidental dispositions.

The current candidates remain separated into six evidence families:

- generated and direct requester fixed-wrap progression;
- direct requester exact-one qualified BUSY cardinality;
- generic/alias one-/two-window paired exact-one BUSY cardinality;
- direct requester exact-two BUSY runtime;
- direct requester exact-three BUSY runtime; and
- exact-three requester profile-alias parity and test structure.

The ordinary requester/subordinate/interconnect producers and exact public
fixtures rederive the current families. Focused oracles inspect accepted wrap
addresses, ready/grant qualification, private counter transitions, pending
ownership, data-beat exclusion during BUSY, resumed `SEQ`, final counts and
storage, source/report/artifact identity, normalized semantic JSON, read-only
MCP output, and generic/alias parity. Continuous, 32-clock ready-low, and
32-clock grant-low cases separate qualification from presentation time.

The exact phase-pipeline and direct-seed repair suites remain in the
no-regression collection even where the candidate numeral is only a test
identifier or an immutable pre-repair observation. They prove depth-one
completion-edge address/control capture, retained interconnect response owner,
final-ERROR active capture versus IDLE cancel, direct Q-named four-state
dispatch, and exact ERROR timing without treating old audit failures as
current behavior.

Shipment-time support values from 315/356/40 through 322/363/46 are retained
at their exact commits, not reclassified as current corpus totals. Likewise,
the original exact-three contract and shipment accepted only literal values
`2..3` at commits `5623b975af8a18337ddba3db8378db7697462d19` and
`325f21267de0a2a0caa8ec1bc96c4c9d26bacc4c`; later generalized behavior makes
the current canonical decimal bound `2..16`. Exact-three runtime and alias
parity remain current and separately executable.

Key repair and shipment commits are
`8ca20e4c4c208b53b1cd8dd5442b298a36505e03` (WRAP),
`3e1dcc9301c17355357e4760d71d5e16f5f84596` (generated phase pipeline),
`75d1070833b61cf7824b750a22c1ff091b9d1db4` (direct completion capture),
`a4cabc875c84e133dcba4f4131c793c3adbc0b23` (single BUSY),
`ed968926e605c328ff3a0e0a9620e2fd44b2f8a6` (exact two), and
`c224b2cbaf9921ed56c842a36df897fa2add1e33` (exact-three alias).
