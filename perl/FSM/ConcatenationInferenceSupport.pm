package FSM::ConcatenationInferenceSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(refaddr);
use FSM::ConcatenationGenerationSourceSupport;
use FSM::ConcatenationSourceObservationSupport;
use FSM::IntermediateWidthAllocationSupport;

sub _json { JSON::PP->new->canonical }
sub _copy { _json()->decode(_json()->encode($_[0])) }
sub _same { FSM::ConcatenationSourceObservationSupport::_same_record(@_) }

# Preserve the complete bounded row, including unknown plain metadata. Only
# built-in AST fields are replaced by identity tokens; no caller getters run.
sub _row {
    my ($row, $ast) = @_;
    return unless ref($row) eq 'HASH' && !tied(%$row)
        && !defined($row->{state_model});
    my %data = %$row;
    for my $field (qw(ast runtime_ast defining_ast driving_ast)) {
        next unless exists $data{$field};
        return unless ref($row->{$field}) eq 'FSM::CoreAST::Concatenation' && $row->{$field} == $ast;
        $data{$field} = ref($row->{$field}) . ':' . sprintf('%x', refaddr($row->{$field}));
    }
    my $walk = {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}, containers => []};
    # The temporary projection's identity is irrelevant; nested original
    # containers remain identity-bound, including equal-state replacements.
    my $data = FSM::ConcatenationSourceObservationSupport::_plain(\%data, $walk, 0);
    return unless FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast);
    shift @{$walk->{containers}};
    return {data => $data, containers => $walk->{containers}};
}

sub _raw {
    my (%args) = @_;
    my $owner = $args{width_support};
    my $binding = FSM::ConcatenationGenerationSourceSupport::_binding(%args) or return;
    my $rows = $owner->_current_graph_inference_rows;
    return unless ref($args{signal_registry}) eq 'HASH' && $args{signal_registry} == $rows;
    my $revision = FSM::IntermediateWidthAllocationSupport::_width(
        $owner->{_width_inference_revisions}{$args{signal_name}}) or return;
    my $ctx = $owner->{flattened_dt};
    my $name = $args{signal_name};
    return if exists $ctx->{fsm_module}{signals}{$name};
    my $row = $args{signal_info};
    return unless ref($row->{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
        && ($row->{runtime_ast_source} // '') eq 'substituted_ast'
        && ($row->{runtime_ast_resolution_state} // '') eq 'resolved';
    my %state;
    for my $pair ([row => $row], [allocator => $ctx->{ast_factorizer}{intermediate_signals}{$name}],
        [registered => $ctx->{intermediate_signals}{$name}]) {
        $state{$pair->[0]} = _row($pair->[1], $row->{ast}) or return;
    }
    return {binding => $binding, revision => $revision, %state};
}

sub _observe {
    my (%args) = @_;
    my $before = _raw(%args) or return;
    my $sources = $args{width_support}->concatenation_generation_sources(
        @args{qw(signal_name signal_info)}) or return;
    my $after = _raw(%args) or return;
    return unless _same($before, $after);
    return {state => $after, sources => $sources};
}

# This is numeric agreement for the selected observation only. Independent
# canonical operand ranges remain separate; no symbolic sum is proved here.
sub _sum {
    my ($tree, $widths) = @_;
    return Math::BigInt->new($widths->{$tree->[1]}) if $tree->[0] eq 'signal';
    if ($tree->[0] eq 'literal') {
        my $width = FSM::IntermediateWidthAllocationSupport::_width($tree->[1]{width}) or return;
        return Math::BigInt->new($width);
    }
    my $sum = Math::BigInt->new(0);
    for my $child (@$tree[1 .. $#$tree]) {
        my $width = _sum($child, $widths) or return;
        $sum->badd($width);
    }
    return $sum;
}

sub _record {
    my ($frame, $selected) = @_;
    my $width = FSM::IntermediateWidthAllocationSupport::_width($selected) or return;
    my $source = $frame->{sources}{sources}{record};
    my %widths = map {$_->{name} => $_->{width}} @{$source->{operands}};
    my $sum = _sum($source->{expression_tree}, \%widths) or return;
    return unless $sum->bstr eq $width;
    return {kind => 'concatenation_sum_inference', selected_width => $selected, source_contract => $source};
}

sub prepare_input {
    my ($class, %args) = @_;
    my $frame = eval {
        my $raw = _raw(%args) or return;
        return unless $raw->{revision} eq '1';
        for my $field (qw(row allocator registered)) {
            my $data = $raw->{$field}{data};
            return if defined($data->{width}) || ($data->{width_source} // '') ne 'unresolved_factorization_ast';
        }
        my $frame = _observe(%args) or return;
        return unless _same($raw, $frame->{state});
        return $frame;
    };
    return $@ ? undef : $frame;
}

sub current_input {
    my ($class, %args) = @_;
    my $frame = eval {
        return unless exists($args{native_signal_info}) && !defined($args{native_signal_info});
        my $current = $class->prepare_input(%args) or return;
        # The callback's returned AST is what the resolver actually infers.
        # Stored row identity alone cannot attest that local return value.
        return unless ref($args{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
            && $args{runtime_ast} == $args{signal_info}{runtime_ast};
        return unless _same($args{input}, $current);
        return $current;
    };
    return $@ ? undef : $frame;
}

# A caller can observe state; only the actual resolver installs the resulting
# event after it has executed intrinsic inference and checked current_input.
sub after_write {
    my ($class, %args) = @_;
    my $holder = eval {
        my $current = _observe(%args) or return;
        my $input = $args{input};
        for my $key (qw(state row data)) {
            return unless ref($input) eq 'HASH' && !tied(%$input);
            $input = $input->{$key};
        }
        return unless ref($input) eq 'HASH' && !tied(%$input);
        my $before = _copy($current);
        for my $field (qw(width width_source)) {
            return if ref($input->{$field}) || (defined($input->{$field})
                && length($input->{$field}) > FSM::CoreExpressionWidthSupport::MAX_NODES());
            $before->{state}{row}{data}{$field} = $input->{$field};
        }
        # Compare against the bounded current shape, never serialize an
        # untrusted caller capsule or follow its arbitrary extra containers.
        return unless _same($args{input}, $before)
            && _same($args{selected_width}, $current->{state}{row}{data}{width})
            && _same($args{selected_source}, $current->{state}{row}{data}{width_source});
        my $record = _record($current, $args{selected_width}) or return;
        return {record => $record, frame => $current};
    };
    return $@ ? undef : $holder;
}

sub current {
    my ($class, %args) = @_;
    my $record = eval {
        my $current = _observe(%args) or return;
        my $record = _record($current, $args{signal_info}{width}) or return;
        return unless _same($args{holder}, {record => $record, frame => $current});
        return _copy($record);
    };
    return $@ ? undef : $record;
}

# Predict only the actual normalizer's two scalar writes to each existing
# allocator/registered row. Everything else, including nested container and
# original source identities, must still match after the callback returns.
sub publication_checkpoint {
    my ($class, %args) = @_;
    my $checkpoint = eval {
        my $frame = _observe(%args) or return;
        my $record = _record($frame, $args{signal_info}{width}) or return;
        return unless _same($args{holder}, {record => $record, frame => $frame});
        for my $target (qw(allocator registered)) {
            for my $field (qw(width width_source)) {
                $frame->{state}{$target}{data}{$field} = $frame->{state}{row}{data}{$field};
            }
        }
        return {record => $record, frame => $frame};
    };
    return $@ ? undef : $checkpoint;
}

1;

=head1 NAME

FSM::ConcatenationInferenceSupport - Private current intrinsic concatenation events

=head1 DESCRIPTION

The actual installed width resolver freezes a complete bounded row/allocator/
initial-registry observation before its metadata callbacks, using the original
generation source freeze. Only first-revision unresolved typed inference with
no native metadata can mint an installed C<concatenation_sum_inference> event.
Before and after inference the same input must remain current; only the actual
resolver's subsequent row width/source writes may change it. Complete plain row
metadata and nested container identities are bound. Unsupported objects, types,
constraints, foreign or replaced rows, expired views and unknown literal widths
withhold without changing ordinary numeric resolution.

The detached record contains C<kind>, the independently selected numeric
C<selected_width> and the ordered canonical C<source_contract>. Repeated/nested
slots and explicit literal widths preserve. Numeric sum agreement supplies no
generic sum-range or emission authority. Later resolver reads can carry only an
already current installed event through their own revision and width/source
writes. Exact normalizer width publication also carries held events through
C<publication_checkpoint>; later annotations and registry replacement invalidate
until their separate carry protocols qualify. Completed policy remains separate.
Abort/reset/new generations clear installed events. Plain holders retain no
caller graph. The original raw observation's restored-scalar-write limitation
still applies.

=head1 METHODS

=head2 prepare_input(width_support => OWNER, signal_name => NAME, signal_info => ROW, signal_registry => ROWS)

Observe first-revision unresolved inputs before resolver callbacks, or undef.

=head2 current_input(..., input => INPUT, runtime_ast => ACTUAL_RETURN, native_signal_info => undef)

Revalidate the same original input at and after the intrinsic branch, or undef.
Defined native metadata, including an empty record, cannot qualify.
The actual recovery return that is passed to inference must be the original
built-in concatenation AST, even when a foreign return has the same numeric sum.

=head2 after_write(..., input => INPUT, selected_width => WIDTH, selected_source => SOURCE)

Compare the original input through only resolver revision and row width/source
writes. Return a detached holder; this observer alone attests no branch execution.

=head2 current(..., holder => HOLDER)

Return the detached record only while the entire current holder still agrees.
Malformed or unsupported observations return undef without installing state.

=head2 publication_checkpoint(..., holder => HOLDER)

Validate a held current intrinsic event before the actual normalizer publication,
then predict only the existing allocator and registered row C<width> and
C<width_source> assignments from the unchanged merged row. The installed owner
removes the event before this check and withholds it while the callback runs.
Only a successful callback followed by C<current> against this exact checkpoint
can restore it. Complete remaining metadata, nested container identities,
original source contracts, rows, registry map, epoch and revision must preserve;
unrelated or late getter changes cannot refresh. Exceptions propagate from the
actual callback with the event already removed. This observer installs nothing
and grants no completed policy. Later normalization annotations and registry
replacement remain separate, unqualified transitions.

=cut
