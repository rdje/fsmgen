package FSM::Support::ISFWidthDeclarations;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(capture_actor_width_metadata);

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
    for my $name (keys %{$args{transaction_params}}) {
        $transactions{$name} = {owner => $name, actor => $owner,
            params => _copy($args{transaction_params}{$name})};
    }
    return {
        _width_declarations => \%declarations,
        _width_scopes => {
            actor => {owner => $owner, params => _copy($args{params}), constants => _copy($args{constants}),
                package_imports => _copy($actor->{package_imports} || []),
                package_constants => _copy(($actor->{constant_symbols} || {})->{packages} || {}),
                enum_symbols => _copy($actor->{enum_symbols} || {local => {}, packages => {}})},
            transactions => \%transactions,
        },
        _width_static_uses => {scope => _copy($scope), storage_depths => \%depths, library_overrides => \%overrides,
            (exists($actor->{_watchdog_declaration}) ? (watchdog => _copy($actor->{_watchdog_declaration})) : ())},
    };
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
