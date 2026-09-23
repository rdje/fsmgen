#!/usr/bin/env perl
use strict;
use warnings;
use IO::Select;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor ();

# Actual pipes, with no child, isolate capture policy from launch and cleanup.
sub fixture {
    my ($limit) = @_;
    my $state = {stdout => '', stderr => '', exec_error => '',
        bounds => {capture_limit_bytes => $limit}, select => IO::Select->new(), streams => {}};
    my %writers;
    for my $name (qw(stdout stderr control)) {
        pipe(my $read, my $write) or die $!;
        FSM::Support::ProcessSupervisor::_set_nonblocking($read) or die 'nonblocking setup';
        $state->{streams}{fileno($read)} = [$name, $read];
        $state->{select}->add($read);
        $state->{control_fileno} = fileno($read) if $name eq 'control';
        $writers{$name} = $write;
    }
    return ($state, \%writers);
}
sub send_bytes {
    my ($fh, $bytes) = @_;
    my $n = syswrite($fh, $bytes);
    die 'fixture pipe write failed' unless defined($n) && $n == length($bytes);
}
sub close_fixture {
    my ($state, $writers) = @_;
    close $_ for grep { defined fileno($_) } values %$writers;
    close $_->[1] for values %{$state->{streams}};
}

subtest 'nonblocking reads preserve separate streams and control EOF meaning' => sub {
    my ($state, $writers) = fixture(16);
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is($state->{stdout}, '', 'empty live pipe returns without inventing bytes');
    ok(!defined($state->{first_output}), 'no false first-output observation');
    send_bytes($writers->{stderr}, "err\x00\xff");
    send_bytes($writers->{stdout}, 'out');
    close $writers->{control};
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is($state->{stdout}, 'out', 'stdout remains separate');
    is($state->{stderr}, "err\x00\xff", 'stderr remains exact bytes');
    ok(defined($state->{exec_handoff}), 'control EOF retains the existing closure observation');
    ok(defined($state->{first_output}), 'real output has an observation');
    ok(!exists($state->{phase}), 'read pass does not choose a process lifecycle transition');
    close $writers->{stdout}; close $writers->{stderr};
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is($state->{select}->count, 0, 'actual EOF removes every reader');
    is_deeply($state->{streams}, {}, 'no stale stream ownership remains');
    close_fixture($state, $writers);
};

subtest 'inclusive aggregate limit and adjacent excess preserve exact prefix' => sub {
    my ($state, $writers) = fixture(6);
    send_bytes($writers->{stdout}, 'abcd');
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    send_bytes($writers->{stderr}, 'ef');
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    ok(!$state->{output_limited}, 'exact combined limit is accepted');
    send_bytes($writers->{stderr}, 'g');
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    ok($state->{output_limited}, 'next actual byte trips combined limit');
    is($state->{stdout} . $state->{stderr}, 'abcdef', 'accepted aggregate prefix is retained');
    close_fixture($state, $writers);
    ($state, $writers) = fixture(3);
    send_bytes($writers->{stdout}, 'abcde');
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is($state->{stdout}, 'abc', 'crossing read retains only admitted prefix');
    ok($state->{output_limited}, 'crossing read retains overflow failure');
    close_fixture($state, $writers);
};

subtest 'control error stays bounded and never becomes successful handoff' => sub {
    my ($state, $writers) = fixture(4);
    send_bytes($writers->{control}, 'exec failed');
    close $writers->{control};
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is($state->{exec_error}, 'exec failed', 'private control bytes survive');
    ok(!defined($state->{exec_handoff}), 'error plus EOF cannot become successful control handoff');
    ok(!defined($state->{first_output}), 'control bytes do not count as user output');
    close_fixture($state, $writers);
    ($state, $writers) = fixture(4);
    send_bytes($writers->{control}, 'x' x 2048);
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    is(length($state->{exec_error}), 2048, 'inclusive control bound is retained');
    send_bytes($writers->{control}, 'x');
    FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
    like($state->{host_error}, qr/exec-control message exceeded/, 'adjacent control excess fails closed');
    is(length($state->{exec_error}), 2048, 'excess is not appended');
    close_fixture($state, $writers);
};

done_testing();
