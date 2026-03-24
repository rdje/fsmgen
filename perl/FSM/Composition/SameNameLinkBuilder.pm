package FSM::Composition::SameNameLinkBuilder;

=head1 NAME

FSM::Composition::SameNameLinkBuilder - Builder for inferred same-name composition links

=head1 DESCRIPTION

Builds the bounded same-name convention links used by the active C2 and C3
composition lanes. This package owns inferred top-input fanout, inferred
top-output selection, and inferred internal same-name carrier links.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::Link;

sub build_top_input_links ($class, %args) {
    my $ports = $args{ports} || [];
    my $explicit_links = $args{explicit_links} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links;
    my %system_port_names = map { $_ => 1 } _system_port_names_from_candidate_endpoints([
        _candidate_endpoints_from_instances($realized_instances)
    ]);
    my %explicit_sources = map { (($_->source || '') => 1) } @$explicit_links;
    my %explicit_targets = map { (($_->target || '') => 1) } @$explicit_links;
    my @candidate_endpoints = _candidate_endpoints_from_instances($realized_instances);

    for my $top_port (@$ports) {
        my $binding_mode = $top_port->binding_mode || 'explicit';
        next unless $binding_mode eq 'implicit_fanout' || ($binding_mode eq 'explicit' && ($top_port->direction || '') eq 'input');
        next if $system_port_names{$top_port->name};

        my @same_name_candidates = grep { $_->{port}->name eq $top_port->name } @candidate_endpoints;
        if ($binding_mode eq 'explicit' && @same_name_candidates) {
            my @direction_incompatible_candidates = grep {
                ($_->{port}->direction || '') ne 'input'
            } @same_name_candidates;
            if (@direction_incompatible_candidates) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.']'
                } @same_name_candidates);
                confess
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."', ".
                    "but same-name top-input convention is blocked because same-name child endpoints include incompatible directions. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring for that family if the mixed-direction naming is intentional. ".
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
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."' with width ".$top_port->width.", ".
                    "but same-name top-input convention is blocked because same-name child inputs do not all match that width. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring or align the interface widths. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }

            my $declared_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($top_port->type);
            my @type_incompatible_candidates = grep {
                FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type) ne $declared_type
            } @same_name_candidates;
            if (@type_incompatible_candidates) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type).']'
                } @same_name_candidates);
                confess
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."' with interface type '$declared_type', ".
                    "but same-name top-input convention is blocked because same-name child inputs do not all match that type metadata. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring or align the interface types. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }
        }

        next if $binding_mode eq 'explicit' && ($explicit_sources{$top_port->name} || $explicit_targets{$top_port->name});

        for my $candidate (@same_name_candidates) {
            next unless ($candidate->{port}->direction || '') eq 'input';
            next unless $candidate->{port}->width == $top_port->width;
            next unless FSM::Composition::InterfacePortBuilder->normalized_interface_type($candidate->{port}->type)
                eq FSM::Composition::InterfacePortBuilder->normalized_interface_type($top_port->type);

            my $target_endpoint = $candidate->{instance_name}.'.'.$candidate->{port}->name;
            next if $binding_mode eq 'explicit' && $explicit_targets{$target_endpoint};

            push @links, FSM::Composition::Link->new(
                source => $top_port->name,
                target => $target_endpoint,
                raw_token => '=implicit:'.$top_port->name,
                origin_kind => $binding_mode eq 'implicit_fanout'
                    ? 'inferred_undeclared_top_input_link'
                    : 'inferred_plain_explicit_top_input_link',
            );
        }
    }

    return \@links;
}

sub build_top_output_links ($class, %args) {
    my $ports = $args{ports} || [];
    my $explicit_links = $args{explicit_links} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links;
    my %explicit_sources = map { (($_->source || '') => 1) } @$explicit_links;
    my %explicit_targets = map { (($_->target || '') => 1) } @$explicit_links;
    my %port_groups = _port_groups_from_instances($realized_instances)->%*;

    for my $top_port (@$ports) {
        my $binding_mode = $top_port->binding_mode || 'explicit';
        next unless $binding_mode eq 'implicit_unique_output' || ($binding_mode eq 'explicit' && ($top_port->direction || '') eq 'output');

        if ($binding_mode eq 'explicit') {
            next if $explicit_sources{$top_port->name} || $explicit_targets{$top_port->name};

            my @same_name_candidates = @{$port_groups{$top_port->name} || []};
            my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @same_name_candidates;
            next if @input_candidates;

            my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @same_name_candidates;
            my @top_facing_output_candidates = grep {
                !$explicit_sources{$_->{instance_name}.'.'.$_->{port}->name}
            } @output_candidates;

            if (@top_facing_output_candidates > 1) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.']'
                } @top_facing_output_candidates);
                confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."', ".
                    "but same-name top-output convention is blocked because several same-name child outputs remain top-facing. ".
                    "Seen child outputs: $candidates. ".
                    "Use explicit '?toplink' wiring if that ambiguity is intentional. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }

            if (@top_facing_output_candidates == 1) {
                my $candidate = $top_facing_output_candidates[0];
                my $candidate_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($candidate->{port}->type);
                my $declared_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($top_port->type);

                confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."' with width ".$top_port->width.", ".
                    "but same-name top-output convention is blocked because the remaining top-facing child output '".$candidate->{instance_name}.'.'.$candidate->{port}->name."' has width ".$candidate->{port}->width.". ".
                    "Use explicit '?toplink' wiring or align the interface widths. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    unless $candidate->{port}->width == $top_port->width;

                confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."' with interface type '$declared_type', ".
                    "but same-name top-output convention is blocked because the remaining top-facing child output '".$candidate->{instance_name}.'.'.$candidate->{port}->name."' has interface type '$candidate_type'. ".
                    "Use explicit '?toplink' wiring or align the interface types. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    unless $candidate_type eq $declared_type;

                push @links, FSM::Composition::Link->new(
                    source => $candidate->{instance_name}.'.'.$candidate->{port}->name,
                    target => $top_port->name,
                    raw_token => '=implicit:'.$top_port->name,
                    origin_kind => 'inferred_plain_explicit_top_output_link',
                );
            }

            next;
        }

        my $source_endpoint = $top_port->raw_token;
        confess
            "Composition source '$header' in '$fsm_file' inferred undeclared top output '".$top_port->name."', ".
            "but the planner lost the unique source endpoint needed to bind it deterministically. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined $source_endpoint && $source_endpoint =~ /^\w+\.\w+$/;

        push @links, FSM::Composition::Link->new(
            source => $source_endpoint,
            target => $top_port->name,
            raw_token => '=implicit:'.$top_port->name,
            origin_kind => 'inferred_undeclared_top_output_link',
        );
    }

    return \@links;
}

sub build_internal_same_name_links ($class, %args) {
    my $ports = $args{ports} || [];
    my $explicit_links = $args{explicit_links} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links;
    my %declared_top_ports = map { $_->name => $_ } @$ports;
    my %system_port_names = map { $_ => 1 } _system_port_names_from_candidate_endpoints([
        _candidate_endpoints_from_instances($realized_instances)
    ]);
    my %explicit_child_endpoints = _explicit_child_endpoints($explicit_links)->%*;
    my %port_groups = _port_groups_from_instances($realized_instances)->%*;

    for my $port_name (sort keys %port_groups) {
        next if $system_port_names{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        next if grep { $explicit_child_endpoints{$_->{instance_name}.'.'.$_->{port}->name} } @candidates;

        my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @candidates;
        my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @candidates;
        next unless @input_candidates && @output_candidates;

        my $declared_top_port = $declared_top_ports{$port_name};
        if ($declared_top_port && ($declared_top_port->direction || '') ne 'output') {
            confess
                "Composition source '$header' in '$fsm_file' declares top port '$port_name' as ".$declared_top_port->direction.", ".
                "but same-name child ports include one driving output and one or more consuming inputs. ".
                "The current bounded convention-over-configuration slice only allows that same-name internal carrier family to be re-exported through an explicit top output, not through a top input of the same name. ".
                "Keep '$port_name' internal by omitting the top port, or declare '$port_name' as an output if it should be re-exported. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %widths = map { $_->{port}->width => 1 } @candidates;
        if (keys(%widths) > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because same-name child ports disagree on width. ".
                "Seen child ports: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when all participating child ports agree exactly on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %types = map { FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type) => 1 } @candidates;
        if (keys(%types) > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type).']'
            } @candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because same-name child ports disagree on interface type. ".
                "Seen child ports: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when all participating child ports agree exactly on resolved interface type too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $resolved_width = $candidates[0]{port}->width;
        my $resolved_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($candidates[0]{port}->type);
        if ($declared_top_port) {
            confess
                "Composition source '$header' in '$fsm_file' declares top output '$port_name' with width ".$declared_top_port->width.", ".
                "but explicit top-output re-export is blocked because the same-name internal-carrier family resolves to width $resolved_width. ".
                "The current bounded convention-over-configuration slice only re-exports an inferred same-name internal carrier when the explicit top output matches the child-side width exactly. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $declared_top_port->width == $resolved_width;

            my $declared_top_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($declared_top_port->type);
            confess
                "Composition source '$header' in '$fsm_file' declares top output '$port_name' with interface type '$declared_top_type', ".
                "but explicit top-output re-export is blocked because the same-name internal-carrier family resolves to interface type '$resolved_type'. ".
                "The current bounded convention-over-configuration slice only re-exports an inferred same-name internal carrier when the explicit top output matches the child-side type metadata exactly. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $declared_top_type eq $resolved_type;
        }

        if (@output_candidates > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @output_candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because several same-name child outputs remain available for same-name child inputs. ".
                "Seen child outputs: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when exactly one same-name child output remains available. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $source = $output_candidates[0];
        my $source_endpoint = $source->{instance_name}.'.'.$source->{port}->name;
        if ($declared_top_port) {
            push @links, FSM::Composition::Link->new(
                source => $source_endpoint,
                target => $declared_top_port->name,
                raw_token => '=implicit-internal:'.$port_name,
                origin_kind => 'inferred_internal_carrier_reexport_link',
            );
        }
        for my $target (@input_candidates) {
            push @links, FSM::Composition::Link->new(
                source => $source_endpoint,
                target => $target->{instance_name}.'.'.$target->{port}->name,
                raw_token => '=implicit-internal:'.$port_name,
                origin_kind => 'inferred_internal_carrier_link',
            );
        }
    }

    return \@links;
}

sub _candidate_endpoints_from_instances ($realized_instances) {
    return map {
        my $instance = $_;
        map {
            {
                instance_name => $instance->instance_name,
                port => $_,
            }
        } @{$instance->interface_ports || []}
    } @{$realized_instances || []};
}

sub _port_groups_from_instances ($realized_instances) {
    my %port_groups;

    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @{$port_groups{$port->name}}, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }

    return \%port_groups;
}

sub _explicit_child_endpoints ($explicit_links) {
    my %explicit_child_endpoints;

    for my $link (@{$explicit_links || []}) {
        for my $endpoint ($link->source, $link->target) {
            next unless defined $endpoint && $endpoint =~ /^(\w+)\.(\w+)$/;
            $explicit_child_endpoints{"$1.$2"} = 1;
        }
    }

    return \%explicit_child_endpoints;
}

sub _system_port_names_from_candidate_endpoints ($candidate_endpoints) {
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

=head2 build_top_input_links

Builds the inferred same-name top-input fanout links for the active explicit
link lanes.

=head2 build_top_output_links

Builds the inferred same-name top-output links for the active explicit link
lanes.

=head2 build_internal_same_name_links

Builds the inferred same-name internal carrier links, including optional
top-output re-export when that bounded convention is valid.

=head2 _candidate_endpoints_from_instances

Builds the shared candidate endpoint list used by the same-name convention
helpers.

=head2 _port_groups_from_instances

Groups realized child endpoints by signal name for same-name matching.

=head2 _explicit_child_endpoints

Collects child endpoints that are already consumed by explicit links so the
same-name convention will not reuse them implicitly.

=head2 _system_port_names_from_candidate_endpoints

Extracts the shared system port names from candidate child endpoints so the
same-name convention ignores clock and reset families.

=cut
