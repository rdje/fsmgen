#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'TestNode branch containers are owned by the node' => sub {
    my $test_signal = FSM::CoreAST::SignalRef->new(
        FSM::CoreAST::Signal->new(name => 'SEL'),
    );
    my $action = FSM::CoreAST::Action->new(type => 'test_action');
    my $branches = [
        {
            value => '0',
            actions => [$action],
            metadata => {
                label => 'zero',
            },
        },
    ];

    my $test_node = FSM::CoreAST::TestNode->new(
        test_signal => $test_signal,
        test_branches => $branches,
    );

    $branches->[0]{metadata}{label} = 'mutated_input';
    push @{$branches->[0]{actions}}, FSM::CoreAST::Action->new(type => 'input_mutation');

    is(
        $test_node->test_branches->[0]{metadata}{label},
        'zero',
        'constructor branch metadata mutation cannot contaminate TestNode',
    );
    is(
        scalar(@{$test_node->test_branches->[0]{actions}}),
        1,
        'constructor action-list mutation cannot contaminate TestNode',
    );
    is(
        $test_node->test_branches->[0]{actions}[0],
        $action,
        'contained action object identity is preserved in branch snapshots',
    );

    my $view = $test_node->test_branches;
    $view->[0]{metadata}{label} = 'mutated_output';
    push @{$view->[0]{actions}}, FSM::CoreAST::Action->new(type => 'output_mutation');

    is(
        $test_node->test_branches->[0]{metadata}{label},
        'zero',
        'test_branches accessor returns a fresh nested branch container',
    );
    is(
        scalar(@{$test_node->test_branches->[0]{actions}}),
        1,
        'test_branches accessor returns a fresh action-list container',
    );
};

subtest 'add_test_branch stores a branch snapshot' => sub {
    my $test_signal = FSM::CoreAST::SignalRef->new(
        FSM::CoreAST::Signal->new(name => 'MODE'),
    );
    my $action = FSM::CoreAST::Action->new(type => 'added_action');
    my $actions = [$action];
    my $test_node = FSM::CoreAST::TestNode->new(
        test_signal => $test_signal,
    );

    $test_node->add_test_branch('IDLE', $actions);
    push @$actions, FSM::CoreAST::Action->new(type => 'mutated_added_action');

    is(
        scalar(@{$test_node->test_branches->[0]{actions}}),
        1,
        'add_test_branch stores a snapshot of the supplied action list',
    );
    is_deeply(
        $test_node->get_all_test_values,
        ['IDLE'],
        'get_all_test_values still reports stored test values',
    );
    is(
        $test_node->get_all_actions->[0],
        $action,
        'get_all_actions still returns the contained action object',
    );
};

done_testing();
