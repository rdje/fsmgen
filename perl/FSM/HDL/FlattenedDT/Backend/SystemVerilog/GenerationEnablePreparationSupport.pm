package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport - Own live pre-stage direct SystemVerilog enable preparation

=head1 DESCRIPTION

Owns the bounded live enable-preparation family for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

the non-structural pre-stage HDL preparation that follows scaffold and
internal declaration emission

=item *

the live composition of enable-condition generation, logical-operation
counting, and WEN/EN prescan before the consolidated intermediate stage runs

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport>
now keeps the broader pre-stage prefix assembly, but this package owns the
enable-oriented preparation that must happen after the basic module scaffold
exists and before consolidated intermediate generation can run.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog enable-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationEnablePreparationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_enable_preparation

Generate the direct SystemVerilog enable-condition fragment and prepare the
backend state that must exist before consolidated intermediate generation can
run.

=cut

sub generate_enable_preparation ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);

    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);

    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog enable-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_enable_preparation

Generates the direct SystemVerilog enable-condition fragment and prepares the
backend state that must exist before consolidated intermediate generation can
run.

=cut
