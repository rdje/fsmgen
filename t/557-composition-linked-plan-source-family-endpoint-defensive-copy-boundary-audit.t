#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::Port;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    signal_ref_expr
);

sub source_descriptor {
    return {
        raw => 'producer.status[0]',
        key => 'child:producer.status[0]',
        kind => 'child_port',
        instance_name => 'producer',
        port_name => 'status',
        port => FSM::Composition::Port->new(
            name => 'status',
            direction => 'output',
            width => 8,
        ),
        connection_expr => bit_select_expr(signal_ref_expr('producer_status'), 0),
        metadata => {
            contexts => ['toplink'],
        },
    };
}

subtest 'source_family_endpoint returns caller-owned non-expression source descriptors' => sub {
    my $source = source_descriptor();
    my $endpoint = FSM::Composition::LinkedPlanBuilder->source_family_endpoint($source);

    is($endpoint->{port}, $source->{port}, 'source descriptor clone preserves live port object identity');

    $endpoint->{raw} = 'mutated.raw';
    $endpoint->{connection_expr}{source_expr}{signal_name} = 'mutated_signal';
    push @{$endpoint->{metadata}{contexts}}, 'mutated_context';

    is_deeply(
        {
            raw => $source->{raw},
            connection_expr => $source->{connection_expr},
            metadata => $source->{metadata},
        },
        {
            raw => 'producer.status[0]',
            connection_expr => bit_select_expr(signal_ref_expr('producer_status'), 0),
            metadata => {
                contexts => ['toplink'],
            },
        },
        'returned source-family endpoint mutation cannot contaminate original source descriptor containers',
    );
};

subtest 'child expression projection still returns the base child endpoint descriptor' => sub {
    my $port = FSM::Composition::Port->new(
        name => 'payload',
        direction => 'output',
        width => 8,
    );
    my $source = {
        raw => 'producer.payload[3]',
        base_raw => 'producer.payload',
        base_key => 'child:producer.payload',
        kind => 'child_expr',
        instance_name => 'producer',
        port_name => 'payload',
        port => $port,
    };

    my $endpoint = FSM::Composition::LinkedPlanBuilder->source_family_endpoint($source);
    is_deeply(
        {
            raw => $endpoint->{raw},
            key => $endpoint->{key},
            kind => $endpoint->{kind},
            instance_name => $endpoint->{instance_name},
            port_name => $endpoint->{port_name},
        },
        {
            raw => 'producer.payload',
            key => 'child:producer.payload',
            kind => 'child_port',
            instance_name => 'producer',
            port_name => 'payload',
        },
        'child expression projects to its base child endpoint descriptor',
    );
    is($endpoint->{port}, $port, 'base child endpoint keeps live port object identity');
};

done_testing();
