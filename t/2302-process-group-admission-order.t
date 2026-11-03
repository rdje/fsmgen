#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Errno qw(EPERM);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Test::ProcessSupervisor qw(supervise_process);

my $workspace = create_project_tempdir(purpose => 'group-admission-order');
my $perl = abs_path($^X) or die "cannot resolve Perl: $!";
my $caller_group = getpgrp(0);
my $real_setpgid = \&POSIX::setpgid;

sub run_probe {
    my ($program, $timeout) = @_;
    return supervise_process(
        schema => 'fsmgen.test.group_admission_order.v1', stage => 'probe',
        bounds => {
            timeout_seconds => $timeout // 5,
            capture_limit_bytes => 65_536,
        },
        containment => 'group_admission_order_probe', cwd => $workspace,
        argv => [$perl, '-MJSON::PP', '-e', $program],
    );
}

sub write_observation {
    my ($path, $value) = @_;
    open my $stream, '>', $path or die "cannot write observation: $!";
    print {$stream} encode_json($value) or die "cannot write observation: $!";
    close $stream or die "cannot close observation: $!";
}

sub read_observation {
    my ($path) = @_;
    open my $stream, '<', $path or die "cannot read observation: $!";
    local $/;
    my $value = decode_json(<$stream>);
    close $stream or die "cannot close observation: $!";
    return $value;
}

sub check_cleanup {
    my ($result, $pid) = @_;
    ok($result->{cleanup}{leader_reaped}, 'leader is reaped');
    ok($result->{cleanup}{group_gone}, 'owned group is gone');
    ok(!kill(0, $pid), 'recorded child is independently absent');
    is(getpgrp(0), $caller_group, 'caller group remains unchanged');
}

subtest 'child admission follows the completed parent group attempt' => sub {
    my $parent_done = File::Spec->catfile($workspace, 'parent-complete.json');
    my $child_path = File::Spec->catfile($workspace, 'ordered-child.json');
    my $parent_calls = 0;
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        my $result = $real_setpgid->(@_);
        my $error = 0 + $!;
        if ($_[0] != 0) {
            ++$parent_calls;
            # Hold the parent call open so an ungated child exposes overlap.
            # Both calls still perform the real native operation exactly once.
            sleep 0.2;
            write_observation($parent_done, {complete => 1});
        }
        else {
            write_observation($child_path, {
                pid => $$, group => getpgrp(0), result => $result,
                parent_completed => -f $parent_done ? 1 : 0,
            });
        }
        $! = $error;
        return $result;
    };
    my $result = run_probe('print encode_json({pid => $$, group => getpgrp(0)})');
    ok($result->{ok}, 'admitted command succeeds') or diag explain $result;
    my $child = read_observation($child_path);
    is($parent_calls, 1, 'parent best-effort group setup is retained');
    ok($child->{parent_completed}, 'child cannot overlap the parent group call');
    cmp_ok($child->{result}, '==', 0, 'child native group call succeeds');
    is($child->{group}, $child->{pid}, 'child independently observes its group');
    is_deeply(decode_json($result->{stdout}), {
        pid => $child->{pid}, group => $child->{pid},
    }, 'executed command observes the admitted native identity');
    check_cleanup($result, $child->{pid});
};

subtest 'a native session-leader refusal still prevents exec' => sub {
    my $path = File::Spec->catfile($workspace, 'native-refusal.json');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        return 0 if $_[0] != 0;
        my $session = POSIX::setsid();
        die "cannot create native session control\n"
            unless defined($session) && $session == $$;
        my $result = $real_setpgid->(@_);
        my $error = 0 + $!;
        write_observation($path, {
            pid => $$, group => getpgrp(0), session => $session,
            result => $result, errno => $error,
        });
        $! = $error;
        return $result;
    };
    my $result = run_probe('print "command-executed\n"');
    my $child = read_observation($path);
    is($child->{group}, $child->{pid}, 'refused child actually has its own group');
    is($child->{session}, $child->{pid}, 'native control is a session leader');
    ok(!defined($child->{result}) && $child->{errno} == EPERM,
        'native syscall actually returns EPERM');
    is($result->{status}, 'exec_error', 'correct group cannot excuse a failed call');
    like($result->{exec_error}, qr/operation=setpgid result=undef errno=1 /,
        'original syscall failure remains precise');
    is($result->{stdout}, '', 'refused command never executes');
    check_cleanup($result, $child->{pid});
};

subtest 'a child still outside its group is reaped at the original deadline' => sub {
    my $path = File::Spec->catfile($workspace, 'pre-group-timeout.json');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        return 0 if $_[0] != 0;
        write_observation($path, {pid => $$, group => getpgrp(0)});
        sleep 60;
        return $real_setpgid->(@_);
    };
    my $result = run_probe('print "command-executed\n"', 1);
    my $child = read_observation($path);
    is($child->{group}, $caller_group, 'held child remains in the inherited group');
    isnt($child->{pid}, $child->{group}, 'held child has no owned group yet');
    is($result->{status}, 'timed_out', 'unchanged deadline bounds pre-group setup');
    is($result->{stdout}, '', 'held command never executes');
    check_cleanup($result, $child->{pid});
};

subtest 'a successful return without actual membership remains a refusal' => sub {
    my $path = File::Spec->catfile($workspace, 'false-success.json');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        write_observation($path, {pid => $$, group => getpgrp(0)}) if $_[0] == 0;
        return 0;
    };
    my $result = run_probe('print "command-executed\n"');
    my $child = read_observation($path);
    is($result->{status}, 'exec_error', 'false success cannot admit exec');
    is($child->{group}, $caller_group, 'child actually remains outside its own group');
    like($result->{exec_error}, qr/operation=membership expected=$child->{pid} observed=$caller_group\z/,
        'membership diagnostic remains independent of syscall status');
    is($result->{stdout}, '', 'uncontained command never executes');
    check_cleanup($result, $child->{pid});
};

done_testing();
