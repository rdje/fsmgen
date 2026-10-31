package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport;

=encoding utf8

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport - Own direct SystemVerilog intermediate-signal recovery and metadata normalization support

=head1 DESCRIPTION

Owns the bounded runtime-AST and metadata-recovery family for the older direct
generated-module SystemVerilog backend. This package centralizes:

=over 4

=item *

defining-AST and substituted runtime-AST lookup

=item *

rendered-expression recovery and caching

=item *

intermediate dependency recovery, including explicit runtime-AST-miss fallback

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport>
now narrows to filter policy over the normalized metadata this package
produces, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport>
now owns width normalization and inference, and this package owns the “figure
out the real intermediate signal payload” side of the direct backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::SourceBitwiseTreeOriginSupport;
use FSM::SourceBitwiseTreePolicySupport;

=head2 new

Construct one intermediate-signal recovery owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalRecoverySupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 resolve_intermediate_signal_defining_ast

Find the defining AST for one intermediate signal from cached metadata or the
enable graph, and cache the resolved AST back onto the signal metadata when
found.

=cut

sub resolve_intermediate_signal_defining_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{defining_ast} && blessed($signal_info->{defining_ast})) {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Using cached defining_ast for '$signal_name'", 3);
        return $signal_info->{defining_ast};
    }

    if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Using inline AST for '$signal_name'", 3);
        return $signal_info->{ast};
    }

    my $resolved_ast = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_ast($signal_name);
    if ($resolved_ast && blessed($resolved_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{defining_ast} //= $resolved_ast;
            $signal_info->{ast} //= $resolved_ast unless exists $signal_info->{ast};
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Resolved defining AST for '$signal_name' via EnableGraph", 3);
        return $resolved_ast;
    }

    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] No defining AST available for '$signal_name'", 3);
    return undef;
}

=head2 resolve_intermediate_signal_runtime_ast

Resolve the runtime AST for one intermediate signal from substituted ASTs or a
defining AST and record the result or miss metadata on the signal info.

=cut

sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{runtime_ast} && blessed($signal_info->{runtime_ast})) {
        $signal_info->{runtime_ast_resolution_state} = 'resolved' if ref($signal_info) eq 'HASH';
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Using cached runtime_ast for '$signal_name'", 3);
        return $signal_info->{runtime_ast};
    }

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && ($signal_info->{runtime_ast_resolution_state} || '') eq 'missing')
    {
        my $miss_reason = $signal_info->{runtime_ast_miss_reason} || 'unknown_miss_reason';
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Reusing cached runtime-AST miss for '$signal_name' ($miss_reason)", 3);
        return undef;
    }

    my $runtime_ast;
    my $runtime_ast_source;
    my $runtime_ast_miss_reason = 'no_ast_source';

    if ($ctx->{ast_factorizer}
        && $ctx->{ast_factorizer}->{intermediate_signals}
        && exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name})
    {
        my $substituted_ast = $ctx->{backend_sv_ast_factorization}->get_substituted_ast_for_signal($signal_name, $signal_info);
        if ($substituted_ast && blessed($substituted_ast)) {
            $runtime_ast = $substituted_ast;
            $runtime_ast_source = 'substituted_ast';
        }
    }

    if ((!$runtime_ast || !blessed($runtime_ast))) {
        my $defining_ast = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
        if ($defining_ast && blessed($defining_ast)) {
            $runtime_ast = $defining_ast;
            $runtime_ast_source = 'defining_ast';
        }
    }

    if ($runtime_ast && blessed($runtime_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{runtime_ast} = $runtime_ast;
            $signal_info->{runtime_ast_source} = $runtime_ast_source;
            $signal_info->{runtime_ast_resolution_state} = 'resolved';
            delete $signal_info->{runtime_ast_miss_reason};
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Resolved runtime AST for '$signal_name' via $runtime_ast_source", 3);
        return $runtime_ast;
    }

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{runtime_ast_resolution_state} = 'missing';
        $signal_info->{runtime_ast_miss_reason} = $runtime_ast_miss_reason;
    }

    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] No runtime AST available for '$signal_name'", 3);
    return undef;
}

=head2 render_intermediate_signal_expression

Render one intermediate signal expression from its resolved runtime AST when
available, otherwise fall back to stored compatibility expressions or the
enable-graph registry.
The default width owner carries only a held current concatenation event through
the typed renderer and its exact expression/source writes, binding the actual
original runtime AST before and after. Unrelated changes and exceptions cannot
refresh authority. Cached no-write reads retain currentness; other fallbacks and
injected legacy width providers keep their original behavior without new proof.

=cut

sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && defined($signal_info->{rendered_expression})
        && $signal_info->{rendered_expression} ne '')
    {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Using cached rendered expression for '$signal_name' via " . ($signal_info->{rendered_expression_source} || 'cache'), 3);
        return $signal_info->{rendered_expression};
    }

    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        my $runtime_ast_source = ($signal_info && ref($signal_info) eq 'HASH')
            ? ($signal_info->{runtime_ast_source} || 'runtime_ast')
            : 'runtime_ast';
        if ($signal_info
            && ref($signal_info) eq 'HASH'
            && $runtime_ast_source =~ /cleaned_/
            && defined($signal_info->{expression})
            && $signal_info->{expression} ne '')
        {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression_preserved_after_cleaned_runtime_ast';
            fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Preserving stored expression for '$signal_name' after cleaned runtime-AST recovery", 3);
            return $signal_info->{expression};
        }

        my $render = sub {
            my $expression = $ctx->{enable_graph_ast_support}->ast_to_systemverilog($runtime_ast);
            if ($signal_info && ref($signal_info) eq 'HASH') {
                $signal_info->{rendered_expression} = $expression;
                $signal_info->{rendered_expression_source} = $runtime_ast_source;
            }
            return $expression;
        };
        my $width_support = $ctx->{backend_sv_intermediate_width_support};
        my $expression = $width_support && $width_support->can('_with_concatenation_render')
            ? $width_support->_with_concatenation_render($signal_name, $signal_info, $runtime_ast, $render)
            : $render->();
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Rendered '$signal_name' from AST", 3);
        return $expression;
    }

    if ($signal_info && defined($signal_info->{expression}) && $signal_info->{expression} ne '') {
        if (ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression';
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Falling back to stored expression for '$signal_name'", 3);
        return $signal_info->{expression};
    }

    my $expression = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_expression($signal_name);
    if (defined($expression) && $expression ne '' && $signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{expression} //= $expression;
        $signal_info->{rendered_expression} = $expression;
        $signal_info->{rendered_expression_source} = 'enable_graph_expression';
    }
    return $expression;
}

sub _whole_signal_reduction ($node) {
    return unless blessed($node) && ($node->isa('FSM::AST::UnaryOp')
        || $node->isa('FSM::CoreAST::UnaryOp') || $node->isa('FSM::HDL::SubstitutedUnaryOp'));
    my $op = $node->operator;
    return unless defined($op) && !ref($op) && $op =~ /\A[&|^]\z/;
    my $name = _whole_signal_name($node->operand) or return;
    return {kind => 'scalar_reduction', operator => $op, source_name => $name};
}

sub _whole_signal_name ($operand) {
    return FSM::IntermediateWidthAllocationSupport->whole_signal_name($operand);
}

sub _whole_signal_binary_bitwise ($node) {
    my $shape = FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($node) or return;
    return {kind => 'binary_bitwise', %$shape};
}

sub _whole_signal_binary_arithmetic ($node) {
    my $shape = FSM::IntermediateWidthAllocationSupport->binary_operand_max_shape($node) or return;
    return unless $shape->{operator} =~ m{\A[+*/%\-]\z};
    return {kind => 'binary_arithmetic', %$shape};
}

=head2 scalar_reduction_origin

Return an optional detached syntactic origin for an actually emitted unary
XOR/AND/OR over one whole SignalRef. Selected defining and runtime ASTs, plus
any cached defining AST, must agree; freshly rendering the runtime AST must
equal the exact selected emitted expression. Stored text alone, conflicting
caches, logical operations and computed operands supply no origin. This does
not prove source membership, unsigned type or a symbolic consumer contract.

=cut

sub scalar_reduction_origin ($self, $signal_name, $signal_info, $expression) {
    return unless ref($signal_info) eq 'HASH' && defined($expression) && !ref($expression);
    my $runtime = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    my $defining = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
    my $origin = _whole_signal_reduction($runtime) or return;
    for my $node ($defining, map {$signal_info->{$_}} grep {exists($signal_info->{$_})} qw(ast defining_ast)) {
        my $other = _whole_signal_reduction($node) or return;
        return unless $other->{operator} eq $origin->{operator} && $other->{source_name} eq $origin->{source_name};
    }
    my $rendered = $self->{flattened_dt}{enable_graph_ast_support}->ast_to_systemverilog($runtime);
    return unless defined($rendered) && $rendered eq $expression;
    return $origin;
}

=head2 binary_bitwise_origin

Return an optional detached binary XOR/AND/OR origin with both ordered whole
SignalRef operands. Defining/runtime/cached ASTs and fresh selected rendering
must agree. Duplicate operand slots preserve; text-only, logical, literal and
compound operands gain no origin. This supplies no symbolic width/type proof.
Shared typed recognition rejects explicit Core slices and runtime state wrappers;
compatible intermediate references use their own interface without assumed
Core Signal/state methods. Fresh rendering and actual declaration membership
remain separate required joins.

=cut

sub binary_bitwise_origin ($self, $signal_name, $signal_info, $expression) {
    return $self->_binary_origin($signal_name, $signal_info, $expression, \&_whole_signal_binary_bitwise);
}

=head2 binary_arithmetic_origin

Return a separate optional C<binary_arithmetic> origin for canonical C<+>, C<->,
C<*>, C</> or C<%> over two ordered whole SignalRefs. The same defining, runtime,
cached-AST and freshly selected text checks apply as for C<binary_bitwise_origin>.
This syntactic record imposes no operand/result width relationship or symbolic
range eligibility. Literal, compound, sliced and state operands withhold it.

=cut

sub binary_arithmetic_origin ($self, $signal_name, $signal_info, $expression) {
    return $self->_binary_origin($signal_name, $signal_info, $expression, \&_whole_signal_binary_arithmetic);
}

sub _binary_origin ($self, $signal_name, $signal_info, $expression, $recognize) {
    return unless ref($signal_info) eq 'HASH' && defined($expression) && !ref($expression);
    my $runtime = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    my $defining = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
    my $origin = $recognize->($runtime) or return;
    for my $node ($defining, map {$signal_info->{$_}} grep {exists($signal_info->{$_})} qw(ast defining_ast)) {
        my $other = $recognize->($node) or return;
        return unless $other->{operator} eq $origin->{operator}
            && $other->{source_names}[0] eq $origin->{source_names}[0]
            && $other->{source_names}[1] eq $origin->{source_names}[1];
    }
    my $rendered = $self->{flattened_dt}{enable_graph_ast_support}->ast_to_systemverilog($runtime);
    return unless defined($rendered) && $rendered eq $expression;
    return $origin;
}

sub _selected_source_tree_shape ($self, $signal_name, $signal_info) {
    return unless ref($signal_info) eq 'HASH' && defined($signal_info->{source})
        && !ref($signal_info->{source}) && $signal_info->{source} eq 'fsmgen_parsing';
    my $runtime = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    my $defining = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
    my $origin = FSM::SourceBitwiseTreeOriginSupport->from_ast($runtime) or return;
    return if grep {$_ eq $signal_name} @{$origin->{source_names}};
    my $json = JSON::PP->new->canonical;
    for my $node ($defining, map {$signal_info->{$_}} grep {exists($signal_info->{$_})} qw(ast defining_ast driving_ast)) {
        my $other = FSM::SourceBitwiseTreeOriginSupport->from_ast($node) or return;
        return unless $json->encode($other) eq $json->encode($origin);
    }
    return {runtime => $runtime, origin => $origin};
}

=head2 source_bitwise_tree_origin

Return a detached source-tree syntactic origin for C<fsmgen_parsing> metadata
only when complete typed defining/runtime/cached trees agree and fresh rendering
matches the selected assignment text. Shared bounded recognition preserves every
operator, association and ordered leaf slot. Source widths establish no shape.
Recheck all selected trees after rendering; changed caches, slices, literals,
state/logical/arithmetic shapes and foreign families withhold. This supplies no
source allocation, plain-type or frozen width proof.

=cut

sub source_bitwise_tree_origin ($self, $signal_name, $signal_info, $expression) {
    return unless defined($signal_name) && !ref($signal_name)
        && defined($expression) && !ref($expression);
    my $shape = $self->_selected_source_tree_shape($signal_name, $signal_info) or return;
    my $rendered = $self->{flattened_dt}{enable_graph_ast_support}->ast_to_systemverilog($shape->{runtime});
    return unless defined($rendered) && !ref($rendered) && $rendered eq $expression;
    my $after = $self->_selected_source_tree_shape($signal_name, $signal_info) or return;
    return unless JSON::PP->new->canonical->encode($shape->{origin})
        eq JSON::PP->new->canonical->encode($after->{origin});
    return $after->{origin};
}

=head2 source_bitwise_tree_width_allocation

Return separate current tree policy only from the installed width owner's
completed actual source attachment. Its complete original tree/operator/ordered
slots must match the fresh selected origin. That owner validates root/all-source
membership, plain profiles and exact maximum. Recheck selected AST/text and current
policy after every read; copied/stale/constrained or late-mutated inputs withhold.
The binary/arithmetic publishers retain their closed profiles. Selected metadata
alone establishes no frozen relationship or symbolic range eligibility.

=cut

sub source_bitwise_tree_width_allocation ($self, $signal_name, $signal_info, $expression) {
    my $origin = $self->source_bitwise_tree_origin($signal_name, $signal_info, $expression) or return;
    my $owner = $self->{flattened_dt}{backend_sv_intermediate_width_support};
    return unless $owner && $owner->can('source_bitwise_tree_width_allocation');
    my $policy = $owner->source_bitwise_tree_width_allocation($signal_name, $signal_info) or return;
    $policy = FSM::SourceBitwiseTreePolicySupport->copy_record($policy);
    return unless FSM::SourceBitwiseTreePolicySupport->matches_origin($policy, $origin);
    # The completed owner checks actual root/all-leaf membership, plain profiles
    # and exact maximum. Recheck after every selected AST/text read.
    my $after = $self->source_bitwise_tree_origin($signal_name, $signal_info, $expression) or return;
    return unless FSM::SourceBitwiseTreePolicySupport->matches_origin($policy, $after);
    my $current = $owner->source_bitwise_tree_width_allocation($signal_name, $signal_info) or return;
    return unless JSON::PP->new->canonical->encode($current) eq JSON::PP->new->canonical->encode($policy);
    return $current;
}

=head2 binary_width_allocation

Return an optional current allocation policy for the same freshly selected
bitwise origin and expression. Only the width owner's completed source attachment
or factorizer proof can supply it. Ordered operands/operator and exact selected
width must agree, with actual plain unsigned module operands and no state or
constraint profile. Recheck current policy after all reads so matching supported
source mutation during publication cannot borrow a prior observation. Opaque,
copied, stale or independently constrained metadata retains its old event shape.
This publishes no symbolic range and does not extend the scalar VHDL profile.

=cut

sub binary_width_allocation ($self, $signal_name, $signal_info, $expression) {
    return $self->_width_allocation_for_origin($signal_name, $signal_info, $expression, 'binary_bitwise_origin');
}

=head2 arithmetic_width_allocation

Return the optional current arithmetic policy using C<binary_arithmetic_origin>
and the same completed-allocation, plain-source, exact-width and final-currentness
checks as C<binary_width_allocation>. Keeping this publisher separate preserves
the bitwise-only recovery method. A declaration consumer additionally proves
the frozen source relationship and final target records before accepting a
symbolic arithmetic range; target metadata alone extends no VHDL admission.

=cut

sub arithmetic_width_allocation ($self, $signal_name, $signal_info, $expression) {
    return $self->_width_allocation_for_origin($signal_name, $signal_info, $expression, 'binary_arithmetic_origin');
}

=head2 arithmetic_graph_width_allocation

Return a separate optional current completed graph policy for the actual selected
arithmetic origin and expression. Traverse the current typed graph to require
plain unsigned module sources and collected, allocated and registered result
rows, including every computed child. Numeric graph inference alone may retain
state-model constraints; this target publisher refuses them. Recheck the complete
current policy after all AST, rendering and profile reads. Copied, stale, opaque
or constrained inputs withhold. This publishes no symbolic range and does not
broaden either ordinary binary policy API or VHDL admission.

=cut

sub arithmetic_graph_width_allocation ($self, $signal_name, $signal_info, $expression) {
    my $origin = $self->binary_arithmetic_origin($signal_name, $signal_info, $expression) or return;
    my $ctx = $self->{flattened_dt};
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    return unless $owner && $owner->can('factorized_graph_width_allocation')
        && $owner->can('_current_graph_inference_rows');
    my $policy = $owner->factorized_graph_width_allocation($signal_name, $signal_info) or return;
    $policy = FSM::IntermediateWidthGraphPolicySupport->copy_record($policy);
    return unless $policy->{operator} eq $origin->{operator}
        && $policy->{source_names}[0] eq $origin->{source_names}[0]
        && $policy->{source_names}[1] eq $origin->{source_names}[1];
    my $rows = $owner->_current_graph_inference_rows;
    return unless ref($rows) eq 'HASH' && ref($rows->{$signal_name}) eq 'HASH'
        && $rows->{$signal_name} == $signal_info;
    my $budget = FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES();
    return unless $self->_plain_arithmetic_graph($signal_name, $rows, {}, \$budget, 0);
    my $current = $owner->factorized_graph_width_allocation($signal_name, $signal_info) or return;
    return unless JSON::PP->new->canonical->encode($policy) eq JSON::PP->new->canonical->encode($current);
    return $current;
}

sub _plain_arithmetic_graph ($self, $name, $rows, $visited, $budget, $depth) {
    return unless $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS()
        && --$$budget >= 0;
    return $visited->{$name} == 2 if $visited->{$name};
    $visited->{$name} = 1;
    my $ctx = $self->{flattened_dt};
    my $info = $rows->{$name};
    return unless ref($info) eq 'HASH';
    my $ast = $info->{ast};
    my $shape = _whole_signal_binary_arithmetic($ast) or return;
    for my $row ($info, $ctx->{ast_factorizer}{intermediate_signals}{$name}, $ctx->{intermediate_signals}{$name}) {
        return unless FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast)
            && !defined($row->{state_model});
    }
    my @nodes = ($ast->left, $ast->right);
    for my $index (0, 1) {
        my $node = $nodes[$index];
        my $source_name = $shape->{source_names}[$index];
        if (UNIVERSAL::isa($node, 'FSM::HDL::IntermediateSignalRef')) {
            return unless $self->_plain_arithmetic_graph($source_name, $rows, $visited, $budget, $depth + 1);
        } else {
            my $signal = $ctx->{fsm_module}->signals->{$source_name};
            my $descriptor = FSM::IntermediateWidthAllocationSupport::_descriptor($signal) or return;
            return unless $descriptor->{name} eq $source_name && !defined($descriptor->{state_model})
                && ref($descriptor->{constraints}) eq 'ARRAY' && !@{$descriptor->{constraints}};
        }
    }
    $visited->{$name} = 2;
    return 1;
}

sub _width_allocation_for_origin ($self, $signal_name, $signal_info, $expression, $origin_method) {
    my $origin = $self->$origin_method($signal_name, $signal_info, $expression) or return;
    my $ctx = $self->{flattened_dt};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    return unless $width_support && $width_support->can('intermediate_width_allocation');
    my $policy = $width_support->intermediate_width_allocation($signal_name, $signal_info) or return;
    $policy = FSM::IntermediateWidthAllocationSupport->copy_record($policy);
    return unless $policy->{operator} eq $origin->{operator}
        && $policy->{source_names}[0] eq $origin->{source_names}[0]
        && $policy->{source_names}[1] eq $origin->{source_names}[1]
        && !defined($signal_info->{state_model});
    my $module = $ctx->{fsm_module};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule')
        && ref($module->signals) eq 'HASH';
    my @widths;
    for my $name (@{$policy->{source_names}}) {
        my $signal = $module->signals->{$name};
        return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
            && !$signal->signed && !defined($signal->state_model)
            && !defined($signal->declared_type_name) && !defined($signal->declared_type_spec)
            && defined($signal->type) && !ref($signal->type) && $signal->type =~ /\A(?:wire|reg)\z/;
        my $constraints = $signal->constraints;
        return unless ref($constraints) eq 'ARRAY' && !@$constraints;
        push @widths, $signal->width;
    }
    return unless FSM::IntermediateWidthAllocationSupport->matches_selected_widths(
        $policy, $signal_info->{width}, @widths);
    my $current = $width_support->intermediate_width_allocation($signal_name, $signal_info) or return;
    my $json = JSON::PP->new->canonical;
    return unless $json->encode($policy) eq $json->encode($current);
    return $current;
}

=head2 resolve_intermediate_signal_dependencies

Normalize the dependency list for one intermediate signal from runtime ASTs or
the explicit runtime-AST-miss recovery path and cache the result.
The default width owner withholds a current concatenation event after nested
rendering and before extraction callbacks. Only its exact published array,
ordered returned names, original source and narrow rendered-expression fallback
tag carry authority. A pre-publication barrier rejects unrelated mutations before
the final assignments can overwrite them; late array substitution and exceptions
cannot refresh. Cached reads and injected legacy providers retain their contracts.

=cut

sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return () unless defined($signal_name) && $signal_name ne '';

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && $signal_info->{dependency_signal_names}
        && ref($signal_info->{dependency_signal_names}) eq 'ARRAY')
    {
        return @{$signal_info->{dependency_signal_names}};
    }

    my @dependencies;
    my $dependency_source = 'none';

    my $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    my $carry_dependencies = $width_support && $width_support->can('_take_concatenation_dependency_input')
        && $width_support->can('_publish_concatenation_dependencies');
    my $dependency_input = $carry_dependencies
        ? $width_support->_take_concatenation_dependency_input($signal_name, $signal_info) : undef;
    my $selected_fallback;
    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        @dependencies = $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($runtime_ast);
        $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
        delete $signal_info->{dependency_fallback_source} if $signal_info && ref($signal_info) eq 'HASH';

        if (defined($expression) && $expression ne '') {
            my %fallback_signal_info = $signal_info && ref($signal_info) eq 'HASH'
                ? %{$signal_info}
                : ();
            delete @fallback_signal_info{
                qw(runtime_ast runtime_ast_source runtime_ast_resolution_state runtime_ast_miss_reason dependency_fallback_source)
            };

            my @fallback_dependencies = $self->extract_intermediate_signals_from_runtime_ast_miss(
                $signal_name,
                \%fallback_signal_info,
                $expression,
            );

            if (@fallback_dependencies) {
                my $fallback_source = $fallback_signal_info{dependency_fallback_source}
                    || 'rendered_expression_fallback';
                $selected_fallback = $fallback_source;
                my %seen_dependencies = map { $_ => 1 } @dependencies;
                push @dependencies, grep { !$seen_dependencies{$_}++ } @fallback_dependencies;
                $dependency_source = $dependency_source . '+' . $fallback_source;
                if ($signal_info && ref($signal_info) eq 'HASH') {
                    $signal_info->{dependency_fallback_source} = $fallback_source;
                }
            }
        }
    } else {
        if (defined($expression) && $expression ne '') {
            @dependencies = $self->extract_intermediate_signals_from_runtime_ast_miss($signal_name, $signal_info, $expression);
            if ($signal_info
                && ref($signal_info) eq 'HASH'
                && $signal_info->{runtime_ast}
                && blessed($signal_info->{runtime_ast}))
            {
                $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast_recovery';
                delete $signal_info->{dependency_fallback_source};
            } else {
                $dependency_source = ($signal_info && ref($signal_info) eq 'HASH')
                    ? ($signal_info->{dependency_fallback_source} || 'runtime_ast_miss_unresolved')
                    : 'runtime_ast_miss_unresolved';
            }
        }
    }

    my %seen_dependencies;
    @dependencies = grep { defined($_) && $_ ne '' && !$seen_dependencies{$_}++ } @dependencies;

    my $publish = sub {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            my $array = [@dependencies];
            $signal_info->{dependency_signal_names} = $array;
            $signal_info->{dependency_source} = $dependency_source;
            return $array;
        }
        return undef;
    };
    if ($carry_dependencies) {
        $width_support->_publish_concatenation_dependencies($signal_name, $signal_info,
            $dependency_input, $runtime_ast, [@dependencies], $dependency_source, $selected_fallback, $publish);
    } else {
        $publish->();
    }

    my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_dependencies()] '$signal_name' dependencies => $dependency_summary via $dependency_source", 3);
    return @dependencies;
}

=head2 extract_intermediate_signals_from_runtime_ast_miss

Attempt AST-backed dependency recovery for a signal whose runtime AST could not
be resolved, including cleaned-expression retries and signal-name fallback
recovery.

=cut

sub extract_intermediate_signals_from_runtime_ast_miss ($self, $signal_name, $signal_info, $expression) {
    my $ctx = $self->{flattened_dt};
    return () unless defined($expression) && $expression ne '';

    my $debug_signal_name = defined($signal_name) && $signal_name ne ''
        ? $signal_name
        : '<compatibility_expression>';
    my $stored_expression = ($signal_info && ref($signal_info) eq 'HASH' && defined($signal_info->{expression}))
        ? $signal_info->{expression}
        : undef;
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my %seen_candidate_expressions;
    my @candidate_expressions = ([ $expression, 'rendered_expression' ]);

    if (defined($signal_name) && $signal_name ne '') {
        my $enable_graph_expression = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_expression($signal_name);
        if (defined($enable_graph_expression) && $enable_graph_expression ne '') {
            push @candidate_expressions, [ $enable_graph_expression, 'enable_graph_expression' ];
        }
    }

    for my $candidate_info (@candidate_expressions) {
        my ($candidate_expression, $candidate_source) = @$candidate_info;
        next unless defined($candidate_expression) && $candidate_expression ne '';
        next if $seen_candidate_expressions{$candidate_expression}++;

        my $is_known_failed_expression =
            $miss_reason eq 'expression_parse_failed'
            && defined($stored_expression)
            && $stored_expression ne ''
            && $candidate_expression eq $stored_expression;

        if ($is_known_failed_expression) {
            fsm_debug("[IntermediateSignalRecoverySupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] Skipping redundant parse retry for '$debug_signal_name' via $candidate_source after known parse failure", 3);
        } else {
            my $parsed_ast = $self->recover_runtime_ast_from_dependency_expression(
                $signal_name,
                $signal_info,
                $candidate_expression,
                $candidate_source,
                0,
            );
            return $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);

            if ($ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
                my $parsed_expression_tree = eval { $ctx->{expr_namer}->parse_expression($candidate_expression) };
                my @parsed_expression_dependencies =
                    $parsed_expression_tree
                    ? $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_expression_tree)
                    : ();
                if (@parsed_expression_dependencies) {
                    if ($signal_info && ref($signal_info) eq 'HASH') {
                        $signal_info->{dependency_fallback_source} = 'parsed_' . $candidate_source . '_expression_tree';
                    }
                    return @parsed_expression_dependencies;
                }
            }
        }

        my $cleaned_expression = $ctx->{enable_graph_signal_support}->clean_intermediate_expression($candidate_expression);
        if (defined($cleaned_expression)
            && $cleaned_expression ne ''
            && $cleaned_expression ne $candidate_expression
            && !$seen_candidate_expressions{$cleaned_expression}++)
        {
            my $cleaned_source = 'cleaned_' . $candidate_source;
            my $parsed_ast = $self->recover_runtime_ast_from_dependency_expression(
                $signal_name,
                $signal_info,
                $cleaned_expression,
                $cleaned_source,
                1,
            );
            return $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);

            if ($ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
                my $parsed_expression_tree = eval { $ctx->{expr_namer}->parse_expression($cleaned_expression) };
                my @parsed_expression_dependencies =
                    $parsed_expression_tree
                    ? $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_expression_tree)
                    : ();
                if (@parsed_expression_dependencies) {
                    if ($signal_info && ref($signal_info) eq 'HASH') {
                        $signal_info->{dependency_fallback_source} = 'parsed_' . $cleaned_source . '_expression_tree';
                    }
                    return @parsed_expression_dependencies;
                }
            }
        }
    }

    if (defined($signal_name) && $signal_name ne '') {
        my $signal_name_ast = $ctx->{enable_graph_intermediate_support}->build_dependency_recovery_ast_from_signal_name($signal_name);
        if ($signal_name_ast && blessed($signal_name_ast)) {
            my @dependencies = $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($signal_name_ast);
            if ($signal_info && ref($signal_info) eq 'HASH') {
                $signal_info->{dependency_fallback_source} = 'runtime_ast_miss_signal_name_ast';
            }
            return @dependencies;
        }
    }

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{dependency_fallback_source} = 'runtime_ast_miss_unresolved';
    }
    fsm_debug(
        "[IntermediateSignalRecoverySupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] No AST-backed dependency recovery remained for '$debug_signal_name'; leaving dependencies unresolved after runtime AST miss",
        3,
    );
    return ();
}

=head2 recover_runtime_ast_from_dependency_expression

Attempt to parse one compatibility expression into a runtime AST for
dependency recovery and update the signal metadata when successful.

=cut

sub recover_runtime_ast_from_dependency_expression ($self, $signal_name, $signal_info, $candidate_expression, $candidate_source, $preserve_rendered_expression = 0) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($candidate_expression) && $candidate_expression ne '';
    return undef unless $ctx->{expr_namer};

    my $debug_signal_name = defined($signal_name) && $signal_name ne ''
        ? $signal_name
        : '<compatibility_expression>';
    my $parsed_ast = eval { $ctx->{expr_namer}->parse_expression($candidate_expression) };
    if ($parsed_ast && blessed($parsed_ast)) {
        my $runtime_ast_source = 'dependency_' . $candidate_source . '_ast';
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{runtime_ast} = $parsed_ast;
            $signal_info->{runtime_ast_source} = $runtime_ast_source;
            $signal_info->{runtime_ast_resolution_state} = 'resolved';
            delete $signal_info->{runtime_ast_miss_reason};
            unless ($preserve_rendered_expression) {
                $signal_info->{rendered_expression} = $candidate_expression;
                $signal_info->{rendered_expression_source} = $candidate_source;
            }
            $signal_info->{expression} //= $candidate_expression;
            delete $signal_info->{dependency_fallback_source};
            if (defined($signal_name) && $signal_name ne '') {
                my $resolved_width = $ctx->{backend_sv_intermediate_width_support}->resolve_intermediate_signal_width($signal_name, $signal_info);
                $signal_info->{width} = $resolved_width if defined($resolved_width) && $resolved_width > 0;
            }
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][recover_runtime_ast_from_dependency_expression()] Recovered runtime AST for '$debug_signal_name' via $candidate_source", 3);
        return $parsed_ast;
    }

    my $error = $@;
    chomp $error if defined $error;
    # informational note: one candidate source of a multi-candidate recovery search did not parse;
    # the search continues and the overall recovery typically succeeds via another candidate.
    fsm_debug("[IntermediateSignalRecoverySupport.pm][recover_runtime_ast_from_dependency_expression()] compatibility parse miss for '$debug_signal_name' via $candidate_source (recovery continues): " . ($error || 'unknown parse failure'), 3);
    return undef;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal recovery owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 resolve_intermediate_signal_defining_ast

Finds the defining AST for one intermediate signal from cached metadata or the
enable graph and caches the result when found.

=head2 resolve_intermediate_signal_runtime_ast

Resolves the runtime AST for one intermediate signal from substituted ASTs or
the defining AST and records the result or miss metadata on the signal info.

=head2 render_intermediate_signal_expression

Renders one intermediate signal expression from its resolved runtime AST when
available, otherwise falls back to stored compatibility expressions or the
enable-graph string registry.

=head2 resolve_intermediate_signal_dependencies

Normalizes the dependency list for one intermediate signal from runtime ASTs
or the explicit runtime-AST-miss recovery path and caches the result.

=head2 extract_intermediate_signals_from_runtime_ast_miss

Attempts AST-backed dependency recovery for a signal whose runtime AST could
not be resolved, including cleaned-expression retries and signal-name fallback
recovery.

=head2 recover_runtime_ast_from_dependency_expression

Attempts to parse one compatibility expression into a runtime AST for
dependency recovery and updates the signal metadata when successful.

=cut
