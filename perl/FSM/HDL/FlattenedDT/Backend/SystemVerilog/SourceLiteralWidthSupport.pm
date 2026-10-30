package FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::CoreExpressionWidthSupport;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { return JSON::PP->new->canonical }
sub _identity { return FSM::SourceLiteralWidthAllocationSupport::_identity($_[0]) }
sub _width { return FSM::IntermediateWidthAllocationSupport::_width($_[0]) }
sub _maximum { return FSM::IntermediateWidthAllocationSupport::_maximum($_[0], $_[1]) }

# This is the existing direct SystemVerilog unsized-literal rule. It belongs to
# the target, not Core, and cannot replace an explicit source literal size.
sub _unsized_literal_width { return 32 }

# Reuse the single source capture's bounded child expansion. The Core walk for
# each local AST stops at its actual child references and receives their widths
# explicitly, so no inference walk recursively re-captures another helper.
sub _infer_capture {
    my ($capture, $observation) = @_;
    my $state = _json()->decode($capture->{state});
    my $edges = $state->{children} // [];
    my $proofs = $capture->{walk}{child_captures};
    return unless @$edges == @$proofs;
    my %resolutions;
    for my $index (0 .. $#$edges) {
        my $edge = $edges->[$index];
        return unless $edge->{phase} eq 'completed';
        my $width = _infer_capture($proofs->[$index]{capture}, $observation);
        return unless defined $width;
        $resolutions{$edge->{reference_identity}} = $width;
        push @{$observation->{reference_widths}}, {
            parent_identity => $state->{signal}{identity_token},
            reference_identity => $edge->{reference_identity},
            signal_identity => $edge->{signal_identity}, width => $width};
    }
    my $signal = $capture->{objects}[0];
    my $width = FSM::CoreExpressionWidthSupport->infer_width($signal->driving_ast,
        unsized_literal_width => \&_unsized_literal_width,
        source_reference_width => sub {
            my ($reference) = @_;
            my $identity = _identity($reference);
            return {width => $resolutions{$identity}} if exists $resolutions{$identity};
            # An unproved generated reference must never borrow its nominal
            # Core width. Independently declared leaves retain ordinary reads.
            return {width => undef} if $reference->signal->{attributes}{is_intermediate};
            return undef;
        });
    $width = _width($width);
    return unless defined $width;
    push @{$observation->{helper_widths}}, {signal_identity => $state->{signal}{identity_token},
        name => $state->{signal}{name}, width => $width};
    return $width;
}

sub _contributions {
    my ($capture, $observation) = @_;
    my %sources = map {$_->{identity_token} => $_} @{$capture->{walk}{operands}};
    for my $stamp (@{$capture->{walk}{stamps}}) {
        my ($node, $raw, $kind) = @$stamp;
        next unless $kind eq 'node';
        if ($node->isa('FSM::CoreAST::Literal')) {
            my $literal = _json()->decode($raw);
            my $sized = defined $literal->{width};
            my $width = _width($sized ? $literal->{width} : _unsized_literal_width());
            return unless defined $width;
            push @{$observation->{literals}}, {identity => _identity($node), literal => $literal,
                width => $width, sizing => $sized ? 'explicit' : 'target_unsized'};
            $observation->{literal_floor} = defined($observation->{literal_floor})
                ? _maximum($observation->{literal_floor}, $width) : $width;
        } elsif ($node->isa('FSM::CoreAST::SignalRef')) {
            my $reference = _json()->decode($raw);
            my $source = $sources{$reference->{signal}} or return;
            next if $source->{roles}{is_intermediate};
            push @{$observation->{leaves}}, {reference_identity => _identity($node), source => $source};
            $observation->{leaf_floor} = defined($observation->{leaf_floor})
                ? _maximum($observation->{leaf_floor}, $source->{width}) : $source->{width};
        }
    }
    return defined $observation->{literal_floor};
}

sub prepare {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'signal';
    my $signal = $args{signal};
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $observation = eval {
        my $holder = $signal->{_source_literal_width_allocation};
        return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state';
        my $raw = _json()->encode($holder);
        my $record = FSM::SourceLiteralWidthAllocationSupport->copy_record($holder->{record});
        my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($signal, {phase => 'completed'}) or return;
        return unless FSM::SourceLiteralWidthAllocationSupport::_tracked($capture)
            && FSM::SourceLiteralWidthAllocationSupport::_matches($record, $capture)
            && $capture->{state} eq $holder->{state};
        my $state = _json()->decode($capture->{state});
        my $result = {kind => 'systemverilog_source_literal_width',
            source_identity => $state->{signal}{identity_token}, source_capsule => _json()->decode($raw),
            reference_widths => [], helper_widths => [], literals => [], leaves => [],
            literal_floor => undef, leaf_floor => undef};
        my $width = _infer_capture($capture, $result);
        return unless defined($width) && _contributions($capture, $result);
        my $maximum = defined($result->{leaf_floor})
            ? _maximum($result->{literal_floor}, $result->{leaf_floor}) : $result->{literal_floor};
        return unless $width eq $maximum;
        $result->{selected_width} = $width;
        # All source/AST reads precede this raw barrier. Rechecking only the
        # last child would miss a getter that wrote an earlier source or holder.
        return unless FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})
            && _json()->encode($signal->{_source_literal_width_allocation}) eq $raw;
        _json()->decode(_json()->encode($result));
    };
    return $@ ? undef : $observation;
}

sub current {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'observation,signal' && ref($args{observation}) eq 'HASH';
    my $observation = $class->prepare(signal => $args{signal}) or return;
    my $matches = eval {_json()->encode($observation) eq _json()->encode($args{observation})};
    return $matches ? $observation : undef;
}

# A numeric observation is deliberately short-lived. Re-derive it at each
# inference read; it is not a completed allocation or an emitted-range policy.
sub _inference_frame {
    my ($args, $observation) = @_;
    my $owner = $args->{width_support};
    return unless blessed($owner)
        && $owner->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport');
    my $context = $owner->{flattened_dt};
    return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT')
        && (refaddr($context->{backend_sv_intermediate_width_support}) // 0) == refaddr($owner);
    my $rows = $owner->_current_graph_inference_rows or return;
    my $name = $args->{signal_name};
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
        && ref($args->{signal_registry}) eq 'HASH'
        && ref($args->{signal_info}) eq 'HASH'
        && (refaddr($rows->{$name}) // 0) == refaddr($args->{signal_info})
        && (refaddr($args->{signal_registry}{$name}) // 0) == refaddr($args->{signal_info});
    my $module = $context->{fsm_module};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    my $signals = $module->{signals};
    my $registry = $context->{intermediate_signals};
    return unless ref($signals) eq 'HASH' && ref($registry) eq 'HASH';
    my $signal = $signals->{$name};
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $source = _json()->decode($observation->{source_capsule}{state});
    my @members = ($source->{signal}, @{$source->{operands}});
    for my $member (@members) {
        my $actual = $signals->{$member->{name}};
        return unless blessed($actual) && _identity($actual) eq $member->{identity_token};
    }
    return unless _identity($signal) eq $observation->{source_identity};
    my $ast = $signal->{driving_ast};
    my @states;
    for my $row ($args->{signal_info}, $registry->{$name}) {
        return unless ref($row) eq 'HASH' && !defined($row->{state_model})
            && defined($row->{source}) && !ref($row->{source}) && $row->{source} eq 'fsmgen_parsing';
        for my $key (qw(ast driving_ast)) {
            return unless blessed($row->{$key}) && refaddr($row->{$key}) == refaddr($ast);
        }
        my $state = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast) or return;
        my $width = _width($row->{width});
        return unless defined $width;
        # Before normalization these rows carry the original Core compatibility
        # width. Only this branch's own numeric publication can be read again.
        if (defined $row->{width_source}) {
            return unless $row->{width_source} eq 'source_literal_intent'
                && $width eq $observation->{selected_width};
        } else {
            return unless $width eq _width($source->{signal}{width});
        }
        push @states, $state;
    }
    return {kind => 'systemverilog_source_literal_numeric', observation => $observation,
        owner_identity => _identity($owner), context_identity => _identity($context),
        module_identity => _identity($module), signals_identity => _identity($signals),
        registry_identity => _identity($registry), rows_identity => _identity($rows),
        epoch => $owner->{_width_inference_epoch}, rows_revision => $owner->{_graph_inference_rows_revision},
        signal_name => $name, signal_info => $states[0], registered => $states[1]};
}

sub prepare_inference {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'signal_info,signal_name,signal_registry,width_support';
    my $result = eval {
        my $owner = $args{width_support};
        return unless blessed($owner)
            && $owner->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport')
            && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($args{signal_name});
        my $context = $owner->{flattened_dt};
        return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT');
        my $module = $context->{fsm_module};
        return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule')
            && ref($module->{signals}) eq 'HASH';
        my $signal = $module->{signals}{$args{signal_name}};
        my $observation = $class->prepare(signal => $signal) or return;
        my $frame = _inference_frame(\%args, $observation) or return;
        # Source getters can mutate an earlier row or module membership. Read
        # all source state again, then close the join using raw target reads.
        return unless $class->current(signal => $signal, observation => $observation);
        my $after = _inference_frame(\%args, $observation) or return;
        return unless _json()->encode($frame) eq _json()->encode($after);
        _json()->decode(_json()->encode($frame));
    };
    return $@ ? undef : $result;
}

sub current_inference {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'observation,signal_info,signal_name,signal_registry,width_support';
    my $saved = delete $args{observation};
    return unless ref($saved) eq 'HASH';
    my $current = $class->prepare_inference(%args) or return;
    my $matches = eval {_json()->encode($current) eq _json()->encode($saved)};
    return $matches ? $current : undef;
}

1;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport - Target-only widths over completed literal source intent

=head1 METHODS

=head2 prepare

C<< prepare(signal => $actual_core_signal) >> returns a detached JSON observation,
which can be absent. It requires the actual current completed
C<source_literal_width_allocation> capsule and all actual typed child
relationships. One globally bounded source capture authenticates the complete
nested graph. Shared Core inference then resolves each local AST using explicit
child reference widths and this target's existing 32-bit unsized-literal rule.
Explicit literal sizes and independent declared leaf widths remain separate.
Core widths, raw literal value/radix/size, source JSON kinds, declarations and
mutable parameter metadata are never changed.

The observation keeps the complete original C<source_capsule>, root lifetime
C<source_identity>, ordered C<helper_widths> and typed C<reference_widths>, and
ordered original C<leaves> and C<literals>, including repeated occurrences.
C<selected_width>, C<literal_floor> and nullable C<leaf_floor> are canonical
positive decimal strings. Leaf source descriptors retain their original raw
metadata and independent width contracts. Literal entries retain raw source
records, target width and C<explicit> or C<target_unsized> sizing. A generated
child's compatibility width is never an independent leaf floor.

Missing, revoked, foreign, unsupported, cyclic, over-bound or independently
constrained source intent withholds. A final complete raw barrier rejects source
or holder changes during inference, including matching writes. Exceptions during
source observation also withhold. No source owners, callbacks or registries are
retained by the returned data.

This is source observation only: it supplies no backend row, normalization epoch,
inference branch attestation, generic range, signedness legality, emitted target
identity or final source/target agreement. Live numeric and declaration consumers
remain separate. Scalar wrappers retain the shared Core walk's own scalar rule;
wrappers cannot themselves impersonate a completed literal helper capsule.

=head2 current

C<< current(signal => $actual_core_signal, observation => $saved_observation) >>
re-derives the complete observation and returns fresh detached data only on exact
JSON equality. Changed kinds, floors, identities, source metadata and extra fields
withhold. It does not upgrade the observation to target eligibility.

=head2 prepare_inference

C<< prepare_inference(width_support => $installed_owner, signal_name => $name,
signal_info => $actual_row, signal_registry => $consumer_rows) >> returns a
detached numeric observation for the current normalization epoch. The actual
row must belong to the owner's current weak canonical row view and the supplied
consumer map. The installed context/module/registry, root and every original
source member, driving AST and independent row constraints must agree. Both
collected and registered rows must carry either the original Core compatibility
width or this branch's own C<source_literal_intent> width publication. Foreign
width branches, signed/typed/constrained rows and missing or revoked source
intent withhold. Source re-observation followed by a raw target-frame comparison
rejects target changes made during source reads.

The direct width resolver consumes this fresh observation before native/cached
compatibility metadata. Its whole-reference resolver also uses the qualified
target width before a Core helper's nominal width. This repairs fixed nested
literal truncation without writing Core widths or reconstructing dependencies
from numeric equality. Existing unsupported profiles retain their compatibility
path and acquire no literal authority. Independent floors, generic ranges,
selected text, final declaration/source agreement and emitted ledgers still
require their separate consumers. This frame supplies no completed allocation
or range eligibility and is re-derived at each numeric read.

=head2 current_inference

Accept the same arguments plus C<observation>. Re-derive the entire numeric
frame and return detached data only on exact JSON agreement, including epoch,
row and registry identities and raw source kinds. A copied or changed saved
frame cannot authorize a later row or epoch. The frame contains no live owners.

=cut
