---
id: ial2-ahb-requester-exact-two-busy-event-profile-alias-behavior
title: Exact-two AHB requester BUSY ships through a byte-identical .ahb alias
answers:
  - "does ppif/ahb_requester_busy_insert_two.ahb ship?"
  - "is the exact-two AHB requester alias a separate generator?"
  - "what support id owns the exact-two requester .ahb alias?"
  - "can MCP semantically introspect the exact-two AHB requester alias?"
  - "how many AHB IAL2 paths ship after the exact-two alias?"
  - "which test proves the exact-two requester alias?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, exact-two, profile-alias, semantics, mcp, behavior]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_requester_busy_insert_two.ppif; ppif/ahb_requester_busy_insert_two.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1521-ial2-ahb-requester-two-busy-insert.t; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: cmp ppif/ahb_requester_busy_insert_two.ppif ppif/ahb_requester_busy_insert_two.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_two.ahb
---

`ppif/ahb_requester_busy_insert_two.ahb` now ships as a byte-identical profile
alias of the generic exact-two `.ppif`. Both use the existing AHB requester
generator and IAL2 -> IAL1 -> IAL0 -> HDL route, generate module
`amba_requester_busy_insert_two`, and preserve numeric
`busy_insertion.beats=2`. The alias removes only
`ahb_profile_alias_deferred`.

The alias support ID is
`intent.ahb_profile_alias_requester_busy_insert_two`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli`, source kind is
`ial2_profile_alias`, and semantic root is `fsm`. Strict semantic JSON and the
existing read-only MCP `fsmgen_semantic_introspect` tool expose that same
bounded public payload; no alias-specific API or private-internal exposure was
added.

Focused t/1522 proves source/report/artifact/check/schedule/semantic/MCP/verify
parity. Assertion-enabled t/1521 remains the shared runtime proof. The alias
checkpoint was 316 protocol fixtures, 357 supported-smoke/strict fixtures, and
40 AHB IAL2 paths split evenly between `.ppif` and `.ahb`. The first generic
exact-two paired composition established the 317/358/41 checkpoint; its
matching alias established 318/359/42. The generic two-subordinate exact-two
source established 319/360/43; its matching alias established 320/361/44. The
additive generic exact-three requester now moves current accounting to
321/362/45, split twenty-three `.ppif` and twenty-two `.ahb`.
