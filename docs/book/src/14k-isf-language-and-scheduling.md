# ISF Language and Scheduling Backlog

### ISF Enum, Type, And Aggregate Parity

Status: shipped bounded surface; broader enum target/operator and aggregate
carrier/subaggregate surfaces remain backlog. The completed task tree is
[ISF-TYPE-AGGREGATE-PARITY](../../tasks/ISF-TYPE-AGGREGATE-PARITY.md), and
the user-facing shipped-surface matrix is
[Types, Enums, And Aggregates](13j-type-enum-aggregate.md).

Goal: let ISF use the same enum, type, and aggregate variable capability that
`.fsm` already exposes, without inventing a second type system.

Current boundary: ISF now ships scalar type aliases for width-bearing actor
interface ports, transaction ports, and actor-owned storage, plus packed
`list`/`record` aliases on actor-owned storage variables only.

Actor bodies may carry `(types ...)` declarations whose payloads map directly
to `.fsm` `+types`; existing `.fsm` packages may be referenced with `(imports
(package shared_pkg) ...)`; and declarations may use `(type NAME)` instead of
`(width N)`, where `NAME` is local (`byte`, `frame_t`) or package-qualified
(`shared_pkg.byte`, `shared_pkg.frame_t`).

Lowered scheduled `.fsm` preserves `+types`, `+import`, typed `+size`
entries, and embedded imported package roots so the review artifact and CLI
HDL generation stay self-contained.

Actor-local `(enums ...)` declarations are accepted as declaration artifacts
and preserved as scheduled `.fsm` `+enums`.

Actor constants may now consume enum members with local `mode.BUSY` or
package-qualified `shared.mode.BUSY` spelling; the authored token is
preserved in scheduled `.fsm` `+constants` and schedule reports, while the
resolved non-negative integer value feeds static wait lowering and existing
static activation-parameter overrides.

The implementation path remains task-tree-managed.

The current shipped subset also continues to accept numeric/exact-width
parameter values, scalar actor parameter defaults backed by local or
package-qualified enum members, actor aggregate/list parameter default leaves
backed by local or package-qualified enum members, generated child
transaction scalar parameter defaults backed by local or package-qualified
enum members, generated child transaction aggregate/list parameter default
leaves backed by local or package-qualified enum members, actor-local
constants and actor-local scalar parameter defaults for selected generated
activation specialization values, and compatible aggregate/list literal
parameter values.

Scalar activation parameter overrides and scalar leaves inside activation
aggregate/list parameter override values may now also consume actor-local
scalar parameter defaults, local enum members, package-qualified enum members,
and qualified imported package scalar constants.

Direct transaction `set` RHS scalar values and scalar operands inside
transaction `set` RHS expressions may consume local and package-qualified
enum members, transaction `when`/`while`/`until` condition expressions may
consume local and package-qualified enum members as scalar operands.

Direct transaction `when`/`while`/`until` scalar conditions may now consume
local and package-qualified enum members too, such as `(when mode.BUSY (set
fire 1))`, `(while mode.BUSY (set busy 1))`, or `(until shared.mode.BUSY
(complete done))`; those dotted standalone condition tokens lower through
computed `.fsm` selector syntax such as `?(mode.BUSY)` or
`?(shared.mode.BUSY)`.

Transaction `switch` selectors and branch values may consume local and
package-qualified enum members, scalar rule assignment RHS values and scalar
operands inside rule assignment RHS expressions and scalar operands inside
rule guard expressions may consume local and package-qualified enum members,
and scalar drive body RHS values or scalar operands inside drive body RHS
expressions may consume local and package-qualified enum members.

Named drive-call scalar actual values may also consume local and
package-qualified enum members, and drive-call actual expressions may use
enum members as scalar operands.

Inline drive assignment RHS scalar values and scalar operands inside inline
drive RHS expressions may now also consume local and package-qualified enum
members.

Reusable-library use-site parameter override values and aggregate/list leaves
may consume importing-actor constants, importing-actor scalar parameter
defaults, local or package-qualified enum members, and qualified imported
package scalar constants too, resolving to literal generated-top bindings and
`library_uses[]` report values.

Transaction `set` RHS clauses may read scalar aggregate leaves from declared
aggregate storage carriers, such as `frame.mode` or `lanes[0]`, either
directly or as scalar operands inside transaction `set` RHS expressions.

Direct transaction `set` targets may write scalar aggregate leaves on those
same carriers, such as `(set frame.flag flag_in)` or `(set lanes[0] bit_in)`.

Rule assignment scalar RHS values may read scalar aggregate leaves directly
or as scalar operands inside RHS expressions, such as `(set mode_out (+
frame.mode mode_in))` inside a rule body.

Rule guard expressions may read scalar aggregate leaves as operands, such as
`(rule fire (& ready frame.flag) (set seen 1))`, and standalone rule guards
may read scalar aggregate leaves directly, such as `(rule fire frame.flag
(set seen 1))`.

Transaction `when`/`while`/`until` conditions may read scalar aggregate
leaves directly or as operands inside condition expressions, such as `(when
frame.flag (set seen 1))` or `(when (& ready frame.flag) (set seen 1))`.

Direct aggregate condition leaves lower through computed `.fsm` selector
syntax.

Transaction `switch` selectors and branch values may read scalar aggregate
leaves, such as `(switch frame.mode (1 (set seen 1)) (default (set seen 0)))`
or `(switch mode_in (frame.mode (set seen 1)) (default (set seen 0)))`;
selector leaves lower through computed `.fsm` selector syntax.

Named drive body scalar RHS values and scalar operands inside RHS expressions
may read scalar aggregate leaves, such as `(drive publish (mode_out
frame.mode))` or `(drive publish (mode_out (+ frame.mode mode_in)))`.

Named drive body targets may write scalar aggregate leaves, such as `(drive
capture (frame.mode mode_in))` or `(drive capture (lanes[1] pair_in))`.

Named drive-call scalar actual values and scalar operands inside actual
expressions may read scalar aggregate leaves, such as `(drive publish
frame.mode)` or `(drive publish (+ frame.mode mode_in))`.

Inline drive assignment scalar RHS values and scalar operands inside RHS
expressions may read scalar aggregate leaves, such as `(drive inline_publish
(mode_out frame.mode))` or `(drive inline_publish (mode_out (+ frame.mode
mode_in)))`.

Inline drive targets may write scalar aggregate leaves, such as `(drive
inline_capture (frame.mode mode_in))` or `(drive inline_capture (lanes[1]
pair_in))`.

Aggregate member paths outside transaction `set` RHS values, direct
transaction `set` targets, transaction condition scalar values/expression
operands, transaction `switch` selectors/branch values, rule assignment
target tokens, rule assignment RHS values/expression operands, rule guard
scalar values/expression operands, drive target tokens, drive body RHS scalar
values/expression operands, inline drive target tokens, inline drive
assignment RHS scalar values/expression operands, or drive-call actual scalar
values/expression operands, subaggregate operands/updates, aggregate
interface or transaction ports, aggregate storage banks, enum member
references in contexts not explicitly listed above as shipped, aggregate
field/slice/update lowering, and broader aggregate shape inference require
future task-tree ownership before they can ship.

The lowering artifact remains the contract. ISF enum/aggregate source should
lower to reviewable `.fsm` text that uses the established type and aggregate
semantics, not to hidden backend-only structure. Diagnostics must reject
unknown types, incompatible enum values, aggregate shape mismatches, and
ambiguous partial updates before HDL generation.

### ISF Scalar Setter Syntax Unification

Status: shipped for scalar rule and transaction assignments.

Goal: use one explicit scalar setter vocabulary across rules and transactions.

Current boundary: `(set lhs expr)` is the canonical explicit scalar setter in
rules and transactions. It schedules an assignment in the current ISF region:
in a rule it lowers under the rule non-state DT DTE, while in a transaction it
lowers as an ordered flopped transaction state. The runtime regions stay
different, but the setter verb is shared. Existing rule `(lhs expr)` remains
supported shorthand, and existing transaction `(update lhs expr)` remains
supported as the older transaction-local spelling while the ISF API continues
to evolve.

Still backlog: aggregate/field setters, bank-entry setters beyond the shipped
`store`/`load` bank access forms, actor-input write policy beyond the current
fail-closed boundary, and any non-flopped assignment family need separate
syntax, lowering, and conflict semantics.

### Enforced Resource Arbitration

Status: partially shipped; broader resource kinds and arbiters remain backlog.

Goal: lower `(resources ...)` metadata into scheduler-enforced mutual
exclusion and arbiter behavior.

Current boundary: resource metadata is structurally validated, including
supported arbiter names, resource kinds, duplicate resource rejection, and
resource-user validation for the enforced rule-user resource kinds. The
scheduler now enforces `rule_slot`, `output_bundle`, `transaction_start`, and
`storage_port` under the static `priority` arbiter for declared rule users.
Each priority-bound rule requests when its guard is true, the priority graph
chooses a unique active winner, and the generated grant gates the whole rule
DT DTE without adding a cycle. The scheduler also enforces bounded `round_robin`
arbitration for `rule_slot`, `output_bundle`, `transaction_start`, and
`storage_port` resources with declared rule users by emitting a generated
pointer counter,
granting the first requesting rule at or after that pointer, and advancing the
pointer from the winning rule DT.
Unmembered `output_bundle` resources keep the implicit bound-rule surface: the
bound rule users and the outputs or other LHS targets they drive describe the
bundle intent. `output_bundle` resources may now carry explicit
`(members name...)` metadata for declared actor output ports or concrete
actor-owned storage signals; member lists validate against bound rule writes
in those declared domains and report through `resource_arbitration[].members`.
`transaction_start` resources use the resource name as the target local
transaction. Each bound rule user must trigger that transaction through the
shipped non-generated rule-trigger surface. Priority suppression gates
lower-priority rule DTs before their trigger source pulses feed the generated
`{transaction}_trigger_fanin` DT. Bounded round-robin grants use the generated
pointer to select the winning requester before that same trigger source fan-in
path.
`storage_port` resources require explicit `(members name...)` metadata when
users are bound. Members must name concrete actor-owned storage signals:
scalar storage variables or scalarized bank element signals. Member lists
validate against bound rule writes in that storage domain and report through
`resource_arbitration[].members`. Under bounded `round_robin`, the same
mandatory member validation and report evidence apply while the generated
pointer selects the winning bound rule for the cycle. Bank roots, aggregate
storage paths, inferred undeclared targets, transaction ports, actor input
ports, route mux/storage, storage locks, memory-port protocols, and
hold/release ownership remain outside this shipped subset.

The resource-kind catalog is owned in code by
`FSM::Support::ISFResourceCatalog` and exposed through the machine-readable
ISF public contract, so downstream consumers can distinguish shipped resource
behavior from parser-recognized backlog names without scraping prose.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle mutual exclusion for rule users under the `priority` or bounded `round_robin` arbiter. |
| `output_bundle` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle ownership of a group of actor outputs or rule-written LHS targets under the `priority` or bounded `round_robin` arbiter, with optional explicit declared-output/storage-signal member lists. |
| `transaction_start` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle arbitration for rule-trigger request fan-in into one local transaction. |
| `storage_port` | shipped for `priority` and bounded `round_robin` arbitration | One-cycle arbitration for rule users that update explicit actor-owned storage signals. |
| `interface_bundle` | backlog | Ownership of a protocol-facing interface or bus bundle. |
| `named_drive` | backlog | Ownership of a reusable actor `(drive ...)` body or drive-call path. |
| `child_instance` | backlog | Re-entry control for a spawned child instance. |

Remaining backlog: `round_robin` for backlog resource kinds,
`interface_bundle`, `named_drive`, `child_instance`, generated-child
transaction starts, generated-child storage arbitration, actor-network trigger
resources, actor-network endpoint users, transaction/storage lifetime
ownership, named-drive users, output-target users, bank-root/aggregate/inferred
output-bundle or storage-port member domains, multi-capacity resources,
dynamic resource names, route mux/storage, storage locks, and broader
memory-port protocols remain backlog until their reset, hold/release,
fairness, and diagnostic contracts are explicit.

### Priority Resolution

Status: partially shipped; broader cases remain backlog.

Goal: enforce actor-level and rule-local priorities when multiple rules or
transactions conflict.

Current boundary: priority declarations are structurally validated and targets
must resolve to declared rules or transactions. Same-target rule/rule data
conflicts can now be resolved by rule-local or actor-level rule priority, with
the lower-priority assignment guarded off by the higher-priority rule
condition. Actor-level rule-over-transaction priority can now resolve the
covered same-target data case by guarding the transaction-state assignment
with the inverse active rule condition. Actor-level transaction-over-rule
priority can now resolve the covered same-target data case by guarding the
lower-priority rule assignment with the inverse scheduled `.fsm`
`(state_active STATE)` predicate for the winning transaction state, without
creating fake state-related input ports. Priority cycles, incomparable rule
conflicts, unordered rule/transaction conflicts, and mixed timing conflicts
fail closed.

A named drive with exactly one distinct local transaction caller and no
generated source now participates in that same bidirectional target-local
rule/transaction priority under its caller's logical transaction identity.
Unique unordered different-value overlap fails closed. Prioritized
shared/generated/mixed drive ownership fails closed through
`isf_ambiguous_rule_transaction_drive_priority`; unprioritized ambiguous or
unused-drive overlap remains the explicit `not_doable` warning. This is
assignment-level conflict resolution, not the broader `named_drive` resource
kind and lifetime/fairness policy listed above.

Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction/transaction priority, broader shared-drive
arbitration/lifetime policy, and broader resource arbitration remain backlog
items.

### Expression-Valued Rule Assignments

Status: shipped for ordinary flopped rule assignments and bounded rule-owned
pulse actions.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(set port expr)`, `(port expr)`,
`(pulse target)`, `(trigger transaction)`, and `(priority over other_rule)`.

Pulse, trigger, and priority targets remain scalar-only today.

`(set port expr)` is the canonical explicit setter; `(port expr)` remains
shorthand.

Both lower as flopped `<-` rule assignments under the rule DT DTE, where
`expr` may be a scalar token or one list expression from the transaction
`set`/`update`/`.fsm` RHS expression domain.

`(pulse target)` lowers as a one-cycle delayed `<1` pulse under the same rule
DT DTE. The target must be a scalar actor output or scalar actor storage
variable. Rule pulses participate in pulse-domain compatible fan-in and remain
distinct from sticky flopped rule assignments.

Direct scalar rule assignment RHS values and scalar operands inside RHS
expressions may use local or package-qualified enum members.

Direct scalar rule assignment RHS values and scalar operands inside RHS
expressions may also read scalar aggregate storage leaves such as
`frame.mode` or `lanes[1]`.

Rule assignment targets may write scalar aggregate storage leaves such as
`frame.mode` or `lanes[1]`.

Rule guard expressions may use enum members as scalar operands and may read
scalar aggregate storage leaves such as `frame.flag`.

Standalone scalar enum and scalar aggregate rule guards are shipped in both
shorthand and long-form `(when ...)` rule syntax, such as `(rule fire
mode.BUSY (set seen 1))` and `(rule fire (when frame.flag) (set seen 1))`;
they lower to guarded non-state DT headers.

The remaining backlog is aggregate paths in rule assignment RHS or
rule guard expression operator position, expression operator-position enum
members, enum rule targets, and subaggregate rule targets.

Transaction `switch` selectors and branch values may read scalar aggregate
storage leaves such as `frame.mode`, and selectors or branch values may use
enum members; subaggregate selectors/branch values remain backlog.

Named drive body scalar RHS values and scalar operands inside RHS expressions
may read scalar aggregate storage leaves such as `frame.mode`, and named
drive body targets may write scalar aggregate storage leaves such as
`frame.mode`; aggregate paths in drive body RHS expression operator position
and subaggregate drive targets remain backlog.

Named drive-call scalar
actual values may
read scalar aggregate storage leaves, and drive-call actual expressions may
read them as scalar operands; aggregate paths in drive-call actual expression
operator position remain backlog. Inline drive assignment scalar RHS values
and scalar operands inside RHS expressions may read scalar aggregate storage
leaves; aggregate paths in inline drive RHS expression operator position and
subaggregate inline drive targets remain backlog.

`(trigger transaction)` lowers through a generated one-cycle source and
transaction start fan-in. `(priority over other_rule)` feeds the covered
priority/resource arbitration paths. Same-expression rule writes report as
compatible fan-in, incompatible expressions fail closed through the same
rule-write conflict diagnostic, and priority-resolved expression conflicts
project through `priority_resolutions`. Alternate rule assignment operators are
separate future features.

### Transaction Stage Lowering

Status: partially shipped.

Goal: lower transaction `(stage ...)` clauses into valid/ready pipeline-stage
logic.

Shipped subset: a top-level transaction stage of the preferred form
`(stage name (ready ready_signal) (valid valid_signal))`. The older
`(input ready_signal)`/`(output valid_signal)` spelling remains accepted as an
alias. It lowers to one state that drives `valid_signal = 1` while active and
advances only when `ready_signal` is true. The valid endpoint is still a normal
transaction drive and participates in existing same-target conflict checks.

Actor-level phase/stage metadata is now parser-carried and schedule-report
visible through `actor_phases[]` and `actor_stages[]`, preserving each
authored metadata name and list-form body. It still has no runtime scheduler
semantics and does not reach scheduled `.fsm`, generated composition tops, or
HDL.

Remaining backlog: nested stages, stage-local latency, compute/action bodies,
multiple ready/valid endpoints, registered-valid variants, skid-buffer
behavior, executable actor-level phase/stage semantics, and richer stage
report families for future stage kinds.

### Transaction Unconditional Wait

Status: shipped base surface, actor-constant symbolic counts,
actor-parameter symbolic counts, bounded runtime scalar counts, bounded
runtime expression counts, and pending-sample preservation for
sample-compatible runtime wait successors. Remaining unknown-width count
shapes stay fail-closed.

Goal: support an unconditional cycle delay such as `(wait N)` inside a
transaction body.

Shipped contract: `(wait N)` advances only after exactly `N` active
transaction clock cycles, without checking an external condition. It is
different from `(await cond)`, which waits for a signal condition, and
different from `(repeat N body...)`, which repeats a body. The static surface
accepts non-negative integer literals, actor-level constants declared with
`(constants (NAME value) ...)`, and actor-local scalar parameter defaults
declared with `(params (NAME value) ...)`, plus same-transaction scalar
parameter defaults, when they resolve to non-negative integer literals.
`wait 0`, constants that resolve to zero, scalar actor parameters that resolve
to zero, and same-transaction scalar parameters that resolve to zero are
transparent no-ops that emit no wait state, consume no active transaction
cycle, and create no report entry.

`wait 1` occupies one generated wait state for one active cycle and advances
on the next state transition; `wait N` contributes exactly `N` active cycles
wherever it executes, including inside `when`, `switch`, `repeat`, `while`,
and `until` bodies. The bounded runtime
surface accepts `(wait count_signal)` when `count_signal` has known unsigned
width and `(wait (<op> ...))` when all referenced operands have known widths
and the expression-width helper derives a positive result width.

The static lowering is a reviewable fixed scheduled-state chain. No hidden
wait counter is introduced for the static literal/constant/parameter/package
constant surface.
Qualified package scalar constants are now part of the shipped static
wait-count surface when they resolve to non-negative integer literals; the
authored `PACKAGE.CONSTANT` token is preserved in `transaction_waits[]`.
Same-transaction scalar parameter defaults are also part of the shipped static
wait-count surface in their owning transaction, shadow actor-level static
names, and remain local lowering inputs. Non-scalar or cross-transaction
parameters, unqualified package constants, aggregate constants, package
member/item paths, and package constants inside wait-count expressions remain
fail-closed.

Pending samples before a positive static wait piggyback onto the first wait
state; pending samples before a zero wait remain pending for the next
state-producing clause. The runtime scalar lowering splits the predecessor
edge: zero bypasses the generated wait state, and positive counts load a
generated counter before entering the wait state. The wait state decrements the
sampled counter and loops until the sampled value reaches `1`.

Consecutive top-level runtime waits are shipped: a zero bypass from one wait
immediately evaluates the next wait, and the final sampled-counter edge of an
active wait splits into the following wait's positive sampled-counter and zero
bypass paths. Pending samples before the first top-level runtime wait in the
chain are also shipped when the final zero-count successor can carry the
sample; zero-then-positive paths use generated downstream wait-entry clones,
and all-zero paths use final compatible target clones.

Additional top-level predecessor kinds are shipped for `await`, `stage`,
`repeat` exit checks, `await_all`, `await_any`, and bank `load`/`store`
states; their own advance conditions are ANDed or ORed into the runtime count
split, and their unrelated alternatives such as await timeouts or repeat
loop-back edges are preserved.

Loop decision predecessors are shipped for the no-pending-sample subset: loop
body entries, loop back-edges, and loop exits that target a runtime wait split
that edge while preserving the opposite loop branch.
Loop-control false-edge predecessors are also shipped for the
no-pending-sample subset: `(exit-when COND)` and `(continue-when COND)` keep
their true exit/continue target while their false fallthrough edge splits a
following runtime wait.

Successful reports expose bounded `transaction_waits[]` entries with
transaction name, `cycles`, `count_kind`, `count_source`, entry state, exit
state, optional counter signal, and optional counter width. Static waits keep
an integer `cycles` and preserve the authored literal, actor constant name, or
actor parameter name, or qualified package constant token in `count_source`;
runtime scalar and runtime expression waits keep `cycles` null and expose their source/counter metadata with
`count_kind` `runtime_scalar` or `runtime_expression`. Schedule reports also
expose actor constants through `actor_constants[]` and actor parameter
defaults separately through `actor_params[]`.

Malformed waits such as missing counts, extra operands, negative counts,
non-integer counts, unknown symbolic names, non-scalar or non-integer actor
parameter defaults, transaction parameter names, unknown-width dynamic names,
malformed or unknown-width dynamic expressions, or unsupported dynamic
contexts fail closed today.

Remaining backlog: runtime waits after any remaining predecessor kinds whose
edge split is not implemented yet, top-level pending-sample zero bypasses
whose successor cannot yet carry samples without changing timing, branch
pending-sample zero bypasses whose successor cannot yet carry samples without
changing timing outside the shipped completion and independent-setter
successor subsets plus independent shift, assemble, and extract successor
subsets plus independent bank-load, bank-store, top-level stage, and
top-level await-all/await-any sync, top-level spawn, top-level transaction
phase, and top-level contract-arm successor subsets, repeat/loop
pending-sample zero bypasses whose successor cannot yet carry samples without
changing timing, and setter successors that read or overwrite a pending
sample alias.

Shift, assemble, extract, bank-load, and bank-store successors are shipped
only when independent; stage successors are shipped only when the ready input
and valid output are independent of the pending sample alias;
await-all/await-any sync successors are shipped only when their collected
done ports are independent of the pending sample alias; contract arm
successors are shipped only when independent of the pending sample alias;
spawn successors are shipped only when the generated start handoff is
independent of the pending sample alias; transaction phase successors are
shipped only for pass-through marker states with no assignments or guards;
loop decision/check successors are shipped only when their counter assignment
and loop condition are independent of the pending sample alias; forms that
read or overwrite a pending sample alias remain backlog.

The inline-body surface is now split into context-specific implementation
leaves. `when` and `repeat` bodies are shipped for the no-pending-sample
subset, `switch` branches are shipped for the no-pending-sample subset, and
`while`/`until` bodies are shipped for the no-pending-sample subset. Pending
samples before `when`-body and `switch`-branch dynamic waits are shipped when
the selected zero-count successor can carry samples without changing timing;
selected completion and independent scalar setter successors are now included
in that sample-compatible branch subset, along with independent shift
assemble, extract, bank-load, and bank-store successors. A scalar setter,
shift, assemble state, extract state, bank-load state, or bank-store state is
independent only when it neither reads nor overwrites a pending sample alias.

Pending samples before `repeat`, `while`, and `until` dynamic waits are also
shipped when the zero-count successor is an independent loop decision/check
state that preserves the repeat counter decrement or while/until branch
decision, or when the selected zero-count body successor can carry samples
without changing timing.

Expansion order is tracked under `ISF-DYNAMIC-WAIT.3.3`: consecutive
top-level dynamic waits and the requested additional top-level predecessor
kinds are shipped. The inline-body work is split; `when` bodies, `repeat`
bodies, `switch` branches, and `while`/`until` bodies are shipped for the
no-pending-sample subset. Pending-sample preservation is now split under
`ISF-DYNAMIC-WAIT.3.3.5`; top-level runtime waits are shipped under
`ISF-DYNAMIC-WAIT.3.3.5.2`, branch runtime waits are shipped under
`ISF-DYNAMIC-WAIT.3.3.5.3`, and repeat/loop runtime waits are shipped under
`ISF-DYNAMIC-WAIT.3.3.5.4`. Expression-valued runtime counts shipped under
`ISF-DYNAMIC-WAIT.3.3.6` with the same predecessor-edge snapshot contract as
scalar runtime counts.

Consecutive top-level runtime waits now include pending-sample zero-link
carrying for the shipped sample-compatible final target subset.

Pending samples cannot be enabled by simply putting the sample assignment on a
shared successor state. The positive-count path must behave like a positive
static wait, where samples materialize in the first active wait state. The
zero-count path must behave like `wait 0`, where no hidden wait/sample cycle is
introduced and the samples materialize with the next state-producing clause.

Top-level runtime waits now use a first wait state that samples once, a
separate wait-loop state for counts greater than one, and a zero-bypass clone
of the following state-producing clause when that successor can carry samples
without changing timing, including completion states that preserve their
delayed pulse and return-to-idle behavior plus independent scalar setters that
neither read nor overwrite pending sample aliases plus independent shifts and
independent assemble and extract states plus independent bank-load states.

Independent bank stores now share that same independent-successor rule, and
top-level ready/valid stages can carry samples when their ready input and
valid output are independent of the pending sample alias. Top-level bounded
eventual contract arm states can carry samples while preserving the monitor
arm pulse. Top-level await-all/await-any sync states can carry samples when
their collected done ports are independent of the pending sample alias.

Top-level spawn states can carry samples when the generated start handoff is
independent of the pending sample alias.

Top-level transaction phase states can carry samples by preserving the
original pass-through transition; actor-level phase metadata remains
report-only and unrelated to runtime zero-count sample materialization.

Consecutive top-level runtime waits carry pending samples through zero-count
wait links with generated downstream wait-entry clones for zero-then-positive
paths and final compatible target clones for all-zero paths. `when` and
`switch` use the same materialization while preserving false, other-case, and
fallthrough exits, and their selected completion, independent setter,
independent shift, independent assemble, independent extract, independent
bank-load, and independent bank-store successors are sample-compatible.

`repeat`, `while`, and `until` use the same materialization while preserving
loop-back and loop-exit edges. Other successor shapes that cannot yet carry
samples remain fail-closed.

### Transaction Dynamic Loops

Status: shipped base surface; nested/child loop combinations remain backlog.

Goal: support transaction-local loops such as `(while cond body...)` and
`(until cond body...)`.

Shipped contract: `(while cond body...)` is a pre-test loop. The scheduler
emits an entry decision state and a back-edge decision state that each sample
`cond` once; true enters or repeats the body, and false exits to the next
transaction clause. Zero iterations are therefore possible. `(until cond
body...)` is a body-first loop. It executes the body once, then samples `cond`
in a generated decision state; true exits, and false loops back to the body.

That spelling means one-or-more iterations. A pre-test "run while not done"
loop should be authored as `(while (! done) body...)` rather than overloading
`until`.

Loop bodies must be non-empty and currently reuse the shipped inline-body
surface: named drive calls, `await`, `sample`, `complete`, `repeat`,
`update`, `set`, shift/assemble/extract data operations, actor-owned bank
`store`/`load`, nested `when`, and shipped `(wait N)` clauses. The first
implementation continues rejecting `do`, `spawn`, `await_all`, `await_any`,
`stage`, `contract`, and nested `while`/`until` until re-entry, child
lifetime, and reporting semantics are specified. The condition uses the same
scalar or list-expression condition surface as `when`.

These loops are persistent hardware schedule regions, not software processes.

They may be data-dependent or unbounded at runtime and do not create an
implicit timeout. Existing watchdog, latency, and temporal-contract mechanisms
remain explicit and count loop-body cycles according to their own active-cycle
semantics. Successful reports expose bounded `transaction_loops[]` entries
with transaction name, kind, normalized condition text, generated
decision/body/exit states, and body clause count.

### Transaction Ports And Actor Pin Access

Status: shipped base surface; richer output/report surfaces remain backlog.

Transaction `(ports ...)` declarations, actor-parameter-backed,
actor-constant-backed, qualified package-constant-backed, and generated-child
or direct/non-generated same-transaction-parameter-backed transaction port
widths, scalar and expression-valued input activation bindings, first
actor-pin conflict/runtime coverage, and bounded schedule-report binding
provenance are shipped. The original
`ISF-PORT-BINDING` task tree is complete; expression-valued input bindings are
tracked by `ISF-ACTIVATION-BIND-EXPRESSIONS`.

Goal: make it easy to connect actor variables, actor-owned storage, and actor
top-level pins to transaction ports so rules and transactions can exchange
data/control intent without manually authoring low-level `.fsm` handoff
signals.

This should be an ISF-level source feature with explicit `.fsm` lowering, not
an author-facing escape hatch to raw handoff wiring. Transaction ports need
direction and width. Activation sites need explicit bindings. Actor input pins
are readable observations and should not be writable from ISF. Actor output
pins are writable targets, but they must use the same assignment, fan-in,
priority/resource, and runtime-conflict rules as any other driven LHS.

Authoring boundary: users should describe the transaction boundary and the
use-site binding, not generated payload wires, bridge ports, start payload
signals, or generated-top handoff nets. For example, a data-bearing
transaction declares local ports, and the caller binds those ports to actor
variables, actor-owned storage, or actor interface pins:

```lisp
(transaction apb_read
  (ports
    (input  addr (width 32))
    (output data (width 32))
    (output done))
  ...)

(do apb_read
  (bind
    (input  addr req_addr)
    (output data read_data)
    (output done read_done)))

(rule launch_read ready
  (trigger apb_read
    (bind
      (input addr (+ base_addr offset)))))
```

The compiler owns the lower-level materialization: generated `.fsm` handoff
signals, guards, mux selectors, assignments, generated-top bridge nets, and
the schedule-report provenance that lets reviewers inspect the result. That
keeps the author-facing model ergonomic while preserving the `.fsm` review
artifact as the authoritative low-level representation.

Shipped declaration shape:

```lisp
(transaction read_word
  (ports
    (input addr (width 32))
    (output data (width 32)))
  ...)
```

The parser accepts at most one `(ports ...)` clause per transaction. Each port
has direction `input` or `output`, a scalar HDL identifier name, and optional
positive integer `(width N)`, actor-parameter-backed `(width PARAM)`, or
actor-constant-backed `(width CONST)`, or package-constant-backed
`(width PACKAGE.CONSTANT)` where the symbolic source names an actor-local
scalar parameter default, declared actor constant, or qualified imported
package scalar constant that resolves to a positive integer; omitted width
means 1. Generated child and direct/non-generated transactions may also use
transaction-parameter-backed `(width TX_PARAM)` when `TX_PARAM` names a
same-transaction scalar parameter default that resolves to a positive integer.
Unknown or unqualified package constants, aggregate package constants,
package member/item paths, ambiguous local-enum/package-constant spellings,
zero-valued constants, runtime signals, and arbitrary expressions fail
closed. The normalized public transaction shell has `ports.inputs[]` and
`ports.outputs[]` entries with `name` and resolved integer `width`. The
declaration is not a scheduler body clause; behavior comes from transaction
states/rules that use the port and activation sites that bind it.

Shipped binding shape:

```lisp
(do read_word
  (bind
    (input addr req_addr)
    (output data read_data)))

(spawn read_word as r0
  (bind
    (input addr req_addr)
    (output data read_data)))

(trigger read_word
  (bind
    (input addr req_addr)))
```

Input bindings accept scalar signals, numeric/exact-width literals, and
non-empty list expressions.

Scalar and known-width expression sources are width-checked against the
transaction input port; unknown expression widths continue through the
downstream `.fsm` expression validation path.

Local `do` lowers input bindings in the state that starts the child and
copies output bindings under the generated child-done guard.

Parameterized/generated `do` lowers through explicit generated-top handoff
ports and a parent-owned `do_port_binding` DT whose output copy is
done-gated.

`spawn` lowers through hidden generated-top handoff ports and reviewable
parent binding DTs; actor signals consumed by explicit spawn input-binding
expressions are not also same-name wired into the child instance.

Rule `trigger` supports input bindings; each local target rule owns a distinct
payload source and the trigger fan-in DT routes payloads under the matching
per-rule trigger pulse. Generated-child rule triggers also support scalar
output bindings: the generated trigger handoff DT copies the child output
handoff into the actor target under that trigger instance's done-observer
signal.

Direct/local rule-trigger output bindings, behavior-changing
snapshot-vs-live timing conversion, additional future binding-report
expansions beyond the shipped bounded `transaction_port_bindings[]` summary
fields, and broader static conflict diagnostics remain backlog. The shipped
summary fields already include `actor_signal`, `actor_expression`,
`actor_endpoint_kind`, `binding_timing`, and `authored_timing_mode`.
The direct/local rule-trigger output-binding diagnostic is intentionally
specific: output bindings require a generated-child rule trigger completion
identity, and direct/local targets do not provide one yet.
Within one activation bind block, multiple output bindings to the same actor
target fail closed with a binding-level diagnostic; no intra-bind output
selection policy is shipped.
Within one rule, multiple generated-child rule-trigger output bindings to the
same actor target also fail closed; no rule-local output selection policy is
shipped.

Schedule reports also publish `authored_timing_mode` on
`transaction_port_bindings[]`. It reports `snapshot` or `live` when the source
binding explicitly includes `(timing snapshot)` or `(timing live)`, and JSON
`null` when no explicit timing clause was authored, including output bindings.
This is source provenance only; it does not imply behavior-changing timing
conversion.

The shipped first snapshot-vs-live timing syntax is an optional fourth
subclause on input bindings: `(input PORT EXPR (timing snapshot))` or
`(input PORT EXPR (timing live))`. This is current-timing-only: `snapshot`
spells activation/trigger payload capture, `live` spells generated-top live
handoff wiring, and mismatched mode/site combinations fail closed until a
separate storage/wiring conversion design exists.

Actor pin binding now uses the same assignment/conflict path as ordinary ISF
drives where it has shipped coverage. Spawn output bindings carry parent
transaction ownership in provenance, so a spawned child output bound to an
actor output conflicts with a same-target rule writer through the existing
rule/transaction diagnostics. Generated-child rule-trigger output bindings
carry rule ownership in provenance and conflict with same-target rule writers
through the rule conflict diagnostics. Accepted spawn-output fan-in and
rule-trigger input payload fan-in remain visible as normal `.fsm` same-LHS
assignments and reach the SystemVerilog backend's verification-only selector
checks.

Successful schedule reports now expose bounded `transaction_port_bindings`
entries for the shipped binding surface. Each entry records the binding site
kind, owner, target transaction, direction role, port, scalar actor signal
when applicable, formatted actor expression, `actor_endpoint_kind`,
`binding_timing`, `authored_timing_mode`, width, and generated handoff names
where they exist.
Generated-child rule-trigger output entries report the done-observer signal in
`done_signal`. The endpoint kind is `signal` for scalar actor-side endpoints,
`literal` for numeric or exact-width input operands, and `expression` for
non-empty list-expression input operands. The binding timing is
`activation_region`, `generated_live_handoff`, `trigger_payload`, or
`done_guarded`. The authored timing mode is `snapshot`, `live`, or JSON null
for no explicit timing clause.
This is a public summary for downstream tooling, not the raw binding or
assignment-provenance internals.

### Bounded-Eventually Monitor Lowering

Status: shipped (the bounded-eventually subset); broader temporal forms remain backlog.

Goal: express bounded-liveness intent ("this signal must hold within N cycles of
a point") as a synthesizable monitor plus a verification assertion.

Shipped subset: the bounded-eventually monitor `(assert (monitor (within signal
N)) ["name"])` placed in a transaction body — from the cycle control reaches the
clause, `signal` must hold within `N` cycles. `N` may be a positive integer
literal, a declared actor constant, an actor-local scalar parameter default, a
qualified imported package scalar constant, or a same-transaction scalar
parameter default on a generated child or direct/non-generated transaction that
resolves to a positive integer. Direct transaction parameters are local lowering
inputs for this window value domain and are not emitted as actor-level `.fsm`
`+params`. (This replaces the former top-level `(contract name (eventually
signal within cycles))` clause, removed in favor of the unified verification
surface.)

Activation-site overrides on `spawn`, generated blocking `do`, or rule
`trigger` that target a generated child parameter used by a static timing value
are accepted only when they resolve to the same value as the child transaction
parameter default. Mismatched overrides fail closed with a targeted diagnostic.
Full override-specialized window/timing lowering remains backlog.
Generated child activation overrides that target transaction parameters used
by static timing lowering for repeat counts, wait counts, latency bounds, or
top-level await-local watchdog limits now use the same default-preserving
gate: same-value overrides are accepted, while mismatches fail closed until
per-activation static timing specialization is shipped. Each sub-axis now
emits its own targeted diagnostic (`repeat-count parameter`, `wait-count
parameter`, `latency-bound parameter`, or `watchdog-limit parameter`) and
its own deferral phrase so the author can identify which deferred lane is
blocking the override. The same
default-preserving gate now also covers transaction parameters used by
data-operation widths (`shift_left`, `shift_right`, `assemble`, `extract`)
on generated children: mismatched activation-site overrides fail closed with
a targeted `static-width parameter` diagnostic until per-activation
data-op width specialization is shipped. The same default-preserving gate
now also covers transaction parameters used by transaction port widths
(`(ports (input/output NAME (width PARAM)))`): mismatched activation-site
overrides fail closed with a targeted `static port-width parameter`
diagnostic until per-activation transaction port width specialization is
shipped.

Reaching the clause emits one arm state; the generated scheduled `.fsm`
monitor tracks pending/age/fail storage, clears on actor reset, and sets a
sticky fail bit if the signal is not seen within the window or if the same
monitor is armed again while pending.

SystemVerilog generation projects the sticky fail bit into a same-cycle clocked
concurrent assertion (`!fail`) under `` `ifndef SYNTHESIS`` — verilator-simulable;
Verilog output stays assertion-free. Remaining backlog: runtime-signal or
expression windows, package constants inside window expressions, global `always`
implication forms, min/max windows, dynamic bounds, same-cycle-only checks,
nested monitors, expression operands, and multiple outstanding obligations.

The file-backed `isf/stream_stage_contract.isf` fixture covers the ready/valid
stage plus bounded-eventually monitor path through scheduled `.fsm` structure,
plain and strict HDL generation, temporal-monitor storage roles, and the
SystemVerilog sticky-fail assertion projection.

### Legacy Handshake Semantics

Status: deprecated compatibility input with tightened validation.

Goal: keep old `(handshake ...)` source intentional without giving it new
runtime semantics.

Current boundary: deprecated handshake metadata is structurally validated and
ignored. The parser accepts a scalar handshake name plus scalar `valid`/`ready`
property entries and leaves the actor-shell handshake placeholder empty. Direct
`(on port ...)` activation plus generated `can_accept` is the current model.

Policy: keep well-formed legacy handshakes accepted and ignored for
compatibility, and do not lower them into scheduled `.fsm`, schedule JSON, or
HDL. Accepted legacy forms now require one `valid` and one `ready` property
with no duplicate handshake names. Use `(on ...)` for activation and
transaction `(stage name (ready ready_signal) (valid valid_signal))` for
ready/valid barriers. The older `(input ready_signal)`/`(output valid_signal)`
stage spelling remains accepted as an alias.

### Removed Assign Keyword

Status: removed compatibility item with shipped targeted diagnostic.

Goal: keep the removed `(assign ...)` transaction keyword out of the language
and guide authors to explicit timing constructs.

Current boundary: authored uses fail closed with a migration-specific
unsupported-clause diagnostic. The parser may carry the raw clause as private
scheduler input, but the scheduler rejects it in top-level transaction bodies
and nested contexts such as `when`, `switch`, or `repeat` bodies. The
diagnostic deliberately does not auto-map the old keyword. It tells authors to
use `(set var expr)` for explicit scalar flopped updates, `(update var expr)`
for the older transaction-local spelling, `(drive ...)` for protocol/output
drives, rule `(set port expr)` or `(port expr)` actions for rule-driven
assignments, and `(complete port)` for transaction completion. A future
transaction-local combinational assignment feature would need a new explicit
construct with its own timing semantics.

### Full Width Inference For Data Operations

Status: backlog.

Goal: infer widths for data operations in more cases without requiring
explicit width options, and keep accepted lowering free of width placeholders.

Current boundary: `shift_left` and `shift_right` accept
`(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)`, `assemble` accepts
`(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)` after the target, and
`extract` accepts `(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)` as
explicit assertions. `TX_PARAM` names a same-transaction scalar parameter
default on a generated child or direct/non-generated transaction and must
resolve to a positive integer, `PARAM` names an actor-local scalar parameter
default that resolves to a positive integer, `CONST` names a declared actor
constant that resolves to a positive integer, and `PACKAGE.CONSTANT` names a
qualified imported package scalar constant that resolves to a positive
integer.
`shift_left` uses the optional width only as register-width evidence; plain
widthless `shift_left` remains accepted because no insertion-position width
is needed.

`extract` also infers exactly one missing destination field width when the
source word width and all sibling field widths prove one positive remainder;
two or more unknown fields remain backlog. `extract` fails closed instead of
emitting placeholder slice bounds when field positions cannot be proven, the
inferred remainder is not positive, or field totals conflict with known source
width. `shift_right` now fails closed when width evidence is missing or
conflicts with an explicit option. `assemble` accepts ordered explicit part
widths, infers exactly one missing part width when the target width and all
sibling part widths prove one positive remainder, and rejects contradictory
explicit part widths, known target-width mismatches, and non-positive
single-part inferred remainders. Two or more unknown parts remain backlog for
inference and are accepted only as non-evidence concat operands unless
explicit widths make them known.

Unknown package constants, unqualified package constants, aggregate package
constants, package member/item paths, ambiguous local-enum/package-constant
spellings, unrelated or cross-transaction parameters, runtime signals,
arbitrary expressions, zero-valued constants, non-scalar values, use-site
overrides, activation-site override-specialized data widths, and generated-top
respecialization remain outside the shipped data-operation width-evidence
surface.

`ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS` is complete: same-transaction scalar
parameter defaults are now accepted for generated child and direct/non-
generated transaction data-operation width evidence in existing
`shift_left`/`shift_right` `(width TX_PARAM)` and `extract`/`assemble`
`(widths TX_PARAM...)` options.

Schedule reports now expose positive integer `width` metadata for inferred
scheduler counters and register storage with known ISF width evidence.

### Richer Schedule-Report Storage Classes

Status: partially shipped; additional classes remain backlog.

Goal: classify inferred storage more precisely in schedule reports.

Current boundary: schedule reports expose bounded storage metadata with
optional positive integer widths when width evidence is known.

`inferred_storage[].kind` remains the coarse storage category (`counter` or
`register`). The first optional `inferred_storage[].role` slice is shipped for
storage families with stable lowering evidence: `activation_done_handoff`,
`activation_start_handoff`, `atl_trigger_start_handoff`,
`scheduler_error_status`, `watchdog_counter`, `latency_counter`,
`repeat_counter`, `dynamic_wait_counter`, `drive_request`, `drive_payload`,
`sample_alias`, `extract_field`, `data_register`, `completion_pulse`,
`temporal_contract_monitor`, `rule_trigger_source`,
`rule_trigger_payload_source`, `transaction_port`,
`transaction_port_binding`, and `trigger_done_observe`.

Declared typed actor-owned storage may also expose optional `type` and
`type_kind` summaries; those fields are bounded metadata, not raw type-spec
hashes.

Remaining direction: keep `role`, `type`, and `type_kind` additive and omit
them when evidence is ambiguous. The shipped `rule_slot`/`round_robin`,
`output_bundle`/`round_robin`, `transaction_start`/`round_robin`, and
`storage_port`/`round_robin` implementations expose their generated pointers
as inferred counter storage with role
`resource_round_robin_pointer`; broader per-cycle resource-grant/debug storage
remains deferred. Add a storage role only if future resource lowering
materializes such signals with compatibility rules, public contract metadata,
and regression coverage.

### Fully Frozen Schedule JSON Schema

Status: shipped for schedule JSON `schema_version: 1`.

Goal: freeze the whole schedule JSON schema as a public contract.

Current boundary: schedule JSON `schema_version: 1` is public and stable
through the schema, key/value families, scalar policies, ordering policies,
nullability rules, and evolution policy advertised by
`embedding.isf_public_interface`. The conflict/fan-in projection boundary is
defined. Nonfatal conflict issues project into `compile_issues`, and accepted
fan-in groups project into `compatible_fanin_groups`, both with bounded
summary shapes. Successful priority/resource decisions project into
`priority_resolutions` and `resource_arbitration` as bounded static lowering
summaries. Shipped transaction stages and bounded eventual contracts project
into `transaction_stages` and `temporal_contracts` with bounded public
summary shapes.

Freeze policy: the current contractual surface is the metadata
advertised by `embedding.isf_public_interface`, including top-level keys,
nested key/value families, scalar policies, ordering policies, nullability
rules, storage kind/role/width metadata, and CLI/in-process report parity.

New optional keys or value-family members may be added only when the same slice
updates contract metadata, focused tests, and user-facing docs.

Generated-name policy is now explicit: generated names are deterministic for
the same source and FSMGen version and may be used for report-local or
artifact-local joins when public fields explicitly reference them, but
downstream consumers should use bounded metadata fields instead of parsing
generated-name spelling as a semantic contract.

Additive/deprecation policy is also explicit: new report keys, nested optional
keys, and value-family members are additive only when public contract metadata,
focused tests, and user-facing docs move in the same slice. Removing,
renaming, changing required/optional status, changing value type, or changing
advertised value meaning is breaking and requires a `schema_version` bump plus
migration or deprecation documentation.

Assignment-provenance and multi-file child-summary policy is explicit: raw
assignment provenance, private assignment indexes, activation proof internals,
and recursive child report dumps stay private. The public boundary is bounded
summary arrays such as `compile_issues[]`, `compatible_fanin_groups[]`,
`priority_resolutions[]`, `resource_arbitration[]`,
`transaction_port_bindings[]`, `bank_accesses[]`, counts such as
`dt_blocks[].assignments`, the lower-result `files` map, named generated
artifacts, `generated_composition`, `library_uses[]`, and `clock_domains[]` /
`crossings[]`.

The executable golden fixture matrix now exists in
`t/1255-isf-schedule-report-golden-matrix.t`. It assigns every advertised
`schedule_report_*` branch to at least one matrix case, runs each case through
both `FSM::Scheduler::ISF->report(...)` and `./bin/fsmgen
--emit-schedule-json`, and requires equal payloads. The public contract now
advertises `schedule_report_full_schema_stable = true` for schema version `1`.

### ISF Realistic Fixture Matrix

Status: current coverage boundary with future promotion candidates.

Goal: keep realistic protocol fixtures aligned with shipped ISF behavior,
strict-mode expectations, schedule JSON assertions, scheduled `.fsm` review
artifacts, and generated HDL reachability.

Current boundary: APB remains the quick/smoke ISF baseline for parse,
scheduled `.fsm` header, and public-contract checks.

Broader realistic fixture coverage belongs in the `isf` regression tier.

The active matrix in
[ISF-FIXTURE-COVERAGE](../../tasks/ISF-FIXTURE-COVERAGE.md) now covers
`isf/spi_master.isf` as a bounded SPI-like mode-0 serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict
HDL checks, and
[ISF-I2C-FIXTURE-PROMOTION](../../tasks/ISF-I2C-FIXTURE-PROMOTION.md) now
covers `isf/i2c_master.isf` as a bounded I2C-like serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict
HDL checks.

These are not complete SPI or I2C protocol compliance suites.

Future fixture promotions should add stable structural assertions rather than
full HDL or full schedule JSON snapshots.

The SPI-like and I2C-like fixtures intentionally stay out of the quick/smoke
tier for now; `quick` remains APB-centered for fast turnaround.

The burst-reader fixture is now also promoted in the `isf` tier for
file-backed strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, dynamic repeat counter storage, watchdog/latency
counter roles, sampled aliases, and completion/timeout pulse fan-in.

The UART-like fixture is now promoted in the `isf` tier for file-backed strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, sampled-byte LSB drive selection, known-width `shift_right`,
repeat counter storage, busy drive sequencing, and completion pulse behavior.

The phase fixture is now promoted in the `isf` tier for file-backed strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, transaction phase pass-through states, absence of reusable
`done` drive storage, and delayed completion pulse behavior.

The switch fixture is now promoted in the `isf` tier for file-backed strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, sampled selector capture, explicit branch dispatch, default
fallthrough to completion, named-drive branch starts, and delayed completion
pulse behavior.

The when fixture is now promoted in the `isf` tier for file-backed strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, entry drive setup, two conditional decision states, multi-step
true-body drives, false-path fallthrough, compatible named-drive start fan-in,
and delayed completion pulse behavior.

The generated-composition fixture is now promoted in the `isf` tier for
file-backed strict schedule JSON parity, strict `--outdir` file emission,
generated top, parent, and child scheduled `.fsm` artifacts, start/done
handoffs, named-drive request/payload handoffs, public input fanout,
`await_all` synchronization, and strict HDL generation for the generated top,
parent, and child artifacts.

The rule/resource fixture is now promoted in the `isf` tier for file-backed
strict schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, rule-over-transaction priority suppression, `rule_slot`/`priority`
resource metadata, lower-priority rule gating by a higher-priority rule, and
delayed completion pulse behavior. Focused resource tests also cover bounded
`rule_slot`/`round_robin`, `output_bundle`/`round_robin`,
`transaction_start`/`round_robin`, and `storage_port`/`round_robin` grants,
generated pointer storage metadata, report projection, and fail-closed
unsupported round-robin combinations.

The stage/contract fixture is now promoted in the `isf` tier for file-backed
strict schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, sampled payload forwarding, ready/valid stage metadata, bounded
eventual contract metadata, temporal monitor storage roles, SystemVerilog
sticky-fail assertion projection, and delayed completion pulse behavior.

The FIFO datapath fixture is now promoted in the `isf` tier for file-backed
strict schedule JSON parity, scheduled `.fsm` structure, bounded
`bank_accesses[]` metadata, plain and strict HDL generation, scalarized
depth-4 `data_0` through `data_3` storage, pointer-guarded accepted pushes,
and pointer-guarded accepted pops. It does not claim general memory-array HDL
emission, write-first collision behavior, bypassing, or arbitrary-depth
parameterized FIFOs.

The FIFO controller fixture is now promoted in the `isf` tier for file-backed
strict schedule JSON parity, scheduled `.fsm` structure, compatible
same-value fan-in metadata, plain and strict HDL generation, idle cycles,
push-only, pop-only, simultaneous push+pop occupancy updates,
actor-maintained full/empty flags, and 2-bit pointer wrap. It is
controller-only and does not claim data-bank storage or `data_out` datapath
transfer behavior.

The FIFO library fixture is now promoted in the `isf` tier for file-backed
strict schedule JSON parity, strict `--outdir` emission, generated importer,
specialized child, and top scheduled `.fsm` artifacts, fixed FIFO parameter
overrides, use-site bindings, scalarized FIFO data entries, generated-top
wiring, and plain plus strict generated-top HDL generation. It is the fixed
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, `OCC_WIDTH=3` reusable FIFO handoff
fixture, not a claim for use-site parameter-driven FIFO interface/storage
shape elaboration, nested imports, standalone transaction/drive exports,
arbitrary-depth generated FIFOs, memory-array backend emission, or automatic
non-zero reset values.

The ATL scalar data-route fixture is now promoted in the `isf` tier for
file-backed strict schedule JSON parity, scheduled `.fsm` structure, generated
parent source/sink handoff ports, `actor_network.data_movements[]` route
metadata, empty association/group schedule arrays, and plain plus strict HDL
generation. It is the bounded two-actor `isf/atl_data_route_pipeline.isf`
handoff fixture, not a claim for generated ATL children, generated ATL tops,
route mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL scalar pin-ingress fixture is now promoted in the `isf` tier for
file-backed strict schedule JSON parity, scheduled `.fsm` structure, an
existing top-level source input pin, generated actor handoff output,
`actor_network.data_movements[]` route metadata, empty association/group
schedule arrays, and plain plus strict HDL generation. It is the bounded
single-actor `isf/atl_pin_ingress_pipeline.isf` ingress fixture, not a claim
for generated ATL children, generated ATL tops, actor-to-pin egress,
bidirectional pin movement, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent actor
grouping.

The ATL scalar pin-egress fixture is now promoted in the `isf` tier for
file-backed strict schedule JSON parity, scheduled `.fsm` structure, generated
actor source handoff input, existing top-level output sink,
`actor_network.data_movements[]` route metadata, empty association/group
schedule arrays, and plain plus strict HDL generation. It is the bounded
single-actor `isf/atl_pin_egress_pipeline.isf` egress fixture, not a claim for
generated ATL children, generated ATL tops, bidirectional pin movement, route
mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL resolved-child fixture is now promoted in the `isf` tier for
file-backed strict schedule JSON parity, parent plus resolved child scheduled
`.fsm` structure, resolved actor-network instance metadata, one parent
transaction-trigger handoff, one parent event-wait handoff, and empty
data/association/group schedule arrays. It is the bounded
`isf/atl_resolved_child_pipeline.isf` emitted-child/generated-top fixture, not
a claim for multi-child data wiring, broader HDL child wiring, inferred
interface binding, route mux/storage, actor-event fan-in, CDC,
ready/backpressure, recursive actor networks, or permanent actor grouping.

The follow-on `isf/atl_resolved_child_pin_ingress_pipeline.isf` fixture is now
promoted for one generated-top scalar pin-ingress route into that resolved
child, using `(worker.payload pins.payload)`. The follow-on
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf` fixture is now
promoted for one generated-top exact-width vector pin-ingress route from top
`payload` to `worker.payload` at width 8. The follow-on
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` fixture is now
promoted for the bounded same-child two-route exact-width vector pin-ingress
case from top `payload` to `worker.payload` at width 8 and from top `sideband`
to `worker.sideband` at width 4. The follow-on
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` fixture is now
promoted for the bounded same-child mixed scalar/vector pin-ingress case from
top `payload` to `worker.payload` at width 8 and from top `valid` to
`worker.valid` at width 1. The follow-on
`isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` fixture is now promoted
for the bounded same-child two-route pin-ingress case from top `payload` to
`worker.payload` and from top `sideband` to `worker.sideband`. The follow-on
`isf/atl_resolved_child_pin_egress_pipeline.isf` fixture is now promoted for
one generated-top scalar pin-egress route from that resolved child to a
top-level output, using `(pins.result worker.payload)` after the child event
wait. The follow-on
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` fixture is now
promoted for one generated-top exact-width vector pin-egress route from
`worker.payload` to top `result` at width 8. The follow-on
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` fixture is now
promoted for the bounded same-child exact-width vector pin-egress route set
from `worker.payload` to top `result` at width 8 and from `worker.status` to
top `status` at width 4. The follow-on
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` fixture is now promoted
for the bounded same-child mixed scalar/vector pin-egress case from
`worker.payload` to top `result` at width 8 and from `worker.valid` to top
`valid` at width 1. The follow-on
`isf/atl_two_child_data_pipeline.isf` fixture is now promoted for one
generated-top scalar generated-child actor-to-actor route from `reader.payload`
to `writer.payload` after the reader event wait and before the writer trigger.
The follow-on
`isf/atl_two_child_vector_data_pipeline.isf` fixture is now promoted for the
same generated-top route at exact 8-bit source/sink endpoint width. The
follow-on
`isf/atl_two_child_multi_data_pipeline.isf` fixture is now promoted for the
bounded same-source/same-sink two-route case from `reader.payload` to
`writer.payload` and from `reader.sideband` to `writer.sideband`, while
fan-in/fan-out routing, mux/storage, width adaptation, payload protocols, and
broader generated-child data routes remain backlog.

Fixture authoring policy: realistic fixtures should use documented ISF
constructs. If a fixture needs an awkward workaround to express a normal
hardware intent, treat that as an ISF expressiveness gap and track the missing
construct instead of hiding the workaround inside the test.

ISF expressiveness policy: Lisp-like syntax makes argument-level composition
and variadic constructs natural, but arity is part of the public contract.

Constructs with fixed hardware roles should keep exact arity. Constructs whose
meaning is naturally list-like or associative may accept an arbitrary number of
arguments when that keeps the source clear and the lowering remains
deterministic. Each new variadic surface needs targeted malformed-arity
diagnostics, focused or fixture coverage, and book/spec updates in the same
slice.

### ISF Reusable Libraries

Status: shipped bounded actor-library surface; broader surfaces remain backlog.

Goal: let users import tested reusable ISF descriptions instead of rewriting
common actors and transaction patterns in every design. The user-facing term is
**library**. The implementation may reuse package/import infrastructure, but
ISF libraries are broader than scalar constants or type packages: they should
be able to contain reusable ISF actors, transactions, drives, and associated
constraints when those surfaces are specified.

Current boundary: the first reusable ISF library import, same-name and
remapped generated-top system binding, actor-owned fixed-storage,
expression-valued rule-guard, disjoint-rule write, FIFO-controller matrix,
bank-access, and fixed FIFO library fixture slices have shipped under
[ISF-LIBRARIES](../../tasks/ISF-LIBRARIES.md).

Actor roots may import library roots, use an exported actor, validate
use-site parameters and explicit bindings, emit a specialized child scheduled
`.fsm` artifact, wire the library actor through a generated top, reach
SystemVerilog generation for the covered generated-top path, project bounded
`library_uses` schedule-report metadata, declare fixed actor-owned
state/banks, author rule fire predicates as expressions, accept same-target
rule writes when direct contradictory guard facts prove disjointness, prove a
depth-4 FIFO-controller same-cycle update matrix, and author a reusable
fixed-shape FIFO actor source with bank-backed accepted push/pop data
movement that reaches generated-top SystemVerilog.

Clock/reset name remapping now works through explicit generated-top links
while keeping the reusable actor's reset kind and polarity unchanged.

This remapping is still system-signal binding behavior; it does not imply
CDC.

Multi-clock, asynchronous, and interacting clock-domain semantics are owned
by the separate shipped [ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md)
event-crossing surface and its remaining backlog.

Shipped source model for actor exports:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Shipped use model for actor exports (the example assumes the
sibling `isf/common/fifo.isf` library is on the search path; see the
`isf/fifo_library_use.isf` fixture in the repo for a self-contained
working pair):

```text
(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params (WIDTH 32) (DEPTH 4))
    (bind
      (clock clk)
      (reset rst)
      (input push push_i)
      (input pop pop_i)
      (input data_in data_i)
      (output data_out data_o)
      (output full full_o)
      (output empty empty_o))))
```

The first repo-local reusable FIFO fixture uses that model through
`isf/common/fifo.isf` and `isf/fifo_library_use.isf`. The library exports
`common.fifo.fifo`; the top-level fixture imports it as `fifo_lib` and binds
the public FIFO ports to instance `u_fifo`. The generated HDL proof checks
the specialized child module, fixed parameter bindings, scalarized data
entries, pointer-gated accepted push/pop selectors, and generated top wiring.

The promoted fixture coverage additionally checks strict schedule JSON parity,
strict `--outdir` file emission for the importer, specialized child, and
generated top `.fsm` files, fixed use-site binding provenance, and both plain
and strict generated-top HDL generation.

Imports are actor-scoped in the first shipped model. Imported definitions stay
namespaced by default; `as alias` creates a local namespace alias, not
unqualified symbol pollution. The first shipped export target should be
reusable actors. Standalone transaction templates and standalone drive helpers
need their own binding rules before they become public library exports.

Shipped specialization and binding model (schematic — the FIFO
actor's body is elided with `...`; the importing actor must live in
a separate file so the parser sees one top-level actor per source):

```text
(actor fifo
  (params
    (WIDTH 8)
    (DEPTH 4))
  ...)

(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params
      (WIDTH 32)
      (DEPTH 4))
    (bind
      (clock clk)
      (reset rst)
      (input push push_i)
      (input pop pop_i)
      (input data_in data_i)
      (output data_out data_o)
      (output full full_o)
      (output empty empty_o))))
```

Actor-library parameters use unique HDL-identifier-compatible names and a
default value. Use-site overrides are instance-local and should reuse the
spawn-parameter value boundary first: scalar decimal literals, exact-width
numeric literals, and compatible aggregate/list literals. Missing overrides use
defaults; duplicate parameters, unknown overrides, unsupported symbolic values,
and unsupported non-static parameter use fail closed.

Binding is explicit. A reusable actor with a clock or reset must bind it at the
use site. Reset kind and polarity belong to the reusable actor for the first
ship; the use site should not silently change sync/async or active-high/low
semantics. Every exported actor interface port must be bound exactly once with
matching direction and matching specialized width. No implicit truncation,
extension, or slicing is performed by the binder.

Generated names are deterministic in the shipped resolver: the authored
instance name remains
the stable diagnostic/report identity, while the first specialized child module
and scheduled `.fsm` basename use `<importing_actor>__<instance>` and
`<importing_actor>__<instance>.fsm`. Successful reports expose a bounded
`library_uses` array with library/export/instance identity, parameter
source/value summaries, binding summaries, and generated artifact names without
exposing raw resolver or lowerer internals.

Resolver scope: `parse_file(...)` checks same-source library roots, then
external library files under the importing source directory, `FSMLIB` entries,
and the current directory. For a dotted namespace such as `common.fifo`, both
`common.fifo.isf` and `common/fifo.isf` are candidate file names. `parse_source`
can use same-source library roots but cannot resolve external files without a
real source path. Standalone transaction/drive exports, symbolic parameter
values beyond the shipped actor-local scalar static-dimension defaults,
derived parameter expressions, transaction-port dimensions beyond positive
literals, actor-local scalar parameters, and scalar type aliases,
memory-array backend emission, nested library imports, and multi-clock-domain
ISF semantics are still deferred.

FIFO modeling rule: a FIFO should be modeled primarily as an actor because it
owns persistent storage, pointers, occupancy, full/empty flags, reset behavior,
and interface timing across cycles. Enqueue, dequeue, flush, or status-probe
behaviors can be transactions or callable operations inside or against that
actor, but a transaction alone should not own the FIFO's persistent state.

Hardware components in ISF are persistent regions, not software processes that
die when their immediate work is done. Actors, transactions, DTs, and rules
may be inactive, but while the design is powered, clocked, and released from
reset, their logic remains present.

Shipped actor-owned storage model (schematic — the actor body
continues with `(interface ...)`, `(transaction ...)`, and so on):

```text
(actor fifo
  (storage
    (var rd_ptr (width 2))
    (var wr_ptr (width 2))
    (var occupancy (width 3)))
  ...)
```

`(var name (width N|PARAM|CONST|PACKAGE.CONSTANT))` declares one internal actor
scalar storage value. `(variable ...)` is the verbose scalar-storage alias.
Bank width and depth use
`(bank name (width N|PARAM|CONST|PACKAGE.CONSTANT) (depth N|PARAM|CONST|PACKAGE.CONSTANT))`.
`PARAM` must be an actor-local scalar parameter default that resolves to a
positive integer. `CONST` on scalar storage, bank width, or bank depth must be
a declared actor constant that resolves to a positive integer.
`PACKAGE.CONSTANT` on scalar storage width, bank width, or bank depth must be
a qualified imported package scalar constant that resolves to a positive
integer.

`(bank name (width N|PARAM|CONST|PACKAGE.CONSTANT) (depth N|PARAM|CONST|PACKAGE.CONSTANT))`
remains the fixed-depth actor-owned storage form. The FIFO-controller matrix
does not use an internal
bank, but the shipped data-path probe now exercises a depth-4 bank through explicit
store/load access.

Declarative field-structured storage now ships for the first bounded scalar
storage slice: `(fields (field NAME (bits HI LO) ...))` is accepted on
width-based scalar `var` / `variable` storage and appears as optional
`inferred_storage[].fields` metadata. It remains report-only; `set-field`,
`when-field`, `extract`, and `assemble` are still runtime behavior/data
operations, not static layout declarations. Residual work remains for parent
reset derivation, access-policy behavior, generated assertions/register
models, actor `(enums ...)` references, banks, typed aggregate carriers, and
packet/flit layouts.

The non-behavior support-accounting promotion is now shipped through
`isf/storage_fields.isf`: check JSON and normalized semantic JSON report the
matched `feature.isf_storage_field_metadata` source identity, while schedule
JSON remains the public payload for the field map.
The narrow field-structured-storage frontier is closed after that promotion;
future reset derivation, access behavior, register-model generation, aggregate
or bank layout, packet/flit mapping, and direct semantic JSON field-map export
need fresh exact task-tree leaves before implementation.

Selected data-buffer access surface:

```lisp
(store data wr_ptr data_in)
(load data rd_ptr as data_out)
```

`store` writes a value into the actor-owned bank entry selected by the index.

For the first depth-4 implementation it lowers through the existing scalarized
review artifact by guarded updates to `data_0`, `data_1`, `data_2`, and
`data_3`. `load` reads the selected bank entry into a scalar target, again
through mux-equivalent guarded assignments from the scalarized entry family.

Rules and supported transaction contexts accept these forms for declared
actor-owned banks.

`store` is intentionally bank-entry-only; scalar actor-owned storage declared
with `(var ...)` or `(variable ...)` uses the existing rule assignment and
transaction `update` surfaces.

The first same-cycle store/load policy is read-before-write. A load observes
the current cycle's bank value, while a store updates the selected entry for
the next cycle. Write-first collision behavior, explicit bypassing, or
collision diagnostics need their own future option or construct.

Successful schedule reports expose bounded `bank_accesses` metadata for these
forms: access kind, owner, container, bank name, index expression, width,
depth, scalarized entries, value or target, and the same-cycle policy. The
shipped index is a scalar signal or literal token; full list-expression indexes
remain future work.

`isf/fifo_data_path.isf` is now the strict file-backed datapath fixture for
this surface. It proves strict schedule JSON parity, scheduled `.fsm`
structure, bounded `bank_accesses[]` metadata, plain and strict HDL
generation, scalarized depth-4 bank storage, pointer-guarded accepted pushes,
and pointer-guarded accepted pops.

The shipped FIFO fixture is a real FIFO actor, not a depth-1 placeholder. A
depth-1 element may be useful as a register slice or holding element, but it
does not exercise FIFO depth, pointers, or occupancy semantics. The first
fixture is fixed to `DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and
`OCC_WIDTH=3`. Those parameters are emitted as provenance and use-site binding
evidence. Actor top-level interface port widths may use declared actor
constants, actor-local scalar parameter defaults, or qualified imported
package scalar constants when they resolve to positive integers. Actor-owned
scalar storage widths, actor-owned bank widths, and actor-owned bank depths
may use declared actor constants, actor-local scalar parameter defaults, or
qualified imported package scalar constants when they resolve to positive
integers.
Transaction-local port widths may use actor-local scalar parameter defaults,
declared actor constants, qualified imported package scalar constants, or
same-transaction scalar parameter defaults on generated child and
direct/non-generated transactions when they resolve to positive integers.
FIFO use-site interface shape specialization and generated-top
respecialization remain future work.

The fixture explicitly models the four request cases: no request, push without
pop, pop without push, and push with pop. Push-only updates occupancy and the
write pointer when not full; pop-only updates occupancy and the read pointer
when not empty; simultaneous push+pop derives the write and read effects from
the same pre-cycle state and updates both sides atomically; idle preserves
state. Depth 4 gives the initial implementation concrete 2-bit pointer wrap,
occupancy values 0 through 4, and full/empty flag checks before arbitrary-depth
elaboration is generalized.

`full` is actor-maintained and is `1` when `occupancy == 4`; `empty` is
actor-maintained and is `1` when `occupancy == 0`. `wr_ptr` names the next
entry selected by an accepted push; `rd_ptr` names the next entry selected by
an accepted pop. For the depth-4 controller matrix both pointers wrap from
entry 3 back to entry 0.

`isf/fifo_controller.isf` is now the strict file-backed controller fixture for
this matrix. It proves strict schedule JSON parity, scheduled `.fsm`
structure, compatible same-value fan-in metadata, plain and strict HDL
generation, and the explicit controller-only boundary.

`isf/fifo_library_use.isf` is now the strict file-backed reusable FIFO fixture
for the combined fixed controller/datapath actor. It proves strict schedule
JSON parity, generated importer/child/top scheduled `.fsm` files, strict
`--outdir` emission, fixed parameter and binding provenance, scalarized bank
entries, generated top wiring, and plain plus strict generated-top HDL
generation.

Transaction `(when condition body...)` is ordered control flow, so using a
chain of `when` branches to model FIFO ports would be misleading. Disjoint-rule
proof for same-target FIFO-style rule writes is shipped for direct
contradictory guard facts, such as one case requiring
`(== occupancy 1)` while another requires `(== occupancy 2)`. Same-cycle
two-port controller semantics are now proven on actor-owned state, and the
fixed reusable FIFO fixture reaches generated-top SystemVerilog. Public
catalog/contract metadata is synchronized through
[docs/ISF_LIBRARY_CATALOG.md](../../ISF_LIBRARY_CATALOG.md),
`library_catalog_paths`, `library_catalog_entry_keys`, and
`shipped_library_definitions`.

### ISF Multi-Clock And CDC Semantics

Status: shipped first acknowledged-event CDC primitive; richer CDC remains backlog.

Goal: give ISF a deliberate model for designs with multiple clock domains,
asynchronous boundaries, and interacting domains.

Current boundary: legacy `(clock name)` actors and reusable-library
clock/reset bindings remain one-clock-domain scheduled artifacts. The parser
now accepts actor-scoped `(clock-domains ...)` metadata and the scheduler can
partition accepted actors by domain. Public multi-domain `lower(...)` now
emits domain-specific scheduled `.fsm` artifacts plus generated top wiring for
domain modules and explicit CDC child interfaces. Public `report(...)` now
projects bounded domain and event-crossing metadata, and accepted
event-crossing actors now reach generated SystemVerilog/Verilog-family HDL for
the generated top plus concrete acknowledged-event CDC child modules for
accepted crossings when each emitted domain artifact satisfies the current
scheduled `.fsm` HDL contract, including clock-only no-reset domains.

Different clock signal names, library clock/reset bindings, and generated-top
system-port links are not CDC semantics by themselves.

The shipped boundary is tracked by
[ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md). The first fixture
hardening slice now adds
[isf/clock_domain_dual_event_crossing.isf](../../isf/clock_domain_dual_event_crossing.isf),
which covers two opposite-direction acknowledged event crossings in one
generated top with two CDC children, report metadata, and generated HDL.
[isf/clock_domain_no_reset_event_crossing.isf](../../isf/clock_domain_no_reset_event_crossing.isf)
now covers the no-reset acknowledged-event schedule/report and HDL path,
including absent-reset CDC metadata, reset-free domain modules, and a generated
CDC child without absent reset ports.

Remaining backlog still needs richer CDC fixture matrices for payload-like
protocol actors, dual-clock FIFO-like actors, and broader reset/no-reset
protocol combinations.

Outside that shipped event primitive, direct same-cycle reads or writes across
domains must not be inferred from ordinary signal access.

Source-model decision: the selected source model is actor-scoped named
domains. Existing `(clock name)` remains the shorthand for one implicit actor
domain named `default`. Multi-domain source uses an actor-level
`(clock-domains ...)` block such as:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain bus  (clock bus_clk)))
```

Interface ports, actor-owned storage entries, transactions, rules, reusable
`use` instances, and generated child activations may reference only domains
declared by the actor through `(domain NAME)` annotations and otherwise inherit
the default. A single-domain `(clock-domains ...)` block has an implicit
default and can still lower through the existing single-clock path. Drives
inherit the activation-site domain. Domain annotations are ownership metadata,
not CDC primitives, so direct cross-domain reads, writes, triggers,
activations, bindings, or multi-domain drive reuse fail closed until a legal
crossing primitive ships.

Reset-ownership decision: multi-domain source puts reset ownership inside each
domain entry. Existing actor-level `(reset ...)` remains the single-domain
shorthand, but it must not be mixed with `(clock-domains ...)`.

Each domain owns zero or one reset. Synchronous resets are sampled on the
owning domain clock; asynchronous resets are direct external reset pins, not
DT-generated logic. Reusing one reset signal across domains is only legal when
kind and polarity match exactly, and it is reset fanout rather than data CDC.

Crossing decision: the first legal crossing primitive is an acknowledged
single-bit event channel declared in actor-scoped
`(crossings ...)` source. It has a source-domain event request, generated
source-domain `ready`, and generated destination-domain one-cycle pulse.

Lowering represents it as an explicit CDC child interface in the generated top;
schedule reports expose the endpoint domains/signals and generated
instance/module names. The first concrete generated-HDL path emits an
acknowledged event synchronizer child for reset-declared
SystemVerilog/Verilog-family actors. It carries no payload and promises no
same-cycle timing. Direct
cross-domain reads, writes, triggers, activations, parent/child bindings, and
reset assertion/deassertion events remain fail-closed unless a shipped
primitive or protocol actor owns that path. Payload handshakes and dual-clock
FIFO-like actors remain future backlog.

Lowering decision: current multi-domain lowering validates a domain-local
partition, rejects unowned crossings, and emits normal single-clock scheduled
`.fsm` artifacts named `<actor>__domain_<domain>.fsm`. The generated top owns
only inter-module wiring and now instantiates explicit CDC child interfaces for
accepted event crossings. Normal scheduled `.fsm` modules are not silently
widened into multi-clock modules. Bounded schedule-report metadata, a first
single-event fixture, and a dual opposite-direction event fixture are shipped;
both fixture families now reach plain generated HDL with concrete CDC
children.

### End-To-End Large-Design Scalability

FSMGen has a foundational requirement to handle end-to-end big to really big
designs. That means the complete source-to-HDL/verification path: parsing and
normalization, IAL lowering, scheduling/analysis, review artifacts, HDL,
semantic exports, and tool handoff. A parser-only stress input is not sufficient
evidence.

The proposed
[large-design scalability task](../../tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md)
will first select measurable `big` and `really_big` structural profiles,
deterministic same-volume workloads, per-stage correctness oracles, peak
descendant RSS/time/artifact measurements, bottleneck analysis, evidence-based
budgets, graceful beyond-capacity behavior, and stable local/CI qualification
gates. Correctness, diagnostics, deterministic artifacts, locality, and
recoverability remain part of the capacity contract.

This requirement is parked rather than active. Selector `.831` chose the
smaller direct-VHDL unary-reduction correctness audit after the separate named-
drive priority tree completed through implementation `.3`. A later roadmap
selector must still activate scale from a clean boundary.
