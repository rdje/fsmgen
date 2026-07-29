---
id: ial2-ahb-requester-exact-four-busy-event-profile-alias-behavior
title: Exact-four AHB requester BUSY ships through a byte-identical .ahb alias
answers:
  - "does ppif/ahb_requester_busy_insert_four.ahb ship?"
  - "is the exact-four AHB requester alias a separate generator?"
  - "what support id owns the exact-four requester .ahb alias?"
  - "can MCP semantically introspect the exact-four AHB requester alias?"
  - "how many AHB IAL2 paths ship after the exact-four alias?"
  - "which test proves the exact-four requester alias?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, profile-alias, semantics, mcp, behavior]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_requester_busy_insert_four.ppif; ppif/ahb_requester_busy_insert_four.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1535-ial2-ahb-requester-four-busy-insert.t; t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md
reverify: "cmp ppif/ahb_requester_busy_insert_four.ppif ppif/ahb_requester_busy_insert_four.ahb && scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -Iperl t/1536-ial2-ahb-requester-four-busy-insert-profile-alias.t"
---

`ppif/ahb_requester_busy_insert_four.ahb` ships as a byte-identical profile
alias of the generic exact-four `.ppif`. Both use the existing AHB requester
generator and IAL2 -> IAL1 -> IAL0 -> HDL route, generate module
`amba_requester_busy_insert_four`, preserve width-three
`4 -> 3 -> 2 -> 1 -> 0` lowering and numeric `busy_insertion.beats=4`, and
differ only because the alias removes `ahb_profile_alias_deferred`.

The alias support ID is
`intent.ahb_profile_alias_requester_busy_insert_four`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli`, source kind
is `ial2_profile_alias`, and semantic root is `fsm`. Strict semantic JSON and
the existing read-only shell-disabled MCP `fsmgen_semantic_introspect` tool
expose that same bounded public payload; no alias-specific API was added.

Focused t1536 proves byte/report/artifact/check/schedule/semantic/MCP/verifier/
diagnostic and requester/paired preservation parity without compiling a second
simulation. Assertion-enabled t1535 remains the sole shared continuous/ready-
low/grant-low runtime proof. The later exact-four paired generic/profile pair
moves current accounting to 330 protocol fixtures / 371 supported+strict / 54
AHB paths split 27 `.ppif` / 27 `.ahb`.
