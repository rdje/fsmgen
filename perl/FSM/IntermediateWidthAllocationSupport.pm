package FSM::IntermediateWidthAllocationSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _width ($value) {
    return unless defined($value) && !ref($value) && $value =~ /\A[0-9]+\z/;
    my $text = "$value";
    $text =~ s/\A0+//;
    return length($text) ? $text : undef;
}

sub _maximum ($left, $right) {
    return length($left) > length($right) ? $left : $right if length($left) != length($right);
    return $left gt $right ? $left : $right;
}

sub _copy_record ($record) {
    confess "Intermediate width allocation requires a closed binary max record\n"
        unless ref($record) eq 'HASH'
            && join(',', sort keys %$record) eq 'kind,operator,selected_width,source_names'
            && defined($record->{kind}) && !ref($record->{kind}) && $record->{kind} eq 'binary_operand_max'
            && defined($record->{operator}) && !ref($record->{operator}) && $record->{operator} =~ /\A[&|^]\z/
            && ref($record->{source_names}) eq 'ARRAY' && @{$record->{source_names}} == 2
            && !grep {!FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_)} @{$record->{source_names}};
    confess "Intermediate width allocation requires a positive decimal selected width\n"
        unless defined(_width($record->{selected_width}));
    return JSON::PP->new->canonical->decode(JSON::PP->new->canonical->encode($record));
}

sub _descriptor ($signal) {
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal->name)
        && defined(_width($signal->width)) && defined($signal->type) && !ref($signal->type)
        && $signal->type =~ /\A(?:wire|reg)\z/
        && !$signal->signed && !defined($signal->declared_type_name) && !defined($signal->declared_type_spec);
    return {object_identity => sprintf('%x', refaddr($signal)), name => $signal->name,
        width => _width($signal->width), type => $signal->type, signed => $signal->signed,
        state_model => $signal->state_model, constraints => $signal->constraints};
}

sub _capture ($signal) {
    my $own = _descriptor($signal) or return;
    return unless $signal->type eq 'wire' && $signal->get_attribute('is_intermediate')
        && !$signal->get_attribute('is_output') && !$signal->get_attribute('is_aux_output')
        && !$signal->get_attribute('width_declared');
    my $role = $signal->get_attribute('signal_role');
    return if defined($role) && (ref($role) || $role ne 'intermediate');
    return if grep {exists($signal->{$_})} qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    return unless ref($own->{constraints}) eq 'ARRAY' && !@{$own->{constraints}};
    my $ast = $signal->driving_ast;
    return unless blessed($ast) && $ast->isa('FSM::CoreAST::BinaryOp');
    my $operator = $ast->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my (@names, @sources, @references);
    for my $operand ($ast->left, $ast->right) {
        return unless blessed($operand) && $operand->isa('FSM::CoreAST::SignalRef');
        my $source = $operand->signal;
        my $descriptor = _descriptor($source) or return;
        return if refaddr($source) == refaddr($signal) || $source->name eq $signal->name;
        push @names, $source->name;
        push @sources, $descriptor;
        push @references, sprintf('%x', refaddr($operand));
    }
    return if $names[0] eq $names[1] && $sources[0]{object_identity} ne $sources[1]{object_identity};
    my $maximum = _maximum($sources[0]{width}, $sources[1]{width});
    return unless _width($signal->width) eq $maximum;
    my $state = JSON::PP->new->canonical->encode({signal => $own,
        revision => $signal->_intermediate_width_allocation_revision,
        ast_identity => sprintf('%x', refaddr($ast)), operator => $operator,
        operand_reference_identities => \@references, operands => \@sources,
        roles => {map {$_ => $signal->get_attribute($_)}
            qw(is_intermediate is_output is_aux_output width_declared signal_role)}});
    return {operator => $operator, source_names => \@names, width => $maximum, state => $state};
}

sub _matches ($record, $capture) {
    return $record->{operator} eq $capture->{operator}
        && $record->{source_names}[0] eq $capture->{source_names}[0]
        && $record->{source_names}[1] eq $capture->{source_names}[1]
        && _width($record->{selected_width}) eq $capture->{width};
}

sub prepare_core ($class, %args) {
    my $record = _copy_record($args{record});
    my $capture = eval {_capture($args{signal})};
    confess "Intermediate width allocation requires the actual current plain binary max shape\n"
        unless $capture && _matches($record, $capture);
    return {record => $record, state => $capture->{state}};
}

sub current_core ($class, %args) {
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = eval {
        my $capture = _capture($args{signal}) or return;
        return unless $capture->{state} eq $holder->{state};
        my $copy = _copy_record($holder->{record});
        return unless _matches($copy, $capture);
        $copy;
    };
    return $@ ? undef : $record;
}

1;

=head1 NAME

FSM::IntermediateWidthAllocationSupport - Explicit current Core intermediate allocation contracts

=head1 CONTRACT

This private helper validates a producer-supplied allocation contract. Equal
selected widths alone install nothing and do not attest an allocator's intent.
The actual parser/factorizer publishers and symbolic range consumers are separate
successors. This helper enables no source or target profile.

The closed record is C<{kind =E<gt> binary_operand_max, operator, source_names,
selected_width}>. The operator is canonical binary C<&>, C<|> or C<^> and
C<source_names> retains both ordered whole Core SignalRef slots, including two
references to the same actual Signal. Distinct objects claiming the same name
cannot borrow that identity. The selected width is a positive decimal scalar;
integer and decimal-string representations retain their supplied JSON kinds.
Decimal maximum comparisons are exact and independent of machine integer width.
This metadata acceptance establishes no target width/domain legality.

The actual result must be a plain unsigned wire intermediate without an authored
width record, conflicting output/auxiliary/declared role, or own constraints.
Operands are plain unsigned Core wire/register Signals. The current driving AST,
actual Signal/operand identities, selected width, type/role/constraint state and
revocation revision must agree. Named/signed or other shapes remain unqualified.
Context-widened/truncated results cannot assert this intrinsic-max contract.

=head1 METHODS

=head2 prepare_core

C<prepare_core(signal =E<gt> $signal, record =E<gt> $record)> returns a detached
plain C<{record, state}> capsule. It throws for malformed or incoherent supplied
records. Only an actual allocator may supply the intent contract; this helper's
shape validation is not caller-provenance attestation. The state contains scalar
identity fingerprints and JSON data, with no additional mutable owner graph.

=head2 current_core

C<current_core(signal =E<gt> $signal, holder =E<gt> $capsule)> returns a detached
record only while its actual installation is current, otherwise undef. Foreign,
stale, malformed or privately diverged installations withhold the record.

The Core Signal getter/setter/clear methods own installation and revision
invalidation. Ordinary Signals acquire no field from lookup or clearing.
Relevant supported writes revoke an installed record even when values match;
unrelated diagnostic attributes preserve it. A failed replacement clears the old
record. Reusing an escaped capsule cannot bypass a later revocation revision.

Runnable lifecycle/opaque-context controls:

  scripts/run_with_ram_guard.sh -- prove -Iperl t/2198-core-intermediate-width-allocation.t

=cut
