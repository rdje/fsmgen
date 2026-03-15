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

subtest 'empty FSM-state DT blocks are rejected explicitly' => sub {
    my $fsm_path = write_fsm('empty_state_block.fsm', <<'FSM');
(?fsm:empty_state_block
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle)
)
FSM

    my $error = parse_failure($fsm_path);
    like($error, qr/Malformed state\/DT block 'idle'/, 'empty regular state gets a targeted diagnostic');
};

subtest 'empty general/combinational DT blocks are rejected explicitly' => sub {
    my $fsm_path = write_fsm('empty_dt_block.fsm', <<'FSM');
(?fsm:empty_dt_block
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-misc)
)
FSM

    my $error = parse_failure($fsm_path);
    like($error, qr/Malformed state\/DT block '-misc'/, 'empty standalone DT gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not silently emit HDL for malformed empty state/DT bodies' => sub {
    my $fsm_path = write_fsm('empty_state_cli.fsm', <<'FSM');
(?fsm:empty_state_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle)
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
    ok($pipeline_error, 'pipeline rejects malformed empty state body');
    like($pipeline_error, qr/Malformed state\/DT block 'idle'/, 'pipeline surfaces the explicit state/DT boundary');

    my $out_path = File::Spec->catfile($tempdir, 'empty_state_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed empty state body');
    ok(!-e $out_path, 'CLI does not emit output for malformed empty state body');
};

done_testing();

sub parse_failure {
    my ($fsm_path) = @_;
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, "parse fails for '$fsm_path'");
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
