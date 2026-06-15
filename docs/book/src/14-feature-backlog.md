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
  `(repeat ...)` directly in a single `(while ...)`/`(until ...)` body now lower.
  Multi-pending `(await_any done)` with later same-body `(await_all done)` and
  the documented pending-spawn local-`do` drain shapes also lower; undrained,
  cross-domain, and unstated wider local-`do` variants stay deferred.
- **Deeper-nested repeat-body `do`/`spawn`**: a plain local `(do child)`
  (`t/1381`), a same-domain generated `(do child (params ...))` (`t/1382`), and
  the basic spawn + drain subset (`t/1383`) plus multi-pending `(await_any done)`
  with later same-body `(await_all done)` (`t/1384`) at deeper branch nesting
  (`when⁺ → repeat`, `switch → when⁺ → repeat`) now lower; undrained and
  cross-domain generated `do` stay deferred.
- **Depth-neutral scheduler target**: the intended compositional scheduler
  contract has no arbitrary nesting-depth limit. Deep mixed chains such as
  `while -> do -> spawn -> call -> do -> while -> spawn -> spawn -> do -> do`
  are valid in principle when typed region/effect proofs establish child
  lifetime, loop backedge, binding/domain, generated-instance, and CDC
  invariants. Current bounded depth/context allow-lists remain migration cuts,
  not the target public contract.
- **Depth-neutrality audit boundary**: current hard requirements are the
  child-lifetime and loop-backedge proofs, `await_any` observation versus
  `await_all` drain semantics, deterministic generated-child identity,
  generated-top handoffs, explicit same-domain binding/domain contracts, and
  explicit CDC contracts. Cross-domain `spawn`, implicit CDC, payload CDC, and
  dynamic per-iteration hardware remain real missing contracts. By contrast,
  the former exact one/two/three/four loop-contained fanout gate has been
  replaced by exact-set proof consumption; the loop-plus-branch
  plain-local-only island, nested `switch` / extra-loop deferrals, and
  generated-activation case splits remain migration cuts.
- **Book example correctness build gate**: every `lisp`-tagged book
  example must parse + lower (`t/1376`). Current state: 80
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
scalar/vector ports, basic enables, reset processes, concat assignments, and
bounded aggregate-output packed-vector lowering. Full aggregate VHDL
record/array lowering is still not shipped. The maintained direct aggregate
output fixtures lower their generated packed struct outputs as VHDL
`std_logic_vector` ports while preserving flattened mux assignments.
Declared aggregate structural VHDL ports/nets/types in composition tops are
locked fail-closed by `BACKEND-API-VALIDATION-FRONTIER.101.1` before any
record/array declaration emission.
The first bounded composition VHDL structural top is also shipped for the C3
external-RTL literal/concat fixture in
`t/corpus/composition_intent_integer_literals.fsm`. The bounded C1
standalone-DT passthrough composition VHDL top is shipped for
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, emitting the child VHDL
entity and a top-level `entity work.standalone_route_src` port map. Neither
composition leaf provides VHDL record/array aggregate lowering.

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

Source-authored `group.name` endpoints now have a targeted fail-closed
boundary. If the qualifier names a declared static group, transaction-body
`(trigger group.name)`, `(await group.name)`, `(await_all group.name)`,
`(await_any group.name)`, and rule-action `(trigger group.name)` fail with an
ATL group-endpoint diagnostic. Accepting those forms still requires a later
contract for group-level trigger arbitration/fanout, event aggregation,
storage/lifetime, and generated-child wiring semantics.

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
CDC, or ready/backpressure. Repeated waits to the same triggered actor after
a trigger batch fail closed with a diagnostic that names the missing event
re-arm or per-event generation/lifetime contract. `await_all`/`await_any`
clauses with qualified actor-event operands fail closed too; those sync forms
remain generated-child completion joins until an explicit actor-event join
contract adds event latch/storage and lifetime semantics.

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

The selected resolved-child trigger-batch generated-top case is also shipped
as `isf/atl_two_child_trigger_batch_pipeline.isf`. It keeps two resolved
children and no data movement, emits one same-cycle parent trigger-batch state
for `reader.capture` and `writer.emit`, waits on `reader.done` and
`writer.done` in source order, and writes parent, both children, and one
generated top. Schedule JSON preserves `transaction_triggers[]`,
`event_waits[]`, `association_schedules[]`, and `group_schedules[]`, then
advertises the generated top with kind
`resolved_children_trigger_batch_event_sequence`.

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
ready/backpressure, payload protocols, repeated triggers, broader
trigger-batch combinations including data movement coupling, groups,
recursive actor networks, cross-transaction continuation, and permanent actor
grouping remain backlog.

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
one bounded temporary trigger batch followed by source-ordered event waits to
distinct triggered actors, and selected generated-child data routes written
with existing drive-body `(sink source)` movement syntax.

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

Status: first bounded IAL2 implementations and `.ppif` Valid-Ready parser/CLI
surface shipped; broader IAL2 remains backlog. IAL2 feature completeness on the
SystemVerilog-backed path is the current priority before VHDL backend/reroute
work resumes.

Historical task-tree record:
[IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION](../../tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md).
That tree is closed; future IAL2 behavior changes need a new task-tree leaf
before implementation.

Active frontier:
[IAL2-FEATURE-COMPLETENESS-FRONTIER](../../tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md)
owns the next IAL2 feature-completeness work. Its first selector audited the
shipped `.ppif` Valid-Ready single/bundle surface and moved the frontier to
the first AXI manager rule-subset selection/pre-code contract. That selector
chose outstanding-capacity plus acceptance/status feedback as the first
post-Valid-Ready manager subset. The completed readiness audit for that subset
found no IAL1 or IAL0/SystemVerilog prerequisite blocker and selected an
in-process generator as the first behavior-bearing capacity/status slice
before public `.ppif` syntax. That in-process generator is now shipped. The
public `.ppif` capacity/status parser/CLI first slice is now shipped for one
manager object with sample, manifest, support-accounting, semantic JSON, check
JSON, generated review artifacts, HDL, `--verify-hdl`, mdBook, and focused
diagnostics. The next AXI manager subset is selected as ID-family declaration
and static validation, and the additive optional `(id-families ...)` `.ppif`
extension is now shipped for the existing capacity/status object with report
metadata and unchanged generated `.isf`, generated `.fsm`, and HDL behavior.
The next AXI manager subset is selected as a machine-readable AST/structural
logical read/write transaction envelope and static-validation contract; the
readiness audit selects an additive optional `(transactions ...)` static/report
metadata extension under the existing `manager-capacity-status` object. That
optional transaction-envelope metadata slice is now shipped with a separate
sample, structural report entries, check JSON and semantic JSON source
identity, and initially unchanged generated `.isf`, generated `.fsm`, and HDL
behavior.
The transaction event dispatch and direction fan-in slice is now shipped for
that same object. Distinct per-transaction request/completion events become
generated IAL1 inputs, multi-event direction groups use OR fan-in guards, the
existing IAL1/IAL0/SystemVerilog path carries the behavior, and schedule JSON
additively reports `transaction_event_dispatch` metadata. The concrete
transaction ID assertion slice is now shipped: transactions with concrete
requested IDs declare used ID-family request/response ID signals as generated
IAL1 inputs, lower assertion-only checks to `.fsm` `+assert` carriers, emit
verification-only SystemVerilog assertions, and report
`id_response_rule_engine` metadata. Auto-ID allocation, ID release, response
demux, ordering, bursts, queued policy, aliases, full-manager behavior, and
VHDL remain residue. The next selector chose AXI manager auto-ID
lifecycle/request-ID drive readiness as the next subset. Completed readiness
audit `.20` concluded that the IAL1/IAL0/SystemVerilog substrate can carry a
bounded scalar request-ID lifecycle, but auto-ID allocation must not be
inferred directly from ID width or existing `(id auto)` syntax. Completed
selector `.21` chose an explicit optional `(auto-id-lifecycle (write (pool
...)) (read (pool ...)))` clause. Completed implementation leaf `.22` shipped
that parser/report metadata and static-validation slice with unchanged
generated `.isf`, `.fsm`, and HDL behavior. Completed implementation leaf
`.23` ships bounded request-ID drive behavior for explicit auto-ID lifecycle
families. Completed selector `.24` chooses AXI generated response-demux
readiness as the next exact subset. Completed readiness audit `.25` selects a
bounded write `BID` response-demux public contract selector first, because
existing transaction `completion` names are authored inputs and must not be
silently reinterpreted as generated demux signals. Completed selector `.26`
chooses explicit write-only `(response-demux ...)` syntax. Completed
implementation leaf `.27` ships parser/report metadata and static validation
for that explicit opt-in while keeping generated `.isf`, `.fsm`, and HDL
behavior unchanged. Completed readiness audit `.28` concludes that generated
write `BID` demux completion names need an IAL1 rule-owned one-cycle pulse
action first. Completed implementation leaf `.29` ships bounded IAL1
`(pulse target)` rule actions that lower as `<1` pulse-domain assignments.
Completed implementation leaf `.30` ships generated write `BID`
response-demux behavior through those pulse completions. Completed selector
`.31` selects `.32` to align `auto_id_lifecycle.residue` with that shipped
behavior before larger ordering/read-response work. Completed implementation
leaf `.32` ships that report-residue alignment. Completed selector `.33`
selects `.34` as the AXI same-ID ordering readiness audit. Completed
readiness audit `.34` selects `.35` as the bounded auto-ID same-ID avoidance
assertion/report slice. Completed implementation leaf `.35` ships that
boundary and advances the active leaf to `.36`, the next selector.
Selected IAL2 slices may include explicit IAL1 or
IAL0/SystemVerilog prerequisites when those prerequisites are needed for
clean, reviewable lowering.

Evaluation note:
[IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION](../../IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md).

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). `IAL2` now has a
first bounded shipped surface for one AXI Valid-Ready protocol intent object,
multi-channel Valid-Ready bundles, and one AXI manager capacity/status shell
through public `.ppif`, including optional static ID-family metadata and
optional structural transaction-envelope metadata with per-transaction event
dispatch/fan-in plus concrete transaction ID request/response assertions.
Broader IAL2 still must justify itself with semantics above individual
transactions, not only syntax convenience. Its generic file surface remains
protocol/platform-generic, and an IAL2 file may select a protocol or platform
vocabulary inside the file.

IAL0, IAL1, IAL2, and this book describe backend-language-neutral contracts,
not Perl-only implementation APIs. The current Perl 5 codebase is the
reference implementation/oracle. Future Rust, Rust/Wasm, browser-capable
JavaScript, and Dart/web implementations should preserve the same source
syntax, generated review artifacts, reports, diagnostics, and HDL behavior
through suitable host abstractions rather than creating parallel semantics. Decision
[0018](../../decisions/0018-ial-contracts-are-backend-language-neutral.md)
records this rule.

Decision `0016` selects `.ppif` (Protocol/Platform Intent Format) as the first
public generic IAL2 file suffix. Earlier candidates `.pif` and `.ppi` are not
first implementation suffixes.

Protocol-specific extensions such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` may also be accepted later as vocabulary/profile
aliases over the same IAL2 model. They are not separate layers and do not get
direct-lowering privileges.

The mandatory lowering chain is `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL`.
Direct `IAL2 -> IAL0` lowering is forbidden.

The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

Current evaluation: IAL2 now has a first in-process behavior-bearing slice for
an AXI Valid-Ready contract object, a first public `.ppif` parser/CLI slice for
that same object shape, multi-channel Valid-Ready bundle behavior, and a public
`.ppif` AXI manager capacity/status shell with reviewable generated `.isf` and
`.fsm` artifacts plus optional ID-family metadata, transaction-envelope
metadata, per-transaction event dispatch/fan-in, and concrete transaction ID
request/response assertions. It also ships optional auto-ID lifecycle
bounded-pool parser/report metadata plus bounded request-ID drive behavior
for explicit lifecycle families.
Future implementation leaves must choose exact owners for the next protocol
rule subset, additional `.ppif` syntax, or aliases; a hand-written reusable
`.fsm` or `.isf` library alone is useful but not enough to justify IAL2.

The repo-local tracked raw AXI reference for future bounded probes is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`.
It is evidence for future task-tree-owned protocol-intent work, not a shipped
PDF/spec extraction capability.

Completed evidence probe:
[AXI-VALID-READY-INTENT-PROBE](../../tasks/AXI-VALID-READY-INTENT-PROBE.md)
extracted the first valid/ready source-anchor evidence inventory without
selecting parser, lowering, `.fsm`, or HDL implementation behavior.

Evidence note:
[AXI_VALID_READY_INTENT_PROBE](../../AXI_VALID_READY_INTENT_PROBE.md)
records the AXI Valid-Ready anchors, source facts, inferred candidate model,
explicit abstractions, unsupported residue, and no-implementation status. It
is evidence for a future task-tree-owned IAL2 design/probe leaf, not a shipped
PDF/spec extraction capability and not an IAL2 implementation.

ID/order evidence note:
[AXI_ID_ORDERING_RULE_EVIDENCE_PROBE](../../AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
records the first AXI ID/order/concurrency source anchors for future manager
rule-engine work. The note covers ID families, outstanding transactions,
same-ID response ordering, response matching through `BID`/`RID`,
read-data interleaving, write-data sequencing, interconnect ID remapping, and
explicit residue. It confirms that Easy mode should not be reduced to
one-transaction-at-a-time behavior; concurrency belongs in the manager, backed
by source-anchored ID allocation, ordering, matching, interleaving, and
capacity-feedback rules.

Rule-matrix design/probe:
[AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE](../../AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
maps the captured Valid-Ready and ID/order evidence into a first future AXI
manager rule responsibility matrix. It classifies candidate responsibilities
as static authoring checks, generated scheduler/scoreboard behavior, runtime
assertions, environment assumptions, or unsupported residue. It still selects
no source syntax, parser, lowering, `.isf`, `.fsm`, HDL, assertion text, queue
default, or ID allocation algorithm.

First post-Valid-Ready manager subset:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md)
selects outstanding transaction capacity plus acceptance/status feedback as
the next AXI manager rule family. The selected source anchors are `A1.1`,
`A1.2`, and `A5.1`. The subset is expected to expose explicit read/write
`max-pending` depths, `try`-style acceptance feedback, full/pending/slots
status, and a capacity-only blocked-reason vocabulary while preserving
generated `.isf` and `.fsm` review artifacts before SystemVerilog HDL. It is
now shipped as a bounded capacity/status shell through an in-process generator
and public `.ppif` parser/CLI sample. It does not claim ID allocation,
ordering, interleaving, response matching, burst assembly, channel expansion,
`blocking`/`queued` policy behavior, profile aliases, or VHDL backend work.
The next manager behavior remains behind a selector.

Capacity/status readiness audit:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md)
finds that existing IAL1 actor storage, status-output, rule/update, scheduled
`.fsm`, and SystemVerilog generation surfaces can carry the first
capacity/status shell. The selected first implementation boundary is an
in-process IAL2 generator, tentatively
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, not public `.ppif`
syntax. The generator should accept a structured contract hash with explicit
read/write `max-pending` depths, `submit_policy => try`, abstract submit and
completion events, namespaced status outputs, and source anchors for `A1.1`,
`A1.2`, and `A5.1`. It must emit reviewable generated `.isf` before generated
`.fsm`, then use the existing SystemVerilog path. Public `.ppif`
capacity/status syntax, profile aliases, IDs, ordering, response matching,
bursts, queued/blocking policies, and VHDL remain future exact-owner work.

Capacity/status in-process generator slice:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md)
ships `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` as the first AXI
manager capacity/status IAL2 generator. It is an in-process API, not public
`.ppif` syntax:

```perl
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;

my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate({
    name              => 'axi0',
    intent_name       => 'axi_manager_capacity_status',
    protocol          => 'axi4',
    submit_policy     => 'try',
    clock             => 'clk',
    reset             => { signal => 'rst_n', active_low => 1, async => 1 },
    read_max_pending  => 4,
    write_max_pending => 2,
    read_submit       => 'axi0_read_submit',
    read_complete     => 'axi0_read_complete',
    write_submit      => 'axi0_write_submit',
    write_complete    => 'axi0_write_complete',
    status            => {
        read_can_accept       => 'axi0_read_can_accept',
        write_can_accept      => 'axi0_write_can_accept',
        read_full             => 'axi0_read_full',
        write_full            => 'axi0_write_full',
        pending_reads         => 'axi0_pending_reads',
        pending_writes        => 'axi0_pending_writes',
        read_slots_available  => 'axi0_read_slots_available',
        write_slots_available => 'axi0_write_slots_available',
    },
    source => {
        object_id => 'axi-manager-capacity-status',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A1.1' },
            { document => 'IHI0022_L_2025-08', section => 'A1.2' },
            { document => 'IHI0022_L_2025-08', section => 'A5.1' },
        ],
    },
});
```

The result exposes `generated_ial1.text` before `generated_ial0.files`. The
generated `.isf` parses through `FSM::Adapter::ISF`, lowers through
`FSM::Scheduler::ISF`, and reaches SystemVerilog through the scheduled `.fsm`
review artifact. The generated actor owns read/write pending counters, exposes
namespaced read/write `can_accept`, full, pending, and slots-available status
outputs, and emits explicit idle, submit-only, complete-only, and
submit+complete rule matrices per direction. Same-cycle submit+complete at a
full depth is accepted because the completion frees capacity in the same
cycle.

The IAL2 report schema is
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`. It includes
source anchors, generated artifact names, read/write capacity metadata,
status-output bindings, abstract-event bindings, generated rule summaries,
assumptions, enforced static rules, and explicit residue. Public `.ppif`
parser/CLI behavior, profile aliases, IDs, ordering, response matching, bursts,
queued/blocking policy, HDL blocked-reason outputs, and VHDL remain future
exact-owner work.

Public capacity/status `.ppif` syntax selection:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md)
selects the next public source shape. The selected syntax is one
`manager-capacity-status` object under the generic PPIF root:

```text
(protocol-platform-intent axi0_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A1.2) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A5.1) (page A5-1)))
  (manager-capacity-status axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-max-pending 4)
    (write-max-pending 2)
    (submit-policy try)
    (read-submit axi0_read_submit)
    (read-complete axi0_read_complete)
    (write-submit axi0_write_submit)
    (write-complete axi0_write_complete)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available))))
```

This syntax is now shipped by the public parser/CLI first slice below.

Public capacity/status `.ppif` first slice:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
ships the selected source shape as a runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status.ppif
```

The public sample is support-accounted as
`intent.ppif_axi_manager_capacity_status`. Schedule JSON emits
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`; `--outdir`
writes `axi0_capacity_status.isf` before `axi0_capacity_status.fsm`; default
HDL and `--verify-hdl` reach the generated `axi0_capacity_status`
SystemVerilog module; check JSON and normalized semantic JSON preserve the
public `.ppif` source path. The first public slice rejects mixed
`valid-ready-channel` plus `manager-capacity-status` files, multiple manager
objects, IDs, ordering, response matching, bursts, queued/blocking policy,
profile aliases, and VHDL behavior.

Next AXI manager subset: ID-family/static-validation:
[AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION](../../AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md)
selects the next bounded subset after capacity/status. The subset owns
separate read/write ID-family declarations, zero-width absence semantics,
static signal-pair validation, source anchors, and report metadata. The
selected semantic shape is:

```text
(id-families
  (write (width 4) (request-id AWID) (response-id BID))
  (read  (width 4) (request-id ARID) (response-id RID)))
```

Readiness audit:
[AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md)
selects the implementation boundary. The first implementation should add an
optional `(id-families ...)` clause under the existing
`manager-capacity-status` object, emit additive report metadata, and leave
generated `.isf`, generated `.fsm`, and HDL behavior unchanged.

First ID-family `.ppif` slice:
[AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE](../../AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
ships that boundary as the optional `(id-families ...)` clause under the
existing capacity/status object:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The zero-width absence form is explicit:

```text
(id-families
  (write (width 0))
  (read (width 0)))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_id_family.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_id_family`. Schedule JSON keeps
schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and
additively emits `id_families.write` and `id_families.read` with `width`,
`present`, request/response signal names for positive widths, and source
anchors. The same `axi0_capacity_status.isf`, `axi0_capacity_status.fsm`, and
SystemVerilog module are produced with or without `id_families`. ID
allocation, per-transaction ID validation, same-ID ordering, different-ID
interleaving, `BID`/`RID` response matching, bursts, queued/blocking policies,
profile aliases, and VHDL remain future task-tree-owned residue.

Next AXI manager subset: transaction envelope/static-validation:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md)
selects the next bridge between static manager metadata and dynamic manager
behavior. The selected subset is a machine-readable AST/structural logical
read/write transaction envelope with stable transaction names, read/write kind,
user-visible tags, request/completion event bindings, optional requested-ID
policy or value, source anchors, report metadata, and explicit residue. The
illustrative semantic shape is:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id auto)))
```

Readiness audit:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md)
selects the implementation boundary. The first implementation should add an
optional `(transactions ...)` clause under the existing
`manager-capacity-status` object, emit additive report metadata, and leave
generated `.isf`, generated `.fsm`, and HDL behavior unchanged. Transaction
request/completion bindings in this first slice must reference the existing
direction-level abstract events:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

First transaction-envelope `.ppif` slice:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
ships that boundary as the optional `(transactions ...)` clause under the
existing capacity/status object:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_transaction_envelope`. Schedule JSON
keeps schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and
additively emits `transactions[]` entries with `name`, `kind`, `tag`,
`request_event`, `completion_event`, `id`, and `source_anchors`. Concrete IDs
report `policy: concrete`, `value`, `family`, `family_width`, and `fits`.
At the time the transaction-envelope slice shipped, generated artifacts were
unchanged. The later concrete-ID assertion slice now makes concrete
`(id (value N))` transactions behavior-bearing: generated `.isf` declares the
used ID-family request/response ID signals, generated `.fsm` carries `+assert`
entries, and SystemVerilog emits verification-only assertions. Auto-ID
transactions remain report-only until an allocator slice ships. The manager
still does not implement ID allocation algorithms, dynamic user-ID validation
while issuing, same-ID ordering queues, different-ID interleaving, generated
`BID`/`RID` response demux, bursts, queued/blocking policy, profile aliases,
full AXI manager behavior, or VHDL.

First transaction-event dispatch `.ppif` slice:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md)
selected the prerequisite before ID allocation or response matching. The
readiness audit:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md)
selected an additive implementation boundary. The first implementation slice:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
ships that behavior under the existing optional `(transactions ...)` clause.
Distinct per-transaction request and completion events now fan into the
read/write capacity/status rule matrices through the current
IAL1/IAL0/SystemVerilog path:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id (value 3))))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_transaction_event_dispatch`.
Schedule JSON keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and additively
emits:

```text
transaction_event_dispatch:
  mode: per_transaction_event_fanin
  directions:
    - direction: write
      request_events:
        - axi0_w0_request
        - axi0_w1_request
      completion_events:
        - axi0_w0_complete
        - axi0_w1_complete
      request_fanin: "(| axi0_w0_request axi0_w1_request)"
      completion_fanin: "(| axi0_w0_complete axi0_w1_complete)"
    - direction: read
      request_events:
        - axi0_r0_request
      completion_events:
        - axi0_r0_complete
      request_fanin: axi0_r0_request
      completion_fanin: axi0_r0_complete
```

Generated `.isf` declares the transaction events as inputs and keeps scalar
one-event compatibility for directions with one transaction event. Multi-event
groups lower as OR fan-in guards, the generated `.fsm` preserves those guard
expressions, and SystemVerilog emits the equivalent OR expressions through the
existing backend. Concrete-ID transactions now also use this event provenance:
request/response ID assertions bind to per-transaction events such as
`axi0_r0_request` and `axi0_r0_complete`, while the capacity/status rule
matrix keeps the same fan-in behavior. The IAL1 rule-conflict proof now
understands the bounded OR/negated-OR guard shape used by this generated rule
matrix. This slice does
not implement or claim ID allocation, generated `BID`/`RID` response demux,
same-ID ordering, interleaving, bursts, payload binding, queued/blocking
policy, profile aliases, full AXI manager behavior, or VHDL.

Next AXI manager subset: ID/response rule-engine readiness:
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION](../../AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md)
selects the next frontier after shipped transaction event provenance. The next
leaf is not an implementation permission slip; it is a readiness audit that
must decide whether the first ID/response behavior can extend the existing
`manager-capacity-status` object through current IAL1/IAL0/SystemVerilog
substrate or whether a narrower prerequisite is needed first.
The readiness audit:
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
selects additive concrete transaction ID request/response assertions as the
first implementation boundary.

Concrete transaction ID assertion first slice:
[AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE](../../AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
ships that boundary without adding new public syntax. Existing machine-readable
ID-family and transaction metadata now become behavior-bearing when a
transaction uses concrete `(id (value N))`:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))))
```

Generated `.isf` declares the used ID-family request/response signals and emits
assertion-only checks:

```text
(input axi0_arid (width 4))
(input axi0_rid (width 4))

(transaction axi0_id_response_checks
  (assert (=> axi0_r0_request (== axi0_arid 3))
          "axi0 r0 request ID matches concrete ID")
  (assert (=> axi0_r0_complete (== axi0_rid 3))
          "axi0 r0 response ID matches concrete ID"))
```

The generated `.fsm` carries `+size` entries for the used ID signals and
`+assert` carriers. SystemVerilog emits verification-only concurrent
properties through the existing assertion backend. Schedule JSON additively
emits:

```text
id_response_rule_engine:
  mode: concrete_id_assertions
  id_signal_inputs:
    - axi0_arid
    - axi0_rid
  checks:
    - transaction: r0
      phase: request
      event: axi0_r0_request
      id_signal: axi0_arid
      id_value: 3
      enforcement: runtime_assertion
    - transaction: r0
      phase: response
      event: axi0_r0_complete
      id_signal: axi0_rid
      id_value: 3
      enforcement: runtime_assertion
  residue:
    - auto_id_allocation
    - id_release
    - same_id_ordering
    - response_demux
```

The shipped scope now includes bounded automatic request-ID allocation and
completion-event ID release only when the explicit `auto-id-lifecycle` clause
is present. Same-ID ordering queues, different-ID read-data
interleaving/reassembly, burst and last-beat tracking, payload binding,
queued/blocking policy, generated response demux, full AXI manager syntax,
profile aliases, and VHDL remain unshipped.

Shipped AXI manager subset: auto-id-lifecycle request-ID drive:
[AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md)
ships bounded request-ID drive behavior for the explicit lifecycle contract.
The earlier
[AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md)
implements the parser/report metadata boundary for the same syntax selected by
[AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md).
Auto-ID transactions are still report-only unless the opt-in clause is
present. With the clause present, request ID signals such as `axi0_awid`
become generated outputs, per-auto-transaction selected-ID/busy state is
generated, first-free allocation and completion release rules lower through
`.fsm`, and SystemVerilog declares the request ID and state registers.

The selected audit starts from the existing syntax:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id auto)))
```

The selected opt-in syntax is:

```text
(auto-id-lifecycle
  (write (pool 0 1))
  (read  (pool 0 1 2 3)))
```

Without that clause, existing `(id auto)` transactions remain
structural/report-only metadata. With that clause, the shipped implementation
validates positive-width ID families, one to four unique pool values per
family, values inside the declared width, and at least one auto-ID transaction
in each listed family. The structural report adds `auto_id_lifecycle` metadata
with `generated_behavior: true`, `request_id_direction: generated_output`,
`response_id_direction: generated_input`, `allocator: first_free_pool_order`,
`transaction_lifetime: single_active`, and `transaction_state[]` entries that
name generated selected-ID storage, busy storage, allocation rules, release
rules, and assertion carriers. Its residue is now `response_demux`; the later
same-ID avoidance slice below removed the covered generated auto-ID same-ID
residue.

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Its support-accounting entry is:

```text
intent.ppif_axi_manager_capacity_status_auto_id_lifecycle
```

The generated behavior uses request ID outputs for `AWID`/`ARID`, keeps
response ID inputs such as `BID`/`RID` absent unless concrete checks require
them, allocates first-free IDs in author pool order, enforces single-active
logical auto transactions, and releases IDs on completion events. Same-ID
ordering queues, generated response demux, read-data interleaving/reassembly,
bursts, queued/blocking policy, full AXI manager syntax, aliases, and VHDL
remain unshipped.

Selected next AXI manager subset:
[AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION](../../AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md)
selects generated response-demux readiness as the next exact slice after
bounded auto-ID request-ID drive. The audit must resolve response-channel
`BID`/`RID` ownership, response handshake/completion-event direction, generated
demux completion signals, report shape, and IAL1/IAL0/SystemVerilog substrate
before any response matching, same-ID ordering, read-data interleaving, burst,
queued-policy, alias, full-manager, or VHDL behavior changes.

Response-demux readiness audit:
[AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects a bounded write `BID` response-demux public-contract step before
parser/report or generated behavior changes. The audit finds no obvious
IAL1/IAL0/SystemVerilog blocker for a narrow write demux once the contract is
explicit, but the source must first define response accepted event naming,
transaction completion ownership, generated demux signal naming, diagnostics,
and report shape.

Write response-demux contract selection:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects the first public response-demux syntax:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

This first contract is write-only. `response-event` names the raw write
response accepted event and must equal top-level `write-complete` in the first
bounded slice. `transaction-completion generated` means write transaction
`completion` names become generated demux signals only under this explicit
opt-in clause. Without `response-demux`, completion names remain authored
inputs as they do today.

Shipped write response-demux first slices:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for the selected explicit
opt-in. The behavior follow-up:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
now generates bounded write `BID` response-demux behavior for the same source
shape. The checked-in sample is:

```text
ppif/axi_manager_capacity_status_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_response_demux.ppif
```

Generated IAL1 declares the raw write response event and `BID` as inputs,
declares each transaction completion as a generated pulse output, and emits
one demux rule per auto-ID write transaction:

```text
(input axi0_write_complete)
(input axi0_bid (width 4))
(output axi0_w0_complete)

(rule axi0_w0_response_demux
  (& axi0_write_complete axi0_w0_auto_id_busy_q
     (== axi0_bid axi0_w0_auto_id_q))
  (pulse axi0_w0_complete))
```

The generated `.fsm` lowers each demux completion through `<1` pulse-domain
assignments. The existing write capacity matrix and auto-ID release rules use
the generated completion pulse fan-in, so capacity and selected-ID release are
driven by the demuxed completion names rather than authored completion inputs.

The report additively emits:

```text
response_demux:
  mode: bounded_write_bid_demux_contract
  generated_behavior: true
  write:
    response_event: axi0_write_complete
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions: [w0, w1]
    generated_rules: [axi0_w0_response_demux, axi0_w1_response_demux]
    generated_completion_signals: [axi0_w0_complete, axi0_w1_complete]
    generated_assertions:
      - axi0_write_response_demux_active_match
      - axi0_w0_w1_write_response_demux_unique_match
  residue:
    - read_response_demux
    - read_data_interleaving
    - bursts
```

The generated assertion transaction checks that every accepted write response
matches an active auto-ID write transaction and that no accepted write response
matches more than one active auto-ID write transaction. The
`id_response_rule_engine` residue removes `response_demux` for this explicit
write demux behavior; concrete/per-ID same-ID ordering remains residue there.

Post-demux selector:
[AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION](../../AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md)
selects the next narrow slice, `.32`, to align `auto_id_lifecycle.residue`
with this shipped behavior. That implementation is now shipped:
[AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
documents the report-contract cleanup. Explicit generated write demux now
removes `response_demux` from `auto_id_lifecycle.residue`; the later same-ID
avoidance slice below removes the covered same-ID residue for generated
auto-ID write demux.

Same-ID ordering readiness selector:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md)
selects `.34` as a readiness audit before same-ID ordering implementation or
prerequisite changes. At selector time, `same_id_ordering` was the common
remaining ID/auto-ID/write-demux residue after generated write `BID` demux and
auto-ID residue alignment. The audit decided whether the first same-ID ordering
step should be static/report classification, generated assertions, allocator
constraints, per-ID issue-order queues/scoreboards, or a smaller
IAL1/IAL0/SystemVerilog prerequisite.

Same-ID ordering readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md)
selects `.35` as the first implementation boundary. The first same-ID slice
is not a per-ID ordering queue; it formalizes generated auto-ID same-ID
avoidance by adding pairwise active selected-ID assertions and
machine-readable `same_id_ordering` report metadata. This preserves the
current conservative behavior where generated auto-ID families avoid two
active transactions sharing an ID. Authored concrete-ID same-ID ordering,
per-ID response queues, read `RID` demux, read-data interleaving/reassembly,
bursts, queued/blocking policy, aliases, full-manager behavior, and VHDL
remain future exact-owner work.

Same-ID ordering first slice:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md)
ships that bounded generated auto-ID same-ID avoidance boundary. Generated
auto-ID families now get pairwise active selected-ID assertions, and reports
add:

```text
same_id_ordering:
  mode: auto_id_same_id_avoidance
  generated_behavior: true
  strategy: avoid_same_id_concurrency
  families:
    - family: write
      enforcement: allocator_free_id_guard
      assertion_enforcement: runtime_assertion
      response_demux_covered: true
      generated_assertions:
        - axi0_w0_w1_auto_id_unique_active_id
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
    - read_response_demux
    - read_data_interleaving
    - bursts
```

For the response-demux sample, `auto_id_lifecycle.residue` is now empty and
`response_demux.residue` is `[read_response_demux, read_data_interleaving,
bursts]`. `id_response_rule_engine.residue` still keeps `same_id_ordering`
for authored concrete-ID same-ID cases and future per-ID queues.

Read response-demux selector:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md)
selects `.37` as a readiness audit for bounded read `RID` response demux after
generated auto-ID same-ID avoidance. The likely public shape to audit is an
additive read arm under the existing `response-demux` clause:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The audit must decide whether `response-event` can honestly mean a bounded
accepted single-beat read response event, whether explicit read
`auto-id-lifecycle` metadata is required, and how to report the remaining
out-of-scope read-data interleaving/reassembly, burst/last-beat, per-ID queue,
full-manager, and VHDL work.

Read response-demux readiness audit:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.38`, a public contract-selection slice. The audit found that the
current parser and generator are intentionally write-shaped for
`response-demux`, while the substrate already has read ID-family metadata,
read transaction metadata, read-capable auto-ID lifecycle state, concrete
`ARID`/`RID` assertion reachability, and IAL1 rule-owned pulse actions. The
contract still has to decide whether the first read demux scope is
single-beat/non-burst, what `response-event` means, whether it must equal
top-level `read-complete`, and whether read `auto-id-lifecycle` metadata is
mandatory before any parser/report or generated behavior changes.

Read response-demux contract selection:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.39`, parser/report metadata and static validation for the read arm.
The selected public syntax requires `(response-scope single-beat)`, so the
first read response-demux contract is explicitly non-burst/single-beat.
`response-event` must equal top-level `read-complete` and means the raw
accepted read response transfer under the opt-in. Read demux also requires
positive-width read ID-family metadata, read transaction metadata, and explicit
read `auto-id-lifecycle` metadata. Generated read `RID` demux rules and read
completion pulses remain future behavior.

Read response-demux metadata first slice:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships the historical `.39` parser/report implementation. Public `.ppif`
sources may use one `read` arm, one `write` arm, or both under
`response-demux`:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

At `.39`, the schedule report included:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: false
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: false
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions: [r0, r1]
  residue:
    - generated_read_rid_demux
    - read_data_interleaving
    - bursts
```

At `.39`, generated read demux behavior was unchanged: the read transaction
completion events remained authored inputs, `RID` was not added to generated
IAL1 by response demux, no read completion outputs were emitted, and no read
response-demux rules or HDL logic were generated. The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_read_response_demux`.

That paragraph describes the `.39` boundary. The generated behavior shipped
later in `.41` without changing the public source syntax.

Read response-demux behavior readiness audit:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md)
selected `.41`, bounded generated single-beat read `RID` response-demux
behavior. The audit found no new IAL1, IAL0, or SystemVerilog prerequisite:
the existing IAL1 `(pulse TARGET)` action and the shipped write demux path can
carry the read demux.

Read response-demux behavior first slice:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
ships the `.41` generated behavior. For the checked-in sample:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(output axi0_r0_complete)
(output axi0_r1_complete)

(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q))
  (pulse axi0_r0_complete))
```

The raw `read-complete` event remains the accepted single-beat read response
input. `RID` is a generated response-ID input. The selected logical read
transaction completion names are generated one-cycle pulse outputs, not
authored event inputs, and read capacity release plus read auto-ID release
consume those pulses.

The schedule report now includes:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: true
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    generated_rules: [axi0_r0_response_demux, axi0_r1_response_demux]
    generated_completion_signals: [axi0_r0_complete, axi0_r1_complete]
    generated_assertions:
      - axi0_read_response_demux_active_match
      - axi0_r0_r1_read_response_demux_unique_match
  residue:
    - read_data_interleaving
    - bursts
```

Useful behavior checks:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Read-data interleaving/reassembly, bursts/`RLAST`, per-ID queues,
queued/blocking policy, full-manager behavior, direct backend lowering, and
VHDL remain future exact-owner work.

Post-read-demux next-slice selection:
[AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.43` as a readiness audit for AXI read-data payload,
burst/`RLAST`, and per-ID ordering/reassembly ownership. The selector chooses
an audit rather than a direct implementation because the remaining read-side
residue is interdependent: read-data payload capture needs a public structural
shape, burst ownership changes what `read-complete` means, different-ID
interleaving needs per-ID collection or an explicit issue constraint, and
authored concrete-ID same-ID ordering needs queues or a fail-closed rule. Full
manager behavior, profile aliases, queued/blocking policy, direct backend
lowering, and VHDL remain deferred.

Read-data/burst readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md)
selects `.44` as the bounded public read-data payload/status contract
selector. The audit concluded that a likely single-beat payload/status subset
can be layered on the shipped generated read `RID` demux with the existing
IAL1/IAL0/SystemVerilog data-path substrate, but FSMGen must first select the
public source syntax, report artifacts, target binding semantics, and
interleaving/burst residue policy. Parser/report metadata and generated
behavior changes stay out of `.43`.

Read-data payload/status contract selection:
[AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md)
selects `.45`, parser/report metadata and static validation for the first
bounded `read-data` source contract:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))))
```

The generated read response-demux completion pulse is the validity strobe for
the selected transaction's data/status outputs. The first contract does not
observe `RLAST`, does not assemble bursts, and does not perform multi-beat
read-data reassembly.

Read-data payload/status metadata first slice:
[AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md)
now ships the parser/report boundary for that contract. The checked-in
sample is:

```text
ppif/axi_manager_capacity_status_read_data.ppif
```

The sample keeps the generated read `RID` response-demux behavior and adds the
structural read-data AST. At the metadata boundary, schedule JSON reported:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_completion_pulse
    data_signal: axi0_rdata
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_width: 2
    interleaving_policy: single_beat_by_rid
```

The report also listed transaction-bound data/status outputs for `r0` and
`r1`, each tied to the generated read-demux completion pulse. The follow-up
behavior slice below now claims generated `RDATA`/`RRESP` capture behavior for
that same public contract.

Response-demux behavior readiness audit:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md)
concluded that generated write `BID` demux should not be implemented directly
on top of ordinary IAL1 rule assignments. Transaction completion names are
one-cycle completion pulses, while existing IAL1 `(set ...)` and shorthand
rule actions lower as sticky flopped assignments. That prerequisite is now
shipped as a bounded rule-owned `(pulse target)` action that lowers through the
existing delayed-pulse path. The generated write `BID` demux behavior is now
shipped through that pulse-completion path.

At the time of the write-demux readiness audit, generated data-capture
behavior still needed a later exact owner. That owner is now shipped for the
bounded single-beat `read-data` contract below. Same-ID response ordering
queues, read-data interleaving/reassembly, bursts, queued/blocking policy,
profile aliases, full AXI manager behavior, and VHDL remain future exact-owner
work.

Read-data capture readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md)
selects `.47`, generated single-beat `RDATA`/`RRESP` capture behavior. The
audit concluded no smaller IAL1/IAL0/SystemVerilog prerequisite is needed:
the shipped public `read_data` report names the source `RDATA`/`RRESP`
signals, widths, transaction-bound output names, and generated read-demux
completion pulses; existing IAL1 already supports width-bearing inputs,
width-bearing outputs, and normal guarded rule assignments. The behavior owner
must use normal data/status assignments rather than `(pulse ...)`, because the
payload/status outputs are held captured values, not one-cycle completion
pulses. `RLAST`, bursts, multi-beat read-data reassembly, per-ID queues,
full-manager behavior, direct backend lowering, and VHDL remain future
exact-owner work.

Read-data capture behavior first slice:
[AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
now ships generated single-beat `RDATA`/`RRESP` capture for explicit
`read-data` contracts. The generated IAL1 review artifact declares
width-bearing source inputs:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

and transaction-bound capture outputs:

```text
(output axi0_r0_rdata (width 32))
(output axi0_r0_rresp (width 2))
```

Each covered read transaction gets one normal guarded capture rule:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
```

The guard is the generated read response-demux completion pulse, while the
payload/status assignments are ordinary held assignments. The generated `.fsm`
contains the corresponding capture assignments:

```text
(-axi0_r0_read_data_capture <axi0_r0_complete
  (<- (axi0_r0_rdata> axi0_rdata))
  (<- (axi0_r0_rresp> axi0_rresp)))
```

SystemVerilog exposes `axi0_rdata` and `axi0_rresp` as inputs, exposes each
transaction-bound captured payload/status as flopped outputs, and passes
`--verify-hdl` for:

```bash
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data.ppif
```

Schedule JSON now reports `read_data.generated_behavior: true` with
`generated_inputs`, `generated_outputs`, and `generated_rules`. The
`read_data.residue` list removes `generated_read_data_capture` and retains
`rlast_completion`, `bursts`, and `multi_beat_read_data_reassembly`.

Burst/`RLAST` completion readiness audit:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md)
selects public contract selection before parser/report metadata or generated
behavior changes. The audit found no evident new IAL1/IAL0/SystemVerilog
prerequisite for a later bounded implementation: width-bearing ports, scalar
storage, guarded assignments, and one-cycle pulses already exist. What is
missing is the public AXI contract. The next selector must define `RLAST`
signal ownership, burst length or beat-count metadata, beat-valid versus
transaction-complete semantics, data/status capture granularity, diagnostics,
generated artifact boundaries, and report/residue movement before behavior can
ship.

`RLAST` completion contract selection:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md)
selects an additive read `response-demux` scope:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The shipped `single-beat` scope stays unchanged. In the selected
`burst-last` contract, `response-event` remains the raw accepted read response
beat, `last-signal` is a generated one-bit `RLAST` input, and the existing
transaction `(completion NAME)` output is the generated last-beat completion
pulse. The contract publishes no per-transaction beat-valid output, selects no
burst length or `ARLEN` ownership, and does not extend `read-data`; the current
single-beat `read-data` contract must be rejected when paired with
`response-scope burst-last`. The next implementation owner is parser/report
metadata and static validation only.

`RLAST` completion metadata first slice:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md)
ships that parser/report boundary. Public `.ppif` now accepts
`response-scope burst-last` with exactly one width-1 `last-signal`, keeps
`single-beat` syntax and behavior unchanged, and rejects malformed
`last-signal` clauses, `last-signal` on `single-beat`, and the current
single-beat `read-data` contract when paired with burst-last response demux.

The checked-in runnable sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

The schedule report marks the burst-last read demux as report-only:

```text
response_demux.generated_behavior: false
response_demux.read.generated_behavior: false
response_demux.read.response_scope: burst_last
response_demux.read.last_signal: axi0_rlast
response_demux.read.last_signal_width: 1
response_demux.read.transaction_completion_source: generated_demux_last_beat
response_demux.read.transaction_completion_semantics: matched_rid_and_last_signal
response_demux.read.burst_length_source: rlast_only
response_demux.read.burst_length_validation: not_generated
response_demux.residue:
  - generated_burst_last_read_demux
  - read_data_interleaving
  - bursts
```

Generated `.isf`, `.fsm`, and HDL behavior remain unchanged for this sample:
no `RLAST` input, `RID` input, transaction completion outputs/rules, or
burst-last assertions are generated yet. The follow-on readiness audit selected
the generated burst-last/`RLAST` completion behavior boundary.

`RLAST` completion behavior readiness audit:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md)
selects direct generated behavior next. No new IAL1, IAL0, or SystemVerilog
prerequisite is needed: scalar inputs, generated pulse outputs, guarded rules,
assertion carriers, report artifacts, capacity release, and auto-ID release
already exist on the SystemVerilog-backed path.

The next behavior slice should add the generated `RLAST` input, reuse
generated `RID` matching, and pulse each generated transaction completion only
when the accepted response beat matches the transaction ID and `RLAST` is
asserted. It should move the burst-last sample to
`response_demux.generated_behavior: true`, remove
`generated_burst_last_read_demux` residue, mark read same-ID response-demux
coverage, and keep read-data reassembly, beat-count/`ARLEN` validation,
per-beat outputs, per-ID queues, direct backend lowering, and VHDL deferred.

`RLAST` completion behavior first slice:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
ships generated burst-last completion behavior for explicit read
`response-demux` contracts. The checked-in burst-last sample now emits
generated `RID` and `RLAST` inputs, generated per-transaction completion pulse
outputs, one `RLAST`-gated response-demux rule per read auto-ID transaction,
active-match and unique-match assertions, auto-ID lifecycle residue movement,
same-ID response-demux coverage movement, and HDL reachability.

Generated IAL1 now includes:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(input axi0_rlast)
(output axi0_r0_complete)
(output axi0_r1_complete)
```

The first generated last-beat rule is:

```text
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q)
     axi0_rlast)
  (pulse axi0_r0_complete))
```

The schedule report marks `response_demux.generated_behavior: true`, removes
`generated_burst_last_read_demux` residue, removes `response_demux` from
`auto_id_lifecycle.residue`, and marks the read same-ID family
`response_demux_covered: true`. Read-data reassembly, beat-count/`ARLEN`
validation, per-beat outputs, per-ID queues, direct backend lowering, and VHDL
remain deferred. The active frontier is the post-`RLAST` selector for the next
exact AXI manager feature-completeness owner.

Post-`RLAST` next-slice selection:
[AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md)
selects the next exact owner after generated burst-last completion behavior.
The selector found that the structured burst-last report fields and generated
artifacts are correct, but generated schedule-report prose still says
burst-last `RLAST` metadata is report-only and generated burst/last-beat
tracking remains outside the capacity/status shell. The active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.55`, a narrow report/static-text
alignment slice. Multi-beat read-data reassembly, per-ID queues, full-manager
behavior, direct backend lowering, and VHDL remain deferred until that
user-facing report drift is resolved.

`RLAST` report alignment first slice:
[AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md)
ships that user-facing report repair. The schedule report now says
`response_scope burst_last` generates matched-`RID`-and-`RLAST` last-beat
completion behavior for explicit opt-in contracts, and the unsupported-residue
prose now lists generated burst-last `RLAST` response-demux completion as
supported. Public syntax, generated `.isf`, generated `.fsm`, HDL, support
accounting, check JSON, and semantic JSON behavior are unchanged.

Post-`RLAST` report next-slice selection:
[AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md)
selects public AXI burst read-data contract selection as the next owner. The
selector keeps direct multi-beat read-data behavior deferred because the
current `read-data` contract is single-beat-only, the burst-last sample has no
`read_data` contract, and the public shape for capture scope, output binding,
beat-count/depth, `RRESP` aggregation, interleaving, diagnostics, and report
residue movement is not selected yet.

Burst read-data contract selection:
[AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
selects explicit last-beat read-data capture as the first bounded burst-side
contract. The selected source shape is `capture-scope last-beat`,
`status-policy last-beat`, and `interleaving last-beat-by-rid` under
`read-data`, paired only with generated `response_scope burst_last` response
demux. It captures only the last-beat `RDATA`/`RRESP` values and keeps full
multi-beat reassembly, per-beat outputs, `RRESP` aggregation,
`ARLEN`/beat-count validation, per-ID queues, and VHDL deferred.

Last-beat read-data metadata first slice:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for that selected contract.
The public `.ppif` sample is
`ppif/axi_manager_capacity_status_read_data_last_beat.ppif`:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The report marks this as structural metadata, not generated capture behavior:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: last_beat
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    status_aggregation: none
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    beat_storage: none
    valid_output: none
    length_output: none
```

The slice requires generated read response-demux metadata with
`response_scope burst_last`, support-accounts the new sample for strict check
JSON and normalized semantic JSON, and keeps generated `.isf`, `.fsm`, HDL
behavior, check JSON semantics, and existing single-beat read-data behavior
unchanged.

Last-beat read-data capture readiness audit:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md)
selects direct generated last-beat `RDATA`/`RRESP` capture behavior. The audit
found no new IAL1/IAL0/SystemVerilog prerequisite: the existing read-data
source-input, transaction-output, capture-rule, and generated-artifact helpers
are already generic over the normalized read-data transaction list, and the
`.58` metadata binds each transaction to its generated burst-last completion
pulse.

Last-beat read-data behavior first slice:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
ships generated last-beat `RDATA`/`RRESP` capture behavior. The last-beat
sample now emits generated data/status inputs, per-transaction last-beat
data/status outputs, and normal guarded capture rules driven by generated
burst-last completion pulses:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

The schedule report marks the behavior as generated and lists the generated
artifacts:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_last_rdata
      - axi0_r0_last_rresp
      - axi0_r1_last_rdata
      - axi0_r1_last_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

Post last-beat read-data next-slice selection:
[AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
selects public AXI burst read-data beat-count/depth contract selection as the
next exact owner. Full multi-beat reassembly, per-beat outputs, `RRESP`
aggregation, missing/extra beat validation, and per-ID reassembly all need an
explicit expected-count/depth contract before behavior can be implemented
honestly.

Burst read-data beat-count contract selection:
[AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
selects an additive ARLEN-based `burst-length` clause under last-beat
`read-data`:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The selected contract is metadata first: generated counters, storage,
missing/extra beat validation, full reassembly, per-beat outputs, `RRESP`
aggregation, and per-ID queues remain future exact-owner work.

Burst read-data beat-count metadata first slice:
[AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
ships the parser/report boundary for that contract. The public sample is:

```text
ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```

The metadata slice introduced the public report fields for ARLEN beat-count
metadata. The current generated behavior, shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.66`, keeps last-beat `RDATA`/`RRESP`
capture behavior and also captures raw ARLEN at each transaction request:

```text
read_data:
  generated_behavior: true
  read:
    burst_length_source: arlen_signal
    burst_length_signal: axi0_arlen
    burst_length_signal_width: 8
    burst_length_encoding: axlen_plus_one
    burst_length_capture: transaction_request
    max_beats: 16
    burst_length_generated_behavior: true
    burst_length_validation: report_only
    beat_storage: none
    valid_output: none
    length_output: none
    generated_burst_length_inputs:
      - axi0_arlen
    generated_burst_length_storage:
      - axi0_r0_arlen_q
      - axi0_r1_arlen_q
    generated_burst_length_rules:
      - axi0_r0_burst_length_capture
      - axi0_r1_burst_length_capture
```

The generated IAL1 includes the ARLEN input, one raw-ARLEN storage variable
per covered read transaction, and one request-event guarded capture rule per
covered read transaction:

```text
(input axi0_arlen (width 8))

(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))

(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

The `.fsm` and SystemVerilog outputs lower the same raw-ARLEN capture
behavior. The captured value is raw `ARLEN`; later beat-count validation will
own the `ARLEN + 1` arithmetic implied by `axlen_plus_one`.

Useful checks:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```

Post burst-length metadata selector:
[AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md)
selects a readiness audit before generated ARLEN capture. Generated ARLEN
capture is the next prerequisite before beat-count/RLAST validation or
multi-beat reassembly, but it adds a new HDL input, generated storage, and
request-event binding that must be audited before behavior changes.

ARLEN capture readiness audit:
[AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md)
finds that existing generated inputs, generated vars, guarded rule
assignments, request-event guards, report artifact lists, and HDL lowering are
enough for a bounded raw-ARLEN capture slice. The selected behavior stores raw
8-bit `ARLEN` per read transaction and leaves `ARLEN + 1` arithmetic,
beat-count/RLAST validation, payload storage, and reassembly deferred.

ARLEN capture behavior first slice:
[AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md)
ships generated raw-ARLEN capture for opt-in last-beat read-data
`burst-length` contracts. It removes `generated_burst_length_capture` from
read-data residue and leaves `generated_beat_count_validation`,
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` as explicit future owners.

Beat-count/RLAST validation readiness audit:
[AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md)
finds the IAL1/IAL0/SystemVerilog substrate ready for future generated
validation after a public validation contract exists. Generated storage can
carry `max-beats`-width expected-count and beat-count state, generated rules
can assign arithmetic expressions, response-demux match expressions can
identify every accepted matched read beat, and generated assertions already
lower through clocked reset-disabled SystemVerilog properties. The audit does
not select direct behavior because the existing public syntax says
`validation report-only`, and that mode must remain no-runtime-check behavior.

Beat-count/RLAST runtime-validation contract selection:
[AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md)
selects an explicit generated-validation mode while preserving
`validation report-only` as report-only metadata:

```text
(validation runtime-assertion)
```

The normalized report values are `report_only` and `runtime_assertion`.
`runtime-assertion` is behavior-bearing: implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.69`
([AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md))
ships parser support and generated validation behavior together. The shipped
report shape includes `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, generated
expected-count storage, generated beat-count storage/rules, and generated
assertion names such as `axi0_r0_arlen_within_max`,
`axi0_r0_read_beat_before_expected_count`,
`axi0_r0_rlast_on_expected_beat`, and
`axi0_r0_expected_final_beat_has_rlast`. Generated IAL1/.fsm/SystemVerilog
now include expected-beat storage, matched-read-beat counters, initialization
and increment rules, ARLEN-bound, extra-beat, early-`RLAST`, and
missing-final-`RLAST` assertions for `(validation runtime-assertion)` while
`validation report-only` remains no-runtime-check behavior.

Post beat-count/RLAST validation next-slice selection:
[AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.71`, public AXI multi-beat
read-data reassembly/output contract selection, as the active frontier. The
selector keeps direct reassembly behavior deferred because the public
source/report surface still needs beat storage, per-beat or packed outputs,
length/valid outputs, all-beat `RRESP` aggregation, and different-ID/per-ID
queue semantics selected first.

Multi-beat read-data reassembly contract selection:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
selects `capture-scope multi-beat` with mandatory ARLEN `burst-length`
runtime assertions, `status-policy per-beat`, `interleaving
multi-beat-by-rid`, and per-transaction data/status output prefixes,
valid-mask outputs, and length outputs. The first selected output shape is a
per-beat output bank, not a packed burst vector. Scalar `RRESP` aggregation
and generated reassembly behavior remain deferred. The selector advanced the
frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.72`, parser/report metadata and static
validation for this public syntax.

Multi-beat read-data metadata first slice:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for the selected
multi-beat output-bank syntax. The support-accounted sample is:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

The public source shape binds per-transaction output names by prefix and
explicit valid/length outputs:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))))
```

Schedule JSON reports `bounded_multi_beat_read_data_contract`, per-transaction
generated lane names, valid-mask widths, length-output widths,
`beat_match_source: response_demux_matched_read_beat`,
`output_shape: per_beat_output_bank`, and
the public transaction output-bank shape. `.72` is the parser/report metadata
boundary; generated output-bank behavior ships in `.74`.

Multi-beat read-data output readiness audit:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md)
finds no new IAL1, IAL0, or SystemVerilog prerequisite for the first
generated output-bank behavior. The selected implementation boundary uses
scalar generated lane outputs, treats the public output registers as the
generated per-transaction beat storage, clears valid/length/lane outputs on
request, captures each accepted beat under a matched-read-beat,
`!request_event`, and current `beat_count_storage == lane_index` guard, and
sets valid masks with constant prefix values. It selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.74`, generated multi-beat read-data
output-bank behavior.

Multi-beat read-data output-bank behavior first slice:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
ships generated output-bank behavior for the public multi-beat sample. The
generated IAL1 review artifact now declares payload inputs such as:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It also declares per-transaction lane outputs, valid masks, and length
outputs:

```text
(output axi0_r0_beat_rdata_0 (width 32))
(output axi0_r0_beat_rresp_0 (width 2))
(output axi0_r0_beat_valid (width 16))
(output axi0_r0_read_beats (width 5))
```

Each read transaction gets a request-time output-bank clear rule and one lane
capture rule per beat. Lane capture guards combine the response-demux
matched-read-beat expression, `!request_event`, and
`beat_count_storage == lane_index`; actions capture current `RDATA`/`RRESP`,
write a constant prefix valid mask, and write `lane_index + 1` into the
length output. Schedule JSON reports
`multi_beat_reassembly_generated_behavior: true`, generated payload inputs,
generated output lanes, valid/length outputs, output-init rules, and lane
capture rules. `read_data.residue` is now only `rresp_aggregation`; scalar
`RRESP` aggregation, per-ID queues, direct backend lowering, and VHDL remain
deferred. Selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selects public
scalar `RRESP` aggregation contract selection as the next exact owner. That
selection advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.76`.

Post multi-beat output next-slice selection:
[AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md)
records the `.75` selector. It chooses public scalar `RRESP` aggregation
contract selection before any parser/report metadata or generated behavior
changes.

RRESP aggregation contract selection:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md)
records the `.76` selector. It chooses an additive read-level
`(status-aggregation (policy worst-observed))` clause plus one
transaction-local `(status-aggregate-output NAME)` binding per transaction:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (transaction r0
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp))))
```

The normalized report spelling is `status_aggregation: worst_observed`.
For the width-2 contract, the selected ordering is
`OKAY < EXOKAY < SLVERR < DECERR` across every accepted matched read-data
beat. Per-beat `RRESP` lanes stay mandatory, valid/length outputs stay
unchanged, width-3 AXI responses remain deferred, and generated scalar
aggregation behavior remains deferred to a later exact owner. The active
frontier moved through `IAL2-FEATURE-COMPLETENESS-FRONTIER.77`, parser/report
metadata and static validation for this selected contract.

RRESP aggregation metadata first slice:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md)
ships the parser/report metadata and static validation for the selected
contract. The public multi-beat sample now accepts `status-aggregation` and
per-transaction `status-aggregate-output` bindings, while generated `.isf`,
`.fsm`, and SystemVerilog output-bank behavior remains unchanged. Schedule JSON
reports the scalar aggregate contract as metadata:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  residue:
    - generated_rresp_aggregation
  read:
    status_policy: per_beat
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: false
    status_aggregate_output: per_transaction_scalar
    status_aggregate_output_width: 2
    transactions:
      - transaction: r0
        status_output_prefix: axi0_r0_beat_rresp
        status_aggregate_output: axi0_r0_rresp
        status_aggregate_output_width: 2
```

Generated scalar aggregate outputs are intentionally absent in this slice. The
existing generated output-bank still exposes per-beat status lanes, valid
masks, and length outputs; there is no generated scalar output such as:

```text
(output axi0_r0_rresp (width 2))
```

The next frontier after `.77` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.78`, generated scalar `RRESP`
aggregation readiness before behavior changes.

RRESP aggregation behavior readiness:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md)
records the `.78` readiness audit. It found no new IAL1, IAL0, or
SystemVerilog prerequisite for first generated width-2 `worst_observed`
behavior.

RRESP aggregation behavior first slice:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md)
ships generated scalar aggregation behavior for the selected width-2
`worst_observed` contract. The public multi-beat sample now emits one scalar
aggregate output per read transaction:

```text
(output axi0_r0_rresp (width 2))
```

The existing output-bank initialization rule initializes the aggregate to
`OKAY` on the transaction request:

```text
(rule axi0_r0_read_data_output_init axi0_r0_request
  ...
  (axi0_r0_rresp 2'd0)
  ...)
```

Each transaction also gets a matched-beat update rule. The rule keeps the
worst width-2 value observed so far:

```text
(rule axi0_r0_rresp_aggregate
  (& MATCHED_READ_BEAT
     (! axi0_r0_request)
     (< axi0_r0_rresp axi0_rresp))
  (axi0_r0_rresp axi0_rresp))
```

The `! REQUEST_EVENT` boundary is mandatory. It keeps scalar aggregation
aligned with the generated output-bank same-cycle request/response behavior.

Schedule JSON now reports generated aggregate artifacts and no scalar
aggregation residue for the selected contract:

```text
read_data:
  residue: []
  read:
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: true
    generated_status_aggregate_outputs:
      - axi0_r0_rresp
      - axi0_r1_rresp
    generated_status_aggregate_init_rules:
      - axi0_r0_read_data_output_init
      - axi0_r1_read_data_output_init
    generated_status_aggregate_update_rules:
      - axi0_r0_rresp_aggregate
      - axi0_r1_rresp_aggregate
```

No-aggregation multi-beat contracts remain valid and continue to report
`status_aggregation: none` with `read_data.residue: [rresp_aggregation]`.

Post-RRESP aggregation selector:
[AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.81`, AXI per-ID read-data
interleaving and queue readiness. The live public multi-beat sample now has
empty `read_data` and `auto_id_lifecycle` residue. Remaining AXI manager
residue clusters around `response_demux` read-data interleaving/bursts and
`same_id_ordering` concrete-ID same-ID ordering, per-ID issue queues,
read-data interleaving, and bursts.

Verification-code generation is a valid future FSMGEN target lane. It should
be separate from the current synthesizable RTL path, so SV/UVM agents,
monitors, scoreboards, protocol checkers, coverage, and reusable verification
IP can use the full non-synthesizable target-language surface without
weakening RTL lowering. Width-3 responses, alternate policies, aggregate-only
shapes, packed outputs, per-ID queues, direct backend lowering, and VHDL
remain deferred in the current RTL lane.

Read-data interleaving queue readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`, report/static residue
alignment for the covered generated auto-ID multi-beat-by-RID subset. The
current public multi-beat sample already has bounded generated
`multi_beat_by_rid` output-bank behavior through generated same-ID avoidance,
matched-`RID` response demux, independent per-transaction beat counters,
output banks, valid masks, length outputs, and scalar aggregate status state.

The next slice is not new queue behavior. It should remove over-broad
`read_data_interleaving` residue from `response_demux` and
`same_id_ordering` only for that covered generated auto-ID subset, while
preserving `concrete_id_same_id_ordering`, `per_id_issue_order_queues`,
broader `bursts`, queued/blocking policy, profile aliases, full-manager
behavior, verification-code generation, direct backend lowering, and VHDL as
deferred work.

Read-data interleaving residue alignment:
[AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`. The public multi-beat sample
now reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: [bursts]
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - bursts
```

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The report
predicate removes `read_data_interleaving` only when generated read same-ID
avoidance, generated burst-last read response demux, matched-read-beat
counting, `multi_beat_by_rid`, per-transaction output banks, valid masks,
length outputs, and generated multi-beat output-bank behavior are all present.
The follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.83`, a selector
for the remaining AXI manager residue owner.

Post-interleaving alignment selector:
[AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`, AXI burst payload/output
readiness. After `.82`, `bursts` is the only remaining `response_demux`
residue and is still present in `same_id_ordering`, while the public
multi-beat sample already has burst-last `RLAST` demux, raw ARLEN capture,
beat-count/RLAST runtime validation, per-beat output banks, valid masks,
length outputs, and scalar aggregate `RRESP`.

Burst payload/output readiness audit:
[AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`. The selected per-beat
output-bank contract is already the bounded burst payload/output shape for the
covered generated auto-ID multi-beat subset: generated burst-last response
demux, raw ARLEN capture, runtime beat-count/RLAST validation,
per-transaction data/status lanes, valid masks, length outputs, scalar status
output, and generated same-ID avoidance are present.

The selected follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`,
report/static `bursts` residue alignment for that covered subset. Packed
burst payload outputs, full burst assembly, aggregate-only status shapes,
authored concrete-ID same-ID ordering, per-ID queues, queued/blocking policy,
profile aliases, full-manager behavior, verification-code generation, direct
backend lowering, and VHDL remain deferred.

Burst residue alignment:
[AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`. The public multi-beat sample
now reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The report
predicate removes `bursts` only when generated read same-ID avoidance,
generated burst-last read response demux, ARLEN-derived expected beats,
runtime beat-count/RLAST validation, matched-read-beat counting,
`multi_beat_by_rid`, per-transaction output banks, full configured
data/status lanes, valid masks, length outputs, and generated multi-beat
output-bank behavior are all present. Scalar `RRESP` aggregation is not
required for this movement because per-beat status lanes are generated.

The selected follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`, the
next AXI manager feature-completeness selector. It also carried the IAL2 factoring
question: keep common IAL2 constructs to a small semantic core where reuse is
proven across multiple profiles, and keep protocol/platform-specific
vocabulary profile-local until evidence justifies promotion. Packed/full
burst assembly, aggregate-only status shapes, authored concrete-ID same-ID
ordering, per-ID queues, queued/blocking policy, profile aliases,
full-manager behavior, verification-code generation, direct backend lowering,
and VHDL remain deferred.

Post-burst-residue selector:
[AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI concrete-ID same-ID ordering
readiness. The public multi-beat sample now leaves only
`concrete_id_same_id_ordering` and `per_id_issue_order_queues` under
`same_id_ordering.residue`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`.

`.87` was selected to decide whether the next implementation could be a
conservative concrete-ID same-ID constraint, report/static classification,
public same-ID policy, or whether generated per-ID issue-order queue substrate
was required first. The selector also records the IAL2 factoring stance: keep common IAL2
constructs to a small semantic core only when reuse is proven across multiple
profiles. AXI same-ID ordering remains AXI profile vocabulary until another
profile proves the same semantic need.

Concrete-ID same-ID readiness audit:
[AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.88`, conservative fail-closed static
validation for multiple concrete-ID transactions in the same read or write
response family that use the same concrete ID value. Existing concrete-ID
assertions prove request/response ID equality only; they do not prove same-ID
response issue order without a per-ID issue-order record, queue, scoreboard, or
selected static rejection rule.

Concrete-ID same-ID static validation first slice:
[AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE](../../AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`. FSMGen now rejects unsupported
same-family concrete-ID reuse before emitting concrete-ID equality assertions:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Read and write ID families stay separate, duplicate concrete assertion event
diagnostics keep their previous precedence, generated auto-ID same-ID avoidance
is unchanged, and valid single-concrete-ID samples keep their generated
`.isf`, `.fsm`, SystemVerilog, and schedule-report residue behavior. Accepted
concrete-ID same-ID ordering behavior, per-ID issue-order queues, scoreboards,
public same-ID reuse policy, full-manager behavior, direct backend lowering,
and VHDL remain deferred. This advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.89`, a selector for the remaining AXI
manager feature-completeness residue after this static validation.

Post concrete-ID static validation selector:
[AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.89`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.90`, AXI per-ID issue-order queue
readiness, before any accepted concrete-ID same-ID reuse behavior or queue
implementation. The selector records that post-`.88` residue is still honest:
the public multi-beat sample still lists `concrete_id_same_id_ordering` and
`per_id_issue_order_queues`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`. Direct queue
behavior remains gated by public same-ID reuse policy, queue/scoreboard
substrate, concrete response-demux prerequisites, report/static residue
refinement, and any smaller IAL1/IAL0/SystemVerilog prerequisites.

Per-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.90`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.91`, AXI same-ID reuse policy contract
selection, before parser/report metadata or generated queue behavior. The
audit finds that existing lower layers can carry bounded scalar or bank state,
guarded rules, pulses, and assertions, so a smaller IAL1/IAL0/SystemVerilog
prerequisite is not the next blocker. The public `.ppif` manager-capacity
surface still lacks a same-ID reuse policy, and concrete-ID response demux
cannot distinguish two same-ID transactions without selected issue-order
state. Current residue remains honest.

Same-ID reuse policy contract selection:
[AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.91`. It selects an optional
AXI-profile-local top-level clause under `manager-capacity-status`:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject))
  (write
    (concrete-id-reuse reject)))
```

The first accepted policy is `reject`: it documents that authored concrete-ID
same-ID reuse is intentionally rejected by public source policy and does not
accept same-ID reuse, generate queues, or change HDL behavior for valid
sources. Omitted policy preserves today's fail-closed diagnostic. The selector
advances to `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`, parser/report metadata
and static validation for explicit reject policy before any
`issue-order-queue` or `scoreboard` behavior.

Same-ID reject policy first slice:
[AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`. The PPIF adapter now accepts
one optional `same-id-ordering` clause under `manager-capacity-status`; each
selected `read` or `write` family must contain exactly one
`(concrete-id-reuse reject)` policy. Duplicate top-level clauses, duplicate
family arms, duplicate policy clauses, missing policy clauses, unsupported
families, and unsupported values such as `scoreboard` fail closed.

The public sample is
`ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`. It reports the
selected policy without claiming generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: reject
      enforcement: static_validation
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Generated `.isf`, `.fsm`, and SystemVerilog stay unchanged for valid
single-concrete-ID sources. Omitted policy preserves the `.88` diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Explicit `reject` emits a policy-specific static validation diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse reject policy rejects concrete same-ID reuse
```

This advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.93`, the next AXI manager selector before
accepted same-ID reuse, generated per-ID issue-order queues, scoreboards,
concrete-ID response demux, queued/blocking policy, full-manager behavior,
direct backend lowering, or VHDL.

Post same-ID reject policy selector:
[AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.93`. Live reports confirm `.92`
is policy-only: the reject-policy sample reports
`same_id_ordering.mode: concrete_id_reuse_policy`,
`generated_behavior: false`, read policy `reject`, and
`generated_queue_behavior: false`; generated auto-ID samples still avoid
same-ID concurrency rather than accepting concrete-ID same-ID reuse.

The selector advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, public AXI same-ID issue-order queue
policy contract selection. `.94` must define the `issue-order-queue` public
source spelling, read/write family scope, queue depth bounds, enqueue/dequeue
semantics, queue-head response-demux behavior, diagnostics, report vocabulary,
validation gates, and rollback boundary before parser/report metadata or
generated queue behavior can ship.

Same-ID issue-order queue contract selection:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.94`. It keeps the existing
AXI-profile-local `same-id-ordering` shape and selects the family-local policy
value:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue))
  (write
    (concrete-id-reuse issue-order-queue)))
```

The first queue contract does not add a public `queue-depth` clause. Queue
depth is bounded by the selected family's `max-pending` value and the number
of concrete transactions in that family using the same ID. Later generated
behavior must enqueue admitted transaction requests, keep a per-ID queue head,
dequeue only on queue-head response completion, and route same-ID responses by
queue-head transaction identity rather than ID-only matching. A metadata-only
slice must not claim `accepted_same_id_reuse: true`; that report value is
reserved for generated queue-head behavior.

`.94` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`, AXI same-ID
issue-order queue behavior readiness, because the current generated
response-demux behavior is auto-ID-oriented and accepting duplicate
concrete-ID transactions before queue-head demux exists would be ambiguous.

Same-ID issue-order queue behavior readiness:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`. Generated queue-head behavior
is not the next safe slice: current response demux is auto-ID selected-ID
matching, concrete transactions have no queue-head state, and queue enqueue
needs an admitted per-transaction request boundary.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, metadata-first
parser/report support for `issue-order-queue`. That slice may accept the
spelling and report `implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.
Duplicated concrete same-ID transactions must still fail closed until
generated queue-head behavior exists.

Same-ID issue-order queue metadata first slice:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`. The PPIF adapter now accepts
`issue-order-queue` in the existing read/write `same-id-ordering`
`concrete-id-reuse` arms while keeping `scoreboard` unsupported.

The runnable sample is
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`. In
the `.96` metadata-first slice it reported selected-not-generated metadata
without changing generated `.isf`, `.fsm`, or SystemVerilog:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: not_generated
      implementation_status: selected_not_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Selecting `issue-order-queue` is not accepted same-ID reuse yet. If two
concrete read transactions reuse ID value 3 under the selected read family,
FSMGen still rejects the source:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships
```

Generated queue-head behavior still needs admitted per-transaction enqueue
guards, per-ID queue state, queue-head response demux, and queue-specific
assertions before `accepted_same_id_reuse` can become true.

Same-ID issue-order queue admitted enqueue boundary audit:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.97`. Queue state and queue-head
response demux are still too broad for the next slice. The next safe
prerequisite is a named admitted-request boundary per concrete transaction in
selected `issue-order-queue` families.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`, admitted request
pulse generation. The implementation ships the first generated prerequisite
for future queue state: one internal admitted-request pulse storage target and
one pulse rule per concrete transaction in a selected `issue-order-queue`
family. The pulse guard is derived from the transaction request event, current
direction pending storage, family `max-pending`, and same-cycle completion
fan-in. It does not use the generated `can_accept` status output as the source
of truth for queue enqueue.

Same-ID issue-order queue admitted request pulses first slice:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`. For the public sample, the
generated `.isf` now includes the admitted boundary:

```lisp
(var axi0_r0_admitted_request_pulse_q (width 1))

(rule axi0_r0_admitted_request
  (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
  (pulse axi0_r0_admitted_request_pulse_q))
```

The generated `.fsm` lowers the rule through the existing one-cycle delayed
pulse action:

```lisp
(<1 (axi0_r0_admitted_request_pulse_q 1))
```

For a selected family with more than one concrete transaction, FSMGen emits a
same-direction request mutual-exclusion assertion so the direction-level
pending counter cannot admit multiple concrete identities in one cycle:

```lisp
(assert (! (& axi0_r0_request axi0_r1_request))
  "axi0 read same-ID issue-order queue requests are mutually exclusive")
```

Current report metadata stays under `same_id_ordering` and remains explicit
that this is not generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: admitted_request_boundary
      implementation_status: admitted_request_pulses_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      admitted_request_boundary:
        guard_source: capacity_storage_and_completion_fanin
        pending_storage: axi0_pending_reads_q
        max_pending: 4
        completion_fanin: axi0_r0_complete
        selected_request_events:
          - axi0_r0_request
        generated_pulses:
          - transaction: r0
            tag: rd0
            concrete_id: 3
            request_event: axi0_r0_request
            pulse: axi0_r0_admitted_request_pulse_q
            rule: axi0_r0_admitted_request
            guard: (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
        generated_assertions: []
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Duplicated concrete same-ID reuse remains fail-closed until per-ID queue
storage, enqueue/dequeue rules, queue-head response demux, and queue-specific
assertions ship. `.98` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.99`, the post-admitted-request-pulse AXI
manager selector.

Post-admitted request pulses next slice selection:
[AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.99`. The selector keeps the next
step as a readiness audit rather than direct queue-state implementation.
Admitted request pulses name the enqueue boundary, but accepted same-ID reuse
still requires bounded per-ID queue storage, enqueue/dequeue semantics,
queue-head response demux, duplicate-ID validation changes, queue assertions,
and report residue movement to be scoped together.

`.99` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`, AXI same-ID
issue-order queue state and queue-head demux readiness audit. That audit must
decide whether the next safe owner is queue-state/enqueue/dequeue behavior,
queue-head demux, report/static alignment, or a smaller helper prerequisite
before any generated behavior changes.

Same-ID issue-order queue state and demux readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`. The audit confirms that
admitted request pulses are only the enqueue boundary. The selected public
same-ID sample still reports `accepted_same_id_reuse: false` and
`generated_queue_behavior: false`, and existing generated response demux
matches auto-ID busy/selected-ID state, including the read burst-last path.

Queue-head response demux cannot ship before queue identity state exists:
`BID` or `RID` selects the concrete ID queue, but the queue head selects the
authored transaction. Direct queue-state behavior is also still too broad
until grouping, bounds, storage shape, transaction identity encoding,
enqueue/dequeue event names, diagnostics, assertions, and report vocabulary
are selected. `.100` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.101`, bounded AXI same-ID issue-order
queue state representation selection. Accepted concrete same-ID reuse,
generated queue behavior, queue-head demux, direct backend lowering, and VHDL
remain deferred.

Same-ID issue-order queue state representation selection:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.101`. The selected future
representation is `compact_onehot_transaction_slots`: each generated queue is
family-local and concrete-ID-value-local, uses compacted explicit slots, keeps
slot `0` as the head, and stores one transaction identity bit per
slot/transaction. Queue depth remains bounded by
`min(max-pending, concrete transaction inventory)`.

This representation stays inside the proven scalar IAL path. It avoids arrays,
dynamic indexed left-hand sides, hidden unbounded queues, and pointer modulo
arithmetic. Enqueue remains sourced only from admitted request pulses; dequeue
is named as a future `queue_dequeue_event` produced by queue-head response
demux. `.101` therefore does not select behavior implementation yet. It
advances the active frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`, AXI
same-ID queue-head response-demux contract selection, because the existing
public `response-demux` syntax and generated behavior are auto-ID-lifecycle
oriented.

Same-ID queue-head response-demux contract selection:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`. The selector reuses the
existing `response-demux` read/write family arms for concrete same-ID
queue-head demux rather than adding a new top-level clause. The queue-head
interpretation is selected only when the same family selects
`concrete-id-reuse issue-order-queue`, has duplicate concrete-ID groups, and
does not also require same-family auto-ID demux in this first contract.

The selected report modes are
`bounded_write_bid_queue_head_demux_contract` and
`bounded_read_rid_queue_head_demux_contract`. They remain
selected-not-generated until later behavior ships generated queue state and
queue-head demux together for the covered group. `.102` advances the active
frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`, AXI same-ID queue-head
response-demux metadata/static validation.

Same-ID queue-head response-demux metadata first slice:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`. FSMGen now accepts the
selected-not-generated metadata contract when the same family has
`concrete-id-reuse issue-order-queue`, at least one duplicate concrete-ID
group, and no same-family auto-ID demux. The runnable sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

Its report includes `bounded_read_rid_queue_head_demux_contract`,
`implementation_status: selected_not_generated`,
`transaction_completion_source: generated_queue_head_demux`,
`queue_state_representation: compact_onehot_transaction_slots`, and one
`same_id_issue_order_queues` group for concrete ID `3` with transactions
`r0` and `r1`. The same-ID policy also records
`response_demux_strategy: queue_head_issue_order`.

This is still not accepted same-ID runtime behavior:
`accepted_same_id_reuse` and `generated_queue_behavior` remain false, no queue
state or queue-head demux rules are generated, and read-data consumption of
selected-not-generated queue-head demux fails closed. `.103` advances the
active frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`, generated
same-ID queue state and queue-head behavior readiness.

Same-ID queue behavior readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`. The audit confirms the
existing lower layers can already carry the first bounded generated behavior
shape: scalar storage, pulse actions, guarded rules, generated inputs and
outputs, Boolean/equality guards, constants, and generated assertions.

The audit still does not select direct runtime implementation. Queue state and
queue-head demux must be specified and shipped together for any covered group:
queue state needs a dequeue event from queue-head demux, and queue-head demux
needs queue-head transaction identity from queue state. Until that behavior
slice is selected and implemented, the `.103` sample remains
selected-not-generated, with `accepted_same_id_reuse` and
`generated_queue_behavior` false.

`.104` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated AXI same-ID queue
state and queue-head behavior slice selection.

Same-ID queue behavior first-slice selection:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.105`. The first generated behavior
implementation boundary is deliberately narrow: read family only, burst-last
queue-head demux, one duplicate concrete read-ID group, two read transactions,
computed depth `2`, no same-family auto-ID lifecycle, and no read-data
consumption.

The selected `.106` implementation must generate compact one-hot queue slots
and queue-head response-demux completion rules together. Covered read
transaction completion names become generated pulse outputs only for that
shape. Wider shapes remain selected-not-generated or fail closed until later
owners select them.

Same-ID queue behavior first slice:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.106`. FSMGen now generates
runtime behavior for the selected public sample shape:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

For that sample, the generated IAL1 exposes `axi0_r0_complete` and
`axi0_r1_complete` as generated pulse outputs, treats `axi0_read_complete`,
`axi0_rid`, and `axi0_rlast` as generated inputs, declares compact one-hot
depth-2 queue slots for concrete read ID `3`, emits finite enqueue/dequeue and
same-cycle dequeue/enqueue update rules, and emits queue-head response-demux
rules:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

The schedule report now marks both `response_demux.generated_behavior` and
`same_id_ordering.generated_behavior` true. The read concrete-ID reuse policy
reports `enforcement: generated_issue_order_queue`,
`implementation_status: generated_read_burst_last_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.

The same-ID queue report lists the concrete ID, depth, transaction order, slot
storage, enqueue pulses, generated update rules, and generated assertions.
Response-demux residue removes `generated_same_id_queue_head_demux`, and the
ID/response rule-engine residue removes `same_id_ordering` and
`response_demux` for this covered shape.

Post same-ID queue behavior next-slice selection:
[AXI_IAL2_MANAGER_POST_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.107`. The selector keeps the
current read burst-last behavior unchanged and chooses the next implementation
owner as `IAL2-FEATURE-COMPLETENESS-FRONTIER.108`: generated write-family
concrete same-ID queue-head behavior for one duplicate concrete write-ID group,
two write transactions, and computed depth `2`.

The selected write queue-head match is the write analogue of the shipped read
queue-head demux, without `RLAST`:

```text
axi0_write_complete
&& axi0_bid == 4'd3
&& axi0_write_id3_same_id_issue_order_slot0_w0_q
```

The `.108` slice later generated compact one-hot write queue slots, finite
write enqueue/dequeue/same-cycle update rules, generated write completion
pulse outputs, queue-head `BID` demux rules, queue assertions, and
report/residue movement only for that covered shape. `.110` later shipped the
read `single-beat` analogue. Deeper or multiple queue groups, same-family
mixed auto-ID, read-data consumption of concrete queue-head demux, direct
backend lowering, and VHDL remain deferred.

Write same-ID queue-head response-demux behavior:
[AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.108`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_write_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
```

The sample uses two write transactions, `w0` and `w1`, sharing concrete write
ID `3`, selected write `concrete-id-reuse issue-order-queue`, and generated
write response demux. FSMGen now emits admitted write enqueue pulses, compact
one-hot depth-2 queue slots, finite queue update rules, generated write
completion pulse outputs, queue-head `BID` demux rules, and queue/response
assertions for that covered shape.

The generated `w0` demux rule is:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w0_q)
  (pulse axi0_w0_complete))
```

The write response-demux report marks
`generated_queue_behavior_boundary: generated_write_bid_queue_head_demux`.
The write same-ID policy reports
`implementation_status: generated_write_bid_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.
Check JSON and normalized semantic JSON match support accounting entry
`intent.ppif_axi_manager_capacity_status_write_same_id_queue_head_response_demux`.

The `.108` HDL gate also repaired verification-only assertion emission:
assertion condition rendering now inlines assertion-only intermediate
expressions before appending SVA, so both the read and write queue-head public
samples pass `--verify-hdl`.

The shipped same-ID queue behavior remains intentionally narrow. Read
`single-beat`, deeper or multiple duplicate-ID groups, same-family mixed
auto-ID plus concrete queue-head demux, read-data consumption of concrete
queue-head demux, generalized per-ID queues, direct backend lowering, and VHDL
remain deferred.
After `.108`, the frontier advanced to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.109`, the next same-ID queue behavior
expansion audit/selector before any broader queue-head behavior changes.

Post-write same-ID queue behavior next-slice selection:
[AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.110` as the next bounded behavior
slice. `.110` owns generated read `single-beat` concrete same-ID queue-head
response demux for exactly one duplicate read-ID group of two transactions at
depth 2. The generated head match should use the raw read response event,
concrete `RID`, and compact slot-0 transaction bit, without `RLAST`.
Read-data consumption, deeper or multiple duplicate-ID groups, same-family
mixed auto-ID plus concrete queue-head demux, generalized per-ID queues,
direct backend lowering, and VHDL remain deferred.

Read single-beat same-ID queue-head response-demux behavior:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.110`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
```

The sample uses two read transactions, `r0` and `r1`, sharing concrete read ID
`3`, selected read `concrete-id-reuse issue-order-queue`, and generated read
single-beat response demux. FSMGen now emits admitted read enqueue pulses,
compact one-hot depth-2 queue slots, finite queue update rules, generated
read completion pulse outputs, queue-head `RID` demux rules, and
queue/response assertions for that covered shape. No `RLAST` signal is
generated or consumed.

The generated `r0` demux rule is:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3)
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

The read response-demux report marks
`generated_queue_behavior_boundary: generated_read_single_beat_queue_head_demux`.
The read same-ID policy reports
`implementation_status: generated_read_single_beat_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.
Check JSON and normalized semantic JSON match support accounting entry
`intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux`.

After `.110`, read-data consumption of concrete queue-head demux, deeper or
multiple duplicate-ID groups, same-family mixed auto-ID plus concrete
queue-head demux, generalized per-ID queues, direct backend lowering, and VHDL
remain deferred. Selector `.111`
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.112`, AXI read-data consumption
of generated concrete same-ID queue-head demux readiness. Existing generated
read-data capture consumes generated auto-ID read response-demux completion
pulses, but current normalization still fail-closes when `read_data` consumes
concrete queue-head read demux. `.112` must decide whether the first safe
behavior slice can be bounded to read single-beat queue-head demux plus
single-beat `RDATA`/`RRESP` capture, or whether metadata/report alignment is
required first. Audit `.112`
[AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`, generated single-beat
read-data capture for the bounded read single-beat concrete same-ID
queue-head demux shape. No lowerer prerequisite is evident; `.113` must make
read-data coverage source-aware for generated queue-head completion signals
instead of only auto-ID transaction lists.

Queue-head read-data behavior first slice:
[AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
```

The implemented boundary is exactly one generated read single-beat concrete
same-ID queue-head demux with one duplicate read-ID group, two read
transactions, computed queue depth 2, and single-beat `read-data` capture.
FSMGen derives read-data transaction coverage from the generated queue-head
group and `generated_completion_signals`, then emits generated `RDATA` and
`RRESP` inputs plus per-transaction data/status outputs.

The read-data capture rules are ordinary guarded assignments driven by the
generated queue-head completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

The schedule report distinguishes this queue-head path with:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    completion_validity: generated_queue_head_response_demux_completion_pulse
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_rdata
      - axi0_r0_rresp
      - axi0_r1_rdata
      - axi0_r1_rresp
```

The existing auto-ID read-data path keeps reporting
`generated_read_response_demux_completion_pulse`. Burst-last, last-beat, and
multi-beat queue-head read-data; deeper or multiple queue groups; mixed
same-family auto-ID plus concrete queue-head demux; direct backend lowering;
and VHDL remain deferred. `IAL2-FEATURE-COMPLETENESS-FRONTIER.114` selected
the bounded last-beat queue-head read-data follow-up before any broader
queue-head/read-data expansion.

Queue-head last-beat read-data behavior:
[AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md)
ships generated last-beat `RDATA`/`RRESP` capture for the bounded read
burst-last concrete same-ID queue-head demux shape:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_last_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
```

The implementation reuses the generated `RID` plus `RLAST` queue-head demux
from:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

and emits per-transaction last-beat capture rules:

```text
rule axi0_r0_read_data_capture:
  guard: axi0_r0_complete
  assignments:
    axi0_r0_last_rdata <- axi0_rdata
    axi0_r0_last_rresp <- axi0_rresp
```

The queue-head last-beat report value is:

```text
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
```

Existing auto-ID last-beat read-data keeps
`generated_read_response_demux_last_beat_completion_pulse`, and existing
queue-head single-beat read-data keeps
`generated_queue_head_response_demux_completion_pulse`. Multi-beat queue-head
read-data, queue-head runtime beat-count/RLAST validation, deeper or multiple
queue groups, mixed same-family auto-ID plus concrete queue-head demux,
generalized per-ID queues, direct backend lowering, and VHDL remain deferred.

Post queue-head last-beat read-data selector:
[AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
selects generated raw-`ARLEN` burst-length capture for the bounded
queue-head last-beat read-data shape as `.117`. That next implementation is
expected to add a public support-accounted sample that combines the `.115`
queue-head last-beat capture shape with report-only `burst-length` metadata,
generating `axi0_arlen`, per-transaction raw-`ARLEN` storage, and
request-guarded burst-length capture rules while preserving the queue-head
last-beat completion-validity report value.

First implementation subset selection:
[AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION](../../AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md)
selects a source-anchored AXI Valid-Ready channel contract/monitor as the
first safe AXI-derived IAL2 implementation subset. It is intentionally not the
full AXI manager; it must first prove reviewable `IAL2 -> IAL1/.isf ->
IAL0/.fsm -> HDL` lowering, source-anchor reporting, and explicit residue.

Implementation readiness audit:
[AXI_IAL2_VALID_READY_READINESS_AUDIT](../../AXI_IAL2_VALID_READY_READINESS_AUDIT.md)
mapped the existing code/test/docs/report owners for the first implementation
subset. It selected the in-process IAL2/protocol-intent generator boundary
that emits reviewable `.isf`, then uses the existing `FSM::Adapter::ISF` and
`FSM::Scheduler::ISF` path to emit reviewable `.fsm`. The audit explicitly
deferred public `.pif`/`.ppi`/`.ppif`/`.axi` CLI suffix support and the full
AXI manager until later owners.

First in-process generator slice:
[AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE](../../AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md)
ships the first behavior-bearing IAL2 protocol-intent entrypoint. It is not a
file parser and not a CLI suffix. It is an in-process API:

```perl
use FSM::IAL2::ProtocolIntent::ValidReadyChannel;

my $result = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new()->generate({
    name     => 'axi_aw',
    protocol => 'axi4',
    channel  => 'AW',
    role     => 'manager-to-subordinate',
    clock    => 'clk',
    reset    => { signal => 'rst_n', active_low => 1, async => 1 },
    valid    => 'awvalid',
    ready    => 'awready',
    payload  => [
        { name => 'awaddr', width => 32 },
        { name => 'awlen',  width => 8 },
    ],
    source => {
        object_id => 'axi-valid-ready-aw',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A3.2.1', page => 'A3-40' },
        ],
    },
});
```

The result exposes `generated_ial1.text` before `generated_ial0.files`. The
generated `.isf` parses through `FSM::Adapter::ISF`, lowers through
`FSM::Scheduler::ISF`, and emits assertion carriers for the first owned safety
subset: prior-cycle stalled `VALID` remains asserted, and each payload/control
signal remains stable after a prior-cycle stall. The IAL2 report includes
source anchors, generated artifact names, bindings, `VALID && READY` as the
transfer/fire condition, generated assertions, assumptions, enforced static
rules, and explicit residue for reset-during-reset behavior, READY
independence, and full AXI manager concurrency.

User-facing AXI manager brainstorm:
[AXI_MANAGER_USER_API_BRAINSTORM](../../AXI_MANAGER_USER_API_BRAINSTORM.md)
captures the intended IAL2 surface direction for a future AXI manager. Easy
mode is conventions over configuration, not a reduced subset: users submit
logical reads/writes and the manager owns AXI legality, outstanding windows,
IDs, ordering, interleaving where permitted, response matching, backpressure,
and clear full/acceptance/status feedback. Power mode exposes structured
overrides while preserving manager enforcement. Raw channel access should
normally be supervised by the same AXI rule engine, with any unsafe bypass
treated as verification-only and unable to claim guaranteed AXI correctness.

Public file-surface decision:
[decision 0016](../../decisions/0016-ppif-is-first-public-ial2-container.md)
selects `.ppif` as the first generic IAL2 file suffix and records the first
public Valid-Ready source shape. The first parser/CLI slice for `.ppif` is now
shipped by
[IAL2_PPIF_PARSER_CLI_FIRST_SLICE](../../IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md).
Public `.pif`, `.ppi`, `.axi`, protocol-profile aliases, and full AXI manager
behavior remain unshipped. Multi-channel `.ppif` Valid-Ready bundle
report/review-artifact behavior is now shipped in the bounded slice below;
aggregate semantic JSON is shipped as a bundle semantic root; and the tracked
AW/W bundle now generates an aggregate wrapper/top HDL entry.

First selected `.ppif` shape, checked in as
`ppif/axi_aw_valid_ready.ppif`:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

CLI examples for the shipped first public slice:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --outdir generated ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
```

The `.ppif` path always lowers through generated `.isf` before generated
`.fsm`. `--outdir` writes both review artifacts before the HDL path runs.
`--emit-schedule-json` emits the IAL2 source-anchor/residue report for the
source object, including the authored top-level PPIF intent name
`axi_aw_valid_ready`. `--emit-semantic-json` emits the bounded normalized
semantic report without writing HDL, while keeping `source.resolved_path` on
the public `.ppif` path and leaving the semantic payload rooted at the
generated `.fsm`. The capability manifest now advertises this file-layer stack
under `language_surface.file_surfaces`, including the `.ppif` sample path,
first-slice alias exclusions, and `supported_cli_modes[]` entries for
`--emit-schedule-json`, `--check --json` / `--check-json`, and
`--emit-semantic-json`. Later completed slices shipped public
`manager-capacity-status` `.ppif` syntax, optional static `(id-families ...)`
metadata, a selector for the next logical read/write
transaction-envelope/static-validation subset, and the readiness audit for its
additive static/report implementation boundary. The optional static
`(transactions ...)` implementation slice and the additive transaction event
dispatch/fan-in slice are now also shipped, and `.45` ships parser/report
metadata and static validation for the bounded public read-data payload/status
contract selected by `.44`. `.46` audits generated read-data capture behavior
readiness and selects `.47`, direct generated single-beat `RDATA`/`RRESP`
capture, with no new IAL1/IAL0/SystemVerilog prerequisite. `.47` ships that
generated capture behavior, `.48` selects AXI burst/`RLAST` completion
readiness, and `.49` selects public burst/`RLAST` completion contract
selection before parser/report metadata or generated behavior changes. The
`.50` selector chooses `response-scope burst-last` plus one-bit `last-signal`
as an additive read response-demux contract. `.51` ships parser/report
metadata and static validation for that contract with generated behavior
unchanged. `.52` selects direct generated burst-last/`RLAST` completion
behavior. `.53` ships that generated behavior. `.55` aligns the generated
report prose with shipped `RLAST` behavior. `.56` selects `.57`, public AXI
burst read-data contract selection, before parser/report metadata or generated
behavior changes. `.57` selects explicit last-beat read-data capture and
advances the frontier to `.58`, parser/report metadata and static validation.
`.58` ships that metadata with generated behavior deferred and advances the
frontier to `.59`, generated last-beat read-data capture readiness. `.59`
selects direct generated last-beat capture behavior and hands off to `.60`.
`.60` ships generated last-beat `RDATA`/`RRESP` capture behavior and hands off
to selector `.61`. `.61` selects public AXI burst read-data beat-count/depth
contract selection and hands off to `.62`. `.62` selects ARLEN-based
`burst-length` parser/report metadata and static validation and advances the
frontier to `.63`. `.63` ships that parser/report metadata and static
validation with a support-accounted sample while keeping generated artifacts
unchanged, then advances the frontier to `.64`. `.64` selects generated
ARLEN burst-length capture readiness and advances the frontier to `.65`.
`.65` audits that readiness, finds no new substrate prerequisite, and
advances the active frontier to `.66`. `.66` ships generated raw-ARLEN
capture behavior and advances the active frontier to `.67`, beat-count/RLAST
validation readiness. `.67` preserves `validation report-only` as
no-runtime-check behavior and selects `.68`, public runtime-validation
contract selection. `.68` selects `(validation runtime-assertion)` /
`runtime_assertion`, preserves report-only behavior, and advances the active
frontier to `.69`, the first generated beat-count/RLAST runtime-validation
implementation slice. `.69` ships that behavior and advances the active
frontier to `.70`, the next exact-owner selector.
Future behavior owners must keep the reviewable
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path; read-data
interleaving/reassembly, bursts, per-ID queues, full-manager behavior, and
VHDL remain out of scope unless a later exact owner selects them.
Additional `.ppif` objects/clauses and profile aliases remain future
exact-owner work, and they must not jump ahead of the active selector unless
that selector records why.

Multi-channel `.ppif` bundle support:
[IAL2_PPIF_MULTI_VALID_READY_READINESS](../../IAL2_PPIF_MULTI_VALID_READY_READINESS.md)
records why accepting multiple `(valid-ready-channel ...)` objects required an
aggregate contract rather than a parser-only change. The bounded implementation
is documented in
[IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE](../../IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md).
It accepts multiple unique Valid-Ready channel objects, emits the
`fsmgen.ial2.protocol_intent.valid_ready_bundle.v1` report, writes per-channel
generated `.isf`/`.fsm` review artifacts plus an aggregate wrapper/top `.fsm`
with `--outdir`, supports aggregate normalized semantic JSON, generates
SystemVerilog through that wrapper/top, and keeps `IAL2 -> IAL1 -> IAL0`
intact.
The semantic JSON slice is documented in
[IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE](../../IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md).

Selected future bundle contract:
[IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION](../../IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md)
and decision
[0017-ppif-valid-ready-bundle-contract](../../decisions/0017-ppif-valid-ready-bundle-contract.md)
select an aggregate PPIF bundle report over per-channel generated `.isf` and
`.fsm` review artifacts. The shipped first bundle slice avoids a hidden
multi-actor `.isf` file and forbids "first channel wins" HDL selection.
Default HDL for the tracked multi-channel bundle now uses the aggregate
wrapper/top `.fsm` generated from the top-level PPIF intent name. Aggregate
semantic JSON is an aggregate PPIF bundle root, not one generated channel root.
The HDL entry contract and first implementation are documented in
[IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION](../../IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md):
bundle HDL must use an aggregate wrapper/top entry with reviewable generated
IAL1 and IAL0 artifacts, not "first channel wins" root selection. The shipped
implementation is recorded in
[IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE](../../IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md).

Runnable bundle commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --outdir generated --output bundle.sv ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --strict --check --json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --outdir generated --output bundle.sv --verify-hdl ppif/axi_aw_w_valid_ready_bundle.ppif
```

The semantic export uses `semantic.module.source_root_kind = ppif_bundle` and
adds `semantic.protocol_intent_bundle`, including the bundle schema,
channel list, generated `.isf`/`.fsm` review artifact summaries, per-channel
schedule-report presence, and the selected aggregate wrapper/top HDL entry.
The wrapper/top HDL output contains the AW and W generated channel monitors and
the `axi_aw_w_valid_ready_bundle` wrapper module. The sampled-value assertions
keep `$past(...)` inside property text; sampled-value helper expressions are
not emitted as unclocked combinational assigns.

PDF extraction workflow:
[PDF_EXTRACTION_WORKFLOW](../../PDF_EXTRACTION_WORKFLOW.md)
documents the reusable source-anchored PDF extraction approach used for the
AXI evidence work. It covers task-tree ownership, metadata/hash checks, text
extraction, table handling, diagram/image rendering, visual QA,
troubleshooting, cleanup, validation, copyright hygiene, and the rule that
future flow improvements must update that document in the same task-owned
slice.

Protocol/platform surface decision:
[0014-protocol-platform-intent-surface-and-layered-lowering](../../decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)
records the generic future IAL2 file-surface direction, the open
`.pif`/`.ppi`/`.ppif` extension candidates, and the required
`IAL2 -> IAL1 -> IAL0` lowering chain. Decision
[0016-ppif-is-first-public-ial2-container](../../decisions/0016-ppif-is-first-public-ial2-container.md)
selects `.ppif` as the first public generic IAL2 suffix.

Profile-extension refinement:
[0015-ial2-profile-extensions-are-vocabulary-aliases](../../decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md)
records that protocol-specific extensions may be accepted later as profile
aliases, not separate semantic layers.

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
Bounded direct aggregate-output fixtures now lower generated inferred packed
struct outputs as VHDL `std_logic_vector` ports with the generated packed
widths.
It is covered by direct pipeline, CLI, and facade tests.

Composition VHDL now includes the bounded C3 external-RTL literal/concat top
for `t/corpus/composition_intent_integer_literals.fsm` and the bounded C1
standalone-DT passthrough top for
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, plus the bounded C2
generated-FSM scalar-autowire top for
`t/corpus/implicit_composition_system_autowire.fsm`, plus the bounded APB/C4
generated-FSM top for `fsm/apb_tb.fsm` with scalar integer, scalar expression,
one-bit sized bitstring, multi-bit sized bitstring, and resolved packed
aggregate plus resolved package-backed generic maps in the same APB/C4 shape.
Still backlog beyond those exact owners: broader generated-FSM/C4 composition
VHDL, internal-net-heavy composition tops beyond APB, composition generic maps
beyond shipped external-RTL scalar integer, scalar integer expression,
metadata-backed one-bit sized bitstring, and multi-bit sized bitstring
literal/resolved-package-constant actuals plus
resolved packed aggregate actuals and shipped generated-FSM scalar integer,
scalar expression, one-bit sized bitstring, multi-bit sized bitstring, and
resolved packed aggregate actuals, plus shipped APB/C4 generated-FSM scalar
integer, scalar expression, one-bit sized bitstring, and multi-bit sized
bitstring actuals plus resolved packed aggregate and resolved package-backed
actuals, aggregate VHDL record/array lowering,
C2 generated-FSM aggregate actuals that do not lower to one packed literal
now locked fail-closed before VHDL emission,
VHDL package
declaration/emission, multi-clock domains, GHDL validation, broad expression
parity, signed scalar division/modulo,
mixed signed/unsigned scalar arithmetic, mixed signed/unsigned vector
arithmetic, and full feature parity with the
SystemVerilog backend. Scalar division/modulo,
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
fixture. Maintained aggregate-output direct roots now lower as packed-vector
VHDL ports; full VHDL record/array aggregate lowering remains deferred.
External-RTL scalar integer, metadata-backed one-bit sized bitstring, and
multi-bit sized bitstring composition generic maps now lower to VHDL
`generic map` actuals before the port map, including qualified package
constants after they resolve to scalar integer or multi-bit sized bitstring
literals, scalar integer expressions such as `(16 + 1)`, one-bit scalar
actuals such as `ENABLE_DEFAULT => '1'`, and resolved packed aggregate values
such as `16'b1010010100111100`; broader
generic-map families remain deferred except for the bounded C1 standalone-DT
scalar integer actuals now emitted as `WIDTH => 16`, standalone-DT scalar
expression actuals now emitted as `EXPR_WIDTH => (8 + 1)`, standalone-DT
one-bit sized bitstring actuals now emitted as `ENABLE_DEFAULT => '1'`,
standalone-DT multi-bit sized bitstring actuals now emitted as
`RESET_VALUE => "10100101"`, standalone-DT packed-list actuals now emitted as
`LANES => "1010010100111100"`, standalone-DT packed-map actuals now emitted as
`FRAME => "101"`, bounded C2
generated-FSM scalar integer actuals now emitted as `WIDTH => 16`,
generated-FSM scalar expression actuals now emitted as `EXPR_WIDTH => (16 + 1)`,
one-bit sized bitstring actuals now
emitted as `ENABLE_DEFAULT => '1'`, multi-bit sized bitstring actuals now
emitted as `RESET_VALUE => "10100101"`, and resolved packed aggregate actuals
now emitted as VHDL bit strings, plus bounded APB/C4 generated-FSM scalar
integer actuals now emitted as VHDL integers such as `TIMEOUT_CYCLES => 8`
and scalar expression actuals emitted as VHDL expressions such as
`TIMEOUT_CYCLES => (4 + 1)`, and one-bit sized bitstring actuals emitted as
VHDL `std_logic` actuals such as `ENABLE_DEFAULT => '1'`, and multi-bit sized
bitstring actuals emitted as VHDL `std_logic_vector` actuals such as
`RESET_VALUE => "10100101"`, and resolved packed aggregate actuals emitted as
VHDL bit strings such as `LANES => "0011110010100101"` and `FRAME => "101"`.
APB/C4 resolved package-backed actuals now emit resolved VHDL literals such as
`TIMEOUT_CYCLES => 8` and `RESET_VALUE => "10100101"` without leaking
`param_pkg`.
The bounded C3 external-RTL
literal/concat structural top now emits a VHDL entity/architecture with
concurrent literal/concat assignments and an external `entity work.uart_tx`
port map. The bounded C1 standalone-DT passthrough structural top now emits the
standalone-DT child VHDL segment and a top-level
`entity work.standalone_route_src` port map; the same bounded C1 family now
also emits scalar integer generic maps such as `WIDTH => 16`, scalar
expression generic maps such as `EXPR_WIDTH => (8 + 1)`, and one-bit sized
bitstring generic maps such as `ENABLE_DEFAULT => '1'`, and multi-bit sized
bitstring generic maps such as `RESET_VALUE => "10100101"`, packed-list
generic maps such as `LANES => "1010010100111100"`, and packed-map generic
maps such as `FRAME => "101"` before that port map.
The bounded C2
generated-FSM scalar-autowire structural top now emits VHDL-safe generated-child
shared-datapath export ports/assignments, scalar structural signals, and both
generated child entity port maps; the same bounded C2 family now also emits
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, and resolved packed aggregate generic maps before the generated
child port map. The bounded APB/C4 generated-FSM structural top now emits APB requester/completer child
VHDL entities, vector APB
structural signals, deterministic shared-datapath sink signals, and both child
entity port maps; the same bounded APB/C4 family now also emits scalar integer
generic maps such as `TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, plus
scalar expression generic maps such as `TIMEOUT_CYCLES => (4 + 1)` and
`TIMEOUT_CYCLES => (3 + 3)`, plus one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, plus multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"` and `RESET_VALUE => "00111100"`, before the
requester/completer port maps; resolved packed aggregate generic maps such as
`LANES => "0011110010100101"` and `FRAME => "101"` also emit before those port
maps. Resolved package-backed generic maps such as `TIMEOUT_CYCLES => 8` and
`RESET_VALUE => "10100101"` also emit before those port maps without leaking
package tokens. Other
composition/top VHDL shapes remain
fail-closed after typed composition IR parsing, with the pipeline and CLI
pointing users to the scoped composition target-support diagnostic.

The compound update and update-shorthand fixtures now lower generated
direct-root vector arithmetic with numeric literal operands, such as `SRC + 2`,
`SRC - 1`, `byte_count + 4`, and `remaining - 3`, through target-width
`to_unsigned` casts. Typed read-only direct-root two-state signals now lower
generated `input bit FLAG_IN` and `input bit [7:0] BYTE_IN` ports to VHDL
`std_logic` and `std_logic_vector` input ports. Typed read-only direct-root
non-signed four-state signals now lower generated `input logic FLAG_IN` and
`input logic [7:0] BYTE_IN` ports to the same VHDL input-port shapes. The declarative bits
symbolic-width fixture now lowers
generated scalar and vector two-state `bit` internal declarations, such as
`bit FLAG;` and `bit [7:0] OUT;`, to VHDL `std_logic` and
`std_logic_vector` signals; signed vector declarations such as
`reg signed [3:0] NIB;` lower to VHDL `signed` signals. Package-backed
declarative `+types` fixtures now lower generated
non-signed four-state `logic` internal declarations, such as
`logic [7:0] ISYM;` and `logic LFLAG;`, to `std_logic_vector` and `std_logic`.
Generated internal `logic signed [MSB:LSB] NAME;` declarations now lower to
VHDL `signed` signals. Generated signed vector direct-root port declarations,
starting with `input logic signed [7:0] IN`, now lower to VHDL `signed` ports.
Generated signed scalar direct-root declarations from one-bit signed type
aliases, such as `input logic signed IN` and `logic signed OUT;`, now lower to
VHDL `std_logic` ports/signals. Signed scalar
addition/subtraction/multiplication RHS assignments and chains now lower as
one-bit `std_logic` bit-pattern logic: `+` and `-` become `xor` chains, and `*`
becomes an `and` chain. Signed scalar division/modulo and mixed signed/unsigned
scalar arithmetic remain fail-closed.
Same-width signed vector addition/subtraction/multiplication/division/modulo
RHS assignments now lower as signed VHDL arithmetic when the target and all operands are
same-width signed vectors, so a signed direct-root `SUM = (+ A B)` assignment
emits `SUM <= A + B;`, a signed `DIFF = (- A B)` assignment emits
`DIFF <= A - B;`, and a signed `PROD = (* A B)` assignment emits
`PROD <= resize(A * B, 8);`. Signed `QUOT = (/ A B)` emits
`QUOT <= resize(A / B, 8);`, and signed `REM = (% A B)` emits
`REM <= resize(A mod B, 8);`, rather than unsigned casts. Scalar signed
division/modulo, mixed signed/unsigned arithmetic, broader generated-FSM/C4
composition VHDL beyond the exact shipped fixtures, internal-net-heavy
composition tops beyond APB, composition generic maps beyond external-RTL
scalar integer, scalar integer expression, metadata-backed one-bit sized
bitstring, and multi-bit sized bitstring literal/resolved-package-constant
actuals plus resolved packed aggregate and standalone-DT scalar integer
actuals and generated-FSM scalar integer/scalar expression/one-bit sized
bitstring/multi-bit sized bitstring/resolved packed aggregate actuals plus
APB/C4 generated-FSM scalar integer/scalar expression/one-bit sized bitstring/
multi-bit sized bitstring/resolved packed aggregate/resolved package-backed
actuals, generated-FSM aggregate actuals that do not lower to one packed
literal now locked fail-closed before VHDL emission, aggregate
VHDL, VHDL package declaration/emission, GHDL validation, and full backend
parity remain outside the shipped
scaffold. Signed vector numeric-literal
addition/subtraction/multiplication/division/modulo also lower through
target-width `to_signed`, so `SUM = (+ A 1)` emits
`SUM <= A + to_signed(1, 8);`, `DIFF = (- A 1)` emits
`DIFF <= A - to_signed(1, 8);`, `PROD = (* A 2)` emits
`PROD <= resize(A * to_signed(2, 8), 8);`, `QUOT = (/ A 2)` emits
`QUOT <= resize(A / to_signed(2, 8), 8);`, and `REM = (% A 2)` emits
`REM <= resize(A mod to_signed(2, 8), 8);`. Mixed signed/unsigned vector
numeric arithmetic is locked fail-closed rather than lowering signed operands
through unsigned casts.
The AMBA requester direct fixture now lowers its bounded generated wrap
arithmetic through explicit unsigned target-width resizes: `wrap_span_q_next`
uses the mixed-width product `beats_total_q * addr_step_q`, `wrap_base_q_next`
uses `addr_q - addr_q % (beats_total_q * addr_step_q)`, and
`wrap_high_q_next` adds the same wrap-span product to the computed base. This
does not claim broad expression-parser parity; unrelated nested or
mismatched-width arithmetic still needs exact future owners.
The maintained direct aggregate-output fixtures now lower through the direct
VHDL scaffold as packed vectors: `NESTED` is
`std_logic_vector(6 downto 0)`, `OUT` is `std_logic_vector(2 downto 0)`, and
`OUT_FRAME` / `OUT_LANES` are 5-bit `std_logic_vector` ports. Full VHDL
record/array aggregate lowering remains a future exact owner.
Direct vector output-port next-signal assignments from unsized decimal
literals now lower through target-width `to_unsigned`; for example an 8-bit
interface output emits `OUT_next <= std_logic_vector(to_unsigned(165, 8));`
instead of a raw integer-to-vector assignment.
Signed vector output-port next-signal assignments from unsized decimal
literals now lower through target-width `to_signed`; for example an 8-bit
signed interface output emits `OUT_next <= to_signed(5, 8);` instead of a raw
integer-to-signed-vector assignment.

### GHDL Validation

Status: backlog, behind a VHDL validation leaf.

Goal: add GHDL validation once the VHDL backend subset is hardened enough for
tool validation.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys. The direct VHDL scaffold is regression-tested through deterministic
text and CLI routing, but not externally validated by GHDL yet. The current
environment blocker is reconfirmed by
`BACKEND-API-VALIDATION-FRONTIER.102.1`.

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

### Semantic Introspection And MCP Adapter

Status: proposed under
[`SEMANTIC-INTROSPECTION-MCP-FRONTIER`](../../tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md).

Goal: make FSMGen machine-controllable for LLM/AI automation by exposing stable
semantic introspection APIs first, then optional MCP adapters over those APIs.

Current boundary: FSMGen already has several machine-readable surfaces:
`--capability-manifest`, `--check --json`, `--emit-semantic-json`,
`--emit-schedule-json`, support accounting, stable diagnostics, generated
artifact inventories, and mdBook/corpus examples. These are candidates for a
future adapter, not proof that an MCP surface is shipped.

The owner-capture slice records the scope and leaves implementation inactive.
The first required implementation prerequisite is a no-code selector. It must choose the bounded
resource/tool/prompt subset, schema/versioning policy, safety model,
workspace/output restrictions, and whether the first adapter is CLI-driven,
in-process, or service-backed. Raw private AST, scheduler, and lowering objects
remain outside the public automation contract.

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
`ports[]` core entry keys, direct-root input-port target extension/entry keys,
composition-top port extension keys, and bounded
`nets[]`, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, and
nested `instances[].interface_ports[]` plus `instances[].port_bindings[]`
core and typed-extension entry keys. It now also advertises
`instances[].parameter_overrides[]` core, raw-value-extension, and
value-metadata-extension entry keys, advertises `assignment_records[]`
generated-enable structural entries, advertises bounded generated-enable net
source/target entry key families, and advertises `auxiliary_assignments[]` as
scalar-string compatibility entries. The `semantic.composition` contract
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

Shipped symbol-contract package-import export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.103.1` publishes bounded package-import
name-list entry metadata for `semantic.symbol_contract.package_imports` and
`semantic.forward_ir.intent_hir.symbol_contract.package_imports`.
`package_import_entry_value_kinds` is `[scalar_package_name]`, and
`package_import_entry_value_meaning` is `authored package-import package-name
string` on the top-level contract surface. The same meaning entries appear as
single-element arrays inside grouped `presence_key_family_map` discovery maps
so every grouped family-map value remains array-valued. Raw package-spec
internals, package source AST, package symbols, VHDL package
declaration/emission, and full normalized semantic export stabilization remain
deferred.

Completed backend/API frontier leaf
`BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API selector
after `.131.1` shipped direct VHDL non-signed vector positive numeric-literal
literal-literal modulo, the supported-smoke `.fsm` corpus passed under
`--language vhdl`, and `ghdl` remained unavailable. Completed selector leaf
`ARCHITECTURE-DEBT-FRONTIER.3` deferred broad ISF parser/lowerer extraction
until a stable family is proven by a future exact owner. The first exact
private lowerer extraction is now shipped by
`ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2`: `FSM::Scheduler::ISF::ATLGeneratedTop`
owns ATL generated-top schedule-report projection and data-link
child-interface marking without changing public reports, generated artifacts,
or HDL behavior. Broader parser/lowerer extraction remains deferred behind
future exact owners. Completed selection/evaluation leaves
`IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1` and `.2` found IAL2
design/probe ready. Completed implementation leaf
`AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1` ships the first in-process IAL2
generator. Completed implementation leaf
`IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1` ships the first public `.ppif` parser/CLI
path for one AXI Valid-Ready source object.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.4` ships the
first in-process AXI manager capacity/status generator. Completed selector
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.5` selects the public
`manager-capacity-status` `.ppif` syntax. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.6` ships that public parser/CLI first
slice. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.7`
selects AXI ID-family declaration/static validation. Completed readiness audit
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` selects the additive
capacity/status implementation boundary. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.9` ships optional `(id-families ...)`
metadata for that object. Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.10` selects the logical read/write
transaction-envelope/static-validation subset. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.11` selects the additive implementation
boundary. Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.12`
ships optional `(transactions ...)` metadata for that object and advances the
frontier to `.13`, the next IAL2 feature-completeness selector. Completed
selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.13` selects transaction
event dispatch and direction fan-in and advances the sequence to `.14`
readiness audit. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` selects the additive implementation
boundary and advances the sequence to `.15`. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.15` ships transaction event dispatch and
direction fan-in and advances the sequence to `.16`. Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.16` selects AXI manager ID/response
rule-engine readiness and advances the sequence to `.17`. Completed readiness
audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.17` selects additive concrete
transaction ID assertions and advances the sequence to `.18`. Completed
implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` ships concrete
transaction ID request/response assertions and advances the active frontier to
`.19`. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.19`
selects auto-ID lifecycle/request-ID drive readiness and advances the active
frontier to `.20`. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.20` selects bounded auto-ID
pool/request-ID drive contract selection and advances the active frontier to
`.21`. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.21`
selects explicit optional `auto-id-lifecycle` bounded-pool syntax and advances
the active frontier to `.22`, parser/report metadata and static validation.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.22` ships
public `auto-id-lifecycle` parser/report metadata and static validation
without generated `.isf`, `.fsm`, or HDL behavior changes, and selected `.23`
as bounded request-ID drive behavior.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.23` ships
bounded request-ID drive behavior for explicit auto-ID lifecycle families and
selected `.24` as the next exact IAL2 feature-completeness selector.
Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.24` selects AXI generated response-demux
readiness and selected `.25` as the readiness audit. Completed readiness audit
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.25` selects bounded write
response-demux public contract selection and selected `.26` as the contract
selector. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.26`
selects explicit write-only response-demux syntax and advances the active
frontier to `.27`. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.27` ships parser/report metadata and
static validation for that syntax, adds the response-demux sample and support
accounting entry, and selected completed `.28` for generated write
response-demux behavior readiness. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` selects `.29` as the minimal IAL1
rule-pulse prerequisite before generated response-demux completion rules ship.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` ships
that bounded `(pulse target)` rule action and selects `.30` for generated
write `BID` response-demux behavior.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` ships
generated write `BID` response-demux behavior and selects `.31` as the next
exact IAL2 feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.31` selects `.32`
to align `auto_id_lifecycle.residue` after generated write `BID` response
demux before larger ordering/read-response work.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` ships
that report-residue alignment and selects `.33` as the next exact IAL2
feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` selects AXI
same-ID ordering readiness and advanced the frontier to `.34`.
Completed readiness audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.34`
selects bounded auto-ID same-ID avoidance assertions/report metadata and
advances the active frontier to `.35`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.35` ships
bounded auto-ID same-ID avoidance assertions/report metadata and advances the
active frontier to `.36`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.36` selects read
`RID` response-demux readiness and advances the active frontier to `.37`.
Completed readiness audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`
selects bounded read response-demux public contract selection and advances
the active frontier to `.38`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.38` selects
explicit `(response-scope single-beat)` read response-demux syntax and advances
the active frontier to `.39`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` ships
read response-demux parser/report metadata and static validation while keeping
generated read behavior unchanged, and advances the active frontier to `.40`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.40` selects
bounded generated single-beat read `RID` response-demux behavior and advances
the active frontier to `.41`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` ships
bounded generated single-beat read `RID` response-demux behavior and advances
the active frontier to `.42`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` selects
read-data payload, burst/`RLAST`, and per-ID readiness as the next audit and
advances the active frontier to `.43`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.43` selects the
bounded public read-data payload/status contract selector and advances the
active frontier to `.44`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.44` selects
explicit bounded `(read-data (read ...))` syntax and advances the active
frontier to `.45`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` ships
read-data parser/report metadata and static validation while keeping generated
read-data capture behavior unchanged, and advances the active frontier to
`.46`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` selects
generated single-beat `RDATA`/`RRESP` capture behavior and advances the active
frontier to `.47`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.47` ships
generated single-beat `RDATA`/`RRESP` capture behavior and advances the active
frontier to `.48`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.48` selects AXI
burst/`RLAST` completion readiness as the next exact prerequisite after
generated single-beat read-data capture and advances the active frontier to
`.49`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.49` selects
public AXI burst/`RLAST` completion contract selection before parser/report
metadata or generated behavior changes and advances the active frontier to
`.50`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.50` selects
additive read `response-demux` syntax for `response-scope burst-last` with
one-bit `last-signal` and selected `.51`, parser/report metadata and static
validation.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.51` ships
report-only burst-last `RLAST` response-demux metadata and static validation
and advances the active frontier to `.52`, generated burst-last/`RLAST`
completion behavior readiness.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.52` selects
direct generated burst-last/`RLAST` completion behavior and advances the
active frontier to `.53`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` ships
generated burst-last/`RLAST` completion behavior and advances the active
frontier to `.54`, the next AXI manager feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.54` selects
narrow AXI `RLAST` report/static-text alignment and advances the active
frontier to `.55`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`
aligns generated AXI `RLAST` report prose with shipped behavior and hands
off to selector `.56`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.56` selects
public AXI burst read-data contract selection and hands off to selector
`.57`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` selects
explicit last-beat read-data parser/report metadata and advances the active
frontier to `.58`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.58` ships
parser/report metadata and static validation for explicit last-beat read-data
capture and hands off to readiness audit `.59`.
Completed readiness-audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.59`
selects direct generated last-beat read-data capture behavior and hands off to
`.60`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.60` ships
generated last-beat `RDATA`/`RRESP` capture behavior and hands off to selector
`.61`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.61` selects
public AXI burst read-data beat-count/depth contract selection and hands off to
`.62`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.62` selects
ARLEN-based `burst-length` parser/report metadata and static validation and
advances the frontier to `.63`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.63` ships
parser/report metadata and static validation for ARLEN-based `burst-length`
contracts and advances the frontier to `.64`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.64` selects
generated AXI ARLEN burst-length capture readiness and advances the active
frontier to `.65`.
Completed audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.65` selects direct
generated raw-ARLEN capture behavior and advances the active frontier to
`.66`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.66` ships
generated raw-ARLEN capture behavior and advances the active frontier to
`.67`, beat-count/RLAST validation readiness.
Completed audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.67` preserves
`validation report-only` as no-runtime-check behavior, selects public
beat-count/RLAST runtime-validation contract selection, and advances the
active frontier to `.68`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.68` selects
`(validation runtime-assertion)` / `runtime_assertion`, preserves
`validation report-only` as report-only metadata, and advances the active
frontier to `.69`, the first generated beat-count/RLAST runtime-validation
implementation slice.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.69` ships
generated beat-count/RLAST runtime validation for `(validation
runtime-assertion)` burst-length contracts and advances the active frontier
to `.70`, the next exact-owner selector. Completed selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.70` advances the active frontier to
`.71`, public AXI multi-beat read-data reassembly/output contract selection,
before parser, generator, HDL, sample, support-accounting, check JSON,
semantic JSON, or validation behavior changes.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.71` advances the
active frontier to `.72`, parser/report metadata and static validation for
the selected public multi-beat read-data contract.
Completed implementation `IAL2-FEATURE-COMPLETENESS-FRONTIER.72` ships
parser/report metadata and static validation for the selected public
multi-beat read-data output-bank contract, adds
`ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`, reports
generated lane names, valid-mask widths, length-output widths, and output-bank
shape, and advances the active frontier to `.73`, generated multi-beat
read-data reassembly/output readiness.
Completed audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.73` finds no lower-layer
prerequisite for first generated output-bank behavior and advances the active
frontier to `.74`, generated multi-beat read-data output-bank behavior.
Completed implementation `IAL2-FEATURE-COMPLETENESS-FRONTIER.74` ships
generated multi-beat read-data output-bank behavior and advances the active
frontier to `.75`, the next AXI manager feature-completeness selector.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selects public
scalar `RRESP` aggregation contract selection and advances the active
frontier to `.76`.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.76` selects additive
`(status-aggregation (policy worst-observed))` syntax, per-transaction
`(status-aggregate-output NAME)` bindings, and advances the active frontier
to `.77`, parser/report metadata and static validation for scalar `RRESP`
aggregation.
Completed implementation leaf
`ARCHITECTURE-DEBT-FRONTIER.2.1`
projects direct backend storage/helper declaration-plan entries into
`structural_rtl_ir.nets[]` without rerouting HDL emission. Completed
implementation leaf
`R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2`
projects top-level direct state and standalone-DT enable wires into
`structural_rtl_ir.nets[]` without claiming DT-specific/LHS WEN/EN wires,
assignment connectivity, instances, links, auxiliary assignments, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1`
projects direct DT-specific and LHS-level WEN/EN wires into
`structural_rtl_ir.nets[]` as declaration-only one-bit nets without claiming
assignment connectivity, instances, links, auxiliary assignments, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2`
projects already-rendered direct generated enable assignment lines into
`structural_rtl_ir.auxiliary_assignments[]` as scalar strings without claiming
assignment records, direct net connectivity, instances, links, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2`
projects those generated enable assignments into
`structural_rtl_ir.assignment_records[]` as machine-readable records while
retaining `auxiliary_assignments[]` as the compatibility mirror and without
rerouting HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`
populates generated-enable direct net `source` objects for assignment-record
drivers and `targets[]` entries for direct nets consumed by another
generated-enable assignment-record RHS. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
populates direct input-port generated-enable RHS target connectivity on
`structural_rtl_ir.ports[]`, while leaving HDL emission unchanged. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2`
populates direct output-port `source` summaries from lowered output-drive
families, while leaving broader always-block body consumer modeling and HDL
emission unchanged. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
reroutes the direct SystemVerilog top state/standalone-DT generated-enable
condition block through `StructuralRTLIR` assignment records by using explicit
backend markers that are removed before final HDL is returned. Full direct
module rerouting is deferred by selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` until direct behavior-body,
state-update, output, and assertion regions have exact structural ownership.
VHDL backend/reroute work is deferred by selector
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete. Completed selector leaf
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep empty instance/link arrays, with populated instances and links remaining
composition-top structural facts. Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.131.1` lowers an 8-bit non-signed
`REM = (% 2 3)` fixture into
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.130.1` lowers an 8-bit non-signed
`QUOT = (/ 2 3)` fixture into
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.129.1` lowers an 8-bit non-signed
`PROD = (* 2 3)` fixture into
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.128.1` lowers an 8-bit non-signed
`REM = (% 2 A)` fixture into
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.127.1` lowers an 8-bit non-signed
`QUOT = (/ 2 A)` fixture into
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.126.1` lowers an 8-bit non-signed
`PROD = (* 2 A)` fixture into
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.125.1` lowers an 8-bit non-signed
`REM = (% A 2)` fixture into
`REM <= std_logic_vector(resize(unsigned(A) mod to_unsigned(2, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.124.1` lowers an 8-bit non-signed
`QUOT = (/ A 2)` fixture into
`QUOT <= std_logic_vector(resize(unsigned(A) / to_unsigned(2, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.123.1` lowers an 8-bit non-signed
`PROD = (* A 2)` signal-first fixture into
`PROD <= std_logic_vector(resize(unsigned(A) * to_unsigned(2, 8), 8));`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.122.1` lowers
direct VHDL non-signed vector modulo with a negative decimal numeric literal
into target-width resized unsigned arithmetic over a two-complement literal,
so the selected 8-bit fixture emits
`REM <= std_logic_vector(resize(unsigned(A) mod unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A % -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.121.1` lowers
direct VHDL non-signed vector division with a negative decimal numeric literal
into target-width resized unsigned arithmetic over a two-complement literal,
so the selected 8-bit fixture emits
`QUOT <= std_logic_vector(resize(unsigned(A) / unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A / -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.120.1` lowers
direct VHDL non-signed vector multiplication with a negative decimal numeric
literal into target-width resized unsigned arithmetic over a two-complement
literal, so the selected 8-bit fixture emits
`PROD <= std_logic_vector(resize(unsigned(A) * unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A * -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.119.1` lowers
direct VHDL non-signed vector subtraction with a negative decimal numeric
literal into unsigned arithmetic over a target-width two-complement literal,
so the selected 8-bit fixture emits
`DIFF <= std_logic_vector(unsigned(A) - unsigned(to_signed(-1, 8)));`
instead of failing at arithmetic expression `'A - -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.118.1` lowers
direct VHDL non-signed vector addition with a negative decimal numeric literal
into unsigned arithmetic over a target-width two-complement literal, so the
selected 8-bit fixture emits
`SUM <= std_logic_vector(unsigned(A) + unsigned(to_signed(-1, 8)));` instead
of failing at arithmetic expression `'A + -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.117.1` lowers
direct VHDL signed vector modulo with a negative decimal numeric literal into
target-width resized signed VHDL arithmetic, so the selected 8-bit signed
fixture emits `REM <= resize(A mod to_signed(-2, 8), 8);` instead of failing
at arithmetic expression `'A % -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.116.1` lowers
direct VHDL signed vector division by a negative decimal numeric literal into
target-width resized signed VHDL arithmetic, so the selected 8-bit signed
fixture emits `QUOT <= resize(A / to_signed(-2, 8), 8);` instead of failing
at arithmetic expression `'A / -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.115.1` lowers
direct VHDL signed vector multiplication with a negative decimal numeric
literal into target-width resized signed VHDL arithmetic, so the selected
8-bit signed fixture emits `PROD <= resize(A * to_signed(-2, 8), 8);`
instead of failing at arithmetic expression `'A * -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.114.1` lowers
direct VHDL signed vector subtraction with a negative decimal numeric literal
into signed VHDL arithmetic, so the selected 8-bit signed fixture emits
`DIFF <= A - to_signed(-1, 8);` instead of failing at arithmetic expression
`'A - -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.113.1` lowers
direct VHDL signed vector addition with a negative decimal numeric literal into
signed VHDL arithmetic, so the selected 8-bit signed fixture emits
`SUM <= A + to_signed(-1, 8);` instead of failing at arithmetic expression
`'A + -1'`. Non-signed vector negative modulo remains deferred.
Completed implementation
leaf `BACKEND-API-VALIDATION-FRONTIER.112.1` lowers direct VHDL scalar
output-port next-signal assignments from negative decimal literals into
`std_logic` low-bit assignments, so the selected plain scalar fixture emits
`FLAG_next <= '1';` for `-1` and the signed one-bit alias fixture emits
`FLAG_next <= '0';` for `-2` instead of failing at arithmetic expression
`'-1'` or `'-2'`. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.111.1` lowers direct VHDL non-signed vector
output-port next-signal assignments from negative decimal literals into
VHDL-typed `std_logic_vector` assignments, so the selected 8-bit
interface-output fixture emits `OUT_next <= std_logic_vector(to_signed(-1,
8));` instead of failing at arithmetic expression `'-1'`. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.111` chose that edge after the probe generated
`std_logic_vector` output/next-signal declarations but failed before VHDL
emission. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.110.1` lowers direct VHDL signed vector
output-port next-signal assignments from negative decimal literals into
VHDL-typed signed assignments, so the selected 8-bit signed interface-output
fixture emits `OUT_next <= to_signed(-1, 8);` instead of failing at arithmetic
expression `'-1'`. Later leaves now cover non-signed vector and scalar
negative output literals too. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.110` chose that edge after the probe generated
`signed` output/next-signal declarations but failed before VHDL emission.
Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.109.1` lowers direct VHDL scalar output-port
next-signal assignments from unsized decimal literals into `std_logic` low-bit
literal assignments, so the selected plain scalar fixture emits
`FLAG_next <= '0';` for `2` and the signed one-bit alias fixture emits
`FLAG_next <= '1';` for `3` instead of raw integer assignments. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.109` chose that edge after the probes
generated `std_logic` output/next-signal declarations but still wrote raw
`FLAG_next <= 2;` in the VHDL combinational assignment. Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.108.1` lowers direct VHDL signed vector
output-port next-signal assignments from unsized decimal literals into
VHDL-typed signed assignments, so the selected 8-bit signed interface-output
fixture emits `OUT_next <= to_signed(5, 8);` instead of raw
`OUT_next <= 5;`. Selector leaf `BACKEND-API-VALIDATION-FRONTIER.108` chose
that edge after the probe emitted `signed` output/next-signal declarations but
still wrote the raw integer assignment. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.107.1` lowers direct VHDL vector output-port
next-signal assignments from unsized decimal literals into VHDL-typed vector
assignments, so the selected 8-bit interface-output fixture emits
`OUT_next <= std_logic_vector(to_unsigned(165, 8));` instead of raw
`OUT_next <= 165;`. Selector leaf `BACKEND-API-VALIDATION-FRONTIER.107` chose
that edge after the probe emitted `std_logic_vector` output/next-signal
declarations but still wrote the raw integer assignment.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.106.1` lowers `input logic IN` and
`input logic [7:0] IN` to VHDL `std_logic` / `std_logic_vector` ports.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.106` chose that exact logic-input edge after
typed read-only direct-root probes stopped at the direct VHDL port parser.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.105.1` lowers `input bit IN` and
`input bit [7:0] IN` to VHDL `std_logic` / `std_logic_vector` ports.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.105` chose that exact input-port edge after
typed read-only direct-root probes stopped at the direct VHDL port parser.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.104.1` lowers those generated declarations to
`std_logic_vector` signals through pipeline, CLI, and facade coverage.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.104` chose that exact vector-bit declaration
edge after representative normalized semantic probes found no unadvertised
bounded top-level contract keys and a direct VHDL probe stopped at
`bit [7:0] OUT;`. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.102.1` reconfirms that VHDL external validation
remains blocked because `ghdl` is unavailable. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.101.1` locks declared aggregate structural VHDL
ports/nets/types as fail-closed before record/array emission. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.100.1` locks package roots as import-only
declaration containers that do not generate standalone SystemVerilog or VHDL
package HDL directly.
Package declaration and VHDL package emission, already bounded
constant/enum/type internals, unrelated forward-IR payloads, signed scalar
division/modulo, mixed signed/unsigned arithmetic, standalone-DT generic maps
beyond scalar integer, scalar expression, one-bit sized bitstring, multi-bit
sized bitstring, packed-list, and packed-map actuals,
APB/C4 generic maps beyond scalar integer, scalar expression, one-bit sized
bitstring, multi-bit sized bitstring, resolved packed aggregate, resolved
package-backed actuals, and non-packed aggregate actuals now locked fail-closed
before VHDL emission, external-RTL aggregate actuals that do not lower to one
packed literal now locked fail-closed before VHDL emission, standalone-DT
aggregate actuals that do not lower to one packed literal now locked
fail-closed before VHDL emission, generated-FSM aggregate actuals that do not
lower to one packed literal now locked fail-closed before VHDL emission,
full aggregate VHDL record/array lowering, broader generated-FSM/C4
composition VHDL beyond the exact shipped fixtures, internal nets/generic maps
beyond APB, broader expression parity beyond the shipped AMBA wrap family, and
full normalized semantic export stabilization remain out of scope until later
exact leaves own them.
Package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`; this keeps `?pkg` roots import-only
and still does not implement VHDL package declaration/emission.
Declared aggregate structural VHDL ports/nets/types are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.101.1`; this keeps composition tops from
emitting VHDL record/array declarations until a future exact aggregate-lowering
leaf owns them.
GHDL validation blocker reconfirmation is locked by
`BACKEND-API-VALIDATION-FRONTIER.102.1`: `ghdl` is unavailable in the current
environment, so external HDL validation remains SystemVerilog-only until a
future exact GHDL lane can run the tool.
