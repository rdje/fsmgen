package FSM::HDL::Factorization::Fixpoint::PassExecutionSupport;

=head1 NAME

FSM::HDL::Factorization::Fixpoint::PassExecutionSupport - Own one-pass execution for iterative post-substitution factorization

=head1 DESCRIPTION

This package owns the bounded single-pass execution family around the
iterative post-substitution factorization loop. It centralizes:

=over 4

=item *

second-pass factorizer construction and AST feed handoff

=item *

repeated-signature short-circuit detection for one prepared pass

=item *

per-pass factorization, substitution, and owner-side AST update execution

=back

The paired C<FSM::HDL::Factorization::Fixpoint::PassSupport> owner keeps the
signature/collision/new-signal helper family, while the paired
C<FSM::HDL::Factorization::Fixpoint::LoopStateSupport> owner keeps aggregate
loop-state application and result normalization, and the paired
C<FSM::HDL::Factorization::Fixpoint> owner keeps pass scheduling and top-level
coordination.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::ASTFactorization;
use FSM::HDL::Factorization::Fixpoint::PassSupport;

=head2 new

Construct one fixpoint pass-execution owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[PassExecutionSupport.pm][new()] Missing required 'flattened_dt' argument";
    my $pass_support = $args{pass_support}
      || FSM::HDL::Factorization::Fixpoint::PassSupport->new(
            flattened_dt => $flattened_dt,
        );

    return bless {
        flattened_dt => $flattened_dt,
        pass_support => $pass_support,
    }, $class;
}

=head2 run_factorization_pass

Run one prepared post-substitution factorization pass and return the bounded
per-pass outcome contract used by the outer fixpoint loop.

=cut

sub run_factorization_pass ($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $pass_support = $args{pass_support} || $self->{pass_support};
    my $pass_number = $args{pass_number} // '?';
    my $primary_intermediate_signals = $args{primary_intermediate_signals} || {};
    my $all_additional_signals = $args{all_additional_signals} || {};
    my $seen_signatures = $args{seen_signatures} || {};

    my $pass_factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3,
    );

    my $fed_count = $ctx->{enable_graph_factorization_policy_support}->feed_current_asts_to_second_pass($pass_factorizer);
    fsm_debug("[PassExecutionSupport.pm][run_factorization_pass()] Pass $pass_number fed $fed_count expression(s)", 3);
    if ($fed_count == 0) {
        return {
            status => 'terminate',
            termination_reason => 'no_factorizable_post_substitution_expressions',
            fed_count => $fed_count,
            signature => undef,
            total_expressions => 0,
            unique_structures => 0,
            factorization_candidates => 0,
            rename_count => 0,
            new_unique_signals => {},
            new_signal_count => 0,
            substitution_count => 0,
            update_count => 0,
        };
    }

    my $signature = $pass_support->build_expression_signature($pass_factorizer);
    if (exists $seen_signatures->{$signature}) {
        fsm_debug("[PassExecutionSupport.pm][run_factorization_pass()] Pass $pass_number repeated expression signature, terminating", 3);
        return {
            status => 'terminate',
            termination_reason => 'repeated_input_signature',
            fed_count => $fed_count,
            signature => $signature,
            total_expressions => 0,
            unique_structures => 0,
            factorization_candidates => 0,
            rename_count => 0,
            new_unique_signals => {},
            new_signal_count => 0,
            substitution_count => 0,
            update_count => 0,
        };
    }
    $seen_signatures->{$signature} = 1;

    my $pass_result = $pass_factorizer->analyze_and_factorize();
    my $pass_signals = $pass_result->{intermediate_signals} || {};
    my $total_expressions = $pass_result->{total_expressions} || 0;
    my $unique_structures = $pass_result->{unique_structures} || 0;
    my $factorization_candidates = $pass_result->{factorization_candidates} || 0;

    fsm_debug("[PassExecutionSupport.pm][run_factorization_pass()] Pass $pass_number results: total=$total_expressions, unique=$unique_structures, candidates=$factorization_candidates", 3);

    if (!%{$pass_signals}) {
        return {
            status => 'terminate',
            termination_reason => 'no_new_factorization_candidates',
            fed_count => $fed_count,
            signature => $signature,
            total_expressions => $total_expressions,
            unique_structures => $unique_structures,
            factorization_candidates => $factorization_candidates,
            rename_count => 0,
            new_unique_signals => {},
            new_signal_count => 0,
            substitution_count => 0,
            update_count => 0,
        };
    }

    my $rename_count = $pass_support->rename_colliding_pass_signals(
        $pass_signals,
        $all_additional_signals,
        $primary_intermediate_signals,
        pass_number => $pass_number,
    );

    my $new_unique_signals = $pass_support->select_new_unique_signals(
        $pass_signals,
        $all_additional_signals,
        $primary_intermediate_signals,
    );
    my $new_signal_count = scalar(keys %{$new_unique_signals});
    if ($new_signal_count == 0) {
        return {
            status => 'terminate',
            termination_reason => 'no_unique_new_intermediate_signals',
            fed_count => $fed_count,
            signature => $signature,
            total_expressions => $total_expressions,
            unique_structures => $unique_structures,
            factorization_candidates => $factorization_candidates,
            rename_count => $rename_count,
            new_unique_signals => $new_unique_signals,
            new_signal_count => 0,
            substitution_count => 0,
            update_count => 0,
        };
    }

    $pass_support->log_new_unique_signals($new_unique_signals, pass_number => $pass_number);

    my $substitution_count = $pass_factorizer->substitute_expressions_with_intermediate_signals(
        $pass_factorizer->{ast_expressions},
    );
    fsm_debug("[PassExecutionSupport.pm][run_factorization_pass()] Pass $pass_number substitutions: $substitution_count", 3);

    my $update_count = $ctx->{enable_graph_factorization_support}->update_original_asts_with_second_pass_substitutions($pass_factorizer);
    fsm_debug("[PassExecutionSupport.pm][run_factorization_pass()] Pass $pass_number original AST updates: $update_count", 3);

    my $status = $substitution_count == 0 ? 'terminate_after_accept' : 'continue';
    my $termination_reason = $substitution_count == 0
        ? "no_substitution_progress_pass_$pass_number"
        : undef;

    return {
        status => $status,
        termination_reason => $termination_reason,
        fed_count => $fed_count,
        signature => $signature,
        total_expressions => $total_expressions,
        unique_structures => $unique_structures,
        factorization_candidates => $factorization_candidates,
        rename_count => $rename_count,
        new_unique_signals => $new_unique_signals,
        new_signal_count => $new_signal_count,
        substitution_count => $substitution_count,
        update_count => $update_count,
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one fixpoint pass-execution owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 run_factorization_pass

Runs one prepared post-substitution factorization pass and returns the bounded
per-pass outcome contract used by the outer fixpoint loop.

=cut
