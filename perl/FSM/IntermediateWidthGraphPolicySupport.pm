package FSM::IntermediateWidthGraphPolicySupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;
use constant MAX_BINARY_LEVELS => 64;
use constant MAX_TREE_NODES => 4096;

=head1 NAME

FSM::IntermediateWidthGraphPolicySupport - Validate closed arithmetic graph max records

=head1 DESCRIPTION

Pure JSON schema and exact positive-decimal consistency for
C<arithmetic_graph_operand_max> records. The closed fields are C<kind>,
C<operator>, ordered current C<source_names>, original C<expression_tree> and
C<selected_width>. The edge pair preserves duplicates and source names use
simple HDL identifiers. The original tree contains canonical arithmetic binary
operators and C<[signal, name]> leaves, with a computed arithmetic subtree.
Its root operator must match the current record. Fresh graph birth and this
schema share the same compile-time walk bounds.

This validates data and numeric consistency, not actual allocator intent,
source-object association, current completion or symbolic target eligibility.
The actual producer/publisher must supply and recheck those contracts.

=cut

sub _json { return JSON::PP->new->canonical }
sub _operator {
    return defined($_[0]) && !ref($_[0]) && $_[0] =~ m{\A[+*/%\-]\z};
}
sub _tree {
    my ($tree, $depth, $budget, $leaves) = @_;
    return undef unless ref($tree) eq 'ARRAY' && $depth <= MAX_BINARY_LEVELS && --$$budget >= 0;
    if (@$tree == 2 && defined($tree->[0]) && !ref($tree->[0]) && $tree->[0] eq 'signal') {
        return undef unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($tree->[1]);
        push @$leaves, $tree->[1];
        return 0;
    }
    return undef unless @$tree == 3 && _operator($tree->[0]);
    my $left = _tree($tree->[1], $depth + 1, $budget, $leaves);
    return undef unless defined($left);
    my $right = _tree($tree->[2], $depth + 1, $budget, $leaves);
    return undef unless defined($right);
    return 1 + $left + $right;
}
sub _checked_shape {
    my ($copy) = @_;
    confess "Graph width allocation requires a closed JSON arithmetic graph max record\n"
        if ref($copy) ne 'HASH'
            || join(',', sort keys %$copy) ne 'expression_tree,kind,operator,selected_width,source_names'
            || !defined($copy->{kind}) || ref($copy->{kind}) || $copy->{kind} ne 'arithmetic_graph_operand_max'
            || !_operator($copy->{operator}) || ref($copy->{source_names}) ne 'ARRAY' || @{$copy->{source_names}} != 2
            || grep {!FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_)} @{$copy->{source_names}};
    confess "Graph width allocation requires a positive decimal selected width\n"
        unless defined(FSM::IntermediateWidthAllocationSupport::_width($copy->{selected_width}));
    my $budget = MAX_TREE_NODES;
    my @leaves;
    my $operators = _tree($copy->{expression_tree}, 0, \$budget, \@leaves);
    confess "Graph width allocation requires its bounded original arithmetic tree\n"
        unless defined($operators) && $operators > 1 && $copy->{expression_tree}[0] eq $copy->{operator};
    return \@leaves;
}
sub _validated {
    my ($record) = @_;
    _checked_shape($record); # Bound traversal before encoding caller data.
    my $copy = eval {_json()->decode(_json()->encode($record))};
    confess "Graph width allocation requires JSON-safe record data\n" if $@;
    my $leaves = _checked_shape($copy);
    return {record => $copy, leaves => $leaves};
}

=head1 METHODS

=head2 copy_record

Validate and detach the closed graph record. Original tree order, duplicate
leaves/edge slots and supplied scalar JSON kinds preserve. Malformed, cyclic,
unsupported and over-bound records throw. A whole binary record remains a
separate schema and does not become a graph record by matching widths.

=cut

sub copy_record {
    my ($class, $record) = @_;
    return _validated($record)->{record};
}

=head2 leaf_names

Return detached original leaf names in tree order, including duplicates, after
full schema validation. These names alone attest no source/target membership.

=cut

sub leaf_names {
    my ($class, $record) = @_;
    return _validated($record)->{leaves};
}

sub _matches {
    my ($record, $result_width, @widths) = @_;
    my $result = FSM::IntermediateWidthAllocationSupport::_width($result_width);
    my @normalized = map {scalar(FSM::IntermediateWidthAllocationSupport::_width($_))} @widths;
    return undef unless defined($result) && @normalized && !grep {!defined($_)} @normalized;
    my $maximum = shift @normalized;
    $maximum = FSM::IntermediateWidthAllocationSupport::_maximum($maximum, $_) for @normalized;
    return FSM::IntermediateWidthAllocationSupport::_width($record->{selected_width}) eq $result
        && $result eq $maximum;
}

=head2 matches_selected_widths

Check selected/result width against the exact decimal maximum of the current
edge pair. Invalid numeric widths withhold; malformed records throw. No native
integer or floating-point conversion selects the maximum.

=cut

sub matches_selected_widths {
    my ($class, $record, $result_width, @widths) = @_;
    my $validated = _validated($record);
    return undef unless @widths == 2;
    return _matches($validated->{record}, $result_width, @widths);
}

=head2 matches_leaf_widths

Check selected/result width against the exact maximum of a complete supplied
original-leaf width vector. Its count must match C<leaf_names>. The caller must
bind the actual ordered leaf objects; this checks only schema and numeric data.

=cut

sub matches_leaf_widths {
    my ($class, $record, $result_width, @widths) = @_;
    my $validated = _validated($record);
    return undef unless @widths == @{$validated->{leaves}};
    return _matches($validated->{record}, $result_width, @widths);
}

1;
