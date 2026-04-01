#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);

subtest 'CLI top-level parse failures keep the diagnostic but drop Perl stack traces' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_top_level_cli.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_top_level_cli.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_top_level_cli
  (bogus)
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed top-level source');
    ok(!-e $output_path, 'CLI does not emit output for malformed top-level source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$fsm_path\E'/s, 'CLI keeps the top-level source file context');
    like($combined_output, qr/Unsupported top-level form '\(bogus undef\)'/s, 'CLI keeps the underlying top-level diagnostic');
    unlike($combined_output, qr/\bcalled at\b/s, 'CLI no longer prints Perl call-stack frames');
    unlike($combined_output, qr/\n at \Q$0\E line \d+\./s, 'CLI no longer re-dies at the script boundary');
};

subtest 'CLI child-source failures keep child context but drop Perl stack traces' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_child_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'child_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child child_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:child_src
  (bogus)
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects malformed generated child source');
    ok(!-e $output_path, 'CLI does not emit output for malformed generated child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$child_path\E'/s, 'CLI keeps the external child source file');
    like($combined_output, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'CLI keeps the parent composition source file');
    like($combined_output, qr/Generated child source:\s+'\?fsmc' 'child_src'/s, 'CLI keeps the generated child source identity');
    like($combined_output, qr/Unsupported top-level form '\(bogus undef\)'/s, 'CLI keeps the underlying child diagnostic');
    unlike($combined_output, qr/\bcalled at\b/s, 'CLI no longer prints Perl call-stack frames for child failures');
    unlike($combined_output, qr/\n at \Q$0\E line \d+\./s, 'CLI no longer re-dies at the script boundary for child failures');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
