#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;

subtest 'stored enum member maps are isolated from caller-owned input' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $members = {
        IDLE => 0,
        RUN => 1,
    };

    $signal_manager->store_enum('mode', $members);
    $members->{RUN} = 99;
    $members->{BROKEN} = 2;

    is(
        $signal_manager->resolve_symbol('mode.RUN')->to_systemverilog,
        '1',
        'enum member expression resolves from the stored enum snapshot',
    );
    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('mode.RUN'),
        {
            kind => 'scalar',
            payload => 1,
        },
        'enum member parameter payload resolves from the stored enum snapshot',
    );
    is(
        $signal_manager->resolve_symbol('mode.BROKEN'),
        undef,
        'later input-only enum members are not visible after storage',
    );
};

subtest 'enum parameter payload lookups return fresh hashes' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    $signal_manager->store_enum('mode', { IDLE => 0, RUN => 1 });

    my $first = $signal_manager->resolve_parameter_value_symbol_payload('mode.RUN');
    $first->{payload} = 99;

    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('mode.RUN'),
        {
            kind => 'scalar',
            payload => 1,
        },
        'later enum payload lookups are not affected by previous lookup mutation',
    );
};

done_testing;
