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
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthAllocationSupport;

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
Actual current binary allocations with identical captured mutable operand
contracts consume the representative symbolic range, including vector rank at
width one. Other declarations retain numeric shapes. A detached emitted-plan
ledger records the selected expression, ordered operands, allocation role and
range; final assembly independently qualifies the completed target records and
requires exact agreement before returning HDL.

=cut

sub render_consolidated_intermediate_declarations ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $hdl = '';

    for my $signal_name (@{$sorted_signals}) {
        my $signal_info = $filtered_signals->{$signal_name};
        my $width = $width_support->resolve_intermediate_signal_width($signal_name, $signal_info, $filtered_signals);
        $ctx->{declared_width_declaration_capture}->record_intermediate_declaration(
            {name => $signal_name, width => $width, signed => 0})
            if $ctx->{declared_width_declaration_capture};

        my $range = $self->_binary_symbolic_range($signal_name, $signal_info, $width);
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

sub _binary_symbolic_range ($self, $name, $info, $width) {
    my $ctx = $self->{flattened_dt};
    my $source_plan = $ctx->{direct_declared_width_source_plan} or return;
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    return unless $recovery && $recovery->can('binary_width_allocation');
    my $expression = $recovery->render_intermediate_signal_expression($name, $info);
    my $policy = $recovery->binary_width_allocation($name, $info, $expression) or return;
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
    my $origin = $recovery->binary_bitwise_origin($name, $info, $expression);
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
        bitwise_origin => $origin, expression => $expression, width_plan => $relationship->{width_plan}}));
    $ctx->{direct_declared_width_emitted_binary_ranges}{$name} = $emitted;
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
