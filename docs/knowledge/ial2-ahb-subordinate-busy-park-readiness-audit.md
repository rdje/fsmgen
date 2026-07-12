---
id: ial2-ahb-subordinate-busy-park-readiness-audit
title: AHB subordinate BUSY-in-burst parking readiness audit selects a contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.774 audit and select?"
  - "is AHB subordinate BUSY-in-burst parking ready for direct implementation?"
  - "how does the shipped AHB subordinate treat an HTRANS=BUSY beat mid-burst?"
  - "does the shipped AHB requester emit HTRANS=BUSY on the bus?"
  - "what is the bounded behavior delta for AHB BUSY-in-burst parking?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, subordinate, readiness-audit]
evidence: docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT.md; docs/IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.774|IAL2-FEATURE-COMPLETENESS-FRONTIER\.775|ignored-transfer busy|ahb_seq_idle_clear|parked-transfer|parks_on|local_status.busy' docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.774` audits bounded AHB subordinate
BUSY-in-burst parking readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.775`, a no-behavior public contract
selection for the endpoint BUSY-parking source. Direct implementation is not
selected because the public contract surface is open.

Findings: the endpoint burst-context state already exists (`seq_valid_q`,
`seq_expected_addr_q`, `seq_size_q`, `seq_write_q`, `seq_hburst_q`,
`seq_beats_remaining_q`) so parking needs no new register or counter. Today the
source declares `(ignored-transfer busy)` and the generator clears the burst
history on IDLE or BUSY (`ahb_seq_idle_clear` fires on `(| idle busy)` at
`AhbSubordinate.pm:710`; report `clears_on` lists `busy` at `:989`). Because
unassigned registers hold their value, the minimal parking behavior is to stop
the clear from firing on BUSY. The shipped requester does not emit `HTRANS=BUSY`
on the bus — its `local_status.busy` (`AhbRequester.pm:473`) is an internal
status flag — so BUSY-parking is a subordinate-side capability verified by
driving `HTRANS=BUSY` stimulus into the standalone subordinate; requester-side
BUSY insertion stays deferred.

`.775` must settle the source path/identity, in-place widening versus a new
additive `*_busy_park` source stem, the `.ppif` declaration for "BUSY parks"
(e.g. `(parked-transfer busy)` or a `busy-parks` seq-policy flag), the
transaction/fail-closed shape, the report change (`clears_on` minus `busy`, plus
`parks_on`/`holds_on`), residue narrowing, tests, and later `.ahb`-alias and
aggregate sequencing.
