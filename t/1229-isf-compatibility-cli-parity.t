#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fsmgen = File::Spec->catfile($repo_root, 'bin', 'fsmgen');

subtest 'deprecated handshake compatibility is accepted through CLI report and strict HDL paths' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf = write_file(
        $dir,
        'legacy_handshake_cli.isf',
        <<'ISF',
(actor legacy_handshake_cli
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input req_valid)
    (output can_accept)
    (output done))
  (handshake request (valid req_valid) (ready can_accept))
  (transaction main
    (on start)
    (complete done)))
ISF
    );

    my $report_result = run_fsmgen('--emit-schedule-json', $isf);
    ok($report_result->{success}, 'CLI schedule JSON accepts deprecated handshake compatibility source');
    is($report_result->{stderr}, '', 'CLI schedule JSON keeps stderr clean for accepted compatibility source');

    my $report = decode_json($report_result->{stdout});
    is($report->{source}, 'legacy_handshake_cli.isf', 'schedule report names the compatibility source');
    is($report->{scheduled_fsm}, 'legacy_handshake_cli.fsm', 'schedule report names the scheduled .fsm');
    is_deeply($report->{compile_issues}, [], 'accepted ignored handshake does not create compile issues');

    my $hdl = File::Spec->catfile($dir, 'legacy_handshake_cli.sv');
    my $strict_result = run_fsmgen('--strict', '--quiet', '--output', $hdl, $isf);
    ok($strict_result->{success}, 'CLI strict HDL generation accepts deprecated handshake compatibility source');
    is($strict_result->{stderr}, '', 'CLI strict HDL generation keeps stderr clean');
    ok(-f $hdl, 'CLI strict HDL generation writes the requested output');
    if (-f $hdl) {
        like(slurp($hdl), qr/\bmodule\s+legacy_handshake_cli\b/, 'strict HDL contains the generated module');
    }
};

subtest 'removed transaction assign fails through CLI with the migration diagnostic' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf = write_file(
        $dir,
        'removed_assign_cli.isf',
        <<'ISF',
(actor removed_assign_cli
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (assign done 1)
    (complete done)))
ISF
    );

    my $result = run_fsmgen('--emit-schedule-json', $isf);
    ok(!$result->{success}, 'CLI schedule JSON rejects removed transaction assign');
    like(
        $result->{stderr},
        qr/removed '\(assign \.\.\.\)' clause is unsupported in transaction body; use '\(set var expr\)'/,
        'CLI diagnostic carries removed-assign migration guidance',
    );
};

done_testing();

sub run_fsmgen {
    my (@args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$fsmgen, @args],
    );

    return {
        success => $success,
        stdout  => join('', @{$stdout_buf || []}),
        stderr  => join('', @{$stderr_buf || []}),
        error   => $error_message,
    };
}

sub write_file {
    my ($dir, $name, $text) = @_;
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $text;
    close $fh or die "cannot close $path: $!";
    return $path;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
