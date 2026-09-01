package FSM::Test::OSVVMRuntimePersistedRequest;

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use JSON::PP ();

use FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

our @EXPORT_OK = qw(exact_inputs rehash_request validate_envelope);

my $JSON = JSON::PP->new->canonical(1);
my $EXACT_TEMPLATE;

sub exact_inputs {
    return map { _clone($_) } @$EXACT_TEMPLATE if $EXACT_TEMPLATE;
    my $repository_root = abs_path('.');
    my $plan =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan->evaluate({
            repository_root => $repository_root,
            level => 'reference_v1',
        });
    my $construction =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization->construct({
            repository_root => $repository_root,
            level => 'reference_v1',
        });
    my $materialization =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization->evaluate({
            repository_root => $repository_root,
            level => 'reference_v1',
        });
    my $controller_root = '.artifacts/tmp/vial-scale/' . ('b' x 64)
        . '/validation/00';
    my $lifecycle_root = "$controller_root/lifecycle";
    my $canonical_root = $plan->{storage_authority}{staging_identity};

    my (%generated_relocation, @generated);
    for my $source (@{$plan->{source_authority}{generated_sources}}) {
        my $relpath = "$controller_root/outputs/emit/source-graph/"
            . $source->{source_artifact_relpath};
        $generated_relocation{$source->{relpath}} = $relpath;
        push @generated, {
            relpath => $relpath,
            bytes => 0 + $source->{bytes},
            sha256 => $source->{sha256},
        };
    }

    my $relocate_argv = sub {
        my ($record) = @_;
        return [map {
            my $argument = $_;
            if (exists $generated_relocation{$argument}) {
                $argument = $generated_relocation{$argument};
            }
            else {
                $argument =~ s/\Q$canonical_root\E/$lifecycle_root/g;
            }
            $argument;
        } @{$record->{argv}}];
    };
    my $relocate_scalar = sub {
        my ($value) = @_;
        $value =~ s/\Q$canonical_root\E/$lifecycle_root/g;
        return $value;
    };

    my $settings_content = $relocate_scalar->(
        $plan->{generated_settings}{content},
    );
    my $commands = {
        schema => 'fsmgen.vial_ghdl_lifecycle_osvvm_command_plan.v2',
        schema_version => 2,
        version => $relocate_argv->($plan->{commands}{version}),
        provider_analyze => [map {
            $relocate_argv->($_)
        } @{$plan->{commands}{provider_analyze}}],
        analyze_generated =>
            $relocate_argv->($plan->{commands}{analyze_generated}),
        elaborate_fixture =>
            $relocate_argv->($plan->{commands}{elaborate_fixture}),
        elaborate_provider_probe =>
            $relocate_argv->($plan->{commands}{elaborate_provider_probe}),
        run_fixture => $relocate_argv->($plan->{commands}{run_fixture}),
        run_provider_probe =>
            $relocate_argv->($plan->{commands}{run_provider_probe}),
        generated_settings => {
            relpath => "$lifecycle_root/OsvvmScriptSettingsPkg_generated.vhd",
            content => $settings_content,
            bytes => bytes::length($settings_content),
            sha256 => sha256_hex($settings_content),
        },
        libraries => {map {
            $_ => $relocate_scalar->($plan->{libraries}{$_})
        } sort keys %{$plan->{libraries}}},
        provider_reports => [map {{
            name => $_->{name},
            relpath => $relocate_scalar->($_->{relpath}),
        }} @{$plan->{report_inventory}}],
        resource_controls => _clone($plan->{resource_controls}),
    };

    my $canonical_settings = $plan->{generated_settings}{relpath};
    my @source_set = (
        (map {{
            relpath => $_->{relpath},
            bytes => 0 + $_->{bytes},
            sha256 => $_->{sha256},
        }} grep {
            $_->{relpath} ne $canonical_settings
        } @{$plan->{provider_authority}{provider_sources}}),
        @generated,
        {
            relpath => $plan->{source_authority}{provider_probe}{relpath},
            bytes => 0 + $plan->{source_authority}{provider_probe}{bytes},
            sha256 => $plan->{source_authority}{provider_probe}{sha256},
        },
    );

    my $raw = {
        repository_root => $repository_root,
        construction => $construction,
        materialization => $materialization,
        execution_plan => $plan,
        context => {staging_identity => $controller_root},
    };
    my $derived_route =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_route_authority(
            $raw,
        );
    my $execution = $derived_route->{projection}{execution_ir};
    my $route = {
        projection => {execution_ir => _clone($execution)},
    };
    my @run_ids = map {
        "run/$execution->{plan_id}/$_->{scenario_id}"
    } @{$execution->{scenarios}};
    my $checked = FSM::VIAL::Backend::VHDLPortableTraceValidator
        ->checked_reference_authority;
    my $tool = $plan->{tool_authority};
    my $request = {
        provider => {
            root => $tool->{root},
            archive => $tool->{archive}{relpath},
            archive_bytes => 0 + $tool->{archive}{bytes},
            archive_sha256 => $tool->{archive}{sha256},
            binary => $tool->{binary}{relpath},
            binary_sha256 => $tool->{binary}{sha256},
            version_output => $tool->{version_output},
        },
        source_set => \@source_set,
        source_identity => undef,
        emission_identity => undef,
        commands => $commands,
        validation => {
            expected_record_counts => _clone(
                $materialization->{trace_projection}{record_families},
            ),
            expected_diagnostic_codes => [map {
                $_->{name} eq 'success'
                    ? 'VIAL_EXPECT_SUCCESS' : 'VIAL_EXPECT_ERROR'
            } @{$execution->{scenarios}}],
            expected_domain_id => $execution->{domains}[0]{domain_id},
            expected_fixture_id => $execution->{fixture}{fixture_id},
            expected_plan_id => $execution->{plan_id},
            expected_random_decisions_sha256 =>
                sha256_hex($JSON->encode($execution->{randomness}{decisions})),
            expected_run_ids => \@run_ids,
            expected_observation_catalog =>
                _clone($checked->{expected_observation_catalog}),
            run_repetitions => 1,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'osvvm_architecture_scale_measurement',
            staging_identity => $lifecycle_root,
            containment => 'outer_worker_process_group',
        },
    };
    my $provider = $plan->{provider_authority};
    my $envelope = {
        schema => 'fsmgen.vial_osvvm_runtime_lifecycle_request.v1',
        schema_version => 1,
        materialization_identity => $plan->{materialization_identity},
        plan_identity => $plan->{plan_identity},
        provider_verification => {
            provider => $provider->{provider},
            version => $provider->{version},
            root_commit => $provider->{root_commit},
            root_tree => $provider->{root_tree},
            materialization_manifest_sha256 =>
                $provider->{materialization_manifest_sha256},
            provider_source_identity =>
                $provider->{provider_source_identity},
        },
        request => $request,
    };
    rehash_request($raw, $envelope);
    $EXACT_TEMPLATE = [$raw, $route, $envelope];
    return map { _clone($_) } @$EXACT_TEMPLATE;
}

sub rehash_request {
    my ($raw, $envelope) = @_;
    my $request = $envelope->{request};
    $request->{source_identity} =
        'source/' . sha256_hex($JSON->encode($request->{source_set}));
    $request->{emission_identity} = 'emission/' . sha256_hex($JSON->encode({
        workload_identity => $raw->{construction}{workload_identity},
        materialization_identity =>
            $raw->{materialization}{report_identity},
        plan_identity => $raw->{execution_plan}{plan_identity},
        source_identity => $request->{source_identity},
        commands => $request->{commands},
    }));
    return $envelope;
}

sub validate_envelope {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_validated_request_envelope(
        @_,
    );
}

sub _clone {
    my ($value) = @_;
    return $JSON->decode($JSON->encode($value));
}

1;
