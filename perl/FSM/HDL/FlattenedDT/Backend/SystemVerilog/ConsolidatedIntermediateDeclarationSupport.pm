package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport - Render direct consolidated intermediate wire declarations

=head1 DESCRIPTION

Owns the bounded declaration-rendering family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

width-aware declaration rendering for prepared consolidated intermediate
signals

=item *

the direct wire declaration block consumed by the narrowed consolidated
emitter

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport>
keeps width normalization and inference, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport>
keeps prepared assign emission, and the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now narrows further to block composition over those extracted rendering owners.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::SourceBitwiseTreeOriginSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

=head2 new

Construct one consolidated-intermediate declaration owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateDeclarationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 render_consolidated_intermediate_declarations

Render the prepared consolidated intermediate wire declarations from the
prepared block contract.
Actual current bitwise/arithmetic allocations with identical captured mutable operand
contracts consume the representative symbolic range, including vector rank at
width one. Current computed arithmetic graph allocations use the canonical
original-leaf relationship through separate source declaration intent. The graph
ledger preserves the selected root fields, original tree and duplicate slots;
independent completed target proof must agree before HDL returns. Fixed graphs
retain numeric declarations, and incompatible mutable leaf contracts refuse.
Other declarations retain numeric shapes. A detached emitted-plan
ledger records the selected expression, ordered operands, allocation role and
range; final assembly independently qualifies the completed target records and
requires exact agreement before returning HDL.

Source-owned nested bitwise trees and computed source binary helpers use a
separate source-range ledger. Actual typed shape and captured mutable dependency
select when proof is required; those selectors prove no allocation or ancestry.
Current source intent must independently prove every original leaf relationship
and selected maximum. Missing policy cannot silently select a numeric fallback.
Fixed independent leaves retain numeric declarations. Complete selected-target
proof and the whole-generation source fence close this ledger before HDL returns.

Literal helpers have a separate generation-local declaration ledger. Actual
selected literal intent supplies either its fixed numeric range or its mutable
maximum. Required typed literal expressions cannot use the other range families
or numeric fallback when that intent is absent. Complete physical target proof
and a whole-generation raw fence independently close this ledger.

Typed concatenation helpers with captured symbolic source dependencies refuse
until a sum-range proof is available. A selected numeric sum cannot replace that
proof. Fixed helpers retain their existing numeric declaration path; this
selector grants no new allocation or target-range authority.

=cut

sub render_consolidated_intermediate_declarations ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $hdl = '';

    for my $signal_name (@{$sorted_signals}) {
        my $signal_info = $filtered_signals->{$signal_name};
        $self->_refuse_unproved_concatenation_range($signal_name, $signal_info);
        my $width = $width_support->resolve_intermediate_signal_width($signal_name, $signal_info, $filtered_signals);
        $ctx->{declared_width_declaration_capture}->record_intermediate_declaration(
            {name => $signal_name, width => $width, signed => 0})
            if $ctx->{declared_width_declaration_capture};

        my $range = $self->_literal_range($signal_name, $signal_info, $width, $filtered_signals);
        $range //= $self->_source_bitwise_symbolic_range($signal_name, $signal_info, $width);
        $range //= $self->_binary_symbolic_range($signal_name, $signal_info, $width);
        $range //= $self->_graph_symbolic_range($signal_name, $signal_info, $width);
        if ($range) {
            $hdl .= "  wire $range->{range_text}$signal_name;\n";
        } elsif ($width > 1) {
            $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
        } else {
            $hdl .= "  wire $signal_name;\n";
        }
    }

    return $hdl;
}

sub _refuse_unproved_concatenation_range ($self, $name, $info) {
    my $ast = $info->{ast};
    return unless blessed($ast) && $ast->isa('FSM::CoreAST::Concatenation');
    my $source = $self->{flattened_dt}{direct_declared_width_source_plan};
    return unless $source && $source->{profile} eq 'symbolic';
    my %active;
    my $budget = FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES();
    confess "Direct concatenation '$name' requires proved symbolic sum range\n"
        if $self->_source_symbolic_dependency($ast, $source, \%active, \$budget, 0);
}

sub _literal_range ($self, $name, $info, $width, $rows) {
    my $ctx = $self->{flattened_dt};
    my $literal = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
    return unless $literal->requires_emission($ctx->{fsm_module}{signals}{$name}, $rows);
    my $expression = $ctx->{backend_sv_intermediate_recovery_support}
        ->render_intermediate_signal_expression($name, $info);
    my $emitted = $literal->prepare_emission(width_support => $ctx->{backend_sv_intermediate_width_support},
        signal_name => $name, signal_info => $info, signal_registry => $rows,
        target_language => 'systemverilog', expression => $expression);
    confess "Direct literal declaration requires current selected source intent and width\n"
        unless $emitted && $emitted->{width} eq FSM::IntermediateWidthAllocationSupport::_width($width);
    $ctx->{direct_declared_width_emitted_literal_ranges}{$name} = $emitted;
    return $emitted;
}

# These selectors decide when proof is required. They install no policy and
# attest no source edge, width relationship or selected target membership.
sub _source_bitwise_family ($self, $name, $info) {
    return unless ref($info) eq 'HASH' && ($info->{source} // '') eq 'fsmgen_parsing';
    my $module = $self->{flattened_dt}{fsm_module};
    my $signal = $module->signals->{$name};
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $ast = $signal->driving_ast;
    return 'tree' if FSM::SourceBitwiseTreeOriginSupport->from_ast($ast);
    return unless blessed($ast) && $ast->isa('FSM::CoreAST::BinaryOp')
        && ref($ast->{operands}) eq 'ARRAY' && @{$ast->{operands}} == 2
        && defined($ast->operator) && $ast->operator =~ /\A[&|^]\z/;
    for my $operand (@{$ast->{operands}}) {
        next unless blessed($operand) && $operand->isa('FSM::CoreAST::SignalRef');
        my $child = $operand->signal;
        next unless blessed($child) && $child->isa('FSM::CoreAST::Signal');
        my $canonical = $module->signals->{$child->name};
        return 'binary' if $child->get_attribute('is_intermediate')
            || ($canonical && $canonical->get_attribute('is_intermediate'));
    }
    return;
}

sub _source_bitwise_uses_symbolic ($self, $name) {
    my $ctx = $self->{flattened_dt};
    return 0 if FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
        ->requires_emission($ctx->{fsm_module}{signals}{$name},
            $ctx->{backend_sv_intermediate_width_support}{_graph_inference_rows});
    my $source = $ctx->{direct_declared_width_source_plan};
    return 0 unless $source && $source->{profile} eq 'symbolic';
    my $signal = $ctx->{fsm_module}->signals->{$name};
    my %active;
    my $budget = FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES();
    return $signal ? $self->_source_symbolic_dependency($signal->driving_ast, $source, \%active, \$budget, 0) : 0;
}

sub _source_symbolic_dependency ($self, $ast, $source, $active, $budget, $depth) {
    return 0 unless blessed($ast);
    confess "Direct source bitwise symbolic dependency exceeds its bounded tree\n"
        if $depth > FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS();
    my $identity = refaddr($ast);
    confess "Direct source bitwise symbolic dependency contains a cycle\n" if $active->{$identity};
    local $active->{$identity} = 1;
    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $operand = $ast->signal;
        return 0 unless blessed($operand) && $operand->isa('FSM::CoreAST::Signal');
        my $plan = $source->{signals}{$operand->name};
        return 1 if $plan && $plan->{width_plan} && $plan->{width_plan}{profile} eq 'symbolic';
        return $self->_source_symbolic_dependency($operand->driving_ast, $source, $active, $budget, $depth)
            if $operand->get_attribute('is_intermediate');
    }
    confess "Direct source bitwise symbolic dependency exceeds its occurrence budget\n" if --$$budget < 0;
    if (ref($ast->{operands}) eq 'ARRAY') {
        for my $operand (@{$ast->{operands}}) {
            return 1 if $self->_source_symbolic_dependency($operand, $source, $active, $budget, $depth + 1);
        }
    }
    return 0;
}

sub _source_bitwise_symbolic_range ($self, $name, $info, $width) {
    my $ctx = $self->{flattened_dt};
    return unless $ctx->{direct_declared_width_source_plan};
    my $family = $self->_source_bitwise_family($name, $info) or return;
    return unless $self->_source_bitwise_uses_symbolic($name);
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    my $expression = $recovery->render_intermediate_signal_expression($name, $info);
    my $method = $family eq 'tree' ? 'prepare_source_tree_declaration' : 'prepare_computed_source_binary_declaration';
    my $emitted = FSM::DirectDeclaredWidthSupport->$method(flattened_dt => $ctx,
        signal_name => $name, signal_info => $info, target_language => 'systemverilog', expression => $expression);
    confess "Direct source bitwise emitted range requires current symbolic intent and selected width\n"
        unless $emitted->{profile} eq 'symbolic' && $emitted->{width_plan}
            && FSM::IntermediateWidthAllocationSupport::_width($emitted->{width})
                eq FSM::IntermediateWidthAllocationSupport::_width($width);
    $ctx->{direct_declared_width_emitted_source_tree_ranges}{$name} = $emitted;
    return $emitted->{width_plan};
}

sub _binary_symbolic_range ($self, $name, $info, $width) {
    my $ctx = $self->{flattened_dt};
    my $source_plan = $ctx->{direct_declared_width_source_plan} or return;
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    return unless $recovery;
    my $expression = $recovery->render_intermediate_signal_expression($name, $info);
    my ($policy, $origin_method, $origin_key);
    for my $family (
        ['binary_width_allocation', 'binary_bitwise_origin', 'bitwise_origin'],
        ['arithmetic_width_allocation', 'binary_arithmetic_origin', 'arithmetic_origin'],
    ) {
        my ($allocation_method, $method, $key) = @$family;
        next unless $recovery->can($allocation_method);
        my $candidate = $recovery->$allocation_method($name, $info, $expression) or next;
        ($policy, $origin_method, $origin_key) = ($candidate, $method, $key);
        last;
    }
    return unless $policy;
    return unless grep {
        my $operand = $source_plan->{signals}{$_};
        $operand && $operand->{width_plan} && $operand->{width_plan}{profile} eq 'symbolic';
    } @{$policy->{source_names}};

    my $relationship = FSM::DirectDeclaredWidthSupport->prepare_binary_operand_relationship(
        fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => 'systemverilog', source_names => $policy->{source_names});
    confess "Direct binary emitted range requires current symbolic operand contracts\n"
        unless $relationship->{profile} eq 'symbolic' && $relationship->{width_plan};
    confess "Direct binary emitted range disagrees with selected allocation width\n"
        unless FSM::IntermediateWidthAllocationSupport->matches_selected_widths(
            $policy, $width, @{$relationship->{operand_widths}});
    my $origin = $recovery->can($origin_method)
        ? $recovery->$origin_method($name, $info, $expression) : undef;
    confess "Direct binary emitted range requires its actual binary origin\n" unless $origin;
    my $role = ($info->{source} // '') eq 'fsmgen_parsing' ? 'source_intermediate'
        : ($info->{source} // '') eq 'ast_factorization' ? 'factorized_intermediate' : undef;
    confess "Direct binary emitted range requires a known allocation role\n" unless $role;
    my $json = JSON::PP->new->canonical;
    # This records the source/allocation proof used for this declaration.
    # Complete target membership is independently re-derived after emission.
    my $emitted = $json->decode($json->encode({profile => $relationship->{profile},
        target_language => $relationship->{target_language}, source_scope => $relationship->{source_scope},
        module_name => $ctx->{fsm_module}->name, target_name => $name, declaration_kind => 'signal',
        allocation_role => $role, source_names => $policy->{source_names},
        operand_targets => $policy->{source_names}, width_allocation => $policy,
        $origin_key => $origin, expression => $expression, width_plan => $relationship->{width_plan}}));
    $ctx->{direct_declared_width_emitted_binary_ranges}{$name} = $emitted;
    return $emitted->{width_plan};
}

sub _graph_symbolic_range ($self, $name, $info, $width) {
    my $ctx = $self->{flattened_dt};
    my $source = $ctx->{direct_declared_width_source_plan} or return;
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    return unless $recovery && $recovery->can('arithmetic_graph_width_allocation');
    my $expression = $recovery->render_intermediate_signal_expression($name, $info);
    my $policy = $recovery->arithmetic_graph_width_allocation($name, $info, $expression) or return;
    my $leaves = FSM::IntermediateWidthGraphPolicySupport->leaf_names($policy);
    return unless grep {
        my $signal = $source->{signals}{$_};
        $signal && $signal->{width_plan} && $signal->{width_plan}{profile} eq 'symbolic';
    } @$leaves;
    my $emitted = FSM::DirectDeclaredWidthSupport->prepare_arithmetic_graph_declaration(
        flattened_dt => $ctx, signal_name => $name, signal_info => $info,
        target_language => 'systemverilog', expression => $expression);
    my $json = JSON::PP->new->canonical;
    confess "Direct graph emitted range requires the same current symbolic declaration intent\n"
        unless $emitted->{profile} eq 'symbolic' && $emitted->{width_plan}
            && $json->encode($emitted->{graph_width_allocation}) eq $json->encode($policy)
            && FSM::IntermediateWidthAllocationSupport::_width($emitted->{width})
                eq FSM::IntermediateWidthAllocationSupport::_width($width);
    $ctx->{direct_declared_width_emitted_graph_ranges}{$name} = $emitted;
    return $emitted->{width_plan};
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate declaration owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 render_consolidated_intermediate_declarations

Renders the prepared consolidated intermediate wire declarations from the
prepared block contract.

=cut
