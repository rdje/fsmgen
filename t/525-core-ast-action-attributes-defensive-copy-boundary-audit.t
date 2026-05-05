#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'Action attributes are stored and returned as metadata snapshots' => sub {
    my $attributes = {
        diagnostic => {
            code => 'FSM-ACTION',
        },
        tags => [qw(core audit)],
    };

    my $action = FSM::CoreAST::Action->new(
        type => 'custom_action',
        priority => 3,
        attributes => $attributes,
    );

    $attributes->{diagnostic}{code} = 'MUTATED';
    push @{$attributes->{tags}}, 'input_mutation';

    is_deeply(
        $action->attributes,
        {
            diagnostic => {
                code => 'FSM-ACTION',
            },
            tags => [qw(core audit)],
        },
        'constructor attribute mutation cannot contaminate the action node',
    );

    my $view = $action->attributes;
    $view->{diagnostic}{code} = 'MUTATED_AGAIN';
    $view->{tags}[0] = 'output_mutation';

    is_deeply(
        $action->attributes,
        {
            diagnostic => {
                code => 'FSM-ACTION',
            },
            tags => [qw(core audit)],
        },
        'attributes accessor returns a fresh nested metadata snapshot',
    );
    is($action->type, 'custom_action', 'scalar action type remains direct');
    is($action->priority, 3, 'scalar action priority remains direct');
};

done_testing();
