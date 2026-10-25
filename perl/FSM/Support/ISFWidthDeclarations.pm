package FSM::Support::ISFWidthDeclarations;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(capture_actor_width_metadata capture_generated_width_metadata);

# Snapshot already admitted declarations. Resolution belongs to the parser and
# canonical lowering parameter/constant resolvers, never to this projection.
sub capture_actor_width_metadata {
    my %args = @_;
    my $actor = $args{actor};
    my $owner = $actor->{_width_source_actor_name} // $actor->{actor_name};
    my $scope = {kind => 'actor', owner => $owner};
    my (%declarations, %depths, %overrides, %transactions);

    for my $pair (['inputs', 'input'], ['outputs', 'output']) {
        for my $port (@{$actor->{interface}{$pair->[0]} || []}) {
            # A projected formal's physical name is not an actor declaration.
            # Its actual identity plan and lexical scope are handled separately.
            next if exists $port->{_isf_formal_identity};
            next unless exists $port->{_width_declaration};
            $declarations{$port->{name}} = {
                scope => _copy($scope), source => _copy($port->{_width_declaration}),
                declaration => {kind => 'interface', name => $port->{name}, direction => $pair->[1]},
            };
        }
    }
    for my $entry (@{$actor->{storage} || []}) {
        $depths{$entry->{name}} = _copy($entry->{_depth_declaration})
            if exists $entry->{_depth_declaration};
        next unless exists $entry->{_width_declaration};
        for my $signal (@{$entry->{signals} || []}) {
            $declarations{$signal->{name}} = {
                scope => _copy($scope), source => _copy($entry->{_width_declaration}),
                declaration => {kind => 'storage', storage_kind => $entry->{kind}, name => $entry->{name},
                    (exists($signal->{index}) ? (index => $signal->{index}) : ())},
            };
        }
    }
    for my $formal (@{$args{direct_formals} || []}) {
        my $port = $formal->{port};
        next unless exists $port->{_width_declaration};
        my $origin = $port->{_isf_formal_identity};
        $declarations{$origin->{physical_name}} = {
            scope => {kind => 'transaction', actor => $owner, owner => $origin->{source}[2]},
            source => _copy($port->{_width_declaration}),
            declaration => {kind => 'transaction_port', name => $origin->{source}[3],
                direction => $formal->{direction}, identity => _copy($origin->{source})},
        };
    }
    for my $use (@{$actor->{library_uses} || []}) {
        $overrides{$use->{instance}} = _copy($use->{_parameter_override_sources})
            if exists $use->{_parameter_override_sources};
    }
    my %source_transactions = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    for my $name (keys %{$args{transaction_params}}) {
        my $tx = $source_transactions{$name};
        confess "Width scope '$name' lacks its source transaction\n" unless $tx;
        my ($params_clause) = grep {
            ref($_) eq 'ARRAY' && @$_ && $_->[0] eq 'params'
        } @{$tx->{clauses} || []};
        # Canonical defaults deliberately literalize actor-backed references.
        # Snapshot the already validated source clause independently so later
        # binding can distinguish that relation from an equal literal default.
        my @sources = $params_clause
            ? map { {name => $_->[0], value => _copy($_->[1])} } @{$params_clause}[1 .. $#$params_clause]
            : ();
        $transactions{$name} = {owner => $name, actor => $owner,
            params => _copy($args{transaction_params}{$name}), parameter_default_sources => \@sources};
    }
    my %instances;
    for my $instance (@{$args{generated_instances} || []}) {
        my $context = $instance->{_width_activation_context};
        confess "Generated activation lacks width source context\n" unless ref($context) eq 'HASH';
        my %overrides = map { $_->{name} => $_ } @{$instance->{parameter_overrides} || []};
        my @parameters = map {
            my $override = $overrides{$_->{name}};
            {name => $_->{name}, source => $override ? 'override' : 'default',
                value => _copy($override ? $override->{value} : $_->{value})}
        } @{$args{transaction_params}{$instance->{child}}};
        $instances{$instance->{instance}} = {
            kind => 'generated_activation', parent_actor => $actor->{actor_name},
            source_actor => $owner, child => $instance->{child}, instance => $instance->{instance},
            activation_kind => $instance->{activation_kind} // 'spawn',
            context => {owner => $context->{owner}, kind => $context->{owner_kind}},
            parameters => \@parameters,
            parameter_overrides => _copy($instance->{parameter_overrides} || []),
            parameter_override_sources => _copy($context->{parameter_override_sources}),
        };
    }
    return {
        _width_declarations => \%declarations,
        _width_scopes => {
            module_parameters => _copy($scope),
            actor => {owner => $owner, params => _copy($args{params}), constants => _copy($args{constants}),
                package_imports => _copy($actor->{package_imports} || []),
                package_constants => _copy(($actor->{constant_symbols} || {})->{packages} || {}),
                enum_symbols => _copy($actor->{enum_symbols} || {local => {}, packages => {}})},
            transactions => \%transactions,
            (keys(%instances) ? (generated_instances => \%instances) : ()),
        },
        _width_static_uses => {scope => _copy($scope), storage_depths => \%depths, library_overrides => \%overrides,
            (exists($actor->{_watchdog_declaration}) ? (watchdog => _copy($actor->{_watchdog_declaration})) : ())},
    };
}

# A generated transaction has its own formal namespace and keeps only selected
# inherited actor ports. Use those actual declarations, then intersect with the
# final physical products; neither default widths nor generated names identify
# a lexical source. Actor storage read ports retain their original declaration.
sub capture_generated_width_metadata {
    my %args = @_;
    my $actor = $args{actor};
    my $tx = $args{transaction};
    my $owner = $actor->{_width_source_actor_name} // $actor->{actor_name};
    my $metadata = capture_actor_width_metadata(%args, direct_formals => []);
    # The generated constructor emits transaction parameters. Inherited actor
    # widths still resolve in the separate actor scope, even if both parameter
    # lists have exactly the same names, values and aliases.
    $metadata->{_width_scopes}{module_parameters} = {
        kind => 'transaction', actor => $owner, owner => $tx->{name},
    };
    my $declarations = $metadata->{_width_declarations};
    for my $pair (['inputs', 'input'], ['outputs', 'output']) {
        for my $port (@{($tx->{ports} || {})->{$pair->[0]} || []}) {
            # Even a literal/type formal shadows a symbolic actor declaration.
            delete $declarations->{$port->{name}};
            next unless exists $port->{_width_declaration};
            $declarations->{$port->{name}} = {
                scope => {kind => 'transaction', actor => $owner, owner => $tx->{name}},
                source => _copy($port->{_width_declaration}),
                declaration => {kind => 'transaction_port', name => $port->{name},
                    direction => $pair->[1],
                    identity => ['transaction_port', $owner, $tx->{name}, $port->{name}]},
            };
        }
    }
    # The auxiliary width table can retain inherited names after port pruning.
    # All authored declarations realized here are ports, including storage reads.
    my %physical = map { $_->{name} => 1 } @{$args{ports}};
    delete $declarations->{$_} for grep { !$physical{$_} } keys %$declarations;
    # The child reads scalar ports, not parent-owned banks or library instances.
    $metadata->{_width_static_uses}{storage_depths} = {};
    $metadata->{_width_static_uses}{library_overrides} = {};
    return $metadata;
}

# Copy without serialization or scalar inspection, preserving primitive kinds.
# Every association and environment owns independent mutable containers.
sub _copy {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Width metadata contains an unsupported reference\n";
}

1;
