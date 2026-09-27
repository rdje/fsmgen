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

Literal guards retain their boolean meaning: `(when 0)` disables a rule and
`(when 1)` enables it. For example, `disabled` remains at its reset value while
`enabled` becomes `6` on a clock edge after reset:

```lisp
(actor constant_rules
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (output disabled (width 8) (reset 0))
    (output enabled (width 8) (reset 0)))
  (rule never (when 0) (set disabled 5))
  (rule always (when 1) (set enabled 6)))
```

The false predicate is emitted as `< (!= 0 0)`. The explicit expression avoids
confusing a numeric guard with the `.fsm` delayed-pulse operator `<N`. A true
rule header remains unconditional. Symbolic and compound guards retain their
normal condition semantics.

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
- `(pulse target)` — guarded one-cycle delayed pulse on a scalar output or
  scalar actor storage variable
- `(trigger transaction)` — guarded one-cycle delayed pulse on a per-rule
  trigger source; generated fan-in drives the transaction start signal
- `(priority over other_rule)` — a rule-local priority edge used by the
  covered priority and resource-arbitration paths

Rule actions are structurally validated before the actor shell is returned.

Rule reads must resolve to the actor's declared interface, storage, parameters
or constants. This applies to guards, nested RHS expressions, bit selections,
and bank index/value operands. Enum members and scalar aggregate leaves retain
their declared meaning. A transaction-local variable is private to its
transaction; its inferred assignment target does not become an actor input.
When a transaction samples or drives a value that a rule must read, declare
that shared signal as actor storage. The AXI AW/AR/W drivers and B/R acceptors
do this for their captured payloads and launch/arm handoffs; the burst W driver
also declares its shared active flag. Their transfer timing is unchanged.
AXI composition coordinators likewise declare their shared active/completion
flags and expected response IDs instead of relying on inferred rule state.

For example, this complete source declares every rule operand:

```lisp
(actor valid_demo
  (interface (input start) (input VALID)
    (output A) (output B) (output done))
  (transaction tx (on start) (complete done))
  (rule r_a (A VALID))
  (rule r_b (B VALID)))
```

Removing `(input VALID)` fails before scheduling or HDL generation. The
diagnostic names `valid_demo`, `VALID` and both reading rules; FSMGen does not
invent an input port. Native check/semantic JSON and their MCP tools preserve
the stable code `FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND` and authored
source identity. Declare the intended actor signal, or correct its spelling.

The shipped `(set port expr)` action is the canonical explicit rule setter.

The shorter `(port expr)` action remains supported shorthand. Both accept a
scalar RHS or one list expression using the same `.fsm` RHS expression domain
as transaction `(set var expr)` and `(update var expr)`, while keeping rule
assignments flopped with `<-`. Rule guard and assignment expressions reject
literal-zero, actor-constant-zero, and actor-parameter-zero division/modulo
divisor operands before scheduled `.fsm` emission; dynamic scalar divisors
lower unchanged and are not yet proven nonzero.

`(pulse target)` is the bounded rule-owned pulse action. `target` must name a
scalar actor output or scalar actor storage variable. The action lowers as a
one-cycle delayed pulse through the same `<1` family as transaction
completion, participates in pulse-domain compatible fan-in, and is not a
sticky data assignment.

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
`(pulse target)` actions are delayed-pulse assignments selected by the same
guarded DT.

`(trigger transaction)`
uses `<1` on a generated
`rule_transaction` source so the request remains pulse-shaped, and a generated
combinational fan-in DT drives `transaction_start` without adding another
cycle.

```lisp
(-always_ready <ready
  (<- (valid> 1))
  (<1 (ready_pulse> 1))
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

This check is intentionally best-effort. A named drive with exactly one
distinct local transaction caller and no generated activation source now uses
that transaction as its logical owner for rule/transaction conflict and
priority analysis. The scheduled assignments retain their raw `drive`
provenance. Calling the same drive more than once from the same transaction
still counts as one distinct caller.

Priority is target-local in both directions. In this complete actor, the rule
has priority over `main`:

```lisp
(actor named_drive_priority_example
  (clock clk)
  (reset reset)
  (interface
    (input start)
    (input override_req)
    (output done)
    (output out)
    (output side))
  (priority force_out over main)
  (drive drive_zero
    (out 0)
    (side 1))
  (transaction main
    (on start)
    (drive drive_zero)
    (complete done))
  (rule force_out override_req
    (out 1)))
```

When `override_req` and the drive request are active together, the lowerer adds
the inverse rule guard only to `drive_zero`'s `out=0` assignment. The `side=1`
assignment, drive request, transaction progress, parameter flow, and completion
are not masked. Reversing the declaration to
`(priority main over force_out)` leaves the drive assignment unchanged and
guards only the conflicting rule assignment with the inverse full drive
activation.

Different-value overlap from a unique caller without a priority now fails
closed as `isf_conflicting_rule_transaction_writes`; a cycle remains
`isf_priority_cycle_conflict`, and same-value fan-in remains compatible. A
declared priority cannot safely choose a transaction for a drive with multiple
local callers, generated callers, or mixed local/generated ownership, so that
case fails before HDL as
`isf_ambiguous_rule_transaction_drive_priority`. Unprioritized ambiguous or
unused-drive overlap remains a nonfatal
`isf_unproven_rule_drive_overlap/not_doable` issue: the compiler explicitly
says the proof is unavailable rather than claiming the overlap is safe.

Generated SystemVerilog selector assertions remain authoritative and pass for
both resolved directions; native Verilog is also runtime-qualified. Direct
VHDL generation now lowers the named-drive scalar reductions by identity or
complement and emits no foreign reduction token. External VHDL compiler/runtime
qualification remains unclaimed under decision `0023`; token-free generation
alone does not establish it.
Private writer qualification now retains the exact invocation source for each
named-drive body assignment. Local calls keep their full caller set, including
an empty set for an unused drive. Generated calls retain the actual child,
instance, activation kind and source owner for `spawn`, `do` or a rule trigger.
Generated assignments do not inherit unrelated local callers. These records
preserve existing target-local priority guards; they do not establish a new
grant or prove that different callers are mutually exclusive.

The public report and normalized-semantic key sets do not widen. See the
[shipped behavior](../../ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_BEHAVIOR.md)
and the preceding
[contract record](../../ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md).

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

Priority suppression retains the union of every conflicting writer condition
from each higher-priority owner. For a transaction writing `out` in two states,
the lower rule now carries the following scheduled `.fsm` guard:

```lisp
(<- (out> 9) <(! (| (state_active main_set_1) (state_active main_set_2))))
```

The condition set is deduplicated and ordered deterministically. A named drive's
activation condition participates alongside direct state writers. Suppression
stays local to the conflicting target; unrelated rule outputs, transaction
progress and the rule's resource grant remain separate. Same-value writes remain
compatible in source admission and do not acquire a priority mask merely because
their owners share a priority relation.

T1974 qualifies emitted predicates and complete native/API/newline/carrier
products. Its observed SystemVerilog and Verilog runs preserve ordered writes,
opposite priority, compatible equal-value overlap, named-drive writes,
unrelated output progress, repeated requests and synchronous reset. The resource
fixture runs with its peer request inactive; this is not a general contention or
fairness qualification. A cloned carrier restoring only the lost contributor
is rejected by the enabled different-value selector assertion. Complete source
identities, stage results, original bounds and cleanup evidence are retained in
`docs/audits/priority-runtime-qualified-20260928/`.

The prior executed failures exposed an incompatible same-value assertion and
a premature synchronous-reset check in the testbench. Decision `0111` corrects
the selector policy to `compatible_fanin`; the bench waits across a rising edge.
Their complete first-attempt records remain in
`docs/audits/priority-contributor-repair-20260928/` and
`docs/audits/priority-reset-oracle-20260928/`. This qualification closes the
priority repair. Broader writer admission and the historical native `setpgid`
cause remain separately owned.

Generated SystemVerilog adds verification-only checks between different RHS
value selectors. They are wrapped in `` `ifndef SYNTHESIS`` and are not emitted
for Verilog. Source enables that select the same RHS value are compatible: the
backend ORs them into one value-family enable and permits simultaneous activity.
For example, two admitted rules that both drive `valid` to `1` retain:

```systemverilog
assign valid_1_en = r0_valid_1_en | r1_valid_1_en;
```

The legacy `same_value_assertion` field remains discoverable in normalized
semantic reports. Its policy kind now identifies compatible fan-in:

```json
{
  "kind": "compatible_fanin",
  "target_signal": "valid",
  "rhs_value": "1",
  "input_count": 2,
  "input_enable_signals": ["r0_valid_1_en", "r1_valid_1_en"]
}
```

This descriptor imposes no source-exclusivity assertion. Consumers must read
`kind`; a `selector_conflict_targets` entry alone does not promise an emitted
one-hot check. Explicit `onehot0` policy metadata still emits its check.

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

Local rule input payloads retain the value accepted by the target's initial
state. While that state is active, a requesting source is visible immediately;
its value is captured only when the authored entry condition admits it. Inline
entry samples therefore see the same value as later reads after a wait. Requests
while the target is busy do not replace its accepted payload. There is no request
queue or implicit source winner. Existing rule/resource grants still control
which source requests are produced.

The target authors its entry condition: `(on worker_start)` accepts a request,
while a leading `when` can also qualify its payload:

```lisp
(actor local_snapshot (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input allow) (input data (width 4))
            (output early (width 4)) (output observed (width 4)) (output done))
 (transaction worker (ports (input payload (width 4)))
  (when (& worker_start allow (== payload 7)) (sample payload as early))
  (wait 3) (set observed payload) (complete done))
 (rule fire start (trigger worker (bind (input payload data (timing snapshot))))))
```

With `allow` asserted and `data` equal to seven when `fire` runs, both `early`
and `observed` receive seven even if `data` changes after the request. The entry
view does not depend on the payload-qualified condition, avoiding a combinational
cycle. Private retained storage uses the advertised `transaction_port_binding`
role; authored binding names remain in the schedule. Source preparation and
final domain declaration checks include the helper.

The production SV/Verilog runtime fixture
`t/data/isf_local_rule_snapshot_runtime.isf` exercises the full invocation
lifecycle through public pins:

- A rejected entry condition does not queue a request for later admission.
- A new request while the body waits, including at a later `(on proceed)`,
  cannot replace the accepted payload or create a queued invocation.
- Reset aborts the in-flight invocation; a later request captures fresh data.
- A held rule condition keeps producing level requests. The target can accept
  a new invocation when it returns to its initial state. Its next entry sample
  may update on the same edge as the preceding invocation's delayed completion
  pulse; the completed result still belongs to the preceding invocation.
- Priority and round-robin `transaction_start` resources select the payload
  from the granted rule. Ungranted overlap retains the SystemVerilog selector
  assertion; it does not gain an implicit winner.

Run the qualification with:

```sh
FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh \
  prove -Iperl -It/lib t/1966-isf-local-rule-snapshot-runtime.t
```

The Darwin opt-in requires the repository's qualified simulator runtime. The
suite also retains generated live-handoff and unguarded-target controls.
Independent-controller reachability and local-call ownership limitations still
apply; local snapshot qualification does not close them. Generated live handoffs
retain their own timing, and an unguarded local target remains free-running.

Parameterized rule triggers are generated-child activations, not writes to
shared transaction parameters. The source shape is
`(trigger transaction (params (NAME value) ...) (bind ...))`, reusing the
same static parameter block shipped for spawn and blocking `do`.

The lowering preserves the shipped trigger timing. The rule DT still creates
the per-rule trigger source and, for input bindings, per-rule payload sources.

Instead of feeding the shared `transaction_start` fan-in, the parameterized
path elaborates a static generated child instance named
`{rule}_{transaction}_trigger_{ordinal}` and a generated trigger handoff DT
drives `{instance}_start` from that trigger source while input handoffs read
the retained per-rule payload beyond the pulse. The generated top applies the `(params ...)` overrides on that
`?fsmc` instance. The parent wires `instance.done` back for uniform generated
composition and reads it into an internal observer signal, but the rule does
not wait for it. Generated-child rule-trigger output bindings copy a bound
child output handoff into a scalar actor target under that same done-observer
signal. Direct/local rule-trigger output bindings remain rejected because a
shared local transaction target does not identify which rule trigger owns a
completion.

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
references are accepted. Named-drive rule/transaction priority uses the
actor-level `(priority lhs over rhs)` form because a drive is not itself a
legal priority actor.

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
  (resource response_outputs
    (kind output_bundle)
    (arbiter priority)
    (members valid ready)
    (users force_valid normal_valid))
  (resource fair_outputs
    (kind output_bundle)
    (arbiter round_robin)
    (members valid ready)
    (users fair_valid fair_ready))
  (resource main_transfer
    (kind transaction_start)
    (arbiter priority)
    (users fast_path slow_path))
  (resource fair_transfer
    (kind transaction_start)
    (arbiter round_robin)
    (users fair_path_a fair_path_b))
  (resource store_bus
    (kind storage_port)
    (arbiter priority)
    (members slot shadow)
    (users writer_a writer_b))
  (resource fair_rule_exec
    (kind rule_slot)
    (arbiter round_robin)
    (users high_pri normal_pri low_pri)))
```

Resources name shareable hardware or scheduler-controlled ownership domains.

The resource name, such as `rule_exec` or `mem_port`, is the author-defined
instance handle. The resource kind says what is being shared. The arbiter says
how requesters are selected. Arbiter names accepted by the parser are
`priority` and `round_robin`.

Resource metadata is structurally validated by the parser, including supported
arbiter names, resource kinds, duplicate resource names, duplicate resource
subclauses, duplicate users, duplicate members, known users for enforced
resource kinds, declared local transaction names for bound
`transaction_start` resources, and declared actor-output/storage-signal
members for explicit `output_bundle` lists plus storage-only members for
explicit `storage_port` lists. `(resources ...)` is a singleton actor clause,
so repeated resources blocks are rejected rather than merged or overwritten.

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
| `rule_slot` | shipped for `priority` and bounded `round_robin` arbitration | A one-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | shipped for `priority` and bounded `round_robin` arbitration | A group of actor outputs or rule-written LHS targets with rule users. A grant enables the whole winning bound rule DT for that cycle; optional explicit members name declared actor output ports or concrete actor-owned storage signals. |
| `transaction_start` | shipped for `priority` and bounded `round_robin` arbitration | The start/request fan-in for one local transaction. The resource name is the transaction name, and rule users must trigger it. |
| `storage_port` | shipped for `priority` and bounded `round_robin` arbitration | Explicit actor-owned storage signals protected by a one-cycle rule-user grant. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |

Today, `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port`
with `priority` arbitration have shipped scheduler behavior for declared rule
users. Each bound rule requests the resource when its normalized rule guard is
true. Priority edges choose the active winner, and the generated grant gates
the whole lowered rule DT DTE without adding a cycle.

`rule_slot`, `output_bundle`, `transaction_start`, and `storage_port` also
support bounded `round_robin` arbitration for declared rule users. The
`(users ...)` list is the circular grant order. FSMGen generates a pointer named
`isf_rr_<resource>_turn`, grants the first requesting rule at or after the
current pointer, gates the whole winning rule DT for that cycle, and advances
the pointer only from the winning rule DT. The generated pointer is reported
in `inferred_storage[]` as a counter with role
`resource_round_robin_pointer`. The pointer name must not collide with
existing actor ports, constants, parameters, declared storage, or generated
counters.

Backlog resource kinds are parser-recognized names, not runtime support
claims; a backlog kind with bound users fails closed until its lowering
contract ships. `round_robin` remains unsupported for backlog resource kinds
and other non-selected resource surfaces.

Without explicit members, `output_bundle` keeps the existing implicit surface:
the bound rule users and the outputs or other LHS targets they drive describe
the bundle intent. `output_bundle` may include an explicit `(members name...)`
list. Each member must be a declared actor output or concrete actor-owned
storage signal; when members are explicit, every listed member must be written
by a bound rule user, and no bound rule user may write a declared output or
actor-owned storage signal outside the list. Bank roots, aggregate paths,
inferred undeclared targets, and arbitrary expressions remain outside explicit
member lists. Under bounded `round_robin`, the same member validation and
`resource_arbitration[].members` reporting contract applies while the
generated pointer selects the winning bound rule for the cycle.

`transaction_start` resources use the resource name as the target local
transaction; each bound rule user must trigger that transaction. Priority
grants suppress lower-priority rule DTs before their trigger source pulses
feed the generated `{transaction}_trigger_fanin` DT. Bounded round-robin
grants use the generated pointer to select the winning requester before that
same trigger source fan-in path, preserving the existing fan-in owner and
timing.

`storage_port` requires an explicit `(members name...)` list when users are
bound. Each member must be a concrete actor-owned storage signal: a scalar
storage variable or scalarized bank element signal. Bound rule users may not
write concrete actor-owned storage signals outside that list, and every listed
member must be written by at least one bound rule user. The grant still gates
the whole bound rule DT. Under bounded `round_robin`, the same mandatory
member validation and `resource_arbitration[].members` reporting contract
apply while the generated pointer selects the winning bound rule for the
cycle. The grant does not create route mux/storage, storage locks, memory-port
protocols, or hold/release ownership.

Schedule reports expose output-bundle and storage-port member names through
`resource_arbitration[].members`; resources without explicit members use an
empty array. `resource_arbitration[].arbiter` is `priority` or `round_robin`.
For priority grants, `suppressed_by` names higher-priority bound rule users.
For round-robin grants, it names the dynamic peer users that can block that
grant for a given pointer position and request set. The remaining resource
work is tracked in [Feature Backlog](14-feature-backlog.md).
