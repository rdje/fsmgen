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
use FSM::Pipeline::HDLGenerator;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'bare inline compound modifiers are supported as delta-1 variants' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:inline_modifier_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (SRC 8)
    (ACC 8)
    (COMB 8)
  )
  (-dt
    (ACC <- SRC (+=))
    (COMB = SRC (-=))
  )
)
FSM

    my ($state) = grep { $_->name eq '-dt' } @{ $fsm_module->states || [] };
    ok($state, 'found standalone DT');
    my @elements = map { @{ $_->elements || [] } } @{ $state->decision_trees || [] };
    is(scalar(@elements), 2, 'standalone DT has the expected number of actions');

    my %assignment_by_target = map { extract_target_name($_) => $_ } @elements;

    is($assignment_by_target{ACC}->operator_symbol, '<-', 'bare inline (+=) keeps register assignment family');
    is($assignment_by_target{ACC}->source_provenance->{compound_operator}, '+=', 'bare inline (+=) records += provenance');
    is($assignment_by_target{ACC}->source_provenance->{compound_delta}, '1', 'bare inline (+=) records delta 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{ACC}->source,
        '+',
        [qw(SRC 1)],
        'bare inline (+=) arithmetic tree'
    );

    is($assignment_by_target{COMB}->operator_symbol, '=', 'bare inline (-=) keeps combinational assignment family');
    is($assignment_by_target{COMB}->source_provenance->{compound_operator}, '-=', 'bare inline (-=) records -= provenance');
    is($assignment_by_target{COMB}->source_provenance->{compound_delta}, '1', 'bare inline (-=) records delta 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{COMB}->source,
        '-',
        [qw(SRC 1)],
        'bare inline (-=) arithmetic tree'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+inline_modifier_contract\b/s, 'inline modifier fixture still generates HDL');
};

subtest 'malformed inline compound modifiers are rejected explicitly' => sub {
    my $payload_error = parse_failure(<<'FSM');
(?fsm:bad_inline_modifier_payload
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (ACC <- SRC (+= 2 3))
  )
)
FSM

    like(
        $payload_error,
        qr/Malformed inline compound modifier '\(\+= 2 3\)' on signal 'ACC'/,
        'multi-token inline modifier payload gets a targeted diagnostic',
    );

    my $duplicate_error = parse_failure(<<'FSM');
(?fsm:bad_inline_modifier_duplicate
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (ACC <- SRC (+= 2) (-= 1))
  )
)
FSM

    like(
        $duplicate_error,
        qr/Duplicate inline compound modifier '\(-= 1\)' on signal 'ACC'/,
        'duplicate inline modifier gets a targeted diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed inline compound modifiers' => sub {
    my $payload_path = write_fsm('bad_inline_modifier_payload_cli.fsm', <<'FSM');
(?fsm:bad_inline_modifier_payload_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (ACC <- SRC (+= 2 3))
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $payload_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($payload_path);
        undef;
    };
    $payload_pipeline_error = $@ if !$payload_pipeline_error;
    ok($payload_pipeline_error, 'pipeline rejects malformed inline modifier payload');
    like(
        $payload_pipeline_error,
        qr/Malformed inline compound modifier '\(\+= 2 3\)' on signal 'ACC'/,
        'pipeline surfaces the inline-modifier payload boundary',
    );

    my $payload_out_path = File::Spec->catfile($tempdir, 'bad_inline_modifier_payload_cli.sv');
    my ($payload_success, $payload_error_message, $payload_full_buf, $payload_stdout_buf, $payload_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $payload_out_path, '--quiet', $payload_path],
    );

    ok(!$payload_success, 'CLI rejects malformed inline modifier payload');
    ok(!-e $payload_out_path, 'CLI does not emit output for malformed inline modifier payload');

    my $payload_combined_output = join(
        '',
        @{ $payload_stdout_buf || [] },
        @{ $payload_stderr_buf || [] },
        ($payload_error_message || ''),
    );

    like(
        $payload_combined_output,
        qr/Malformed inline compound modifier '\(\+= 2 3\)' on signal 'ACC'/,
        'CLI surfaces the inline-modifier payload boundary',
    );

    my $duplicate_path = write_fsm('bad_inline_modifier_duplicate_cli.fsm', <<'FSM');
(?fsm:bad_inline_modifier_duplicate_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (ACC <- SRC (+= 2) (-= 1))
  )
)
FSM

    my $duplicate_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($duplicate_path);
        undef;
    };
    $duplicate_pipeline_error = $@ if !$duplicate_pipeline_error;
    ok($duplicate_pipeline_error, 'pipeline rejects duplicate inline modifier');
    like(
        $duplicate_pipeline_error,
        qr/Duplicate inline compound modifier '\(-= 1\)' on signal 'ACC'/,
        'pipeline surfaces the duplicate inline-modifier boundary',
    );

    my $duplicate_out_path = File::Spec->catfile($tempdir, 'bad_inline_modifier_duplicate_cli.sv');
    my ($duplicate_success, $duplicate_error_message, $duplicate_full_buf, $duplicate_stdout_buf, $duplicate_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $duplicate_out_path, '--quiet', $duplicate_path],
    );

    ok(!$duplicate_success, 'CLI rejects duplicate inline modifier');
    ok(!-e $duplicate_out_path, 'CLI does not emit output for duplicate inline modifier');

    my $duplicate_combined_output = join(
        '',
        @{ $duplicate_stdout_buf || [] },
        @{ $duplicate_stderr_buf || [] },
        ($duplicate_error_message || ''),
    );

    like(
        $duplicate_combined_output,
        qr/Duplicate inline compound modifier '\(-= 1\)' on signal 'ACC'/,
        'CLI surfaces the duplicate inline-modifier boundary',
    );
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, 'parse failed as expected');
    return $error;
}

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw_ast);
    ok($module, 'parse succeeded as expected');
    return $module;
}

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('name')) {
        my $name = eval { $target->name };
        return $name if defined $name;
    }

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub assert_left_associative_binary_tree {
    my ($expr, $operator, $expected_leaves, $label) = @_;
    my @expected = @$expected_leaves;
    my $node = $expr;

    for (my $i = $#expected; $i >= 1; $i--) {
        ok($node->isa('FSM::CoreAST::BinaryOp'), "$label keeps BinaryOp node for position $i");
        is($node->operator, $operator, "$label uses operator '$operator' at position $i");
        is(expr_leaf_name($node->right), $expected[$i], "$label keeps right operand $expected[$i] at position $i");

        if ($i == 1) {
            is(expr_leaf_name($node->left), $expected[0], "$label keeps leftmost operand $expected[0]");
        } else {
            $node = $node->left;
        }
    }
}

sub expr_leaf_name {
    my ($expr) = @_;
    return undef unless $expr;

    if ($expr->isa('FSM::CoreAST::SignalRef') && $expr->signal) {
        return $expr->signal->name;
    }

    if ($expr->isa('FSM::CoreAST::Literal')) {
        return $expr->value;
    }

    return ref($expr);
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
