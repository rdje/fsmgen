# Decision Trees and FSMs

FSMGen has two main direct authored roots:

- `?fsm:name`
- `?dt:name`

They are related, but not interchangeable.

## `?fsm:name`

Use `?fsm:name` when you are modeling an actual finite-state machine with:

- named states,
- transitions,
- sequential state-holding behavior,
- and optional non-state DT blocks alongside those states.

Typical ingredients:

- `+system`
- `+size`
- `+constants`, `+enums`, `+types`
- `:=` init/reset directives
- state blocks such as `idle`, `run`, `done`

## `?dt:name`

Use `?dt:name` for a standalone decision tree, especially when the logic is:

- decision-oriented,
- naturally described as decision-tree routing,
- or intended to be reused as a direct child in composition.

The current `?dt:name` contract is intentionally narrower than `?fsm:name`.

## State DTs and Non-State DTs

Inside an FSM root, a state DT is written as a normal state block such as
`(idle ...)` or `(run ...)`. A non-state DT is written with a leading dash such
as `(-route ...)`, `(-scl ...)`, or `(-counter_inc ...)`.

The block spelling does not decide whether the assignments are combinational or
sequential. Assignment operators do:

- `(= (lhs rhs))` is combinational.
- `(<- (lhs rhs))` is sequential/flopped with a Q/output-named LHS.
- `(<= (lhs rhs))` is sequential/flopped with a D-input/next-value-named LHS.

Therefore a state DT or a non-state DT can contain combinational assignments,
sequential assignments, or both, subject to the same assignment-family
validation rules described in the language basics chapter.

## Reset and Initialization

Current direct-root reset/init comes from two places:

- the conventional `+system` contract
- explicit `:=` directives

Prefer the canonical pair form:

```lisp
(:= (valid 0))
(:= (next_mode mode.IDLE))
(:= (reset_count (+ RESET_BASE EXTRA_RESET)))
```

The right-hand side is a constant-expression slot. It can be a literal, a
named constant, an enum member, a param/generic, an aggregate scalar leaf, or a
nested Lisp-ish arithmetic/bitwise expression. The older compact
`(:= signal=value)` spelling is kept as default-mode compatibility residue;
strict mode rejects it and points to `(:= (signal value))`.

Those reset/init rules are still documented as a live contract rather than as a
fully frozen language forever, so keep an eye on current wording in the
reference docs.

## State Transitions

Transitions target named FSM states in the same root.

Example:

```lisp
(idle
  (<start
    (-> active)
  )
)

(active
  (<done
    (-> idle)
  )
)
```

## Future Feature: Advanced DT Enable Control

Every DT/state block has a conceptual activity input: its `dt_enable`.
Today the author-facing `.fsm` language does not expose that input directly.
Normal authored DT/state blocks behave as if `dt_enable` is tied to `1` once
their surrounding root or state-selection context is active.

The intended future advanced feature is to expose that hidden control as a
semantic DT enable expression, still defaulting to `1` for existing sources.
An author should eventually be able to bind a DT/state block's enable to a
signal or bounded logical expression, for example an OR of several event/control
inputs. That would make it possible to model independently activatable
state-like regions, including designs that behave like they have multiple
initial/entry states.

A classic FSM with one reset/initial state and one active state at a time is
therefore the conservative subset, not the full model. The broader model treats
states and DT blocks as activation regions: a region can be active because of
the normal FSM state decode, the default `dt_enable = 1` behavior, an external
actor, or a validated logical expression. In that model, a state-like region can
be activated or deactivated outside the strict transition graph.

That power should be allowed, but it must not be invisible. Validation and
reports should make hazards explicit, including multiple active regions driving
the same target, conflicting assignment families, the selected merge/priority
policy, assertion hooks, and debug reporting. This is a power-user feature:
intent-level semantics, strong diagnostics, and no hidden backend magic.

This must be implemented as frontend intent, not as a late HDL-generation
shortcut. The parser should capture the authored enable expression, validation
should prove the referenced operands and widths before generation, the AST/IR
should preserve the DT enable contract, and only then should the selected HDL
backend emit the gated behavior.

## Practical Guidance

Prefer:

- `?fsm` when you need persistent state and explicit transitions
- `?dt` when you want a standalone routing/decision surface

If you later want hierarchy, both can participate in composition as generated
children through `?fsmc` and `?dtc`.
