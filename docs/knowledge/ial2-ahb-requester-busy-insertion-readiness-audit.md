---
id: ial2-ahb-requester-busy-insertion-readiness-audit
title: AHB requester BUSY-beat insertion machinery is ready; .786 audit selects a contract selection
answers:
  - "is requester-side AHB BUSY-beat insertion ready to implement?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.786 select?"
  - "how would the AHB requester drive HTRANS=BUSY mid-burst?"
  - "does the AHB subordinate need a change to receive a requester-driven BUSY beat?"
  - "what contract is still open for requester-side AHB BUSY insertion?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.787?"
date: 2026-07-12
status: current
tags: [ial2, ahb, requester, busy, insertion, htrans, burst, readiness, audit, task-tree]
evidence: docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_READINESS_AUDIT.md; docs/IAL2_POST_AHB_AGGREGATE_BUSY_PARK_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; ppif/ahb_requester.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.786|IAL2-FEATURE-COMPLETENESS-FRONTIER\.787|transfer_busy|busy.*2.b01|_normalize_transfer|beats_remaining_q' docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.786` audits bounded requester-side single
BUSY-beat insertion readiness — teaching the AHB requester to drive
`HTRANS = BUSY` for one held beat inside an active `WRAP4`/`INCR4` burst — and
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.787`, a no-behavior public contract
selection for the requester BUSY-insertion source. Direct implementation is not
selected: the burst machinery is ready, but the source syntax, drive block, FSM
insertion/`SEQ`-re-entry semantics, fail-closed policy, and new-stem-vs-widen
contract are still open.

The requester source declares only `idle = 2'b00`, `nonseq = 2'b10`, and
`seq = 2'b11` (`ppif/ahb_requester.ppif:65`–`71`;
`AhbRequester::_normalize_transfer`, `AhbRequester.pm:224`–`232`), with no
`busy = 2'b01` encoding and no `transfer_busy` drive block. The beat loop
(`AhbRequester.pm:430`–`466`) drives `request_bus` (IDLE) until grant, then
`transfer_nonseq` on beat 0 and `transfer_seq` on later beats, advancing
`beat_index_q`/`beats_remaining_q` on each OKAY beat. `local_status.busy`
(`:175`/`:474`) is an internal activity flag, not the bus `HTRANS = BUSY` code,
and the requester `_unsupported_residue` (`:566`–`590`) carries no BUSY-insertion
deferral today.

The machinery is ready: the requester already models `beat_index_q`/
`beats_remaining_q` (width 5), `burst_active_q`, the wrap registers, all eight
burst encodings, and the wrap/incr address progression, so a held BUSY beat only
needs to drive `HTRANS = BUSY` while re-driving the same `addr_q`/`write_q`/
`size_q`/`burst_q`/`wdata_q` and not advancing the counters — no new register or
counter, inside the shipped byte-only `WRAP4`/`INCR4` window. The receiving side
is already complete: the subordinate/interconnect BUSY-park family (`.776`–`.784`)
parks across a BUSY beat (`parks_on = [busy]` per child), so no subordinate or
interconnect change is expected for the requester to drive one.

The bounded behavior delta is requester-side only: a `busy = 2'b01` encoding, a
`transfer_busy` drive block (hold address/control, do not advance counters), a
bounded single-beat insertion decision plus `SEQ` re-entry in the beat loop, a
fail-closed policy, and a new requester residue. `.787` must settle the source
path, in-place widen vs new stem, the `busy` encoding + insertion clause syntax,
the drive-block/insertion-point/`SEQ`-re-entry shape, the fail-closed policy,
`local_status` reporting, support/coverage/artifact naming, focused test shape
(model `t/1473` + `t/1494` stimulus), `t/248`/`t/297` impact, docs, and the
matching `.ahb` alias sequencing before any behavior changes.
