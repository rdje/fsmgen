package FSM::HDL::Factorization::Fixpoint;

=head1 NAME

FSM::HDL::Factorization::Fixpoint - Own iterative post-substitution factorization orchestration

=head1 DESCRIPTION

This package owns the iterative post-substitution factorization loop used by
the older direct generated-module backend. It centralizes:

=over 4

=item *

bounded multi-pass orchestration over post-substitution AST expressions

=item *

termination policy and aggregate result reporting

=item *

delegation of per-pass signal-processing helpers to
C<FSM::HDL::Factorization::Fixpoint::PassSupport>

=item *

delegation of one-pass execution to
C<FSM::HDL::Factorization::Fixpoint::PassExecutionSupport>

=item *

delegation of loop-state lifecycle and aggregate-result normalization to
C<FSM::HDL::Factorization::Fixpoint::LoopStateSupport>

=back

The paired pass-support owner now keeps signature building, collision
resolution, and new-signal projection; the paired pass-execution owner now
keeps one-pass factorizer execution, substitution, and update work; the paired
loop-state owner now keeps aggregate loop-state application and result
normalization; and this package owns pass scheduling and top-level
coordination.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::Factorization::Fixpoint::LoopStateSupport;
use FSM::HDL::Factorization::Fixpoint::PassExecutionSupport;
use FSM::HDL::Factorization::Fixpoint::PassSupport;

=head2 new

Construct one iterative post-substitution factorization owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[Fixpoint.pm][new()] Missing required 'flattened_dt' argument";
    my $pass_support = FSM::HDL::Factorization::Fixpoint::PassSupport->new(
        flattened_dt => $flattened_dt,
    );

    return bless {
        flattened_dt => $flattened_dt,
        pass_support => $pass_support,
        loop_state_support => FSM::HDL::Factorization::Fixpoint::LoopStateSupport->new(
            flattened_dt => $flattened_dt,
        ),
        pass_execution_support => FSM::HDL::Factorization::Fixpoint::PassExecutionSupport->new(
            flattened_dt => $flattened_dt,
            pass_support => $pass_support,
        ),
    }, $class;
}

=head2 run_post_substitution_factorization

Run the iterative post-substitution factorization loop until no new work
remains, a repeated input signature is seen, or the configured pass cap is
reached.

=cut

sub run_post_substitution_factorization ($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $pass_support = $self->{pass_support};
    my $loop_state_support = $self->{loop_state_support};
    my $pass_execution_support = $self->{pass_execution_support};
    my $primary_factorizer = $args{primary_factorizer};
    my $max_pass_number = $args{max_passes} // $ctx->{factorization_fixpoint_max_passes} // 16;

    my $primary_intermediate_signals = $pass_support->resolve_primary_intermediate_signals($primary_factorizer);
    my $loop_state = $loop_state_support->initialize_loop_state();

    fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Starting iterative post-substitution factorization", 3);
    fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Maximum pass number: $max_pass_number", 3);

    PASS_LOOP:
    for (my $pass_number = 2; $pass_number <= $max_pass_number; $pass_number++) {
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Starting pass $pass_number", 3);

        my $pass_outcome = $pass_execution_support->run_factorization_pass(
            pass_number => $pass_number,
            primary_intermediate_signals => $primary_intermediate_signals,
            all_additional_signals => $loop_state->{all_additional_signals},
            seen_signatures => $loop_state->{seen_signatures},
        );

        my $loop_transition = $loop_state_support->apply_pass_outcome(
            $loop_state,
            $pass_outcome,
            $primary_intermediate_signals,
        );

        if ($loop_transition->{terminate}) {
            last PASS_LOOP;
        }
    }

    return $loop_state_support->finalize_loop_result(
        $loop_state,
        max_pass_number => $max_pass_number,
    );
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one iterative post-substitution factorization owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=head2 run_post_substitution_factorization

Runs the iterative post-substitution factorization loop until no new work
remains, a repeated input signature is seen, or the configured pass cap is
reached.

=cut
