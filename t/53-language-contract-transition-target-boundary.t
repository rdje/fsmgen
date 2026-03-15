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

subtest 'declared regular-state targets remain supported, including forward references' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:transition_target_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> busy)
  )
  (busy
    (OUT <= 1)
    (-> idle <!full)
  )
)
FSM

    ok($fsm_module, 'FSM with declared transition targets parses successfully');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+transition_target_contract\b/s, 'declared transition targets still generate HDL');
};

subtest 'malformed and unknown transition targets are rejected explicitly' => sub {
    my $malformed_error = parse_failure(<<'FSM');
(?fsm:bad_transition_target_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> bad-name)
  )
  (busy
    (OUT <= 1)
  )
)
FSM
    like($malformed_error, qr/Malformed transition target 'bad-name'/, 'malformed transition target name gets a targeted diagnostic');

    my $standalone_target_error = parse_failure(<<'FSM');
(?fsm:standalone_transition_target_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> -comb)
  )
  (-comb
    (FLAG = 1)
  )
)
FSM
    like($standalone_target_error, qr/Malformed transition target '-comb'/, 'standalone DT target gets a targeted malformed-target diagnostic');

    my $unknown_error = parse_failure(<<'FSM');
(?fsm:unknown_transition_target
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> missing_state)
  )
  (busy
    (OUT <= 1)
  )
)
FSM
    like($unknown_error, qr/Unknown transition target 'missing_state' from state\/DT 'idle'/, 'unknown target gets a targeted membership diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for unknown transition targets' => sub {
    my $fsm_path = write_fsm('bad_transition_target_cli.fsm', <<'FSM');
(?fsm:bad_transition_target_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> missing_state)
  )
  (busy
    (OUT <= 1)
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
    ok($pipeline_error, 'pipeline rejects unknown transition target');
    like($pipeline_error, qr/Unknown transition target 'missing_state' from state\/DT 'idle'/, 'pipeline surfaces the explicit transition-target boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_transition_target_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects unknown transition target');
    ok(!-e $out_path, 'CLI does not emit output for unknown transition target');
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
