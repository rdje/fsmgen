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

sub whole_signal_name ($class, $operand) {
    return unless blessed($operand);
    my $name;
    if (UNIVERSAL::isa($operand, 'FSM::CoreAST::SignalRef')) {
        return if defined $operand->slice;
        my $signal = $operand->signal;
        return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
        $name = $signal->name;
    } elsif (UNIVERSAL::isa($operand, 'FSM::AST::SignalRef')) {
        return if $operand->is_fsm_state_next || $operand->is_fsm_state_register;
        $name = $operand->name;
    } elsif (UNIVERSAL::isa($operand, 'FSM::HDL::IntermediateSignalRef')) {
        # This documented compatible reference intentionally has no Core
        # Signal owner or runtime state-wrapper methods.
        $name = $operand->signal_name;
    } else {
        return;
    }
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    return $name;
}

sub binary_whole_signal_shape ($class, $node) {
    return unless blessed($node) && ($node->isa('FSM::AST::BinaryOp')
        || $node->isa('FSM::CoreAST::BinaryOp') || $node->isa('FSM::HDL::SubstitutedBinaryOp'));
    my $operator = $node->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my $left = $class->whole_signal_name($node->left) or return;
    my $right = $class->whole_signal_name($node->right) or return;
    return {operator => $operator, source_names => [$left, $right]};
}

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

sub copy_record ($class, $record) {
    return _copy_record($record);
}

sub matches_selected_widths ($class, $record, $result_width, @operand_widths) {
    my $copy = _copy_record($record);
    return unless @operand_widths == 2;
    my @widths = map {_width($_)} @operand_widths;
    my $result = _width($result_width);
    return unless defined($result) && !grep {!defined($_)} @widths;
    return _width($copy->{selected_width}) eq $result && $result eq _maximum(@widths);
}

sub _descriptor ($signal) {
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
        && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($signal->name)
        && defined(_width($signal->width)) && defined($signal->type) && !ref($signal->type)
        && $signal->type =~ /\A(?:wire|reg)\z/
        && !$signal->signed && !defined($signal->declared_type_name) && !defined($signal->declared_type_spec);
    return {object_identity => sprintf('%x', refaddr($signal)), name => $signal->name,
        width => _width($signal->width), type => $signal->type, signed => $signal->signed,
        state_model => $signal->state_model, constraints => $signal->constraints,
        revision => $signal->_intermediate_width_allocation_revision};
}

sub _capture ($signal) {
    my $own = _descriptor($signal) or return;
    return unless $signal->type eq 'wire' && $signal->get_attribute('is_intermediate')
        && !$signal->get_attribute('is_output') && !$signal->get_attribute('is_aux_output')
        && !$signal->get_attribute('width_declared');
    my $role = $signal->get_attribute('signal_role');
    return if defined($role)
        && (ref($role) || ($role ne 'intermediate' && $role ne 'INTERNAL_INTERMEDIATE'));
    return if grep {exists($signal->{$_})} qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    return unless ref($own->{constraints}) eq 'ARRAY' && !@{$own->{constraints}};
    my $ast = $signal->driving_ast;
    return unless blessed($ast) && $ast->isa('FSM::CoreAST::BinaryOp');
    my $operator = $ast->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my (@names, @sources, @references);
    for my $operand ($ast->left, $ast->right) {
        return unless blessed($operand) && UNIVERSAL::isa($operand, 'FSM::CoreAST::SignalRef');
        return unless __PACKAGE__->whole_signal_name($operand);
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
    if ($args{track}) {
        # Track only explicitly opted-in objects. Initializing an absent counter
        # to zero preserves the already captured state, but future supported
        # writes revoke this event even if they restore identical values.
        my $signal = $args{signal};
        $_->_track_intermediate_width_allocation
            for ($signal, $signal->driving_ast->left->signal, $signal->driving_ast->right->signal);
    }
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

sub _factorized_metadata_state ($metadata, $ast) {
    return unless ref($metadata) eq 'HASH';
    return if grep {defined($metadata->{$_}) && ref($metadata->{$_})} qw(width_source source);
    return if defined($metadata->{width}) && !defined(_width($metadata->{width}));
    return if $metadata->{signed} || defined($metadata->{declared_type_name}) || defined($metadata->{declared_type_spec});
    return if defined($metadata->{constraints})
        && (ref($metadata->{constraints}) ne 'ARRAY' || @{$metadata->{constraints}});
    return if grep {defined($metadata->{$_})} qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    return if defined($metadata->{type}) && (ref($metadata->{type}) || $metadata->{type} ne 'wire');
    my %asts;
    for my $key (qw(ast runtime_ast defining_ast driving_ast)) {
        next unless exists $metadata->{$key};
        my $node = $metadata->{$key};
        return unless blessed($node) && refaddr($node) == refaddr($ast);
        $asts{$key} = sprintf('%x', refaddr($node));
    }
    return {identity => sprintf('%x', refaddr($metadata)), asts => \%asts,
        width => $metadata->{width}, width_source => $metadata->{width_source}, source => $metadata->{source},
        result_constraints => {map {$_ => $metadata->{$_}} qw(type signed state_model constraints
            declared_type_name declared_type_spec _declared_width_source _declared_width_binding _declared_width_requirements)}};
}

sub factorized_inference_frame ($class, %args) {
    return unless defined(_width($args{epoch})) && defined(_width($args{revision}));
    my $context = $args{context};
    return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT');
    my $module = $context->{fsm_module};
    my $factorizer = $context->{ast_factorizer};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule')
        && blessed($factorizer) && $factorizer->isa('FSM::HDL::ASTFactorization');
    my $name = $args{signal_name};
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    my $signals = $module->signals;
    return unless ref($signals) eq 'HASH' && !exists($signals->{$name});
    my $birth = $factorizer->_current_intermediate_width_birth($name) or return;
    my $entry = $factorizer->{intermediate_signals}{$name};
    my $ast = $entry->{ast};
    my $info = $args{signal_info};
    return unless ref($info) eq 'HASH' && ($info->{source} // '') eq 'ast_factorization'
        && blessed($info->{ast}) && refaddr($info->{ast}) == refaddr($ast)
        && blessed($info->{runtime_ast}) && refaddr($info->{runtime_ast}) == refaddr($ast)
        && ($info->{runtime_ast_source} // '') eq 'substituted_ast';
    my (@sources, @descriptors);
    my @operands = ($ast->left, $ast->right);
    for my $index (0, 1) {
        my $operand = $operands[$index];
        # Generated-reference width lookup has another registry precedence;
        # this bounded event covers actual module Signal references only.
        return unless UNIVERSAL::isa($operand, 'FSM::AST::SignalRef')
            || UNIVERSAL::isa($operand, 'FSM::CoreAST::SignalRef');
        my $source = $signals->{$birth->{record}{source_names}[$index]};
        my $descriptor = _descriptor($source) or return;
        return unless $descriptor->{name} eq $birth->{record}{source_names}[$index];
        return if UNIVERSAL::isa($operand, 'FSM::CoreAST::SignalRef') && refaddr($operand->signal) != refaddr($source);
        push @sources, $source;
        push @descriptors, $descriptor;
    }
    my $info_state = _factorized_metadata_state($info, $ast) or return;
    my $entry_state = _factorized_metadata_state($entry, $ast) or return;
    my $registry = $context->{intermediate_signals};
    return if defined($registry) && ref($registry) ne 'HASH';
    my $registered = ref($registry) eq 'HASH' ? $registry->{$name} : undef;
    my $registered_state = defined($registered) ? _factorized_metadata_state($registered, $ast) : undef;
    return if defined($registered) && !$registered_state;
    my $frame = {
        shape => {operator => $birth->{record}{operator}, source_names => $birth->{record}{source_names}},
        context_identity => sprintf('%x', refaddr($context)), module_identity => sprintf('%x', refaddr($module)),
        epoch => $args{epoch}, revision => $args{revision}, birth_state => $birth->{state},
        signal_info => $info_state, factorizer_entry => $entry_state, registered => $registered_state,
        source_signals => \@descriptors,
    };
    my $json = JSON::PP->new->canonical;
    my $copy = $json->decode($json->encode($frame));
    if ($args{track}) {$_->_track_intermediate_width_allocation for @sources}
    return $copy;
}

sub prepare_factorized_inference ($class, %args) {
    my $frame = $class->factorized_inference_frame(%args) or return;
    my $maximum = _maximum(map {$_->{width}} @{$frame->{source_signals}});
    my $width = $args{selected_width};
    return unless defined(_width($width)) && _width($width) eq $maximum
        && defined(_width($frame->{signal_info}{width})) && _width($frame->{signal_info}{width}) eq $maximum;
    my $record = _copy_record({kind => 'binary_operand_max', %{$frame->{shape}}, selected_width => $width});
    return {record => $record, state => JSON::PP->new->canonical->encode($frame)};
}

sub factorized_registry_copy_state ($class, $signal_info, $existing) {
    return unless ref($signal_info) eq 'HASH'
        && (!defined($existing) || ref($existing) eq 'HASH');
    my $copy = {%{$existing // {}}, %$signal_info};
    my $state = _factorized_metadata_state($copy, $signal_info->{ast}) or return;
    delete $state->{identity};
    return JSON::PP->new->decode(JSON::PP->new->encode($state));
}

sub current_factorized_inference ($class, %args) {
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state';
    my $record = eval {
        my $copy = _copy_record($holder->{record});
        my $current = $class->prepare_factorized_inference(%args, selected_width => $copy->{selected_width}, track => 0) or return;
        return unless defined($holder->{state}) && !ref($holder->{state}) && $holder->{state} eq $current->{state}
            && JSON::PP->new->canonical->encode($copy) eq JSON::PP->new->canonical->encode($current->{record});
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
The completed direct source Parser/facade publisher uses tracked current births.
Factorizer provenance and symbolic range consumers remain separate successors.
This validator alone enables no source or target profile.

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
An absent role, legacy C<intermediate>, or canonical C<INTERNAL_INTERMEDIATE>
role is eligible; other explicit roles are withheld. Matching role writes revoke.
Operands are unsliced whole references to plain unsigned Core wire/register Signals.
The current driving AST,
actual Signal/operand identities, selected width, type/role/constraint state and
revocation revision must agree. Named/signed or other shapes remain unqualified.
Context-widened/truncated results cannot assert this intrinsic-max contract.

=head1 METHODS

=head2 copy_record

Validate and detach the closed C<binary_operand_max> record, preserving scalar
JSON kinds and ordered duplicate operand slots. Invalid records throw. This
schema operation supplies no allocation, object-currentness or source proof.

=head2 matches_selected_widths

Check that a valid record's selected width equals the supplied result width and
the exact positive decimal maximum of two supplied operand widths. Leading
zeros normalize only for comparison; caller fields and JSON kinds preserve.
No native integer or floating-point conversion determines equality or maximum.
This numeric consistency check does not attest actual allocation or membership.

=head2 whole_signal_name

Return a simple whole-reference name from an actual Core SignalRef with an
actual Signal, runtime SignalRef, or documented compatible IntermediateSignalRef.
Core slices, runtime state wrappers, invalid names and unrelated node classes
withhold. Actual class ancestry distinguishes the compatible reference from the
Core/runtime interfaces it advertises, so absent Signal/state methods are not
assumed. No rendered-text fallback selects a name.

=head2 binary_whole_signal_shape

Return detached C<{operator, source_names}> syntax for canonical binary bitwise
C<&>, C<|> or C<^> over those whole references. Core, runtime and substituted
binary nodes retain both ordered slots, including duplicates. This shared shape
boundary proves no allocator intent, object association, width or target legality.

=head2 prepare_core

C<prepare_core(signal =E<gt> $signal, record =E<gt> $record)> returns a detached
plain C<{record, state}> capsule. It throws for malformed or incoherent supplied
records. Only an actual allocator may supply the intent contract; this helper's
shape validation is not caller-provenance attestation. Internal C<track =E<gt> 1>
opts the validated result and operand Signals into revocation counters, so later
supported matching-state writes also invalidate staged or installed source intent.
Ordinary validation/getters do not start tracking. The state contains scalar
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

=head2 factorized_inference_frame

Internal plain-data observation of an actual backend normalization epoch, current
factorizer birth, exact metadata/AST associations and complete plain unsigned
module operands. Native result declarations, generated-reference lookup, named
or signed types, authored result constraints and missing/foreign membership
withhold. Optional C<track> starts source revocation counters only after the
complete frame can be serialized. Returned data retains no owner references.

=head2 prepare_factorized_inference

Validate a producer-supplied intrinsic selection against that current frame and
the exact positive operand maximum, returning a detached C<{record, state}>.
This validator does not attest branch execution. Only the actual width resolver's
first unresolved AST-inference branch installs the observation; native/cached
constraints cannot supply it from numeric equality. State includes the epoch,
call revision, actual input/canonical/backend metadata identities and source
mutation revisions. This enables no symbolic range or target profile.

=head2 factorized_registry_copy_state

Project only the width/type/AST fields selected by the actual merged registry
copy, as detached plain data without a replacement identity. The publisher
checks current proof before reset/copy, binds the newly created row identity
and compares the full resulting frame. This projection alone mints no event.

=head2 current_factorized_inference

Return the detached selected record only while the entire held frame agrees.
Unknown registry copies, source writes and epoch reset withhold. The actual
normalizer, registry publisher and resolver qualify their exact transitions from
current held proof. The producer separately gates completed policy on successful
collection; target-event/range admission remains outside this validator.

=cut
