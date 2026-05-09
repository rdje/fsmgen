#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(build_serializable_diagnostic_summary);

my $tempdir = tempdir(CLEANUP => 1);
my $bad_path = write_bad_fixture();

subtest 'semantic JSON diagnostic_summary matches standalone builder' => sub {
    my $decoded = run_json_report(['./bin/fsmgen', '--strict', '--emit-semantic-json', $bad_path], 0);
    my $rebuilt = build_serializable_diagnostic_summary(report => $decoded);

    is_deeply(
        $decoded->{diagnostic_summary},
        $rebuilt,
        'semantic JSON embeds the same diagnostic summary as the standalone builder',
    );
};

subtest 'check JSON diagnostic_summary matches standalone builder' => sub {
    my $decoded = run_json_report(['./bin/fsmgen', '--strict', '--check-json', $bad_path], 0);
    my $rebuilt = build_serializable_diagnostic_summary(report => $decoded);

    is_deeply(
        $decoded->{diagnostic_summary},
        $rebuilt,
        'check JSON embeds the same diagnostic summary as the standalone builder',
    );
};

done_testing();

sub run_json_report {
    my ($command, $expect_success) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(command => $command);

    is($success ? 1 : 0, $expect_success ? 1 : 0, 'command exits with expected status');
    is(join('', @{$stderr_buf || []}), '', 'command keeps stderr clean');
    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_bad_fixture {
    my $bad_path = File::Spec->catfile($tempdir, 'diagnostic_summary_public_report_bad.fsm');
    write_file(
        $bad_path,
        <<'FSM'
(?fsm:diagnostic_summary_public_report_bad
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (SRC 8)
    (OUT 8)
  )
  (idle
    (OUT = SRC)
  )
)
FSM
    );
    return $bad_path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
