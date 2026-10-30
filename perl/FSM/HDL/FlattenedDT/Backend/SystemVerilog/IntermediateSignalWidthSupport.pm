package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport - Own direct SystemVerilog intermediate-signal width normalization and inference support

=head1 DESCRIPTION

Owns the bounded width family for the older direct generated-module
SystemVerilog backend. This package centralizes:

=over 4

=item *

intermediate width normalization from native signal metadata, runtime ASTs, and
cached width fallbacks

=item *

recursive width inference over substituted intermediate AST shapes, including
referenced intermediate signals

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport>
now owns runtime-AST lookup, rendered-expression recovery, and dependency
recovery, while this package owns the narrower width side of the direct backend
path.

Normalization also binds a weak, epoch/revision-scoped view of its actual rows
for private pending/ready arithmetic graph frames. It retains no registry and
abort clears the association. These diagnostic frames do not install graph
events, completed policies or symbolic range eligibility.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator is_shift_operator);
use Scalar::Util qw(blessed refaddr weaken);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::SourceBitwiseTreeWidthSupport;
use FSM::IntermediateWidthGraphInferenceSupport;
use FSM::ConcatenationGenerationSourceSupport;
use FSM::ConcatenationInferenceSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _begin_factorized_width_inference ($self) {
    $self->_abort_factorized_width_inference;
    ++$self->{_width_inference_epoch};
}

sub _abort_factorized_width_inference ($self) {
    $self->{_width_inference_events} = {};
    $self->{_graph_inference_events} = {};
    $self->{_source_width_allocation_events} = {};
    $self->{_source_bitwise_tree_allocation_events} = {};
    $self->{_width_inference_revisions} = {};
    $self->{_concatenation_source_frames} = {};
    $self->{_concatenation_inference_events} = {};
    delete $self->{_width_inference_complete};
    delete @{$self}{qw(_graph_inference_rows _graph_inference_rows_epoch)};
}

sub _bind_graph_inference_rows ($self, $rows) {
    my $ctx = $self->{flattened_dt};
    return undef unless $self->{_width_inference_epoch} && ref($rows) eq 'HASH'
        && blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
        && ref($ctx->{backend_sv_intermediate_width_support}) eq ref($self)
        && $ctx->{backend_sv_intermediate_width_support} == $self;
    $self->{_graph_inference_rows} = $rows;
    weaken($self->{_graph_inference_rows});
    $self->{_graph_inference_rows_epoch} = $self->{_width_inference_epoch};
    ++$self->{_graph_inference_rows_revision};
    # Freeze original source before normalization's recovery and metadata
    # callbacks. Later lookup may only revalidate these exact observations.
    # A second bind in a spent epoch can invalidate the original view, never
    # refresh source after callbacks. Abort clears holders, not this admission.
    return 1 if ($self->{_concatenation_source_epoch} // 0) == $self->{_width_inference_epoch};
    $self->{_concatenation_source_epoch} = $self->{_width_inference_epoch};
    my %inputs;
    for my $name (sort keys %$rows) {
        next unless ref($rows->{$name}) eq 'HASH'
            && ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
        my $input = FSM::ConcatenationGenerationSourceSupport->prepare_input(
            width_support => $self, signal_name => $name, signal_info => $rows->{$name});
        $inputs{$name} = $input if $input;
    }
    for my $name (sort keys %inputs) {
        my $holder = FSM::ConcatenationGenerationSourceSupport->capture(
            width_support => $self, signal_name => $name, signal_info => $rows->{$name}, input => $inputs{$name});
        $self->{_concatenation_source_frames}{$name} = $holder if $holder;
    }
    return 1;
}

=head2 concatenation_generation_sources

Return only the original current detached concatenation source frame frozen at
actual epoch/view binding before normalization callbacks. Copied/foreign rows,
changed sources, replaced initial registries and expired views withhold. Abort
and reuse clear the installed frames. This source-only observation supplies no
intrinsic event, selected sum, completed policy or symbolic target range.

=cut

sub concatenation_generation_sources ($self, $signal_name, $signal_info) {
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name)
        && ref($self->{_concatenation_source_frames}) eq 'HASH';
    return FSM::ConcatenationGenerationSourceSupport->current(
        width_support => $self, signal_name => $signal_name, signal_info => $signal_info,
        holder => $self->{_concatenation_source_frames}{$signal_name});
}

=head2 concatenation_inference_event

Return the current detached intrinsic concatenation event for the actual row
in the installed weak view. First unresolved typed inference alone mints it;
native/cache/constraint/unknown/stale inputs do not. Original source and complete
row metadata revalidate around callbacks and inference. Repeated reads preserve
only an already current event through their own revision and width/source writes.
Initial allocator/registry publication invalidates this event until the separate
owned carry protocol is installed. Abort/reset/reuse clears all events. Numeric
sum agreement is separate from symbolic range or completed collection policy.

=cut

sub concatenation_inference_event ($self, $signal_name, $signal_info) {
    my $rows = $self->_current_graph_inference_rows or return;
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name)
        && ref($self->{_concatenation_inference_events}) eq 'HASH'
        && exists($self->{_concatenation_inference_events}{$signal_name});
    return FSM::ConcatenationInferenceSupport->current(
        width_support => $self, signal_name => $signal_name, signal_info => $signal_info,
        signal_registry => $rows, holder => $self->{_concatenation_inference_events}{$signal_name});
}

sub _current_graph_inference_rows ($self) {
    my $epoch = FSM::IntermediateWidthAllocationSupport::_width($self->{_width_inference_epoch});
    my $view_epoch = FSM::IntermediateWidthAllocationSupport::_width($self->{_graph_inference_rows_epoch});
    return undef unless defined($epoch) && defined($view_epoch) && $view_epoch eq $epoch
        && defined(FSM::IntermediateWidthAllocationSupport::_width($self->{_graph_inference_rows_revision}))
        && ref($self->{_graph_inference_rows}) eq 'HASH';
    return $self->{_graph_inference_rows};
}

sub _complete_factorized_width_inference ($self, $all_intermediate_signals) {
    return unless $self->{_width_inference_epoch};
    for my $name (keys %{$self->{_width_inference_events}}) {
        delete $self->{_width_inference_events}{$name}
            unless ref($all_intermediate_signals->{$name}) eq 'HASH'
                && $self->factorized_width_inference_event($name, $all_intermediate_signals->{$name});
    }
    for my $name (keys %{$self->{_graph_inference_events}}) {
        delete $self->{_graph_inference_events}{$name}
            unless ref($all_intermediate_signals->{$name}) eq 'HASH'
                && $self->factorized_graph_inference_event($name, $all_intermediate_signals->{$name});
    }
    for my $name (keys %{$all_intermediate_signals || {}}) {
        my $holder = eval {FSM::IntermediateWidthAllocationSupport->prepare_source_intermediate(
            context => $self->{flattened_dt}, signal_name => $name,
            signal_info => $all_intermediate_signals->{$name}, epoch => $self->{_width_inference_epoch})};
        $self->{_source_width_allocation_events}{$name} = $holder if $holder;
        my $tree_holder = eval {FSM::SourceBitwiseTreeWidthSupport->prepare_source_intermediate(
            context => $self->{flattened_dt}, signal_name => $name,
            signal_info => $all_intermediate_signals->{$name}, epoch => $self->{_width_inference_epoch})};
        $self->{_source_bitwise_tree_allocation_events}{$name} = $tree_holder if $tree_holder;
    }
    $self->{_width_inference_complete} = $self->{_width_inference_epoch};
}

=head2 factorized_width_inference_event

Return a detached current intrinsic binary max event for the actual metadata
object in this normalization epoch. Only a current actual factorizer birth,
complete plain unsigned module operands and first unresolved AST inference can
mint it. Native/cached/opaque target constraints, missing/type/stale inputs and
supported source mutation during inference withhold, including equal defaults.
Plain capsules add no mutable owner graph. Ordinary numeric selection preserves.

The actual normalizer width publication and consolidated registry rebuild carry
a still-current event through exact before/after checks. Registry-copy proof is
captured before the owned reset, and binds the exact newly installed row and
merged metadata. Independent floors, stale/copy identities and source mutations
cannot refresh. Later resolver calls preserve only a still-current held event
through their exact revision and width/source writes. Scalar AST re-inference
uses the same check; recursive fallback and unknown writes withhold.

=cut

sub factorized_width_inference_event ($self, $signal_name, $signal_info) {
    return unless $self->{_width_inference_epoch}
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name);
    return FSM::IntermediateWidthAllocationSupport->current_factorized_inference(
        context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info,
        epoch => $self->{_width_inference_epoch}, revision => $self->{_width_inference_revisions}{$signal_name},
        holder => $self->{_width_inference_events}{$signal_name});
}

=head2 factorized_graph_inference_event

Return a detached current C<arithmetic_graph_operand_max> intrinsic event for
the actual row in the current weak view. The actual first unresolved AST branch
must bind original graph ownership and current ordered child proofs, then compare
the ready frame through only its own parent width/source writes. Selected max,
original expression tree and current typed edge names remain separate fields.
The whole-reference event and completed allocation APIs retain their profiles.

Owned resolver cache reads preserve only an already current graph holder through
the exact revision and parent width/source writes; default-one AST re-inference
uses the same contract. Native metadata, independent floors, stale or copied
inputs, cycles and source/view changes withhold. Abort clears graph holders.
The actual normalizer checkpoints current graph proof before its callback and
refreshes only the exact allocator/registered width/source writes. Other fields,
source changes and row replacement withhold; callback failure clears partial
holders through normalizer abort. Transitive child publications preserve only
still-current dependency proof. Registry merge/rebuild checkpoints validate all
graphs before removing any child holder, then bind each actual installed row
identity and complete merged metadata. Graph restoration follows dependencies
after whole-reference child holders and all rows are installed. Equal foreign
copies, copied row-view maps and changed sources/constraints cannot refresh.
The actual prepared block owns C<all_intermediate_signals> through rendering;
its distinct C<filtered_signals> map contains the same row objects. The weak
canonical view remains current while that original map is owned. Explicitly
retaining the actual block extends that lifetime; retaining filtered row values
alone does not retain their containing original map and cannot recreate an
expired view. Ordinary generation releases the view, and generation failure
clears partial holders through the existing orchestrator abort. This is a row
lifetime contract, not a claim about whole-backend ownership cycles. Separate
completed graph policy follows successful collection through its separate getter;
selected graph target publication and symbolic range admission remain separate.

=cut

sub factorized_graph_inference_event ($self, $signal_name, $signal_info) {
    my $events = $self->{_graph_inference_events};
    return undef unless $self->{_width_inference_epoch} && ref($events) eq 'HASH'
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name);
    return FSM::IntermediateWidthGraphInferenceSupport->current_inference(
        width_support => $self, signal_name => $signal_name, signal_info => $signal_info,
        holder => $events->{$signal_name});
}

=head2 factorized_graph_width_allocation

Return a detached current completed graph allocation record only after successful
collection, pruning and final registry publication in the current epoch. The
actual canonical row view and complete current graph proof must still exist.
Before collection completion, held intrinsic events supply no completed policy.
Source/row/constraint changes, expired weak views and new/failed/reset generations
withhold; equal metadata or later numeric widths cannot create or revive proof.
The existing C<intermediate_width_allocation> and whole-reference APIs keep their
profiles. Graph target events and symbolic range admission remain separate.

=cut

sub factorized_graph_width_allocation ($self, $signal_name, $signal_info) {
    return undef unless $self->{_width_inference_complete}
        && $self->{_width_inference_complete} == $self->{_width_inference_epoch};
    return $self->factorized_graph_inference_event($signal_name, $signal_info);
}

=head2 factorized_width_allocation

Return the detached current selected policy only after successful normalization,
pruning and final registry publication in this epoch. Earlier diagnostic events
remain available through C<factorized_width_inference_event> but are incomplete.
New normalization, collection/generation failure and generator reset clear the
policy. Exact cache reads preserve it; equal copied metadata or new constraints
cannot create or revive it. Target-event and symbolic range joins remain separate.

=cut

sub factorized_width_allocation ($self, $signal_name, $signal_info) {
    return unless $self->{_width_inference_complete}
        && $self->{_width_inference_complete} == $self->{_width_inference_epoch};
    return $self->factorized_width_inference_event($signal_name, $signal_info);
}

=head2 intermediate_width_allocation

Return only a completed current backend policy for the actual metadata row.
Successful collection attaches an existing current Core source-helper policy
through exact module/helper/operand/AST/input/registry identity and state proof.
The factorizer branch delegates its existing completed intrinsic policy. Equal
source metadata copies or Core policy alone without owned collection cannot
supply the source attachment. Failure/reset/new epochs clear both plain maps;
ordinary source declaration cache reads preserve still-identical source state.
This lookup supplies no selected-text event or symbolic admission.

=cut

sub intermediate_width_allocation ($self, $signal_name, $signal_info) {
    return unless $self->{_width_inference_complete}
        && $self->{_width_inference_complete} == $self->{_width_inference_epoch}
        && ref($signal_info) eq 'HASH'
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name);
    if (defined($signal_info->{source}) && !ref($signal_info->{source})
            && $signal_info->{source} eq 'fsmgen_parsing') {
        return FSM::IntermediateWidthAllocationSupport->current_source_intermediate(
            context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info,
            epoch => $self->{_width_inference_epoch}, holder => $self->{_source_width_allocation_events}{$signal_name});
    }
    return $self->factorized_width_allocation($signal_name, $signal_info);
}

=head2 source_bitwise_tree_width_allocation

Return only separate completed source bitwise tree intent for the actual collected
row after successful collection by this installed width owner in this epoch.
Cloned, replaced or displaced width owners cannot borrow another owner's capsule.
Actual module/root/all leaves,
AST, registered row, relevant metadata and current Core policy must still agree.
The adapter checks again after source reads; equal copies, foreign contexts,
source changes and private constraints withhold. Returned and stored data retain
no owners. Abort/reset/new generations clear the separate map; ordinary identical
numeric cache reads preserve it. The binary getter retains its closed family.
No selected target origin, frozen relationship or symbolic range is supplied.

=cut

sub source_bitwise_tree_width_allocation ($self, $signal_name, $signal_info) {
    my $context = $self->{flattened_dt};
    return unless blessed($context)
        && (refaddr($context->{backend_sv_intermediate_width_support}) // 0) == refaddr($self);
    return unless $self->{_width_inference_complete}
        && $self->{_width_inference_complete} == $self->{_width_inference_epoch}
        && ref($signal_info) eq 'HASH'
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal_name);
    return FSM::SourceBitwiseTreeWidthSupport->current_source_intermediate(
        context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info,
        epoch => $self->{_width_inference_epoch}, holder => $self->{_source_bitwise_tree_allocation_events}{$signal_name});
}

sub _unresolved_factorized_input_frame ($self, $signal_name, $signal_info, $signal_registry) {
    return unless $self->{_width_inference_epoch} && ref($signal_info) eq 'HASH'
        && !defined($signal_info->{width}) && defined($signal_info->{width_source})
        && !ref($signal_info->{width_source}) && $signal_info->{width_source} eq 'unresolved_factorization_ast'
        && ref($signal_registry) eq 'HASH' && ref($signal_registry->{$signal_name}) eq 'HASH'
        && $signal_registry->{$signal_name} == $signal_info;
    my %args = (context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info,
        epoch => $self->{_width_inference_epoch}, revision => $self->{_width_inference_revisions}{$signal_name});
    my $frame = eval {FSM::IntermediateWidthAllocationSupport->factorized_inference_frame(%args)} or return;
    for my $row ($frame->{factorizer_entry}, $frame->{registered}) {
        next unless $row;
        return if defined($row->{width})
            || (defined($row->{width_source}) && $row->{width_source} ne 'unresolved_factorization_ast');
    }
    return eval {FSM::IntermediateWidthAllocationSupport->factorized_inference_frame(%args, track => 1)};
}

sub _record_factorized_inference ($self, $signal_name, $signal_info, $width, $source, $frame) {
    return unless $frame;
    my $holder = eval {FSM::IntermediateWidthAllocationSupport->prepare_factorized_inference(
        context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info, selected_width => $width,
        epoch => $self->{_width_inference_epoch}, revision => $self->{_width_inference_revisions}{$signal_name})} or return;
    my $identity = $frame->{signal_info}{identity};
    for my $row ($frame->{signal_info}, $frame->{factorizer_entry}, $frame->{registered}) {
        next unless $row && $row->{identity} eq $identity;
        $row->{width} = $width;
        $row->{width_source} = $source;
    }
    $self->{_width_inference_events}{$signal_name} = $holder
        if JSON::PP->new->canonical->encode($frame) eq $holder->{state};
}

sub _take_current_factorized_inference ($self, $signal_name, $signal_info) {
    my $record = $self->factorized_width_inference_event($signal_name, $signal_info);
    my $holder = delete $self->{_width_inference_events}{$signal_name};
    return unless $record;
    return JSON::PP->new->decode(JSON::PP->new->encode($holder));
}

sub _restore_factorized_inference ($self, $signal_name, $signal_info, $holder, $expected) {
    return unless $holder;
    my $current = eval {FSM::IntermediateWidthAllocationSupport->prepare_factorized_inference(
        context => $self->{flattened_dt}, signal_name => $signal_name, signal_info => $signal_info,
        selected_width => $holder->{record}{selected_width}, epoch => $self->{_width_inference_epoch},
        revision => $self->{_width_inference_revisions}{$signal_name})} or return;
    my $json = JSON::PP->new->canonical;
    return unless $json->encode($expected) eq $current->{state}
        && $json->encode($holder->{record}) eq $json->encode($current->{record});
    $self->{_width_inference_events}{$signal_name} = $current;
}

sub _with_factorized_width_publication ($self, $signal_name, $signal_info, $publish) {
    my $graph_holder = $self->_take_current_graph_inference($signal_name, $signal_info);
    my $graph_expected = $graph_holder ? JSON::PP->new->decode($graph_holder->{state}) : undef;
    if ($graph_expected) {
        for my $row ($graph_expected->{registered}, $graph_expected->{factorizer_entry}) {
            next unless $row;
            $row->{width} = $signal_info->{width};
            $row->{width_source} = $signal_info->{width_source};
        }
    }
    my $holder = $self->_take_current_factorized_inference($signal_name, $signal_info);
    my $expected = $holder ? JSON::PP->new->decode($holder->{state}) : undef;
    if ($expected) {
        for my $row ($expected->{registered}, $expected->{factorizer_entry}) {
            next unless $row;
            $row->{width} = $signal_info->{width};
            $row->{width_source} = $signal_info->{width_source};
        }
    }
    $publish->();
    $self->_restore_factorized_inference($signal_name, $signal_info, $holder, $expected);
    $self->_restore_graph_inference_state($signal_name, $signal_info, $graph_holder, $graph_expected);
}

sub _checkpoint_factorized_registry_copies ($self, $all_intermediate_signals, $replace_registry = 0) {
    my %checkpoints;
    for my $name (keys %{$all_intermediate_signals || {}}) {
        my $info = $all_intermediate_signals->{$name};
        my $holder = $self->_take_current_factorized_inference($name, $info) or next;
        my $copy = eval {FSM::IntermediateWidthAllocationSupport->factorized_registry_copy_state(
            $info, $replace_registry ? undef : $self->{flattened_dt}{intermediate_signals}{$name})} or next;
        $checkpoints{$name} = {holder => $holder, copy => $copy};
    }
    return \%checkpoints;
}

sub _finish_factorized_registry_copy ($self, $name, $info, $checkpoint, $replacement) {
    return unless $checkpoint && ref($replacement) eq 'HASH'
        && ref($self->{flattened_dt}{intermediate_signals}{$name}) eq 'HASH'
        && $self->{flattened_dt}{intermediate_signals}{$name} == $replacement;
    my $expected = JSON::PP->new->decode($checkpoint->{holder}{state});
    $expected->{registered} = {%{$checkpoint->{copy}}, identity => sprintf('%x', refaddr($replacement))};
    $self->_restore_factorized_inference($name, $info, $checkpoint->{holder}, $expected);
}

sub _checkpoint_graph_registry_copies ($self, $rows, $replace_registry = 0) {
    return {} unless $self->{_width_inference_epoch};
    my $view = $self->_current_graph_inference_rows;
    my %checkpoints;
    if (ref($rows) eq 'HASH' && ref($view) eq 'HASH' && $rows == $view) {
        # Validate every graph while its child holders are still installed.
        # Taking a child first would invalidate its parent before checkpointing.
        for my $name (sort keys %$rows) {
            my $record = $self->factorized_graph_inference_event($name, $rows->{$name}) or next;
            my $copy = eval {FSM::IntermediateWidthAllocationSupport->factorized_registry_copy_state(
                $rows->{$name}, $replace_registry ? undef : $self->{flattened_dt}{intermediate_signals}{$name})}
                or next;
            my $holder = $self->{_graph_inference_events}{$name};
            $checkpoints{$name} = {holder => JSON::PP->new->decode(JSON::PP->new->encode($holder)), copy => $copy};
        }
    }
    $self->{_graph_inference_events} = {};
    return \%checkpoints;
}

sub _finish_graph_registry_copies ($self, $rows, $checkpoints, $installed_ids) {
    return unless ref($rows) eq 'HASH' && ref($checkpoints) eq 'HASH' && ref($installed_ids) eq 'HASH';
    my %pending = %$checkpoints;
    my $json = JSON::PP->new;
    while (%pending) {
        my $progress;
        for my $name (sort keys %pending) {
            my $checkpoint = $pending{$name};
            my $expected = $json->decode($checkpoint->{holder}{state});
            my @graph_children = map {$_->{source_name}} grep {
                $_->{kind} eq 'intermediate' && $_->{proof}{record}{kind} eq 'arithmetic_graph_operand_max'
            } @{$expected->{dependencies}};
            next if grep {exists($pending{$_})} @graph_children;
            delete $pending{$name};
            $progress = 1;
            my $replacement = $self->{flattened_dt}{intermediate_signals}{$name};
            next unless ref($replacement) eq 'HASH' && defined($installed_ids->{$name})
                && !ref($installed_ids->{$name}) && $installed_ids->{$name} eq sprintf('%x', refaddr($replacement));
            $expected->{registered} = {%{$checkpoint->{copy}}, identity => $installed_ids->{$name}};
            $self->_restore_graph_inference_state($name, $rows->{$name}, $checkpoint->{holder}, $expected);
        }
        last unless $progress; # Cyclic or unsupported checkpoints install nothing.
    }
}

sub _record_graph_inference ($self, $name, $info, $width, $source, $ready) {
    return unless $ready;
    my $holder = FSM::IntermediateWidthGraphInferenceSupport->prepare_inference(
        width_support => $self, signal_name => $name, signal_info => $info, selected_width => $width) or return;
    my $expected = JSON::PP->new->decode(JSON::PP->new->encode($ready));
    my $identity = $expected->{signal_info}{identity};
    for my $row ($expected->{signal_info}, $expected->{factorizer_entry}, $expected->{registered}) {
        next unless $row && $row->{identity} eq $identity;
        $row->{width} = $width;
        $row->{width_source} = $source;
    }
    $self->{_graph_inference_events}{$name} = $holder
        if JSON::PP->new->canonical->encode($expected) eq $holder->{state};
}

sub _take_current_graph_inference ($self, $name, $info) {
    my $record = $self->factorized_graph_inference_event($name, $info);
    my $holder = delete $self->{_graph_inference_events}{$name};
    return undef unless $record;
    return JSON::PP->new->decode(JSON::PP->new->encode($holder));
}

sub _restore_graph_inference ($self, $name, $info, $holder, $width, $source) {
    return unless $holder;
    my $expected = JSON::PP->new->decode($holder->{state});
    $expected->{revision} = $self->{_width_inference_revisions}{$name};
    my $identity = $expected->{signal_info}{identity};
    for my $row ($expected->{signal_info}, $expected->{factorizer_entry}, $expected->{registered}) {
        next unless $row && $row->{identity} eq $identity;
        $row->{width} = $width;
        $row->{width_source} = $source;
    }
    $self->_restore_graph_inference_state($name, $info, $holder, $expected);
}

sub _restore_graph_inference_state ($self, $name, $info, $holder, $expected) {
    return unless $holder && $expected;
    my $current = FSM::IntermediateWidthGraphInferenceSupport->prepare_inference(
        width_support => $self, signal_name => $name, signal_info => $info,
        selected_width => $holder->{record}{selected_width}) or return;
    my $json = JSON::PP->new->canonical;
    $self->{_graph_inference_events}{$name} = $current
        if $json->encode($expected) eq $current->{state}
            && $json->encode($holder->{record}) eq $json->encode($current->{record});
}

=head2 new

Construct one intermediate-signal width owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalWidthSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 resolve_intermediate_signal_width

Normalize one intermediate signal width from native signal metadata, runtime
AST inference, or cached width fallback.
The recursion guard covers only active calls. Repeated sibling references to the
same computed child are ordinary cache/re-inference reads and preserve current
allocation proof; an actual active cycle still takes the conservative fallback.

=cut

sub resolve_intermediate_signal_width ($self, $signal_name, $signal_info, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return 1 unless defined($signal_name) && $signal_name ne '';

    my $held = $self->{_width_inference_epoch}
        ? $self->_take_current_factorized_inference($signal_name, $signal_info) : undef;
    my $graph_held = $self->{_width_inference_epoch}
        ? $self->_take_current_graph_inference($signal_name, $signal_info) : undef;
    my $concat_held;
    if ($self->{_width_inference_epoch}) {
        my $record = $self->concatenation_inference_event($signal_name, $signal_info);
        my $holder = delete $self->{_concatenation_inference_events}{$signal_name};
        $concat_held = JSON::PP->new->decode(JSON::PP->new->encode($holder)) if $record;
    }
    ++$self->{_width_inference_revisions}{$signal_name} if $self->{_width_inference_epoch};
    my ($input_frame, $graph_input, $graph_ready, $intrinsic_inference);

    $signal_registry //= {};
    $seen_signals //= {};
    if ($seen_signals->{$signal_name}) {
        my $cached_width = ($signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0)
            ? $signal_info->{width}
            : 1;
        fsm_debug("[IntermediateSignalWidthSupport.pm][resolve_intermediate_signal_width()] Detected recursive width lookup for '$signal_name'; using cached width $cached_width", 3);
        return $cached_width;
    }
    local $seen_signals->{$signal_name} = 1;

    # Bind original sources and row state before native metadata or recovery.
    # A repeat may carry only held authority, with this exact owned increment.
    my %concat_args = (width_support => $self, signal_name => $signal_name,
        signal_info => $signal_info, signal_registry => $signal_registry);
    my $concat_input = FSM::ConcatenationInferenceSupport->prepare_input(%concat_args);
    my $concat_ready;
    if ($concat_held) {
        $concat_held->{frame}{state}{revision} =
            FSM::IntermediateWidthAllocationSupport::_width($self->{_width_inference_revisions}{$signal_name});
    }

    my $resolved_width;
    my $width_source = 'default_1bit';

    my $native_signal_info = $ctx->{enable_graph_assignment_support}->get_signal_info($signal_name);
    my $literal = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
        ->prepare_inference(width_support => $self, signal_name => $signal_name,
            signal_info => $signal_info, signal_registry => $signal_registry);
    if ($literal) {
        $resolved_width = $literal->{observation}{selected_width};
        $width_source = 'source_literal_intent';
    }
    if (!defined($resolved_width) && $native_signal_info && $native_signal_info->{width} && $native_signal_info->{width} > 1) {
        $resolved_width = $native_signal_info->{width};
        $width_source = 'native_signal_metadata';
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 1) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    if (!defined($resolved_width) || $resolved_width < 1) {
        my $runtime_ast = $ctx->{backend_sv_intermediate_recovery_support}->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            my $concat_branch = FSM::ConcatenationInferenceSupport->current_input(
                %concat_args, input => $concat_input, runtime_ast => $runtime_ast,
                native_signal_info => $native_signal_info);
            $input_frame = $self->_unresolved_factorized_input_frame($signal_name, $signal_info, $signal_registry)
                unless $native_signal_info;
            $graph_input = FSM::IntermediateWidthGraphInferenceSupport->prepare_input(
                width_support => $self, signal_name => $signal_name, signal_info => $signal_info,
                signal_registry => $signal_registry, native_signal_info => undef, track => 1)
                unless $native_signal_info;
            my $ast_width = $self->infer_width_from_intermediate_ast($runtime_ast, $signal_registry, $seen_signals);
            if (defined($ast_width) && $ast_width > 0) {
                $resolved_width = $ast_width;
                $width_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
                $intrinsic_inference = 1;
                $concat_ready = FSM::ConcatenationInferenceSupport->current_input(
                    %concat_args, input => $concat_branch, runtime_ast => $runtime_ast,
                    native_signal_info => $native_signal_info)
                    if $concat_branch;
                $graph_ready = FSM::IntermediateWidthGraphInferenceSupport->prepare_frame(
                    width_support => $self, input => $graph_input) if $graph_input;
            }
        }
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    $resolved_width = 1 unless defined($resolved_width) && $resolved_width > 0;
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{width} = $resolved_width;
        $signal_info->{width_source} = $width_source;
    }

    if (!defined($native_signal_info) && ($concat_ready || $concat_held)) {
        my $event = FSM::ConcatenationInferenceSupport->after_write(
            %concat_args, input => $concat_ready || $concat_held->{frame},
            selected_width => $resolved_width, selected_source => $width_source);
        $self->{_concatenation_inference_events}{$signal_name} = $event if $event;
    }

    $self->_record_factorized_inference($signal_name, $signal_info, $resolved_width, $width_source, $input_frame)
        if $intrinsic_inference && !$native_signal_info;
    $self->_record_graph_inference($signal_name, $signal_info, $resolved_width, $width_source, $graph_ready)
        if $intrinsic_inference && !$native_signal_info;
    $self->_restore_graph_inference($signal_name, $signal_info, $graph_held, $resolved_width, $width_source)
        if $graph_held && !$native_signal_info;

    if ($held && !$native_signal_info) {
        my $expected = JSON::PP->new->decode($held->{state});
        $expected->{revision} = $self->{_width_inference_revisions}{$signal_name};
        my $identity = $expected->{signal_info}{identity};
        for my $row ($expected->{signal_info}, $expected->{factorizer_entry}, $expected->{registered}) {
            next unless $row && $row->{identity} eq $identity;
            $row->{width} = $resolved_width;
            $row->{width_source} = $width_source;
        }
        $self->_restore_factorized_inference($signal_name, $signal_info, $held, $expected);
    }

    fsm_debug("[IntermediateSignalWidthSupport.pm][resolve_intermediate_signal_width()] Resolved width $resolved_width for '$signal_name' via $width_source", 3);
    return $resolved_width;
}

=head2 infer_width_from_intermediate_ast

Infer one intermediate expression width recursively from the substituted AST
shape, including referenced intermediate signals.
Runtime and substituted binary shifts use the left operand's inferred width,
with the existing conservative fallback when that width is unavailable. The
amount has an independent width and is not used to widen the result. This
numeric rule establishes no generic range or source-allocation provenance.

=cut

sub infer_width_from_intermediate_ast ($self, $ast, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return undef unless $ast && blessed($ast);

    $signal_registry //= {};
    $seen_signals //= {};

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $referenced_signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        if (defined($referenced_signal_name) && $referenced_signal_name ne '') {
            my $referenced_signal_info = $signal_registry->{$referenced_signal_name}
                || ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}
                    ? $ctx->{ast_factorizer}->{intermediate_signals}->{$referenced_signal_name}
                    : undef);
            return $self->resolve_intermediate_signal_width($referenced_signal_name, $referenced_signal_info, $signal_registry, $seen_signals);
        }
        return 1;
    }

    if ($ast->isa('FSM::AST::SignalRef')) {
        my $referenced_signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        return $self->resolve_ast_signal_ref_width($referenced_signal_name, $signal_registry, $seen_signals);
    }

    if ($ast->isa('FSM::AST::Literal')) {
        my $value = eval { $ast->value };
        my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($value);
        return $parts->{width} if $parts && defined($parts->{width}) && $parts->{width} > 0;
        return 1 if defined($value) && $value =~ /\A1'b[01]\z/i;
        return 32;
    }

    if ($ast->isa('FSM::AST::UnaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator eq '!' || is_reduction_operator($operator);
        my $operand = eval { $ast->operand } || $ast->{operand};
        my $operand_width = $self->infer_width_from_intermediate_ast($operand, $signal_registry, $seen_signals);
        return (defined($operand_width) && $operand_width > 0) ? $operand_width : 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator =~ /^(==|!=|<|>|<=|>=|&&|\|\|)$/;

        my $left = eval { $ast->left } || $ast->{left};
        my $right = eval { $ast->right } || $ast->{right};
        my $left_width = $self->infer_width_from_intermediate_ast($left, $signal_registry, $seen_signals);
        return (defined($left_width) && $left_width > 0) ? $left_width : 1
            if is_shift_operator($operator);
        my $right_width = $self->infer_width_from_intermediate_ast($right, $signal_registry, $seen_signals);

        $left_width = 1 unless defined($left_width) && $left_width > 0;
        $right_width = 1 unless defined($right_width) && $right_width > 0;
        return $left_width > $right_width ? $left_width : $right_width;
    }

    if ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator eq '!' || is_reduction_operator($operator);
        my $operand = eval { $ast->operand } || $ast->{operand};
        my $operand_width = $self->infer_width_from_intermediate_ast($operand, $signal_registry, $seen_signals);
        return (defined($operand_width) && $operand_width > 0) ? $operand_width : 1;
    }

    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator =~ /^(==|!=|<|>|<=|>=|&&|\|\|)$/;

        my $left = eval { $ast->left } || $ast->{left};
        my $right = eval { $ast->right } || $ast->{right};
        my $left_width = $self->infer_width_from_intermediate_ast($left, $signal_registry, $seen_signals);
        return (defined($left_width) && $left_width > 0) ? $left_width : 1
            if is_shift_operator($operator);
        my $right_width = $self->infer_width_from_intermediate_ast($right, $signal_registry, $seen_signals);

        $left_width = 1 unless defined($left_width) && $left_width > 0;
        $right_width = 1 unless defined($right_width) && $right_width > 0;
        return $left_width > $right_width ? $left_width : $right_width;
    }

    my $width = eval { $ctx->{expr_namer}->infer_ast_width($ast) };
    return $width if defined($width) && $width > 0;

    return undef;
}

sub resolve_ast_signal_ref_width ($self, $signal_name, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return 1 unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals->{$signal_name}) {
        my $signal = $ctx->{fsm_module}->signals->{$signal_name};
        if (ref($signal_registry) eq 'HASH' && ref($signal_registry->{$signal_name}) eq 'HASH') {
            my $literal = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
                ->prepare_inference(width_support => $self, signal_name => $signal_name,
                    signal_info => $signal_registry->{$signal_name}, signal_registry => $signal_registry);
            return $literal->{observation}{selected_width} if $literal;
        }
        my $width = eval { $signal->width };
        return $width if defined($width) && $width > 0;
    }

    if ($ctx->{assignment_analysis} && $ctx->{assignment_analysis}{$signal_name}) {
        my $width = eval {
            $ctx->{enable_graph_assignment_support}->get_lhs_width_from_analysis(
                $ctx->{assignment_analysis}{$signal_name},
            );
        };
        return $width if defined($width) && $width > 0;
    }

    if ($signal_registry && $signal_registry->{$signal_name}) {
        return $self->resolve_intermediate_signal_width(
            $signal_name,
            $signal_registry->{$signal_name},
            $signal_registry,
            $seen_signals,
        );
    }

    return 1;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal width owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 resolve_intermediate_signal_width

Normalizes one intermediate signal width from native signal metadata, runtime
AST inference, or cached width fallback.

=head2 infer_width_from_intermediate_ast

Infers one intermediate expression width recursively from the substituted AST
shape, including referenced intermediate signals.

=cut
