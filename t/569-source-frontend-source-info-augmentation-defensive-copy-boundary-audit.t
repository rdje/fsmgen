#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::SourceFrontend;

subtest 'source-info package-import augmentation does not mutate caller source_info' => sub {
    my $raw_ast = [
        '?fsm:direct_imports',
        [
            ['+import', ['param_pkg', 'types_pkg']],
        ],
    ];
    my $source_info = {
        kind => 'fsm',
        header => '?fsm:direct_imports',
        metadata => {
            labels => ['caller_owned'],
        },
    };

    my $augmented = FSM::Pipeline::SourceFrontend->_augment_source_info_package_import_summary(
        raw_ast => $raw_ast,
        source_info => $source_info,
    );

    is_deeply(
        $source_info,
        {
            kind => 'fsm',
            header => '?fsm:direct_imports',
            metadata => {
                labels => ['caller_owned'],
            },
        },
        'caller source_info is unchanged after direct-root package-import augmentation',
    );

    $augmented->{metadata}{labels}[0] = 'mutated';
    is(
        $source_info->{metadata}{labels}[0],
        'caller_owned',
        'returned source_info copy does not alias nested caller metadata',
    );
};

subtest 'composition source-info package-import augmentation does not mutate caller source_info' => sub {
    my $raw_ast = [
        '?top:composition_imports',
        [
            ['+import', ['param_pkg']],
        ],
    ];
    my $source_info = {
        kind => 'composition',
        header => '?top:composition_imports',
    };

    my $augmented = FSM::Pipeline::SourceFrontend->_augment_source_info_package_import_summary(
        raw_ast => $raw_ast,
        source_info => $source_info,
    );

    is_deeply(
        $source_info,
        {
            kind => 'composition',
            header => '?top:composition_imports',
        },
        'caller source_info is unchanged after composition package-import augmentation',
    );
    is_deeply(
        $augmented->{package_import_names},
        ['param_pkg'],
        'augmented source_info still reports composition package imports',
    );
};

done_testing();
