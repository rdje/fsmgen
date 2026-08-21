---
id: ial2-ahb-exact-four-requester-paired-claim-evidence
title: AHB exact-four requester and paired claims retain distinct evidence
answers:
  - "how are Chapter 14i exact-four requester and paired claims verified?"
  - "why is the old exact-four literal range 2 through 4 historical?"
  - "how is the minimum exact-four BUSY counter width verified?"
  - "how is exact-four paired AHB runtime verified?"
  - "which exact-four support totals are shipment checkpoints?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, requester, busy, exact-four, paired, composition, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  ppif/ahb_requester_busy_insert_four.ppif;
  ppif/ahb_requester_busy_insert_four.ahb;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb;
  t/1535-ial2-ahb-requester-four-busy-insert.t;
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t;
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t;
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1535-ial2-ahb-requester-four-busy-insert.t
  t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t
  t/1537-ial2-ahb-exact-four-paired-busy-composition.t
  t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.10` reviews the exact 35 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1662 through
1779. Five candidates state current numeric behavior and use derived gates.
The other 30 candidates are disposable probe measurements, readiness or
contract inputs, projected support values, shipment checkpoints, or removed
workspace measurements and therefore use reviewed-incidental dispositions.

The current candidates remain separated into three evidence families:

- exact-four requester minimum counter width and assertion-enabled runtime;
- one-window exact-four paired topology, artifacts, semantic/MCP surfaces,
  and assertion-enabled runtime; and
- one-window exact-four paired profile-alias parity.

The requester producer derives width-three state for literal four while
preserving width-two state for exact two and three. Focused t1535 inspects the
generated counter and exact `4 -> 3 -> 2 -> 1 -> 0` qualified retirement under
continuous, 32-clock ready-low, and 32-clock grant-low cases. It also checks
stable pending ownership, resumed `SEQ`, older exact-two/three behavior, and
zero/one/17/symbolic/duplicate controls. Current generalized normalization is
canonical decimal `2..16`; the original exact-four `2..4` selection and
shipment remain immutable chronology rather than a current range limit.

The ordinary requester, subordinate, and interconnect producers rederive the
one-window paired family. Focused t1537 independently checks exact 3 IAL1/4
IAL0 artifacts, strict and schedule surfaces, normalized semantic JSON, real
read-only MCP, HDL verification, one-hot response ownership, BUSY parking,
assertion-enabled 5/4/1/4/1 runtime, and final `44332211` storage. Focused
t1538 proves the byte-identical profile alias through 4 top-level subtests and
88 nested assertions without a second simulation.

The one-file/2,313-byte failing transform, disposable readiness runtimes, and
the unsupported two-window 11-file/2,180,377-byte workspace remain at their
exact historical commits. Projected and shipment checkpoints from 327/368/51
through 331/372/55 likewise remain structural or historical records, not
current support-corpus totals. The selected two-window runtime after line
1779 belongs to the next bounded candidate slice.

Key durable commits are `74d91347e5bb967fd72c441014e90c3693a405ab`
(requester readiness), `95bfb7e4b7a51e1a2f18c881f9aa6bcc7ffbc2bd`
(generic requester), `ba2d1c01f7aa6e56d326518c82b6a04617fc7739`
(requester alias), `19772adec1fe5835f70b6b95c5530ad83f7c1aff`
(paired readiness), `c42347a5ea01ab781f7a6c30b3adfd413174b37f`
(paired generic), and `40b8ead71c42c151328680cb3e64568837bb0c49`
(paired alias).
