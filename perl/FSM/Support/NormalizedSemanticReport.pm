package FSM::Support::NormalizedSemanticReport;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::CheckDiagnostics qw(build_check_failure_report build_check_success_report);
use FSM::Support::CompositionReportContract qw(sanitize_composition_report);
use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot);
use FSM::Support::SerializableDiagnosticSummary qw(build_serializable_diagnostic_summary);
use FSM::Support::SerializableGenerationResultSnapshot qw(build_serializable_generation_result_snapshot);

our @EXPORT_OK = qw(
    build_normalized_semantic_failure_report
    build_normalized_semantic_success_report
);

sub build_normalized_semantic_success_report {
    my (%args) = @_;

    my $result = $args{result} || {};
    my $module_info = $args{module_info} || $result->{module_info} || {};
    my $check_report = build_check_success_report(
        input => $args{input},
        source_file => $args{source_file},
        target_language => $args{target_language},
        strict_mode => $args{strict_mode},
        module_info => $module_info,
    );

    return {
        normalized_semantic_schema_version => 1,
        producer => _producer_contract(),
        command => _command_contract(%args),
        source => _source_contract(%args),
        success => JSON::PP::true,
        diagnostics => [],
        diagnostic_summary => build_serializable_diagnostic_summary(
            report => {
                success => JSON::PP::true,
                diagnostics => [],
            },
        ),
        support_accounting => $check_report->{support_accounting} || _unmatched_support_accounting(),
        semantic => _semantic_contract(
            result => $result,
            module_info => $module_info,
            target_language => $args{target_language},
        ),
        generation_result_snapshot => build_serializable_generation_result_snapshot(result => $result),
        generated_output => {
            emitted => JSON::PP::false,
        },
    };
}

sub build_normalized_semantic_failure_report {
    my (%args) = @_;

    my $check_report = build_check_failure_report(
        input => $args{input},
        source_file => $args{source_file},
        target_language => $args{target_language},
        strict_mode => $args{strict_mode},
        message => $args{message},
        error => $args{error},
    );
    my $diagnostics = $check_report->{diagnostics} || [];
    my $support_accounting = _unmatched_support_accounting();
    if (@$diagnostics && ref($diagnostics->[0]) eq 'HASH'
        && ref($diagnostics->[0]{support_accounting}) eq 'HASH') {
        $support_accounting = $diagnostics->[0]{support_accounting};
    }

    return {
        normalized_semantic_schema_version => 1,
        producer => _producer_contract(),
        command => _command_contract(%args),
        source => _source_contract(%args),
        success => JSON::PP::false,
        diagnostics => $diagnostics,
        diagnostic_summary => build_serializable_diagnostic_summary(
            report => {
                success => JSON::PP::false,
                diagnostics => $diagnostics,
            },
        ),
        support_accounting => $support_accounting,
        generated_output => {
            emitted => JSON::PP::false,
        },
    };
}

sub _producer_contract {
    return {
        name => 'FSMGen',
        report_source => 'FSM::Support::NormalizedSemanticReport',
        semantic_layers => [qw(intent_hir lowered_rtl_ir structural_rtl_ir)],
    };
}

sub _command_contract {
    my (%args) = @_;

    return {
        mode => 'semantic_export',
        json => JSON::PP::true,
        strict_mode => $args{strict_mode} ? JSON::PP::true : JSON::PP::false,
        target_language => $args{target_language} || 'systemverilog',
    };
}

sub _source_contract {
    my (%args) = @_;

    return {
        input => $args{input},
        resolved_path => $args{source_file},
    };
}

sub _semantic_contract {
    my (%args) = @_;

    my $result = $args{result} || {};
    my $module_info = $args{module_info} || {};
    my $intent_hir = _public_value($result->{intent_hir} || $module_info->{intent_hir} || {});
    my $lowered_rtl_ir = _public_value($result->{lowered_rtl_ir} || $module_info->{lowered_rtl_ir} || {});
    my $structural_rtl_ir = _public_value($result->{structural_rtl_ir} || $module_info->{structural_rtl_ir} || {});
    my $signal_analysis = _public_value($module_info->{signal_analysis} || $intent_hir->{signal_analysis} || {});
    my $system_contract = _public_value($module_info->{system_contract} || $intent_hir->{system_contract} || {});
    my $explicit_system_contract = _public_value(
        exists $module_info->{explicit_system_contract}
            ? $module_info->{explicit_system_contract}
            : $intent_hir->{explicit_system_contract}
    );
    my $symbol_contract = _public_value($module_info->{symbol_contract} || $intent_hir->{symbol_contract});
    my $protocol_intent_bundle = _public_value(
        exists $result->{protocol_intent_bundle}
            ? $result->{protocol_intent_bundle}
            : $module_info->{protocol_intent_bundle}
    );

    my $module = _module_contract(
        module_info => $module_info,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => $args{target_language},
    );
    my $composition = _composition_contract(
        composition_plan => $result->{composition_plan},
        composition_report => $result->{composition_report} || $module_info->{composition_provenance},
        module_info => $module_info,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
    );

    my %semantic = (
        module => $module,
        system_contract => $system_contract || {},
        explicit_system_contract => $explicit_system_contract,
        signal_analysis => $signal_analysis || {},
        forward_ir => {
            intent_hir => $intent_hir || {},
            lowered_rtl_ir => $lowered_rtl_ir || {},
            structural_rtl_ir => $structural_rtl_ir || {},
        },
    );

    $semantic{symbol_contract} = $symbol_contract
        if defined $symbol_contract;
    $semantic{composition} = $composition
        if defined $composition;
    $semantic{protocol_intent_bundle} = $protocol_intent_bundle
        if defined $protocol_intent_bundle;

    return \%semantic;
}

sub _module_contract {
    my (%args) = @_;

    my $module_info = $args{module_info} || {};
    my $intent_hir = $args{intent_hir} || {};
    my $lowered_rtl_ir = $args{lowered_rtl_ir} || {};
    my $structural_rtl_ir = $args{structural_rtl_ir} || {};

    my %module = (
        name => _first_defined(
            $module_info->{module_name},
            $intent_hir->{module_name},
            $structural_rtl_ir->{module_name},
        ),
        source_root_kind => _first_defined(
            $module_info->{source_root_kind},
            $intent_hir->{source_root_kind},
            $structural_rtl_ir->{source_root_kind},
        ),
        target_language => _first_defined(
            $args{target_language},
            $lowered_rtl_ir->{target_language},
            $structural_rtl_ir->{target_language},
            'systemverilog',
        ),
        state_count => _first_defined($module_info->{state_count}, $intent_hir->{state_count}, 0),
        regular_state_count => _first_defined(
            $module_info->{regular_state_count},
            $intent_hir->{regular_state_count},
            0,
        ),
        regular_state_names => _array_value($module_info->{regular_state_names}, $intent_hir->{regular_state_names}),
        standalone_dt_count => _first_defined(
            $module_info->{standalone_dt_count},
            $intent_hir->{standalone_dt_count},
            0,
        ),
        standalone_dt_names => _array_value($module_info->{standalone_dt_names}, $intent_hir->{standalone_dt_names}),
        signal_count => _first_defined($module_info->{signal_count}, $intent_hir->{signal_count}, 0),
        signal_names => _array_value($module_info->{signal_names}, $intent_hir->{signal_names}),
        parameter_count => _first_defined($module_info->{parameter_count}, $intent_hir->{parameter_count}, 0),
        parameter_names => _array_value($module_info->{parameter_names}, $intent_hir->{parameter_names}),
        requires_implicit_system_ports => (
            _first_defined(
                $module_info->{requires_implicit_system_ports},
                $intent_hir->{requires_implicit_system_ports},
                0,
            ) ? JSON::PP::true : JSON::PP::false
        ),
    );

    for my $field (qw(
        output_drive_family_count
        standalone_dt_multi_drive_target_count
        composition_child_count
        composition_net_count
        composition_resolved_link_count
        composition_generated_child_count
        composition_generated_fsm_child_count
        composition_generated_dt_child_count
        composition_standalone_dt_child_count
        composition_standalone_dt_block_count
        composition_standalone_dt_multi_drive_target_count
        composition_shared_datapath_candidate_count
    )) {
        $module{$field} = $module_info->{$field}
            if exists $module_info->{$field};
    }

    return \%module;
}

sub _composition_contract {
    my (%args) = @_;

    my $module_info = $args{module_info} || {};
    my $intent_hir = $args{intent_hir} || {};
    my $lowered_rtl_ir = $args{lowered_rtl_ir} || {};
    my $structural_rtl_ir = $args{structural_rtl_ir} || {};
    my $composition_report = sanitize_composition_report($args{composition_report});
    my $composition_plan_snapshot = build_serializable_composition_plan_snapshot(
        composition_plan => $args{composition_plan},
    );
    my $is_composition = (
        exists $module_info->{composition_child_count}
        || exists $intent_hir->{composition_child_count}
        || (($module_info->{source_root_kind} || $intent_hir->{source_root_kind} || '') eq 'top')
    );
    return undef unless $is_composition;
    my $child_count = _first_defined(
        $module_info->{composition_child_count},
        $intent_hir->{composition_child_count},
        $structural_rtl_ir->{instance_count},
    );

    return {
        lane => _first_defined($module_info->{composition_lane}, $intent_hir->{composition_lane}),
        child_count => _first_defined($child_count, 0),
        children => _public_value($module_info->{composition_children} || $intent_hir->{composition_children} || []),
        net_count => _first_defined(
            $module_info->{composition_net_count},
            $structural_rtl_ir->{net_count},
            0,
        ),
        resolved_link_count => _first_defined(
            $module_info->{composition_resolved_link_count},
            $structural_rtl_ir->{resolved_link_count},
            0,
        ),
        generated_child_count => _first_defined(
            $module_info->{composition_generated_child_count},
            $intent_hir->{composition_generated_child_count},
            0,
        ),
        generated_children => _public_value(
            $module_info->{composition_generated_children}
                || $intent_hir->{composition_generated_children}
                || []
        ),
        standalone_dt_child_count => _first_defined(
            $module_info->{composition_standalone_dt_child_count},
            $intent_hir->{composition_standalone_dt_child_count},
            0,
        ),
        standalone_dt_children => _public_value(
            $module_info->{composition_standalone_dt_children}
                || $intent_hir->{composition_standalone_dt_children}
                || []
        ),
        shared_datapath_candidate_count => _first_defined(
            $module_info->{composition_shared_datapath_candidate_count},
            $lowered_rtl_ir->{composition_shared_datapath_candidate_count},
            0,
        ),
        shared_datapath_candidates => _public_value(
            $module_info->{composition_shared_datapath_candidates}
                || $lowered_rtl_ir->{composition_shared_datapath_candidates}
                || []
        ),
        plan_snapshot => $composition_plan_snapshot,
        (
            $composition_report
                ? (provenance_report => $composition_report)
                : ()
        ),
    };
}

sub _array_value {
    for my $candidate (@_) {
        next unless ref($candidate) eq 'ARRAY';
        return _public_value($candidate) || [];
    }
    return [];
}

sub _first_defined {
    for my $value (@_) {
        return $value if defined $value;
    }
    return undef;
}

sub _unmatched_support_accounting {
    return {
        matched => JSON::PP::false,
    };
}

sub _public_value {
    my ($value) = @_;
    my ($ok, $public_value) = _json_ready_value($value);
    return $ok ? $public_value : undef;
}

sub _json_ready_value {
    my ($value) = @_;

    return (1, undef) unless defined $value;
    return (1, $value) unless ref($value);

    if (ref($value) eq 'HASH') {
        my %public;
        for my $key (sort keys %$value) {
            my ($ok, $child) = _json_ready_value($value->{$key});
            next unless $ok;
            $public{$key} = $child;
        }
        return (1, \%public);
    }

    if (ref($value) eq 'ARRAY') {
        my @public;
        for my $item (@$value) {
            my ($ok, $child) = _json_ready_value($item);
            push @public, $child if $ok;
        }
        return (1, \@public);
    }

    # Public semantic JSON deliberately does not leak live CoreAST/Signal/etc.
    # objects. Their scalar metadata is exported through explicit projections.
    return (0, undef);
}

1;
