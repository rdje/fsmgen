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

subtest 'pipeline and CLI do not emit HDL for bare assignment condition suffixes' => sub {
    my $fsm_path = write_fsm('bare_assignment_suffix.fsm', <<'FSM');
(?fsm:bad_assignment_suffix
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A <= B start)
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
    ok($pipeline_error, 'pipeline rejects bare assignment condition suffix');
    like($pipeline_error, qr/Unsupported bare condition suffix 'start'/, 'pipeline surfaces the explicit bare-assignment-suffix boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bare_assignment_suffix.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects bare assignment condition suffix');
    ok(!-e $out_path, 'CLI does not emit output for bare assignment condition suffix');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported bare condition suffix 'start'/, 'CLI surfaces the explicit bare-assignment-suffix boundary');
};

subtest 'pipeline and CLI do not emit HDL for bare transition condition suffixes' => sub {
    my $fsm_path = write_fsm('bare_transition_suffix.fsm', <<'FSM');
(?fsm:bad_transition_suffix
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> busy full)
  )
  (busy
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
    ok($pipeline_error, 'pipeline rejects bare transition condition suffix');
    like($pipeline_error, qr/Unsupported bare condition suffix 'full'/, 'pipeline surfaces the explicit bare-transition-suffix boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bare_transition_suffix.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects bare transition condition suffix');
    ok(!-e $out_path, 'CLI does not emit output for bare transition condition suffix');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported bare condition suffix 'full'/, 'CLI surfaces the explicit bare-transition-suffix boundary');
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
