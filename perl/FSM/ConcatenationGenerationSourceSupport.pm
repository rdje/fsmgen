package FSM::ConcatenationGenerationSourceSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::ConcatenationSourceObservationSupport;
use FSM::ConcatenationSourceWidthSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { JSON::PP->new->canonical }
sub _identity { ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef }

# Bind only built-in installed owners and the original merged/allocator rows.
# Numeric row fields deliberately supply no semantic source authority here.
sub _binding {
    my (%args) = @_;
    my ($owner, $name, $row) = @args{qw(width_support signal_name signal_info)};
    return unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
        && ref($row) eq 'HASH' && !tied(%$row);
    my $ctx = $owner->{flattened_dt};
    return unless ref($ctx) eq 'FSM::HDL::FlattenedDT'
        && ($ctx->{backend_sv_intermediate_width_support} // 0) == $owner
        && ref($ctx->{fsm_module}) eq 'FSM::CoreAST::FSMModule'
        && ref($ctx->{ast_factorizer}) eq 'FSM::HDL::ASTFactorization'
        && ref($ctx->{assignment_analysis}) eq 'HASH';
    my $view = $owner->_current_graph_inference_rows;
    return unless $view && ($view->{$name} // 0) == $row
        && ($row->{source} // '') eq 'ast_factorization'
        && ref($row->{ast}) eq 'FSM::CoreAST::Concatenation'
        && (!defined($row->{runtime_ast}) || (ref($row->{runtime_ast}) eq 'FSM::CoreAST::Concatenation'
            && $row->{runtime_ast} == $row->{ast}));
    my $allocator = $ctx->{ast_factorizer}{intermediate_signals}{$name};
    my $registered = $ctx->{intermediate_signals}{$name};
    return unless ref($allocator) eq 'HASH' && ref($registered) eq 'HASH'
        && $row != $allocator && $row != $registered && $allocator != $registered
        && ref($allocator->{ast}) eq 'FSM::CoreAST::Concatenation'
        && ref($registered->{ast}) eq 'FSM::CoreAST::Concatenation'
        && $allocator->{ast} == $row->{ast} && $registered->{ast} == $row->{ast}
        && defined($row->{structural_id}) && !ref($row->{structural_id})
        && ($allocator->{structural_id} // '') eq $row->{structural_id};
    return {width_owner => _identity($owner), backend => _identity($ctx),
        module => _identity($ctx->{fsm_module}), factorizer => _identity($ctx->{ast_factorizer}),
        row_view => _identity($view), view_revision => $owner->{_graph_inference_rows_revision},
        epoch => $owner->{_width_inference_epoch}, name => $name, row => _identity($row),
        allocator => _identity($allocator), ast => _identity($row->{ast}),
        structural_id => $row->{structural_id}, registry => _identity($ctx->{intermediate_signals}),
        registered => _identity($registered)};
}

sub _source_args {
    my (%args) = @_;
    my $ctx = $args{width_support}{flattened_dt};
    return (factorizer => $ctx->{ast_factorizer}, signal_name => $args{signal_name},
        fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => 'systemverilog');
}

sub prepare_input {
    my ($class, %args) = @_;
    my $result = eval {
        my $binding = _binding(%args) or return;
        my $row = $args{signal_info};
        return if defined($row->{width}) || ($row->{width_source} // '') ne 'unresolved_factorization_ast';
        my $raw = FSM::ConcatenationSourceObservationSupport->capture(_source_args(%args)) or return;
        return {binding => $binding, observation => $raw};
    };
    return $@ ? undef : $result;
}

sub capture {
    my ($class, %args) = @_;
    my $result = eval {
        my $input = $args{input};
        return unless ref($input) eq 'HASH' && !tied(%$input)
            && join(',', sort keys %$input) eq 'binding,observation';
        my $binding = _binding(%args) or return;
        return unless FSM::ConcatenationSourceObservationSupport::_same_record($input->{binding}, $binding);
        my $row = $args{signal_info};
        return if defined($row->{width}) || ($row->{width_source} // '') ne 'unresolved_factorization_ast';
        my $sources = FSM::ConcatenationSourceWidthSupport->prepare(
            _source_args(%args), observation => $input->{observation});
        my $after = _binding(%args) or return;
        return unless _json()->encode($after) eq _json()->encode($binding)
            && !defined($row->{width}) && ($row->{width_source} // '') eq 'unresolved_factorization_ast';
        # Canonical preparation already rechecks the original complete raw
        # scope after its last semantic read. Never replace that observation.
        return _json()->decode(_json()->encode({kind => 'concatenation_generation_sources',
            binding => $binding, sources => $sources}));
    };
    return $@ ? undef : $result;
}

sub current {
    my ($class, %args) = @_;
    my $result = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && !tied(%$holder)
            && join(',', sort keys %$holder) eq 'binding,kind,sources'
            && ($holder->{kind} // '') eq 'concatenation_generation_sources';
        my $binding = _binding(%args) or return;
        return unless FSM::ConcatenationSourceObservationSupport::_same_record($holder->{binding}, $binding);
        my $sources = FSM::ConcatenationSourceWidthSupport->current(_source_args(%args), holder => $holder->{sources})
            or return;
        my $after = _binding(%args) or return;
        return unless _json()->encode($after) eq _json()->encode($binding);
        return _json()->decode(_json()->encode({kind => 'concatenation_generation_sources',
            binding => $binding, sources => $sources}));
    };
    return $@ ? undef : $result;
}

1;

=head1 NAME

FSM::ConcatenationGenerationSourceSupport - Private original generation source freeze

=head1 DESCRIPTION

The installed default width owner captures each eligible unresolved original
concatenation once, immediately after binding its actual normalization epoch
and weak row view, before runtime recovery and native-metadata callbacks.
C<capture> and C<current> accept C<width_support>, C<signal_name> and the actual
C<signal_info>. C<current> additionally takes the original C<holder>.
Before any canonical getter, C<prepare_input> freezes getter-free inputs for
every candidate in the view. C<capture> consumes its original C<input>; a later
candidate cannot bless a source changed by an earlier candidate's getter.

Detached plain holders bind the installed backend, width owner, module,
factorizer, original merged/allocator/AST identities, epoch/view revision and
initial registered row/map, alongside the original complete raw observation and
independent canonical operand contracts. Numeric width/source writes do not
replace source proof. Current lookup revalidates the same original source
through late semantic reads; it never recaptures a changed scope. Unsupported
or preconstrained profiles withhold without changing ordinary numeric behavior.

The source freeze grants no intrinsic event, selected sum, completed allocation
or target range. Initial registry replacement or an expired weak view invalidates
this frame; later owned event publication/carry is a separate protocol. Abort,
failure, reset and new epochs clear installed holders. Holders retain no caller
objects and cannot extend a row view's lifetime. The raw observer's trusted
built-in and restored-scalar-write limits still apply.

=head1 METHODS

=head2 prepare_input(width_support => OWNER, signal_name => NAME, signal_info => ROW)

Return an original getter-free binding/raw input, or undef. Prepare the complete
candidate set before canonical capture starts.

=head2 capture(width_support => OWNER, signal_name => NAME, signal_info => ROW, input => INPUT)

Return an original detached source frame, or undef for an ineligible profile.

=head2 current(width_support => OWNER, signal_name => NAME, signal_info => ROW, holder => FRAME)

Return the detached original frame only while its complete binding and source
contracts remain current; return undef on divergence or malformed inputs.

=cut
