# ISF-PORT-BINDING: Transaction Ports And Actor Pin Access

## Metadata

- Tree ID: `ISF-PORT-BINDING`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Add an ISF-level surface for connecting variables, actor storage, and actor
top-level pins to transaction ports, so transactions and rules can exchange
data and control intent without authors dropping to low-level `.fsm` wiring.

The feature should make transaction boundaries feel like hardware module or
block boundaries: ports are declared with direction and width, call/use sites
bind those ports explicitly, and the scheduler lowers the connections to
reviewable `.fsm` signals with conflict checks.

## Non-Goals

- Do not expose raw `.fsm` handoff wiring as the authoring surface.
- Do not add implicit multi-driver merging. Any write fan-in must be explicit,
  conflict-checked, or priority/resource-mediated.
- Do not allow writes to actor input pins; actor inputs are readable external
  observations.
- Do not hide transaction lifetime, start/done, or spawned-instance busy
  behavior behind software-call semantics.
- Do not make transaction port binding a textual macro system.

## Acceptance Criteria

- Transaction port declaration syntax is specified with direction, width,
  lifetime, reset/initial value policy where relevant, and duplicate-name
  diagnostics.
- Transaction invocation or activation syntax can explicitly bind actor
  variables, storage, top-level pins, or expressions to transaction ports.
- Rules and transactions have a clear contract for reading actor inputs and
  driving actor outputs, including same-cycle visibility and conflict
  behavior.
- Lowering is defined through scheduled `.fsm` review artifacts, not hidden
  backend-only wiring.
- Schedule reports expose bounded provenance for transaction ports and
  bindings when the feature ships.
- Focused regressions prove parser diagnostics, lowering, schedule-report
  projection, conflict behavior, and SystemVerilog generation for accepted
  cases.

## Task Tree

- ID: `ISF-PORT-BINDING`
  Status: `active`
  Goal: `Specify and implement transaction port binding plus actor pin
  access.`
  Children: `ISF-PORT-BINDING.1`, `ISF-PORT-BINDING.2`,
  `ISF-PORT-BINDING.3`, `ISF-PORT-BINDING.4`,
  `ISF-PORT-BINDING.5`

- ID: `ISF-PORT-BINDING.1`
  Status: `done`
  Goal: `Specify the public transaction-port and actor-pin access contract.`
  Acceptance: The task tree, mdBook, spec, and live docs define source
  syntax candidates, direction rules, binding sites, same-cycle visibility,
  allowed actor pin reads/writes, conflict policy, report fields, diagnostics,
  and the lowering path into explicit `.fsm`.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PORT-BINDING.1: specify port binding contract`

- ID: `ISF-PORT-BINDING.2`
  Status: `pending`
  Goal: `Implement transaction port declarations and parser diagnostics.`
  Acceptance: Transactions accept the selected port-declaration syntax,
  reject malformed, duplicate, unknown-width, or direction-invalid forms, and
  preserve a scheduler-consumable normalized shell without freezing raw parser
  internals.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PORT-BINDING.3`
  Status: `pending`
  Goal: `Implement explicit transaction port bindings at activation sites.`
  Acceptance: Supported transaction activations bind declared ports to actor
  variables, storage, or top-level pins with exact direction and width checks,
  lower to reviewable `.fsm` handoff signals, and fail closed for missing,
  duplicate, direction-mismatched, or width-mismatched bindings.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PORT-BINDING.4`
  Status: `pending`
  Goal: `Integrate actor pin access with assignment and conflict semantics.`
  Acceptance: Actor input reads and actor output writes through rules and
  transactions use the same assignment/conflict model as other ISF regions,
  including compatible fan-in, priority/resource handling where already
  shipped, and runtime selector-conflict instrumentation where applicable.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PORT-BINDING.5`
  Status: `pending`
  Goal: `Publish report, docs, and fixture coverage for the shipped surface.`
  Acceptance: Schedule reports expose bounded port/binding provenance, docs
  and mdBook match the implementation, realistic fixtures use the new surface
  without low-level hacks, and the public contract advertises only the
  regression-backed key families.
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-PORT-BINDING.2` | `pending` | The source contract now exists; the next slice should implement parser support for declared transaction ports and fail-closed diagnostics. |

## Design Notes

- This is an ISF feature, not an author-facing `.fsm` escape hatch. The
  implementation should still lower to explicit `.fsm` so reviewers can see
  the handoff signals, guards, mux selectors, and assignment operators.
- Transaction ports should be directional. A transaction input is read by the
  transaction and driven by the caller/binding context. A transaction output
  is driven by the transaction and read by the caller/binding context.
- Actor top-level input pins are readable observations. Actor top-level output
  pins are writable targets, subject to the same conflict model as other LHS
  signals.
- Same-cycle visibility must be explicit. If a caller binds a variable to a
  transaction input in the activation cycle, the specification must say whether
  the transaction sees that value in the first active state or in a later
  state, and which assignment operator family implements that behavior.
- Rules that trigger transactions need a port-binding story before the model
  is fully ergonomic. Directly pulsing a transaction start input works for
  control-only transactions, but data-bearing activations need per-trigger
  payload ownership and conflict handling.
- Multiple rules or transactions writing the same actor output or the same
  transaction input binding in one cycle must not silently merge. Compatible
  same-value fan-in, explicit priority, or verification-only runtime conflict
  instrumentation should carry the existing conflict policy forward.

## Decisions

- `2026-05-15`: Treat transaction port binding and actor pin access as an
  ISF-level feature with explicit `.fsm` lowering, not as a low-level author
  escape hatch.
- `2026-05-15`: Actor input pins are readable but not writable. Actor output
  pins are writable only through the normal ISF assignment/conflict model.
- `2026-05-15`: Do not implement syntax before specifying same-cycle
  visibility, direction checking, width checking, binding lifetime, and
  conflict/report behavior.
- `2026-05-15`: Candidate syntax uses a transaction-local `(ports ...)`
  declaration and activation-local `(bind ...)` blocks on `(do ...)`,
  `(spawn ...)`, and `(trigger ...)`, pending implementation validation.
- `2026-05-15`: Same-cycle visibility remains the key implementation
  decision. The first implementation must choose live binding, activation
  snapshot, or explicit author-selected timing before parser acceptance.

## Open Questions

- Should transaction ports be declared in a dedicated `(ports ...)` clause,
  reused from `(interface ...)`, or separated into input/output-specific
  clauses?
- Should data-bearing `(trigger transaction ...)` use inline bindings, a named
  binding block, or a rule-local trigger object?
- Should `(do child)` and `(spawn child as name)` share one binding syntax, or
  should spawned-instance bindings be instance-scoped because the hardware
  child persists?
- What is the first safe same-cycle visibility rule for input bindings:
  immediate D-side visibility, next-state Q-side visibility, or explicit
  author selection?
- Which report fields are useful enough to publish without freezing raw
  LoweringIR binding internals?

## Blockers

- None for the specification leaf. Implementation leaves are blocked until
  `ISF-PORT-BINDING.1` fixes the source syntax and runtime contract.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-PORT-BINDING` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PORT-BINDING.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PORT-BINDING` | `R14: activate ISF port binding tree` | Task tree activation from transaction-port and actor-pin access discussion. |
| `ISF-PORT-BINDING.1` | `ISF-PORT-BINDING.1: specify port binding contract` | Transaction port declaration/binding candidates, actor pin read/write policy, same-cycle visibility decision point, and conflict/report requirements. |

## Changelog

- `2026-05-15`: Created the active transaction-port and actor-pin access task
  tree from the ISF feature discussion.
- `2026-05-15`: Specified the first public contract direction in the spec,
  mdBook backlog, and public contract notes before implementation.
