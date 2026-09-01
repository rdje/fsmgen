#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $capture = \&FSM::VIAL::Backend::ProcessSupervisor::_capture;
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-selected-tool-detached-containment-$$",
);
my @active_residue;

die "selected-tool detached fixture already exists\n"
    if -e $fixture_base || -l $fixture_base;

END {
    terminate_residue($_->{pid}, $_->{group}) for @active_residue;
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

my @containment_cases = (
    [qw(lifecycle_process_group normal_exit)],
    [qw(lifecycle_process_group timeout)],
    [qw(outer_worker_process_group normal_exit)],
    [qw(outer_worker_process_group timeout)],
);
for my $case (@containment_cases) {
    my ($containment, $leader_behavior) = @$case;
    subtest "$containment/$leader_behavior contains a detached descendant" => sub {
        my $fixture_root = File::Spec->catdir(
            $fixture_base, "$containment-$leader_behavior",
        );
        my $stage_root = File::Spec->catdir($fixture_root, 'stage');
        my $identity_path =
            File::Spec->catfile($fixture_root, 'descendant.pid');
        my $late_marker = File::Spec->catfile(
            $stage_root, 'late-marker.txt',
        );
        make_path($stage_root, {mode => 0700});
        chmod 0700, $fixture_base, $fixture_root, $stage_root
            or die "cannot seal selected-tool detached fixture: $!\n";

        my ($result, $error);
        {
            local $@;
            my $ok = eval {
                $result = $capture->(
                    $fixture_root,
                    [
                        $^X, '-e', selected_tool_program(),
                        $identity_path, $stage_root, $late_marker,
                        $leader_behavior,
                    ],
                    {
                        schema =>
                            'fsmgen.vial_process_supervisor_policy.v1',
                        schema_version => 1,
                        containment => $containment,
                        timeout_seconds =>
                            $leader_behavior eq 'timeout' ? 1 : 3,
                        capture_limit_bytes => 65_536,
                    },
                );
                1;
            };
            $error = $@ unless $ok;
        }
        my ($descendant_pid, $descendant_group) =
            read_descendant_identity($identity_path);
        my $residue = {
            pid => $descendant_pid,
            group => $descendant_group,
        };
        push @active_residue, $residue;

        if ($leader_behavior eq 'normal_exit') {
            ok(ref($error)
                    && eval {
                        $error->isa(
                            'FSM::VIAL::Backend::ProcessSupervisor::Failure',
                        )
                    }
                    && ($error->{code} // '') eq
                        'VIAL_PROCESS_RESIDUE_ERROR',
                'a detached descendant has an explicit residue failure');
        }
        else {
            ok(!defined($error) && defined($result) && $result->{timed_out},
                'timeout remains the primary supervised result');
        }
        ok(!defined($result) || !$result->{ok},
            'a zero-exit leader cannot promote detached residue');
        ok(!process_alive($descendant_pid),
            'the detached descendant is gone before supervisor return');

        remove_tree($stage_root)
            if -d($stage_root) && !-l($stage_root);
        my $marker_published = wait_for_path($late_marker, 2);
        ok(!$marker_published && !-e($late_marker) && !-l($late_marker),
            'detached residue cannot mutate staging after cleanup');

        terminate_residue($descendant_pid, $descendant_group);
        pop @active_residue;
        remove_tree($fixture_root);
        ok(!-e($fixture_root) && !-l($fixture_root),
            'the detached fixture leaves no repository-local residue');
    };
}

remove_tree($fixture_base);
die "selected-tool detached fixture base remains\n"
    if -e $fixture_base || -l $fixture_base;

done_testing();

sub selected_tool_program {
    return <<'PROGRAM';
use strict;
use warnings;
use File::Path qw(make_path);
use POSIX ();
use Time::HiRes qw(sleep);

my ($identity_path, $stage_root, $late_marker, $leader_behavior) = @ARGV;
my $child = fork();
die "cannot fork selected-tool detached child\n" unless defined $child;
if ($child == 0) {
    my $session = POSIX::setsid();
    POSIX::_exit(71) unless defined($session) && $session > 0;
    open STDOUT, '>', '/dev/null' or POSIX::_exit(72);
    open STDERR, '>', '/dev/null' or POSIX::_exit(73);
    my $wrote_containment_probe = 0;
    for my $fd (3 .. 255) {
        next unless open my $probe, '>&', $fd;
        my $written = syswrite($probe, "P", 1);
        close $probe;
        if (defined($written) && $written == 1) {
            $wrote_containment_probe = 1;
            last;
        }
    }
    POSIX::_exit(81) unless $wrote_containment_probe;
    my $group = POSIX::getpgrp();
    open my $identity, '>:raw', $identity_path or POSIX::_exit(74);
    print {$identity} "$$ $group\n" or POSIX::_exit(75);
    close $identity or POSIX::_exit(76);
    for (1 .. 1_000) {
        last unless -e $stage_root || -l $stage_root;
        sleep 0.005;
    }
    POSIX::_exit(77) if -e $stage_root || -l $stage_root;
    make_path($stage_root, {mode => 0700});
    open my $marker, '>:raw', $late_marker or POSIX::_exit(78);
    print {$marker} "late selected-tool mutation\n" or POSIX::_exit(79);
    close $marker or POSIX::_exit(80);
    sleep 30;
    POSIX::_exit(0);
}
for (1 .. 200) {
    last if -f $identity_path && !-l $identity_path;
    sleep 0.005;
}
die "selected-tool detached child did not publish identity\n"
    unless -f $identity_path && !-l $identity_path;
sleep 30 if $leader_behavior eq 'timeout';
exit 0;
PROGRAM
}

sub read_descendant_identity {
    my ($identity_path) = @_;
    open my $identity, '<:raw', $identity_path
        or die "cannot read selected-tool descendant identity: $!\n";
    my $record = <$identity>;
    close $identity
        or die "cannot close selected-tool descendant identity: $!\n";
    my ($descendant_pid, $descendant_group) = $record
        =~ /\A([1-9][0-9]*) ([1-9][0-9]*)\n\z/
        or die "selected-tool descendant identity is malformed\n";
    return ($descendant_pid, $descendant_group);
}

sub wait_for_path {
    my ($path, $seconds) = @_;
    my $attempts = int($seconds / 0.01);
    for (0 .. $attempts) {
        return 1 if -e $path || -l $path;
        sleep 0.01;
    }
    return -e $path || -l $path;
}

sub process_alive {
    my ($pid) = @_;
    return defined($pid) && kill(0, $pid) ? 1 : 0;
}

sub terminate_residue {
    my ($descendant_pid, $descendant_group) = @_;
    return unless defined $descendant_pid;
    my $own_group = POSIX::getpgrp();
    if (defined($descendant_group) && $descendant_group != $own_group) {
        kill 'TERM', -$descendant_group;
        for (1 .. 25) {
            return unless process_alive($descendant_pid);
            sleep 0.01;
        }
        kill 'KILL', -$descendant_group;
    }
    elsif ($descendant_pid != $$) {
        kill 'KILL', $descendant_pid;
    }
    for (1 .. 200) {
        last unless process_alive($descendant_pid);
        sleep 0.01;
    }
    return;
}
