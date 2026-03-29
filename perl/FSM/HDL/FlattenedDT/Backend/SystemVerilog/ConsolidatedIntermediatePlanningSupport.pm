package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport - Compose consolidated intermediate selection and dependency planning

=head1 DESCRIPTION

Owns the bounded plan-composition family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

overall plan composition across the extracted dependency-map and selection
owners

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDependencySupport>
now owns dependency-map construction plus dependency-safe ordering, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
still owns collection-plus-planning composition for one prepared block, and
this package now narrows to overall plan composition over the extracted
selection and dependency owners.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

=head2 new

Construct one consolidated-intermediate planning owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediatePlanningSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 plan_consolidated_intermediate_signals

Build the full dependency/filter/order plan for an already normalized
consolidated intermediate-signal set by composing the extracted selection and
dependency owners.

=cut

sub plan_consolidated_intermediate_signals ($self, $all_intermediate_signals) {
    my $ctx = $self->{flattened_dt};
    my $dependency_support = $ctx->{backend_sv_consolidated_intermediate_dependency_support};
    my $signal_dependencies = $dependency_support->build_signal_dependencies($all_intermediate_signals);
    my $filter_plan = $ctx->{backend_sv_consolidated_intermediate_selection_support}->filter_consolidated_signals(
        $all_intermediate_signals,
        $signal_dependencies,
    );
    my @sorted_signals = $dependency_support->topologically_sort_signals(
        $filter_plan->{filtered_signals},
        $signal_dependencies,
    );

    return {
        signal_dependencies => $signal_dependencies,
        sorted_signals => \@sorted_signals,
        %{$filter_plan},
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate planning owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 plan_consolidated_intermediate_signals

Builds the full dependency/filter/order plan for an already normalized
consolidated intermediate-signal set by composing the extracted selection and
dependency owners.

=cut
