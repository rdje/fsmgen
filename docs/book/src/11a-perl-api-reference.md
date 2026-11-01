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

Source-transition [dependency selection](perl-api/FSM/AllocationTransitionDependencies.html)
now avoids traversing known unrelated binary, source-tree and literal allocations.
Successful constructors index their complete physical Signal participants with
weak holder keys and a snapshot seal. Potential dependencies still receive the
complete registry, live-state, revision and transition checks. Unknown or copied
holders and changed snapshots use the full path. Holder JSON shapes and Signal
fields stay unchanged; the index retains no Core graph and caches no validation
pass. Focused currentness, transport and lifetime checks pass. The original
large PPIF generation remains a tracked performance blocker; these focused
savings do not establish end-to-end completion.
Repeated bare references still register source writes and revalidate their
dependent allocations; that remaining cost is under repair.

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
nested bitwise forms such as `(& A B C)` now retain a symbolic helper range
when their original plain unsigned leaves share a complete captured mutable
width contract. The Parser owns their nested Core tree; its binary allocation
bucket accepts two whole operands, while a separate source-tree journal captures
fresh n-ary births. Computed arithmetic graph ownership remains separate.
Negated n-ary forms wrap the bitwise helper in scalar logical NOT. Completed
source publication, independent selected-target proof and a separate emitted
source-range ledger qualify bounded native generation. External parameter
changes and runtime still require the separate full feature qualification.

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

use FSM::CoreAST;
my @sources = map {FSM::CoreAST::Signal->new(name => $_, width => 8)} qw(A B C);
my @refs = map {FSM::CoreAST::SignalRef->new($_)} @sources;
my $tree = FSM::CoreAST::BinaryOp->new('&',
    FSM::CoreAST::BinaryOp->new('&', @refs[0, 1]), $refs[2]);
my $helper = FSM::CoreAST::Signal->new(
    name => 'H', width => 8, type => 'wire', attributes => {is_intermediate => 1});
$helper->set_driving_ast($tree);
$helper->set_source_bitwise_tree_width_allocation($policy);
die "missing current policy\n" unless $helper->source_bitwise_tree_width_allocation;
$helper->set_driving_ast($tree); # A matching-state supported write still revokes.
die "stale policy survived\n" if $helper->source_bitwise_tree_width_allocation;
```

This prints `A B C`. Numeric agreement describes the independent fixed maximum;
the explicit Core setter additionally binds the actual root, nested bitwise nodes
and every ordered whole-reference leaf through `SourceBitwiseTreeWidthSupport`.
Plain unsigned wire/register leaves, root roles, exact maximum and empty independent
constraints must qualify. Returned records and private capsules detach from owners.
Weak lifetime identities distinguish objects without retaining their graphs.
Relevant supported writes revoke even when values match; private shape/identity
changes, malformed counters and writes during validation withhold current intent.
Ordinary lookups install no fields. Failed replacement clears previous intent,
and `clear_intermediate_width_allocation` clears both intent families.
This local intent establishes no module membership or fresh source birth.
The separate source journal now provides completed Parser/facade publication.
Separate source/target proof now supports live bounded source helper ranges,
with whole-generation currentness and final emitted-field closure. Binary
two-slot and computed arithmetic graph contracts remain separate.

The actual ExpressionBuilder allocator now stages fresh n-ary AND/OR/XOR births
in a separate optional `source_tree_events` journal. The original binary `events`
bucket keeps its existing shape, and the new bucket is absent without a qualified
tree birth. Only current actual registry/root/tree/leaf associations can refresh
across the known bare-reference, analyzed-role and Parser width-metadata writes.
An external matching-state write, annotated reference or extra write to another
leaf cannot borrow that refresh. Repeated leaf slots and nested dependent helpers
preserve their own identities. Negated n-ary forms stage the bitwise base and
retain their scalar logical NOT wrapper. For example, this internal staging API
prints `A B C` and leaves the returned helper unpublished:

```perl
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::SourceBitwiseTreeWidthSupport;
my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
$manager->register_signal($_, width => 8) for qw(A B C);
my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager);
my $packet = $builder->_capture_intermediate_width_allocations(sub {
    $builder->parse_expression(['&', 'A', 'B', 'C']);
});
my $event = $packet->{source_tree_events}[0];
my $record = FSM::SourceBitwiseTreeWidthSupport->current_core(
    signal => $manager->get_signal($event->{signal_name}), holder => $event->{holder});
die "missing staged birth\n" unless $record;
die "premature publication\n" if $packet->{value}->signal->source_bitwise_tree_width_allocation;
print join(' ', @{$record->{source_names}}), "\n";
```

Captured journal data retains no Core graph; failed capture restores both journal
scopes and a retry records only its fresh births. Ordinary uncaptured allocation
adds no revision trackers. Completed direct Parser calls publish current staged
trees at their registry/AST boundary. The facade defers publication through role
and interface success. Source, phase and publication failures clear previous and
partial policy; a fresh parse can reuse the adapter. Publication adds no semantic
revision, preserving nested source and binary dependency epochs. A same-name
foreign registry leaf cannot borrow a completed birth. For example:

```perl
use Lispish;
use FSM::Adapter::FSMGenFull;
my $text = '(?fsm:tree_policy (+size (A 8) (B 8) (C 8) (DATA 1) (OTHER 1))'
    . ' (idle (<(& A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
my $adapter = FSM::Adapter::FSMGenFull->new;
my $module = $adapter->parse_fsm(scalar Lispish::multi(\$text));
my @helpers = grep {defined($_->source_bitwise_tree_width_allocation)} values %{$module->signals};
die "expected current tree policy\n" unless @helpers == 1;
my $record = $helpers[0]->source_bitwise_tree_width_allocation;
print join(' ', @{$record->{source_names}}), "\n";
```

This prints `A B C`. Successful backend collection now attaches the current tree
policy through a separate `source_bitwise_tree_width_allocation(name, actual_row)`
getter on IntermediateSignalWidthSupport. It requires the actual collected row;
an equal copied row or a Core policy alone cannot supply backend completion.
Installed width owner, context/epoch, module/maps, root/all ordered leaves, AST,
registered row and plain
width/type/source/constraint metadata must agree. A final join after source reads
rejects late membership swaps and supported writes. Returned/stored data detach
from owners. Failed/reset/new generations clear the separate attachment map,
while unchanged numeric cache reads preserve it at one and wide defaults.
The old binary and arithmetic graph getters retain their own families. The
actual source-tree collection/refusal/reuse contract can be run with:

```sh
scripts/run_with_ram_guard.sh -- prove -Iperl t/2240-source-bitwise-tree-attachment.t
```

Frozen source/selected target proof and symbolic range consumption remain separate;
the new attachment emits no new symbolic helper range.

The selected-data collector now accepts separate optional `source_tree_origin`
and `source_tree_width_allocation` fields. The origin keeps the complete bitwise
tree and every ordered leaf slot; the policy must match the entire tree, including
association and mixed operators. Equal flat leaf vectors alone are insufficient.
Every leaf needs an actual declaration, and the result cannot be its own leaf.
With policy, plain unsigned result/leaf declarations and exact decimal maxima
must agree. Origin alone keeps contextual result widths independent. The new
origin/allocation families are exclusive with the existing families, preserve
JSON kinds and detach on input/output. For example:

```perl
use FSM::SourceBitwiseTreePolicySupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $origin = FSM::SourceBitwiseTreePolicySupport->copy_origin({
    kind => 'source_bitwise_tree', operator => '&', source_names => ['A','B','C'],
    expression_tree => ['&', ['&', ['signal','A'], ['signal','B']], ['signal','C']],
});
my $policy = {%$origin, kind => 'source_bitwise_tree_operand_max', selected_width => '8'};
my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
$capture->begin_module('selected_tree');
$capture->record_intermediate_declaration({name => 'H', width => 8, signed => 0});
for my $row (['A',8], ['B',4], ['C',2]) {
    $capture->record_declaration('ports', {name => $row->[0], width => $row->[1], signed => 0});
}
$capture->record_intermediate_assignment('H', {
    expression => 'A & B & C', source_tree_origin => $origin,
    source_tree_width_allocation => $policy,
});
$capture->complete;
print join(' ', @{$capture->snapshot->{target_intermediates}{H}{source_tree_origin}{source_names}}), "\n";
```

This prints `A B C`. Tree data is bounded before complete-event JSON cloning.
Malformed, cyclic, over-bound, conflicting, missing, typed or width-inconsistent
records invalidate the collector; a new transaction can start fresh. These checks
validate data and numeric declarations. Actual source assignment emission now
publishes these fields separately through the recovery owner's optional
`source_bitwise_tree_origin` and `source_bitwise_tree_width_allocation` methods.
`SourceBitwiseTreeOriginSupport` walks typed Core/runtime/compatible references
under the shared bounds, preserving association, mixed operators and every
ordered occurrence. Cycles, slices, literals, state/logical/arithmetic shapes,
unknown names and binary-only trees receive no new tree origin. It follows the
held tree, without expanding other Signals' driving ASTs or interpreting names.
Complete defining/runtime/cached trees must agree, and fresh rendering must equal
the exact selected assignment text. A final tree check rejects cache changes
during rendering. The optional policy additionally needs the installed width
owner's current completed source attachment; its whole tree and plain/max
contract are rechecked after selected reads. Matching late source writes, copied
rows, independent floors and unsupported source constraints cannot borrow policy.
Origin alone still supplies syntactic data without mutable width equivalence.
For example, after the earlier complete-source parse, the selected record can be
inspected through actual generation:

```perl
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $text = '(?fsm:tree_target (+size (A 8) (B 8) (C 8) (DATA 1) (OTHER 1))'
    . ' (idle (<(& A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
my $backend = FSM::HDL::FlattenedDT->new;
my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
{
    local $backend->{declared_width_declaration_capture} = $capture;
    $backend->generate_systemverilog($module);
}
my @events = grep {exists($_->{source_tree_width_allocation})}
    values %{$capture->snapshot->{target_intermediates}};
die "missing selected tree policy\n" unless @events == 1;
print join(' ', @{$events[0]{source_tree_origin}{source_names}}), "\n";
```

This prints `A B C`. Assignment text and declaration widths keep their current
behavior; legacy providers without the optional methods retain their old event
shape. Failure after actual event emission invalidates the capture, and fresh
same-backend reuse recovers. Frozen source/complete selected-target proof and
symbolic range consumption remain separate; selected metadata admits neither.

A separate source-only prerequisite now proves the frozen original-leaf
relationship through `DirectDeclaredWidthSupport`. The closed tree policy
selects all ordered leaves, including duplicates and mixed operators; it does
not attest their allocation or selected maximum. The existing canonical width
kernel requires actual plain unsigned module leaves. If any leaf is mutable,
every complete frozen range contract must agree, including its original scope,
width tree, ordered parameter roots and vector rank. Equal-default aliases,
fixed floors and a different final leaf cannot borrow an earlier match. Fixed
leaves retain their independent widths and return no symbolic range.

For example, this prepares a relationship from actual source and selected data:

```perl
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $text = '(?fsm:tree_leaves (+params (W 1))'
    . ' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
    . ' (idle (<(& A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
my $backend = FSM::HDL::FlattenedDT->new;
my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
my $collect = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
    ->can('collect_consolidated_intermediate_signals');
my $rows;
{
    no warnings 'redefine';
    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals
        = sub {$rows = $collect->(@_); return $rows};
    local $backend->{declared_width_declaration_capture} = $capture;
    $backend->generate_systemverilog($module);
}
my ($event) = grep {exists($_->{source_tree_width_allocation})}
    values %{$capture->snapshot->{target_intermediates}};
my $plan = FSM::DirectDeclaredWidthSupport->prepare_source_tree_operand_relationship(
    fsm_module => $module, assignment_analysis => $backend->{assignment_analysis},
    target_language => 'systemverilog', source_tree_width_allocation => $event->{source_tree_width_allocation});
print $plan->{profile}, ' ', join(' ', @{$plan->{source_names}}), "\n";
```

This prints `symbolic A B C`. The detached representative retains vector rank
at the selected default of one. Changing only C to `(param COPY)`, with COPY
aliasing W, refuses because its original relationship differs. This private
method emits no range and attests neither current source-helper edges nor
complete selected targets. Actual source intent over original module leaves now has a separate private
preparation step, including recursive typed source helpers. The independent
complete-target join below qualifies selected records, and the live Verilog-family
backend now consumes these source intents with independent final closure. VHDL
and public API/MCP/corpus support are unchanged.


The example deliberately retains the actual collected row map in `$rows`. With
that caller-owned view still alive, prepare current source declaration intent:

```perl
my ($name) = grep {exists($capture->snapshot->{target_intermediates}{$_}{source_tree_width_allocation})}
    sort keys %$rows;
my $expression = $backend->{backend_sv_intermediate_recovery_support}
    ->render_intermediate_signal_expression($name, $rows->{$name});
my $intent = FSM::DirectDeclaredWidthSupport->prepare_source_tree_declaration(
    flattened_dt => $backend, signal_name => $name, signal_info => $rows->{$name},
    target_language => 'systemverilog', expression => $expression);
print $intent->{allocation_role}, ' ', join(' ', @{$intent->{leaf_names}}), "\n";
```

This prints `source_intermediate A B C`. The source-only root binds installed
completed allocation, exact selected typed tree/text, current row identity,
original-leaf contracts and independent selected maxima. Complete source-width
snapshots and selected policy are checked again after preparation, so an
unrelated source constraint or late matching write cannot hide behind unchanged
range text. Arithmetic graph intent uses the same source snapshot logic.
Returned plans retain no caller map or objects; copied rows, displaced owners,
expired row views and independent source/result constraints refuse.

Actual whole Core helper references now expand recursively through their own
current completed source-tree or binary bitwise attachments. For example, repeat
the generation block above with the source condition `(& A B (| A C))`, keeping
the actual `$rows` alive. The same preparation call returns:

```text
source_intermediate A B A C
```

The expanded `expression_tree` is
`[&, [&, [signal, A], [signal, B]], [|, [signal, A], [signal, C]]]`.
Its `leaf_names` retain the repeated A. Root `source_names` and the root
allocation/origin keep the selected local edges, including the actual child
helper name. A nested n-ary child such as `(| A B C)` similarly returns original
leaves `A B A B C`. Mixed operators, association and shared helper occurrences
preserve; names and matching numeric widths alone supply no edge.

Every child needs its own actual current collected row, plain unsigned completed
policy and fresh typed selected expression. Missing or copied rows, stale child
text, foreign Core references, independent constraints and cycles refuse.
Expansion uses the shared tree depth and occurrence bounds, counting repeated
helper occurrences separately. Original mutable leaf contracts must agree even
when a different equal-default alias is hidden behind a helper. All child
selections replay at return; a final raw-field fence follows the last complete
source read so a late child metadata change cannot escape.

Source intent supplies no completed-target membership or child
inventory. The live backend consumes it separately from independent target proof. Keep the actual
prepared block alive through proof; a saved plain plan cannot revive expired
current ownership.

With the actual row view retained, independently join the complete selected
namespace, declarations and intermediate events:

```perl
my $selected = $capture->snapshot;
my $target = FSM::DirectDeclaredWidthSupport->prepare_source_tree_intermediate_range(
    flattened_dt => $backend, signal_name => $name, signal_info => $rows->{$name},
    target_language => 'systemverilog',
    map {$_ => $selected->{$_}} qw(target_namespace target_declarations target_intermediates));
print $target->{allocation_role}, ' ', join(' ', @{$target->{leaf_names}}), "\n";
```

For the original `(& A B C)` example this prints `source_intermediate A B C`.
The root fields agree with separate source intent. `nodes` contains each actual
reachable helper's detached plan; `node_order` puts children before parents.
Binary children retain their own binary policy/origin fields, while source-tree
children retain their tree fields. Shared physical children appear once in the
inventory and expand at every ordered source occurrence.

Each actual typed edge needs its current selected child event, completed policy,
exact expression and plain unsigned physical declaration. Original leaves must
join their canonical target membership and frozen width contracts. Missing or
foreign child records, renamed targets, substituted original events, altered
operators or independent maxima refuse. Every complete input map and current
child proof rechecks at return, followed by a raw currentness fence after the
last source snapshot. Unrelated input or source changes cannot hide behind an
unchanged derived range. Returned data retains no caller row map, and failure
returns no partial plan. Private proof and live declaration emission keep separate
ownership; final assembly independently compares every emitted source intent
with the completed target root.

A nested source expression such as `(& A B (| (| A B C) C))` also creates a
binary helper over a generated child. That helper cannot use the old
two-original-operand relationship: its numeric width supplies no mutable
ancestry. Separate private `prepare_computed_source_binary_declaration` and
`prepare_computed_source_binary_intermediate_range` entrypoints now prove its
source intent and complete selected targets through the same bounded recursive
kernels. Pass the actual binary root's name/row and expression to the first;
pass its name/row and complete target maps to the second, as in the calls above.
The binary root retains `width_allocation` and `bitwise_origin`, while expanded
leaves preserve the original `A B C C` order. Every child still needs its own
current policy/event and physical declaration. Tree-only entrypoints remain
closed to binary roots, and direct two-original binary helpers retain their
existing owner.

The actual Verilog-family backend now consumes both source-tree and computed
source binary intent. Every original mutable leaf must have the same complete
captured width relationship; a helper name or equal selected default supplies no
ancestry. A separate generation ledger records every emitted source helper's
range, selected expression, policy/origin, original tree and ordered leaves.
Whole-value guards consult that symbolic rank even when the default is one.
Scalar logical NOT and unary reduction results keep their own scalar behavior.
Fixed independent leaves retain numeric declarations and no symbolic ledger.

Final assembly derives expected coverage from actual selected events and typed
source dependencies, independently of ledger membership. It re-proves complete
targets and compares every root field. A raw source fence spans declaration
preparation through the final proof: even a later child's getter cannot revoke
an already proved helper unnoticed. Missing policies/events, changed source,
incompatible equal-default aliases or ledger mismatches return no HDL and no
completed capture. Fresh same-backend generation recovers.

For example, save this as `.artifacts/bitwise_generic.fsm`:

```lisp
(?fsm:bitwise_generic
  (+params (W 1))
  (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))
  (idle
    (<(& A B (| (| A B C) C)) (= (DATA 1)) (= (OTHER 1)))
    (-> idle)))
```

Generate either Verilog-family target:

```bash
./bin/fsmgen --strict --output .artifacts/sv/bitwise_generic.sv .artifacts/bitwise_generic.fsm
./bin/fsmgen --strict --language verilog --output .artifacts/sv/bitwise_generic.v .artifacts/bitwise_generic.fsm
```

The participating source bitwise helpers retain `[(W - 1):0]` at default one.
This fixes the previously recorded nested binary consumer refusal. The focused
native checks qualify declarations, whole-value guards, missing-event/late-write
refusals and atomic recovery. External compiler, parameter override, runtime and
full feature qualification remain separate; generated text alone proves none of
those outcomes.

Bounded native family closure also covers top-level OR/XOR with repeated leaves
and negated-base forms such as `(!& A B C)`. Logical negation may render as `!X`
or the equivalent whole-vector zero test `(~|X)`; its result stays scalar. A
source-matched comparison of the saved AND fixture preserves complete selected
namespace/declaration/event snapshots, including JSON kinds, at the recorded
mutable and fixed defaults. Its HDL changes are confined to helper ranges and
whole-value enable gating at default one, plus the authenticated generated date
comment. The comparison binds the three named native producers; full feature,
external override/compiler/runtime and transport qualification remain pending.
The deferred full-feature task also owns collection-scale retained-fence memory
qualification; the native cases above establish correctness in their saved scope.

Focused scalar closure covers `(== A B)`, `(! A)`, `(! (+ A B))`, `(!& A B)`
and `(== (+ A B) C)` in both Verilog-family backends. Their comparison or
whole-value logical-NOT result remains a scalar wire, while any arithmetic or
bitwise vector child retains its original parameterized range, including at a
one-bit default. Scalar results do not borrow vector maximum-allocation policies.
`t/2272-scalar-intermediate-source-target-closure.t` joins complete actual HDL
expressions/declarations and captured widths to those source contracts, preserving
Core expressions, parameter bindings and caller JSON kinds. Independent signed,
named-type, state, opaque and floor constraints remain a separately owned lane;
this check adds no external elaboration, runtime or public-profile qualification.
At the private Core boundary, post-parse signed, named/explicit-type, state,
opaque or declared-result changes cannot reuse a completed plain literal policy.
`t/2273-literal-source-profile-refusals.t` checks actual generation refusal,
invalidated capture, cleared generation ledgers and fresh same-backend recovery.
These interventions qualify source-proof rejection, not typed source admission.
The bounded scalar/literal/independent-constraint implementation family is closed
within these contracts. Concatenation, selection and shift relationships, wider
paired VHDL consumers and full feature/public qualification remain separately owned.

Native guard diagnosis also identifies open capture repairs: static slice guards
lose the selection during condition capture, and bit guards can
become an undeclared `condition` operand.
The saved sources, complete target observations and repair owners are in
`docs/audits/expression-shape-selection-20261030/` and the active reduction tree.
These guard observations do not classify RHS support or qualify generic ranges.

Concatenation condition capture now preserves the existing Core typed tree;
ASTSupport recursively renders its ordered operands with the current target rules.
Nested concatenations, repeated/reversed operands, explicit literal widths and
fixed scalar/vector sums retain their actual source values. T2275 joins complete
actual expressions and summed declarations in both Verilog backends, preserves
caller/Core products and rejects mutable helper dependencies until symbolic sum
proof exists. A selected numeric sum is insufficient; refusal invalidates capture
and the same backend can recover with a fixed source. This changes guard capture;
separate native comparisons preserve existing RHS artifacts. Exact receipts and
replay producer: `docs/audits/concat-guard-capture-20261030/`. Generic sum
allocation/currentness/emission, VHDL and external runtime remain separately owned.

The factorizer's private `concatenation_width_birth($actual_candidate_name)` now
exposes original allocation provenance independently of numeric inference. It
returns a detached `concatenation_sum_candidate` record with an ordered
`expression_tree`: `['concat', OPERANDS...]`, `['signal', NAME]`, or
`['literal', {value, width, radix}]`. Nested and repeated occurrences preserve;
literal fields reflect the actual Core representation at allocation, including
an unknown width. Source parsing may already have normalized a literal's digits.
The capsule binds the actual allocator, candidate row, AST and reference/Core
source identities. Equal names or selected widths cannot recreate a birth, and
copied/foreign/divergent objects withhold it. Lookup adds no tracking state.
Built-in whole references, Core literals and concatenations qualify within the
bounded walk documented in `FSM::ConcatenationWidthBirthSupport`; unsupported
computed, generated, sliced/indexed, state or subclassed operands withhold.
This diagnostic provenance supplies no source width, rank, type eligibility,
completed allocation policy or generic target range. Later numeric widths remain
independent. T2276 qualifies actual native fixed guards in both Verilog backends,
ownership/refusal/boundary controls and caller preservation; the exact predecessor
and complete native product comparison are retained in
`docs/audits/concat-candidate-birth-20261030/`. In the retained fixed/mutable
guard/RHS cases, native observation selects actual factorizer/Core operands;
typed naming remains a separate API. The observed calls, positive controls and
complete native products are in `docs/audits/concat-source-producer-selection-20261030/`.
`FSM::ConcatenationSourceObservationSupport` provides a separate getter-free
observation of current Core sources. `capture` takes the actual `factorizer`,
`signal_name`, `fsm_module` and complete normalized `assignment_analysis`;
`current` takes the same inputs plus the returned `holder`. Both return detached
`record`/opaque in-process `state` capsules, or withhold unsupported observations.
The record preserves the original tree, duplicate ordered source names and raw
Signal declaration/requirement/binding/revision fields. Actual Core membership
is required; a printed name or an equal selected width cannot supply it.

The raw barrier includes nonoperand declarations, normalized LHS/control rows,
parameter scope and observed container identities. Equal-valued replacements
revoke an old frame. No semantic getter runs, no tracking state is installed and
no owner graph is retained. Unknown literal widths remain unknown; raw numeric
width one establishes no scalar/vector rank. Signed, typed or constrained fields
remain unqualified observations. Restored scalar edits without a surviving
revision change are outside this read-only contract. Canonical source eligibility,
getter-versus-raw coherence and completed backend events remain prerequisites of
generic sum proof and emission. T2277 checks actual factorized guard sources and
preserves inline RHS profiles that expose no concatenation candidate; neither
those finite observations nor a raw frame authorize generic helper ranges.
Exact native conservation and first test corrections:
`docs/audits/concat-source-observations-20261030/`.

`FSM::ConcatenationSourceWidthSupport->prepare` joins that original `observation`
to canonical direct source preparation. Pass the same actual inputs plus
`target_language`; `current` takes those inputs and the returned `holder`.
Its detached record retains the original expression tree and ordered operands,
including repeated slots, with each operand's independent numeric width,
scalar/vector rank and canonical `width_plan`. Fixed and independently mutable
widths may coexist; a parameter width defaulting to one remains a vector.
Literal value/width/radix fields, including an unknown width, stay independent.
No matching-maximum rule or selected concatenation sum is introduced.

Complete getter-free barriers surround canonical preparation and late semantic
reads, including nonoperand declarations. Semantic getter snapshots must match
the raw declaration projection. A stale observation cannot be refreshed by
revalidation. Signed, state, typed, constrained, computed/intermediate, opaque,
combined or foreign source profiles refuse contextually. A fixed retained
requirement needs one matching literal declaration; plain Core widths without
source metadata retain their fixed contract. Malformed scalar driving expressions
withhold at raw observation. Returned plans retain no caller owner graph.
T2278 covers actual native guard sources, independent parameter relationships,
width-one rank, hostile reads, refusal/recovery and detached lifetime. Complete
native products and the exact predecessor control are retained in
`docs/audits/concat-source-widths-20261030/`. This source-only join grants no
completed backend event, symbolic sum range, generic emission or full qualification.

`ConcatenationSourceWidthSupport->prepare_sum` now takes the same actual source
inputs and the original independent source `holder`. It revalidates that holder,
walks the original nested concatenation in order and derives each term from its
own contract. Repeated signals contribute repeatedly; independent equal-default
parameters retain distinct names. Explicit literal widths contribute exact terms
while their original value, width and radix fields remain unchanged. Unknown
literal widths refuse; target-specific unsized sizing stays with the emission
integration owner. The adapter shares the prepared kernel's flattened-term bound.

The returned holder contains `sources` (the original revalidated source holder)
and a `concatenation_source_sum` record. Its exact `width` is a decimal string;
`terms` retain the ordered signal/literal contracts. Fixed-only sums have no
symbolic range. Mutable sums use the canonical parameter environment and shared
prepared-sum renderer, retaining independent source arithmetic and width-one
operand vector rank. `current_sum` rechecks the whole original result, including
JSON scalar kinds, and withholds changed, stale or foreign holders. Neither
operation refreshes an observation or installs backend metadata.

Complete raw barriers and getter coherence include nonoperand declarations and
all parameter maps, including after environment preparation and target rendering.
The `t/2291-concatenation-source-sums.t` regression exercises
actual original Core/factorizer contracts and native guard collection in both
Verilog-family backends. Its independent emitted-syntax oracle checks source-slot
widths under distinguishing overrides. The retained
`docs/audits/concat-source-sums-20261031/replay.py` producer also
rejects native controls that borrow the first source contract or remove the final
raw barrier. These focused checks qualify private source sums; completed backend
event/currentness, target projection, declarations and ledgers remain separate
joins. Actual mutable guard generation still refuses without target sum proof.
VHDL and external compiler/override/runtime qualification remain open.

The installed width owner's private `factorized_concatenation_sum(NAME, ROW)`
now joins those independent source sums to a held original completed inference
event. It derives on read and returns detached `{allocation, sum}` records:
`allocation` is the original numeric inference record; `sum` is the canonical
ordered source-sum record above. Its selected width must agree exactly with the
independent sum, and both must name the same original source contract. The
shared source profile is `systemverilog` for both Verilog-family backends;
physical target selection remains a separate contract.

Intrinsic events before successful collection supply no completed sum. The
original installed source/event holders, complete row and registry identities,
weak row view and completed epoch must survive all semantic reads. The last
barrier reads raw state without invoking getters, so a late source, nonoperand,
row, proof-map or epoch change withholds the result. No additional cache is
installed and missing proof cannot be minted. Returned records retain no caller
graph or row-view ownership. Failure, reset and backend reuse revoke old joins;
a fresh successful generation obtains its own original events.

`t/2292-concatenation-completed-sums.t` checks actual collection/prepared
boundaries, ordered repeated and explicit-literal sums, width-one operand rank
and independently interpreted range arithmetic under distinguishing overrides.
It also checks actual inline-RHS applicability and hostile late mutations.
`docs/audits/concat-completed-sums-20261031/replay.py` retains the identical
predecessor test and controls removing the final raw barrier or numeric agreement.
This qualifies the private completed join. Stable filtered resolver carry is
qualified separately below; mutable guards still refuse without target sum proof. Target namespaces, declarations,
expressions and final emitted ledgers, VHDL, external execution and full
publication qualification remain open. Public source/report/API/MCP/corpus
capabilities do not expand in this slice.

`DirectDeclaredWidthSupport->prepare_concatenation_declaration` delegates private
source-only declaration intent to `DirectConcatenationRangeSupport`. Supply the
actual `flattened_dt`, `signal_name`, `signal_info`, selected `expression` and
explicit Verilog-family `target_language`. The original completed sum must remain
current. The selected expression must match both its installed cache and a fresh
direct rendering of the original typed AST: a cache present before source capture
can already carry the same source tag, so that tag alone proves no rendering.

The detached `concatenation_source_declaration` preserves original `allocation`,
`sum`, ordered repeated `source_names`, selected expression, decimal-string width,
packed rank and optional symbolic range. `source_profile` retains the shared
SystemVerilog source profile independently of the canonical actual target language.
Every original term supplies its own width contract to target range rendering.
Original source/event/map/row/epoch and renderer identities must survive all
callbacks, including equal holder substitutions; the final fence invokes no
semantic getters. Results retain no caller graph or weak row-view ownership.

This source preparation emits no HDL. Complete physical namespace/declaration
proof uses the separate target join below; live emission, final ledgers and full
qualification remain separate obligations.
The focused regression is `t/2294-concatenation-source-declarations.t`; exact
predecessor, defect controls and native replay are owned by
`docs/audits/concat-source-declarations-20261031/replay.py`.

`DirectDeclaredWidthSupport->prepare_concatenation_intermediate_range` takes the
same source arguments plus complete plain `target_namespace` and
`target_declarations` records. Canonical namespace and declaration validation
checks complete membership, physical identifiers, parameter mappings and source
agreement. The selected helper must be an unrenamed signal without another
allocation origin. Selected operands and result must be unsigned and have no
declared type or state model; module and operand renaming currently refuse.

Independent current declarations reproduce every ordered source-sum term,
including repeated operands, explicit literal widths and width-one vector rank.
The actual target language selects fresh canonical range rendering. The target
root equals the separate current source intent; the detached result additionally
contains ordered `operand_targets` and complete target namespace/declarations.
Bounded raw snapshots precede semantic reads. Final getter-free checks reject
changed source/holder/renderer state and any changed target value or container
identity, including equal replacements hidden by unchanged range text.

`t/2295-concatenation-target-ranges.t` covers native fixed emission records and
proposed matching numeric records for mutable sources whose live emitter still
refuses. Preparation attests neither record producer origin nor actual emission.
Its focused predecessor and bad-owner replay is
`docs/audits/concat-target-ranges-20261031/replay.py`. Actual expression/declaration
writers, final ledgers, VHDL and full external/publication qualification remain open.

The standalone typed `ExpressionNamer` definition API retains its original Core
AST and selected numeric width; it is not a source-width provenance protocol.
For the retained required native guard/RHS profiles, current source preparation
joins original factorizer/Core candidates. A separate named-definition protocol
requires an observed required producer before admission. This bounded exclusion
says nothing about arbitrary external or dynamic callers. Backend inference and
collection must still establish their own current generation event before sum
proof or emission can consume these source contracts.

The [generation-boundary replay](../../../docs/audits/concat-generation-boundaries-20261030/replay.py)
qualifies original source frames through actual normalization, inference,
publication, registry replacement and collection. Native/cache widths bypass
intrinsic inference; recovery, metadata and late nonoperand changes revoke the
original frames. That historical receipt is bound to its original producers.

The installed width owner now imports `FSM::ConcatenationGenerationSourceSupport`.
At actual epoch/view binding it freezes getter-free inputs for every candidate
before the first canonical getter, then prepares each original source holder.
`concatenation_generation_sources(NAME, ROW)` revalidates that same source,
actual owner/row/AST/view/epoch and initial registry identity. Getter mutation,
copied/foreign rows, unsupported or cached initial profiles and expired views
withhold. Abort and new generations clear holders; a repeated bind in the same
epoch cannot recapture after failure. Returned plain data retains no caller
objects or row view. Initial registry replacement invalidates this source frame;
owned event carry is a separate protocol.
The [source-freeze regression](../../../t/2279-concatenation-generation-sources.t)
checks actual two-candidate callbacks and same-backend failure/recovery; complete
native products and exact predecessor evidence retain in
`docs/audits/concat-source-freeze-20261030/`. This grants source observation only.
The installed resolver now uses `FSM::ConcatenationInferenceSupport` for a
separate first unresolved `concatenation_sum_inference` event. Before metadata
callbacks it observes the complete bounded merged/allocator/initial-registry rows
against the original source freeze. The actual typed inference branch rechecks
that input before and after inference, including the exact AST returned by
recovery and actually passed to inference. An equal-sum foreign return cannot
borrow the unchanged stored row's identity. Only its own subsequent width/source
writes may change it. `concatenation_inference_event(NAME, ROW)` returns detached
`kind`, independently selected numeric `selected_width` and ordered canonical
`source_contract`. Independent fixed/mutable operand plans, nested/repeated slots
and explicit literal widths retain their distinct meanings.

Equal native/cache widths, scalar fallbacks, unknown literal widths, constraints,
changed metadata/sources/revisions and foreign or expired identities cannot mint.
Repeated resolver reads carry only a still-current installed event through their
own revision and width/source writes. Abort/reset/reuse clears events; holders
retain no caller graph. The raw observer's restored-scalar-write limitation still
applies. Numeric agreement supplies no symbolic sum-range proof. The actual
normalizer now checkpoints and withholds the event before publishing the merged
row's exact `width` and `width_source` into the allocator and registered rows.
Only successful publication and complete original source/metadata revalidation
restore that same event. Wrong width/source values, unrelated metadata, equal
object/container replacements, late getter mutations and throwing callbacks
cannot refresh it; a clean later cache read cannot remint spent authority.
The actual typed renderer now carries the event through only its scalar
`rendered_expression` return and original `rendered_expression_source`. It binds
the actual original runtime AST before and after rendering, including the nested
call from dependency resolution. Cached no-write reads preserve currentness;
foreign AST returns, source/metadata changes and renderer exceptions cannot
refresh it. Cleaned/compatibility rendering fallbacks gain no authority.
Dependency resolution now withholds a held event after nested rendering and
before runtime recovery, extraction and fallback callbacks. It checks the
complete original input before final publication can overwrite callback changes,
then binds the actual new `dependency_signal_names` array, exact ordered returned
names and original `dependency_source`. Only the selected
`rendered_expression_fallback` tag qualifies; other fallback paths retain ordinary
numeric behavior without event authority. Cached reads preserve the same array;
missing/stale proof, equal copied arrays, unrelated metadata/source mutations,
late getters and throwing callbacks cannot refresh or remint.
Complete-view bulk live-usage priming now removes all original event holders before
any getter or traversal callback, binds exact installed membership and row identities,
and checks the whole original transaction before annotation writes can hide changes.
It admits only the actual computed substitution/final-use booleans and derived
state/source. Cached rows receive no writes. After all assignments, semantic checks
finish with a getter-free whole-view/source barrier before events restore together.
An earlier root or later getter cannot bless another changed row; missing/stale proof,
copied/partial views, unrelated mutations and exceptions cannot refresh or remint.
The single-row fallback now shares that transaction across its two actual queries.
It checks the supplied row's installed identity, validates before writes can hide
callback changes, and admits only that row's exact computed annotations. Other
uncached rows receive no writes. Invalid-name defaults and cached no-write reads
return before taking a transaction. Foreign rows, stale/missing proof, query errors
and late cross-row changes cannot refresh or remint; a clean new generation recovers.
Bulk, fallback and mixed fallback-then-bulk paths are jointly checked through the
actual metadata and public normalization exits. Original events and annotations,
scalar/list/void context, failure cleanup, fresh-generation recovery and weak view
lifetimes preserve. The complete annotation sequence also preserves the original
event and merged/allocator/initial-registry/source identities for the selected
fixed and mutable guards, ordered/repeated sources, nested explicit literals and
width-one rank. The selected inline RHS profiles expose no concatenation candidate;
they supply no helper-event authority. Unowned changes during rendering cannot
borrow later annotations, and original errors clear partial events before clean
backend reuse. This pass grants no completed collection policy.
Actual registry synchronization now checkpoints paired original source/intrinsic
holders before graph and copy callbacks. It predicts the complete existing,
merged and `name` copy, binds the actual installed map/row identities, and keeps
the original canonical source observations and contracts. Both installed proof
maps remain withheld through semantic validation and a final whole-view raw
barrier. Ordinary merge preserves independent existing metadata; reset drops it
according to the existing copy contract. Missing/stale/unpaired proof, copied
views, equal object replacements, partial/extra installs, changed nested metadata,
proof-map interference and late source/getter mutations cannot refresh. Rejection
clears partial proof; original callback exceptions and clean backend reuse preserve.
Optional providers retain the original graph callback's scalar/list/void contexts
and exact returned values, including the absent-provider branch.
`factorized_concatenation_width_allocation(NAME, ROW)` now returns that same
original detached numeric record only after successful normalization, pruning
and final registry publication in the current epoch. Completion removes missing
or stale events, then rechecks source and row state without getters after its
semantic reads. It never recaptures source or mints from equal numeric/cache
widths. Current original rows and their weak canonical map must still be owned;
the actual prepared block extends that map's lifetime, while detached records
and retained rows alone do not. Failure, reset, new generations and source/row
changes withhold policy; a clean backend generation can recover.
The selected inline RHS profiles have no helper candidates. Mutable guards
reach completed numeric collection but still refuse the unproved symbolic sum
at declaration time. Fixed declaration rendering passes a distinct filtered map
to the resolver. Held original events now survive a bounded plain subset whose
members alias the actual canonical rows. The supplied map identity and complete
key/member identities are frozen before allocation getters and checked after
all semantic callbacks; numeric resolution still consumes the supplied map.
Only proof revalidation uses the original canonical map. The candidate event
stays withheld until a final getter-free projection and canonical source/row
barrier succeeds. Missing proof, copied/foreign rows, changed subset membership,
late source/registry/proof-map changes and native metadata cannot mint or refresh
it. Non-map or oversized projections refuse carry without relaxing the ordinary
numeric path. A distinct plain map of actual rows may qualify; that property
does not attest prepared-block producer origin or physical target membership.

`t/2293-concatenation-filtered-projections.t` follows actual fixed declaration
calls in both Verilog-family backends, early and late callback changes, absent
proof, native metadata, canonical weak lifetime and clean backend reuse.
`docs/audits/concat-filtered-projections-20261031/replay.py` reproduces the
predecessor's actual event loss and rejects controls that omit the final
projection comparison or refresh its entry snapshot after getters. Complete
native caller/HDL/declaration/refusal products preserve with Date-only
normalization. The getter supplies current collection policy through these
qualified resolver writes; symbolic target plans, declarations and final
emitted ledgers, unknown literal sizing and full qualification remain open. The [event regression](../../../t/2280-concatenation-inference-events.t)
and [native/predecessor replay](../../../docs/audits/concat-inference-events-20261031/replay.py)
retain focused currentness, refusal, lifecycle and complete native product evidence.
The [returned-AST control](../../../docs/audits/concat-inference-runtime-20261031/replay.py)
retains the identical failing/passing regression and native conservation proof.
The [publication regression](../../../t/2281-concatenation-width-publication.t) and
[exact predecessor/native replay](../../../docs/audits/concat-width-publication-20261031/replay.py)
qualify only the owned width publication and retain complete native products.
The [typed-render regression](../../../t/2282-concatenation-render-events.t) and
[render predecessor/native replay](../../../docs/audits/concat-render-events-20261031/replay.py)
retain its focused carry/refusal and complete product evidence.
The [dependency regression](../../../t/2283-concatenation-dependency-events.t) and
[dependency predecessor/native replay](../../../docs/audits/concat-dependency-events-20261031/replay.py)
retain exact array/ordered-return, callback refusal and native conservation evidence.
The [bulk live-usage regression](../../../t/2284-concatenation-bulk-live-usage.t) and
[predecessor/native replay](../../../docs/audits/concat-bulk-live-usage-20261031/replay.py)
retain actual multi-row/root, mixed cache, cross-row callback and native preservation
checks. The [single-row fallback regression](../../../t/2285-concatenation-fallback-live-usage.t)
and [predecessor/native replay](../../../docs/audits/concat-fallback-live-usage-20261031/replay.py)
qualify actual query order, independent usage roots, cached reads, hostile callbacks
and weak lifetimes. These are focused annotation checks; completion is qualified below.
The [normalization join regression](../../../t/2286-concatenation-normalization-live-usage.t)
and [native/prerequisite replay](../../../docs/audits/concat-normalization-live-usage-20261031/replay.py)
retain both actual exits, late cached-callback refusal and original-error cleanup.
The [annotation closure regression](../../../t/2287-concatenation-annotation-closure.t)
and [native conservation replay](../../../docs/audits/concat-annotation-closure-20261031/replay.py)
join the full sequence to these actual guard/RHS boundaries. This is focused
integration qualification; generic ranges and external execution remain open.
The [registry carry regression](../../../t/2288-concatenation-registry-carry.t) and
[exact predecessor/native replay](../../../docs/audits/concat-registry-carry-20261031/replay.py)
qualify actual registry reset and merge with paired source/event preservation,
hostile callbacks and weak lifetimes. Source-only frames cannot mint a new event.
The [completion regression](../../../t/2289-concatenation-policy-completion.t) and
[predecessor/native replay](../../../docs/audits/concat-policy-completion-20261031/replay.py)
check actual completion/prepared ownership, stale/removed proof, late cross-row
callbacks, failure/reset/reuse and detached returns. The dated original replay
retains the historical filtered-map revocation; T2293 qualifies its current repair.
An isolated missing-final-barrier control must fail the late-callback check.

Numeric shift transfer is repaired in the shared Core width walk, named Core and
runtime widths, stored named definitions and runtime/substituted intermediate
inference. Canonical shift operators and their published aliases follow the left
operand's width independently of the amount width. An unknown left width remains
unknown; width-only inference need not visit or validate the amount expression.
`t/2274-shift-width-transfer.t` distinguishes this rule from an operand maximum,
checks nested concatenation sums and preserves actual fixed scalar/vector helper
declarations, complete shift expressions, amount declarations and caller products
in both Verilog-family backends. The same corrected regression fails against exact
predecessor modules. This numeric repair establishes no generic shift provenance,
mutable declaration proof, signed runtime or external compiler qualification.

Run the bounded source proof and live-emission checks with:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2247-computed-source-binary-proof.t t/2248-source-tree-symbolic-range-emission.t t/2249-source-bitwise-family-closure.t
```

Completed literal source intent now closes the former final-width gap: with `(W 8)`,
`(& A B 3)` keeps an unknown Core literal width and helper placeholder 1, while
SystemVerilog inference selects width 32. Final declaration agreement independently
rederives that target width from current completed source intent. The original
Core and caller widths remain intact. Explicit literal sizes preserve their own
floors, and every existing signedness, type, state and auxiliary-origin check
remains in force. Literal observation supplies no VHDL exception. All source
observations recheck before a final raw whole-set barrier, so a later source
getter cannot silently change an earlier proved literal. The focused
`t/2269-literal-final-declaration-agreement.t` checks actual direct/nested
fixed/mutable emission, false placeholder matches and those preserved boundaries.
Full feature, external compiler/override/runtime and public qualification remain
deferred; the earlier diagnosis is retained as historical evidence.
Read the final source/target proof, real predecessor and raw-barrier controls with
`python3 -B docs/audits/literal-final-agreement-20261030/verify.py --qualify`.

The preparatory `FSM::CoreExpressionWidthSupport->infer_width` contract now
centralizes the direct builder's exact-width walk. Unsized literals stay unknown
unless a caller explicitly supplies an `unsized_literal_width` callback. The
callback receives detached raw `{value, radix, width}` data; it cannot replace an
explicit literal width or assign a width to an unknown expression class. Scalar
wrappers keep their result width. Active cycles and over-bound walks stay unknown.
References read selected Signal widths; they do not prove helper ancestry or
that a compatibility placeholder is exact.

```perl
use FSM::CoreAST;
use FSM::CoreExpressionWidthSupport;
my $literal = FSM::CoreAST::Literal->new('3');
die "unexpected Core default\n"
    if defined FSM::CoreExpressionWidthSupport->infer_width($literal);
# Illustrative caller policy; the shared Core walk supplies no target default.
my $width = FSM::CoreExpressionWidthSupport->infer_width($literal,
    unsized_literal_width => sub { return 32 });
die "caller policy lost\n" unless $width == 32;
```

The Core walk alone does not authorize target generation. The completed source,
numeric, range, emission and final-agreement consumers described here now qualify
bounded fixed and mutable literal helpers. The focused Core/source controls in
`t/2250-core-expression-width-contract.t` retain unknown target-neutral widths
while checking successful target generation and unchanged caller data.

The retained predecessor defect in this family is a nested fixed-width helper
truncating an unsized literal's high bit in a narrower parent helper. The retained
strict CLI reproduction and source-width diagnosis are authenticated by
`docs/audits/literal-width-ownership-20261029/verify.py`. At that retained revision,
ordinary generation and injected declaration capture had different outcomes;
the latter could refuse the source. Current source allocation, nested unknown-width
propagation, target inference and final declaration agreement repair that defect.
The later source-qualified capture at
`docs/audits/literal-target-consumers-20261030/verify.py --qualify` preserves the
strict CLI/trace, explicit-size control and independent mask algebra. Its captured
parent route read a generated child's nominal Core width before resolving that
child's backend row. The live numeric consumer described below repairs that
ordering; this receipt remains historical evidence of the earlier defect.
The saved reader starts no compiler or HDL execution; its optional `--current`
checks only the named producer identities, not complete current behavior.

The private target-only
`FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport`
now provides `prepare(signal => $actual_core_helper)` and
`current(signal => $actual_core_helper, observation => $saved)`. It uses one
bounded completed-source capture and shared Core inference with explicit typed
child resolutions. Unsized literals contribute the existing SystemVerilog floor
of 32; explicit sizes keep their independent floors. The detached observation
separates `literal_floor`, `leaf_floor` and `selected_width`, retaining ordered
raw literals, original leaf width metadata, helper widths, typed reference edges
and the complete original source capsule. Generated placeholder widths never
become independent leaf floors. Missing, stale, foreign, constrained or over-bound
source intent withholds; matching writes during inference also withhold.
This preparation supplies no backend row/epoch proof, generic range or final
declaration agreement. Separate numeric and emission consumers are now installed;
final agreement uses a separate consumer. `t/2261-target-source-literal-width.t`
covers the completed Parser/facade sources, explicit and independent floors,
raw kinds, repeated edges and mutation barriers without HDL execution.

The literal requirement selector follows typed operators whose literals can
contribute to the helper's data-width maximum. Comparison and logical-negation
operands terminate that search: their scalar results do not inherit input or
literal widths. This restores AHB guards such as `(| (== HTRANS 2'b10)
(== HTRANS 2'b11))` through the existing scalar-width path. Every physical child
helper is still selected independently, so a data-literal helper inside a logical
parent retains its original proof requirement. An installed holder always
requires proof, and removing a holder from a true data-literal expression cannot
select numeric fallback. `t/2297-scalar-literal-guard-emission.t` checks scalar
widths, nested children, mutable scalar behavior and still-required data proof;
the retained old-selector control reproduces the false positive.

Fixed inline logical shifts within literal-containing bitwise expressions now
preserve data widths through the same original-source and emitted-target proof.
For `(| (<< A 1) B)`, with fixed `A` eight bits and `B` one bit, the helper
is eight bits: the unsized shift amount supplies no data-width floor.
For `(| (<< A 1) 0)`, the data literal `0` contributes the existing target
unsized floor, so the helper is 32 bits before assignment sizing. Explicit data
literal sizes remain independent. A 128-bit amount still does not widen the data.
Every original amount node remains fenced; editing it revokes the proof.

This profile requires fixed, plain unsigned sources and a bitwise root. Mutable,
opaque, combined-width, signed and typed sources remain refused; standalone shift
allocation belongs to its separate work. Ordinary output marking uses the existing
named role transition, and assignment sizing preserves an unresolved original
inline-shift helper until target sizing. Input-named sampled storage is joined
through its actual normalized assignment LHS when absent from the module signal
map. Replacing that LHS with an equal-looking object invalidates the saved join.
`t/2296-inline-shift-literal-emission.t` checks actual Verilog-family declarations,
self-updates, data/amount floors, storage ownership and mutation refusals.

```perl
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;
my $text = '(?fsm:target_literal (+size (A 8) (B 16) (DATA 1) (OTHER 1))
  (idle (<(^ (| A 256) B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
my ($root) = grep {defined($_->source_literal_width_allocation)
    && $_->driving_ast->operator eq '^'} values %{$module->signals};
my $observation = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
    ->prepare(signal => $root);
die "missing target observation\n" unless $observation;
print join(' ', @{$observation}{qw(selected_width literal_floor leaf_floor)}), "\n";
```

This prints `32 32 16`. It observes the completed source graph.

`prepare_inference(width_support => $installed_owner, signal_name => $name,
signal_info => $actual_row, signal_registry => $consumer_rows)` joins this
observation to the installed backend, current normalization epoch, canonical
collected row, registered row and actual module source membership. Independent
row constraints and complete AST ownership must agree. It rechecks target state
after source reads. `current_inference` additionally compares a saved frame;
changed epochs, row identities, raw kinds or constraints withhold saved authority.
Frames contain detached data and confer no completed allocation or range proof.

The live width resolver selects this qualified result before native or cached
compatibility widths and records `source_literal_intent`. Nested source references
also consume the actual target row before their nominal Core widths. Thus the
fixed nested high-bit witness keeps its bit through both child and parent;
explicit literal sizes and wider independent leaves preserve their own floors.
Core source widths and original caller data stay unchanged. Missing or unsupported
joins supply no literal authority. `t/2262-target-source-literal-numeric-inference.t`
checks actual fixed generation, mutable numeric preparation, independent mask
algebra and hostile row/source/epoch changes. Separate emission ledgers now consume
generic ranges; final agreement now consumes the completed source observation. These are
focused source and generated-text checks; external HDL execution and full feature
qualification remain deferred. Saved evidence can be read without source or HDL
execution with `python3 -B docs/audits/literal-numeric-inference-20261030/verify.py --qualify`;
its optional `--current` checks only the named producer identities.

The shared Verilog-family `WidthExpressionEmitter->lower_maximum_range` now
renders a maximum over independently prepared width contracts and fixed floors.
Pass `operands => [{width => $observed, width_contract => $prepared_contract},
{width => $fixed_floor}]` with the existing captured `environment` and
`target_language`. Every supplied contract retains its actual ordered lookups,
scope and arithmetic checks, and must reproduce its own observed width even
when another default dominates it. Mutable terms remain conditional branches
under external overrides; equal defaults cannot merge independent parameters.
The result stays a packed vector at a one-bit default. Fixed-only maxima fold.
Inputs and output text have explicit bounds; oversize inputs or mismatched
observed operand values refuse. `t/2263-verilog-prepared-maximum-range.t` interprets emitted
conditional ranges under distinguishing overrides and checks hostile inputs.
This is a prepared rendering kernel. The separate source adapter below joins
literal observations to original generic contracts; separate emission ledgers now
consume that intent; final declaration agreement remains independently proved.

The separate `WidthExpressionEmitter->lower_sum_range` composes the same prepared
operand contracts by ordered addition. Every repeated slot contributes; a fixed
width is an exact summand. Independent parameters retain their names even when
their defaults agree. Each operand still passes canonical lookup, scope and
arithmetic checks and must match its own observed width. Fixed-only sums fold
with exact integer arithmetic. A single width-one operand remains a packed vector.
The sum uses the same bounded input and rendered-text limits as the maximum.

For example, this private prepared-kernel call retains `W + 3 + X + W`:

```perl
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;
my $scope = {kind => 'direct_module', owner => 'sum_example'};
my $environment = {scope => $scope, declaration_order => [qw(W X)],
    parameters => {map {$_ => {value_payload => {kind => 'scalar', payload => '1'}}} qw(W X)}};
my $term = sub {
    my ($name) = @_;
    return {width => 1, width_contract => {scope => $scope,
        expression => ['param', $name], references => [{kind => 'parameter', token => $name}]}};
};
my $range = FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_sum_range(
    environment => $environment, target_language => 'systemverilog',
    operands => [$term->('W'), {width => 3}, $term->('X'), $term->('W')]);
# $range is '[((((W + 3) + X) + W) - 1):0] '
```

Run Perl snippets with `perl -Iperl` from the repository root. The
`t/2290-verilog-prepared-sum-range.t` regression interprets the
actual emitted syntax under distinguishing parameter values. Its retained
`docs/audits/concat-sum-kernel-20261031/replay.py` producer also
checks native controls that substitute a maximum, omit a slot or merge equal
defaults. This private renderer accepts prepared contracts; current concatenation
source sums, completed backend events, target declarations and emitted ledgers
still require their separate joins. Generic concatenation emission and external
compiler/override/runtime qualification remain open.

`SourceLiteralWidthSupport->prepare_range` now joins the actual numeric frame to
canonical direct module preparation and the proved original parameter environment.
Use the `prepare_inference` arguments plus a Verilog-family `target_language`.
Every original mutable leaf supplies its own prepared width contract; fixed
leaves and the literal floor remain separate operands of the shared maximum.
Independent equal-default parameter names therefore survive in the prepared range.
The detached record carries the complete numeric observation, source plan,
environment, ordered operands and symbolic packed range. `current_range` also
requires an exact saved `observation`. A final numeric recheck and raw module,
parameter-map and assignment-source barrier withhold late changes. A strict UTF-8
digest binds this complete source state and its actual namespace identities into
the saved range; matching namespace replacements cannot reuse it. Fixed-only
sources, foreign targets and unproved or over-bound joins withhold this generic
preparation. `t/2264-target-source-literal-generic-range.t` covers actual installed
rows, independent wider floors, source conservation and a late parameter change.
Selected declaration/event proof and live ledgers have separate consumers below;
this preparation alone grants no generation or final Core agreement.

`prepare_selection` takes the same actual inputs plus the root `expression`
selected for emission. It joins every typed child helper to its own current
numeric frame, installed recovery/AST-rendering owners and canonical rows.
Defining, runtime and cached ASTs must retain actual source identity; fresh typed
rendering must equal selected text. Matching cached text alone supplies no proof.
The detached record retains root numeric/range intent and a complete physical
helper inventory in children-before-parent order. Original capsules separately
preserve ordered repeated typed edges and raw literal kinds. Mutable leaves
require the generic source-range proof; fixed observations invent no mutable
relationship. After all rendering reads, numeric rechecks and final raw source,
owner and row/text barriers reject late changes to earlier children.
`current_selection` additionally compares a saved `observation` with the complete
fresh result. `t/2265-target-source-literal-selection.t` covers direct/nested,
fixed/mutable and explicit/wider floors, altered caches, foreign ASTs, owner/row/
epoch changes and late child-cache writes. This qualifies private selected
expression intent; actual captured declarations/events and live range ledgers have
separate consumers below. Final declaration agreement has its own source observer;
compiler/runtime/full qualification is pending.

`prepare_targets` adds complete actual `target_namespace`, `target_declarations`
and `target_intermediates` snapshots to the selection arguments. It reuses canonical
namespace closure, then independently checks every selected helper and original
leaf against its unrenamed plain unsigned physical declaration and numeric maximum.
Every helper assignment must match its own fresh typed expression and existing
ordered binary origin/allocation, when present. Missing events, conflicting
families, wrong roles and changed widths/types refuse. The detached result retains
complete selection and generic operands/floors, physical nodes in postorder,
ordered repeated typed edges and duplicate-preserving original leaf targets.
`current_targets` also compares a saved `observation`. Full selection re-observation
and final raw source, row, owner and complete target-input barriers withhold late
mutations. Snapshots remain data inputs; this does not prove collector provenance
or emitted range text. `t/2267-target-source-literal-declarations.t` uses ordinary
fixed emission and explicit test-only mutable source/binary selector seams to
observe real numeric emitter records. Mutable record-contract checks do not
qualify normal generic generation. Live ledgers now have the separate actual
consumer below; final Core/source-width agreement remains independent.
Read the saved proof and hostile-record checks with
`python3 -B docs/audits/literal-target-proof-20261030/verify.py --qualify`.

Actual Verilog-family generation now records each literal helper's complete
selected declaration intent and its exact assignment expression in separate
per-generation ledgers. Fixed helpers retain numeric ranges; mutable helpers keep
the independent original width contracts and literal floor. Required coverage
comes from selected typed source rows, independently of either ledger or event
membership. Final assembly re-proves complete physical targets and compares every
record, range and expression. Missing policy or events, extra ledger members and
changed text cannot select a fallback. A raw fence spans emission through the last
final proof, including earlier roots that a later proof might mutate. Any exception
invalidates capture; fresh same-backend generation starts with new ledgers.

This admits bounded explicitly sized literal cases such as
`(^ (| A 9'b100000000) B)` with independently parameterized `A` and `B` widths.
For example, save this as `.artifacts/literal_ranges.fsm`:

```lisp
(?fsm:literal_ranges
  (+params (W 1) (X 1))
  (+size (A (param W)) (B (param X)) (DATA 1) (OTHER 1))
  (idle
    (<(^ (| A 9'b100000000) B) (= (DATA 1)) (= (OTHER 1)))
    (-> idle)))
```

```bash
./bin/fsmgen --strict --output .artifacts/sv/literal_ranges.sv .artifacts/literal_ranges.fsm
```

The child range retains `W` and the literal floor of 9; the parent also retains
the independent `X` dependency. A one-bit explicit literal similarly keeps vector
rank when the default maximum is one. The canonical source view is available
before normalization can fold default-one expressions and is refreshed after
helper discovery; complete target proof still follows actual emission.
Unsized mutable literals now complete the separate final declaration check through
current source observation; the emission ledger alone grants no numeric authority.
Run the focused actual-emitter and final-agreement controls:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/2268-target-source-literal-emission.t
scripts/run_with_ram_guard.sh -- prove -Iperl t/2269-literal-final-declaration-agreement.t
scripts/run_with_ram_guard.sh -- prove -Iperl t/2270-literal-final-atomic-reuse.t
```

These checks qualify native generated declarations/expressions, complete capture,
atomic refusals and reuse. External compiler/override/runtime, full feature and
public corpus/API/MCP qualification remain deferred.

The bounded repair closure also exercises ordinary generation without a supplied
declaration capture. `t/2271-literal-source-target-closure.t` checks the original
`(& A B 3)` and nested `(^ (| A 256) B)` expressions in both Verilog-family
backends, plus explicit literal sizes, wider independent leaves and one-bit
defaults. It reads complete assignments and wire ranges directly from HDL and
interprets the emitted range arithmetic against independent source maxima.
Re-evaluating that text with different parameter values checks the preserved
relationship; it is not external elaboration or HDL execution. Caller data,
unknown Core widths and original parameter bindings remain unchanged.
The retained n-ary literal child/parent case also compares the distinguishing
high bit with the actual declaration masks and a deliberately narrowed historical
mask. This establishes declaration algebra rather than generated-HDL execution.

DirectDeclaredWidthSupport joins module Signals and normalized assignment-target
SignalRefs, refusing distinct objects claiming one physical name. Copied parameter
maps pass canonical observation proof; coherent bindings join the bounded adapter
under original lexical scope. Fixed/type/static controls preserve. Independent
combined mutable requirements or stale/missing bindings refuse. Detached plans
retain no Core/backend owner. prepare_declarations joins actual namespace/declaration
snapshots: mapped parameter/Signal membership, reserved names/collisions, numeric
default width, signedness and type. VHDL folds case. Selected mutable root renaming
refuses; physical module/Signal mapping stays independent of source ownership.
Detached target plans identify symbolic port/storage ranges and independent fixed
rows. Focused numeric rendered widths independently match planner metadata.

The private `DirectDeclaredWidthSupport->prepare_target_namespace` now exposes
the canonical structural checks shared with `prepare_declarations`: complete
module/parameter mappings, role/name/declaration closure and unique physical
source membership. Its detached result retains the source plan, target namespace,
actual rows, roles and source-target map. This supplies no source numeric/type/
state/helper-origin, currentness or range proof. The full declaration validator
still applies all those existing agreement checks. `t/2266-direct-target-namespace.t`
distinguishes valid namespaces from mismatched widths/types; existing complete
plans and refusal controls remain covered by `t/2173-direct-width-target-plans.t`.
This namespace-only preparation grants no numeric authority; literal target proof
and final declaration agreement use the separate consumers described above.

The private `FSM::SourceLiteralWidthAllocationSupport` holder now preserves
raw literal `{value, width, radix}` and a nullable exact allocation width.
Unknown exact width remains distinct from a helper's nominal scalar width;
explicit literal sizes remain independent floors. Its bounded direct bitwise
profile validates actual helper, AST and independent leaf identities, raw JSON
kinds and tracked source revisions. Matching writes, foreign object lifetimes
and late source mutations withhold intent. The detached holder retains no
owners. `t/2251-source-literal-width-holder.t` includes an isolated bad-barrier
control. The builder now journals actual fresh direct literal allocations in
an optional `source_literal_events` bucket. Fresh name ownership and actual
registry membership distinguish those births from equal existing or foreign
objects. The journal preserves parsed Core literal kinds, independently of the
caller's token spelling; old binary/tree buckets preserve. T2252 exercises actual
fixed/mutable parsing and failed-capture reuse. Exact bare-reference, role and
final width-metadata operations now transport only a still-current holder whose
complete source state differs by the named operation and its tracked revision.
Independent constraints, extra writes and foreign registry membership withhold;
escaped old holders stay stale. T2253 checks direct Parser and facade completion,
actual mutable leaf metadata and repeated/shared source slots. Completed direct
Parser calls now publish `source_literal_width_allocation` on the actual Core
helper; facade calls wait through role and interface analysis too. The getter
returns detached raw source intent. An explicit setter clears prior allocation
intent before replacement, including on failure; the common allocation clear
revokes this family on relevant matching writes. Private completion preserves
semantic revisions and requires the original staged epoch plus final registry
membership after source reads. Parse failure, partial publication and reuse clear
old or partial policy. Direct Parser keeps its registry/AST boundary; facade
completion also attaches those actual Signals to the module.

```perl
use Lispish;
use FSM::Adapter::FSMGenFull;
my $text = '(?fsm:literal_intent (+size (A 8) (B 8) (DATA 1) (OTHER 1))
  (idle (<(| A B 256) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
my $adapter = FSM::Adapter::FSMGenFull->new;
my $module = $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text));
my @helpers = grep { defined $_->source_literal_width_allocation }
    values %{$adapter->{signal_manager}{signal_registry}};
die "missing direct literal intent\n" unless @helpers == 1;
my $intent = $helpers[0]->source_literal_width_allocation;
die "unexpected exact width\n" if defined $intent->{selected_width};
die "nominal width changed\n" unless $helpers[0]->width == 1;
```

T2254 checks both completion paths, raw kinds, explicit floors, revocation,
failure/reuse and distinguishing stale-epoch/foreign-registry controls. This
internal policy supplies no backend default or target sizing. The separate target
consumers above repair fixed nested truncation; this policy alone admits no new
public semantic schema, MCP field, source grammar or HDL profile.

The shared width walk now has a preparatory `source_reference_width` option.
It passes the actual whole Core SignalRef to an explicit source resolver, so
that caller can join its current source ownership. Returning `undef` preserves
the selected width; a closed `{width => undef}` deliberately withholds it.
A positive `{width => VALUE}` resolves explicitly; malformed results withhold
and callback exceptions propagate. Independent authored references must stay
unoverridden. Slices, explicit literals and scalar-result wrappers keep their
own rules, and the walk's cycle/depth/occurrence bounds still apply.

```perl
use FSM::CoreAST;
use FSM::CoreExpressionWidthSupport;
my $helper = FSM::CoreAST::Signal->new(name => 'H', width => 1);
my $reference = FSM::CoreAST::SignalRef->new($helper);
my $width = FSM::CoreExpressionWidthSupport->infer_width($reference,
    source_reference_width => sub { return {width => undef} });
die "unresolved source borrowed nominal width\n" if defined $width;
die "source width changed\n" unless $helper->width == 1;
```

This example supplies an illustrative caller decision, not source provenance.
T2255 separately exercises actual completed literal policy and revoked-source
controls. During source capture, the builder now resolves actual generated
references from current local allocation holders before registering a parent.
An unresolved literal child keeps its parent's exact width unknown even beside
a wider declared leaf. Missing or revoked generated intent cannot lend its
nominal width to an old binary maximum policy. Current nonliteral binary/tree
proofs, independent declared widths and scalar wrappers keep their own rules.

The literal holder has a separate opt-in `children` boundary for prepared nested
ownership. `{phase => 'birth', lookup => sub { ... }}` supplies a current child
holder for each actual whole Core reference; the capture owner still attests
fresh birth. `{phase => 'completed'}` reads only the actual installed child
policy and permits no callback. A provisional birth cannot supply completed
policy. Every generated child must have its own current literal contract.
Missing, foreign, stale or independently constrained child intent withholds.
The holder expands original raw source syntax while binding each typed edge
separately, including repeated/shared child slots. One depth and occurrence
budget spans the complete expansion. Late writes and removed completed policy
withhold. Returned capsules retain no source owners or lookup callbacks.

```perl
use FSM::CoreAST;
use FSM::SourceLiteralWidthAllocationSupport;
my $a = FSM::CoreAST::Signal->new(name => 'A', width => 8);
my $literal = FSM::CoreAST::Literal->new('256', radix => 'decimal');
my $tree = ['|', ['signal', 'A'],
    ['literal', {value => '256', width => undef, radix => 'decimal'}]];
my $child = FSM::CoreAST::Signal->new(name => 'CHILD', width => 1,
    type => 'wire', attributes => {is_intermediate => 1},
    driving_ast => FSM::CoreAST::BinaryOp->new('|',
        FSM::CoreAST::SignalRef->new($a), $literal));
$child->set_source_literal_width_allocation({kind => 'source_literal_operand_max',
    selected_width => undef, expression_tree => $tree});
my $parent = FSM::CoreAST::Signal->new(name => 'PARENT', width => 1,
    type => 'wire', attributes => {is_intermediate => 1},
    driving_ast => FSM::CoreAST::BinaryOp->new('^',
        FSM::CoreAST::SignalRef->new($child), FSM::CoreAST::SignalRef->new($a)));
my $holder = FSM::SourceLiteralWidthAllocationSupport->prepare_core(
    signal => $parent, track => 1, children => {phase => 'completed'},
    record => {kind => 'source_literal_operand_max', selected_width => undef,
        expression_tree => ['^', $tree, ['signal', 'A']]});
die "nested source borrowed a nominal width\n"
    if defined $holder->{record}{selected_width};
```

This constructs explicit local Core intent; it does not attest a Parser birth.
T2256 checks prepared birth/completed joins, independent floors, raw kinds,
ordered child edges, revocation and global bounds. Default direct holders retain
their prior behavior. Actual fresh nested allocations now journal their own
literal birth through this boundary. Named nested transition transport uses
the same explicit child phase.
The caller first validates current source/registry ownership, performs exactly
the named write, then refreshes affected children before their parents. Each
new child capsule must reconstruct its original complete capsule under only
that operation's revision/role/metadata delta, matching the digest held by the
original parent edge. The complete projected parent state must agree too.
An independently current replacement child cannot hide unrelated raw data,
declarations, JSON kinds or a birth/completed phase change. Old escaped holders
stay stale. Raw string data retains Unicode through strict UTF-8 capsule digests.
T2257 exercises nested and repeated edges, matching-reference and
helper roles, real mutable leaf metadata, completed-child refresh and hostile
replacement/late-write controls; an isolated missing original-child check fails.
T2258 exercises actual allocation before registration, named transport and
fixed/mutable Parser and facade completion writes, with explicit size and
independent-floor controls. Completed publication now installs children before
parents through `complete_core`: the complete current birth capsule projects
only each ordered edge's phase and original child digest into completed form.
Actual installed completed child capsules must match that whole projection.
An independently current child with equal source or width cannot replace the
original relationship, including when its record changes JSON scalar kind.
Late raw writes and removed child policy withhold; original source, birth
capsules and semantic revisions preserve. The final registry join follows all
validation reads. The Core getter validates completed nested relationships.
T2259 covers both completion paths, replacement/late-write controls and atomic
partial-publication failure/reuse. Target literal sizing and the fixed truncation
repair remain open. No source grammar or public API/MCP schema is added.
T2260 closes focused source-only repeated/shared/deeper edges and raw-object
conservation, bound refusal and detached capsule lifetime. The lifetime fixture
separately removes its known Core fanout cycles; it makes no graph leak-free claim.

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
