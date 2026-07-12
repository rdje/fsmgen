---
id: ial2-post-ahb-endpoint-busy-park-next-slice-selection
title: AHB endpoint BUSY-park family selects aggregate BUSY-park propagation readiness audit
answers:
  - "what follows the endpoint AHB BUSY-park .ppif/.ahb family?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.779 select?"
  - "what is the smallest next AHB burst-SEQ increment after endpoint BUSY-park?"
  - "which task audits aggregate AHB BUSY-park propagation readiness?"
  - "how does the AHB interconnect forward a child subordinate's parked BUSY seq_policy?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, interconnect, aggregate, selector]
evidence: docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.779|IAL2-FEATURE-COMPLETENESS-FRONTIER\.780|BUSY-in-burst handling|aggregate propagation|_seq_policy_propagation_report|parks_on' docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.779` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.780`, a no-behavior readiness audit for
bounded aggregate AHB BUSY-parking propagation, after the endpoint BUSY-park
`.ppif`/`.ahb` family (`.776`/`.778`) is complete.

Aggregate BUSY-park propagation is the smallest natural increment and reuses the
most existing machinery. Every prior AHB burst feature shipped at the endpoint
first and then propagated through the interconnect (byte-lane, byte-lane `SEQ`,
HBURST-aware byte-lane `SEQ`), and BUSY-park is now shipped at the endpoint. Both
residue strings bracket exactly this increment: the endpoint BUSY-park residue
defers `aggregate propagation` (`AhbSubordinate.pm:1031`) while the aggregate
residue still lists `BUSY-in-burst handling` first among remaining burst work
(`AhbInterconnect.pm:1401`/`:1403`).

The mechanism is bounded. The interconnect `_seq_policy_propagation_report`
clones each child's `seq_policy` verbatim (`AhbInterconnect.pm:1177`, `:1207`),
so a child subordinate declared with `(parked-transfer busy)` automatically
forwards its `parks_on = [busy]` and BUSY-free `clears_on` into the aggregate
`composition.seq_policy_propagation` report — no new interconnect report field is
needed. The aggregate sources inline the child transfer block, so the delta is
new aggregate stems whose child uses `(ignored-transfer idle)` +
`(parked-transfer busy)` plus residue narrowing, reusing the shared
`AhbSubordinate::_normalize_transfer` parked-busy path shipped for the endpoint.

`.780` must audit whether the aggregate BUSY-park propagation owner can implement
directly (new aggregate sources) or needs a public contract selection first, and
cover the child transfer declaration, whether the propagation report needs any
change beyond its verbatim clone, the residue narrowing, the child `seq_ok_base`
fail-closed path through the interconnect, whether one or both aggregate stems
ship first, support-accounting/capability-manifest/focused-test impact, docs, and
preservation before any behavior changes. Requester-side BUSY insertion
(the requester never drives bus `HTRANS = BUSY`; `AhbRequester.pm:473`),
halfword/word burst `SEQ`, wider/indefinite bursts, multi-word/register-bank
progression, and optional/property-gated AHB signals are larger and remain
deferred.
