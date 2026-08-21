---
id: ial2-ahb-arbitration-exact-three-paired-claim-evidence
title: AHB arbitration and exact-three paired claims retain distinct evidence
answers:
  - "how are Chapter 14i arbitration and exact-three paired claims verified?"
  - "which AHB arbitration counts are historical audit measurements?"
  - "how are one-window exact-three paired artifacts verified?"
  - "how is two-window exact-three paired runtime verified?"
  - "why are old AHB support totals not current accounting?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, arbitration, exact-three, paired, composition, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb;
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t;
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t;
  t/1530-ial2-ahb-interconnect-output-arbitration.t;
  t/1531-ial2-ahb-exact-three-paired-busy-composition.t;
  t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t;
  t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t;
  t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1519-ial2-ahb-pipelined-active-transfer-audit.t
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
  t/1530-ial2-ahb-interconnect-output-arbitration.t
  t/1531-ial2-ahb-exact-three-paired-busy-composition.t
  t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t
  t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t
  t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.9` reviews the exact 27 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1407 through
1661. Two candidates state current numeric behavior and use derived gates.
The other 25 candidates are pre-repair audit observations, selected contract
inputs, decision identifiers, projected support values, or shipment-time
support checkpoints and therefore use reviewed-incidental dispositions.

The current candidates remain separated into two evidence families:

- one-window exact-three paired topology, artifact, strict, semantic, and MCP
  behavior; and
- two-window exact-three assertion-enabled runtime behavior.

The ordinary requester, subordinate, and interconnect producers rederive both
families from tracked generic/profile sources. Focused t1531 independently
checks the three-child topology, exact 3 IAL1/4 IAL0 artifacts, strict and
schedule surfaces, normalized semantic JSON, real read-only MCP, HDL
verification, and assertion-enabled 5/4/1/3/1 runtime. Focused t1533 drives
both windows and checks 2 commands, 10 presentations, 8 beats, 2 BUSY
episodes, 6 qualified BUSY events, 2 resumed `SEQ` events, and final
`44332211`/`88776655` storage. t1532 and t1534 independently retain profile
alias parity without duplicating runtime simulation.

Arbitration stays in the exact no-regression collection even though its
inventory numerals describe immutable audit or contract history. t1530 proves
complementary one-/two-window interconnect output ownership, mapped-zero and
nonzero decode, retained responses, same-edge replacement, and two-cycle
unmapped ERROR with assertions enabled. t1519 and t1520 retain the generated
endpoint and direct-seed repairs, including final-ERROR capture versus IDLE
cancel and implicit-zero conditional overrides.

The time-40/time-345 failures, 8/10/20/20/20 conflict-target census, selected
five-write removal, and readiness/contract projections are retained at their
exact audit or selection commits. Shipment checkpoints from 323/364/47
through 326/367/50 likewise remain historical measurements; they are not
reclassified as current support-corpus totals.

Key durable commits are `c32255645adafcf88773f6c0965c86bde2159b2e`
(interconnect audit), `6eeac974c9471e3cb58cbaacd1ec999dd51f15b1`
(interconnect repair), `0dad690cb552efd7741494e7caee522f2784b97b`
(endpoint audit), `1eec6253d4dd69af8cfdc6b331073edd7768dcb1`
(endpoint repair), `35a6fbfcf51914b1b83a36c50296be5c05428b8a`
(direct-seed repair), `00d71114d5866d570ad11d37845ac48bf2b0ece7`
(one-window exact-three), and
`1a73bc65e6f2b445af6947ea6724c71801e85776` / `db402fd9d275bb1da5e3597b9a911a1d6afc3765`
(two-window generic/profile exact-three).
