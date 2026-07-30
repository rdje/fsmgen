# 0030 — SourceHIR v2 is a semantic concrete-control subset

- Date: 2026-07-30
- Type: architecture
- Status: accepted by `FSMGEN-HIR-ROADMAP-FRONTIER.6`
- Refines: `0029`
- Refined by: `0031`

## Context

Decision `0029` requires a second private SourceHIR route to canonical IAL1
before public promotion is reconsidered. The route must test whether the shared
immutable/provenance boundary survives concrete control without embedding raw
ISF syntax or cloning the IAL1 parser AST.

The mature `isf/phase_test.isf` fixture is a 17-line checked actor with ordered
ports, one parameterized named drive, one trigger, three concrete transaction
phase states, and one completion. Existing t1179/t1312 coverage owns parser,
schedule, strict CLI, and HDL reachability behavior.

## Decision

SourceHIR version 2 adds a private discriminated `concrete_control` root. It
models a closed semantic actor subset—clock/reset, ordered typed scalar ports,
parameter-to-output named drives, and linear trigger/phase/completion
transactions—and renders `isf/phase_test.isf` byte-for-byte through a new
private `FSM::IR::SourceHIRISFRenderer`.

The rendered text must enter the existing ISF adapter and scheduler. SourceHIR
does not construct the typed ISF AST directly, call the scheduler directly, or
store arbitrary Lispish forms or expression strings.

The exact schema, APIs, validation, provenance, diagnostics, source map,
golden hashes, test owner, and deferrals live in
`docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md`.

Clean decision commit `f42fb033d` activates only the separate `.7` private
implementation leaf; activation changes none of the selected code or behavior.

Leaf `.7` subsequently implemented the exact decision in
`FSM::IR::SourceHIR`, `FSM::IR::SourceHIRBuilder`, and
`FSM::IR::SourceHIRISFRenderer`. Focused t1548 proves byte-identical ISF,
equal typed-actor/schedule results, the exact IAL0 hash, provenance remapping,
and no public exposure; t1547/t1179/t1312 preserve the existing routes.

## Consequences

- Version 1 remains unchanged and private.
- Version 2 extends the existing SourceHIR object/builder and adds one private
  ISF renderer plus focused t1548.
- `isf/phase_test.isf` remains the tracked source oracle and is not rewritten.
- Arbitrary control flow, expressions, ATL/composition, protocol policy, and
  every public HIR/builder/report/accounting surface remain deferred.
- If implementation requires raw ISF fragments or parser-AST duplication, the
  route fails the decision and must be reconsidered rather than widened.
