# Composition Basics

Composition is the `?top` layer that lets FSMGen build one top module from
multiple child blocks.

Current child kinds are:

- `?fsmc` for generated FSM children
- `?dtc` for generated standalone-DT children
- `?rtl` for external RTL children

Other child headers such as `?bogus:child` are rejected as unsupported child
kinds; FSMGen does not reinterpret unknown composition children as raw HDL or
legacy extension hooks.

The parser now accepts top `+params` declarations and resolves their defaults
after package imports. Scalar fixed-interface RTL sources now preserve their
defaults and child bindings through HDL; the exact bounded profile and runnable
example are below. Generated-child and mutable-interface sources still refuse.
Configurable parameters stay separate from the static symbol table used by
existing child overrides.

For example, this tracked refusal fixture collects declarations across blocks,
resolves a forward alias and imported aggregate values, then reaches the explicit
lowering boundary before trying to realize its child:

```lisp
{{#include ../../../t/corpus/composition_top_parameters_lowering_pending.fsm}}
```

Run `./bin/fsmgen --strict --check --json
t/corpus/composition_top_parameters_lowering_pending.fsm`. It currently reports
`FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING`. The native check, in-process API
and newline MCP return the same source refusal. This example does not generate
HDL yet.

Defaults use the canonical parameter value rules, with acyclic forward references,
scalar and aggregate values, package symbols and direct parameter reference
identity. Multiple blocks contribute to one declaration order. Empty sections,
malformed entries, invalid identifiers, duplicate names, dependency cycles and
unknown names refuse. A parameter name must differ from local constant and enum
roots and imported package roots; this prevents ambiguous static/configurable
lookup. Named types keep their separate namespace. Top declarations and default
source/value getters return detached records.

The compiler also retains scoped default bindings. In the fixture above,
`BOUND` remains a reference to the actual `WIDTH` declaration; the imported
`WIDTH` default remains static. Equal default values do not merge declarations,
and aliases retain their immediate reference. Aggregate paths retain their
parameter root and suffix; operators, list order and map fields retain their
structure. Static symbols keep their lookup identity and selected value cache.
`Top::parameter_default_bindings()` exposes detached compiler records beside
the unchanged normalized default graph. A failed retry clears both graphs.
Instance overrides retain actual scoped bindings beside their canonical validation
values. The fixed-interface RTL source profile below admits only qualified
scalar relationships; generated and mutable-interface plans remain blocked.

Prepared port declarations also accept verbose width expressions, for example
`(input data (width (+ (param WIDTH) 2)))`. The shared bounded integer evaluator
resolves these after imports and top defaults. Bare operands select static
symbols; `(param NAME)` selects only a declared parameter, even when a static
symbol has an equal value. Arithmetic uses the direct width operators and
requires nonnegative intermediate results and a positive final width; aggregate
parameters, unknown names and unsupported operators refuse with top/port context.
Compact widths and named-type precedence keep their existing meaning.
`Port::width_token()` returns the detached authored AST;
`Port::width_contract()` returns its `scope`, `expression` and ordered actual
`references`. Each lookup carries `kind` (`parameter` or `static_symbol`) and
`token`; static lookups also retain `value_payload`. Aliases keep their selected
name beside the cached `width()`. Re-resolution uses source rather than the old
cache. Retries clear all expression ports before imports/defaults and publish
new widths/contracts only after every declaration resolves successfully.
See the [source fixture](../../../t/data/composition-top-port-width-expressions.fsm)
and [focused test](../../../t/2129-composition-port-width-expressions.t).
`Plan::ports()` captures separate structured-width Port objects beside its
parameter environment and returns fresh copies on access. Later source retries
or getter mutations cannot mix another width epoch into that captured plan;
unresolved expression widths refuse capture. Ordinary static port behavior
stays unchanged. The [snapshot regression](../../../t/2130-composition-port-width-plan-snapshots.t)
checks actual source retries and complete serialized plan stability.
Prepared normalized reports also retain `width_contract` under structural
`ports[]`, IntentHIR `signal_analysis` bucket entries, common
`semantic.signal_analysis` entries and plan-snapshot `top_ports[]`.
`composition_parameter_contract.width_contract_paths` names the exact paths;
its `width_analysis_buckets` bounds wildcard expansion. `width_contract_keys`
and `width_reference_keys` describe the exact object and kind-specific lookup
keys; static payloads use the existing recursive payload schema. The authored
`expression` remains a frontend JSON tree, separate from its numeric cache.
These optional records have no separate schema/version envelope. Ordinary
static ports omit them. Object and hash snapshots detach the structured width
AST/contract and refuse non-JSON references. Supplied structural IR must match
its plan's captured width, scope and dependency identities before IntentHIR
accepts it. The [public-contract test](../../../t/2131-composition-port-width-public-contract.t)
checks actual source/Plan/IR/report allocation and isolation.

These inspection records cover more than the bounded source profile below.
Parameter-dependent interface specialization remains pending at source admission.
Direct prepared emitters can render captured ranges with a matching environment;
a cached positive width alone cannot supply that environment or its dependencies.
Parameterized `.isf` widths remain outside this source profile.

`Top::parameter_environment()` captures these actual resolved products as
separate scope, declaration order, normalized parameters, authored default
sources and scoped default bindings. A plan constructed from that source owns
a detached snapshot, available through `Plan::parameter_environment()`.
Caller retries and getter mutations cannot change an existing snapshot;
unresolved or failed defaults refuse new capture. Tops without parameters keep
no environment. Both forward IR builders and structural hash coercion preserve
the full environment; IntentHIR's parameter names follow authored order. A
supplied structural environment must match its actual plan. Successful default
resolution also captures the separate static-symbol/import contract, so a later
caller cache edit cannot mix new static facts with older parameter defaults.
Constructor/getter/hash mutation remains isolated.

In-process normalized semantic reports now preserve this environment in
`semantic.forward_ir.intent_hir.parameter_environment`,
`semantic.forward_ir.structural_rtl_ir.parameter_environment`, and
`semantic.composition.plan_snapshot.parameter_environment`. These optional
objects contain exactly `scope`, `declaration_order`, `parameters`,
`default_sources`, and `default_bindings`. Static snapshots omit the field.
The plan snapshot owns a JSON-safe copy, including for hash-backed callers.
These builders describe the actual resolved objects supplied by the caller;
a hand-built hash does not establish source provenance.

Capability discovery exposes `composition_parameter_contract` under
`semantic_exports.normalized_semantic_json`. It names the optional paths,
source owners, exact recursive environment/binding/payload/type key families,
and schema-version semantics. For example:

```bash
./bin/fsmgen --capability-manifest | python3 -c 'import json,sys; print(json.load(sys.stdin)["semantic_exports"]["normalized_semantic_json"]["composition_parameter_contract"]["environment_paths"])'
```

The enclosing report and discovery schema stay at version 1; environment and
binding nodes have no separate version envelope. `parameters` contains resolved
validation caches, while `default_sources` retains authored trees and ordered
references. `default_bindings` preserves the scoped expression structure.
The three maps use declared parameter names; `declaration_order` preserves the
authored order independently of lazy resolution. Numeric equality cannot select
an owner. Recursive binding nodes distinguish literals, parameters, static
symbols, semantic payloads, operators, lists and maps. Optional instance
`binding_expression` fields use this same family alongside their validation
cache; static overrides gain no symbolic binding field. Matched declarations
may add the optional metadata described below.

Scalar top parameters now have a bounded successful source profile:
`composition_parameter_contract.fixed_interface_rtl_source`. It admits scalar
top defaults and scalar child actuals when every child is external RTL with a
published fixed `.rtlif` interface, and top widths contain no mutable parameter
references. Defaults and actuals retain selected names instead of validation
numbers. Generated children, aggregate top defaults and top widths selecting
`(param NAME)` still refuse with `FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING`.
Equal default widths never establish interface independence. A static generated
child literal actual can be emitted while the child interface still uses its
default width; generic HDL and per-instance specialization must precede admission.

For example, this complete source preserves `COPY = WIDTH`, `TOTAL = COPY + 2`
and the selected child bindings:

```lisp
(?top:composition_scalar_rtl_parameters
  (+params (COPY WIDTH) (WIDTH 16) (SAME 16) (TOTAL (+ COPY shared.EXTRA)))
  (+import shared)
  (?ports drive<1 ready>1)
  (?rtl:u_leaf (module scalar_leaf) (params (COUNT TOTAL) (OTHER SAME)))
  (?wiring:links (drive u_leaf.enable) (u_leaf.ready ready))
)
(?pkg:shared (+constants (EXTRA 2)))
(?rtlif:scalar_leaf (params (COUNT 8) (OTHER 8)) enable<1 ready>1)
```

```bash
./bin/fsmgen --quiet --strict --check --json t/corpus/composition_scalar_rtl_parameters.fsm
./bin/fsmgen --quiet --strict --language vhdl --check --json t/corpus/composition_scalar_rtl_parameters.fsm
```

The Verilog-family top emits `.COUNT(TOTAL)` and `.OTHER(SAME)`; VHDL emits
`COUNT => TOTAL` and `OTHER => SAME`. SystemVerilog/Verilog use untyped scalar
top defaults. VHDL retains its natural top defaults, declaration-qualified
integer child actuals and existing bounded external-RTL composition shapes.
All existing target, namespace, type, lane and connection checks still apply.
The `.rtlif` ports are the external module's fixed public interface contract;
FSMGen does not inspect the RTL implementation to infer parameterized ports.
Ordinary static compositions retain their existing lanes.

The source/HDL support flags are true within this named profile. The prepared
emitter profiles below are broader: they also render symbolic port ranges and
some generated-child actuals, so their whole-profile `source_admission` flags
remain false. The [source regression](../../../t/2141-composition-scalar-rtl-source-admission.t)
qualifies actual planning, native strict checks and generated text for
SystemVerilog, Verilog and VHDL, plus representative native semantic export.
External override legality, external HDL compilation/runtime and complete
API/MCP/profile qualification remain pending.

The direct Verilog-family structural IR emitter now supports prepared scalar
top defaults and child actuals when a matching captured environment is present.
It emits untyped `parameter` defaults in canonical dependency order; the earliest
currently ready authored declaration wins each tie. Immediate aliases, nested
operators, literal sizing and static values survive. For example, `ALIAS` can
remain `WIDTH`, `SUM` can remain `(ALIAS + 2)`, and a child's `.WIDTH(SUM)`
remains configurable independently of its validation cache. Inferred validation
widths do not become fixed parameter declaration sizes. Ordinary static module
formatting and static/literal child actuals retain their existing behavior.

The internal [scalar binding renderer](../../../perl/FSM/Backend/VerilogFamily/CompositionBindingEmitter.pm)
delegates canonical node validation and scalar rendering to `ParameterBindingEmitter`,
retaining its composition-top scope and diagnostics. The
[declaration preparer](../../../perl/FSM/Backend/VerilogFamily/CompositionParameterEmitter.pm)
reserves actual module, port, net, instance and
collected typedef names in the case-sensitive target namespace. Cycles,
incomplete binding membership, foreign scopes, reserved identifiers, aggregate parameter defaults, symbolic
aggregate actuals and raw expression payloads refuse. Symbolic child actuals
without a captured environment still refuse instead of emitting cached numbers.
Explicit typed top parameters remain outside this prepared profile.
Parameter-bearing source plans beyond the fixed-interface RTL subset retain
`FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING`; VHDL has its separate profile below.

Captured scalar port widths also render through the internal
[width renderer](../../../perl/FSM/Backend/VerilogFamily/CompositionWidthEmitter.pm).
For `(input data (width (param ALIAS)))`, the prepared emitter writes
`input [(ALIAS - 1):0] data` even when the default width is one. Numeric port
width caches never supply this range. Scoped parameter selectors retain actual
names; bare static symbols use captured integer payloads. Static expression
subtrees fold to decimal integers; symbolic arithmetic retains explicit
left-associated parentheses and the shared width evaluator's default checks.
Signed/state flags survive, and ordinary static/named-type ports retain their
existing declarations. Combining a declared type with an expression width,
foreign scopes, incomplete or out-of-order lookups, aggregates and unsupported
operators refuses. The [range fixture](../../../t/data/composition-symbolic-port-ranges.fsm)
and [focused regression](../../../t/2135-composition-symbolic-port-ranges.t)
exercise actual parsed/imported declarations and captured Plan/IR products.
This prepares direct symbolic-range emission only; source admission of mutable
interfaces, external override legality, internal-net width propagation and HDL
runtime qualification remain pending.

Discovery's `composition_parameter_contract.prepared_scalar_emission` names the
direct targets (`systemverilog`, `sv`, `verilog`, `v`), supported `top_defaults`,
`child_actuals` and `symbolic_port_widths`, with false `typed_top_parameters`
and `source_admission`. Source/HDL support flags apply within the separately
named fixed-interface RTL source profile.
The [source fixture](../../../t/data/composition-scalar-emission.fsm) and
[emission test](../../../t/2134-composition-scalar-structural-emission.t) use
actual import resolution, child declaration validation and captured Plan/IR.
[Declaration checks](../../../t/2133-composition-top-declaration-lowering.t)
cover forward/default/namespace meaning; the
[binding checks](../../../t/2132-composition-scalar-binding-renderer.t) cover
canonical expression boundaries. These focused checks do not qualify external
HDL compilation/runtime or complete profile and transport matrices.

The VHDL [generic preparer](../../../perl/FSM/Backend/VHDL/CompositionParameterEmitter.pm)
and direct structural emitter now consume dependency-ordered `natural` top
defaults from matching captured environments. Plain nonnegative decimal literals, aliases,
captured decimal static values and canonical `+`, `-`, `*`, `/`, `%` arithmetic
are prepared; `%` renders as VHDL `mod`. Rendered arithmetic steps must remain
nonnegative and within the portable integer range through `2147483647`.
Defaults retain parameter names rather than validation values. Names must be
non-reserved VHDL basic identifiers; module, port, signal, instance and parameter
names reserve a case-insensitive namespace. Generated `natural`, `std_logic`,
`std_logic_vector` and `signed` type names are also reserved. Sized literals, aggregate defaults,
bitwise operators, foreign scopes, cycles and incomplete bindings refuse.
The [source fixture](../../../t/data/composition-vhdl-natural-generics.fsm) and
[focused preparation test](../../../t/2136-composition-vhdl-natural-generics.t)
cover actual parsed/imported Plan/IR and independent order, cache and namespace
controls. External override legality and full qualification remain pending.

Validated RTL, FSM and standalone-DT child overrides now retain the matched
declaration's canonical `declaration_default_value_text`, `payload`, `kind`,
`width` and `type_spec`, with the same `declaration_default_value_` prefix.
Optional `declaration_default_source_expression` separately preserves the
authored frontend tree, including aliases. For example, equal actual values
can target defaults `1`, `1'b1` and `8'h01`; declaration text and payload keep
their different generic types distinguishable. Width alone cannot do so.
These detached fields survive realization, structural IR and prepared reports.
Absent source records gain no invented provenance; missing declaration text or
payload refuses. Discovery names `declaration_default_value_keys` and
`declaration_default_optional_keys`; payload/type recurse through the existing
schemas. The [declaration regression](../../../t/2137-composition-child-declaration-evidence.t)
checks real RTL/FSM/DT sources, cache separation and missing-evidence controls.
Prepared VHDL symbolic actuals now forward canonical natural-valued expressions
to child generics whose matched scalar declaration has a bounded plain decimal
default. Canonical default text, payload and type must agree; absent evidence,
sized bit/vector defaults and aggregate symbolic declarations refuse. Actual
validation caches never supply emitted values. For example, `COUNT => TOTAL`
retains the selected top generic independently of its default. Static literal
and aggregate mappings keep their existing path and formatting. Child generic
names must be non-reserved VHDL basic identifiers and unique without regard
to case; `COUNT` and `count` cannot appear in the same generic map.
The [emission fixture](../../../t/data/composition-vhdl-scalar-emission.fsm) and
[focused test](../../../t/2138-composition-vhdl-scalar-emission.t) exercise actual
RTL/FSM/DT declaration producers and connected prepared Plan/IR products.
Discovery's `prepared_vhdl_scalar_emission` advertises `top_defaults` and
`natural_to_integer_child_actuals` and `symbolic_port_widths`, with false
`source_admission`. Source queries beyond the fixed-interface RTL subset still
refuse; these focused checks do not qualify external VHDL compilation or runtime.

Captured scalar port widths now render descending VHDL vector ranges. For
example, `(input data (width (param COPY)))` retains
`data : in std_logic_vector((COPY - 1) downto 0)` even when `COPY` defaults
to one. Signed ports use `signed` with the same range; state flags retain the
existing VHDL representation. The emitter validates the captured top scope and
exact ordered parameter/static lookups, retains selected parameter names, and
folds static subexpressions from their captured integer payloads. Numeric port
width caches never supply the range. Arithmetic `+`, `-`, `*`, `/`, `%` retains
left-associated parentheses, with `%` rendered as `mod`; each default fold
must fit the portable natural integer range and final width must be positive.
Declared-type conflicts, bitwise operators, malformed/cyclic expressions,
foreign scopes, missing/extra/wrong lookups and invalid default arithmetic
refuse. Ordinary static scalar/vector declarations keep their existing text.
The [VHDL range fixture](../../../t/data/composition-vhdl-port-ranges.fsm) and
[focused test](../../../t/2139-composition-vhdl-port-ranges.t) exercise actual
parsed/imported Plan/IR products, complete expected HDL and hostile controls.
Run `scripts/run_with_ram_guard.sh -- prove -Iperl t/2139-composition-vhdl-port-ranges.t`
for this prepared-emitter check. Mutable-interface source admission, internal
net width propagation, external override legality and full compiler/runtime
qualification remain separately owned.

## Top Root Shape

A composition source uses one `?top:name` root with an
HDL-identifier-compatible top name.

The current active top-root body can contain:

- zero or more declaration sections such as `+constants`, `+enums`, bounded
  `+types`, and bounded `+import`
- zero or one `?ports` block
- one or more child instances
- zero or more explicit `?wiring` wiring blocks
- embedded generated child roots, embedded `?pkg` package roots, or embedded
  `?rtlif` metadata roots as companion source material

Malformed top names, duplicate child declarations, duplicate top ports, several
`?ports` blocks, empty child lists, malformed child entries, malformed port
tokens, and malformed wiring tokens are rejected at the composition boundary
rather than being left for HDL emission.

Duplicate names are rejected before scheduling or wiring inference starts. A
top port name may appear only once in `?ports`, and each realized child
instance name must be unique within the `?top`. Child instance labels must also
be portable non-keywords across the shipped HDL targets: SystemVerilog lookup
is case-sensitive and VHDL-2008 lookup is case-insensitive. For example,
`?fsmc:interconnect` and `?rtl:process` fail during composition parsing instead
of reaching a backend as invalid HDL. See
[Portable Instance Identifiers](13f-composition.md#portable-instance-identifiers)
for authored diagnostics and generated-name allocation.

## The Minimal Shape

```text
(?top:top_name
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
)
```

In the narrowest `C1` lane, one child may be enough for the top interface to be
inferred directly when `?ports` is omitted or empty.

Outside inferable single-child lanes, the top boundary must have exactly one
explicit `?ports` block and that block must declare at least one top port.

## Ports

Top ports live in one `?ports` block.

Common forms:

- `clk`
- `reset`
- `rst_n`
- `data_in<8`
- `data_out>8`
- `=status>`

Plain direction tokens are:

- no suffix: one-bit input by default, often used for shared system inputs such
  as `clk` and `rst_n`
- `<` or `<N`: input, optionally with width
- `>` or `>N`: output, optionally with width
- named type or scalar width tokens such as `payload<frame_t` or
  `payload<BYTE_W`

The plain forms are ordinary explicit ports.

Legacy mapping directives such as `/foo/bar/` do not belong inside `?ports`.
Use `?wiring` for explicit connectivity; `?ports` is only for top-port
declarations.

Historical inputs such as `fsm/trial_2.fsm` also used legacy mapping forms like
`/data_o/{tasu_timestamp, tasu_pl_data}/` inside named `?ports` blocks. Those
remain an expected-failure boundary, not an active composition feature.

For readability, `?ports` also accepts verbose declarations. These are aliases
of the compact tokens, not a separate port kind:

```lisp
(?ports:public_io
  (input clk)
  (input rst_n)
  (input data_in (width 8))
  (output result_data (width 8))
)
```

That is equivalent to:

```lisp
(?ports:public_io
  clk
  rst_n
  data_in<8
  result_data>8
)
```

The `(width TOKEN)` attribute accepts the same width tokens as the compact
suffix: positive integer widths, same-scope scalar width symbols, same-scope
type aliases, or direct imported type aliases.

When `TOKEN` names a type, the word `width` is syntax, not a claim that width
and type are the same semantic thing. For example:

```lisp
(?ports:public_io
  packed_out>frame_t
)
```

is equivalent to:

```lisp
(?ports:public_io
  (output packed_out (width frame_t))
)
```

Both forms resolve `frame_t`, use its packed bit width for sizing, and preserve
its declared type contract on the port. The packed width is only the bit count.

Verbose declarations must start with `input` or `output`. Compact tokens must
use HDL-identifier-compatible names and positive widths. FSMGen rejects nested
or wrapper forms in `?ports`, malformed names such as `bad-name>8`, and
non-positive widths such as `data_in<0` at the composition parser boundary.

The declared type contract may also carry signedness, two-state/four-state
intent, aggregate shape, member layout, and type identity. Two ports can
therefore have the same packed width while still being incompatible because
their preserved declared type contracts differ.

The compact `=name` forms and verbose `:same-name` forms are declared
same-name connect-by-name ports:

```lisp
=status>              ;; same as (output status :same-name)
=enable<              ;; same as (input enable :same-name)
=enable               ;; same as (input enable :same-name)
(output status :same-name)
(input enable :same-name)
```

Nullary verbose attributes may be written either as `(attribute)` or
`:attribute`. The canonical concise spelling for declared same-name binding is
`:same-name`; `(same-name)`, `:connect-by-name`, and `(connect-by-name)` are
accepted aliases.

Declared same-name ports mean:

- “this top port must bind by the same name”
- not “infer whatever seems convenient”

Practical rules for declared same-name ports:

- do not use `=clk`, `=rst_n`, or similar system ports; those already use the
  shared system-input contract
- a top-output match is valid only when exactly one compatible child output has
  the same name
- a top-input match is valid when one or more compatible child inputs have the
  same name
- compatibility requires direction, width, and preserved declared type contract
  to agree
- use explicit `?wiring` when you need renaming, remapping, or non-system
  child-to-child wiring

FSMGen rejects declared same-name markers on shared system ports such as
`=clk` or `=rst_n`. Clock and reset ports use the dedicated shared system-input
contract instead of the general connect-by-name path.

## Inference-First Top Boundaries

The preferred authoring model is:

- omit `?ports` when the top boundary can be inferred honestly,
- add `?ports` when you want to disambiguate, rename, constrain, or freeze the
  public interface,
- and fail explicitly when several different public boundaries would all be
  plausible.

In other words, `?ports` is best treated as an interface-control surface, not
as mandatory boilerplate.

That means `?ports` is especially useful for:

- disambiguating multi-child boundaries,
- forcing a stable published interface,
- renaming ports at the top boundary,
- attaching explicit width/type intent when inference is underconstrained,
- and using declared same-name forms like `=status>`, `=enable<`, or
  `(output status :same-name)`.

This is also why the current composition inference work keeps adding more
safe omitted-`?ports` paths: the long-term goal is that authoring a clean
composition should feel lightweight, while still refusing to guess when the
boundary is ambiguous.

## Single-Child Passthrough

Generated-child example:

```lisp
(?top:single_child_top
  (?fsmc:child child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (output_data 8)
  )
  (idle
    (output_data> <= 8'1)
  )
)
```

This works because the top can honestly expose the realized child interface.

When a C1 source authors an explicit `?ports` block, that block must expose
the realized child interface accurately. FSMGen rejects the top before HDL
emission if a child data port is missing from `?ports`, if `?ports` declares a
data port the child does not have, or if an explicitly exposed port disagrees
with the child port's direction or width.

Generated child source roots can be embedded in the same file or resolved from
external `.fsm` sources. Resolution searches repeated `--path DIR` roots, then
`FSMLIB`, then the local directory context. Strict mode requires canonical
`?fsm:name` roots for `?fsmc` children and canonical `?dt:name` roots for
`?dtc` children.

Every child entry must be a proper list whose first item is a real child header
string. Empty child entries, non-string child headers, and dotted-pair child
payloads such as `(?fsmc:child . foo)`, `(?wiring:wiring . foo)`, `(?ports .
foo)`, `(?dtc:child . foo)`, or `(?rtl:uart_tx . foo)` are rejected before
the parser tries to interpret the child kind.

The child form and resolved source root must agree before HDL generation starts.
A `?fsmc` child whose external file is rooted at `?dt:name` is rejected as a
wrong-kind FSM child source and tells the author to use `?dtc` instead. A
`?dtc` child whose external file is rooted at `?fsm:name` is rejected as a
wrong-kind standalone-DT child source and tells the author to use `?fsmc`
instead.

Each `?fsmc` or `?dtc` instance must provide exactly one flat source name. The
only supported nested semantic block on those instances is `(params (NAME
value) ...)`. Other nested blocks, including target-HDL-looking payloads, are
rejected before source realization because generated-child declarations are
structural composition intent, not raw backend text.

Generated children can also be parameterized semantically. Declare the
supported names in the child source with `(+params ...)`, then override those
names on the `?fsmc` or `?dtc` instance:

```lisp
(?top:parameterized_child_top
  (+constants
    (TOP_WIDTH 16)
    (TOP_LANES (8'hA5 8'h3C))
  )
  (?ports:public_io
    clk
    reset
    data_in<16
    data_out>16
  )
  (?fsmc:child child_ctrl_src
    (params
      (WIDTH TOP_WIDTH)
      (LANES TOP_LANES)
    )
  )
)

(?fsm:child_ctrl_src
  (+params
    (WIDTH 8)
    (LANES (8'h00 8'h00))
  )
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (data_in 16)
    (data_out 16)
  )
  (idle
    (data_out> = LANES <data_in=WIDTH)
  )
)
```

Scalar overrides are intentionally width-flexible at the intent layer.

Aggregate overrides must match the list/record shape inferred from the child
parameter default before HDL is emitted.

## Explicit Child-To-Child Wiring

Once you have multiple children, the normal tool is `?wiring`.

```text
(?top:two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.final_data result_data)
  )
)
```

Each list item is one directed link: `(source target)`.

The verbose spelling `(connect source target)` is equivalent and can improve
readability in dense wiring blocks. The older `/source/target/` token remains
accepted as compatibility input, but new examples and generated artifacts use
the list form. In strict mode, `/source/target/` is rejected with a migration
hint because the strict composition surface is the canonical `(source target)`
or `(connect source target)` list form.

List-form wiring entries must be real directed links; a list wrapper around an
old slash token such as `(group /child.out/top_out/)` is rejected instead of
being guessed. Bare arrow-like tokens such as `child.out->top_out` are also
rejected; use `(child.out top_out)`, `(connect child.out top_out)`, or the
legacy `/child.out/top_out/` compatibility token.

Member/item endpoints such as `producer.output_data.extra` require the base
endpoint to carry a declared aggregate type. If the child port is only a scalar
or untyped vector, FSMGen rejects the link and asks for an aggregate `+types`
alias before member or item access is used in composition wiring.

When a generated child FSM omits `+system`, it still has the same direct-root
implicit system defaults as a standalone FSM: `clk` and async active-low
`rst_n`. In a composition top, those implicit child system ports participate in
the shared system-input auto-wiring contract. If the top exposes `clk` and
`rst_n`, generated child instances bind `.clk(clk)` and `.rst_n(rst_n)`
without explicit `?wiring` entries for those system ports; ordinary data links
still belong in `?wiring`.

If a multi-child composition topology needs explicit data routing and no
`?wiring` block is present, FSMGen rejects it after typed composition parsing
and before HDL emission. The scheduler does not guess which child output should
feed a top output or another child input.

Generated standalone-DT children use the same shared system-input convention.
When a `?dtc` child source has explicit `+system` metadata such as
`(clock clk)` and `(areset rst_n)`, those system ports are part of the child
interface and the top binds them by name. A single `?dtc` child can therefore
emit a top instance with `.clk(clk)` and `.rst_n(rst_n)` while data ports such
as `data_in` and `result_data` stay ordinary top/child connections.

## Reusable Standalone-DT Modules

A standalone-DT root is a reusable module-shaped source rooted at `?dt:name`.
The legacy aliases `?mod:name` and `?module:name` are accepted in compatibility
mode, but strict child-source checks require canonical `?dt:name` for `?dtc`
children.

Standalone-DT roots are built from one or more general DT blocks such as
`(-from_a ...)` and `(-from_b ...)`.

Example:

```lisp
(?dt:route_src
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (out> = a)
    )
  )
  (-from_b
    (<sel==1'b1
      (out> = b)
    )
  )
)
```

Direct `?dt:name` generation reports the reusable-DT structure in
`module_info`:

- `standalone_dt_count`
- `standalone_dt_names`
- `standalone_dt_enable_families`
- `standalone_dt_module_enable_family`
- `standalone_dt_multi_drive_target_count`
- `standalone_dt_multi_drive_targets`

The enable-family metadata names each block-level enable signal and the
module-level group of block enables. For the example above, the block enables
are `from_a_en` and `from_b_en`.

When several standalone-DT blocks drive the same target, FSMGen reports one
grouped multi-drive target family. That family records the target signal,
mux/storage class, contributing DT block names, RHS values, per-DT enable
signals, grouped LHS enable signals, and one bounded assertion metadata object.

SystemVerilog output emits verification-only onehot0 guard assertions for
those grouped standalone-DT multi-drive targets under `` `ifndef SYNTHESIS``.
Verilog output keeps the metadata but does not emit SystemVerilog assertion
syntax.

The same metadata survives `?dtc` realization. A composition top that
instantiates standalone-DT children aggregates those exports through:

- `composition_standalone_dt_child_count`
- `composition_standalone_dt_block_count`
- `composition_standalone_dt_multi_drive_target_count`
- `composition_standalone_dt_children`

Those child exports also live in the top-level `intent_hir`, and they carry
each realized child's forward `intent_hir`, `lowered_rtl_ir`, and structural
interface boundary where those layers exist.

Example:

```text
(?top:dtc_top
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_src)
  (?dtc:router_b route_src)
  (?wiring:wiring
    (sel router_a.sel)
    (data_a router_a.a)
    (data_b router_a.b)
    (router_a.out router_b.a)
    (router_b.out final_out)
  )
)
```

Named `?dtc:name` children may omit the source token and default it to the
instance name. For external files, source lookup follows the same generated
child order: repeated `--path DIR` roots, then `FSMLIB`, then the local source
directory context.

Current boundary: standalone-DT modules do not yet have an authored
enable-control syntax that overrides the implicit block enable, unnamed
`?dt:` roots are not a public contract, and broader reusable-module package or
lookup semantics remain future work.

## Same-Name Convention

There are now several bounded same-name paths:

- single-child top-interface passthrough when `?ports` is omitted or empty
- explicit-link top-port inference when `?wiring` endpoints define the public
  boundary exactly
- undeclared top-input inference when compatible child inputs remain top-facing
- undeclared top-output inference when one unique child output remains top-facing
- plain explicit top ports reusing the same-name convention in explicit-link
  `C2` / `C3` tops
- declared compact `=name` or verbose `:same-name` connect-by-name
- same-name internal carrier inference for one producer and one or more sinks
- explicit top-output re-export of a compatible inferred internal carrier

Simple example:

```text
(?top:single_by_name_top
  (?ports:public_io
    clk
    rst_n
    =enable<
    =output_data>8
  )
  (?fsmc:child child_src)
)
```

This is useful when the top boundary is intentionally the same as the child
boundary.

The shipped rule is direction-asymmetric:

- a same-name top input may fan out to one or more child inputs when every
  child-side candidate is an input and the width/type/declared-type contract
  matches
- a same-name top output must match exactly one child output
- mixed-direction families fail instead of being guessed
- width-equal but declared-type-incompatible families fail instead of being
  flattened to raw vectors

The convention is also local. Explicit `?wiring` owns the exact endpoints it
mentions and overrides same-name convention at those endpoints. The
composition report records those overrides and the common blocked cases, such
as explicit child links preventing undeclared top-interface inference or an
inferred internal carrier staying internal by default.

For a whole top input routed by `?wiring`, explicit ownership is resolved
before validating same-name candidates. The following complete composition
passes strict source checking even though `noise.ready` is an output with a
different width from the input `worker.ready`:

```lisp
(?top:explicit_ready
  (?ports:public_io ready result> observed>8)
  (?rtl:worker worker_if)
  (?rtl:noise noise_if)
  (?wiring:routes
    (ready worker.ready)
    (worker.done result)
    (noise.ready observed)))
(?rtlif:worker_if ready<:data done>:data)
(?rtlif:noise_if ready>8:data)
```

The top input drives only `worker.ready`; `noise.ready` drives `observed`.
Normal external RTL implementations supply these declared interfaces. Each
explicit link still requires valid source/target directions, exact widths,
compatible declared types and a single driver per target. Removing the
explicit input route restores the mixed-family refusal. Routing a child
endpoint alone does not claim an otherwise unrouted top input.

The same rule allows an ISF activation actor to use a public input named
`ready` even when generated CDC children also have `ready` outputs. The
compiler's explicit route binds the authored input to its owning domain;
independent HDL tests use an explicit transaction entry, hold that input low,
release it, and repeat activations around reset. A body-first `await` in an
externally activated worker has a separately tracked watchdog initialization
defect; see the [current lowering limits](13h-lowering-reference.md).
Native check/semantic reports and the MCP adapter retain the
same complete success or failure result.

What this does not mean:

- no broad hidden child-to-child auto-wiring
- no interface-bundle or protocol-group inference
- no priority, merge, or arbitration semantics for same-name conflicts
- no automatic publication of internal carriers as top outputs
- no backend-specific remapping syntax hidden behind `=name`

When the boundary is not obvious, write the link explicitly in `?wiring` or
declare the top port explicitly in `?ports`.

## External RTL Children

External RTL is declared with `?rtl` and described by `.rtlif` metadata.

```text
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    (producer.output_data uart_tx.data_in)
    (uart_tx.txd serial_out)
  )
)
```

With metadata:

```lisp
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
```

The same metadata can be written with verbose port declarations:

```lisp
(?rtlif:uart_tx
  (input clk :clock)
  (input rst_n :reset)
  (input data_in (width 8) :data)
  (output txd :data)
)
```

External RTL metadata can be sidecar `<module>.rtlif` or an embedded
`(?rtlif:module ...)` companion root. Embedded metadata for the requested
module takes precedence over sidecar metadata. Metadata roots are flat port
contracts plus an optional semantic `(params (NAME default_value) ...)` block.
This is the canonical low-level external-RTL interface metadata contract in
the current toolchain. FSMGen does not currently define a separate higher-level
interface-source language above `.rtlif`; future interface abstractions should
be added only when a concrete type, package, shared-datapath, or reusable-module
need cannot be represented honestly by this metadata layer.

Port categories are currently `data`, `clock`, and `reset`; typed clock/reset
ports are system-input roles and output-direction clock/reset tokens are
rejected.

Those category markers are interface roles, not separate HDL data types.

`:clock` marks a clock input that participates in composition's system-clock
auto-wiring, `:reset` marks a reset input that participates in system-reset
auto-wiring, and `:data` marks an ordinary payload/status/control port. The
compact `core_clk:clock` spelling is equivalent to `(input core_clk :clock)`;
`data_in<8:data` is equivalent to `(input data_in (width 8) :data)`; and
`txd>:data` is equivalent to `(output txd :data)`. As with other nullary
verbose attributes, `(clock)`, `(reset)`, and `(data)` are accepted aliases for
`:clock`, `:reset`, and `:data`.

If you need two instances of the same external RTL module, keep one interface
contract and give each `?rtl` child its own instance name:

```lisp
(?top:dual_uart_top
  (?ports:public_io
    clk
    rst_n
    data_a<8
    data_b<8
    tx_a>
    tx_b>
  )
  (?rtl:u_uart_a uart_tx)
  (?rtl:u_uart_b uart_tx)
  (?wiring:wiring
    (data_a u_uart_a.data_in)
    (u_uart_a.txd tx_a)
    (data_b u_uart_b.data_in)
    (u_uart_b.txd tx_b)
  )
)

(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)
```

Here `uart_tx` is the reused RTL module/interface contract, while `u_uart_a`
and `u_uart_b` are the actual child instance names used in links and emitted
HDL.

Each `?rtl` instance must use either the shorthand `(?rtl:module_name)`, the
explicit alias `(?rtl:instance_name module_name)`, or the semantic nested form
`(?rtl:instance_name (module module_name) (params ...))`. Extra flat module
names and unsupported nested blocks are rejected before `.rtlif` metadata is
loaded, because `?rtl` declarations describe an external module contract rather
than raw backend text.

Historical inputs such as `fsm/lte_digital_rf.fsm` used one `?rtl` child to
carry many flat module references. For example, its `?rtl:lte_dif_iosocket`
child currently fails as an expected-failure corpus entry because it names 36
RTL modules in one child declaration. Keep each external RTL child to one
semantic module contract instead.

If an external RTL module is parameterized, keep that contract semantic too:
declare supported parameter/generic names in an optional `.rtlif`
`(params (NAME default_value) ...)` block, then override declared names on the
specific `?rtl` instance. Values may be scalar integer literals, bounded
literal list/record payloads, or resolved composition-top/imported-package
symbols such as `WIDTH_VALUE`, `mode.BUSY`, or `shared.LANES`; `.rtlif`
defaults may also use package-qualified imported symbols such as
`shared.DEFAULT_LANES`. Aggregate overrides are checked against the aggregate
shape inferred from the `.rtlif` default before HDL is emitted. The advanced
composition chapter shows the full pattern.

## Current Boundary

Composition is no longer single-child-only. The shipped live lanes already
cover:

- `C1` single-child passthrough and interface inference
- `C2` explicit-link composition with generated children
- `C3` explicit-link composition with at least one external RTL child
- `C4` declared connect-by-name through compact `=name` or verbose
  `:same-name`
- `C5` diagnostics for duplicate drivers, width mismatches, ambiguous or
  missing connect-by-name matches, unknown endpoints, malformed child/source
  metadata, and blocked inference
- `C6` scoped rejection of older out-of-support composition/template forms

The normative composition boundary now lives in these composition chapters. The
focused [COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) document remains a
maintainer-side scope map while the book continues absorbing the old guide's
user-facing detail.

For expressions, structural actuals, concat/repeat sources, inferred carriers,
and type-aware link validation, continue with
[Composition Advanced](06-composition-advanced.md).
