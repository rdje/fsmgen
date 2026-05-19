#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $contract = build_isf_public_interface_contract();
my %matrix_coverage;

subtest 'schedule-report golden matrix owns advertised branches' => sub {
    for my $case (golden_matrix_cases()) {
        my ($in_process_report, $cli_report) = reports_for_case($case);

        is_deeply(
            $cli_report,
            $in_process_report,
            "$case->{name} CLI report matches in-process report",
        );
        assert_branch_present(
            schedule_report_top_level_keys => $in_process_report,
            "$case->{name} top-level shell",
        );

        for my $branch (@{$case->{covers}}) {
            assert_branch_present($branch, $in_process_report, $case->{name});
            $matrix_coverage{$branch} = $case->{name};
        }
    }
};

subtest 'golden matrix has no missing advertised branch owner' => sub {
    my @missing = grep { !exists $matrix_coverage{$_} } required_matrix_branches();
    is_deeply(\@missing, [], 'all advertised schedule-report branches have a matrix owner');
};

done_testing();

sub golden_matrix_cases {
    return (
        {
            name => 'apb_requester',
            fixture => 'isf/apb_requester.isf',
            covers => [
                qw(
                  schedule_report_source_shape
                  schedule_report_top_level_keys
                  schedule_report_scheduled_fsm_shape
                  schedule_report_clock_shape
                  schedule_report_watchdog_shape
                  schedule_report_interface_count_shape
                  schedule_report_state_count_shape
                  schedule_report_presence_key_family_map
                  schedule_report_reset_shape
                  schedule_report_reset_keys
                  schedule_report_reset_kind_values
                  schedule_report_reset_polarity_values
                  schedule_report_storage_required_keys
                  schedule_report_storage_kind_values
                  schedule_report_storage_role_values
                  schedule_report_storage_width_shape
                  schedule_report_transaction_keys
                  schedule_report_transaction_states_shape
                  schedule_report_transaction_count_shape
                  schedule_report_transaction_ordering
                  schedule_report_dt_keys
                  schedule_report_dt_kind_values
                  schedule_report_dt_assignments_shape
                  schedule_report_dt_ordering
                  schedule_report_compile_issues_success_shape
                )
            ],
        },
        {
            name => 'typed_storage',
            filename => 'typed_storage_report.isf',
            source => typed_storage_source(),
            covers => ['schedule_report_storage_optional_keys'],
        },
        {
            name => 'compatible_fanin',
            filename => 'compatible_fanin.isf',
            source => compatible_fanin_source(),
            covers => [
                qw(
                  schedule_report_fanin_group_required_keys
                  schedule_report_fanin_group_optional_keys
                  schedule_report_fanin_group_kind_values
                )
            ],
        },
        {
            name => 'compile_issue',
            filename => 'rule_drive_unproven.isf',
            source => compile_issue_source(),
            covers => [
                qw(
                  schedule_report_compile_issue_keys
                  schedule_report_compile_issue_source_keys
                  schedule_report_compile_issue_severity_values
                  schedule_report_compile_issue_proof_status_values
                )
            ],
        },
        {
            name => 'arbitration',
            filename => 'arbitration_report.isf',
            source => arbitration_source(),
            covers => [
                qw(
                  schedule_report_priority_resolution_keys
                  schedule_report_resource_arbitration_keys
                )
            ],
        },
        {
            name => 'generated_composition',
            filename => 'generated_composition_report.isf',
            source => generated_composition_source(),
            covers => [
                qw(
                  schedule_report_generated_composition_required_keys
                  schedule_report_generated_composition_kind_values
                  schedule_report_generated_composition_parent_keys
                  schedule_report_generated_composition_child_keys
                  schedule_report_generated_composition_child_parameter_keys
                  schedule_report_generated_composition_instance_keys
                  schedule_report_generated_composition_link_keys
                  schedule_report_generated_composition_binding_keys
                  schedule_report_generated_composition_drive_handoff_keys
                  schedule_report_generated_composition_payload_keys
                  schedule_report_multi_file_scope
                )
            ],
        },
        {
            name => 'library_use',
            fixture => 'isf/fifo_library_use.isf',
            covers => [
                qw(
                  schedule_report_library_use_keys
                  schedule_report_library_use_parameter_keys
                  schedule_report_library_use_binding_keys
                )
            ],
        },
        {
            name => 'clock_domain_child_instance',
            filename => 'clock_domain_partition.isf',
            source => clock_domain_partition_source(),
            covers => [
                qw(
                  schedule_report_clock_domain_keys
                  schedule_report_clock_domain_child_instance_keys
                )
            ],
        },
        {
            name => 'clock_domain_crossing',
            fixture => 'isf/clock_domain_event_crossing.isf',
            covers => [
                qw(
                  schedule_report_clock_domain_crossing_endpoint_keys
                  schedule_report_crossing_keys
                )
            ],
        },
        {
            name => 'actor_metadata',
            filename => 'actor_metadata_report.isf',
            source => actor_metadata_source(),
            covers => [
                qw(
                  schedule_report_actor_phase_keys
                  schedule_report_actor_stage_keys
                )
            ],
        },
        {
            name => 'actor_params',
            filename => 'actor_param_report.isf',
            source => actor_param_source(),
            covers => ['schedule_report_actor_param_keys'],
        },
        {
            name => 'wait_matrix',
            filename => 'wait_matrix.isf',
            source => wait_matrix_source(),
            covers => [
                qw(
                  schedule_report_actor_constant_keys
                  schedule_report_transaction_wait_keys
                  schedule_report_transaction_wait_count_kind_values
                )
            ],
        },
        {
            name => 'loop_matrix',
            filename => 'loop_matrix.isf',
            source => loop_matrix_source(),
            covers => ['schedule_report_transaction_loop_keys'],
        },
        {
            name => 'stage_contract',
            filename => 'stage_contract_report.isf',
            source => stage_contract_source(),
            covers => [
                qw(
                  schedule_report_transaction_stage_keys
                  schedule_report_transaction_stage_kind_values
                  schedule_report_temporal_contract_keys
                  schedule_report_temporal_contract_kind_values
                  schedule_report_temporal_contract_overlap_policy_values
                  schedule_report_temporal_contract_assertion_projection_values
                  schedule_report_temporal_contract_reset_policy_shape
                )
            ],
        },
        {
            name => 'bank_access',
            fixture => 'isf/fifo_data_path.isf',
            covers => [
                qw(
                  schedule_report_bank_access_keys
                  schedule_report_bank_access_kind_values
                  schedule_report_bank_access_policy_values
                )
            ],
        },
        {
            name => 'port_binding',
            filename => 'port_binding_report.isf',
            source => port_binding_source(),
            covers => [
                qw(
                  schedule_report_transaction_port_binding_keys
                  schedule_report_transaction_port_binding_site_kind_values
                )
            ],
        },
        {
            name => 'actor_network_static',
            filename => 'actor_network_static_report.isf',
            source => actor_network_static_source(),
            covers => [
                qw(
                  schedule_report_actor_network_keys
                  schedule_report_actor_network_instance_keys
                )
            ],
        },
        {
            name => 'actor_network_resolved_instance',
            filename => 'actor_network_resolved_instance_report.isf',
            source => actor_network_resolved_instance_source(),
            covers => [
                qw(
                  schedule_report_actor_network_resolved_instance_keys
                )
            ],
        },
        {
            name => 'actor_network_generated_top',
            fixture => 'isf/atl_resolved_child_pipeline.isf',
            covers => [
                qw(
                  schedule_report_actor_network_generated_top_keys
                )
            ],
        },
        {
            name => 'actor_network_generated_top_child',
            fixture => 'isf/atl_two_child_pipeline.isf',
            covers => [
                qw(
                  schedule_report_actor_network_generated_top_multi_child_keys
                  schedule_report_actor_network_generated_top_child_keys
                )
            ],
        },
        {
            name => 'actor_network_generated_top_child_data_route',
            fixture => 'isf/atl_two_child_data_pipeline.isf',
            covers => [
                qw(
                  schedule_report_actor_network_generated_top_multi_child_keys
                  schedule_report_actor_network_generated_top_child_keys
                  schedule_report_actor_network_data_movement_keys
                )
            ],
        },
        {
            name => 'actor_network_group',
            filename => 'actor_network_group_report.isf',
            source => actor_network_group_source(),
            covers => [
                qw(
                  schedule_report_actor_network_group_keys
                )
            ],
        },
        {
            name => 'actor_network_group_schedule',
            filename => 'actor_network_group_schedule_report.isf',
            source => actor_network_group_schedule_source(),
            covers => [
                qw(
                  schedule_report_actor_network_association_schedule_keys
                  schedule_report_actor_network_group_schedule_keys
                )
            ],
        },
        {
            name => 'actor_network_event_wait',
            filename => 'actor_network_event_wait_report.isf',
            source => actor_network_event_wait_source(),
            covers => [
                qw(
                  schedule_report_actor_network_event_wait_keys
                )
            ],
        },
        {
            name => 'actor_network_transaction_trigger',
            filename => 'actor_network_transaction_trigger_report.isf',
            source => actor_network_transaction_trigger_source(),
            covers => [
                qw(
                  schedule_report_actor_network_transaction_trigger_keys
                )
            ],
        },
        {
            name => 'actor_network_data_movement',
            filename => 'actor_network_data_movement_report.isf',
            source => actor_network_data_movement_source(),
            covers => [
                qw(
                  schedule_report_actor_network_data_movement_keys
                )
            ],
        },
    );
}

sub required_matrix_branches {
    my %required = map { $_ => 1 }
        grep { $_ ne 'schedule_report_full_schema_stable' }
        grep { /^schedule_report_/ }
        keys %$contract;

    return sort keys %required;
}

sub reports_for_case {
    my ($case) = @_;
    my $path;

    if ($case->{fixture}) {
        $path = repo_file($case->{fixture});
    }
    else {
        my $dir = tempdir(CLEANUP => 1);
        $path = File::Spec->catfile($dir, $case->{filename});
        write_file($path, $case->{source});
    }

    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my $cli_report = run_schedule_json($path, $case->{name});

    return ($in_process_report, $cli_report);
}

sub assert_branch_present {
    my ($branch, $report, $label) = @_;

    if ($branch eq 'schedule_report_top_level_keys') {
        is_deeply(
            sorted([keys %$report]),
            sorted($contract->{schedule_report_top_level_keys}),
            "$label exposes the advertised top-level keys",
        );
        return;
    }
    if ($branch eq 'schedule_report_presence_key_family_map') {
        my %families = %{$contract->{schedule_report_presence_key_family_map}};
        ok(keys(%families) > 0, "$label has a presence key-family map");
        return;
    }
    if ($branch eq 'schedule_report_source_shape') {
        ok_scalar($report->{source}, "$label source");
        return;
    }
    if ($branch eq 'schedule_report_scheduled_fsm_shape') {
        ok_scalar($report->{scheduled_fsm}, "$label scheduled_fsm");
        return;
    }
    if ($branch eq 'schedule_report_clock_shape') {
        ok_scalar($report->{clock}, "$label clock");
        return;
    }
    if ($branch eq 'schedule_report_watchdog_shape') {
        ok(exists $report->{watchdog}, "$label watchdog key exists");
        return;
    }
    if ($branch eq 'schedule_report_interface_count_shape') {
        ok_nonnegative_integer($report->{inputs}, "$label inputs count");
        ok_nonnegative_integer($report->{outputs}, "$label outputs count");
        ok_nonnegative_integer($report->{port_count}, "$label port_count");
        return;
    }
    if ($branch eq 'schedule_report_state_count_shape') {
        ok_nonnegative_integer($report->{state_count}, "$label state_count");
        return;
    }
    if ($branch eq 'schedule_report_reset_shape') {
        ok(ref($report->{reset}) eq 'HASH' || !defined($report->{reset}), "$label reset is hash or null");
        return;
    }
    if ($branch eq 'schedule_report_multi_file_scope') {
        ok(ref($report->{generated_composition}) eq 'HASH', "$label has a multi-file composition summary");
        return;
    }
    if ($branch eq 'schedule_report_compile_issues_success_shape') {
        is_deeply($report->{compile_issues}, [], "$label has the successful empty compile_issues shape");
        return;
    }
    if ($branch eq 'schedule_report_temporal_contract_reset_policy_shape') {
        my $contract_entry = first_entry($report->{temporal_contracts});
        ok(ref($contract_entry->{reset_policy}) eq 'HASH', "$label has temporal reset policy");
        return;
    }
    if ($branch eq 'schedule_report_dt_assignments_shape') {
        my $dt = first_entry($report->{dt_blocks});
        ok_nonnegative_integer($dt->{assignments}, "$label DT assignment count");
        return;
    }
    if ($branch eq 'schedule_report_dt_ordering') {
        my @names = map { $_->{name} } @{$report->{dt_blocks}};
        ok(@names, "$label has ordered DT block names");
        return;
    }
    if ($branch eq 'schedule_report_storage_width_shape') {
        my @widths = grep { defined $_ } map { $_->{width} } @{$report->{inferred_storage}};
        ok(@widths, "$label has width-bearing storage");
        ok_nonnegative_integer($_, "$label storage width $_") for @widths;
        return;
    }
    if ($branch eq 'schedule_report_transaction_states_shape') {
        my $transaction = first_entry($report->{transactions});
        ok(ref($transaction->{states}) eq 'ARRAY' && @{$transaction->{states}}, "$label transaction states array");
        return;
    }
    if ($branch eq 'schedule_report_transaction_count_shape') {
        my $transaction = first_entry($report->{transactions});
        ok_nonnegative_integer($transaction->{count}, "$label transaction count");
        return;
    }
    if ($branch eq 'schedule_report_transaction_ordering') {
        my @names = map { $_->{name} } @{$report->{transactions}};
        is_deeply(\@names, [sort @names], "$label transaction summaries are ordered");
        return;
    }

    my $handled =
        assert_key_branch($branch, $report, $label)
        || assert_value_branch($branch, $report, $label);
    ok($handled, "$label branch $branch is handled by the matrix audit");
}

sub assert_key_branch {
    my ($branch, $report, $label) = @_;

    my %array_branch = (
        schedule_report_actor_constant_keys => ['actor_constants'],
        schedule_report_actor_param_keys => ['actor_params'],
        schedule_report_actor_phase_keys => ['actor_phases'],
        schedule_report_actor_stage_keys => ['actor_stages'],
        schedule_report_bank_access_keys => ['bank_accesses'],
        schedule_report_clock_domain_keys => ['clock_domains'],
        schedule_report_compile_issue_keys => ['compile_issues'],
        schedule_report_crossing_keys => ['crossings'],
        schedule_report_dt_keys => ['dt_blocks'],
        schedule_report_library_use_keys => ['library_uses'],
        schedule_report_priority_resolution_keys => ['priority_resolutions'],
        schedule_report_resource_arbitration_keys => ['resource_arbitration'],
        schedule_report_temporal_contract_keys => ['temporal_contracts'],
        schedule_report_transaction_keys => ['transactions'],
        schedule_report_transaction_loop_keys => ['transaction_loops'],
        schedule_report_transaction_port_binding_keys => ['transaction_port_bindings'],
        schedule_report_transaction_stage_keys => ['transaction_stages'],
        schedule_report_transaction_wait_keys => ['transaction_waits'],
    );
    if (my $path = $array_branch{$branch}) {
        assert_entry_keys(first_entry($report->{$path->[0]}), $contract->{$branch}, "$label $branch");
        return 1;
    }

    if ($branch eq 'schedule_report_storage_required_keys') {
        my $entry = first_entry($report->{inferred_storage});
        for my $key (@{$contract->{$branch}}) {
            ok(exists $entry->{$key}, "$label storage entry has required key $key");
        }
        return 1;
    }
    if ($branch eq 'schedule_report_reset_keys') {
        assert_entry_keys($report->{reset}, $contract->{$branch}, "$label reset keys");
        return 1;
    }
    if ($branch eq 'schedule_report_storage_optional_keys') {
        my %optional = map { $_ => 0 } @{$contract->{$branch}};
        for my $entry (@{$report->{inferred_storage}}) {
            $optional{$_} = 1 for grep { exists $entry->{$_} } keys %optional;
        }
        is_deeply([sort grep { !$optional{$_} } keys %optional], [], "$label observes storage optional keys");
        return 1;
    }
    if ($branch eq 'schedule_report_fanin_group_required_keys') {
        my $entry = first_entry($report->{compatible_fanin_groups});
        for my $key (@{$contract->{$branch}}) {
            ok(exists $entry->{$key}, "$label fan-in group has required key $key");
        }
        return 1;
    }
    if ($branch eq 'schedule_report_fanin_group_optional_keys') {
        my %optional = map { $_ => 0 } @{$contract->{$branch}};
        for my $entry (@{$report->{compatible_fanin_groups}}) {
            $optional{$_} = 1 for grep { exists $entry->{$_} } keys %optional;
        }
        is_deeply([sort grep { !$optional{$_} } keys %optional], [], "$label observes fan-in optional keys");
        return 1;
    }
    if ($branch eq 'schedule_report_compile_issue_source_keys') {
        my $issue = first_entry($report->{compile_issues});
        assert_entry_keys(first_entry($issue->{sources}), $contract->{$branch}, "$label compile issue source keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_required_keys') {
        assert_entry_keys($report->{generated_composition}, $contract->{$branch}, "$label generated composition keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_keys') {
        assert_entry_keys($report->{actor_network}, $contract->{$branch}, "$label actor network keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_instance_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{instances}), $contract->{$branch}, "$label actor network instance keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_resolved_instance_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{instances}), $contract->{$branch}, "$label actor network resolved instance keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_group_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{groups}), $contract->{$branch}, "$label actor network group keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_generated_top_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{generated_tops}), $contract->{$branch}, "$label actor network generated top keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_generated_top_child_keys') {
        my $top = first_entry($report->{actor_network}{generated_tops});
        assert_entry_keys(first_entry($top->{children}), $contract->{$branch}, "$label actor network generated top child keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_generated_top_multi_child_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{generated_tops}), $contract->{$branch}, "$label actor network generated top multi-child keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_group_schedule_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{group_schedules}), $contract->{$branch}, "$label actor network group schedule keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_association_schedule_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{association_schedules}), $contract->{$branch}, "$label actor network association schedule keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_event_wait_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{event_waits}), $contract->{$branch}, "$label actor network event wait keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_data_movement_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{data_movements}), $contract->{$branch}, "$label actor network data movement keys");
        return 1;
    }
    if ($branch eq 'schedule_report_actor_network_transaction_trigger_keys') {
        assert_entry_keys(first_entry($report->{actor_network}{transaction_triggers}), $contract->{$branch}, "$label actor network transaction trigger keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_parent_keys') {
        assert_entry_keys($report->{generated_composition}{parent}, $contract->{$branch}, "$label composition parent keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_child_keys') {
        assert_entry_keys(first_entry($report->{generated_composition}{children}), $contract->{$branch}, "$label composition child keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_child_parameter_keys') {
        my $child = first_entry($report->{generated_composition}{children});
        assert_entry_keys(first_entry($child->{parameters}), $contract->{$branch}, "$label composition child parameter keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_instance_keys') {
        assert_entry_keys(first_entry($report->{generated_composition}{instances}), $contract->{$branch}, "$label composition instance keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_link_keys') {
        my $instance = first_entry($report->{generated_composition}{instances});
        assert_entry_keys($instance->{start}, $contract->{$branch}, "$label composition start link keys");
        assert_entry_keys($instance->{done}, $contract->{$branch}, "$label composition done link keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_binding_keys') {
        my $instance = first_entry($report->{generated_composition}{instances});
        assert_entry_keys(first_entry($instance->{parameter_bindings}), $contract->{$branch}, "$label composition binding keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_drive_handoff_keys') {
        my $instance = first_entry($report->{generated_composition}{instances});
        assert_entry_keys(first_entry($instance->{drive_handoffs}), $contract->{$branch}, "$label composition drive handoff keys");
        return 1;
    }
    if ($branch eq 'schedule_report_generated_composition_payload_keys') {
        my $instance = first_entry($report->{generated_composition}{instances});
        my $handoff = first_entry($instance->{drive_handoffs});
        assert_entry_keys(first_entry($handoff->{payloads}), $contract->{$branch}, "$label composition payload keys");
        return 1;
    }
    if ($branch eq 'schedule_report_library_use_parameter_keys') {
        my $use = first_entry($report->{library_uses});
        assert_entry_keys(first_entry($use->{parameters}), $contract->{$branch}, "$label library parameter keys");
        return 1;
    }
    if ($branch eq 'schedule_report_library_use_binding_keys') {
        my $use = first_entry($report->{library_uses});
        assert_entry_keys(first_entry($use->{bindings}), $contract->{$branch}, "$label library binding keys");
        return 1;
    }
    if ($branch eq 'schedule_report_clock_domain_child_instance_keys') {
        my $domain = first_entry_with_nonempty($report->{clock_domains}, 'child_instances');
        assert_entry_keys(first_entry($domain->{child_instances}), $contract->{$branch}, "$label clock-domain child instance keys");
        return 1;
    }
    if ($branch eq 'schedule_report_clock_domain_crossing_endpoint_keys') {
        my $domain = first_entry_with_nonempty($report->{clock_domains}, 'crossings');
        assert_entry_keys(first_entry($domain->{crossings}), $contract->{$branch}, "$label clock-domain crossing endpoint keys");
        return 1;
    }

    return 0;
}

sub assert_value_branch {
    my ($branch, $report, $label) = @_;

    my @values;
    if ($branch eq 'schedule_report_reset_kind_values') {
        @values = ($report->{reset}{kind});
    }
    elsif ($branch eq 'schedule_report_reset_polarity_values') {
        @values = ($report->{reset}{polarity});
    }
    elsif ($branch eq 'schedule_report_storage_kind_values') {
        @values = map { $_->{kind} } @{$report->{inferred_storage}};
    }
    elsif ($branch eq 'schedule_report_storage_role_values') {
        @values = grep { defined $_ } map { $_->{role} } @{$report->{inferred_storage}};
    }
    elsif ($branch eq 'schedule_report_transaction_wait_count_kind_values') {
        @values = map { $_->{count_kind} } @{$report->{transaction_waits}};
    }
    elsif ($branch eq 'schedule_report_transaction_stage_kind_values') {
        @values = map { $_->{kind} } @{$report->{transaction_stages}};
    }
    elsif ($branch eq 'schedule_report_temporal_contract_kind_values') {
        @values = map { $_->{kind} } @{$report->{temporal_contracts}};
    }
    elsif ($branch eq 'schedule_report_temporal_contract_overlap_policy_values') {
        @values = map { $_->{overlap_policy} } @{$report->{temporal_contracts}};
    }
    elsif ($branch eq 'schedule_report_temporal_contract_assertion_projection_values') {
        @values = map { $_->{assertion_projection} } @{$report->{temporal_contracts}};
    }
    elsif ($branch eq 'schedule_report_dt_kind_values') {
        @values = map { $_->{kind} } @{$report->{dt_blocks}};
    }
    elsif ($branch eq 'schedule_report_bank_access_kind_values') {
        @values = map { $_->{kind} } @{$report->{bank_accesses}};
    }
    elsif ($branch eq 'schedule_report_bank_access_policy_values') {
        @values = map { $_->{same_cycle_policy} } @{$report->{bank_accesses}};
    }
    elsif ($branch eq 'schedule_report_transaction_port_binding_site_kind_values') {
        @values = map { $_->{site_kind} } @{$report->{transaction_port_bindings}};
    }
    elsif ($branch eq 'schedule_report_compile_issue_severity_values') {
        @values = map { $_->{severity} } @{$report->{compile_issues}};
    }
    elsif ($branch eq 'schedule_report_compile_issue_proof_status_values') {
        @values = map { $_->{proof_status} } @{$report->{compile_issues}};
    }
    elsif ($branch eq 'schedule_report_fanin_group_kind_values') {
        @values = map { $_->{kind} } @{$report->{compatible_fanin_groups}};
    }
    elsif ($branch eq 'schedule_report_generated_composition_kind_values') {
        @values = ($report->{generated_composition}{kind});
    }
    else {
        return 0;
    }

    my %advertised = map { $_ => 1 } @{$contract->{$branch}};
    my @bad = grep { !defined($_) || !$advertised{$_} } @values;

    ok(@values, "$label observes at least one $branch value");
    is_deeply(\@bad, [], "$label observes only advertised $branch values");
    return 1;
}

sub assert_entry_keys {
    my ($entry, $expected_keys, $label) = @_;

    ok(ref($entry) eq 'HASH', "$label entry exists");
    return unless ref($entry) eq 'HASH';
    is_deeply(sorted([keys %$entry]), sorted($expected_keys), "$label are exact");
}

sub first_entry {
    my ($items) = @_;

    ok(ref($items) eq 'ARRAY' && @$items, 'matrix branch has a non-empty entry array');
    return {} unless ref($items) eq 'ARRAY' && @$items;
    return $items->[0];
}

sub first_entry_with_nonempty {
    my ($items, $field) = @_;

    for my $entry (@{$items || []}) {
        return $entry if ref($entry->{$field}) eq 'ARRAY' && @{$entry->{$field}};
    }
    fail("matrix branch has a clock-domain entry with non-empty $field");
    return {};
}

sub ok_scalar {
    my ($value, $label) = @_;
    ok(defined($value) && !ref($value) && length("$value"), "$label is a scalar");
}

sub ok_nonnegative_integer {
    my ($value, $label) = @_;
    ok(defined($value) && !ref($value) && "$value" =~ /\A[0-9]+\z/, "$label is a non-negative integer");
}

sub run_schedule_json {
    my ($path, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, "$label CLI schedule JSON succeeds");
    is(join('', @{$stderr_buf || []}), '', "$label CLI schedule JSON keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_file {
    my ($path, $content) = @_;

    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub repo_file {
    my ($path) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $path);
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub compatible_fanin_source {
    return <<'ISF';
(actor compatible_fanin
  (clock clk)
  (interface
    (input start)
    (input kick)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction work
    (on start)
    (complete done))
  (transaction parent
    (on kick)
    (do work)
    (complete done))
  (rule r0 a
    (valid 1)
    (trigger work))
  (rule r1 b
    (valid 1)
    (trigger work)))
ISF
}

sub compile_issue_source {
    return <<'ISF';
(actor rule_drive_unproven
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done)
    (output out))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (drive set_out 0)
    (complete done))
  (rule force_out ready
    (out 1)))
ISF
}

sub arbitration_source {
    return <<'ISF';
(actor arbitration_report
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (input high_req)
    (input low_req)
    (output done)
    (output out)
    (output valid)
    (output err))
  (priority force_out over main)
  (priority high over low)
  (resources
    (resource shared_slot
      (kind rule_slot)
      (arbiter priority)
      (users high low)))
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1))
  (rule high high_req
    (valid 1))
  (rule low low_req
    (err 1)))
ISF
}

sub generated_composition_source {
    return <<'ISF';
(actor generated_composition_report
  (clock clk)
  (interface
    (input trigger)
    (output done)
    (output rdata (width 32)))
  (drive (rdata val) (rdata val))
  (transaction parent
    (on trigger)
    (spawn worker as w0
      (params
        (WIDTH 16)))
    (spawn worker as w1)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (sample trigger as val)
    (drive rdata val)
    (complete done)))
ISF
}

sub clock_domain_partition_source {
    return <<'ISF';
(actor clock_domain_partition
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
  (interface
    (input start (domain core))
    (input bus_evt (domain bus))
    (output core_done (domain core))
    (output helper_done (domain core))
    (output bus_done (domain bus)))
  (storage
    (var core_reg (width 1) (domain core))
    (var bus_reg (width 1) (domain bus))
    (var bus_rule_reg (width 1) (domain bus)))
  (transaction core_tx
    (domain core)
    (on start)
    (spawn helper as h0
      (domain core))
    (update core_reg start)
    (complete core_done))
  (transaction helper
    (domain core)
    (complete helper_done))
  (transaction bus_tx
    (domain bus)
    (on bus_evt)
    (update bus_reg bus_evt)
    (complete bus_done))
  (rule bus_rule
    (domain bus)
    bus_evt
    (set bus_rule_reg 1)))
ISF
}

sub actor_metadata_source {
    return <<'ISF';
(actor actor_metadata_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (phase setup (outputs done) (next finish))
  (stage pass_through (input start) (output done) (latency (max 3)))
  (transaction main
    (on start)
    (complete done)))
ISF
}

sub actor_param_source {
    return <<'ISF';
(actor actor_param_report
  (clock clk)
  (params
    (WIDTH 8)
    (LANES (1 2)))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
}

sub typed_storage_source {
    return <<'ISF';
(actor typed_storage_report
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (interface
    (input start)
    (input frame_in (width 3))
    (output frame_out (width 3)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (set frame_out frame)))
ISF
}

sub wait_matrix_source {
    return <<'ISF';
(actor wait_matrix
  (clock clk)
  (constants
    (WAIT_TWO 2))
  (params
    (WAIT_PARAM 1))
  (interface
    (input start_static)
    (input start_param)
    (input start_scalar)
    (input start_expr)
    (input cycles (width 4))
    (input bias (width 4))
    (output done_static)
    (output done_param)
    (output done_scalar)
    (output done_expr))
  (transaction static_tx
    (on start_static)
    (wait WAIT_TWO)
    (complete done_static))
  (transaction param_tx
    (on start_param)
    (wait WAIT_PARAM)
    (complete done_param))
  (transaction scalar_tx
    (on start_scalar)
    (wait cycles)
    (complete done_scalar))
  (transaction expr_tx
    (on start_expr)
    (wait (+ cycles bias))
    (complete done_expr)))
ISF
}

sub loop_matrix_source {
    return <<'ISF';
(actor loop_matrix
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input keep)
    (input done_seen)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (while keep
      (drive tick)
      (wait 1))
    (until done_seen
      (drive tick)
      (wait 1))
    (complete done)))
ISF
}

sub stage_contract_source {
    return <<'ISF';
(actor stage_contract_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input ack)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF
}

sub port_binding_source {
    return <<'ISF';
(actor port_binding_report
  (clock clk)
  (interface
    (input start)
    (input fire)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction do_child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (on do_child_start)
    (update data addr)
    (complete do_child_done))
  (transaction spawn_child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete done))
  (transaction work
    (ports
      (input addr (width 8)))
    (on work_start)
    (complete done))
  (transaction parent
    (on start)
    (do do_child
      (bind
        (input addr req_addr)
        (output data resp)))
    (spawn spawn_child as w0
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done))
  (rule fire_work fire
    (trigger work
      (bind
        (input addr req_addr)))))
ISF
}

sub actor_network_static_source {
    return <<'ISF';
(actor actor_network_static_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
ISF
}

sub actor_network_resolved_instance_source {
    return <<'ISF';
(actor actor_network_resolved_instance_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
}

sub actor_network_group_source {
    return <<'ISF';
(actor actor_network_group_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline
    (members reader writer)
    (mode concurrent))
  (transaction run
    (on start)
    (complete done)))
ISF
}

sub actor_network_group_schedule_source {
    return <<'ISF';
(actor actor_network_group_schedule_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline
    (members reader writer)
    (mode concurrent))
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger writer.emit)
    (complete done)))
ISF
}

sub actor_network_event_wait_source {
    return <<'ISF';
(actor actor_network_event_wait_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF
}

sub actor_network_transaction_trigger_source {
    return <<'ISF';
(actor actor_network_transaction_trigger_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
}

sub actor_network_data_movement_source {
    return <<'ISF';
(actor actor_network_data_movement_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
}
