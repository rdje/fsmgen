#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Context;

{
    package Test::ExtensionContextPayloadPipeline;
    sub new { return bless {}, shift }
}

sub base_args {
    return (
        pipeline => Test::ExtensionContextPayloadPipeline->new,
        source_path => 'design.fsm',
        target_language => 'systemverilog',
    );
}

subtest 'source_info and raw_ast parse payloads are context-owned snapshots' => sub {
    my $source_info = {
        kind => 'fsm',
        package_import_names => ['shared'],
    };
    my $raw_ast = [
        '?fsm',
        [
            '+imports',
            ['shared'],
        ],
    ];
    my $context = FSM::Extension::Context->new(
        base_args(),
        stage => 'after_parse_source',
        source_info => $source_info,
        raw_ast => $raw_ast,
    );

    push @{$source_info->{package_import_names}}, 'mutated_input';
    $raw_ast->[1][1][0] = 'mutated_input';

    is_deeply(
        $context->source_info->{package_import_names},
        ['shared'],
        'constructor source_info mutation cannot contaminate context',
    );
    is_deeply(
        $context->raw_ast,
        [
            '?fsm',
            [
                '+imports',
                ['shared'],
            ],
        ],
        'constructor raw_ast mutation cannot contaminate context',
    );

    my $source_info_view = $context->source_info;
    my $raw_ast_view = $context->raw_ast;
    push @{$source_info_view->{package_import_names}}, 'mutated_output';
    $raw_ast_view->[1][1][0] = 'mutated_output';

    is_deeply(
        $context->source_info->{package_import_names},
        ['shared'],
        'source_info accessor returns a fresh nested snapshot',
    );
    is_deeply(
        $context->raw_ast,
        [
            '?fsm',
            [
                '+imports',
                ['shared'],
            ],
        ],
        'raw_ast accessor returns a fresh nested snapshot',
    );
};

subtest 'result payload remains live for result-hook augmentation' => sub {
    my $source_info = {
        kind => 'dt',
        summary => {
            name => 'route',
        },
    };
    my $result = {
        module_info => {
            module_name => 'route',
        },
    };
    my $context = FSM::Extension::Context->new(
        base_args(),
        stage => 'after_generate_result',
        source_info => $source_info,
        result => $result,
    );

    $source_info->{summary}{name} = 'mutated_input';
    is(
        $context->source_info->{summary}{name},
        'route',
        'result context source_info is still snapshotted',
    );

    $context->result->{extension_marker} = 1;
    is($result->{extension_marker}, 1, 'result accessor remains the live mutation surface');
};

done_testing();
