package FSM::Support::ISFWidthForwarding;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(build_width_forwarding_plan remap_width_forwarding_plan);

sub build_width_forwarding_plan {
    my ($ir) = @_;
    confess "Width forwarding requires a module IR\n" unless ref($ir) eq 'HASH';
    my @instances;
    for my $instance (@{$ir->{spawn_instances} || []}) {
        push @instances, {instance => $instance->{instance}, module => $instance->{child},
            selection => ($ir->{_width_scopes}{generated_instances} || {})->{$instance->{instance}}};
    }
    for my $instance (@{$ir->{library_uses} || []}) {
        push @instances, {instance => $instance->{instance}, module => $instance->{module}};
    }
    for my $top (@{$ir->{atl_top_instances} || []}) {
        my @children = ref($top->{children}) eq 'ARRAY' ? @{$top->{children}} : ($top);
        push @instances, map {{instance => $_->{instance}, module => $_->{child_module}}} @children;
    }
    # No composition parent instance is emitted for a module without children.
    return undef unless @instances;
    confess "Width forwarding requires the actual producer module identity\n"
        unless defined($ir->{actor_name}) && !ref($ir->{actor_name}) && length($ir->{actor_name});

    my $symbols = $ir->{_width_symbols};
    confess "Width forwarding requires final producer symbols\n" unless ref($symbols) eq 'HASH';
    my $scope = $symbols->{module_parameters};
    my $scope_key = _scope_key($scope);
    my %parameters = map {$_->{name} => 1} @{$ir->{params} || []};
    my (%contexts, %context_names);
    for my $context (@{$symbols->{capture_parameters}}) {
        my $key = _capture_key($context->{source});
        _require_context_name($context->{name});
        confess "Width forwarding has duplicate producer context identity\n" if exists $contexts{$key};
        confess "Width forwarding producer context conflicts with declared parameter '$context->{name}'\n"
            if $parameters{$context->{name}} || $context_names{$context->{name}}++;
        $contexts{$key} = $context->{name};
    }

    my (%seen, @bound);
    for my $instance (@instances) {
        my ($name, $module) = @{$instance}{qw(instance module)};
        confess "Width forwarding lacks actual instance/module identity\n"
            unless defined($name) && !ref($name) && length($name)
                && defined($module) && !ref($module) && length($module);
        confess "Width forwarding has duplicate actual instance '$name'\n" if $seen{$name}++;
        my $child = ($ir->{children} || {})->{$module};
        confess "Width forwarding cannot find actual child module '$module' for instance '$name'\n"
            unless ref($child) eq 'HASH' && ref($child->{_width_symbols}) eq 'HASH';
        my $selection = $instance->{selection} // $child->{_width_scopes}{instance};
        confess "Width forwarding lacks canonical selection for actual instance '$name'\n"
            unless ref($selection) eq 'HASH';
        my %child_parameters = map {$_->{name} => 1} @{$child->{params} || []};
        my %overrides = map {$_->{name} => 1} @{$selection->{parameter_overrides} || []};
        my (%targets, @bindings);
        for my $target (@{$child->{_width_symbols}{capture_parameters}}) {
            my $target_name = $target->{name};
            _require_context_name($target_name);
            confess "Width forwarding context target conflicts with real child parameter '$target_name'\n"
                if $child_parameters{$target_name};
            confess "Width forwarding context target conflicts with authored override '$target_name'\n"
                if $overrides{$target_name};
            confess "Width forwarding has duplicate child context target '$target_name'\n" if $targets{$target_name}++;
            my $source = $target->{source};
            my $key = _capture_key($source);
            my ($source_parameter, $source_kind);
            if (_scope_key($source->{scope}) eq $scope_key && $parameters{$source->{token}}) {
                ($source_parameter, $source_kind) = ($source->{token}, 'module_parameter');
            } elsif (exists $contexts{$key}) {
                ($source_parameter, $source_kind) = ($contexts{$key}, 'context_parameter');
            } else {
                confess "Width forwarding has no declared producing parameter for actor capture '$source->{token}' at instance '$name'\n";
            }
            push @bindings, {target_parameter => _copy($target_name), source_parameter => _copy($source_parameter),
                source_kind => $source_kind, source_identity => _copy($source)};
        }
        push @bound, {instance => _copy($name), module => _copy($module),
            module_parameters => _copy($child->{_width_symbols}{module_parameters}),
            selection => _copy($selection), bindings => \@bindings};
    }
    return {producer => {module => _copy($ir->{actor_name}), instance => _copy($ir->{actor_name}),
        module_parameters => _copy($scope)}, instances => \@bound};
}

sub remap_width_forwarding_plan {
    my ($plan, $names) = @_;
    confess "Width forwarding requires a normal composition plan and final domain maps\n"
        unless ref($plan) eq 'HASH' && ref($plan->{producer}) eq 'HASH'
            && ref($plan->{instances}) eq 'ARRAY' && ref($names) eq 'HASH'
            && ref($names->{instances}) eq 'HASH' && ref($names->{modules}) eq 'HASH';
    my $mapped = _copy($plan);
    $mapped->{producer}{instance} = _domain_name($names->{instances}, $plan->{producer}{instance}, 'instance');
    # The parent definition module is already the actual scheduled domain
    # module. The module map belongs to child definitions, even if a child key
    # happens to have the same spelling as the parent definition.
    for my $instance (@{$mapped->{instances}}) {
        $instance->{instance} = _domain_name($names->{instances}, $instance->{instance}, 'instance');
        $instance->{module} = _domain_name($names->{modules}, $instance->{module}, 'module');
    }
    return $mapped;
}

sub _domain_name {
    my ($map, $logical, $role) = @_;
    confess "Width forwarding requires actual domain $role mapping\n"
        unless defined($logical) && !ref($logical) && length($logical);
    my $actual = $map->{$logical};
    confess "Width forwarding requires actual domain $role mapping for '$logical'\n"
        unless defined($actual) && !ref($actual) && length($actual);
    return _copy($actual);
}

sub _require_context_name {
    my ($name) = @_;
    confess "Width forwarding requires a named context parameter slot\n"
        unless defined($name) && !ref($name) && $name =~ /\A[A-Za-z_][A-Za-z_0-9]*\z/;
}

sub _capture_key {
    my ($source) = @_;
    confess "Width forwarding requires an actor capture identity\n"
        unless ref($source) eq 'HASH' && ($source->{kind} // '') eq 'capture'
            && ref($source->{scope}) eq 'HASH' && ($source->{scope}{kind} // '') eq 'actor'
            && defined($source->{token}) && !ref($source->{token}) && length($source->{token});
    return join("\0", _scope_key($source->{scope}), $source->{token});
}

sub _scope_key {
    my ($scope) = @_;
    confess "Width forwarding requires a canonical parameter scope\n"
        unless ref($scope) eq 'HASH' && defined($scope->{kind}) && !ref($scope->{kind})
            && ($scope->{kind} eq 'actor' || $scope->{kind} eq 'transaction')
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner})
            && ($scope->{kind} ne 'transaction'
                || (defined($scope->{actor}) && !ref($scope->{actor}) && length($scope->{actor})));
    return join("\0", $scope->{kind}, $scope->{kind} eq 'transaction' ? $scope->{actor} : '', $scope->{owner});
}

sub _copy {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Width forwarding contains an unsupported reference\n";
}

1;

=head1 NAME

FSM::Support::ISFWidthForwarding - Private actual-instance width context bindings

=head1 DESCRIPTION

C<build_width_forwarding_plan($ir)> joins actual spawn, generated do, rule-trigger,
library and ATL instance records to their child module symbol plans. It returns
detached C<producer> and C<instances> records, or undef when no composition parent
instance will be emitted. Each instance retains its canonical C<selection>
environment, real parameter scope and automatic context C<bindings>.

Every instantiated child context target binds to a declared producer parameter
or an explicitly imported producer context with the identical actor scope and
token. C<source_identity> retains that lexical capture; C<source_parameter> and
C<source_kind> identify the producing module slot. Equal defaults, names in an
unrelated lexical environment and physical-name prefixes cannot supply a slot.
Conflicting real parameters, authored overrides and duplicate targets refuse.
Existing selected defaults and authored override sources remain separate.

C<remap_width_forwarding_plan($plan, $names)> consumes final actual domain name
maps and returns a detached plan with the producer instance and child
instance/module identities mapped. The parent definition module is already
explicit and stays outside the child-module map. Lexical scopes, local parameter
slots and selected source environments remain exact. Missing actual mappings
refuse instead of falling back to guessed names.

These plans change no source, HDL, public report or parameter value. Canonical
top configuration and symbolic source emission remain separately required.
Normal producer identity follows the composition emitter's parent-instance
contract; domain realization applies its final maps after collision allocation.

=cut
