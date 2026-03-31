package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport - Own live pre-stage direct SystemVerilog prescan preparation

=head1 DESCRIPTION

Owns the bounded live prescan-preparation family for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

the non-emitting preparation that must happen after enable-condition emission
and before consolidated intermediate generation can run

=item *

the live composition of logical-operation counting plus WEN/EN prescan over
the prepared direct backend state

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now reaches this owner
directly after enable-condition generation, and this package owns the
side-effect preparation that seeds factorization counts and
intermediate-signal discovery for the direct backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog prescan-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationPrescanPreparationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 prepare_enable_prescan

Run the direct backend logical-operation counting and WEN/EN prescan that
must happen before consolidated intermediate generation can run.

=cut

sub prepare_enable_prescan ($self) {
    my $ctx = $self->{flattened_dt};

    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);

    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);

    return;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog prescan-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 prepare_enable_prescan

Runs the direct backend logical-operation counting and WEN/EN prescan that
must happen before consolidated intermediate generation can run.

=cut
