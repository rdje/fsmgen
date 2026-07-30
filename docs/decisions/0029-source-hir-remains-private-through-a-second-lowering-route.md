# 0029 — SourceHIR remains private through a second lowering route

- Date: 2026-07-30
- Type: architecture
- Status: accepted by `FSMGEN-HIR-ROADMAP-FRONTIER.5`
- Refines: `0028`

## Context

The private version-1 SourceHIR prototype deterministically renders one
protocol-neutral valid-ready object to canonical PPIF and proves unchanged
`IAL2 -> IAL1 -> IAL0` results. It has one repository-internal test producer,
one semantic shape, and no public API, CLI, serialization, report, manifest, or
support-accounting contract.

Decision `0028` selected SourceHIR as a shared layer above both IAL2 protocol
intent and concrete IAL1 control. The prototype proves only the IAL2 half.
Promoting it now would freeze a purportedly shared public abstraction from one
route; retiring it would discard a working immutable/provenance boundary that
currently carries no compatibility burden.

## Decision

SourceHIR remains private while FSMGen selects and proves one bounded
concrete-FSM/control-to-IAL1 route. That route must render canonical IAL1,
enter the existing parser/validator and `IAL1 -> IAL0` chain, and preserve the
same immutability, deterministic validation, provenance, source-map, and
golden-equivalence principles.

Public host-language and package selection remains separately owned by
`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`. Proving a second private route is
necessary evidence for another promotion audit, but does not itself authorize
a public API.

Decision `0030` now selects the separate `.6` route: semantic SourceHIR version
2 renders `isf/phase_test.isf` canonically through the shipped ISF adapter and
scheduler. This decision's private-before-promotion rule remains unchanged.

## Consequences

- The current valid-ready packages and t1547 remain intact and private.
- A design-only leaf selects the exact second-route schema and IAL1 golden
  before any implementation change.
- A later implementation leaf proves the selected route; a following audit
  reconsiders promotion, continued private iteration, or retirement.
- No CLI, public raw-HIR or serialization contract, supported host language,
  normalized report, capability manifest, or support-accounting promise is
  added now.
- If a coherent shared object would require embedding IAL1 syntax, duplicating
  the IAL1 AST, or weakening provenance/determinism, the later design leaf must
  select retirement or a narrower renamed object rather than force the route.
