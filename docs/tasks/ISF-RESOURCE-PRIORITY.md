# ISF-RESOURCE-PRIORITY: Resource Arbitration And Priority Enforcement

## Metadata

- Tree ID: `ISF-RESOURCE-PRIORITY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Turn ISF `(resources ...)`, actor-level priority metadata, and rule-local
priority metadata from validated informational declarations into scheduler
behavior that enforces mutual exclusion, priority ordering, and clear
diagnostics for unresolved arbitration.

## Non-Goals

- Do not silently resolve incompatible same-cycle drives without an explicit
  resource, priority, or conflict policy.
- Do not implement a broad generic arbiter library beyond the resource
  arbiters accepted by the ISF contract.
- Do not duplicate `ISF-CONFLICTS`; that tree owns same-target conflict domain
  vocabulary and lower-level drive compatibility.

## Acceptance Criteria

- Existing resource and priority metadata parsing/validation is inventoried.
- The relationship between resource arbitration, priority resolution, and
  same-cycle conflict handling is documented.
- Resource mutual exclusion lowers into deterministic scheduler behavior or
  fails closed when the requested arbitration is not supported.
- Actor-level and rule-local priorities affect conflict/arbitration outcomes
  for the covered cases.
- Diagnostics identify missing, ambiguous, circular, or unsupported arbitration
  semantics.
- Focused tests, schedule-report metadata, ISF spec, public contract, mdBook,
  roadmap, and live docs agree.

## Task Tree

- ID: `ISF-RESOURCE-PRIORITY`
  Status: `done`
  Goal: `Ship resource arbitration and priority enforcement for ISF.`
  Children: `ISF-RESOURCE-PRIORITY.1`, `ISF-RESOURCE-PRIORITY.2`,
  `ISF-RESOURCE-PRIORITY.3`, `ISF-RESOURCE-PRIORITY.4`,
  `ISF-RESOURCE-PRIORITY.5`, `ISF-RESOURCE-PRIORITY.6`

- ID: `ISF-RESOURCE-PRIORITY.1`
  Status: `done`
  Goal: `Inventory current resource and priority metadata behavior.`
  Acceptance: `The task file lists accepted resource forms, accepted priority
  forms, existing validations, schedule-report exposure, and enforcement gaps.`
  Verification: `prove -l t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.1: inventory metadata behavior`

- ID: `ISF-RESOURCE-PRIORITY.2`
  Status: `done`
  Goal: `Specify arbitration and priority semantics.`
  Acceptance: `The tree records mutual-exclusion rules, supported arbiters,
  actor-level priority ordering, rule-local priority ordering, ties, cycles,
  and unsupported cases.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.2: specify arbitration semantics`

- ID: `ISF-RESOURCE-PRIORITY.3`
  Status: `done`
  Goal: `Implement resource mutual-exclusion lowering.`
  Acceptance: `The scheduler enforces the covered resource conflicts with
  deterministic generated artifacts or targeted fail-closed diagnostics.`
  Verification: `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.3: enforce rule-slot resources`

- ID: `ISF-RESOURCE-PRIORITY.4`
  Status: `done`
  Goal: `Implement priority resolution for covered rule/transaction conflicts.`
  Acceptance: `Actor-level and rule-local priority declarations affect the
  covered scheduler decisions and reject unresolved or cyclic cases.`
  Verification: `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t t/1219-isf-rule-transaction-priority.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.4: resolve rule-transaction priority`

- ID: `ISF-RESOURCE-PRIORITY.5`
  Status: `done`
  Goal: `Integrate arbitration with conflict diagnostics and schedule reports.`
  Acceptance: `Accepted arbitration decisions and rejected conflicts are
  visible in bounded report metadata and targeted diagnostics.`
  Verification: `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1096-isf-schedule-json-report.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1213-isf-schedule-report-compatible-fanin-projection.t t/1220-isf-arbitration-schedule-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.5: report arbitration decisions`

- ID: `ISF-RESOURCE-PRIORITY.6`
  Status: `done`
  Goal: `Add tests and synchronize docs.`
  Acceptance: `Tests cover accepted arbitration, priority ordering, ties,
  cycles, unsupported arbiters, diagnostics, and synchronized user-facing docs.`
  Verification: `prove -l t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t t/1219-isf-rule-transaction-priority.t t/1220-isf-arbitration-schedule-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.6: close resource priority tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-RESOURCE-PRIORITY` is complete; PNT should continue with the next active tree in `docs/TASK_TREE.md`. |

## ISF-RESOURCE-PRIORITY.1 Inventory

This inventory records shipped behavior at the completion of
`ISF-RESOURCE-PRIORITY.1`. It is not a frozen API claim: the ISF public
surface is live and may evolve alongside FSMGen as the resource/priority
implementation becomes more complete.

### Accepted Resource Forms

- Resource declarations are accepted only as an actor-level singleton
  `(resources ...)` block.
- Each entry must have the exact shape
  `(resource name (arbiter priority))` or
  `(resource name (arbiter round_robin))`.
- `name` must be a non-empty scalar token.
- The only accepted arbiter names are `priority` and `round_robin`.
- Duplicate resource names in the same block are rejected.
- A repeated actor-level `(resources ...)` block is rejected by the general
  actor singleton-clause validation.

Current storage: the parser returns
`resources => [ { name => ..., arbiter => ... }, ... ]` in the actor shell.

### Accepted Priority Forms

- Actor-level priority is accepted as `(priority lhs over rhs)`.
- Actor-level `lhs` and `rhs` must be non-empty scalar tokens naming declared
  same-actor transactions or rules. Forward references are accepted because
  targets are validated after the full actor body is parsed.
- Actor-level priority is stored as
  `priorities => [ [ lhs, 'over', rhs ], ... ]`.
- Rule-local priority is accepted as a rule action
  `(priority over other_rule)`.
- Rule-local `other_rule` must be a non-empty scalar token naming a declared
  same-actor rule. Forward references are accepted.
- Rule-local priority is preserved in the rule action list as
  `[ 'priority', 'over', other_rule ]`.

### Existing Validations

- Malformed resource entries fail before actor-shell return.
- Unsupported arbiter names fail before actor-shell return.
- Duplicate resource names fail before actor-shell return.
- Repeated `(resources ...)` actor blocks fail before actor-shell return.
- Malformed actor-level priority forms fail before actor-shell return.
- Actor-level priority targets must resolve to declared same-actor
  transactions or rules before actor-shell return.
- Malformed rule-local priority forms fail before actor-shell return.
- Rule-local priority targets must resolve to declared same-actor rules before
  actor-shell return.
- Priority cycles in the currently enforced same-target rule/rule data-conflict
  path fail closed with `isf_priority_cycle_conflict`.
- Priority attempts to resolve mixed assignment timing operators fail closed
  with `isf_priority_mixed_timing_conflict`.

### Enforcement At Inventory Time

- `(resources ...)` is not enforced by the scheduler today. A declared
  resource does not yet create mutual exclusion, grants, arbitration state, or
  generated HDL.
- Rule-local and actor-level priority are enforced only for same-target
  rule/rule data assignments when the conflicting owners are rules and the
  assignment operators match.
- Actor-level priority edges participate in that enforcement only when both
  priority endpoints are rules. Transaction endpoints are validated metadata
  today.
- A compatible same-target same-value rule write does not need priority; it is
  treated as compatible fan-in.
- When one rule dominates another through the priority graph, only the losing
  conflicting assignment is suppressed. The lowerer keeps unrelated actions in
  the losing rule alive.
- Suppression is implemented by ANDing the losing assignment guard with the
  inverse of the winning rule condition. Assignment provenance records
  `priority_suppressed_by` for internal analysis and downstream conflict
  filtering.
- If two conflicting rules are incomparable, the existing conflict diagnostic
  path remains responsible for failing closed.

### Schedule-Report Exposure

- Schedule JSON does not currently expose authored `resources`.
- Schedule JSON does not currently expose authored actor-level or rule-local
  priority declarations.
- Schedule JSON does not currently expose successful priority-resolution
  decisions or `priority_suppressed_by` bookkeeping.
- Nonfatal compile issues can appear in reports for other conflict domains,
  but the currently fatal priority-resolution issues stop lowering before a
  successful schedule report is emitted.

### Enforcement Gaps

- There is no source syntax yet that binds a transaction, rule, drive, or
  output to a declared resource.
- `round_robin` is parser-accepted but has no scheduler or HDL implementation.
- `priority` resource arbitration is parser-accepted but is not connected to
  resource users or generated grants.
- Actor-level priority that references transactions is validated but not
  enforced.
- Rule-local priority only orders rule/rule data conflicts. It does not yet
  order transaction starts, resource requests, named-drive calls, or broader
  owner-level scheduling.
- Successful arbitration decisions are not visible in bounded schedule-report
  metadata.
- The scheduler does not yet diagnose unused resources or priorities that are
  valid but have no effect.

### Regression Evidence

- [t/1176-isf-resource-priority-boundary.t](../../t/1176-isf-resource-priority-boundary.t)
  covers accepted resources/priorities, malformed resource syntax,
  unsupported arbiters, duplicate resources, malformed actor priority, and
  malformed rule priority.
- [t/1190-isf-rule-priority-target-boundary.t](../../t/1190-isf-rule-priority-target-boundary.t)
  covers rule-local priority forward references and unknown target rejection.
- [t/1191-isf-actor-priority-target-boundary.t](../../t/1191-isf-actor-priority-target-boundary.t)
  covers actor-level priority forward references and unknown lhs/rhs target
  rejection.
- [t/1210-isf-priority-conflict-resolution.t](../../t/1210-isf-priority-conflict-resolution.t)
  covers same-target rule/rule priority suppression, actor-level rule
  priority suppression, scheduled `.fsm` guard output, HDL handoff, and cycle
  rejection.

## ISF-RESOURCE-PRIORITY.2 Semantics

This section defines the target semantics for the next resource/priority
implementation slices. It separates what the parser accepts today from what
the scheduler is allowed to enforce next.

### Resource Model

- ISF resources need two orthogonal pieces of information: the shareable
  resource kind and the arbiter policy.
- The resource name, such as `shared_bus`, `mem_port`, or `csr_window`, is the
  author-defined instance handle.
- The resource kind tells the scheduler what is being shared and therefore how
  a grant affects lowering.
- The `arbiter` field names the arbitration policy for that resource kind.
- The only parser-accepted arbiter policy names are `priority` and
  `round_robin`.
- A resource is a single-grant domain for the covered implementation. At most
  one bound user may be granted in a cycle.
- A declared resource with no bound users remains accepted metadata and has no
  scheduler effect.

### Shareable Resource Kind Catalog

The resource-kind catalog starts deliberately small and should grow only when a
kind has a clear lowering path, runtime semantics, diagnostics, and report
surface.

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | first implementation target | One-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | backlog | A group of actor outputs or LHS targets that must have one owner for a cycle. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `transaction_start` | backlog | The start/request fan-in for one transaction. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |
| `storage_port` | backlog | A shared state/register/memory-port access path. |

Unsupported resource kinds must fail closed when authors try to use them for
enforced arbitration. A future slice may add kinds to this list, but it must
also define their lowering and diagnostics before they are treated as shipped.

### Resource User Binding

The first enforceable resource syntax should extend the existing resource
entry with an explicit `kind` plus an optional `users` clause:

```lisp
(resources
  (resource shared_bus
    (kind rule_slot)
    (arbiter priority)
    (users high_pri low_pri)))
```

The existing metadata-only spelling remains accepted:

```lisp
(resources
  (resource shared_bus (arbiter priority)))
```

Target binding rules:

- Enforced resources require a supported `kind` clause. The first supported
  kind is `rule_slot`.
- `users` names are non-empty scalar tokens.
- Duplicate user names inside one resource are rejected.
- The first enforceable user kind for `rule_slot` is a rule name.
- User names must resolve to declared same-actor rules for the first
  implementation. Unknown names fail closed before scheduled `.fsm` emission.
- Ambiguous names that resolve to more than one future user namespace must fail
  closed until a namespace-qualified syntax is introduced.
- Transaction users, named-drive users, output-target users, child-instance
  users, storage-port users, and whole transaction-lifetime ownership are
  deferred. They need resource-kind-specific hold/release and re-entry
  contracts before being enforced.

The syntax is intentionally centralized under `(resources ...)` instead of
being parsed as a rule action. That avoids collisions with the current
`(port value)` rule-action shape and keeps resource mapping next to resource
policy.

### Priority Arbiter Semantics

`priority` is the first implementation-ready resource arbiter for bound
`rule_slot` users.

For a priority-arbitrated resource:

- Each bound rule requests the resource in cycles where that rule's normalized
  guard is true.
- Rule-local `(priority over other_rule)` adds an ordering edge from the
  containing rule to `other_rule`.
- Actor-level `(priority lhs over rhs)` adds an ordering edge for resource
  arbitration when both endpoints are bound rule users of the same resource.
- Priority edges are transitive.
- Duplicate identical edges are harmless.
- A cycle in the priority graph fails closed.
- A resource with two or more bound rule users requires a deterministic unique
  winner for any possible simultaneous request. The first implementation
  should require a total ordering across bound users unless a later proof pass
  can prove the unordered users mutually exclusive.
- Incomparable bound users are therefore rejected for enforced priority
  resources in the first implementation.
- The winner is the active requester that has no active higher-priority bound
  requester.
- A lower-priority rule is denied only while a higher-priority bound requester
  is active. When no higher requester is active, the lower-priority rule can
  still run.
- The generated resource grant gates the whole lowered rule DT DTE.
  Assignment-specific priority suppression for same-target rule/rule data
  conflicts stays target-local and composes with the resource grant.

Conceptually, for a resource with `high > low`, the rule DTEs become:

```text
high_grant = high_guard
low_grant  = low_guard & !high_guard
```

For a longer order `r0 > r1 > r2`, the grant shape is:

```text
r0_grant = r0_guard
r1_grant = r1_guard & !r0_guard
r2_grant = r2_guard & !(r0_guard | r1_guard)
```

The generated form is combinational and does not add a cycle.

### Round-Robin Arbiter Semantics

`round_robin` remains parser-accepted metadata, but it is not
implementation-ready for enforced resources.

Reason: a real round-robin arbiter introduces state. The contract still needs
to define reset value, grant advance point, whether the pointer advances on
request or accepted grant, behavior when no requester is active, and report/
debug visibility for each resource kind. Until that is settled, a
`round_robin` resource with bound users must fail closed instead of silently
behaving like priority arbitration.

### Priority Declarations Outside Resources

Existing same-target rule/rule data priority remains target-local:

- It suppresses the losing assignment only.
- It does not disable unrelated actions in the losing rule.
- It does not by itself claim a resource.

Resource priority is owner-level for the bound rule:

- It gates the rule's non-state DT DTE for the resource-protected rule.
- It can suppress triggers and all data actions in that rule while a higher
  requester is active.
- It is the right mechanism when the user wants mutual exclusion over a shared
  resource, not merely conflict resolution for one target.

Actor-level priorities that mention transactions remain validated metadata
until transaction priority semantics are implemented. They do not participate
in first-pass rule-resource arbitration unless both endpoints are bound rules
of the same resource.

### Ties, Cycles, And Unsupported Cases

Fail closed:

- Unknown resource user.
- Duplicate user inside one resource.
- Ambiguous user namespace.
- Unsupported resource kind.
- Priority cycle among bound users.
- Incomparable bound users in an enforced `priority` resource.
- `round_robin` resource with bound users before round-robin lowering ships.
- Transaction, drive, output-target, child-instance, storage-port, dynamic,
  nested, or multi-capacity resource users before their contracts ship.

Allowed no-op metadata:

- A valid resource declaration with no `users` clause.
- A priority declaration that is valid but irrelevant to the currently covered
  rule/rule data or rule-resource arbitration path.

### Conflict Interaction

- Resource arbitration can prevent same-cycle conflicts by making at most one
  bound rule active for that resource in a cycle.
- Resource arbitration does not replace `ISF-CONFLICTS`: unbound same-target
  incompatible writes still fail through the existing conflict diagnostics.
- Compatible fan-in, such as same-target same-value writes or request/pulse
  OR fan-in, does not require a resource.
- Verification-only runtime selector checks remain valuable after resource
  lowering because they confirm that generated mux selectors obey the final
  onehot/onehot0 assumptions.

## ISF-RESOURCE-PRIORITY.3 Implementation

This slice ships the first enforceable resource kind: priority-arbitrated
`rule_slot`.

### Parser Surface

- Existing metadata-only resources keep their old shape:
  `(resource name (arbiter priority|round_robin))`.
- Enforceable resources can now add:
  `(kind rule_slot)` and `(users rule_a rule_b ...)`.
- The parser accepts the growable resource-kind catalog:
  `rule_slot`, `output_bundle`, `interface_bundle`, `named_drive`,
  `transaction_start`, `child_instance`, and `storage_port`.
- Duplicate resource names, duplicate subclauses, duplicate users, malformed
  arbiter/kind/users clauses, and unknown `rule_slot` users fail before
  scheduler handoff.
- Unsupported resource kinds remain metadata only until used. If a resource
  with bound users uses a non-`rule_slot` kind, lowering fails closed.

### Lowering Surface

- `rule_slot` + `priority` is the only enforced resource/arbitration pair.
- Each bound rule requests the slot when its normalized rule guard is true.
- Actor-level and rule-local priority edges are reused to build the resource
  ordering graph.
- A complete acyclic ordering is required across bound users. Cycles fail with
  `isf_resource_priority_cycle`; unordered pairs fail with
  `isf_resource_priority_incomplete`.
- `round_robin` resources with bound users fail with
  `isf_resource_unsupported_arbiter` until round-robin state semantics ship.
- Bound users on unsupported kinds fail with
  `isf_resource_unsupported_kind`.
- The generated grant gates the whole lowered rule DT DTE. For example,
  `high > low` lowers the low rule header guard to the equivalent of
  `<(& low_guard (! high_guard))`, so all low rule actions, including
  triggers, are suppressed while the higher requester is active.
- Assignment provenance records `resource_suppressed_by` internally so static
  same-target conflict checks can recognize conflicts resolved by resource
  arbitration without widening the public schedule-report schema yet.

### Regression Evidence

- [t/1218-isf-rule-slot-resource-arbitration.t](../../t/1218-isf-rule-slot-resource-arbitration.t)
  covers parser preservation for `(kind rule_slot)`/`(users ...)`, scheduled
  `.fsm` DTE gating, HDL handoff, incomplete ordering rejection, cycle
  rejection, unsupported `round_robin`, unsupported resource kinds, and
  unknown `rule_slot` users.
- [t/1176-isf-resource-priority-boundary.t](../../t/1176-isf-resource-priority-boundary.t)
  continues to cover the legacy metadata-only resource shape plus malformed
  resource and priority input.
- [t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
  now includes the resource-arbitration regression in the ISF public-interface
  contract's live `tested_by` list.

## ISF-RESOURCE-PRIORITY.4 Implementation

This slice ships the first target-local priority path that involves a
transaction owner: actor-level rule-over-transaction priority for same-target
data assignments with matching timing operators.

### Lowering Surface

- Rule-over-transaction priority is lowerable because the winning rule's
  active condition is already expressible as a scheduled `.fsm` guard.
- The lowerer suppresses the transaction-state assignment by adding the
  inverse active rule condition to that assignment. The winning rule assignment
  remains in the rule's non-state DT.
- The suppression is target-local. It affects only the conflicting assignment,
  not every action owned by the lower-priority transaction.
- Unordered rule/transaction data conflicts fail closed with
  `isf_conflicting_rule_transaction_writes`.
- Priority cycles fail closed with `isf_priority_cycle_conflict`.
- Mixed timing operators continue to fail closed with
  `isf_priority_mixed_timing_conflict`; priority does not make different
  hardware timing contracts interchangeable.
- Transaction-over-rule priority fails with
  `isf_priority_transaction_winner_unsupported`. The current scheduled `.fsm`
  review artifact does not expose a state-active predicate that can safely
  guard a non-state rule DT assignment. That direction needs an explicit
  public lowering contract before it can ship.

### Regression Evidence

- [t/1219-isf-rule-transaction-priority.t](../../t/1219-isf-rule-transaction-priority.t)
  covers accepted rule-over-transaction suppression, scheduled `.fsm` guard
  output, HDL handoff, unordered conflict rejection, cycle rejection, and
  transaction-over-rule fail-closed diagnostics.
- [t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
  now includes the rule/transaction priority regression in the ISF
  public-interface contract's live `tested_by` list.

## ISF-RESOURCE-PRIORITY.5 Implementation

This slice exposes successful arbitration decisions in the schedule report
without publishing raw `LoweringIR` internals.

### Report Surface

- Successful reports now include `priority_resolutions`, an array of bounded
  target-local suppression summaries.
- Each `priority_resolutions` entry records `target`, `winner`,
  `winner_kind`, `loser`, and `loser_kind`.
- Successful reports now include `resource_arbitration`, an array of bounded
  enforced-resource grant-shaping summaries.
- Each `resource_arbitration` entry records `resource`, `kind`, `arbiter`,
  `user`, `user_kind`, and `suppressed_by`.
- These entries describe static lowering decisions. They are not per-cycle
  runtime grant traces.
- Fail-closed rejected conflicts remain targeted diagnostics and do not produce
  successful schedule-report JSON. Existing nonfatal conflict warnings remain
  in `compile_issues`.

### Regression Evidence

- [t/1220-isf-arbitration-schedule-report.t](../../t/1220-isf-arbitration-schedule-report.t)
  covers bounded `priority_resolutions` and `resource_arbitration` projection
  through both in-process schedule reports and the CLI JSON path.
- [t/1140-isf-public-schedule-report-metadata-audit.t](../../t/1140-isf-public-schedule-report-metadata-audit.t)
  now advertises the two new schedule-report key families.
- [t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
  now includes the arbitration report regression in the ISF public-interface
  contract's live `tested_by` list.

## ISF-RESOURCE-PRIORITY.6 Closure

This closure slice confirms that the resource/priority tree has no remaining
open leaf work.

### Shipped Coverage

- Parser validation covers resource entries, resource subclauses, duplicate
  resources/users, rule-local priorities, actor-level priorities, and target
  resolution.
- Resource arbitration covers priority-arbitrated `rule_slot` resources with
  complete acyclic rule ordering, whole-rule DT DTE gating, and fail-closed
  diagnostics for unsupported or incomplete cases.
- Target-local priority covers same-target rule/rule data conflicts and the
  lowerable rule-over-transaction data case. Mixed timing, cycles,
  incomparable/unordered cases, and transaction-over-rule priority fail closed.
- Successful schedule reports expose bounded `priority_resolutions` and
  `resource_arbitration` summaries.
- The ISF spec, public contract, mdBook, roadmap, task-tree index, MEMORY,
  CHANGES, DEVELOPMENT_NOTES, and LIVE_ACHIEVEMENT_STATUS agree on the shipped
  behavior and deferred boundaries.

### Remaining Backlog Outside This Tree

- `round_robin` resources with users still fail closed until stateful arbiter
  semantics ship.
- Resource kinds beyond `rule_slot` remain backlog: `output_bundle`,
  `interface_bundle`, `named_drive`, `transaction_start`, `child_instance`,
  and `storage_port`.
- Transaction-over-rule priority remains deferred until state-active guards
  have an explicit public lowering contract for non-state rule DTs.
- Per-cycle runtime grant tracing remains outside the current schedule-report
  surface.

## Decisions

- `2026-05-14`: Resource and priority enforcement is tracked separately from
  same-target output conflicts, but it must consume the conflict-domain policy
  defined by `ISF-CONFLICTS`.
- `2026-05-14`: `ISF-RESOURCE-PRIORITY.1` records that resources are
  validated metadata only, while priority has one shipped enforcement path:
  same-target rule/rule data-conflict resolution through target-local
  suppression of the lower-priority assignment.
- `2026-05-14`: Resource/priority schedule-report exposure is intentionally
  not treated as frozen. Any new public metadata must be added as a bounded,
  documented, regression-backed surface when the feature implementation ships.
- `2026-05-14`: ISF resources need an explicit growable catalog of shareable
  resource kinds. The first implementation target is `rule_slot`, a
  one-cycle mutual-exclusion slot that gates bound rule DTs. Additional kinds
  such as `output_bundle`, `interface_bundle`, `named_drive`,
  `transaction_start`, `child_instance`, and `storage_port` remain backlog
  until their lowering and diagnostics are explicit.
- `2026-05-14`: First-pass resource enforcement should use centralized
  resource user binding through explicit `(kind rule_slot)` and optional
  `(users ...)` resource subclauses, and should cover only
  priority-arbitrated rule users. Transaction, drive, output-target,
  child-instance, storage-port, round-robin, and lifetime-hold resource
  semantics remain deferred until their contracts are explicit.
- `2026-05-14`: `ISF-RESOURCE-PRIORITY.3` ships the `rule_slot`/`priority`
  case exactly. Other resource kinds stay accepted catalog metadata but fail
  closed when bound users attempt to use them for enforced arbitration.
- `2026-05-14`: Resource grant provenance remains internal for now.
  Successful schedule-report projection is left to `ISF-RESOURCE-PRIORITY.5`
  so the public JSON surface can be specified and audited as its own slice.
- `2026-05-14`: The first rule/transaction priority implementation is
  intentionally one-way: rule-over-transaction is lowerable as an ordinary
  assignment guard on the transaction-state assignment; transaction-over-rule
  remains fail-closed until state-active predicates have a documented lowering
  surface for non-state rule DT guards.
- `2026-05-14`: Successful arbitration report metadata is bounded to static
  lowering decisions: `priority_resolutions` for target-local suppression and
  `resource_arbitration` for enforced resource grant shaping. Per-cycle grant
  traces and raw suppression provenance remain private.

## Open Questions

- None for the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.1` | `prove -l t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.3` | `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.4` | `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t t/1219-isf-rule-transaction-priority.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.5` | `perl -I perl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -I perl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1096-isf-schedule-json-report.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1213-isf-schedule-report-compatible-fanin-projection.t t/1220-isf-arbitration-schedule-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.6` | `prove -l t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1218-isf-rule-slot-resource-arbitration.t t/1219-isf-rule-transaction-priority.t t/1220-isf-arbitration-schedule-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-PRIORITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-RESOURCE-PRIORITY.1` | `ISF-RESOURCE-PRIORITY.1: inventory metadata behavior` | Records accepted resource/priority forms, existing validation, current enforcement, schedule-report exposure gaps, and implementation gaps. |
| `ISF-RESOURCE-PRIORITY.2` | `ISF-RESOURCE-PRIORITY.2: specify arbitration semantics` | Defines the shareable resource-kind catalog, first-pass `(kind rule_slot)` plus `(users ...)` binding, priority-arbitrated rule-user grants, tie/cycle behavior, and unsupported cases. |
| `ISF-RESOURCE-PRIORITY.3` | `ISF-RESOURCE-PRIORITY.3: enforce rule-slot resources` | Adds parser/lowering support for priority-arbitrated `rule_slot` resources and fail-closed unsupported cases. |
| `ISF-RESOURCE-PRIORITY.4` | `ISF-RESOURCE-PRIORITY.4: resolve rule-transaction priority` | Adds target-local rule-over-transaction priority suppression and fail-closed diagnostics for unordered, cyclic, mixed-timing, and transaction-over-rule cases. |
| `ISF-RESOURCE-PRIORITY.5` | `ISF-RESOURCE-PRIORITY.5: report arbitration decisions` | Adds bounded schedule-report projection for successful priority suppressions and resource arbitration decisions. |
| `ISF-RESOURCE-PRIORITY.6` | `ISF-RESOURCE-PRIORITY.6: close resource priority tree` | Confirms coverage and closes the resource/priority task tree. |

## Changelog

- `2026-05-14`: Created the active ISF resource/priority task tree.
- `2026-05-14`: Completed the current-behavior inventory and moved the
  frontier to `ISF-RESOURCE-PRIORITY.2`.
- `2026-05-14`: Completed the resource/priority target semantics and moved
  the frontier to `ISF-RESOURCE-PRIORITY.3`.
- `2026-05-14`: Implemented priority-arbitrated `rule_slot` resource
  enforcement and moved the frontier to `ISF-RESOURCE-PRIORITY.4`.
- `2026-05-14`: Implemented the first rule/transaction priority path and
  moved the frontier to `ISF-RESOURCE-PRIORITY.5`.
- `2026-05-14`: Added bounded schedule-report projection for arbitration
  decisions and moved the frontier to `ISF-RESOURCE-PRIORITY.6`.
- `2026-05-14`: Closed the resource/priority tree and moved PNT to the next
  active ISF task tree.
