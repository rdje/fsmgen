package FSM::Support::ISFWidthBindings;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(build_width_binding_plan);

sub build_width_binding_plan {
    my ($metadata) = @_;
    my $scopes = $metadata->{_width_scopes};
    my $declarations = $metadata->{_width_declarations};
    confess "Width binding requires constructor scopes and declarations\n"
        unless ref($scopes) eq 'HASH' && ref($declarations) eq 'HASH'
            && ref($scopes->{actor}) eq 'HASH';
    my $actor_scope = {kind => 'actor', owner => $scopes->{actor}{owner}};
    my $module_scope = $scopes->{module_parameters};
    my $context = {scopes => $scopes, actor_scope => $actor_scope,
        module_key => _scope_key($module_scope), actor_key => _scope_key($actor_scope),
        captures => {}, active => {}, parameter_names => {}};
    my %bound;
    for my $signal (sort keys %$declarations) {
        my $declaration = $declarations->{$signal};
        confess "Width binding lacks source declaration for '$signal'\n"
            unless ref($declaration) eq 'HASH' && ref($declaration->{source}) eq 'HASH'
                && ref($declaration->{scope}) eq 'HASH';
        $bound{$signal} = {declaration => _copy($declaration),
            expression => _bind_default($context, $declaration->{source}, $declaration->{scope})};
    }
    return {module_parameters => _copy($module_scope), declarations => \%bound,
        captures => [map {_copy($context->{captures}{$_})} sort keys %{$context->{captures}}]};
}

sub _bind_parameter {
    my ($context, $scope, $token) = @_;
    my $key = _scope_key($scope);
    my $scopes = $context->{scopes};
    my $environment;
    if ($scope->{kind} eq 'actor') {
        confess "Width binding references an inconsistent actor scope\n" unless $key eq $context->{actor_key};
        $environment = $scopes->{actor};
    } else {
        $environment = ($scopes->{transactions} || {})->{$scope->{owner}};
        confess "Width binding lacks transaction scope '$scope->{owner}'\n"
            unless ref($environment) eq 'HASH'
                && $scope->{actor} eq $context->{actor_scope}{owner}
                && defined($environment->{actor}) && $environment->{actor} eq $scope->{actor}
                && defined($environment->{owner}) && $environment->{owner} eq $scope->{owner};
    }
    if (!exists $context->{parameter_names}{$key}) {
        $context->{parameter_names}{$key} = {map {$_->{name} => 1} @{$environment->{params} || []}};
    }
    confess "Width binding lacks declared parameter '$token' in $scope->{kind} scope '$scope->{owner}'\n"
        unless $context->{parameter_names}{$key}{$token};
    return _reference('parameter', $scope, $token) if $key eq $context->{module_key};

    if ($scope->{kind} eq 'actor') {
        my $capture = _reference('capture', $scope, $token);
        $context->{captures}{join("\0", $key, $token)} ||= _copy($capture);
        return $capture;
    }

    my $identity = join("\0", $key, $token);
    confess "Width binding has cyclic inline parameter '$token'\n" if $context->{active}{$identity};
    my $binding = ($environment->{parameter_default_bindings} || {})->{$token};
    confess "Width binding lacks canonical default for inline parameter '$token'\n"
        unless ref($binding) eq 'HASH';
    local $context->{active}{$identity} = 1;
    return {kind => 'inline_parameter', scope => _copy($scope), token => _copy($token),
        default => _bind_default($context, $binding, $scope)};
}

sub _bind_default {
    my ($context, $binding, $lexical_scope) = @_;
    my $kind = $binding->{kind} // '';
    my $token = $binding->{token};
    my $actor_scope = $context->{actor_scope};
    confess "Width binding lacks a scalar source token\n" unless defined($token) && !ref($token);
    if ($kind eq 'actor_parameter' || $kind eq 'actor_constant') {
        confess "Width binding references an inconsistent actor scope\n"
            if exists($binding->{owner}) && $binding->{owner} ne $actor_scope->{owner};
        return _bind_parameter($context, $actor_scope, $token) if $kind eq 'actor_parameter';
        return _reference('constant', $actor_scope, $token);
    }
    if ($kind eq 'transaction_parameter') {
        confess "Width binding references an inconsistent transaction scope\n"
            unless $lexical_scope->{kind} eq 'transaction'
                && (!exists($binding->{owner}) || $binding->{owner} eq $lexical_scope->{owner});
        return _bind_parameter($context, $lexical_scope, $token);
    }
    if ($kind eq 'package_constant') {
        confess "Width binding lacks the selected package owner\n"
            unless defined($binding->{owner}) && !ref($binding->{owner}) && length($binding->{owner});
        return _reference('package_constant', {kind => 'package', owner => $binding->{owner}}, $token);
    }
    # Enum tokens retain their actual actor lookup environment and full
    # local or package-qualified spelling. No enum value is re-resolved.
    return _reference('enum_member', $actor_scope, $token) if $kind eq 'enum_member';
    return {kind => 'literal', token => _copy($token)} if $kind eq 'literal';
    confess "Width binding has unsupported scalar source kind '$kind'\n";
}

sub _scope_key {
    my ($scope) = @_;
    confess "Width binding lacks a canonical parameter scope\n"
        unless ref($scope) eq 'HASH' && defined($scope->{kind}) && !ref($scope->{kind})
            && ($scope->{kind} eq 'actor' || $scope->{kind} eq 'transaction')
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner})
            && ($scope->{kind} ne 'transaction'
                || (defined($scope->{actor}) && !ref($scope->{actor}) && length($scope->{actor})));
    return join("\0", $scope->{kind}, $scope->{kind} eq 'transaction' ? $scope->{actor} : '', $scope->{owner});
}

sub _reference {
    my ($kind, $scope, $token) = @_;
    return {kind => $kind, scope => _copy($scope), token => _copy($token)};
}

sub _copy {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Width binding contains an unsupported reference\n";
}

1;

=head1 NAME

FSM::Support::ISFWidthBindings - Private lexical expressions for scalar width lowering

=head1 DESCRIPTION

C<build_width_binding_plan($metadata)> consumes final constructor width
declarations, explicit module parameter ownership and canonical default-binding
observations. It returns detached C<module_parameters>, C<declarations> and
C<captures>. Each physical declaration retains its complete source descriptor
beside a typed expression.

Real module parameters remain C<parameter> references. Actor parameters outside
that module become C<capture> references. Non-module transaction parameters
become C<inline_parameter> nodes whose nested C<default> preserves each alias.
Static nodes preserve constant, package and enum identities; literal nodes
preserve tokens. Enum references retain their actor lookup environment and full
qualified token. Captures are deduplicated by lexical identity, without sharing
mutable containers with declaration expressions.

This is private semantic groundwork, with no new evaluation or target names.
Module-parameter default supporting graphs, symbol allocation, instance
forwarding, IAL0 carrier emission, generic HDL and public dependency reports
remain separate compiler stages.

=cut
