#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;
use FSM::IR::IntentHIRBuilder;

subtest 'Intent HIR signal analysis skips parser-created intermediate helpers from interface-facing inputs/outputs' => sub {
    my $input = FSM::CoreAST::Signal->new(
        name => 'A',
        width => 8,
        attributes => {
            signal_role => 'INPUT',
        },
    );
    my $output = FSM::CoreAST::Signal->new(
        name => 'Z',
        width => 1,
        attributes => {
            signal_role => 'OUTPUT',
            is_output => 1,
        },
    );
    my $intermediate = FSM::CoreAST::Signal->new(
        name => 'intermediate_and_A_B_1',
        width => 1,
        attributes => {
            signal_role => 'INTERNAL_INTERMEDIATE',
            is_intermediate => 1,
        },
    );

    my %analysis = FSM::IR::IntentHIRBuilder->analyze_signals({
        A => $input,
        Z => $output,
        intermediate_and_A_B_1 => $intermediate,
    });

    is_deeply(
        [map { $_->{name} } @{$analysis{inputs} || []}],
        ['A'],
        'only real input signals appear in Intent HIR input analysis',
    );
    is_deeply(
        [map { $_->{name} } @{$analysis{outputs} || []}],
        ['Z'],
        'only real output signals appear in Intent HIR output analysis',
    );
    ok(
        !grep({ $_->{name} eq 'intermediate_and_A_B_1' } @{$analysis{single_bit} || []}),
        'intermediate helpers are omitted entirely from interface-facing signal analysis buckets',
    );
};

done_testing();
