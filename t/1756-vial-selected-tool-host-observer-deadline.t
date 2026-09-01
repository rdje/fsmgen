#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Scalar::Util qw(blessed);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $capture = \&FSM::VIAL::Backend::ProcessSupervisor::_capture;
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-selected-tool-host-observer-deadline-$$",
);
my $fixture_bin = File::Spec->catdir($fixture_root, 'bin');
my $WATCHDOG_SECONDS = 7;
my @active_groups;

die "selected-tool observer fixture already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($fixture_bin, {mode => 0700});
chmod 0700, $fixture_root, $fixture_bin
    or die "cannot seal selected-tool observer fixture: $!\n";

END {
    terminate_group($_) for @active_groups;
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

for my $observer (qw(lsof ps)) {
    subtest "$observer cannot suspend selected-tool supervision" => sub {
        my $observer_path = File::Spec->catfile($fixture_bin, $observer);
        write_stalling_observer($observer_path);
        my ($reader, $writer);
        pipe($reader, $writer)
            or die "cannot create observer result pipe: $!\n";
        my $probe_pid = fork();
        die "cannot fork observer deadline probe: $!\n"
            unless defined $probe_pid;
        if ($probe_pid == 0) {
            close $reader;
            setpgid(0, 0) or _exit(91);
            local $ENV{PATH} = "$fixture_bin:$ENV{PATH}";
            my $error;
            {
                local $@;
                eval {
                    $capture->(
                        $fixture_root,
                        [$^X, '-e', 'exit 0'],
                        {
                            schema =>
                                'fsmgen.vial_process_supervisor_policy.v1',
                            schema_version => 1,
                            containment => 'lifecycle_process_group',
                            timeout_seconds => 1,
                            capture_limit_bytes => 65_536,
                        },
                    );
                    1;
                } or $error = $@;
            }
            my $accepted_error = blessed($error)
                && $error->isa(
                    'FSM::VIAL::Backend::ProcessSupervisor::Failure',
                )
                && ($error->{code} // '') =~
                    /\AVIAL_PROCESS_(?:HOST|RESIDUE)_ERROR\z/;
            syswrite($writer, $accepted_error ? 'S' : 'F', 1);
            close $writer;
            _exit($accepted_error ? 0 : 92);
        }
        close $writer;
        eval { setpgid($probe_pid, $probe_pid); 1 };
        push @active_groups, $probe_pid;

        my ($finished, $status) = wait_until_exit(
            $probe_pid, $WATCHDOG_SECONDS,
        );
        ok($finished,
            "$observer observation returns inside the outer watchdog");
        if (!$finished) {
            terminate_group($probe_pid);
            waitpid($probe_pid, 0);
        }
        my $record = '';
        sysread($reader, $record, 1);
        close $reader;
        is($record, 'S',
            "$observer stall returns one explicit process failure");
        ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
            "$observer probe itself exits cleanly after supervision");
        ok(!kill(0, -$probe_pid),
            "$observer helper leaves no detached process-group residue");

        terminate_group($probe_pid);
        pop @active_groups;
        unlink($observer_path)
            or die "cannot remove stalling observer fixture: $!\n";
        ok(!-e($observer_path) && !-l($observer_path),
            "$observer fixture is removed exactly");
    };
}

remove_tree($fixture_root);
die "selected-tool observer fixture remains\n"
    if -e $fixture_root || -l $fixture_root;

done_testing();

sub write_stalling_observer {
    my ($path) = @_;
    open my $observer, '>:raw', $path
        or die "cannot create stalling observer fixture: $!\n";
    print {$observer} "#!$^X\n", <<'SCRIPT'
use strict;
use warnings;
$SIG{TERM} = 'IGNORE';
sleep 30;
SCRIPT
        or die "cannot write stalling observer fixture: $!\n";
    close $observer
        or die "cannot close stalling observer fixture: $!\n";
    chmod 0700, $path
        or die "cannot make stalling observer executable: $!\n";
}

sub wait_until_exit {
    my ($pid, $seconds) = @_;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + $seconds;
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
        return (1, $?) if $waited == $pid || $waited == -1;
        sleep 0.02;
    }
    return (0, undef);
}

sub terminate_group {
    my ($pid) = @_;
    return unless defined($pid) && $pid > 1;
    kill 'TERM', -$pid;
    sleep 0.05;
    kill 'KILL', -$pid if kill(0, -$pid);
    return;
}
