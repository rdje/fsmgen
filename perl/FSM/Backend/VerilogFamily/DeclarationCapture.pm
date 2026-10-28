package FSM::Backend::VerilogFamily::DeclarationCapture;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::IntermediateWidthAllocationSupport;

sub new ($class) {return bless {state => 'empty'}, $class}

sub invalidate ($self) {
    %$self = (state => 'empty');
    return;
}

sub _fail ($self, $message) {
    $self->invalidate;
    confess "Direct declaration capture $message\n";
}

sub begin_module ($self, $name) {
    $self->invalidate;
    $self->_fail('requires a simple actual module name')
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    %$self = (state => 'active', module_name => $name, names => {}, declarations => {}, parameter_order => []);
    return;
}

sub record_name ($self, $role, $name) {
    $self->_fail('requires an active emission transaction') unless $self->{state} eq 'active';
    $self->_fail('has an unknown declaration category')
        unless defined($role) && !ref($role) && $role =~ /\A(?:ports|signals|constants|types|parameter_names)\z/;
    $self->_fail('requires a simple actual declaration name')
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    if (exists($self->{names}{$name})) {
        # One allocated aggregate typedef can serve several actual declarations.
        return if $role eq 'types' && $self->{names}{$name} eq 'types';
        $self->_fail("has duplicate emitted declaration '$name'");
    }
    $self->{names}{$name} = $role;
    push @{$self->{parameter_order}}, $name if $role eq 'parameter_names';
    return;
}

sub record_declaration ($self, $role, $record) {
    $self->_fail('requires a port or signal declaration row')
        unless defined($role) && !ref($role) && $role =~ /\A(?:ports|signals)\z/ && ref($record) eq 'HASH';
    my $json = JSON::PP->new->canonical;
    my $copy = eval {$json->decode($json->encode($record))};
    $self->_fail("requires JSON-safe acyclic declaration metadata: $@") if $@;
    $self->_fail('requires positive numeric width and a numeric signed flag')
        unless defined($copy->{width}) && !ref($copy->{width}) && $copy->{width} =~ /\A[0-9]+\z/ && $copy->{width} > 0
            && defined($copy->{signed}) && !ref($copy->{signed}) && $copy->{signed} =~ /\A[01]\z/;
    if (exists($copy->{width_origin})) {
        my $origin = $copy->{width_origin};
        $self->_fail('requires a closed signal-helper width origin')
            unless $role eq 'signals' && ref($origin) eq 'HASH'
                && join(',', sort keys %$origin) eq 'kind,source_name'
                && defined($origin->{kind}) && !ref($origin->{kind})
                && $origin->{kind} =~ /\A(?:register_next|register_q)\z/
                && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($origin->{source_name})
                && defined($copy->{name}) && !ref($copy->{name})
                && $origin->{source_name} ne $copy->{name};
    }
    $self->record_name($role, $copy->{name});
    $self->{declarations}{$copy->{name}} = {map {$_ => $copy->{$_}}
        qw(name width signed state_model declared_type_name declared_type_spec)};
    $self->{declarations}{$copy->{name}}{width_origin} = $copy->{width_origin}
        if exists($copy->{width_origin});
    return;
}

sub record_typedefs ($self, $lookup) {
    $self->_fail('requires actual allocated typedef lookup') unless ref($lookup) eq 'HASH';
    $self->record_name('types', $_) for sort values %$lookup;
    return;
}

sub record_intermediate_declaration ($self, $record) {
    $self->record_declaration('signals', $record);
    $self->{intermediates}{$record->{name}} = {};
    return;
}

sub record_intermediate_assignment ($self, $name, $record) {
    $self->_fail('intermediate assignment requires its active emitted declaration')
        unless $self->{state} eq 'active' && defined($name) && !ref($name)
            && exists($self->{intermediates}{$name});
    $self->_fail('has duplicate intermediate assignment events')
        if exists($self->{intermediates}{$name}{expression});
    my $json = JSON::PP->new->canonical;
    my $copy = eval {$json->decode($json->encode($record))};
    $self->_fail('requires a closed JSON-safe intermediate expression event')
        if $@ || ref($copy) ne 'HASH'
            || grep {$_ ne 'expression' && $_ ne 'reduction_origin' && $_ ne 'bitwise_origin' && $_ ne 'arithmetic_origin'
                && $_ ne 'width_allocation'} keys %$copy;
    $self->_fail('requires actual nonempty intermediate expression text')
        unless defined($copy->{expression}) && !ref($copy->{expression}) && length($copy->{expression});
    $self->_fail('requires one coherent intermediate origin family')
        if 1 < grep {exists($copy->{$_})} qw(reduction_origin bitwise_origin arithmetic_origin);
    if (exists($copy->{bitwise_origin})) {
        my $origin = $copy->{bitwise_origin};
        $self->_fail('requires a closed binary bitwise intermediate origin')
            unless ref($origin) eq 'HASH' && join(',', sort keys %$origin) eq 'kind,operator,source_names'
                && defined($origin->{kind}) && !ref($origin->{kind}) && $origin->{kind} eq 'binary_bitwise'
                && defined($origin->{operator}) && !ref($origin->{operator}) && $origin->{operator} =~ /\A[&|^]\z/
                && ref($origin->{source_names}) eq 'ARRAY' && @{$origin->{source_names}} == 2
                && !grep {!FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_) || $_ eq $name}
                    @{$origin->{source_names}};
    }
    if (exists($copy->{arithmetic_origin})) {
        my $origin = $copy->{arithmetic_origin};
        $self->_fail('requires a closed binary arithmetic intermediate origin')
            unless ref($origin) eq 'HASH' && join(',', sort keys %$origin) eq 'kind,operator,source_names'
                && defined($origin->{kind}) && !ref($origin->{kind}) && $origin->{kind} eq 'binary_arithmetic'
                && defined($origin->{operator}) && !ref($origin->{operator}) && $origin->{operator} =~ m{\A[+*/%\-]\z}
                && ref($origin->{source_names}) eq 'ARRAY' && @{$origin->{source_names}} == 2
                && !grep {!FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_) || $_ eq $name}
                    @{$origin->{source_names}};
    }
    if (exists($copy->{reduction_origin})) {
        my $origin = $copy->{reduction_origin};
        $self->_fail('requires a closed scalar intermediate reduction origin')
            unless ref($origin) eq 'HASH' && join(',', sort keys %$origin) eq 'kind,operator,source_name'
                && defined($origin->{kind}) && !ref($origin->{kind}) && $origin->{kind} eq 'scalar_reduction'
                && defined($origin->{operator}) && !ref($origin->{operator}) && $origin->{operator} =~ /\A[&|^]\z/
                && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($origin->{source_name})
                && $origin->{source_name} ne $name && $self->{declarations}{$name}{width} == 1;
    }
    if (exists($copy->{width_allocation})) {
        my $allocation = eval {FSM::IntermediateWidthAllocationSupport->copy_record($copy->{width_allocation})};
        $self->_fail('requires a closed binary width allocation policy') if $@ || !$allocation;
        my $origin = $copy->{bitwise_origin} // $copy->{arithmetic_origin};
        $self->_fail('width allocation requires its same ordered binary origin')
            unless $origin && $origin->{operator} eq $allocation->{operator}
                && $origin->{source_names}[0] eq $allocation->{source_names}[0]
                && $origin->{source_names}[1] eq $allocation->{source_names}[1];
        $copy->{width_allocation} = $allocation;
    }
    $self->{intermediates}{$name} = $copy;
    return;
}

sub complete ($self) {
    $self->_fail('cannot complete an inactive declaration transaction') unless $self->{state} eq 'active';
    my @required = grep {$self->{names}{$_} eq 'ports' || $self->{names}{$_} eq 'signals'} keys %{$self->{names}};
    $self->_fail('cannot complete without every numeric declaration row')
        unless @required == keys(%{$self->{declarations}})
            && !grep {!exists($self->{declarations}{$_})} @required;
    for my $row (values %{$self->{declarations}}) {
        next unless exists($row->{width_origin});
        $self->_fail('width origin requires an actual declared parent')
            unless exists($self->{declarations}{$row->{width_origin}{source_name}});
    }
    for my $name (keys %{$self->{intermediates} // {}}) {
        my $row = $self->{intermediates}{$name};
        if (exists($row->{reduction_origin})) {
            $self->_fail('intermediate reduction requires an actual declared operand')
                unless exists($self->{declarations}{$row->{reduction_origin}{source_name}});
        }
        if (exists($row->{bitwise_origin})) {
            my @operands = @{$row->{bitwise_origin}{source_names}};
            $self->_fail('binary bitwise intermediate requires actual declared operands')
                if grep {!exists($self->{declarations}{$_})} @operands;
        }
        if (exists($row->{arithmetic_origin})) {
            my @operands = @{$row->{arithmetic_origin}{source_names}};
            $self->_fail('binary arithmetic intermediate requires actual declared operands')
                if grep {!exists($self->{declarations}{$_})} @operands;
        }
        if (exists($row->{width_allocation})) {
            my @operands = @{$row->{width_allocation}{source_names}};
            my @declarations = map {$self->{declarations}{$_}} ($name, @operands);
            $self->_fail('width allocation requires actual plain unsigned declarations')
                if grep {$_->{signed} || defined($_->{state_model})
                    || defined($_->{declared_type_name}) || defined($_->{declared_type_spec})} @declarations;
            $self->_fail('width allocation requires the exact declared operand maximum and result width')
                unless FSM::IntermediateWidthAllocationSupport->matches_selected_widths(
                    $row->{width_allocation}, map {$_->{width}} @declarations);
        }
    }
    $self->{state} = 'complete';
    return;
}

sub snapshot ($self) {
    confess "Direct declaration capture requires completed declaration generation\n" unless $self->{state} eq 'complete';
    my %namespace = (module_name => $self->{module_name}, identifier_map => {},
        parameter_names => $self->{parameter_order});
    for my $role (qw(ports signals constants types)) {
        $namespace{$role} = [sort grep {$self->{names}{$_} eq $role} keys %{$self->{names}}];
    }
    my $json = JSON::PP->new->canonical;
    return $json->decode($json->encode({target_namespace => \%namespace,
        target_declarations => $self->{declarations},
        (keys(%{$self->{intermediates} // {}}) ? (target_intermediates => $self->{intermediates}) : ())}));
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::DeclarationCapture - Opt-in actual direct emission snapshots

=head1 DESCRIPTION

An explicitly supplied C<declared_width_declaration_capture> on a direct backend
context receives actual declaration events from the existing emitters. Direct
captured-parameter/width preparation also installs a per-generation collector;
legacy uncaptured generation retains its existing path. C<begin_module> starts a new transaction;
generation reset invalidates previous state and only full successful assembly
calls C<complete>. Failed or incomplete generations supply no C<snapshot>.

Actual parameter order, port/storage/state/enable/intermediate names and selected
numeric/type metadata come from existing emission points. No HDL is parsed or
regenerated to obtain membership. Allocated aggregate typedef names deduplicate
across uses. Other duplicate owners, invalid rows and non-JSON graphs refuse
and invalidate the transaction. Target legality remains separate preparation.

Actual internal register-helper rows may additionally contain C<width_origin>,
a closed C<{kind, source_name}> record. The allocation kind is C<register_next>
or C<register_q>; C<source_name> identifies the actual assignment parent at
allocation, independently of numeric width equality or suffix interpretation.
Only signal rows accept this field. The parent must be a different simple name
and have its own declaration row when the transaction completes. Malformed or
missing-parent origins invalidate the transaction. Origins detach with the rest
of each row; absent fields preserve the old snapshot shape. Pulse-delay,
enable, source-owned and other unrelated declarations acquire no origin.
This metadata does not prove a caller-made allocation or a symbolic width/type
relationship; qualified range consumers retain those obligations.

Actual prepared intermediates use C<record_intermediate_declaration>, then
C<record_intermediate_assignment> at their selected assign emission. The optional
C<target_intermediates> snapshot map contains every such declared name: an empty
row means no assignment was emitted; otherwise C<expression> retains the exact
selected text. A C<reduction_origin> additionally holds closed
C<{kind =E<gt> scalar_reduction, operator, source_name}> metadata for typed whole
SignalRef XOR/AND/OR whose defining/runtime ASTs and fresh rendering agree.
Result width must be one and the operand must have its own actual declaration.
Other rendered expressions retain text without an origin. Unknown or duplicate
assignment owners, malformed records and missing operands invalidate the
transaction. Records detach on input/output; a generation with no intermediates
omits this map, preserving the legacy empty shape. The publisher supplies no
source unsigned/type proof and activates no symbolic intermediate consumer.

A separate optional C<bitwise_origin> is closed
C<{kind =E<gt> binary_bitwise, operator, source_names =E<gt> [left, right]}>.
Canonical binary XOR/AND/OR over typed whole SignalRefs must agree across
actual defining/runtime/cached ASTs and fresh selected expression rendering.
Both ordered operand slots retain, including duplicates; names must differ
from the result and have actual declaration rows at completion. The origin
families are mutually exclusive. Selected operand and result widths remain
separate numeric constraints: context-widened or truncated result declarations
are valid and do not imply an intrinsic maximum-width allocation policy.
The event proves no mutable width equivalence or symbolic range eligibility.
Malformed, conflicting or missing-operand records invalidate the transaction.

The optional C<arithmetic_origin> uses the same ordered slots and syntactic
checks with C<kind =E<gt> binary_arithmetic> and canonical C<+>, C<->, C<*>, C</>
or C<%>. It is exclusive with both other origin families. Actual operand
membership is required, while contextual widths remain independent without
allocation policy. Arithmetic event publication alone enables no symbolic range.

An optional C<width_allocation> additionally carries the separate closed
C<{kind =E<gt> binary_operand_max, operator, source_names, selected_width}>
policy. It requires the same ordered C<bitwise_origin> or C<arithmetic_origin>.
On completion the actual
result and both operand declarations must be plain unsigned, without state or
named-type metadata, and their exact decimal widths must satisfy the selected
intrinsic maximum. Scalar JSON kinds and duplicate slots preserve. Malformed,
conflicting, typed, missing or width-inconsistent policies invalidate atomically.
Absent policy fields preserve independent contextual widths and old snapshots.
Schema/numeric validation alone supplies no source provenance. The actual
assignment publisher obtains current completed backend policy and rechecks fresh
AST/text and plain operand profiles. Symbolic range admission remains separate.

C<snapshot> returns detached C<target_namespace> and C<target_declarations> in
the C<DirectDeclaredWidthSupport::prepare_declarations> input format. It retains
no module, Signal, backend or collector owner. This private publisher does not
activate symbolic ranges or change ordinary HDL, and it does not repair the
independent backend context/helper ownership cycle.

=cut
