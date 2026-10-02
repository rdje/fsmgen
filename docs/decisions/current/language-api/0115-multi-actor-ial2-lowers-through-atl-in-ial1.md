# 0115 — Multi-actor IAL2 lowers through ATL in IAL1

- Date: 2026-10-02
- Type: architecture
- Status: accepted target; composition migration pending
- Owner: `IAL2-ATL-LOWERING-INTEGRATION`
- Capture: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.66`
- Refines: decisions `0014`, `0016`, and `0018`

## Context

The director requires IAL2 lowering to be aware of ATL when protocol/platform
intent describes interacting actors. ATL means Actor Transfer Level: data and
activation movement among actors, with scheduling and generated cycles exposed.
The director also requires thorough mdBook coverage.

Explicit ATL source is IAL1/ISF. Higher protocol/platform intent is IAL2;
generating an actor graph does not change the layer of the generated ATL.

Fixed APB public `--outdir` currently emits `apb_requester.isf` and
`apb_completer.isf`, their scheduled FSMs, and `apb_tb.fsm`. The last artifact
contains the structural composition and continuous APB wiring; no corresponding
network `.isf` is emitted. `ApbComposition` constructs that top after collecting
the already lowered endpoint products. This is a missing IAL1 network review
boundary, not evidence of a protocol malfunction. The bound actual products
and source path are retained under `docs/audits/ial2-atl-contract-20261002`.

## Decision

The complete lowering target is:

```text
IAL2 protocol/platform intent
  -> IAL1/ISF actors and ATL network intent
  -> canonical scheduling/elaboration to IAL0/FSM
  -> HDL
```

When IAL2 intent requires an actor network, its IAL1 output must preserve the
participating instances, interfaces/bindings, activation/events, ordering and
data movement needed to review that network. Leaf actor `.isf` files alone do
not establish that the network passed through IAL1. A single actor does not
need an invented network wrapper. ATL remains part of IAL1, not another tier.

The lowering path must consume that network representation through canonical
IAL1 elaboration/scheduling. Emitting a descriptive `.isf` beside an independently
built IAL0 top would not satisfy this contract. Keep source object/anchor to
actor/network/artifact mappings explicit and backend-language neutral.

Continuous physical protocol bindings and temporal ATL drive routes have
different lifetimes. Preserve the distinction. Existing `(sink source)` drive
bodies activate at drive-call cycles; they do not authorize persistent APB/AXI/AHB
bus wiring. Select any missing static binding or orchestration prerequisite
before migration, rather than changing protocol meaning to fit current syntax.

## Consequences

`IAL2-ATL-LOWERING-INTEGRATION` owns the P2 gap, complete affected-generator and
history census, IAL1 prerequisites, compatibility, staged protocol migrations,
independent behavior qualification and public inspection closure. It is scheduled
after the current R13 source-intent contract's clean handoff. Existing generated
products remain shipped behavior until exact migrations qualify.

The mdBook must explain the ATL model, syntax, scheduling, artifacts, runnable
examples, supported boundaries and IAL2 relationship. It must disclose the
current composition gap; neither the generic layered diagram nor the presence
of child `.isf` files can advertise complete ATL generation.

This does not activate decision `0020`'s separate transaction-interface horizon,
general concurrent groups, event joins, route storage/muxing, payloads, CDC or
new runtime/backend support. Each missing capability retains an exact owner.
