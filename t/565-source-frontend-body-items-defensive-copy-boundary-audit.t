#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::SourceFrontend;

subtest 'direct-root body item extraction returns caller-owned AST containers' => sub {
    my $raw_ast = [
        '?fsm:body_items_direct',
        [
            [
                '+import',
                ['shared_pkg'],
            ],
        ],
    ];
    my $source_info = {
        kind => 'fsm',
        header => '?fsm:body_items_direct',
    };

    my $body_items = FSM::Pipeline::SourceFrontend->_direct_root_body_items(
        raw_ast => $raw_ast,
        source_info => $source_info,
    );
    $body_items->[0][1][0] = 'mutated_pkg';

    is_deeply(
        $raw_ast->[1],
        [
            [
                '+import',
                ['shared_pkg'],
            ],
        ],
        'mutating returned direct-root body items cannot contaminate the source AST',
    );
};

subtest 'composition body item extraction returns caller-owned AST containers' => sub {
    my $raw_ast = [
        '?top:body_items_top',
        [
            [
                '+import',
                ['shared_pkg'],
            ],
        ],
    ];
    my $source_info = {
        kind => 'composition',
        header => '?top:body_items_top',
    };

    my $body_items = FSM::Pipeline::SourceFrontend->_composition_body_items(
        raw_ast => $raw_ast,
        source_info => $source_info,
    );
    $body_items->[0][1][0] = 'mutated_pkg';

    is_deeply(
        $raw_ast->[1],
        [
            [
                '+import',
                ['shared_pkg'],
            ],
        ],
        'mutating returned composition body items cannot contaminate the source AST',
    );
};

done_testing();
