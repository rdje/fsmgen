#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'State decision-tree and attribute containers are owned by the state' => sub {
    my $first_dt = FSM::CoreAST::DecisionTree->new(name => 'first_dt');
    my $second_dt = FSM::CoreAST::DecisionTree->new(name => 'second_dt');
    my $decision_trees = [$first_dt];
    my $attributes = {
        source => {
            block => 'idle',
        },
    };

    my $state = FSM::CoreAST::State->new(
        name => 'idle',
        decision_trees => $decision_trees,
        attributes => $attributes,
    );

    push @$decision_trees, FSM::CoreAST::DecisionTree->new(name => 'input_mutation');
    $attributes->{source}{block} = 'mutated_block';

    is(
        scalar(@{$state->decision_trees}),
        1,
        'constructor decision-tree list mutation cannot contaminate state',
    );
    is(
        $state->decision_trees->[0],
        $first_dt,
        'contained decision-tree object identity is preserved in snapshots',
    );
    is_deeply(
        $state->attributes,
        {
            source => {
                block => 'idle',
            },
        },
        'constructor attribute mutation cannot contaminate state',
    );

    my $tree_view = $state->decision_trees;
    my $attribute_view = $state->attributes;
    push @$tree_view, FSM::CoreAST::DecisionTree->new(name => 'output_mutation');
    $attribute_view->{source}{block} = 'mutated_again';

    is(
        scalar(@{$state->decision_trees}),
        1,
        'decision_trees accessor returns a fresh list container',
    );
    is_deeply(
        $state->attributes,
        {
            source => {
                block => 'idle',
            },
        },
        'attributes accessor returns fresh nested metadata',
    );

    $state->add_decision_tree($second_dt);
    is(
        scalar(@{$state->decision_trees}),
        2,
        'add_decision_tree remains the explicit mutation path',
    );
    is(
        $state->decision_trees->[1],
        $second_dt,
        'add_decision_tree stores the supplied DecisionTree object by identity',
    );
};

done_testing();
