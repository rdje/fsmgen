#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::WiringBlock;

sub expected_links {
    return [
        { source => 'producer.out', target => 'consumer.in' },
        { source => 'consumer.done', target => 'done' },
    ];
}

sub expected_raw_ast {
    return [
        '?wiring:wiring',
        '/producer.out/consumer.in/',
    ];
}

subtest 'WiringBlock constructor copies mutable inputs' => sub {
    my $links = expected_links();
    my $raw_ast = expected_raw_ast();
    my $wiring = FSM::Composition::WiringBlock->new(
        name => 'wiring',
        links => $links,
        raw_ast => $raw_ast,
    );

    $links->[0]{source} = 'mutated.out';
    push @$links, { source => 'late.out', target => 'late.in' };
    $raw_ast->[1] = '/mutated/out/';

    is_deeply($wiring->links, expected_links(), 'wiring stores a snapshot of constructor links');
    is_deeply($wiring->raw_ast, expected_raw_ast(), 'wiring stores a snapshot of constructor raw AST');
};

subtest 'WiringBlock accessors return caller-owned containers' => sub {
    my $wiring = FSM::Composition::WiringBlock->new(
        name => 'wiring',
        links => expected_links(),
        raw_ast => expected_raw_ast(),
    );

    my $links = $wiring->links;
    $links->[0]{target} = 'mutated.in';
    push @$links, { source => 'late.out', target => 'late.in' };

    my $raw_ast = $wiring->raw_ast;
    $raw_ast->[1] = '/mutated/out/';

    is_deeply($wiring->links, expected_links(), 'links accessor returns a fresh container');
    is_deeply($wiring->raw_ast, expected_raw_ast(), 'raw_ast accessor returns a fresh container');
};

done_testing;
