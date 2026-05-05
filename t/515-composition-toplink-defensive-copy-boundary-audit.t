#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::TopLink;

sub expected_links {
    return [
        { source => 'producer.out', target => 'consumer.in' },
        { source => 'consumer.done', target => 'done' },
    ];
}

sub expected_raw_ast {
    return [
        '?toplink:wiring',
        '/producer.out/consumer.in/',
    ];
}

subtest 'TopLink constructor copies mutable inputs' => sub {
    my $links = expected_links();
    my $raw_ast = expected_raw_ast();
    my $toplink = FSM::Composition::TopLink->new(
        name => 'wiring',
        links => $links,
        raw_ast => $raw_ast,
    );

    $links->[0]{source} = 'mutated.out';
    push @$links, { source => 'late.out', target => 'late.in' };
    $raw_ast->[1] = '/mutated/out/';

    is_deeply($toplink->links, expected_links(), 'toplink stores a snapshot of constructor links');
    is_deeply($toplink->raw_ast, expected_raw_ast(), 'toplink stores a snapshot of constructor raw AST');
};

subtest 'TopLink accessors return caller-owned containers' => sub {
    my $toplink = FSM::Composition::TopLink->new(
        name => 'wiring',
        links => expected_links(),
        raw_ast => expected_raw_ast(),
    );

    my $links = $toplink->links;
    $links->[0]{target} = 'mutated.in';
    push @$links, { source => 'late.out', target => 'late.in' };

    my $raw_ast = $toplink->raw_ast;
    $raw_ast->[1] = '/mutated/out/';

    is_deeply($toplink->links, expected_links(), 'links accessor returns a fresh container');
    is_deeply($toplink->raw_ast, expected_raw_ast(), 'raw_ast accessor returns a fresh container');
};

done_testing;
