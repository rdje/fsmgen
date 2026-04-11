#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::SourceExpressionSpecSupport;
use FSM::Composition::TopSymbols;

subtest 'source expression support parses top and child endpoint forms' => sub {
    is_deeply(
        FSM::Composition::SourceExpressionSpecSupport->top_expression_spec('payload[3]'),
        {
            raw => 'payload[3]',
            port_name => 'payload',
            expr_kind => 'bit_select',
            index => 3,
        },
        'top bit-select specs stay available through the support owner',
    );

    is_deeply(
        FSM::Composition::SourceExpressionSpecSupport->child_expression_spec('producer.frame.tag[1:0]'),
        {
            raw => 'producer.frame.tag[1:0]',
            instance_name => 'producer',
            port_name => 'frame',
            expr_kind => 'aggregate_ref',
            path_text => '.tag[1:0]',
        },
        'child aggregate paths parse as child-expression specs',
    );

    is(
        FSM::Composition::SourceExpressionSpecSupport->child_expression_base_endpoint('producer.frame.tag[1:0]'),
        'producer.frame',
        'child expression base endpoint keeps the producer port root',
    );
};

subtest 'source expression support parses concat, repeat, child sources, and literal operands' => sub {
    my $symbols = FSM::Composition::TopSymbols->new(
        constants => {
            MAGIC => "4'hA",
            FRAME => {
                kind => 'list',
                items => [
                    { kind => 'scalar', payload => "1'b1" },
                    { kind => 'scalar', payload => "3'b010" },
                ],
            },
        },
        enums => {
            mode => {
                BUSY => '1',
            },
        },
    );

    is_deeply(
        FSM::Composition::SourceExpressionSpecSupport->parse_top_expression_spec(
            'header,{status[0],=0b1_0},{producer.serial[3:2],producer.frame.payload[1]},=MAGIC,=mode.BUSY,=FRAME,{3{footer[0]}}',
            allow_plain_top_ref => 1,
            allow_child_ref => 1,
            allow_literal_actual => 1,
            top_symbols => $symbols,
        ),
        {
            raw => 'header,{status[0],=0b1_0},{producer.serial[3:2],producer.frame.payload[1]},=MAGIC,=mode.BUSY,=FRAME,{3{footer[0]}}',
            expr_kind => 'concat',
            operands => [
                {
                    raw => 'header',
                    port_name => 'header',
                    expr_kind => 'signal_ref',
                },
                {
                    raw => '{status[0],=0b1_0}',
                    expr_kind => 'concat',
                    operands => [
                        {
                            raw => 'status[0]',
                            port_name => 'status',
                            expr_kind => 'bit_select',
                            index => 0,
                        },
                        {
                            raw => '=0b1_0',
                            expr_kind => 'literal',
                            bits => '10',
                            width => 2,
                        },
                    ],
                },
                {
                    raw => '{producer.serial[3:2],producer.frame.payload[1]}',
                    expr_kind => 'concat',
                    operands => [
                        {
                            raw => 'producer.serial[3:2]',
                            instance_name => 'producer',
                            port_name => 'serial',
                            expr_kind => 'child_slice',
                            msb => 3,
                            lsb => 2,
                        },
                        {
                            raw => 'producer.frame.payload[1]',
                            instance_name => 'producer',
                            port_name => 'frame',
                            expr_kind => 'child_aggregate_ref',
                            path_text => '.payload[1]',
                        },
                    ],
                },
                {
                    raw => '=MAGIC',
                    expr_kind => 'literal',
                    bits => '1010',
                    width => 4,
                },
                {
                    raw => '=mode.BUSY',
                    expr_kind => 'literal',
                    bits => '1',
                    width => 1,
                },
                {
                    raw => '=FRAME',
                    expr_kind => 'literal',
                    bits => '1010',
                    width => 4,
                },
                {
                    raw => '{3{footer[0]}}',
                    expr_kind => 'repeat',
                    repeat_count => 3,
                    operand => {
                        raw => 'footer[0]',
                        port_name => 'footer',
                        expr_kind => 'bit_select',
                        index => 0,
                    },
                },
            ],
        },
        'support owns nested concat, repeat, top-symbol, child, and aggregate operand parsing',
    );
};

subtest 'source expression support collects inference and child source contracts' => sub {
    is_deeply(
        FSM::Composition::SourceExpressionSpecSupport->top_expression_inference_specs(
            'header,{status[0],producer.serial[3:2]},{payload[7:4],producer.serial[1:0]}',
        ),
        [
            {
                raw => 'status[0]',
                port_name => 'status',
                expr_kind => 'bit_select',
                index => 0,
            },
            {
                raw => 'payload[7:4]',
                port_name => 'payload',
                expr_kind => 'slice',
                msb => 7,
                lsb => 4,
            },
        ],
        'top-expression inference collection still reports only top bit/slice requirements',
    );

    is_deeply(
        FSM::Composition::SourceExpressionSpecSupport->top_expression_child_base_endpoints(
            'header,{producer.serial[3:2],producer.serial[1:0]},{producer.frame.tag,producer.frame.payload[0]}',
        ),
        [
            'producer.serial',
            'producer.frame',
        ],
        'child base endpoint collection deduplicates child source roots in expression order',
    );
};

subtest 'linked plan builder wrappers preserve the historic parser API' => sub {
    require FSM::Composition::LinkedPlanBuilder;

    is_deeply(
        FSM::Composition::LinkedPlanBuilder->top_expression_spec('payload[3:1]'),
        FSM::Composition::SourceExpressionSpecSupport->top_expression_spec('payload[3:1]'),
        'builder top-expression wrapper delegates to the support parser',
    );

    is(
        FSM::Composition::LinkedPlanBuilder->child_expression_base_endpoint('producer.frame.tag'),
        'producer.frame',
        'builder child-expression wrapper keeps the old call surface intact',
    );
};

done_testing();
