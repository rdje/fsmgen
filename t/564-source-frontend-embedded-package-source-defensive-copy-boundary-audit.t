#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::SourceFrontend;

subtest 'embedded package source collection returns caller-owned AST snapshots' => sub {
    my $raw_ast = [
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
        [
            '?fsm:top',
            [],
        ],
    ];

    my $embedded_sources = FSM::Pipeline::SourceFrontend->collect_embedded_package_sources($raw_ast);
    $embedded_sources->{param_pkg}[1][0][1][0][1] = '99';

    is_deeply(
        $raw_ast->[0],
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
        'mutating collected embedded package AST cannot contaminate the source frontend raw AST',
    );
};

done_testing();
