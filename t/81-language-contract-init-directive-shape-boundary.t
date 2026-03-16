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

my $tempdir = tempdir(CLEANUP => 1);

subtest "malformed ':=' directive payload shapes are rejected explicitly" => sub {
    my $payload_error = parse_failure(<<'FSM');
(?fsm:bad_init_payload_shape
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= (tester_reset=1 extra))
  (idle
    (A = 1)
  )
)
FSM

    like(
        $payload_error,
        qr/Malformed ':=' directive payload/,
        "non-scalar ':=' payload gets a targeted diagnostic",
    );

    my $directive_error = parse_failure(<<'FSM');
(?fsm:bad_init_directive_shape
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= BROKEN)
  (idle
    (A = 1)
  )
)
FSM

    like(
        $directive_error,
        qr/Unsupported ':=' directive 'BROKEN'/,
        "compact ':=' directive without signal=value gets a targeted diagnostic",
    );
};

subtest "pipeline and CLI do not emit HDL for malformed ':=' directive shapes" => sub {
    my $payload_path = write_fsm('bad_init_payload_shape_cli.fsm', <<'FSM');
(?fsm:bad_init_payload_shape_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= (tester_reset=1 extra))
  (idle
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );

    my $payload_error = eval {
        $pipeline->generate_hdl_from_file($payload_path);
        undef;
    };
    $payload_error = $@ if !$payload_error;
    ok($payload_error, 'pipeline rejects malformed non-scalar := payload');
    like(
        $payload_error,
        qr/Malformed ':=' directive payload/,
        "pipeline surfaces the explicit ':=' payload boundary",
    );

    my $payload_out = File::Spec->catfile($tempdir, 'bad_init_payload_shape_cli.sv');
    my ($payload_success, $payload_error_message, $payload_full_buf, $payload_stdout_buf, $payload_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $payload_out, '--quiet', $payload_path],
    );

    ok(!$payload_success, 'CLI rejects malformed non-scalar := payload');
    ok(!-e $payload_out, 'CLI does not emit output for malformed non-scalar := payload');

    my $payload_combined = join(
        '',
        @{ $payload_stdout_buf || [] },
        @{ $payload_stderr_buf || [] },
        ($payload_error_message || ''),
    );

    like(
        $payload_combined,
        qr/Malformed ':=' directive payload/,
        "CLI surfaces the explicit ':=' payload boundary",
    );

    my $directive_path = write_fsm('bad_init_directive_shape_cli.fsm', <<'FSM');
(?fsm:bad_init_directive_shape_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= BROKEN)
  (idle
    (A = 1)
  )
)
FSM

    my $directive_error = eval {
        $pipeline->generate_hdl_from_file($directive_path);
        undef;
    };
    $directive_error = $@ if !$directive_error;
    ok($directive_error, 'pipeline rejects malformed compact := directive');
    like(
        $directive_error,
        qr/Unsupported ':=' directive 'BROKEN'/,
        "pipeline surfaces the explicit ':=' compact-form boundary",
    );

    my $directive_out = File::Spec->catfile($tempdir, 'bad_init_directive_shape_cli.sv');
    my ($directive_success, $directive_error_message, $directive_full_buf, $directive_stdout_buf, $directive_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $directive_out, '--quiet', $directive_path],
    );

    ok(!$directive_success, 'CLI rejects malformed compact := directive');
    ok(!-e $directive_out, 'CLI does not emit output for malformed compact := directive');

    my $directive_combined = join(
        '',
        @{ $directive_stdout_buf || [] },
        @{ $directive_stderr_buf || [] },
        ($directive_error_message || ''),
    );

    like(
        $directive_combined,
        qr/Unsupported ':=' directive 'BROKEN'/,
        "CLI surfaces the explicit ':=' compact-form boundary",
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

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
