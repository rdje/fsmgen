#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'DecisionTree element and attribute containers are owned by the node' => sub {
    my $first_action = FSM::CoreAST::Action->new(type => 'first_action');
    my $second_action = FSM::CoreAST::Action->new(type => 'second_action');
    my $elements = [$first_action];
    my $attributes = {
        source => {
            block => 'main_dt',
        },
    };

    my $dt = FSM::CoreAST::DecisionTree->new(
        name => 'main_dt',
        elements => $elements,
        attributes => $attributes,
    );

    push @$elements, FSM::CoreAST::Action->new(type => 'input_mutation');
    $attributes->{source}{block} = 'mutated_block';

    is(
        scalar(@{$dt->elements}),
        1,
        'constructor element-list mutation cannot contaminate decision tree',
    );
    is(
        $dt->elements->[0],
        $first_action,
        'contained element object identity is preserved in element snapshots',
    );
    is_deeply(
        $dt->attributes,
        {
            source => {
                block => 'main_dt',
            },
        },
        'constructor attribute mutation cannot contaminate decision tree',
    );

    my $element_view = $dt->elements;
    my $attribute_view = $dt->attributes;
    push @$element_view, FSM::CoreAST::Action->new(type => 'output_mutation');
    $attribute_view->{source}{block} = 'mutated_again';

    is(
        scalar(@{$dt->elements}),
        1,
        'elements accessor returns a fresh element-list container',
    );
    is_deeply(
        $dt->attributes,
        {
            source => {
                block => 'main_dt',
            },
        },
        'attributes accessor returns fresh nested metadata',
    );

    $dt->add_element($second_action);
    is(
        scalar(@{$dt->elements}),
        2,
        'add_element remains the explicit mutation path',
    );
    is(
        $dt->elements->[1],
        $second_action,
        'add_element stores the supplied element object by identity',
    );
};

done_testing();
