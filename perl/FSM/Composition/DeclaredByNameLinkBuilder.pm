package FSM::Composition::DeclaredByNameLinkBuilder;

=head1 NAME

FSM::Composition::DeclaredByNameLinkBuilder - Builder for C4 declared connect-by-name links

=head1 DESCRIPTION

Builds the bounded C4 declared connect-by-name links used by the current
composition implementation. This package owns same-name endpoint discovery,
system-port exclusion, direction and width validation, input fanout, and
single-output selection for declared C<=port> top ports.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::Link;

sub build_links ($class, %args) {
    my $ports = $args{ports} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links;
    my @candidate_endpoints;
    for my $instance (@$realized_instances) {
        for my $port (@{$instance->interface_ports || []}) {
            push @candidate_endpoints, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }
    my @system_port_names = _system_port_names_from_endpoints(\@candidate_endpoints);
    my %system_port_names = map { $_ => 1 } @system_port_names;

    for my $top_port (@$ports) {
        next unless ($top_port->binding_mode || 'explicit') eq 'connect_by_name';

        confess
            "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
            "but declared connect-by-name is blocked because the shared system ports '".join("' and '", @system_port_names)."' already use the dedicated system-input contract and must not be declared with '=port' connect-by-name syntax. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $system_port_names{$top_port->name};

        my @same_name_candidates = grep { $_->{port}->name eq $top_port->name } @candidate_endpoints;
        my @direction_incompatible_candidates = grep {
            $_->{port}->direction ne $top_port->direction
        } @same_name_candidates;
        if (@direction_incompatible_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because same-name child endpoints include incompatible directions for a top ".$top_port->direction." port. ".
                "Seen same-name child endpoints: $candidates. ".
                "The active C4 lane currently keeps top-boundary connect-by-name direction-strict even when several same-name child ports exist. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my @width_incompatible_candidates = grep {
            $_->{port}->width != $top_port->width
        } @same_name_candidates;
        if (@width_incompatible_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because same-name child endpoints do not all match the declared width ".$top_port->width.". ".
                "Seen same-name child endpoints: $candidates. ".
                "The current active composition lanes require exact width agreement. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($top_port->direction eq 'input') {
            push @links, map {
                FSM::Composition::Link->new(
                    source => $top_port->name,
                    target => $_->{instance_name}.'.'.$_->{port}->name,
                    raw_token => '=byname:'.$top_port->name,
                    origin_kind => 'declared_connect_by_name_link',
                )
            } @same_name_candidates;
            next;
        }

        if (@same_name_candidates > 1) {
            my $candidates = join(', ', map { $_->{instance_name}.'.'.$_->{port}->name } @same_name_candidates);
            confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because that name resolves ambiguously to multiple compatible child endpoints: $candidates. ".
                "The current active C4 lane requires exactly one compatible child output for each '=port' top output declaration. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (@same_name_candidates == 1) {
            my $match = $same_name_candidates[0];
            push @links, FSM::Composition::Link->new(
                source => $match->{instance_name}.'.'.$match->{port}->name,
                target => $top_port->name,
                raw_token => '=byname:'.$top_port->name,
                origin_kind => 'declared_connect_by_name_link',
            );
            next;
        }

        if (@same_name_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because no compatible child endpoint matches its declared direction/width (".$top_port->direction.", width=".$top_port->width."). ".
                "Seen same-name child endpoints: $candidates. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        confess
            "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
            "but declared connect-by-name is blocked because no realized child endpoint with that name exists. ".
            "The current active C4 lane requires each '=port' declaration to match one or more child inputs for top inputs, or exactly one child output for top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    return \@links;
}

sub _system_port_names_from_endpoints ($candidate_endpoints) {
    my %names;
    for my $endpoint (@{$candidate_endpoints || []}) {
        my $port = $endpoint->{port} or next;
        my $type = $port->type || '';
        next unless $type eq 'clock' || $type eq 'reset';
        $names{$port->name} = 1;
    }
    return sort keys %names;
}

1;

__END__

=head1 METHODS

=head2 build_links

Builds the declared connect-by-name links for the active C4 lane and raises the
current lane diagnostics when the by-name rules do not resolve cleanly.

=head2 _system_port_names_from_endpoints

Extracts the reserved shared system port names from candidate child endpoints
so declared by-name matching can reject clock and reset collisions.

=cut
