---
id: ial2-ahb-requester-busy-insertion-behavior
title: The additive AHB requester source inserts one held BUSY presentation before a selected SEQ beat
answers:
  - "does FSMGen generate requester-side AHB HTRANS BUSY?"
  - "how do I insert an AHB BUSY beat from a requester?"
  - "what does busy-before-beat mean?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.788?"
  - "what does t 1498 prove?"
  - "what is ppif/ahb_requester_busy_insert.ppif?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, busy, htrans, burst, ppif, behavior]
evidence: ppif/ahb_requester_busy_insert.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1498-ial2-ahb-requester-busy-insert.t; t/data/ahb_requester_busy_insert_tb.svt; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: prove -Iperl t/1473-ial2-ahb-requester.t t/1498-ial2-ahb-requester-busy-insert.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t && ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert.ppif
---

FSMGen ships requester-side AHB BUSY insertion through the additive source
`ppif/ahb_requester_busy_insert.ppif`. It retains the existing AHB requester
contract and ports but has distinct intent/artifact/module identity
`ahb_requester_busy_insert` / `amba_requester_busy_insert` and support identity
`intent.ppif_ahb_requester_busy_insert`.

The transfer block adds `(busy 2'b01)` and `(busy-before-beat 2)`. For a burst
that reaches index two, the generated requester presents the pending
address/control/write-data with `HTRANS = BUSY`, holds address and counters,
skips response advancement, and then resumes that same index-two transfer as
`SEQ`. One `busy_inserted_q` bit makes the insertion a one-shot. The literal
index must be in `1..15`; missing/wrong BUSY encoding, non-literal or
out-of-range index, and duplicate clause fail closed.

Generated-HDL t/1498 proves the `INCR4` presentation sequence
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, unchanged
pending fields/counters across BUSY, exactly four accepted data beats, and
completion with zero remaining. The base requester and its `.ahb` alias remain
BUSY-insertion free. Matching `.ahb`, policy/runtime/multi-beat BUSY, distinct
local bus-BUSY status, paired composition, and broader requester behavior are
deferred.
