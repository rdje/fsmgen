#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use Errno qw(EPERM EIO);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND);
use IO::Select;
use JSON::PP;
use POSIX ();
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use GroupWitness;

my $root = abs_path('.');
my $work = "$root/.artifacts/native-group-witness";
my $name = shift(@ARGV) // 'qualification';
die "invalid capture name\n" unless $name =~ /\A[a-z0-9_]+\z/ && !@ARGV;
my $capture = "$work/$name.jsonl";
sysopen my $sink, $capture, O_WRONLY | O_CREAT | O_EXCL | O_APPEND, 0600
    or die "exclusive witness capture: $!";
GroupWitness->load_context("$work/context.bundle");
my $caller_group = CORE::getpgrp(0);
my $caller = GroupWitness::context(0);
is($caller->{caller}{pid}, $$, 'native caller agrees with the running Perl PID');
is($caller->{caller}{ppid}, getppid(), 'native caller agrees with Perl parent identity');
is($caller->{caller}{pgid}, $caller_group, 'native group agrees with independent core query');
is_deeply($caller->{target}, {map {$_ => $caller->{caller}{$_}} qw(pid pgid pgid_errno sid sid_errno)},
    'zero PID refers to the same actual caller');
GroupWitness->install($sink);
my $witness = \&FSM::Support::ProcessSupervisor::setpgid;
my $writer = \&GroupWitness::record;
{
    no warnings 'redefine';
    *GroupWitness::record = sub {
        $writer->(@_);
        $! = EIO; # Diagnostic I/O cannot change the actual syscall's errno.
        return 1;
    };
}


sub exchange {
    my ($handle, $write, $token) = @_;
    local $!;
    if ($write) {
        die "control write failed\n" unless syswrite($handle, $token, 1) == 1;
    } else {
        die "control read deadline\n" unless IO::Select->new($handle)->can_read(2);
        my $observed;
        die "control read failed\n" unless sysread($handle, $observed, 1) == 1 && $observed eq $token;
    }
}

for my $mode (qw(ordinary parent_first child_first session_leader success_stale)) {
    $GroupWitness::label = $mode;
    pipe my $parent_ready, my $parent_send or die $!;
    pipe my $child_ready, my $child_send or die $!;
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @arguments = @_;
        if ($arguments[0] == 0) {
            if ($mode eq 'session_leader') {
                my $session = POSIX::setsid();
                die "native session control failed\n" unless defined($session) && $session == $$;
            }
            exchange($parent_ready, 0, 'P') if $mode eq 'parent_first';
            $! = EPERM if $mode eq 'success_stale';
            my $result = $witness->(@arguments);
            my $error = 0 + $!;
            if ($mode eq 'child_first') {
                exchange($child_send, 1, 'C');
                exchange($parent_ready, 0, 'P');
            }
            $! = $error;
            return $result;
        }
        return 0 if $mode eq 'session_leader';
        exchange($child_ready, 0, 'C') if $mode eq 'child_first';
        $! = EPERM if $mode eq 'success_stale';
        my $result = $witness->(@arguments);
        my $error = 0 + $!;
        exchange($parent_send, 1, 'P') if $mode eq 'parent_first' || $mode eq 'child_first';
        $! = $error;
        return $result;
    };
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
        bounds => {timeout_seconds => 2, capture_limit_bytes => 65_536},
        containment => 'process_supervisor_probe_group', cwd => $work,
        argv => [$^X, '-e', 'print "native-witness-command=$$\n"'],
    );
    GroupWitness::record({event => 'result', label => $mode, result => $result});
    if ($mode eq 'session_leader') {
        is($result->{status}, 'exec_error', 'native EPERM remains a pre-exec rejection');
        like($result->{exec_error}, qr/operation=setpgid result=undef errno=1 /,
            'native failure keeps the existing exact diagnostic meaning');
        is($result->{stdout}, '', 'rejected native session never executes the command');
    } else {
        ok($result->{ok}, "$mode executes through unchanged admission") or diag explain $result;
        like($result->{stdout}, qr/^native-witness-command=\d+\n$/, "$mode executes its exact body once");
    }
    ok($result->{cleanup}{leader_reaped}, "$mode exact leader reaped");
    ok($result->{cleanup}{group_gone}, "$mode exact group absent");
    is(CORE::getpgrp(0), $caller_group, "$mode leaves the observer group unchanged");
    close $_ for ($parent_ready, $parent_send, $child_ready, $child_send);
}

ok(!GroupWitness::capture_error(), 'all original witness writes completed');
my $size = -s $capture;
my $oversized = eval { GroupWitness::record({padding => 'x' x 4096}); 1 };
ok(!$oversized && $@ =~ /capture envelope/, 'row excess is refused before writing');
is(-s $capture, $size, 'row excess preserves prior evidence');
truncate($sink, 1_048_575) or die $!;
my $full = eval { GroupWitness::record({event => 'overflow'}); 1 };
ok(!$full && $@ =~ /capture envelope/, 'aggregate excess is refused before writing');
truncate($sink, $size) or die $!;
is(-s $capture, $size, 'owned padding is removed and original evidence retained');
close $sink or die $!;
done_testing();
