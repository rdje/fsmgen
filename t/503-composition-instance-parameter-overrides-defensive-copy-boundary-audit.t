#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Instance;

subtest 'Composition::Instance parameter overrides are caller-owned across construction, access, and setter use' => sub {
    my $parameter_overrides = [
        {
            name => 'LANES',
            value_kind => 'list',
            value => [
                "8'hA5",
                "8'h3C",
            ],
            origin_kind => 'generated_child_parameter_override',
        },
    ];

    my $instance = FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => 'u_ctrl',
        source_name => 'ctrl_src',
        parameter_overrides => $parameter_overrides,
    );

    $parameter_overrides->[0]{value}[0] = 'mutated_after_constructor';

    my $first_overrides = $instance->parameter_overrides;
    $first_overrides->[0]{value}[1] = 'mutated_after_accessor';

    is_deeply(
        $instance->parameter_overrides,
        [
            {
                name => 'LANES',
                value_kind => 'list',
                value => [
                    "8'hA5",
                    "8'h3C",
                ],
                origin_kind => 'generated_child_parameter_override',
            },
        ],
        'parameter_overrides is isolated from constructor and accessor mutation',
    );

    my $resolved_overrides = [
        {
            name => 'WIDTH',
            value_kind => 'scalar',
            value => '16',
            origin_kind => 'resolved_generated_child_parameter_override',
        },
    ];

    my $returned_overrides = $instance->set_parameter_overrides($resolved_overrides);
    $resolved_overrides->[0]{value} = '32';
    $returned_overrides->[0]{value} = '64';

    is_deeply(
        $instance->parameter_overrides,
        [
            {
                name => 'WIDTH',
                value_kind => 'scalar',
                value => '16',
                origin_kind => 'resolved_generated_child_parameter_override',
            },
        ],
        'set_parameter_overrides input and return values cannot mutate stored overrides',
    );
};

done_testing();
