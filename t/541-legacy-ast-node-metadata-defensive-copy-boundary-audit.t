#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;

sub expected_metadata {
    return {
        origin => {
            pass => 'capture',
            tags => ['legacy', 'runtime'],
        },
    };
}

subtest 'legacy AST node constructors snapshot generic metadata containers' => sub {
    my $metadata = expected_metadata();
    my $node = FSM::AST::SignalRef->new('REQ', metadata => $metadata);

    push @{$metadata->{origin}{tags}}, 'mutated-input';
    $metadata->{origin}{pass} = 'mutated';

    is_deeply(
        $node->{metadata},
        expected_metadata(),
        'SignalRef metadata is isolated from constructor input mutation',
    );
};

subtest 'legacy AST node clones preserve and isolate generic metadata' => sub {
    my $node = FSM::AST::Literal->new('8', metadata => expected_metadata());
    my $clone = $node->clone;

    is_deeply($clone->{metadata}, expected_metadata(), 'Literal clone keeps generic metadata');
    isnt($clone->{metadata}, $node->{metadata}, 'Literal clone has its own metadata hash');
    isnt($clone->{metadata}{origin}{tags}, $node->{metadata}{origin}{tags}, 'Literal clone has its own nested metadata list');

    push @{$clone->{metadata}{origin}{tags}}, 'mutated-clone';
    $node->{metadata}{origin}{pass} = 'mutated-original';

    is_deeply(
        $clone->{metadata},
        {
            origin => {
                pass => 'capture',
                tags => ['legacy', 'runtime', 'mutated-clone'],
            },
        },
        'clone-side metadata mutation stays on the clone',
    );
    is_deeply(
        $node->{metadata},
        {
            origin => {
                pass => 'mutated-original',
                tags => ['legacy', 'runtime'],
            },
        },
        'original-side metadata mutation stays on the original',
    );
};

subtest 'operation clones preserve metadata while cloning structural children' => sub {
    my $left = FSM::AST::SignalRef->new('A');
    my $right = FSM::AST::SignalRef->new('B');
    my $metadata_refs = [$left];
    my $node = FSM::AST::BinaryOp->new(
        '&&',
        $left,
        $right,
        metadata => {
            referenced_nodes => $metadata_refs,
            labels => ['gate'],
        },
    );

    push @{$metadata_refs}, $right;

    is_deeply(
        [map { $_->signal_name } @{$node->{metadata}{referenced_nodes}}],
        ['A'],
        'BinaryOp constructor clones metadata list containers',
    );
    is($node->{metadata}{referenced_nodes}[0], $left, 'metadata keeps AST object identity for referenced nodes');

    my $clone = $node->clone;

    isnt($clone->left, $node->left, 'BinaryOp clone still clones left structural child');
    isnt($clone->right, $node->right, 'BinaryOp clone still clones right structural child');
    ok($clone->left->equals($node->left), 'cloned left child remains equivalent');
    ok($clone->right->equals($node->right), 'cloned right child remains equivalent');
    is_deeply($clone->{metadata}{labels}, ['gate'], 'BinaryOp clone keeps generic metadata lists');
    isnt($clone->{metadata}{labels}, $node->{metadata}{labels}, 'BinaryOp clone metadata list is caller-owned');
};

subtest 'LogicalConstant and UnaryOp clones keep generic metadata' => sub {
    my $logical = FSM::AST::LogicalConstant->new(1, metadata => expected_metadata());
    my $logical_clone = $logical->clone;
    is_deeply($logical_clone->{metadata}, expected_metadata(), 'LogicalConstant clone keeps metadata');

    my $unary = FSM::AST::UnaryOp->new('!', FSM::AST::SignalRef->new('rst_n'), metadata => expected_metadata());
    my $unary_clone = $unary->clone;
    is_deeply($unary_clone->{metadata}, expected_metadata(), 'UnaryOp clone keeps metadata');
    isnt($unary_clone->operand, $unary->operand, 'UnaryOp clone still clones structural operand');
};

done_testing();
