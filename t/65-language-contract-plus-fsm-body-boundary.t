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

subtest 'malformed +fsm root bodies fail through an explicit boundary' => sub {
    my $empty_error = parse_failure(<<'FSM');
(+fsm plus_empty)
FSM
    like($empty_error, qr/Malformed top-level FSM body for source '\+fsm'/, 'empty +fsm body gets a targeted body diagnostic');

    my $scalar_error = parse_failure(<<'FSM');
(+fsm plus_scalar BROKEN)
FSM
    like($scalar_error, qr/Malformed top-level FSM body item 'BROKEN' in source 'plus_scalar'/, 'scalar nested +fsm body item gets a targeted body-item diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed +fsm root bodies' => sub {
    my $fsm_path = write_fsm('plus_scalar_cli.fsm', <<'FSM');
(+fsm plus_scalar BROKEN)
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
    ok($pipeline_error, 'pipeline rejects malformed +fsm body');
    like($pipeline_error, qr/Malformed top-level FSM body item 'BROKEN' in source 'plus_scalar'/, 'pipeline surfaces the explicit +fsm body-item boundary');

    my $out_path = File::Spec->catfile($tempdir, 'plus_scalar_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed +fsm body');
    ok(!-e $out_path, 'CLI does not emit output for malformed +fsm body');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed top-level FSM body item 'BROKEN' in source 'plus_scalar'/, 'CLI surfaces the explicit +fsm body-item boundary');
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
    ok($error, 'parse fails for generated fixture');
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
