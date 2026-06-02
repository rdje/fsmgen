package FSM::Backend::GeneratedModuleEmitter;

=head1 NAME

FSM::Backend::GeneratedModuleEmitter - Direct generated-module HDL backend support

=head1 DESCRIPTION

Owns the bounded direct generated-module backend path that still serves
direct-root FSM/DT generation and realized generated children. This package
drives the existing C<FSM::HDL::FlattenedDT> backend family, exposes the
target-language backend selection rule, collects backend statistics, and owns
the verification-only assertion postprocessing that augments generated HDL
after lowered analysis is available.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::FlattenedDT;

sub emit_from_fsm_module ($class, %args) {
    my $fsm_module = $args{fsm_module}
        or confess "GeneratedModuleEmitter requires a fsm_module";
    my $target_language = $args{target_language} // 'systemverilog';
    my $debug_level = $args{debug_level} // 0;

    fsm_trace_enter('Generate HDL code from semantic FSM module', 2);
    fsm_debug("Generating HDL code", 1);

    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => ($debug_level > 0));
    my $generator_method = $class->generator_method_for_target($target_language);

    fsm_debug("Using generator method: $generator_method", 1);

    my $hdl_code;
    eval {
        $hdl_code = $hdl_generator->$generator_method($fsm_module);
    };

    if ($@) {
        fsm_trace_decision(0, "HDL backend method '$generator_method' raised exception", 1);
        confess "Error generating HDL: $@\n";
    }

    fsm_debug("HDL code generation completed", 1);
    fsm_trace_exit("HDL generation complete via '$generator_method'", 2);

    return {
        hdl_code => $hdl_code,
        hdl_generator => $hdl_generator,
        generator_method => $generator_method,
        statistics => $class->statistics_from_generator($hdl_generator),
    };
}

sub generator_method_for_target ($class, $target_language = 'systemverilog') {
    fsm_trace_enter('Resolve backend generator method for target language', 4);
    my %language_methods = (
        vhdl => 'generate_vhdl',
        verilog => 'generate_verilog',
        v => 'generate_verilog',
        systemverilog => 'generate_systemverilog',
        sv => 'generate_systemverilog',
    );

    my $method = $language_methods{$target_language} || 'generate_systemverilog';
    fsm_trace_exit("Generator method resolved => $method", 4);
    return $method;
}

sub statistics_from_generator ($class, $hdl_generator = undef) {
    fsm_trace_enter('Gather pipeline generation statistics', 2);
    fsm_debug("Gathering generation statistics", 1);

    my $stats = {
        intermediate_signals => 0,
        global_expressions => 0,
        reused_expressions => [],
        factoring_enabled => 0,
    };

    if ($hdl_generator) {
        my $intermediate_signals = $hdl_generator->{intermediate_signals} || {};
        my $global_expressions = $hdl_generator->{global_expressions} || {};
        my $expression_usage = $hdl_generator->{expression_usage} || {};

        $stats->{intermediate_signals} = scalar(keys %$intermediate_signals);
        $stats->{global_expressions} = scalar(keys %$global_expressions);
        $stats->{factoring_enabled} = (%$intermediate_signals || %$global_expressions) ? 1 : 0;

        my @reused = grep { $expression_usage->{$_} > 1 } keys %$expression_usage;
        for my $signal_name (sort { $expression_usage->{$b} <=> $expression_usage->{$a} } @reused) {
            my $usage = $expression_usage->{$signal_name};
            my $expression = _clone($intermediate_signals->{$signal_name});
            push @{$stats->{reused_expressions}}, {
                signal => $signal_name,
                expression => $expression,
                usage_count => $usage,
            };
        }
        $stats->{raw_intermediate_signals} = _clone($intermediate_signals);
        $stats->{raw_global_expressions} = _clone($global_expressions);
        $stats->{raw_expression_usage} = _clone($expression_usage);
    }

    fsm_debug("Statistics gathering complete", 1);
    fsm_debug("  Intermediate signals: $stats->{intermediate_signals}", 1);
    fsm_debug("  Global expressions: $stats->{global_expressions}", 1);
    fsm_debug("  Reused expressions: " . scalar(@{$stats->{reused_expressions}}), 1);

    fsm_trace_exit('Statistics gathering complete', 2);
    return $stats;
}

sub standalone_dt_assertion_runtime_lines ($class, %args) {
    my $target_language = $args{target_language} // 'systemverilog';
    my $module_info = $args{module_info};

    return () unless $target_language =~ /^(?:systemverilog|sv)$/;
    return () unless ref($module_info) eq 'HASH';

    my @assertion_lines;
    for my $target (@{$module_info->{standalone_dt_multi_drive_targets} || []}) {
        next unless ref($target) eq 'HASH';
        my $assertion = $target->{multi_drive_assertion} || {};
        next unless ($assertion->{input_count} || 0) > 1;

        my @inputs = @{$assertion->{input_enable_signals} || []};
        next unless @inputs;

        my $target_signal = $target->{signal_name} || $assertion->{target_signal} || 'unknown_signal';
        push @assertion_lines,
            "    assert (\$onehot0({" . join(', ', @inputs) . "}))"
                . qq{ else \$error("standalone-dt multi-drive conflict: $target_signal");};
    }

    return () unless @assertion_lines;

    return (
        "  `ifndef SYNTHESIS",
        "  always_comb begin",
        @assertion_lines,
        "  end",
        "  `endif",
    );
}

# ISF-ASSERT: project `(assert COND [message])` invariants (surfaced into module_info) to
# verification-only SV — a combinational `assert (COND)` per invariant, under `ifndef
# SYNTHESIS`. Verilog (non-SV) output stays assertion-free, like the other assertion kinds.
sub immediate_assertion_runtime_lines ($class, %args) {
    my $target_language = $args{target_language} // 'systemverilog';
    my $module_info = $args{module_info};

    return () unless $target_language =~ /^(?:systemverilog|sv)$/;
    return () unless ref($module_info) eq 'HASH';

    my @assertion_lines;
    for my $assertion (@{$module_info->{immediate_assertions} || []}) {
        next unless ref($assertion) eq 'HASH';
        my $condition = $assertion->{condition_sv};
        next unless defined($condition) && length($condition);
        my $message = _sv_message_fragment(
            $assertion->{message} // ('assertion failed: ' . ($assertion->{name} // 'assert')));
        push @assertion_lines, qq{    assert ($condition) else \$error("$message");};
    }

    return () unless @assertion_lines;

    return (
        "  `ifndef SYNTHESIS",
        "  always_comb begin",
        @assertion_lines,
        "  end",
        "  `endif",
    );
}

sub selector_conflict_assertion_runtime_lines ($class, %args) {
    my $target_language = $args{target_language} // 'systemverilog';
    my $module_info = $args{module_info};

    return () unless $target_language =~ /^(?:systemverilog|sv)$/;
    return () unless ref($module_info) eq 'HASH';
    return () if ($module_info->{source_root_kind} || '') eq 'dt';

    my @assertion_lines;
    for my $target (@{$module_info->{selector_conflict_targets} || []}) {
        next unless ref($target) eq 'HASH';
        my $target_signal = $target->{signal_name} || 'unknown_signal';
        my $escaped_target = _sv_message_fragment($target_signal);

        for my $family (@{$target->{rhs_enable_families} || []}) {
            next unless ref($family) eq 'HASH';
            my $assertion = $family->{same_value_assertion} || {};
            next unless ($assertion->{input_count} || 0) > 1;

            my @inputs = @{$assertion->{input_enable_signals} || []};
            next unless @inputs;

            my $rhs_value = _sv_message_fragment($family->{rhs_value} // $assertion->{rhs_value} // 'unknown_value');
            push @assertion_lines,
                "    assert (\$onehot0({" . join(', ', @inputs) . "}))"
                    . qq{ else \$error("selector same-value conflict: $escaped_target $rhs_value");};
        }

        my $multi_value_assertion = $target->{multi_value_assertion} || {};
        next unless ($multi_value_assertion->{input_count} || 0) > 1;

        my @inputs = @{$multi_value_assertion->{input_enable_signals} || []};
        next unless @inputs;

        push @assertion_lines,
            "    assert (\$onehot0({" . join(', ', @inputs) . "}))"
                . qq{ else \$error("selector multi-value conflict: $escaped_target");};
    }

    return () unless @assertion_lines;

    return (
        "  `ifndef SYNTHESIS",
        "  always_comb begin",
        @assertion_lines,
        "  end",
        "  `endif",
    );
}

sub temporal_contract_assertion_runtime_lines ($class, %args) {
    my $target_language = $args{target_language} // 'systemverilog';
    my $schedule_report = $args{schedule_report};

    return () unless $target_language =~ /^(?:systemverilog|sv)$/;
    return () unless ref($schedule_report) eq 'HASH';

    my $clock = $schedule_report->{clock};
    return () unless defined($clock) && !ref($clock) && length($clock);

    my @assertion_lines;
    for my $contract (@{$schedule_report->{temporal_contracts} || []}) {
        next unless ref($contract) eq 'HASH';
        my $fail_signal = $contract->{fail_signal};
        next unless defined($fail_signal) && !ref($fail_signal) && length($fail_signal);

        my $transaction = _sv_message_fragment($contract->{transaction} // 'unknown_transaction');
        my $name = _sv_message_fragment($contract->{name} // 'unknown_contract');
        push @assertion_lines,
            qq{assert (!$fail_signal) else \$error("temporal contract failed: $transaction.$name");};
    }

    return () unless @assertion_lines;

    my $reset_guard = _temporal_contract_assertion_reset_guard($schedule_report->{reset});
    my @body_lines;
    if (defined($reset_guard) && length($reset_guard)) {
        push @body_lines, "    if ($reset_guard) begin";
        push @body_lines, map { "      $_" } @assertion_lines;
        push @body_lines, "    end";
    } else {
        push @body_lines, map { "    $_" } @assertion_lines;
    }

    return (
        "  `ifndef SYNTHESIS",
        "  always_ff @(posedge $clock) begin",
        @body_lines,
        "  end",
        "  `endif",
    );
}

sub augment_with_standalone_dt_assertions ($class, %args) {
    my $hdl_code = $args{hdl_code};
    my $module_info = $args{module_info};
    my $target_language = $args{target_language} // 'systemverilog';

    return $hdl_code unless defined($hdl_code) && length($hdl_code);

    my @assertion_lines = $class->standalone_dt_assertion_runtime_lines(
        module_info => $module_info,
        target_language => $target_language,
    );
    return $hdl_code unless @assertion_lines;

    my $assertion_block = join("\n", '', @assertion_lines);
    if ($hdl_code =~ s/\nendmodule\s*\z/\n$assertion_block\nendmodule/s) {
        return $hdl_code;
    }

    return $hdl_code . "\n$assertion_block\n";
}

sub augment_with_temporal_contract_assertions ($class, %args) {
    my $hdl_code = $args{hdl_code};
    my $target_language = $args{target_language} // 'systemverilog';

    return $hdl_code unless defined($hdl_code) && length($hdl_code);

    my @assertion_lines = $class->temporal_contract_assertion_runtime_lines(
        schedule_report => $args{schedule_report},
        target_language => $target_language,
    );
    return $hdl_code unless @assertion_lines;

    my $assertion_block = join("\n", '', @assertion_lines);
    if ($hdl_code =~ s/\nendmodule\s*\z/\n$assertion_block\nendmodule/s) {
        return $hdl_code;
    }

    return $hdl_code . "\n$assertion_block\n";
}

sub augment_with_selector_conflict_assertions ($class, %args) {
    my $hdl_code = $args{hdl_code};
    my $module_info = $args{module_info};
    my $target_language = $args{target_language} // 'systemverilog';

    return $hdl_code unless defined($hdl_code) && length($hdl_code);

    my @assertion_lines = $class->selector_conflict_assertion_runtime_lines(
        module_info => $module_info,
        target_language => $target_language,
    );
    return $hdl_code unless @assertion_lines;

    my $assertion_block = join("\n", '', @assertion_lines);
    if ($hdl_code =~ s/\nendmodule\s*\z/\n$assertion_block\nendmodule/s) {
        return $hdl_code;
    }

    return $hdl_code . "\n$assertion_block\n";
}

sub augment_with_immediate_assertions ($class, %args) {
    my $hdl_code = $args{hdl_code};
    my $target_language = $args{target_language} // 'systemverilog';

    return $hdl_code unless defined($hdl_code) && length($hdl_code);

    my @assertion_lines = $class->immediate_assertion_runtime_lines(
        module_info => $args{module_info},
        target_language => $target_language,
    );
    return $hdl_code unless @assertion_lines;

    my $assertion_block = join("\n", '', @assertion_lines);
    if ($hdl_code =~ s/\nendmodule\s*\z/\n$assertion_block\nendmodule/s) {
        return $hdl_code;
    }

    return $hdl_code . "\n$assertion_block\n";
}

sub augment_with_runtime_assertions ($class, %args) {
    my $hdl_code = $args{hdl_code};

    $hdl_code = $class->augment_with_selector_conflict_assertions(
        %args,
        hdl_code => $hdl_code,
    );
    $hdl_code = $class->augment_with_temporal_contract_assertions(
        %args,
        hdl_code => $hdl_code,
    );
    $hdl_code = $class->augment_with_standalone_dt_assertions(
        %args,
        hdl_code => $hdl_code,
    );
    return $class->augment_with_immediate_assertions(
        %args,
        hdl_code => $hdl_code,
    );
}

sub _clone ($value) {
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return [ map { _clone($_) } @$value ] if ref($value) eq 'ARRAY';
    return $value;
}

sub _sv_message_fragment ($value) {
    $value //= '';
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return $value;
}

sub _temporal_contract_assertion_reset_guard ($reset) {
    return undef unless ref($reset) eq 'HASH';
    my $name = $reset->{name};
    return undef unless defined($name) && !ref($name) && length($name);

    my $polarity = $reset->{polarity} // '';
    return $name if $polarity eq 'active_low';
    return "!$name" if $polarity eq 'active_high';
    return undef;
}

1;

__END__

=head1 METHODS

=head2 emit_from_fsm_module

Runs the direct generated-module HDL backend for one semantic FSM/DT module and
returns emitted HDL text, backend handle, the resolved backend method, and the
derived backend statistics snapshot.

=head2 generator_method_for_target

Resolves the current generated-module backend method name for one target
language token.

=head2 statistics_from_generator

Builds the bounded backend-statistics summary from one direct generated-module
backend instance.

=head2 standalone_dt_assertion_runtime_lines

Builds the post-lowering standalone-DT assertion block lines for one generated
module when the current backend target supports those assertions.

=head2 selector_conflict_assertion_runtime_lines

Builds the post-lowering mux-selector assertion block lines for one generated
module when the current backend target supports those assertions.

=head2 temporal_contract_assertion_runtime_lines

Builds verification-only SystemVerilog assertion block lines for ISF temporal
contract summaries when the current backend target supports those assertions.

=head2 augment_with_standalone_dt_assertions

Injects the standalone-DT assertion block into emitted generated HDL when the
lowered module metadata exposes grouped multi-drive targets.

=head2 augment_with_temporal_contract_assertions

Injects the generated ISF temporal-contract assertion block into emitted HDL
when a schedule report exposes bounded temporal-contract summaries.

=head2 augment_with_selector_conflict_assertions

Injects the generated mux-selector assertion block into emitted generated HDL
when lowered module metadata exposes runtime selector conflict targets.

=head2 augment_with_runtime_assertions

Applies all generated-module verification-only assertion augmentations in the
stable post-lowering order.

=cut
