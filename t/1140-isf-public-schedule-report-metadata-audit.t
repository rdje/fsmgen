#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_dt_ordering_policy
    isf_public_interface_schedule_report_compile_issue_keys
    isf_public_interface_schedule_report_compile_issue_proof_status_values
    isf_public_interface_schedule_report_compile_issue_severity_values
    isf_public_interface_schedule_report_compile_issue_source_keys
    isf_public_interface_schedule_report_compile_issues_success_shape
    isf_public_interface_schedule_report_clock_domain_child_instance_keys
    isf_public_interface_schedule_report_clock_domain_crossing_endpoint_keys
    isf_public_interface_schedule_report_clock_domain_keys
    isf_public_interface_schedule_report_crossing_keys
    isf_public_interface_schedule_report_bank_access_keys
    isf_public_interface_schedule_report_bank_access_kind_values
    isf_public_interface_schedule_report_bank_access_policy_values
    isf_public_interface_schedule_report_dt_keys
    isf_public_interface_schedule_report_fanin_group_kind_values
    isf_public_interface_schedule_report_fanin_group_optional_keys
    isf_public_interface_schedule_report_fanin_group_required_keys
    isf_public_interface_schedule_report_priority_resolution_keys
    isf_public_interface_schedule_report_resource_arbitration_keys
    isf_public_interface_schedule_report_generated_composition_binding_keys
    isf_public_interface_schedule_report_generated_composition_child_keys
    isf_public_interface_schedule_report_generated_composition_child_parameter_keys
    isf_public_interface_schedule_report_generated_composition_drive_handoff_keys
    isf_public_interface_schedule_report_generated_composition_instance_keys
    isf_public_interface_schedule_report_generated_composition_kind_values
    isf_public_interface_schedule_report_generated_composition_link_keys
    isf_public_interface_schedule_report_generated_composition_parent_keys
    isf_public_interface_schedule_report_generated_composition_payload_keys
    isf_public_interface_schedule_report_generated_composition_required_keys
    isf_public_interface_schedule_report_library_use_binding_keys
    isf_public_interface_schedule_report_library_use_keys
    isf_public_interface_schedule_report_library_use_parameter_keys
    isf_public_interface_schedule_report_multi_file_scope
    isf_public_interface_schedule_report_actor_network_generated_top_child_keys
    isf_public_interface_schedule_report_actor_network_generated_top_multi_child_keys
    isf_public_interface_schedule_report_actor_phase_keys
    isf_public_interface_schedule_report_actor_stage_keys
    isf_public_interface_schedule_report_actor_param_keys
    isf_public_interface_schedule_report_actor_constant_keys
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_reset_keys
    isf_public_interface_schedule_report_storage_optional_keys
    isf_public_interface_schedule_report_storage_required_keys
    isf_public_interface_schedule_report_storage_role_values
    isf_public_interface_schedule_report_temporal_contract_assertion_projection_values
    isf_public_interface_schedule_report_temporal_contract_keys
    isf_public_interface_schedule_report_temporal_contract_kind_values
    isf_public_interface_schedule_report_temporal_contract_overlap_policy_values
    isf_public_interface_schedule_report_temporal_contract_reset_policy_shape
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_transaction_port_binding_keys
    isf_public_interface_schedule_report_transaction_port_binding_actor_endpoint_kind_values
    isf_public_interface_schedule_report_transaction_port_binding_site_kind_values
    isf_public_interface_schedule_report_transaction_loop_keys
    isf_public_interface_schedule_report_transaction_wait_count_kind_values
    isf_public_interface_schedule_report_transaction_wait_keys
    isf_public_interface_schedule_report_transaction_stage_keys
    isf_public_interface_schedule_report_transaction_stage_kind_values
    isf_public_interface_schedule_report_transaction_keys
);

subtest 'direct ISF schedule-report metadata is exact and unique' => sub {
    assert_schedule_report_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report metadata is exact and unique' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_schedule_report_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_schedule_report_metadata {
    my ($contract, $label) = @_;

    my @list_checks = (
        [
            schedule_report_top_level_keys =>
                isf_public_interface_schedule_report_top_level_keys(),
        ],
        [
            schedule_report_reset_keys =>
                isf_public_interface_schedule_report_reset_keys(),
        ],
        [
            schedule_report_actor_phase_keys =>
                isf_public_interface_schedule_report_actor_phase_keys(),
        ],
        [
            schedule_report_actor_stage_keys =>
                isf_public_interface_schedule_report_actor_stage_keys(),
        ],
        [
            schedule_report_actor_network_generated_top_child_keys =>
                isf_public_interface_schedule_report_actor_network_generated_top_child_keys(),
        ],
        [
            schedule_report_actor_network_generated_top_multi_child_keys =>
                isf_public_interface_schedule_report_actor_network_generated_top_multi_child_keys(),
        ],
        [
            schedule_report_actor_param_keys =>
                isf_public_interface_schedule_report_actor_param_keys(),
        ],
        [
            schedule_report_actor_constant_keys =>
                isf_public_interface_schedule_report_actor_constant_keys(),
        ],
        [
            schedule_report_clock_domain_keys =>
                isf_public_interface_schedule_report_clock_domain_keys(),
        ],
        [
            schedule_report_clock_domain_child_instance_keys =>
                isf_public_interface_schedule_report_clock_domain_child_instance_keys(),
        ],
        [
            schedule_report_clock_domain_crossing_endpoint_keys =>
                isf_public_interface_schedule_report_clock_domain_crossing_endpoint_keys(),
        ],
        [
            schedule_report_crossing_keys =>
                isf_public_interface_schedule_report_crossing_keys(),
        ],
        [
            schedule_report_storage_required_keys =>
                isf_public_interface_schedule_report_storage_required_keys(),
        ],
        [
            schedule_report_storage_optional_keys =>
                isf_public_interface_schedule_report_storage_optional_keys(),
        ],
        [
            schedule_report_transaction_keys =>
                isf_public_interface_schedule_report_transaction_keys(),
        ],
        [
            schedule_report_transaction_stage_keys =>
                isf_public_interface_schedule_report_transaction_stage_keys(),
        ],
        [
            schedule_report_temporal_contract_keys =>
                isf_public_interface_schedule_report_temporal_contract_keys(),
        ],
        [
            schedule_report_dt_keys =>
                isf_public_interface_schedule_report_dt_keys(),
        ],
        [
            schedule_report_compile_issue_keys =>
                isf_public_interface_schedule_report_compile_issue_keys(),
        ],
        [
            schedule_report_compile_issue_source_keys =>
                isf_public_interface_schedule_report_compile_issue_source_keys(),
        ],
        [
            schedule_report_bank_access_keys =>
                isf_public_interface_schedule_report_bank_access_keys(),
        ],
        [
            schedule_report_transaction_port_binding_keys =>
                isf_public_interface_schedule_report_transaction_port_binding_keys(),
        ],
        [
            schedule_report_transaction_port_binding_actor_endpoint_kind_values =>
                isf_public_interface_schedule_report_transaction_port_binding_actor_endpoint_kind_values(),
        ],
        [
            schedule_report_transaction_loop_keys =>
                isf_public_interface_schedule_report_transaction_loop_keys(),
        ],
        [
            schedule_report_transaction_wait_keys =>
                isf_public_interface_schedule_report_transaction_wait_keys(),
        ],
        [
            schedule_report_transaction_wait_count_kind_values =>
                isf_public_interface_schedule_report_transaction_wait_count_kind_values(),
        ],
        [
            schedule_report_fanin_group_required_keys =>
                isf_public_interface_schedule_report_fanin_group_required_keys(),
        ],
        [
            schedule_report_fanin_group_optional_keys =>
                isf_public_interface_schedule_report_fanin_group_optional_keys(),
        ],
        [
            schedule_report_priority_resolution_keys =>
                isf_public_interface_schedule_report_priority_resolution_keys(),
        ],
        [
            schedule_report_resource_arbitration_keys =>
                isf_public_interface_schedule_report_resource_arbitration_keys(),
        ],
        [
            schedule_report_generated_composition_required_keys =>
                isf_public_interface_schedule_report_generated_composition_required_keys(),
        ],
        [
            schedule_report_generated_composition_parent_keys =>
                isf_public_interface_schedule_report_generated_composition_parent_keys(),
        ],
        [
            schedule_report_generated_composition_child_keys =>
                isf_public_interface_schedule_report_generated_composition_child_keys(),
        ],
        [
            schedule_report_generated_composition_child_parameter_keys =>
                isf_public_interface_schedule_report_generated_composition_child_parameter_keys(),
        ],
        [
            schedule_report_generated_composition_instance_keys =>
                isf_public_interface_schedule_report_generated_composition_instance_keys(),
        ],
        [
            schedule_report_generated_composition_link_keys =>
                isf_public_interface_schedule_report_generated_composition_link_keys(),
        ],
        [
            schedule_report_generated_composition_binding_keys =>
                isf_public_interface_schedule_report_generated_composition_binding_keys(),
        ],
        [
            schedule_report_generated_composition_drive_handoff_keys =>
                isf_public_interface_schedule_report_generated_composition_drive_handoff_keys(),
        ],
        [
            schedule_report_generated_composition_payload_keys =>
                isf_public_interface_schedule_report_generated_composition_payload_keys(),
        ],
        [
            schedule_report_library_use_keys =>
                isf_public_interface_schedule_report_library_use_keys(),
        ],
        [
            schedule_report_library_use_parameter_keys =>
                isf_public_interface_schedule_report_library_use_parameter_keys(),
        ],
        [
            schedule_report_library_use_binding_keys =>
                isf_public_interface_schedule_report_library_use_binding_keys(),
        ],
    );

    for my $check (@list_checks) {
        my ($field, $expected) = @$check;
        is_deeply($contract->{$field}, $expected, "$label $field is exact");
        assert_unique_scalar_list($contract->{$field}, "$label $field");
    }

    is_deeply(
        $contract->{schedule_report_presence_key_family_map},
        isf_public_interface_schedule_report_presence_key_family_map(),
        "$label schedule_report_presence_key_family_map is exact",
    );
    is(
        $contract->{schedule_report_compile_issues_success_shape},
        isf_public_interface_schedule_report_compile_issues_success_shape(),
        "$label compile_issues success shape is exact",
    );
    is_deeply(
        $contract->{schedule_report_compile_issue_severity_values},
        isf_public_interface_schedule_report_compile_issue_severity_values(),
        "$label compile issue severity values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_compile_issue_severity_values},
        "$label compile issue severity values",
    );
    is_deeply(
        $contract->{schedule_report_compile_issue_proof_status_values},
        isf_public_interface_schedule_report_compile_issue_proof_status_values(),
        "$label compile issue proof status values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_compile_issue_proof_status_values},
        "$label compile issue proof status values",
    );
    is_deeply(
        $contract->{schedule_report_bank_access_kind_values},
        isf_public_interface_schedule_report_bank_access_kind_values(),
        "$label bank access kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_bank_access_kind_values},
        "$label bank access kind values",
    );
    is_deeply(
        $contract->{schedule_report_bank_access_policy_values},
        isf_public_interface_schedule_report_bank_access_policy_values(),
        "$label bank access policy values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_bank_access_policy_values},
        "$label bank access policy values",
    );
    is_deeply(
        $contract->{schedule_report_transaction_port_binding_actor_endpoint_kind_values},
        isf_public_interface_schedule_report_transaction_port_binding_actor_endpoint_kind_values(),
        "$label transaction port binding actor endpoint kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_transaction_port_binding_actor_endpoint_kind_values},
        "$label transaction port binding actor endpoint kind values",
    );
    is_deeply(
        $contract->{schedule_report_transaction_port_binding_site_kind_values},
        isf_public_interface_schedule_report_transaction_port_binding_site_kind_values(),
        "$label transaction port binding site kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_transaction_port_binding_site_kind_values},
        "$label transaction port binding site kind values",
    );
    is_deeply(
        $contract->{schedule_report_fanin_group_kind_values},
        isf_public_interface_schedule_report_fanin_group_kind_values(),
        "$label fan-in group kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_fanin_group_kind_values},
        "$label fan-in group kind values",
    );
    is_deeply(
        $contract->{schedule_report_storage_role_values},
        isf_public_interface_schedule_report_storage_role_values(),
        "$label storage role values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_storage_role_values},
        "$label storage role values",
    );
    is_deeply(
        $contract->{schedule_report_generated_composition_kind_values},
        isf_public_interface_schedule_report_generated_composition_kind_values(),
        "$label generated composition kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_generated_composition_kind_values},
        "$label generated composition kind values",
    );
    is_deeply(
        $contract->{schedule_report_transaction_stage_kind_values},
        isf_public_interface_schedule_report_transaction_stage_kind_values(),
        "$label transaction stage kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_transaction_stage_kind_values},
        "$label transaction stage kind values",
    );
    is_deeply(
        $contract->{schedule_report_temporal_contract_kind_values},
        isf_public_interface_schedule_report_temporal_contract_kind_values(),
        "$label temporal contract kind values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_temporal_contract_kind_values},
        "$label temporal contract kind values",
    );
    is_deeply(
        $contract->{schedule_report_temporal_contract_overlap_policy_values},
        isf_public_interface_schedule_report_temporal_contract_overlap_policy_values(),
        "$label temporal contract overlap policy values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_temporal_contract_overlap_policy_values},
        "$label temporal contract overlap policy values",
    );
    is_deeply(
        $contract->{schedule_report_temporal_contract_assertion_projection_values},
        isf_public_interface_schedule_report_temporal_contract_assertion_projection_values(),
        "$label temporal contract assertion projection values are exact",
    );
    assert_unique_scalar_list(
        $contract->{schedule_report_temporal_contract_assertion_projection_values},
        "$label temporal contract assertion projection values",
    );
    is(
        $contract->{schedule_report_temporal_contract_reset_policy_shape},
        isf_public_interface_schedule_report_temporal_contract_reset_policy_shape(),
        "$label temporal contract reset policy shape is exact",
    );
    is(
        $contract->{schedule_report_multi_file_scope},
        isf_public_interface_schedule_report_multi_file_scope(),
        "$label multi-file schedule-report scope is exact",
    );
    is(
        $contract->{schedule_report_dt_ordering},
        isf_public_interface_dt_ordering_policy(),
        "$label schedule report DT ordering policy is exact",
    );
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
    }
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
