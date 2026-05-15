#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::SourceExpressionSpecSupport;

subtest 'top-expression inference spec collection owns returned leaf specs' => sub {
    my $source_spec = {
        raw => '{payload[3],literal_passthrough}',
        expr_kind => 'concat',
        operands => [
            {
                raw => 'payload[3]',
                port_name => 'payload',
                expr_kind => 'bit_select',
                index => 3,
                metadata => {
                    contexts => ['wiring'],
                },
            },
            {
                raw => 'literal_passthrough',
                expr_kind => 'literal',
                bits => '1',
                width => 1,
            },
        ],
    };

    my $requirements = FSM::Composition::SourceExpressionSpecSupport->collect_top_expression_inference_specs($source_spec);
    is(scalar(@$requirements), 1, 'collector returns the bounded top inference leaf');

    $requirements->[0]{metadata}{contexts}[0] = 'mutated_context';

    is_deeply(
        $source_spec->{operands}[0]{metadata},
        {
            contexts => ['wiring'],
        },
        'mutating returned top inference metadata cannot contaminate the source expression spec',
    );
};

subtest 'child-expression spec collection owns returned leaf specs through repeat wrappers' => sub {
    my $source_spec = {
        raw => '{2{producer.payload[7:4]}}',
        expr_kind => 'repeat',
        repeat_count => 2,
        operand => {
            raw => 'producer.payload[7:4]',
            instance_name => 'producer',
            port_name => 'payload',
            expr_kind => 'child_slice',
            msb => 7,
            lsb => 4,
            metadata => {
                contexts => ['child_source'],
            },
        },
    };

    my $child_specs = FSM::Composition::SourceExpressionSpecSupport->collect_top_expression_child_specs($source_spec);
    is(scalar(@$child_specs), 1, 'collector returns the bounded child expression leaf through repeat');

    push @{$child_specs->[0]{metadata}{contexts}}, 'mutated_context';

    is_deeply(
        $source_spec->{operand}{metadata},
        {
            contexts => ['child_source'],
        },
        'mutating returned child expression metadata cannot contaminate the source expression spec',
    );
};

done_testing();
