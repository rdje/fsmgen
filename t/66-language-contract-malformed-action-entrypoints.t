#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'pipeline and CLI do not emit HDL for single-token malformed DT actions' => sub {
    my $fsm_path = write_fsm('malformed_single_token_action.fsm', <<'FSM');
(?fsm:broken_single_token_action
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (BROKEN)
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
    ok($pipeline_error, 'pipeline rejects single-token malformed DT action');
    like($pipeline_error, qr/Unsupported action form '\(BROKEN\)'/, 'pipeline surfaces the explicit malformed-action boundary');

    my $out_path = File::Spec->catfile($tempdir, 'malformed_single_token_action.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects single-token malformed DT action');
    ok(!-e $out_path, 'CLI does not emit output for single-token malformed DT action');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported action form '\(BROKEN\)'/, 'CLI surfaces the explicit malformed-action boundary');
};

subtest 'pipeline and CLI do not emit HDL for empty guarded blocks' => sub {
    my $fsm_path = write_fsm('malformed_empty_guard.fsm', <<'FSM');
(?fsm:broken_empty_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (<req)
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
    ok($pipeline_error, 'pipeline rejects empty guarded block');
    like($pipeline_error, qr/Malformed guarded block '<req'/, 'pipeline surfaces the explicit guarded-block boundary');

    my $out_path = File::Spec->catfile($tempdir, 'malformed_empty_guard.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects empty guarded block');
    ok(!-e $out_path, 'CLI does not emit output for empty guarded block');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed guarded block '<req'/, 'CLI surfaces the explicit guarded-block boundary');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
