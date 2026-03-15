#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest "unsupported ':=' reset values are rejected explicitly" => sub {
    my $placeholder_error = parse_failure(<<'FSM');
(?fsm:broken_init_rhs_placeholder
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= tester_reset=[DATAIN])
  (idle
    (A = 1)
  )
)
FSM

    like(
        $placeholder_error,
        qr/Unsupported ':=' reset value '\[DATAIN\]' for signal 'tester_reset'/,
        "placeholder RHS gets a targeted ':=' reset-value diagnostic",
    );

    my $guard_error = parse_failure(<<'FSM');
(?fsm:broken_init_rhs_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= tester_reset=<start)
  (idle
    (A = 1)
  )
)
FSM

    like(
        $guard_error,
        qr/Unsupported ':=' reset value '<start' for signal 'tester_reset'/,
        "guard-like RHS gets a targeted ':=' reset-value diagnostic",
    );
};

subtest "pipeline and CLI do not emit HDL for unsupported ':=' reset values" => sub {
    my $fsm_path = write_fsm('bad_init_rhs_cli.fsm', <<'FSM');
(?fsm:bad_init_rhs_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= tester_reset=[DATAIN])
  (idle
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects unsupported := reset value');
    like(
        $pipeline_error,
        qr/Unsupported ':=' reset value '\[DATAIN\]' for signal 'tester_reset'/,
        "pipeline surfaces the explicit ':=' reset-value boundary",
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_init_rhs_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects unsupported := reset value');
    ok(!-e $out_path, 'CLI does not emit output for unsupported := reset value');
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
