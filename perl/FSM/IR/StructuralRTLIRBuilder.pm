package FSM::IR::StructuralRTLIRBuilder;

=head1 NAME

FSM::IR::StructuralRTLIRBuilder - Builder and coercion helpers for forward StructuralRTLIR

=head1 DESCRIPTION

Builds and coerces the extracted forward C<StructuralRTLIR> layer. The current
shipped scope covers composition-top structural construction from
C<FSM::Composition::Plan>, bounded direct-root structural construction from
generated module analysis, and object/hash coercion for downstream pipeline and
backend consumers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

sub build_from_generated_module_info ($class, %args) {
    my $module_info = $args{module_info}
        or confess "StructuralRTLIRBuilder requires a module_info";
    my $target_language = $args{target_language} // 'systemverilog';
    my $fsm_module = $args{fsm_module};
    my $hdl_generator = $args{hdl_generator};

    my @ports;
    my %seen_ports;
    for my $bucket (
        [ inputs => 'input' ],
        [ outputs => 'output' ],
    ) {
        my ($analysis_key, $direction) = @$bucket;
        for my $entry (@{$module_info->{signal_analysis}{$analysis_key} || []}) {
            my $signal_name = $entry->{name};
            my $signal = ref($module_info->{signals}) eq 'HASH'
                ? $module_info->{signals}{$signal_name}
                : undef;
            my $type = (ref($signal) && $signal->can('type')) ? $signal->type : undef;
            my $signed = (ref($signal) && $signal->can('signed')) ? $signal->signed : 0;
            my $state_model = (ref($signal) && $signal->can('state_model')) ? $signal->state_model : undef;
            my $declared_type_name = (ref($signal) && $signal->can('declared_type_name'))
                ? $signal->declared_type_name
                : undef;
            my $declared_type_spec = (ref($signal) && $signal->can('declared_type_spec'))
                ? $signal->declared_type_spec
                : undef;

            my $port_entry = {
                name => $signal_name,
                direction => $direction,
                width => ($entry->{width} || 1),
                signed => $signed ? 1 : 0,
                type => $type,
            };
            $port_entry->{state_model} = $state_model if defined $state_model;
            $port_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
            $port_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
            push @ports, $port_entry;
            $seen_ports{$signal_name} = 1;
        }
    }

    my $system_contract = $module_info->{system_contract} || {};
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{clock}) && length($system_contract->{clock})
        && !$seen_ports{$system_contract->{clock}}) {
        push @ports, {
            name => $system_contract->{clock},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'clock',
        };
        $seen_ports{$system_contract->{clock}} = 1;
    }

    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{reset}) && length($system_contract->{reset})
        && !$seen_ports{$system_contract->{reset}}) {
        push @ports, {
            name => $system_contract->{reset},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'reset',
        };
        $seen_ports{$system_contract->{reset}} = 1;
    }

    my $assignment_records = _direct_structural_assignment_records(
        hdl_generator => $hdl_generator,
    );

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($module_info->{module_name} // ''),
        source_root_kind => (
            $module_info->{source_root_kind}
                // ($fsm_module && $fsm_module->can('source_root_kind') ? $fsm_module->source_root_kind : 'fsm')
        ),
        target_language => $target_language,
        ports => \@ports,
        nets => _direct_structural_nets(
            fsm_module => $fsm_module,
            hdl_generator => $hdl_generator,
        ),
        instances => [],
        assignment_records => $assignment_records,
        auxiliary_assignments => _direct_structural_auxiliary_assignments(
            assignment_records => $assignment_records,
            hdl_generator => $hdl_generator,
        ),
    );
}

sub build_from_composition_plan ($class, $composition_plan, $target_language = 'systemverilog') {
    confess "StructuralRTLIRBuilder requires a composition plan"
        unless $composition_plan;

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => ($target_language // 'systemverilog'),
        ports => [
            map {
                do {
                    my $port_entry = {
                    name => $_->name,
                    direction => $_->direction,
                    width => $_->width,
                    signed => ($_->can('signed') ? $_->signed : 0),
                    type => $_->type,
                    binding_mode => $_->binding_mode,
                    origin_kind => $_->origin_kind,
                    };
                    my $state_model = $_->can('state_model') ? $_->state_model : undef;
                    my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                    my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                    $port_entry->{state_model} = $state_model if defined $state_model;
                    $port_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                    $port_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                    $port_entry;
                }
            } @{$composition_plan->ports || []}
        ],
        nets => [
            map {
                do {
                    my $net_entry = {
                    name => $_->name,
                    width => $_->width,
                    source => $_->source,
                    targets => [@{$_->targets || []}],
                    };
                    my $declaration_keyword = $_->can('declaration_keyword') ? $_->declaration_keyword : undef;
                    my $signed = $_->can('signed') ? $_->signed : 0;
                    my $state_model = $_->can('state_model') ? $_->state_model : undef;
                    my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                    my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                    $net_entry->{declaration_keyword} = $declaration_keyword if defined $declaration_keyword;
                    $net_entry->{signed} = $signed if $signed;
                    $net_entry->{state_model} = $state_model if defined $state_model;
                    $net_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                    $net_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                    $net_entry;
                }
            } @{$composition_plan->nets || []}
        ],
        instances => [
            map {
                +{
                    kind => $_->kind,
                    instance_name => $_->instance_name,
                    module_name => $_->module_name,
                    source_name => $_->source_name,
                    interface_ports => [
                        map {
                            do {
                                my $interface_entry = {
                                name => $_->name,
                                direction => $_->direction,
                                width => $_->width,
                                signed => ($_->can('signed') ? $_->signed : 0),
                                type => $_->type,
                                };
                                my $state_model = $_->can('state_model') ? $_->state_model : undef;
                                my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                                my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                                $interface_entry->{state_model} = $state_model if defined $state_model;
                                $interface_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                                $interface_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                                $interface_entry;
                            }
                        } @{$_->interface_ports || []}
                    ],
                    port_bindings => [
                        map { normalized_binding($_) } @{$_->port_bindings || []}
                    ],
                    parameter_overrides => [
                        map { _clone($_) } @{$_->parameter_overrides || []}
                    ],
                }
            } @{$composition_plan->instances || []}
        ],
        declared_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->links || []}
        ],
        resolved_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->resolved_links || []}
        ],
        assignment_records => [],
        auxiliary_assignments => [@{$composition_plan->auxiliary_assignments || []}],
    );
}

sub coerce ($class, $structural_rtl_ir, $default_target_language = 'systemverilog') {
    return $structural_rtl_ir
        if blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref');

    my $structural_rtl_ir_hash = ref($structural_rtl_ir) eq 'HASH'
        ? $structural_rtl_ir
        : {};

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($structural_rtl_ir_hash->{module_name} // ''),
        source_root_kind => ($structural_rtl_ir_hash->{source_root_kind} // 'fsm'),
        target_language => ($structural_rtl_ir_hash->{target_language} // ($default_target_language // 'systemverilog')),
        ports => ($structural_rtl_ir_hash->{ports} || []),
        nets => ($structural_rtl_ir_hash->{nets} || []),
        instances => ($structural_rtl_ir_hash->{instances} || []),
        declared_links => ($structural_rtl_ir_hash->{declared_links} || []),
        resolved_links => ($structural_rtl_ir_hash->{resolved_links} || []),
        assignment_records => ($structural_rtl_ir_hash->{assignment_records} || []),
        auxiliary_assignments => ($structural_rtl_ir_hash->{auxiliary_assignments} || []),
    );
}

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }
    return $value;
}

sub _direct_structural_nets (%args) {
    my @entries = (
        @{_direct_internal_declaration_nets(%args)},
        @{_direct_top_enable_nets(%args)},
        @{_direct_assignment_enable_nets(%args)},
    );

    my %seen;
    my @deduped;
    for my $entry (@entries) {
        next unless ref($entry) eq 'HASH';
        my $name = $entry->{name};
        next unless defined($name) && length($name);
        next if $seen{$name}++;
        push @deduped, $entry;
    }

    return \@deduped;
}

sub _direct_internal_declaration_nets (%args) {
    my $fsm_module = $args{fsm_module};
    my $hdl_generator = $args{hdl_generator};
    return [] unless $fsm_module && ref($hdl_generator);

    my $planning_support = $hdl_generator->{enable_graph_module_planning_support};
    return [] unless ref($planning_support)
        && $planning_support->can('build_module_declaration_plan')
        && $planning_support->can('build_internal_signal_declaration_plan');

    my $module_plan = $planning_support->build_module_declaration_plan($fsm_module);
    return [] unless ref($module_plan) eq 'HASH';

    my $declaration_plan = $planning_support->build_internal_signal_declaration_plan(
        $fsm_module,
        $module_plan->{declared_port_signals},
    );
    return [] unless ref($declaration_plan) eq 'HASH';

    return [
        _direct_net_entries_from_declarations(
            $declaration_plan->{signal_decls},
            $declaration_plan->{signal_signed},
            $declaration_plan->{signal_state_model},
            $declaration_plan->{signal_declared_type_name},
            $declaration_plan->{signal_declared_type_spec},
        ),
        _direct_net_entries_from_declarations(
            $declaration_plan->{aux_decls},
            $declaration_plan->{aux_signed},
            $declaration_plan->{aux_state_model},
            $declaration_plan->{aux_declared_type_name},
            $declaration_plan->{aux_declared_type_spec},
        ),
    ];
}

sub _direct_top_enable_nets (%args) {
    my $hdl_generator = $args{hdl_generator};
    return [] unless ref($hdl_generator);

    my @entries;
    for my $state_name (sort keys %{$hdl_generator->{state_enables} || {}}) {
        push @entries, _direct_one_bit_enable_net("${state_name}_en");
    }

    for my $dt_name (sort keys %{$hdl_generator->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        push @entries, _direct_one_bit_enable_net("${clean_name}_en");
    }

    return \@entries;
}

sub _direct_assignment_enable_nets (%args) {
    my $hdl_generator = $args{hdl_generator};
    return [] unless ref($hdl_generator);

    my $assignment_analysis = $hdl_generator->{assignment_analysis};
    return [] unless ref($assignment_analysis) eq 'HASH';

    my @entries;
    for my $lhs (sort keys %$assignment_analysis) {
        my $lhs_analysis = $assignment_analysis->{$lhs};
        next unless ref($lhs_analysis) eq 'HASH';

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups} || {}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
            next unless ref($rhs_group) eq 'HASH';

            for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                next unless ref($dt_enable) eq 'HASH';
                push @entries, _direct_one_bit_enable_net($dt_enable->{enable_name});
            }

            my $lhs_enable = $rhs_group->{lhs_level_enable};
            push @entries, _direct_one_bit_enable_net($lhs_enable->{name})
                if ref($lhs_enable) eq 'HASH';
        }
    }

    return \@entries;
}

sub _direct_structural_auxiliary_assignments (%args) {
    my $assignment_records = $args{assignment_records};
    if (ref($assignment_records) eq 'ARRAY') {
        return [
            map { $_->{rendered} }
            grep { ref($_) eq 'HASH' && defined($_->{rendered}) && length($_->{rendered}) }
            @$assignment_records
        ];
    }

    my $hdl_generator = $args{hdl_generator};
    return [] unless ref($hdl_generator);

    my $enable_support = $hdl_generator->{enable_graph_enable_support};
    return [] unless ref($enable_support)
        && $enable_support->can('generate_enable_conditions')
        && $enable_support->can('generate_dt_enables_from_analysis')
        && $enable_support->can('generate_lhs_enables_from_analysis');

    my @rendered_blocks = _with_preserved_referenced_intermediate_signals(
        $hdl_generator,
        sub {
            return (
                $enable_support->generate_enable_conditions(),
                $enable_support->generate_dt_enables_from_analysis(),
                $enable_support->generate_lhs_enables_from_analysis(),
            );
        },
    );

    return _direct_assignment_lines_from_blocks(@rendered_blocks);
}

sub _with_preserved_referenced_intermediate_signals ($hdl_generator, $callback) {
    my $had_original = exists $hdl_generator->{referenced_intermediate_signals};
    my $original = _clone($hdl_generator->{referenced_intermediate_signals});
    my @result;

    my $ok = eval {
        @result = $callback->();
        1;
    };
    my $error = $@;

    if ($had_original) {
        $hdl_generator->{referenced_intermediate_signals} = $original;
    } else {
        delete $hdl_generator->{referenced_intermediate_signals};
    }

    die $error unless $ok;
    return @result;
}

sub _direct_assignment_lines_from_blocks (@blocks) {
    my @assignments;

    for my $block (@blocks) {
        next unless defined($block) && !ref($block);

        for my $line (split /\n/, $block) {
            next unless $line =~ /\A\s*assign\s+\S+\s*=/;
            push @assignments, $line;
        }
    }

    return \@assignments;
}

sub _direct_structural_assignment_records (%args) {
    my $hdl_generator = $args{hdl_generator};
    return [] unless ref($hdl_generator);

    my $ast_support = $hdl_generator->{enable_graph_ast_support};
    my $enable_support = $hdl_generator->{enable_graph_enable_support};
    my @records;

    for my $state_name (sort keys %{$hdl_generator->{state_enables} || {}}) {
        push @records, _direct_assignment_record(
            lhs => "${state_name}_en",
            rhs_ast => $hdl_generator->{state_enables}{$state_name},
            ast_support => $ast_support,
            provenance => {
                family => 'generated_enable',
                role => 'top_state_enable',
                state_name => $state_name,
            },
        );
    }

    for my $dt_name (sort keys %{$hdl_generator->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        push @records, _direct_assignment_record(
            lhs => "${clean_name}_en",
            rhs_ast => $hdl_generator->{dt_enables}{$dt_name},
            ast_support => $ast_support,
            provenance => {
                family => 'generated_enable',
                role => 'standalone_dt_enable',
                dt_name => $dt_name,
                clean_dt_name => $clean_name,
            },
        );
    }

    my $assignment_analysis = $hdl_generator->{assignment_analysis};
    return [grep { defined $_ } @records]
        unless ref($assignment_analysis) eq 'HASH';

    if (ref($enable_support) && $enable_support->can('build_boundary_gated_dt_enable_ast')) {
        my %dt_to_lhs_enables;
        for my $lhs (sort keys %$assignment_analysis) {
            my $lhs_analysis = $assignment_analysis->{$lhs};
            next unless ref($lhs_analysis) eq 'HASH';

            for my $rhs (sort keys %{$lhs_analysis->{rhs_groups} || {}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                next unless ref($rhs_group) eq 'HASH';

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables} || []}) {
                    next unless ref($dt_enable_info) eq 'HASH';
                    my $dt_name = $dt_enable_info->{dt};
                    next unless defined($dt_name) && length($dt_name);

                    push @{$dt_to_lhs_enables{$dt_name}{$lhs}}, {
                        %$dt_enable_info,
                        rhs => $rhs,
                    };
                }
            }
        }

        for my $dt_name (sort keys %dt_to_lhs_enables) {
            for my $lhs (sort keys %{$dt_to_lhs_enables{$dt_name}}) {
                for my $enable_info (@{$dt_to_lhs_enables{$dt_name}{$lhs}}) {
                    my $rhs = $enable_info->{rhs};
                    my $rhs_ast = $enable_support->build_boundary_gated_dt_enable_ast($enable_info);
                    push @records, _direct_assignment_record(
                        lhs => $enable_info->{enable_name},
                        rhs_ast => $rhs_ast,
                        ast_support => $ast_support,
                        comment => "$lhs <- $rhs",
                        provenance => {
                            family => 'generated_enable',
                            role => 'dt_specific_enable',
                            dt_name => $dt_name,
                            lhs_signal => $lhs,
                            rhs_value => $rhs,
                            dte_gate_signal => $enable_info->{dte_gate_signal},
                        },
                    );
                }
            }
        }
    }

    for my $lhs (sort keys %$assignment_analysis) {
        my $lhs_analysis = $assignment_analysis->{$lhs};
        next unless ref($lhs_analysis) eq 'HASH';

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups} || {}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
            next unless ref($rhs_group) eq 'HASH';

            my $lhs_enable = $rhs_group->{lhs_level_enable};
            next unless ref($lhs_enable) eq 'HASH' && defined($lhs_enable->{name});

            push @records, _direct_assignment_record(
                lhs => $lhs_enable->{name},
                rhs_ast => $lhs_enable->{ast},
                ast_support => $ast_support,
                provenance => {
                    family => 'generated_enable',
                    role => 'lhs_level_enable',
                    lhs_signal => $lhs,
                    rhs_value => $rhs,
                },
            );
        }
    }

    return [grep { defined $_ } @records];
}

sub _direct_assignment_record (%args) {
    my $lhs = $args{lhs};
    return undef unless defined($lhs) && length($lhs);

    my $rhs_text = _direct_ast_to_systemverilog(
        ast => $args{rhs_ast},
        ast_support => $args{ast_support},
    );
    my $rendered = "  assign $lhs = $rhs_text;";
    $rendered .= "  // $args{comment}"
        if defined($args{comment}) && length($args{comment});

    return {
        kind => 'continuous_assign',
        lhs => {
            kind => 'signal_ref',
            name => $lhs,
        },
        rhs => {
            kind => 'expression',
            language => 'systemverilog',
            text => $rhs_text,
            ast => _direct_ast_record($args{rhs_ast}),
        },
        rendered => $rendered,
        provenance => _clone($args{provenance} || {}),
    };
}

sub _direct_ast_to_systemverilog (%args) {
    my $ast = $args{ast};
    return "1'b1" unless defined($ast);
    return $ast unless ref($ast);

    my $ast_support = $args{ast_support};
    if (blessed($ast) && ref($ast_support) && $ast_support->can('ast_to_systemverilog')) {
        return $ast_support->ast_to_systemverilog($ast);
    }

    return $ast->to_systemverilog
        if blessed($ast) && $ast->can('to_systemverilog');

    return "$ast";
}

sub _direct_ast_record ($ast) {
    return {
        kind => 'scalar_expression',
        value => $ast,
    } unless ref($ast);

    return {
        kind => 'null_expression',
    } unless blessed($ast);

    my $class = ref($ast);

    if ($ast->can('operator') && $ast->can('left') && $ast->can('right')) {
        return {
            kind => 'binary_op',
            class => $class,
            operator => $ast->operator,
            left => _direct_ast_record($ast->left),
            right => _direct_ast_record($ast->right),
        };
    }

    if ($ast->can('operator') && $ast->can('operand')) {
        return {
            kind => 'unary_op',
            class => $class,
            operator => $ast->operator,
            operand => _direct_ast_record($ast->operand),
        };
    }

    if ($ast->isa('FSM::CoreAST::AggregateRef')) {
        my $signal = $ast->signal;
        return {
            kind => 'aggregate_ref',
            class => $class,
            signal => _direct_signal_name($signal),
            path => _direct_json_clone($ast->path),
            width => $ast->can('width') ? $ast->width : undef,
            type_spec => $ast->can('type_spec') ? _direct_json_clone($ast->type_spec) : undef,
        };
    }

    if ($ast->isa('FSM::CoreAST::ParameterRef')) {
        return {
            kind => 'parameter_ref',
            class => $class,
            name => $ast->name,
            width => $ast->can('width') ? $ast->width : undef,
            type_spec => $ast->can('type_spec') ? _direct_json_clone($ast->type_spec) : undef,
            default_value_text => $ast->can('default_value_text') ? $ast->default_value_text : undef,
            value_info => $ast->can('value_info') ? _direct_json_clone($ast->value_info) : undef,
        };
    }

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') || $ast->can('signal_name')) {
        my $entry = {
            kind => 'signal_ref',
            class => $class,
            name => _direct_ast_signal_name($ast),
        };
        $entry->{slice} = _direct_json_clone($ast->slice)
            if $ast->can('slice') && defined($ast->slice);
        return $entry;
    }

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal') || $ast->isa('FSM::AST::LogicalConstant')) {
        my $entry = {
            kind => $ast->isa('FSM::AST::LogicalConstant') ? 'logical_constant' : 'literal',
            class => $class,
            value => _direct_json_scalar($ast->value),
        };
        $entry->{width} = $ast->width if $ast->can('width') && defined($ast->width);
        $entry->{radix} = $ast->radix if $ast->can('radix') && defined($ast->radix);
        return $entry;
    }

    return {
        kind => 'opaque_ast',
        class => $class,
        text => eval { $ast->to_systemverilog } || undef,
    };
}

sub _direct_ast_signal_name ($ast) {
    return undef unless blessed($ast);
    return $ast->signal_name if $ast->can('signal_name') && defined($ast->signal_name);
    return $ast->name if $ast->can('name') && defined($ast->name);
    return _direct_signal_name($ast->signal)
        if $ast->can('signal') && blessed($ast->signal);
    return eval { $ast->to_systemverilog };
}

sub _direct_signal_name ($signal) {
    return undef unless defined($signal);
    return $signal->name if blessed($signal) && $signal->can('name');
    return "$signal";
}

sub _direct_json_clone ($value) {
    return undef unless defined $value;
    return _direct_json_scalar($value) if blessed($value);

    if (ref($value) eq 'HASH') {
        return { map { $_ => _direct_json_clone($value->{$_}) } sort keys %$value };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _direct_json_clone($_) } @$value ];
    }

    return $value;
}

sub _direct_json_scalar ($value) {
    return undef unless defined $value;
    return "$value" if blessed($value);
    return $value;
}

sub _direct_one_bit_enable_net ($name) {
    return undef unless defined($name) && length($name);
    return {
        name => $name,
        width => 1,
        signed => 0,
        source => undef,
        targets => [],
    };
}

sub _direct_net_entries_from_declarations (
    $decls,
    $signed_map = undef,
    $state_model_map = undef,
    $declared_type_name_map = undef,
    $declared_type_spec_map = undef,
) {
    return () unless ref($decls) eq 'HASH';

    my @entries;
    for my $name (sort keys %$decls) {
        my $entry = {
            name => $name,
            width => ($decls->{$name} || 1),
            source => undef,
            targets => [],
            signed => (($signed_map || {})->{$name} // 0) ? 1 : 0,
        };

        my $state_model = ($state_model_map || {})->{$name};
        my $declared_type_name = ($declared_type_name_map || {})->{$name};
        my $declared_type_spec = ($declared_type_spec_map || {})->{$name};

        $entry->{state_model} = $state_model if defined $state_model;
        $entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
        $entry->{declared_type_spec} = _clone($declared_type_spec) if defined $declared_type_spec;

        push @entries, $entry;
    }

    return @entries;
}

1;

__END__

=head1 METHODS

=head2 build_from_generated_module_info

Builds a structural RTL IR object from generated direct-root module analysis,
preserving the module boundary ports and system-interface ports currently
materialized in the bounded direct structural slice.

=head2 build_from_composition_plan

Builds a structural RTL IR object from a realized composition plan, preserving
top ports, nets, instances, links, bindings, and auxiliary assignments.

=head2 coerce

Coerces a structural hash payload or existing structural object into a
C<FSM::IR::StructuralRTLIR> instance.

=cut
