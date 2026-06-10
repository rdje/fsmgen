# 0013 — Compositional Control-Flow/Activation Model

Date: 2026-06-10

Type: architecture

## Context

ISF control-flow and activation support has grown through exact, signoff-safe
slices. That protected hardware correctness, but it also produced an
enumerated support surface: individual syntax paths such as
`while -> when -> repeat -> plain local do` have to be named before they are
accepted.

The long-term direction is a uniform control-flow/activation model where
combinations are supported by construction. In that model, each control-flow
construct exposes a typed region contract and each activation/synchronization
construct exposes typed effects. Validators and lowerers should accept a
combination when those contracts prove the required hardware invariants, not
because a hand-written allow-list names that path.

## Decision

Adopt a typed region/effect architecture for ISF control-flow and activation.

The model must represent, at minimum:

- region entry and normal exits;
- loop backedges;
- branch and loop conditions;
- local child start/done effects;
- generated child start/done effects;
- `spawn`, `await_any`, and `await_all` outstanding-child effects;
- binding, domain, and CDC requirements;
- deterministic generated-child instance identity;
- public report/doc implications.

Rollout must be staged:

1. Build the model in shadow mode first, with no behavior widening.
2. Prove parity on existing accepted and rejected fixtures.
3. Add invariant checks over the shadow effects.
4. Migrate discovery/planning/validation one family at a time.
5. Widen combinations only when the model proves the invariants.
6. Simplify public docs from enumerated combinations to construction rules once
   the implementation actually supports those rules.

## Required Hardware Invariants

- A spawned/static child must not be restarted before its previous activation is
  drained or explicitly governed by a proven lifetime rule.
- Loop backedges must be dominated by required child completion checks.
- `await_any` observes completion; it does not drain all outstanding children.
- Generated children must have deterministic static instance names and complete
  generated-top wiring before a source shape is accepted.
- Bindings, domains, and CDC cannot be inferred implicitly.
- Reports, diagnostics, mdBook, and spec wording must match emitted hardware.

## Consequences

- New architecture work belongs to
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE`.
- Existing hardcoded validators remain in force until a migrated effect checker
  proves equivalent or stricter behavior.
- The project may temporarily carry both the existing lowerer walks and the new
  shadow region/effect inventory.
- Documentation must continue to state exact shipped behavior; it may not claim
  "all combinations" until validator, lowering, generated-top planning, and
  lifetime checks are actually migrated.
