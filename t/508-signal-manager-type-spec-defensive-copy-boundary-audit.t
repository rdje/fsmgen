#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;

sub frame_type {
    return {
        kind => 'record',
        width => 9,
        member_order => [qw(flag payload)],
        members => {
            flag => {
                kind => 'bit',
                width => 1,
                signed => 0,
                state_model => 'two_state',
            },
            payload => {
                kind => 'bits',
                width => 8,
                signed => 0,
                state_model => 'four_state',
            },
        },
    };
}

subtest 'stored type specs are isolated from caller-owned input' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $type_spec = frame_type();

    $signal_manager->store_type('frame_t', $type_spec);
    $type_spec->{members}{payload}{width} = 99;
    push @{$type_spec->{member_order}}, 'mutated';

    is_deeply(
        $signal_manager->resolve_type('frame_t'),
        frame_type(),
        'stored type spec is not mutated through the original input hash',
    );
    is($signal_manager->resolve_type_width('frame_t'), 9, 'type width lookup reads the stored snapshot');
};

subtest 'resolved type specs are fresh caller-owned snapshots' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    $signal_manager->store_type('frame_t', frame_type());

    my $first = $signal_manager->resolve_type('frame_t');
    $first->{members}{flag}{state_model} = 'mutated';
    $first->{member_order}[0] = 'mutated';

    is_deeply(
        $signal_manager->resolve_type('frame_t'),
        frame_type(),
        'later type lookups are not affected by mutation of earlier lookup results',
    );
};

done_testing;
