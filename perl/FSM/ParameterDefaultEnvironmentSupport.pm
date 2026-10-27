package FSM::ParameterDefaultEnvironmentSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::Support::HDLInstanceIdentifierPolicy;

sub build_direct_environment ($class, %args) {
    my ($parameters,$sources,$bindings)=@args{qw(parameters sources bindings)};
    die "Module parameter defaults require declaration, source and binding maps\n"
        unless ref($parameters) eq 'HASH' && ref($sources) eq 'HASH' && ref($bindings) eq 'HASH';
    my $validator=$args{validate_declaration_name};
    die "Module parameter declaration validator requires a callback\n"
        if defined($validator) && ref($validator) ne 'CODE';
    return undef unless keys(%$parameters) || keys(%$sources) || keys(%$bindings);
    die "Module parameter defaults require complete source and binding membership\n"
        unless keys(%$parameters) == keys(%$sources) && keys(%$parameters) == keys(%$bindings)
            && !grep {!exists($sources->{$_}) || !exists($bindings->{$_})} keys %$parameters;
    my $owner;
    for my $name (sort keys %$parameters) {
        my ($info, $source, $binding) = ($parameters->{$name}, $sources->{$name}, $bindings->{$name});
        die "Module parameter default '$name' requires normalized declaration evidence\n"
            unless ref($info) eq 'HASH' && defined($info->{value_kind}) && !ref($info->{value_kind})
                && $info->{value_kind} =~ /\A(?:scalar|list|map)\z/
                && ref($info->{value_payload}) eq 'HASH'
                && defined($info->{value_text}) && !ref($info->{value_text}) && length($info->{value_text});
        die "Module parameter default '$name' requires an actual source declaration\n"
            unless ref($source) eq 'HASH' && ($source->{parameter} // '') eq $name
                && defined($source->{source_module}) && !ref($source->{source_module})
                && length($source->{source_module}) && ref($source->{references}) eq 'ARRAY';
        $owner //= $source->{source_module};
        die "Module parameter default '$name' has a foreign source scope\n"
            unless $source->{source_module} eq $owner;
        die "Module parameter default '$name' requires a canonical binding record\n"
            unless ref($binding) eq 'HASH' && defined($binding->{kind}) && !ref($binding->{kind})
                && $binding->{kind} =~ /\A(?:literal|parameter|static_symbol|payload|operator|list|map)\z/;
        die "Module parameter default '$name' requires a target identifier\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
        $validator->($name) if $validator;
        for my $reference (@{$source->{references}}) {
            die "Module parameter default '$name' has malformed reference observations\n"
                unless ref($reference) eq 'HASH'
                    && !grep {!defined($reference->{$_}) || ref($reference->{$_})} qw(parameter token suffix);
            die "Module parameter default '$name' has inconsistent reference observations\n"
                unless exists($parameters->{$reference->{parameter}})
                    && $reference->{token} eq $reference->{parameter}.$reference->{suffix};
        }
    }
    return {scope => {kind => 'direct_module', owner => $owner}, parameters => $parameters,
        declaration_order => [sort keys %$parameters]};
}

1;

=head1 NAME

FSM::ParameterDefaultEnvironmentSupport - Shared captured direct-module default validation

=head1 DESCRIPTION

C<build_direct_environment> consumes normalized C<parameters>, authored
C<sources> and canonical C<bindings> maps. Nonempty captured sets require exact
membership, complete declaration evidence, one original source owner, known
binding kinds and consistent observed parameter references. Empty coherent
maps return undef without inventing a scope.

The result contains explicit C<direct_module> C<scope>, alphabetical
C<declaration_order> and the supplied C<parameters> snapshot. It retains the
existing read-only temporary-environment contract: the parameter map is reused,
not deep-cloned. Consumers supply the Core getters' detached snapshots. Physical
module copies retain original lexical ownership; a stale/incomplete capture
cannot acquire guessed bindings.

The optional C<validate_declaration_name> callback receives exactly one name
at its original per-declaration position after source/kind checks and before
reference-body validation. A target validator throws to reject a name; its
return value is ignored. Simple identifier shape is shared, while target
reservation policy belongs to the consumer. Callbacks are transient and are
not retained in the returned environment.

This helper validates captured source evidence without evaluating values,
rendering text, choosing an HDL profile or changing a public schema. Caller
records remain read-only. The resulting hash is not independent provenance
attestation for caller-constructed records.

=cut
