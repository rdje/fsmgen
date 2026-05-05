#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Instance;

sub expected_raw_items {
    return [
        ['?params', ['WIDTH', '8']],
        'child_src',
    ];
}

sub expected_raw_ast {
    return [
        '?fsmc:u_child',
        ['?params', ['WIDTH', '8']],
    ];
}

subtest 'Instance constructor copies raw parse containers' => sub {
    my $raw_items = expected_raw_items();
    my $raw_ast = expected_raw_ast();
    my $instance = FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => 'u_child',
        source_name => 'child_src',
        raw_items => $raw_items,
        raw_ast => $raw_ast,
    );

    $raw_items->[0][1][1] = '99';
    $raw_ast->[1][1][1] = '99';

    is_deeply($instance->raw_items, expected_raw_items(), 'raw_items are isolated from constructor mutation');
    is_deeply($instance->raw_ast, expected_raw_ast(), 'raw_ast is isolated from constructor mutation');
};

subtest 'Instance raw accessors return caller-owned containers' => sub {
    my $instance = FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => 'u_child',
        source_name => 'child_src',
        raw_items => expected_raw_items(),
        raw_ast => expected_raw_ast(),
    );

    my $raw_items = $instance->raw_items;
    $raw_items->[0][1][1] = '99';
    push @$raw_items, 'late';

    my $raw_ast = $instance->raw_ast;
    $raw_ast->[1][1][1] = '99';

    is_deeply($instance->raw_items, expected_raw_items(), 'raw_items accessor returns a fresh container');
    is_deeply($instance->raw_ast, expected_raw_ast(), 'raw_ast accessor returns a fresh container');
};

done_testing;
