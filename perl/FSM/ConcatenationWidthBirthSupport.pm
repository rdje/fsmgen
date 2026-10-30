package FSM::ConcatenationWidthBirthSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::CoreExpressionWidthSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { return JSON::PP->new->canonical }
sub _identity { return sprintf('%x', refaddr($_[0])) }
sub _scalar {
    return defined($_[0]) && !ref($_[0])
        && length($_[0]) <= FSM::CoreExpressionWidthSupport::MAX_NODES();
}

# This is a provenance snapshot of the built-in node representation, not a
# semantic getter walk. Unknown/subclassed nodes need their own contract;
# invoking arbitrary accessors here could mutate an earlier observed operand.
sub _tree {
    my ($node, $walk, $depth) = @_;
    return unless blessed($node) && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        && --$walk->{remaining} >= 0;
    my $identity = _identity($node);
    return if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;
    my $class = ref($node);
    if ($class eq 'FSM::CoreAST::SignalRef' || $class eq 'FSM::AST::SignalRef') {
        my ($name, $source);
        if ($class eq 'FSM::CoreAST::SignalRef') {
            return if defined $node->{slice};
            my $signal = $node->{signal};
            return unless ref($signal) eq 'FSM::CoreAST::Signal';
            $name = $signal->{name};
            $source = _identity($signal);
        } else {
            return if $node->{is_fsm_state_next} || $node->{is_fsm_state_register};
            $name = $node->{signal_name};
        }
        return unless _scalar($name)
            && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
        return {tree => ['signal', $name], state => [$class, $identity, $name, $source]};
    }
    if ($class eq 'FSM::CoreAST::Literal') {
        return unless _scalar($node->{value}) && _scalar($node->{radix})
            && $node->{radix} =~ /\A(?:binary|decimal|hex|octal)\z/;
        return if defined($node->{width}) && (!_scalar($node->{width}) || $node->{width} !~ /\A[0-9]*[1-9][0-9]*\z/);
        my $literal = {map {$_ => $node->{$_}} qw(value width radix)};
        return {tree => ['literal', $literal], state => [$class, $identity, $literal]};
    }
    return unless $class eq 'FSM::CoreAST::Concatenation'
        && ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} >= 2;
    # Reject oversized fan-out before constructing an intermediate array.
    return if @{$node->{operands}} > $walk->{remaining};
    my (@trees, @states);
    for my $operand (@{$node->{operands}}) {
        my $child = _tree($operand, $walk, $depth + 1) or return;
        push @trees, $child->{tree};
        push @states, $child->{state};
    }
    return {tree => ['concat', @trees], state => [$class, $identity, @states]};
}

sub _snapshot {
    my ($factorizer, $name) = @_;
    return unless blessed($factorizer) && $factorizer->isa('FSM::HDL::ASTFactorization')
        && _scalar($name) && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    my $entries = $factorizer->{intermediate_signals};
    my $entry = ref($entries) eq 'HASH' ? $entries->{$name} : undef;
    return unless ref($entry) eq 'HASH' && _scalar($entry->{structural_id})
        && ref($entry->{ast}) eq 'FSM::CoreAST::Concatenation';
    my $tree = _tree($entry->{ast}, {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}}, 0)
        or return;
    my $record = {kind => 'concatenation_sum_candidate', expression_tree => $tree->{tree}};
    return {record => $record, state => _json()->encode({owner => _identity($factorizer),
        name => $name, entry => _identity($entry), structural_id => $entry->{structural_id}, tree => $tree->{state}})};
}

sub prepare_birth {
    my ($class, %args) = @_;
    my $holder = eval {
        my $snapshot = _snapshot(@args{qw(factorizer signal_name)}) or return;
        my $entry = $args{factorizer}{intermediate_signals}{$args{signal_name}};
        return unless !defined($entry->{width}) && _scalar($entry->{width_source})
            && $entry->{width_source} eq 'unresolved_factorization_ast';
        return $snapshot;
    };
    return $@ ? undef : $holder;
}

sub current_birth {
    my ($class, %args) = @_;
    my $current = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
            && defined($holder->{state}) && !ref($holder->{state});
        my $expected = _snapshot(@args{qw(factorizer signal_name)}) or return;
        return unless $holder->{state} eq $expected->{state}
            && _json()->encode($holder->{record}) eq _json()->encode($expected->{record});
        return _json()->decode(_json()->encode($expected));
    };
    return $@ ? undef : $current;
}

1;

=head1 NAME

FSM::ConcatenationWidthBirthSupport - Private ordered typed concatenation allocation provenance

=head1 DESCRIPTION

The actual factorizer allocator calls C<prepare_birth> only for a freshly created
unresolved candidate. C<current_birth> returns detached JSON state only while
the same allocator, row, structural identity, complete ordered AST and actual
reference/Core source identities still agree. Caller-made rows or copied capsules
cannot supply that provenance. Lookup never installs or refreshes a birth.

The closed record is C<{kind =E<gt> concatenation_sum_candidate,
expression_tree =E<gt> TREE}>. Trees use C<[concat, OPERANDS...]>,
C<[signal, NAME]> and C<[literal, {value, width, radix}]>. Repeated occurrences,
nesting and original raw literal fields preserve; an unknown literal width stays
null. Only built-in Core concatenations, Core/runtime whole signal references
and Core literals qualify. Subclasses, computed/generated/state/sliced/indexed
references, malformed nodes and cycles withhold without changing generation.

Walk depth and visited occurrences use the canonical Core width-walk bounds;
each scalar is additionally limited to C<MAX_NODES> characters. This is a private
metadata refusal boundary, not a supported source-capacity promise. Capsules
retain plain data and identity tokens, never additional AST or Signal owners.

Birth is independent of subsequent numeric selection. It proves no source width,
rank, signed/type eligibility, namespace membership, completed allocation policy
or symbolic target range. Those require their separate current-source consumers.

=head1 METHODS

=head2 prepare_birth(factorizer => OWNER, signal_name => NAME)

Prepare a capsule at actual unresolved allocation. Only the real allocator may
install it; calling this helper on an arbitrary row grants no allocator authority.
Invalid or unsupported inputs return undef without changing ordinary row data.

=head2 current_birth(factorizer => OWNER, signal_name => NAME, holder => CAPSULE)

Validate current ownership and return detached capsule data, or undef. Later
independent selected widths do not rewrite the historical original birth.

=cut
