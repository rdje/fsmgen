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
    my @expression_links;

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
            my $source_child_expr_spec = FSM::Composition::LinkedPlanBuilder->child_expression_spec($source);
            my ($source_instance_name, $source_port_name) = $source =~ /^(\w+)\.(\w+)$/;
            my $source_is_realized_child_endpoint = defined($source_port_name)
                && exists($instances_by_name{$source_instance_name})
                && exists($child_ports_by_instance{$source_instance_name}{$source_port_name});
            my $source_top_expr_spec = ($source_child_expr_spec || $source_is_realized_child_endpoint)
                ? undef
                : FSM::Composition::LinkedPlanBuilder->top_expression_spec($source);

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

            if ($source_top_expr_spec
                && $target =~ /^\w+\.\w+$/
                && $class->_expression_spec_mentions_undeclared_top_inputs($source_top_expr_spec, \%declared_by_name))
            {
                $source_top_expr_spec = $class->_annotate_expression_spec_child_widths(
                    $source_top_expr_spec,
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                my $child_endpoint = FSM::Composition::LinkedPlanBuilder->resolve_endpoint(
                    $target,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                push @expression_links, {
                    source => $source,
                    target => $target,
                    child_endpoint => $child_endpoint,
                    expression_spec => $source_top_expr_spec,
                };
            }

            if ($target_is_top && !$declared_by_name{$target_top_name} && ($source =~ /^\w+\.\w+$/ || $source_child_expr_spec)) {
                my $child_endpoint = FSM::Composition::LinkedPlanBuilder->resolve_endpoint(
                    $source,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                    allow_child_expression_source => 1,
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

    my $made_progress = 1;
    while ($made_progress) {
        $made_progress = 0;
        for my $expression_link (@expression_links) {
            $made_progress ||= $class->_record_inferred_ports_from_top_expression(
                \%inferred_specs,
                \%declared_by_name,
                $expression_link->{expression_spec},
                $expression_link->{child_endpoint},
                $expression_link->{source}.' -> '.$expression_link->{target},
                $fsm_file,
                $header,
            );
        }
    }

    for my $expression_link (@expression_links) {
        $class->_assert_top_expression_inference_is_resolved(
            \%declared_by_name,
            \%inferred_specs,
            $expression_link->{expression_spec},
            $expression_link->{child_endpoint},
            $expression_link->{source}.' -> '.$expression_link->{target},
            $fsm_file,
            $header,
        );
    }

    my @inferred_ports = map {
        FSM::Composition::Port->new(
            name => $_->{name},
            direction => $_->{direction},
            width => $_->{width},
            type => $_->{type},
            declared_type_name => $_->{declared_type_name},
            declared_type_spec => $_->{declared_type_spec},
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
            my $source_is_child_expression = defined FSM::Composition::LinkedPlanBuilder->child_expression_spec($source);
            my $source_is_actual = $source =~ /^=/;
            my ($source_top_port_name) = $source =~ /^(\w+)$/;
            my $source_top_expr_spec = FSM::Composition::LinkedPlanBuilder->top_expression_spec($source);
            my $source_is_top_expression = defined $source_top_expr_spec;
            my $source_top_expr_port_name = FSM::Composition::LinkedPlanBuilder->top_expression_base_port_name($source);
            my $source_is_declared_top_port = defined($source_top_port_name) && $declared_by_name{$source_top_port_name};
            my $source_is_declared_top_expr = defined($source_top_expr_port_name) && $declared_by_name{$source_top_expr_port_name};
            if (defined($source_top_port_name) && !$source_is_declared_top_port && $source_top_port_name eq $target_port_name) {
                $same_name_undeclared_top_input_links{$target_port_name} = 1;
                next;
            }
            next unless $source_is_child_endpoint || $source_is_child_expression || $source_is_declared_top_port || $source_is_declared_top_expr || $source_is_top_expression || $source_is_actual;
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

        my @typed_input_candidates = grep {
            defined FSM::Composition::InterfacePortBuilder->declared_type_signature($_->{port})
        } @input_candidates;
        my %declared_type_signatures = map {
            FSM::Composition::InterfacePortBuilder->declared_type_signature($_->{port}) => 1
        } @typed_input_candidates;
        if (keys(%declared_type_signatures) > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                "[declared_type='".FSM::Composition::InterfacePortBuilder->declared_type_label($_->{port})."']"
            } @typed_input_candidates);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-input inference is blocked because same-name child inputs disagree on declared type contract. ".
                "Seen typed child inputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top inputs when all same-name typed child inputs agree on one declared type contract too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $template = $input_candidates[0]{port};
        my $declared_type_contract = FSM::Composition::InterfacePortBuilder->uniform_declared_type_contract(
            [ map { $_->{port} } @input_candidates ]
        );
        push @inferred_ports, FSM::Composition::Port->new(
            name => $template->name,
            direction => 'input',
            width => $template->width,
            type => FSM::Composition::InterfacePortBuilder->normalized_interface_type($template->type),
            declared_type_name => $declared_type_contract->{declared_type_name},
            declared_type_spec => $declared_type_contract->{declared_type_spec},
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
            if ($source =~ /^(\w+)\.(\w+)$/) {
                $explicitly_linked_child_output_endpoints{"$1.$2"} = 1;
                next;
            }

            if (my $base_endpoint = FSM::Composition::LinkedPlanBuilder->child_expression_base_endpoint($source)) {
                $explicitly_linked_child_output_endpoints{$base_endpoint} = 1;
                next;
            }

            for my $base_endpoint (@{FSM::Composition::LinkedPlanBuilder->top_expression_child_base_endpoints($source)}) {
                $explicitly_linked_child_output_endpoints{$base_endpoint} = 1;
            }
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
            declared_type_name => FSM::Composition::InterfacePortBuilder->declared_type_name($template),
            declared_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($template),
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
    my $declared_type_name = FSM::Composition::InterfacePortBuilder->declared_type_name($child_endpoint->{port});
    my $declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($child_endpoint->{port});
    return $class->_record_inferred_top_port_requirement(
        $inferred_specs,
        $top_name,
        $direction,
        $width,
        $width,
        $type,
        $declared_type_name,
        $declared_type_spec,
        $evidence,
        $fsm_file,
        $header,
    );
}

sub _record_inferred_top_expression_port ($class, $inferred_specs, $top_name, $expression_spec, $child_endpoint, $evidence, $fsm_file, $header) {
    my $type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($child_endpoint->{port}->type);
    my $required_width = $class->_required_top_width_for_expression_spec($expression_spec);
    my $declared_type_name = FSM::Composition::InterfacePortBuilder->declared_type_name($child_endpoint->{port});
    my $declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($child_endpoint->{port});
    return $class->_record_inferred_top_port_requirement(
        $inferred_specs,
        $top_name,
        'input',
        $required_width,
        undef,
        $type,
        $declared_type_name,
        $declared_type_spec,
        $evidence,
        $fsm_file,
        $header,
    );
}

sub _record_inferred_ports_from_top_expression ($class, $inferred_specs, $declared_by_name, $expression_spec, $child_endpoint, $evidence, $fsm_file, $header) {
    my $analysis = $class->_analyze_top_expression_for_inference(
        $declared_by_name,
        $inferred_specs,
        $expression_spec,
        $child_endpoint,
        $evidence,
        $fsm_file,
        $header,
        record_requirements => 1,
    );

    my $expr_kind = $expression_spec->{expr_kind} || '';
    return $analysis->{progress}
        unless $expr_kind eq 'concat' || $expr_kind eq 'repeat';

    my @unresolved = @{$analysis->{unresolved_signal_refs} || []};
    return $analysis->{progress} unless @unresolved == 1;

    my $target_width = $child_endpoint->{port}->width;
    my $remaining_width = $target_width - $analysis->{known_exact_width};
    my $width_multiplier = $unresolved[0]{width_multiplier} || 1;
    return $analysis->{progress} unless $remaining_width >= $width_multiplier;
    return $analysis->{progress} if $remaining_width % $width_multiplier != 0;
    my $inferred_width = int($remaining_width / $width_multiplier);
    return $analysis->{progress} unless $inferred_width >= 1;

    my $type = FSM::Composition::InterfacePortBuilder->normalized_interface_type($child_endpoint->{port}->type);
    return $class->_record_inferred_top_port_requirement(
        $inferred_specs,
        $unresolved[0]{port_name},
        'input',
        $inferred_width,
        $inferred_width,
        $type,
        undef,
        undef,
        $evidence,
        $fsm_file,
        $header,
    ) || $analysis->{progress};
}

sub _assert_top_expression_inference_is_resolved ($class, $declared_by_name, $inferred_specs, $expression_spec, $child_endpoint, $evidence, $fsm_file, $header) {
    my $expr_kind = $expression_spec->{expr_kind} || '';
    return unless $expr_kind eq 'concat' || $expr_kind eq 'repeat';

    my $analysis = $class->_analyze_top_expression_for_inference(
        $declared_by_name,
        $inferred_specs,
        $expression_spec,
        $child_endpoint,
        $evidence,
        $fsm_file,
        $header,
        record_requirements => 0,
    );

    my @unresolved = @{$analysis->{unresolved_signal_refs} || []};
    return unless @unresolved;

    my @operand_names = sort map { $_->{port_name} } @unresolved;
    my $target_width = $child_endpoint->{port}->width;
    my $known_width = $analysis->{known_exact_width};
    my $remaining_width = $target_width - $known_width;
    my $width_multiplier = $unresolved[0]{width_multiplier} || 1;

    if (@operand_names > 1) {
        confess
            "Composition source '$header' in '$fsm_file' omits top ports '".join("', '", @operand_names)."', ".
            "but explicit top-link port inference is blocked because top expression '".$expression_spec->{raw}."' leaves several undeclared whole-port concat operands without exact widths. ".
            "Seen explicit link evidence: $evidence. ".
            "The current bounded omitted/empty-'?ports' concat inference slice only infers undeclared whole-port operands when one remaining concat operand can be sized exactly from the child-input target width. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($width_multiplier > 1 && $remaining_width >= 1 && $remaining_width % $width_multiplier != 0) {
        confess
            "Composition source '$header' in '$fsm_file' omits top port '".$operand_names[0]."', ".
            "but explicit top-link port inference is blocked because top expression '".$expression_spec->{raw}."' leaves remaining width $remaining_width that cannot be divided evenly across $width_multiplier repeated uses of undeclared whole-port concat operand '".$operand_names[0]."'. ".
            "Seen explicit link evidence: $evidence. ".
            "The current bounded omitted/empty-'?ports' concat inference slice only infers undeclared whole-port operands when one remaining concat operand can be sized exactly from the child-input target width. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    confess
        "Composition source '$header' in '$fsm_file' omits top port '".$operand_names[0]."', ".
        "but explicit top-link port inference is blocked because top expression '".$expression_spec->{raw}."' leaves no remaining width for that undeclared whole-port concat operand after accounting for $known_width of the child-input target width $target_width. ".
        "Seen explicit link evidence: $evidence. ".
        "The current bounded omitted/empty-'?ports' concat inference slice only infers undeclared whole-port operands when one remaining concat operand can be sized exactly from the child-input target width. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub _annotate_expression_spec_child_widths ($class, $expression_spec, $instances_by_name, $child_ports_by_instance, $fsm_file, $header) {
    return undef unless ref($expression_spec) eq 'HASH';

    my %annotated = %$expression_spec;
    my $expr_kind = $expression_spec->{expr_kind} || '';

    if ($expr_kind eq 'concat') {
        $annotated{operands} = [
            map {
                $class->_annotate_expression_spec_child_widths(
                    $_,
                    $instances_by_name,
                    $child_ports_by_instance,
                    $fsm_file,
                    $header,
                )
            } @{$expression_spec->{operands} || []}
        ];
        return \%annotated;
    }

    if ($expr_kind eq 'repeat') {
        my $annotated_operand = $class->_annotate_expression_spec_child_widths(
            $expression_spec->{operand},
            $instances_by_name,
            $child_ports_by_instance,
            $fsm_file,
            $header,
        );
        $annotated{operand} = $annotated_operand;
        $annotated{width} = ($expression_spec->{repeat_count} || 0) * ($annotated_operand->{width} || 0)
            if defined($annotated_operand->{width});
        return \%annotated;
    }

    return \%annotated
        unless $expr_kind eq 'child_signal_ref'
            || $expr_kind eq 'child_bit_select'
            || $expr_kind eq 'child_slice'
            || $expr_kind eq 'child_aggregate_ref';

    my $instance_name = $expression_spec->{instance_name} || '';
    my $port_name = $expression_spec->{port_name} || '';
    my $instance = $instances_by_name->{$instance_name};
    my $context_label = $expr_kind eq 'child_signal_ref' ? 'child endpoint' : 'child expression';

    confess
        "Composition source '$header' in '$fsm_file' uses $context_label '".$expression_spec->{raw}."', ".
        "but explicit top-link port inference is blocked because no realized child instance named '$instance_name' exists. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $instance;

    my $port = $child_ports_by_instance->{$instance_name}{$port_name};
    confess
        "Composition source '$header' in '$fsm_file' uses $context_label '".$expression_spec->{raw}."', ".
        "but explicit top-link port inference is blocked because instance '$instance_name' has no port named '$port_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $port;

    confess
        "Composition source '$header' in '$fsm_file' uses $context_label '".$expression_spec->{raw}."', ".
        "but explicit top-link port inference is blocked because base child port '$instance_name.$port_name' is ".$port->direction." instead of output. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless ($port->direction || '') eq 'output';

    my $base_width = $port->width;
    if ($expr_kind eq 'child_signal_ref') {
        $annotated{width} = $base_width;
        return \%annotated;
    }

    if ($expr_kind eq 'child_bit_select') {
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '".$expression_spec->{raw}."', ".
            "but explicit top-link port inference is blocked because bit index ".$expression_spec->{index}." falls outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($base_width) && $base_width > 0 && $expression_spec->{index} < $base_width;

        $annotated{width} = 1;
        return \%annotated;
    }

    if ($expr_kind eq 'child_aggregate_ref') {
        my (undef, undef, $resolved_width) = FSM::Composition::LinkedPlanBuilder->_resolve_aggregate_path_connection(
            base_expr => FSM::IR::StructuralRTLIR::ConnectionExpr::signal_ref_expr("$instance_name.$port_name"),
            root_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($port),
            path_text => $expression_spec->{path_text},
            raw => $expression_spec->{raw},
            context_label => 'child expression',
            base_label => "child endpoint '$instance_name.$port_name'",
            fsm_file => $fsm_file,
            header => $header,
        );
        $annotated{width} = $resolved_width;
        return \%annotated;
    }

    confess
        "Composition source '$header' in '$fsm_file' uses child expression '".$expression_spec->{raw}."', ".
        "but explicit top-link port inference is blocked because slice bounds [".$expression_spec->{msb}.':'.$expression_spec->{lsb}."] fall outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless defined($base_width) && $base_width > 0 && $expression_spec->{msb} < $base_width && $expression_spec->{lsb} < $base_width;

    $annotated{width} = abs(($expression_spec->{msb} || 0) - ($expression_spec->{lsb} || 0)) + 1;
    return \%annotated;
}

sub _expression_spec_mentions_undeclared_top_inputs ($class, $expression_spec, $declared_by_name) {
    return 0 unless ref($expression_spec) eq 'HASH';

    my $expr_kind = $expression_spec->{expr_kind} || '';
    if ($expr_kind eq 'signal_ref' || $expr_kind eq 'bit_select' || $expr_kind eq 'slice') {
        my $port_name = $expression_spec->{port_name} || '';
        return !$declared_by_name->{$port_name};
    }

    return 0
        if $expr_kind eq 'literal'
        || $expr_kind eq 'child_signal_ref'
        || $expr_kind eq 'child_bit_select'
        || $expr_kind eq 'child_slice'
        || $expr_kind eq 'child_aggregate_ref';

    if ($expr_kind eq 'aggregate_ref') {
        my $port_name = $expression_spec->{port_name} || '';
        return !$declared_by_name->{$port_name};
    }

    if ($expr_kind eq 'repeat') {
        return $class->_expression_spec_mentions_undeclared_top_inputs($expression_spec->{operand}, $declared_by_name);
    }

    if ($expr_kind eq 'concat') {
        for my $operand_spec (@{$expression_spec->{operands} || []}) {
            return 1 if $class->_expression_spec_mentions_undeclared_top_inputs($operand_spec, $declared_by_name);
        }
        return 0;
    }

    confess "TopPortInferenceBuilder requires a supported top-expression operand kind";
}

sub _analyze_top_expression_for_inference ($class, $declared_by_name, $inferred_specs, $expression_spec, $child_endpoint, $evidence, $fsm_file, $header, %opts) {
    my $expr_kind = $expression_spec->{expr_kind} || '';

    if ($expr_kind eq 'signal_ref') {
        my $port_name = $expression_spec->{port_name} || '';
        my $declared_port = $declared_by_name->{$port_name};
        return {
            progress => 0,
            known_exact_width => ($declared_port ? $declared_port->width : 0),
            unresolved_signal_refs => [],
        } if $declared_port;

        my $existing = $inferred_specs->{$port_name};
        return {
            progress => 0,
            known_exact_width => $existing->{exact_width},
            unresolved_signal_refs => [],
        } if $existing && defined($existing->{exact_width});

        return {
            progress => 0,
            known_exact_width => 0,
            unresolved_signal_refs => [{
                port_name => $port_name,
                width_multiplier => 1,
            }],
        };
    }

    if ($expr_kind eq 'bit_select' || $expr_kind eq 'slice') {
        my $progress = 0;
        my $port_name = $expression_spec->{port_name};
        if (!$declared_by_name->{$port_name} && $opts{record_requirements}) {
            $progress = $class->_record_inferred_top_expression_port(
                $inferred_specs,
                $port_name,
                $expression_spec,
                $child_endpoint,
                $evidence,
                $fsm_file,
                $header,
            );
        }

        return {
            progress => $progress,
            known_exact_width => $class->_expression_spec_width($expression_spec),
            unresolved_signal_refs => [],
        };
    }

    if ($expr_kind eq 'literal') {
        return {
            progress => 0,
            known_exact_width => $expression_spec->{width},
            unresolved_signal_refs => [],
        };
    }

    if ($expr_kind eq 'aggregate_ref' || $expr_kind eq 'child_signal_ref' || $expr_kind eq 'child_bit_select' || $expr_kind eq 'child_slice' || $expr_kind eq 'child_aggregate_ref') {
        return {
            progress => 0,
            known_exact_width => $class->_expression_spec_width($expression_spec),
            unresolved_signal_refs => [],
        };
    }

    if ($expr_kind eq 'repeat') {
        my $operand_analysis = $class->_analyze_top_expression_for_inference(
            $declared_by_name,
            $inferred_specs,
            $expression_spec->{operand},
            $child_endpoint,
            $evidence,
            $fsm_file,
            $header,
            %opts,
        );
        my @unresolved_signal_refs;
        $class->_merge_unresolved_signal_refs(
            \@unresolved_signal_refs,
            $operand_analysis->{unresolved_signal_refs} || [],
            ($expression_spec->{repeat_count} || 0),
        );
        return {
            progress => $operand_analysis->{progress},
            known_exact_width => ($expression_spec->{repeat_count} || 0) * $operand_analysis->{known_exact_width},
            unresolved_signal_refs => \@unresolved_signal_refs,
        };
    }

    if ($expr_kind eq 'concat') {
        my $progress = 0;
        my $known_exact_width = 0;
        my @unresolved_signal_refs;

        for my $operand_spec (@{$expression_spec->{operands} || []}) {
            my $operand_analysis = $class->_analyze_top_expression_for_inference(
                $declared_by_name,
                $inferred_specs,
                $operand_spec,
                $child_endpoint,
                $evidence,
                $fsm_file,
                $header,
                %opts,
            );
            $progress ||= $operand_analysis->{progress};
            $known_exact_width += $operand_analysis->{known_exact_width};
            $class->_merge_unresolved_signal_refs(
                \@unresolved_signal_refs,
                $operand_analysis->{unresolved_signal_refs} || [],
            );
        }

        return {
            progress => $progress,
            known_exact_width => $known_exact_width,
            unresolved_signal_refs => \@unresolved_signal_refs,
        };
    }

    confess "TopPortInferenceBuilder requires a supported top-expression inference rule";
}

sub _record_inferred_top_port_requirement ($class, $inferred_specs, $top_name, $direction, $required_width, $exact_width, $type, $declared_type_name, $declared_type_spec, $evidence, $fsm_file, $header) {
    my $existing = $inferred_specs->{$top_name};
    my $evidence_changed = 0;
    my $shape_changed = 0;

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

        if ($existing->{type} ne $type) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on interface type ('".$existing->{type}."' vs '$type'). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on type metadata too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $existing_declared_type_label = FSM::Composition::InterfacePortBuilder->declared_type_label({
            declared_type_name => $existing->{declared_type_name},
            declared_type_spec => $existing->{declared_type_spec},
        });
        my $incoming_declared_type_label = FSM::Composition::InterfacePortBuilder->declared_type_label({
            declared_type_name => $declared_type_name,
            declared_type_spec => $declared_type_spec,
        });
        if (FSM::Composition::InterfacePortBuilder->declared_type_conflicts(
            {
                declared_type_name => $existing->{declared_type_name},
                declared_type_spec => $existing->{declared_type_spec},
            },
            {
                declared_type_name => $declared_type_name,
                declared_type_spec => $declared_type_spec,
            },
        )) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on declared type contract ('".$existing_declared_type_label."' vs '".$incoming_declared_type_label."'). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on one declared type contract too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (defined($exact_width) && defined($existing->{exact_width}) && $existing->{exact_width} != $exact_width) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on width (".$existing->{exact_width}." vs $exact_width). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (defined($exact_width) && !defined($existing->{exact_width}) && $existing->{width} > $exact_width) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because top-expression evidence requires declared width at least ".$existing->{width}.", while another explicit top-link use fixes that same top port at width $exact_width. ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on one compatible declared width contract. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (!defined($exact_width) && defined($existing->{exact_width}) && $required_width > $existing->{exact_width}) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because top-expression evidence requires declared width at least $required_width, while another explicit top-link use fixes that same top port at width ".$existing->{exact_width}.". ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on one compatible declared width contract. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (!grep { $_ eq $evidence } @{$existing->{evidence}}) {
            push @{$existing->{evidence}}, $evidence;
            $evidence_changed = 1;
        }
        if (!defined($declared_type_spec) || !defined($existing->{declared_type_spec})) {
            if (defined($existing->{declared_type_name}) || defined($existing->{declared_type_spec})) {
                $existing->{declared_type_name} = undef;
                $existing->{declared_type_spec} = undef;
                $shape_changed = 1;
            }
        } elsif (defined($existing->{declared_type_name}) && (!defined($declared_type_name) || $existing->{declared_type_name} ne $declared_type_name)) {
            $existing->{declared_type_name} = undef;
            $shape_changed = 1;
        }
        if (defined($exact_width) && (!defined($existing->{exact_width}) || $existing->{exact_width} != $exact_width)) {
            $existing->{exact_width} = $exact_width;
            $shape_changed = 1;
        }
        my $new_width = defined($existing->{exact_width})
            ? $existing->{exact_width}
            : ($required_width > $existing->{width} ? $required_width : $existing->{width});
        if ($existing->{width} != $new_width) {
            $existing->{width} = $new_width;
            $shape_changed = 1;
        }
        return $shape_changed || $evidence_changed ? 1 : 0;
    }

    $inferred_specs->{$top_name} = {
        name => $top_name,
        direction => $direction,
        width => $required_width,
        exact_width => $exact_width,
        type => $type,
        declared_type_name => $declared_type_name,
        declared_type_spec => $declared_type_spec,
        evidence => [$evidence],
    };
    return 1;
}

sub _required_top_width_for_expression_spec ($class, $expression_spec) {
    my $expr_kind = $expression_spec->{expr_kind} || '';
    return $expression_spec->{width}
        if $expr_kind eq 'signal_ref' || $expr_kind eq 'child_signal_ref';
    return ($expression_spec->{index} || 0) + 1
        if $expr_kind eq 'bit_select' || $expr_kind eq 'child_bit_select';
    return (($expression_spec->{msb} || 0) > ($expression_spec->{lsb} || 0)
        ? ($expression_spec->{msb} || 0)
        : ($expression_spec->{lsb} || 0)) + 1
        if $expr_kind eq 'slice' || $expr_kind eq 'child_slice';
    return $expression_spec->{width}
        if ($expr_kind eq 'aggregate_ref' || $expr_kind eq 'child_aggregate_ref')
            && defined($expression_spec->{width});
    confess "TopPortInferenceBuilder requires a supported top-expression width rule";
}

sub _expression_spec_width ($class, $expression_spec) {
    my $expr_kind = $expression_spec->{expr_kind} || '';
    return $expression_spec->{width}
        if $expr_kind eq 'signal_ref' || $expr_kind eq 'literal' || $expr_kind eq 'child_signal_ref';
    return 1
        if $expr_kind eq 'bit_select' || $expr_kind eq 'child_bit_select';
    return abs(($expression_spec->{msb} || 0) - ($expression_spec->{lsb} || 0)) + 1
        if $expr_kind eq 'slice' || $expr_kind eq 'child_slice';
    return $expression_spec->{width}
        if ($expr_kind eq 'aggregate_ref' || $expr_kind eq 'child_aggregate_ref')
            && defined($expression_spec->{width});

    if ($expr_kind eq 'concat') {
        my $width = 0;
        $width += $class->_expression_spec_width($_)
            for @{$expression_spec->{operands} || []};
        return $width;
    }

    if ($expr_kind eq 'repeat') {
        return ($expression_spec->{repeat_count} || 0)
            * $class->_expression_spec_width($expression_spec->{operand});
    }

    confess "TopPortInferenceBuilder requires a supported top-expression exact-width rule";
}

sub _merge_unresolved_signal_refs ($class, $into, $incoming, $multiplier = 1) {
    return unless ref($into) eq 'ARRAY';
    return unless ref($incoming) eq 'ARRAY';
    return unless defined($multiplier) && $multiplier =~ /\A\d+\z/ && $multiplier >= 1;

    my %index_by_port = map { (($into->[$_]{port_name} || '') => $_) } 0 .. $#$into;

    for my $entry (@$incoming) {
        next unless ref($entry) eq 'HASH';
        my $port_name = $entry->{port_name} || '';
        next unless length $port_name;
        my $entry_multiplier = ($entry->{width_multiplier} || 1) * $multiplier;

        if (exists $index_by_port{$port_name}) {
            $into->[$index_by_port{$port_name}]{width_multiplier} += $entry_multiplier;
            next;
        }

        push @$into, {
            port_name => $port_name,
            width_multiplier => $entry_multiplier,
        };
        $index_by_port{$port_name} = $#$into;
    }
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
