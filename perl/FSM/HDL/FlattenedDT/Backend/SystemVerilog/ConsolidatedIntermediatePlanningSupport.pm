package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport - Plan dependency-aware consolidated intermediate retention and ordering

=head1 DESCRIPTION

Owns the bounded planning family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

dependency-map construction over normalized consolidated intermediate metadata

=item *

dependency-aware keep/filter/rescue planning for consolidated intermediates

=item *

dependency-safe emission ordering with cycle-tolerant fallback

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now narrows to final HDL rendering, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
now owns collection-plus-planning composition for one prepared block, and this
package owns the “which signals survive and in what order?” planning side of
the direct backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

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

=head2 build_signal_dependencies

Build the intermediate-signal dependency map from already normalized
consolidated signal metadata.

=cut

sub build_signal_dependencies ($self, $all_intermediate_signals) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my %signal_dependencies;

    for my $signal_name (keys %{ $all_intermediate_signals || {} }) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my @referenced_signals = $recovery_support->resolve_intermediate_signal_dependencies($signal_name, $signal_info);

        if (@referenced_signals) {
            $signal_dependencies{$signal_name} = [@referenced_signals];
            fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][build_signal_dependencies()] '$signal_name' depends on: " . join(", ", @referenced_signals), 3);
        }
    }

    return \%signal_dependencies;
}

=head2 filter_consolidated_signals

Apply the dependency-aware consolidated-intermediate keep/filter plan and
return the resulting filtered set plus intermediate planning metadata.

=cut

sub filter_consolidated_signals ($self, $all_intermediate_signals, $signal_dependencies) {
    my $ctx = $self->{flattened_dt};
    my $filter_support = $ctx->{backend_sv_intermediate_support};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my %initially_filtered_signals;
    my %initially_kept_signals;
    my %rescued_signals;

    for my $signal_name (keys %{ $all_intermediate_signals || {} }) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        next unless defined($expression) && $expression ne '';

        my $should_filter = $filter_support->should_filter_consolidated_signal($expression, $signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][filter_consolidated_signals()] INITIAL FILTER: '$signal_name' = $expression", 3);
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][filter_consolidated_signals()] INITIAL KEEP: '$signal_name' = $expression", 3);
        }
    }

    for my $kept_signal (keys %initially_kept_signals) {
        next unless $signal_dependencies->{$kept_signal};
        for my $dependency (@{ $signal_dependencies->{$kept_signal} }) {
            if ($initially_filtered_signals{$dependency}) {
                $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][filter_consolidated_signals()] RESCUED: '$dependency' is needed by '$kept_signal'", 3);
            }
        }
    }

    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    my %finally_filtered_signals = %initially_filtered_signals;
    delete @finally_filtered_signals{keys %rescued_signals};

    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %finally_filtered_signals);
    my $total_kept = scalar(keys %filtered_signals);

    fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][filter_consolidated_signals()] Summary: initially_kept=$initially_kept_count rescued=$rescued_count filtered=$filtered_count total_kept=$total_kept", 3);

    return {
        filtered_signals => \%filtered_signals,
        initially_kept_signals => \%initially_kept_signals,
        initially_filtered_signals => \%initially_filtered_signals,
        rescued_signals => \%rescued_signals,
        finally_filtered_signals => \%finally_filtered_signals,
        initially_kept_count => $initially_kept_count,
        rescued_count => $rescued_count,
        filtered_count => $filtered_count,
        total_kept_count => $total_kept,
    };
}

=head2 topologically_sort_signals

Return the dependency-safe emission order for the filtered consolidated signal
set, with alphabetical cycle fallback when a strict topological order cannot be
formed.

=cut

sub topologically_sort_signals ($self, $filtered_signals, $signal_dependencies) {
    fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][topologically_sort_signals()] Starting topological sort", 3);

    my @sorted_signals;
    my %visited;
    my %in_degree;

    for my $signal (keys %{ $filtered_signals || {} }) {
        $in_degree{$signal} = 0;
    }

    for my $signal (keys %{ $signal_dependencies || {} }) {
        my $deps = $signal_dependencies->{$signal};
        for my $dep (@$deps) {
            if (exists $filtered_signals->{$dep}) {
                $in_degree{$signal}++;
            }
        }
    }

    my @queue = sort grep { $in_degree{$_} == 0 } keys %{ $filtered_signals || {} };

    while (@queue) {
        my $current = shift @queue;
        push @sorted_signals, $current;
        $visited{$current} = 1;

        my @newly_unblocked;
        for my $signal (keys %{ $signal_dependencies || {} }) {
            next if $visited{$signal};

            my $deps = $signal_dependencies->{$signal};
            if (grep { $_ eq $current } @$deps) {
                $in_degree{$signal}--;
                push @newly_unblocked, $signal if $in_degree{$signal} == 0;
            }
        }

        push @queue, sort @newly_unblocked;
    }

    my @remaining_signals = sort grep { !$visited{$_} } keys %{ $filtered_signals || {} };
    if (@remaining_signals) {
        fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][topologically_sort_signals()] WARNING: cycle fallback for: " . join(", ", @remaining_signals), 3);
        push @sorted_signals, @remaining_signals;
    }

    fsm_debug("[ConsolidatedIntermediatePlanningSupport.pm][topologically_sort_signals()] Final order: " . join(", ", @sorted_signals), 3);
    return @sorted_signals;
}

=head2 plan_consolidated_intermediate_signals

Build the full dependency/filter/order plan for an already normalized
consolidated intermediate-signal set.

=cut

sub plan_consolidated_intermediate_signals ($self, $all_intermediate_signals) {
    my $signal_dependencies = $self->build_signal_dependencies($all_intermediate_signals);
    my $filter_plan = $self->filter_consolidated_signals($all_intermediate_signals, $signal_dependencies);
    my @sorted_signals = $self->topologically_sort_signals(
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

=head2 build_signal_dependencies

Builds the intermediate-signal dependency map from already normalized
consolidated signal metadata.

=head2 filter_consolidated_signals

Applies the dependency-aware consolidated-intermediate keep/filter plan and
returns the resulting filtered set plus intermediate planning metadata.

=head2 topologically_sort_signals

Returns the dependency-safe emission order for the filtered consolidated
signal set, with alphabetical cycle fallback when a strict topological order
cannot be formed.

=head2 plan_consolidated_intermediate_signals

Builds the full dependency/filter/order plan for an already normalized
consolidated intermediate-signal set.

=cut
