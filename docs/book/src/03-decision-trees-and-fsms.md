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
- and optional combinational helper DTs alongside those states.

Typical ingredients:

- `+system`
- `+size`
- `+constants`, `+enums`, `+types`
- `:=` init/reset directives
- state blocks such as `idle`, `run`, `done`

## `?dt:name`

Use `?dt:name` for a standalone decision tree, especially when the logic is:

- combinational,
- naturally described as decision-tree routing,
- or intended to be reused as a direct child in composition.

The current `?dt:name` contract is intentionally narrower than `?fsm:name`.

## Reset and Initialization

Current direct-root reset/init comes from two places:

- the conventional `+system` contract
- explicit `:=` directives

Those are still documented as a live contract rather than as a fully frozen
language forever, so keep an eye on current wording in the reference docs.

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

## Practical Guidance

Prefer:

- `?fsm` when you need persistent state and explicit transitions
- `?dt` when you want a standalone routing/decision surface

If you later want hierarchy, both can participate in composition as generated
children through `?fsmc` and `?dtc`.
