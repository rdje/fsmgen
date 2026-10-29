package FSM::SourceLiteralWidthAllocationSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::CoreExpressionWidthSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::SourceBitwiseTreeWidthSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { return JSON::PP->new->canonical }
sub _identity { return FSM::SourceBitwiseTreeWidthSupport::_identity($_[0]) }
sub _positive { return defined FSM::IntermediateWidthAllocationSupport::_width($_[0]) }

sub _literal_record {
    my ($record) = @_;
    return unless ref($record) eq 'HASH' && join(',', sort keys %$record) eq 'radix,value,width';
    return if !defined($record->{value}) || ref($record->{value})
        || !defined($record->{radix}) || ref($record->{radix});
    return if defined($record->{width}) && !_positive($record->{width});
    return $record;
}

sub _validate_tree {
    my ($tree, $walk, $depth) = @_;
    return unless ref($tree) eq 'ARRAY' && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        && --$walk->{remaining} >= 0;
    my $identity = refaddr($tree);
    return if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;
    my $kind = $tree->[0];
    return unless defined($kind) && !ref($kind);
    if ($kind eq 'signal') {
        return @$tree == 2 && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($tree->[1]);
    }
    if ($kind eq 'literal') {
        return @$tree == 2 && _literal_record($tree->[1]);
    }
    return unless @$tree == 3 && $kind =~ /\A[&|^]\z/;
    return _validate_tree($tree->[1], $walk, $depth + 1)
        && _validate_tree($tree->[2], $walk, $depth + 1);
}

sub copy_record {
    my ($class, $record) = @_;
    confess "Source literal allocation requires a closed raw source record\n"
        unless ref($record) eq 'HASH' && join(',', sort keys %$record) eq 'expression_tree,kind,selected_width'
            && defined($record->{kind}) && !ref($record->{kind}) && $record->{kind} eq 'source_literal_operand_max'
            && (!defined($record->{selected_width}) || _positive($record->{selected_width}))
            && _validate_tree($record->{expression_tree}, {
                remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}}, 0);
    return _json()->decode(_json()->encode($record));
}

# Raw stamps are read without invoking source getters. A getter used later in a
# walk may write an earlier object; the final barrier must observe that write.
sub _raw_signal {
    my ($signal) = @_;
    my @keys = qw(name _width type signed state_model declared_type_name declared_type_spec constraints
        _declared_width_source _declared_width_binding _declared_width_requirements _declared_width_requirements_state);
    return _json()->encode({fields => {map {exists($signal->{$_}) ? ($_ => $signal->{$_}) : ()} @keys},
        revision => $signal->{_intermediate_width_allocation_revision} // 0,
        ast_identity => blessed($signal->{driving_ast}) ? _identity($signal->{driving_ast}) : undef,
        roles => {map {exists($signal->{attributes}{$_}) ? ($_ => $signal->{attributes}{$_}) : ()}
            qw(is_intermediate is_output is_aux_output width_declared signal_role)}});
}

sub _raw_node {
    my ($node) = @_;
    return _json()->encode({value => $node->{value}, width => $node->{width}, radix => $node->{radix}})
        if $node->isa('FSM::CoreAST::Literal');
    return _json()->encode({signal => blessed($node->{signal}) ? _identity($node->{signal}) : undef,
        slice => $node->{slice}}) if $node->isa('FSM::CoreAST::SignalRef');
    return _json()->encode({operator => $node->{operator},
        operands => [map {blessed($_) ? _identity($_) : undef} @{$node->{operands}}]});
}

sub _observe_signal {
    my ($signal, $walk) = @_;
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
        && ref($signal->{attributes}) eq 'HASH';
    my $raw = _raw_signal($signal);
    my $descriptor = FSM::SourceBitwiseTreeWidthSupport::_plain($signal) or return;
    return unless _raw_signal($signal) eq $raw;
    push @{$walk->{signals}}, $signal;
    push @{$walk->{stamps}}, [$signal, $raw, 'signal'];
    return {%$descriptor, raw_state => $raw};
}

sub _core_tree {
    my ($node, $root, $walk, $depth) = @_;
    return unless blessed($node) && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        && --$walk->{remaining} >= 0;
    my $address = refaddr($node);
    return if $walk->{active}{$address};
    local $walk->{active}{$address} = 1;
    return unless $node->isa('FSM::CoreAST::Literal') || $node->isa('FSM::CoreAST::SignalRef')
        || ($node->isa('FSM::CoreAST::BinaryOp') && ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} == 2);
    push @{$walk->{stamps}}, [$node, _raw_node($node), 'node'];
    push @{$walk->{nodes}}, _identity($node);
    if ($node->isa('FSM::CoreAST::Literal')) {
        my $record = _literal_record({value => $node->value, width => $node->width, radix => $node->radix}) or return;
        ++$walk->{literals};
        return ['literal', $record];
    }
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        return if defined $node->slice;
        my $source = $node->signal;
        my $descriptor = _observe_signal($source, $walk) or return;
        return if refaddr($source) == refaddr($root) || $source->name eq $root->name;
        # A generated child's nominal width is not an exact width contract.
        # Actual nested birth/completion joins belong to the source successor.
        return if $descriptor->{roles}{is_intermediate};
        my $name = $descriptor->{name};
        return if exists($walk->{names}{$name}) && $walk->{names}{$name} ne $descriptor->{identity_token};
        $walk->{names}{$name} = $descriptor->{identity_token};
        push @{$walk->{operands}}, $descriptor;
        return ['signal', $name];
    }
    my $operator = $node->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my $left = _core_tree($node->left, $root, $walk, $depth + 1) or return;
    my $right = _core_tree($node->right, $root, $walk, $depth + 1) or return;
    ++$walk->{operators};
    return [$operator, $left, $right];
}

sub _unchanged {
    my ($walk) = @_;
    for my $stamp (@{$walk->{stamps}}) {
        my ($object, $raw, $kind) = @$stamp;
        return unless ($kind eq 'signal' ? _raw_signal($object) : _raw_node($object)) eq $raw;
    }
    return 1;
}

sub _capture {
    my ($signal) = @_;
    my $walk = {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {},
        signals => [], stamps => [], nodes => [], operands => [], names => {}, operators => 0, literals => 0};
    my $own = _observe_signal($signal, $walk) or return;
    my $roles = $own->{roles};
    return unless $own->{type} eq 'wire' && $roles->{is_intermediate}
        && !$roles->{is_output} && !$roles->{is_aux_output} && !$roles->{width_declared};
    my $role = $roles->{signal_role};
    return if defined($role) && (ref($role) || ($role ne 'intermediate' && $role ne 'INTERNAL_INTERMEDIATE'));
    return if grep {exists($signal->{$_})} qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    my $tree = _core_tree($signal->driving_ast, $signal, $walk, 0) or return;
    return unless $walk->{operators} && $walk->{literals};
    my $width = FSM::CoreExpressionWidthSupport->infer_width($signal->driving_ast);
    my $expected = defined($width) ? $width : 1;
    return unless FSM::IntermediateWidthAllocationSupport::_width($signal->width)
        eq FSM::IntermediateWidthAllocationSupport::_width($expected);
    return unless _unchanged($walk);
    my $record = {kind => 'source_literal_operand_max', selected_width => $width, expression_tree => $tree};
    return {record => $record, objects => $walk->{signals}, state => _json()->encode({signal => $own,
        nodes => $walk->{nodes}, operands => $walk->{operands}, record => $record,
        stamps => [map {[_identity($_->[0]), $_->[1], $_->[2]]} @{$walk->{stamps}}]})};
}

sub _tracked {
    my ($capture) = @_;
    return !grep {!exists($_->{_intermediate_width_allocation_revision})} @{$capture->{objects}};
}

sub _matches {
    my ($record, $capture) = @_;
    return unless _json()->encode($record->{expression_tree}) eq _json()->encode($capture->{record}{expression_tree});
    my ($supplied, $actual) = ($record->{selected_width}, $capture->{record}{selected_width});
    return !defined($supplied) && !defined($actual) unless defined($supplied) && defined($actual);
    return FSM::IntermediateWidthAllocationSupport::_width($supplied)
        eq FSM::IntermediateWidthAllocationSupport::_width($actual);
}

sub prepare_core {
    my ($class, %args) = @_;
    my $record = $class->copy_record($args{record});
    my $capture = eval {_capture($args{signal})};
    confess "Source literal allocation requires the actual current plain Core literal shape\n"
        unless $capture && _matches($record, $capture);
    if ($args{track}) {
        $_->_track_intermediate_width_allocation for @{$capture->{objects}};
    }
    my $after = eval {_capture($args{signal})};
    confess "Source literal allocation requires unchanged tracked source state\n"
        unless $after && _tracked($after) && $capture->{state} eq $after->{state};
    return {record => $record, state => $after->{state}};
}

sub current_core {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = eval {
        my $capture = _capture($args{signal}) or return;
        return unless _tracked($capture) && $capture->{state} eq $holder->{state};
        my $copy = $class->copy_record($holder->{record});
        return unless _matches($copy, $capture);
        my $after = _capture($args{signal}) or return;
        return unless _tracked($after) && $after->{state} eq $capture->{state} && _matches($copy, $after);
        $copy;
    };
    return $@ ? undef : $record;
}

1;

=head1 NAME

FSM::SourceLiteralWidthAllocationSupport - Current raw source literal allocation holders

=head1 METHODS

=head2 copy_record

Validate and detach C<{kind =E<gt> source_literal_operand_max, selected_width,
expression_tree}>. Exact C<selected_width> may be undef; it is distinct from a
Core Signal's nominal scalar compatibility width. Tree nodes are canonical
binary bitwise C<&>, C<|>, C<^>, C<[signal, name]> or
C<[literal, {value, width, radix}]>. Literal data retains supplied JSON kinds.
An explicit literal size is independent; this holder assigns no backend default.
Closed schema, cycle, depth and occurrence validation precede serialization.

=head2 prepare_core

Validate producer-supplied intent against the actual current plain unsigned
wire intermediate, bitwise tree and literal data. At least one literal and one
operator are required. Whole leaf Signals must be plain unsigned independent
Signals; generated child references, slices and other expression families
withhold. Result declarations, constraints, named/signed types and conflicting
roles withhold. Nullable exact width comes from the shared Core width walk;
unknown results must still have their nominal compatibility width. Explicit
sizes must agree with the actual exact operand maximum.

C<track =E<gt> 1> opts validated result and source Signals into the existing
revocation counters. Complete validation precedes tracking, followed by an
unchanged-state check. Returned C<{record, state}> is detached plain JSON;
lifetime tokens use the existing weak identity table and retain no owners.
This validator does not attest source birth, publish a policy, change source
inference, or admit a target profile. Actual birth/publication and nested
unknown propagation remain separately owned consumers.

=head2 current_core

Return a detached record only while actual identities, raw literal kinds,
explicit widths, selected state, roles, source metadata, AST slots and tracked
revisions agree. Supported matching-state writes revoke. Foreign capsules,
later object lifetimes and unknown shapes withhold. A raw complete-capture
barrier checks earlier objects after all potentially mutating getters. Ordinary
absent lookup creates no fields. Failed preparation installs nothing; the
future owner must revoke any previous installation before replacement.

Focused executable controls:

  scripts/run_with_ram_guard.sh -- prove -Iperl t/2251-source-literal-width-holder.t

=cut
