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

subtest 'malformed delayed-pulse RHS values are rejected explicitly' => sub {
    my $symbolic_error = parse_failure(<<'FSM');
(?fsm:bad_pulse_rhs_symbolic
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (P <1 B)
  )
  (+size
    (P 1)
    (B 1)
  )
)
FSM

    like(
        $symbolic_error,
        qr/Malformed delayed pulse RHS 'B'/,
        'symbolic delayed-pulse RHS gets a targeted diagnostic',
    );

    my $width_error = parse_failure(<<'FSM');
(?fsm:bad_pulse_rhs_width
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (P <1 2'0)
  )
  (+size
    (P 1)
  )
)
FSM

    like(
        $width_error,
        qr/Malformed delayed pulse RHS '2'0'/,
        'multi-bit delayed-pulse RHS gets a targeted diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed delayed-pulse RHS values' => sub {
    my $fsm_path = write_fsm('bad_pulse_rhs_cli.fsm', <<'FSM');
(?fsm:bad_pulse_rhs_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (P <1 B)
  )
  (+size
    (P 1)
    (B 1)
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
    ok($pipeline_error, 'pipeline rejects malformed delayed-pulse RHS value');
    like(
        $pipeline_error,
        qr/Malformed delayed pulse RHS 'B'/,
        'pipeline surfaces the delayed-pulse boundary clearly',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_pulse_rhs_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed delayed-pulse RHS value');
    ok(!-e $out_path, 'CLI does not emit output for malformed delayed-pulse RHS value');
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
