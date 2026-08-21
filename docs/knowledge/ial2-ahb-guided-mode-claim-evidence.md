---
id: ial2-ahb-guided-mode-claim-evidence
title: Chapter 16c guided AHB mode and byte-lane claims retain four evidence gates
answers:
  - "how are the first six Chapter 16c AHB claims verified?"
  - "how is the Chapter 16c raw mode map verified?"
  - "how are AHB little-endian byte lane bit ranges verified?"
  - "how is the 32-bit in-word AHB SEQ boundary verified?"
  - "how are the AHB INCR4 and WRAP4 starting-lane rules verified?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, mode-map, byte-lane, seq, hburst, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  fsm/ahb_lite_subordinate.fsm;
  ppif/ahb_requester_busy_insert_four.ppif;
  ppif/ahb_lite_subordinate_byte_lane.ppif;
  ppif/ahb_lite_subordinate_byte_lane_seq.ppif;
  ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif;
  t/1482-ial2-ahb-subordinate-byte-lane.t;
  t/1486-ial2-ahb-subordinate-byte-lane-seq.t;
  t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t;
  t/1498-ial2-ahb-requester-busy-insert.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t;
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl
  t/1482-ial2-ahb-subordinate-byte-lane.t
  t/1486-ial2-ahb-subordinate-byte-lane-seq.t
  t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
  t/1498-ial2-ahb-requester-busy-insert.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t
  t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.1` reviews the exact six inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 1 through 1176. All six
state current bounded behavior and use derived gates. No syntax example or
heading is promoted into a separate capability.

The candidates remain separated into four evidence families:

- the raw/full-control mode summary covering generated depth-one phase
  ownership, exact-one requester BUSY by clause absence, generalized literal
  counts `2..16`, and the direct subordinate's Q-named four-state repair;
- little-endian byte-lane mapping from lane 0 `[7:0]` through lane 3
  `[31:24]`;
- byte/halfword `SEQ` progression constrained to one 32-bit register word;
  and
- byte-only four-beat `INCR4`/`WRAP4`, with `INCR4` starting at lane 0 and
  `WRAP4` starting at and wrapping from any lane inside the four-byte window.

The ordinary requester, subordinate, and interconnect builders plus the
tracked direct seed rederive the mode-map claim. Distinct focused oracles
exercise exact-one absence, paired one-hot data ownership, generated
completion-edge phase replacement, four direct Q-named completion scenarios,
and assertion-enabled generalized `5`, `8`, and `16` runtimes. Adjacent `17`,
noncanonical count forms, overwritten phases, ERROR completions, and a
pending-bank direct implementation are separating alternatives.

The three endpoint builders emit structured reports that independently expose
all four bit ranges, `in_word_progressive` address and control rules, and
`hburst_in_word_progressive` with `beats_per_burst=4` and `window_bytes=4`.
Focused oracles additionally inspect generated IAL1/IAL0 masks and state,
reject the opposite lane order and crossing/unexpected `SEQ`, distinguish
linear `INCR4` from modulo `WRAP4`, reject non-lane0 `INCR4`, and prove lane-3
`WRAP4` returns to lane 0.
