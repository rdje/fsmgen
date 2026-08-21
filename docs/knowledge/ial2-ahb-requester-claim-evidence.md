---
id: ial2-ahb-requester-claim-evidence
title: AHB requester shape and exact-one-through-four BUSY claims retain count-specific evidence
answers:
  - "how are AHB requester signal-width claims verified?"
  - "how are exact one through four AHB BUSY insertions verified?"
  - "why is an AHB BUSY presentation not an additional data beat?"
  - "how are AHB BUSY qualifier stalls and counter widths falsified?"
  - "which AHB requester support counts are current and which are historical?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, requester, busy, cardinality, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  perl/FSM/Support/LanguageSurfaceSection.pm;
  ppif/ahb_requester.ppif;
  ppif/ahb_requester_busy_insert.ppif;
  ppif/ahb_requester_busy_insert_two.ppif;
  ppif/ahb_requester_busy_insert_three.ppif;
  ppif/ahb_requester_busy_insert_four.ppif;
  t/1473-ial2-ahb-requester.t;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t;
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t;
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t;
  t/1521-ial2-ahb-requester-two-busy-insert.t;
  t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t;
  t/1528-ial2-ahb-requester-three-busy-insert.t;
  t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t;
  t/1535-ial2-ahb-requester-four-busy-insert.t;
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t;
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t;
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1473-ial2-ahb-requester.t
  t/1498-ial2-ahb-requester-busy-insert.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
  t/1521-ial2-ahb-requester-two-busy-insert.t
  t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t
  t/1528-ial2-ahb-requester-three-busy-insert.t
  t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t
  t/1535-ial2-ahb-requester-four-busy-insert.t
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t &&
  prove -Iperl t/248-regression-corpus-accounting.t
  t/297-capability-manifest.t t/1638-claim-verification-dispositions.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.2` reviews the exact 37 inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 1177 through 1656.
Seventeen current statements use derived gates. Twenty test locators,
shipment-time corpus totals, split counts, and proposed-contract references
use reviewed-incidental dispositions so they cannot masquerade as current
capability measurements.

The current candidates remain separated into eight evidence families:

- base requester field widths and bounded SINGLE/INCR4 completion;
- exact-one BUSY hold, qualification, resumed `SEQ`, and four data beats;
- one- and two-window exact-one paired ownership and runtime;
- canonical generalized count admission from 2 through 16;
- exact-two counter, qualifier-stall, runtime, and alias behavior;
- exact-three width-two counter, runtime, and alias behavior;
- exact-four width-three counter, runtime, and alias behavior; and
- exact-four paired artifact shape plus live support accounting.

The ordinary requester builder derives 32-bit address/data, three-bit size
and burst, four-bit protection, five-bit length/index/remaining, and two-bit
transfer/response fields. Its runtime oracles distinguish transfer
presentations from completed data beats: BUSY holds the pending beat and
counter state, and only an `HGRANT && HREADY` qualified BUSY edge retires a
BUSY event. Exact-two, -three, and -four suites directly observe `2 -> 1 ->
0`, `3 -> 2 -> 1 -> 0`, and `4 -> 3 -> 2 -> 1 -> 0`; 32-clock ready-low and
grant-low controls reject hidden retirement. The generalized oracle accepts
representative counts 5, 8, and 16 while rejecting zero, one, 17,
noncanonical, symbolic, expression, duplicate, and missing-prerequisite
forms.

The paired exact-one suites retain one qualified BUSY event per command,
exactly four completed data beats, and one-hot ownership across one- and
two-window generic/profile-alias sources. Exact-four paired suites retain
three IAL1 artifacts, four IAL0 artifacts, a width-three requester counter,
and generic/alias parity. The live support producers independently retain 332
protocol fixtures, 373 supported-plus-strict fixtures, and 56 AHB paths split
28 `.ppif` / 28 `.ahb`.

Historical shipment checkpoints remain attached to their exact commits:
`c224b2cbaf9921ed56c842a36df897fa2add1e33` (exact-three requester alias),
`00d71114d5866d570ad11d37845ac48bf2b0ece7` (exact-three paired generic),
`d94f303d804334cb083d510949f2ccb04a4ee938` (exact-three paired alias),
`ba2d1c01f7aa6e56d326518c82b6a04617fc7739` (exact-four requester alias),
and `40b8ead71c42c151328680cb3e64568837bb0c49` (one-window exact-four paired
alias). The proposed paired contract locator remains durable at
`c5fe2ad4120fd2b21141c0470a71a213641000a0`. These values document chronology;
the current behavior and support boundaries are rederived by the executable
gates above.
