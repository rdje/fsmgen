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
  Status: `done`
  Goal: `Implement transaction port declarations and parser diagnostics.`
  Acceptance: Transactions accept the selected port-declaration syntax,
  reject malformed, duplicate, unknown-width, or direction-invalid forms, and
  preserve a scheduler-consumable normalized shell without freezing raw parser
  internals.
  Verification: `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `prove -I perl t/1240-isf-transaction-port-declarations.t`; focused public
  contract/CI-tier suite; `./bin/ci-regression isf --no-book`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PORT-BINDING.2: parse transaction ports`

- ID: `ISF-PORT-BINDING.3`
  Status: `done`
  Goal: `Implement explicit transaction port bindings at activation sites.`
  Acceptance: Supported transaction activations bind declared ports to actor
  variables, storage, or top-level pins with exact direction and width checks,
  lower to reviewable `.fsm` handoff signals, and fail closed for missing,
  duplicate, direction-mismatched, or width-mismatched bindings.
  Verification: `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`;
  `prove -I perl t/1241-isf-transaction-port-bindings.t`; adjacent
  do/spawn/rule regression suite; focused public contract/CI-tier suite;
  `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `ISF-PORT-BINDING.3: lower transaction port bindings`

- ID: `ISF-PORT-BINDING.4`
  Status: `done`
  Goal: `Integrate actor pin access with assignment and conflict semantics.`
  Acceptance: Actor input reads and actor output writes through rules and
  transactions use the same assignment/conflict model as other ISF regions,
  including compatible fan-in, priority/resource handling where already
  shipped, and runtime selector-conflict instrumentation where applicable.
  Verification: `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -I perl -c t/1242-isf-port-binding-conflict-semantics.t`;
  focused provenance/conflict/runtime selector suite; public contract and
  CI-tier metadata suite; `./bin/ci-regression isf --no-book`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-PORT-BINDING.4: align port binding conflicts`

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
| 1 | `ISF-PORT-BINDING.5` | `pending` | Binding conflict semantics now have first shipped coverage; the next slice should decide and publish the bounded schedule-report projection for port/binding provenance. |

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
- Same-cycle visibility for the first shipped binding surface is explicit:
  input payloads are emitted in the same activation region as their
  start/trigger handoff, and spawned child bindings use live generated-top
  handoff wiring. A future snapshot-vs-live choice needs a separate spelling.
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
- `2026-05-15`: Do not implement activation-binding syntax before specifying
  same-cycle visibility, direction checking, width checking, binding lifetime,
  and conflict/report behavior.
- `2026-05-15`: Shipped declaration syntax uses a transaction-local
  `(ports ...)` clause. Shipped binding syntax uses activation-local
  `(bind ...)` blocks on `(do ...)`, `(spawn ...)`, and rule `(trigger ...)`;
  rule triggers currently accept input bindings only.
- `2026-05-15`: Same-cycle visibility for the shipped scalar bindings is
  activation-region visibility for `do` and rule-trigger payloads, and live
  generated-top handoff wiring for spawned child bindings.
- `2026-05-15`: Transaction-local `(ports ...)` declarations are accepted by
  the parser as public actor-shell metadata only. Each transaction has one
  normalized `ports` hash with directional `inputs` and `outputs` arrays of
  `name`/`width` entries; the declaration is removed from scheduler body
  clauses until activation bindings and lowering ship.
- `2026-05-15`: Scalar `do`, `spawn`, and rule-trigger input bindings now
  lower to reviewable `.fsm`. `do` uses the parent await state, `spawn` uses
  hidden generated-top handoff ports plus a parent binding DT, and rule
  triggers use per-rule payload source signals before fan-in.
- `2026-05-15`: Spawned output bindings now carry parent-transaction
  ownership in assignment provenance and feed the existing rule/transaction
  conflict pass. Accepted spawn-output fan-in and rule-trigger input payload
  fan-in reach backend verification-only selector instrumentation through
  ordinary `.fsm` assignments.

## Open Questions

- Should rule-trigger output bindings remain unsupported, lower as completion
  callbacks, or require a separate awaited rule/transaction composition form?
- Should expression-valued input bindings gain an explicit `(width N)` option
  or be modeled through named variables only?
- Which report fields are useful enough to publish without freezing raw
  LoweringIR binding internals?

## Blockers

- None for `ISF-PORT-BINDING.5`. Remaining edge cases are rule-trigger output
  binding, expression-valued binding width contracts, and richer static
  conflict/report projection.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-PORT-BINDING` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PORT-BINDING.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PORT-BINDING.2` | `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -I perl t/1240-isf-transaction-port-declarations.t`; focused public contract/CI-tier suite; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PORT-BINDING.3` | `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `prove -I perl t/1241-isf-transaction-port-bindings.t`; adjacent do/spawn/rule regression suite; focused public contract/CI-tier suite; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PORT-BINDING.4` | `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -I perl -c t/1242-isf-port-binding-conflict-semantics.t`; focused provenance/conflict/runtime selector suite; focused public contract/CI-tier suite; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PORT-BINDING` | `R14: activate ISF port binding tree` | Task tree activation from transaction-port and actor-pin access discussion. |
| `ISF-PORT-BINDING.1` | `ISF-PORT-BINDING.1: specify port binding contract` | Transaction port declaration/binding candidates, actor pin read/write policy, same-cycle visibility decision point, and conflict/report requirements. |
| `ISF-PORT-BINDING.2` | `ISF-PORT-BINDING.2: parse transaction ports` | Parser-normalized transaction `(ports ...)` declarations with fail-closed diagnostics and public actor-shell contract coverage. |
| `ISF-PORT-BINDING.3` | `ISF-PORT-BINDING.3: lower transaction port bindings` | Scalar activation bindings for `do`, `spawn`, and rule-trigger input payloads with generated handoff wiring and diagnostics. |
| `ISF-PORT-BINDING.4` | `ISF-PORT-BINDING.4: align port binding conflicts` | Spawn output bindings now have parent transaction provenance and fail-closed rule/transaction conflict coverage; accepted binding fan-in reaches runtime selector assertions. |

## Changelog

- `2026-05-15`: Created the active transaction-port and actor-pin access task
  tree from the ISF feature discussion.
- `2026-05-15`: Specified the first public contract direction in the spec,
  mdBook backlog, and public contract notes before implementation.
- `2026-05-15`: Implemented parser support for transaction `(ports ...)`
  declarations as public actor-shell metadata, with malformed declaration
  diagnostics and regression coverage.
- `2026-05-15`: Implemented scalar activation-time port bindings for `do`,
  `spawn`, and rule-trigger input payloads, including generated-top handoffs,
  per-rule payload fan-in, and malformed binding diagnostics.
- `2026-05-15`: Integrated spawned output binding assignments with parent
  transaction provenance and existing rule/transaction conflict semantics, and
  locked runtime selector instrumentation for accepted binding fan-in.
