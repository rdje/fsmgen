---
id: ial2-ahb-foundational-claim-evidence
title: Foundational AHB numeric claims retain topology, HBURST, and BUSY evidence
answers:
  - "how are the foundational Chapter 14i AHB claims verified?"
  - "which early AHB numeric lines are current behavior versus chronology?"
  - "how are AHB child counts three and four verified?"
  - "how is one-word HBURST WRAP4 INCR4 behavior verified?"
  - "why are early AHB support totals historical measurements?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, interconnect, hburst, busy, profile-alias, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  ppif/ahb_interconnect.ppif;
  ppif/ahb_interconnect_byte_lane.ahb;
  ppif/ahb_interconnect_two_subordinate_byte_lane.ahb;
  ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif;
  ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb;
  t/1478-ial2-ahb-interconnect.t;
  t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t;
  t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t;
  t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t;
  t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1478-ial2-ahb-interconnect.t
  t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
  t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
  t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t
  t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t
  t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t
  t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t
  t/1498-ial2-ahb-requester-busy-insert.t
  t/1512-ial2-ahb-requester-busy-insert-profile-alias.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.7` reviews the exact 40 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1 through
1070. Seven candidates state current numeric behavior and use derived gates.
The other 33 candidates are immutable contract parameters, time-local support
milestones, or test/decision identifiers and therefore use reviewed-incidental
dispositions.

The current candidates remain separated into five evidence families:

- one-window AHB interconnect decode at base zero with size four;
- one- and two-subordinate aggregate byte-lane aliases with child counts three
  and four;
- byte-only `WRAP4`/`INCR4` `SEQ` inside one 32-bit register word;
- generic one- and two-subordinate aggregate BUSY parking with child counts
  three and four; and
- the matching aggregate BUSY-park profile aliases with the same topology.

The ordinary subordinate/interconnect generators and exact public fixtures
rederive each family. Focused oracles inspect source/report/support identity,
generated IAL1/IAL0/HDL artifacts, mapped and unmapped response policy,
local-address subtraction, narrow-transfer policy, HBURST progression,
`parks_on` versus `clears_on`, generic/alias parity, and profile-residue
suppression. Unsupported burst kinds, `SINGLE`-to-`SEQ`, unexpected address or
control changes, invalid parking without HBURST `SEQ`, missing children, and
generic/alias divergence remain separating RED paths.

Requester BUSY insertion and one-/two-subordinate paired BUSY runtime behavior
remain part of the exact no-regression collection. Their numeric candidate
lines in this range contain test identifiers or historical support totals,
not new current measurements; the current behavior is already watched by
`t/1498` and `t/1512` through `t/1516`.

Exact Git retention distinguishes selection-time inputs and shipment-time
accounting from current behavior. The key current shipments are commits
`ab4838dd5f22bc9ece4a1e34649af96167fe31e0` (`.723`),
`21215c2ce7f835cec54b62325e42b950e3d4a04d` (`.745`),
`3fb1cf7f40a4284ca44d9fe6c0130fc2c6662bab` (`.764`),
`43c48ecea23d33fa81e6e7d43eddc1ec1df60d66` (`.782`), and
`6cf029b3383222021a800c379e7d85dd0c348a9a` (`.784`). Historical support
checkpoints from 292/333 through 314/355 remain accurate at their named
commits but are not promises about the current corpus size.
