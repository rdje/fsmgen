#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Package::Parser;

subtest 'package root discovery returns a caller-owned AST snapshot for direct root source' => sub {
    my $parser = FSM::Package::Parser->new();
    my $raw_ast = [
        '?pkg:param_pkg',
        [
            ['+constants', [['WIDTH', '16']]],
        ],
    ];

    my $package_root = $parser->find_package_root($raw_ast);
    $package_root->[1][0][1][0][1] = '99';

    is_deeply(
        $raw_ast,
        [
            '?pkg:param_pkg',
            [
                ['+constants', [['WIDTH', '16']]],
            ],
        ],
        'mutating discovered direct package root cannot contaminate the parser raw AST',
    );
};

subtest 'package root discovery returns a caller-owned AST snapshot for multi-root source' => sub {
    my $parser = FSM::Package::Parser->new();
    my $raw_ast = [
        [
            '?top:root',
            [],
        ],
        [
            '?pkg:param_pkg',
            [
                ['+constants', [['WIDTH', '16']]],
            ],
        ],
    ];

    my $package_root = $parser->find_package_root($raw_ast);
    $package_root->[1][0][1][0][1] = '99';

    is_deeply(
        $raw_ast,
        [
            [
                '?top:root',
                [],
            ],
            [
                '?pkg:param_pkg',
                [
                    ['+constants', [['WIDTH', '16']]],
                ],
            ],
        ],
        'mutating discovered multi-root package AST cannot contaminate the parser raw AST',
    );
};

done_testing();
