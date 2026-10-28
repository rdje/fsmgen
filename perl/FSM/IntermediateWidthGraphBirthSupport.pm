package FSM::IntermediateWidthGraphBirthSupport;

use v5.20;
use strict;
use warnings;
use Scalar::Util qw(blessed refaddr);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

=head1 NAME

FSM::IntermediateWidthGraphBirthSupport - Retain original arithmetic candidate ownership through factorizer substitution

=head1 DESCRIPTION

Private plain-data support for the actual fresh factorizer allocation and owned
substitution boundaries. A graph birth retains the ordered original arithmetic
tree separately from later widths and policies. It proves no numeric allocation,
source type eligibility, mutable range relationship or target admission.

The closed tree uses C<[operator, left, right]> for canonical C<+>, C<->, C<*>,
C</>, C<%>, and C<[signal, name]> for typed whole source references. At least
one operand must originally be a compound expression. Literal, state, sliced,
foreign and cyclic trees withhold. Private walks stop beyond 64 binary levels or 4096
visited nodes; withholding metadata does not change ordinary generation.

Capsules retain only JSON data. Object identities anchor the actual allocator,
candidate, AST nodes and Core source owners. Generated references additionally
bind actual child candidates and their current original birth proof. Expanding
those children must reproduce the original ordered source tree, including Core
source identities. A printed expression or selected width supplies no lineage.
Compatible generated references are classified by actual ancestry before any
Core-specific method is used; their broad compatibility C<isa> is not a Core
Signal ownership contract.

=cut

sub _json { return JSON::PP->new->canonical }
sub _id { return ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef }

sub _entry {
    my ($factorizer, $name) = @_;
    return undef unless blessed($factorizer) && $factorizer->isa('FSM::HDL::ASTFactorization')
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    my $entries = $factorizer->{intermediate_signals};
    my $entry = ref($entries) eq 'HASH' ? $entries->{$name} : undef;
    return undef unless ref($entry) eq 'HASH' && defined($entry->{structural_id})
        && !ref($entry->{structural_id});
    return $entry;
}

sub _unresolved {
    my ($entry) = @_;
    return !defined($entry->{width}) && defined($entry->{width_source})
        && !ref($entry->{width_source}) && $entry->{width_source} eq 'unresolved_factorization_ast';
}

sub _binary_operator {
    my ($node, $substituted) = @_;
    return undef unless blessed($node) && (UNIVERSAL::isa($node, 'FSM::AST::BinaryOp')
        || UNIVERSAL::isa($node, 'FSM::CoreAST::BinaryOp')
        || ($substituted && UNIVERSAL::isa($node, 'FSM::HDL::SubstitutedBinaryOp')));
    my $operator = $node->operator;
    return undef unless defined($operator) && !ref($operator) && $operator =~ m{\A[+*/%\-]\z};
    return $operator;
}

sub _source_leaf {
    my ($node) = @_;
    return undef unless blessed($node) && (UNIVERSAL::isa($node, 'FSM::AST::SignalRef')
        || UNIVERSAL::isa($node, 'FSM::CoreAST::SignalRef'));
    my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($node);
    return undef unless defined $name;
    my $core = UNIVERSAL::isa($node, 'FSM::CoreAST::SignalRef') ? _id($node->signal) : undef;
    return {public => ['signal', $name], semantic => ['signal', $name, $core],
        snapshot => ['signal', ref($node), _id($node), $name, $core], operators => 0};
}

sub _original_tree {
    my ($node, $active, $budget, $depth) = @_;
    return undef unless blessed($node) && $depth <= 64 && --$$budget >= 0;
    my $identity = _id($node);
    return undef if $active->{$identity};
    local $active->{$identity} = 1;
    my $leaf = _source_leaf($node);
    return $leaf if $leaf;
    my $operator = _binary_operator($node, 0);
    return undef unless defined $operator;
    my $left = _original_tree($node->left, $active, $budget, $depth + 1) or return undef;
    my $right = _original_tree($node->right, $active, $budget, $depth + 1) or return undef;
    return {public => [$operator, $left->{public}, $right->{public}],
        semantic => [$operator, $left->{semantic}, $right->{semantic}],
        snapshot => ['binary', ref($node), $identity, $operator, $left->{snapshot}, $right->{snapshot}],
        operators => 1 + $left->{operators} + $right->{operators}};
}

sub _child_source_tree {
    my ($factorizer, $name, $visiting) = @_;
    return undef if $visiting->{$name};
    my $entry = _entry($factorizer, $name) or return undef;
    my $graphs = $factorizer->{_intermediate_width_graph_births};
    if (ref($graphs) eq 'HASH' && exists($graphs->{$name})) {
        my $graph = _current_birth($factorizer, $name, $graphs->{$name}, $visiting) or return undef;
        return _json()->decode($graph->{birth_state})->{source_tree};
    }
    my $whole = $factorizer->_current_intermediate_width_birth($name) or return undef;
    my $budget = 4096;
    my $tree = _original_tree($entry->{ast}, {}, \$budget, 0) or return undef;
    return undef unless $tree->{operators} == 1;
    return $tree->{semantic};
}

sub _current_tree {
    my ($node, $context, $active, $budget, $depth) = @_;
    return undef unless blessed($node) && $depth <= 64 && --$$budget >= 0;
    my $identity = _id($node);
    return undef if $active->{$identity};
    local $active->{$identity} = 1;
    my $leaf = _source_leaf($node);
    return $leaf if $leaf;
    if (UNIVERSAL::isa($node, 'FSM::HDL::IntermediateSignalRef')) {
        my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($node);
        return undef unless defined($name) && $name ne $context->{name};
        my $entry = _entry($context->{factorizer}, $name) or return undef;
        my $source = _child_source_tree($context->{factorizer}, $name, $context->{visiting}) or return undef;
        my $edge = {source_name => $name, entry_identity => _id($entry),
            structural_id => $entry->{structural_id}, source_tree_sha256 => sha256_hex(_json()->encode($source))};
        my $previous = $context->{previous_edges}{$identity};
        if (defined $previous) {
            return undef unless _json()->encode($previous) eq _json()->encode($edge);
        } else {
            my $mapping = $context->{mapping};
            return undef unless ref($mapping) eq 'HASH'
                && defined($mapping->{$entry->{structural_id}}) && !ref($mapping->{$entry->{structural_id}})
                && $mapping->{$entry->{structural_id}} eq $name;
        }
        $context->{edges}{$identity} = $edge;
        return {semantic => $source, snapshot => ['intermediate', ref($node), $identity, $name]};
    }
    my $operator = _binary_operator($node, 1);
    return undef unless defined $operator;
    my $left = _current_tree($node->left, $context, $active, $budget, $depth + 1) or return undef;
    my $right = _current_tree($node->right, $context, $active, $budget, $depth + 1) or return undef;
    return {semantic => [$operator, $left->{semantic}, $right->{semantic}],
        snapshot => ['binary', ref($node), $identity, $operator, $left->{snapshot}, $right->{snapshot}]};
}

sub _state {
    my ($factorizer, $name, $ast, $basis, $previous_edges, $mapping, $visiting) = @_;
    my $context = {factorizer => $factorizer, name => $name, previous_edges => $previous_edges,
        mapping => $mapping, visiting => $visiting, edges => {}};
    my $budget = 4096;
    my $tree = _current_tree($ast, $context, {}, \$budget, 0) or return undef;
    return undef unless _json()->encode($tree->{semantic}) eq _json()->encode($basis->{source_tree});
    return _json()->encode({ast => $tree->{snapshot}, edges => $context->{edges}});
}

sub _current_birth {
    my ($factorizer, $name, $holder, $visiting) = @_;
    my $entry = _entry($factorizer, $name) or return undef;
    return undef if $visiting->{$name};
    local $visiting->{$name} = 1;
    return undef unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'birth_state,current_state,record'
        && ref($holder->{record}) eq 'HASH' && join(',', sort keys %{$holder->{record}}) eq 'expression_tree,kind'
        && ($holder->{record}{kind} // '') eq 'arithmetic_graph_candidate'
        && defined($holder->{birth_state}) && !ref($holder->{birth_state})
        && defined($holder->{current_state}) && !ref($holder->{current_state});
    my $basis = _json()->decode($holder->{birth_state});
    return undef unless ref($basis) eq 'HASH' && ($basis->{owner_identity} // '') eq _id($factorizer)
        && ($basis->{entry_identity} // '') eq _id($entry)
        && ($basis->{structural_id} // '') eq $entry->{structural_id}
        && _json()->encode($basis->{record}) eq _json()->encode($holder->{record});
    my $previous = _json()->decode($holder->{current_state});
    return undef unless ref($previous) eq 'HASH' && ref($previous->{edges}) eq 'HASH';
    my $state = _state($factorizer, $name, $entry->{ast}, $basis, $previous->{edges}, undef, $visiting);
    return undef unless defined($state) && $state eq $holder->{current_state};
    return _json()->decode(_json()->encode($holder));
}

=head1 METHODS

=head2 prepare_birth

Called at the actual fresh unresolved candidate allocation. Return a separate
C<{kind =E<gt> arithmetic_graph_candidate, expression_tree}> record inside its
owner-local capsule. Caller-made rows do not attest allocator provenance; only
the actual allocator installs this capsule. Whole-reference candidates retain
their existing separate birth API. Ordinary lookup never creates tracking data.

=cut

sub prepare_birth {
    my ($class, %args) = @_;
    my $holder = eval {
        my ($factorizer, $name) = @args{qw(factorizer signal_name)};
        my $entry = _entry($factorizer, $name) or return undef;
        return undef unless _unresolved($entry);
        my $budget = 4096;
        my $tree = _original_tree($entry->{ast}, {}, \$budget, 0) or return undef;
        return undef unless $tree->{operators} > 1;
        my $record = {kind => 'arithmetic_graph_candidate', expression_tree => $tree->{public}};
        my $basis = {owner_identity => _id($factorizer), entry_identity => _id($entry),
            structural_id => $entry->{structural_id}, record => $record, source_tree => $tree->{semantic}};
        return {record => $record, birth_state => _json()->encode($basis),
            current_state => _json()->encode({ast => $tree->{snapshot}, edges => {}})};
    };
    return $@ ? undef : $holder;
}

=head2 current_birth

Return a detached still-current capsule for the actual candidate and all typed
generated edges. Copied rows/capsules, changed AST/reference ownership, foreign
or stale children, malformed records and cycles withhold. Historical birth is
independent of later selected widths; this getter creates no new birth or policy.

=cut

sub current_birth {
    my ($class, %args) = @_;
    my $holder = eval {_current_birth(@args{qw(factorizer signal_name holder)}, {})};
    return $@ ? undef : $holder;
}

=head2 prepare_substitution

Called around the actual owned substitution while the candidate is unresolved.
Validate the prior actual capsule and original AST, then bind the returned AST's
new typed references to the actual structural-id mapping and current children.
Expanded original child trees must preserve the exact original source tree.
Return pending plain state for installation with that AST; later observation,
numeric selection, printed names or arbitrary mapping cannot refresh ownership.

=cut

sub prepare_substitution {
    my ($class, %args) = @_;
    my $holder = eval {
        my ($factorizer, $name) = @args{qw(factorizer signal_name)};
        my $entry = _entry($factorizer, $name) or return undef;
        return undef unless _unresolved($entry) && blessed($args{original_ast})
            && _id($entry->{ast}) eq _id($args{original_ast});
        my $current = _current_birth($factorizer, $name, $args{holder}, {}) or return undef;
        my $basis = _json()->decode($current->{birth_state});
        my $previous = _json()->decode($current->{current_state});
        my $state = _state($factorizer, $name, $args{substituted_ast}, $basis,
            $previous->{edges}, $args{mapping}, {$name => 1});
        return undef unless defined $state;
        $current->{current_state} = $state;
        return $current;
    };
    return $@ ? undef : $holder;
}

1;
