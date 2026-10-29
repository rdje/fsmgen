package FSM::SourceBitwiseTreeWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Hash::Util::FieldHash qw(fieldhash);
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed refaddr);
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport ();
use FSM::SourceBitwiseTreePolicySupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

fieldhash my %IDENTITIES;
my $NEXT_IDENTITY = Math::BigInt->new(0);

sub _json { return JSON::PP->new->canonical }

sub _identity {
    my ($object) = @_;
    return $IDENTITIES{$object} if exists $IDENTITIES{$object};
    # Reference addresses can be reused after destruction. FieldHash keys are
    # weak, and these values contain no object, so neither owners nor their
    # identities are accidentally associated with a later allocation.
    return $IDENTITIES{$object} = 'source-tree-' . $NEXT_IDENTITY->binc->bstr;
}

sub _plain {
    my ($signal) = @_;
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    return unless ref($signal->{attributes}) eq 'HASH'
        && ref($signal->{constraints}) eq 'ARRAY' && !@{$signal->{constraints}};
    return if defined($signal->{state_model}) || defined($signal->{declared_type_name})
        || defined($signal->{declared_type_spec});
    if (exists $signal->{_intermediate_width_allocation_revision}) {
        my $revision = $signal->{_intermediate_width_allocation_revision};
        return unless defined($revision) && !ref($revision) && $revision =~ /\A[0-9]+\z/;
    }
    my $descriptor = FSM::IntermediateWidthAllocationSupport::_descriptor($signal) or return;
    my %roles = map {$_ => $signal->get_attribute($_)}
        qw(is_intermediate is_output is_aux_output width_declared signal_role);
    return if grep {defined($_) && ref($_) && !JSON::PP::is_bool($_)} values %roles;
    return {%$descriptor, identity_token => _identity($signal),
        width_value => $signal->width, roles => \%roles};
}

sub _core_tree {
    my ($node, $root, $depth, $walk) = @_;
    return unless blessed($node)
        && $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS()
        && --$walk->{remaining} >= 0;
    my $address = refaddr($node);
    return if $walk->{active}{$address};
    local $walk->{active}{$address} = 1;
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        return if defined($node->{slice});
        my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($node) or return;
        my $signal = $node->signal;
        my $descriptor = _plain($signal) or return;
        return if refaddr($signal) == refaddr($root) || $name eq $root->name;
        return if exists($walk->{names}{$name})
            && $walk->{names}{$name} ne $descriptor->{identity_token};
        $walk->{names}{$name} = $descriptor->{identity_token};
        push @{$walk->{sources}}, $signal;
        push @{$walk->{descriptors}}, $descriptor;
        push @{$walk->{references}}, _identity($node);
        return ['signal', $name];
    }
    return unless $node->isa('FSM::CoreAST::BinaryOp')
        && ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} == 2;
    my $operator = $node->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    push @{$walk->{nodes}}, [_identity($node), $operator];
    my $left = _core_tree($node->left, $root, $depth + 1, $walk) or return;
    my $right = _core_tree($node->right, $root, $depth + 1, $walk) or return;
    ++$walk->{operators};
    return [$operator, $left, $right];
}

sub _capture {
    my ($signal) = @_;
    my $own = _plain($signal) or return;
    my $roles = $own->{roles};
    return unless $signal->type eq 'wire' && $roles->{is_intermediate}
        && !$roles->{is_output} && !$roles->{is_aux_output} && !$roles->{width_declared};
    my $role = $roles->{signal_role};
    return if defined($role)
        && (ref($role) || ($role ne 'intermediate' && $role ne 'INTERNAL_INTERMEDIATE'));
    return if grep {exists($signal->{$_})}
        qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    my $walk = {remaining => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES(),
        active => {}, names => {}, sources => [], descriptors => [], references => [], nodes => [], operators => 0};
    my $tree = _core_tree($signal->driving_ast, $signal, 0, $walk) or return;
    return unless $walk->{operators} > 1;
    my @names = map {$_->{name}} @{$walk->{descriptors}};
    my $maximum = $walk->{descriptors}[0]{width};
    $maximum = FSM::IntermediateWidthAllocationSupport::_maximum($maximum, $_->{width})
        for @{$walk->{descriptors}};
    return unless $own->{width} eq $maximum;
    my $state = _json()->encode({signal => $own,
        revision => $signal->_intermediate_width_allocation_revision,
        ast_nodes => $walk->{nodes}, operand_reference_identities => $walk->{references},
        expression_tree => $tree, operands => $walk->{descriptors}, roles => $roles});
    return {operator => $tree->[0], expression_tree => $tree, source_names => \@names,
        width => $maximum, objects => [$signal, @{$walk->{sources}}], state => $state};
}

sub _matches {
    my ($record, $capture) = @_;
    return $record->{operator} eq $capture->{operator}
        && _json()->encode($record->{source_names}) eq _json()->encode($capture->{source_names})
        && _json()->encode($record->{expression_tree}) eq _json()->encode($capture->{expression_tree})
        && FSM::IntermediateWidthAllocationSupport::_width($record->{selected_width}) eq $capture->{width};
}

sub _tracked {
    my ($capture) = @_;
    return !grep {!exists($_->{_intermediate_width_allocation_revision})} @{$capture->{objects}};
}

sub prepare_core {
    my ($class, %args) = @_;
    my $record = FSM::SourceBitwiseTreePolicySupport->copy_record($args{record});
    my $capture = eval {_capture($args{signal})};
    confess "Source bitwise tree allocation requires the actual current plain Core tree max shape\n"
        unless $capture && _matches($record, $capture);
    if ($args{track}) {
        $_->_track_intermediate_width_allocation for @{$capture->{objects}};
        my $after = eval {_capture($args{signal})};
        confess "Source bitwise tree allocation changed during tracked installation\n"
            unless $after && $after->{state} eq $capture->{state} && _matches($record, $after);
        $capture = $after;
    }
    confess "Source bitwise tree allocation requires tracked result and leaf revisions\n"
        unless _tracked($capture);
    return {record => $record, state => $capture->{state}};
}

sub current_core {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = eval {
        my $capture = _capture($args{signal}) or return;
        return unless _tracked($capture) && $capture->{state} eq $holder->{state};
        my $copy = FSM::SourceBitwiseTreePolicySupport->copy_record($holder->{record});
        return unless _matches($copy, $capture);
        # A later leaf read can trigger a supported write to an earlier leaf.
        # Recheck the complete state after validation before returning intent.
        my $after = _capture($args{signal}) or return;
        return unless _tracked($after) && $after->{state} eq $capture->{state}
            && _matches($copy, $after);
        $copy;
    };
    return $@ ? undef : $record;
}

sub _source_row_state {
    my ($row, $ast) = @_;
    return unless ref($row) eq 'HASH' && !defined($row->{state_model})
        && defined($row->{source}) && !ref($row->{source}) && $row->{source} eq 'fsmgen_parsing';
    for my $key (qw(ast driving_ast runtime_ast)) {
        return unless blessed($row->{$key}) && refaddr($row->{$key}) == refaddr($ast);
    }
    my $state = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast) or return;
    return {%$state, identity_token => _identity($row)};
}

sub prepare_source_intermediate {
    my ($class, %args) = @_;
    my $context = $args{context};
    my $name = $args{signal_name};
    return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT')
        && defined(FSM::IntermediateWidthAllocationSupport::_width($args{epoch}))
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    my $owner = $context->{backend_sv_intermediate_width_support};
    return unless blessed($owner)
        && $owner->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport')
        && (refaddr($owner->{flattened_dt}) // 0) == refaddr($context);
    my $module = $context->{fsm_module};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    my $signals = $module->signals;
    return unless ref($signals) eq 'HASH';
    my $signal = $signals->{$name};
    my $capture = _capture($signal) or return;
    return unless $signal->name eq $name;
    my $record = $signal->source_bitwise_tree_width_allocation or return;
    return unless _matches($record, $capture);
    for my $object (@{$capture->{objects}}) {
        return unless refaddr($signals->{$object->name} // {}) == refaddr($object);
    }
    my $info = $args{signal_info};
    return unless ref($info) eq 'HASH' && defined($info->{source}) && !ref($info->{source})
        && $info->{source} eq 'fsmgen_parsing';
    my $registry = $context->{intermediate_signals};
    return unless ref($registry) eq 'HASH';
    my $registered = $registry->{$name};
    my $ast = $signal->driving_ast;
    my $info_state = _source_row_state($info, $ast) or return;
    my $registered_state = _source_row_state($registered, $ast) or return;
    my @widths = map {$_->width} @{$capture->{objects}}[1 .. $#{$capture->{objects}}];
    return unless FSM::SourceBitwiseTreePolicySupport->matches_selected_widths($record, $info->{width}, @widths)
        && FSM::SourceBitwiseTreePolicySupport->matches_selected_widths($record, $registered->{width}, @widths);
    my $state = _json()->encode({context_identity => _identity($context), module_identity => _identity($module),
        width_owner_identity => _identity($owner),
        module_signals_identity => _identity($signals), registry_identity => _identity($registry),
        epoch => $args{epoch}, signal_name => $name, core_state => $capture->{state},
        signal_info => $info_state, registered => $registered_state});
    # Complete all potentially mutating source reads before returning a capsule.
    my $after = _capture($signal) or return;
    return unless _tracked($after) && $after->{state} eq $capture->{state}
        && $signal->source_bitwise_tree_width_allocation;
    return unless (refaddr($context->{fsm_module}) // 0) == refaddr($module)
        && (refaddr($context->{backend_sv_intermediate_width_support}) // 0) == refaddr($owner)
        && (refaddr($owner->{flattened_dt}) // 0) == refaddr($context)
        && (refaddr($module->signals) // 0) == refaddr($signals)
        && (refaddr($context->{intermediate_signals}) // 0) == refaddr($registry);
    my $core_state = _json()->decode($capture->{state});
    my @descriptors = ($core_state->{signal}, @{$core_state->{operands}});
    my @names = ($name, @{$record->{source_names}});
    for my $index (0 .. $#names) {
        my $object = $capture->{objects}[$index];
        return unless (refaddr($signals->{$names[$index]}) // 0) == refaddr($object)
            && exists($object->{_intermediate_width_allocation_revision})
            && _json()->encode([$object->{_intermediate_width_allocation_revision}])
                eq _json()->encode([$descriptors[$index]{revision}]);
    }
    return unless (refaddr($registry->{$name}) // 0) == refaddr($registered);
    my $final_info = _source_row_state($info, $ast) or return;
    my $final_registered = _source_row_state($registered, $ast) or return;
    return unless _json()->encode($final_info) eq _json()->encode($info_state)
        && _json()->encode($final_registered) eq _json()->encode($registered_state);
    return {record => $record, state => $state};
}

sub current_source_intermediate {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = eval {
        my $current = $class->prepare_source_intermediate(%args) or return;
        return unless $current->{state} eq $holder->{state}
            && _json()->encode($current->{record}) eq _json()->encode(
                FSM::SourceBitwiseTreePolicySupport->copy_record($holder->{record}));
        $current->{record};
    };
    return $@ ? undef : $record;
}

1;

=head1 NAME

FSM::SourceBitwiseTreeWidthSupport - Current Core and source-row bitwise tree intent

=head1 DESCRIPTION

Binds an explicitly supplied source bitwise tree policy to a plain unsigned Core
wire intermediate, its actual nested Core bitwise tree and every ordered whole
Core SignalRef leaf. Root and leaf wire/register profiles exclude state, named
types and independent constraints; authored result width metadata and conflicting
roles withhold. The exact result maximum, operators, topology, duplicate-name
object association, AST/reference lifetimes, roles and revisions must agree.
This adapter traverses the held Core tree, not other Signals' driving ASTs.

Stored capsules contain only detached C<record> and opaque JSON C<state>.
Per-object serial identities use Perl core C<Hash::Util::FieldHash> weak keys
with scalar values, so they retain no source graph and cannot associate an old
identity with reused storage. Supported matching-state writes revoke the shared
opt-in revision counters. Unknown, copied, foreign, stale or changed capsules
withhold instead of re-deriving intent from selected widths.

The Core methods establish explicit local intent, not fresh Parser provenance,
module membership or backend completion. The separate source-row adapter joins
that current policy to actual module/root/all-source identities and collected
and registered metadata rows. Its owner supplies the successful collection/epoch
boundary. Neither layer establishes frozen leaf equivalence, selected target
proof or symbolic range eligibility.
The existing binary policy API retains its closed schema and eligibility.

=head1 METHODS

=head2 prepare_core

Accept C<signal>, producer-supplied C<record> and optional C<track>. Validate
the separate source-tree schema against the actual current Core graph.
C<track =E<gt> 1> opts the result and every leaf into existing revision counters;
without it, all objects must already be tracked. Tracking changes no semantic
revision and is followed by a complete capture recheck. Return a detached
C<{record, state}> capsule; invalid or incoherent installation throws. Returned
data retains no Core objects. It does not install or publish the policy.

=head2 current_core

Accept C<signal> and C<holder>. Recheck complete actual shape, lifetimes and
tracked revisions against the held state, then return a detached policy or
undef. A complete final capture rejects a supported write during validation;
existing revision counters must be nonnegative decimal scalars. Malformed,
stale and foreign private holders withhold without throwing.
An absent policy is not inferred from matching numeric widths.

=head2 prepare_source_intermediate

Accept C<context>, C<signal_name>, actual collected C<signal_info> and C<epoch>.
Prepare detached C<{record, state}> data from an existing current Core tree
policy, exact module membership for root and every ordered leaf, actual held AST
and both source metadata rows. Plain unsigned profiles and exact selected maximum
must agree. Lifetime tokens bind the installed width owner, context/module and
maps/rows without retaining them.
A final join rechecks module membership, current rows and raw tracked revisions
after all source reads. Unsupported or incoherent shape withholds. This adapter
does not assert that collection completed; its backend owner owns that gate.

=head2 current_source_intermediate

Accept the preparation arguments plus C<holder>. Reprepare complete current state
and compare the closed held record/state before returning a detached tree policy.
Changed, copied, foreign or stale rows/contexts/epochs withhold; malformed holders
withhold without throwing. The backend owner checks successful epoch completion
before calling. Binary and arithmetic graph APIs remain separate.

=cut
