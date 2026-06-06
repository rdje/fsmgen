# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

### 2026-05-29 Status Snapshot

Recent surfaces added since the last consolidated walkthrough of
this chapter:

- **Targeted rejection diagnostics**: mismatched-domain generated repeat-body
  `do` and residual deeper-nested cross-domain activation remain deferred with targeted
  messages (`t/1372`, `t/1387`); four sub-axis activation-override
  gates — `repeat-count parameter`, `wait-count parameter`,
  `latency-bound parameter`, `watchdog-limit parameter` — each with
  its own deferral phrase (`t/1373`); undrained and cross-domain
  loop-contained/deeper-nested repeat-body spawn-drain variants remain
  deferred (`t/1374`/`t/1375`).
- **Loop-contained repeat-body `do`/`spawn`**: a plain local `(do child)`
  (`t/1379`), a same-domain generated `(do child (params ...))` (`t/1380`, child
  instantiated in the `_top`), and the basic `spawn` + same-body `(await_all
  done)`/single-pending `(await_any done)` subset (`t/1383`) inside a
  `(repeat ...)` directly in a single `(while ...)`/`(until ...)` body now lower;
  undrained / multi-pending spawn and cross-domain generated `do` stay deferred.
- **Deeper-nested repeat-body `do`/`spawn`**: a plain local `(do child)`
  (`t/1381`), a same-domain generated `(do child (params ...))` (`t/1382`), and
  the basic spawn + drain subset (`t/1383`) at deeper branch nesting (`when⁺ →
  repeat`, `switch → when⁺ → repeat`) now lower; undrained / multi-pending spawn
  and cross-domain generated `do` stay deferred.
- **Book example correctness build gate**: every `lisp`-tagged book
  example must parse + lower (`t/1376`). Current state: 40
  complete fixtures lower cleanly.
- **Cookbook ISF recipes**: `docs/book/src/12-cookbook.md` now
  carries recipes 9-13 covering basic actor, spawn, parameterized
  blocking do (same-value override), rule trigger, and repeat-body
  generated do. Each recipe carries a `**Walkthrough.**` paragraph.
- **Block-tag convention**: `lisp` blocks are reserved for
  accept-path fixtures that lower cleanly; `text` blocks are for
  schematics, elided actor bodies, and rejected-shape
  illustrations.
- **Handoff documents**: `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md` are now current with the
  recent diagnostic surface.
- **Coverage audit**: a comprehensive mdBook coverage audit lives
  at `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` with
  per-chapter coverage metrics and a prioritized slice queue.

The status markers below predate this snapshot and remain
chapter-internal categorisations; they have not been
retroactively renormalized.

Top-level backlog category ownership is tracked in
[docs/TASK_TREE.md](../../TASK_TREE.md). A category marked there as
`future task tree required` is not an implementation permission slip;
behavior-bearing work still has to create or activate an executable task tree
before code, tests, source artifacts, generated artifacts, or public behavior
changes.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: partially shipped; broader inference surfaces remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, symbolic scalar `+types`
`(bits WIDTH_SYMBOL)` specs, slices, selectors, guards, and other bounded
evidence. It does not yet promise "never declare scalar types unless you want
to" across every source position.

### Dynamic Divisor Safety Proofs

Status: partially shipped.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission, and direct `.fsm` runtime expressions reject
numeric/exact-width literal-zero divisors before HDL emission. ISF runtime
expression contexts now reject numeric/exact-width literal-zero divisors and
actor-level constants that resolve to zero, plus actor-local scalar parameter
defaults that resolve to zero, plus same-transaction scalar parameter defaults
that resolve to zero, before scheduled `.fsm` emission. Nonzero literal
divisors, nonzero actor-constant divisors, nonzero actor-parameter divisors,
nonzero same-transaction parameter divisors, and dynamic scalar divisors are
emitted unchanged; FSMGen does not yet prove every dynamic divisor nonzero.
Nonzero actor parameters and nonzero transaction parameters remain outside a
full nonzero proof because they are overrideable specialization values, not
fixed actor constants.

## Aggregate Types And Data

### Portable Synthesizable Type Core

Status: partially shipped; broader portable type core remains backlog.

Goal: define one frontend type model that stays semantic and portable across
SystemVerilog and future VHDL instead of exposing backend-specific spelling as
the source-language contract.

Current boundary: the shipped `+types` surface covers scalar aliases for
`bit`, `(bits N)`, positive symbolic widths, signed variants, explicit
`two_state` / `four_state` intent, local/imported aliases, and packed
`list` / `record` aggregate aliases. Direct roots and composition tops preserve
those exact contracts through symbol contracts, `Intent HIR`, `module_info`,
`Structural RTL IR`, realized child interfaces, structural connection
expressions, and SystemVerilog declaration lowering.

Direct roots support typed aggregate member/list-item reads and partial
aggregate LHS writes when the base signal has a declared aggregate type.
Composition supports typed aggregate top-port and generated-child output
member/list-item source paths, whole aggregate actuals, typed structural
bindings, and bounded aggregate-root inference when a declared or safely
inferred aggregate root already exists.

Remaining backlog: enum-as-type unification with the existing `+enums`
family, fixed-size arrays, arrays of records, broad inference-first scalar
declarations, aggregate member/index autogrowth from partial use, arbitrary
subaggregate runtime operators, VHDL record/array lowering, backend-neutral
signedness/state-model policy across every inferred site, and richer public
type/export APIs remain deferred until one exact task-tree-owned contract is
selected.

### Automatic Aggregate Growth From Usage

Status: partially shipped; broader inference surfaces remain backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, partial aggregate LHS
writes, direct whole-signal target contract inference from whole aggregate
constant roots, and list-only direct RHS concat target autogrowth are
supported on the current SystemVerilog path. Broad automatic aggregate type
growth from arbitrary usage is not fully shipped. Member/index-root
autogrowth from partial use remains backlog because it does not yet provide a
complete, conflict-free hardware shape proof.

### Backend-Owned Struct/Record Default Lowering

Status: partially shipped; broader default-lowering policy remains backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases and other exact aggregate contracts on the current
SystemVerilog path. The shipped Verilog-family declaration renderers preserve
named aggregate contracts as backend-owned packed typedefs on direct module
ports, direct internal/helper declarations, structural composition ports and
nets, projected child aggregate carriers, and bounded inferred direct targets.

Structured record lowering is not the default for every aggregate-like value.
FSMGen does not invent structs from partial member/index use, width-only
matches, anonymous record guesses, or target families without a proven
synthesizable lowering. VHDL aggregate lowering and ISF aggregate aliases on
interface ports, transaction ports, and banks remain backlog.

### Richer Aggregate Operators

Status: partially shipped; broader operators remain backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: semantic parameter/generic aggregate values support matching
list/record aggregate shapes with leafwise `+`, `-`, `*`, `/`, `%`, `&`, `|`,
`^` plus word aliases before HDL lowering. They also support unary bitwise
aggregate complement through `(~ VALUE)` and `(not VALUE)`, and binary
aggregate comparison through `(== A B)` and `(!= A B)` for matching aggregate
shapes. Comparison folds to a scalar exact-width `1'b1` or `1'b0`.

Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path. Runtime direct `.fsm`
aggregate-to-aggregate operators, ISF runtime subaggregate operands, aggregate
paths in expression-operator position, VHDL aggregate lowering, mixed
scalar/aggregate operators, and mismatched aggregate shapes remain deferred.
The R11 parameter/generic frontier audit did not select another aggregate
operator widening; future work must first name one exact type, shape, result,
and lowering rule.

### VHDL Aggregate Lowering

Status: backlog, behind future VHDL aggregate-lowering work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: direct single-FSM VHDL generation has a scaffold subset for
scalar/vector ports, basic enables, reset processes, and concat assignments.
Aggregate VHDL lowering is still not shipped; aggregate-output direct roots
remain fail-closed outside the scaffold. Direct aggregate-output roots are
locked as explicit fail-closed direct VHDL boundaries by focused pipeline and
facade coverage.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.

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

Status: backlog, behind future composition VHDL work.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL
generic-map lowering is not shipped. Composition/top VHDL is locked as a
fail-closed boundary: current pipeline and CLI composition paths parse
`?top` sources into typed composition IR, then reject
`target_language => 'vhdl'` / `--language vhdl` with the scoped target-support
diagnostic. Generic maps remain deferred until a later leaf implements
composition VHDL top emission.

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
single-pending '(await_any done)'`), a multi-pending `(await_any done)` is
deferred (`loop-contained repeat-body multi-pending '(await_any done)' remains
deferred`), and a cross-domain generated `do` fails closed (`cross-domain
repeat-body do remains deferred`); a repeat reached through an additional loop
ancestor still emits `loop-contained repeat-body do remains deferred`. A plain
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

## Intent Scheduling Format

### Actor Network Orchestration

Status: shipped bounded ATL v0 public contract; broader ATL remains backlog.

Static metadata, scalar handoffs, bounded temporary trigger-batch scheduling,
parent trigger/event handoffs, resolved child `.fsm` artifact emission,
generated ATL tops, and selected scalar generated-child routes are shipped
under the selected ATL v0 public contract. The owning task tree is closed;
remaining ATL behavior changes need a new task-tree leaf before
implementation.

Historical task-tree record:
[ISF-ACTOR-NETWORK-ORCHESTRATION](../../tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).
That tree is closed; future ATL behavior changes need a new task-tree leaf
before implementation.

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
the direct actor-level `(instance NAME of ACTOR_TYPE)` clause or compact
`(NAME : ACTOR_TYPE)` alias, and static concurrent groups may be declared with
direct actor-level `(group NAME (members ACTOR...) (mode concurrent))` clauses
or compact `(concurrent NAME ACTOR...)` aliases.

The enclosing actor is the network boundary; `(network ...)` is not part of
the shipped source surface. The accepted forms lower to parser shell and
schedule-report metadata under `actor_network`; verbose instances report
`declaration: "actor"` and compact instance aliases report
`declaration: "instance_alias"`.

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
generated actor-to-actor handoff subset. The shipped subset is exactly
two direct static actor instances, one named drive body with one
`(sink_actor.endpoint source_actor.endpoint)` pair, matching endpoint widths,
and one top-level transaction drive call. It emits external parent handoff
ports named `source_actor_source_endpoint` and `sink_actor_sink_endpoint`, uses
a one-cycle route lifetime, and reports through
`actor_network.data_movements[]`.

Storage, muxing, broader pin movement, inline/expression movement, width
adaptation, fan-in/fan-out, groups, CDC, and trigger/await coupling outside
the selected generated-child top sequence remain separate backlog leaves.

The first pin-movement subsets are shipped in both scalar directions:
top-level input pin to actor endpoint as `(actor.endpoint pins.input_pin)`,
and actor endpoint to top-level output pin as
`(pins.output_pin actor.endpoint)`. Each shipped direction accepts one named
drive body, one direct static actor instance, one top-level transaction drive
call, and one-bit top-level pins only. Wider pin payloads and mixed
pin/actor movement in one drive remain later leaves.

The selected pin-route widening is exact-width vector movement for the
generated-child top-level pin routes. It is tracked by
`ISF-ATL-PIN-ROUTE-VECTOR-WIDTH`. The first implementation leaf is shipped for
one top-level input pin to one resolved child input when both endpoints have
the same positive width, and the inverse resolved-child output to top-level
output pin route is now shipped under the same exact-width policy. The selected
boundary is same-width only, with no packing, truncation, storage, muxing,
fan-in/fan-out, ready/backpressure, CDC/reset remapping, mixed route sets,
broader pin route sets outside the same-child exact-width vector subsets, or
payload protocol inference.

The next selected pin-route widening is exact-width vector multi-route sets.
It is tracked by `ISF-ATL-PIN-VECTOR-MULTI-ROUTE`. The same-child
pin-ingress vector multi-route leaf and inverse same-child pin-egress vector
multi-route leaf are shipped. Each route keeps the existing `(sink source)`
spelling and must prove a matching top-level pin and resolved child endpoint
width. Width adaptation, storage, muxing, fan-in/fan-out,
ready/backpressure, CDC/reset remapping, repeated activation, and payload
protocol inference remain deferred.

The next selected pin-route widening is mixed scalar/vector route sets. It is
tracked by `ISF-ATL-PIN-MIXED-ROUTE-SETS`. The selected sequence keeps the
same `(sink source)` spelling and drive-call timing while allowing one
same-child route set to contain both scalar one-bit routes and exact-width
vector routes in one direction. The pin-ingress leaf is shipped as
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`: `(worker.payload
pins.payload)` is an exact-width vector route at width 8 and `(worker.valid
pins.valid)` is a scalar one-bit route into the same resolved child through
adjacent pre-trigger drive calls. Each route keeps route-local `kind`, `width`,
and `width_source` metadata. The pin-egress leaf is also shipped as
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`: `(pins.result
worker.payload)` is an exact-width vector route at width 8 and `(pins.valid
worker.valid)` is a scalar one-bit route from the same resolved child through
adjacent post-event drive calls. The task tree is closed. Width adaptation,
storage, muxing, fan-in/fan-out, ready/backpressure, CDC/reset remapping,
repeated activation, and payload protocol inference remain deferred.

The selected orchestration vocabulary reuses existing ISF activation forms:
`(do actor.transaction)` for blocking actor transaction activation, `(spawn
actor.transaction as NAME)` for nonblocking activation, `(trigger
actor.transaction)` for rule-level or transaction-body activation, and
`(await actor.event)` for one-cycle actor event synchronization.

The bounded transaction-body trigger/event-wait parent-handoff subsets are
shipped today. One top-level rule action `(trigger actor.transaction)` is also
shipped as a parent-handoff pulse.

Event payloads are not part of ATL v0.

Concurrent groups use `(group NAME (members ACTOR...)

(mode concurrent))` as schedulable intent, not as a bypass for ordering,
fan-in, width, lifetime, or CDC safety.

The group axis started with fail-closed diagnostics, then shipped report-only
static group metadata for verbose `(group ...)` declarations.

The compact `(concurrent NAME ACTOR...)` alias is now shipped by
`ISF-ATL-COMPACT-GROUP-ALIAS`. It is only a readability alias for the verbose
group form and keeps group behavior report-only. Runtime group scheduling,
group endpoints, group handoff routing, generated HDL behavior, and compact
movement syntax remain later leaves.

The compact `(NAME : ACTOR_TYPE)` instance alias is now shipped by
`ISF-ATL-COMPACT-INSTANCE-ALIAS`. It is only a readability alias for verbose
`(instance NAME of ACTOR_TYPE)` static instance declarations. Verbose
instances report `declaration: "actor"`; compact instance aliases report
`declaration: "instance_alias"`. Instance scheduling behavior, actor type
resolution, generated child emission, generated ATL tops, compact movement
syntax, and route behavior are unchanged by the alias.

The first multi-actor trigger scheduling leaf is shipped as a same-cycle
external trigger batch over existing transaction-body
`(trigger actor.transaction)` clauses: one contiguous batch, distinct static
actor instances, generated external trigger outputs pulsed from one parent
state, and `actor_network.association_schedules[]` report evidence. Static
`(group ...)` declarations are not required and remain review metadata only.

Noncontiguous batches, repeated members, generated children, group endpoints,
data-movement coupling, hidden same-cycle event joins, route mux/storage, and
CDC remain later leaves.

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
generated ATL tops, group endpoints, compact movement aliases, CDC, route mux/storage,
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
HDL reachability without claiming hidden actor-event fan-in, generated
children, generated ATL tops, actor type resolution, HDL child wiring, data
movement coupling, CDC, ready/backpressure, or permanent grouping.

The bounded multi-event wait widening is now shipped through
`isf/atl_trigger_batch_multi_wait_pipeline.isf`. It keeps the existing
`(await actor.event)` syntax and preserves each authored wait as a
source-ordered scheduled wait state after one temporary trigger batch. The
accepted subset requires contiguous top-level waits, distinct triggered actor
instances, and no ATL data movement in the same transaction segment. It is
not a hidden same-cycle join and does not claim repeated waits, event
payloads, event fan-out, generated-child route coupling, group endpoints,
CDC, or ready/backpressure.

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
pin-ingress route, exact-width vector pin-ingress route, same-child scalar
pin-ingress multi-route extension, same-child vector pin-ingress multi-route
extension, same-child mixed scalar/vector pin-ingress route-set extension,
scalar pin-egress route, exact-width vector pin-egress route, scalar
same-child pin-egress multi-route extension, vector same-child pin-egress
multi-route extension, and same-child mixed scalar/vector pin-egress route-set
extension below are shipped for that same one-child top. Broader
generated ATL tops, HDL child wiring outside that selected pair plus shipped
scalar/vector pin routes,
interface binding inference, event fan-in, route mux/storage, CDC, recursive
actor networks, and ready/backpressure remain later leaves.

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
preservation, and plain plus strict HDL generation.

The exact-width vector version of that pin-ingress slice is shipped as
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`. It uses the same
drive-body spelling and routes one top-level input pin into one resolved child
input when both endpoints have the same width. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with `vector_pin_to_actor_handoff`, child input port
preservation, strict outdir materialization, plain plus strict HDL generation,
and a fail-closed top-input/child-input width mismatch diagnostic.

The exact-width vector multi-route extension of that pin-ingress shape is now
shipped as `isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf`. It
routes `(worker.payload pins.payload)` and
`(worker.sideband pins.sideband)` through adjacent top-level drive calls before
the child trigger, with route-local widths 8 and 4. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with two `vector_pin_to_actor_handoff` entries, child vector
input port preservation, strict outdir materialization, plain plus strict HDL
generation, and a fail-closed route-local top-input/child-input width mismatch
diagnostic.

The mixed scalar/vector route-set extension of that one-child pin-ingress shape
is now shipped as `isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`. It
routes `(worker.payload pins.payload)` at width 8 and
`(worker.valid pins.valid)` at width 1 through adjacent top-level drive calls
before the child trigger. The fixture proves parent/child/top artifacts,
route-local vector and scalar handoff ports, generated-top wiring, route
metadata with `vector_pin_to_actor_handoff` and
`scalar_pin_to_actor_handoff` entries, child input port preservation, strict
outdir materialization, plain plus strict HDL generation, and a fail-closed
route-local vector top-input/child-input width mismatch diagnostic.

The bounded multi-route extension of that one-child pin-ingress shape is now
shipped as `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf`. It routes
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
adjacent top-level drive calls before the child trigger, with separate drive
states, generated handoffs, generated child interface roles, generated-top
wiring, and route metadata for each scalar path. Actor-to-actor generated-child
routes outside their own two-child subset, multi-child data wiring, route
mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, and
payload protocols remain deferred.

The inverse generated-child data-route slice is now shipped as one scalar
resolved-child output route to one top-level output through the generated top,
written as `(pins.result worker.payload)` in a named drive body after the
parent triggers `worker.process` and awaits `worker.done`. The fixture
`isf/atl_resolved_child_pin_egress_pipeline.isf` proves parent/child/top
artifacts, generated-top wiring, route metadata, child output port
preservation, plain plus strict HDL generation, missing child output failure,
and pre-event drive-order failure. That one-child pin route does not include
actor-to-actor generated-child routing, multi-child data wiring, route
mux/storage, CDC/reset remapping, ready/backpressure, or payload protocols.

The exact-width vector version of that pin-egress slice is shipped as
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf`. It uses the same
drive-body spelling and routes one resolved child output into one top-level
output pin when both endpoints have the same width. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with `vector_actor_to_pin_handoff`, child output port
preservation, strict outdir materialization, plain plus strict HDL generation,
and a fail-closed child-output/top-output width mismatch diagnostic.

The exact-width vector multi-route extension of that pin-egress shape is now
shipped as `isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf`. It
routes `(pins.result worker.payload)` and `(pins.status worker.status)` through
adjacent top-level drive calls after the child event wait, with route-local
widths 8 and 4. The fixture proves parent/child/top artifacts, exact-width
handoff ports, generated-top wiring, route metadata with two
`vector_actor_to_pin_handoff` entries, child vector output port preservation,
strict outdir materialization, plain plus strict HDL generation, and a
fail-closed route-local child-output/top-output width mismatch diagnostic.

The mixed scalar/vector route-set extension of that one-child pin-egress shape
is now shipped as `isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`. It
routes `(pins.result worker.payload)` at width 8 and `(pins.valid
worker.valid)` at width 1 through adjacent top-level drive calls after the
child event wait. The fixture proves parent/child/top artifacts, route-local
vector and scalar handoff ports, generated-top wiring, route metadata with
`vector_actor_to_pin_handoff` and `scalar_actor_to_pin_handoff` entries, child
output port preservation, strict outdir materialization, plain plus strict HDL
generation, and a fail-closed route-local vector child-output/top-output width
mismatch diagnostic.

The bounded multi-route extension of that one-child pin-egress shape is now
shipped as `isf/atl_resolved_child_pin_egress_multi_pipeline.isf`. It routes
`(pins.result worker.payload)` and `(pins.status worker.status)` through
adjacent top-level drive calls after the child event wait, with separate drive
states, generated handoffs, generated child interface roles, generated-top
wiring, and route metadata for each scalar path. That one-child route set does
not include actor-to-actor generated-child routing, multi-child data wiring,
route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, or
payload protocols.

The selected generated-child actor-to-actor data movement across two resolved
children is shipped only for same-source/same-sink two-child routes that use
qualified trigger/event handoffs and matching endpoint widths. The source
shape reuses the existing `(sink source)` drive-body pair; malformed or
mismatched-width routes still fail closed before remapping, storage, muxing,
fan-in/fan-out, payload adaptation, or backpressure behavior is inferred.

The first positive two-child generated top is now shipped for the control-only
case: `isf/atl_two_child_pipeline.isf` triggers `reader.capture`, waits on
`reader.done`, triggers `writer.emit`, waits on `writer.done`, and completes.

Lowering emits parent, both children, and one generated top; schedule JSON
records the generated-top child wiring under
`actor_network.generated_tops[].children[]`.

The first one-bit generated-child actor-to-actor route through that two-child
top is now shipped as `isf/atl_two_child_data_pipeline.isf`. The source uses
`(writer.payload reader.payload)` in a named drive body, called after
`reader.done` and before `writer.emit`. Lowering emits parent, both children,
and one generated top. The parent exposes `reader_payload` and
`writer_payload` handoffs, the parent drive body moves the scalar payload for
the drive-call cycle, and the generated top wires `reader.payload` to the
parent source handoff plus the parent sink handoff to `writer.payload`.

The exact-width vector route through that two-child top is now shipped as
`isf/atl_two_child_vector_data_pipeline.isf`. It uses the same
`(writer.payload reader.payload)` source shape and ordering, but both child
payload endpoints declare width 8. Lowering emits 8-bit parent handoffs,
8-bit child interface roles, generated-top wiring, SystemVerilog vector links,
and `actor_network.data_movements[]` metadata with
`kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`.

The bounded multi-route extension of that same route shape is now shipped as
`isf/atl_two_child_multi_data_pipeline.isf`. It keeps the same parent
transaction and child pair, then routes both `(writer.payload reader.payload)`
and `(writer.sideband reader.sideband)` with adjacent top-level drive calls
between `reader.done` and `writer.emit`. Lowering emits separate drive states,
separate handoff signals, generated child interface roles for both scalar
paths, and generated-top wiring for both paths.

Fan-in/fan-out data routing, mux/storage, CDC/reset remapping,
ready/backpressure, payload protocols, repeated triggers, trigger batches,
groups, recursive actor networks, cross-transaction continuation, and
permanent actor grouping remain backlog.

The shipped hardening does not widen that support. It locks focused
fail-closed coverage for missing or wrong-direction child payload ports and
route-cardinality violations around the shipped same-source/same-sink route
fixtures before any mux/storage, fan-in/fan-out, or payload-protocol work is
claimed.

The shipped width hardening narrows that payload-protocol backlog further by
allowing only same-width generated-child actor-to-actor route endpoints.
Mismatched widths remain fail-closed until explicit packing, truncation,
extension, slicing, storage, or mux semantics are selected.

The shipped clock/reset hardening narrows the CDC/reset-remap backlog by
requiring source and sink children in the generated-child actor-to-actor
route to share the parent clock/reset policy; mismatches fail closed until
explicit CDC bridge or reset-remapping semantics are selected.

The shipped self-route hardening narrows the loopback/storage backlog by
requiring source and sink actor qualifiers in the generated-child
actor-to-actor route to name distinct resolved children; same-child pairs
fail closed until explicit self-route, bypass, storage, mux, or fan-in/fan-out
semantics are selected.

The shipped repeated-trigger hardening narrows the repeated-activation
backlog by requiring the generated-child actor-to-actor route sequence to
contain only one source-child trigger and one sink-child trigger; extra
route-child triggers fail closed until explicit restart, pending-request,
trigger fan-in/fan-out, or multi-activation scheduling semantics are
selected.

The shipped repeated-wait hardening narrows the event-coupling backlog by
requiring the same route sequence to contain only one source-child event wait
and one sink-child event wait; extra route-child waits fail closed until
explicit event fan-in/fan-out, repeated wait sequencing, route-level wait
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped same-parent-transaction hardening narrows the route continuation
backlog by requiring the route sequence to stay inside one parent
transaction; split route clauses remain fail-closed until explicit pending
handoff storage, transaction rendezvous, cross-transaction scheduling,
muxing, ready/backpressure, or payload semantics are selected.

The shipped sink-trigger ordering hardening narrows the speculative
activation backlog by requiring the data drive call to precede the sink child
trigger; sink-before-drive route clauses remain fail-closed until explicit
delayed payload delivery, route storage, muxing, ready/backpressure, or
payload semantics are selected.

The shipped sink-event-wait ordering hardening narrows the event sampling
backlog by requiring the sink child event wait to follow the sink child
trigger; sink-wait-before-trigger route clauses remain fail-closed until
explicit pre-trigger acknowledgement, sticky event sampling, event replay,
route storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped source-event-wait ordering hardening applies the same
event-sampling boundary on the source side by requiring the source child
event wait to follow the source child trigger; source-wait-before-trigger
route clauses remain fail-closed until explicit pre-trigger acknowledgement,
sticky event sampling, event replay, route storage, muxing, ready/backpressure,
or payload semantics are selected.

The shipped route-contiguity hardening narrows the route-interleaving
backlog by requiring the same route sequence to stay one contiguous
transaction-body segment; unrelated parent clauses interleaved between route
clauses remain fail-closed until explicit interleaved parent work, local side
effects, pre/post route sampling, route continuation, storage, muxing,
ready/backpressure, or payload semantics are selected.

The shipped route-isolation hardening narrows the pre/post-route side-effect
backlog by requiring the contiguous route segment to remain the only
executable parent transaction-body work between start and completion; parent
clauses before the source trigger or after the sink event wait remain
fail-closed until explicit setup, cleanup, local side effects, continuation,
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped route-boundary cardinality hardening narrows the activation and
completion boundary backlog by requiring that isolated route to stay bounded
by exactly one simple start boundary and one simple completion boundary;
extra start or completion clauses remain fail-closed until explicit
activation fan-in, completion fan-out, start arbitration, setup/cleanup,
continuation, storage, muxing, ready/backpressure, or payload semantics are
selected.

The shipped boundary-simplicity hardening narrows the boundary-body backlog
by keeping those start/completion boundaries body-free; activation-body
samples in `(on ...)` and extra payload operands in `(complete ...)` remain
fail-closed until explicit activation-body sampling, completion payload,
setup/cleanup, continuation, storage, muxing, ready/backpressure, or payload
semantics are selected.

The shipped boundary-role hardening narrows the parent-interface boundary
backlog. For the generated-child actor-to-actor route, the start boundary
must remain a scalar top-level input pin, and the completion boundary must
remain a scalar top-level output pin. Output-as-start, input-as-completion,
undeclared, and wider boundary pins fail closed until explicit interface
remapping, activation fan-in, completion fan-out, boundary expressions,
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped generated-handoff collision hardening narrows collision coverage
for that same route. Parent interface or actor-owned storage declarations
that collide with generated trigger, event, data, or named-drive request
handoffs fail closed before any generated-handoff remapping, route
mux/storage, fan-in/fan-out, interface remapping, ready/backpressure, or
payload semantics are claimed.

The shipped lowerer defensive backstop covers the same handoff names for
malformed or mutated scheduler-facing actor metadata that bypasses normal
parser finalization. Those collisions now fail closed before generated-top
wiring. This did not select a new authoring surface, generated-handoff
remapping, route mux/storage, fan-in/fan-out, ready/backpressure, or payload
semantics.

The dedicated generated-child route terminology section is audit-backed in
the mdBook. This is a documentation truth guard for handoff remapping, route
mux/storage, fan-in/fan-out, ready/backpressure, payload protocols,
parser/lowerer collision ownership, and the current one-bit drive-call-cycle
boundary, not a behavior widening.

The selected documentation precision pass for that same section is now
shipped. The route terms are presented as a term-by-term support boundary so
the current definitions, shipped subset, and deferred behavior are reviewable
without reading implementation code.

Parameterized route drive definitions and route drive calls with actual
arguments also remain outside the shipped ATL actor-to-actor, pin-ingress, and
pin-egress route families. Those forms fail closed before drive actual binding,
expression movement, route mux/storage, or payload protocol behavior can be
inferred.

Route endpoint expressions also remain outside that route. The selected
source stays the scalar endpoint `reader.payload`; a source expression such
as `(+ reader.payload 1)` fails closed before expression movement, value
transformation, storage, or payload protocol behavior can be inferred. The
selected sink stays the scalar endpoint `writer.payload`; a sink expression
such as `(+ writer.payload 1)` fails closed before expression destinations,
route-side transforms, storage, or payload protocol behavior can be inferred.

The source-expression source-order diagnostic is now shipped:
drive-before-instance malformed source expressions such as
`(writer.payload (+ reader.payload 1))` report the same targeted ATL
source-expression diagnostic after actor instances are known. It does not
select expression movement, route-side transforms, storage, muxing,
ready/backpressure, or payload protocols.
That sink-expression diagnostic is source-order independent for
endpoint-looking malformed route sinks, while ordinary malformed local drive
targets such as `((out) 1)` keep the generic drive-body scalar-head
diagnostic.
The accepted scalar generated-child route is source-order independent too:
placing the named route drive before the direct static actor instances still
resolves to the same generated ATL top handoffs and
`actor_network.data_movements[]` metadata.

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
actor transaction trigger wiring beyond the parent-handoff subset. Multiple
waits, nested waits, fan-in, fan-out, event payloads, cross-clock events, and
concurrent group events stay fail-closed/deferred. Existing unqualified local
forms stay unchanged:
`(await signal)` remains a transaction wait, and rule-level
`(trigger transaction)` remains a local transaction trigger. Dotted
enum-looking names that do not name a static actor instance keep their prior
diagnostics.

The shipped qualified actor-transaction trigger subset mirrors that handoff
boundary. One top-level transaction-body `(trigger actor.transaction)` against
a direct static actor instance lowers to a generated one-cycle parent output
named `actor_transaction_start`; for example, `reader.capture`
maps to `reader_capture_start`. One top-level rule action may use the same
qualified trigger spelling; for example, `(trigger worker.process)` in a rule
lowers through `worker_process_start`. The scheduled parent `.fsm` exposes
and pulses that output at the trigger point, and schedule JSON records the
trigger under `actor_network.transaction_triggers[]`.

```lisp
(actor atl_rule_transaction_trigger
  (clock clk)
  (interface (input fire) (output done))
  (instance worker of packet_worker)
  (transaction run
    (on fire)
    (complete done))
  (rule kick fire
    (trigger worker.process)))
```

The trigger sink remains external until later ATL leaves resolve actor types,
generate child artifacts, emit ATL tops, and add ready/backpressure or payload
semantics. Nested triggers, repeated triggers to the same actor instance,
repeated rule-action qualified triggers, generated handoff signal conflicts,
fan-in, fan-out, rule-action trigger payloads or bindings, cross-clock
triggers, and broader concurrent group behavior stay fail-closed/deferred.

Direct actor-body proposal (backlog illustration; uses syntax that
is still on the deferred list, so the validator rejects this fixture
today — kept here to document the future direction):

```text
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
transaction activations.

They now define public actor-network source surfaces: static actor instance
declarations and compact `(NAME : ACTOR_TYPE)` aliases, library-qualified
resolved child artifacts, and report-only static group declarations plus
compact `(concurrent NAME ACTOR...)` aliases recorded as `actor_network`
metadata. Parent transactions can use selected child trigger/event handoffs,
one bounded temporary trigger batch followed by source-ordered event waits,
and selected generated-child data routes written with existing drive-body
`(sink source)` movement syntax.

Resolved ATL child `.fsm` files and bounded generated ATL tops are shipped for
the documented one-child/two-child resolved-child trigger/event and data-route
subsets. The public report surface includes `actor_network.generated_tops[]`
and `actor_network.data_movements[]` evidence for those subsets; private
generated-top data-link plumbing remains outside the public contract.

Route mux/storage, handoff remapping/storage, payload protocols,
ready/backpressure, CDC/reset remapping, fan-in/fan-out, compact movement
aliases, group endpoints, runtime group scheduling, inferred child interface
bindings outside the documented generated-child subsets, broader global
scheduling ownership, and broader fail-closed boundaries remain under
task-tree ownership.

This direction is still IAL1 if the source remains explicit actor/network
`.isf` syntax with scheduler-visible events, bindings, and constraints.

It becomes an IAL2 candidate only if the source model moves above explicit
ISF actor/network syntax into protocol/platform intent inference.

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

Rule/drive overlap is still tracked because compile-time proof is not doable.

Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction/transaction priority, drive/rule
arbitration policy, and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: shipped for ordinary flopped rule assignments.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(set port expr)`, `(port expr)`,
`(trigger transaction)`, and `(priority over other_rule)`.

Trigger targets and priority targets remain scalar-only today.

`(set port expr)` is the canonical explicit setter; `(port expr)` remains
shorthand.

Both lower as flopped `<-` rule assignments under the rule DT DTE, where
`expr` may be a scalar token or one list expression from the transaction
`set`/`update`/`.fsm` RHS expression domain.

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

## Backends And Validation

### Full VHDL Backend

Status: partially shipped; full backend remains backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI and `FSM::Pipeline::HDLGenerator` route
`target_language => 'vhdl'` direct single-FSM roots through
`FSM::HDL::FlattenedDT::Backend::VHDL`. The scaffold emits deterministic VHDL
entity/architecture text for scalar/vector ports, state constants,
continuous enable assignments, `process(all)` combinational muxes, sync-reset
clocked processes, async-reset clocked processes, delayed-pulse clock-branch
nested-if lowering, generic-bearing direct-root module headers as VHDL integer
generics or typed scalar/vector generics for sized-literal defaults, basic
concat RHS forms, scalar addition/subtraction/multiplication RHS/chain
lowering, generated scalar `bit` internal declarations as `std_logic`,
generated signed vector internal declarations as VHDL `signed`, generated mux
arithmetic with vector signal plus/minus numeric literal operands through
target-width `to_unsigned` casts, same-width vector addition/subtraction RHS
chain lowering through `numeric_std` unsigned casts, same-width vector
multiplication/division/modulo RHS chain lowering through explicit
target-width `numeric_std` resize, same-width scalar/vector XOR chain lowering
through VHDL `xor`, and generated non-signed four-state `logic` scalar/vector
internal declarations as `std_logic` / `std_logic_vector`, plus generated
vector `logic signed` internal declarations as VHDL `signed` signals and
generated signed vector direct-root port declarations as VHDL `signed` ports,
and same-width signed vector addition/subtraction/multiplication/division/modulo RHS
assignments as signed VHDL arithmetic.
It is covered by direct pipeline, CLI, and facade tests.

Still backlog: composition/top VHDL, aggregate VHDL record/array lowering,
VHDL packages, multi-clock domains, GHDL validation, broad expression parity,
scalar signed arithmetic, mixed signed/unsigned arithmetic, and full feature
parity with the SystemVerilog backend. Scalar division/modulo,
broader scalar arithmetic beyond scalar addition/subtraction/multiplication
chains, broader arithmetic operators, mismatched-width arithmetic, and
expression contexts beyond the same-width
addition/subtraction/multiplication/division/modulo/XOR RHS chain family remain
fail-closed at the scaffold boundary. Scalar `A / B` and `A % B` are locked as
explicit fail-closed direct VHDL boundaries by focused pipeline and facade
coverage. The maintained
arithmetic/XOR and runtime division/modulo corpora now lower through the direct
VHDL scaffold for that family, and the maintained size-expression width fixture
now lowers generated direct-root parameter blocks to VHDL integer generics.
Generated sized-literal generic defaults such as `1'b1` and `1'b0` now lower
to typed `std_logic` generics in the maintained aggregate-parameter comparison
fixture, and multi-bit sized-literal generic defaults now lower to typed
`std_logic_vector` generics in the maintained aggregate unary complement
fixture. Composition VHDL generic maps remain deferred until a composition VHDL
leaf owns that path. Aggregate-output roots are locked as explicit fail-closed
direct VHDL boundaries. Composition/top VHDL is locked fail-closed after typed
composition IR parsing, with the pipeline and CLI pointing users to the scoped
composition target-support diagnostic instead of emitting a VHDL top.

The compound update and update-shorthand fixtures now lower generated
direct-root vector arithmetic with numeric literal operands, such as `SRC + 2`,
`SRC - 1`, `byte_count + 4`, and `remaining - 3`, through target-width
`to_unsigned` casts. The declarative bits symbolic-width fixture now lowers
generated scalar `bit` and signed vector internal declarations, such as
`bit FLAG;` and `reg signed [3:0] NIB;`, to VHDL `std_logic` and `signed`
signals. Package-backed declarative `+types` fixtures now lower generated
non-signed four-state `logic` internal declarations, such as
`logic [7:0] ISYM;` and `logic LFLAG;`, to `std_logic_vector` and `std_logic`.
Generated internal `logic signed [MSB:LSB] NAME;` declarations now lower to
VHDL `signed` signals. Generated signed vector direct-root port declarations,
starting with `input logic signed [7:0] IN`, now lower to VHDL `signed` ports.
Generated signed scalar direct-root declarations from one-bit signed type
aliases, such as `input logic signed IN` and `logic signed OUT;`, now lower to
VHDL `std_logic` ports/signals for non-arithmetic shapes; signed scalar
arithmetic remains fail-closed.
Same-width signed vector addition/subtraction/multiplication/division/modulo
RHS assignments now lower as signed VHDL arithmetic when the target and all operands are
same-width signed vectors, so a signed direct-root `SUM = (+ A B)` assignment
emits `SUM <= A + B;`, a signed `DIFF = (- A B)` assignment emits
`DIFF <= A - B;`, and a signed `PROD = (* A B)` assignment emits
`PROD <= resize(A * B, 8);`. Signed `QUOT = (/ A B)` emits
`QUOT <= resize(A / B, 8);`, and signed `REM = (% A B)` emits
`REM <= resize(A mod B, 8);`, rather than unsigned casts. Scalar signed
arithmetic, mixed signed/unsigned arithmetic, composition/top VHDL, aggregate
VHDL, packages, GHDL validation, and full backend parity remain outside the
shipped scaffold. Signed vector numeric-literal
addition/subtraction/multiplication/division/modulo also lower through
target-width `to_signed`, so `SUM = (+ A 1)` emits
`SUM <= A + to_signed(1, 8);`, `DIFF = (- A 1)` emits
`DIFF <= A - to_signed(1, 8);`, `PROD = (* A 2)` emits
`PROD <= resize(A * to_signed(2, 8), 8);`, `QUOT = (/ A 2)` emits
`QUOT <= resize(A / to_signed(2, 8), 8);`, and `REM = (% A 2)` emits
`REM <= resize(A mod to_signed(2, 8), 8);`. Mixed signed/unsigned vector
numeric arithmetic is locked fail-closed rather than lowering signed operands
through unsigned casts.

### GHDL Validation

Status: backlog, behind a VHDL validation leaf.

Goal: add GHDL validation once the VHDL backend subset is hardened enough for
tool validation.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys. The direct VHDL scaffold is regression-tested through deterministic
text and CLI routing, but not externally validated by GHDL yet.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set
covering the direct protocol/MIPI/trial samples named in
[Generated HDL Debugging And Inspection](09-generated-hdl-debugging-and-inspection.md)
plus the APB composition top `fsm/apb_tb.fsm`.

It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

Current shipped boundary: the external validation support and manifest surfaces
report optional ABC executable discovery candidates while keeping ABC disabled,
non-required, and outside the shipped CLI validation command sequence. The
in-process support API now has an explicit opt-in mapping probe:
`FSM::Support::HDLExternalValidation::validate_systemverilog_file(...,
abc_mapping => 1)`. That mode requires optional ABC discovery and runs Yosys
`synth -top`, while default `--verify-hdl` remains ABC-free with
`synth -noabc`.

Remaining hardening direction: any ABC-backed Yosys optimization/mapping gate
still needs broader timeout/error policy and regression coverage before it can
become a validation requirement or CLI default.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

Current shipped boundary: the programmatic facade contract and capability
manifest publish `default_generation_mode: flattened_debug_first`,
`generation_mode_names: ["flattened_debug_first"]`, and
`structured_nonflattened_generation_enabled: false`. `generation_mode` remains
absent from public constructor options until a real backend path is implemented
and regression-backed.

## Embedding And Public APIs

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

Current shipped boundary: the capability manifest advertises the JSON-safe
generation-result snapshot contract directly as
`embedding.serializable_generation_result_snapshot`, preserves the existing
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
reference, and keeps raw `HDLGenerator` result objects out of the public JSON
API.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.

Current shipped boundary: the normalized semantic payload contract publishes
`optional_child_presence_keys` for `semantic.composition` and
`semantic.symbol_contract`, and the report contract republishes that list as
`success_semantic_optional_child_presence_keys`. The
`semantic.composition` contract also advertises bounded
`children[]`, `children[].parameter_overrides[]`, `generated_children[]`,
`generated_children[].parameter_overrides[]`, and `standalone_dt_children[]`
shallow/alias entry key families while delegating child `intent_hir`,
`lowered_rtl_ir`, and `structural_rtl_ir` summaries to their existing bounded
owners. The standalone-DT
child family also advertises bounded reusable-DT enable-family metadata,
module-enable-family metadata, and nested multi-drive target metadata while
delegating the assertion shape to the existing lowered-RTL standalone-DT
multi-drive assertion owner. The same contract also advertises the
composition-side `shared_datapath_candidates[]` alias family by delegating to
the already bounded lowered-RTL shared-datapath candidate, contributor,
drive-intent, aggregate-enable, assertion, and bound-connection schemas. The
`semantic.forward_ir.lowered_rtl_ir` contract also advertises the emitted
`output_drive_family_count` and `output_drive_families` metadata with bounded
entry keys for `output_drive_families[]` and its nested
`rhs_enable_families[]` entries. It also advertises
`selector_conflict_target_count` and `selector_conflict_targets` metadata,
including bounded entry keys for `selector_conflict_targets[]`, nested
`rhs_enable_families[]`, and selector assertion metadata. It also advertises
`standalone_dt_multi_drive_target_count` and
`standalone_dt_multi_drive_targets` metadata, including bounded entry keys for
`semantic.forward_ir.lowered_rtl_ir.standalone_dt_multi_drive_targets[]` and
its nested `multi_drive_assertion` metadata. It also advertises bounded entry
keys for
`semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]`,
including optional declared-type extensions, contributor entries, contributor
`bound_connection_expr` metadata, contributor `drive_intent` entries plus
nested drive-intent `rhs_enable_families[]` entries, aggregate enable-family
entries, aggregate family contributors, and multi/same-value assertion
metadata. It also advertises bounded alias key families for
`semantic.forward_ir.intent_hir.composition_children[]`,
`semantic.forward_ir.intent_hir.composition_generated_children[]`, and
`semantic.forward_ir.intent_hir.composition_standalone_dt_children[]` by
delegating to the existing `semantic.composition` child and standalone-DT child
schema owners. It also advertises
`semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]`
and
`semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]`
by delegating through the composition aliases to the structural instance
parameter-override schema owner. Contributor and child `intent_hir`,
`lowered_rtl_ir`, and `structural_rtl_ir` summaries stay delegated to their
existing bounded contracts. The
`semantic.forward_ir.structural_rtl_ir` contract also advertises bounded
`ports[]` core entry keys, composition-top port extension keys, and bounded
`nets[]`, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, and
nested `instances[].interface_ports[]` plus `instances[].port_bindings[]`
core and typed-extension entry keys. It now also advertises
`instances[].parameter_overrides[]` core, raw-value-extension, and
value-metadata-extension entry keys, and advertises `auxiliary_assignments[]`
as scalar string assignment-line entries. The `semantic.composition` contract
now also advertises `children[].parameter_overrides[]` and
`generated_children[].parameter_overrides[]` as aliases of those same
structural instance parameter-override core, raw-value-extension, and
value-metadata-extension schemas. The manifest is still not a full normalized
semantic export.

Shipped generated-child export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.51.1` publishes
`parameter_override_count`, `parameter_overrides[]`, and bounded
parameter-override alias key families for
`semantic.composition.generated_children[]` and
`semantic.forward_ir.intent_hir.composition_generated_children[]`. Full
normalized semantic export stabilization remains out of scope.

Shipped symbol-contract constants export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.52.1` publishes bounded scalar/list value key
families for `semantic.symbol_contract.constants` and
`semantic.forward_ir.intent_hir.symbol_contract.constants`. Every advertised
constant value carries `kind`; scalar values add `payload`, and list values add
`items`. That constants edge did not widen enum/type nested schemas,
package-import internals, or full normalized semantic export stabilization.

Shipped symbol-contract enum export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.53.1` publishes enum value-kind families for
`semantic.symbol_contract.enums` and
`semantic.forward_ir.intent_hir.symbol_contract.enums`. Enum entries are
member-payload maps, and dynamic enum members carry scalar payloads. Type
nested schemas, package-import internals, already bounded constant internals,
and full normalized semantic export stabilization remain out of scope.

Shipped symbol-contract type export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.54.1` publishes bounded recursive type-entry
schema metadata for `semantic.symbol_contract.types` and
`semantic.forward_ir.intent_hir.symbol_contract.types`. Scalar entries carry
`kind`, `signed`, `width`, and optional `state_model`; aggregate entries carry
recursive `items` or `members` plus `member_order`.

Current active backend edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.65.1` locks signed scalar subtraction and
multiplication arithmetic fail-closed coverage after `.65` confirmed those
operators already stop at the arithmetic guard.
Package-import internals, already bounded constant/enum/type internals,
unrelated forward-IR payloads, scalar signed arithmetic,
aggregate/composition VHDL, and full normalized semantic export stabilization
remain out of scope until later exact leaves own them.
