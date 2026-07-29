---
id: ial2-ahb-requester-exact-three-busy-event-profile-alias-behavior
title: Exact-three AHB requester BUSY ships through a byte-identical .ahb alias
answers:
  - "does ppif/ahb_requester_busy_insert_three.ahb ship?"
  - "is the exact-three AHB requester alias a separate generator?"
  - "what support id owns the exact-three requester .ahb alias?"
  - "can MCP semantically introspect the exact-three AHB requester alias?"
  - "how many AHB IAL2 paths ship after the exact-three alias?"
  - "which test proves the exact-three requester alias?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, profile-alias, semantics, mcp, behavior]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_requester_busy_insert_three.ppif; ppif/ahb_requester_busy_insert_three.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1528-ial2-ahb-requester-three-busy-insert.t; t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md
reverify: cmp ppif/ahb_requester_busy_insert_three.ppif ppif/ahb_requester_busy_insert_three.ahb && scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_three.ahb
---

`ppif/ahb_requester_busy_insert_three.ahb` ships as a byte-identical profile
alias of the generic exact-three `.ppif`. Both use the existing AHB requester
generator and IAL2 -> IAL1 -> IAL0 -> HDL route, generate module
`amba_requester_busy_insert_three`, and preserve numeric
`busy_insertion.beats=3`. The alias removes only
`ahb_profile_alias_deferred`.

The alias support ID is
`intent.ahb_profile_alias_requester_busy_insert_three`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli`, source kind
is `ial2_profile_alias`, and semantic root is `fsm`. Strict semantic JSON and
the existing read-only shell-disabled MCP `fsmgen_semantic_introspect` tool
expose that same bounded public payload; no alias-specific API or private-
internal exposure was added.

Focused t/1529 proves byte/report/artifact/check/schedule/semantic/MCP/verifier/
diagnostic parity without compiling a second simulation. Assertion-enabled
t/1528 remains the sole shared continuous/ready-low/grant-low runtime proof.
The alias established 322/363/46. The generic exact-three paired source
established 323/364/47; its matching alias established 324
protocol fixtures / 365 supported+strict / 48 AHB paths. The generic
two-subordinate exact-three paired source established 325/366/49; its matching
alias established 326/367/50. The generic exact-four requester established
327/368/51 and its matching alias established 328/369/52. The later exact-four
paired generic/profile pair moves current accounting to 330 protocol fixtures,
371 supported-smoke/strict fixtures, and 54 AHB IAL2 paths split 27 `.ppif` /
27 `.ahb`.
