---
id: ial2-ahb-aggregate-busy-park-propagation-behavior
title: AHB aggregate BUSY-park HBURST SEQ PPIF propagation behavior shipped
answers:
  - "does FSMGen ship AHB aggregate BUSY-in-burst parking propagation?"
  - "what does ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif generate?"
  - "what does ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif generate?"
  - "how does the aggregate interconnect propagate a child (parked-transfer busy)?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy-park, aggregate, interconnect, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.782` ships generic `.ppif` AHB aggregate
HBURST-aware byte-lane `SEQ` propagation with BUSY-in-burst parking through
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` (child count 3) and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`
(child count 4).

Each source is a byte-for-byte copy of the shipped aggregate HBURST `SEQ`
source with every inlined child transfer's `(ignored-transfer busy)` replaced by
`(parked-transfer busy)` (keeping `(ignored-transfer idle)`), so each embedded
subordinate holds the in-word `SEQ` burst context across an accepted
`HTRANS=BUSY` beat instead of clearing it. Both lower through generated `.isf`
before generated `.fsm` and select HDL module `ahb_tb`.

No interconnect parser/generator/report code changed: the `(parked-transfer
busy)` machinery lives in the shared `AhbSubordinate` child role, and
`_seq_policy_propagation_report` clones each child `seq_policy` verbatim
(`AhbInterconnect.pm:1177`/`:1207`), so `composition.seq_policy_propagation`
reports `parks_on = [busy]` and a BUSY-free `clears_on` per child automatically.
The only code change is narrowing the aggregate `ahb_burst_seq_support_deferred`
HBURST residue at `AhbInterconnect.pm:1401`, gated on
`_all_subordinates_park_busy($contract)`, to record shipped BUSY-in-burst
parking; the non-parking aggregate HBURST sources keep `BUSY-in-burst handling`
deferred, and the base non-HBURST aggregate residue is untouched.

Support-accounted as `intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`
and `intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`.
Focused coverage `t/1496`; `t/248` moved to 295 protocol / 336 total. The
matching aggregate BUSY-park `.ahb` aliases remain deferred to a later slice.
