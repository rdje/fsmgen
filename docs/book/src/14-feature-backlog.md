# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: partially shipped; broader inference surfaces remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, slices, selectors, guards, and
other bounded evidence. It does not yet promise "never declare scalar types
unless you want to" across every source position.

### Dynamic Divisor Safety Proofs

Status: partially shipped.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission. ISF runtime expression contexts now reject
numeric/exact-width literal-zero divisors and actor-level constants that
resolve to zero before scheduled `.fsm` emission. Nonzero literal divisors,
nonzero actor-constant divisors, and dynamic scalar divisors are emitted
unchanged; FSMGen does not yet prove every dynamic divisor nonzero. Actor and
transaction parameters remain outside this safety proof because they are
overrideable specialization values, not fixed actor constants.

## Aggregate Types And Data

### Automatic Aggregate Growth From Usage

Status: backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, and partial aggregate
LHS writes are supported on the current SystemVerilog path. Broad automatic
aggregate type growth from arbitrary usage is not fully shipped.

### Backend-Owned Struct/Record Default Lowering

Status: backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases on the current SystemVerilog path. Structured
record lowering is not the default for all aggregate data.

### Richer Aggregate Operators

Status: backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: matching list/record aggregate shapes support leafwise
`+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` plus word aliases before HDL lowering.
Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path.

### VHDL Aggregate Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: VHDL is recognized as a target family, but the full backend
is not implemented. Aggregate lowering beyond scalar/width-safe surfaces is
therefore not shipped.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.

## Composition

### VHDL Generic-Map Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL
generic-map lowering is not shipped.

### Broader Generated-Child Top Instantiation

Status: partially shipped; generalized surfaces remain backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths, and ISF generated-child fixtures now emit a generated
`<actor>_top.fsm` that wires the scheduled parent, scheduled children,
start/done handoffs, named-drive handoffs, explicit port-binding handoffs, and
per-instance parameter overrides for spawn and generated blocking `do`
activations through the existing composition pipeline. Broader generated-child
top surfaces beyond the covered spawn and parameterized `do` patterns remain
backlog.

### Spawn and Blocking Do Parameter Binding

Status: partially shipped; broader parameter/value surfaces remain backlog.

Goal: bind parameters through static generated child activations in
ISF-generated multi-file scheduled designs.

Current boundary: spawn and parameterized blocking `do` emit child files, a
parent scheduled `.fsm`, and a generated composition top for covered
generated-child fixtures. The ISF lowerer accepts one optional nested
`(params (NAME value) ...)` block on `(spawn child as instance ...)` and on
`(do child ...)`, accepts generated child transaction parameters from a
transaction-local `params` clause, emits child defaults as scheduled child
`+params`, validates duplicates/unknown overrides/value shapes, rejects
parameter declarations on non-generated transactions, preserves per-instance
override lists in the parent lowerer IR, and applies those overrides through
the generated top. The shipped value domain is scalar/exact-width literals,
actor-local constants, scalar local or package-qualified enum members, and
compatible aggregate/list literals whose scalar leaves are literals,
actor-local constants for activation overrides, or enum members for actor
parameter defaults, generated child transaction parameter defaults, and
activation overrides. Reusable-library use-site parameter overrides may use
enum members as scalar values or scalar leaves inside compatible aggregate/list
override values. Constant names and scalar enum members on activation sites,
and enum members on reusable-library use sites, are resolved to literal values
before generated-top emission. Runtime signals and arbitrary expressions remain
outside the shipped value domain.

### General Transaction Activation Parameter Overrides

Status: shipped bounded surface; broader activation forms remain backlog.
The original `ISF-TRANSACTION-ACTIVATION` tree is closed for spawn and
blocking `do`, and the `ISF-ACTIVATION-PARAM-OVERRIDES` tree is closed for
rule-trigger overrides plus the direct-activation boundary. Rule-trigger
parameter overrides are shipped. Direct `(on ...)` activation is unsupported
for activation-site `(params ...)` and is regression-covered as a fail-closed
entry-body form.

Goal: extend the task-like transaction activation model so activation sites can
override declared transaction parameters where that is semantically valid.

Current boundary: transaction ports already provide formal data/control ports,
and shipped activation-site `(bind ...)` blocks pass scalar actual signals for
the supported `do`, `spawn`, and rule `trigger` subset. Spawned child
transactions and blocking `do` child activations support per-instance
`(params (NAME value) ...)` overrides through generated composition.
Parameterized rule triggers now use the same generated-composition
specialization model. Parameter overrides on direct transaction activation or
other future activation forms are not public syntax. For direct `(on ...)`,
there is deliberately no source shape: the entry guard belongs to the
transaction definition, not to a caller-owned instance that can be specialized.
Runtime-varying values should use transaction ports, `(sample ...)`, or
activation-site `(bind ...)` where supported.

Source shape: reuse the existing explicit spawn-style
`(params (NAME value) ...)` block on activation sites that support static
specialization, while keeping runtime payloads in `(bind ...)`. This is
shipped for spawn, blocking `do`, and rule `trigger`:

```lisp
(do child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))

(trigger child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))
```

Lowering rule: parameter overrides specialize hardware; they do not assign
runtime parameter signals. A parameterized blocking `do` elaborates a generated
child activation instance named `{parent}_{child}_do_{ordinal}` and waits for
that instance's `done` handoff. The selected parameterized rule-trigger
lowering elaborates a generated child activation instance named
`{rule}_{transaction}_trigger_{ordinal}`. The rule still emits the existing
one-cycle trigger source and input payload sources, then a generated handoff DT
drives the instance start and input handoff ports under that source. The
generated top applies the static `(params ...)` overrides on the child
`?fsmc` instance. The rule wires but does not await the generated child `done`
handoff, and output bindings remain unsupported. Scalar enum member override
values are resolved to literal generated-top parameter bindings for the shipped
spawn, generated blocking `do`, and rule-trigger subset; scalar enum member
leaves inside aggregate/list override values resolve to the same literal
generated-top bindings.

Direct `(on port body...)` remains the entry/idle-state guard and accepts only
`(sample port as name)` nested body clauses. `(on start (params (WIDTH 16)))`
must fail closed instead of being interpreted as a static specialization or a
runtime parameter assignment.

If two activation sites pass different parameter values to the same
transaction, the lowerer must elaborate distinct logical child instances or
cloned scheduled regions. If that cannot be done for a given activation form,
the form must fail closed with a diagnostic that tells the author to move the
value to a transaction input port and `(bind ...)` it as runtime data.

### Spawn Inside Repeat Bodies

Status: partially shipped; broader repeat-body child activation remains backlog.
Task-tree owner for the remaining backlog:
[`ISF-REPEAT-BODY-CHILD-ACTIVATION`](../../tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md).
Repeat-body local `(do child)`, top-level when-body nested repeat local
or generated-child `(do child)`, top-level when-body nested repeat
static-parameter generated `(do child (params ...))` with optional
`(bind ...)` handoffs, top-level switch-branch nested repeat local,
generated-child `(do child)`, or static-parameter generated
`(do child (params ...))` with optional `(bind ...)` handoffs and optional
declared same-domain `(domain NAME)` metadata, repeat-body generated blocking
`(do child (params ...))`, repeat-body spawn `(bind ...)`, and declared
same-domain `(domain NAME)` metadata are shipped for the already shipped
top-level repeat plus same-body synchronization paths. The local `do` subset
stays in the parent scheduled module and waits for the child's fresh done
pulse before the repeat check can loop; when the repeat is directly inside a
top-level `when` body, a local do state lives in the branch-owned repeat
region or a plain generated-child do site emits one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance when the target is already
generated elsewhere. Both forms gate that nested repeat check on fresh child
done. Top-level `switch` branch nested repeats support the same local or
generated-child do forms. The
generated `do` subset emits one
generated child instance for the lexical repeat-body do site and applies
static parameter overrides once in the generated top. The spawn subset reuses
the static generated-child model: one lexical spawn name maps to one generated
child instance, binding payload ports are generated once for that instance
rather than per repeat iteration, and the domain annotation records ownership
metadata without implying CDC behavior.

Goal: allow `(spawn child as name)` inside `(repeat count body...)` without
implying dynamic hardware creation.

Required contract: the lexical spawn name denotes one static child instance in
the generated top. The repeat loop may activate that instance multiple times,
but it must not elaborate one instance per iteration. The scheduler needs a
busy/re-entry rule before this can ship: either prove or insert sequencing so
each later iteration observes the child's fresh done pulse before starting it
again, or reject the loop with a targeted diagnostic.

Shipped subset: a top-level repeat body may use local `(do child)` when the
child remains in the parent scheduled module. A repeat directly inside a
top-level `when` body may also use that local `(do child)` subset, may use
plain generated-child `(do child)` when the target child is already emitted as
a generated child by another activation site, or may use generated blocking
`(do child (params ...))` with static parameter overrides. The nested
generated `when` forms own one deterministic generated do instance for the
lexical site, apply parameter overrides once when present, may wire
input/output binding handoffs once when `(bind ...)` is paired with static
`(params ...)`, and may carry declared same-domain `(domain NAME)` metadata
when static params are present. A repeat directly inside a top-level
`switch` branch may use local, plain generated-child `(do child)`, or
static-parameter generated `(do child (params ...))` under the same
generated-do rule and may wire input/output binding handoffs once when
`(bind ...)` is paired with static `(params ...)`; it may also carry declared
same-domain `(domain NAME)` metadata when static params are present. It
rejects deeper branch nesting and loop-contained repeat activation.
A top-level repeat body may use
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` clauses
when the same repeat body reaches `(await_all done)` before the repeat check
can loop. A single-pending `(await_any done)` is also shipped when exactly one
repeat-body spawn is pending; in that case it has the same re-entry proof as
waiting for the one static child. Local repeat-body `do` and `await_all`
consume the needed done pulse before the repeat check, so the next iteration
cannot re-assert the local or static child start before the previous activation
has returned fresh done. Repeat-body generated blocking `do` with static
parameter overrides has the same re-entry proof because the do state waits for
the generated instance's done handoff before the repeat check. Samples after
repeat-body spawn are shipped when they appear before the same-body
`await_all` or single-pending `await_any`; they materialize in an explicit
sample state before the sync state.
Parameter overrides reuse the same static specialization contract as top-level
spawn: they specialize the one lexical child instance in the generated top and do not
create per-iteration parameter values. Binding handoffs generate one set of
parent handoff ports for the lexical static instance and are wired in the
generated top. Repeat-body generated `do` now uses the same static
parameter-plus-binding handoff model for its lexical generated do instance and
may also carry same-domain `(domain NAME)` metadata. Domain annotations are
accepted only when they name the same declared domain as the owning
transaction and child; cross-domain activation still needs an explicit
CDC/protocol contract. Plain repeat-body generated-child `(do child)` is now
shipped for targets already generated elsewhere: it creates one deterministic
generated do instance for the lexical repeat-body do site without requiring
`(params ...)`,
`(bind ...)`, or `(domain NAME)` on that site, then gates repeat re-entry on
that instance's fresh done handoff. Samples immediately before shipped
repeat-body local or generated `do` states now lower into explicit sample
states before the do state. Samples immediately after those do states lower
after the do state's fresh done guard and before the repeat check.
Multi-pending repeat-body `await_any` is now shipped only as an observation
point: a later same-body `await_all` must drain the same outstanding
repeat-body spawns before the repeat check can loop, and new repeat-body
`spawn` or `do` clauses between that observation and the drain remain out of
scope. Repeats directly inside a top-level `when` body may also use one or
more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites when
the same nested repeat body reaches `(await_all done)` before the nested
repeat check can loop. Repeats directly inside a top-level `switch` branch
accept the same multiple generated-spawn plus same-body `await_all` subset.
Both branch-contained paths may use single-pending `(await_any done)` directly
when exactly one generated child is pending. Both branch-contained paths may
also use multi-pending `(await_any done)` as an observation point when a later
same-body `(await_all done)` drains the same outstanding generated children
before the nested repeat check can loop. Those branch-contained nested spawn
subsets reuse the static generated-child handoff model, preserve source-order
samples before the nested spawn or sync states, and gate the nested repeat
check on spawned child done handoffs. The top-level `when` body nested-repeat
subset now also allows a local plain `(do child)` while generated nested
spawns remain pending either before or after a prior multi-pending
`(await_any done)` observation, provided a later same-body `(await_all done)`
drains the outstanding generated children before the nested repeat check can
loop. The top-level `switch` branch nested-repeat subset allows the same
local plain `(do child)` pending-spawn form before or after a prior
multi-pending `(await_any done)` observation. That local do target remains in
the parent scheduled module, waits for the local child's fresh done pulse, and
does not clear the pending generated-spawn done set. The top-level `when`
body and top-level `switch` branch nested-repeat subsets also allow a plain
generated-child `(do child)` in that same pending-spawn interval when the
target child is already emitted as a generated child by another activation
site. Both branch-contained generated-child subsets may place that do before
or after a prior multi-pending `(await_any done)` observation. Those generated
do sites own one deterministic generated instance, wait for that instance's
fresh done handoff, and leave the pending generated-spawn done set live for
the later same-body `(await_all done)` drain. The same two
branch-contained subsets also ship static-parameter generated
`(do child (params ...))` in that pending-spawn interval, preserving generated
top parameter binding on the generated do instance while still requiring the
later same-body drain. The same branch-contained pending-spawn generated do
subsets also accept `(bind ...)` input/output port bindings when static
`(params ...)` overrides are present. The nested do site reuses the
deterministic generated do instance for that lexical site, wires
generated-top binding handoffs once, waits for the instance's fresh done
handoff before the branch-owned repeat check, and leaves the pending
generated-spawn done set live for the later drain. Generated `do` after a
prior multi-pending `await_any`, `await_any` after the do, new nested
`spawn` after the do before the drain, cross-domain repeat-body `do`,
generated/spawn nested activation beyond the documented branch-contained
generated `do` cases and the branch-contained spawned cases, deeper branch
repeat activation, loop-contained repeat activation, and broader
outstanding-child lifetime semantics beyond the mandatory-drain subset remain
backlog. The shipped branch-contained generated nested do subsets still keep
unsupported activation subclauses, spawn nesting, deeper branch/loop nesting,
cross-domain activation, and broader outstanding-child semantics out of scope.

The when-contained same-domain metadata analogue for that pending-spawn
interval is shipped. It covers a repeat directly inside a top-level `when`
body with one or more generated spawns, generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))` while those generated
nested spawns are pending, and a later same-body `(await_all done)` drain
before the nested repeat check can loop. The domain
annotation is declared same-domain ownership metadata only for the
deterministic generated do instance; it preserves generated-composition/domain
partition metadata and schedule-report clock-domain child-instance summaries
without implying CDC or cross-domain activation. The switch-contained
same-domain analogue for that pending-spawn interval is also shipped. It
covers a repeat directly inside a top-level `switch` branch with one or more
generated spawns, generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))` while those generated
nested spawns are pending, and a later same-body `(await_all done)` drain
before the nested repeat check can loop. The domain annotation is declared
same-domain ownership metadata only for the deterministic generated do
instance; it preserves generated-composition/domain partition metadata and
schedule-report clock-domain child-instance summaries without implying CDC or
cross-domain activation.

Outside the pending-spawn interval, the when-contained nested generated-do
domain leaf covers a repeat directly inside a top-level `when` body with
generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))`: declared same-domain
ownership metadata only. This subset is shipped. The nested do site records
ownership for the deterministic generated do instance at that lexical site,
preserves generated-composition and schedule-report clock-domain metadata,
and keeps spawn nesting, cross-domain activation, deeper branch/loop nesting,
and broader outstanding-child semantics out of scope.

Outside the pending-spawn interval, the switch-contained nested generated-do
domain leaf covers a repeat directly inside a top-level `switch` branch with
generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))`: declared same-domain
ownership metadata only. This subset is shipped. The deterministic generated
do instance at that lexical site records ownership in generated-composition
and schedule-report clock-domain metadata without implying CDC or
cross-domain activation.

The when-contained nested repeat spawn leaf covers a repeat directly inside a
top-level `when` body with one or more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites that
reach same-body `(await_all done)` before the nested repeat check can loop.
This subset is shipped. Exactly one pending generated child may also use
single-pending `(await_any done)`. It reuses the static generated-child
handoff model, keeps source-order samples before the spawn or sync states
explicit, and keeps the nested repeat re-entry gated on spawned child done
handoffs.

The switch-contained nested repeat spawn leaf covers the direct switch
analogue: a repeat directly inside a top-level `switch` branch with one or
more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites that
reach same-body `(await_all done)` before the nested repeat check can loop.
This subset is shipped. Exactly one pending generated child may also use
single-pending `(await_any done)`. It reuses the static generated-child
handoff model, keeps source-order samples before the spawn or sync states
explicit, and keeps the nested repeat re-entry gated on spawned child done
handoffs.

The when-contained nested repeat multi-pending `await_any` leaf covers a
repeat directly inside a top-level `when` body with two or more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
`(await_any done)` as an observation point, and a later same-body
`(await_all done)` drain before the nested repeat check can loop. This subset
is shipped. New nested `spawn` or `do` clauses before the mandatory drain,
cross-domain activation, deeper branch/loop nesting, and broader
outstanding-child semantics remain backlog beyond the shipped
branch-contained spawn leaves.

The switch-contained nested repeat multi-pending `await_any` leaf covers the
direct switch analogue: a repeat directly inside a top-level `switch` branch
with two or more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
`(await_any done)` as an observation point, and a later same-body
`(await_all done)` drain before the nested repeat check can loop. This subset
is shipped. New nested `spawn` or `do` clauses before the mandatory drain,
cross-domain activation, deeper branch/loop nesting, and broader
outstanding-child semantics remain backlog beyond the shipped
branch-contained spawn leaves.

The when-contained nested repeat local-do-while-spawn-pending leaf covers
top-level `when` body nested repeats with one or more
generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
sites may run a local `(do child)` while those generated spawns remain
pending, provided a later same-body `(await_all done)` drains the outstanding
generated children before the nested repeat check can loop. This subset is
shipped. The `do` target must remain local to the parent scheduled module; it
uses the parent-module start/done pulse contract and leaves generated-spawn
done handoffs live until the later drain. The direct top-level `switch` branch
analogue is also shipped: a repeat directly inside a top-level `switch` branch
may run a local `(do child)` while generated nested spawns remain pending,
with the same later same-body `(await_all done)` drain requirement and the
same local start/done proof.
The top-level `when` body generated-child analogue is also shipped: plain
`(do child)` may run while generated nested spawns are pending when `child` is
already emitted as a generated child by another activation site. The generated
do site owns one deterministic generated instance, waits for that instance's
fresh done handoff, and leaves the pending generated-spawn done set live for
the later same-body `(await_all done)` drain.
The direct top-level `switch` branch generated-child analogue is also shipped:
plain `(do child)` may run while generated nested spawns are pending when
`child` is already emitted as a generated child by another activation site.
The generated do site owns one deterministic generated instance, waits for
that instance's fresh done handoff, and leaves the pending generated-spawn
done set live for the later same-body `(await_all done)` drain.
The top-level `when` body and top-level `switch` branch static-parameter
generated `do` analogues are also shipped: `(do child (params ...))` may run
while generated nested spawns are pending when a later same-body
`(await_all done)` still drains every outstanding generated child before the
nested repeat check can loop. The generated do site owns one deterministic
generated instance, records static generated-top parameter binding, waits for
that instance's fresh done handoff, and leaves the pending generated-spawn
done set live for the later drain.
The top-level `when` body binding analogue is also shipped: generated
`(do child (params ...) (bind ...))` may run while generated nested spawns are
pending when a later same-body `(await_all done)` still drains every
outstanding generated child before the nested repeat check can loop. This
subset mirrors the shipped static-parameter pending-spawn leaf, with
generated-top input/output binding handoffs added once for the generated do
instance while pending generated-spawn done handoffs remain live until the
later drain.
The direct top-level `switch` branch binding analogue is also shipped:
generated `(do child (params ...) (bind ...))` may run while generated nested
spawns are pending when a later same-body `(await_all done)` still drains
every outstanding generated child before the nested repeat check can loop.
This switch-contained subset mirrors the shipped when-contained bound
pending-spawn leaf, with generated-top input/output binding handoffs added
once for the generated do instance while pending generated-spawn done
handoffs remain live until the later drain. Domain metadata on those generated
`do` sites, `await_any` observation before or after the do, new spawn after
the do before the drain, cross-domain activation, deeper branch/loop nesting,
and broader outstanding-child semantics remain deferred.

The branch-contained `await_any`-before-local-do subsets for that
pending-spawn interval are shipped. They cover repeats directly inside a
top-level `when` body or top-level `switch` branch with multiple generated
spawns, a multi-pending `(await_any done)` observation, local blocking
`(do child)` while those generated spawns remain pending, and a later
same-body `(await_all done)` drain before the nested repeat check can loop.
The local do target stays in the parent scheduled module and the
generated-spawn done handoffs stay live through the local do until the later
drain. The when-contained generated-child `await_any`-before-do subset is also
shipped: a repeat directly inside a top-level `when` body with multiple
generated spawns, a multi-pending `(await_any done)` observation, a plain
generated-child `(do child)` whose target is already emitted by another
activation site, and a later same-body `(await_all done)` drain before the
nested repeat check can loop. The generated do instance keeps its own fresh
done handoff while the pending generated-spawn done set remains live for the
later drain. The switch-contained generated-child `await_any`-before-do
analogue is also shipped with the same pending-spawn lifetime and later drain
contract. The when-contained static-parameter generated
`await_any`-before-do analogue is now shipped as well: a repeat directly
inside a top-level `when` body may have multiple generated spawns, a
multi-pending `(await_any done)` observation, generated blocking
`(do child (params ...))` with static parameter overrides while those
generated spawns remain pending, and a later same-body `(await_all done)`
drain before the nested repeat check can loop. The generated do instance
carries its static parameter binding in the generated top, waits on its own
fresh done handoff, and does not clear the pending generated-spawn done set
that the later drain must consume. The switch-contained static-parameter
generated `await_any`-before-do analogue is shipped with the same contract: a
repeat directly inside a top-level `switch` branch may have multiple
generated spawns, a multi-pending `(await_any done)` observation, generated
blocking `(do child (params ...))` with static parameter overrides while those
generated spawns remain pending, and a later same-body `(await_all done)`
drain before the nested repeat check can loop.

The when-contained bound generated `await_any`-before-do analogue is also
shipped: a repeat directly inside a top-level `when` body may have multiple
generated spawns, a multi-pending `(await_any done)` observation, generated
blocking `(do child (params ...) (bind ...))` with static parameter overrides
and input/output binding handoffs, and a later same-body `(await_all done)`
drain before the nested repeat check can loop. The generated do instance wires
its input/output handoff ports in the generated top, waits on its own fresh
done handoff, and does not clear the pending generated-spawn done set that the
later drain must consume.

The switch-contained bound generated `await_any`-before-do analogue is also
shipped: a repeat directly inside a top-level `switch` branch may have
multiple generated spawns, a multi-pending `(await_any done)` observation,
generated blocking `(do child (params ...) (bind ...))` with static parameter
overrides and input/output binding handoffs, and a later same-body
`(await_all done)` drain before the nested repeat check can loop. The
generated do instance wires its input/output handoff ports in the generated
top, waits on its own fresh done handoff, and does not clear the pending
generated-spawn done set that the later drain must consume.

The when-contained same-domain metadata `await_any`-before-do analogue is
also shipped: a repeat directly inside a top-level `when` body with multiple
generated spawns, a prior multi-pending
`(await_any done)` observation, static-parameter generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))` while those generated
spawns remain pending, and a later same-body `(await_all done)` drain before
the nested repeat check can loop. The shipped contract records declared
same-domain ownership metadata for the generated do instance and generated
children without implying CDC or cross-domain activation.

The switch-contained same-domain metadata `await_any`-before-do analogue is
also shipped: a repeat directly inside a top-level `switch` branch with
multiple generated spawns, a prior
multi-pending `(await_any done)` observation, static-parameter generated
blocking `(do child (params ...) [(bind ...)] (domain NAME))` while those
generated spawns remain pending, and a later same-body `(await_all done)`
drain before the nested repeat check can loop. The shipped contract mirrors
the shipped when-contained domain proof and records declared same-domain
ownership metadata without implying CDC or cross-domain activation.
The top-level `when` body nested repeat local do before post-do multi-pending
`await_any` subset is also shipped: a repeat directly inside a top-level
`when` body with multiple generated spawns, local blocking `(do child)` while
those generated spawns remain pending, `(await_any done)` after the local do
as an observation point, and a later same-body `(await_all done)` drain before
the nested repeat check can loop. The top-level switch branch nested repeat
local do before post-do multi-pending `await_any` subset is shipped with the
same contract for a repeat directly inside a top-level `switch` branch while
generated nested spawns remain pending before the same-body `await_all` drain:
the local child still completes through the parent scheduled module, and the
post-do `await_any` observes only the pending generated-spawn done set
without clearing it. The top-level `when` body nested repeat plain
generated-child `(do child)` before post-do multi-pending `await_any` subset
is shipped as well: a repeat directly inside a top-level `when` body with
multiple generated spawns, a plain generated-child blocking do while those
generated spawns remain pending, post-do `(await_any done)` as an observation
point, and a later same-body `(await_all done)` drain before the nested
repeat check can loop. The generated-child do waits for its deterministic
generated do instance's fresh done handoff, and the post-do `await_any`
observes only the pending generated-spawn done set without clearing it.
The switch-contained generated-child post-do `await_any` analogue is now
shipped with the same generated-child and later-drain contract: a repeat
directly inside a top-level `switch` branch may run a plain generated-child
blocking do while multiple generated spawns remain pending, then use post-do
`(await_any done)` as an observation point before the later same-body
`(await_all done)` drain. The top-level `when` body static-parameter
generated-do post-do `await_any` analogue is also shipped: a repeat directly
inside a top-level `when` body may run `(do child (params ...))` while
multiple generated spawns remain pending, then use post-do
`(await_any done)` as an observation point before the later same-body
`(await_all done)` drain. The generated do preserves static generated-top
parameter binding, waits for its deterministic generated do instance's fresh
done handoff before that observation, and leaves the pending generated-spawn
done set live for the later drain. The direct switch-contained
static-parameter generated-do post-do `await_any` analogue is also shipped:
a repeat directly inside a top-level `switch` branch may run
`(do child (params ...))` while multiple generated spawns remain pending,
then use post-do `(await_any done)` as an observation point before the later
same-body `(await_all done)` drain. It uses the same deterministic generated
do instance, preserves the static generated-top parameter binding, waits for
that generated do instance's fresh done handoff before the observation, and
leaves the pending generated-spawn done set live for the later drain. The
when-contained bound generated-do post-do `await_any` subset is now shipped:
a repeat directly inside a top-level `when` body may run
`(do child (params ...) (bind ...))` while multiple generated spawns remain
pending, then use post-do `(await_any done)` as an observation point before
the later same-body `(await_all done)` drain. That subset wires the
generated-top input/output binding handoffs for the generated do instance,
requires that instance's fresh done handoff before the observation, and
leaves the pending generated-spawn done set live for the later drain. Domain
metadata on generated-do post-do `await_any`, the switch-contained bound
analogue, new spawn after the do before the drain, cross-domain activation,
deeper branch/loop nesting, and broader outstanding-child semantics remain
backlog until their own leaves select and ship them.

Dynamic repeat counts are compatible with this model because `count` is a
runtime counter load value, not an elaboration count. They do make loop latency
data-dependent, and the repeat contract still needs an explicit zero-count
policy for the fully general case.

## Intent Scheduling Format

### Actor Network Orchestration

Status: active ATL design tree; static metadata, scalar handoffs, bounded
temporary trigger-batch scheduling, parent trigger/event handoffs, and
resolved child `.fsm` artifact emission are shipped under the selected ATL v0
public contract.
Task-tree owner:
[ISF-ACTOR-NETWORK-ORCHESTRATION](../../tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).
Concrete design proposal:
[ISF_ATL_DESIGN_PROPOSAL](../../ISF_ATL_DESIGN_PROPOSAL.md).

Goal: move ISF up one abstraction level while staying in explicit `.isf`.
The working name is Actor Transfer Level (`ATL`): where RTL describes data
movement between flops/registers, ATL describes data, information, and
activation movement between actors. The actor is the transfer endpoint.

The intended source model is a top-level actor whose structure/content is a
static actor network. Transactions and rules in the top-level actor can
trigger actors or transactions inside the network. Actor instances can
synchronize on scheduler-visible events, move data to other actors, move data
within concurrent actor groups, and move data between actors and the
top-level pins. FSMGen owns scheduling and lowering to explicit `.fsm`, with
the inferred schedule remaining reviewable.

The syntax should stay intent-expressive and should also have a verbose
variant for maximum readability, so the network topology, orchestration,
data movement, and generated schedule evidence can be reviewed without
reading lowering code.

Current ATL v0 proposal:

The top-level root remains `(actor name ...)`. The first metadata-only
implementation slices are shipped: static actor instances may be declared with
the direct actor-level `(instance NAME of ACTOR_TYPE)` clause, and static
concurrent groups may be declared with direct actor-level
`(group NAME (members ACTOR...) (mode concurrent))` clauses.
The enclosing actor is the network boundary; `(network ...)` is not part of
the shipped source surface. The accepted form lowers to parser shell and
schedule-report metadata under `actor_network` with `declaration: "actor"`.
Unqualified static instances remain metadata-only external intent.
Library-qualified static instances now resolve to report metadata and emit
their resolved child scheduled `.fsm` artifacts; they still do not emit a
generated ATL top, infer parent/child handoff wiring, schedule groups, or wire
HDL. Multiple instances outside the shipped
scalar handoff and report-only group metadata subsets, broader event/trigger
behavior beyond the single parent-handoff subsets, and wider endpoint movement
remain backlog.
Actor-to-actor and pin-to-actor movement is not expressed as top-level
`connect` clauses. The selected ATL v0 proposal reuses existing drive
definitions and drive calls: a drive body keeps its shipped `(sink source)`
assignment-pair order, while ATL widens `sink` and `source` to qualified actor
endpoints and top-level pins. FSMGen discriminates endpoint roles during
scheduling; the source does not add a new movement keyword.
The rationale is uniform ISF syntax: ATL should not make downstream emitters
or users learn a second data-movement form when existing drive bodies and
drive calls can carry the same intent.
The first `.5` data-movement implementation sequence shipped fail-closed
reservation for unsupported endpoint drive-body pairs, then shipped the first
generated scalar actor-to-actor handoff subset. The shipped subset is exactly
two direct static actor instances, one named drive body with one
`(sink_actor.endpoint source_actor.endpoint)` pair, and one top-level
transaction drive call. It emits one-bit external parent handoff ports named
`source_actor_source_endpoint` and `sink_actor_sink_endpoint`, uses a
one-cycle route lifetime, and reports through
`actor_network.data_movements[]`.
Storage, muxing, generated child `.fsm` artifacts, generated ATL tops, HDL
child wiring, broader pin movement, inline/expression movement,
fan-in/fan-out, groups, CDC, and trigger/await coupling remain separate
backlog leaves.
The first pin-movement subsets are shipped in both scalar directions:
top-level input pin to actor endpoint as `(actor.endpoint pins.input_pin)`,
and actor endpoint to top-level output pin as
`(pins.output_pin actor.endpoint)`. Each shipped direction accepts one named
drive body, one direct static actor instance, one top-level transaction drive
call, and one-bit top-level pins only. Wider pin payloads and mixed
pin/actor movement in one drive remain later leaves.
The selected orchestration vocabulary reuses existing ISF activation forms:
`(do actor.transaction)` for blocking actor transaction activation,
`(spawn actor.transaction as NAME)` for nonblocking activation,
`(trigger actor.transaction)` for rule-level or transaction-body activation,
and `(await actor.event)` for one-cycle actor event synchronization. Only the
bounded transaction-body trigger and event-wait parent-handoff subsets are
shipped today. Event payloads are not part of ATL v0. Concurrent groups use
`(group NAME (members ACTOR...) (mode concurrent))` as schedulable intent,
not as a bypass for ordering, fan-in, width, lifetime, or CDC safety. The
group axis starts with shipped fail-closed diagnostics for direct `(group ...)`
declarations and compact `(concurrent ...)` aliases. Report-only static group
metadata is shipped for verbose `(group ...)`; scheduling behavior and compact
aliases remain later leaves.
The first multi-actor trigger scheduling leaf is shipped as a same-cycle
external trigger batch over existing transaction-body
`(trigger actor.transaction)` clauses: one contiguous batch, distinct static
actor instances, generated external trigger outputs pulsed from one parent
state, and `actor_network.association_schedules[]` report evidence. Static
`(group ...)` declarations are not required and remain review metadata only.
Noncontiguous batches, repeated members, generated children, group endpoints,
data-movement coupling, multi-event fan-in, route mux/storage, CDC, and
compact aliases remain later leaves.

The compatibility `actor_network.group_schedules[]` array remains for schedule
JSON `schema_version: 1`. The canonical association entry uses
`kind: "temporary_trigger_batch"` and `lifetime: "task_scoped"`. This report
contract does not add source syntax or generated HDL behavior.

The first realistic ATL fixture is shipped as
`isf/atl_trigger_batch_pipeline.isf`. It is deliberately bounded to already
shipped surfaces: three direct static actor instances and one contiguous
transaction-body trigger batch. It proves scheduled `.fsm`, strict schedule
JSON, and HDL reachability coverage. It does not claim peer event
synchronization, endpoint data movement, generated ATL child artifacts,
generated ATL tops, group endpoints, compact aliases, CDC, route mux/storage,
payloads, ready/backpressure, trigger/data/event coupling, or permanent actor
grouping.

The scalar data-route ATL fixture is now shipped as
`isf/atl_data_route_pipeline.isf`. It uses the already shipped scalar
actor-to-actor data movement surface: two direct static actors, one named
drive body with `(consumer.payload producer.payload)`, and one transaction
drive call. The fixture proves generated parent handoff ports,
`actor_network.data_movements[]` route metadata, empty association/group
schedule arrays, strict schedule JSON, and plain plus strict HDL reachability
without claiming generated children, route mux/storage, trigger/data coupling,
wider payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent
grouping.

The scalar pin-ingress ATL fixture is now shipped as
`isf/atl_pin_ingress_pipeline.isf`. It uses the already shipped scalar
top-level input-pin to actor movement surface: one direct static actor, one
top-level input pin `payload`, one named drive body with
`(consumer.payload pins.payload)`, and one transaction drive call. The fixture
proves the existing top-level pin as the source, generated actor handoff
output `consumer_payload`, `actor_network.data_movements[]` route metadata
with kind `scalar_pin_to_actor_handoff`, strict schedule JSON, and plain plus
strict HDL reachability without claiming actor-to-pin egress, bidirectional
pin movement, generated children, route mux/storage, trigger/data coupling,
wider payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent
grouping.

The scalar pin-egress ATL fixture is now shipped as
`isf/atl_pin_egress_pipeline.isf`. It uses the already shipped scalar
actor-to-top-level output pin movement surface: one direct static actor, one
top-level output pin `result`, one named drive body with
`(pins.result producer.payload)`, and one transaction drive call. The fixture
proves the generated actor source handoff input `producer_payload`, existing
top-level output sink `result`, `actor_network.data_movements[]` route
metadata with kind `scalar_actor_to_pin_handoff`, strict schedule JSON, and
plain plus strict HDL reachability without claiming bidirectional pin
movement, generated children, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent grouping.

The ATL trigger-wait fixture is now shipped as
`isf/atl_trigger_wait_pipeline.isf`. It uses the shipped parent handoff
subsets rather than generated child wiring: one static actor `worker`, one
`(trigger worker.process)` one-cycle output handoff, one following
`(await worker.done)` event input wait, and one completion pulse. The fixture
proves single-actor orchestration sequencing, strict schedule JSON, and plain
plus strict HDL reachability without claiming temporary trigger-batch plus
event coupling, multiple waits or triggers, generated children, generated ATL
tops, actor type resolution, HDL child wiring, data movement coupling,
fan-in/fan-out, CDC, ready/backpressure, or permanent grouping.

The ATL trigger-batch wait fixture is now shipped as
`isf/atl_trigger_batch_wait_pipeline.isf`. It couples the shipped temporary
trigger-batch surface to one following actor event wait: a parent transaction
triggers reader, filter, and writer in one same-cycle batch, waits on
`writer.done`, then completes. The fixture proves parent-level
trigger-batch/event sequencing, strict schedule JSON, and plain plus strict
HDL reachability without claiming multiple event waits, actor-event fan-in,
generated children, generated ATL tops, actor type resolution, HDL child
wiring, data movement coupling, CDC, ready/backpressure, or permanent
grouping.

The multi-event fan-in boundary is regression-backed. A parent transaction
that emits one temporary trigger batch and then attempts two actor event waits
remains outside the shipped subset; the second wait fails before scheduled
emission with the current one-event-wait diagnostic, and production behavior
is not widened.

The ATL source-root boundary is shipped before generated child resolution. A
sibling top-level `(actor ...)` root in the same `.isf` source fails closed
until FSMGen has an explicit actor type-resolution and generated child
artifact contract. Same-source `(library ...)` roots remain accepted.

The explicit actor type-resolution source contract is now selected for future
ATL leaves. Resolved static actor types use the library-qualified form
`(instance NAME of ALIAS.EXPORT)`, where `ALIAS` is declared by the enclosing
actor's `(imports (library ... as ALIAS))` clause and `EXPORT` is an actor
export from that library. Unqualified `(instance NAME of ACTOR_TYPE)` remains
metadata-only external intent until a later leaf widens it, and sibling actor
roots remain rejected. Existing `(use alias.actor as instance ...)` remains
the separate reusable-library generated-top surface with explicit bindings.
The targeted fail-closed reservation for the qualified ATL syntax is now
shipped: missing imports, non-explicit import aliases, unknown aliases,
and unknown exports still fail before scheduled `.fsm` emission. Resolved
qualified entries add `type_resolution`, `library`, `alias`, `export`,
`module`, and `scheduled_fsm` to resolved `actor_network.instances[]` entries
and now emit their child `.fsm` files. The first generated ATL top is shipped
for one resolved child plus one trigger/event handoff pair, and the scalar
pin-ingress route below is shipped for that same one-child top. Broader
generated ATL tops, HDL child wiring outside that selected pair plus scalar
pin-ingress route, interface binding inference, event fan-in,
route mux/storage, CDC, recursive actor networks, and ready/backpressure
remain later leaves.
The resolved-child fixture is now shipped as
`isf/atl_resolved_child_pipeline.isf`. It proves the generated-top boundary
with one same-source library actor export, one resolved child instance, one
parent trigger handoff, one parent event wait, exactly three lower-result
artifacts, strict schedule JSON parity, and generated parent/child handoff
wiring through `atl_resolved_child_pipeline_top.fsm`.
HDL promotion for that resolved-child shape is shipped. It keeps the source
and report schema unchanged and proves plain plus strict CLI SystemVerilog
generation contains the generated top, scheduled parent, resolved child, and
selected internal trigger/event links.
The first generated-child data-route slice is shipped as one scalar top-level
input-pin route into one resolved child through the generated top, written as
`(worker.payload pins.payload)` in a named drive body. The fixture
`isf/atl_resolved_child_pin_ingress_pipeline.isf` proves parent/child/top
artifacts, generated-top wiring, route metadata, child input port
preservation, and plain plus strict HDL generation. Actor-to-actor
generated-child routes, actor-to-pin routes, multi-child tops,
route mux/storage, CDC/reset remapping, ready/backpressure, and payload
protocols remain deferred.

The first actor-event implementation boundary is a generated parent-handoff
wait, not full child orchestration. FSMGen accepts exactly one top-level
transaction-body `(await actor.event)` when the qualifier names a declared
direct static actor instance. The wait may stand alone for a single static
actor, or follow one selected same-cycle temporary trigger batch. That wait
lowers to a deterministic one-bit parent handoff input named `actor_event`;
for example, `reader.done` maps to `reader_done`. The scheduled parent `.fsm`
exposes and waits on that input, and schedule JSON records the wait under
`actor_network.event_waits[]`.

The producer of that pulse remains external until later ATL leaves resolve
actor types, generate child artifacts, emit ATL tops, and support qualified
actor transaction triggers. Multiple waits, nested waits, fan-in, fan-out,
event payloads, cross-clock events, and concurrent group events stay
fail-closed/deferred. Existing unqualified local forms stay unchanged:
`(await signal)` remains a transaction wait, and rule-level
`(trigger transaction)` remains a local transaction trigger. Dotted
enum-looking names that do not name a static actor instance keep their prior
diagnostics.

The shipped qualified actor-transaction trigger subset mirrors that handoff
boundary. One top-level transaction-body `(trigger actor.transaction)` against
a direct static actor instance lowers to a generated one-cycle parent output
named `actor_transaction_start`; for example, `reader.capture`
maps to `reader_capture_start`. The scheduled parent `.fsm` exposes and
pulses that output at the trigger point, and schedule JSON records the
trigger under `actor_network.transaction_triggers[]`.

The trigger sink remains external until later ATL leaves resolve actor types,
generate child artifacts, emit ATL tops, and add ready/backpressure or payload
semantics. Rule-level qualified triggers, nested triggers, repeated triggers
to the same actor instance, generated handoff signal conflicts, fan-in,
fan-out, cross-clock triggers, and broader concurrent group behavior stay
fail-closed/deferred.

Direct actor-body proposal:

```lisp
(actor packet_pipe
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input  start)
    (input  in_data  (width 32))
    (output out_data (width 32))
    (output done))

  (instance reader of packet_reader)
  (instance crc    of crc32_unit)
  (instance writer of packet_writer)

  (group pipeline
    (members reader crc writer)
    (mode concurrent))

  (drive feed_reader
    (reader.data_i pins.in_data))

  (drive feed_crc
    (crc.payload reader.payload))

  (drive feed_writer
    (writer.crc crc.result))

  (drive publish_output
    (pins.out_data writer.data_o))

  (transaction run_packet
    (on start)
    (drive feed_reader)
    (trigger reader.capture)
    (await reader.done)
    (drive feed_crc)
    (trigger crc.compute)
    (await crc.done)
    (drive feed_writer)
    (trigger writer.emit)
    (await writer.done)
    (drive publish_output)
    (complete done)))
```

Proposed endpoint vocabulary:

| Endpoint | Meaning |
| --- | --- |
| `pins.name` | Top-level actor interface pin. |
| `actor.port` | Interface port on an actor instance. |
| `actor.transaction` | Transaction on an actor instance. |
| `actor.event` | Scheduler-visible one-cycle event from an actor instance. |
| `group.name` | Explicit concurrent group. |

Proposed semantic split:

| Form | Meaning |
| --- | --- |
| Drive body pair `(sink source)` | Selected ATL v0 movement source shape: existing drive-body assignment order with widened endpoint names. |
| Drive call `(drive name args...)` | Existing timing point that activates the drive body. |
| `transfer source sink` / `move source sink` | Not planned for ATL v0; possible later ergonomic sugar only if drive-body reuse proves inadequate. |
| `event` | Named one-cycle control pulse; payloads remain deferred. |
| `trigger` | Activation of a qualified actor transaction. |
| `group` | Intentional concurrent actor group for scheduling analysis/reporting. |

The ATL v0 movement proposal reuses existing drive bodies, for example
`(drive feed_crc (crc.payload reader.payload))`, where `crc.payload` is the
sink and `reader.payload` is the source. The scheduler knows whether the
source, the sink, or both are actor-interface endpoints or top-level pins, and
it derives the required routing/handoff plan. Directional symbolic aliases
such as `=>` are not preferred because they can look like physical routing
instead of intent-level movement.

The movement action is not intended to mean permanent actor-to-actor wiring.
The RTL analogy is a mux feeding a flop: the sink actor is like the flop D
input, and source actors are like mux data inputs. Several source actors may
be allowed to provide the same information to a sink actor at different
scheduled moments, but FSMGen must infer or reject the actual movement based
on the drive body's `(sink source)` pair, the drive-call timing point,
triggers, sink-valid conditions, disjoint timing, and any generated
mux/enable/handoff plan. The scheduler derives the connectivity; the source
does not need a separate `connect` clause for actor-to-actor movement.
The author should not have to hand-author routing. FSMGen owns the runtime
route-select control, mux selects, enables, and handoffs that dynamically move
information between actors once the scheduled interaction is inferred.

Current boundary: ISF actors currently decompose into actor-local
transactions, rules, stages, resources, storage, and generated child
transaction activations. They now define public actor-network source surfaces:
static actor instance declarations, library-qualified resolved child
artifacts, and report-only static group declarations recorded as
`actor_network` metadata. Resolved ATL child `.fsm` files are emitted, but the
ATL generated-artifact contract still excludes generated ATL tops, route
muxes, handoff storage, child HDL wiring, and inferred child interface
bindings. Event pulse semantics, actor-to-actor and pin-to-actor data
movement, concurrent actor-group scheduling, global versus local scheduling
ownership, generated top names, report visibility beyond the shipped
actor-network metadata, compact aliases, and broader fail-closed
boundaries remain under task-tree ownership. This direction is still IAL1 if
the source remains explicit actor/network `.isf` syntax with
scheduler-visible events, bindings, and constraints. It becomes an IAL2
candidate only if the source model moves above explicit ISF actor/network
syntax into protocol/platform intent inference.

### IAL2 Protocol And Platform Intent Exploration

Status: backlog.

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). A future `IAL2`
would need to justify itself with semantics above individual transactions, not
only syntax convenience. The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

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
`list`/`record` aliases on actor-owned storage variables only. Actor bodies may
carry `(types ...)` declarations whose payloads map directly to `.fsm`
`+types`; existing `.fsm` packages may be referenced with `(imports (package
shared_pkg) ...)`; and declarations may use `(type NAME)` instead of `(width
N)`, where `NAME` is local (`byte`, `frame_t`) or package-qualified
(`shared_pkg.byte`, `shared_pkg.frame_t`). Lowered scheduled `.fsm` preserves
`+types`, `+import`, typed `+size` entries, and embedded imported package roots
so the review artifact and CLI HDL generation stay self-contained. Actor-local
`(enums ...)` declarations are accepted as declaration artifacts and preserved
as scheduled `.fsm` `+enums`. Actor constants may now consume enum members
with local `mode.BUSY` or package-qualified `shared.mode.BUSY` spelling; the
authored token is preserved in scheduled `.fsm` `+constants` and schedule
reports, while the resolved non-negative integer value feeds static wait
lowering and existing static activation-parameter overrides.

The implementation path remains task-tree-managed. The current shipped subset
also continues to accept numeric/exact-width parameter values, scalar actor
parameter defaults backed by local or package-qualified enum members,
actor aggregate/list parameter default leaves backed by local or
package-qualified enum members,
generated child transaction scalar parameter defaults backed by local or
package-qualified enum members,
generated child transaction aggregate/list parameter default leaves backed by
local or package-qualified enum members,
actor-local constants for selected static specialization values, and
compatible aggregate/list literal parameter values. Scalar activation parameter
overrides and scalar leaves inside activation aggregate/list parameter override
values may now also consume local and package-qualified enum members. Direct
transaction `set` RHS scalar values and scalar operands inside transaction
`set` RHS expressions may consume local and package-qualified enum members,
transaction `when`/`while`/`until` condition expressions may consume local and
package-qualified enum members as scalar operands. Direct transaction
`when`/`while`/`until` scalar conditions may now consume local and
package-qualified enum members too, such as
`(when mode.BUSY (set fire 1))`, `(while mode.BUSY (set busy 1))`, or
`(until shared.mode.BUSY (complete done))`; those dotted standalone condition
tokens lower through computed `.fsm` selector syntax such as `?(mode.BUSY)` or
`?(shared.mode.BUSY)`.
Transaction `switch` selectors and branch values may consume local and
package-qualified enum members, scalar rule assignment RHS values and scalar
operands inside rule assignment RHS expressions and scalar operands inside rule
guard expressions may consume local and package-qualified enum members, and
scalar drive body RHS values or scalar operands inside drive body RHS
expressions may consume local and package-qualified enum members. Named
drive-call scalar actual values may also
consume local and package-qualified enum members, and drive-call actual
expressions may use enum members as scalar operands. Inline drive assignment
RHS scalar values and scalar operands inside inline drive RHS expressions may
now also consume local and package-qualified enum members. Reusable-library
use-site parameter override values and aggregate/list leaves may consume local
and package-qualified enum members too, resolving to literal generated-top
bindings and `library_uses[]` report values.
Transaction `set` RHS clauses may read scalar aggregate leaves from declared
aggregate storage carriers, such as
`frame.mode` or `lanes[0]`, either directly or as scalar operands inside
transaction `set` RHS expressions. Direct transaction `set` targets may write
scalar aggregate leaves on those same carriers, such as `(set frame.flag
flag_in)` or `(set lanes[0] bit_in)`. Rule assignment scalar RHS values may
read scalar aggregate leaves directly or as scalar operands inside RHS
expressions, such as `(set mode_out (+ frame.mode mode_in))` inside a rule
body. Rule guard expressions may read scalar aggregate leaves as operands, such
as `(rule fire (& ready frame.flag) (set seen 1))`, and standalone rule guards
may read scalar aggregate leaves directly, such as
`(rule fire frame.flag (set seen 1))`. Transaction
`when`/`while`/`until` conditions may read scalar aggregate leaves directly or
as operands inside condition expressions, such as
`(when frame.flag (set seen 1))` or
`(when (& ready frame.flag) (set seen 1))`. Direct aggregate condition leaves
lower through computed `.fsm` selector syntax. Transaction
`switch` selectors and branch values may read scalar aggregate leaves, such as
`(switch frame.mode (1 (set seen 1)) (default (set seen 0)))` or
`(switch mode_in (frame.mode (set seen 1)) (default (set seen 0)))`; selector
leaves lower through computed `.fsm` selector syntax. Named drive body
scalar RHS values and scalar operands inside RHS expressions may read scalar
aggregate leaves, such as `(drive publish (mode_out frame.mode))` or
`(drive publish (mode_out (+ frame.mode mode_in)))`. Named drive body targets
may write scalar aggregate leaves, such as
`(drive capture (frame.mode mode_in))` or
`(drive capture (lanes[1] pair_in))`. Named drive-call scalar
actual values and scalar operands inside actual expressions may read scalar
aggregate leaves, such as `(drive publish frame.mode)` or
`(drive publish (+ frame.mode mode_in))`. Inline drive assignment scalar RHS
values and scalar operands inside RHS expressions may read scalar aggregate
leaves, such as `(drive inline_publish (mode_out frame.mode))` or
`(drive inline_publish (mode_out (+ frame.mode mode_in)))`. Inline drive
targets may write scalar aggregate leaves, such as
`(drive inline_capture (frame.mode mode_in))` or
`(drive inline_capture (lanes[1] pair_in))`. Aggregate member
paths outside transaction `set` RHS values, direct transaction `set` targets,
transaction condition scalar values/expression operands, transaction `switch`
selectors/branch values, rule assignment target tokens, rule assignment RHS
values/expression operands, rule guard scalar values/expression operands, drive target
tokens, drive body RHS scalar values/expression operands, inline drive target
tokens, inline drive assignment RHS scalar values/expression operands, or
drive-call actual scalar values/expression operands, subaggregate
operands/updates, aggregate
interface or transaction ports, aggregate storage banks, enum member
references outside actor constants, actor parameter scalar
values or aggregate/list default leaves, generated child transaction scalar
parameter defaults or aggregate/list default leaves, activation parameter
scalar values or aggregate/list override leaves, reusable-library use-site
parameter override values or leaves, transaction `set` RHS scalar
values/expression operands, transaction `when`/`while`/`until` condition
scalar values/expression operands, transaction `switch` selector/branch values,
rule guard scalar values/expression operands, scalar rule assignment RHS values
or expression operands, or drive body RHS scalar values/expression operands, inline drive
assignment RHS scalar values/expression operands, or drive-call actual scalar
values/expression operands, aggregate field/slice/update lowering, and broader
aggregate shape inference require future task-tree ownership before they can
ship.

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
resource-user validation for `rule_slot`. The scheduler now enforces the first
resource kind: `rule_slot`, a one-cycle mutual-exclusion slot where each bound
rule requests when its guard is true, the priority graph chooses a unique
active winner, and the generated grant gates the whole rule DT DTE without
adding a cycle.
The resource-kind catalog is owned in code by
`FSM::Support::ISFResourceCatalog` and exposed through the machine-readable
ISF public contract, so downstream consumers can distinguish shipped resource
behavior from parser-recognized backlog names without scraping prose.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | One-cycle mutual exclusion for rule users under the `priority` arbiter. |
| `output_bundle` | backlog | One-cycle ownership of a group of actor outputs or LHS targets. |
| `interface_bundle` | backlog | Ownership of a protocol-facing interface or bus bundle. |
| `named_drive` | backlog | Ownership of a reusable actor `(drive ...)` body or drive-call path. |
| `transaction_start` | backlog | Arbitration for start/request fan-in into one transaction. |
| `child_instance` | backlog | Re-entry control for a spawned child instance. |
| `storage_port` | backlog | Arbitration for shared state, register, memory, or storage-port access. |

Remaining backlog: non-`rule_slot` resource kinds, `round_robin`, transaction
lifetime ownership, named-drive users, output-target users, multi-capacity
resources, and dynamic resource names remain backlog until their reset,
hold/release, fairness, and diagnostic contracts are explicit.

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
with the inverse active rule condition. Priority cycles, incomparable rule
conflicts, unordered rule/transaction conflicts, and mixed timing conflicts
fail closed.
Rule/drive overlap is still tracked because compile-time proof is not doable.
Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction-over-rule priority, drive/rule arbitration
policy, and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: shipped for ordinary flopped rule assignments.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(set port expr)`, `(port expr)`,
`(trigger transaction)`, and `(priority over other_rule)`. Trigger targets and
priority targets remain scalar-only today. `(set port expr)` is the canonical
explicit setter; `(port expr)` remains shorthand. Both lower as flopped `<-`
rule assignments under the rule DT DTE, where `expr` may be a scalar token or
one list expression from the transaction `set`/`update`/`.fsm` RHS expression
domain. Direct scalar rule assignment RHS values and scalar operands inside RHS
expressions may use local or package-qualified enum members. Direct scalar rule
assignment RHS values and scalar operands inside RHS expressions may also read
scalar aggregate storage leaves such as `frame.mode` or `lanes[1]`. Rule
assignment targets may write scalar aggregate storage leaves such as
`frame.mode` or `lanes[1]`. Rule guard expressions may use enum members as
scalar operands and may read scalar aggregate storage leaves such as
`frame.flag`. Standalone scalar enum and scalar aggregate rule guards are
shipped in both shorthand and long-form `(when ...)` rule syntax, such as
`(rule fire mode.BUSY (set seen 1))` and
`(rule fire (when frame.flag) (set seen 1))`; they lower to guarded non-state
DT headers. The remaining backlog is aggregate paths in rule assignment RHS or
rule guard expression operator position, expression operator-position enum
members, enum rule targets, and subaggregate rule targets. Transaction
`switch` selectors and branch values may
read scalar aggregate storage leaves such as `frame.mode`, and selectors or
branch values may use enum members; subaggregate selectors/branch values remain
backlog. Named drive body scalar RHS values
and scalar operands inside RHS expressions may read scalar aggregate storage
leaves such as `frame.mode`, and named drive body targets may write scalar
aggregate storage leaves such as `frame.mode`; aggregate paths in drive body
RHS expression operator position and subaggregate drive targets remain backlog.
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
declared with `(params (NAME value) ...)` when they resolve to non-negative
integer literals. `wait 0`, constants that resolve to zero, and scalar actor
parameters that resolve to zero are transparent no-ops that emit no wait
state, consume no active transaction cycle, and create no report entry.
`wait 1` occupies one generated wait state for one active cycle and advances
on the next state transition; `wait N` contributes exactly `N` active cycles
wherever it executes, including inside `when`, `switch`, `repeat`, `while`,
and `until` bodies. The bounded runtime
surface accepts `(wait count_signal)` when `count_signal` has known unsigned
width and `(wait (<op> ...))` when all referenced operands have known widths
and the expression-width helper derives a positive result width.

The static lowering is a reviewable fixed scheduled-state chain. No hidden
wait counter is introduced for the static literal/constant/parameter surface.
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
Successful reports expose bounded `transaction_waits[]` entries with
transaction name, `cycles`, `count_kind`, `count_source`, entry state, exit
state, optional counter signal, and optional counter width. Static waits keep
an integer `cycles` and preserve the authored literal, actor constant name, or
actor parameter name in `count_source`; runtime scalar and runtime expression
waits keep `cycles` null and expose their source/counter metadata with
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
subsets plus independent bank-load, bank-store, top-level stage, and top-level
await-all/await-any sync, top-level spawn, top-level transaction phase, and
top-level contract-arm successor subsets,
repeat/loop pending-sample zero bypasses whose successor cannot yet carry
samples without changing timing, and setter successors that read or overwrite
a pending sample alias. Shift, assemble, extract, bank-load, and bank-store
successors are shipped only when independent; stage successors are shipped
only when the ready input and valid output are independent of the pending
sample alias; await-all/await-any sync successors are shipped only when their
collected done ports are independent of the pending sample alias; contract arm
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
Transaction `(ports ...)` declarations, scalar and expression-valued input
activation bindings, first actor-pin conflict/runtime coverage, and bounded
schedule-report binding provenance are shipped. The original
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
positive integer `(width N)`; omitted width means 1. The normalized public
transaction shell has `ports.inputs[]` and `ports.outputs[]` entries with
`name` and `width`. The declaration is not a scheduler body clause; behavior
comes from transaction states/rules that use the port and activation sites
that bind it.

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
non-empty list expressions. Scalar and known-width expression sources are
width-checked against the transaction input port; unknown expression widths
continue through the downstream `.fsm` expression validation path. Local `do`
lowers input bindings in the state that starts the child and copies output
bindings under the generated child-done guard. Parameterized/generated `do`
lowers through explicit generated-top handoff ports and a parent-owned
`do_port_binding` DT whose output copy is done-gated. `spawn` lowers through
hidden generated-top handoff ports and reviewable parent binding DTs; actor
signals consumed by explicit spawn input-binding expressions are not also
same-name wired into the child instance. Rule `trigger` supports input
bindings only; each rule owns a distinct payload source and the trigger fan-in
DT routes payloads under the matching per-rule trigger pulse.
Rule-trigger output bindings, explicit snapshot-vs-live timing selection,
richer report fields, and broader static conflict diagnostics remain backlog.

Actor pin binding now uses the same assignment/conflict path as ordinary ISF
drives where it has shipped coverage. Spawn output bindings carry parent
transaction ownership in provenance, so a spawned child output bound to an
actor output conflicts with a same-target rule writer through the existing
rule/transaction diagnostics. Accepted spawn-output fan-in and rule-trigger
input payload fan-in remain visible as normal `.fsm` same-LHS assignments and
reach the SystemVerilog backend's verification-only selector checks.

Successful schedule reports now expose bounded `transaction_port_bindings`
entries for the shipped binding surface. Each entry records the binding site
kind, owner, target transaction, direction role, port, scalar actor signal
when applicable, formatted actor expression, width, and generated handoff names
where they exist. This is a public summary for downstream tooling, not the raw
binding or assignment-provenance internals.

### Temporal Contract Lowering

Status: partially shipped; broader contract forms remain backlog.

Goal: lower transaction `(contract ...)` temporal assertions into generated
checks or equivalent scheduled artifacts.

Shipped subset: a top-level transaction contract of the preferred form
`(contract name (eventually signal within cycles))`. The older nested
`(eventually signal (within cycles))` spelling remains accepted as an alias.
Reaching the clause emits one arm state; the generated scheduled `.fsm`
monitor tracks pending/age/fail storage, clears on actor reset, and sets a
sticky fail bit if the signal is not seen within the window or if the same
contract is armed again while pending.

SystemVerilog generation now projects the sticky fail bit into a
verification-only assertion under `` `ifndef SYNTHESIS``; Verilog output stays
assertion-free. Remaining backlog: global `always` implication forms, min/max
windows, dynamic bounds, same-cycle checks, nested contracts, expression
operands, and multiple outstanding obligations.
The file-backed `isf/stream_stage_contract.isf` fixture covers the shipped
top-level ready/valid stage plus bounded eventual contract path through
strict schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, temporal monitor storage roles, and SystemVerilog sticky-fail
assertion projection.

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

Current boundary: `shift_left` and `shift_right` accept `(width N)` and
`extract` accepts `(widths N...)` as explicit assertions. `shift_left` uses
the optional width only as register-width evidence; plain widthless
`shift_left` remains accepted because no insertion-position width is needed.
`extract` also infers exactly one missing destination field width when the
source word width and all sibling field widths prove one positive remainder;
two or more unknown fields remain backlog. `extract` fails closed instead of
emitting placeholder slice bounds when field positions cannot be proven, the
inferred remainder is not positive, or field totals conflict with known source
width. `shift_right` now fails closed when width evidence is missing or
conflicts with an explicit option. `assemble` infers exactly one missing part
width when the target width and all sibling part widths prove one positive
remainder; two or more unknown parts remain backlog for inference and are
accepted only as non-evidence concat operands. `assemble` also rejects known
target-width mismatches and non-positive single-part inferred remainders.
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
`activation_start_handoff`, `watchdog_counter`, `latency_counter`,
`repeat_counter`, `dynamic_wait_counter`, `drive_request`, `drive_payload`,
`sample_alias`, `extract_field`, `data_register`, `completion_pulse`,
`temporal_contract_monitor`,
`rule_trigger_source`, `rule_trigger_payload_source`, `transaction_port`,
`transaction_port_binding`, and `trigger_done_observe`.
Declared typed actor-owned storage may also expose optional `type` and
`type_kind` summaries; those fields are bounded metadata, not raw type-spec
hashes.

Remaining direction: keep `role`, `type`, and `type_kind` additive and omit
them when evidence is ambiguous. Per-cycle resource-grant/debug storage remains
deferred because the shipped `rule_slot`/`priority` implementation exposes
static grant shaping through `resource_arbitration[]` and guard lowering
rather than materialized grant storage. Add a storage role only if future resource
lowering materializes such signals with compatibility rules, public contract
metadata, and regression coverage.

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

Current boundary: APB remains the quick/smoke ISF baseline for parse, scheduled
`.fsm` header, and public-contract checks. Broader realistic fixture coverage
belongs in the `isf` regression tier. The active matrix in
[ISF-FIXTURE-COVERAGE](../../tasks/ISF-FIXTURE-COVERAGE.md) now covers
`isf/spi_master.isf` as a bounded SPI-like mode-0 serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL
checks, and [ISF-I2C-FIXTURE-PROMOTION](../../tasks/ISF-I2C-FIXTURE-PROMOTION.md)
now covers `isf/i2c_master.isf` as a bounded I2C-like serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL
checks. These are not complete SPI or I2C protocol compliance suites. Future
fixture promotions should add stable structural assertions rather than full
HDL or full schedule JSON snapshots. The SPI-like and I2C-like fixtures
intentionally stay out of the quick/smoke tier for now; `quick` remains
APB-centered for fast turnaround.
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
delayed completion pulse behavior.
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
fixture, not a claim for parameter-driven interface/storage elaboration,
nested imports, standalone transaction/drive exports, arbitrary-depth
generated FIFOs, memory-array backend emission, or automatic non-zero reset
values.

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
a claim for multi-child ATL tops, broader HDL child wiring, inferred
interface binding, route mux/storage, actor-event fan-in, CDC,
ready/backpressure, recursive actor networks, or permanent actor grouping.
The follow-on `isf/atl_resolved_child_pin_ingress_pipeline.isf` fixture is now
promoted for one generated-top scalar pin-ingress route into that resolved
child, using `(worker.payload pins.payload)`, while broader generated-child
data routes remain backlog.

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

Current boundary: the first reusable ISF library import, same-name
and remapped generated-top system binding, actor-owned fixed-storage,
expression-valued rule-guard, disjoint-rule write, FIFO-controller matrix,
bank-access, and fixed FIFO
library fixture slices have shipped under
[ISF-LIBRARIES](../../tasks/ISF-LIBRARIES.md). Actor roots may import library roots, use
an exported actor, validate use-site parameters and explicit bindings, emit a
specialized child scheduled `.fsm` artifact, wire the library actor through a
generated top, reach SystemVerilog generation for the covered generated-top
path, project bounded `library_uses` schedule-report metadata, declare fixed
actor-owned state/banks, author rule fire predicates as expressions, accept
same-target rule writes when direct contradictory guard facts prove
disjointness, prove a depth-4 FIFO-controller same-cycle update matrix, and
author a reusable fixed-shape FIFO actor source with bank-backed accepted
push/pop data movement that reaches generated-top SystemVerilog. Clock/reset
name remapping now works through explicit generated-top links while keeping
the reusable actor's reset kind and polarity unchanged. This remapping is
still system-signal binding behavior; it does not imply CDC. Multi-clock,
asynchronous, and interacting clock-domain semantics are owned by the
separate shipped
[ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md) event-crossing surface
and its remaining backlog.

Shipped source model for actor exports:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Shipped use model for actor exports:

```lisp
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

Shipped specialization and binding model:

```lisp
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
values, derived parameter expressions, parameter-derived storage dimensions,
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

Shipped actor-owned storage model:

```lisp
(actor fifo
  (storage
    (var rd_ptr (width 2))
    (var wr_ptr (width 2))
    (var occupancy (width 3)))
  ...)
```

`(var name (width N))` declares one fixed-width internal actor scalar storage
value. `(variable ...)` is the verbose scalar-storage alias.
`(bank name (width N) (depth N))` remains the fixed-depth actor-owned storage
form. The FIFO-controller matrix does not use an internal bank, but the
shipped data-path probe now exercises a depth-4 bank through explicit
store/load access.

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
evidence; parameter-driven interface/storage elaboration remains future work.
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
scheduled `.fsm` clock/reset HDL contract.
Different clock signal names, library clock/reset bindings, and generated-top
system-port links are not CDC semantics by themselves.

The shipped boundary is tracked by
[ISF-CLOCK-DOMAINS](../../tasks/ISF-CLOCK-DOMAINS.md). The first fixture
hardening slice now adds
[isf/clock_domain_dual_event_crossing.isf](../../isf/clock_domain_dual_event_crossing.isf),
which covers two opposite-direction acknowledged event crossings in one
generated top with two CDC children, report metadata, and generated HDL.
Remaining backlog still needs richer CDC fixture matrices for payload-like
protocol actors, dual-clock FIFO-like actors, and broader reset/no-reset
combinations.

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

## Backends And Validation

### Full VHDL Backend

Status: backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI recognizes VHDL target spelling, but explicit VHDL
generation is not implemented.

### GHDL Validation

Status: backlog, behind active VHDL backend work.

Goal: add GHDL validation once there is an active VHDL backend.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set.
It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

## Embedding And Public APIs

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.
