# 0028 — Source-facing HIR is a distinct private pre-IAL layer

- Date: 2026-07-30
- Type: architecture
- Status: accepted and privately implemented by `FSMGEN-HIR-ROADMAP-FRONTIER.4`

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
- Decision `0029` refines the post-prototype state: the proved valid-ready
  boundary remains private through a second concrete-control-to-IAL1 route and
  another evidence audit.
- SourceHIR may be removed without migration if it does not justify another
  producer or public promotion, because the first prototype exposes no public
  raw-object contract.

## Implementation

`FSM::IR::SourceHIR`, `FSM::IR::SourceHIRBuilder`, and
`FSM::IR::SourceHIRPPIFRenderer` implement the private valid-ready boundary.
Focused t1547 proves the byte-identical golden, existing-parser handoff,
diagnostic provenance, immutability, and unchanged IAL1/IAL0/report results.
No public surface is advertised.

The post-prototype outcome is recorded separately by decision `0029`; this
record's original first-prototype selection remains intact.
