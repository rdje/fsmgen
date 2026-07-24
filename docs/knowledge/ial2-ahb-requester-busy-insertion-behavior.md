---
id: ial2-ahb-requester-busy-insertion-behavior
title: The additive AHB requester retires exactly one qualified BUSY event before the selected SEQ beat
answers:
  - "does FSMGen generate requester-side AHB HTRANS BUSY?"
  - "how do I insert an AHB BUSY beat from a requester?"
  - "what does busy-before-beat mean?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.788?"
  - "what does t 1498 prove?"
  - "what is ppif/ahb_requester_busy_insert.ppif?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, burst, ppif, behavior]
evidence: ppif/ahb_requester_busy_insert.ppif; ppif/ahb_requester_busy_insert.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1498-ial2-ahb-requester-busy-insert.t; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; t/data/ahb_requester_busy_insert_tb.svt; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
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
`SEQ`. One `busy_inserted_q` bit makes the procedural insertion a one-shot. The literal
index must be in `1..15`; missing/wrong BUSY encoding, non-literal or
out-of-range index, and duplicate clause fail closed.

Generated-HDL t/1498 proves the `INCR4` transfer-type transition sequence
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, exactly one
`HGRANT && HREADY` BUSY event, unchanged pending fields/counters across BUSY,
exactly four accepted data beats, and completion with zero remaining. It runs
continuously-qualified, 32-clock ready-low, and 32-clock grant-low scenarios
with generated assertions enabled. The base requester and its `.ahb` alias
remain BUSY-insertion free. The matching additive
`ppif/ahb_requester_busy_insert.ahb` alias now ships with identical behavior;
fact `ial2-ahb-requester-busy-insertion-profile-alias-behavior` owns its public
surface. The requester now presents an active transfer for a clock and holds it
while `HREADY=0`, consuming `HRESP` only after data-phase completion. The first
generic paired requester/subordinate composition now ships; fact
`ial2-ahb-paired-busy-composition-behavior` owns it.

Exact-two requester insertion now ships on generic `.ppif` and matching `.ahb`
requester surfaces, and the first generic one-subordinate exact-two paired
composition also ships. Fact
`ial2-ahb-exact-two-paired-busy-composition-behavior` owns its generated-HDL,
normalized semantic JSON, and read-only MCP proof. The matching paired alias
and two-subordinate exact-two sibling remain separate.

Historical audit `ial2-ahb-requester-multi-busy-insertion-readiness-audit`
records the pre-repair ten-qualified-edge contradiction. Repair fact
`ial2-ahb-requester-single-busy-event-cardinality-repair` owns the shipped
exact-one result. Counts beyond exact two, policy/runtime-selected BUSY
behavior, distinct local bus-BUSY status, and broader requester behavior remain
deferred.
