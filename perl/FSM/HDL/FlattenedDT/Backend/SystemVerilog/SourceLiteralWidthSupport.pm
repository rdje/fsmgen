package FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed);
use FSM::CoreExpressionWidthSupport;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::IntermediateWidthAllocationSupport;

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

=cut
