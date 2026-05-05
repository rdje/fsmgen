#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Parser;

subtest 'top root discovery returns a caller-owned AST snapshot for direct root source' => sub {
    my $parser = FSM::Composition::Parser->new();
    my $raw_ast = [
        '?top:root',
        [
            ['+ports', [['/child/out/top_out']]],
        ],
    ];

    my $top_root = $parser->find_top_root($raw_ast);
    $top_root->[1][0][1][0] = '/mutated/out/top_out';

    is_deeply(
        $raw_ast,
        [
            '?top:root',
            [
                ['+ports', [['/child/out/top_out']]],
            ],
        ],
        'mutating discovered direct top root cannot contaminate the parser raw AST',
    );
};

subtest 'top root discovery returns a caller-owned AST snapshot for multi-root source' => sub {
    my $parser = FSM::Composition::Parser->new();
    my $raw_ast = [
        [
            '?pkg:param_pkg',
            [
                ['+constants', [['WIDTH', '16']]],
            ],
        ],
        [
            '?top:root',
            [
                ['+instances', [['child', 'leaf']]],
            ],
        ],
    ];

    my $top_root = $parser->find_top_root($raw_ast);
    $top_root->[1][0][1][0][1] = 'mutated_leaf';

    is_deeply(
        $raw_ast,
        [
            [
                '?pkg:param_pkg',
                [
                    ['+constants', [['WIDTH', '16']]],
                ],
            ],
            [
                '?top:root',
                [
                    ['+instances', [['child', 'leaf']]],
                ],
            ],
        ],
        'mutating discovered multi-root top AST cannot contaminate the parser raw AST',
    );
};

done_testing();
