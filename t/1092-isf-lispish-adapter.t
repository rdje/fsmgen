#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use Lispish;
use JSON::PP;
use FSM::Adapter::ISF::LispishAdapter;

subtest 'normalize_form flattens Lispish nested head convention' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();

    my $raw = Lispish::single(\'(actor apb (clock clk) (reset rst_n (async)))');
    my $form = $adapter->normalize_form($raw);
    is($form->[0], 'actor', 'head preserved');
    is($form->[1], 'apb', 'name extracted from sub-array');
    is(ref($form->[2]), 'ARRAY', 'body element is array');
    is($form->[2][0], 'clock', 'clock clause head');
    is($form->[2][1], 'clk', 'clock name leaf-unwrapped');
};

subtest 'normalize_form handles singleton leaf unwrapping' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();

    my $raw = Lispish::single(\'(interface (input start) (output done))');
    my $form = $adapter->normalize_form($raw);
    is($form->[0], 'interface');
    my $input = $form->[1];
    is($input->[0], 'input');
    is($input->[1], 'start', 'port name leaf-unwrapped');
};

subtest 'normalize_form handles numeric literals' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();

    my $raw = Lispish::single(\'(latency (min 2) (max 16))');
    my $form = $adapter->normalize_form($raw);
    is($form->[0], 'latency');
    is_deeply($form->[1], ['min', '2'], 'min clause');
    is_deeply($form->[2], ['max', '16'], 'max clause');
};

subtest 'nested list heads normalize recursively without changing the raw caller' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();
    my $json = JSON::PP->new->canonical;
    for my $case (
        ['((1 2) (3 4))', '[["1","2"],["3","4"]]'],
        ['((1 2 3) (4 5 6) (7 8 9))', '[["1","2","3"],["4","5","6"],["7","8","9"]]'],
        ['(((1 2) (3 4)) ((5 6) (7 8)))', '[[["1","2"],["3","4"]],[["5","6"],["7","8"]]]'],
        ['((1 2))', '[["1","2"],null]'],
        ['(pair (1) (2))', '["pair",["1",null],["2",null]]'],
        ['(when (== flag 1) (set data (| left right)))',
            '["when",["==","flag","1"],["set","data",["|","left","right"]]]'],
    ) {
        my $raw = Lispish::single(\$case->[0]);
        my $before = $json->encode($raw);
        my $form = $adapter->normalize_form($raw);
        is($json->encode($form), $case->[1], "literal shape and kinds: $case->[0]");
        is($json->encode($raw), $before, 'normalization preserves complete raw caller');
        # Mutating the returned first row must not reach a raw Lispish row.
        $form->[0][0] = 'changed' if ref($form->[0]) eq 'ARRAY';
        is($json->encode($raw), $before, 'returned list head is detached');
    }
};

subtest 'find_form_by_head locates form in multi-form result' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();

    my $raw = Lispish::multi(\'(comment one) (actor main (clock clk)) (comment two)');
    my $form = $adapter->find_form_by_head($raw, 'actor');
    ok($form, 'actor form found');
    is($form->[0], 'actor');
    is($form->[1], 'main');

    my $missing = $adapter->find_form_by_head($raw, 'transaction');
    ok(!$missing, 'non-existent form returns undef');
};

subtest 'reset options retain authored empty lists separately from singleton tails' => sub {
    my $adapter = FSM::Adapter::ISF::LispishAdapter->new();
    for my $case (
        ['(reset (rst_n ()))', ['reset', ['rst_n', []]]],
        ['(reset (rst_n () active_low))', ['reset', ['rst_n', [], 'active_low']]],
        ['(reset (rst_n async ()))', ['reset', ['rst_n', 'async', []]]],
        ['(reset (rst_n))', ['reset', ['rst_n', undef]]],
        ['(reset rst_n)', ['reset', 'rst_n']],
        ['(reset 0)', ['reset', '0']],
        ['(options ())', ['options', undef]],
    ) {
        my $raw = Lispish::single(\$case->[0]);
        is_deeply($adapter->normalize_form($raw), $case->[1], $case->[0]);
    }
};

done_testing();
