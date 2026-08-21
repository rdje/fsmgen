---
id: ial2-ahb-direct-exact-count-claim-evidence
title: AHB direct-seed and exact-count progression claims separate current gates from shipment chronology
answers:
  - "how are direct AHB seed and exact-count progression claims verified?"
  - "which exact-three and exact-four AHB runtime claims are current?"
  - "why are projected AHB support totals reviewed rather than gated?"
  - "how are AHB readiness and contract measurements separated from shipped behavior?"
  - "which tests retain exact-three and exact-four generic and alias behavior?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, direct-seed, exact-three, exact-four, runtime, shipment, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  fsm/ahb_lite_subordinate.fsm;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_requester_busy_insert_four.ppif;
  ppif/ahb_requester_busy_insert_four.ahb;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb;
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t;
  t/1531-ial2-ahb-exact-three-paired-busy-composition.t;
  t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t;
  t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t;
  t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t;
  t/1535-ial2-ahb-requester-four-busy-insert.t;
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t;
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t;
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
  t/1531-ial2-ahb-exact-three-paired-busy-composition.t
  t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t
  t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t
  t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t
  t/1535-ial2-ahb-requester-four-busy-insert.t
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.4` reviews the exact 71 inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 2038 through 2400. Six
current two-window exact-three, exact-four requester, and one-window exact-four
paired statements use derived gates. Sixty-five direct-seed chronology,
test/task locators, readiness results, selected contract values, disposable
candidates, projected totals, and shipment checkpoints use reviewed-incidental
dispositions.

The six current records deliberately reuse three independently falsifiable
evidence families:

- the two-window exact-three generic/profile pair, exact 4 IAL1/5 IAL0
  topology, normalized semantic/read-only-MCP surfaces, and assertion-enabled
  10/8/2/6/2 runtime;
- the exact-four requester generic/profile pair, minimum-width state, semantic/
  MCP/verifier surfaces, and continuous/32-ready-low/32-grant-low behavior; and
- the one-window exact-four paired generic/profile pair and assertion-enabled
  5/4/1/4/1/`44332211` runtime.

The guarded exact collection passes all nine focused files at `Files=9,
Tests=34`. It keeps the direct Q-named completion repair, exact-three one- and
two-window generic/profile behavior, exact-four requester generic/profile
behavior, and exact-four one-window generic/profile behavior executable in one
run. The claim records do not turn the `t1520` through `t1538` locators into
additional measurements.

Readiness and contract values remain chronology even where the selected tuple
later became shipped behavior. In particular, pre-shipment 5/4/1/3/1,
10/8/2/6/2, 4->3->2->1->0, and 5/4/1/4/1 results retain their exact audit or
contract commits, while current behavior is rederived from tracked public
sources and focused oracles. Likewise, 323/364/47 through 329/370/53 support
boundaries, their `.ppif`/`.ahb` splits, and the 4,978-byte disposable alias
candidate are time-local records rather than current support or output-size
promises.

The direct-seed candidates in this range make the same distinction. The
IDLE-only dropped completion-edge phase is explicitly pre-`.8`; `.8` and
`t/1520` are work-unit and test locators. The current Q-named repair and
assertion-clean arbitration remain executable through `t/1520`, while the
candidate dispositions preserve the earlier failure as history instead of
reopening it as a current defect.
