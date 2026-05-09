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

my $tempdir = tempdir(CLEANUP => 1);

subtest 'failed semantic JSON omits success-only snapshot branches' => sub {
    my $bad_path = write_bad_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $bad_path],
    );

    ok(!$success, 'semantic JSON fails for rejected source');
    is(join('', @{$stderr_buf || []}), '', 'failed semantic JSON keeps stderr clean');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'failure report marks success false');
    ok(!exists $decoded->{semantic}, 'failure report omits semantic success payload');
    ok(!exists $decoded->{generation_result_snapshot}, 'failure report omits generation_result_snapshot');
    ok(
        !exists($decoded->{semantic})
            || !exists($decoded->{semantic}{composition})
            || !exists($decoded->{semantic}{composition}{plan_snapshot}),
        'failure report omits composition plan_snapshot',
    );
    ok($decoded->{diagnostics}[0]{code}, 'failure report still carries a diagnostic code');
};

done_testing();

sub write_bad_fixture {
    my $bad_path = File::Spec->catfile($tempdir, 'semantic_snapshot_failure_boundary_bad.fsm');
    write_file(
        $bad_path,
        <<'FSM'
(?fsm:semantic_snapshot_failure_boundary_bad
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
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
