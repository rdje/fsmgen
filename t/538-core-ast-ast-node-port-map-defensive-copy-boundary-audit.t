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
    return FSM::CoreAST::ASTNode->new(
        node_type => 'test_node',
        name => $name,
    );
}

subtest 'ASTNode port maps and attributes are owned by the node' => sub {
    my $driver = node('driver');
    my $input_port = FSM::CoreAST::Port->new(
        name => 'in',
        direction => 'input',
        driving_node => $driver,
    );
    my $output_port = FSM::CoreAST::Port->new(
        name => 'out',
        direction => 'output',
    );
    my $input_ports = {
        in => $input_port,
    };
    my $output_ports = {
        out => $output_port,
    };
    my $attributes = {
        source => {
            role => 'combinational',
        },
    };

    my $ast_node = FSM::CoreAST::ASTNode->new(
        node_type => 'logic_node',
        input_ports => $input_ports,
        output_ports => $output_ports,
        attributes => $attributes,
    );

    $input_ports->{extra} = FSM::CoreAST::Port->new(name => 'extra', direction => 'input');
    delete $output_ports->{out};
    $attributes->{source}{role} = 'mutated_input';

    is_deeply([sort keys %{$ast_node->input_ports}], ['in'], 'constructor input-port map mutation cannot contaminate node');
    is_deeply([sort keys %{$ast_node->output_ports}], ['out'], 'constructor output-port map mutation cannot contaminate node');
    is($ast_node->input_ports->{in}, $input_port, 'input Port object identity is preserved in snapshots');
    is_deeply(
        $ast_node->attributes,
        {
            source => {
                role => 'combinational',
            },
        },
        'constructor attribute mutation cannot contaminate node',
    );

    my $input_view = $ast_node->input_ports;
    my $output_view = $ast_node->output_ports;
    my $attribute_view = $ast_node->attributes;
    delete $input_view->{in};
    $output_view->{extra} = FSM::CoreAST::Port->new(name => 'extra', direction => 'output');
    $attribute_view->{source}{role} = 'mutated_output';

    is_deeply([sort keys %{$ast_node->input_ports}], ['in'], 'input_ports accessor returns a fresh map');
    is_deeply([sort keys %{$ast_node->output_ports}], ['out'], 'output_ports accessor returns a fresh map');
    is_deeply(
        $ast_node->attributes,
        {
            source => {
                role => 'combinational',
            },
        },
        'attributes accessor returns fresh nested metadata',
    );

    is($ast_node->get_fanin_nodes->[0], $driver, 'fanin traversal still reads the owned input port map');
};

subtest 'parent hierarchy remains a live graph link' => sub {
    my $parent = node('parent');
    my $child = FSM::CoreAST::ASTNode->new(
        node_type => 'child_node',
        parent_hierarchy => $parent,
    );

    is($child->parent_hierarchy, $parent, 'parent_hierarchy remains a live graph link');
};

done_testing();
