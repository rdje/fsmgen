#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::ActualLiteralSupport;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    bit_vector_literal_expr
    open_expr
    signal_ref_expr
);

subtest 'non-actual source connection expressions are cloned on return' => sub {
    my $source = {
        kind => 'top_port',
        connection_expr => bit_select_expr(signal_ref_expr('status'), 0),
    };

    my $expr = FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
        $source,
        8,
    );
    $expr->{source_expr}{signal_name} = 'mutated_status';

    is_deeply(
        $source->{connection_expr},
        bit_select_expr(signal_ref_expr('status'), 0),
        'returned non-actual connection expression cannot contaminate source payload',
    );
};

subtest 'width-independent actual source connection expressions are cloned on return' => sub {
    my $source = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        'open',
        raw => '=open',
    );

    my $expr = FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
        $source,
        8,
    );
    $expr->{kind} = 'mutated_open';

    is_deeply(
        $source->{connection_expr},
        open_expr(),
        'returned open actual expression cannot contaminate source payload',
    );
};

subtest 'target-width-bound actuals still return fresh lowered expressions' => sub {
    my $source = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        '1',
        raw => '=1',
    );

    my $expr = FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
        $source,
        4,
    );
    is_deeply($expr, bit_vector_literal_expr('0001'), 'scalar actual lowers to target-width bit vector');

    $expr->{bits} = '1111';
    is_deeply(
        $source->{connection_expr},
        bit_vector_literal_expr('1'),
        'mutating lowered scalar expression cannot contaminate source one-bit payload',
    );
};

done_testing();
