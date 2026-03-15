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

subtest 'pipeline and CLI do not emit HDL for empty test-node branches' => sub {
    my $fsm_path = write_fsm('empty_test_branch.fsm', <<'FSM');
(?fsm:bad_empty_test_branch
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (?MODE
      (=0)
      (=1 (A = 1))
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
    ok($pipeline_error, 'pipeline rejects empty test-node branch');
    like($pipeline_error, qr/Malformed test branch '=0'/, 'pipeline surfaces the explicit empty-test-branch boundary');

    my $out_path = File::Spec->catfile($tempdir, 'empty_test_branch.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects empty test-node branch');
    ok(!-e $out_path, 'CLI does not emit output for empty test-node branch');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed test branch '=0'/, 'CLI surfaces the explicit empty-test-branch boundary');
};

subtest 'pipeline and CLI do not emit HDL for missing nested action inside a test branch' => sub {
    my $fsm_path = write_fsm('missing_nested_test_branch_action.fsm', <<'FSM');
(?fsm:bad_missing_nested_action
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (?MODE
      (=0)
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
    ok($pipeline_error, 'pipeline rejects malformed single test-node branch');
    like($pipeline_error, qr/Malformed test branch '=0'/, 'pipeline surfaces the explicit single-branch boundary');

    my $out_path = File::Spec->catfile($tempdir, 'missing_nested_test_branch_action.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed single test-node branch');
    ok(!-e $out_path, 'CLI does not emit output for malformed single test-node branch');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed test branch '=0'/, 'CLI surfaces the explicit single-branch boundary');
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
