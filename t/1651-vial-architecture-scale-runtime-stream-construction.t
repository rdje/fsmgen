#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRuntimeStream;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleRuntimeStream';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my @profiles = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my @stages = qw(
    construct semantic bridge plan emit compile run trace_validate
    result_produce failure
);
my @nonclaims = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);
my %profile = (
    sv_portable_verilator => {
        tool_profile => 'verilator_5_046',
        logical_tool => 'verilator',
        version => '5.046',
        provider => 'none',
        backend_schema => 'fsmgen.vial_backend.sv_portable_verilator.v1',
        trace_schema => 'fsmgen.vial_sv_runtime_trace.v1',
        trace_projection_schema => 'fsmgen.vial_sv_trace_projection.v1',
        trace_authority => 'FSM::VIAL::Backend::TraceValidator',
        result_authority => 'FSM::VIAL::Backend::ResultProducer',
        command_count => 1,
        elaboration_timeout => undef,
    },
    vhdl_portable_ghdl => {
        tool_profile => 'ghdl_6_0_0_llvm_jit',
        logical_tool => 'ghdl',
        version => '6.0.0',
        provider => 'none',
        backend_schema => 'fsmgen.vial_backend.vhdl_portable.v1',
        trace_schema => 'fsmgen.vial_vhdl_runtime_trace.v2',
        trace_projection_schema => undef,
        trace_authority =>
            'FSM::VIAL::Backend::VHDLPortableTraceValidator',
        result_authority =>
            'FSM::VIAL::Backend::VHDLPortableGHDLQualification',
        command_count => 2,
        elaboration_timeout => 60,
    },
    vhdl_osvvm_qualified => {
        tool_profile => 'osvvm_2026_05_ghdl_6_0_0_llvm_jit',
        logical_tool => 'ghdl',
        version => '6.0.0',
        provider => 'OSVVM 2026.05',
        backend_schema => 'fsmgen.vial_backend.vhdl_osvvm.v1',
        trace_schema => 'fsmgen.vial_vhdl_runtime_trace.v2',
        trace_projection_schema => undef,
        trace_authority =>
            'FSM::VIAL::Backend::VHDLPortableTraceValidator',
        result_authority =>
            'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification',
        command_count => 2,
        elaboration_timeout => 60,
    },
);
my %level = (
    reference_v1 => {
        mode => 'checked_anchor_profile',
        anchor => 'checked_ahb_reference_v1',
    },
    gate_candidate_v1 => {
        mode => 'exact_semantic_candidate',
        semantic => 10_000,
    },
    qualification_candidate_v1 => {
        mode => 'exact_semantic_candidate',
        semantic => 100_000,
    },
    limit_v1 => {
        mode => 'earliest_structural_cap_specification',
        structural_records => 8_000_002,
        structural_bytes => 67_108_864,
        earliest => 1,
    },
    over_limit_v1 => {
        mode => 'earliest_structural_cap_specification',
        structural_records => 8_000_003,
        structural_bytes => 67_108_865,
        earliest => 1,
    },
);
my (%construction, %report);

sub construction {
    my ($backend_profile, $selected_level) = @_;
    return $class->construct({
        backend_profile => $backend_profile,
        level => $selected_level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

subtest 'catalog ownership and construction close all fifteen shapes' => sub {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my @catalog_profiles = grep {
        $catalog->{backend_profiles}{$_}{runtime_eligible}
    } sort keys %{$catalog->{backend_profiles}};
    is_deeply(\@catalog_profiles, [sort @profiles],
        'catalog exposes exactly the three runtime-eligible profiles');
    is_deeply($catalog->{levels}, \@levels,
        'runtime construction consumes the exact five-level catalog ladder');

    my @owned = map {
        my $backend_profile = $_;
        map {{backend_profile => $backend_profile, level => $_}} @levels
    } @profiles;
    is_deeply($class->owned_shapes, \@owned,
        'runtime constructor owns exactly three profiles by five levels');

    for my $backend_profile (@profiles) {
        for my $selected_level (@levels) {
            my $key = "$backend_profile/$selected_level";
            my $first = construction($backend_profile, $selected_level);
            my $second = construction($backend_profile, $selected_level);
            ok($first->{ok}, "$key constructs successfully");
            is($json->encode($second), $json->encode($first),
                "$key construction is byte-identical");
            is($first->{specification}{family}, 'runtime_stream_v1',
                "$key uses the exact runtime family");
            is($first->{specification}{primary_axis},
                'runtime_trace_records', "$key uses the exact trace axis");
            is($first->{specification}{tool_profile},
                $profile{$backend_profile}{tool_profile},
                "$key derives the exact qualified tool selector");
            is_deeply($first->{specification}{applicable_oracles},
                [qw(construct semantic bridge plan emit compile run failure)],
                "$key retains the selected oracle applicability");
            is_deeply(
                $first->{specification}{requested_counts}{backend_limits},
                {
                    compile_transcript_bytes => 8_388_608,
                    run_transcript_bytes => 67_108_864,
                    runtime_trace_records => 8_000_002,
                    runtime_trace_bytes => 67_108_864,
                },
                "$key derives every runtime limit from the catalog",
            );
            is_deeply($first->{specification}{explicit_nonclaims},
                \@nonclaims, "$key preserves every scale nonclaim");
            $construction{$key} = $first;
        }
    }
};

subtest 'provider-free reports freeze inputs, stages, and exact expectations' => sub {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my %reference_route_identity;
    for my $backend_profile (@profiles) {
        for my $selected_level (@levels) {
            my $key = "$backend_profile/$selected_level";
            my $evaluated = $class->evaluate({
                construction => $construction{$key},
            });
            ok($evaluated->{ok}, "$key report succeeds");
            is($evaluated->{status},
                'provider_free_runtime_inputs_constructed',
                "$key is explicitly provider-free construction evidence");
            is_deeply([sort keys %$evaluated],
                [sort @{$class->report_keys}],
                "$key report schema is closed");
            like($evaluated->{report_identity},
                qr{\Aruntime-stream-report/[0-9a-f]{64}\z},
                "$key report identity is content-addressed");
            like($evaluated->{rerun_identity},
                qr{\Aruntime-stream-rerun/[0-9a-f]{64}\z},
                "$key carries a canonical rerun identity");
            is($evaluated->{workload_identity},
                $construction{$key}{workload_identity},
                "$key report preserves workload identity");
            is_deeply([map { $_->{stage} }
                    @{$evaluated->{stage_expectations}}], \@stages,
                "$key carries every selected and downstream stage");
            is_deeply(
                [map { $_->{construction_status} }
                    @{$evaluated->{stage_expectations}}[0 .. 3]],
                [map { 'completed' } 1 .. 4],
                "$key completed only provider-free canonical stages",
            );
            is_deeply(
                [map { $_->{construction_status} }
                    @{$evaluated->{stage_expectations}}[4 .. 8]],
                [map { 'not_run_measurement_required' } 1 .. 5],
                "$key leaves emit through result production for measurement",
            );

            my $handoff = $evaluated->{backend_handoff};
            is($handoff->{backend_schema},
                $profile{$backend_profile}{backend_schema},
                "$key freezes the exact backend schema");
            is_deeply($handoff->{structural_authority},
                $catalog->{backend_profiles}{$backend_profile}
                    {structural_authority},
                "$key retains shared structural authority");
            is_deeply($handoff->{route_metrics}, {
                scenarios => 2,
                operations_total => 21,
                fibers_total => 4,
                simultaneously_live_fibers => 3,
                source_map_entries => 39,
                backend_input_artifacts => 2,
            }, "$key rebuilds the exact checked-AHB backend inputs");
            is($handoff->{backend_inputs_sha256},
                $handoff->{stage_identities}{backend_inputs_sha256},
                "$key binds handoff identity to canonical backend inputs");
            ok(!$handoff->{provider_accessed}
                    && !$handoff->{external_tool_executed},
                "$key touches neither provider nor external tool");
            $reference_route_identity{$backend_profile} //=
                $json->encode($handoff->{stage_identities});
            is($json->encode($handoff->{stage_identities}),
                $reference_route_identity{$backend_profile},
                "$key preserves its profile reference-route identities");

            my $compile = $evaluated->{compile_expectation};
            is($compile->{tool_profile},
                $profile{$backend_profile}{tool_profile},
                "$key compile expectation names the tool profile");
            is($compile->{logical_tool},
                $profile{$backend_profile}{logical_tool},
                "$key compile expectation names the logical tool");
            is($compile->{qualified_version},
                $profile{$backend_profile}{version},
                "$key compile expectation names the exact version");
            is($compile->{provider}, $profile{$backend_profile}{provider},
                "$key compile expectation preserves provider identity");
            is(scalar(@{$compile->{command_authorities}}),
                $profile{$backend_profile}{command_count},
                "$key compile command authority is closed");
            is($compile->{analysis_timeout_seconds}, 120,
                "$key compile/analyze timeout is exact");
            is($compile->{elaboration_timeout_seconds},
                $profile{$backend_profile}{elaboration_timeout},
                "$key elaboration timeout is exact");
            is($compile->{transcript_limit_bytes}, 8_388_608,
                "$key compile transcript cap is exact");
            is($evaluated->{run_expectation}{timeout_seconds}, 30,
                "$key run timeout is exact");
            is($evaluated->{run_expectation}{transcript_limit_bytes},
                67_108_864, "$key run transcript cap is exact");
            ok(!$evaluated->{run_expectation}{external_tool_executed},
                "$key does not convert a run expectation into evidence");

            my $trace = $evaluated->{trace_expectation};
            my $count = $trace->{record_count_expectation};
            my $expected = clone($level{$selected_level});
            $expected->{semantic} = 15_000
                if $backend_profile eq 'sv_portable_verilator'
                    && $selected_level eq 'qualification_candidate_v1';
            is($trace->{trace_schema},
                $profile{$backend_profile}{trace_schema},
                "$key trace schema is profile-exact");
            is($trace->{trace_projection_schema},
                $profile{$backend_profile}{trace_projection_schema},
                "$key trace projection authority is honest");
            is($trace->{validation_authority},
                $profile{$backend_profile}{trace_authority},
                "$key trace validator authority is exact");
            is($count->{mode}, $expected->{mode},
                "$key record-count mode is exact");
            is($count->{anchor_profile}, $expected->{anchor},
                "$key anchor expectation is exact");
            is($count->{semantic_trace_records}, $expected->{semantic},
                "$key semantic record candidate is exact");
            is($count->{structural_trace_records},
                $expected->{structural_records},
                "$key structural record specification is exact");
            is($count->{structural_trace_bytes},
                $expected->{structural_bytes},
                "$key structural byte specification is exact");
            is(0 + $count->{earliest_cap_authoritative},
                0 + ($expected->{earliest} // 0),
                "$key earliest-cap authority is exact");
            ok(!$count->{boundary_reached} && !$trace->{materialized},
                "$key claims neither a reached cap nor a materialized trace");
            is($trace->{record_limit}, 8_000_002,
                "$key structural trace-record limit is exact");
            is($trace->{byte_limit}, 67_108_864,
                "$key structural trace-byte limit is exact");

            my $result = $evaluated->{result_expectation};
            is($result->{result_schema},
                'fsmgen.verification_result_manifest.v1',
                "$key normalized result schema is exact");
            is($result->{production_authority},
                $profile{$backend_profile}{result_authority},
                "$key result-production authority is exact");
            is($result->{expected_result_status}, 'pass',
                "$key requires one passing normalized result");
            ok($result->{semantic_oracle_required}
                    && !$result->{materialized},
                "$key requires semantics without fabricating a result");

            my $claims = $evaluated->{claims};
            ok($claims->{qualification_only}
                    && $claims->{runtime_stream_constructed}
                    && $claims->{canonical_backend_inputs_constructed},
                "$key claims only provider-free construction");
            ok(!$claims->{backend_artifacts_emitted}
                    && !$claims->{provider_accessed}
                    && !$claims->{external_tool_executed}
                    && !$claims->{runtime_executed}
                    && !$claims->{trace_materialized}
                    && !$claims->{result_materialized}
                    && !$claims->{support_claimed}
                    && !$claims->{performance_claimed}
                    && !$claims->{capacity_claimed}
                    && !$claims->{structural_boundary_reached},
                "$key preserves every runtime and product nonclaim");
            is_deeply($evaluated->{explicit_nonclaims}, \@nonclaims,
                "$key copies the selected explicit nonclaims");
            is_deeply($evaluated->{diagnostics}, [],
                "$key provider-free construction has no diagnostics");
            $report{$key} = $evaluated;
        }
    }
};

subtest 'hostile calls and mutations fail closed' => sub {
    my $key = 'sv_portable_verilator/gate_candidate_v1';
    my $validated = $class->validate_report({
        construction => $construction{$key},
        report => $report{$key},
    });
    is($json->encode($validated), $json->encode($report{$key}),
        'canonical report validation returns a defensive equal value');
    $validated->{trace_expectation}{record_count_expectation}
        {semantic_trace_records} = 9_999;
    is($report{$key}{trace_expectation}{record_count_expectation}
            {semantic_trace_records}, 10_000,
        'validated report mutation cannot alter stored evidence');

    my $mutated_report = clone($report{$key});
    $mutated_report->{claims}{support_claimed} = JSON::PP::true;
    eval {
        $class->validate_report({
            construction => $construction{$key},
            report => $mutated_report,
        });
    };
    like($@, qr/runtime-stream report is not canonical/,
        'support-claim forgery is rejected');

    my $mutated_construction = clone($construction{$key});
    $mutated_construction->{specification}{requested_counts}
        {semantic_trace_records} = 9_999;
    eval { $class->evaluate({construction => $mutated_construction}) };
    like($@, qr/runtime-stream construction is not canonical/,
        'construction mutation is rejected');

    eval {
        $class->_evaluate_candidate({construction => $construction{$key}})
    };
    like($@, qr/candidate evaluation is caller-sealed/,
        'private candidate evaluation rejects direct callers');
    eval {
        FSM::VIAL::ArchitectureScaleRuntimeStream::construct(
            'FSM::VIAL::ArchitectureScaleRuntimeStream::Subclass', {})
    };
    like($@, qr/requires the exact class invocant/,
        'subclass invocants cannot widen the boundary');
    eval {
        $class->construct({
            backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
        })
    };
    like($@, qr/unknown runtime-stream profile/,
        'non-runtime native UVM is rejected');
    eval {
        $class->construct({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => "$reference_hial ",
            reference_vial_text => $reference_vial,
        })
    };
    like($@, qr/checked-AHB HIAL byte length changed/,
        'changed reference HIAL is rejected before construction');
    eval {
        $class->construct({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            tool_profile => 'forged',
        })
    };
    like($@, qr/unknown key 'tool_profile'/,
        'callers cannot forge the qualified tool selector');
};

subtest 'same-volume staging cleans success and failure exactly' => sub {
    my $construction =
        $construction{'vhdl_osvvm_qualified/over_limit_v1'};
    my $stage_abs = repo_path(split m{/},
        $construction->{staging_identity});
    my $seen_stage;
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $seen_stage = $context->{staging_identity};
            ok(-d $context->{staging_root},
                'consumer sees one repository-local runtime stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful staging is on-volume and removed');
    is($seen_stage, $construction->{staging_identity},
        'consumer sees the content-addressed relative staging identity');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful staging leaves no runtime-scale residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub { die "intentional runtime consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable scale diagnostic');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed staging also leaves no runtime-scale residue');
};

done_testing;

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
