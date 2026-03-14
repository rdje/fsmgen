package FSM::HDL::Factorization::Fixpoint;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::ASTFactorization;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[Fixpoint.pm][new()] Missing required 'flattened_dt' argument";
    
    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub run_post_substitution_factorization ($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $primary_factorizer = $args{primary_factorizer};
    my $max_pass_number = $args{max_passes} // $ctx->{factorization_fixpoint_max_passes} // 16;
    
    my $primary_intermediate_signals = {};
    if ($primary_factorizer) {
        $primary_factorizer->{intermediate_signals} ||= {};
        $primary_intermediate_signals = $primary_factorizer->{intermediate_signals};
    }
    
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
        
        my $fed_count = $ctx->{enable_graph}->feed_current_asts_to_second_pass($pass_factorizer);
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number fed $fed_count expression(s)", 3);
        if ($fed_count == 0) {
            $termination_reason = 'no_factorizable_post_substitution_expressions';
            last PASS_LOOP;
        }
        
        my $signature = $self->_build_expression_signature($pass_factorizer);
        if (exists $seen_signatures{$signature}) {
            $termination_reason = 'repeated_input_signature';
            fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number repeated expression signature, terminating", 3);
            last PASS_LOOP;
        }
        $seen_signatures{$signature} = 1;
        
        my $pass_result = $pass_factorizer->analyze_and_factorize();
        my $pass_signals = $pass_result->{intermediate_signals} || {};
        
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number results: total=$pass_result->{total_expressions}, unique=$pass_result->{unique_structures}, candidates=$pass_result->{factorization_candidates}", 3);
        
        if (!%$pass_signals) {
            $termination_reason = 'no_new_factorization_candidates';
            last PASS_LOOP;
        }
        
        my %reserved_names = map { $_ => 1 } (keys %all_additional_signals, keys %$primary_intermediate_signals);
        for my $signal_name (sort keys %$pass_signals) {
            next unless $reserved_names{$signal_name};
            my $base_name = $signal_name;
            my $counter = 1;
            my $unique_name = "${base_name}_${counter}";
            while ($reserved_names{$unique_name} || exists $pass_signals->{$unique_name}) {
                $counter++;
                $unique_name = "${base_name}_${counter}";
            }
            $pass_signals->{$unique_name} = delete $pass_signals->{$signal_name};
            $reserved_names{$unique_name} = 1;
            fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number renamed colliding signal '$signal_name' -> '$unique_name'", 3);
        }
        
        my %new_unique_signals;
        for my $signal_name (sort keys %$pass_signals) {
            next if exists $all_additional_signals{$signal_name};
            next if exists $primary_intermediate_signals->{$signal_name};
            $new_unique_signals{$signal_name} = $pass_signals->{$signal_name};
        }
        
        my $new_signal_count = scalar(keys %new_unique_signals);
        if ($new_signal_count == 0) {
            $termination_reason = 'no_unique_new_intermediate_signals';
            last PASS_LOOP;
        }
        
        for my $signal_name (sort keys %new_unique_signals) {
            my $signal_info = $new_unique_signals{$signal_name};
            my $expression_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($signal_info->{ast}) } || '[NO SV REPRESENTATION]';
            fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number new signal $signal_name = $expression_sv (usage=$signal_info->{usage_count})", 3);
        }
        
        my $substitution_count = $pass_factorizer->substitute_expressions_with_intermediate_signals(
            $pass_factorizer->{ast_expressions},
        );
        $total_substitution_count += $substitution_count;
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number substitutions: $substitution_count", 3);
        
        my $update_count = $ctx->{enable_graph}->update_original_asts_with_second_pass_substitutions($pass_factorizer);
        $total_update_count += $update_count;
        fsm_debug("[Fixpoint.pm][run_post_substitution_factorization()] Pass $pass_number original AST updates: $update_count", 3);
        
        for my $signal_name (sort keys %new_unique_signals) {
            $all_additional_signals{$signal_name} = $new_unique_signals{$signal_name};
            $primary_intermediate_signals->{$signal_name} = $new_unique_signals{$signal_name};
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

sub _build_expression_signature ($self, $pass_factorizer) {
    my $ctx = $self->{flattened_dt};
    my @parts;
    
    for my $expr_info (@{$pass_factorizer->{ast_expressions} || []}) {
        my $context = $expr_info->{context} // 'unknown_context';
        my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($expr_info->{ast}) } || '[NO SV REPRESENTATION]';
        push @parts, "$context=$sv";
    }
    
    @parts = sort @parts;
    return join(' || ', @parts);
}

1;
