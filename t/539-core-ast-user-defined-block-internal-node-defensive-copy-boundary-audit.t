#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

sub child_node {
    my ($name) = @_;
    return FSM::CoreAST::PrimaryGate->new(
        name => $name,
        gate_type => 'and',
    );
}

subtest 'UserDefinedBlock internal-node lists are owned by the block' => sub {
    my $first_node = child_node('first_child');
    my $second_node = child_node('second_child');
    my $internal_nodes = [$first_node];
    my $block = FSM::CoreAST::UserDefinedBlock->new(
        name => 'child_block',
        internal_nodes => $internal_nodes,
    );

    push @$internal_nodes, child_node('mutated_input');

    is(scalar(@{$block->internal_nodes}), 1, 'constructor internal-node mutation cannot contaminate block');
    is($block->internal_nodes->[0], $first_node, 'internal node object identity is preserved in snapshots');

    my $internal_view = $block->internal_nodes;
    my $navigation_view = $block->get_internal_nodes;
    push @$internal_view, child_node('mutated_accessor');
    push @$navigation_view, child_node('mutated_navigation');

    is(scalar(@{$block->internal_nodes}), 1, 'internal_nodes accessor returns a fresh list container');
    is(scalar(@{$block->get_internal_nodes}), 1, 'get_internal_nodes returns a fresh list container');

    $block->add_internal_node($second_node);
    is(scalar(@{$block->internal_nodes}), 2, 'add_internal_node remains the explicit mutation path');
    is($block->internal_nodes->[1], $second_node, 'add_internal_node preserves supplied node identity');
    is($second_node->parent_hierarchy, $block, 'add_internal_node still records the live parent hierarchy');
};

subtest 'UserDefinedBlock rendering still reads the owned internal-node list' => sub {
    my $block = FSM::CoreAST::UserDefinedBlock->new(
        name => 'render_block',
        internal_nodes => [child_node('and_for_render')],
    );

    like(
        $block->to_systemverilog,
        qr/assign unknown_out = unknown_in & unknown_in;/,
        'rendering still sees owned internal nodes',
    );
};

done_testing();
