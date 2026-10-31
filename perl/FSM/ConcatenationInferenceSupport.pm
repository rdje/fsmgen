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
use FSM::Support::HDLInstanceIdentifierPolicy;

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
    my $sources = exists($args{source_holder})
        ? FSM::ConcatenationGenerationSourceSupport->current(%args, holder => $args{source_holder})
        : $args{width_support}->concatenation_generation_sources(@args{qw(signal_name signal_info)});
    return unless $sources;
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

sub render_input {
    my ($class, %args) = @_;
    my $input = eval {
        my $frame = _observe(%args) or return;
        return unless ref($args{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
            && $args{runtime_ast} == $args{signal_info}{runtime_ast};
        my $record = _record($frame, $args{signal_info}{width}) or return;
        my $input = {record => $record, frame => $frame};
        return unless _same($args{holder}, $input);
        return $input;
    };
    return $@ ? undef : $input;
}

sub after_render {
    my ($class, %args) = @_;
    my $holder = eval {
        my $frame = _observe(%args) or return;
        return unless ref($args{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
            && $args{runtime_ast} == $args{signal_info}{runtime_ast}
            && !ref($args{selected_expression});
        my $record = _record($frame, $args{signal_info}{width}) or return;
        my $input_row = $args{input};
        for my $key (qw(frame state row data)) {
            return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
            $input_row = $input_row->{$key};
        }
        return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
        my $before = {record => $record, frame => _copy($frame)};
        for my $field (qw(rendered_expression rendered_expression_source)) {
            if (exists $input_row->{$field}) {
                return if ref($input_row->{$field}) || (defined($input_row->{$field})
                    && length($input_row->{$field}) > FSM::CoreExpressionWidthSupport::MAX_NODES());
                $before->{frame}{state}{row}{data}{$field} = $input_row->{$field};
            } else {
                delete $before->{frame}{state}{row}{data}{$field};
            }
        }
        return unless _same($args{input}, $before)
            && _same($args{selected_expression}, $frame->{state}{row}{data}{rendered_expression})
            && _same($input_row->{runtime_ast_source}, $frame->{state}{row}{data}{rendered_expression_source});
        return {record => $record, frame => $frame};
    };
    return $@ ? undef : $holder;
}

# Extraction may publish only the selected narrow fallback tag before the
# final array/source assignments. Validate that transition before those writes
# can overwrite evidence of a callback mutation.
sub dependency_checkpoint {
    my ($class, %args) = @_;
    my $checkpoint = eval {
        my $frame = _observe(%args) or return;
        return unless ref($args{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
            && $args{runtime_ast} == $args{signal_info}{runtime_ast};
        my $record = _record($frame, $args{signal_info}{width}) or return;
        my $input_row = $args{input};
        for my $key (qw(frame state row data)) {
            return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
            $input_row = $input_row->{$key};
        }
        return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
        my $fallback = $args{selected_fallback};
        return if ref($fallback) || (defined($fallback) && $fallback ne 'rendered_expression_fallback');
        my $current_row = $frame->{state}{row}{data};
        if (defined($fallback)) {
            return unless exists($current_row->{dependency_fallback_source})
                && _same($fallback, $current_row->{dependency_fallback_source});
        } else {
            return if exists $current_row->{dependency_fallback_source};
        }
        my $before = {record => $record, frame => _copy($frame)};
        my $field = 'dependency_fallback_source';
        if (exists $input_row->{$field}) {
            return if ref($input_row->{$field}) || (defined($input_row->{$field})
                && length($input_row->{$field}) > FSM::CoreExpressionWidthSupport::MAX_NODES());
            $before->{frame}{state}{row}{data}{$field} = $input_row->{$field};
        } else {
            delete $before->{frame}{state}{row}{data}{$field};
        }
        return unless _same($args{input}, $before)
            && _same($args{selected_source}, $input_row->{runtime_ast_source}
                . (defined($fallback) ? '+' . $fallback : ''));
        return {record => $record, frame => $frame};
    };
    return $@ ? undef : $checkpoint;
}

sub after_dependencies {
    my ($class, %args) = @_;
    my $holder = eval {
        my $array = $args{published_array};
        return unless ref($array) eq 'ARRAY' && !tied(@$array)
            && ref($args{selected_names}) eq 'ARRAY' && !tied(@{$args{selected_names}});
        my $frame = _observe(%args) or return;
        return unless ref($args{signal_info}{dependency_signal_names}) eq 'ARRAY'
            && $args{signal_info}{dependency_signal_names} == $array;
        my $record = _record($frame, $args{signal_info}{width}) or return;
        my $input_row = $args{input};
        for my $key (qw(frame state row data)) {
            return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
            $input_row = $input_row->{$key};
        }
        return unless ref($input_row) eq 'HASH' && !tied(%$input_row);
        my $before = {record => $record, frame => _copy($frame)};
        my $row = $before->{frame}{state}{row};
        return unless _same($args{selected_names}, $row->{data}{dependency_signal_names})
            && _same($args{selected_source}, $row->{data}{dependency_source});
        for my $name (@{$row->{data}{dependency_signal_names}}) {
            return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
        }
        # The real assignment creates one new flat array. Preserve every other
        # nested identity, and reject aliases or reuse of an original row container.
        my $token = ['ARRAY', sprintf('%x', refaddr($array))];
        my $removed = 0;
        my @containers;
        for my $container (@{$row->{containers}}) {
            if (_same($container, $token)) { $removed++ }
            else { push @containers, $container }
        }
        $row->{containers} = \@containers;
        return unless $removed == 1;
        for my $field (qw(dependency_signal_names dependency_source)) {
            if (exists $input_row->{$field}) {
                return if ref($input_row->{$field}) || (defined($input_row->{$field})
                    && length($input_row->{$field}) > FSM::CoreExpressionWidthSupport::MAX_NODES());
                $row->{data}{$field} = $input_row->{$field};
            } else {
                delete $row->{data}{$field};
            }
        }
        return unless _same($args{input}, $before);
        return {record => $record, frame => $frame};
    };
    return $@ ? undef : $holder;
}

# A batch's last barrier must not call semantic getters: a getter for a later
# row could otherwise change an earlier row after it was checked. Revalidate
# the original raw source observation as well as all row/owner identities.
sub live_usage_current_raw {
    my ($class, %args) = @_;
    my $result = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && ref($holder->{frame}) eq 'HASH';
        my $state = _raw(%args) or return;
        return unless _same($holder->{frame}{state}, $state);
        my $observation = $holder->{frame}{sources}{sources}{observation};
        return unless FSM::ConcatenationSourceObservationSupport->current(
            FSM::ConcatenationGenerationSourceSupport::_source_args(%args), holder => $observation);
        return 1;
    };
    return $@ ? undef : $result;
}

sub after_live_usage {
    my ($class, %args) = @_;
    my $holder = eval {
        my $frame = _observe(%args) or return;
        my $record = _record($frame, $args{signal_info}{width}) or return;
        my $input = $args{input};
        return unless ref($input) eq 'HASH' && ref($input->{frame}) eq 'HASH';
        my $old = $input->{frame}{state}{row}{data};
        return unless ref($old) eq 'HASH' && !tied(%$old);
        my $before = {record => $record, frame => _copy($frame)};
        my $data = $before->{frame}{state}{row}{data};
        for my $field (qw(referenced_in_substitutions used_in_final_expressions
            live_usage_evidence_state live_usage_source)) {
            return unless _same($args{selected}{$field}, $data->{$field});
            if (exists $old->{$field}) { $data->{$field} = $old->{$field} }
            else { delete $data->{$field} }
        }
        return unless _same($input, $before);
        return {record => $record, frame => $frame};
    };
    return $@ ? undef : $holder;
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
C<publication_checkpoint>. Typed rendering carries the held event through only
its actual scalar expression/source annotations, binding the exact returned
runtime AST before and after the renderer. Dependency publication carries the
held event through its exact new array, source and narrow fallback tag, with a
barrier before the final assignments. Complete-view bulk live-usage priming
withholds every original event before traversal, admits only its exact computed
annotations, and finishes with a getter-free whole-transaction barrier. The
single-row fallback shares that transaction across its two actual queries and
four scalar assignments, admitting only the actual supplied installed row and
computed results. Invalid-name defaults and cached no-write returns preserve.
Actual registry synchronization preserves paired original source/event holders
through its exact complete existing/merged/name copies and witnessed installed
registry identities. Both installed proof maps remain withheld across callbacks
and semantic revalidation, followed by whole-view raw checks. Source observations
are never recaptured. Completed policy remains separate.
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
The installed registry transaction may additionally pass C<source_holder> to
validate a staged original source frame without publishing it. It must first
prove the old source/event pair and predict only actual registry identity/copy
changes; this observer neither performs that transaction nor installs authority.

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
and grants no completed policy. Other normalization and registry transitions
require their own checks.

=head2 render_input(..., holder => HOLDER, runtime_ast => ACTUAL_RETURN)

Validate the held current event and the actual original built-in runtime AST
before the typed renderer callback. The installed width owner removes the event
while rendering. Cached no-write returns preserve existing currentness; cleaned
or compatibility fallback branches receive no new authority.

=head2 after_render(..., input => INPUT, runtime_ast => ACTUAL_RETURN, selected_expression => EXPRESSION)

Revalidate the original input and actual rendered AST after the real callback
and its annotations. Only the merged row's C<rendered_expression>, equal to the
bounded scalar callback return, and C<rendered_expression_source>, equal to its
original runtime source, may change. Preserve prior field absence as well as
values, complete other metadata/container identities and original sources.
Missing/stale/foreign input, unrelated or late getter mutations and malformed
returns withhold. Actual renderer exceptions propagate with no installed event.
Return only a detached holder; this observer installs nothing. Dependency and
live-usage transactions, registry replacement, completed policy and symbolic
emission remain separate from rendering.

=head2 dependency_checkpoint(..., input => INPUT, runtime_ast => ACTUAL_RETURN, selected_source => SOURCE, selected_fallback => TAG)

After nested rendering, the installed owner removes a held current event before
runtime recovery, dependency extraction and fallback callbacks. Before the final
array/source assignments, revalidate that original input and actual returned AST.
Only removal of the old scalar C<dependency_fallback_source> or assignment of the
actual selected C<rendered_expression_fallback> tag may have changed. The selected
source must equal the original runtime source, with that exact suffix when used.
Other fallback labels retain ordinary resolution but receive no carried event.
Unrelated metadata, source or identity mutations withhold before publication can
overwrite them. Missing or stale inputs cannot mint. Return a detached checkpoint
or undef; install nothing.

=head2 after_dependencies(..., input => CHECKPOINT, selected_names => NAMES, selected_source => SOURCE, published_array => ACTUAL_ARRAY)

After the real array/source assignments, bind the exact newly installed plain
array and the independently retained ordered selected names. Names must be plain
identifiers. Only C<dependency_signal_names> and C<dependency_source> may change
from the checkpoint. Preserve original field absence/values, all other container
identities, complete original sources, epoch, rows and registry. Copied/substituted
arrays, aliases, changed values and late getter mutations cannot restore authority.
Actual callback exceptions propagate with the event already removed. Cached reads
perform no writes and preserve existing currentness; a clean later retry cannot
remint a spent event. Return only a detached holder. No live-usage, registry,
completed policy or symbolic sum/emission authority follows.

=head2 live_usage_current_raw(..., holder => HOLDER)

Revalidate complete original row/allocator/registry state and the original raw
source observation without semantic getters. The installed bulk transaction
uses this after its semantic passes to detect a later getter changing an earlier
row. Return true or undef; install nothing and infer no new source contract.

=head2 after_live_usage(..., input => HOLDER, selected => ANNOTATIONS)

Validate the held input through only the actual merged row's
C<referenced_in_substitutions>, C<used_in_final_expressions>,
C<live_usage_evidence_state> and C<live_usage_source> assignments. Compare each
with the independently retained value computed by bulk priming. Preserve old
field absence, other metadata, nested identities and original sources. Return a
detached holder or undef. The installed owner freezes/removes all holders before
any getter or traversal, binds exact complete view membership and row identities,
checks the whole input before writes can hide callback mutations, then checks all
resulting holders before atomic restoration. Cached rows admit no writes.
Missing/stale/foreign/partial views, callback or late getter changes and failures
cannot refresh or remint an event. Plain transactions retain no view or caller
graph. Single-row fallback and completed policy remain separately qualified.

=cut
