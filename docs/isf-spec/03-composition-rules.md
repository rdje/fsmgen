
## 8. Composition Between Transactions

### 8.1 Blocking Sequence

```lisp
(do child_transaction)

(do child_transaction
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)
    (output data resp)))
```

Current lowering:
- Local `do` emits an await-shaped parent state guarded by
  `child_transaction_done`.
- Local `do` rewires the child idle state to wait on
  `child_transaction_start`.
- `do` is structurally validated as
  `(do transaction [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
  with one scalar child transaction operand and at most one `domain`, `params`,
  and `bind` block before child-target resolution.
- The `child_transaction` target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- The rewired child idle state enters the first non-entry child state, so the
  child body does not need to begin with a drive state.
- The child's terminal state pulses `child_transaction_done` with `<1`, matching
  the completion-pulse contract and avoiding sticky done bits across repeated
  blocking calls.
- The parent `do` state asserts `child_transaction_start` directly.
- Parameterized `do` is a generated child activation. It emits the child as a
  separate scheduled module, creates a deterministic generated instance named
  `{parent}_{child}_do_{ordinal}`, applies static parameter overrides on the
  generated top `?fsmc` instance, asserts `{instance}_start`, and awaits
  `{instance}_done`.
- Parameterized/generated `do` port bindings use explicit generated-top
  handoffs. Input handoffs are parent-owned combinational assignments; output
  handoffs are copied under the generated instance's `done` guard. The
  generated top does not auto-fanout unrelated actor public inputs into a
  generated `do` child; authors must bind intended payload ports explicitly.
- If a plain `(do child)` targets a child transaction that is already generated
  because another activation site needs generated specialization, that plain
  `do` also uses a generated child activation instance. This keeps the parent
  from referencing a child body that was skipped from the parent scheduled
  module.

### 8.2 Spawn

```lisp
(spawn child_worker as w0)
(await_all done)
```

Current lowering:
- Spawned transactions are emitted as separate child `.fsm` files.
- `spawn` is structurally validated as
  `(spawn transaction as instance [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
  with one scalar child transaction, one scalar instance name, and at most one
  validated `domain`, parameter override, and bind block before spawned child
  collection.
- The spawned transaction target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- Each spawned child exposes `start` as an input and `done` as an output. Named
  drive calls inside a spawned child expose drive handoff outputs such as
  `<drive>_start` and `<drive>_<param>` instead of directly exporting the
  actor output driven by that drive body.
- The parent exposes per-instance `instance_start` outputs and
  `instance_done` inputs for generated-top wiring. Each spawn state asserts
  its matching `instance_start` signal.
- `await_all` and `await_any` are structurally validated as
  `(await_all done_port)` and `(await_any done_port)` with one scalar done-port
  operand before sync-state emission.
- `await_all` waits for all collected spawned done ports using one scheduled
  transition suffix guarded by their logical AND, for example
  `(-> parent_done <(& w0_done w1_done w2_done))`.
- `await_any` emits one guard per collected spawned done port and advances when
  any one of them fires.
Focused regressions cover both synchronization forms.

Top-level generated-child instantiation is now shipped for the covered
spawn and parameterized blocking `do` fixture set. Spawn and generated `do`
parameter declaration, validation, scheduled child `+params` emission,
per-instance override preservation, and generated-top application now all flow
through the normal composition pipeline. The public contract is:

- Multi-file generated-child actors expose an explicit generated `?top` source
  over the scheduled parent module and child modules.
- The scheduled parent module keeps the actor name. The generated top uses a
  distinct deterministic name, initially `<actor_name>_top`.
- The generated top re-exports the actor public interface. Per-instance
  `instance_start`/`instance_done` handoff signals are internal top wiring, not
  public top ports.
- The scheduled parent exposes `instance_start` as an output port and
  `instance_done` as an input port for each generated instance. Each generated
  child exposes `start` as an input and `done` as an output.
- The generated top wires `parent.instance_start` to `instance.start`,
  `instance.done` to `parent.instance_done`, explicit port-binding handoffs,
  and child named-drive handoff outputs to parent per-instance handoff inputs
  using canonical `?wiring` list forms such as
  `(parent.instance_start instance.start)`.
- A spawned child returns to its `start`-guarded idle state after completion and
  must not re-enter the body until the next start pulse.
- Spawn instance names are actor-local identities and must be unique. Generated
  `do` instance names use `{parent}_{child}_do_{ordinal}` and share the same
  actor-local uniqueness rule. Multiple instances of one child transaction
  share the same child module with distinct instance names.
- Spawn and generated `do` parameter overrides are emitted on the generated
  `?fsmc` instance through the existing composition `(params ...)` override
  surface.

`spawn` is static HDL composition plus runtime activation. The generated child
instance exists for the lifetime of the generated top. Executing the spawn site
asserts the instance start path; completion only returns that same instance to
idle. Reaching the same lexical spawn again, including through future
spawn-in-repeat support, reuses the same physical instance. The scheduler must
reject or sequence any path that could start a still-busy child before its
fresh done pulse is observed.

Parameterized spawn uses one optional nested `params` block after the instance
name. Parameterized blocking `do` uses the same `params` block after the child
transaction name:

```lisp
(transaction child_worker
  (params
    (WIDTH 8)
    (LANES (8'h00 8'h00)))
  ...)

(transaction parent_main
  (spawn child_worker as w0
    (params
      (WIDTH 16)
      (LANES (8'hA5 8'h3C))))
  (do child_worker
    (params
      (WIDTH 32))))
```

The shipped parameter-binding surface covers spawn and blocking `do` generated
child activations. Child transaction parameter declarations must use unique
HDL-identifier-compatible names. Overrides must use unique names declared by
the child transaction; missing overrides use child defaults. Scalar numeric
and exact-width literal overrides are width-flexible. Aggregate/list defaults
require compatible aggregate/list override shape. Actor-local constants,
actor-local scalar parameter defaults, enum members, and qualified imported
package scalar constants may supply static activation override scalar values
or scalar leaves inside activation aggregate/list override values. Malformed
forms, duplicate generated instance names, duplicate parameters, unknown
targets, unknown override names, unsupported value shapes, unresolved enum
members, and parameter declarations on non-generated transactions without a
supported same-transaction static use fail before misleading scheduled
artifacts are emitted. The scheduled child `.fsm` carries
the child transaction defaults in a direct `+params` block. Generated child
transaction defaults backed by actor constants or actor-local scalar parameter
defaults are published as resolved literal values in that child `+params`
block and generated-composition report metadata, while child-local transaction
parameter dependencies and enum defaults preserve authored tokens. The parent lowerer IR
preserves each generated instance's override list. The generated top emits
those overrides as `?fsmc` instance `(params ...)` blocks, so the existing
composition pipeline applies them to the generated child instances.

### 8.3 Generated Composition Schedule Report Projection

The accepted schedule-report projection for generated ISF composition is a
top-level `generated_composition` field. Successful reports keep the ordinary
transaction, storage, and DT summaries parent-scoped, while this field exposes
bounded generated-top discovery metadata for generated-child composition.

For actors without a generated composition top, `generated_composition` is
`null`. For generated-child actors, the field is an object with these bounded
keys:
- `kind`: `spawn_generated_top` when every generated child activation is spawn,
  or `activation_generated_top` when another activation kind such as blocking
  `do` participates in the generated top.
- `top_module`: generated top module name, initially `<actor>_top`.
- `top_fsm`: generated top `.fsm` basename, initially `<actor>_top.fsm`.
- `parent`: object with `module` and `scheduled_fsm` for the scheduled parent.
- `children`: array of generated child module summaries. Each child entry exposes
  `transaction`, `module`, `scheduled_fsm`, and `parameters`; parameter entries
  expose `name` and stringified `default`.
- `instances`: array of generated instance summaries. Each instance entry
  exposes `instance`, `child`, `activation_kind`, `start`, `done`,
  `parameter_bindings`, and `drive_handoffs`.

Instance `start` and `done` entries expose the parent and child port names used
by the generated top. `parameter_bindings` entries expose `name`, `source`
(`default` or `override`), and stringified `value`. `drive_handoffs` entries
expose one named drive, its request link, and one payload entry per drive
parameter with `parameter`, `child_port`, `parent_port`, and `width`.

This projection is deliberately bounded. It does not expose raw LoweringIR
records, raw composition parser objects, raw `?wiring` arrays, assignment
provenance, or private port-inference internals. It is live contract metadata
that evolves with FSMGen, not a frozen full schedule-report schema.

### 8.4 Generated Composition Diagnostics

Generated composition diagnostics must be targeted before scheduled artifacts
or generated tops become misleading. Diagnostics in this family should name the
transaction, generated instance, child transaction, parameter, or generated
handoff that failed. The current accepted diagnostic families cover malformed
spawn and `do` syntax, unknown child targets, duplicate instance names, parent
actor naming conflicts, malformed or duplicate parameter
declarations/overrides, unknown override names, aggregate/scalar shape
mismatches, unsupported parameter declarations on non-generated transactions,
and generated handoff port-name conflicts.

If an actor interface already declares a port name reserved for a generated
handoff, lowering fails before the generated top is emitted. Spawn start/done
conflicts name the transaction and spawn instance. Named-drive request
conflicts also name the drive. Named-drive payload conflicts name the drive and
payload parameter. This keeps generated-composition failures source-local
instead of letting them fall through as later composition-pipeline fallout.

## 9. Rules

```lisp
(rule always_ready ready
  (valid 1)
  (trigger main_transfer))
```

The long guard spelling remains accepted for compatibility and clarity:

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

Current lowering:
- Accepted parser output exposes rules as an array of shell entries with
  unique non-empty scalar `name`, optional `when`, and `actions` array fields.
  Duplicate, nested, empty, or otherwise non-scalar rule names are rejected
  before the parser returns an actor shell. Condition and action payload
  contents remain scheduler input and are not frozen as a public API by the
  actor-shell rule-shape metadata.
- Rule actions are structurally validated before the actor shell is returned.
  Supported action shapes are `(set port expr)`, `(port expr)`,
  `(pulse target)`, `(trigger transaction)`, and
  `(priority over other_rule)`. The explicit setter and shorthand assignment
  shapes keep `port` scalar and allow `expr` to use the same scalar-or-list
  `.fsm` RHS expression domain as transaction `(set var expr)` and
  `(update var expr)`.
- `(trigger transaction)` targets must name a declared transaction in the same
  actor. Forward references are accepted because the parser validates trigger
  targets after the full actor body is collected; missing targets fail before
  an actor shell is returned.
- Each rule emits one non-state DT block.
- A scalar condition immediately after the rule name is the preferred shorthand
  guard, and a list-expression condition may also be used when the expression
  head is a recognized expression operator. Long-form `(when condition)`
  supplies the same scalar-or-expression guard. The parser normalizes both
  spellings to the same public `when` field. Rule-local `(when condition)` is
  not the transaction control-flow form; it has no body and guards the rule
  actions that follow it.
- Expression rule guards lower through the same `.fsm` guard-expression
  surface as authored DT guards. A FIFO fire predicate can therefore be
  written directly, for example
  `(rule push_only (& push (! pop) (! full)) ...)`, and the scheduled `.fsm`
  emits `-push_only <(& push (! pop) (! full))`.
- `(set port expr)` and `(port expr)` actions lower as flopped assignments
  inside the guarded non-state DT. They keep the existing `<-` rule
  data-assignment family and do not introduce combinational or D-input-named
  rule action operators.
- `(pulse target)` actions target a scalar actor output or scalar actor
  storage variable and lower as `<1 (target 1)` inside the guarded non-state
  DT, using the normal `.fsm` output marker for output targets. They are
  pulse-domain assignments, participate in pulse-compatible fan-in, and do
  not create sticky flopped rule writes.
- Same-target rule data writes now receive a best-effort compile-time conflict
  check before scheduled `.fsm` text is treated as valid. Two rules that drive
  the same target to incompatible values fail closed with
  `isf_conflicting_rule_writes`; compatible same-target/same-value rule writes
  remain accepted. The checker also accepts same-target rule writes when their
  rule guards contain a direct contradictory fact, such as `push` versus
  `(! push)`, `pop` versus `(! pop)`, or equality facts that require a signal
  like `occupancy` or `wr_ptr` to equal two different constants, proving that
  the assignments cannot fire in the same cycle. This disjointness proof is
  intentionally conservative; guards that are not proved disjoint still use the existing
  compatible fan-in, priority-resolution, or fail-closed conflict paths.
  Named-drive calls are included in this analysis. When exactly one local
  transaction calls a drive and no generated child activation also calls it,
  the scheduler treats that transaction as the logical writer while retaining
  the raw drive provenance. A different-value rule/drive conflict without an
  applicable priority therefore fails closed as
  `isf_conflicting_rule_transaction_writes`. Shared, generated, mixed-source,
  and unused drives do not have one provable transaction owner; their
  unprioritized overlap remains the nonfatal
  `isf_unproven_rule_drive_overlap` issue with
  `proof_status => not_doable`.
- Rule-local `(priority over other_rule)` and actor-level
  `(priority high over low)` can resolve same-target rule/rule data conflicts
  when the priority graph selects one winner for that target. The lowerer
  suppresses the lower-priority rule assignment with the inverse of the
  higher-priority rule condition. Priority cycles fail closed with
  `isf_priority_cycle_conflict`; incomparable rules still fail closed through
  the ordinary conflict diagnostic.
- Actor-level rule-over-transaction priority can resolve the covered
  same-target data case when the rule assignment and transaction-state
  assignment use the same timing operator. The lowerer keeps the winning rule
  assignment in its guarded non-state DT and adds the inverse active rule
  condition to the transaction-state assignment. Unordered rule/transaction
  conflicts fail closed with `isf_conflicting_rule_transaction_writes`.
  Actor-level transaction-over-rule priority is also supported for the
  covered same-target data case: the lowerer leaves the transaction-state
  assignment unchanged and guards the lower-priority rule assignment with the
  inverse scheduled `.fsm` `(state_active STATE)` predicate for the
  transaction state that owns the winning assignment. The state-active
  predicate lowers to an internal `current_state == STATE` comparison without
  creating fake input ports for `current_state`, state constants, or generated
  state-enable names. Priority cycles still fail with
  `isf_priority_cycle_conflict`.
- Actor-level priority also covers a rule assignment that conflicts with a
  data assignment in a uniquely owned named drive. For
  `(priority rule over transaction)`, the inverse rule condition is added only
  to the conflicting drive assignment; other outputs in the same drive and
  the drive-request fan-in remain unchanged. For
  `(priority transaction over rule)`, the conflicting rule assignment is
  guarded by the inverse full drive-activation condition. Same-value writes
  remain compatible fan-in. A declared priority involving a drive with
  multiple local callers, generated callers, or mixed local/generated callers
  fails closed as `isf_ambiguous_rule_transaction_drive_priority`, because a
  single logical transaction owner cannot be proved. Drive DTs retain sorted
  private caller/source metadata and drive-assignment provenance retains its
  invoking transactions; successful public schedule-report schemas are not
  widened.
- Generated SystemVerilog includes verification-only selector assertions for
  analyzed muxes after ISF lowers through scheduled `.fsm`. Same-value
  `LHS`/`VAL` source selectors and whole-`LHS` value selectors are checked
  with `$onehot0` under `` `ifndef SYNTHESIS``; Verilog emission stays free of
  SystemVerilog assertions. The checks are derived from backend assignment
  analysis, so they cover internal generated muxes such as `next_state` as
  well as ISF-authored data targets. Standalone DT roots keep their existing
  standalone-DT multi-drive assertions rather than receiving duplicate
  selector blocks.
- `(trigger transaction)` lowers as a `<1` one-cycle delayed pulse inside the
  guarded non-state DT to a generated per-rule/per-transaction source named
  `rule_transaction`, so a rule trigger is a pulse rather than a sticky
  flopped request bit.
- If multiple rules trigger the same transaction, the scheduled `.fsm` exposes
  each rule source separately and emits one generated combinational fan-in DT
  per target transaction. That DT drives `transaction_start` from the OR of the
  rule sources without adding another cycle.
- Parameterized rule triggers use the source shape
  `(trigger transaction (params (NAME value) ...) (bind ...))`. The lowering
  creates one static generated child activation instance per lexical
  parameterized trigger site, named
  `{rule}_{transaction}_trigger_{ordinal}`, applies overrides through the
  generated top's `?fsmc` `(params ...)` block, and preserves the current
  rule-trigger timing by routing the existing per-rule trigger source and input
  payload sources through a generated handoff DT. The rule does not wait for
  the generated child `done` handoff; the parent reads that done handoff into
  an internal observer so the generated-top endpoint is explicit and so any
  generated-child output binding can copy its output under that per-trigger
  completion observation. Direct/local rule-trigger output bindings remain
  rejected.
- Scheduled `.fsm` emission writes the rule guard as the non-state DT header
  DTE, for example:

```lisp
(-always_ready <ready
  (<- (valid> 1))
  (<1 (always_ready_main_transfer 1))
)

(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

Direct scalar rule assignment RHS values and scalar operands inside rule
assignment RHS expressions may use local or package enum members, and strict
HDL generation accepts the guarded rule DT header plus canonical assignment-pair
body form. Rule guards may use local or package enum members directly as
standalone scalar guards, for example `(rule r mode.BUSY ...)` or
`(rule r (when shared.mode.BUSY) ...)`; scheduled `.fsm` preserves those guards
as non-state DT header suffixes such as `<mode.BUSY` or
`<shared.mode.BUSY`. Rule guard expression operands may also use local or
package enum members. Scalar aggregate storage leaves may appear as standalone
rule guards or as rule guard expression operands, for example
`(rule r frame.flag ...)` or `(rule r (when lanes[1]) ...)`; scheduled `.fsm`
preserves those guards as non-state DT header suffixes such as `<frame.flag`
or `<lanes[1]`. Rule assignment targets may write scalar aggregate storage
leaves. Rule guard and assignment expression operator-position enum members or
aggregate paths, and subaggregate rule guards, remain deferred.

Multi-rule fan-in example:

```lisp
(-r0 <a
  (<1 (r0_work 1))
)

(-r1 <b
  (<1 (r1_work 1))
)

(-work_trigger_fanin
  (= (work_start (| r0_work r1_work)))
)
```

Malformed trigger `params` blocks fail before scheduled artifacts are emitted:
more than one `params` block on one trigger action, malformed `(NAME value)`
entries, non-HDL parameter names, duplicate override names, unknown target
parameters, shape-incompatible values, unsupported non-constant symbolic or
expression override values, and generated instance name or handoff-port
collisions are all fail-closed diagnostics. A rule trigger with output
bindings remains rejected;
runtime data must continue to use input ports and `(bind ...)`.

- Inline `(priority over other_rule)` is structurally validated by the parser,
  and `other_rule` must name a declared rule in the same actor. Forward
  references are accepted because the target check runs after the full actor
  body is collected. For same-target rule/rule data conflicts, lowering uses
  this edge as target-local priority metadata.

Separate `(priority lhs over rhs)` declarations are structurally validated by
the parser, and both `lhs` and `rhs` must name declared transactions or rules
in the same actor. Forward references are accepted. Actor-level priority
metadata is enforced for same-target rule/rule data conflicts when both
targets are rules, for priority-arbitrated `rule_slot` resources when the
endpoints are bound rules of the same resource, for priority-arbitrated
`output_bundle` resources when the endpoints are bound rules of the same
resource, for priority-arbitrated `transaction_start` resources when the
endpoints are bound rules that trigger the named local transaction, and for
the lowerable rule-over-transaction and
transaction-over-rule same-target data cases.
Transaction/transaction priority beyond ordinary state mutual exclusion and
broader resource arbitration remain deferred.

`(resources ...)` entries are structurally validated as resource entries with
non-empty scalar names, an `(arbiter priority|round_robin)` subclause, and
optional `(kind ...)`, `(users ...)`, and `(members ...)` subclauses.
Duplicate resource names, duplicate resource subclauses, duplicate users,
duplicate members, malformed kinds, malformed users, malformed members,
unknown enforced-kind users, bound `transaction_start` resource names that do
not name declared local transactions, output-bundle members that are not
declared actor output ports or concrete actor-owned storage signals, and
storage-port members that are not concrete actor-owned storage signals are
rejected before scheduled `.fsm` emission. `(members ...)` is accepted for
`(kind output_bundle)` and `(kind storage_port)` in the current shipped
surface. `(resources ...)` is an actor-level singleton clause, so repeated
resources blocks are rejected instead of merged or overwritten.
Resource
semantics use a growable catalog of shareable resource kinds. The resource name
is the author-defined instance handle; the kind says what is being shared; the
`arbiter` says how requesters are selected. The table below is the current
public registry of things ISF can name as shareable resources. It deliberately
starts small and grows only when a kind has a clear lowering path, runtime
semantics, diagnostics, report surface, and regression coverage.
The same registry is owned in code by `FSM::Support::ISFResourceCatalog` and
advertised through the machine-readable ISF public contract as
`resource_arbiter_values`, `resource_kind_values`,
`resource_kind_status_map`, `resource_kind_meaning_map`,
`enforced_resource_kind_values`, and `backlog_resource_kind_values`.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` and bounded `round_robin` arbitration | A one-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | shipped for `priority` and bounded `round_robin` arbitration | A group of actor outputs or rule-written LHS targets with rule users. A grant enables the whole winning bound rule DT for that cycle; optional explicit members name declared actor output ports or concrete actor-owned storage signals. |
| `transaction_start` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle arbitration for rule-trigger request fan-in into one local transaction. The resource name must be the target transaction name. |
| `storage_port` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle arbitration for rule users that update explicit actor-owned storage signals. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |

Backlog names are parser-recognized catalog entries, not shipped runtime
behavior. A backlog kind with bound users must fail closed until its lowering
path, runtime semantics, diagnostics, report surface, and regression coverage
ship.

The shipped resource-arbitration implementation covers priority-arbitrated
`rule_slot`, `output_bundle`, `transaction_start`, and `storage_port` rule
users, plus bounded `round_robin` arbitration for `rule_slot`,
`output_bundle`, `transaction_start`, and `storage_port` rule users. The
source shape keeps
binding centralized under `(resources ...)` by extending a resource entry with
`(kind rule_slot)`, `(kind output_bundle)`, `(kind transaction_start)`, or
`(kind storage_port)`, `(users rule_a rule_b ...)`, and for output bundles or
storage ports `(members target_a target_b ...)` subclauses.

For priority-arbitrated covered cases, each bound rule requests the resource
when its normalized rule guard is true. Rule-local
`(priority over other_rule)` and actor-level `(priority lhs over rhs)` edges
choose the active winner when the endpoints are bound rules of the same
resource. The generated grant gates the whole lowered rule DT DTE, while
existing same-target priority suppression remains assignment-local.

For bounded `rule_slot`, `output_bundle`, `transaction_start`, or
`storage_port` plus `round_robin`, each bound rule also requests when its
normalized rule guard is
true. The `(users ...)` list is the circular grant order. FSMGen emits a
generated pointer named `isf_rr_<resource>_turn`, grants the first requesting
rule at or after the current pointer, gates the whole winning rule DT DTE, and
advances the pointer only from the winning rule DT. The pointer name is
derived from the resource name, so bounded round-robin resource names must be
HDL identifiers and must not collide with existing ports, actor constants,
actor parameters, declared storage, or generated counters. A rule user may not
be bound to more than one round-robin resource in the same actor. Reports
expose the pointer in `inferred_storage[]` as a counter with role
`resource_round_robin_pointer`.

Without an explicit member list, the bundle remains the historical implicit
bound-rule surface: the bound users and their driven outputs or other LHS
targets describe the author intent. If an explicit output-bundle member list is
present, each member must be a declared actor output port or a concrete
actor-owned storage signal. Concrete storage signals include scalar storage
variables and scalarized bank element signals; bank roots, aggregate paths,
inferred undeclared LHS targets, and arbitrary expressions remain outside this
explicit member domain. Each listed member must be written by at least one
bound rule user, and no bound rule user may write a declared output or
actor-owned storage signal outside the list.
For `transaction_start`, the resource name is the target local transaction
name. Every bound rule user must trigger that transaction through the shipped
non-generated rule-trigger surface. Under `priority`, the resource suppresses
lower-priority rule DTs before their per-rule trigger source pulses can feed
the generated `{transaction}_trigger_fanin` DT. Under bounded `round_robin`,
the generated pointer grant gates the winning rule DT before the same
per-rule trigger source fan-in path. The resource does not replace the fan-in
DT, so no extra cycle is added and the fan-in owner remains reviewable.
For `storage_port`, an explicit member list is required when users are bound.
Each member must be a concrete actor-owned storage signal: a scalar storage
variable or a scalarized bank element signal. Bank roots, aggregate storage
paths, inferred undeclared LHS targets, transaction ports, actor input ports,
and arbitrary expressions remain outside the shipped member domain. Each
listed storage member must be written by at least one bound rule user, and no
bound rule user may write a concrete actor-owned storage signal outside the
list. Under bounded `round_robin`, the same mandatory member validation and
`resource_arbitration[].members` report evidence apply while the generated
pointer selects the winning bound rule for the cycle. The grant still gates
the whole bound rule DT for the cycle; it does not create route mux/storage,
storage locks, memory-port protocols, or hold/release ownership.
Cycles, incomplete ordering among potentially simultaneous priority-bound
users, ambiguous future user namespaces, unsupported resource kinds,
unsupported `round_robin` kind/user combinations outside the shipped
`rule_slot`, `output_bundle`, `transaction_start`, and `storage_port`
rule-user subsets, invalid generated round-robin pointer names or collisions, duplicate
round-robin rule-user ownership across resources, member/list mismatches, and
unwritten explicit members fail closed.
Transaction users, named-drive users, output-target users, child-instance
users, generated-child transaction-start resources, generated-child storage
arbitration, actor-network trigger resources, actor-network endpoint users,
bank-root or aggregate output-bundle/storage-port members, inferred
undeclared member targets, multi-capacity resources, storage lifetime
ownership, and transaction lifetime hold/release semantics remain deferred.

Actor-level `(phase name property...)` and `(stage name property...)` metadata
is structurally validated by the parser and carried in the actor shell for
downstream consumers, but the scheduler does not enforce actor-level phase or
stage semantics yet. That actor-level metadata is copied into `LoweringIR`
only for bounded public report projection: schedule JSON exposes
`actor_phases[]` and `actor_stages[]` entries with each authored metadata
`name` and parser-validated list-form `body`. Generated `.fsm`, generated
composition tops, and HDL do not consume that actor-level metadata today.

Actor-level `(observe NAME (role passive_monitor) (signals SIG...))` metadata
is the first shipped IAL1 verification-specific source feature. It records a
named passive observation point over public actor interface signals for future
generated verification artifacts. The parser requires a single-clock actor,
the exact `passive_monitor` role, and a non-empty unique list of scalar input
or output interface signal names. It rejects storage names, transaction-local
ports, dotted or child endpoints, unknown signals, duplicate observation names,
and unsupported roles. LoweringIR carries the resolved metadata only for
bounded public report projection: schedule JSON exposes
`verification_observations[]` entries with `name`, `role`, inherited `clock`,
`reset`, and source-ordered signal summaries. Generated `.fsm`, generated
composition tops, HDL, UVM, VHDL, scoreboards, coverage, and reusable VIP do
not consume observation metadata today.
Transaction-level `(phase name property...)` remains the
current pass-through state marker lowering. Transaction-level
`(stage name (ready ready_signal) (valid valid_signal))` is the preferred
spelling for the first shipped stage-lowering subset. FSMGen also accepts the
older `(stage name (input ready_signal) (output valid_signal))` spelling as a
compatibility alias; `ready` and `input` bind the same ready endpoint, while
`valid` and `output` bind the same valid endpoint. The stage is supported only
as a top-level transaction clause, with `ready_signal` bound to an actor input
and `valid_signal` bound to an actor output. It lowers to one transaction
state that drives `valid_signal = 1` while the state is active and advances
only when `ready_signal` is true in that same cycle. The valid drive is a
normal transaction combinational assignment and remains subject to existing
same-target conflict checks. Pending samples immediately before the stage
materialize before the stage so a stall does not resample every cycle. Pending
samples before a runtime wait whose zero-count successor is a stage materialize
in a sample-preserving stage clone; the clone still drives `valid_signal` and
advances only under `ready_signal`, matching the original stage state. Nested
stages, stage-local `(latency ...)`, `(compute ...)`, arbitrary stage body
actions, multiple ready/valid endpoints, registered-valid variants, and
skid-buffer behavior remain fail-closed/deferred. Schedule reports expose
shipped transaction stages through `transaction_stages` entries containing the
authored transaction and stage names, `kind = ready_valid_barrier`, generated
state name, ready input, and valid output.

The bounded-eventually monitor `(assert (monitor (within signal cycles)) ["name"])`,
placed in a transaction body, asserts that `signal` must hold within `cycles`
cycles of the cycle control reaches that clause. (It replaces the former
top-level `(contract name (eventually signal within cycles))` clause, which was
removed in favor of this unified verification surface.) It is supported with
`signal` bound to a scalar actor interface input or output, and `cycles` as
either a positive
integer literal, a declared actor constant that resolves to a positive
integer, an actor-local scalar parameter default that resolves to a positive
integer, a qualified imported package scalar constant that resolves to a
positive integer, or a same-transaction scalar parameter default on a
generated child or direct/non-generated transaction that resolves to a
positive integer. Direct transaction parameters are local lowering inputs for
this contract-window value domain and are not emitted as actor-level `.fsm`
`+params`. Activation-site overrides on `spawn`, generated blocking `do`, or
rule `trigger` that target a generated child parameter used by the child
contract window are accepted only when the override resolves to the same
positive integer cycle count as the child transaction parameter default.
Mismatched overrides fail closed with a targeted diagnostic; override
specialization of generated child contract windows remains deferred. The same
generated-child activation rule applies to transaction parameters used by
static timing lowering for repeat counts, wait counts, latency bounds, and
top-level await-local watchdog limits: same-value overrides remain accepted,
while mismatches fail closed before scheduled artifacts are emitted. The same
rule also applies to transaction parameters used by data-operation widths
(`shift_left`, `shift_right`, `assemble`, `extract`) and by transaction port
widths (`(ports (input/output NAME (width PARAM)))`): same-value overrides
remain accepted, while mismatches fail closed with targeted `static-width
parameter` and `static port-width parameter` diagnostics respectively. Runtime
signals, arbitrary expressions, unknown names, unknown or unqualified package
constants, package aggregate constants, package member/item paths, ambiguous
local-enum/package-constant spellings, zero-valued constants, and zero-valued
or non-scalar actor/transaction parameters are not accepted as contract
windows. Reaching the
clause emits one arm state. The checked window starts on the next cycle and
lasts for the resolved `cycles` bound. The generated scheduled `.fsm` artifact
contains the arm state plus an always-on monitor DT with pending, age, and
sticky-fail storage. Actor reset clears the monitor storage. Seeing `signal`
while pending clears the obligation; window expiry or re-arming the same
contract while pending sets the sticky fail bit. Schedule-report
`dt_blocks` classify the generated monitor as `temporal_contract_monitor`, and
`inferred_storage` reports pending/fail as registers and age as a counter.
Pending samples before a runtime wait whose zero-count successor is the
contract arm state materialize in a sample-preserving contract clone; the
clone emits the same one-cycle arm request and leaves the monitor DT as the
only owner of pending/age/fail storage.
Schedule reports also expose shipped contracts through `temporal_contracts`
entries containing the authored transaction and contract names, `kind =
bounded_eventually`, trigger state, observed signal, cycle bound, pending,
counter, and fail signal names, overlap policy, reset policy, and assertion
projection status. The current assertion projection is
`systemverilog_sticky_fail`: SystemVerilog generation emits a
verification-only assertion under `` `ifndef SYNTHESIS`` that checks the
generated sticky fail bit remains clear outside reset, while Verilog output
stays assertion-free. Raw monitor equations and backend assertion text are not
schedule-report payloads; the scheduled monitor remains the source of truth.
Historical/free-form contract bodies, override-specialized contract-window
lowering after mismatched activation-site parameter overrides,
runtime-signal or expression windows, global `always` implication forms,
min/max windows, dynamic bounds, same-cycle checks, nested
contracts, expression operands, and multiple outstanding obligations remain
fail-closed/deferred.

## 9.5. Actor Network Static Declarations

The shipped Actor Transfer Level (`ATL`) static surfaces let a top-level actor
record direct child actor instances and report-only static actor groups while
FSMGen preserves that identity in the parser shell and schedule JSON report.

The selected ATL v0 source contract keeps the existing `(actor NAME ...)` root.
The actor body is the network boundary; there is no accepted `(network ...)`
wrapper. The shipped static instance syntax accepts the direct actor-body
`(instance NAME of ACTOR_TYPE)` form below and the compact readability alias
`(NAME : ACTOR_TYPE)`. Report-only static groups use direct actor-body
`(group NAME (members ACTOR...) (mode concurrent))` declarations or the
compact `(concurrent NAME ACTOR...)` alias. Future ATL leaves must keep the
same boundary unless a task-tree leaf explicitly changes the public contract.

Accepted form:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

The compact instance alias is equivalent for scheduling purposes:

```lisp
(actor packet_pipe_compact
  (clock clk)
  (interface
    (input start)
    (output done))
  (reader : packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

The enclosing actor is the network boundary; there is no `(network ...)`
wrapper in the shipped ATL surface. The accepted form lowers to this
parser/schedule-report metadata:

```json
"actor_network": {
  "kind": "static_declaration",
  "instances": [
    {
      "name": "reader",
      "actor_type": "packet_reader",
      "declaration": "actor"
    }
  ],
  "groups": [],
  "association_schedules": [],
  "group_schedules": [],
  "data_movements": [],
  "event_waits": [],
  "transaction_triggers": []
}
```

Verbose instance declarations report `declaration: "actor"`. Compact
`(NAME : ACTOR_TYPE)` aliases report `declaration: "instance_alias"` so
downstream consumers can audit the original source spelling. Instance names
must also satisfy the portable child-instance keyword policy. Instance actor
types must be scalar HDL identifiers, except that selected
library-qualified actor types may use `ALIAS.EXPORT` as described below.
Multiple direct static instances are accepted only by shipped bounded subsets:
scalar or exact-width vector actor-to-actor handoff routes and report-only
static group metadata. Unqualified static instance metadata does not
instantiate or resolve actor types.
Library-qualified static instances resolve to report metadata and reserved
child names, and the selected generated-child subsets emit child `.fsm`
artifacts plus generated tops where documented.

The shipped source contract for ATL actor type resolution is the qualified
library-backed form:

```lisp
(actor packet_system
  (clock clk)
  (interface (input start) (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (complete done)))
```

In that future surface, `ALIAS` must come from the enclosing actor's explicit
`(imports (library LIBRARY as ALIAS))` clause, and `EXPORT` must name an actor
export from that imported library. Same-source `(library ...)` roots and
external library files are the selected resolver inputs, reusing the existing
library import model. Unqualified `(instance NAME of ACTOR_TYPE)` remains
metadata-only external intent until a later leaf explicitly changes it.
Existing `(use alias.actor as instance ...)` remains the shipped reusable
library path with explicit bindings and generated-top behavior; ATL
`(instance ...)` type resolution is a separate actor-network path. The
qualified syntax now fails closed with targeted diagnostics for missing
imports, non-explicit import aliases, unknown aliases, and unknown actor
exports. Known actor exports now resolve to metadata as described below.

The shipped first resolution subset accepts
resolved qualified entries and widens those `actor_network.instances[]`
entries with `type_resolution`, `library`, `alias`, `export`, `module`, and
`scheduled_fsm`. The selected `type_resolution` value is
`library_actor_export`; `module` and
`scheduled_fsm` reserve `<parent_actor>__<instance>` and
`<parent_actor>__<instance>.fsm`. The lowerer now emits those child `.fsm`
artifacts. For the selected one-resolved-child trigger/event subset, it also
emits `<parent_actor>_top.fsm` and reports the top through
`actor_network.generated_tops[]`; other trigger/event/data handoffs remain
external parent handoffs until their interface binding and HDL wiring are
explicitly selected.
The shipped resolved-child fixture
`isf/atl_resolved_child_pipeline.isf` combines one resolved child artifact
with one parent trigger handoff and one parent event wait, and emits the first
generated ATL top for that exact subset.
The shipped resolved-child pin-ingress fixture
`isf/atl_resolved_child_pin_ingress_pipeline.isf` adds one scalar
`(worker.payload pins.payload)` data route to that same generated-top shape.
It wires the top-level input pin through the parent and into the resolved
child input while preserving public route metadata in
`actor_network.data_movements[]`.
The shipped resolved-child vector pin-ingress fixture
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf` uses the same
drive-body route spelling but carries one top-level input pin through the
parent and generated top into one resolved child input at the matching declared
endpoint width. It reports `kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
The shipped resolved-child vector pin-ingress multi-route fixture
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` extends that
same same-child generated-top shape to two route-local vector widths:
`(worker.payload pins.payload)` at width 8 and
`(worker.sideband pins.sideband)` at width 4. Each route reports
`kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
The shipped resolved-child mixed pin-ingress fixture
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` uses the same
same-child generated-top shape with one exact-width vector route
`(worker.payload pins.payload)` and one scalar route
`(worker.valid pins.valid)`. Each route keeps its own
`actor_network.data_movements[]` entry, kind, width, and width source.
The shipped resolved-child pin-ingress multi-route fixture
`isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` adds the bounded
same-child route set `(worker.payload pins.payload)` and
`(worker.sideband pins.sideband)` to that same generated-top shape. It preserves
each public route in `actor_network.data_movements[]` and does not add a public
data-link report key.
The shipped resolved-child pin-egress fixture
`isf/atl_resolved_child_pin_egress_pipeline.isf` adds the inverse scalar
`(pins.result worker.payload)` route to that same generated-top shape. It
wires the resolved child output through the parent and to the top-level output
pin while preserving public route metadata in `actor_network.data_movements[]`.
The shipped resolved-child vector pin-egress fixture
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` uses the same
drive-body route spelling but carries one resolved child output through the
parent and generated top into one top-level output pin at the matching declared
endpoint width. It reports `kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` extends that
same direction to a bounded same-child vector route set. It preserves
route-local widths for `(pins.result worker.payload)` and
`(pins.status worker.status)` and reports each route as
`vector_actor_to_pin_handoff` with the same width source.
The shipped resolved-child mixed pin-egress fixture
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` uses the same
same-child generated-top shape with one exact-width vector route
`(pins.result worker.payload)` and one scalar route
`(pins.valid worker.valid)`. Each route keeps its own
`actor_network.data_movements[]` entry, kind, width, and width source.
The shipped two-child data fixture `isf/atl_two_child_data_pipeline.isf` adds
one one-bit generated-child actor-to-actor route `(writer.payload
reader.payload)` through a generated top with resolved `reader` and `writer`
children. It preserves public route metadata in
`actor_network.data_movements[]` and top discovery in
`actor_network.generated_tops[]`.
The shipped two-child vector data fixture
`isf/atl_two_child_vector_data_pipeline.isf` uses the same route spelling and
generated top but carries the route through matching 8-bit child payload
ports. It reports `kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`.
The shipped bounded multi-route fixture
`isf/atl_two_child_multi_data_pipeline.isf` keeps the same resolved
`reader`/`writer` generated top and adds a second same-source/same-sink
one-bit route `(writer.sideband reader.sideband)`. It reports both route
records in `actor_network.data_movements[]` without adding a public data-link
report key.

The following remain fail-closed/deferred:

- multiple static actor instances outside the shipped actor handoff,
  generated-top, and report-only group metadata subsets;
- `(network ...)` wrappers;
- broader actor-to-actor endpoint movement through widened drive-body
  `(sink source)` pairs outside the shipped scalar one-cycle handoff subset;
- broader qualified actor transaction/event behavior beyond the selected
  parent-handoff subsets;
- generated top-level ATL wiring, interface binding, generated child HDL
  wiring, and group scheduling outside the exact shipped trigger/event top,
  scalar and exact-width vector pin-ingress routes, scalar and exact-width
  vector pin-egress generated-child routes, selected same-source/same-sink
  generated-child actor-to-actor route set, and trigger-batch subsets;
- recursive actor-network declarations.

The broader ATL v0 vocabulary is selected, with only the bounded event-wait,
actor-transaction trigger, scalar data-movement handoff, top-level pin
handoff, and report-only group metadata subsets implemented so far:

- Endpoint-aware movement will reuse existing drive bodies and drive calls.
  Drive body pairs keep the existing `(sink source)` order. The widened
  endpoint names are `pins.name`, `actor.port`, `actor.transaction`,
  `actor.event`, and `group.name`.
- Source-authored `group.name` ATL endpoints are still unsupported when the
  qualifier names a declared static group. Transaction-body `(trigger
  group.name)`, `(await group.name)`, `(await_all group.name)`, `(await_any
  group.name)`, and rule-action `(trigger group.name)` fail with the ATL
  group-endpoint diagnostic, which names the missing group-level trigger
  arbitration/fanout, event aggregation, storage/lifetime, and generated-child
  wiring semantics.
- No top-level `connect`, `transfer`, or `move` movement clause is part of
  ATL v0. Movement remains temporal intent placed by drive-call timing, not a
  permanent actor-to-actor wire.
- The first endpoint-movement code leaf shipped fail-closed reservation for
  unsupported qualified actor endpoint drive-body pairs, and the generated
  actor-to-actor handoff subset is now shipped for one-bit scalar and
  exact-width vector child endpoint routes. The accepted source shape is
  exactly two direct static actor instances, one or more named drive bodies
  with one `(sink_actor.endpoint source_actor.endpoint)` pair each, and one
  top-level transaction drive call per route. All routes in the widened
  generated-child route subset must share the same source child, sink child,
  parent transaction, and contiguous route segment. For each route, FSMGen
  resolves the source child output and sink child input widths. Matching
  positive widths become the generated parent handoff port width; mismatches
  fail closed before scheduled `.fsm` emission. FSMGen rewrites each pair to
  generated parent handoff signals named `source_actor_source_endpoint` and
  `sink_actor_sink_endpoint`, then drives each sink handoff from its source
  handoff during that route's named drive-call cycle.
- The actor-to-actor handoff inserts no storage, route mux, pin movement in
  that actor-to-actor route, inline drive movement, expression movement,
  fan-in/fan-out, groups, CDC, or trigger/await coupling beyond the selected
  generated-child top sequence. Schedule reports expose accepted movements
  through
  `actor_network.data_movements[]` with `kind`, `transaction`, `context`,
  `drive`, `source_instance`, `source_endpoint`, `source_signal`,
  `sink_instance`, `sink_endpoint`, `sink_signal`, `width`, `width_source`,
  `route_lifetime`, `storage`, `source`, and `sink`.
- The first top-level pin movement subset is shipped. It accepts one direct
  static actor instance, one named drive body with one
  `(actor.endpoint pins.input_pin)` scalar pair, and one top-level
  transaction drive call. `pins.input_pin` must name a scalar one-bit
  top-level actor input. FSMGen reads that existing input pin directly,
  rewrites the actor sink endpoint to a generated scalar external handoff
  output named `actor_endpoint`, and drives that output from the input pin for
  the drive-call cycle. The report entry reuses
  `actor_network.data_movements[]` with kind
  `scalar_pin_to_actor_handoff`, `source => top_level_pin`, and
  `sink => external_handoff`.
- The generated-child top-level input-pin movement subset extends that public
  route entry shape for one resolved child and one exact-width vector route.
  It accepts the same `(actor.endpoint pins.input_pin)` drive-body spelling
  only when the top-level input pin and resolved child input endpoint have the
  same positive width. Widths greater than one report
  `kind => vector_pin_to_actor_handoff`,
  `width_source => top_level_input_pin_resolved_child_endpoint_exact_width`,
  `source => top_level_pin`, and `sink => external_handoff`. The selected
  same-child vector multi-route pin-ingress subset accepts multiple such
  route entries when every route has unique pins/endpoints, adjacent
  pre-trigger drive calls, and exact route-local widths. The selected
  same-child mixed scalar/vector pin-ingress subset accepts a route set that
  combines scalar one-bit entries and exact-width vector entries when every
  route shares one resolved child and parent transaction, uses unique
  pins/endpoints, and keeps adjacent pre-trigger drive calls. Width adaptation
  and unresolved external vector pin routing remain deferred.
- The inverse actor-to-top-level output pin subset is shipped. It accepts one
  direct static actor instance, one named drive body with one
  `(pins.output_pin actor.endpoint)` scalar pair, and one top-level
  transaction drive call. `pins.output_pin` must name a scalar one-bit
  top-level actor output. FSMGen exposes the actor endpoint as generated
  scalar external parent input `actor_endpoint`, drives the existing
  top-level output pin for the drive-call cycle, and reports kind
  `scalar_actor_to_pin_handoff` with `source => external_handoff` and
  `sink => top_level_pin`.
- The generated-child top-level output-pin movement subset extends that
  inverse route entry shape for one resolved child and one exact-width vector
  route. It accepts the same `(pins.output_pin actor.endpoint)` drive-body
  spelling only when the resolved child output endpoint and top-level output
  pin have the same positive width. Widths greater than one report
  `kind => vector_actor_to_pin_handoff`,
  `width_source => top_level_output_pin_resolved_child_endpoint_exact_width`,
  `source => external_handoff`, and `sink => top_level_pin`. The selected
  same-child vector multi-route pin-egress subset accepts multiple such route
  entries when every route has unique child outputs/top-level pins, adjacent
  post-event drive calls, and exact route-local widths. The selected
  same-child mixed scalar/vector pin-egress subset accepts a route set that
  combines scalar one-bit entries and exact-width vector entries when every
  route shares one resolved child and parent transaction, uses unique
  child-output/top-output endpoints, and keeps adjacent post-event drive
  calls. Width adaptation and unresolved external vector pin routing remain
  deferred.
- Future blocking orchestration uses `(do actor.transaction)`, and future
  nonblocking orchestration uses `(spawn actor.transaction as NAME)`.
- The shipped parent-handoff subsets are top-level transaction-body
  `(await actor.event)` and `(trigger actor.transaction)`, plus one top-level
  rule action `(trigger actor.transaction)` in the selected rule-action
  trigger subset. Events and trigger handoffs are scheduler-visible one-cycle
  control pulses; event and trigger payloads remain deferred.
- Concurrent groups may still use
  `(group NAME (members ACTOR...) (mode concurrent))`, but groups are static
  review metadata only. Task-scoped ATL associations are created by scheduled
  transaction behavior, not by permanent group membership.
- The concurrent-group implementation axis has shipped targeted diagnostics,
  report-only metadata, and the compact readability alias. FSMGen accepts
  direct actor-body `(group NAME (members ACTOR...) (mode concurrent))`
  declarations and compact `(concurrent NAME ACTOR...)` aliases when every
  member names an already declared direct static actor instance, at least two
  members are present, and the actor is single-clock. Schedule JSON reports
  each group through `actor_network.groups[]` with `name`, `members`, `mode`,
  `declaration`, `source`, and `scheduling`; the current `scheduling` value is
  `metadata_only`. Verbose groups report `declaration: "group"`, while compact
  aliases report `declaration: "concurrent_alias"` so downstream consumers can
  audit the original source spelling. Group endpoints, concurrent execution,
  storage/mux insertion, generated child artifacts, compact movement aliases,
  and CDC behavior remain deferred.
- The shipped first multi-actor trigger scheduling subset uses existing
  top-level transaction-body `(trigger actor.transaction)` clauses: one
  contiguous batch may target distinct static actor instances and lowers as
  one same-cycle external trigger-batch state. The association is temporary
  and scoped to that transaction state; no static `(group ...)` declaration is
  required. Schedule JSON reports canonical scheduling evidence through
  `actor_network.association_schedules[]` with `association`, `kind`,
  `lifetime`, `owner_transaction`, `context`, `members`,
  `target_transactions`, `signals`, `schedule`, `dependency_policy`,
  `storage`, `source`, and `sink` keys while preserving per-target
  `actor_network.transaction_triggers[]` entries. `kind` is
  `temporary_trigger_batch`; `lifetime` is `task_scoped`.
  `actor_network.group_schedules[]` remains a schema-version-1 compatibility
  view. If the trigger set matches one declared static group, the
  compatibility `group` field names that group; otherwise it uses a synthetic
  transaction-scoped name such as `run_trigger_batch`. The selected coupling
  subset permits either one following actor event wait or a contiguous
  source-ordered chain of multiple following event waits after that temporary
  trigger batch. Multi-event waits must target distinct triggered actor
  instances and remain explicit sequential wait states. Generated child
  wiring, group endpoints, data-movement coupling, hidden actor-event
  fan-in/fan-out joins, storage/mux insertion, CDC, compact movement aliases,
  repeated-instance batches, and broader fan-in/fan-out remain fail-closed.

The current actor-event wait subset is deliberately narrower than full child
orchestration. FSMGen accepts top-level transaction-body
`(await actor.event)` when `actor` names a declared direct static actor
instance and `event` is a scalar HDL identifier. A single wait may stand alone
for a single static actor, or follow one selected same-cycle temporary trigger
batch. A bounded multi-wait chain is also accepted after one temporary trigger
batch when every wait is contiguous, source ordered, top level, targets a
distinct triggered actor instance, and the transaction segment has no ATL data
movement. Each wait lowers to a deterministic one-bit parent event handoff
input named `actor_event`; for example, `(await reader.done)` lowers to an
await on `reader_done` and the scheduled parent `.fsm` exposes `reader_done`
as a one-bit input. Multiple accepted waits remain explicit sequential states
and are not collapsed into a same-cycle join. The event source is external in
this subset even when the target actor type resolves and a child `.fsm`
artifact is emitted. FSMGen does not generate an ATL top or wire the event
producer for parent-handoff-only trigger-batch waits.

Schedule JSON reports the shipped wait under `actor_network.event_waits[]`.
Each entry has `transaction`, `context`, `instance`, `event`, `signal`, and
`source`; the current `source` value is `external_handoff`.

The rest of the event boundary remains fail-closed. FSMGen rejects multiple
actor-event waits outside the selected generated-top or trigger-batch
multi-wait shapes, nested actor-event waits, repeated waits to one triggered
actor after a trigger batch, event handoff signal conflicts, and actor-event
waits on `(clock-domains ...)` actors with ATL-specific diagnostics when the
qualifier names a declared static actor instance. The repeated trigger-batch
wait diagnostic names the missing event re-arm or per-event
generation/lifetime contract. Sync-clause attempts such as
`(await_all reader.done writer.done)` or
`(await_any reader.done writer.done)` fail closed with an ATL event-join
diagnostic because `await_all`/`await_any` currently synchronize generated
child completion, not qualified actor-event all-of/any-of joins.
Existing unqualified local behavior remains unchanged: `(await signal)` is
still a local transaction wait, and rule-level `(trigger transaction)` still
targets a local transaction. Dotted enum-looking names that do not name a
static actor instance or static group keep their prior diagnostics; dotted
names that do name a static group fail with the ATL group-endpoint diagnostic.
Event fan-in/fan-out, event payloads, cross-clock actor events, concurrent
group events, generated ATL top wiring, child event-source wiring, and route
muxes remain deferred unless a later leaf explicitly widens this surface.

The current actor-transaction trigger subset is also narrower than full child
orchestration. It accepts a top-level transaction-body
`(trigger actor.transaction)` against a static actor instance either as a
single handoff or as part of the exact temporary trigger-batch subset above,
where `transaction` is a scalar HDL identifier. It also accepts one
top-level rule action `(trigger actor.transaction)` against a static actor
instance. FSMGen maps each accepted trigger to a deterministic one-cycle
parent output handoff named `actor_transaction_start`; for example,
`(trigger reader.capture)` maps to `reader_capture_start`, and a rule action
`(trigger worker.process)` maps to `worker_process_start`. The scheduled
parent `.fsm` exposes and pulses that output at the trigger point: in the
transaction trigger state, in the accepted trigger-batch state, or in the
guarded rule DT for the rule-action subset. Rule-action trigger metadata uses
`context => rule_action`; no owning transaction applies. The trigger sink is
external even when the target actor type resolves and a child `.fsm` artifact
is emitted; generated ATL top wiring, trigger payloads, and ready/backpressure
semantics remain unshipped.
Nested triggers, repeated triggers to the same actor instance, repeated
rule-action qualified triggers, generated handoff signal conflicts, trigger
fan-in/fan-out, cross-clock actor triggers, rule-action trigger payloads or
bindings, source-authored `group.name` triggers, and broader concurrent group
behavior remain deferred unless a later leaf explicitly widens this surface.
Rule-action `group.name` triggers use the same ATL group-endpoint diagnostic
as transaction-body group triggers. Schedule JSON reports accepted triggers
through `actor_network.transaction_triggers[]`.

The current generated-artifact contract is explicit: the parent scheduled
`.fsm` may include the selected one-bit actor-event handoff input, selected
one-cycle actor-transaction trigger output, selected scalar data-movement
handoff ports, and selected same-cycle trigger-batch handoff outputs. FSMGen
also emits resolved ATL child scheduled `.fsm` artifacts for valid
`(instance NAME of ALIAS.EXPORT)` entries. For one resolved child, one parent
trigger handoff, one parent event wait, and matching parent/child clock/reset
names and policies, FSMGen emits `<parent>_top.fsm`; it instantiates the
parent and child, wires public pins to the parent, binds the parent trigger
handoff to the child transaction start input discovered from the child's
authored `(on START_SIGNAL)`, binds the child event output to the parent event
handoff input, and reports the top through `actor_network.generated_tops[]`.
For the selected scalar pin-ingress generated-child route set, the same top also
wires parent generated handoff outputs such as `worker_payload` and
`worker_sideband` to child scalar inputs such as `payload` and `sideband`. The
child scheduled `.fsm` may include generated `+interface` role metadata for
those selected inputs so HDL generation preserves the child module ports.
For the selected scalar and exact-width vector pin-egress generated-child route
sets, the same top also wires child outputs such as `payload` and `status` to
parent generated handoff inputs such as `worker_payload` and `worker_status`;
the parent then drives the public top-level output pins through the scheduled
drive-call states. The child scheduled `.fsm` may include generated
`+interface` role metadata for those selected outputs so HDL generation
preserves the child module ports.

FSMGen still emits no generated route mux, no generated internal handoff
storage, no broader HDL event wiring, and no multi-child generated ATL top
beyond the selected two-child trigger/event and same-source/same-sink
actor-to-actor route set. Any later ATL implementation that emits broader
artifacts must document their names, report keys, and review surfaces in the
same slice that ships them.
