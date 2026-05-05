#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'SideEffect parameters are owned by the node' => sub {
    my $parameters = {
        message => 'trace point',
        tags => [qw(debug audit)],
        metadata => {
            severity => 'info',
        },
    };

    my $side_effect = FSM::CoreAST::SideEffect->new(
        effect_type => 'debug_trace',
        parameters => $parameters,
    );

    push @{$parameters->{tags}}, 'mutated_input';
    $parameters->{metadata}{severity} = 'error';

    is_deeply(
        $side_effect->parameters,
        {
            message => 'trace point',
            tags => [qw(debug audit)],
            metadata => {
                severity => 'info',
            },
        },
        'constructor parameter mutation cannot contaminate the side-effect node',
    );

    my $view = $side_effect->parameters;
    push @{$view->{tags}}, 'mutated_output';
    $view->{metadata}{severity} = 'warning';

    is_deeply(
        $side_effect->parameters,
        {
            message => 'trace point',
            tags => [qw(debug audit)],
            metadata => {
                severity => 'info',
            },
        },
        'parameters accessor returns a fresh nested snapshot',
    );
    is(
        $side_effect->effect_type,
        'debug_trace',
        'scalar side-effect identity remains directly readable',
    );
};

done_testing();
