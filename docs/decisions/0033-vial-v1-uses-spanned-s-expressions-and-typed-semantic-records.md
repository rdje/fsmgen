# 0033 — VIAL v1 uses spanned S-expressions and typed semantic records

- Date: 2026-07-31
- Type: language and compiler architecture
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`
- Refines: `0008`, `0032`

## Context

Decision `0032` selected one public `.vial` language and a private immutable
`VIALSemanticIR`, but left concrete syntax, parser ownership, type/value
semantics, provenance, and the first bounded implementation profile to `.2`.

FSMGen's existing Lispish source style is readable and familiar, but the
current `Lispish` reader returns nested arrays with normalization quirks and no
contract-grade byte/source spans. Publishing that representation would make a
legacy parser shape part of VIAL's API and undermine exact diagnostics,
semantic IDs, source maps, stable random-decision identity, and later backend
traceability.

VIAL also needs target-neutral four-state values and temporal checks without
silently inheriting SystemVerilog equality/scheduling or creating a second
property language beside decision `0008`.

## Decision

Use closed versioned S-expression syntax for `.vial`, parsed by a dedicated
span-aware VIAL lexer/parser. Reuse the repository's approachable notation,
but do not reuse or expose raw `Lispish` arrays. The parser hands closed forms
to a semantic builder and discards them after constructing private immutable
`FSM::VIAL::SemanticIR`.

Select target-neutral scalar domains (`bool`, `u`, `s`, `logic`, `slogic`),
ordered enum/record/list types, contextual checked integer literals, and
`#b` four-state literals normalized to value/known/Z masks. There is no
implicit truncation, signedness conversion, wrap, or X/Z coercion.

Reuse the canonical property operators `=>`, `next`, and `within` for VIAL
expectations and waits. VIAL adds typed sampled/event/model/choice references
and exact `same` versus known-only `value_eq`, but does not add a parallel
temporal language.

Select `core_directed_single_clock_v1` as the first parse/typecheck profile.
It includes explicit packages/imports, types, transactions, deterministic
models, bounded scoreboards, unbound typed DUT references, explicit bounded
coverage/fault/randomness/scenarios/concurrency, and the planned AHB
arbitration source. It emits only a sanitized semantic report and explicit
non-claims; bridge binding, execution, artifacts, and runtime remain later.

## Consequences

- Implementation `.3` owns dedicated Parser, SemanticBuilder, SemanticIR, and
  SemanticReport packages plus the first `.vial` source and focused t1550.
- All paths/imports come from repository-relative caller-supplied identities
  and an in-memory catalog; the parser performs no filesystem/network/cache
  discovery.
- Raw parser forms and raw semantic objects are private. Structured access and
  reports are defensive clones; bridge references remain explicitly
  unresolved binding assertions.
- Stable source spans, semantic paths, named semantic IDs, content identities,
  bounded limits, and deterministic diagnostic order are language invariants.
- Typed native extensions, logical-time execution, random algorithm/replay,
  public CLI/API/artifacts, backends, parity, and scale remain separately
  owned; this decision creates no shipped product behavior by itself.
- The exact grammar, object/report contracts, first source shape, validation,
  negative boundaries, and rollback are canonical in
  `docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md`.
