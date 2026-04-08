#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::HDLGenerator;

subtest 'local direct-root aggregate constants resolve scalar leaves in expressions and guards' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_local_aggregate_root.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_local_aggregate_root.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_local_aggregate_root
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (BYTES (8'hA5 8'h3C 0))
    (FRAME ((mode 3) (flag 1)))
    (NEST ((header ((nibble 4'hA))) (tail (1 0))))
    (SETTINGS ((mode 3) (enable 1)))
  )
  (+size
    (SEL 8)
    (OUT 8)
    (FLAG 1)
    (NIBBLE 4)
    (TAIL0 1)
    (HIT 1)
  )
  (idle
    (OUT = BYTES[1])
    (FLAG = FRAME.flag)
    (NIBBLE = NEST.header.nibble)
    (TAIL0 = NEST.tail[0])
    (HIT = 1 <SEL=SETTINGS.mode)
  )
)
FSM
    );

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    my $symbol_summary = $adapter->{signal_manager}->get_symbol_summary;

    is($symbol_summary->{constants}, 4, 'local aggregate constants keep summary counting at declared roots');

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, '3C', 8, 'OUT resolves local aggregate list leaf to a literal');
    is_literal_assignment($assignment_by_target{FLAG}, '1', undef, 'FLAG resolves local aggregate hash leaf to a literal');
    is_literal_assignment($assignment_by_target{NIBBLE}, 'A', 4, 'NIBBLE resolves nested local aggregate hash leaf to a literal');
    is_literal_assignment($assignment_by_target{TAIL0}, '1', undef, 'TAIL0 resolves nested local aggregate list leaf to a literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{HIT}->condition,
        'SEL',
        '3',
        'local aggregate leaf resolves in direct-root condition context',
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    unlike(
        $hdl,
        qr/BYTES\[1\]|FRAME\.flag|NEST\.header\.nibble|SETTINGS\.mode/s,
        'generated HDL lowers local aggregate leaves before emission',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_result = $pipeline->generate_hdl_from_file($fsm_path);
    my $pipeline_hdl = $pipeline_result->{hdl_code};
    unlike(
        $pipeline_hdl,
        qr/BYTES\[1\]|FRAME\.flag|NEST\.header\.nibble|SETTINGS\.mode/s,
        'pipeline output also lowers local aggregate leaves before emission',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts local direct-root aggregate leaves');
    ok(-e $output_path, 'CLI emits HDL for local direct-root aggregate leaves');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for local direct-root aggregate leaves');
    unlike($combined_output, qr/aggregate-valued symbol|mixed aggregate value/s, 'successful direct-root aggregate CLI run does not report aggregate failures');
    unlike(
        $output_text,
        qr/BYTES\[1\]|FRAME\.flag|NEST\.header\.nibble|SETTINGS\.mode/s,
        'CLI output lowers local aggregate leaves before emission',
    );
};

subtest 'local direct-root list aggregate roots lower as whole literals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_local_list_aggregate_root.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_local_list_aggregate_root.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_local_list_aggregate_root
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (BYTES (8'hA5 8'h3C))
    (TAIL (1 0))
    (FRAME ((mode 3) (flag 1)))
  )
  (+size
    (SEL 16)
    (OUT 16)
    (TAIL_OUT 2)
    (HIT 1)
  )
  (idle
    (OUT = BYTES)
    (TAIL_OUT = TAIL)
    (HIT = 1 <SEL=BYTES)
  )
)
FSM
    );

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, '1010010100111100', 16, 'OUT resolves whole local list aggregate root to one literal');
    is_literal_assignment($assignment_by_target{TAIL_OUT}, '10', 2, 'TAIL_OUT resolves nested local list aggregate root to one literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{HIT}->condition,
        'SEL',
        '1010010100111100',
        'whole local list aggregate root resolves in direct-root condition context',
    );
    is(
        $conditional_by_target{HIT}->condition->right->width,
        16,
        'whole local list aggregate root preserves width in condition context',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_result = $pipeline->generate_hdl_from_file($fsm_path);
    my $pipeline_hdl = $pipeline_result->{hdl_code};
    unlike(
        $pipeline_hdl,
        qr/\bBYTES\b|\bTAIL\b/s,
        'pipeline output lowers whole local list aggregate roots before emission',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts whole local list aggregate roots');
    ok(-e $output_path, 'CLI emits HDL for whole local list aggregate roots');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for whole local list aggregate roots');
    unlike($combined_output, qr/Unsupported aggregate-valued symbol|whole aggregate roots/s, 'successful whole-list aggregate CLI run does not report aggregate-root failures');
    unlike(
        $output_text,
        qr/\bBYTES\b|\bTAIL\b/s,
        'CLI output lowers whole local list aggregate roots before emission',
    );
};

subtest 'local aggregate values resolve same-scope constants and enums regardless of declaration order' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_local_named_aggregate_values.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_local_named_aggregate_values.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_local_named_aggregate_values
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (PACKET (HEADER mode.IDLE))
    (FLAGS ((busy mode.BUSY)))
    (HEADER (mode.BUSY RESET_BYTE))
    (RESET_BYTE 8'hA5)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (+size
    (SEL 10)
    (OUT 10)
    (FLAG 1)
    (HIT 1)
  )
  (idle
    (OUT = PACKET)
    (FLAG = FLAGS.busy)
    (HIT = 1 <SEL=PACKET)
  )
)
FSM
    );

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, '1101001010', 10, 'OUT resolves nested named aggregate roots to one literal');
    is_literal_assignment($assignment_by_target{FLAG}, '1', undef, 'FLAG resolves enum-backed aggregate leaves to a literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{HIT}->condition,
        'SEL',
        '1101001010',
        'named aggregate roots also resolve in direct-root condition context',
    );
    is(
        $conditional_by_target{HIT}->condition->right->width,
        10,
        'named aggregate roots preserve width in condition context',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_result = $pipeline->generate_hdl_from_file($fsm_path);
    my $pipeline_hdl = $pipeline_result->{hdl_code};
    unlike(
        $pipeline_hdl,
        qr/\bPACKET\b|\bHEADER\b|\bRESET_BYTE\b|mode\.BUSY|FLAGS\.busy/s,
        'pipeline output lowers named aggregate ingredients before emission',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts named aggregate ingredients inside local constants');
    ok(-e $output_path, 'CLI emits HDL for named aggregate ingredients inside local constants');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for named aggregate ingredients inside local constants');
    unlike($combined_output, qr/Malformed '\+constants' entry|aggregate-valued symbol/s, 'successful named-aggregate CLI run does not report aggregate-symbol failures');
    unlike(
        $output_text,
        qr/\bPACKET\b|\bHEADER\b|\bRESET_BYTE\b|mode\.BUSY|FLAGS\.busy/s,
        'CLI output lowers named aggregate ingredients before emission',
    );
};

subtest 'direct-root declarative symbol cycles fail explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_local_symbol_cycle.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_local_symbol_cycle.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_local_symbol_cycle
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (A B)
    (B A)
  )
  (+size
    (OUT 1)
  )
  (idle
    (OUT = A)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Malformed declarative symbol scope in source 'direct_local_symbol_cycle'.*Cycle:\s*constant 'A' -> constant 'B' -> constant 'A'/s,
        'pipeline reports the explicit direct-root symbol dependency cycle',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects direct-root declarative symbol cycles');
    ok(!-e $output_path, 'CLI does not emit HDL for direct-root declarative symbol cycles');
    like(
        $combined_output,
        qr/Malformed declarative symbol scope in source 'direct_local_symbol_cycle'.*Cycle:\s*constant 'A' -> constant 'B' -> constant 'A'/s,
        'CLI surfaces the explicit direct-root symbol dependency cycle',
    );
    isnt($error_code, 0, 'CLI exits non-zero for direct-root declarative symbol cycles');
};

subtest 'pipeline and CLI resolve whole local map aggregate roots in direct-root expressions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_local_map_aggregate_root.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_local_map_aggregate_root.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_local_map_aggregate_root
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (FRAME ((mode 2'b10) (flag 1)))
  )
  (+size
    (SEL 3)
    (OUT 3)
    (HIT 1)
  )
  (idle
    (OUT = FRAME)
    (HIT = 1 <SEL=FRAME)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $fsm_module = $result->{fsm_module};
    my $hdl = $result->{hdl_code};

    my %assignment_by_target = %{ assignments_by_target($fsm_module, 'idle') };
    is_literal_assignment($assignment_by_target{OUT}, '101', 3, 'OUT resolves whole local map aggregate root to one literal');

    my %conditional_by_target = %{ conditionals_by_target($fsm_module, 'idle') };
    assert_condition_equality(
        $conditional_by_target{HIT}->condition,
        'SEL',
        '101',
        'whole local map aggregate root resolves in direct-root condition context',
    );
    is(
        $conditional_by_target{HIT}->condition->right->width,
        3,
        'whole local map aggregate root preserves packed width in condition context',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts whole local map aggregate roots');
    ok(-e $output_path, 'CLI emits HDL for whole local map aggregate roots');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for whole local map aggregate roots');
    unlike($combined_output, qr/Unsupported aggregate-valued symbol|packed literal/s, 'successful whole-map aggregate CLI run does not report aggregate-root failures');
    unlike(
        $hdl,
        qr/\bFRAME\b/s,
        'pipeline output lowers whole local map aggregate roots before emission',
    );
    unlike(
        $output_text,
        qr/\bFRAME\b/s,
        'CLI output lowers whole local map aggregate roots before emission',
    );
};

subtest 'pipeline and CLI reject mixed local aggregate value shapes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_local_aggregate_shape.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_local_aggregate_shape.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_local_aggregate_shape
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (BROKEN ((mode 3) 0))
  )
  (+size
    (OUT 1)
  )
  (idle
    (OUT = 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    ok($pipeline_error, 'pipeline rejects mixed local aggregate value shapes');
    like(
        $pipeline_error,
        qr/mixed aggregate value/s,
        'pipeline surfaces the mixed local aggregate boundary',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects mixed local aggregate value shapes');
    ok(!-e $output_path, 'CLI does not emit HDL for mixed local aggregate value shapes');
    like(
        $combined_output,
        qr/mixed aggregate value/s,
        'CLI surfaces the mixed local aggregate boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for mixed local aggregate value shapes');
};

done_testing();

sub assignments_by_target {
    my ($fsm_module, $state_name) = @_;
    my %assignments;
    my ($state) = grep { $_->name eq $state_name } @{ $fsm_module->states || [] };
    return \%assignments unless $state;

    for my $dt (@{ $state->decision_trees || [] }) {
        for my $element (@{ $dt->elements || [] }) {
            next unless $element->isa('FSM::CoreAST::Assignment') || $element->isa('FSM::CoreAST::RegisterAssignment');
            my $target_name = extract_target_name($element);
            $assignments{$target_name} = $element if defined $target_name;
        }
    }

    return \%assignments;
}

sub conditionals_by_target {
    my ($fsm_module, $state_name) = @_;
    my %conditionals;
    my ($state) = grep { $_->name eq $state_name } @{ $fsm_module->states || [] };
    return \%conditionals unless $state;

    for my $dt (@{ $state->decision_trees || [] }) {
        for my $element (@{ $dt->elements || [] }) {
            next unless $element->isa('FSM::CoreAST::ConditionalBranch');
            my $assignment = $element->branches->[0]{actions}[0];
            my $target_name = extract_target_name($assignment);
            $conditionals{$target_name} = $element if defined $target_name;
        }
    }

    return \%conditionals;
}

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub is_literal_assignment {
    my ($assignment, $expected_value, $expected_width, $label) = @_;
    ok($assignment, "$label assignment exists");
    return unless $assignment;

    ok($assignment->source->isa('FSM::CoreAST::Literal'), "$label source is stored as a literal");
    return unless $assignment->source->isa('FSM::CoreAST::Literal');

    is($assignment->source->value, $expected_value, "$label value matches");
    if (defined $expected_width) {
        is($assignment->source->width, $expected_width, "$label width matches");
    } else {
        ok(!defined($assignment->source->width), "$label width remains implicit");
    }
}

sub assert_condition_equality {
    my ($condition, $lhs_name, $rhs_value, $label) = @_;
    ok($condition->isa('FSM::CoreAST::BinaryOp'), "$label condition is a BinaryOp");
    return unless $condition->isa('FSM::CoreAST::BinaryOp');

    is($condition->operator, '==', "$label uses equality comparison");
    ok($condition->left->isa('FSM::CoreAST::SignalRef'), "$label left operand is a signal reference");
    ok($condition->right->isa('FSM::CoreAST::Literal'), "$label right operand is a literal");
    return unless $condition->left->isa('FSM::CoreAST::SignalRef') && $condition->right->isa('FSM::CoreAST::Literal');

    is($condition->left->signal->name, $lhs_name, "$label left signal matches");
    is($condition->right->value, $rhs_value, "$label right literal matches");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
