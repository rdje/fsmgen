package FSM::Backend::VerilogFamily::DeclarationCapture;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::Support::HDLInstanceIdentifierPolicy;

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
    $self->record_name($role, $copy->{name});
    $self->{declarations}{$copy->{name}} = {map {$_ => $copy->{$_}}
        qw(name width signed state_model declared_type_name declared_type_spec)};
    return;
}

sub record_typedefs ($self, $lookup) {
    $self->_fail('requires actual allocated typedef lookup') unless ref($lookup) eq 'HASH';
    $self->record_name('types', $_) for sort values %$lookup;
    return;
}

sub complete ($self) {
    $self->_fail('cannot complete an inactive declaration transaction') unless $self->{state} eq 'active';
    my @required = grep {$self->{names}{$_} eq 'ports' || $self->{names}{$_} eq 'signals'} keys %{$self->{names}};
    $self->_fail('cannot complete without every numeric declaration row')
        unless @required == keys(%{$self->{declarations}})
            && !grep {!exists($self->{declarations}{$_})} @required;
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
        target_declarations => $self->{declarations}}));
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

C<snapshot> returns detached C<target_namespace> and C<target_declarations> in
the C<DirectDeclaredWidthSupport::prepare_declarations> input format. It retains
no module, Signal, backend or collector owner. This private publisher does not
activate symbolic ranges or change ordinary HDL, and it does not repair the
independent backend context/helper ownership cycle.

=cut
