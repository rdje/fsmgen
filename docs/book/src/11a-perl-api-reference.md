# API and Model Reference

## Perl API Reference

The [generated API index](perl-api/index.html) renders the POD embedded in
FSMGen's Perl modules. Start with the selected entry points below. The
[coverage report](perl-api/coverage.html) lists every `.pm` source under `perl/FSM/`
and identifies missing POD explicitly; it also has a
[machine-readable form](perl-api/coverage.json).

| Entry point | Use it for |
| --- | --- |
| [HDLGenerator](perl-api/FSM/Pipeline/HDLGenerator.html) | Construct a generation pipeline and obtain HDL/results |
| [ISF parser](perl-api/FSM/Adapter/ISF.html) | Parse an IAL1 file or source text |
| [ISF scheduler](perl-api/FSM/Scheduler/ISF.html) | Obtain lowered IAL0 sources or a schedule JSON string |
| [Capability manifest](perl-api/FSM/Support/CapabilityManifest.html) | Discover current capabilities and binding contracts |
| [MCP adapter](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html) | Host the bounded read-only local MCP service |
| [VIAL tooling](perl-api/FSM/VIAL/Tool.html) | Check/inspect VIAL source or use the versioned tooling lifecycle |

Prepared composition parameter inspection has a shared
[optional schema owner](perl-api/FSM/Support/CompositionParameterContract.html).
See [Composition Basics](05-composition-basics.md) for discovery paths,
recursive records and the pending source-planning/HDL boundary. The
[plan snapshot](perl-api/FSM/Support/SerializableCompositionPlanSnapshot.html)
preserves a detached environment only when one is supplied by the actual plan.

The internal [integer-width evaluator](perl-api/FSM/WidthExpressionSupport.html)
shares direct-parser width semantics through separate ordinary-symbol and
explicit-parameter resolver callbacks. Composition and direct prepared-range emitters now share this evaluator.
The evaluator alone does not prove source capture or admit a symbolic HDL profile.

POD documents the Perl bindings. The normalized semantic field reference below
complements [Extensions and Embedding](11-extensions-and-embedding.md) for
discovery, support boundaries and tutorials, and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md) for versioned VIAL models.
The selected guides describe signatures, options, return values, exceptions,
effects and stability, with runnable examples. This list is a starting set of
guides, not an exhaustive list of every supported interface.

Other rendered module pages are implementation documentation. POD presence
does not make an internal method public or stable, and a no-POD inventory page
does not describe that module's methods. In particular, the entire raw HDL
generation result is not JSON-safe. Use the documented normalized reports for
external consumers. The MCP adapter exposes its documented read-only query
subset; VIAL tooling's plan/run operations have a separate host boundary.

Direct backend capture preserves Core-authored binary `&`/`|` as bitwise
operations, separately from logical `&&`/`||`. Disjoint nonzero masks remain a
false bitwise-AND guard; nested comparisons use the vector result. Existing Core
bitwise aliases retain their native products. See the
[condition capture implementation](perl-api/FSM/Synthesis/EnableGraph/CaptureSupport.html#convert_condition_to_ast).
Focused constructor/backend checks preserve caller kinds and the distinct parsed
source path. Core literal capture also preserves canonical size/radix spelling:
binary digits retain their binary value in nested guards. Existing unsized scalar
products preserve. Typed and ordinary parsed guard literals have focused controls;
complete external/runtime/public qualification remains separate work. Internal
runtime comparison text now groups bare `&`/`|` children on either side, preserving
the operand tree in diagnostic/factorization strings. Existing scalar and already
grouped products preserve; the checked native factored HDL is unchanged. This
bounded repair does not close arbitrary mixed arithmetic/unary text rendering.

An internal [intermediate allocation holder](perl-api/FSM/IntermediateWidthAllocationSupport.html)
records an explicit current binary max-allocation contract. It binds the actual
Core helper, AST and ordered unsliced operand objects. Matching helper or operand
writes revoke it. Parsed helpers with `INTERNAL_INTERMEDIATE`, unspecified roles
and legacy lowercase intermediate roles qualify; other explicit roles withhold.
Opaque equal-width metadata installs nothing. Records detach and add no owner graph.

The source builder journals eligible fresh binary allocations. Still-current
events cross only exact bare-reference, final width-metadata and classifier
operations, with full state checks around each write. External, annotated or
stale writes cannot borrow that refresh. Direct Parser success publishes at its
existing registry/AST boundary; the facade waits through role and interface
completion. Source, phase or publication failure and parse reuse clear prior or
partial policy. Publishing an inner helper preserves a dependent helper's epoch.
N-ary, literal, sliced, signed, named and unknown shapes remain outside this
binary whole-reference profile. The factorizer and actual target-event joins below qualify the same bounded
profile; other generic range relationships remain separate work.

The factorizer now retains plain-data births for actual unresolved binary
whole-reference candidates, anchored to its owner, row and AST identities. Existing
candidate row keys preserve. A later cached width remains independent; birth
records carry no selected policy. The width resolver now captures selected
intrinsic-max events at the first qualified AST inference, with complete plain
unsigned operands and no native/cached target constraint. Copied/stale inputs and
matching supported source mutations withhold. Exact normalizer width/source
publications and the registry rebuild now preserve current events, checking
proof before reset and binding the actual replacement row. Independent floors
and copied/stale metadata cannot refresh. Exact cache reads now preserve the
held event, including scalar AST re-inference; recursive fallback revokes it.
`factorized_width_allocation` returns completed policy only after normalization,
pruning and final registry publication succeed. Earlier observations remain
diagnostic. Normalization/collection/generation failures and reset/reuse clear
policy; repeated cached normalization mints no replacement proof. Actual target-event publication and bounded symbolic consumers are described
below.
The collector accepts a separate optional `width_allocation` record with kind,
operator, ordered source names and selected width. It requires the same binary
origin and actual plain unsigned declarations satisfying the exact decimal
operand maximum. Absent policy keeps contextual widths independent. This schema
check alone supplies no source provenance; the actual publisher supplies that join.
Successful collection also attaches an existing current Core source-helper
policy to its actual module, operands, AST and input/registry row identities.
`intermediate_width_allocation` returns only that current source attachment or
the completed factorizer policy. Copies and foreign/stale state withhold;
failure/reset/reuse clear both maps. The actual assignment publisher now joins
that current policy to fresh typed origin/text and actual plain module operands.
A final currentness check rejects supported source mutation during publication.
Unknown copies, independent result floors and unsupported source profiles keep
the old event shape. Only `width_allocation` extends qualified snapshots;
publication preserves HDL text and scalar VHDL behavior. Bounded symbolic
consumers follow below.
Private `prepare_binary_operand_relationship` now re-derives canonical ranges
from actual current module operands. Mutable plans must agree in every field
except source-signal identity; equal defaults, independent aliases, static
floors and different trees refuse. Both static operands keep separate fixed
widths. The result is detached source-only data, retaining width-one vector
rank; it proves no allocation/target membership and enables no helper emission.
Private `prepare_binary_intermediate_range` now joins one actual current backend
row and its selected allocation/origin/text event to complete target declarations
and the source relationship proof. It returns detached range data with distinct
source/factorizer roles and width-one vector rank. Copies, caller policy objects,
independent aliases/floors, missing or inconsistent targets and changes during
proof refuse. Static operands retain fixed data; computed operands and binary
VHDL helpers remain outside this profile. Live Verilog-family declarations now
consume current allocation/source relationships. Final assembly independently
invokes the complete-target proof and compares the detached emitted range,
expression, ordered origin and allocation role before returning HDL.

Whole-reference origins now share typed recognition: explicit Core slices and
state wrappers withhold; compatible intermediate references use their own
interface. This supplies syntactic shape before allocation and range proof.

The current width fact cards name their component owners as evidence. Their
complete earlier test/audit locator lists and exact card sources remain in
`docs/audits/width-card-evidence-20261028.json.gz`; each card includes a
digest-checked recovery command. Current contract text and existing recheck
commands remain directly readable in the cards.
Completed declared-width, bitwise/arithmetic allocation/lifecycle/emission/target-proof and graph-birth/intrinsic-frame/vector-guard subtrees retain exact Git revision, file
digest and retention-contract retrieval through their live compact terminals.
The bounded binary family now composes allocation, frozen source/target proof,
actual declaration emission and final event closure. Symbolic truth stays vector
aware at default one. Nested/n-ary and remaining arithmetic/scalar constraints,
other shapes and binary VHDL stay separately owned; full qualification is deferred.

Arithmetic source expressions such as `(+ A B)` stay inline in the parser;
repeated expressions acquire their actual helper in the backend factorizer.
The actual factorizer now records unresolved whole-operand arithmetic births and
qualifies its first intrinsic-max inference for canonical `+`, `-`, `*`, `/` and
`%`. Current policy survives only the already qualified normalization, cache and
registry publications; copied/stale inputs and independent floors cannot mint it.
A separate max-shape recognizer and extended closed max record serve these
arithmetic kernels. Bitwise origin recognition and the Core-holder profile stay
bitwise-only. Opaque operand constraints now withhold a shared inference frame
before tracking, including the existing bitwise factorizer profile; later target
publication already rejected that profile.

Selected arithmetic target events now
publish a separate `arithmetic_origin` with canonical operator and ordered whole
operand names, plus `width_allocation` only while the actual producer policy is
current. For example, `A + B` records `binary_arithmetic`, `+`, and `[A, B]`;
an independently widened result can retain that origin without allocation policy.
Conflicting AST/text, copied metadata and source mutation cannot supply current
policy. Collector completion checks actual operand membership and exact max
widths whenever policy is present. Legacy injected providers retain their shape.
Private arithmetic range preparation now joins those actual events to complete
source and target proof. Both operands must carry the identical frozen mutable
width contract: `A` and `B` using `(param W)` qualify, while `(param COPY)`, an
independent equal-default parameter, a fixed operand or a different expression
tree cannot borrow that relationship. Default one retains vector rank in the
private plan; fixed operands yield fixed data without a generic range. Actual
helper identity, plain unsigned declarations, exact intrinsic max, selected text
and current policy must all agree. Computed operands remain outside this profile.
Complete namespace, declaration and event inputs are checked again at return;
an unchanged derived plan cannot hide a changed computed-helper width or event.
Actual arithmetic declarations now consume that proved range. For repeated
`(+ A B)` guards with both operands sized by `(param W)`, the generated helper
uses `wire [(W - 1):0] A_plus_B;` even when `W` defaults to one. Its assignment
remains `A + B`; guards test the whole vector, zero/nonzero comparisons reduce
the whole helper and equals-one stays exact equality. Ordered operands and
duplicate slots preserve, including subtraction. Fixed helpers keep numeric
declarations. Final assembly independently re-derives complete source/target
proof and compares the emitted expression, origin, allocation role and range;
late disagreement returns no HDL or completed collector snapshot. Failed
generations can reuse the backend and collector after a fresh valid proof.
The bitwise range consumer and scalar-only symbolic VHDL profile retain their
existing boundaries. Other unary/shift/select/concatenation and source-owned nested bitwise
constraints remain separately owned.
Comparison and logical negation helpers retain
independently scalar results. Source acceptance and matching selected numeric
widths cannot establish a mutable helper relationship.

The runnable default-one source is `t/data/ial0-direct-symbolic-arithmetic.fsm`:

```sh
./bin/fsmgen --quiet --strict --check --json t/data/ial0-direct-symbolic-arithmetic.fsm
./bin/fsmgen --quiet --strict --output .artifacts/sv/direct-arithmetic.sv t/data/ial0-direct-symbolic-arithmetic.fsm
./bin/fsmgen --quiet --strict --language verilog --output .artifacts/verilog/direct-arithmetic.v t/data/ial0-direct-symbolic-arithmetic.fsm
```

Computed arithmetic forms such as `(+ A B C)` and `(+ A (* B C))` now propagate
the same proved generic range through selected child and parent declarations.
Every original leaf must have the identical frozen mutable width relationship,
and actual current graph allocation and complete selected-target proof must
agree. Repeated source and computed operand slots retain their order. Fixed
graphs keep their independently selected numeric widths. Different mutable roots,
aliases or static floors cannot borrow an equal default value. Source-owned
nested bitwise forms such as `(& A B C)` still retain a numeric helper range
at the selected default. The Parser owns their nested Core tree; its existing
allocation journal accepts two whole operands, so computed arithmetic graph
ownership cannot supply the missing source-tree contract. Negated n-ary forms
wrap that same bitwise helper in scalar logical NOT. Source-tree birth,
selected-target proof and symbolic range integration remain pending; these
forms do not yet propagate parameter changes through their helper ranges.

The separate `SourceBitwiseTreePolicySupport` data schema now validates
`source_bitwise_tree_operand_max` records. Its source vector contains every
ordered tree leaf slot, including repeated names, and must agree exactly with
the original bitwise tree. It preserves scalar JSON kinds and checks exact
decimal maxima using the existing graph walk limits. For example:

```perl
use FSM::SourceBitwiseTreePolicySupport;
my $policy = FSM::SourceBitwiseTreePolicySupport->copy_record({
    kind => 'source_bitwise_tree_operand_max', operator => '&',
    source_names => ['A', 'B', 'C'], selected_width => '8',
    expression_tree => ['&', ['&', ['signal', 'A'], ['signal', 'B']],
                              ['signal', 'C']],
});
die "width mismatch\n" unless
    FSM::SourceBitwiseTreePolicySupport->matches_selected_widths($policy, 8, 8, 4, 2);
print join(' ', @{FSM::SourceBitwiseTreePolicySupport->leaf_names($policy)}), "\n";
```

This prints `A B C`. Numeric agreement describes the independent fixed maximum;
actual Core ownership, Parser publication, selected target proof and live helper
range integration remain pending. Binary two-slot and computed arithmetic graph
contracts remain separate.

Original nested candidates receive a separate graph birth; substitution binds
typed helper references while the root width is unresolved. Intrinsic events
join that ownership to held child proofs, and completed graph policy follows
successful collection. A later numeric width or printed child range cannot
recreate those events. Actual declaration intent and an independent completed
target traversal bind emission. Logical/comparison wrappers retain one-bit
results; that scalar result alone supplies no vector allocation proof. Focused
selected-graph closure covers deep and multiple-child graphs, default-one rank
and atomic target disagreement. Full override/runtime qualification remains open.

A separate `intermediate_width_graph_birth` diagnostic now retains
`{kind => arithmetic_graph_candidate, expression_tree => ...}` at the actual
fresh unresolved allocation. For `(+ A B C)`, the tree is
`["+", ["+", ["signal", "A"], ["signal", "B"]], ["signal", "C"]]`.
Owned substitution binds generated references to actual current child entries;
expanding their original trees must preserve every ordered operator/source and
Core source identity. This also retains duplicates and deeper arithmetic chains.
Copied rows/capsules, changed or foreign children, unsupported trees and cycles
withhold the diagnostic. Returned records detach and retained capsules own no
AST or backend graph. Compatible generated references use their actual interface;
their compatibility `isa` does not provide Core Signal methods.

The original whole-reference birth API stays separate. Later numeric widths do
not create graph birth or prove allocation. Each private tree walk admits
at most 64 binary levels and 4096 visited nodes; larger trees receive no new
metadata. Private graph input and ready frames now validate source constraints
and actual current child proofs; graph intrinsic events now qualify separately.
Completed graph policy uses its separate current getter after collection.
These diagnostics alone change no HDL, target events or range admission.

`IntermediateWidthGraphInferenceSupport` separates pending unresolved parent input
from ready dependency proof. The canonical width owner holds a weak association
to the actual normalization rows: collected, factorizer and registered rows have
distinct identities. Generated references use the passed registry before the
factorizer fallback; only actual collected rows qualify here. Ordinary sources
require module Signals. Ready frames validate current held child events, preserve
ordered edges and independent constraints, and calculate the exact operand max
before publishing the parent width. Complete dependency rechecks reject a source
write during a later sibling read. Copied/stale rows, missing proofs and merely
equal numeric widths withhold. Returned frames contain only detached JSON data;
the weak association retains no registry and abort clears it. Child cache reads
preserve the stable proof only after the full current child getter validates
owned transient fields. No graph inference event or completed policy is installed
by these private queries. The actual resolver now captures eligible input before
inference, validates ready child proof and compares its selected parent write.
Its separate `factorized_graph_inference_event` returns a closed
`arithmetic_graph_operand_max` record with operator, ordered current edge names,
original expression tree and selected max. N-ary, nested, duplicate and transitive
arithmetic graphs retain their actual ownership. Valid resolver cache reads
preserve held proof, including scalar re-inference; equal copied metadata,
native/floor constraints and changed sources/views cannot create or revive it.
A read shares child validation within its own operation, then independently
rechecks graph inputs, held capsules and whole-reference child proofs before
return. A later sibling source write therefore cannot hide behind a cached
child result. Operation-local observations retain no owner graph. Abort/new
epochs clear holders. Actual normalizer width/source publications now checkpoint
current graph proof and refresh only those allocator/registered fields. Source,
constraint and row-identity changes withhold; publication failure clears partial
holders and fresh backend reuse can capture new proof. Registry merges/rebuilds
now checkpoint all current graphs before taking any child holder. Each actual
assignment witnesses its replacement identity; dependency-ordered restoration
starts after all rows and whole-reference holders are installed. Equal foreign
row copies, copied view maps, source changes and partial installs withhold.
Later matching copies cannot recreate missing proof. Failed collection clears
partial holders and fresh reuse can qualify new events. The prepared block
owns the original row map through rendering, alongside a distinct filtered map
whose entries are the same actual rows. The graph view remains weak: real
prepare/render observations retain current proof, and the view clears when
ordinary generation releases that block. Explicitly retaining the actual block
extends its canonical row lifetime. Retaining only the filtered map keeps row
objects alive without keeping the containing original map; current graph proof
then withholds. Rendering failure clears graph holders, and fresh backend reuse
re-establishes the ordinary lifecycle. Focused checks now qualify this existing
handoff without a new rebind or strong owner reference.

`factorized_graph_width_allocation($name, $actual_info)` now returns the current
closed graph max record only after successful collection, sampled-value pruning
and final registry publication in that epoch. Current intrinsic events alone
supply no early completed policy. The original weak row view and complete graph
proof must remain valid; copied metadata, source/constraint changes, expired
views and failed/reset/new generations withhold. Returned records detach, and
later matching numeric values cannot recreate policy. The ordinary
`intermediate_width_allocation` and whole-reference methods retain their existing
profiles. This completes the bounded graph producer foundation with focused
checks. The current graph policy feeds the canonical range and independent
final-assembly proof described below; full override/runtime qualification is deferred.

The shared `IntermediateWidthGraphPolicySupport` now validates that closed graph
record, original arithmetic tree and current edge pair. It preserves order,
duplicates and scalar JSON kinds, shares the existing birth walk bounds, and
compares exact decimal maxima without native numeric rounding. Numeric helpers
preserve invalid or missing width slots in graph and existing binary checks;
those vectors withhold instead of accepting the remaining values or throwing
an internal arity error. The collector accepts an optional
`graph_width_allocation` schema only with the matching
arithmetic origin, a declared computed operand, no original self-leaf, complete
plain unsigned membership and exact current-pair/original-leaf maxima. It is
exclusive with ordinary `width_allocation`; malformed transactions expose no
partial snapshot. This schema support supplies no producer provenance or range
proof.

Actual consolidated assignments now publish `graph_width_allocation` through
the separate `arithmetic_graph_width_allocation` recovery method. For example,
`(+ A (* B C))` retains `B_mul_C` as an ordered current edge and the original
three-leaf arithmetic tree in its graph policy. The selected expression and
defining/runtime/cached arithmetic origins must agree with the completed current
policy. Every source and collected, allocated and registered computed row must
have a plain unsigned profile; numeric state-model evidence alone cannot publish
this target field. A final complete-policy read rejects source or dependency
changes during publication. Copied metadata, independent floors and mismatched
selected text withhold; legacy recovery providers keep their existing events.
The returned policy detaches. Canonical transitive source/target range proof and
its actual graph declaration consumer are described below. Ordinary binary
allocation and VHDL profiles retain their boundaries.

`DirectDeclaredWidthSupport::prepare_graph_operand_relationship` now provides
the source-only prerequisite for that graph range proof. It uses the shared
graph schema to select every original leaf, preserving order and duplicates,
then proves actual plain module Signals through canonical source preparation.
For `(+ A (* B C))`, the relationship covers `A`, `B` and `C`, rather than using
the computed helper's numeric width as a substitute. If any leaf has a mutable
width, every complete frozen width plan must match except its source Signal
name. Equal defaults from different parameter roots, aliases, static floors or
different expression trees refuse. Fixed leaves retain separate observed widths.
The detached result uses the existing relationship fields and the first leaf's
canonical range representative, preserving vector rank when its default is one.
The graph record selects sources only; this helper proves no selected maximum,
graph allocation or target membership. Actual transitive child/event/declaration
closure is separately checked below. The binary relationship API keeps its existing arity.

The private `prepare_arithmetic_graph_intermediate_range` facade now joins that
relationship to complete actual selected target records. Each computed edge
must have its current arithmetic policy, selected expression and ordered origin;
each source, child and result declaration must retain its independent plain
profile and selected numeric width. Reconstructing the selected DAG must exactly
match the original bounded arithmetic tree. A printed child range or equal
numeric default supplies no child allocation proof. The detached result includes
the original leaves/tree, root range representative and child plans in
`node_order`, with each child's own first-leaf representative.

For a retained actual prepared block, the call uses the current root row and the
collector's complete snapshot:

```perl
my $plan = FSM::DirectDeclaredWidthSupport->prepare_arithmetic_graph_intermediate_range(
    flattened_dt => $backend, signal_name => $root,
    signal_info => $prepared->{all_intermediate_signals}{$root},
    target_language => 'systemverilog', %{$capture->snapshot});
```

The original row map must remain owned; retaining a metadata row alone is
insufficient. Complete source/target inputs, canonical plans and completed graph
policy recheck before the plan returns. Repeated computed operands retain both
ordered edge slots: the numeric resolver's active-call guard distinguishes a
shared child from an actual recursive cycle. This restores the existing whole
child's symbolic declaration in repeated-computed graphs, including vector rank
at a default width of one. The computed parent's proved range is now consumed
through separate graph declaration intent. A real cycle retains conservative numeric
fallback and creates no graph proof. The focused executable examples are
in `t/2230-arithmetic-graph-intermediate-ranges.t`. Focused deep-input and weak
caller-view closure checks now pass in `t/2231-arithmetic-graph-proof-closure.t`.
Actual declaration emission consumes separate source intent and independently
reuses this complete-target proof at final assembly. Full qualification remains
pending. This private join itself emits no HDL and does not extend VHDL admission.

The closure controls change nested child target metadata, selected original-tree
data and a source constraint after canonical source preparation. Even when the
derived canonical plans stay equal, complete input snapshots reject the changed
proof. Matching supported source writes independently revoke dependency policy.
Returned graph JSON retains no row container and cannot revive an expired view.
If the caller releases its last actual prepared-block owner during preparation,
the join refuses. These are graph row-view guarantees; whole-backend and Core
ownership cycles remain separately tracked.

`prepare_arithmetic_graph_declaration` now prepares the source-only root intent
that declaration emission will consume. It takes the current backend/root row,
target language and freshly selected expression, without target snapshots.
Completed graph allocation, selected origin/text and original-leaf contracts must
agree, and complete source/currentness checks run again before return. Its root
fields agree exactly with the independently completed target plan after removing
the child inventory. Fixed widths remain independent; mutable default-one widths
retain vector rank. Copied metadata, different selected text, independent roots,
result floors and late source/result constraints refuse. This intent fabricates
no target events and prints no range. Actual one-pass declarations now consume
that intent, retain a separate graph ledger and expose vector rank to guard
classification. Final assembly independently re-proves the completed selected
graph and requires exact root-field agreement with the ledger before returning
HDL. Missing or changed source/target/ledger evidence refuses atomically; fresh
reuse starts with a new per-generation ledger. Focused actual deep/multiple-child
checks pass in `t/2235-arithmetic-graph-emission-closure.t`: changing a selected
child expression or original tree, removing a child record or dropping the root
allocation returns no HDL or completed snapshot. The collector data remains
detached and a fresh generation recovers on the same backend. Replacing final
independent target proof with already emitted source intent fails the child
forgery checks. These controls qualify the bounded arithmetic graph consumer;
full feature/compiler/override/runtime qualification remains separate work.

The book search covers the manual and this guide. Use the API index, coverage
list or browser Find to navigate the standalone module pages.

For result interpretation, follow a tool's query family through its domains
and contract surfaces to the dedicated owners. A shared source tool can return
hardware or VIAL models, selected by source kind and version. Manifest section
owner maps and nested contract records describe deeper fields; presence-key
lists alone do not close every object. A schema or CLI/library operation named
inside metadata is a description of that separate API. The current MCP tool
list determines callable operations. See
[result contract discovery](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#DISCOVERING_RESULT_CONTRACTS)
for the ownership joins and the distinct tool/resource envelopes.

Keep identity layers separate: manifest/record schema versions, authored-language
versions and the negotiated MCP protocol describe different contracts. Producer
version and best-effort Git revision identify the reporting build; they do not
establish a package release or replay identity.

For `fsmgen_check`, `fsmgen_semantic_introspect` and
`fsmgen_schedule_preview`, supply `source_id` or `source_path`. Discovery
expresses this alternative with `anyOf`; both may be supplied. Every supplied
selector must be a nonempty JSON string, including the unused one. When both are
present, `source_path` selects the source. Paths remain subject to workspace
containment and source/query applicability; schema admission alone does not
prove that a file exists or supports the requested query. See the
[selector reference](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#SOURCE_QUERY_SELECTORS)
for the separate VIAL inspection and version-selection boundaries.

`fsmgen_explain_diagnostic` accepts optional integer `limit_examples` alongside
required `code`. Omitted, zero and negative limits select 10. Positive limits
cap at 100, including large integral numbers such as `1e30`. Matching catalog
entries can be fewer than the limit, including none; reading them does not
execute the examples. See the
[catalog sample limits](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#DIAGNOSTIC_SAMPLE_LIMITS).

| Tool limit | Omitted or negative | Zero | Positive |
| --- | --- | --- | --- |
| Diagnostic `limit_examples` | 10 | 10 | Capped at 100 |
| Support-summary `limit_examples` | 10 | No samples | Capped at 100 |
| Source-discovery `limit` | 25 | No sources | Capped at 100 |
| Example `limit` | 25 | 25 | No numeric cap; at most the matching catalog |

Limits preserve catalog order and leave full-population aggregates intact.
Discovery and example results report the effective limit and returned count;
diagnostic and support results carry sample arrays. Resource reads use defaults.

`fsmgen_capability_query` returns an object. Selected sections normally use
`{section, payload}`; the manifest version is an integer payload, while other
current wrapped sections contain objects. The `all`, `contracts` and `examples`
selectors return their corresponding objects directly. Preserve the selected
value's JSON type and use its public contract for field meanings. See
[capability query payloads](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#CAPABILITY_QUERY_PAYLOADS).

Match each tool's `inputSchema`: arguments are objects, and quoted numbers,
numbers and Booleans are different kinds. Omitted arguments and explicit null
are distinct requests. VIAL tool versions require integers; versions inside
resource URIs are textual path components. `tools/call` requires object `params`
with a string `name`; present `arguments` must be an object. Metadata tools
enforce their required fields, declared kinds and closed argument objects.
Malformed parameters return JSON-RPC `-32602`; unknown string tool names or
diagnostic codes retain their lookup errors. Integral numbers such as `1.0`
and `1e0` are accepted as integers. Quoted tool versions are refused; URI
versions remain textual path components. Validation preserves supplied values
and their JSON kinds in later copies. See the
[argument-admission notes](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#CURRENT_ARGUMENT_ADMISSION)
describe the remaining compatibility limits.

## Current MCP schema compatibility

The tool argument and result declarations identified by the live census have
been repaired. The complete operating reference, nested model coverage and
drift checks remain under qualification. Remaining error-message compatibility
debt is tracked below.

| Surface | Current discrepancy |
| --- | --- |
| Error messages | Reference addresses may remain. Use codes and structured diagnostics |

Example lookup returns a `documentation` object containing grouped Markdown
path lists and their public section contract. It is the manifest's complete
documentation section. Query and limit select catalog entries; they do not
filter that metadata or search document contents. The examples resource and
capability alias return the default examples object. See
[example documentation](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#EXAMPLE_DOCUMENTATION)
for the metadata groups and their relationship to catalog results.

Adapter messages remove recognized final Perl locations naming loaded code or
the entry script, including spaced paths and input line/chunk annotations.
Authored `.isf` and `.fsm` source references remain message text; one final
newline is normalized independently of the embedding caller's record separator.
Quoted division tokens in operator and operator-list diagnostics preserve
regardless of capitalization; ordinary filesystem roots and longer paths still
follow path redaction. Messages retain their character bound. Empty formatted
messages use the generic fallback; a nonempty zero-valued reason remains a
string. See
[error messages](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html#ERROR_MESSAGES)
for the string-recognition boundary and structured-report guidance.

## Normalized Semantic Metadata Reference

Use each field family with its payload subject, dedicated owner, optional or
variant rule, and qualification limits. Begin with
[capability discovery](11-extensions-and-embedding.md#capability-manifest-discovery)
for the containing manifest and query workflow.

### Normalized report-envelope families

`semantic_exports.normalized_semantic_json` advertises the normalized report
contract. Its common family lists describe the native report, rather than the
capability record or the outer MCP tool envelope. Required presence does not
imply a non-null value. Use the published source-query applicability before
requesting a report; reading capability metadata alone performs no source query.

| Metadata field | Subject and condition |
| --- | --- |
| `public_top_level_presence_keys` | Normalized report on either outcome: schema version, producer, command, source, success, diagnostics, diagnostic summary, report-level support accounting and generated-output marker. |
| `success_only_top_level_keys` | Success-only `semantic` and `generation_result_snapshot`. These are not the check report's `result` field. Failure reports omit both. |
| `command_presence_keys` | The report's `command` object on either outcome; its mode is `semantic_export`. |
| `generated_output_presence_keys` | The report's `generated_output` object; the report invocation retains `emitted: false`. A serializable generation snapshot does not itself emit HDL. |
| `producer_presence_keys` | Shared `producer` fields `name` and `report_source` on either outcome. |
| `producer_extra_presence_keys` | The normalized producer's additive `semantic_layers` field, also on failures. It advertises public projection names; its presence does not mean a failed report carries partial semantics. |
| `source_presence_keys` | Base `source` fields `input` and `resolved_path` on either outcome. Their values retain the source-identity contract; they do not describe the metadata record. |
| `source_optional_fields` | The shared name-to-contract object for optional source declarations. Qualifying successful source reports can carry these declarations according to their dedicated contracts; the failure producer uses the base source object. This is not an array of universally required fields. |
| `support_accounting_presence_keys` | Base fields of report-level `support_accounting` on success and failure; currently `matched`. Unmatched sources/failures retain `matched: false`. |
| `matched_success_support_accounting_presence_keys` | Additional report-level support fields when a successful source has a corpus match; includes source-kind and strict-support identity. |
| `matched_failure_support_accounting_presence_keys` | Additional report-level fields for a matched failure; includes diagnostic-code and migration-hint identity. This differs from matched-success additions. |
| `failure_diagnostic_presence_keys` | Base fields of each failure `diagnostics[]` element. These reuse the check-diagnostic contract, including nested support accounting. Unclassified diagnostics retain `code: null`. |
| `matched_failure_diagnostic_presence_keys` | Additional corpus identity fields on each matched failure diagnostic. |
| `failure_diagnostic_optional_artifact_keys` | Optional extracted artifact fields of each diagnostic; absent/unavailable path data must not be treated as a usable path, and the current producer can emit null values. |
| `failure_diagnostic_support_accounting_presence_keys` | Base fields of each diagnostic's nested `support_accounting`; currently `matched`. |
| `matched_failure_diagnostic_support_accounting_presence_keys` | Matched-failure additions inside that nested support object. The advertised field list equals the report-level matched-failure family, but the objects occupy different paths. |

A normalized failure keeps **report-level** support accounting as well as the
support object inside its diagnostic. The current failure producer takes the
report-level match from the first diagnostic's support object when available,
otherwise it uses an unmatched object. Check failures instead place their support
match only inside the diagnostic. Select the family for the actual object path;
matching field names do not make the report and diagnostic interchangeable.

The corresponding shared `*_contract_source` fields name these dedicated owners:

| Shared subject | Owner under `FSM::Support` |
| --- | --- |
| `command` | `ReportCommandContract` |
| `generated_output` | `ReportGeneratedOutputContract` |
| `producer` | `ReportProducerContract` |
| `source` | `ReportSourceContract` |
| `support_accounting` | `SupportAccountingMatchContract` |
| `failure_diagnostic` | `CheckFailureDiagnosticContract` |
| `diagnostic_summary` | `SerializableDiagnosticSummary` |
| `generation_result_snapshot` | `SerializableGenerationResultSnapshot` |

These are owner identities, not commands or MCP tools. The snapshot owner names
a serializable result projection, rather than the live generator object.
The common report `producer` is also distinct from manifest build provenance.
`normalized_semantic_schema_version` identifies the report schema; do not confuse
it with the advertised contract's `schema_version`, tool/build identity, MCP
protocol or VIAL language version.

This is not a closed schema for every nested value. Preserve array order in
observations without inferring family priority; objects use named lookup.
The bounded named families coexist with `full_export_stable: false` and deliberate
regression-backed widening. Semantic payload children, IR tiers, grouped-map
members, snapshots, optional declaration models and classifier policy retain
their dedicated contracts and the detailed references below.


### Normalized payload and IR baseline families

The normalized contract also advertises the baseline shapes below. These lists
name fields of a particular payload or entry, rather than the contract record.
Read the enclosing report outcome and each object's availability before applying
a nested family. The source-query/report-variant coverage and complete nested
value models remain with their dedicated contracts.

| Metadata field | Subject and meaning |
| --- | --- |
| `public_layers` | Advertised public layer-name values: `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir`. This is a value family; the similarly valued forward-IR list below names object fields. Neither establishes executed simulation or validation. |
| `success_semantic_presence_keys` | Base keys of success-only `semantic`: `module`, `system_contract`, `explicit_system_contract`, `signal_analysis`, `forward_ir`. Key presence does not require a non-null object. |
| `success_semantic_optional_child_presence_keys` | Optional `semantic` children: `composition`, `protocol_intent_bundle`, `symbol_contract`. Their presence depends on available source/projection data; they are not mandatory on every success. |
| `success_module_presence_keys` | Core fields of `semantic.module`: module/root/language identity and state, signal, parameter and implicit-system-port summaries. These describe the exported module summary, not the full compiler module. |
| `success_module_optional_metric_keys` | Additional module metric fields for applicable output-drive, standalone-DT and composition projections. Discover these separately from the core fields; do not require every metric for every source. |
| `success_explicit_system_contract_presence_keys` | Authored clock/reset fields of `semantic.explicit_system_contract` when an explicit object is preserved. The parent key can hold `null` when no authored contract is preserved. |
| `success_signal_analysis_presence_keys` | Bucket names in `semantic.signal_analysis`: `inputs`, `multi_bit`, `outputs`, `single_bit`. These are views of signal metadata; the family list does not promise a disjoint partition. |
| `success_signal_analysis_entry_presence_keys` | Core fields of each bucket's signal entry: `direction`, `name`, `signed`, `width`. This names entry fields, not bucket names; broader typed extensions remain separately owned. |
| `success_system_contract_presence_keys` | Effective clock/reset and `declare_ports`/`implicit` behavior fields in `semantic.system_contract`. This differs from the authored explicit-system object, whose family omits those effective-behavior fields. |
| `success_symbol_contract_presence_keys` | Baseline fields of optional `semantic.symbol_contract`: constants, enums, types, package imports and their summaries/projections. Dynamic names and nested values retain their detailed contracts. |
| `success_forward_ir_presence_keys` | Child field names of `semantic.forward_ir`: `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir`. These are sanitized projections, not live compiler objects. |
| `success_forward_ir_intent_hir_presence_keys` | Base fields of the intent-HIR projection: module/state/signal/parameter/system/symbol and standalone-DT intent summaries. Apply it to that tier, not the outer `forward_ir` container. |
| `success_forward_ir_intent_hir_optional_composition_keys` | Additional intent-HIR fields when composition data is projected, including child/generated-child/standalone-DT summaries and records. These are optional tier fields, not the root `semantic.composition` field. |
| `success_forward_ir_lowered_rtl_ir_presence_keys` | Base fields of the lowered-RTL projection, including output-drive, selector-conflict and standalone-DT multi-drive summaries/collections. Detailed entries retain their specific families. |
| `success_forward_ir_lowered_rtl_ir_optional_composition_keys` | Additional lowered-RTL composition fields: auxiliary-assignment, shared-datapath, instance and internal-net metadata. The subject is the lowered tier, not a child entry or the root composition object. |
| `success_forward_ir_structural_rtl_ir_presence_keys` | Base fields of the structural-RTL projection: assignment, auxiliary-assignment, instance, port, net and declared/resolved-link collections and summaries, plus identity. Typed entries and extensions remain separately owned. |

For example, a present `semantic.explicit_system_contract: null` satisfies parent
key presence without providing an authored-system object to inspect. Conversely,
an omitted `semantic.composition` is permitted by the optional-child family.
The current public report factory keeps those states distinct: it always writes
the explicit-system key, then adds each optional child only when its public value
is defined. Reading an advertised nested family does not establish availability
of its object or complete population of an arbitrary raw in-process result.

The scalar owner fields use their emitted names; do not construct a field name
by appending a suffix to an object label:

| Owner field | Namespace under `FSM::Support` |
| --- | --- |
| `semantic_contract_source` | `NormalizedSemanticPayloadContract` |
| `module_contract_source` | `NormalizedSemanticModuleContract` |
| `explicit_system_contract_source` | `NormalizedSemanticExplicitSystemContract` |
| `signal_analysis_contract_source` | `NormalizedSemanticSignalAnalysisContract` |
| `system_contract_source` | `NormalizedSemanticSystemContract` |
| `symbol_contract_source` | `NormalizedSemanticSymbolContract` |
| `forward_ir_contract_source` | `NormalizedSemanticForwardIRContract` |
| `composition_contract_source` | `NormalizedSemanticCompositionContract` |
| `forward_ir_intent_hir_contract_source` | `NormalizedSemanticIntentHIRContract` |
| `forward_ir_lowered_rtl_ir_contract_source` | `NormalizedSemanticLoweredRTLIRContract` |
| `forward_ir_structural_rtl_ir_contract_source` | `NormalizedSemanticStructuralRTLIRContract` |

Each namespace identifies a dedicated contract, not a callable tool. The layer
names and tier containers describe inspectable compilation representations;
metadata discovery supplies no lifecycle execution, temporal observation or
external-tool validation result. Keep report schema, contract version and
source/language applicability separate.

The normalized report builder preserves JSON Boolean metadata, including false
values inside nested hashes and arrays. Private objects and unsupported references
remain filtered. This preserves value kinds without changing the advertised field
families. Direct public-builder controls qualify this value preservation;
native DSL/CLI/MCP source reachability and complete source-report models retain
their separate qualification owners.

This is not a closed schema for every nested payload. Preserve emitted arrays
in evidence without inferring priority, and use named lookup for objects.
Detailed symbol values, composition entries, shared datapath/control records,
structural entries and grouped-map projections retain their own family guides
and deeper model contracts. Unknown extensions are not promoted to stable API
merely because a sanitized object currently carries them.

### Normalized symbol family subjects

Within `semantic_exports.normalized_semantic_json`, each suffix below has two
metadata names. Append it to the appropriate prefix and apply its family to the
corresponding payload root. These are metadata names, not literal keys to add
inside a symbol value. The symbol object remains optional on symbol-poor sources.

| Metadata prefix | Payload root |
| --- | --- |
| `symbol_contract_` | `semantic.symbol_contract` |
| `success_forward_ir_intent_hir_symbol_contract_` | `semantic.forward_ir.intent_hir.symbol_contract` |

The dedicated owner is `FSM::Support::NormalizedSemanticSymbolContract`.
Intent-HIR delegates the matching families to that owner; forward-IR, payload,
report and capability surfaces republish them. Equal family values do not make
the root and intent-HIR payload locations interchangeable.

| Metadata suffix | Subject relative to payload root | Advertised value | Interpretation |
| --- | --- | --- | --- |
| `constant_value_entry_keys` | `constants.<name>` | `kind` | Core key on every advertised constant value, including recursive list elements. |
| `constant_scalar_value_extension_keys` | `constants.<name>` | `payload` | Additional key for a scalar constant value. It is not required on a list value. |
| `constant_list_value_extension_keys` | `constants.<name>` | `items` | Additional key for a list constant value; its ordered elements reuse the value-entry schema. |
| `enum_entry_value_kinds` | `enums.<name>` | `member_payload_map` | Kind label for each enum's member map. It is not a literal member-name key. |
| `enum_member_value_kinds` | `enums.<name>.<member>` | `scalar_payload` | Kind label for values under dynamic enum member names. |
| `type_entry_keys` | `types.<name>` | `kind`, `signed`, `width` | Core keys on advertised recursive type entries. |
| `type_scalar_value_kinds` | `types.<name>` | `bit`, `bits` | Scalar type-kind labels, rather than entry field names. |
| `type_aggregate_value_kinds` | `types.<name>` | `list`, `record` | Aggregate type-kind labels. Their extensions are described separately below. |
| `type_state_model_extension_keys` | `types.<name>` | `state_model` | Scalar extension for explicit two-state/four-state intent; do not require it on every scalar entry. |
| `type_list_extension_keys` | `types.<name>` | `items` | List extension containing recursive type entries. |
| `type_record_extension_keys` | `types.<name>` | `member_order`, `members` | Record extensions: deterministic member order and recursively typed members. |
| `package_import_entry_value_kinds` | `package_imports[]` | `scalar_package_name` | Kind label for an authored package-name string, not a package object. |
| `package_import_entry_value_meaning` | `package_imports[]` | `authored package-import package-name string` | Scalar meaning text on the individual metadata field. |

For example, `symbol_contract_type_entry_keys` describes root type entries;
`success_forward_ir_intent_hir_symbol_contract_type_entry_keys` describes the
same schema at the intent-HIR location. A list type adds `items`; a record type
adds `member_order` and `members`. Both reuse the recursive core keys. Names in
the `constants`, `enums` and `types` maps come from the design, so a family of
value keys or kind labels is not a fixed list of those dynamic names.

In `presence_key_family_map`, look up the same full metadata names. In
`semantic_presence_key_family_map`, remove the leading `success_` from the
intent-HIR name; the root symbol name is unchanged. Both maps preserve list
families as arrays. The two `package_import_entry_value_meaning` fields are
strings individually and single-element arrays in these grouped maps, containing
the same meaning string. Keep that distinction when comparing discovery output.

See the [type and package payload examples](#normalized-symbol-payload-examples)
below for payload context. Package-name metadata exposes no package-spec object
graph, AST or package symbol table. This is not a closed schema for arbitrary
nested values or a source-availability, simulation or backend-execution promise.
The baseline field guide still owns symbol-object availability and core keys;
complete payload/source models and the remaining grouped-map closure stay with
their dedicated contracts.

### Normalized composition envelope and shallow children

Use these fields of `semantic_exports.normalized_semantic_json` to select the
right composition object or child element. The function column names the
dedicated `FSM::Support::NormalizedSemanticCompositionContract` function;
report/payload contracts republish its values, with forward-IR and intent-HIR
delegation for the flattened HIR locations.

| Metadata field | Payload subject | Dedicated function |
| --- | --- | --- |
| `composition_child_entry_keys` | `semantic.composition.children[]` | `normalized_semantic_composition_child_entry_keys` |
| `composition_generated_child_entry_keys` | `semantic.composition.generated_children[]` | `normalized_semantic_composition_generated_child_entry_keys` |
| `composition_presence_keys` | `semantic.composition` | `normalized_semantic_composition_presence_keys` |
| `success_forward_ir_intent_hir_composition_child_entry_keys` | `semantic.forward_ir.intent_hir.composition_children[]` | `normalized_semantic_composition_child_entry_keys` |
| `success_forward_ir_intent_hir_composition_generated_child_entry_keys` | `semantic.forward_ir.intent_hir.composition_generated_children[]` | `normalized_semantic_composition_generated_child_entry_keys` |

The envelope advertises these keys, in emitted family order:
`lane`, `child_count`, `children`, `net_count`, `resolved_link_count`, `generated_child_count`, `generated_children`, `standalone_dt_child_count`, `standalone_dt_children`, `shared_datapath_candidate_count`, `shared_datapath_candidates`, `plan_snapshot`, `provenance_report`.
Counts describe their named summaries or collections; envelope membership does
not describe every entry inside those collections. `plan_snapshot` delegates
to `FSM::Support::SerializableCompositionPlanSnapshot`, and the sanitized
`provenance_report` delegates to `FSM::Support::CompositionReportContract`.

Both ordinary and generated child families advertise the same shallow keys:
`kind`, `instance_name`, `module_name`, `source_name`, `source_root_kind`, `regular_state_count`, `standalone_dt_count`, `output_drive_family_count`, `standalone_dt_multi_drive_target_count`, `parameter_override_count`, `parameter_overrides`, `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir`.
The identity fields identify the child instance/module and its source/root;
the count fields summarize its state, DT, output-drive, multi-drive-target
and parameter-override data. Read `parameter_overrides` as a collection with
its own structural parameter-override alias contract. The child `intent_hir`,
`lowered_rtl_ir` and `structural_rtl_ir` objects retain their dedicated IR
contracts; this shallow list does not recursively define them.

For example, select `composition_child_entry_keys` when reading
`report.semantic.composition.children[0]`; select
`success_forward_ir_intent_hir_composition_generated_child_entry_keys` when
reading `report.semantic.forward_ir.intent_hir.composition_generated_children[0]`.
Guard the optional composition object or HIR collection, and check that the
array has an element before indexing. A HIR collection is flattened under
`intent_hir`; it is not `intent_hir.composition.generated_children`.

Identical key lists do not establish equal child populations, matching array
indices, or unconditional source availability. Keep ordinary and generated
collections distinct, and preserve source-provided array order without treating
it as priority. The baseline guide owns optional object/tier availability.
Standalone-DT child entries, `shared_datapath_candidates`, parameter-override
extensions, deeper value models and grouped-map closure retain their dedicated
contracts. These metadata families do not establish execution or backend support.

### Normalized composition parameter-override aliases

Within `semantic_exports.normalized_semantic_json`, append a suffix from the
second table to a prefix from the first. Each complete name describes an
element of the corresponding child's `parameter_overrides` array, rather than
the child itself or every structural instance in the design.

| Metadata prefix | Payload subject |
| --- | --- |
| `composition_child_parameter_override_` | `semantic.composition.children[].parameter_overrides[]` |
| `composition_generated_child_parameter_override_` | `semantic.composition.generated_children[].parameter_overrides[]` |
| `success_forward_ir_intent_hir_composition_child_parameter_override_` | `semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]` |
| `success_forward_ir_intent_hir_composition_generated_child_parameter_override_` | `semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]` |

| Metadata suffix | Advertised keys | Interpretation |
| --- | --- | --- |
| `entry_keys` | `name`, `origin_kind`, `raw_value_ast`, `value_kind`, `value_payload`, `value_text` | Core entry keys. |
| `raw_value_extension_keys` | `raw_value` | Optional authored-token extension. |
| `value_metadata_extension_keys` | `declaration_default_value_kind`, `declaration_default_value_width`, `value_type_spec`, `value_width`, `declaration_default_value_text`, `declaration_default_value_payload`, `declaration_default_value_type_spec`, `declaration_default_source_expression` | Optional resolver/declaration metadata. |

`FSM::Support::NormalizedSemanticCompositionContract` owns the child aliases.
Its ordinary/generated helpers delegate to
`FSM::Support::NormalizedSemanticStructuralRTLIRContract`: append the same
suffix to `normalized_semantic_structural_rtl_ir_instance_parameter_override_`
for the dedicated value-family function. These reuse the structural
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`
schemas. Root payload/report and flattened intent-HIR/forward-IR metadata
republish the corresponding aliases without merging their payload subjects.

For example, `composition_generated_child_parameter_override_entry_keys`
describes `semantic.composition.generated_children[i].parameter_overrides[j]`.
The HIR counterpart adds `success_forward_ir_intent_hir_` to that metadata
name and applies at the flattened `intent_hir.composition_generated_children`
location. Follow the [shallow child guide](#normalized-composition-envelope-and-shallow-children)
for optional collection checks and child identity before indexing either array.

The core list advertises value representations, not a complete `raw_value_ast`
or `value_payload` model. `raw_value` is optional: a single authored token must
survive validation for that extension to apply. Do not require it on a compound
expression. The value resolver and matched child/interface declaration provide
the optional type, packed-width and declaration-default metadata. Membership
in that extension family does not require every extension key on every entry.

These aliases establish neither equal ordinary/generated override populations
nor unconditional source availability. They introduce no standalone-DT
parameter-override alias family. Detailed expression/type/value semantics,
grouped-map closure and source/backend qualification remain separately owned;
discovering an alias does not run generation or validation.

### Normalized composition standalone-DT children

Within `semantic_exports.normalized_semantic_json`, combine a prefix below
with a suffix from the next table. The payload root is an element of the
standalone-DT child collection, distinct from ordinary/generated children.

| Metadata prefix | Payload root |
| --- | --- |
| `composition_standalone_dt_` | `semantic.composition.standalone_dt_children[]` |
| `success_forward_ir_intent_hir_composition_standalone_dt_` | `semantic.forward_ir.intent_hir.composition_standalone_dt_children[]` |

| Metadata suffix | Subject relative to child entry | Advertised keys |
| --- | --- | --- |
| `child_entry_keys` | `(child entry)` | `instance_name`, `module_name`, `source_name`, `standalone_dt_count`, `standalone_dt_names`, `standalone_dt_enable_families`, `standalone_dt_module_enable_family`, `standalone_dt_multi_drive_target_count`, `standalone_dt_multi_drive_targets`, `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir` |
| `enable_family_entry_keys` | `standalone_dt_enable_families[]` | `dt_name`, `enable_signal` |
| `module_enable_family_keys` | `standalone_dt_module_enable_family` | `dt_names`, `enable_signals` |
| `multi_drive_target_entry_keys` | `standalone_dt_multi_drive_targets[]` | `dt_enable_signals`, `dt_names`, `lhs_enable_signals`, `multi_drive_assertion`, `multiplexer_type`, `rhs_values`, `signal_name` |
| `multi_drive_assertion_keys` | `standalone_dt_multi_drive_targets[].multi_drive_assertion` | `input_count`, `input_enable_signals`, `kind`, `target_signal` |

`FSM::Support::NormalizedSemanticCompositionContract` directly owns the child,
per-DT enable and module-enable key lists. Its target/assertion functions
delegate to `FSM::Support::NormalizedSemanticLoweredRTLIRContract` functions
with the `normalized_semantic_lowered_rtl_ir_standalone_dt_` prefix and matching
suffix. Report/payload and forward-IR/intent-HIR helpers republish the
corresponding families at the distinct root and flattened HIR locations.

The child collection, per-DT enable families and multi-drive targets are
arrays. The singular `standalone_dt_module_enable_family` and each target's
`multi_drive_assertion` are objects. The module summary contains arrays of
DT names and enable signals; each per-DT entry advertises its own
`dt_name`/`enable_signal` pair. Keep these container subjects distinct when
selecting a schema; an assertion family does not describe the entire target.

For example, `composition_standalone_dt_multi_drive_assertion_keys` applies
at `report.semantic.composition.standalone_dt_children[0].standalone_dt_multi_drive_targets[0].multi_drive_assertion`.
Guard optional composition/HIR collections and check array contents before
indexing. HIR uses `intent_hir.composition_standalone_dt_children`, with no
intermediate HIR composition object. Equal metadata lists do not establish
equal populations or matching indices across tiers.

Child `intent_hir`, `lowered_rtl_ir` and `structural_rtl_ir` remain shallow
delegations to their own bounded IR contracts. These advertised families
contain no standalone-DT parameter-override aliases. Enable/assertion metadata
does not establish execution, emitted/checked HDL assertions, verified
arbitration or unconditional source availability. Deeper value models,
broader grouped-map closure and source/backend qualification retain their owners.

### Normalized composition grouped lookups

Within `semantic_exports.normalized_semantic_json`, the report
`presence_key_family_map` and the `semantic_presence_key_family_map` expose
selected composition key families through different names. The report map
uses the complete advertised metadata field name. For the flattened intent-HIR
child families, the semantic map omits the report's leading `success_`:

| Report `presence_key_family_map` key | Semantic `semantic_presence_key_family_map` key |
| --- | --- |
| `composition_presence_keys` | absent |
| `composition_child_entry_keys` | `composition_child_entry_keys` |
| `success_forward_ir_intent_hir_composition_child_entry_keys` | `forward_ir_intent_hir_composition_child_entry_keys` |

The envelope `composition_presence_keys` is present in the report map; the
semantic map omits it. Do not infer an entry merely by transforming its name.
The ordinary/generated-child, parameter-override and standalone-DT families
documented above use the same root versus intent-HIR naming rule. Their grouped
values are the corresponding complete ordered key arrays, with the same
dedicated owners, optional extensions and payload subjects as the individual
fields. A map entry advertises a schema; it does not establish a child instance
or source availability.

For example, compare the root child family with its flattened intent-HIR family:

```sh
./bin/fsmgen --capability-manifest | python3 -c 'import json,sys; n=json.load(sys.stdin)["semantic_exports"]["normalized_semantic_json"]; print(n["presence_key_family_map"]["composition_child_entry_keys"]); print(n["semantic_presence_key_family_map"]["forward_ir_intent_hir_composition_child_entry_keys"])'
```

Equal lists do not prove equal child populations or matching indices. This
selected composition join leaves broader grouped-map/model closure,
shared-datapath subjects and source/backend qualification with their owners.

### Normalized shared-datapath candidate and contributor subjects

Under `semantic_exports.normalized_semantic_json`, combine either prefix with
one suffix below to obtain the exact metadata field. Each prefix describes a
different payload location:

| Metadata prefix | Candidate payload subject |
| --- | --- |
| `composition_shared_datapath_` | `semantic.composition.shared_datapath_candidates[]` |
| `success_forward_ir_lowered_rtl_ir_composition_shared_datapath_` | `semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]` |

| Suffix | Subject relative to the candidate | Family rule | Complete ordered keys |
| --- | --- | --- | --- |
| `candidate_entry_keys` | `(candidate entry)` | `core` | `signal_name`, `width`, `interface_type`, `storage_class`, `reset_value`, `contributor_count`, `contributors`, `top_output_signals`, `peer_input_count`, `peer_input_endpoints`, `default_lifted_visibility`, `planned_reexport_top_output_signals`, `loopback_allowed`, `lifted_runtime_kind`, `lifted_runtime_signal`, `lifted_runtime_next_signal`, `lifted_runtime_reset_value`, `lifted_runtime_reset_active_level`, `lifted_runtime_reset_kind`, `lifted_runtime_reset_keyword`, `aggregate_target_enable_signal`, `multi_value_conflict_signal`, `multi_value_assertion`, `aggregate_enable_family_count`, `aggregate_enable_families` |
| `candidate_declared_type_extension_keys` | `(candidate entry)` | `optional_extension` | `declared_type_name`, `declared_type_spec` |
| `candidate_contributor_entry_keys` | `contributors[]` | `core` | `kind`, `instance_name`, `module_name`, `source_name`, `endpoint`, `bound_signal`, `bound_signals`, `bound_connection_expr`, `output_drive_family`, `drive_intent`, `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir` |
| `candidate_contributor_declared_type_extension_keys` | `contributors[]` | `optional_extension` | `declared_type_name`, `declared_type_spec` |

For example, `composition_shared_datapath_candidate_contributor_entry_keys`
describes each root candidate's `contributors[]` element; it does not describe
the candidate itself. The longer prefix selects the corresponding contributor
subject inside the lowered-RTL candidate collection. These families use the
lowered tier; do not substitute an intent-HIR prefix.

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` owns all four suffix
lists through `normalized_semantic_lowered_rtl_ir_composition_shared_datapath_`
plus the suffix. Root composition aliases delegate through
`FSM::Support::NormalizedSemanticCompositionContract`; the lowered metadata
delegates through the forward-IR contract. Payload/report contracts and the
manifest republish those lists rather than defining another candidate schema.

The declared-type extensions apply to their respective candidate or contributor
objects. `declared_type_name` and `declared_type_spec` are independently optional:
the builder emits each only when its corresponding resolved value is defined.
Check the keys separately. The extension list does not promise both keys on
every entry, and `declared_type_spec` does not close the deeper type/value model.
Core families advertise shallow schema members; they do not make every value
non-null or establish unconditional candidate/source availability.

Contributor `intent_hir`, `lowered_rtl_ir` and `structural_rtl_ir` remain bounded
delegates. Binding expressions, drive intent, aggregate-enable families and the
two assertion contexts retain their own nested contracts. Equal root/lowered
lists do not establish equal populations, matching indices, execution or
verified arbitration. Preserve arrays without inferring priority, and inspect
optional collections before indexing.

### Normalized shared-datapath binding and drive-intent subjects

Use either metadata prefix with one suffix below. Relative subjects begin at the corresponding candidate, and include the contributor collection explicitly:

| Metadata prefix | Candidate payload subject |
| --- | --- |
| `composition_shared_datapath_` | `semantic.composition.shared_datapath_candidates[]` |
| `success_forward_ir_lowered_rtl_ir_composition_shared_datapath_` | `semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]` |

| Suffix | Subject relative to the candidate | Family rule | Complete ordered advertised keys |
| --- | --- | --- | --- |
| `bound_connection_expr_keys` | `contributors[].bound_connection_expr` | `signal_ref_variant` | `kind`, `signal_name` |
| `candidate_contributor_drive_intent_entry_keys` | `contributors[].drive_intent` | `object` | `default_value`, `driver_blocks`, `driver_count`, `driver_enable_signals`, `family_enable_signals`, `multiplexer_type`, `reset_value`, `rhs_enable_families`, `rhs_values` |
| `candidate_contributor_drive_intent_rhs_enable_family_entry_keys` | `contributors[].drive_intent.rhs_enable_families[]` | `array_element` | `driver_blocks`, `driver_enable_signals`, `family_enable_signal`, `rhs_value` |

The binding is a nullable object. The `signal_ref_variant` rule means the advertised two-key list describes `kind: "signal_ref"`; it is not the complete
expression grammar. The public structured-IR builder also preserves compound nodes, such as this observed contributor binding:

```json
{
  "kind": "concat",
  "operands": [
    {"kind": "signal_ref", "signal_name": "left_hi"},
    {"kind": "signal_ref", "signal_name": "left_lo"}
  ]
}
```

Inspect `kind` and preserve the nested data. Applying the two-key list as a universal closed-object validator would reject or discard valid compound data. This
direct public-builder example does not establish native source availability or complete support for every expression kind in every query. The structural
connection-expression owner retains the complete expression grammar and its deeper kind-dependent fields.

`drive_intent` is a singular object; `rhs_enable_families` and its driver-list members are arrays. The helper returns an empty drive object when no valid
output-drive family is available. Guard contents before indexing, and do not infer priority from array order. Default/reset/RHS values and nested expression
semantics retain their dedicated deeper models.

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` owns these families. Its shared drive-intent RHS-family helper delegates to
`normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys`. Composition aliases and forward/payload/report contracts republish the
corresponding root/lowered metadata. Equal key lists do not establish equal populations, actual execution, verified arbitration or source/backend support.

### Normalized shared-datapath aggregate and assertion subjects

The following suffixes apply under both metadata prefixes. The root composition
and lowered-RTL records use the same dedicated LoweredRTLIRContract family
lists; matching schemas do not establish equal candidate populations.

| Metadata prefix | Candidate context |
| --- | --- |
| `composition_shared_datapath_` | `semantic.composition.shared_datapath_candidates[]` |
| `success_forward_ir_lowered_rtl_ir_composition_shared_datapath_` | `semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]` |

| Metadata suffix | Relative subject | Container | Advertised keys |
| --- | --- | --- | --- |
| `aggregate_enable_family_entry_keys` | `aggregate_enable_families[]` | `array_element` | `rhs_value`, `aggregate_enable_signal`, `same_value_conflict_signal`, `same_value_assertion`, `contributor_count`, `contributors` |
| `aggregate_enable_contributor_entry_keys` | `aggregate_enable_families[].contributors[]` | `array_element` | `endpoint`, `family_enable_signal`, `source_enable_signal`, `driver_blocks`, `driver_enable_signals` |
| `assertion_keys` | `multi_value_assertion`; `aggregate_enable_families[].same_value_assertion` | `object` | `input_count`, `input_enable_signals`, `kind`, `result_signal` |

`aggregate_enable_families` groups the candidate contributors' available RHS
families by `rhs_value`, in sorted RHS-key order. Only hash-shaped RHS families
with a defined value participate; the resulting array can be empty. Its
`aggregate_enable_family_count` counts the family entries. Each family's
`contributor_count` counts its own `contributors` array, whose entries identify
an endpoint, its original family enable, its source enable, and copied driver
block/enable arrays. These entries have their own bounded schema, separate from
the candidate-level contributor objects described above. An array establishes
neither scheduling priority nor equality with another candidate population.

The assertion family describes two singular objects with different inputs:

- Candidate `multi_value_assertion.input_enable_signals` contains the families'
  `aggregate_enable_signal` values. Its `result_signal` names the candidate's
  multi-value conflict signal.
- Family `same_value_assertion.input_enable_signals` contains that family's
  contributor `source_enable_signal` values. Its `result_signal` names the
  family's same-value conflict signal.

Both shared-datapath objects carry `kind: onehot0`. Their input list drops
undefined or empty signal names, preserves the surviving order, and uses
`input_count` for the surviving length. The metadata constructor returns an
object even for an empty input list. A family assertion exists only where its
family entry exists; optional candidate/IR availability still applies. Metadata
presence alone establishes neither emitted assertions nor verified arbitration
or execution. Use the separate backend/runtime contracts for those guarantees.
RHS/default/reset values, full expression and deeper IR models,
source availability, and source-query applicability remain separately qualified.

### Normalized shared-datapath grouped lookups

The shared families above also appear in
`semantic_exports.normalized_semantic_json.presence_key_family_map` and
`semantic_presence_key_family_map`. Use the full advertised metadata name in
the report map. In the semantic map, root composition names stay the same and
lowered-RTL names omit the leading `success_`:

| Report `presence_key_family_map` key | Semantic `semantic_presence_key_family_map` key |
| --- | --- |
| `composition_shared_datapath_candidate_entry_keys` | `composition_shared_datapath_candidate_entry_keys` |
| `success_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys` | `forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys` |

The same naming rule applies to the documented contributor, declared-type,
bound-expression, drive-intent and aggregate families. Each grouped value is the
complete ordered key array from the corresponding individual field. Its
payload subject, dedicated owner and container/variant rule remain those in
the tables above. For example:

```sh
./bin/fsmgen --capability-manifest | python3 -c 'import json,sys; n=json.load(sys.stdin)["semantic_exports"]["normalized_semantic_json"]; print(n["presence_key_family_map"]["composition_shared_datapath_candidate_entry_keys"]); print(n["semantic_presence_key_family_map"]["forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys"])'
```

Grouped lookup preserves optional declared-type extensions, nullable bindings,
the bounded `signal_ref` variant, singular drive/assertion objects and nested
family arrays. The assertion list still has distinct candidate multi-value and
family same-value contexts. A schema lookup establishes neither candidate or
source availability nor equal populations, matching indices, execution or
verified arbitration. Full expression/value/deeper IR models, other grouped
maps and source/backend qualification retain their separate contracts.

## Build and preview

Normal HTML builds and previews generate and validate the reference
automatically:

```bash
mdbook build docs/book
cd docs/book
mdbook serve
```

The documentation tool needs Python 3.9 or newer on macOS/Linux and
`Pod::Simple` 3.42 or newer, including `Pod::Simple::HTMLBatch` and
`Pod::Simple::Checker`. Perl's main implementation requirement remains in the
repository README. No FSMGen module is loaded merely to render its POD.

Run these standalone commands from the repository root when diagnosing a
documentation build:

```bash
python3 -B scripts/generate_pod_reference.py
python3 -B scripts/generate_pod_reference.py --check
```

The reference uses local styles and relative links, so it works in a moved
checkout, a custom book destination or a site hosted below a URL prefix.
Generated pages live in the ignored `docs/book/src/perl-api/` directory; the
HTML backend copies them into the book. Captured inputs and temporary staging
stay under `.artifacts/`. The preprocessor reuses an intact current tree
without writing it. Serve watches the module/tool/style inputs and ignores the
generated directory to avoid rebuilding in response to its own output.

## Validation and failures

Generation rejects malformed POD, missing expected module pages, broken local
links/fragments and unsafe paths. The gate considers both the checker
error flag and its diagnostic output. With the qualified Pod::Simple 3.42,
formatting diagnostics can clear the flag even when the output reports an error;
that output still fails generation. The generated coverage population is checked
against all module sources. Source/tool fingerprints and complete output hashes
prevent a stale, missing or modified tree from passing `--check`. The fingerprint
includes Perl/Pod::Simple versions and Python's implementation and release
versions. Missing or changed runtime identities require regeneration. Under the
same inputs and tool versions, fresh renders have identical file bytes;
generated footers contain no wall-clock timestamp.

If generation fails, the previous output tree is retained and the book build
fails. Fix the reported source POD or link before rebuilding. If known generated
files have been damaged, inspect them, then run:

```bash
python3 -B scripts/generate_pod_reference.py --repair
```

Repair replaces only a manifest-owned tree. Unknown extra files/directories,
symlinks and foreign repository/volume paths are refused. Resolve any unowned
content deliberately; the generator will not delete it. Simultaneous generator
invocations fail clearly rather than modifying the output concurrently.

## Check the documented examples

The existing CI Python fixture job discovers the POD example suite. It executes
the selected guides' actual SYNOPSIS programs and checks concrete public
results, source identities and their agreement with the book's entry-point list.
Run the same checker from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B scripts/check_pod_api_examples.py
```

Keep each selected SYNOPSIS as one complete Perl program indented by four
spaces. New selected entry points need an explicit result check. Each invocation
uses a unique repository-local workspace. Failed programs and raw stdout/stderr
are retained at the printed relative evidence path; successful temporary
workspaces are removed. The checker offers a per-program `--timeout` option.
Reference rendering and normal book builds do not execute these programs.
