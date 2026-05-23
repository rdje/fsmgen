# Rules and Priorities

Rules lower to non-state DTs whose DTE is the rule condition. Their assignments
are independent of the transaction state machine.

## Rule Syntax

```lisp
(rule always_ready ready
  (valid 1)
  (trigger main_transfer))

(rule push_only (& push (! pop) (! full))
  (write_fire 1))
```

The long form remains accepted and normalizes to the same parser output:

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

This rule-local `(when ready)` is a guard clause, not transaction control flow.

It has no body of its own; it guards the rule actions that follow it. The
body-bearing `(when condition body...)` form is only described in
[Control Flow](13d-control-flow.md) because it is a transaction clause.

Rule guards may be scalar conditions or list expressions using the normal
`.fsm` expression spelling. Expression guards are the intended way to author
FIFO fire predicates such as `(& push (! pop) (! full))` without creating
temporary scalar condition signals. Local and package enum members are valid
standalone scalar rule guards too. A local guard such as `mode.BUSY` lowers to
the non-state DT header guard `<mode.BUSY`, while a package guard such as
`shared.mode.BUSY` lowers to `<shared.mode.BUSY`. The guard is evaluated by the
existing `.fsm` condition-suffix machinery, so a nonzero enum value selects the
rule and a zero-valued enum member does not. Scalar aggregate storage leaves
from declared actor-owned storage are valid standalone rule guards as well.

For example, `frame.flag` lowers to `<frame.flag`, and a package-backed list
leaf such as `lanes[1]` lowers to `<lanes[1]`. Subaggregate guards, such as a
whole record member or whole list member, still fail closed.

```lisp
(rule fire_when_busy mode.BUSY
  (set fire 1))

(rule fire_when_shared_busy
  (when shared.mode.BUSY)
  (set fire 1))

(rule fire_when_flag frame.flag
  (set fire 1))

(rule fire_when_lane
  (when lanes[1])
  (set fire 1))
```

**Actions**:
- `(set port expr)` — explicit guarded flopped assignment when the condition holds
- `(port expr)` — guarded flopped assignment when the condition holds
- `(trigger transaction)` — guarded one-cycle delayed pulse on a per-rule
  trigger source; generated fan-in drives the transaction start signal
- `(priority over other_rule)` — a rule-local priority edge used by the
  covered priority and resource-arbitration paths

Rule actions are structurally validated before the actor shell is returned.

The shipped `(set port expr)` action is the canonical explicit rule setter.

The shorter `(port expr)` action remains supported shorthand. Both accept a
scalar RHS or one list expression using the same `.fsm` RHS expression domain
as transaction `(set var expr)` and `(update var expr)`, while keeping rule
assignments flopped with `<-`. Rule guard and assignment expressions reject
literal-zero, actor-constant-zero, and actor-parameter-zero division/modulo
divisor operands before scheduled `.fsm` emission; dynamic scalar divisors
lower unchanged and are not yet proven nonzero.

`(trigger transaction)` must name a declared transaction in the same actor;
forward references are accepted because validation happens after the full actor
body is collected. `(priority over other_rule)` must name a declared rule in
the same actor.

**Lowering**: Non-state DT block with the rule guard emitted as the DT header
DTE. Shorthand scalar or expression guards and long-form `(when ...)` guards
all become the public parser `when` field. Scheduled `.fsm` emission writes
that guard once in the DT header instead of repeating it on every assignment
or wrapping the actions in a nested guard block. `(set port expr)` and ordinary
`(port expr)` actions are flopped assignments selected by the guarded DT.

`(trigger transaction)`
uses `<1` on a generated
`rule_transaction` source so the request remains pulse-shaped, and a generated
combinational fan-in DT drives `transaction_start` without adding another
cycle.

```lisp
(-always_ready <ready
  (<- (valid> 1))
  (<1 (always_ready_main_transfer 1))
)

(-push_only <(& push (! pop) (! full))
  (<- (write_fire> 1))
)

(-fire_when_busy <mode.BUSY
  (<- (fire> 1))
)

(-fire_when_flag <frame.flag
  (<- (fire> 1))
)

(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

## Rule Data Conflicts

Rule data writes are checked before generated scheduled `.fsm` text is accepted.

When two rules drive the same target to incompatible values, lowering fails
closed with `isf_conflicting_rule_writes`; compatible same-target/same-value
rule writes remain accepted.

The checker also accepts same-target rule writes when their rule guards are
proved mutually exclusive by direct contradictory facts. For example, a
push-only FIFO rule guarded by `(& push (! pop) (! full))` and a pop-only FIFO
rule guarded by `(& pop (! push) (! empty))` cannot both fire because one path
requires `pop=0` while the other requires `pop=1`, and likewise one path
requires `push=1` while the other requires `push=0`. Equality facts are covered
too: rules guarded by `(== occupancy 1)` and `(== occupancy 2)` cannot both
select the same target in the same cycle. That proof is enough for the
scheduler to avoid priority boilerplate for the covered FIFO-style cases.

The proof is intentionally conservative: if the guard equations are not
reduced to direct contradictory signal or equality facts, the pair remains
unproved and uses the existing compatible fan-in, priority-resolution, or
fail-closed conflict path.

This check is intentionally best-effort. Rule/drive same-target overlap is
recorded internally as `isf_unproven_rule_drive_overlap` with
`proof_status => not_doable` because the current compile-time analysis does
not prove that the rule guard and generated drive-start guard can or cannot be
active together.

That status is explicit: the compiler is flagging that the proof is NOT doable
for the current analysis rather than claiming the overlap is safe.

Rule priority can resolve the supported rule/rule data-conflict case. If
`high` has priority over `low` and both rules drive the same target to
different values, the lowerer keeps `high` unchanged and suppresses `low`'s
assignment whenever `high`'s rule condition is active:

```lisp
(-high <a
  (<- (valid> 1))
)

(-low <b
  (<- (valid> 0) <(! a))
)
```

The schedule-report projection for these conflict facts is intentionally
bounded. Successful reports with no nonfatal issues keep
`compile_issues` as an empty array. Nonfatal issue entries now expose only
stable issue code, severity, target/domain, `proof_status`, human-readable
reason text, and capped source summaries. Accepted compatible fan-in groups now
project as bounded `compatible_fanin_groups` entries with classifier
kind/domain, target/value facts, and the same source-summary shape. Raw
assignment provenance, activation proof context, and priority-suppression
bookkeeping remain lowerer internals.

Rejected conflicts stay on the fail-closed diagnostic path. For a provable
rule/rule conflict, in-process scheduling and `--emit-schedule-json` both
reject the source with a diagnostic that names the stable conflict code,
target, reason, conflicting owners, source kinds, operators, and values. The
CLI does not emit successful schedule JSON for that case.

Priority is target-local here: it gates the conflicting assignment, not the
whole lower-priority rule. Priority cycles fail closed with
`isf_priority_cycle_conflict`, and incomparable conflicting rules still fail
closed instead of being ordered by source text.

Actor-level rule/transaction priority uses the same target-local rule. In the
covered same-target data case, `rule over transaction` guards the
transaction-state assignment with the inverse active rule condition. The
opposite direction, `transaction over rule`, leaves the transaction-state
assignment unchanged and guards the lower-priority rule assignment with a
scheduled `.fsm` state-active predicate such as:

```lisp
(-force_out <force
  (<- (out> 1) <(! (state_active main_update_1)))
)
```

The `state_active` guard is internal scheduled `.fsm` review syntax. It lowers
to a `current_state == MAIN_UPDATE_1` comparison without creating fake module
input ports for `current_state`, `MAIN_UPDATE_1`, or `main_update_1_en`.

Generated SystemVerilog now adds verification-only selector assertions for the
analyzed muxes that reach HDL generation. These checks are wrapped in
`` `ifndef SYNTHESIS`` and are not emitted for Verilog. The runtime checks use
the actual mux selectors generated by the `.fsm` backend:

- Same-value source selector check: if two rules or DTs feed the same
  `LHS`/`VAL` selector, the source enables are checked with `$onehot0`.
- Multi-value selector check: if one `LHS` mux has two or more value selectors,
  those value selectors are checked with `$onehot0`.

For example, two compatible rules that both drive `valid` to `1` can still be
accepted at compile time, but verification HDL checks that the source enables
for `valid=1` are not active together:

```systemverilog
assert ($onehot0({r0_valid_1_en, r1_valid_1_en}))
  else $error("selector same-value conflict: valid 1");
```

For a priority-resolved `valid=0` / `valid=1` rule conflict, the lower-priority
assignment is still statically guarded, and verification HDL also checks the
whole `valid` mux selectors:

```systemverilog
assert ($onehot0({valid_0_en, valid_1_en}))
  else $error("selector multi-value conflict: valid");
```

The instrumentation is derived from backend assignment analysis, so it also
covers generated muxes such as `next_state`. Standalone DT roots keep their
existing standalone-DT multi-drive assertions instead of receiving a duplicate
selector block. Binding-generated muxes use the same path: accepted
rule-trigger input payload fan-in and spawned-output binding fan-in are emitted
as ordinary guarded `.fsm` assignments, so the HDL backend can add the same
verification-only selector assertions for their transaction ports or actor
outputs.

## Trigger Fan-In

Shipped rule-trigger lowering preserves trigger provenance before transaction
activation. If rule `Rj` triggers transaction `Tk`, the rule DT emits a `<1`
pulse on the generated one-bit source `Rj_Tk`. For each triggered transaction,
the scheduler emits one combinational `Tk_trigger_fanin` DT that drives
`Tk_start` from the OR of all rule sources for `Tk`.

The fan-in is combinational on purpose. It does not add a cycle after the
per-rule `<1` pulse appears; it only separates "which rule requested the
transaction" from "the transaction sees at least one request."

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

With a single rule source, the generated fan-in assigns the source directly:

```lisp
(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

Parameterized rule triggers are generated-child activations, not writes to
shared transaction parameters. The source shape is
`(trigger transaction (params (NAME value) ...) (bind ...))`, reusing the
same static parameter block shipped for spawn and blocking `do`.

The lowering preserves the shipped trigger timing. The rule DT still creates
the per-rule trigger source and, for input bindings, per-rule payload sources.

Instead of feeding the shared `transaction_start` fan-in, the parameterized
path elaborates a static generated child instance named
`{rule}_{transaction}_trigger_{ordinal}` and a generated trigger handoff DT
drives `{instance}_start` plus the input handoff ports under that trigger
source. The generated top applies the `(params ...)` overrides on that
`?fsmc` instance. The parent wires `instance.done` back for uniform generated
composition and reads it into an internal observer signal, but the rule does
not wait for it. Rule-trigger output bindings remain unsupported because there
is no completion point in the rule action.

Malformed or ambiguous trigger parameter overrides must fail before scheduled
artifacts are emitted: duplicate `params` blocks, duplicate override names,
unknown target parameters, incompatible aggregate/list shapes, unsupported
symbolic or expression override values, generated instance name collisions, and
generated handoff-port collisions are all diagnostics rather than implicit
fallbacks.

## Rule Examples

### Error Gate

```lisp
(rule error_gate err
  (valid 1)
  (err 1))
```

**DT block**:
```lisp
(-error_gate <err
  (<- (valid> 1))
  (<- (err> 1))
)
```

### Parsed Priority

```lisp
(rule high_pri start
  (priority over always_ready)
  (rdata 0))
```

Inline priority is accepted and structurally validated by the parser, then
used by current lowering for same-target rule/rule data conflicts. The
`other_rule` target must name a declared rule in the same actor; forward
references are accepted. It does not resolve rule/drive conflicts yet.

## Priorities

```lisp
;; Separate section
(priority main_transfer over chained)
(priority read_burst over write_burst)
```

Priority declarations are structurally validated as
`(priority lhs over rhs)`. Both sides must name declared transactions or rules
in the same actor; forward references are accepted. When both sides are rules,
the edge can resolve same-target rule/rule data conflicts by suppressing the
lower-priority assignment under the higher-priority rule condition.
When one side is a rule and the other side is a transaction, actor-level
priority can resolve the covered same-target data case in either direction as
long as both assignments use the same timing operator.

Transaction/transaction priority and broader resource arbitration are still
deferred. The remaining enforcement work is tracked in
[Feature Backlog](14-feature-backlog.md).

## Resources

```lisp
(resources
  (resource rule_exec
    (kind rule_slot)
    (arbiter priority)
    (users high_pri low_pri))
  (resource mem_port
    (arbiter round_robin)))
```

Resources name shareable hardware or scheduler-controlled ownership domains.

The resource name, such as `rule_exec` or `mem_port`, is the author-defined
instance handle. The resource kind says what is being shared. The arbiter says
how requesters are selected. Arbiter names accepted by the parser are
`priority` and `round_robin`.

Resource metadata is structurally validated by the parser, including supported
arbiter names, resource kinds, duplicate resource names, duplicate resource
subclauses, duplicate users, and known `rule_slot` users. `(resources ...)` is
a singleton actor clause, so repeated resources blocks are rejected rather
than merged or overwritten.

The table below is the current public registry of things ISF can name as
shareable resources. It deliberately starts small. A new kind should enter the
registry only when its authoring shape, lowering path, runtime semantics,
diagnostics, report surface, and tests are explicit.

The code owner is `FSM::Support::ISFResourceCatalog`; the parser and
machine-readable ISF public contract use that same owner. Downstream consumers
can discover the current arbiter list, resource-kind list, status map, meaning
map, enforced kinds, and backlog kinds from
`embedding.isf_public_interface`.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | A one-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | backlog | A group of actor outputs or LHS targets that must have one owner for a cycle. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `transaction_start` | backlog | The start/request fan-in for one transaction. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |
| `storage_port` | backlog | A shared state, register, memory, or storage-port access path. |

Today, only `rule_slot` with `priority` arbitration has shipped scheduler
behavior. Each bound rule requests the slot when its normalized rule guard is
true. Priority edges choose the active winner, and the generated grant gates
the whole lowered rule DT DTE without adding a cycle. Backlog resource kinds
are parser-recognized names, not runtime support claims; a backlog kind with
bound users fails closed until its lowering contract ships. The remaining
resource work is tracked in [Feature Backlog](14-feature-backlog.md).
