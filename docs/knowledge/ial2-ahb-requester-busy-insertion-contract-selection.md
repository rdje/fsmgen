---
id: ial2-ahb-requester-busy-insertion-contract-selection
title: AHB requester BUSY-insertion contract picks a new additive stem with a busy=2'b01 encoding and busy-before-beat clause
answers:
  - "what is the public contract for requester-side AHB BUSY insertion?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.787 select?"
  - "how does an AHB requester source declare a BUSY beat insertion?"
  - "what source ships requester HTRANS=BUSY insertion?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.788?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, busy, insertion, htrans, contract, selector, task-tree]
evidence: docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_READINESS_AUDIT.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/ahb_requester.ppif; ppif/ahb_requester_busy_insert.ppif; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.787|IAL2-FEATURE-COMPLETENESS-FRONTIER\.788|ahb_requester_busy_insert|busy-before-beat|busy_before_beat|transfer_busy' docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.787` selects the public contract for the
requester-side AHB single BUSY-beat insertion source and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.788`, the direct implementation.

The behavior ships as a **new additive source stem**
`ppif/ahb_requester_busy_insert.ppif` (actor `amba_requester_busy_insert` → HDL
module `amba_requester_busy_insert`; support identity
`intent.ppif_ahb_requester_busy_insert`, coverage
`ial2_ppif_ahb_requester_busy_insert_pipeline_cli`, source kind `ppif`, contract
kind still `ahb_requester`), preserving `ppif/ahb_requester.ppif`, its
`ppif/ahb_requester.ahb` mirror, and `t/1473` with zero regression.

The source adds a `busy = 2'b01` HTRANS encoding and a bounded single-beat
insertion clause `(busy-before-beat N)` to the `(transfer …)` block: the
requester drives exactly one held `HTRANS = BUSY` beat immediately before the
`SEQ` beat whose `beat_index_q` equals `N`, holding that beat's address/control.
`N` is a literal in `1..15` (AHB BUSY precedes a `SEQ` beat, never the `NONSEQ`
first beat; `max_beats = 16`). `AhbRequester::_normalize_transfer` gains optional
`busy` and `busy_before_beat` fields, fail-closed at parse for `busy_before_beat`
without `busy`, `N` outside `1..15`, non-literal `N`, a duplicate clause, or a
`busy` encoding other than `2'b01`; at runtime a burst that never reaches
`beat_index_q == N` is a safe no-op.

The generator adds a `transfer_busy` drive block (drive `HTRANS = BUSY`, hold
address/control, no `set`) and a `busy_inserted_q` one-shot in the beat loop so
exactly one BUSY presentation is driven and the following beat is `SEQ` resuming from the
armed address/beat count — no new register beyond the one-bit flag, inside the
shipped byte-only `WRAP4`/`INCR4` window. It adds a `busy_insertion` report block
and an `ahb_requester_busy_insert_support` residue; no new bus-BUSY output port
(the beat is visible on `HTRANS`); the receiving subordinate/interconnect already
parks. `.788` ships the source, parser/generator/report/residue, support
accounting, `t/1498`, `t/297`, language surface, mdBook, and `--verify-hdl`
closeout. The selector projected `t/248` 297→298/338→339; intervening AXI
shipments moved the implementation baseline, so `.788` closes at the measured
current 308→309 protocol / 349→350 supported-smoke and strict entries. `.788`
now ships that selected contract through
`ppif/ahb_requester_busy_insert.ppif`; the behavior fact
`ial2-ahb-requester-busy-insertion-behavior` owns the runtime result. The
matching `.ahb` alias, a paired
requester+subordinate composition, multi-beat/policy BUSY, a runtime insertion
point, and a distinct `local_status.bus_busy` output remain deferred.
