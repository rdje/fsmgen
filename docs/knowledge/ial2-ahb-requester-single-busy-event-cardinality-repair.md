---
id: ial2-ahb-requester-single-busy-event-cardinality-repair
title: The AHB requester now retires exactly one grant-and-ready-qualified BUSY event
answers:
  - "does busy_insertion beats single now mean one bus event?"
  - "how does the AHB requester retire its single BUSY event?"
  - "what shipped in IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3?"
  - "what do the requester BUSY ready and grant stall tests prove?"
  - "how many qualified BUSY events do the paired AHB sources produce?"
  - "are paired AHB selector assertions enabled?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, hready, hgrant, cardinality, repair, runtime]
evidence: docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1498-ial2-ahb-requester-busy-insert.t; t/1513-ial2-ahb-paired-busy-composition.t; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t; t/data/ahb_requester_busy_insert_tb.svt; t/data/ahb_paired_busy_composition_tb.svt; t/data/ahb_two_subordinate_paired_busy_composition_tb.svt; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: prove -Iperl t/1498-ial2-ahb-requester-busy-insert.t t/1513-ial2-ahb-paired-busy-composition.t t/1514-ial2-ahb-paired-busy-composition-profile-alias.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
---

`busy_insertion.beats=single` now means exactly one rising event with
`HGRANT && HREADY && HTRANS==BUSY`. BUSY stays pending while ready or grant is
low. Its address/control/data and counters remain stable; after one qualified
event, existing `ahb_address_pending_q` ownership presents the same pending
transfer as `SEQ`. No public syntax, report field, counter, or other storage is
added.

Assertion-enabled t/1498 proves continuously-qualified, 32-clock ready-low,
and 32-clock grant-low scenarios. Each produces one qualified BUSY event, one
resumed SEQ, four data beats, and zero remaining. t/1513-t/1516 count one
qualified embedded BUSY event per paired command across generic and `.ahb`
one-/two-window surfaces.

Paired aggregate tests retain their pre-existing `--no-assert` compile mode
because the unchanged interconnect independently overlaps mapped output drives
with state defaults. Fact
`ial2-ahb-interconnect-default-decode-output-arbitration-gap` and its proposed
inactive task own that separate assertion-enablement gap.
