# Symbols, Types, and Imports

This chapter covers the declarative surfaces that let you name things instead
of repeating raw numerics everywhere.

The current canonical intent-level families are:

- `+constants`
- `+enums`
- `+types`
- `+import`

Compatibility families such as `+define` and `+params` still exist in the live
tree, but they are not the long-term center of gravity for the language.

## Declaration Shape Contract

These declaration sections are parsed as semantic source forms, not as loose
lists for the backend to guess later. Malformed section shapes fail explicitly.

Current accepted families are:

- `(+size (signal width_or_type) ...)`
- `(+constants (NAME value) ...)`
- `(+define (NAME scalar_value))`
- `(+params (NAME value) ...)`
- `(+enums (enum_name (MEMBER value) ...) ...)`
- `(+types (type NAME type_spec) ...)`
- `(+import package_name ...)`

Important boundary rules:

- `+size` entries require one signal name plus one positive width expression or
  named type.
- The legacy empty `(+size)` no-op remains default-mode compatibility residue;
  strict mode rejects it.
- `+constants`, `+params`, `+enums`, `+types`, and `+import` require non-empty
  payloads.
- `+define` carries exactly one `(NAME value)` pair in the current active
  contract.
- `+import` is a flat list of HDL-identifier-compatible package names.
- Whole aggregate roots are not scalar width expressions. Use a scalar leaf
  such as `LANES[1]`, or a named aggregate type alias when the target is typed
  aggregate storage.
- Dependency cycles in constants, params, and types are rejected before HDL
  emission.

Those constraints are part of the public language boundary. They keep invalid
declarations from falling through to Perl list-unpacking errors, raw backend
warnings, or accidental target-HDL behavior.

## Parameters

Use `+params` for direct-root parameter values when the source is describing a
configuration knob rather than a general shared constant. The direct-root
surface now uses the same bounded parameter/generic value normalization policy
as external RTL interface metadata.

```lisp
(+params
  (WIDTH 0x10)
  (RESET_VALUE 8'hA5)
  (LANES (8'hA5 8'h3C))
  (RESET_PARAM RESET_BYTE)
  (MODE_PARAM mode.BUSY)
  (LANE_PARAM LANES)
  (WIDTH_ALIAS WIDTH)
)
```

Scalar values may use decimal, sized SystemVerilog-style literals, unsized
SystemVerilog-style based literals, `0x` / `0b` / `0o` prefixes, or FSMGen
intent-level sized literals such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`,
and `20'x1`. Bounded literal list/record payloads are also accepted when they
can lower to one packed literal. That keeps the authoring surface convenient
while preserving a concrete semantic value before generation.

The Core module retains authored defaults separately from those normalized
values. For example, `(BOUND W)` with `W=16` retains the expression `W` and its
selected parameter reference, while `(BOUND 16)` retains a literal with no
parameter reference. Both still have the same normalized default value.
`FSMModule::parameter_default_sources()` exposes detached source records for
compiler consumers; `parameters()` keeps its existing normalized shape.
Forward references, aggregate member/index paths and arithmetic retain their
direct parameter references through the existing resolver. Constants and enum
members keep their source expression but are not listed as parameter references.

The direct-root parser now uses the reusable
`FSM::ParameterDeclarationSupport` declaration graph with the existing canonical
value evaluator. It keeps declaration and registration order even when a default
refers forward. Callbacks receive detached values and source records. Literal,
alias, cyclic and unknown-name parameter resolutions release their parser context
after the caller releases it; this is a scoped lifetime guarantee, not a claim
about every symbol resolver. Composition tops share this graph after imports;
the bounded fixed-interface RTL source profile is described in Composition Basics.
Generated and mutable-interface composition profiles remain pending.

Compiler consumers can also request `capture_expression` from
`FSM::ParameterValueSupport::canonical_value`. Its optional `value_expression`
records literal and successfully resolved symbol tokens, operators with their
authored aliases, ordered lists and maps. Existing semantic payload inputs stay
explicit payload nodes. The ordinary result shape, values and resolver order
stay unchanged when capture is disabled. This source tree prepares scoped
binding; it does not itself supply top generics or symbolic HDL emission.

`FSM::ParameterBindingSupport` shares the canonical binding walk between
explicit direct-module and composition-top scopes. It preserves observed
parameter roots and paths, nested operators and immutable selected static
payloads. The composition wrapper still requires its original top scope and
static-symbol object.

The direct parser now captures complete canonical bindings through this helper.
`FSMModule::parameter_default_bindings()` returns detached compiler records in
the original source scope, including selected static constants, enum members
and imported aggregate leaves. A copied physical module keeps that captured
scope. Declaration replacement invalidates the entire derived binding map;
failed nonempty resolution retries expose no stale or partial binding snapshot.
Normalized parameter values and the existing authored-source records retain
their previous shapes and JSON kinds. Private bindings add no public report
fields. Direct headers consume the supported scalar relationships described below.

Captured declaration/source/binding membership is validated through one shared
source-environment helper. Target name reservation remains a backend policy at
its original validation boundary; source ownership stays lexical. The ordinary
direct symbol resolver now also exposes a detached observation of the branch it
actually selected: static symbol or immediate parameter root/path. The existing
payload API keeps its precedence and values. This observation alone does not publish bindings; the capture and direct-port
consumers below now use it without changing ordinary resolver precedence.

`WidthExpressionSupport` now has a private opt-in capture method that follows
the existing prefix and infix evaluator walk. It retains structured literals,
operators, selected payload expressions and complete ordered actual lookups.
Repeated references remain separate; namespace identity comes from the
resolver's observation, and captured records stay detached. Ordinary width
evaluation keeps its existing interface and callbacks. The direct parser now
provides private `capture_declared_width_contract` with an explicit
`{kind => 'direct_module', owner => 'source_name'}` scope. Selected constants
and general expressions add detached `width_capture` records containing scope,
resolved width, structured binding and ordered actual lookup observations.
Literal and named-type branches retain their existing fixed/type contracts.
The constant fast path consumes its actual exact decimal observation without
replaying general lookup, evaluation or target formatting. Expression capture
uses the canonical walk and declared-only parameter selector. Ordinary parser
calls, source getters and numeric values stay unchanged. Successful full source
parsing now publishes eligible private primary and auxiliary bindings from the
recorded actual requirements. Symbolic HDL activation remains pending.

Core Signals now provide private `declared_width_binding` storage for explicitly
supplied compiler records. The envelope adds the actual declaration signal and
expression to the captured scope, width, binding tree and observations. Input
and getter copies are plain and detached. The getter exposes a binding only
when its declaration source, effective width and absence of declared type agree;
a physical copy can retain a different original declaration name. Failed
replacement clears the old record. Registry width refinement or explicit source/
type replacement invalidates the binding while preserving existing numeric and
source getters. Ordinary inference with unchanged width and absent type keeps
it. Canonical graph proof remains the producer and target preparer's job.

Normal parsing resolves declarative environments before sizing, captures during
the actual sizing walk, and stages the real Signal/record associations until the
complete module validates. The lexical owner comes from the original decoded
source header and survives later physical renaming. Bindings reach the same
objects held by assignment targets, including targets absent from the module's
signal map. A parser or later facade-analysis failure clears the records;
nonempty environment replacement and failed direct sizing retries invalidate
old snapshots while legacy empty no-ops retain them. Ordinary direct sizing
without an active source context still supplies no inferred scope. Public reports
and numeric HDL remain unchanged by this private publication.

The auxiliary-origin audit found a separate preservation gap. When a generated
`next_data` or `data_r` output also has an explicit size declaration, legacy
numeric refinement retains both size requirements, while its old source getter
is replaced by the parent's origin. An independent parameter and an equal-valued
literal can therefore leave identical selected source records. Copying the
parent's binding alone would lose the explicit constraint. The parser now
preserves those separate private requirements before the legacy overwrite;
existing numeric behavior is unchanged.

The private Core `declared_width_requirements` holder now stores separate
declaration and generated requirements under the original lexical scope. Each
snapshot retains its origin, authored expression, observed width, named-type
information and optional canonical capture. Literal, named-type and inferred
generated contributions remain distinct. The envelope must account for the
observed effective width; it does not supply a combined symbolic expression.
Inputs and getter results are detached. Failed replacement clears the old
record, and width/source/type replacement or failed source transactions clear
the metadata. The getter withholds records after private installation-state
divergence. Ordinary constructors acquire no inferred records.

Actual scoped size declarations now retain literal, type and captured-expression
snapshots. Generated copies freeze the source requirements at the copy event,
using the actual Signal objects. A later source replacement cannot rebind an
earlier copy. Mutation versions revoke pending records even if later fields
match their former values. Only current records publish after complete source
validation; parser/facade failure and environment replacement clear them. Earlier
contributions to the legacy maximum remain separate; only identical complete
snapshots are deduplicated. Unrecorded contributions explicitly lack an authored
expression and cannot supply an inferred parameter relationship.

For example, this source retains the independent `X` requirement alongside the
generated `W` requirement on `next_data`, while keeping its existing numeric HDL:

```lisp
(?fsm:aux_origin
 (+params (W 8) (X 16))
 (+size (data (param W)) (next_data (param X)))
 (idle (<-= (data 0))))
```

The same retention applies to `data_r` produced by `<=-` or `<=+`, including an
auxiliary declared before its parent is sized. This closes the private retention
defect. Combined symbolic shape rendering remains separately qualified; the
requirements do not fabricate a single parent binding. Ordinary unscoped late
sizing still supplies no guessed lexical scope.

Primary declarations and auxiliary copies now publish `declared_width_binding`
when all current requirements share one complete original capture and the
actual legacy source, width and type state agree. A combined set requires every
generated edge to retain its immediate copy attestation. Clean copies and copy
chains retain the original declaration signal and lexical owner, including a
parameter defaulting to a single bit. Static observations remain static; named
types and unrecorded inference acquire no borrowed parameter relationship.
Independent auxiliary constraints and repeated independent primary declarations
remain separate, even with equal defaults, and do not publish a single binding.
Fresh source retries capture the current lexical declarations rather than
importing prior parses' origins. A larger inherited numeric floor stays opaque
and withholds a single binding. Explicit scoped late sizing and symbolic ranges
remain subsequent compiler work; combined-shape rendering remains separately
qualified.

The scoped late-sizing contract audit also exercises overlapping auxiliary names:
`next_data_r` can be the next output of `data_r` and the registered output of
`next_data`. Current source retention keeps both real contributions. Starting a
fresh sizing context would lose existing declarations; clearing every generated
requirement would lose an independent copy path. Preserving all records is safe,
but earlier opaque inference can then withhold a clean late binding. The next
private records now carry optional `copy_origin`, the immediate actual registry
source, separately from the original declaration. Capture requires the identical
source object in that registry association; a same-name object cannot attest it.
Chains update this immediate edge while retaining original expression/capture
identity. Older records without the field, or with a null field, remain
unattested. Ordinary declarations and unexplained numeric floors invent no
copy origin. Distinct actual edges stay separate even if their original captured
expressions are identical. Complete original signal/expression/capture equality
now allows one effective binding while preserving both edge records. Independent
same-default parameters, different original declarations, opaque/literal/type
requirements and unattested combined edges still withhold that binding.
The [focused regression](../../../t/2185-equivalent-width-copy-bindings.t) proves
actual parser records and prepared SystemVerilog/Verilog/VHDL ranges at defaults
one and eight. Its overlapping-copy source also uses independently unsupported
mixed assignment styles: prepared ranges do not qualify whole-source HDL.
Backend-only allocation, computed shapes and override/runtime proof remain open.
Scoped updates preserve authored and other-origin
requirements, replacing only earlier opaque inference attested to the same
immediate source. Replay the earlier diagnostic policy contract with:

```bash
python3 -B docs/audits/scoped-late-width-contract-20261027.py --self-test
```

The private parser entrypoint `parse_size_section_in_scope(size_ast, scope)` now
supports explicit late sizing. The scope must name the original direct source
header; a physical module name never supplies ownership. For example:

```perl
use lib 'perl';
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::DeclaredWidthBindingSupport;
use FSM::DeclaredWidthRangeSupport;
use FSM::DirectDeclaredWidthSupport;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::ParameterDefaultEnvironmentSupport;
my $source = '(?fsm:late_case (+params (W 8)) (idle (<-= (data 0))))';
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
$adapter->parse_fsm(scalar Lispish::multi(\$source));
$adapter->{parser}->parse_size_section_in_scope(
    ['+size', [['data', ['param', ['W']]]]],
    {kind => 'direct_module', owner => 'late_case'});
my $module = $adapter->{parser}->get_fsm_module;
my $environment = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
    parameters => $module->parameters, sources => $module->parameter_default_sources,
    bindings => $module->parameter_default_bindings);
my $proof = FSM::DeclaredWidthBindingSupport->prove_signal(
    signal => $adapter->{signal_manager}->get_signal('next_data'),
    environment => $environment);
my $range_plan = FSM::DeclaredWidthRangeSupport->prepare_signal(
    signal => $adapter->{signal_manager}->get_signal('next_data'),
    environment => $environment, target_language => 'vhdl');
# $range_plan->{range_text} is '((W - 1) downto 0)'.
my $backend = FSM::HDL::FlattenedDT->new(debug => 0);
my $declaration_capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
{
    local $backend->{declared_width_declaration_capture} = $declaration_capture;
    $backend->generate_systemverilog($module);
}
my $module_width_plan = FSM::DirectDeclaredWidthSupport->prepare_module(
    fsm_module => $module, assignment_analysis => $backend->{assignment_analysis},
    target_language => 'vhdl');
my $target_width_plan = FSM::DirectDeclaredWidthSupport->prepare_declarations(
    fsm_module => $module, assignment_analysis => $backend->{assignment_analysis},
    target_language => 'systemverilog', %{$declaration_capture->snapshot});
```

Scope preflight refuses malformed or incompatible records before mutation.
Accepted transactions stage current compatible records, perform real sizing,
and publish only after complete success. A sizing or publication failure clears
all derived records while retaining the existing numeric/source failure prefix.
Nested calls in a same-scope source transaction defer publication to outer source
validation. Scalar/list/void return contexts and valid no-ops retain their legacy
contracts. Ordinary unscoped calls stay unscoped.

Late sizing preserves independent literal/type/parameter declarations and other
copy paths. Older opaque records without an attested immediate origin stay
conservative; larger unexplained numeric floors remain opaque. The existing
named-type ordering asymmetry is retained: assignment-created auxiliaries omit
the parent's Core type metadata, while legacy late sizing copies it. Their
numeric widths and private type requirements agree in the reproduced case.
Task `ISF-REDUCTION-DELIVERY.24` owns impact analysis and a deliberate consistency
repair before full qualification. Symbolic ranges and combined shapes remain
separate compiler work.

The private Verilog-family `WidthExpressionEmitter` now shares prepared range
rendering between explicit direct-module and composition-top scope. Its existing
composition wrapper retains the top-scope boundary and port diagnostics. The
kernel reuses the canonical width evaluator and shared parameter renderer:
actual names, ordered lookups, static folding and explicit arithmetic folds
retain their meaning, including vector rank at a one-bit default. Numeric width
caches cannot replace a captured range. Unknown scopes, foreign targets,
type conflicts, missing/extra lookups and invalid arithmetic refuse. Caller
records remain detached from returned text. This extraction keeps current
composition output and leaves direct capture-to-plan preparation and direct
range emission as subsequent work.

The parallel private VHDL `WidthExpressionEmitter` now accepts the same explicit
source scopes behind its narrower composition wrapper. It preserves portable
natural bounds at each arithmetic step, positive final width, left-associated
parentheses and modulo spelling as `mod`. Selected roots use the existing VHDL
identifier primitive; complete declaration/namespace preparation remains the
caller's responsibility. Current composition output, refusal messages and caller
graphs preserve. The shared helper adds no direct converter or source admission;
captured-plan preparation and source-aware declaration conversion remain next.

The private `DeclaredWidthBindingSupport::prove_signal` check now validates an
actual coherent Signal capture against an explicit declaration environment. It
re-derives the captured evaluator walk with strict frozen observations: lookup
entrypoint, selected identity, order, nested payload structure, binding and
default width must agree. Selected parameter root/path payloads must also match
the declared environment. It performs no live namespace lookup and never chooses
a relationship from equal numbers. Static selections stay pinned beside
same-named parameters. Returned capture and ordered parameter-reference records
are plain and detached. This proves consistency; producer authorship and full
target declaration legality remain caller responsibilities.

The private `DeclaredWidthRangeSupport::prepare_signal` adapter now turns that
proved binding into a bounded SystemVerilog, Verilog or VHDL range plan. It
retains selected scalar root names and repeated order, inlines pinned static
trees, and delegates arithmetic and target text to the shared width kernels.
Symbolic widths retain vector rank at a default of one. Fully static captures
return a fixed plan with the existing numeric rank and no new range text.
Mutable paths, aggregate or unsupported typed roots, symbol-bearing parameter
payloads and static payloads hiding mutable dependencies refuse explicitly.
VHDL additionally requires portable natural payloads and arithmetic operators,
with bounds checked at each intermediate step. Caller defaults remain unchanged.
The private `DirectDeclaredWidthSupport::prepare_module` collector now joins
actual module Signals with the Signals held by normalized assignment targets.
The module's signal map alone can omit an assigned storage object. Shared
object identity deduplicates; distinct objects claiming one physical name
refuse. Copied module defaults pass their canonical observation proof before
captured ranges are prepared. Original source scope survives a physical module
rename. Fixed/type declarations stay independent, while independent combined mutable
requirements and missing or stale captures refuse before numeric fallback.
The returned module plan is detached from Core and backend objects.
The private `prepare_declarations` entrypoint now joins these source plans to
explicit backend namespace and declaration records. It checks complete mapped
parameter and Signal membership, reserved names, target collisions (including
VHDL case folding), observed widths, signedness and declared types. Selected
width roots retain their names; actual Signal and physical module names can use
the backend's mapping without replacing original source scope. The detached
result identifies port/storage ranges and the independent fixed declarations.
The target input contract is documented in the helper's API reference; it must
come from the actual backend boundary. The opt-in `DeclarationCapture` publisher
now supplies it directly from the existing emitters: actual parameter order,
ports, state declarations, storage, enable/intermediate wires and allocated
aggregate type names. No HDL parsing or second generation pass supplies these
records. Only completed generation exposes a detached snapshot; reset, failure
or incomplete numeric rows withhold prior/partial results. Captured direct
parameter/width preparation now installs this collector for one generation;
legacy uncaptured generation keeps its existing path.

Direct SystemVerilog and compatibility Verilog ports and source-owned internal
storage now consume the proved ranges. Selected names and arithmetic remain,
including an explicit vector when the selected width defaults to one. Fixed
literals, static selections and named types keep independent numeric/type
ranges. Before returning HDL, complete actual target snapshots are qualified
again and compared with the emitted port/storage identities. A same-default source
replacement cannot bless already emitted text. Independent combined mutable requirements,
stale captures, namespace conflicts and symbolic clock/reset widths refuse.

Run the [one-bit input/output fixture](../../../t/data/ial0-direct-symbolic-ports.fsm):

```bash
./bin/fsmgen --quiet --strict --check --json t/data/ial0-direct-symbolic-ports.fsm
./bin/fsmgen --quiet --strict --language systemverilog --output .artifacts/direct_symbolic_ports.sv t/data/ial0-direct-symbolic-ports.fsm
./bin/fsmgen --quiet --strict --language verilog --output .artifacts/direct_symbolic_ports.v t/data/ial0-direct-symbolic-ports.fsm
```

Its port block includes:

```systemverilog
input  wire FIXED,
input  wire [(W - 1):0] INPUT_PORT,
output reg  [(COPY - 1):0] next_DATA
```

The [storage fixture](../../../t/data/ial0-direct-symbolic-storage.fsm) adds an
explicit unused internal and an independently typed signed four-state control.
Run the same commands above with that source and a distinct output path. Its
internal declarations include:

```systemverilog
reg [(COPY - 1):0] DATA;
reg [((W + 1) - 1):0] SPARE;
logic signed [3:0] TYPED;
```

Assignment-target storage is included even when absent from the Core module's
signal map. Explicit internal roles stay internal; fixed/static/type ranges
retain their existing declaration paths. Backend-only helpers acquire no
symbolic range by matching numeric widths.

Port/storage emission has focused checks and native generation evidence.
Computed helper shapes and complete external override/runtime qualification
remain pending. The source-aware VHDL range integration is also
pending: symbolic direct ports currently refuse in that converter before a new
artifact is returned; an existing destination remains unchanged.

The target-plan ownership check exposed an independent backend retention defect:
ordinary numeric generation keeps a context/helper back-reference cycle and its
module after callers leave scope. A control that never invokes the new plan
helper reproduces it. Task `ISF-REDUCTION-DELIVERY.25` owns repair before full
qualification. Detached plan ownership passes in isolation; whole backend
release is not claimed.

The bounded source/Core observations and rejecting saved-record controls can be
replayed without generating new artifacts:

```bash
python3 -B docs/audits/auxiliary-width-origin-contract-20261027.py --self-test
```

The private `prove_binding_observations` check now verifies that recorded
references cover the complete canonical binding tree, retaining immediate
identities and JSON kinds. Missing, conflicting or opaque dependency records
refuse. Private direct VHDL preparation now uses this proof to select related
natural-valued declarations and preserve independent static defaults. Direct
VHDL generation consumes that plan against actual normalized target names,
separately from lexical source ownership. Complete qualification remains pending.

Private generic preparation also accepts paired `assignment_analysis` and
`target_declarations` inputs from the actual backend boundary. It re-proves
captured source widths and complete target declarations against the same
namespace, then joins their selected parameter roots to the default-dependency
subset. A parameter used only by a width can therefore receive a `natural`
declaration in that prepared plan; an equal independent literal stays static.
Incomplete, stale, renamed or inconsistent width inputs refuse. This optional
preparation is covered by the [width-root regression](../../../t/2177-direct-vhdl-width-generic-roots.t);
the source-aware converter now supplies these actual inputs for its bounded symbolic profile.

The private [DirectDeclarationPlan](../../../perl/FSM/Backend/VHDL/DirectDeclarationPlan.pm)
now pairs complete actual emitted declarations with the converter's normalized
identifier map. Canonical source and VHDL width proofs check both namespaces
against the same actual Signals. Each selected row retains its exact source
range spelling, numeric width and signedness beside a separate VHDL range and
vector type. A selected default of one remains a vector; independently fixed
and named-type declarations retain their numeric/type metadata. Width-selected
natural generic preparation uses the same target records. Original lexical
scope stays distinct from normalized physical names. Missing, stale, foreign,
renamed or conflicting inputs refuse, and returned records retain no caller
owners. The [paired-plan regression](../../../t/2178-direct-vhdl-declaration-plan.t)
qualifies this preparation with actual port and storage captures. The private
parser now checks complete normalized declaration membership, port/storage roles,
numeric widths and signedness against that plan. Symbolic ranges must match the
prepared source spelling exactly, including at a selected default of one; an
equivalent expression or numeric substitute refuses. Parsed declarations carry
separate VHDL range/type strings beside their selected numeric behavior bounds.
Static rows preserve the existing parser products. The
[parser regression](../../../t/2179-direct-vhdl-declaration-parser.t) includes
actual generated sources and altered-text controls. The bounded source-aware renderer
now consumes the paired plan; standalone symbolic raw-text conversion and public reports are unchanged.
External override/runtime and full qualification remain separately owned.

Private declaration rendering now consumes that canonical VHDL type. Whole-target
decimal and sized-literal assignments use the target's `'length` instead of its
selected numeric default; sized unsigned literals zero-extend or truncate before
target signedness conversion. This preserves vector rank at a default of one.
The [target-rank regression](../../../t/2180-direct-vhdl-target-rank.t) checks
actual paired declarations and static controls. Selected symbolic literal target
lvalues and X/Z literals refuse. Generated computed shapes remain separately owned.

Private symbolic unsigned comparisons with sized literals now use numeric vector
overloads at the actual operand lengths, in either operand order. Decimal equality
uses numeric scalar overloads without truncating the literal to a selected default.
Comparison-result literals use the actual symbolic target's `'length`. Static
products preserve; negative comparisons retain their existing arithmetic refusal,
and signed symbolic sized comparisons refuse pending qualification. The
[comparison-rank regression](../../../t/2181-direct-vhdl-comparison-rank.t)
checks actual paired declarations and independent expected target text.
External generic override/runtime qualification remains pending.

Private symbolic Boolean conditions now reduce whole vectors through the existing
OR helper, including when the selected default is one. Logical grouping,
negation, conjunction and disjunction preserve precedence; negated vector truth
compares the reduction with zero. The symbolic profile reserves that helper before
the existing collision check. Qualified literal comparisons and reductions reuse
their expression consumers. Selected, bitwise, vector-pair, decimal-relational and
negated-comparison leaves remain withheld. Static condition products preserve.
The [condition-rank regression](../../../t/2182-direct-vhdl-condition-rank.t)
checks actual paired declarations, whole expected Boolean strings and helper
closure. Complete generated intermediate-shape propagation remains pending.

Private symbolic assignments now resize unsigned vector sources to the actual
whole target length, preserving zero extension and low-bit truncation across
independent widths. Scalar sources and whole-vector reduction results extend
from one bit; a scalar destination takes the source vector's low bit. Target
signedness is applied after unsigned resizing. Complete grouping preserves the
same conversion. The [assignment-rank regression](../../../t/2183-direct-vhdl-assignment-rank.t)
checks actual paired ports, storage and register assignments at distinct selected
defaults, with independent expected target text and unchanged static controls.
Selected operands or lvalues, signed-vector resizing, arithmetic, concatenation
and other computed expressions refuse before selected numeric widths can be
mistaken for elaborated relationships. Symbolic vector-pair and decimal-relational
conditions remain withheld. Generated internal shape propagation and
compiler/override/runtime qualification remain pending.

Direct VHDL source generation now joins its actual completed declaration capture,
assignment analysis and normalized target mapping to that paired parser and
renderer. The bounded combinational profile preserves symbolic port/storage
ranges and width-root natural generics, including vector rank at a selected
default of one. Fixed source products keep their existing conversion path.
The [source regression](../../../t/2184-direct-vhdl-symbolic-source.t) checks
complete expected port/generic blocks, actual mux defaults/transfers, source
capture kinds, backend reuse and whole fixed-product preservation.

Compiler-owned transition references use their existing flagged control AST.
The width preflight validates their complete transition family and actual fixed
state encoding separately from canonical source data Signals. Wrong references,
foreign state targets and mixed/inconsistent families refuse. This does not
turn an ordinary data reference into a compiler state-control node.

Symbolic modules with allocated auxiliary registers or intermediate expressions
remain withheld until those generated shapes propagate correctly. This is a
conservative allocation boundary, including unrelated helpers. A symbolic FSM
with no captured transition also refuses pending state-hold repair. These
refusals happen before any VHDL artifact returns; raw symbolic text gains no
source authority. Full transport, compiler, override and runtime qualification
remain pending.

The explicit self-loop in this complete example gives the state logic its
required transition drive:

```lisp
{{#include ../../../t/data/ial0-direct-symbolic-comb.fsm}}
```

Generate it through the strict CLI:

```bash
./bin/fsmgen --quiet --strict --language vhdl --output .artifacts/vhdl/direct_symbolic_comb.vhdl t/data/ial0-direct-symbolic-comb.fsm
```

`FSM::Backend::VerilogFamily::ParameterBindingEmitter` now shares scalar target
preparation for these direct-module bindings and composition-top bindings. It
retains selected names, static payloads, operator parentheses and repeated
dependencies. Its `text` result keeps the canonical normalizer's scalar kind
for target interpolation. Direct Verilog-family headers now use the same helper;
the composition wrapper keeps its narrower scope. Its direct `lower_default`
profile folds immutable aggregate subtrees and refuses mutable aggregate/path
defaults. Complete override/runtime qualification remains separately owned.

Direct VHDL now emits related plain-decimal scalar defaults as `natural`
generics. Each selected default and arithmetic intermediate must remain in
`0..2147483647`; the supported relationships are root aliases and `+`, `-`,
`*`, `/`, `%` arithmetic. Dependencies precede consumers. A same-valued
independent literal stays `integer`; unrelated sized literals retain their
`std_logic` or `std_logic_vector` type, and independent negative literals stay
on the existing static path. Sized, bitwise, aggregate and path relationships
refuse when they cannot satisfy the natural profile. Related source names must
already be valid VHDL identifiers; independent generated names still normalize.

The [complete direct VHDL fixture](../../../t/data/ial0-direct-vhdl-natural-defaults.fsm)
contains forward aliases, arithmetic, a distinct equal literal, a vector default
and a negative static control:

```bash
./bin/fsmgen --quiet --strict --language vhdl --output .artifacts/direct_natural_defaults.vhd t/data/ial0-direct-vhdl-natural-defaults.fsm
```

Its generic block includes:

```vhdl
NEG : integer := -1;
SAME : integer := 16;
WIDTH : natural := 16;
COPY : natural := WIDTH;
TOTAL : natural := (COPY + 2);
RESIDUE : natural := (TOTAL mod WIDTH);
PAD : std_logic_vector(7 downto 0) := "10100101"
```

This qualifies VHDL default relationships. Direct Verilog-family ports
and source-owned storage now preserve captured symbolic ranges and default-one vector
rank; computed shapes remain successors. A distinct equal literal width creates
no relationship. Direct VHDL symbolic ports and complete external
override/runtime qualification remain pending. The standalone SystemVerilog-text converter
keeps its existing static/integer-expression profile because it has no Core
source bindings. See the direct-backend chapter for the separately owned
reserved-identifier emission defect.

The complete [imported-default fixture](../../../t/data/ial0-imported-default-bindings.fsm)
exercises qualified constants, enum members and a nested aggregate leaf:

```bash
./bin/fsmgen --quiet --strict --output .artifacts/sv/imported_default_bindings.sv t/data/ial0-imported-default-bindings.fsm
```

Direct SystemVerilog and compatibility Verilog module declarations now preserve
actual direct scalar root aliases from these observations. `(BOUND W)` emits
`parameter BOUND = W`; a distinct `(LITERAL 16)` remains a literal even when
`W` also defaults to sixteen. Declared dependencies precede their consumers;
independent names keep the existing alphabetical tie order. Static values and
legacy programmatic declarations keep their existing formatting. A physical
module rename does not replace its local declared binding identities.

The complete [scalar alias fixture](../../../t/data/ial0-scalar-parameter-aliases.fsm)
checks ordinary, forward, chained and sized scalar aliases:

```bash
./bin/fsmgen --quiet --strict --output .artifacts/sv/scalar_parameter_aliases.sv t/data/ial0-scalar-parameter-aliases.fsm
```

Supported scalar operator defaults preserve their actual operands too.
`(FIRST_PLUS (add ALIAS 1))` emits `parameter FIRST_PLUS = (ALIAS + 1)`;
chained defaults retain the immediate parameter name. Nested arithmetic and
bitwise operators keep parentheses and static selections. The complete
[scalar-default fixture](../../../t/data/ial0-scalar-default-expressions.fsm)
is a named supported corpus contract:

```bash
./bin/fsmgen --quiet --strict --output .artifacts/sv/scalar_default_expressions.sv t/data/ial0-scalar-default-expressions.fsm
```

Captured sources require complete source and canonical binding maps. Explicit
compiler copies carry both maps; physical renaming preserves their source
owner. Declaration replacement invalidates the binding map and requires fresh
resolution before another captured header can be emitted. Missing membership,
foreign ownership, inconsistent observations, reserved captured declaration
names and dependency cycles refuse. Legacy programmatic literals retain their
existing formatting.

Direct SystemVerilog and compatibility Verilog headers support immutable
aggregate default subtrees: literal lists/records, captured constants and their
leafwise operations or comparisons. Packed members retain their declared
order. A scalar expression around a folded static subtree still preserves its
actual scalar parameter roots, for example `(1'b1 + W)`.

Defaults that depend on mutable aggregate parameters, member/index selections,
or parameter-valued aggregate members refuse before HDL is returned. This also
covers scalar results from mutable aggregate comparisons. A selected default
layout alone cannot qualify an override-sensitive packed relationship. Parsing
and normalized Core values still describe the selected semantic defaults.

The complete [static aggregate fixture](../../../t/data/ial0-static-aggregate-defaults.fsm)
keeps executable aggregate roots named and is runnable:

```bash
./bin/fsmgen --quiet --strict --output .artifacts/sv/static_aggregate_defaults.sv t/data/ial0-static-aggregate-defaults.fsm
```

VHDL, generic storage/computed shapes and complete external override/runtime
qualification remain separate work. Verilog-family port ranges are implemented;
header text alone is not a complete generic-width guarantee.

One new hardening rule applies in these value lanes: obviously bitstring-like
bare `0/1` tokens such as `00001110` or `10000000` are rejected instead of
being guessed. Use `0b00001110`, `8'b00001110`, or `0d1110` explicitly.

Parameter values may also use bounded operator expressions:

```lisp
(+constants
  (BYTES (8'hA5 8'h3C))
  (BYTE_MASK (8'hF0 8'h0F))
  (FRAME ((meta ((mode 2'b10))))))
(+params
  (WIDTH 16)
  (COUNT_PLUS_ONE (+ WIDTH 1))
  (BYTE_PLUS_ONE (+ BYTES[1] 1))
  (MODE_PLUS_ONE (+ FRAME.meta.mode 1))
  (MASKED (and 8'hF0 8'h3C))
  (BYTES_MASKED (and BYTES BYTE_MASK))
)
```

The current expression operators are `+`, `-`, `*`, `/`, `%`, `&`, `|`, and
`^`, with word aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and
`xor`. Scalar expressions may use scalar parameter/generic operands, including
scalar leaves inside list/record aggregate constants, package aggregate values,
and aggregate parameter defaults, for example `BYTES[1]`, `FRAME.flag`, or
`NESTED.meta.mode`. Width inference stays conservative for scalar expression
defaults.

This is not a scalar-only parameter/generic model.

Parameter/generic values are semantic values and may be scalar or aggregate.

Aggregate values can be declared, reused, overridden, shape-checked, and
packed where the existing paths support them.

The first aggregate-expression slices now support leafwise numeric and
bitwise operators `+`, `-`, `*`, `/`, `%`, `&`, `|`, and `^`, plus `add`,
`sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor` aliases, between matching
list/record aggregate shapes. They also support binary aggregate comparison
with `==` and `!=` between matching list/record shapes.

Normalization folds those expressions leaf-by-leaf into selected aggregate
values. Direct HDL emission requires immutable aggregate operands; actual
mutable aggregate parameter dependencies refuse through the profile above.

Unary bitwise complement is also supported on one aggregate operand through
`(~ VALUE)` or `(not VALUE)`. It keeps the same list/record shape and scalar
leaf widths, and flips each scalar leaf bit before backend lowering.
Aggregate comparison folds to a scalar exact-width `1'b1` or `1'b0` before
backend lowering.

Arithmetic leaves are unsigned and fixed-width: each leaf width must match,
division or modulo by zero is rejected, and overflow/underflow outside that
leaf width aborts before generation.

The supported aggregate-operator surface is currently limited to semantic
parameter/generic values. It applies to direct `+params`, composition
parameter overrides, generated-child parameter overrides, and `.rtlif`
parameter/generic defaults after their values resolve to semantic payloads.
It does not mean that runtime `.fsm` or `.isf` expressions can operate on
whole aggregate values.

Examples:

```lisp
(+constants
  (LANES_A (8'hA5 8'h3C))
  (LANES_B (8'h01 8'h02))
  (FRAME_A ((mode 2'b10) (flag 1)))
  (FRAME_B ((mode 2'b01) (flag 0))))

(+params
  (LANES_SUM (+ LANES_A LANES_B))
  (LANES_MASK (& LANES_A LANES_B))
  (FRAME_OR (or FRAME_A FRAME_B))
  (LANES_INV (~ LANES_A))
  (FRAME_INV (not FRAME_A))
  (LANES_MATCH (== LANES_A LANES_A))
  (FRAME_DIFF (!= FRAME_A FRAME_B)))
```

`LANES_SUM` is folded by adding each matching list item. `LANES_MASK` is
folded by applying bitwise `&` to each matching list item. `FRAME_OR` is
folded by applying bitwise `|` to each matching record member while preserving
the authored record member order. `LANES_INV` and `FRAME_INV` apply unary
bitwise complement to each scalar leaf while preserving the original aggregate
shape. `LANES_MATCH` and `FRAME_DIFF` compare the packed matching aggregate
payloads and fold to scalar `1'b1`/`1'b0` values.

Richer aggregate operators beyond those matching-shape numeric, bitwise,
unary complement, and binary comparison forms remain future work until their
type/shape/result contracts are explicit enough to validate before generation;
that widening is tracked in [Feature Backlog](14-feature-backlog.md).

Direct-root `+params` values may also reuse resolved semantic symbols:
same-root constants, whole aggregate constant roots, enum members such as
`mode.BUSY`, direct `+define` values, and other same-root direct `+params`.

Parameter-to-parameter references are resolved as one acyclic dependency graph,
so declaration order does not matter when there is one safe answer. Cycles such
as `(P_A P_B)` plus `(P_B P_A)` are rejected before HDL emission instead of
being guessed or left for the backend.

In the current direct-root path, references to `+params` remain named parameter
references in expressions instead of being substituted back to their default
literals. SystemVerilog direct-module generation emits those declarations as a
`#(...)` parameter block:

```systemverilog
module example #(
  parameter WIDTH = 16,
  parameter LANES = 16'b1010010100111100
) (
  input  logic clk
);
```

FSMGen keeps width inference conservative here. Explicitly sized defaults and
packed aggregate defaults can contribute exact width where the semantic checker
requires it, but unsized scalar defaults such as `(WIDTH 16)` remain
width-implicit until the HDL context resolves them. Generated-child parameter
override binding is now a separate instance-side contract that targets these
direct `+params` declarations.

## Using Symbols In Widths

`+size` width entries are constant-expression slots too. That means you can
name width ingredients once and reuse them without littering the source with
magic numbers:

```lisp
(+constants
  (BYTE_W 8)
  (LANES (4 8))
)
(+enums
  (mode_w
    (CTRL 4)
    (DATA 8)
  )
)
(+params
  (EXTRA_W 1)
  (CTRL_W (+ BYTE_W EXTRA_W))
)
(+size
  (payload (+ BYTE_W EXTRA_W))
  (mode mode_w.DATA)
  (lane LANES[1])
  (ctrl CTRL_W)
)
```

The resolved value must be one positive integer before generation. Named types
still work in this same slot, so `(+size (frame frame_t))` remains the way to
attach a declared aggregate/scalar type rather than computing a raw width.

Use `(param NAME)` in a direct `+size` expression when the parameter namespace
must be explicit:

```lisp
(+constants (W 8))
(+types (type W (bits 4)))
(+params (W 16))
(+size
  (typed_bus W)
  (constant_bus (+ W 0))
  (parameter_bus (param W))
  (extended_bus (+ (param W) 1)))
```

Here `typed_bus` uses the named type at width 4, `constant_bus` uses the constant
at width 8, `parameter_bus` uses the parameter default at width 16, and
`extended_bus` has width 17. The selector requires exactly one declared scalar
parameter identifier;
it never borrows a same-named constant or type. Member/index paths and general
expressions are not selector names. Existing arithmetic can contain selectors,
and the final result must remain a positive integer. A missing parameter,
aggregate default, malformed selector or non-positive result is rejected.

This form is confined to direct `+size` width expressions. It is not a general
parameter-value operator or an extension to `+types`. The original selector
tree survives in Core width-source metadata. Direct Verilog-family ports now
retain the selected parameter names and vector rank; internal/computed ranges,
source-aware VHDL conversion and complete override behavior remain follow-on work. The complete collision example can be checked with:

```sh
./bin/fsmgen --quiet --strict --check --json t/corpus/direct_size_parameter_selection.fsm
```

Positive integer scalar symbols used as direct `+size` widths or composition
`?ports` widths accept the same common scalar literal spellings, so a shared
`(BYTE_W 0x8)` or `(BYTE_W 'h8)` can safely drive a width contract.

Aggregate scalar leaves may participate too, for example `LANES[1]` or
`FRAME.meta.mode`, but a whole aggregate root such as `LANES` is not itself a
scalar width. Use a scalar leaf when computing a raw width, or use a declared
aggregate type alias when the intent is typed aggregate storage.

The direct `+size` expression path and the scalar-width-symbol path share the
same integer literal interpreter for decimal, `0d`, `0b`, `0o`, `0x`,
SystemVerilog-style based spellings, and FSMGen intent-level sized values.

Signed literal terms are valid ingredients when the final width remains
positive, for example:

```lisp
(+params
  (DEC_W (+ 0d10 -2))
)
(+size
  (from_param DEC_W)
  (from_terms (+ 8'sd9 8'sd-1))
)
```

Width arithmetic must still be fully valid before HDL generation. Division or
modulo by zero, unsupported operators, malformed arity, unresolved symbols, and
non-positive final widths are rejected as language-contract errors instead of
being delegated to the backend.

For example, `(pow 2 3)` is intentionally rejected today because `pow` is not
part of the bounded width-expression operator set.

Likewise, `(+ 8)` is rejected because the supported infix-style width
operators require at least two operands.

Expressions such as `(/ 8 0)` or `(% 8 0)` are rejected before HDL generation
because width declarations must fold to one well-defined positive integer.

## Constants

Use `+constants` for named scalar values and bounded aggregate values.

Simple scalar example:

```lisp
(+constants
  (RESET_BYTE 8'hA5)
  (RESET_ALIAS 0xA5)
  (LANE_MASK 0b1010)
  (OCT_W 0o10)
  (IDLE_MASK 8'h03)
)
```

Scalar constants accept the common integer spellings used elsewhere in the
language: plain decimal, sized SystemVerilog literals, unsized
SystemVerilog-style based literals such as `'hA5`, prefixed forms such as
`0xA5`, `0b1010`, and `0o77`, FSMGen intent-level sized values such as
`5'23` or `8'-0xA`, plus underscore-separated digits.

For value-bearing constants, FSMGen also rejects obviously bitstring-like bare
`0/1` tokens such as `00001110` or `10000000`. Use `0b...`, `N'b...`, or an
explicit decimal `0d...` spelling so the source stays unambiguous before HDL
generation.

FSMGen intent-level sized literals use `<width>'<integer-value>` in `.fsm`.

They are source-language values, not target-HDL text escapes. The backend must
normalize them before emission, so `5'23` lowers to legal SV like `5'd23`,
`20'x1` lowers to `20'h1`, and negative sized values lower as two's-complement
bit patterns such as `8'-10` -> `8'd246`, `8'-0xA` -> `8'hF6`, and
`8'-0b1010` -> `8'b11110110`.

Those names can then be used in direct expressions:

```lisp
(idle
  (OUT = RESET_BYTE)
  (<MODE=IDLE_MASK
    (HIT = 1)
  )
)
```

## Enums

Use `+enums` when you want named members instead of magic numbers.

```lisp
(+enums
  (mode
    (IDLE 0)
    (BUSY 1)
    (DONE 2))
)
```

Then refer to members as `mode.IDLE`, `mode.BUSY`, and so on.

This is especially useful in:

- guard equality conditions
- constant-backed aggregate values
- structural actuals in composition

## Types

The current shipped `+types` slice is intentionally semantic, not backend
spelling.

Current bounded scalar forms include:

- `bit`
- `(bits N)`
- `(bits WIDTH_SYMBOL)`
- `(signed bit)`
- `(signed (bits N))`
- `(signed (bits WIDTH_SYMBOL))`
- `(two_state TYPE)`
- `(four_state TYPE)`
- named aliases to other scalar types

Examples:

```lisp
(+constants
  (WORD_W 32)
)

(+types
  (type flag bit)
  (type byte (bits 8))
  (type word (bits WORD_W))
  (type signed_word (signed (bits 16)))
  (type packed_flag (two_state bit))
  (type safe_bus (four_state (bits 32)))
)
```

The intent is:

- width is semantic
- signedness is semantic
- 2-state vs 4-state is semantic
- the HDL backend chooses the final spelling later

This is not a complete portable type core yet. Enum families still use the
existing `+enums` declaration family, and fixed-size arrays / arrays of
records remain future work rather than accepted `+types` forms.

## Packed Aggregate Aliases

The first shipped aggregate type aliases are:

- `(list TYPE TYPE ...)`
- `(record (field TYPE) ...)`

Both forms allow a single item or member, including a nested type expression:
`(list (bits 8))`, `(record (payload byte_t))`, and
`(list (record (payload byte_t)))`. Local aliases may be declared later in the
same type scope; dependency cycles, empty aggregates, unknown aliases, and
duplicate record member names are rejected. A single-member aggregate retains
its list or record identity rather than becoming a scalar alias.

Example:

```lisp
(+types
  (type nibble (bits 4))
  (type header_t (list bit nibble))
  (type frame_t
    (record
      (mode (bits 2))
      (flag bit)))
)
```

The semantic type identity is preserved through the pipeline so compatibility
checks can use more than width alone. On the SystemVerilog path, direct
generated modules and composition tops also preserve that identity into the
emitted declaration surface by synthesizing backend-owned packed typedefs for
declared aggregate aliases instead of flattening them back to raw vectors.
Generated typedef identifiers include the owning module's identity, so separate
modules may reuse an alias name without colliding at compilation-unit scope.
These backend names are implementation details; semantic compatibility still
uses the declared type shape rather than the emitted spelling or width alone.
Repeated instances of a generated module share its emitted definition while
retaining separate bindings, parameter overrides and hardware state. Conflicting
definitions under the same module name fail explicitly. Reusing a definition
does not merge instances or relax their type contracts.

That means SystemVerilog may emit shapes like:

```systemverilog
typedef struct packed {
  logic [3:0] tag;
  logic flag;
  struct packed {
    logic [3:0] item_0;
    logic [3:0] item_1;
  } payload;
} fsmgen_m10_frame_demo__frame_t__fsmgen_t;
```

Record members keep authored field names. List members use deterministic
synthetic names like `item_0`, `item_1`, and so on.

Typed aggregate signals can also be read in direct-root expressions when the
base signal has a declared aggregate type:

```lisp
(+types
  (type pair_t (list bit (bits 4) bit))
  (type frame_t
    (record
      (tag (bits 4))
      (flag bit)
      (payload pair_t)))
)

(+size
  (IN_FRAME frame_t)
  (OUT_TAG 4)
  (OUT_PAYLOAD_MID 4)
)

(idle
  (OUT_TAG = IN_FRAME.tag)
  (OUT_PAYLOAD_MID = IN_FRAME.payload[1])
)
```

The source stays intent-level: record fields use `.field`, and list elements
use `[N]`. On the current SystemVerilog path, the generated list field spelling
then follows the typedef convention, so `IN_FRAME.payload[1]` emits as
`IN_FRAME.payload.item_1`. Partial aggregate LHS writes such as
`OUT_FRAME.tag = IN_FRAME.tag` are also mapped through the typed AST to the
correct packed base-signal range before generation.

## Width Tokens From Types And Scalars

Direct-root `+size`, composition `?ports`, and scalar `+types` `(bits ...)`
widths may now come from:

- raw positive integers
- local scalar type aliases
- imported package-qualified scalar type aliases
- local positive integer scalar symbols
- imported positive integer scalar symbols

For `+size` and composition `?ports`, width expressions also retain the
broader already-shipped constant-expression surface where documented. For
`+types` `(bits WIDTH_SYMBOL)`, the accepted symbol must resolve directly to a
positive integer scalar constant or enum member in the available symbol scope.
Aggregate scalar leaves, runtime signals, parameters, and arbitrary
expressions are intentionally not accepted as type-width symbols.

Those scalar width symbols use the same positive-integer literal
interpretation as direct `+size` scalar terms, including decimal, `0d`, `0b`,
`0o`, `0x`, SystemVerilog-style based spellings, and intent-level sized
values. This keeps a package constant such as `(BYTE_W 0d8)` or `(BYTE_W 'h8)`
usable anywhere a positive width scalar symbol is allowed.

Example:

```lisp
(+constants
  (BYTE_W 8)
)

(+types
  (type byte (bits BYTE_W))
)
```

Enum members are also valid width symbols:

```lisp
(+enums
  (width_e
    (NIBBLE 4))
)

(+types
  (type nibble (signed (bits width_e.NIBBLE)))
)
```

And in composition:

```lisp
(?ports:public_io
  data_in<BYTE_W
  packed_out>byte
)
```

## Imports

Use `+import` to pull semantic package symbols into scope.

```lisp
(+import shared)
```

The imported names stay namespaced:

- `shared.RESET_BYTE`
- `shared.mode.BUSY`
- `shared.frame_t`
- `shared.BYTES[1]`
- `shared.FRAME.flag`

That is intentional. FSMGen packages are semantic imports, not textual include
files.

## Declarative Scope

Within one declaration family, normal non-cyclic references are no longer
order-dependent.

This is valid:

```lisp
(+constants
  (PACKET (HEADER mode.IDLE))
  (HEADER (mode.BUSY RESET_BYTE))
  (RESET_BYTE 8'hA5)
)
```

But explicit cycles still fail:

```lisp
(+constants
  (A B)
  (B A)
)
```

## Current Boundary

What is shipped today:

- named scalar constants
- bounded aggregate constants
- enum families
- scalar type aliases, including signed and two-state/four-state intent
- packed list and record aliases
- semantic imports from `?pkg`
- declared-type preservation across the live pipeline
- direct generated-module packed typedef emission for aggregate aliases
- composition-top packed typedef emission for aggregate aliases
- direct-root typed aggregate signal member/list-item access in expressions
  and partial aggregate LHS writes on the SystemVerilog path
- typed aggregate top-port and generated-child source paths in composition
  `?wiring`
- symbol-contract, `Intent HIR`, `module_info`, and `Structural RTL IR`
  preservation for the bounded type surface

These items are also tracked in the consolidated
[Feature Backlog](14-feature-backlog.md):

- broader inference-first typing so users need fewer explicit anchors
- broader inference-first aggregate member/index typing without explicit
  declared aggregate anchors
- fixed-size arrays, arrays of records, and full enum-as-type unification
- VHDL aggregate-type lowering beyond current scalar/width-safe surfaces
- richer public type/export surfaces for embedders
