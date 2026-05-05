#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Instance;
use FSM::Composition::ParameterOverrideResolver;
use FSM::Composition::TopSymbols;

subtest 'deferred parameter override resolution owns parser metadata' => sub {
    my $top_symbols = FSM::Composition::TopSymbols->new(
        constants => {
            PARAM_WIDTH => {
                kind => 'scalar',
                payload => '16',
            },
        },
    );
    my $override = {
        name => 'WIDTH',
        raw_value => 'PARAM_WIDTH',
        value_kind => 'deferred_symbol',
        deferred_value_symbol => 'PARAM_WIDTH',
        metadata => {
            contexts => ['parser'],
        },
    };

    my $resolved = FSM::Composition::ParameterOverrideResolver->_resolve_override(
        top_name => 'top',
        instance => FSM::Composition::Instance->new(
            kind => 'rtl',
            name => 'u_child',
            module_name => 'child_mod',
        ),
        override => $override,
        top_symbols => $top_symbols,
    );

    $resolved->{metadata}{contexts}[0] = 'mutated_after_resolution';

    is_deeply(
        $override->{metadata},
        {
            contexts => ['parser'],
        },
        'mutating resolved override metadata cannot contaminate the parser-owned deferred override',
    );
    is($resolved->{value_text}, '16', 'resolver still lowers the deferred symbol to canonical text');
    is($resolved->{value_kind}, 'scalar', 'resolver still records the resolved scalar value kind');
    ok(!exists $resolved->{deferred_value_symbol}, 'resolver still removes deferred symbol bookkeeping');
};

done_testing();
