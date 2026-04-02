package FSM::Composition::ProvenanceReportBuilder;

=head1 NAME

FSM::Composition::ProvenanceReportBuilder - Builder for composition provenance and convention reports

=head1 DESCRIPTION

Builds the bounded composition provenance/reporting family used by the active
composition lanes. This package owns provenance report assembly, endpoint
context projection, override/block event detection, and the label/example
helpers consumed by the pipeline and CLI summary surfaces.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::InterfacePortBuilder;
use FSM::IR::IntentHIR;
use FSM::IR::StructuralRTLIRBuilder;

=head2 build_report

Builds the full composition provenance report from a composition plan and the
already-built forward IR layers.

=cut

sub build_report ($class, %args) {
    my $composition_plan = $args{composition_plan};
    my $intent_hir = $args{intent_hir};
    my $structural_rtl_ir = $class->_structural_rtl_ir_object(
        $composition_plan,
        $args{structural_rtl_ir},
        $args{target_language},
    );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;

    my @ports = map {
        my $origin_kind = $_->{origin_kind} || 'unknown_port_origin';
        +{
            name => $_->{name},
            direction => $_->{direction},
            width => $_->{width},
            type => $_->{type},
            origin_kind => $origin_kind,
            origin_category => $class->provenance_category($origin_kind),
            origin_label => $class->provenance_label($origin_kind),
        }
    } @{$structural_rtl_ir_hash->{ports} || []};

    my @resolved_links = map {
        my $origin_kind = $_->{origin_kind} || 'unknown_link_origin';
        my $source_context = $class->endpoint_context(
            composition_plan => $composition_plan,
            endpoint => $_->{source},
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $intent_hir,
            target_language => $args{target_language},
        );
        my $target_context = $class->endpoint_context(
            composition_plan => $composition_plan,
            endpoint => $_->{target},
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $intent_hir,
            target_language => $args{target_language},
        );
        +{
            source => $_->{source},
            target => $_->{target},
            origin_kind => $origin_kind,
            origin_category => $class->provenance_category($origin_kind),
            origin_label => $class->provenance_label($origin_kind),
            source_context => $source_context,
            target_context => $target_context,
        }
    } @{$structural_rtl_ir_hash->{resolved_links} || []};

    my %port_origin_counts;
    my %port_category_counts;
    my %port_origin_examples;
    for my $entry (@ports) {
        $port_origin_counts{$entry->{origin_kind}}++;
        $port_category_counts{$entry->{origin_category}}++;
        $port_origin_examples{$entry->{origin_kind}} //= $class->port_example_summary($entry);
    }

    my %resolved_link_origin_counts;
    my %resolved_link_category_counts;
    my %resolved_link_origin_examples;
    for my $entry (@resolved_links) {
        $resolved_link_origin_counts{$entry->{origin_kind}}++;
        $resolved_link_category_counts{$entry->{origin_category}}++;
        $resolved_link_origin_examples{$entry->{origin_kind}} //= $class->link_example_summary($entry);
    }

    my @override_events = @{$class->build_override_events(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $args{target_language},
    )};
    my %override_kind_counts;
    my %override_kind_examples;
    for my $event (@override_events) {
        $override_kind_counts{$event->{kind}}++;
        $override_kind_examples{$event->{kind}} //= $class->override_example_summary($event);
    }

    my @block_events = @{$class->build_block_events(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $args{target_language},
    )};
    my %block_kind_counts;
    my %block_kind_examples;
    for my $event (@block_events) {
        $block_kind_counts{$event->{kind}}++;
        $block_kind_examples{$event->{kind}} //= $class->block_example_summary($event);
    }

    return {
        lane => $composition_plan->lane,
        top_port_count => scalar(@ports),
        resolved_link_count => scalar(@resolved_links),
        override_count => scalar(@override_events),
        block_count => scalar(@block_events),
        ports => \@ports,
        resolved_links => \@resolved_links,
        override_events => \@override_events,
        block_events => \@block_events,
        port_origin_counts => \%port_origin_counts,
        port_category_counts => \%port_category_counts,
        port_origin_examples => \%port_origin_examples,
        resolved_link_origin_counts => \%resolved_link_origin_counts,
        resolved_link_category_counts => \%resolved_link_category_counts,
        resolved_link_origin_examples => \%resolved_link_origin_examples,
        override_kind_counts => \%override_kind_counts,
        block_kind_counts => \%block_kind_counts,
        override_kind_examples => \%override_kind_examples,
        block_kind_examples => \%block_kind_examples,
        ordered_port_origins => [
            sort {
                $class->provenance_sort_key($a) <=> $class->provenance_sort_key($b)
                    ||
                $class->provenance_label($a) cmp $class->provenance_label($b)
            } keys %port_origin_counts
        ],
        ordered_resolved_link_origins => [
            sort {
                $class->provenance_sort_key($a) <=> $class->provenance_sort_key($b)
                    ||
                $class->provenance_label($a) cmp $class->provenance_label($b)
            } keys %resolved_link_origin_counts
        ],
        ordered_override_kinds => [
            sort { $class->override_label($a) cmp $class->override_label($b) }
            keys %override_kind_counts
        ],
        ordered_block_kinds => [
            sort { $class->block_label($a) cmp $class->block_label($b) }
            keys %block_kind_counts
        ],
    };
}

=head2 build_override_events

Builds the bounded override-event family used by composition provenance
reporting.

=cut

sub build_override_events ($class, %args) {
    my $composition_plan = $args{composition_plan};
    my $intent_hir = $args{intent_hir};
    my @events;
    my $structural_rtl_ir = $class->_structural_rtl_ir_object(
        $composition_plan,
        $args{structural_rtl_ir},
        $args{target_language},
    );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;
    my $same_name_endpoints = $structural_rtl_ir->interface_signal_endpoint_groups;

    for my $top_port (@{$structural_rtl_ir_hash->{ports} || []}) {
        next unless (($top_port->{binding_mode} || 'explicit') eq 'explicit');
        my $type = $top_port->{type} || '';
        next if $type eq 'clock' || $type eq 'reset';

        my @same_name_candidates = @{$same_name_endpoints->{$top_port->{name}} || []};
        next unless @same_name_candidates;

        my @touching_explicit_toplinks = @{$structural_rtl_ir->resolved_links_touching(
            $top_port->{name},
            'declared_explicit_toplink',
        )};
        next unless @touching_explicit_toplinks;
        my $example_link = $touching_explicit_toplinks[0];
        my $source_context = $class->endpoint_context(
            composition_plan => $composition_plan,
            endpoint => $example_link->{source},
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $intent_hir,
            target_language => $args{target_language},
        );
        my $target_context = $class->endpoint_context(
            composition_plan => $composition_plan,
            endpoint => $example_link->{target},
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $intent_hir,
            target_language => $args{target_language},
        );

        if (($top_port->{direction} || '') eq 'input') {
            my @compatible = grep {
                (($_->{port}{direction} || '') eq 'input')
                    && $_->{port}{width} == $top_port->{width}
                    && FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}{type})
                        eq FSM::Composition::InterfacePortBuilder->normalized_interface_type($top_port->{type})
            } @same_name_candidates;

            next unless @compatible == @same_name_candidates;

            push @events, {
                kind => 'explicit_toplink_overrides_same_name_top_input_convention',
                top_port_name => $top_port->{name},
                lane => $composition_plan->lane,
                top_port_context => $class->endpoint_context(
                    composition_plan => $composition_plan,
                    endpoint => $top_port->{name},
                    structural_rtl_ir => $structural_rtl_ir,
                    intent_hir => $intent_hir,
                    target_language => $args{target_language},
                ),
                source_context => $source_context,
                target_context => $target_context,
            };
            next;
        }

        next unless (($top_port->{direction} || '') eq 'output');

        my @input_candidates = grep { (($_->{port}{direction} || '') eq 'input') } @same_name_candidates;
        next if @input_candidates;

        my @compatible_output_candidates = grep {
            (($_->{port}{direction} || '') eq 'output')
                && $_->{port}{width} == $top_port->{width}
                && FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}{type})
                    eq FSM::Composition::InterfacePortBuilder->normalized_interface_type($top_port->{type})
        } @same_name_candidates;

        next unless @compatible_output_candidates == @same_name_candidates;
        next unless @compatible_output_candidates == 1;

        push @events, {
            kind => 'explicit_toplink_overrides_same_name_top_output_convention',
            top_port_name => $top_port->{name},
            lane => $composition_plan->lane,
            top_port_context => $class->endpoint_context(
                composition_plan => $composition_plan,
                endpoint => $top_port->{name},
                structural_rtl_ir => $structural_rtl_ir,
                intent_hir => $intent_hir,
                target_language => $args{target_language},
            ),
            source_context => $source_context,
            target_context => $target_context,
        };
    }

    my %seen_reexports;
    for my $resolved_link (@{$structural_rtl_ir_hash->{resolved_links} || []}) {
        next unless (($resolved_link->{origin_kind} || '') eq 'inferred_internal_carrier_reexport_link');
        my $top_port_name = $resolved_link->{target};
        next if $seen_reexports{$top_port_name}++;

        push @events, {
            kind => 'explicit_top_output_reexports_internal_carrier',
            top_port_name => $top_port_name,
            source => $resolved_link->{source},
            lane => $composition_plan->lane,
            top_port_context => $class->endpoint_context(
                composition_plan => $composition_plan,
                endpoint => $top_port_name,
                structural_rtl_ir => $structural_rtl_ir,
                intent_hir => $intent_hir,
                target_language => $args{target_language},
            ),
            source_context => (
                $class->signal_family_contexts(
                    composition_plan => $composition_plan,
                    signal_name => $top_port_name,
                    direction => 'output',
                    structural_rtl_ir => $structural_rtl_ir,
                    intent_hir => $intent_hir,
                    target_language => $args{target_language},
                )->[0]
            ),
        };
    }

    return \@events;
}

=head2 build_block_events

Builds the bounded convention-block event family used by composition
provenance reporting.

=cut

sub build_block_events ($class, %args) {
    my $composition_plan = $args{composition_plan};
    my $intent_hir = $args{intent_hir};
    my @events;
    my $structural_rtl_ir = $class->_structural_rtl_ir_object(
        $composition_plan,
        $args{structural_rtl_ir},
        $args{target_language},
    );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;
    my %declared_top_ports = map { (($_->{name} || '') => $_) } @{$structural_rtl_ir_hash->{ports} || []};
    my @declared_links = @{$structural_rtl_ir_hash->{declared_links} || []};
    my @resolved_links = @{$structural_rtl_ir_hash->{resolved_links} || []};
    my $port_groups = $structural_rtl_ir->interface_signal_endpoint_groups;

    my %explicitly_linked_child_input_names;
    my %explicitly_linked_child_output_endpoints;
    for my $link (@declared_links) {
        my $source = $link->{source} || '';
        my $target = $link->{target} || '';

        my ($target_instance, $target_port_name) = $target =~ /^(\w+)\.(\w+)$/;
        if (defined $target_port_name) {
            my $source_is_child_endpoint = $source =~ /^\w+\.\w+$/;
            my $source_is_declared_top_port = exists $declared_top_ports{$source};
            my $source_is_actual = $source =~ /^=/;
            if ($source_is_child_endpoint || $source_is_declared_top_port || $source_is_actual) {
                $explicitly_linked_child_input_names{$target_port_name} = 1;
            }
        }

        my ($source_instance, $source_port_name) = $source =~ /^(\w+)\.(\w+)$/;
        if (defined $source_port_name) {
            $explicitly_linked_child_output_endpoints{"$source_instance.$source_port_name"} = 1;
        }
    }

    for my $port_name (sort keys %$port_groups) {
        next if $declared_top_ports{$port_name};
        my @candidates = @{$port_groups->{$port_name}};
        next unless @candidates;

        my @input_candidates = grep { (($_->{port}{direction} || '') eq 'input') } @candidates;
        if (@input_candidates && @input_candidates == @candidates && $explicitly_linked_child_input_names{$port_name}) {
            my %widths = map { $_->{port}{width} => 1 } @input_candidates;
            my %types = map { FSM::Composition::InterfacePortBuilder->normalized_interface_type($_->{port}{type}) => 1 } @input_candidates;
            if (keys(%widths) == 1 && keys(%types) == 1) {
                push @events, {
                    kind => 'explicit_child_links_block_undeclared_top_input_inference',
                    signal_name => $port_name,
                    lane => $composition_plan->lane,
                    candidate_contexts => $class->signal_family_contexts(
                        composition_plan => $composition_plan,
                        signal_name => $port_name,
                        direction => 'input',
                        structural_rtl_ir => $structural_rtl_ir,
                        intent_hir => $intent_hir,
                        target_language => $args{target_language},
                    ),
                };
            }
            next;
        }

        my @output_candidates = grep { (($_->{port}{direction} || '') eq 'output') } @candidates;
        if (@output_candidates && @output_candidates == @candidates && @output_candidates == 1) {
            my $endpoint = $output_candidates[0]{instance_name}.'.'.$output_candidates[0]{port}{name};
            if ($explicitly_linked_child_output_endpoints{$endpoint}) {
                push @events, {
                    kind => 'explicit_child_links_block_undeclared_top_output_inference',
                    signal_name => $port_name,
                    lane => $composition_plan->lane,
                    candidate_contexts => $class->signal_family_contexts(
                        composition_plan => $composition_plan,
                        signal_name => $port_name,
                        direction => 'output',
                        structural_rtl_ir => $structural_rtl_ir,
                        intent_hir => $intent_hir,
                        target_language => $args{target_language},
                    ),
                };
                next;
            }
        }
    }

    my %internal_carrier_family;
    my %reexported_internal_carrier_family;
    for my $link (@resolved_links) {
        my $raw_token = $link->{raw_token} || '';
        my ($family_name) = $raw_token =~ /^=implicit-internal:(\w+)$/;
        next unless defined $family_name;

        if (($link->{origin_kind} || '') eq 'inferred_internal_carrier_link') {
            $internal_carrier_family{$family_name} = 1;
        } elsif (($link->{origin_kind} || '') eq 'inferred_internal_carrier_reexport_link') {
            $reexported_internal_carrier_family{$family_name} = 1;
        }
    }

    for my $family_name (sort keys %internal_carrier_family) {
        next if $reexported_internal_carrier_family{$family_name};
        my $output_contexts = $class->signal_family_contexts(
            composition_plan => $composition_plan,
            signal_name => $family_name,
            direction => 'output',
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $intent_hir,
            target_language => $args{target_language},
        );
        push @events, {
            kind => 'inferred_internal_carrier_kept_internal_by_default',
            signal_name => $family_name,
            lane => $composition_plan->lane,
            candidate_contexts => (
                @$output_contexts
                    ? $output_contexts
                    : $class->signal_family_contexts(
                        composition_plan => $composition_plan,
                        signal_name => $family_name,
                        direction => undef,
                        structural_rtl_ir => $structural_rtl_ir,
                        intent_hir => $intent_hir,
                        target_language => $args{target_language},
                    )
            ),
        };
    }

    return \@events;
}

=head2 endpoint_context

Projects one top-port or child-endpoint string into the bounded provenance
context structure used by reporting and CLI summaries.

=cut

sub endpoint_context ($class, %args) {
    my $endpoint = $args{endpoint};
    return undef unless defined $endpoint && length $endpoint;

    my $structural_rtl_ir = $class->_structural_rtl_ir_object(
        $args{composition_plan},
        $args{structural_rtl_ir},
        $args{target_language},
    );

    if (my $top_port = $structural_rtl_ir->top_port($endpoint)) {
        return {
            kind => 'top_port',
            name => $top_port->{name},
            endpoint => $top_port->{name},
            direction => $top_port->{direction},
            width => $top_port->{width},
            type => $top_port->{type},
        };
    }

    my ($instance_name, $port_name) = $endpoint =~ /^(\w+)\.(\w+)$/;
    return {
        kind => 'raw_endpoint',
        endpoint => $endpoint,
    } unless defined $port_name;

    my $endpoint_entry = $structural_rtl_ir->interface_endpoint($endpoint);
    my $child = FSM::IR::IntentHIR->composition_child_from_input($args{intent_hir}, $instance_name);

    return {
        kind => 'raw_endpoint',
        endpoint => $endpoint,
    } unless $child || $endpoint_entry;

    my $port = $endpoint_entry->{port};
    my $structural_instance = $endpoint_entry->{instance} || {};

    my $instance_kind = $child->{kind}
        // ($structural_instance->{kind} // '');
    my $source_root_kind = $child->{source_root_kind}
        // $class->_source_root_kind_for_instance_kind($instance_kind);

    return {
        kind => 'child_endpoint',
        endpoint => $endpoint,
        instance_name => ($child->{instance_name} // $endpoint_entry->{instance_name} // $instance_name),
        instance_kind => $instance_kind,
        module_name => ($child->{module_name} // $structural_instance->{module_name}),
        source_name => ($child->{source_name} // $structural_instance->{source_name}),
        port_name => $port_name,
        direction => $port ? $port->{direction} : undef,
        width => $port ? $port->{width} : undef,
        type => $port ? $port->{type} : undef,
        source_root_kind => $source_root_kind,
        regular_state_count => ($child->{regular_state_count} || 0),
        standalone_dt_count => ($child->{standalone_dt_count} || 0),
        output_drive_family_count => ($child->{output_drive_family_count} || 0),
        intent_hir => ($child->{intent_hir} || {}),
        lowered_rtl_ir => ($child->{lowered_rtl_ir} || {}),
        structural_rtl_ir => ($child->{structural_rtl_ir} || {}),
    };
}

=head2 endpoint_example_label

Renders one provenance endpoint context into the short example text used by
composition summary reporting.

=cut

sub endpoint_example_label ($class, $context, $fallback = undef) {
    return $fallback // '' unless ref($context) eq 'HASH';

    if (($context->{kind} || '') eq 'top_port') {
        return $context->{name} || $context->{endpoint} || ($fallback // '');
    }

    if (($context->{kind} || '') eq 'child_endpoint') {
        my $root_kind = $context->{source_root_kind} || 'unknown_root';
        my @details = ('?' . $root_kind);

        if ($root_kind eq 'fsm') {
            push @details, 'states: ' . ($context->{regular_state_count} || 0);
        } elsif ($root_kind eq 'dt') {
            push @details, 'blocks: ' . ($context->{standalone_dt_count} || 0);
        }

        if ($root_kind eq 'fsm' || $root_kind eq 'dt') {
            push @details, 'output drive families: ' . ($context->{output_drive_family_count} || 0);
        }

        return ($context->{endpoint} || $fallback || 'unknown_endpoint')
            . ' (' . join(', ', @details) . ')';
    }

    return $context->{endpoint} || $fallback || '';
}

=head2 port_example_summary

Builds the short example text for one top-port provenance entry.

=cut

sub port_example_summary ($class, $entry) {
    return '' unless ref($entry) eq 'HASH';
    return $entry->{name} // '';
}

=head2 link_example_summary

Builds the short example text for one resolved-link provenance entry.

=cut

sub link_example_summary ($class, $entry) {
    return '' unless ref($entry) eq 'HASH';

    my $source = $class->endpoint_example_label(
        $entry->{source_context},
        $entry->{source},
    );
    my $target = $class->endpoint_example_label(
        $entry->{target_context},
        $entry->{target},
    );

    return '' unless length($source) || length($target);
    return $source . ' -> ' . $target;
}

=head2 signal_family_contexts

Returns the ordered provenance contexts for one same-name structural interface
family, optionally filtered by direction.

=cut

sub signal_family_contexts ($class, %args) {
    my $signal_name = $args{signal_name};
    return [] unless defined $signal_name && length $signal_name;

    my $structural_rtl_ir = $class->_structural_rtl_ir_object(
        $args{composition_plan},
        $args{structural_rtl_ir},
        $args{target_language},
    );
    my @contexts;
    for my $endpoint (@{$structural_rtl_ir->interface_signal_endpoints($signal_name, $args{direction})}) {
        my $context = $class->endpoint_context(
            composition_plan => $args{composition_plan},
            endpoint => $endpoint->{endpoint},
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $args{intent_hir},
            target_language => $args{target_language},
        );
        push @contexts, $context if $context;
    }

    @contexts = sort {
        ($a->{endpoint} || '') cmp ($b->{endpoint} || '')
            ||
        ($a->{instance_name} || '') cmp ($b->{instance_name} || '')
    } @contexts;

    return \@contexts;
}

=head2 provenance_category

Maps one provenance origin token onto its high-level reporting category.

=cut

sub provenance_category ($class, $origin_kind) {
    return 'declared' if $origin_kind =~ /^declared_/;
    return 'inferred' if $origin_kind =~ /^inferred_/;
    return 'auto' if $origin_kind =~ /^auto_/;
    return 'realized' if $origin_kind =~ /^realized_/;
    return 'declared' if $origin_kind =~ /^rtlif_/;
    return 'other';
}

=head2 provenance_sort_key

Returns the stable display-order rank for one provenance origin token.

=cut

sub provenance_sort_key ($class, $origin_kind) {
    my %rank = (
        declared => 0,
        inferred => 1,
        auto => 2,
        realized => 3,
        other => 4,
    );

    return $rank{$class->provenance_category($origin_kind)};
}

=head2 provenance_label

Returns the human-readable label for one provenance origin token.

=cut

sub provenance_label ($class, $origin_kind) {
    my %labels = (
        declared_explicit_port => 'declared explicit top port',
        declared_connect_by_name_port => 'declared connect-by-name top port',
        declared_explicit_toplink => 'declared explicit toplink',
        declared_connect_by_name_link => 'declared connect-by-name link',
        declared_c1_passthrough_link => 'declared single-child passthrough link',
        inferred_c1_passthrough_port => 'inferred single-child passthrough top port',
        inferred_c1_passthrough_link => 'inferred single-child passthrough link',
        inferred_explicit_toplink_port => 'inferred top port from explicit toplink',
        inferred_undeclared_top_input_port => 'inferred undeclared top input',
        inferred_undeclared_top_output_port => 'inferred undeclared top output',
        inferred_plain_explicit_top_input_link => 'inferred plain explicit top-input convention link',
        inferred_plain_explicit_top_output_link => 'inferred plain explicit top-output convention link',
        inferred_undeclared_top_input_link => 'inferred undeclared top-input link',
        inferred_undeclared_top_output_link => 'inferred undeclared top-output link',
        inferred_internal_carrier_link => 'inferred internal carrier link',
        inferred_internal_carrier_reexport_link => 'inferred internal carrier re-export link',
        auto_system_port_link => 'auto system-port link',
        realized_child_interface_port => 'realized child interface port',
        rtlif_declared_port => 'declared rtlif port',
    );

    return $labels{$origin_kind} if defined $labels{$origin_kind};

    (my $label = $origin_kind) =~ s/_/ /g;
    return $label;
}

=head2 override_label

Returns the human-readable label for one convention-override event kind.

=cut

sub override_label ($class, $kind) {
    my %labels = (
        explicit_toplink_overrides_same_name_top_input_convention => 'explicit toplink overrides same-name top-input convention',
        explicit_toplink_overrides_same_name_top_output_convention => 'explicit toplink overrides same-name top-output convention',
        explicit_top_output_reexports_internal_carrier => 'explicit top output re-exports internal carrier',
    );

    return $labels{$kind} if defined $labels{$kind};

    (my $label = $kind) =~ s/_/ /g;
    return $label;
}

=head2 override_example_summary

Builds the short example text for one convention-override event.

=cut

sub override_example_summary ($class, $event) {
    return '' unless $event && ref($event) eq 'HASH';

    if ($event->{source_context} || $event->{target_context}) {
        return $class->link_example_summary({
            source => $event->{source},
            target => $event->{top_port_name},
            source_context => $event->{source_context},
            target_context => $event->{target_context} || $event->{top_port_context},
        });
    }

    if (defined $event->{top_port_name} && length $event->{top_port_name}) {
        return "Top port '$event->{top_port_name}'";
    }

    if (defined $event->{signal_name} && length $event->{signal_name}) {
        return "Signal name '$event->{signal_name}'";
    }

    return '';
}

=head2 block_label

Returns the human-readable label for one convention-block event kind.

=cut

sub block_label ($class, $kind) {
    my %labels = (
        explicit_child_links_block_undeclared_top_input_inference => 'explicit child links block undeclared top-input inference',
        explicit_child_links_block_undeclared_top_output_inference => 'explicit child links block undeclared top-output inference',
        inferred_internal_carrier_kept_internal_by_default => 'inferred internal carrier kept internal by default',
    );

    return $labels{$kind} if defined $labels{$kind};

    (my $label = $kind) =~ s/_/ /g;
    return $label;
}

=head2 block_example_summary

Builds the short example text for one convention-block event.

=cut

sub block_example_summary ($class, $event) {
    return '' unless $event && ref($event) eq 'HASH';

    if (ref($event->{candidate_contexts}) eq 'ARRAY' && @{$event->{candidate_contexts}}) {
        return $class->endpoint_example_label($event->{candidate_contexts}[0]);
    }

    if (defined $event->{signal_name} && length $event->{signal_name}) {
        return "Signal name '$event->{signal_name}'";
    }

    if (defined $event->{top_port_name} && length $event->{top_port_name}) {
        return "Top port '$event->{top_port_name}'";
    }

    return '';
}

=head2 _structural_rtl_ir_object

Normalizes one optional structural input into the concrete structural IR object
used by this builder.

=cut

sub _structural_rtl_ir_object ($class, $composition_plan, $structural_rtl_ir = undef, $target_language = undef) {
    $structural_rtl_ir //= FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
        $composition_plan,
        ($target_language // 'systemverilog'),
    );
    return FSM::IR::StructuralRTLIRBuilder->coerce(
        $structural_rtl_ir,
        ($target_language // 'systemverilog'),
    );
}

=head2 _source_root_kind_for_instance_kind

Maps one realized child kind onto the bounded source-root token used by report
contexts.

=cut

sub _source_root_kind_for_instance_kind ($class, $instance_kind) {
    return 'dt' if ($instance_kind || '') eq 'dtc';
    return 'fsm' if ($instance_kind || '') eq 'fsmc';
    return 'rtl' if ($instance_kind || '') eq 'rtl';
    return 'unknown_root';
}

1;
