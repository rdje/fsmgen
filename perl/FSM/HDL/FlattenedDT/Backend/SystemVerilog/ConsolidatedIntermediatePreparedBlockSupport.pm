package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport - Own direct prepared consolidated intermediate block projection

=head1 DESCRIPTION

Owns the bounded prepared-block projection family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

projection of the prepared consolidated intermediate block contract from the
already collected normalized signal set plus the already composed plan

=item *

prepared-block debug summary for one direct backend block handoff

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
keeps collection plus planning handoff, and the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
consumes the projected prepared block contract for final HDL rendering.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one prepared consolidated-intermediate block owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediatePreparedBlockSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 build_prepared_consolidated_intermediate_block

Project the prepared consolidated intermediate block contract from the already
collected normalized signal set plus the already composed plan.

=cut

sub build_prepared_consolidated_intermediate_block ($self, $all_intermediate_signals, $plan) {
    my $prepared_block = {
        all_intermediate_signals => $all_intermediate_signals,
        %{$plan},
    };

    fsm_debug(
        "[ConsolidatedIntermediatePreparedBlockSupport.pm][build_prepared_consolidated_intermediate_block()] Prepared consolidated block: total_signals="
          . scalar(keys %{ $all_intermediate_signals || {} })
          . ", kept="
          . ($plan->{total_kept_count} || 0)
          . ", ordered="
          . scalar(@{ $plan->{sorted_signals} || [] }),
        3,
    );

    return $prepared_block;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one prepared consolidated-intermediate block owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=head2 build_prepared_consolidated_intermediate_block

Projects the prepared consolidated intermediate block contract from the
already collected normalized signal set plus the already composed plan.

=cut
