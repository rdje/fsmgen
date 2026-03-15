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

subtest 'malformed update shorthand targets are rejected explicitly' => sub {
    my $prefix_error = parse_failure(<<'FSM');
(?fsm:bad_update_target_prefix
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (++ (counter))
  )
)
FSM

    like(
        $prefix_error,
        qr/Malformed update shorthand '\(\+\+ ARRAY\)'/,
        'nested target in ++ shorthand gets a targeted diagnostic',
    );

    my $separated_error = parse_failure(<<'FSM');
(?fsm:bad_update_target_separated
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (+= (byte_count) 4)
  )
)
FSM

    like(
        $separated_error,
        qr/Malformed update shorthand '\(\+= ARRAY\)'/,
        'nested target in separated += shorthand gets a targeted diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed update shorthand targets' => sub {
    my $fsm_path = write_fsm('bad_update_target_cli.fsm', <<'FSM');
(?fsm:bad_update_target_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (++ (counter))
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
    ok($pipeline_error, 'pipeline rejects malformed update shorthand target');
    like(
        $pipeline_error,
        qr/Malformed update shorthand '\(\+\+ ARRAY\)'/,
        'pipeline surfaces the update-shorthand boundary clearly',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_update_target_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed update shorthand target');
    ok(!-e $out_path, 'CLI does not emit output for malformed update shorthand target');
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
