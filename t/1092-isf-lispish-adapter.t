#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use Lispish;
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

done_testing();
