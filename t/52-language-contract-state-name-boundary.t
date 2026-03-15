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

subtest 'HDL-identifier-compatible state and standalone DT names remain supported' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:state_name_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (state_0
    (OUT <= 1)
    (-> next_1)
  )
  (next_1
    (OUT <= 0)
  )
  (-comb_1
    (FLAG = 1)
  )
)
FSM

    ok($fsm_module, 'FSM with conventional state/DT names parses successfully');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+state_name_contract\b/s, 'valid state/DT names still generate HDL');
};

subtest 'malformed state and DT names are rejected explicitly' => sub {
    my $regular_error = parse_failure(<<'FSM');
(?fsm:bad_regular_state_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (bad-name
    (OUT <= 1)
  )
)
FSM
    like($regular_error, qr/Malformed state\/DT name 'bad-name'/, 'bad regular state name gets a targeted diagnostic');

    my $standalone_error = parse_failure(<<'FSM');
(?fsm:bad_standalone_dt_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-bad-name
    (FLAG = 1)
  )
)
FSM
    like($standalone_error, qr/Malformed state\/DT name '-bad-name'/, 'bad standalone DT name gets a targeted diagnostic');

    my $double_hyphen_error = parse_failure(<<'FSM');
(?fsm:bad_double_hyphen_dt_name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (--bad
    (FLAG = 1)
  )
)
FSM
    like($double_hyphen_error, qr/Malformed state\/DT name '--bad'/, 'double-hyphen DT name gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed state names' => sub {
    my $fsm_path = write_fsm('bad_state_name_cli.fsm', <<'FSM');
(?fsm:bad_state_name_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (bad-name
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
    ok($pipeline_error, 'pipeline rejects malformed regular state name');
    like($pipeline_error, qr/Malformed state\/DT name 'bad-name'/, 'pipeline surfaces the explicit state/DT-name boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_state_name_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed regular state name');
    ok(!-e $out_path, 'CLI does not emit output for malformed regular state name');
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
