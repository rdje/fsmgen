---
id: ial2-post-ahb-aggregate-busy-park-next-slice-selection
title: AHB aggregate BUSY-park family selects requester-side BUSY insertion readiness audit
answers:
  - "what follows the subordinate/aggregate AHB BUSY-park .ppif/.ahb family?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.785 select?"
  - "what is the smallest next AHB feature-completeness increment after BUSY-park?"
  - "which task audits requester-side BUSY-beat insertion readiness?"
  - "does the AHB requester drive HTRANS=BUSY on the bus?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.786?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, requester, insertion, selector, task-tree]
evidence: docs/IAL2_POST_AHB_AGGREGATE_BUSY_PARK_NEXT_SLICE_SELECTION.md; docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; ppif/ahb_requester.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.785|IAL2-FEATURE-COMPLETENESS-FRONTIER\.786|transfer_busy|busy.*2.b01|local_status.busy|_normalize_transfer' docs/IAL2_POST_AHB_AGGREGATE_BUSY_PARK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.785` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.786`, a no-behavior readiness audit for
bounded **requester-side single BUSY-beat insertion** — teaching the AHB
requester to drive `HTRANS = BUSY` for one held beat inside an active
`WRAP4`/`INCR4` burst — after the entire subordinate/aggregate BUSY-park
`.ppif`/`.ahb` family (endpoint `.776`/`.778`, aggregate `.782`/`.784`) is
complete.

BUSY-park is now finished on the side that *receives* a BUSY beat, but no
FSMGen-generated AHB actor *drives* one. The requester's HTRANS table defines
only `idle = 2'b00`, `nonseq = 2'b10`, and `seq = 2'b11`
(`AhbRequester::_normalize_transfer`, `AhbRequester.pm:224`-`232`); there is no
`busy = 2'b01` encoding and no `transfer_busy` drive block (it emits IDLE,
`transfer_nonseq` at `:326`, and `transfer_seq` at `:338`), confirmed at runtime
by the `ppif/ahb_requester.ppif` schedule JSON `transfer` block. `local_status.busy`
(`AhbRequester.pm:175`, driven default `1` in `_status_drive_lines` at `:474`) is
an internal mid-command activity flag, not the bus `HTRANS = BUSY` encoding. The
subordinate/interconnect side already parks the byte-only `WRAP4`/`INCR4` in-word
`SEQ` context across a BUSY beat (aggregate schedule JSON reports
`parks_on = [busy]` per child).

Requester-side insertion is the smallest *remaining* AHB increment that is both
bounded and coherent: it closes the just-shipped BUSY-park loop end to end, is
self-contained on the requester, and reuses the existing requester burst
machinery (`beat_index_q`/`beats_remaining_q` width 5, `burst_active_q`, wrap
registers, all eight burst encodings). The delta is a `busy = 2'b01` HTRANS
encoding, a `transfer_busy` drive block that holds address/control constant, and
a bounded single-beat insertion decision — with no change to burst address
progression and inside the shipped byte-only `WRAP4`/`INCR4` window.

The larger candidates are deferred: halfword/word burst `SEQ` and
wider/indefinite `WRAP8`/`INCR8`/`WRAP16`/`INCR16`/indefinite `INCR` both cross
the single 32-bit word (`supported_sizes = [byte]`, `beats_per_burst = 4`,
in-word window; `seq_beats_remaining_q` width 2) and depend on the separately
deferred multi-word/register-bank progression; multi-word progression is itself a
foundational medium-large address-model prerequisite; and optional/property-gated
AHB signals (`HPROT`/`HMASTLOCK`/exclusive/protection/legacy two-bit `HRESP`,
`ahb_optional_signal_residue`, `AhbInterconnect.pm:1411`) are an unanchored fresh
signal family with no bus binding or state today.

`.786` must audit whether the requester-side BUSY insertion owner can implement
directly or needs a public contract selection first, covering the source
declaration, the `transfer_busy` drive block, the insertion point and SEQ
re-entry, the fail-closed policy, `local_status` reporting, the (expected: none)
receiving-side change, support-accounting/capability-manifest/focused-test
impact, docs, and preservation before any behavior changes.
