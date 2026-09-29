package FSM::Scheduler::ISF::DomainSource;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use FSM::Support::ISFResetProvenance qw(snapshot_reset_provenance);
use feature qw(signatures);
no warnings 'experimental::signatures';

our @EXPORT_OK = qw(_domain_actor_for_scheduled_artifact _entry_domain);

# Construct the same detached domain source for executable realization and
# formal preparation. This selects ownership and injects crossing contracts;
# it does not build or finalize a parent IR.
sub _domain_actor_for_scheduled_artifact($actor, $domain, $default_domain) {
    my $domain_name = $domain->{name};
    confess "FSM::Scheduler::ISF->lower domain metadata is missing a scalar domain name\n"
        unless defined($domain_name) && !ref($domain_name) && length($domain_name);

    my $module_name = $domain->{scheduled_fsm};
    $module_name =~ s/\.fsm\z//;

    my %transaction_names = map {
        $_->{name} => 1
    } grep {
        _entry_domain($_, $default_domain) eq $domain_name
    } @{$actor->{transactions} || []};
    my %rule_names = map {
        $_->{name} => 1
    } grep {
        _entry_domain($_, $default_domain) eq $domain_name
    } @{$actor->{rules} || []};
    my %owner_names = (%transaction_names, %rule_names);

    my %domain_actor = %{_clone_isf_value($actor)};
    $domain_actor{actor_name} = $module_name;
    $domain_actor{clock} = $domain->{clock};
    $domain_actor{reset} = _clone_isf_value($domain->{reset});
    my $reset_provenance = snapshot_reset_provenance($actor->{reset_provenance});
    $domain_actor{reset_provenance} = [
        grep { defined($_->{domain}) && $_->{domain} eq $domain_name } @$reset_provenance
    ] if defined $reset_provenance;
    $domain_actor{clock_domains} = undef;
    $domain_actor{_scheduled_domain_name} = $domain_name;
    $domain_actor{interface} = {
        inputs => [
            map { _clone_isf_value($_) }
            grep { _entry_domain($_, $default_domain) eq $domain_name }
            @{$actor->{interface}{inputs} || []}
        ],
        outputs => [
            map { _clone_isf_value($_) }
            grep { _entry_domain($_, $default_domain) eq $domain_name }
            @{$actor->{interface}{outputs} || []}
        ],
    };
    _add_crossing_endpoint_ports($actor, \%domain_actor, $domain_name);
    _inject_activation_external_activations($actor, \%domain_actor, $domain_name);
    $domain_actor{storage} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{storage} || []}
    ];
    $domain_actor{transactions} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{transactions} || []}
    ];
    $domain_actor{rules} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{rules} || []}
    ];
    $domain_actor{library_uses} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{library_uses} || []}
    ];
    $domain_actor{resources} = _domain_resources($actor, \%rule_names);
    $domain_actor{priorities} = _domain_priorities($actor, \%owner_names);

    return \%domain_actor;
}

sub _add_crossing_endpoint_ports($actor, $domain_actor, $domain_name) {
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        if (($crossing->{from}{domain} // '') eq $domain_name) {
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{from}{signal},
                'output',
                "crossing event '$crossing->{name}' request",
            );
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{ready}{signal},
                'input',
                "crossing event '$crossing->{name}' ready",
            );
        }
        if (($crossing->{to}{domain} // '') eq $domain_name) {
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{to}{signal},
                'input',
                "crossing event '$crossing->{name}' destination pulse",
            );
        }
    }
    return 1;
}

sub _inject_activation_external_activations($actor, $domain_actor, $domain_name) {
    my @activations;
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ref($crossing) eq 'HASH' && ($crossing->{kind} // '') eq 'activation';
        my $child = $crossing->{child};
        next unless defined($child) && !ref($child) && length($child);
        my $from = $crossing->{from}{domain} // '';
        my $to   = $crossing->{to}{domain} // '';
        my $role;
        if ($from eq $domain_name)  { $role = 'caller'; }
        elsif ($to eq $domain_name) { $role = 'callee'; }
        else                        { next; }
        push @activations, {
            child        => $child,
            role         => $role,
            start_signal => "${child}_start",
            done_signal  => "${child}_done",
        };
    }
    $domain_actor->{external_activations} = \@activations if @activations;
    return 1;
}

sub _ensure_domain_interface_port($interface, $name, $direction, $context) {
    return 1 unless defined($name) && !ref($name) && length($name);
    for my $existing_direction (qw(inputs outputs)) {
        for my $port (@{$interface->{$existing_direction} || []}) {
            next unless $port->{name} eq $name;
            my $port_direction = $existing_direction eq 'inputs' ? 'input' : 'output';
            confess "FSM::Scheduler::ISF->lower $context endpoint '$name' conflicts with an existing $port_direction port\n"
                unless $port_direction eq $direction;
            confess "FSM::Scheduler::ISF->lower $context endpoint '$name' conflicts with an existing $direction port of different width\n"
                if ($port->{width} // 1) != 1;
            return 1;
        }
    }
    my $bucket = $direction eq 'input' ? 'inputs' : 'outputs';
    push @{$interface->{$bucket}}, {
        name   => $name,
        width  => 1,
        domain => undef,
    };
    return 1;
}

sub _entry_domain($entry, $default_domain) {
    return ref($entry) eq 'HASH' && defined($entry->{domain})
        ? $entry->{domain}
        : $default_domain;
}

sub _domain_resources($actor, $rule_names) {
    my @resources;
    for my $resource (@{$actor->{resources} || []}) {
        my $copy = _clone_isf_value($resource);
        if (ref($copy->{users}) eq 'ARRAY') {
            $copy->{users} = [ grep { $rule_names->{$_} } @{$copy->{users}} ];
            next unless @{$copy->{users}};
        }
        push @resources, $copy;
    }
    return \@resources;
}

sub _domain_priorities($actor, $owner_names) {
    my @priorities;
    for my $priority (@{$actor->{priorities} || []}) {
        next unless ref($priority) eq 'ARRAY' && @$priority >= 3;
        next unless $owner_names->{$priority->[0]} && $owner_names->{$priority->[2]};
        push @priorities, _clone_isf_value($priority);
    }
    return \@priorities;
}

sub _clone_isf_value($value) {
    return $value unless ref($value);
    return [ map { _clone_isf_value($_) } @$value ] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_isf_value($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    confess "FSM::Scheduler::ISF cannot clone unsupported reference value\n";
}

1;
