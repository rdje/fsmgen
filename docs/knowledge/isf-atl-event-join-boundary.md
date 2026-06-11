---
id: isf-atl-event-join-boundary
title: ISF ATL actor-event join boundary
answers:
  - "what diagnostic reports ATL await_all or await_any actor-event joins?"
  - "can await_all join qualified ATL actor events?"
  - "can await_any join qualified ATL actor events?"
  - "where is the ATL sync-clause event-join diagnostic implemented?"
date: 2026-06-11
status: current
tags: [isf, atl, event-wait, event-join, diagnostics]
evidence: perl/FSM/Adapter/ISF/Parser.pm; t/1322-isf-actor-network-static.t; docs/book/src/13f-composition.md; docs/ISF_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
reverify: prove -Iperl t/1322-isf-actor-network-static.t
---

`await_all` and `await_any` remain generated-child completion sync forms in the
current ISF surface. They accept the documented child-completion done port
shape, not qualified ATL actor-event operands.

Source that tries to spell an ATL actor-event join with sync clauses, for
example `(await_all reader.done writer.done)` or
`(await_any reader.done writer.done)`, fails closed in
`FSM::Adapter::ISF::Parser` before generic dotted enum-member handling. The
diagnostic says that sync clauses cannot join qualified actor events and that
hidden all-of/any-of actor-event joins require event latch/storage and
per-event lifetime semantics.

The accepted ATL multi-event wait shape remains sequential: one temporary
trigger batch followed by source-ordered top-level `(await actor.event)` waits
to distinct triggered actors. It is not a hidden same-cycle event join.
