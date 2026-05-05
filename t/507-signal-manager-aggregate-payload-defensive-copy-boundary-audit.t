#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;

subtest 'aggregate payload storage copies caller-owned input' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $payload = {
        kind => 'list',
        items => [
            { kind => 'scalar', payload => q{8'h12} },
            { kind => 'scalar', payload => q{8'h34} },
        ],
    };

    ok($signal_manager->store_aggregate_symbol('FRAME', $payload), 'aggregate symbol is stored');
    $payload->{items}[0]{payload} = q{8'hFF};
    push @{$payload->{items}}, { kind => 'scalar', payload => q{8'h00} };

    is_deeply(
        $signal_manager->resolve_aggregate_symbol_payload('FRAME'),
        {
            kind => 'list',
            items => [
                { kind => 'scalar', payload => q{8'h12} },
                { kind => 'scalar', payload => q{8'h34} },
            ],
        },
        'stored payload is isolated from later input mutation',
    );
};

subtest 'aggregate payload resolver returns fresh copies' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    $signal_manager->store_aggregate_symbol(
        'BYTES',
        {
            kind => 'list',
            items => [
                { kind => 'scalar', payload => q{8'hAA} },
                { kind => 'scalar', payload => q{8'h55} },
            ],
        },
    );

    my $first = $signal_manager->resolve_aggregate_symbol_payload('BYTES');
    $first->{items}[0]{payload} = q{8'h00};
    push @{$first->{items}}, { kind => 'scalar', payload => q{8'h11} };

    is_deeply(
        $signal_manager->resolve_aggregate_symbol_payload('BYTES'),
        {
            kind => 'list',
            items => [
                { kind => 'scalar', payload => q{8'hAA} },
                { kind => 'scalar', payload => q{8'h55} },
            ],
        },
        'subsequent aggregate payload lookups are not affected by prior lookup mutation',
    );
};

subtest 'parameter-value aggregate symbol lookup returns fresh copies' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    $signal_manager->store_aggregate_symbol(
        'TABLE',
        {
            kind => 'list',
            items => [
                {
                    kind => 'struct',
                    fields => {
                        code => { kind => 'scalar', payload => q{4'hA} },
                    },
                },
            ],
        },
    );

    my $first = $signal_manager->resolve_parameter_value_symbol_payload('TABLE');
    $first->{items}[0]{fields}{code}{payload} = q{4'h0};

    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('TABLE'),
        {
            kind => 'list',
            items => [
                {
                    kind => 'struct',
                    fields => {
                        code => { kind => 'scalar', payload => q{4'hA} },
                    },
                },
            ],
        },
        'parameter-value symbol payload lookup preserves aggregate payload isolation',
    );
};

done_testing;
