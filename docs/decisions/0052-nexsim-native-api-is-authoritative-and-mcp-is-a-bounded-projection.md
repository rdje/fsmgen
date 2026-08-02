# 0052 — NEXSIM native semantic API is authoritative and MCP is a bounded projection

- Date: 2026-08-02
- Type: external simulator operability/consumer contract
- Status: accepted
- Extends: `0032`, `0036`, `0041`, `0045`, `0050`
- Evidence owner: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1`

## Context

NEXSIM is planned to expose deep semantic introspection through a clean API
that can be operated through MCP. A general intention to expose introspection
does not yet tell an API implementer what an expert engineering agent needs,
how large semantic results remain bounded, which operations require authority,
or how support claims become verifiable.

The consumer contract also needs to remain useful outside FSMGen. Requiring a
simulator to understand a particular client's private intent language,
intermediate representation, reference engine, or reasoning process would
couple independent projects and make the public boundary less reusable.

A complete standalone specification adds one focused maintained document, one
Knowledge Map fact card, and one one-line mdBook landing include. These are
new durable roles rather than unclassified or accidental document growth.

## Decision

Publish and maintain
`docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md` as the implementation-
neutral consumer requirements authority. It specifies observable contracts for
capability discovery, identity, provenance, build, elaboration, static and
runtime semantics, scheduler state, causality, control, authorized mutation,
replay, UVM, assertions, coverage, traces, orchestration, comparison,
reduction, evidence, performance, security, errors, conformance, and evolution.

The native typed NEXSIM semantic API is the semantic authority. MCP is a
faithful, typed, bounded, discoverable, and separately authorized projection
of the native API. Neither transport nor client-private architecture defines
simulator meaning.

Requested, accepted, implemented, and verified capability states remain
distinct. The requirements document makes no current NEXSIM support claim.
Future amendments are owned by the dedicated task-tree and must cite their
trigger, compatibility effect, affected requirement IDs, and evidence.

The new document is classified as live maintainer reference, the mdBook uses a
single include rather than duplicating its prose, and Knowledge Map routing
provides question-first discovery. The exact surface changes have the
following approved authorities:

- Ceiling authority: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1-FOCUSED-DOCUMENT`
- Surface: `focused_documents`
- Dimension: `files`
- Change: `1005 -> 1006`

- Ceiling authority: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1-KNOWLEDGE-CARD`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1105 -> 1106`

## Consequences

- NEXSIM can consume a precise requirements baseline without receiving or
  depending on FSMGen-private architecture.
- Agents and other clients can share stable semantic concepts while choosing
  different native bindings, MCP clients, storage, and reasoning systems.
- MCP cannot become an unbounded log/waveform dump, a second simulator
  authority, or an implicit grant of mutation, filesystem, process, or network
  access.
- NEXSIM may implement capabilities incrementally, but support discovery and
  conformance evidence must identify the exact implemented subset.
- Document growth remains explicit: the focused-document and knowledge-card
  file ceilings each rise by exactly one, while maintained-reference aggregate
  authority records the one-line mdBook landing.
