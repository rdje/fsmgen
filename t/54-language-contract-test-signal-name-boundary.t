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
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'HDL-identifier-compatible plain test signals remain supported' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:test_signal_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?SEL
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
  )
)
FSM

    ok($fsm_module, 'FSM with conventional ?SIG test node parses successfully');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+test_signal_contract\b/s, 'valid ?SIG test node still generates HDL');
};

subtest 'malformed plain test-node signal names are rejected explicitly' => sub {
    my $hyphen_error = parse_failure(<<'FSM');
(?fsm:bad_test_signal_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?bad-name
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
  )
)
FSM
    like($hyphen_error, qr/Malformed test signal '\?bad-name'/, 'hyphenated plain test signal gets a targeted diagnostic');

    my $numeric_error = parse_failure(<<'FSM');
(?fsm:numeric_test_signal_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?0
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
  )
)
FSM
    like($numeric_error, qr/Malformed test signal '\?0'/, 'numeric plain test signal gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed plain test-node signal names' => sub {
    my $fsm_path = write_fsm('bad_test_signal_cli.fsm', <<'FSM');
(?fsm:bad_test_signal_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?bad-name
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
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
    ok($pipeline_error, 'pipeline rejects malformed plain test-node signal name');
    like($pipeline_error, qr/Malformed test signal '\?bad-name'/, 'pipeline surfaces the explicit plain test-node signal boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_test_signal_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed plain test-node signal name');
    ok(!-e $out_path, 'CLI does not emit output for malformed plain test-node signal name');
};

done_testing();

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

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
    ok($error, "parse fails for generated fixture");
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
