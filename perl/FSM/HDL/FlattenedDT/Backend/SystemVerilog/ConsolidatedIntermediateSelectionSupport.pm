package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport - Own dependency-aware consolidated intermediate rescue and final selection

=head1 DESCRIPTION

Owns the bounded selection family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

dependency-aware rescue of filtered intermediates required by kept signals

=item *

selection summary metadata for the final kept and filtered sets

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport>
now owns the initial AST-first keep/filter partition over the normalized
signal set. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
now owns dependency-map construction, dependency-safe ordering, and overall plan
composition, while this package owns the narrower “which filtered signals get
rescued and what is the final kept/filtered summary?” side of the direct
backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one consolidated-intermediate selection owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateSelectionSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 filter_consolidated_signals

Apply the dependency-aware consolidated-intermediate keep/filter/rescue plan
and return the resulting filtered set plus intermediate selection metadata.

=cut

sub filter_consolidated_signals ($self, $all_intermediate_signals, $signal_dependencies) {
    my $ctx = $self->{flattened_dt};
    my $classification = $ctx->{backend_sv_consolidated_intermediate_classification_support}
        ->classify_consolidated_signals($all_intermediate_signals);
    my %initially_filtered_signals = %{ $classification->{initially_filtered_signals} || {} };
    my %initially_kept_signals = %{ $classification->{initially_kept_signals} || {} };
    my %rescued_signals;
    my %visited_signal_dependencies;
    my @pending_signals = sort keys %initially_kept_signals;

    while (@pending_signals) {
        my $current_signal = shift @pending_signals;
        next if $visited_signal_dependencies{$current_signal}++;
        next unless $signal_dependencies->{$current_signal};

        for my $dependency (sort @{ $signal_dependencies->{$current_signal} }) {
            next unless exists $initially_kept_signals{$dependency}
                || exists $initially_filtered_signals{$dependency};

            if ($initially_filtered_signals{$dependency} && !$rescued_signals{$dependency}) {
                $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] RESCUED: '$dependency' is needed by '$current_signal'", 3);
            }

            push @pending_signals, $dependency
                unless $visited_signal_dependencies{$dependency};
        }
    }

    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    my %finally_filtered_signals = %initially_filtered_signals;
    delete @finally_filtered_signals{keys %rescued_signals};

    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %finally_filtered_signals);
    my $total_kept = scalar(keys %filtered_signals);

    fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] Summary: initially_kept=$initially_kept_count rescued=$rescued_count filtered=$filtered_count total_kept=$total_kept", 3);

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

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate selection owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 filter_consolidated_signals

Applies the dependency-aware consolidated-intermediate keep/filter/rescue plan
and returns the resulting filtered set plus intermediate selection metadata.
This owner now starts from the extracted initial classification owner and then
applies dependency-aware rescue plus final kept/filtered summary projection.

=cut
