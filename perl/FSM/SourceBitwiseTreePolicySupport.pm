package FSM::SourceBitwiseTreePolicySupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport ();
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { return JSON::PP->new->canonical }

sub _operator {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[&|^]\z/;
}

sub _tree {
    my ($tree, $depth, $budget, $leaves) = @_;
    return undef unless ref($tree) eq 'ARRAY'
        && $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS()
        && --$$budget >= 0;
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
    my ($record) = @_;
    confess "Source bitwise tree allocation requires a closed tree max record\n"
        unless ref($record) eq 'HASH'
            && join(',', sort keys %$record) eq 'expression_tree,kind,operator,selected_width,source_names'
            && defined($record->{kind}) && !ref($record->{kind})
            && $record->{kind} eq 'source_bitwise_tree_operand_max'
            && _operator($record->{operator});
    my $names = $record->{source_names};
    confess "Source bitwise tree allocation requires its complete ordered whole-name slots\n"
        unless ref($names) eq 'ARRAY' && @$names >= 3
            && @$names <= FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES();
    for my $name (@$names) {
        confess "Source bitwise tree allocation requires simple whole-signal names\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    }
    confess "Source bitwise tree allocation requires a positive decimal selected width\n"
        unless defined(FSM::IntermediateWidthAllocationSupport::_width($record->{selected_width}));
    my $budget = FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES();
    my @leaves;
    my $operators = _tree($record->{expression_tree}, 0, \$budget, \@leaves);
    confess "Source bitwise tree allocation requires its bounded nested bitwise tree\n"
        unless defined($operators) && $operators > 1
            && $record->{expression_tree}[0] eq $record->{operator};
    confess "Source bitwise tree allocation requires identical ordered tree and source slots\n"
        unless _json()->encode(\@leaves) eq _json()->encode($names);
    return;
}

sub _validated {
    my ($record) = @_;
    _checked_shape($record); # Bound caller traversal before JSON encoding.
    my $copy = eval {_json()->decode(_json()->encode($record))};
    confess "Source bitwise tree allocation requires JSON-safe record data\n" if $@;
    _checked_shape($copy);
    return $copy;
}

sub copy_record {
    my ($class, $record) = @_;
    return _validated($record);
}

sub leaf_names {
    my ($class, $record) = @_;
    return [@{_validated($record)->{source_names}}];
}

sub matches_selected_widths {
    my ($class, $record, $result_width, @widths) = @_;
    my $copy = _validated($record);
    return undef unless @widths == @{$copy->{source_names}};
    my $result = FSM::IntermediateWidthAllocationSupport::_width($result_width);
    my @normalized = map {scalar(FSM::IntermediateWidthAllocationSupport::_width($_))} @widths;
    return undef unless defined($result) && !grep {!defined($_)} @normalized;
    my $maximum = shift @normalized;
    $maximum = FSM::IntermediateWidthAllocationSupport::_maximum($maximum, $_) for @normalized;
    return FSM::IntermediateWidthAllocationSupport::_width($copy->{selected_width}) eq $result
        && $result eq $maximum;
}

1;

=head1 NAME

FSM::SourceBitwiseTreePolicySupport - Closed source bitwise tree max data

=head1 DESCRIPTION

Validates the separate C<source_bitwise_tree_operand_max> data family. Closed
fields are C<kind>, C<operator>, C<source_names>, C<expression_tree> and
C<selected_width>. A tree contains more than one canonical binary C<&>, C<|>
or C<^> node and C<[signal, name]> leaves. Its root operator must match the
record. C<source_names> is the complete ordered leaf-slot vector, including
duplicates; it is not a current edge pair or a deduplicated dependency set.
Selected width is a positive decimal, with the caller's scalar JSON kind kept.

Traversal uses the existing compile-time depth and visited-node limits from
L<FSM::IntermediateWidthGraphPolicySupport>. Shared subtree slots count each
time they occur. Cyclic and over-bound trees refuse before JSON encoding.
Binary two-slot and computed arithmetic graph schemas remain separate.

This pure data contract proves no actual Core allocation, source object,
current epoch, frozen width relationship or selected target provenance. It
installs no Core policy, publishes no target event and changes no HDL profile.
Source-holder, parser, backend and range consumers retain those obligations.

=head1 METHODS

=head2 copy_record

Validate and detach one closed record. Original operators, topology, ordered
leaf slots, duplicate occurrences and scalar JSON kinds preserve. Malformed,
unsupported, inconsistent, cyclic or over-bound data throws. Caller data is
read-only and the returned record retains no caller graph.

=head2 leaf_names

Return a detached complete ordered leaf vector after validating its exact
agreement with the tree. Names alone prove no actual membership or ownership.

=head2 matches_selected_widths

Check selected and result widths against the exact decimal maximum of the
complete supplied leaf-width vector. Independent fixed widths may differ;
the caller must bind each width to its actual ordered leaf object. Wrong
counts or invalid numeric widths withhold, while malformed records throw.
No native integer or floating-point conversion selects the maximum. Numeric
agreement alone does not establish a mutable symbolic relationship.

=cut
