# Composition Backlog

## Composition

### Shared-Datapath Contract

Status: shipped for bounded generated-FSM same-name families; broader
route/storage/protocol surfaces remain backlog.

Goal: turn compatible same-name generated-child output families into a clearly
bounded shared datapath with explicit contributor metadata, helper signals,
assertion hooks, and deterministic lifted runtime carriers where the current
contract can prove them.

Current boundary: FSMGen can infer shared-datapath candidates across multiple
realized `?fsmc` children when their output families have the same name,
width, interface type, and compatible declared type identity. The shipped
surface reports contributor identity, bound connection expressions,
contributor forward IR, selected output-drive families, peer-read endpoints,
top-output bindings, storage class, default lifted visibility, aggregate
enable families, conflict signals, and assertion metadata.

SystemVerilog generated composition tops emit helper source-enable,
aggregate-enable, same-value conflict, and multi-value conflict wiring, plus
verification-only shared-datapath guard assertions. Verilog targets keep the
metadata but do not emit SystemVerilog assertion syntax.

Registered families with a consistent reset value and usable composition
clock/reset can lift into `*_shared_next` and `*_shared_q` carriers for the
covered public-preserving peer-read, internal-only peer-read, mixed
public/internal, and public-fanout cases. Combinational families can lift into
`*_shared_comb` carriers for the covered public-preserving peer-read,
internal-only peer-read, and public-fanout cases without inventing state.

Remaining backlog: arbitrary route mux/storage, general fan-in/fan-out
protocols, ready/backpressure, payload protocols, dynamic scheduling,
external-RTL or standalone-DT contributors as shared datapath sources, mixed
registered/combinational runtime lifting, and broader shared-data movement
remain deferred until their route/storage/protocol, reusable-module,
portable-type, or architecture contract is explicit.

### Reusable Standalone-DT Modules

Status: shipped for bounded `?dt:name` roots and `?dtc` generated children;
broader reusable-module surfaces remain backlog.

Goal: make standalone-DT roots usable as reusable module-shaped sources with a
clear root/interface/lookup/system-port/arbitration contract.

Current boundary: direct `?dt:name` roots are supported. Compatibility aliases
`?mod:name` and `?module:name` are accepted outside strict child-source
checks, while strict `?dtc` child sources require canonical `?dt:name`.
Standalone-DT roots may contain multiple general DT blocks, expose explicit
`+system` metadata when sequential behavior needs clock/reset ports, and
report block-level enable families plus module-level enable-family metadata.

Grouped standalone-DT multi-drive targets are shipped in metadata. They report
target signal, mux/storage class, contributing DT block names, RHS values,
per-DT enable signals, grouped LHS enable signals, and onehot0 assertion
metadata. SystemVerilog direct `?dt` roots and realized `?dtc` children emit
bounded non-synthesis guard assertions from that metadata; Verilog keeps the
metadata without assertion syntax.

Composition tops aggregate realized `?dtc` children through
`composition_standalone_dt_children` and related count fields. Those exports
preserve stable instance/module/source identity, standalone-DT names, enable
families, grouped multi-drive targets, and forward IR summaries through
`module_info` and `intent_hir`.

Generated child source lookup is shipped for embedded roots, repeated
`--path DIR` roots, `FSMLIB`, and local source context. Named `?dtc:name`
children may omit the explicit source token and default it to `name`.

Remaining backlog: unnamed reusable roots such as bare `?dt:`, authored DT
enable-control syntax beyond the implicit block enable, reusable-module
interface/export rules beyond the current generated-child surfaces, broader
`--path`/`FSMLIB` lookup policy, declarative reusable packages, advanced
same-target merge/priority policy, external activation/deactivation, and
debug-reporting contracts remain deferred until one exact reusable-module,
lookup, package/import, enable-control, portable-type, or architecture
contract is selected.

### Top-Boundary Convention Widening

Status: shipped for bounded top-boundary same-name convention; broader
convention surfaces remain backlog.

Goal: keep composition authoring lightweight by inferring or adopting the top
boundary when one safe public interface exists, while preserving explicit
`?ports` and `?wiring` as local override and disambiguation surfaces.

Current boundary: single-child `C1` passthrough may infer the full top
interface when `?ports` is omitted or empty. Explicit-link `C2` / `C3` tops
may infer renamed top-boundary endpoints from `?wiring`, undeclared same-name
top inputs when compatible child inputs agree exactly, undeclared same-name
top outputs when one unique child output remains top-facing, and same-name
internal carriers when one producer and one or more sinks remain otherwise
unwired. Plain explicit top inputs may adopt same-name fanout, plain explicit
top outputs may adopt one unique same-name child output, and declared compact
`=name` or verbose `:same-name` ports use the C4 declared connect-by-name
contract. Explicit top outputs may also re-export compatible inferred internal
carriers.

Those paths are direction-, width-, type-, and declared-type-checked.
Explicit `?wiring` overrides convention locally, inferred internal carriers
stay internal by default, and composition provenance/reporting surfaces expose
declared, inferred, override, and blocked convention events.

Remaining backlog: interface bundles, protocol groups, broader hidden
child-to-child inference, automatic priority/merge/arbitration for same-name
conflicts, wider public re-export policy, and non-top-boundary convention
semantics remain deferred until one exact composition contract is selected.

### VHDL Generic-Map Lowering

Status: partially shipped; broader generic-map actuals and child families remain backlog.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL now
lowers bounded external-RTL scalar integer, metadata-backed one-bit sized
bitstring, and multi-bit sized bitstring overrides to `generic map` actuals,
such as `WIDTH => 16`, `ENABLE_DEFAULT => '1'`, and
`RESET_VALUE => "10100101"` for `8'hA5`, before the instance `port map`.
Resolved scalar integer expressions also lower to VHDL expression actuals, such
as `EXPR_WIDTH => (16 + 1)`.
Resolved packed aggregate actuals also lower after they become multi-bit packed
values, such as `LANES => "1010010100111100"` and `FRAME => "101"`.
Qualified imported package constants in that same bounded external-RTL subset
are resolved before VHDL emission and also emit literal actuals, for example
`param_pkg.WIDTH_16` and `param_pkg.RESET_A5` emit `WIDTH => 16` and
`RESET_VALUE => "10100101"` without leaking `param_pkg` into the VHDL. This is
not VHDL package declaration/emission support. The shipped composition
VHDL tops are the bounded C3 external-RTL literal/concat fixture in
`t/corpus/composition_intent_integer_literals.fsm` and the bounded C1
standalone-DT passthrough fixture in
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, plus the bounded C2
generated-FSM scalar-autowire fixture in
`t/corpus/implicit_composition_system_autowire.fsm`, plus the bounded APB/C4
generated-FSM fixture in `fsm/apb_tb.fsm`. The bounded C2 generated-FSM family
also lowers scalar integer generic maps before the generated child port map,
such as `WIDTH => 16`, and scalar expression generic maps such as
`EXPR_WIDTH => (16 + 1)`, one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'` for `ENABLE_DEFAULT 1'b1`, multi-bit sized bitstring
generic maps such as `RESET_VALUE => "10100101"` for `RESET_VALUE 8'hA5`, and
resolved packed aggregate generic maps such as `LANES => "1010010100111100"` and
`FRAME => "101"`. The bounded C1 standalone-DT family also lowers scalar
integer generic maps before the standalone-DT child port map, such as
`WIDTH => 16`, scalar expression generic maps such as
`EXPR_WIDTH => (8 + 1)`, and one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, and multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"`, while the child entity keeps the matching VHDL
integer, `std_logic`, or `std_logic_vector` generic declaration. Packed-list
generic maps such as `LANES => "1010010100111100"` and packed-map generic
maps such as `FRAME => "101"` also emit before the standalone-DT child port
map. Other `?top` VHDL shapes still parse into typed composition IR and then
fail closed with the scoped target-support diagnostic.
Standalone-DT one-bit, multi-bit, and aggregate generic maps, APB/C4
generic-map shapes, aggregate/list/record actuals that do not
resolve to multi-bit packed values, unresolved package/expression actuals,
VHDL package
declaration/emission, and broader generic-map families remain deferred until
later exact leaves own those paths.

### Broader Generated-Child Top Instantiation

Status: partially shipped; generalized surfaces remain backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths, and ISF generated-child fixtures now emit a generated
`<actor>_top.fsm` that wires the scheduled parent, scheduled children,
start/done handoffs, named-drive handoffs, explicit port-binding handoffs, and
per-instance parameter overrides for spawn, generated blocking `do`, and
generated rule-trigger activations through the existing composition pipeline.
Broader generated-child top surfaces beyond the covered spawn, generated `do`,
and rule-trigger patterns remain backlog.

### Spawn and Blocking Do Parameter Binding

Status: partially shipped; broader parameter/value surfaces remain backlog.

Goal: bind parameters through static generated child activations in
ISF-generated multi-file scheduled designs.

Current boundary: spawn and parameterized blocking `do` emit child files, a
parent scheduled `.fsm`, and a generated composition top for covered
generated-child fixtures.

The ISF lowerer accepts one optional nested `(params (NAME value) ...)` block
on `(spawn child as instance ...)` and on `(do child ...)`, accepts generated
child transaction parameters from a transaction-local `params` clause, emits
child defaults as scheduled child `+params`, validates duplicates/unknown
overrides/value shapes, rejects parameter declarations on non-generated
transactions, preserves per-instance override lists in the parent lowerer IR,
and applies those overrides through the generated top.

The shipped activation override value domain is scalar/exact-width literals,
actor-local constants, actor-local scalar parameter defaults, scalar local or
package-qualified enum members, qualified imported package scalar constants,
and compatible aggregate/list literals whose scalar leaves are literals,
actor-local constants, actor-local scalar parameter defaults, enum members, or
qualified imported package scalar constants. Package-constant-backed
activation overrides resolve to literal generated-top bindings and
generated-composition report values; unqualified package constants, aggregate
package constants, package member/item paths, and ambiguous
local-enum/package-constant spellings remain fail-closed.

Actor top-level interface port widths may use qualified imported package
scalar constants too, when the imported package constant resolves to a
positive integer. Those widths publish as resolved integer parser-handoff
widths, scheduled `.fsm` `+size` entries, schedule-report evidence, and HDL
port ranges. Unqualified package constants, aggregate package constants,
package member/item paths, ambiguous local-enum/package-constant spellings,
zero values, runtime signals, and expressions remain fail-closed for
interface widths.

Actor-owned scalar storage widths may also use qualified imported package
scalar constants when the imported package constant resolves to a positive
integer. Those widths publish as resolved integer parser-handoff storage
widths, scheduled `.fsm` `+size` entries, schedule-report evidence, width
evidence, and HDL register ranges. Unqualified package constants, aggregate
package constants, package member/item paths, ambiguous
local-enum/package-constant spellings, zero values, runtime signals,
and expressions remain fail-closed.

Actor-owned bank storage widths may also use qualified imported package scalar
constants when the imported package constant resolves to a positive integer.
Those widths publish as resolved integer parser-handoff bank widths,
scalarized scheduled `.fsm` `+size` entries, schedule-report evidence,
`bank_accesses[]` widths, width evidence, and HDL register ranges.
Unqualified package constants, aggregate package constants, package
member/item paths, ambiguous local-enum/package-constant spellings, zero
values, runtime signals, and expressions remain fail-closed for bank widths.

Actor-owned bank storage depths may also use qualified imported package scalar
constants when the imported package constant resolves to a positive integer.
Those depths publish as resolved integer parser-handoff bank depths,
scalarized scheduled `.fsm` `+size` entries, schedule-report evidence,
`bank_accesses[]` depths and scalarized entries, and HDL register
declarations. Unqualified package constants, aggregate package constants,
package member/item paths, ambiguous local-enum/package-constant spellings,
zero values, runtime signals, and expressions remain fail-closed for bank
depths.

Transaction-local port widths may also use qualified imported package scalar
constants when the imported package constant resolves to a positive integer.
Those widths publish as resolved integer parser-handoff port widths,
scheduled `.fsm` activation handoff storage, `transaction_port_bindings[]`
report widths, and HDL register ranges. Unqualified package constants,
aggregate package constants, package member/item paths, ambiguous
local-enum/package-constant spellings, zero values, runtime signals, and
expressions remain fail-closed for transaction-local port widths.

Generated child and direct/non-generated transaction-local port widths may
also use same-transaction scalar parameter defaults when those defaults
resolve to positive integers. The accepted `TX_PARAM` source resolves before
actor constants and actor parameters, may derive from an earlier scalar
transaction parameter default, and publishes through parser handoff, scheduled
`.fsm` port `+size` declarations, generated parent handoff storage where
applicable, `transaction_port_bindings[]` report widths, and HDL port/register
ranges.
Activation-site override specialization, generated-top respecialization,
aggregate/list parameters, cross-transaction parameter names, zero-valued
transaction parameters, forward/self/cyclic transaction-parameter defaults,
runtime signals, arbitrary expressions, and schedule-report key-family
changes remain outside the shipped generated-child surface.

Explicit data-operation width evidence may also use qualified imported
package scalar constants when the imported package constant resolves to a
positive integer. Those values publish as resolved scheduler width facts for
`shift_left` and `shift_right` `(width ...)` options, `assemble` and `extract`
`(widths ...)` entries, scheduled `.fsm` shift positions and extract slices,
and `inferred_storage[]` report widths. Unqualified package constants,
aggregate package constants, package member/item paths, ambiguous
local-enum/package-constant spellings, zero-valued constants, unrelated or
cross-transaction parameters, zero-valued transaction parameters,
aggregate/list transaction parameters, activation-site override-specialized
data widths, runtime signals, and expressions remain fail-closed for
data-operation width evidence.

Actor parameter defaults accept enum members, declared actor constants, earlier
scalar actor parameter defaults, and qualified imported package scalar
constants in their shipped scalar and aggregate/list leaf positions. Actor
constant, actor-parameter, and qualified package-constant tokens remain visible
in scheduled `.fsm` `+params` and `actor_params[]`, and the resolved literal is
recorded internally for scalar parameter consumers. Actor parameter references
are source-order dependencies only; forward, self, cyclic, and non-scalar
actor-parameter references remain fail-closed. Imported package constants must
be qualified, scalar package `+constants` entries; unqualified package
constants, aggregate package constants, package member/item paths, and
ambiguous local-enum/package-constant spellings remain fail-closed.

Generated child transaction parameter defaults also accept enum members in
their shipped scalar and aggregate/list leaf positions. They also accept
declared actor constants, actor-local scalar parameter defaults, and earlier
scalar transaction parameter defaults, and qualified imported package scalar
constants by name in those positions. Actor constants and actor scalar
parameter defaults are resolved to literal values before generated child
`.fsm` `+params`, generated-composition child summaries, and default instance
bindings are published; child-local transaction parameter dependencies,
enum-backed defaults, and qualified package-constant defaults keep the
authored token in those review surfaces. Imported package constants must be
qualified scalar package `+constants` entries; unqualified package constants,
aggregate package constants, and package member/item paths remain fail-closed.

Reusable-library use-site parameter overrides may use importing-actor
constants, importing-actor scalar parameter defaults, enum members, and
qualified imported package scalar constants as scalar values or scalar leaves
inside compatible aggregate/list override values. Package-constant-backed
use-site overrides resolve to literal generated-top/generated-composition
bindings and `library_uses[]` report values; unqualified package constants,
aggregate package constants, package member/item paths, and ambiguous
local-enum/package-constant spellings remain fail-closed.

Actor constant names, actor-local scalar parameter default names, scalar enum
members, and qualified imported package scalar constants on activation sites
are resolved to literal values before generated-top emission. Reusable-library
use-site values, including qualified imported package scalar constants, also
resolve before `library_uses[]` report publication.

Runtime signals and arbitrary expressions remain outside the shipped value
domain.

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
runtime parameter signals.

A parameterized blocking `do` elaborates a generated child activation
instance named `{parent}_{child}_do_{ordinal}` and waits for that instance's
`done` handoff.

The selected parameterized rule-trigger lowering elaborates a generated child
activation instance named `{rule}_{transaction}_trigger_{ordinal}`.

The rule still emits the existing one-cycle trigger source and input payload
sources, then a generated handoff DT drives the instance start and input
handoff ports under that source.

The generated top applies the static `(params ...)` overrides on the child
`?fsmc` instance.

The rule wires but does not await the generated child `done` handoff.
Generated-child rule-trigger output bindings can copy a scalar child output
handoff back into an actor target under that trigger instance's done-observer
signal. Direct/local rule-trigger output bindings remain unsupported because a
shared local transaction target has no rule-specific completion identity.

Scalar enum member override values are resolved to literal generated-top
parameter bindings for the shipped spawn, generated blocking `do`, and
rule-trigger subset; scalar enum member leaves inside aggregate/list override
values resolve to the same literal generated-top bindings.

Direct `(on port body...)` remains the entry/idle-state guard and accepts only
`(sample port as name)` nested body clauses. `(on start (params (WIDTH 16)))`
fails closed with a diagnostic that says direct `(on ...)` activation is an
entry guard, not a generated activation-site parameter override. It must not
be interpreted as a static specialization or a runtime parameter assignment.
The optional `(on SIGNAL as NAME)` activation label names the entry state for
checks only; it does not create a parameterizable activation instance.

If two activation sites pass different parameter values to the same
transaction, the lowerer must elaborate distinct logical child instances or
cloned scheduled regions. If that cannot be done for a given activation form,
the form must fail closed with a diagnostic that tells the author to move the
value to a transaction input port and `(bind ...)` it as runtime data.

### Spawn Inside Repeat Bodies

Status: partially shipped; broader repeat-body child activation remains backlog.

Historical task-tree record:
[`ISF-REPEAT-BODY-CHILD-ACTIVATION`](../../tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md).
That tree is closed; future repeat-body child-activation behavior needs a new
task-tree leaf before implementation.

Repeat-body local `(do child)`, top-level when-body nested repeat local or
generated-child `(do child)`, top-level when-body nested repeat
static-parameter generated `(do child (params ...))` with optional `(bind
...)` handoffs, top-level switch-branch nested repeat local, generated-child
`(do child)`, or static-parameter generated `(do child (params ...))` with
optional `(bind ...)` handoffs and optional declared same-domain `(domain
NAME)` metadata, repeat-body generated blocking `(do child (params ...))`,
repeat-body spawn `(bind ...)`, and declared same-domain `(domain NAME)`
metadata are shipped for the already shipped top-level repeat plus same-body
synchronization paths.

The local `do` subset stays in the parent scheduled module and waits for the
child's fresh done pulse before the repeat check can loop; when the repeat is
directly inside a top-level `when` body, a local do state lives in the
branch-owned repeat region or a plain generated-child do site emits one
deterministic `{parent}_{child}_repeat_do_{ordinal}` instance when the target
is already generated elsewhere.

Both forms gate that nested repeat check on fresh child done.

Top-level `switch` branch nested repeats support the same local or
generated-child do forms.

The generated `do` subset emits one generated child instance for the lexical
repeat-body do site and applies static parameter overrides once in the
generated top.

The spawn subset reuses the static generated-child model: one lexical spawn
name maps to one generated child instance, binding payload ports are
generated once for that instance rather than per repeat iteration, and the
domain annotation records ownership metadata without implying CDC behavior.

Goal: allow `(spawn child as name)` inside `(repeat count body...)` without
implying dynamic hardware creation.

Required contract: the lexical spawn name denotes one static child instance in
the generated top. The repeat loop may activate that instance multiple times,
but it must not elaborate one instance per iteration. The scheduler needs a
busy/re-entry rule before this can ship: either prove or insert sequencing so
each later iteration observes the child's fresh done pulse before starting it
again, or reject the loop with a targeted diagnostic.

Shipped subset: a top-level repeat body may use local `(do child)` when the
child remains in the parent scheduled module.

A repeat directly inside a top-level `when` body may also use that local `(do
child)` subset, may use plain generated-child `(do child)` when the target
child is already emitted as a generated child by another activation site, or
may use generated blocking `(do child (params ...))` with static parameter
overrides.

The nested generated `when` forms own one deterministic generated do instance
for the lexical site, apply parameter overrides once when present, may wire
input/output binding handoffs once when `(bind ...)` is paired with static
`(params ...)`, and may carry declared same-domain `(domain NAME)` metadata
when static params are present.

A repeat directly inside a top-level `switch` branch may use local, plain
generated-child `(do child)`, or static-parameter generated `(do child
(params ...))` under the same generated-do rule and may wire input/output
binding handoffs once when `(bind ...)` is paired with static `(params ...)`;
it may also carry declared same-domain `(domain NAME)` metadata when static
params are present.

It rejects deeper branch nesting beyond the documented branch-contained
subsets. A plain local `(do child)` (`t/1379`) and a same-domain generated
`(do child (params ...))` (`t/1380`) inside a `(repeat ...)` directly in a
single `(while ...)`/`(until ...)` body now lower (reusing the proven repeat
schedule inside the loop body; a generated `do` instantiates its child in the
`_top` composition). The basic `spawn` + same-body `(await_all done)` (or
single-pending `(await_any done)`) subset (`t/1383`) also lowers in a
loop-contained repeat (lowering + composition parity with the top-level
repeat-body spawn). An undrained loop-contained spawn fails closed
(`loop-contained repeat-body spawn requires same-body '(await_all done)' or
single-pending '(await_any done)'`). A parent-body sync after the repeat exits
does not drain repeat-body spawned children; it fails closed with
`repeat-body spawn cannot be drained by parent-body '(await_all done)' after
the repeat exits; use same-body '(await_all done)' before the repeat check can
loop` (or the authored parent-body sync form). A multi-pending `(await_any done)` is
accepted only as an observation point when a later same-body `(await_all done)`
drains the same outstanding children. Without that later drain, the diagnostic
names the missing lifetime proof
(`loop-contained repeat-body multi-pending await_any requires later same-body
'(await_all done)' before the repeat check can loop`; top-level and
deeper-nested forms use the matching context prefix). A cross-domain generated
`do` fails
closed (`cross-domain repeat-body do remains deferred`). A `while`- or
body-first `until`-contained repeat may keep one or more generated spawns
pending across one plain local blocking `(do child)` when a later same-body
`(await_all done)` drains the exact spawned-child set before repeat and the
surrounding loop re-entry. The single-pending variant may also use post-`do`
`(await_any done)` as that final sync. Multi-pending post-`do`
`(await_any done)` is accepted as an observation point only when a later
same-body `(await_all done)` drains the same pending generated children before
repeat and loop re-entry; this rule has no public fanout cap. Generated `do`
while spawned children are pending, missing later drains, cross-domain
activation, and unrelated deeper placements remain fail-closed.
A plain local
`(do child)` inside `while -> when -> repeat` now also lowers (`t/1379`);
generated `do`, `spawn`, `until -> when`, nested `switch`, and extra loop
nesting in that loop-plus-branch family still emit the loop-contained or
deeper-nested deferral diagnostics. A plain
local `(do child)` (`t/1381`), a same-domain generated `(do child (params ...))`
(`t/1382`), and the basic spawn + drain subset (`t/1383`) at deeper branch
nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) also lower; a
deeper-nested cross-domain generated `do` fails closed with `cross-domain
repeat-body do remains deferred` and an undrained deeper-nested `spawn` with
`deeper-nested repeat-body spawn requires same-body '(await_all done)' or
single-pending '(await_any done)'`; the original generic message remains as a
safety-net fallback for shapes not yet classified. Undrained / multi-pending /
cross-domain loop-contained and deeper-nested spawn-drain variants, and broader
implementations, remain backlog.

A top-level repeat body may use `(spawn child as inst [(params ...)] [(bind
...)] [(domain NAME)])` clauses when the same repeat body reaches `(await_all
done)` before the repeat check can loop.

A single-pending `(await_any done)` is also shipped when exactly one
repeat-body spawn is pending; in that case it has the same re-entry proof as
waiting for the one static child.

Local repeat-body `do` and `await_all` consume the needed done pulse before
the repeat check, so the next iteration cannot re-assert the local or static
child start before the previous activation has returned fresh done.

Repeat-body generated blocking `do` with static parameter overrides has the
same re-entry proof because the do state waits for the generated instance's
done handoff before the repeat check.

Samples after repeat-body spawn are shipped when they appear before the
same-body `await_all` or single-pending `await_any`; they materialize in an
explicit sample state before the sync state.

Parameter overrides reuse the same static specialization contract as
top-level spawn: they specialize the one lexical child instance in the
generated top and do not create per-iteration parameter values.

Binding handoffs generate one set of parent handoff ports for the lexical
static instance and are wired in the generated top.

Repeat-body generated `do` now uses the same static parameter-plus-binding
handoff model for its lexical generated do instance and may also carry
same-domain `(domain NAME)` metadata.

Repeat-body generated-do domain annotations are accepted only when they name the
same declared domain as the owning transaction and child. A blocking `(do child)`
may now cross domains through an explicit `(crossings (activation child (from
SRC)(to DST)))` contract at the transaction top level or directly inside a
top-level body, including a top-level repeat body and the four top-level
branch/loop bodies, and directly inside a repeat nested in a top-level `when`
body or top-level `switch` branch, or directly inside a supported nested `when`
chain reached from one of those top-level branch bodies, including a repeat under
that chain (see
[Activation Crossing](13a-actor-interface.md#activation-crossing)).
Deeper-nested cross-domain activation beyond those shipped contexts,
mismatched-domain generated-do metadata, and cross-domain `(spawn)` remain
deferred.

Plain repeat-body generated-child `(do child)` is now shipped for targets
already generated elsewhere: it creates one deterministic generated do
instance for the lexical repeat-body do site without requiring `(params
...)`, `(bind ...)`, or `(domain NAME)` on that site, then gates repeat
re-entry on that instance's fresh done handoff.

Samples immediately before shipped repeat-body local or generated `do` states
now lower into explicit sample states before the do state.

Samples immediately after those do states lower after the do state's fresh
done guard and before the repeat check.

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

Both branch-contained paths may use single-pending `(await_any done)`
directly when exactly one generated child is pending.

Both branch-contained paths may also use multi-pending `(await_any done)` as
an observation point when a later same-body `(await_all done)` drains the
same outstanding generated children before the nested repeat check can loop.

Those branch-contained nested spawn subsets reuse the static generated-child
handoff model, preserve source-order samples before the nested spawn or sync
states, and gate the nested repeat check on spawned child done handoffs.

The top-level `when` body nested-repeat subset now also allows a local plain
`(do child)` while generated nested spawns remain pending either before or
after a prior multi-pending `(await_any done)` observation, provided a later
same-body `(await_all done)` drains the outstanding generated children before
the nested repeat check can loop.

The top-level `switch` branch nested-repeat subset allows the same local
plain `(do child)` pending-spawn form before or after a prior multi-pending
`(await_any done)` observation.

That local do target remains in the parent scheduled module, waits for the
local child's fresh done pulse, and does not clear the pending
generated-spawn done set.

The top-level `when` body and top-level `switch` branch nested-repeat subsets
also allow a plain generated-child `(do child)` in that same pending-spawn
interval when the target child is already emitted as a generated child by
another activation site.

Both branch-contained generated-child subsets may place that do before or
after a prior multi-pending `(await_any done)` observation.

Those generated do sites own one deterministic generated instance, wait for
that instance's fresh done handoff, and leave the pending generated-spawn
done set live for the later same-body `(await_all done)` drain.

The same two branch-contained subsets also ship static-parameter generated
`(do child (params ...))` in that pending-spawn interval, preserving
generated top parameter binding on the generated do instance while still
requiring the later same-body drain.

Top-level `when` body and top-level `switch` branch nested repeats also ship
generated `do` with static-parameter params while generated nested spawn is
pending before the same-body `await_all` drain.

The same branch-contained pending-spawn generated do subsets also accept
`(bind ...)` input/output port bindings when static `(params ...)` overrides
are present.

The nested do site reuses the deterministic generated do instance for that
lexical site, wires generated-top binding handoffs once, waits for the
instance's fresh done handoff before the branch-owned repeat check, and
leaves the pending generated-spawn done set live for the later drain.

Generated `do` after a prior multi-pending `await_any` and generated `do`
before post-do multi-pending `await_any` have shipped only for the documented
branch-contained generated-child, static-parameter, bound, and same-domain
metadata variants. Local-do, plain generated-child, static-parameter
generated-do, bound generated-do, and same-domain generated-do
do-then-spawn after a prior multi-pending `await_any` have shipped only for
the documented branch-contained forms that may include a second post-spawn
`await_any` before the mandatory same-body `await_all` drain. Cross-domain
blocking `do` lowering through an explicit activation crossing is shipped for
the transaction top level and direct top-level bodies; deeper-nested
cross-domain activation remains backlog. Mismatched-domain generated-do
metadata stays fail-closed with a targeted "cross-domain repeat-body do
remains deferred" diagnostic instead of the misleading same-domain-feature
`(params)` requirement message. Cross-domain do without a covering activation
crossing still surfaces the generic clock-domain violation message.
Generated/spawn nested activation beyond the documented branch-contained
generated `do` cases and the branch-contained spawned cases, and cross-domain
generated `do` (the plain local `(do child)`, same-domain generated
`(do child (params ...))`, and basic `spawn` + same-body drain loop-contained
AND deeper-nested cases are shipped at the lowering + composition level — the
undrained / multi-pending / cross-domain spawn-drain variants stay deferred),
and broader outstanding-child lifetime semantics beyond the mandatory-drain
subset remain backlog.

The shipped branch-contained generated nested do subsets still keep
unsupported activation subclauses, spawn nesting, deeper branch/loop nesting,
cross-domain activation, and broader outstanding-child semantics out of
scope.

The when-contained same-domain metadata analogue for that pending-spawn
interval is shipped.

It covers a repeat directly inside a top-level `when` body with one or more
generated spawns, generated blocking `(do child (params ...) [(bind ...)]
(domain NAME))` while those generated nested spawns are pending, and a later
same-body `(await_all done)` drain before the nested repeat check can loop.

The domain annotation is declared same-domain ownership metadata only for the
deterministic generated do instance; it preserves
generated-composition/domain partition metadata and schedule-report
clock-domain child-instance summaries without implying CDC or cross-domain
activation.

The switch-contained same-domain analogue for that pending-spawn interval is
also shipped.

It covers a repeat directly inside a top-level `switch` branch with one or
more generated spawns, generated blocking `(do child (params ...) [(bind
...)] (domain NAME))` while those generated nested spawns are pending, and a
later same-body `(await_all done)` drain before the nested repeat check can
loop.

The domain annotation is declared same-domain ownership metadata only for the
deterministic generated do instance; it preserves
generated-composition/domain partition metadata and schedule-report
clock-domain child-instance summaries without implying CDC or cross-domain
activation.

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
top-level `when` body nested repeats with one or more generated `(spawn child
as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites may run a local
`(do child)` while those generated spawns remain pending, provided a later
same-body `(await_all done)` drains the outstanding generated children before
the nested repeat check can loop.

This subset is shipped.

The `do` target must remain local to the parent scheduled module; it uses the
parent-module start/done pulse contract and leaves generated-spawn done
handoffs live until the later drain.

The direct top-level `switch` branch analogue is also shipped: a repeat
directly inside a top-level `switch` branch may run a local `(do child)`
while generated nested spawns remain pending, with the same later same-body
`(await_all done)` drain requirement and the same local start/done proof.

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

The static-parameter generated-do-then-spawn analogue is also shipped for
those same top-level branch-contained subsets when no multi-pending
`(await_any done)` observation is active before the drain: after the
generated do instance completes, one or more later generated spawns may start
before the mandatory same-body `(await_all done)` drain, and that drain covers
both pre-do and post-do generated spawns before nested repeat re-entry.

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
handoffs remain live until the later drain.

The bound generated-do-then-spawn analogue is also shipped for those same
top-level branch-contained subsets when no multi-pending `(await_any done)`
observation is active before the drain: after the bound generated do instance
completes, one or more later generated spawns may start before the mandatory
same-body `(await_all done)` drain, and that drain covers both pre-do and
post-do generated spawns before nested repeat re-entry.

At that bound-generated-do checkpoint, domain metadata on those generated
`do` sites, `await_any` observation before or after the do, cross-domain
activation, deeper branch/loop nesting, and broader outstanding-child
semantics remained deferred. Later leaves in this R14 series shipped the
documented same-domain, pre-do/post-do observation, and generated-do
then-spawn subsets while keeping cross-domain activation, deeper nesting, and
broader outstanding-child semantics deferred.

The branch-contained `await_any`-before-local-do subsets for that
pending-spawn interval are shipped. They cover repeats directly inside a
top-level `when` body or top-level `switch` branch with multiple generated
spawns, a multi-pending `(await_any done)` observation, local blocking
`(do child)` while those generated spawns remain pending, and a later
same-body `(await_all done)` drain before the nested repeat check can loop.

The local do target stays in the parent scheduled module and the
generated-spawn done handoffs stay live through the local do until the later
drain.

The when-contained generated-child `await_any`-before-do subset is also
shipped: a repeat directly inside a top-level `when` body with multiple
generated spawns, a multi-pending `(await_any done)` observation, a plain
generated-child `(do child)` whose target is already emitted by another
activation site, and a later same-body `(await_all done)` drain before the
nested repeat check can loop.

The generated do instance keeps its own fresh done handoff while the pending
generated-spawn done set remains live for the later drain.

The switch-contained generated-child `await_any`-before-do analogue is also
shipped with the same pending-spawn lifetime and later drain contract.

The when-contained static-parameter generated `await_any`-before-do analogue
is now shipped as well: a repeat directly inside a top-level `when` body may
have multiple generated spawns, a multi-pending `(await_any done)`
observation, generated blocking `(do child (params ...))` with static
parameter overrides while those generated spawns remain pending, and a later
same-body `(await_all done)` drain before the nested repeat check can loop.

The generated do instance carries its static parameter binding in the
generated top, waits on its own fresh done handoff, and does not clear the
pending generated-spawn done set that the later drain must consume.

The switch-contained static-parameter generated `await_any`-before-do
analogue is shipped with the same contract: a repeat directly inside a
top-level `switch` branch may have multiple generated spawns, a multi-pending
`(await_any done)` observation, generated blocking `(do child (params ...))`
with static parameter overrides while those generated spawns remain pending,
and a later same-body `(await_all done)` drain before the nested repeat check
can loop.

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
as an observation point, and a later same-body `(await_all done)` drain
before the nested repeat check can loop.

The top-level switch branch nested repeat local do before post-do
multi-pending `await_any` subset is shipped with the same contract for a
repeat directly inside a top-level `switch` branch while generated nested
spawns remain pending before the same-body `await_all` drain: the local child
still completes through the parent scheduled module, and the post-do
`await_any` observes only the pending generated-spawn done set without
clearing it.

The top-level `when` body nested repeat plain generated-child `(do child)`
before post-do multi-pending `await_any` subset is shipped as well: a repeat
directly inside a top-level `when` body with multiple generated spawns, a
plain generated-child blocking do while those generated spawns remain
pending, post-do `(await_any done)` as an observation point, and a later
same-body `(await_all done)` drain before the nested repeat check can loop.

The generated-child do waits for its deterministic generated do instance's
fresh done handoff, and the post-do `await_any` observes only the pending
generated-spawn done set without clearing it.

The switch-contained generated-child post-do `await_any` analogue is now
shipped with the same generated-child and later-drain contract: a repeat
directly inside a top-level `switch` branch may run a plain generated-child
blocking do while multiple generated spawns remain pending, then use post-do
`(await_any done)` as an observation point before the later same-body
`(await_all done)` drain.

The top-level `when` body static-parameter generated-do post-do `await_any`
analogue is also shipped: a repeat directly inside a top-level `when` body
may run `(do child (params ...))` while multiple generated spawns remain
pending, then use post-do `(await_any done)` as an observation point before
the later same-body `(await_all done)` drain.

The generated do preserves static generated-top parameter binding, waits for
its deterministic generated do instance's fresh done handoff before that
observation, and leaves the pending generated-spawn done set live for the
later drain.

The direct switch-contained static-parameter generated-do post-do `await_any`
analogue is also shipped: a repeat directly inside a top-level `switch`
branch may run `(do child (params ...))` while multiple generated spawns
remain pending, then use post-do `(await_any done)` as an observation point
before the later same-body `(await_all done)` drain.

It uses the same deterministic generated do instance, preserves the static
generated-top parameter binding, waits for that generated do instance's fresh
done handoff before the observation, and leaves the pending generated-spawn
done set live for the later drain.

The when-contained bound generated-do post-do `await_any` subset is now
shipped: a repeat directly inside a top-level `when` body may run `(do child
(params ...) (bind ...))` while multiple generated spawns remain pending, then use post-do
`(await_any done)` as an observation point before the later same-body
`(await_all done)` drain.

That subset wires the generated-top input/output binding handoffs for the
generated do instance, requires that instance's fresh done handoff before the
observation, and leaves the pending generated-spawn done set live for the
later drain.

The direct switch-contained bound generated-do post-do `await_any` analogue is
now shipped: a repeat directly inside a top-level `switch` branch may run
`(do child (params ...) (bind ...))` while multiple generated spawns remain
pending, then use post-do `(await_any done)` as an observation point before
the later same-body `(await_all done)` drain.

That subset wires generated-top input/output binding handoffs for the
generated do instance, requires that instance's fresh done handoff before the
observation, and leaves the pending generated-spawn done set live for the
later drain.

The same-domain generated-do post-do `await_any` analogue is now shipped for
both top-level `when` body and top-level `switch` branch nested repeats: a
static-parameter generated `(do child (params ...) [(bind ...)] (domain
NAME))` may run while multiple generated spawns remain pending, then use
post-do `(await_any done)` as an observation point before the later same-body
`(await_all done)` drain.

That subset preserves generated-top parameter binding, optional input/output
binding handoffs, and declared same-domain ownership metadata for the
generated do instance; the post-do `await_any` does not clear the pending
generated-spawn done set. New spawn after generated `do` when a multi-pending
`await_any` observation is active before the drain, new spawn after plain
generated-child `do` when a multi-pending `await_any` observation is active
before the drain, cross-domain activation, deeper branch/loop nesting, and
broader outstanding-child semantics remain backlog until their own leaves
select and ship them.

The branch-contained local-do-then-spawn-before-drain analogue is now shipped
for top-level `when` bodies and top-level `switch` branches. A nested repeat
may run an initial generated `(spawn child as inst ...)`, then local blocking
`(do child)` in the parent scheduled module, then one or more additional
generated `(spawn child as inst ...)` sites, and finally same-body
`(await_all done)` before the nested repeat check can loop. The local child
must complete before the later generated spawn starts, the later spawn joins
the outstanding generated-spawn done set, and the `await_all` drain observes
both the pre-do and post-do generated children. The shipped subset does not
allow `(await_any done)` after the later spawn, does not allow generated
blocking `do` to be followed by a new spawn before the drain, and does not
change cross-domain activation, deeper nesting, or broader outstanding-child
lifetime rules.

The branch-contained plain-generated-do-then-spawn-before-drain analogue is
now shipped for top-level `when` bodies and top-level `switch` branches. A
nested repeat may run an initial generated `(spawn child as inst ...)`, then
plain generated-child blocking `(do child)` for a target already emitted as a
generated child, then one or more additional generated
`(spawn child as inst ...)` sites, and finally same-body `(await_all done)`
before the nested repeat check can loop. The generated do instance must
complete before the later generated spawn starts, the later spawn joins the
outstanding generated-spawn done set, and the `await_all` drain observes both
pre-do and post-do generated children. Later R14 leaves shipped the
static-parameter, bound, and same-domain generated-do analogues for the same
do-then-spawn-before-drain shape.

The branch-contained plain-generated-do-then-spawn post-spawn `await_any`
analogue is now shipped for top-level `when` bodies and top-level `switch`
branches. A nested repeat may run an initial generated spawn, plain
generated-child blocking `(do child)`, one or more later generated spawns,
post-spawn multi-pending `(await_any done)` as an observation point, and then
same-body `(await_all done)` before the nested repeat check can loop. The
post-spawn observation does not clear the outstanding generated-spawn done
set; the final drain still observes both pre-do and post-do generated
children.

The branch-contained local-do-then-spawn post-spawn `await_any` analogue is
also shipped for top-level `when` bodies and top-level `switch` branches. A
nested repeat may run an initial generated spawn, local blocking `(do child)`
in the parent scheduled module, one or more later generated spawns,
post-spawn multi-pending `(await_any done)` as an observation point, and then
same-body `(await_all done)` before the nested repeat check can loop. The
local child must complete before the later generated spawn starts; the
post-spawn observation leaves both pre-do and post-do generated-spawn done
handoffs live for the final drain.

The branch-contained static-parameter generated-do-then-spawn post-spawn
`await_any` analogue is also shipped for top-level `when` bodies and
top-level `switch` branches. A nested repeat may run an initial generated
spawn, generated blocking `(do child (params ...))`, one or more later
generated spawns, post-spawn multi-pending `(await_any done)` as an
observation point, and then same-body `(await_all done)` before the nested
repeat check can loop. The generated do instance preserves static
generated-top parameter binding and must complete before the later generated
spawn starts; the post-spawn observation leaves both pre-do and post-do
generated-spawn done handoffs live for the final drain. At that checkpoint,
bound and same-domain generated-do do-then-spawn post-spawn `await_any`
variants, active-prior-`await_any` spawn-after-do variants, cross-domain
activation, deeper nesting, and broader outstanding-child lifetime rules
remained backlog; later slices shipped the bound and same-domain post-spawn
`await_any` analogues plus the local-do, plain generated-child,
static-parameter generated-do, bound generated-do, and same-domain
generated-do prior-active-`await_any` analogues.

The branch-contained bound generated-do-then-spawn post-spawn `await_any`
analogue is also shipped for top-level `when` bodies and top-level `switch`
branches. A nested repeat may run an initial generated spawn, bound generated
blocking `(do child (params ...) (bind ...))`, one or more later generated
spawns, post-spawn multi-pending `(await_any done)` as an observation point,
and then same-body `(await_all done)` before the nested repeat check can
loop. The generated do instance preserves static generated-top parameter
binding and generated-top input/output binding handoffs, and it must complete
before the later generated spawn starts; the post-spawn observation leaves
both pre-do and post-do generated-spawn done handoffs live for the final
drain. At that checkpoint, same-domain generated-do do-then-spawn post-spawn
`await_any` variants, active-prior-`await_any` spawn-after-do variants,
cross-domain activation, deeper nesting, and broader outstanding-child
lifetime rules remained backlog; later slices shipped the same-domain
post-spawn `await_any` analogue plus the local-do, plain generated-child,
static-parameter generated-do, bound generated-do, and same-domain
generated-do prior-active-`await_any` analogues.

The branch-contained same-domain generated-do-then-spawn post-spawn
`await_any` analogue is also shipped for top-level `when` bodies and
top-level `switch` branches. A nested repeat may run an initial generated
spawn, same-domain generated blocking `(do child (params ...) [(bind ...)]
(domain NAME))`, one or more later generated spawns, post-spawn multi-pending
`(await_any done)` as an observation point, and then same-body `(await_all
done)` before the nested repeat check can loop. The generated do instance
preserves static generated-top parameter binding, optional generated-top
input/output binding handoffs, and declared ownership metadata, and it must
complete before the later generated spawn starts; the post-spawn observation
leaves both pre-do and post-do generated-spawn done handoffs live for the
final drain.

The branch-contained local-do, plain generated-child, static-parameter
generated-do, bound generated-do, and same-domain generated-do
prior-active-`await_any` spawn-after-do analogues are shipped for top-level
`when` bodies and
top-level `switch` branches. A nested repeat may run generated spawns,
observe one done pulse through multi-pending `(await_any done)`, run local
blocking `(do child)`, plain generated-child `(do child)`, static-parameter
generated `(do child (params ...))`, bound generated
`(do child (params ...) (bind ...))`, or same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))`, start one or more later
generated spawns, and then use the mandatory same-body `(await_all done)`
drain before the nested repeat check can loop. The local child or
deterministic generated do instance must complete before the later generated
spawn starts, generated-top input/output binding handoffs remain scoped to
the bound or same-domain generated do instance, declared ownership metadata
remains scoped to the same-domain generated do instance, and the final drain
covers every pre-do and post-do generated spawn. The local-do, plain
generated-child, static-parameter generated-do, bound generated-do, and
same-domain generated-do prior-observation shapes may also run a second
post-spawn `(await_any done)` before that mandatory drain; both observations
leave the outstanding generated-spawn done set live until the final drain
covers every pre-do and post-do generated spawn. Cross-domain activation,
deeper nesting, and broader outstanding-child lifetime rules remain backlog.

The top-level `when` body branch-contained plain generated-child and
static-parameter generated-do prior-observation shapes and the top-level
`switch` branch analogues allow the generated-child `(do child)` or generated
`(do child (params ...))` to follow a multi-pending `(await_any done)`, start
later generated spawns after the deterministic do handoff, run a second
post-spawn `(await_any done)`, and then use same-body `(await_all done)` to
drain every pre-do and post-do generated spawn.

Dynamic repeat counts are compatible with this model because `count` is a
runtime counter load value, not an elaboration count. Known-width runtime
scalar counts now bypass the repeat body and repeat check when the runtime
value is zero. Unknown count names, non-scalar actor parameters, non-scalar
transaction parameters, cross-transaction parameters, expression-valued counts,
and generated-top repeat-count respecialization fail closed or remain backlog,
so fully general dynamic repeat counts are still not a frozen public contract.
Actor-constant and actor-scalar-parameter repeat counts, plus qualified
imported package scalar constant repeat counts, are now static repeat-count
sources when they resolve to non-negative integers: positive counts provide
counter-width evidence while scheduled `.fsm` still loads the authored count
token. Same-transaction scalar parameter repeat counts also provide static
width evidence when they resolve to positive integers, but the scheduled
`.fsm` loads the resolved integer because transaction parameters are local
lowering inputs. Static zero repeat counts, whether literal zero or
actor/transaction parameters, actor constants, or package scalar constants
resolving to zero, lower as transparent no-op regions with no counter, repeat
init/check state, repeat-body state, or `transaction_loops[]` entry when the
body contains no activation or contains only valid child activation sites that
can be pruned with the skipped body. `(do child)` and
`(spawn child as inst)` sites emit no generated child/top, activation
instance, local handoff, or loop report artifact when the target is not
otherwise live. Syntactically valid parameterized, bound, or
domain-annotated static-zero child activations are now pruned the same way
after activation subclause shape validation; only malformed activation
subclause syntax remains fail-closed in dead zero-count bodies.
Unqualified
package constants, aggregate package constants, package
member/item paths, and package constants inside repeat-count expressions
remain fail-closed.
