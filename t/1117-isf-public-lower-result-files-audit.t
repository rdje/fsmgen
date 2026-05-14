#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_lower_result_presence_keys
);

subtest 'single-file ISF lower result exposes advertised files map' => sub {
    my $lowered = lower_fixture('apb_requester.isf');

    is_deeply(
        sorted([keys %{$lowered}]),
        sorted(isf_public_interface_lower_result_presence_keys()),
        'single-file lower result exposes exactly the advertised top-level keys',
    );
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        ['apb_requester.fsm'],
        'single-file lower result maps one scheduled .fsm basename',
    );
    like(
        $lowered->{files}{'apb_requester.fsm'},
        qr/\A\(\?fsm:apb_requester\b/,
        'single-file lower result stores scheduled .fsm text by basename',
    );
};

subtest 'multi-file ISF lower result exposes parent and child files' => sub {
    my $lowered = lower_fixture('spawn_parent.isf');

    is_deeply(
        sorted([keys %{$lowered}]),
        sorted(isf_public_interface_lower_result_presence_keys()),
        'multi-file lower result exposes exactly the advertised top-level keys',
    );
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(child_worker.fsm spawn_parent.fsm spawn_parent_top.fsm)],
        'multi-file lower result maps parent, spawned child, and generated top .fsm basenames',
    );
    like(
        $lowered->{files}{'spawn_parent.fsm'},
        qr/\A\(\?fsm:spawn_parent\b/,
        'multi-file lower result stores parent scheduled .fsm text',
    );
    like(
        $lowered->{files}{'child_worker.fsm'},
        qr/\A\(\?fsm:child_worker\b/,
        'multi-file lower result stores child scheduled .fsm text',
    );
    like(
        $lowered->{files}{'spawn_parent_top.fsm'},
        qr/\A\(\?top:spawn_parent_top\b/,
        'multi-file lower result stores generated top composition .fsm text',
    );
};

done_testing();

sub lower_fixture {
    my ($fixture) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
