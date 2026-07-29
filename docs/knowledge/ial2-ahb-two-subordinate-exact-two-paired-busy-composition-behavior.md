---
id: ial2-ahb-two-subordinate-exact-two-paired-busy-composition-behavior
title: Two-subordinate exact-two paired AHB BUSY ships with deep semantic and MCP parity
answers:
  - "does FSMGen ship a two-subordinate exact-two paired AHB BUSY source?"
  - "what does t 1525 prove?"
  - "does the two-subordinate exact-two composition need a new generator?"
  - "does the two-subordinate exact-two source support semantic JSON and MCP introspection?"
  - "are deep semantic introspection APIs ongoing for new FSMGen features?"
  - "what are the current AHB IAL2 support counts?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, composition, semantic, mcp, runtime]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t; t/data/ahb_two_subordinate_exact_two_paired_busy_composition_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -Iperl t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
---

`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`
and its byte-identical matching `.ahb` alias ship a four-child `ahb_tb`
composition. They reuse the existing exact-two
requester, two BUSY-parking status/control subordinates, interconnect, and top
generators. It is declarative source data, not a new generator or MCP API.

Focused t/1525 proves strict check, schedule JSON, normalized semantic JSON,
the real read-only `fsmgen_semantic_introspect` adapter with shell access
disabled, exact generated artifacts, HDL verification, and two-command
generated-HDL behavior. Runtime totals are four qualified BUSY events, two
resumed `SEQ` events, eight data beats, and final status/control storage
`32'h44332211`/`32'h88776655`.

That alias shipment checkpoint is 320 protocol / 361 supported+strict / 44 AHB
paths split 22 `.ppif` and 22 `.ahb`; the later generic exact-three requester
established 321/362/45 and its alias established 322/363/46. The generic
exact-three paired source established 323/364/47; its matching alias moves
the next checkpoint to 324/365/48. The generic two-subordinate exact-three
paired source established 325/366/49; its matching alias established
326/367/50. The generic exact-four requester established 327/368/51; its
matching alias now moves current accounting to 328/369/52 split 26 `.ppif` /
26 `.ahb`.
Deep semantic
introspection is an ongoing
language-wide capability: each new support-accounted semantic feature must
preserve check, schedule, normalized semantic JSON, and stable read-only MCP
parity rather than introducing feature-specific APIs or exposing raw private
internals. Focused t1526 proves alias parity without a second runtime; t1525
remains shared.
