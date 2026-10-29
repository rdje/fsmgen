package FSM::SourceBitwiseTreeOriginSupport;

use v5.20;
use strict;
use warnings;
use Scalar::Util qw(blessed refaddr);
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport ();
use FSM::SourceBitwiseTreePolicySupport;

sub _walk {
    my ($node, $depth, $walk) = @_;
    return unless blessed($node)
        && $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS()
        && --$walk->{remaining} >= 0;
    my $identity = refaddr($node);
    return if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;
    if (UNIVERSAL::isa($node, 'FSM::CoreAST::SignalRef')) {
        return if defined($node->{slice});
    }
    my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($node);
    if (defined $name) {
        if (UNIVERSAL::isa($node, 'FSM::CoreAST::SignalRef')) {
            return if defined($node->signal->state_model);
        }
        push @{$walk->{names}}, $name;
        return ['signal', $name];
    }
    return unless $node->isa('FSM::CoreAST::BinaryOp') || $node->isa('FSM::AST::BinaryOp')
        || $node->isa('FSM::HDL::SubstitutedBinaryOp');
    if (UNIVERSAL::isa($node, 'FSM::CoreAST::BinaryOp')) {
        return unless ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} == 2;
    }
    my $operator = $node->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my $left = _walk($node->left, $depth + 1, $walk) or return;
    my $right = _walk($node->right, $depth + 1, $walk) or return;
    return [$operator, $left, $right];
}

sub from_ast {
    my ($class, $node) = @_;
    my $origin = eval {
        my $walk = {remaining => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES(), active => {}, names => []};
        my $tree = _walk($node, 0, $walk) or return;
        FSM::SourceBitwiseTreePolicySupport->copy_origin({kind => 'source_bitwise_tree',
            operator => $tree->[0], source_names => $walk->{names}, expression_tree => $tree});
    };
    return $@ ? undef : $origin;
}

1;

=head1 NAME

FSM::SourceBitwiseTreeOriginSupport - Bounded typed source bitwise tree shape

=head1 DESCRIPTION

Recognizes nested canonical binary AND/OR/XOR over whole typed Core/runtime/
compatible intermediate references. Preserve every original operator, tree
association and ordered leaf occurrence. Actual shared nodes retain repeated
slots; active cycles, malformed, over-bound, binary-only, sliced, literal,
arithmetic/logical and state-reference shapes withhold. Source widths are not
read, and other Signals' driving ASTs are not expanded.

The returned closed selected origin is detached data under the shared source-tree
schema and walk bounds. This syntactic recognizer establishes no module membership,
fresh source allocation, unsigned/type equivalence or symbolic range eligibility.
Actual cached-tree agreement, fresh selected rendering and completed policy joins
belong to the publisher.

=head1 METHODS

=head2 from_ast

Return a detached C<source_bitwise_tree> origin from the actual typed held tree,
or undef for unknown/ineligible/malformed shapes. No printed-text parsing or
helper-name inference supplies a tree. No AST or Signal owner is retained.

=cut
