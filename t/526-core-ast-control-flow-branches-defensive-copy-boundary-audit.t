#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'ControlFlow branches and attributes are container snapshots' => sub {
    my $action = FSM::CoreAST::Action->new(type => 'branch_action');
    my $branches = [
        {
            condition => 'guard_a',
            actions => [$action],
            metadata => {
                labels => [qw(fast path)],
            },
        },
    ];
    my $attributes = {
        source => {
            block => 'conditional',
        },
    };

    my $flow = FSM::CoreAST::ControlFlow->new(
        type => 'custom_flow',
        branches => $branches,
        attributes => $attributes,
    );

    $branches->[0]{metadata}{labels}[0] = 'mutated_input';
    push @{$branches->[0]{actions}}, FSM::CoreAST::Action->new(type => 'input_mutation');
    $attributes->{source}{block} = 'mutated_block';

    is_deeply(
        $flow->branches->[0]{metadata}{labels},
        [qw(fast path)],
        'constructor branch metadata mutation cannot contaminate control flow',
    );
    is(
        scalar(@{$flow->branches->[0]{actions}}),
        1,
        'constructor action-list mutation cannot contaminate control flow',
    );
    is(
        $flow->branches->[0]{actions}[0],
        $action,
        'contained action objects retain identity inside cloned branch containers',
    );
    is_deeply(
        $flow->attributes,
        {
            source => {
                block => 'conditional',
            },
        },
        'constructor attribute mutation cannot contaminate control flow',
    );

    my $branch_view = $flow->branches;
    my $attribute_view = $flow->attributes;
    $branch_view->[0]{metadata}{labels}[1] = 'mutated_output';
    push @{$branch_view->[0]{actions}}, FSM::CoreAST::Action->new(type => 'output_mutation');
    $attribute_view->{source}{block} = 'mutated_again';

    is_deeply(
        $flow->branches->[0]{metadata}{labels},
        [qw(fast path)],
        'branches accessor returns fresh nested branch containers',
    );
    is(
        scalar(@{$flow->branches->[0]{actions}}),
        1,
        'branches accessor returns a fresh action list container',
    );
    is_deeply(
        $flow->attributes,
        {
            source => {
                block => 'conditional',
            },
        },
        'attributes accessor returns fresh nested metadata',
    );
};

subtest 'ConditionalBranch uses the same branch container ownership' => sub {
    my $action = FSM::CoreAST::Action->new(type => 'conditional_action');
    my $branches = [
        {
            condition => 'guard_b',
            actions => [$action],
            metadata => {
                label => 'primary',
            },
        },
    ];

    my $conditional = FSM::CoreAST::ConditionalBranch->new(
        condition => 'root_guard',
        branches => $branches,
        attributes => {
            owner => {
                name => 'parser',
            },
        },
    );

    $branches->[0]{metadata}{label} = 'mutated_input';
    my $view = $conditional->branches;
    $view->[0]{metadata}{label} = 'mutated_output';

    is(
        $conditional->branches->[0]{metadata}{label},
        'primary',
        'conditional branches are isolated from constructor and accessor mutation',
    );
    is(
        $conditional->get_all_actions->[0],
        $action,
        'conditional helper still returns the contained action object',
    );
};

done_testing();
