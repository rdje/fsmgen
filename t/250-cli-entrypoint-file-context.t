#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);

subtest 'CLI missing-input failures keep requested-source context' => sub {
    my $missing_name = 'definitely_missing_cli_context_fixture';

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', $missing_name],
    );

    ok(!$success, 'CLI rejects unresolved bare-name source input');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Requested source:\s+'\Q$missing_name\E'/s, 'CLI keeps the unresolved requested-source token');
    like($combined_output, qr/Error:\s+FSM file '\Q$missing_name.fsm\E' not found/s, 'CLI keeps the underlying search failure');
    like($combined_output, qr/Searched locations:/s, 'CLI still shows the searched locations summary');
    unlike($combined_output, qr/\n at \Q$0\E line \d+\./s, 'CLI missing-input failure does not re-die at the script boundary');
};

subtest 'CLI output-open failures keep source-file and output-file context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'good_cli_output_context.fsm');
    my $missing_dir = File::Spec->catdir($tempdir, 'missing', 'nested');
    my $output_path = File::Spec->catfile($missing_dir, 'good_cli_output_context.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:good_cli_output_context
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT = IN)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $fsm_path],
    );

    ok(!$success, 'CLI rejects unwritable output path');
    ok(!-e $output_path, 'CLI does not emit output when the output path cannot be opened');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$fsm_path\E'/s, 'CLI keeps the source file context for output-open failures');
    like($combined_output, qr/Output file:\s+'\Q$output_path\E'/s, 'CLI keeps the failing output file path');
    like($combined_output, qr/Cannot write to output file:/s, 'CLI keeps the underlying output-open diagnostic');
    unlike($combined_output, qr/\n at \Q$0\E line \d+\./s, 'CLI output-open failure does not re-die at the script boundary');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
