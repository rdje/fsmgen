package FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport - Validate pre-emission operand and assignment semantic contracts

=head1 DESCRIPTION

Owns the bounded direct-backend validation pass that checks AST operands and
assignment-width contracts against the generation inventories before final
SystemVerilog text emission. This catches internal-signal contract holes
early, so the final renderer can stay a simpler AST walk instead of silently
depending on undeclared or unassigned internal names or on hidden width
adaptation side effects.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed refaddr);

use FSM::Debug;
use FSM::Package::PayloadTypeSupport;

=head2 new

Construct one operand-contract validation owner bound to a specific direct
backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[OperandContractValidationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 validate_pre_generation_operand_contract

Validate that AST operands referenced by the prepared direct-backend
generation flow are either top-level signals or backed by declared and
assigned internal generation inventory, and that assignment families have not
already relied on hidden width adaptation before emission begins.

=cut

sub validate_pre_generation_operand_contract ($self, $fsm_module, $prepared_block = undef) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $inventory = $self->build_operand_contract_inventory($fsm_module, $prepared_block);
    my @violations;

    for my $state_name (sort keys %{$ctx->{state_enables} || {}}) {
        $self->_validate_named_ast(
            "state enable '$state_name\_en'",
            $ctx->{state_enables}{$state_name},
            $inventory,
            \@violations,
        );
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        $self->_validate_named_ast(
            "standalone DT enable '$clean_name\_en'",
            $ctx->{dt_enables}{$dt_name},
            $inventory,
            \@violations,
        );
    }

    for my $lhs (sort keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs} || next;

        for my $assignment (@{$lhs_analysis->{assignments} || []}) {
            $self->_validate_named_ast(
                "assignment guard for '$lhs'",
                $assignment->{conditions_ast},
                $inventory,
                \@violations,
            );
            $self->_validate_assignment_width_contract(
                $lhs,
                $lhs_analysis,
                $assignment,
                \@violations,
            );
            $self->_validate_assignment_aggregate_contract(
                $lhs,
                $assignment,
                \@violations,
            );
        }

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups} || {}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs} || {};

            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables} || []}) {
                $self->_validate_named_ast(
                    "DT-specific enable '$dt_enable_info->{enable_name}'",
                    $dt_enable_info->{enable_ast},
                    $inventory,
                    \@violations,
                );
            }

            if ($rhs_group->{lhs_level_enable}) {
                $self->_validate_named_ast(
                    "LHS-level enable '$rhs_group->{lhs_level_enable}{name}'",
                    $rhs_group->{lhs_level_enable}{ast},
                    $inventory,
                    \@violations,
                );
            }
        }
    }

    for my $signal_name (sort keys %{ $prepared_block->{filtered_signals} || {} }) {
        my $signal_info = $prepared_block->{filtered_signals}{$signal_name} || {};
        my $runtime_ast = $signal_info->{runtime_ast};

        if ($runtime_ast && (blessed($runtime_ast) || ref($runtime_ast) eq 'HASH')) {
            $self->_validate_named_ast(
                "consolidated intermediate '$signal_name'",
                $runtime_ast,
                $inventory,
                \@violations,
            );
            next;
        }

        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        $self->_validate_named_expression(
            "consolidated intermediate '$signal_name'",
            $expression,
            $inventory,
            \@violations,
        );
    }

    return unless @violations;

    my $message = "[OperandContractValidationSupport.pm][validate_pre_generation_operand_contract()] "
        . "Pre-generation operand contract validation failed:\n"
        . join('', map { "  - $_\n" } @violations);
    die $message;
}

=head2 build_operand_contract_inventory

Build the normalized signal ownership inventory used by the pre-emission
operand validator.

=cut

sub build_operand_contract_inventory ($self, $fsm_module, $prepared_block = undef) {
    my $ctx = $self->{flattened_dt};
    my $module_plan = $ctx->{enable_graph_module_planning_support}->build_module_declaration_plan($fsm_module);
    my $internal_plan = $ctx->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
        $fsm_module,
        $module_plan->{declared_port_signals},
    );
    my $state_plan = $ctx->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);

    my %top_level_signals;
    for my $group (qw(base_ports inputs outputs)) {
        for my $port (@{$module_plan->{$group} || []}) {
            next unless ref($port) eq 'HASH';
            my $name = $port->{name};
            next unless defined($name) && $name ne '';
            $top_level_signals{$name} = 1;
        }
    }

    my %declared_internal_signals = (
        %{$internal_plan->{signal_decls} || {}},
        %{$internal_plan->{aux_decls} || {}},
    );
    my %assigned_internal_signals;
    my %localparam_names = map { ($_->{localparam_name} => 1) } @{$state_plan->{encodings} || []};

    if ($state_plan->{has_state_registers}) {
        $declared_internal_signals{current_state} = 1;
        $declared_internal_signals{next_state} = 1;
        $assigned_internal_signals{current_state} = 1;
        $assigned_internal_signals{next_state} = 1;
    }

    for my $state_name (keys %{$ctx->{state_enables} || {}}) {
        my $enable_name = "${state_name}_en";
        $declared_internal_signals{$enable_name} = 1;
        $assigned_internal_signals{$enable_name} = 1;
    }

    for my $dt_name (keys %{$ctx->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        my $enable_name = "${clean_name}_en";
        $declared_internal_signals{$enable_name} = 1;
        $assigned_internal_signals{$enable_name} = 1;
    }

    for my $lhs (keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs} || next;

        $assigned_internal_signals{$lhs} = 1 unless $top_level_signals{$lhs};

        for my $rhs (keys %{$lhs_analysis->{rhs_groups} || {}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs} || {};

            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables} || []}) {
                my $enable_name = $dt_enable_info->{enable_name};
                next unless defined($enable_name) && $enable_name ne '';
                $declared_internal_signals{$enable_name} = 1;
                $assigned_internal_signals{$enable_name} = 1;
            }

            my $lhs_level_enable = $rhs_group->{lhs_level_enable} || {};
            my $lhs_enable_name = $lhs_level_enable->{name};
            if (defined($lhs_enable_name) && $lhs_enable_name ne '') {
                $declared_internal_signals{$lhs_enable_name} = 1;
                $assigned_internal_signals{$lhs_enable_name} = 1;
            }
        }
    }

    my %driven_aux_signals = $ctx->{enable_graph_assignment_support}->get_driven_signals();
    for my $signal_name (keys %driven_aux_signals) {
        $declared_internal_signals{$signal_name} = 1;
        $assigned_internal_signals{$signal_name} = 1;
    }

    my $all_intermediate_signals = $prepared_block && ref($prepared_block) eq 'HASH'
        ? ($prepared_block->{all_intermediate_signals} || {})
        : ($ctx->{intermediate_signals} || {});
    my $filtered_intermediate_signals = $prepared_block && ref($prepared_block) eq 'HASH'
        ? ($prepared_block->{filtered_signals} || {})
        : {};

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        $declared_internal_signals{$signal_name} = 1;
    }
    for my $signal_name (keys %{$filtered_intermediate_signals || {}}) {
        $assigned_internal_signals{$signal_name} = 1;
    }

    return {
        top_level_signals => \%top_level_signals,
        declared_internal_signals => \%declared_internal_signals,
        assigned_internal_signals => \%assigned_internal_signals,
        localparam_names => \%localparam_names,
    };
}

sub _validate_assignment_width_contract ($self, $lhs, $lhs_analysis, $assignment, $violations) {
    return unless ref($assignment) eq 'HASH';

    my $source_provenance = ref($assignment->{source_provenance}) eq 'HASH'
        ? $assignment->{source_provenance}
        : {};
    my $width_contract = ref($source_provenance->{width_contract}) eq 'HASH'
        ? $source_provenance->{width_contract}
        : {};
    my $resolution = $width_contract->{resolution} // '';

    return unless $resolution eq 'rhs_expanded_to_lhs' || $resolution eq 'rhs_truncated_to_lhs';

    my $lhs_width = $self->{flattened_dt}{enable_graph_assignment_support}
        ->get_lhs_width_from_analysis($lhs_analysis);
    my $rhs_width = $width_contract->{rhs_width};
    my $rhs_display = defined($source_provenance->{raw_value_expr})
            && $source_provenance->{raw_value_expr} ne ''
            && $source_provenance->{raw_value_expr} !~ /^(?:ARRAY|HASH)$/
        ? $source_provenance->{raw_value_expr}
        : (
            defined($assignment->{rhs}) && $assignment->{rhs} ne ''
                ? $assignment->{rhs}
                : '<unknown>'
        );
    my $adaptation = $resolution eq 'rhs_expanded_to_lhs'
        ? 'implicit widening'
        : 'implicit truncation';

    push @$violations,
        "assignment to '$lhs' uses RHS '$rhs_display' with incompatible width"
        . (defined($rhs_width) ? " $rhs_width" : ' <unknown>')
        . " for LHS width $lhs_width; the current contract blocks $adaptation and requires an explicit width-aligned source expression before generation";
}

sub _validate_assignment_aggregate_contract ($self, $lhs, $assignment, $violations) {
    return unless ref($assignment) eq 'HASH';

    my $source_provenance = ref($assignment->{source_provenance}) eq 'HASH'
        ? $assignment->{source_provenance}
        : {};

    my @contracts = ref($source_provenance->{aggregate_assignment_contracts}) eq 'ARRAY'
        ? @{$source_provenance->{aggregate_assignment_contracts}}
        : ();
    if (!@contracts) {
        my $fallback_contract = $self->_aggregate_assignment_contract_from_provenance(
            $lhs,
            $assignment,
            $source_provenance,
        );
        @contracts = ($fallback_contract) if $fallback_contract;
    }

    for my $contract (@contracts) {
        next unless ref($contract) eq 'HASH';

        my $source_aggregate_type_spec = ref($contract->{source_aggregate_type_spec}) eq 'HASH'
            ? $contract->{source_aggregate_type_spec}
            : undef;
        next unless $source_aggregate_type_spec;

        my $source_kind = $source_aggregate_type_spec->{kind} || '';
        next unless $source_kind eq 'list' || $source_kind eq 'record';

        my $target_declared_type_spec = ref($contract->{target_aggregate_type_spec}) eq 'HASH'
            ? $contract->{target_aggregate_type_spec}
            : undef;
        next unless $target_declared_type_spec;

        my $target_kind = $target_declared_type_spec->{kind} || '';
        next unless $target_kind eq 'list' || $target_kind eq 'record';

        next if FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(
            $source_aggregate_type_spec,
            $target_declared_type_spec,
        );

        my $rhs_display = defined($contract->{aggregate_symbol_name})
                && $contract->{aggregate_symbol_name} ne ''
            ? $contract->{aggregate_symbol_name}
            : (
                defined($contract->{raw_value_expr})
                    && $contract->{raw_value_expr} ne ''
                    && $contract->{raw_value_expr} !~ /^(?:ARRAY|HASH)$/
                ? $contract->{raw_value_expr}
                : (
                    defined($assignment->{rhs}) && $assignment->{rhs} ne ''
                        ? $assignment->{rhs}
                        : '<unknown>'
                )
            );

        my $target_display = defined($contract->{target_display}) && $contract->{target_display} ne ''
            ? $contract->{target_display}
            : $lhs;
        my $source_type_label = FSM::Package::PayloadTypeSupport->type_spec_label($source_aggregate_type_spec);
        my $target_type_label = FSM::Package::PayloadTypeSupport->type_spec_label($target_declared_type_spec);

        push @$violations,
            "assignment to '$target_display' uses whole aggregate RHS '$rhs_display' with contract '$source_type_label'"
            . " that does not match declared type '$target_type_label'; the current contract blocks width-equal aggregate-shape mismatch before generation";
    }
}

sub _aggregate_assignment_contract_from_provenance ($self, $lhs, $assignment, $source_provenance) {
    my $source_aggregate_type_spec = ref($source_provenance->{aggregate_type_spec}) eq 'HASH'
        ? $source_provenance->{aggregate_type_spec}
        : undef;
    return unless $source_aggregate_type_spec;

    my $lhs_ast = $assignment->{lhs_ast};
    my ($target_declared_type_spec, $target_display) = $self->_target_aggregate_contract_from_lhs_ast($lhs, $lhs_ast);
    return unless ref($target_declared_type_spec) eq 'HASH';

    my %contract = (
        source_aggregate_type_spec => $source_aggregate_type_spec,
        target_aggregate_type_spec => $target_declared_type_spec,
        target_display => $target_display,
    );
    $contract{aggregate_symbol_name} = $source_provenance->{aggregate_symbol_name}
        if defined($source_provenance->{aggregate_symbol_name}) && $source_provenance->{aggregate_symbol_name} ne '';
    $contract{raw_value_expr} = $source_provenance->{raw_value_expr}
        if defined($source_provenance->{raw_value_expr}) && $source_provenance->{raw_value_expr} ne '';

    return \%contract;
}

sub _target_aggregate_contract_from_lhs_ast ($self, $lhs, $lhs_ast) {
    my $assignment_support = $self->{flattened_dt}{enable_graph_assignment_support};
    return unless $assignment_support && $assignment_support->can('assignment_target_aggregate_contract');
    return $assignment_support->assignment_target_aggregate_contract($lhs, $lhs_ast);
}

sub _validate_named_expression ($self, $label, $expression, $inventory, $violations) {
    my $ctx = $self->{flattened_dt};
    return unless defined($expression) && $expression ne '';
    return unless $ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression');

    my $parsed_ast = eval { $ctx->{expr_namer}->parse_expression($expression) };
    return unless $parsed_ast && (blessed($parsed_ast) || ref($parsed_ast) eq 'HASH');

    $self->_validate_named_ast($label, $parsed_ast, $inventory, $violations);
}

sub _validate_named_ast ($self, $label, $ast, $inventory, $violations) {
    return unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    my @operand_names;
    my %seen_node_ids;
    my %seen_operand_names;
    $self->_collect_signal_operand_names($ast, \@operand_names, \%seen_node_ids, \%seen_operand_names);

    for my $signal_name (@operand_names) {
        next if $inventory->{top_level_signals}{$signal_name};
        next if $inventory->{localparam_names}{$signal_name};

        unless ($inventory->{declared_internal_signals}{$signal_name}) {
            push @$violations,
                "$label references undeclared internal operand '$signal_name'";
            next;
        }

        unless ($inventory->{assigned_internal_signals}{$signal_name}) {
            push @$violations,
                "$label references internal operand '$signal_name' that is declared but not backed by any internal assignment";
        }
    }
}

sub _collect_signal_operand_names ($self, $ast, $signal_names, $seen_node_ids, $seen_signal_names) {
    my $ctx = $self->{flattened_dt};
    return unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    my $node_id = refaddr($ast);
    $node_id = sprintf('%p', $ast) unless defined $node_id;
    return if $seen_node_ids->{$node_id}++;

    if (ref($ast) eq 'HASH' && !blessed($ast)) {
        if (($ast->{type} || '') eq 'signal') {
            my $signal_name = $ast->{name};
            if (defined($signal_name) && $signal_name ne '' && !$seen_signal_names->{$signal_name}++) {
                push @$signal_names, $signal_name;
            }
        }

        for my $key (qw(left right operand condition true_expr false_expr index expression)) {
            my $child = $ast->{$key};
            next unless $child && (blessed($child) || ref($child) eq 'HASH');
            $self->_collect_signal_operand_names($child, $signal_names, $seen_node_ids, $seen_signal_names);
        }

        for my $key (qw(operands children arguments expressions parts)) {
            my $children = $ast->{$key};
            next unless ref($children) eq 'ARRAY';
            for my $child (@$children) {
                next unless $child && (blessed($child) || ref($child) eq 'HASH');
                $self->_collect_signal_operand_names($child, $signal_names, $seen_node_ids, $seen_signal_names);
            }
        }

        return;
    }

    my $signal_name;
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
    } elsif ($ast->isa('FSM::AST::SignalRef')
        || $ast->isa('FSM::CoreAST::SignalRef')
        || $ast->isa('FSM::AST::IndexedRef')
        || $ast->isa('FSM::CoreAST::IndexedRef')
        || $ast->isa('FSM::CoreAST::AggregateRef'))
    {
        $signal_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
    }

    if (defined($signal_name) && $signal_name ne '' && !$seen_signal_names->{$signal_name}++) {
        push @$signal_names, $signal_name;
    }

    for my $accessor (qw(left right operand condition true_expr false_expr index expression)) {
        next unless $ast->can($accessor);
        my $child = eval { $ast->$accessor() };
        next unless $child && (blessed($child) || ref($child) eq 'HASH');
        $self->_collect_signal_operand_names($child, $signal_names, $seen_node_ids, $seen_signal_names);
    }

    for my $accessor (qw(operands children arguments expressions parts)) {
        next unless $ast->can($accessor);
        my $children = eval { $ast->$accessor() };
        next unless ref($children) eq 'ARRAY';
        for my $child (@$children) {
            next unless $child && (blessed($child) || ref($child) eq 'HASH');
            $self->_collect_signal_operand_names($child, $signal_names, $seen_node_ids, $seen_signal_names);
        }
    }
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one operand-contract validation owner bound to a specific direct
backend context.

=head2 validate_pre_generation_operand_contract

Validates that AST operands referenced by the prepared direct-backend
generation flow are either top-level signals or backed by declared and
assigned internal generation inventory before emission begins.

=head2 build_operand_contract_inventory

Builds the normalized signal ownership inventory used by the pre-emission
operand validator.

=cut
