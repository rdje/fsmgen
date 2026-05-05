#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Parser;

subtest 'embedded source collectors return caller-owned AST snapshots' => sub {
    my $parser = FSM::Composition::Parser->new();
    my $raw_ast = [
        [
            '?top:root',
            [],
        ],
        [
            '?fsm:child_src',
            [
                ['+state', ['idle']],
            ],
        ],
        [
            '?dt:route_src',
            [
                ['+assign', ['next', 'value']],
            ],
        ],
        [
            '?pkg:param_pkg',
            [
                [
                    '+constants',
                    [
                        ['WIDTH', '16'],
                    ],
                ],
            ],
        ],
    ];

    my $embedded_fsm_sources = $parser->collect_embedded_fsm_sources($raw_ast);
    my $embedded_dt_sources = $parser->collect_embedded_dt_sources($raw_ast);
    my $embedded_package_sources = $parser->collect_embedded_package_sources($raw_ast);

    $embedded_fsm_sources->{child_src}[1][0][1][0] = 'mutated_state';
    $embedded_dt_sources->{route_src}[1][0][1][1] = 'mutated_value';
    $embedded_package_sources->{param_pkg}[1][0][1][0][1] = '99';

    is_deeply(
        $raw_ast,
        [
            [
                '?top:root',
                [],
            ],
            [
                '?fsm:child_src',
                [
                    ['+state', ['idle']],
                ],
            ],
            [
                '?dt:route_src',
                [
                    ['+assign', ['next', 'value']],
                ],
            ],
            [
                '?pkg:param_pkg',
                [
                    [
                        '+constants',
                        [
                            ['WIDTH', '16'],
                        ],
                    ],
                ],
            ],
        ],
        'mutating collected embedded source ASTs cannot contaminate the composition parser raw AST',
    );
};

done_testing();
