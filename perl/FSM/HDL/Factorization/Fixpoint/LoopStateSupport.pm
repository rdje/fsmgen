package FSM::HDL::Factorization::Fixpoint::LoopStateSupport;

=head1 NAME

FSM::HDL::Factorization::Fixpoint::LoopStateSupport - Own loop-state lifecycle for iterative post-substitution factorization

=head1 DESCRIPTION

This package owns the bounded loop-state and aggregate-result family around the
iterative post-substitution factorization path. It centralizes:

=over 4

=item *

initial loop-state creation for accepted signals, repeated-signature tracking,
and aggregate counters

=item *

application of one accepted pass outcome back into aggregate loop state

=item *

final termination normalization and aggregate-result projection after the loop
ends

=back

The paired C<FSM::HDL::Factorization::Fixpoint::PassExecutionSupport> owner
keeps one-pass execution, the paired
C<FSM::HDL::Factorization::Fixpoint::PassSupport> owner keeps per-pass helper
logic, and the paired C<FSM::HDL::Factorization::Fixpoint> owner keeps pass
scheduling and top-level coordination.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one fixpoint loop-state owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[LoopStateSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 initialize_loop_state

Create the fresh aggregate loop-state record used by the outer iterative
post-substitution factorization loop.

=cut

sub initialize_loop_state ($self) {
    return {
        all_additional_signals => {},
        seen_signatures => {},
        passes_run => 0,
        total_substitution_count => 0,
        total_update_count => 0,
        termination_reason => 'running',
    };
}

=head2 apply_pass_outcome

Apply one pass outcome to aggregate loop state, including accepted-signal
adoption, aggregate counter updates, and termination-state transitions.

=cut

sub apply_pass_outcome ($self, $loop_state, $pass_outcome, $primary_intermediate_signals) {
    $loop_state ||= $self->initialize_loop_state();
    $pass_outcome ||= {};
    $primary_intermediate_signals ||= {};

    if (($pass_outcome->{status} || '') eq 'terminate') {
        $loop_state->{termination_reason} = $pass_outcome->{termination_reason};
        return {
            terminate => 1,
            accepted => 0,
        };
    }

    $loop_state->{total_substitution_count} += $pass_outcome->{substitution_count} || 0;
    $loop_state->{total_update_count} += $pass_outcome->{update_count} || 0;

    for my $signal_name (sort keys %{ $pass_outcome->{new_unique_signals} || {} }) {
        $loop_state->{all_additional_signals}{$signal_name} = $pass_outcome->{new_unique_signals}{$signal_name};
        $primary_intermediate_signals->{$signal_name} = $pass_outcome->{new_unique_signals}{$signal_name};
    }

    $loop_state->{passes_run}++;

    if (($pass_outcome->{status} || '') eq 'terminate_after_accept') {
        $loop_state->{termination_reason} = $pass_outcome->{termination_reason};
        return {
            terminate => 1,
            accepted => 1,
        };
    }

    return {
        terminate => 0,
        accepted => 1,
    };
}

=head2 finalize_loop_result

Normalize the final termination reason and project aggregate loop state into
the public fixpoint result contract.

=cut

sub finalize_loop_result ($self, $loop_state, %args) {
    my $max_pass_number = $args{max_pass_number} // '?';
    $loop_state ||= $self->initialize_loop_state();

    if (($loop_state->{termination_reason} || 'running') eq 'running') {
        $loop_state->{termination_reason} = "max_pass_limit_reached_$max_pass_number";
        fsm_debug("[LoopStateSupport.pm][finalize_loop_result()] WARNING: reached pass cap $max_pass_number", 3);
    }

    fsm_debug(
        "[LoopStateSupport.pm][finalize_loop_result()] Completed: additional_signals="
          . scalar(keys %{ $loop_state->{all_additional_signals} || {} })
          . ", passes_run=$loop_state->{passes_run}, substitutions=$loop_state->{total_substitution_count}, updates=$loop_state->{total_update_count}, reason=$loop_state->{termination_reason}",
        3,
    );

    return {
        intermediate_signals => $loop_state->{all_additional_signals},
        passes_run => $loop_state->{passes_run},
        total_substitution_count => $loop_state->{total_substitution_count},
        total_update_count => $loop_state->{total_update_count},
        termination_reason => $loop_state->{termination_reason},
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one fixpoint loop-state owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 initialize_loop_state

Creates the fresh aggregate loop-state record used by the outer iterative
post-substitution factorization loop.

=head2 apply_pass_outcome

Applies one pass outcome to aggregate loop state, including accepted-signal
adoption, aggregate counter updates, and termination-state transitions.

=head2 finalize_loop_result

Normalizes the final termination reason and projects aggregate loop state into
the public fixpoint result contract.

=cut
