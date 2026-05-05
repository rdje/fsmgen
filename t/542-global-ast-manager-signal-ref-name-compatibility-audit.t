#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::GlobalASTManager;

sub binary_enable_ast {
    return FSM::AST::BinaryOp->new(
        '&&',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
}

subtest 'legacy SignalRef keeps name alias for GlobalASTManager compatibility' => sub {
    my $signal_ref = FSM::AST::SignalRef->new('REQ');

    is($signal_ref->signal_name, 'REQ', 'signal_name accessor returns the signal name');
    is($signal_ref->name, 'REQ', 'name alias returns the signal name expected by legacy factorization code');
};

subtest 'GlobalASTManager factors repeated legacy ASTs containing SignalRef leaves' => sub {
    my $manager = FSM::GlobalASTManager->new;
    my $first = binary_enable_ast();
    my $second = binary_enable_ast();

    $manager->collect_ast($first, 'first_context');
    $manager->collect_ast($second, 'second_context');
    $manager->perform_structural_analysis;
    $manager->perform_top_level_factorization;

    my $factored_name = $manager->get_name_for_ast($first);
    ok($factored_name, 'repeated top-level AST receives a factored signal name');
    is(
        $manager->get_name_for_ast_structure($second),
        $factored_name,
        'structurally identical AST resolves to the same factored name',
    );

    my $signals = $manager->get_all_factored_signals;
    is_deeply(
        $signals->{$factored_name},
        {
            expr => '(A && B)',
            width => 1,
            source => 'global_factorization',
            usage_count => 2,
        },
        'factored signal summary is emitted from the repeated legacy AST structure',
    );
};

done_testing();
