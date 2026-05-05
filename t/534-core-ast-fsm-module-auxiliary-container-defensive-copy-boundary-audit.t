#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'FSMModule auxiliary metadata containers are owned by the module' => sub {
    my $clock_domains = {
        default => 'clk',
        derived => {
            name => 'clk_fast',
        },
    };
    my $reset_domains = {
        default => 'rst_n',
        derived => {
            name => 'rst_fast_n',
        },
    };
    my $parameters = {
        WIDTH => {
            value_text => '8',
            tags => ['public'],
        },
    };

    my $module = FSM::CoreAST::FSMModule->new(
        name => 'aux_module',
        clock_domains => $clock_domains,
        reset_domains => $reset_domains,
        parameters => $parameters,
    );

    $clock_domains->{derived}{name} = 'mutated_clock';
    $reset_domains->{derived}{name} = 'mutated_reset';
    push @{$parameters->{WIDTH}{tags}}, 'mutated_input';

    is(
        $module->clock_domains->{derived}{name},
        'clk_fast',
        'constructor clock-domain mutation cannot contaminate module',
    );
    is(
        $module->reset_domains->{derived}{name},
        'rst_fast_n',
        'constructor reset-domain mutation cannot contaminate module',
    );
    is_deeply(
        $module->parameters->{WIDTH}{tags},
        ['public'],
        'constructor parameter mutation cannot contaminate module',
    );

    my $clock_view = $module->clock_domains;
    my $reset_view = $module->reset_domains;
    my $parameter_view = $module->parameters;
    $clock_view->{derived}{name} = 'mutated_again';
    $reset_view->{derived}{name} = 'mutated_again';
    push @{$parameter_view->{WIDTH}{tags}}, 'mutated_output';

    is(
        $module->clock_domains->{derived}{name},
        'clk_fast',
        'clock_domains accessor returns a fresh nested map',
    );
    is(
        $module->reset_domains->{derived}{name},
        'rst_fast_n',
        'reset_domains accessor returns a fresh nested map',
    );
    is_deeply(
        $module->parameters->{WIDTH}{tags},
        ['public'],
        'parameters accessor returns fresh nested metadata',
    );

    my $depth = {
        value_text => '16',
        tags => ['generated'],
    };
    $module->set_parameter(DEPTH => $depth);
    push @{$depth->{tags}}, 'mutated_after_set';
    is(
        $module->parameters->{DEPTH}{value_text},
        '16',
        'explicit parameter mutation path remains visible through snapshots',
    );
    is_deeply(
        $module->parameters->{DEPTH}{tags},
        ['generated'],
        'explicit parameter mutation path clones its input metadata',
    );
};

subtest 'FSMModule broad graph compatibility surfaces remain live' => sub {
    my $state = FSM::CoreAST::State->new(name => 'idle');
    my $signal = FSM::CoreAST::Signal->new(name => 'READY');
    my $module = FSM::CoreAST::FSMModule->new(
        name => 'graph_module',
        states => [$state],
        signals => {
            READY => $signal,
        },
        attributes => {
            source_root_kind => 'fsm',
        },
    );

    is(
        $module->states->[0],
        $state,
        'states compatibility accessor still returns the live state list',
    );
    is(
        $module->signals->{READY},
        $signal,
        'signals compatibility accessor still returns the live signal map',
    );

    $module->attributes->{source_root_kind} = 'dt';
    is($module->source_root_kind, 'dt', 'broad attributes compatibility accessor remains live');
};

done_testing();
