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

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator);
use Scalar::Util qw(blessed refaddr);
use JSON::PP ();
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _begin_factorized_width_inference ($self) {
    $self->_abort_factorized_width_inference;
    ++$self->{_width_inference_epoch};
}

sub _abort_factorized_width_inference ($self) {
    $self->{_width_inference_events} = {};
    $self->{_source_width_allocation_events} = {};
    $self->{_width_inference_revisions} = {};
    delete $self->{_width_inference_complete};
}

sub _complete_factorized_width_inference ($self, $all_intermediate_signals) {
    return unless $self->{_width_inference_epoch};
    for my $name (keys %{$self->{_width_inference_events}}) {
        delete $self->{_width_inference_events}{$name}
            unless ref($all_intermediate_signals->{$name}) eq 'HASH'
                && $self->factorized_width_inference_event($name, $all_intermediate_signals->{$name});
    }
    for my $name (keys %{$all_intermediate_signals || {}}) {
        my $holder = eval {FSM::IntermediateWidthAllocationSupport->prepare_source_intermediate(
            context => $self->{flattened_dt}, signal_name => $name,
            signal_info => $all_intermediate_signals->{$name}, epoch => $self->{_width_inference_epoch})};
        $self->{_source_width_allocation_events}{$name} = $holder if $holder;
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

=cut

sub resolve_intermediate_signal_width ($self, $signal_name, $signal_info, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return 1 unless defined($signal_name) && $signal_name ne '';

    my $held = $self->{_width_inference_epoch}
        ? $self->_take_current_factorized_inference($signal_name, $signal_info) : undef;
    ++$self->{_width_inference_revisions}{$signal_name} if $self->{_width_inference_epoch};
    my ($input_frame, $intrinsic_inference);

    $signal_registry //= {};
    $seen_signals //= {};
    if ($seen_signals->{$signal_name}++) {
        my $cached_width = ($signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0)
            ? $signal_info->{width}
            : 1;
        fsm_debug("[IntermediateSignalWidthSupport.pm][resolve_intermediate_signal_width()] Detected recursive width lookup for '$signal_name'; using cached width $cached_width", 3);
        return $cached_width;
    }

    my $resolved_width;
    my $width_source = 'default_1bit';

    my $native_signal_info = $ctx->{enable_graph_assignment_support}->get_signal_info($signal_name);
    if ($native_signal_info && $native_signal_info->{width} && $native_signal_info->{width} > 1) {
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
            $input_frame = $self->_unresolved_factorized_input_frame($signal_name, $signal_info, $signal_registry)
                unless $native_signal_info;
            my $ast_width = $self->infer_width_from_intermediate_ast($runtime_ast, $signal_registry, $seen_signals);
            if (defined($ast_width) && $ast_width > 0) {
                $resolved_width = $ast_width;
                $width_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
                $intrinsic_inference = 1;
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

    $self->_record_factorized_inference($signal_name, $signal_info, $resolved_width, $width_source, $input_frame)
        if $intrinsic_inference && !$native_signal_info;

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
