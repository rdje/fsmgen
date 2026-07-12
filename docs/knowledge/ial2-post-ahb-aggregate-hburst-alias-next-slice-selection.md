---
id: ial2-post-ahb-aggregate-hburst-alias-next-slice-selection
title: AHB aggregate HBURST alias family selects BUSY-in-burst parking readiness audit
answers:
  - "what follows the aggregate AHB HBURST SEQ .ahb alias family?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.773 select?"
  - "what is the smallest next AHB burst-SEQ increment after byte-only WRAP4/INCR4?"
  - "which task audits AHB BUSY-in-burst parking readiness?"
  - "how does the AHB subordinate currently handle an HTRANS=BUSY beat mid-burst?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, subordinate, selector]
evidence: docs/IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Adapter/IAL2/PPIF.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.773|IAL2-FEATURE-COMPLETENESS-FRONTIER\.774|BUSY-in-burst|ahb_seq_idle_clear|clears_on|seq_beats_remaining_q' docs/IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.773` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.774`, a no-behavior readiness audit for
bounded AHB subordinate BUSY-in-burst parking, after the byte-only
`WRAP4`/`INCR4` in-word HBURST `SEQ` endpoint and aggregate `.ppif`/`.ahb`
family is complete.

BUSY-in-burst parking is the smallest natural increment and reuses the most
existing machinery. The endpoint burst-context registers (`seq_valid_q`,
`seq_expected_addr_q`, `seq_size_q`, `seq_write_q`, `seq_hburst_q`,
`seq_beats_remaining_q`) already exist for the shipped `WRAP4`/`INCR4` path.
Today an `HTRANS = BUSY` beat is folded into the burst-history clear alongside
IDLE — the `ahb_seq_idle_clear` transaction fires on
`(| (== HTRANS idle) (== HTRANS busy))` (`AhbSubordinate.pm:710`) and the report
advertises `clears_on = [reset, idle, busy, error, new_nonseq, final_beat]`
(`:989`). Parking means holding the burst context across a BUSY beat instead of
clearing it, which is a bounded decode edit plus report/residue narrowing.

`.774` must audit the clear-versus-park decode change, the fail-closed behavior
for a drifting BUSY beat, the report/residue narrowing, whether the endpoint
source is widened in place or a new source stem is added, focused test and
support-accounting/capability-manifest impact, docs, and preservation before any
BUSY-parking behavior changes. Halfword/word burst `SEQ`, wider/indefinite
bursts, multi-word/register-bank progression, and optional/property-gated AHB
signals are larger and remain deferred.
