package FSM::ParameterDefaultEnvironmentSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::Support::HDLInstanceIdentifierPolicy;
use JSON::PP ();
use FSM::ParameterBindingSupport;
use FSM::ParameterDeclarationSupport;
use FSM::ParameterValueSupport;

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

sub prove_binding_observations ($class, %args) {
    my $environment=$class->build_direct_environment(%args);
    my $result={environment=>$environment, reference_observations=>{}, has_parameter_references=>0};
    return $result unless $environment;
    my $json=JSON::PP->new->canonical;
    # Detach before normalization and reject non-JSON/cyclic caller graphs
    # before either the adapter or the existing binder recurses over them.
    my $encoded=eval {$json->encode($args{bindings})};
    die "Parameter binding observation proof requires JSON-safe acyclic records: $@"
        unless defined $encoded;
    my $bindings=$json->decode($encoded);
    my $context={environment=>$environment, json=>$json, statics=>{}};
    my %expressions=map {$_=>_observed_expression($context,$bindings->{$_})}
        @{$environment->{declaration_order}};
    for my $name (@{$environment->{declaration_order}}) {
        my $references=$args{sources}{$name}{references};
        my $bound=FSM::ParameterBindingSupport->bind_expression(
            scope=>$environment->{scope}, parameters=>$environment->{parameters},
            references=>$references, expression=>$expressions{$name},
            resolve_static_symbol_payload=>sub ($token) {
                # A missing actual parameter observation cannot be satisfied
                # by a same-valued captured constant or the compatibility cache.
                return undef if FSM::ParameterDeclarationSupport->declared_reference(
                    $environment->{parameters},$token);
                return $context->{statics}{$token};
            });
        die "Parameter binding observations for '$name' do not match the canonical binding snapshot\n"
            unless $json->encode($bound) eq $json->encode($bindings->{$name});
        $result->{reference_observations}{$name}=[map {
            {parameter=>$_->{parameter},token=>$_->{token},suffix=>$_->{suffix}}
        } @$references];
        $result->{has_parameter_references}=1 if @$references;
    }
    return $result;
}

sub _observed_scope ($context,$scope) {
    my $expected=$context->{environment}{scope};
    die "Parameter binding observation proof has a foreign or missing scope\n"
        unless ref($scope) eq 'HASH' && defined($scope->{kind}) && !ref($scope->{kind})
            && defined($scope->{owner}) && !ref($scope->{owner})
            && $scope->{kind} eq $expected->{kind} && $scope->{owner} eq $expected->{owner};
}

sub _ordered_members ($node) {
    my ($order,$members)=@{$node}{qw(member_order members)};
    die "Parameter binding observation proof requires complete ordered map members\n"
        unless ref($order) eq 'ARRAY' && @$order && ref($members) eq 'HASH' && @$order==keys(%$members);
    my %seen;
    for my $name (@$order) {
        die "Parameter binding observation proof requires unique map members\n"
            unless defined($name) && !ref($name) && exists($members->{$name}) && !$seen{$name}++;
    }
    return $order;
}

sub _observable_payload ($payload) {
    die "Parameter binding observation proof requires a canonical literal payload\n" unless ref($payload) eq 'HASH';
    my $kind=$payload->{kind} // '';
    if ($kind eq 'scalar') {
        FSM::ParameterValueSupport->canonical_value(value_ast=>$payload,context=>'Parameter observation literal');
        return;
    }
    if ($kind eq 'list') {
        die "Parameter binding observation proof requires nonempty payload items\n"
            unless ref($payload->{items}) eq 'ARRAY' && @{$payload->{items}};
        _observable_payload($_) for @{$payload->{items}};
        return;
    }
    if ($kind eq 'map') {
        _observable_payload($payload->{members}{$_}) for @{_ordered_members($payload)};
        return;
    }
    die "Parameter binding observation proof cannot classify opaque scalar-expression or unknown payload '$kind'\n";
}

sub _observed_expression ($context,$node) {
    die "Parameter binding observation proof requires a canonical node\n" unless ref($node) eq 'HASH';
    my $kind=$node->{kind} // '';
    if ($kind eq 'literal') {
        FSM::ParameterValueSupport->canonical_value(value_ast=>$node->{token},context=>'Parameter observation literal');
        return {kind=>'literal',token=>$node->{token}};
    }
    if ($kind eq 'parameter' || $kind eq 'static_symbol') {
        _observed_scope($context,$node->{scope});
        my $token=$node->{token};
        die "Parameter binding observation proof requires a source token\n"
            unless defined($token) && !ref($token) && length($token);
        if ($kind eq 'parameter') {
            my $selected=FSM::ParameterDeclarationSupport->declared_reference($context->{environment}{parameters},$token);
            die "Parameter binding observation proof requires an actual declared reference token\n" unless $selected;
        } else {
            _observable_payload($node->{value_payload});
            my $statics=$context->{statics};
            die "Parameter binding observation proof has conflicting static snapshots for '$token'\n"
                if exists($statics->{$token}) && $context->{json}->encode($statics->{$token})
                    ne $context->{json}->encode($node->{value_payload});
            $statics->{$token}=$node->{value_payload};
        }
        return {kind=>'symbol',token=>$token};
    }
    if ($kind eq 'payload') {
        _observable_payload($node->{value});
        return {kind=>'payload',value=>$node->{value}};
    }
    if ($kind eq 'operator') {
        die "Parameter binding observation proof requires canonical operator operands\n" unless ref($node->{operands}) eq 'ARRAY';
        return {kind=>'operator',operator=>$node->{operator},source_operator=>$node->{source_operator},
            operands=>[map {_observed_expression($context,$_)} @{$node->{operands}}]};
    }
    if ($kind eq 'list') {
        die "Parameter binding observation proof requires canonical list items\n" unless ref($node->{items}) eq 'ARRAY';
        return {kind=>'list',items=>[map {_observed_expression($context,$_)} @{$node->{items}}]};
    }
    if ($kind eq 'map') {
        my $order=_ordered_members($node);
        return {kind=>'map',member_order=>$order,
            members=>{map {$_=>_observed_expression($context,$node->{members}{$_})} @$order}};
    }
    die "Parameter binding observation proof has unknown canonical node kind '$kind'\n";
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

=head2 prove_binding_observations

This opt-in proof consumes the same captured maps. It adapts canonical binding
nodes to C<FSM::ParameterBindingSupport>'s existing observed-expression walk,
rebinds in the original source scope and requires complete canonical snapshot
equality, including JSON kinds and immediate identities. Missing declared
references cannot borrow frozen static values. Repeated reference order and
same-token static selections remain consistent. Literal normalization reuses
C<FSM::ParameterValueSupport>; no second expression evaluator is introduced.

The result contains C<environment>, detached C<reference_observations> and
C<has_parameter_references> as a plain zero/one scalar. Empty coherent inputs
have no environment. Foreign scopes, unknown nodes, cycles, malformed values,
conflicting static snapshots and opaque scalar-expression payloads refuse:
opaque text cannot establish parameter independence. This proves the declared
binding/observation contract, not authorship of caller-made records, target
legality or an HDL profile. Existing header consumers remain on the original
membership validator until separately selected integration.

=cut
