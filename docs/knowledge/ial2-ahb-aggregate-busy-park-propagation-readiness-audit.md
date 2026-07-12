---
id: ial2-ahb-aggregate-busy-park-propagation-readiness-audit
title: AHB aggregate BUSY-park propagation is ready; .780 audit selects a contract selection
answers:
  - "is aggregate AHB BUSY-park propagation ready to implement?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.780 select?"
  - "does the AHB interconnect need a generator change to propagate a child's parked BUSY?"
  - "how does the AHB interconnect compose a child subordinate that parks BUSY?"
  - "what contract is still open for aggregate AHB BUSY-park propagation?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, interconnect, aggregate, readiness, audit]
evidence: docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md; docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.780|IAL2-FEATURE-COMPLETENESS-FRONTIER\.781|AhbSubordinate->generate|_seq_policy_propagation_report|parked-transfer busy|BUSY-in-burst handling' docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.780` audits bounded aggregate AHB
BUSY-parking propagation readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.781`, a no-behavior public contract
selection for the aggregate BUSY-park source(s). Direct implementation is not
selected: the machinery is ready, but the source-stem / support-identity /
residue contract is still open.

The aggregate is more ready than the endpoint was before `.774`. The interconnect
composes child subordinate FSMs by calling `AhbSubordinate->generate($_)` per
child (`AhbInterconnect.pm:38`–`41`) and composing the results into a
`(?fsmc:...)` top (`:585`–`588`), so a child declared with `(parked-transfer
busy)` parks BUSY through the exact endpoint machinery shipped in `.776` with no
interconnect generator change. `_seq_policy_propagation_report` clones each child
`seq_policy` verbatim (`AhbInterconnect.pm:1177`, `:1207`), so the child's
`parks_on = [busy]` and BUSY-free `clears_on` surface on the aggregate report
with no new interconnect field. The `(parked-transfer busy)` vocabulary and its
parser/report support already live in the shared `AhbSubordinate` child path, and
the child `seq_ok_base` fail-closed path carries through composition unchanged.

The bounded behavior delta is new aggregate stem(s) whose child transfer uses
`(ignored-transfer idle)` + `(parked-transfer busy)`, plus narrowing the
aggregate residue at `AhbInterconnect.pm:1401` (drop `BUSY-in-burst handling`
from the HBURST variant). `.781` must settle the stem name(s)
(`ahb_interconnect_byte_lane_hburst_seq_busy_park` and whether the
two-subordinate sibling ships in the same slice), per-stem support identity /
coverage key / source kind / generated artifact names (HDL entry `ahb_tb`),
residue narrowing scope, focused test shape, `t/248`/`t/297` deltas, and the
later matching aggregate `.ahb` alias. Requester-side BUSY insertion (the
requester never drives bus `HTRANS = BUSY`; `AhbRequester.pm:473`), halfword/word
burst `SEQ`, wider/indefinite bursts, multi-word/register-bank progression, and
optional/property-gated AHB signals are larger and remain deferred.
