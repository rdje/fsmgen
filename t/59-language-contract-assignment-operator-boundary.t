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

subtest 'unsupported assignment operators are rejected explicitly' => sub {
    my $qeq_error = parse_failure(<<'FSM');
(?fsm:bad_assignment_operator_qeq
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (A ?= B)
  )
)
FSM

    like(
        $qeq_error,
        qr/Unsupported assignment operator '\?=' for signal 'A'/,
        "'?=' gets a targeted assignment-operator diagnostic",
    );

    my $arrow_error = parse_failure(<<'FSM');
(?fsm:bad_assignment_operator_arrow
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (A => B)
  )
)
FSM

    like(
        $arrow_error,
        qr/Unsupported assignment operator '=>' for signal 'A'/,
        "'=>' gets a targeted assignment-operator diagnostic",
    );
};

subtest 'pipeline and CLI do not emit HDL for unsupported assignment operators' => sub {
    my $fsm_path = write_fsm('bad_assignment_operator_cli.fsm', <<'FSM');
(?fsm:bad_assignment_operator_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (A ?= B)
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
    ok($pipeline_error, 'pipeline rejects unsupported assignment operator');
    like(
        $pipeline_error,
        qr/Unsupported assignment operator '\?=' for signal 'A'/,
        'pipeline surfaces the assignment-operator boundary clearly',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_assignment_operator_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects unsupported assignment operator');
    ok(!-e $out_path, 'CLI does not emit output for unsupported assignment operator');
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
