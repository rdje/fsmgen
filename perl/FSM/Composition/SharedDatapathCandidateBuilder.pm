package FSM::Composition::SharedDatapathCandidateBuilder;

=head1 NAME

FSM::Composition::SharedDatapathCandidateBuilder - Builder for shared-datapath candidate metadata

=head1 DESCRIPTION

Builds the bounded shared-datapath candidate family used by the active
composition lanes. This package owns candidate discovery from structural
instance bindings plus the normalized contributor, peer-read, aggregate-family,
and lift-planning metadata later consumed by lowering, runtime augmentation,
reporting, and CLI summaries.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::ChildExportBuilder;
use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::SharedDatapathSupport;
use FSM::IR::IntentHIR;
use FSM::IR::LoweredRTLIR;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    binding_signal_summaries_by_port
    binding_signal_summary_leaf_signal
    binding_signal_summary_metadata
);

=head2 candidates_for_plan

Returns the shared-datapath candidates already attached to one composition plan,
or rebuilds and stores them when they are not present yet.

=cut

sub candidates_for_plan ($class, %args) {
    my $composition_plan = $args{composition_plan};
    return [] unless $composition_plan;

    if ($composition_plan->can('shared_datapath_candidates')
        && ref($composition_plan->shared_datapath_candidates) eq 'ARRAY'
        && @{$composition_plan->shared_datapath_candidates})
    {
        return $composition_plan->shared_datapath_candidates;
    }

    my $shared_datapath_candidates = $class->build_candidates(%args);
    $composition_plan->{shared_datapath_candidates} = $shared_datapath_candidates;
    return $shared_datapath_candidates;
}

=head2 build_candidates

Builds the shared-datapath candidate surface from one composition plan and the
already-built structural and semantic inputs.

=cut

sub build_candidates ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "SharedDatapathCandidateBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';
    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->coerce(
        $args{structural_rtl_ir}
            // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
                $composition_plan,
                $target_language,
            ),
        $target_language,
    );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;

    my %top_output_by_name = map {
        ((($_->{name}) || '') => $_)
    } grep {
        ((($_->{direction}) || '') eq 'output')
    } @{$structural_rtl_ir_hash->{ports} || []};

    my $children_by_instance = FSM::IR::IntentHIR->composition_children_by_instance_from_input($args{intent_hir});
    my %child_by_instance = $children_by_instance
        ? %$children_by_instance
        : map {
            ((($_->{instance_name}) || '') => $_)
        } @{FSM::Composition::ChildExportBuilder->build_child_exports(
            composition_plan => $composition_plan,
            structural_rtl_ir => $structural_rtl_ir,
            target_language => $target_language,
        )->{children} || []};

    my %candidate_groups;
    my %peer_input_groups;
    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        next unless (($instance->{kind} || '') eq 'fsmc');

        my $binding_signals_by_port = binding_signal_summaries_by_port(
            $instance->{port_bindings}
        );
        my $child = $child_by_instance{$instance->{instance_name}} || {};
        my $drive_family_by_signal = FSM::IR::LoweredRTLIR->output_drive_families_by_signal_from_input(
            $child->{lowered_rtl_ir}
        );

        for my $port (@{$instance->{interface_ports} || []}) {
            next unless (($port->{direction} || '') eq 'output');

            my $normalized_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($port->{type});
            my $key = join "\x1E",
                ($port->{name} // ''),
                ($port->{width} // 1),
                $normalized_type;

            my $drive_family = $drive_family_by_signal->{$port->{name}} || {};
            my $output_drive_family = ref($drive_family) eq 'HASH'
                ? _clone($drive_family)
                : {};
            my $binding_metadata = binding_signal_summary_metadata(
                $binding_signals_by_port->{$port->{name}}
            );
            my $contributor = {
                kind => ($child->{kind} // $instance->{kind}),
                instance_name => ($child->{instance_name} // $instance->{instance_name}),
                module_name => ($child->{module_name} // $instance->{module_name}),
                source_name => ($child->{source_name} // $instance->{source_name}),
                endpoint => (($instance->{instance_name} // 'unknown').'.'.($port->{name} // 'unknown')),
                %{$class->_project_shared_datapath_binding_metadata($binding_metadata)},
                intent_hir => ($child->{intent_hir} || {}),
                lowered_rtl_ir => ($child->{lowered_rtl_ir} || {}),
                structural_rtl_ir => ($child->{structural_rtl_ir} || {}),
                output_drive_family => $output_drive_family,
                drive_intent => $class->drive_intent_from_output_drive_family($output_drive_family),
            };
            my $declared_type_name = FSM::Composition::InterfacePortBuilder->declared_type_name($port);
            my $declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($port);
            $contributor->{declared_type_name} = $declared_type_name if defined $declared_type_name;
            $contributor->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
            push @{$candidate_groups{$key}{contributors}}, $contributor;
            push @{$candidate_groups{$key}{contributor_ports}}, $port;
            $candidate_groups{$key}{signal_name} = $port->{name};
            $candidate_groups{$key}{width} = $port->{width} || 1;
            $candidate_groups{$key}{interface_type} = $normalized_type;
        }

        for my $port (@{$instance->{interface_ports} || []}) {
            next unless (($port->{direction} || '') eq 'input');

            my $normalized_type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($port->{type});
            my $key = join "\x1E",
                ($port->{name} // ''),
                ($port->{width} // 1),
                $normalized_type;
            my $binding_metadata = binding_signal_summary_metadata(
                $binding_signals_by_port->{$port->{name}}
            );

            my $peer_input = {
                instance_name => ($child->{instance_name} // $instance->{instance_name}),
                module_name => ($child->{module_name} // $instance->{module_name}),
                endpoint => (($instance->{instance_name} // 'unknown').'.'.($port->{name} // 'unknown')),
                %{$class->_project_shared_datapath_binding_metadata($binding_metadata)},
            };
            my $declared_type_name = FSM::Composition::InterfacePortBuilder->declared_type_name($port);
            my $declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($port);
            $peer_input->{declared_type_name} = $declared_type_name if defined $declared_type_name;
            $peer_input->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;

            push @{$peer_input_groups{$key}}, $peer_input;
        }
    }

    my @candidates;
    for my $key (sort keys %candidate_groups) {
        my $group = $candidate_groups{$key};
        my @contributors = sort {
            ($a->{instance_name} // '') cmp ($b->{instance_name} // '')
                ||
            ($a->{module_name} // '') cmp ($b->{module_name} // '')
                ||
            ($a->{endpoint} // '') cmp ($b->{endpoint} // '')
        } @{$group->{contributors} || []};
        next unless @contributors >= 2;

        my @contributor_ports = @{$group->{contributor_ports} || []};
        my %typed_declared_type_signatures = map {
            my $signature = FSM::Composition::InterfacePortBuilder->declared_type_signature($_);
            defined($signature) ? ($signature => 1) : ();
        } @contributor_ports;
        next if keys(%typed_declared_type_signatures) > 1;

        my $declared_type_contract = FSM::Composition::InterfacePortBuilder->uniform_declared_type_contract(
            \@contributor_ports
        );

        my %top_output_signals;
        for my $contributor (@contributors) {
            my $bound_signal = binding_signal_summary_leaf_signal($contributor);
            next unless length $bound_signal;
            $top_output_signals{$bound_signal} = 1 if exists $top_output_by_name{$bound_signal};
        }

        my %candidate_carriers = map {
            my $bound_signal = binding_signal_summary_leaf_signal($_);
            length($bound_signal) ? ($bound_signal => 1) : ();
        } @contributors;

        my @peer_input_endpoints = sort {
            ($a->{instance_name} // '') cmp ($b->{instance_name} // '')
                ||
            ($a->{module_name} // '') cmp ($b->{module_name} // '')
                ||
            ($a->{endpoint} // '') cmp ($b->{endpoint} // '')
        } grep {
            my $bound_signal = binding_signal_summary_leaf_signal($_);
            length($bound_signal) && $candidate_carriers{$bound_signal}
        } @{$peer_input_groups{$key} || []};
        my $storage_class = $class->storage_class(\@contributors);
        my %reset_values = map {
            my $output_drive_family = $class->contributor_output_drive_family($_);
            my $reset_value = $output_drive_family->{reset_value};
            defined($reset_value) && length($reset_value)
                ? ($reset_value => 1)
                : ();
        } @contributors;
        my $reset_value = keys(%reset_values) == 1
            ? (sort keys %reset_values)[0]
            : undef;
        my $default_lifted_visibility = (@peer_input_endpoints && $storage_class eq 'registered')
            ? 'internal'
            : (@peer_input_endpoints && $storage_class eq 'combinational' && !keys(%top_output_signals))
                ? 'top_local'
                : 'top_output';
        my @planned_reexport_top_output_signals = $default_lifted_visibility eq 'internal'
            ? sort keys %top_output_signals
            : ();
        my $peer_read_policy = $class->peer_read_policy(
            $storage_class,
            \@peer_input_endpoints,
            [sort keys %top_output_signals],
        );

        my %aggregate_families_by_rhs;
        for my $contributor (@contributors) {
            my $output_drive_family = $class->contributor_output_drive_family($contributor);
            for my $rhs_family (@{$output_drive_family->{rhs_enable_families} || []}) {
                next unless ref($rhs_family) eq 'HASH';
                my $rhs_value = $rhs_family->{rhs_value};
                next unless defined $rhs_value;

                my $aggregate = ($aggregate_families_by_rhs{$rhs_value} ||= {
                    rhs_value => $rhs_value,
                    aggregate_enable_signal => FSM::Composition::SharedDatapathSupport->value_enable_name($group->{signal_name}, $rhs_value),
                    contributors => [],
                });

                push @{$aggregate->{contributors}}, {
                    endpoint => $contributor->{endpoint},
                    family_enable_signal => $rhs_family->{family_enable_signal},
                    source_enable_signal => FSM::Composition::SharedDatapathSupport->source_value_enable_name(
                        $contributor->{instance_name},
                        $group->{signal_name},
                        $rhs_value,
                    ),
                    driver_blocks => [@{$rhs_family->{driver_blocks} || []}],
                    driver_enable_signals => [@{$rhs_family->{driver_enable_signals} || []}],
                };
            }
        }

        my @aggregate_enable_families = map {
            my $family = $aggregate_families_by_rhs{$_};
            my $same_value_conflict_signal = FSM::Composition::SharedDatapathSupport->same_value_conflict_name(
                $group->{signal_name},
                $family->{rhs_value},
            );
            +{
                rhs_value => $family->{rhs_value},
                aggregate_enable_signal => $family->{aggregate_enable_signal},
                same_value_conflict_signal => $same_value_conflict_signal,
                same_value_assertion => FSM::Composition::SharedDatapathSupport->assertion_metadata(
                    $same_value_conflict_signal,
                    [
                        map {
                            $_->{source_enable_signal}
                        } @{$family->{contributors} || []}
                    ],
                ),
                contributor_count => scalar(@{$family->{contributors} || []}),
                contributors => $family->{contributors},
            }
        } sort keys %aggregate_families_by_rhs;

        my $multi_value_conflict_signal = FSM::Composition::SharedDatapathSupport->multi_value_conflict_name($group->{signal_name});

        my $candidate = {
            signal_name => $group->{signal_name},
            width => $group->{width},
            interface_type => $group->{interface_type},
            storage_class => $storage_class,
            reset_value => $reset_value,
            contributor_count => scalar(@contributors),
            contributors => \@contributors,
            top_output_signals => [ sort keys %top_output_signals ],
            peer_input_count => scalar(@peer_input_endpoints),
            peer_input_endpoints => \@peer_input_endpoints,
            default_lifted_visibility => $default_lifted_visibility,
            planned_reexport_top_output_signals => \@planned_reexport_top_output_signals,
            loopback_allowed => (@peer_input_endpoints && $storage_class eq 'registered') ? 1 : 0,
            (%{$peer_read_policy || {}}),
            aggregate_target_enable_signal => FSM::Composition::SharedDatapathSupport->target_enable_name($group->{signal_name}),
            multi_value_conflict_signal => $multi_value_conflict_signal,
            multi_value_assertion => FSM::Composition::SharedDatapathSupport->assertion_metadata(
                $multi_value_conflict_signal,
                [
                    map {
                        $_->{aggregate_enable_signal}
                    } @aggregate_enable_families
                ],
            ),
            aggregate_enable_family_count => scalar(@aggregate_enable_families),
            aggregate_enable_families => \@aggregate_enable_families,
        };
        $candidate->{declared_type_name} = $declared_type_contract->{declared_type_name}
            if defined $declared_type_contract->{declared_type_name};
        $candidate->{declared_type_spec} = $declared_type_contract->{declared_type_spec}
            if defined $declared_type_contract->{declared_type_spec};

        push @candidates, $candidate;
    }

    return \@candidates;
}

=head2 storage_class

Classifies the contributor family as registered, combinational, mixed, or
unknown from contributor drive-family metadata.

=cut

sub storage_class ($class, $contributors) {
    my %types = map {
        my $output_drive_family = $class->contributor_output_drive_family($_);
        my $type = $output_drive_family->{multiplexer_type} // 'unknown';
        ($type => 1);
    } @{$contributors || []};

    return 'registered' if keys(%types) == 1 && $types{flop};
    return 'combinational' if keys(%types) == 1 && $types{comb};
    return 'unknown' if !keys(%types) || (keys(%types) == 1 && $types{unknown});
    return 'mixed';
}

=head2 peer_read_policy

Builds the bounded peer-read policy metadata from one storage class and the
peer/top-output context discovered for a candidate family.

=cut

sub peer_read_policy ($class, $storage_class, $peer_input_endpoints, $top_output_signals = undef) {
    return undef unless @{$peer_input_endpoints || []};

    return {
        peer_read_policy => 'registered_loopback',
    } if ($storage_class || '') eq 'registered';

    return {
        peer_read_policy => 'top_output_only',
        peer_read_block_reason =>
            'combinational shared families must stay top-facing and are not internalized into lifted state',
    } if ($storage_class || '') eq 'combinational' && @{$top_output_signals || []};

    return {
        peer_read_policy => 'top_local_only',
        peer_read_block_reason =>
            'combinational shared families may lift only into top-local combinational carriers and are not internalized into lifted state',
    } if ($storage_class || '') eq 'combinational';

    return undef;
}

=head2 contributor_output_drive_family

Returns the normalized output-drive-family payload carried by one candidate
contributor.

=cut

sub contributor_output_drive_family ($class, $contributor) {
    return {} unless ref($contributor) eq 'HASH';
    return $contributor->{output_drive_family} if ref($contributor->{output_drive_family}) eq 'HASH';
    return $contributor->{drive_intent} if ref($contributor->{drive_intent}) eq 'HASH';
    return {};
}

=head2 drive_intent_from_output_drive_family

Builds the compatibility drive-intent projection from one exact output-drive
family payload.

=cut

sub drive_intent_from_output_drive_family ($class, $output_drive_family) {
    return {} unless ref($output_drive_family) eq 'HASH';

    return {
        multiplexer_type => ($output_drive_family->{multiplexer_type} // 'unknown'),
        default_value => $output_drive_family->{default_value},
        reset_value => $output_drive_family->{reset_value},
        driver_count => ($output_drive_family->{driver_count} || 0),
        driver_blocks => [@{$output_drive_family->{driver_blocks} || []}],
        rhs_values => [@{$output_drive_family->{rhs_values} || []}],
        driver_enable_signals => [@{$output_drive_family->{driver_enable_signals} || []}],
        family_enable_signals => [@{$output_drive_family->{family_enable_signals} || []}],
        rhs_enable_families => [
            map {
                +{
                    rhs_value => $_->{rhs_value},
                    family_enable_signal => $_->{family_enable_signal},
                    driver_blocks => [@{$_->{driver_blocks} || []}],
                    driver_enable_signals => [@{$_->{driver_enable_signals} || []}],
                }
            } @{$output_drive_family->{rhs_enable_families} || []}
        ],
    };
}

sub _project_shared_datapath_binding_metadata ($class, $binding_metadata) {
    return {
        bound_signal => '',
        bound_signals => [],
        bound_connection_expr => undef,
    } unless ref($binding_metadata) eq 'HASH';

    return {
        bound_signal => $binding_metadata->{bound_signal} || '',
        bound_signals => [@{$binding_metadata->{bound_signals} || []}],
        bound_connection_expr => _clone($binding_metadata->{bound_connection_expr}),
    };
}

=head2 _clone

Recursively clones hash and array payloads used in candidate metadata.

=cut

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } sort keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }
    return $value;
}

1;
