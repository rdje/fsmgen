package FSM::IntermediateWidthGraphInferenceSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

=head1 NAME

FSM::IntermediateWidthGraphInferenceSupport - Prepare actual pending arithmetic graph inputs and current dependency frames

=head1 DESCRIPTION

Private two-phase validation at the real normalization/inference boundary.
Pending input binds the first unresolved parent and exact typed operands in the
width owner's current non-owning row view. Ready proof additionally requires
current held child events. Neither phase publishes an event or selected policy,
attests execution of a caller-supplied branch, or enables a symbolic range.

Generated references follow the numeric resolver's passed-registry precedence.
The factorizer fallback without an actual collected row supplies no proof.
Ordinary source references in this bounded profile require actual module Signals;
assignment-analysis-only lookup and other source profiles remain separate.
Intrinsic numeric profiles preserve their independent state/width constraints;
they are not target type or mutable-range eligibility.

=cut

sub _json { return JSON::PP->new->canonical }
sub _id { return ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef }
sub _copy { return _json()->decode(_json()->encode($_[0])) }

sub _scope {
    my ($owner) = @_;
    return undef unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
    my $ctx = $owner->{flattened_dt};
    return undef unless blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
        && ref($ctx->{backend_sv_intermediate_width_support}) eq ref($owner)
        && $ctx->{backend_sv_intermediate_width_support} == $owner
        && blessed($ctx->{fsm_module}) && $ctx->{fsm_module}->isa('FSM::CoreAST::FSMModule');
    my $rows = $owner->_current_graph_inference_rows;
    return undef unless ref($rows) eq 'HASH';
    return {context => $ctx, module => $ctx->{fsm_module}, rows => $rows,
        epoch => $owner->{_width_inference_epoch}, view_revision => $owner->{_graph_inference_rows_revision}};
}

sub _metadata {
    return FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state(@_);
}

sub _unresolved {
    my ($row) = @_;
    return ref($row) eq 'HASH' && !defined($row->{width})
        && defined($row->{width_source}) && !ref($row->{width_source})
        && $row->{width_source} eq 'unresolved_factorization_ast';
}

sub _factorized_row {
    my ($factorizer, $name, $info) = @_;
    my $entries = $factorizer->{intermediate_signals};
    my $entry = ref($entries) eq 'HASH' ? $entries->{$name} : undef;
    return undef unless ref($entry) eq 'HASH' && ref($info) eq 'HASH'
        && ($info->{source} // '') eq 'ast_factorization'
        && blessed($entry->{ast}) && blessed($info->{ast}) && blessed($info->{runtime_ast})
        && _id($entry->{ast}) eq _id($info->{ast}) && _id($entry->{ast}) eq _id($info->{runtime_ast})
        && ($info->{runtime_ast_source} // '') eq 'substituted_ast';
    my $input = _metadata($info, $entry->{ast}) or return undef;
    my $allocated = _metadata($entry, $entry->{ast}) or return undef;
    return {entry => $entry, input => $input, allocated => $allocated};
}

sub _child_birth {
    my ($factorizer, $name) = @_;
    my $graph = $factorizer->_current_intermediate_width_graph_birth($name);
    return {family => 'graph', capsule => $graph} if $graph;
    my $whole = $factorizer->_current_intermediate_width_birth($name);
    return $whole ? {family => 'whole', capsule => $whole} : undef;
}

sub _prepare_input {
    my (%args) = @_;
    return undef unless exists($args{native_signal_info}) && !defined($args{native_signal_info});
    return undef if defined($args{track}) && (ref($args{track}) || $args{track} !~ /\A[01]\z/);
    my $owner = $args{width_support};
    my $scope = _scope($owner) or return undef;
    my ($ctx, $module, $rows) = @{$scope}{qw(context module rows)};
    my $name = $args{signal_name};
    return undef unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
        && ref($args{signal_registry}) eq 'HASH' && _id($args{signal_registry}) eq _id($rows)
        && ref($args{signal_info}) eq 'HASH' && ref($rows->{$name}) eq 'HASH'
        && _id($rows->{$name}) eq _id($args{signal_info});
    my $revisions = $owner->{_width_inference_revisions};
    return undef unless ref($revisions) eq 'HASH'
        && defined(FSM::IntermediateWidthAllocationSupport::_width($revisions->{$name}))
        && FSM::IntermediateWidthAllocationSupport::_width($revisions->{$name}) eq '1';
    my $signals = $module->signals;
    return undef unless ref($signals) eq 'HASH' && !exists($signals->{$name});
    return undef if defined($ctx->{enable_graph_assignment_support}->get_signal_info($name));
    my $factorizer = $ctx->{ast_factorizer};
    return undef unless blessed($factorizer) && $factorizer->isa('FSM::HDL::ASTFactorization');
    my $parent = _factorized_row($factorizer, $name, $args{signal_info}) or return undef;
    return undef unless _unresolved($args{signal_info}) && _unresolved($parent->{entry});
    my $birth = $factorizer->_current_intermediate_width_graph_birth($name) or return undef;
    my $ast = $parent->{entry}{ast};
    my $shape = FSM::IntermediateWidthAllocationSupport->binary_operand_max_shape($ast) or return undef;
    my (@operands, @sources);
    my @nodes = ($ast->left, $ast->right);
    my $generated = 0;
    for my $index (0, 1) {
        my $node = $nodes[$index];
        my $source_name = $shape->{source_names}[$index];
        if (UNIVERSAL::isa($node, 'FSM::HDL::IntermediateSignalRef')) {
            return undef if $source_name eq $name || exists($signals->{$source_name});
            my $child = _factorized_row($factorizer, $source_name, $rows->{$source_name}) or return undef;
            my $origin = _child_birth($factorizer, $source_name) or return undef;
            push @operands, {kind => 'intermediate', source_name => $source_name,
                reference_identity => _id($node), signal_info => $child->{input},
                factorizer_entry => $child->{allocated}, birth => $origin};
            ++$generated;
        } else {
            my $source = $signals->{$source_name};
            my $descriptor = FSM::IntermediateWidthAllocationSupport::_descriptor($source) or return undef;
            return undef unless $descriptor->{name} eq $source_name;
            return undef unless ref($descriptor->{constraints}) eq 'ARRAY' && !@{$descriptor->{constraints}};
            return undef if UNIVERSAL::isa($node, 'FSM::CoreAST::SignalRef')
                && _id($node->signal) ne _id($source);
            push @sources, $source;
            push @operands, {kind => 'module', source_name => $source_name,
                reference_identity => _id($node), source => $descriptor};
        }
    }
    return undef unless $generated;
    my $registered_map = $ctx->{intermediate_signals};
    return undef if defined($registered_map) && ref($registered_map) ne 'HASH';
    my $registered = ref($registered_map) eq 'HASH' ? $registered_map->{$name} : undef;
    my $registered_state = defined($registered) ? _metadata($registered, $ast) : undef;
    return undef if defined($registered) && !$registered_state;
    return undef if $registered_state && (defined($registered_state->{width})
        || (defined($registered_state->{width_source})
            && $registered_state->{width_source} ne 'unresolved_factorization_ast'));
    # Tracking is explicit and begins only after every source/profile is valid.
    # Refresh its descriptors after activating the existing revocation counters.
    if ($args{track}) {
        $_->_track_intermediate_width_allocation for @sources;
        for my $operand (@operands) {
            next unless $operand->{kind} eq 'module';
            $operand->{source} = FSM::IntermediateWidthAllocationSupport::_descriptor($signals->{$operand->{source_name}});
            return undef unless $operand->{source};
        }
    }
    return _copy({kind => 'arithmetic_graph_input', signal_name => $name,
        context_identity => _id($ctx), module_identity => _id($module),
        registry_identity => _id($rows), registry_revision => $scope->{view_revision},
        epoch => $scope->{epoch}, revision => $revisions->{$name}, shape => $shape,
        graph_birth => $birth, signal_info => $parent->{input}, factorizer_entry => $parent->{allocated},
        registered => $registered_state, operands => \@operands});
}

sub _stable_input {
    my ($input) = @_;
    my $copy = _copy($input);
    for my $operand (@{$copy->{operands}}) {
        next unless $operand->{kind} eq 'intermediate';
        for my $field (qw(signal_info factorizer_entry)) {
            delete @{$operand->{$field}}{qw(width width_source)};
        }
    }
    return $copy;
}

sub _child_kernel {
    my ($owner, $scope, $operand) = @_;
    my $name = $operand->{source_name};
    my $info = $scope->{rows}{$name};
    return undef unless ref($info) eq 'HASH';
    my ($method, $events);
    if ($operand->{birth}{family} eq 'whole') {
        $method = 'factorized_width_inference_event';
        $events = $owner->{_width_inference_events};
    } else {
        $method = 'factorized_graph_inference_event';
        $events = $owner->{_graph_inference_events};
    }
    return undef unless $owner->can($method) && ref($events) eq 'HASH';
    my $record = $owner->$method($name, $info) or return undef;
    my $holder = $events->{$name};
    return undef unless ref($holder) eq 'HASH' && defined($holder->{state}) && !ref($holder->{state});
    my $state = _json()->decode($holder->{state});
    return undef unless ref($state) eq 'HASH' && ref($state->{signal_info}) eq 'HASH'
        && $state->{signal_info}{identity} eq _id($info)
        && ($state->{epoch} // 0) == $scope->{epoch};
    # The full current getter above validates the owned transient fields. The
    # parent's stable kernel retains semantic/input/source revisions, not a
    # child's permitted cache label, registry-copy identity or resolver count.
    delete @{$state}{qw(revision registered registry_identity registry_revision)};
    for my $field (qw(signal_info factorizer_entry)) {
        next unless ref($state->{$field}) eq 'HASH';
        delete @{$state->{$field}}{qw(width width_source)};
    }
    my $current = $owner->$method($name, $info) or return undef;
    return undef unless _json()->encode($record) eq _json()->encode($current);
    my $width = FSM::IntermediateWidthAllocationSupport::_width($info->{width});
    my $selected = FSM::IntermediateWidthAllocationSupport::_width($record->{selected_width});
    return undef unless defined($width) && defined($selected) && $selected eq $width;
    return {record => $record, state => $state, width => $width};
}

sub _dependencies {
    my ($owner, $scope, $operands) = @_;
    my (@widths, @dependencies);
    for my $operand (@$operands) {
        if ($operand->{kind} eq 'module') {
            push @widths, $operand->{source}{width};
            push @dependencies, {kind => 'module', source_name => $operand->{source_name},
                reference_identity => $operand->{reference_identity}, source => $operand->{source}};
        } else {
            my $kernel = _child_kernel($owner, $scope, $operand) or return undef;
            push @widths, $kernel->{width};
            push @dependencies, {kind => 'intermediate', source_name => $operand->{source_name},
                reference_identity => $operand->{reference_identity}, proof => $kernel};
        }
    }
    return {dependencies => \@dependencies,
        expected_width => FSM::IntermediateWidthAllocationSupport::_maximum(@widths)};
}

=head1 METHODS

=head2 prepare_input

Validate the resolver-supplied C<width_support>, C<signal_name>, C<signal_info>,
actual C<signal_registry> and explicitly absent C<native_signal_info>. The
canonical owner must have the current weak normalization view, first resolver
revision, original graph birth and unresolved parent/allocator rows. Actual
module and generated operands preserve order and independent constraints.
Optional scalar C<track =E<gt> 1> starts existing direct-source revocation counters
only after complete validation. The detached C<arithmetic_graph_input> contains
only JSON data; caller data alone does not attest branch execution.

=cut

sub prepare_input {
    my ($class, %args) = @_;
    my $input = eval {_prepare_input(%args)};
    return $@ ? undef : $input;
}

=head2 prepare_frame

Revalidate C<input> against the canonical C<width_support> and current actual
row view while the parent is still unresolved. Child width/source publication
may advance only with a fully current held child event. Missing or fabricated
record values, changed source/profile/identity, stale view revisions, foreign
epochs and unsupported dependency families withhold. A stable child kernel
keeps original/source constraints while the full child getter validates its
current owned cache/registry/revision state. Ready C<expected_width> is the exact
observed operand maximum; no selected parent result or event is installed.
The complete dependency vector is checked again so a later sibling getter cannot
hide invalidation of a child that was already read.

=cut

sub prepare_frame {
    my ($class, %args) = @_;
    my $frame = eval {
        my $input = _copy($args{input});
        return undef unless ref($input) eq 'HASH' && ($input->{kind} // '') eq 'arithmetic_graph_input';
        my $scope = _scope($args{width_support}) or return undef;
        my $name = $input->{signal_name};
        my $rows = $scope->{rows};
        my $current = _prepare_input(width_support => $args{width_support}, signal_name => $name,
            signal_info => $rows->{$name}, signal_registry => $rows, native_signal_info => undef) or return undef;
        return undef unless _json()->encode(_stable_input($input)) eq _json()->encode(_stable_input($current));
        my $proof = _dependencies($args{width_support}, $scope, $current->{operands}) or return undef;
        # A later sibling's getter can invalidate an earlier child's source.
        # Compare the complete dependency proof again before publishing a frame.
        my $checked = _dependencies($args{width_support}, $scope, $current->{operands}) or return undef;
        return undef unless _json()->encode($proof) eq _json()->encode($checked);
        my $again = _prepare_input(width_support => $args{width_support}, signal_name => $name,
            signal_info => $rows->{$name}, signal_registry => $rows, native_signal_info => undef) or return undef;
        return undef unless _json()->encode(_stable_input($current)) eq _json()->encode(_stable_input($again));
        # Child before-inference widths are deliberately replaced by current,
        # validated proof rather than retained as another sizing constraint.
        my $stable = _stable_input($current);
        delete $stable->{operands};
        $stable->{kind} = 'arithmetic_graph_inference_frame';
        $stable->{dependencies} = $proof->{dependencies};
        $stable->{expected_width} = $proof->{expected_width};
        return _copy($stable);
    };
    return $@ ? undef : $frame;
}

1;
