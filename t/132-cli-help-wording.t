#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IPC::Cmd qw(run);

sub capture_output {
    my (@command) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => \@command,
    );

    my $output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    return ($success, $output);
}

subtest 'help output names the active bin/fsmgen entrypoint' => sub {
    my ($success, $output) = capture_output($^X, '-I', 'perl', 'bin/fsmgen', '--help');

    ok($success, 'help invocation succeeds');
    like(
        $output,
        qr/Usage: \.\/bin\/fsmgen \[OPTIONS\] <fsm_file>/s,
        'help output now names the active bin/fsmgen entrypoint',
    );
    unlike(
        $output,
        qr/generate_fsm_hdl\.pl/s,
        'help output no longer advertises the legacy generate_fsm_hdl.pl wrapper',
    );
    like(
        $output,
        qr/default: <fsm_name>\.<ext> in current working directory/s,
        'help output now describes the current-working-directory default output path honestly',
    );
};

subtest 'missing-argument usage also names the active bin/fsmgen entrypoint' => sub {
    my ($success, $output) = capture_output($^X, '-I', 'perl', 'bin/fsmgen');

    ok(!$success, 'CLI still fails when no FSM file argument is supplied');
    like(
        $output,
        qr/Usage: \.\/bin\/fsmgen \[OPTIONS\] <fsm_file>/s,
        'missing-argument usage now names the active bin/fsmgen entrypoint',
    );
    unlike(
        $output,
        qr/generate_fsm_hdl\.pl/s,
        'missing-argument usage no longer advertises the legacy generate_fsm_hdl.pl wrapper',
    );
};

done_testing();
