---
id: ial2-ahb-exact-four-generalized-repair-claim-evidence
title: AHB exact-four, generalized-range, and qualified-event claims retain distinct evidence
answers:
  - "how are Chapter 16c exact-four and generalized BUSY claims verified?"
  - "how is two-window exact-four AHB runtime verified?"
  - "how is the AHB requester 2 through 16 range verified?"
  - "how is single qualified BUSY-event repair verified?"
  - "why are repeated 332 373 56 AHB totals historical in Chapter 16c?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, exact-four, two-window, generalized-range, busy, repair, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  perl/FSM/Support/LanguageSurfaceSection.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_requester_busy_insert.ppif;
  ppif/ahb_requester_busy_insert_two.ppif;
  ppif/ahb_requester_busy_insert_four.ppif;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t;
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t;
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t;
  t/1521-ial2-ahb-requester-two-busy-insert.t;
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t;
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t;
  t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t;
  t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1498-ial2-ahb-requester-busy-insert.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
  t/1521-ial2-ahb-requester-two-busy-insert.t
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
  t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t
  t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t &&
  prove -Iperl t/1638-claim-verification-dispositions.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.5` reviews the exact 62 inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 2401 through 2640.
Fifteen candidates state current behavior and use derived gates. The other 47
candidates are readiness or contract inputs, projected totals, superseded
activation states, shipment checkpoints, repeated time-local AHB accounting,
or the historical pre-repair observation and therefore use reviewed-incidental
dispositions.

The current candidates remain separated into five evidence families:

- one-window exact-four profile-alias parity with t1537 as shared runtime;
- two-window exact-four generic topology, artifacts, semantic/MCP/verifier
  surfaces, and assertion-enabled 10/8/2/8/2 runtime;
- two-window profile-alias parity and independently derived live
  332/373/56 support accounting split 28 `.ppif` / 28 `.ahb`;
- canonical requester `busy-beats` values `2..16`, adjacent-invalid and
  malformed controls, minimum widths, no-count-specific-fixture behavior, and
  seven assertion-enabled 5/8/16 runtime scenarios; and
- repaired exact-one qualified-event cardinality through direct requester and
  paired one-/two-window paths, with exact-two requester behavior retained as
  an adjacent current control.

The guarded exact collection passes all 11 focused files at `Files=11,
Tests=47`. It proves one-window and two-window exact-four generic/profile
behavior, single-BUSY continuous and 32-clock ready/grant stalls, paired
qualified-event propagation, exact-two preservation, and the generalized
range plus zero/one/17/noncanonical/symbolic/expression/duplicate rejection.
The support/disposition collection independently passes `Files=3, Tests=7107`.

Readiness and contract values remain chronology even when the selected tuple
later became shipped behavior. The same applies to repeated 332/373/56 split
28/28 statements made while unrelated named-drive and direct-VHDL work
selected, activated, or shipped: those lines record exact time-local AHB
checkpoints, while one dedicated live-support gate and the generalized-range
gate rederive current accounting. The pre-repair ten-edge observation and
disposable 32-clock audit candidates remain historical evidence; current
single-event and paired behavior is rederived by t1498 and t1513 through
t1516.

Key durable commits are `40b8ead71c42c151328680cb3e64568837bb0c49`
(one-window alias), `a62ddb70593bb667b7fa36485107c7fb5a445b5f`
(two-window generic), `3519cde33e35d6f84e65af33dd7fe5d010539ee6`
(two-window alias), `2f64611ca41c8d78648358c0e7bdcf71ba7f6fe7`
(generalized range), `a4cabc875c84e133dcba4f4131c793c3adbc0b23`
(single-event repair), and `ed968926e605c328ff3a0e0a9620e2fd44b2f8a6`
(exact-two preservation).
