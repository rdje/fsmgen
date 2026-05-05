#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

sub node {
    my ($name) = @_;
    return FSM::CoreAST::PrimaryGate->new(
        name => $name,
        gate_type => 'and',
    );
}

subtest 'Port driven-node list containers are owned by the port' => sub {
    my $first_node = node('first_gate');
    my $second_node = node('second_gate');
    my $driven_nodes = [$first_node];
    my $port = FSM::CoreAST::Port->new(
        name => 'out',
        direction => 'output',
        driven_nodes => $driven_nodes,
    );

    push @$driven_nodes, node('mutated_input');

    is(scalar(@{$port->get_driven_nodes}), 1, 'constructor driven-node mutation cannot contaminate port');
    is($port->get_driven_nodes->[0], $first_node, 'driven-node object identity is preserved in snapshots');

    my $driven_view = $port->get_driven_nodes;
    push @$driven_view, node('mutated_output');

    is(scalar(@{$port->get_driven_nodes}), 1, 'get_driven_nodes returns a fresh list container');

    $port->add_driven_node($second_node);
    is(scalar(@{$port->get_driven_nodes}), 2, 'add_driven_node remains the explicit mutation path');
    is($port->get_driven_nodes->[1], $second_node, 'add_driven_node preserves supplied node identity');
};

subtest 'ASTNode fanout traversal still reads port-owned driven nodes' => sub {
    my $driven = node('driven_gate');
    my $source = FSM::CoreAST::ASTNode->new(
        node_type => 'source_node',
        output_ports => {
            out => FSM::CoreAST::Port->new(
                name => 'out',
                direction => 'output',
                driven_nodes => [$driven],
            ),
        },
    );

    my $fanout_nodes = $source->get_fanout_nodes;
    is(scalar(@$fanout_nodes), 1, 'fanout traversal still reports one driven node');
    is($fanout_nodes->[0], $driven, 'fanout traversal preserves driven node identity');

    push @$fanout_nodes, node('mutated_traversal');
    is(scalar(@{$source->get_fanout_nodes}), 1, 'mutating traversal result cannot contaminate port state');
};

done_testing();
