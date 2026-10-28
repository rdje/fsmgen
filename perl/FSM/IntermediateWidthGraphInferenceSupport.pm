package FSM::IntermediateWidthGraphInferenceSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

=head1 NAME

FSM::IntermediateWidthGraphInferenceSupport - Prepare actual pending arithmetic graph inputs and current dependency frames

=head1 DESCRIPTION

Private two-phase validation at the real normalization/inference boundary.
Pending input binds the first unresolved parent and exact typed operands in the
width owner's current non-owning row view. Ready proof additionally requires
current held child events. The actual resolver compares the ready proof around
its own selected-width publication before installing a separate intrinsic event.
Frame queries alone do not attest branch execution or complete selected policy.

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
my %validation;

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

sub _observe_input {
    my ($selected, %args) = @_;
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
        && ($selected || FSM::IntermediateWidthAllocationSupport::_width($revisions->{$name}) eq '1');
    my $signals = $module->signals;
    return undef unless ref($signals) eq 'HASH' && !exists($signals->{$name});
    return undef if defined($ctx->{enable_graph_assignment_support}->get_signal_info($name));
    my $factorizer = $ctx->{ast_factorizer};
    return undef unless blessed($factorizer) && $factorizer->isa('FSM::HDL::ASTFactorization');
    my $parent = _factorized_row($factorizer, $name, $args{signal_info}) or return undef;
    return undef unless $selected || (_unresolved($args{signal_info}) && _unresolved($parent->{entry}));
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
    return undef if !$selected && $registered_state && (defined($registered_state->{width})
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
    if ($operand->{birth}{family} eq 'whole' && $validation{active}) {
        $validation{active}{whole}{$name} = _copy({record => $record, state => $holder->{state}});
    }
    return {record => $record, state => $state, width => $width};
}

sub _validation_current {
    my ($owner, $session) = @_;
    my $scope = _scope($owner) or return undef;
    return undef unless $session->{owner_identity} eq _id($owner);
    # These are shallow observations, with no recursive event getters. Every
    # visited graph contributes its own exact local input; whole-reference
    # children contribute their existing non-recursive full inference proof.
    for my $name (sort keys %{$session->{inputs}}) {
        my $current = _observe_input(1, width_support => $owner, signal_name => $name,
            signal_info => $scope->{rows}{$name}, signal_registry => $scope->{rows}, native_signal_info => undef)
            or return undef;
        return undef unless _json()->encode($current) eq $session->{inputs}{$name};
    }
    for my $name (sort keys %{$session->{whole}}) {
        my $expected = $session->{whole}{$name};
        my $events = $owner->{_width_inference_events};
        return undef unless ref($events) eq 'HASH'
            && _json()->encode($events->{$name}) eq _json()->encode($expected);
        my $current = FSM::IntermediateWidthAllocationSupport->prepare_factorized_inference(
            context => $scope->{context}, signal_name => $name, signal_info => $scope->{rows}{$name},
            epoch => $scope->{epoch}, revision => $owner->{_width_inference_revisions}{$name},
            selected_width => $expected->{record}{selected_width}) or return undef;
        return undef unless _json()->encode($current) eq _json()->encode($expected);
    }
    my $events = $owner->{_graph_inference_events};
    for my $name (sort keys %{$session->{holders}}) {
        return undef unless ref($events) eq 'HASH'
            && _json()->encode($events->{$name}) eq $session->{holders}{$name};
    }
    return 1;
}

sub _new_validation {
    my ($owner) = @_;
    return {owner_identity => _id($owner), inputs => {}, whole => {}, holders => {}, records => {}};
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
    my $input = eval {_observe_input(0, %args)};
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
    my $owner = $args{width_support};
    my $outer = !$validation{active} || ($validation{active}{owner_identity} // '') ne (_id($owner) // '');
    local $validation{active} = $outer ? _new_validation($owner) : $validation{active};
    my $frame = eval {
        my $ready = _ready_frame($owner, $args{input}, 0) or return undef;
        return undef if $outer && !_validation_current($owner, $validation{active});
        return $ready;
    };
    return $@ ? undef : $frame;
}

sub _ready_frame {
    my ($owner, $pending, $selected) = @_;
    my $input = _copy($pending);
    return undef unless ref($input) eq 'HASH' && ($input->{kind} // '') eq 'arithmetic_graph_input';
    my $scope = _scope($owner) or return undef;
    my $name = $input->{signal_name};
    my $rows = $scope->{rows};
    my $current = _observe_input($selected, width_support => $owner, signal_name => $name,
        signal_info => $rows->{$name}, signal_registry => $rows, native_signal_info => undef) or return undef;
    return undef unless _json()->encode(_stable_input($input)) eq _json()->encode(_stable_input($current));
    my $proof = _dependencies($owner, $scope, $current->{operands}) or return undef;
    # A later sibling's getter can invalidate an earlier child's source.
    # Compare the complete dependency proof again before publishing a frame.
    my $checked = _dependencies($owner, $scope, $current->{operands}) or return undef;
    return undef unless _json()->encode($proof) eq _json()->encode($checked);
    my $again = _observe_input($selected, width_support => $owner, signal_name => $name,
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
}

=head2 prepare_inference

Re-derive selected graph state from the actual current row view and held child
proofs. The selected parent width must equal the exact dependency maximum.
Return a detached C<{record, state}> capsule with closed
C<arithmetic_graph_operand_max> record: canonical C<operator>, ordered current
C<source_names>, original C<expression_tree> and C<selected_width>. This observer
alone does not attest earlier unresolved input; the resolver must compare its
ready frame through only the actual parent width/source writes before installing.
The detached record uses the shared graph-policy schema; schema validation alone
does not attest this actual earlier inference branch.

=cut

sub prepare_inference {
    my ($class, %args) = @_;
    my $owner = $args{width_support};
    my $outer = !$validation{active} || ($validation{active}{owner_identity} // '') ne (_id($owner) // '');
    local $validation{active} = $outer ? _new_validation($owner) : $validation{active};
    my $holder = eval {
        my $scope = _scope($owner) or return undef;
        my $input = _observe_input(1, %args, signal_registry => $scope->{rows}, native_signal_info => undef)
            or return undef;
        my $frame = _ready_frame($owner, $input, 1) or return undef;
        my $width = FSM::IntermediateWidthAllocationSupport::_width($args{selected_width});
        return undef unless defined($width) && $width eq $frame->{expected_width}
            && defined(FSM::IntermediateWidthAllocationSupport::_width($frame->{signal_info}{width}))
            && FSM::IntermediateWidthAllocationSupport::_width($frame->{signal_info}{width}) eq $width;
        $validation{active}{inputs}{$args{signal_name}} = _json()->encode($input);
        return undef if $outer && !_validation_current($owner, $validation{active});
        return {record => FSM::IntermediateWidthGraphPolicySupport->copy_record(
                {kind => 'arithmetic_graph_operand_max', %{$frame->{shape}},
                    expression_tree => $frame->{graph_birth}{record}{expression_tree}, selected_width => $args{selected_width}}),
            state => _json()->encode($frame)};
    };
    return $@ ? undef : _copy($holder);
}

=head2 current_inference

Return the detached held record only if complete current selected state and
record still equal the installation. Re-entrant dependency cycles withhold.
This validates intrinsic inference rather than completed policy. Unknown row,
view, source, constraint or registry publications cannot refresh the holder.
Child validation is shared only within the current read operation. Before the
outer read returns, every visited graph input and held capsule is checked again,
and whole-reference children re-derive their complete current inference state
without recursive graph getters. This avoids repeated recursive proof work while
rejecting source/row/holder changes behind a temporarily reused child result.
The operation-local plain observations disappear on return or failure.

=cut

my %checking;
sub current_inference {
    my ($class, %args) = @_;
    my $record = eval {
        my $holder = $args{holder};
        return undef unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
            && ref($holder->{record}) eq 'HASH' && defined($holder->{state}) && !ref($holder->{state});
        return undef unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($args{signal_name});
        my $key = (_id($args{width_support}) // '') . '/' . ($args{signal_name} // '');
        return undef if $checking{$key};
        local $checking{$key} = 1;
        my $session = $validation{active};
        $session = undef if $session && ($session->{owner_identity} // '') ne (_id($args{width_support}) // '');
        my $name = $args{signal_name};
        my $cached = $session ? $session->{records}{$name} : undef;
        return _copy($cached->{record}) if $cached
            && ($cached->{identity} // '') eq (_id($args{signal_info}) // '');
        my $current = $class->prepare_inference(%args, selected_width => $holder->{record}{selected_width}) or return undef;
        return undef unless $holder->{state} eq $current->{state}
            && _json()->encode($holder->{record}) eq _json()->encode($current->{record});
        if ($session) {
            $session->{records}{$name} = {identity => _id($args{signal_info}), record => _copy($current->{record})};
            $session->{holders}{$name} = _json()->encode($holder);
        }
        return _copy($current->{record});
    };
    return $@ ? undef : $record;
}

1;
