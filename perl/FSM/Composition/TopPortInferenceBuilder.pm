package FSM::Composition::TopPortInferenceBuilder;

=head1 NAME

FSM::Composition::TopPortInferenceBuilder - Builder for inferred composition top ports

=head1 DESCRIPTION

Builds the bounded inferred top-port families used by the active multi-child
composition lanes. This package owns explicit-toplink top-port inference plus
same-name undeclared top-input and top-output inference.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::Port;

sub augment_ports ($class, %args) {
    my $ports = $args{ports} || [];
    my $toplinks = $args{toplinks} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my $augmented_ports = $class->augment_from_explicit_links(
        ports => $ports,
        toplinks => $toplinks,
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
    );
    $augmented_ports = $class->augment_undeclared_top_inputs(
        ports => $augmented_ports,
        toplinks => $toplinks,
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
    );
    $augmented_ports = $class->augment_undeclared_top_outputs(
        ports => $augmented_ports,
        toplinks => $toplinks,
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
    );

    return $augmented_ports;
}

sub augment_from_explicit_links ($class, %args) {
    my @ports = @{$args{ports} || []};
    my $toplinks = $args{toplinks} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my %declared_by_name = map { $_->name => $_ } @ports;
    my %instances_by_name;
    my %child_ports_by_instance;
    my %inferred_specs;

    for my $instance (@$realized_instances) {
        $instances_by_name{$instance->instance_name} = $instance;
        $child_ports_by_instance{$instance->instance_name}
            = FSM::Composition::LinkedPlanBuilder->index_ports_by_name($instance->interface_ports);
    }

    for my $toplink (@$toplinks) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            my $target = $link->target || '';

            my ($source_top_name) = $source =~ /^(\w+)$/;
            my ($target_top_name) = $target =~ /^(\w+)$/;
            my $source_is_top = defined $source_top_name;
            my $target_is_top = defined $target_top_name;

            if ($source_is_top && !$declared_by_name{$source_top_name} && $target =~ /^\w+\.\w+$/) {
                my $child_endpoint = FSM::Composition::LinkedPlanBuilder->resolve_endpoint(
                    $target,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                $class->_record_inferred_top_port(
                    \%inferred_specs,
                    $source_top_name,
                    'input',
                    $child_endpoint,
                    $source.' -> '.$target,
                    $fsm_file,
                    $header,
                );
            }

            if ($target_is_top && !$declared_by_name{$target_top_name} && $source =~ /^\w+\.\w+$/) {
                my $child_endpoint = FSM::Composition::LinkedPlanBuilder->resolve_endpoint(
                    $source,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                $class->_record_inferred_top_port(
                    \%inferred_specs,
                    $target_top_name,
                    'output',
                    $child_endpoint,
                    $source.' -> '.$target,
                    $fsm_file,
                    $header,
                );
            }
        }
    }

    my @inferred_ports = map {
        FSM::Composition::Port->new(
            name => $_->{name},
            direction => $_->{direction},
            width => $_->{width},
            type => $_->{type},
            raw_token => undef,
            binding_mode => 'explicit',
            origin_kind => 'inferred_explicit_toplink_port',
        )
    } values %inferred_specs;

    @inferred_ports = _sort_ports(@inferred_ports);
    return [@ports, @inferred_ports];
}

sub augment_undeclared_top_inputs ($class, %args) {
    my @ports = @{$args{ports} || []};
    my $toplinks = $args{toplinks} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my %declared_by_name = map { $_->name => $_ } @ports;
    my %port_groups = _port_groups_from_instances($realized_instances)->%*;
    my %explicitly_linked_child_input_names;
    my %same_name_undeclared_top_input_links;

    for my $toplink (@$toplinks) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            my $target = $link->target || '';
            my ($target_port_name) = $target =~ /^\w+\.(\w+)$/;
            next unless defined $target_port_name;
            my $source_is_child_endpoint = $source =~ /^\w+\.\w+$/;
            my $source_is_actual = $source =~ /^=/;
            my ($source_top_port_name) = $source =~ /^(\w+)$/;
            my $source_is_declared_top_port = defined($source_top_port_name) && $declared_by_name{$source_top_port_name};
            if (defined($source_top_port_name) && !$source_is_declared_top_port && $source_top_port_name eq $target_port_name) {
                $same_name_undeclared_top_input_links{$target_port_name} = 1;
                next;
            }
            next unless $source_is_child_endpoint || $source_is_declared_top_port || $source_is_actual;
            $explicitly_linked_child_input_names{$target_port_name} = 1;
        }
    }

    my @inferred_ports;
    for my $port_name (sort keys %port_groups) {
        next if $declared_by_name{$port_name};
        next if $explicitly_linked_child_input_names{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @candidates;
        next unless @input_candidates;
        next unless @input_candidates == @candidates;

        my %widths = map { $_->{port}->width => 1 } @input_candidates;
        if (keys(%widths) > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @input_candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-input inference is blocked because same-name child inputs disagree on width. ".
                "Seen child inputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top inputs when all same-name child inputs agree exactly on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %types = map { FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type) => 1 } @input_candidates;
        if (keys(%types) > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}->type).']'
            } @input_candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-input inference is blocked because same-name child inputs disagree on interface type. ".
                "Seen child inputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top inputs when all same-name child inputs agree exactly on type metadata too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $template = $input_candidates[0]{port};
        push @inferred_ports, FSM::Composition::Port->new(
            name => $template->name,
            direction => 'input',
            width => $template->width,
            type => FSM::Composition::InterfacePortBuilder->normalized_interface_type($template->type),
            raw_token => undef,
            binding_mode => $same_name_undeclared_top_input_links{$template->name}
                ? 'explicit'
                : 'implicit_fanout',
            origin_kind => 'inferred_undeclared_top_input_port',
        );
    }

    @inferred_ports = _sort_ports(@inferred_ports);
    return [@ports, @inferred_ports];
}

sub augment_undeclared_top_outputs ($class, %args) {
    my @ports = @{$args{ports} || []};
    my $toplinks = $args{toplinks} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my %declared_by_name = map { $_->name => $_ } @ports;
    my %port_groups = _port_groups_from_instances($realized_instances)->%*;
    my %explicitly_linked_child_output_endpoints;

    for my $toplink (@$toplinks) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            next unless $source =~ /^(\w+)\.(\w+)$/;
            $explicitly_linked_child_output_endpoints{"$1.$2"} = 1;
        }
    }

    my @inferred_ports;
    for my $port_name (sort keys %port_groups) {
        next if $declared_by_name{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @candidates;
        next unless @output_candidates;
        next unless @output_candidates == @candidates;

        my @top_facing_output_candidates = grep {
            !$explicitly_linked_child_output_endpoints{$_->{instance_name}.'.'.$_->{port}->name}
        } @output_candidates;
        next unless @top_facing_output_candidates;

        if (@top_facing_output_candidates > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @top_facing_output_candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-output inference is blocked because several same-name child outputs remain unconsumed by explicit links. ".
                "Seen child outputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top outputs when exactly one same-name child output remains top-facing. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $template = $top_facing_output_candidates[0]{port};
        my $source_endpoint = $top_facing_output_candidates[0]{instance_name}.'.'.$template->name;
        push @inferred_ports, FSM::Composition::Port->new(
            name => $template->name,
            direction => 'output',
            width => $template->width,
            type => FSM::Composition::InterfacePortBuilder->normalized_interface_type($template->type),
            raw_token => $source_endpoint,
            binding_mode => 'implicit_unique_output',
            origin_kind => 'inferred_undeclared_top_output_port',
        );
    }

    @inferred_ports = _sort_ports(@inferred_ports);
    return [@ports, @inferred_ports];
}

sub _record_inferred_top_port ($class, $inferred_specs, $top_name, $direction, $child_endpoint, $evidence, $fsm_file, $header) {
    my $width = $child_endpoint->{port}->width;
    my $type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($child_endpoint->{port}->type);
    my $existing = $inferred_specs->{$top_name};

    if ($existing) {
        if ($existing->{direction} ne $direction) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because that same top endpoint is used as both an input and an output across explicit links. ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on one direction. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($existing->{width} != $width) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on width (".$existing->{width}." vs $width). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($existing->{type} ne $type) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on interface type ('".$existing->{type}."' vs '$type'). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on type metadata too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        push @{$existing->{evidence}}, $evidence;
        return;
    }

    $inferred_specs->{$top_name} = {
        name => $top_name,
        direction => $direction,
        width => $width,
        type => $type,
        evidence => [$evidence],
    };
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

sub _sort_ports (@ports) {
    return sort {
        FSM::Composition::InterfacePortBuilder->system_port_sort_key($a) <=> FSM::Composition::InterfacePortBuilder->system_port_sort_key($b)
        ||
        $a->name cmp $b->name
    } @ports;
}

1;

__END__

=head1 METHODS

=head2 augment_ports

Applies the full bounded top-port inference family in order: explicit-toplink
port inference, undeclared same-name top-input inference, and undeclared
same-name top-output inference.

=head2 augment_from_explicit_links

Infers missing top ports from explicit top-link endpoints when all linked child
endpoints agree on one direction, width, and normalized interface type.

=head2 augment_undeclared_top_inputs

Infers missing top inputs from same-name child inputs when the bounded
same-name fanout convention is satisfied.

=head2 augment_undeclared_top_outputs

Infers missing top outputs from one remaining same-name top-facing child
output when the bounded unique-output convention is satisfied.

=head2 _record_inferred_top_port

Tracks one inferred explicit-toplink port candidate and enforces the bounded
agreement rules on direction, width, and normalized interface type.

=head2 _port_groups_from_instances

Builds a same-name port-group index across realized children for undeclared
top-input and top-output inference.

=head2 _sort_ports

Applies the stable composition port ordering used by inferred top-port
families, with system ports first and names as the secondary key.

=cut
