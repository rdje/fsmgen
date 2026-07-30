# 0028 — Source-facing HIR is a distinct private pre-IAL layer

- Date: 2026-07-30
- Type: architecture
- Status: accepted; implementation pending under `FSMGEN-HIR-ROADMAP-FRONTIER`

## Context

FSMGen's existing `IntentHIR` is constructed after direct `.fsm` parsing or
composition planning. `LoweredRTLIR` and `StructuralRTLIR` are later forward
compiler phases. Future high-level frontends need a checked semantic target
before IAL2/IAL1 without teaching every frontend every downstream rule.

Extending `IntentHIR` would mix pre-IAL authored semantics with a post-parse
forward summary. A text-only prototype would preserve reviewability but leave
future frontends without one stable object and diagnostic model.

## Decision

FSMGen will use a distinct private `FSM::IR::SourceHIR` semantic-intent layer
above IAL2 and IAL1. The first bounded producer is an internal constrained Perl
builder. The first consumer validates and canonically renders `.ppif`, then
passes that text through the existing PPIF parser/validator and the existing
`IAL2 -> IAL1 -> IAL0` path.

The first fixture is `ppif/valid_ready_handshake.ppif`, reproduced byte-for-
byte. The raw object, builder shape, and source map remain private. No public
host-language API, CLI mode, normalized-report projection, or support-
accounting promise is selected by the prototype.

The full IR-policy record, source-location rules, validation plan, exact owner
family, alternatives, and retirement conditions live in
`docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md`.

## Consequences

- Existing `IntentHIR`, `LoweredRTLIR`, and `StructuralRTLIR` owners and public
  projections remain unchanged.
- Canonical `.ppif` stays the inspectable compatibility boundary; the new IR
  does not bypass existing IAL2 validation.
- The first implementation is deliberately protocol-neutral and valid-ready-
  only. Concrete FSM-to-IAL1 and other protocol shapes require later owners.
- Public builder-language selection remains proposed under
  `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` until the private boundary is proved.
- SourceHIR may be removed without migration if it does not justify another
  producer or public promotion, because the first prototype exposes no public
  raw-object contract.
