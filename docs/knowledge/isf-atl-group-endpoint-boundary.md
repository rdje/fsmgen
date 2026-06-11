---
id: isf-atl-group-endpoint-boundary
title: ISF ATL group endpoint boundary
answers:
  - "what diagnostic reports ATL group.name endpoints?"
  - "can ATL trigger a declared static group endpoint?"
  - "can ATL await a declared static group endpoint?"
  - "can await_all or await_any use group.name operands?"
  - "where is the ATL group endpoint diagnostic implemented?"
date: 2026-06-11
status: current
tags: [isf, atl, actor-network, groups, diagnostics]
evidence: perl/FSM/Adapter/ISF/Parser.pm; t/1322-isf-actor-network-static.t; docs/book/src/13f-composition.md; docs/ISF_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
reverify: prove -Iperl t/1322-isf-actor-network-static.t
---

`group.name` is reserved ATL endpoint vocabulary, but it is not accepted
source behavior in the current subset.

When the qualifier names a declared static group from either verbose
`(group ...)` syntax or compact `(concurrent ...)` syntax, transaction-body
`(trigger group.name)`, `(await group.name)`, `(await_all group.name)`,
`(await_any group.name)`, and rule-action `(trigger group.name)` fail before
generic dotted enum-member validation.

The parser diagnostic says ATL group endpoints are unsupported and names the
missing contract: group-level trigger arbitration/fanout, event aggregation,
storage/lifetime, and generated-child wiring semantics. Dotted names that do
not match a declared static actor instance or static group keep the existing
enum-member diagnostics.
