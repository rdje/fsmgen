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

=back

The paired pass-support owner now keeps signature building, collision
resolution, and new-signal projection, while this package owns the loop and
termination contract.

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

Construct one iterative post-substitution factorization owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[Fixpoint.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
        pass_support => FSM::HDL::Factorization::Fixpoint::PassSupport->new(
            flattened_dt => $flattened_dt,
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
    my $primary_factorizer = $args{primary_factorizer};
    my $max_pass_number = $args{max_passes} // $ctx->{factorization_fixpoint_max_passes} // 16;

    my $primary_intermediate_signals = $pass_support->resolve_primary_intermediate_signals($primary_factorizer);

    fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Starting iterative post-substitution factorization", 3);
    fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Maximum pass number: $max_pass_number", 3);

    my %all_additional_signals;
    my %seen_signatures;
    my $passes_run = 0;
    my $total_substitution_count = 0;
    my $total_update_count = 0;
    my $termination_reason = 'running';

    PASS_LOOP:
    for (my $pass_number = 2; $pass_number <= $max_pass_number; $pass_number++) {
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Starting pass $pass_number", 3);

        my $pass_factorizer = FSM::HDL::ASTFactorization->new(
            min_usage_count => 2,
            debug => debug_enabled(),
            debug_level => 3,
        );

        my $fed_count = $ctx->{enable_graph_factorization_policy_support}->feed_current_asts_to_second_pass($pass_factorizer);
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number fed $fed_count expression(s)", 3);
        if ($fed_count == 0) {
            $termination_reason = 'no_factorizable_post_substitution_expressions';
            last PASS_LOOP;
        }

        my $signature = $pass_support->build_expression_signature($pass_factorizer);
        if (exists $seen_signatures{$signature}) {
            $termination_reason = 'repeated_input_signature';
            fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number repeated expression signature, terminating", 3);
            last PASS_LOOP;
        }
        $seen_signatures{$signature} = 1;

        my $pass_result = $pass_factorizer->analyze_and_factorize();
        my $pass_signals = $pass_result->{intermediate_signals} || {};

        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number results: total=$pass_result->{total_expressions}, unique=$pass_result->{unique_structures}, candidates=$pass_result->{factorization_candidates}", 3);

        if (!%{$pass_signals}) {
            $termination_reason = 'no_new_factorization_candidates';
            last PASS_LOOP;
        }

        $pass_support->rename_colliding_pass_signals(
            $pass_signals,
            \%all_additional_signals,
            $primary_intermediate_signals,
            pass_number => $pass_number,
        );

        my $new_unique_signals = $pass_support->select_new_unique_signals(
            $pass_signals,
            \%all_additional_signals,
            $primary_intermediate_signals,
        );

        my $new_signal_count = scalar(keys %{$new_unique_signals});
        if ($new_signal_count == 0) {
            $termination_reason = 'no_unique_new_intermediate_signals';
            last PASS_LOOP;
        }

        $pass_support->log_new_unique_signals($new_unique_signals, pass_number => $pass_number);

        my $substitution_count = $pass_factorizer->substitute_expressions_with_intermediate_signals(
            $pass_factorizer->{ast_expressions},
        );
        $total_substitution_count += $substitution_count;
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number substitutions: $substitution_count", 3);

        my $update_count = $ctx->{enable_graph_factorization_support}->update_original_asts_with_second_pass_substitutions($pass_factorizer);
        $total_update_count += $update_count;
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number original AST updates: $update_count", 3);

        for my $signal_name (sort keys %{$new_unique_signals}) {
            $all_additional_signals{$signal_name} = $new_unique_signals->{$signal_name};
            $primary_intermediate_signals->{$signal_name} = $new_unique_signals->{$signal_name};
        }

        $passes_run++;

        if ($substitution_count == 0) {
            $termination_reason = "no_substitution_progress_pass_$pass_number";
            last PASS_LOOP;
        }
    }

    if ($termination_reason eq 'running') {
        $termination_reason = "max_pass_limit_reached_$max_pass_number";
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] WARNING: reached pass cap $max_pass_number", 3);
    }

    fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Completed: additional_signals=" . scalar(keys %all_additional_signals) . ", passes_run=$passes_run, substitutions=$total_substitution_count, updates=$total_update_count, reason=$termination_reason", 3);

    return {
        intermediate_signals => \%all_additional_signals,
        passes_run => $passes_run,
        total_substitution_count => $total_substitution_count,
        total_update_count => $total_update_count,
        termination_reason => $termination_reason,
    };
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
