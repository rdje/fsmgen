#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;
use FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;

my $class = 'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization';
my $portable =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization';
my $provider = 'FSM::VIAL::Backend::OSVVM2026_05Materialization';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1);
my $mirror_rel = ".artifacts/test/vial-osvvm-runtime-materialization-$$";
my $mirror_root = repo_path(split m{/}, $mirror_rel);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %expected = (
    reference_v1 => {
        status => 'provider_structurally_qualified', records => 77,
        source => 'vial/ahb_subordinate_base_output_arbitration.vial',
        source_bytes => 4_986,
        source_sha =>
            '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        emitted_source_bytes => 122_413,
        graph =>
            '236f430941682884ba2cd77858cb43fc2bc1dbc6b568ec75759cf4b1561047ea',
        report =>
            'osvvm-runtime-materialization/6ce4f9a16327c11b18e82052d525b6a534b69494456c955ee8496a5356a8551e',
    },
    gate_candidate_v1 => {
        status => 'provider_structurally_qualified', records => 10_000,
        source =>
            'vial/qualification/vhdl_portable_ghdl_runtime_gate.vial',
        source_bytes => 4_991,
        source_sha =>
            'ce1374f97dcf992e823273d70ebcf1014813ff926a103fea53800797cf304959',
        emitted_source_bytes => 122_426,
        graph =>
            '58eddfc1a4a1d0f7fd04c479604b8402a6bf87dc6d3ad8b3dfc70df176f09c91',
        report =>
            'osvvm-runtime-materialization/df695752247a5c005d5c4b1d653915bd7a2d6e61396e7679862381d1b06a69ad',
    },
    qualification_candidate_v1 => {
        status => 'provider_structurally_qualified', records => 100_000,
        source =>
            'vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial',
        source_bytes => 4_993,
        source_sha =>
            'cbf752abb62d0b88e5411cde979d0e6eb91a5f0e23a1b2eece8c633edad4b7ca',
        emitted_source_bytes => 122_438,
        graph =>
            '21fecffec8f130b8f09be3be62f0270f91ff1b5234a791101b786d2fadfc6226',
        report =>
            'osvvm-runtime-materialization/3e1359c0d1c985bbf78f67371a60072c7fa2be3d3d9ba2cec766939a48dcdc8f',
    },
    limit_v1 => {
        status => 'preflight_dominated', records => 8_000_002,
        bytes => 67_108_864,
        report =>
            'osvvm-runtime-materialization/fa5cd1e0415321b0f451c9dd57eb8fda8c7e7c771127d254f5c5a34bc7d3af9b',
    },
    over_limit_v1 => {
        status => 'preflight_dominated', records => 8_000_003,
        bytes => 67_108_865,
        report =>
            'osvvm-runtime-materialization/d306370a652879187d02364185a11d1e004003098e38af68545d12246ddb059d',
    },
);
my %report;

END {
    remove_tree($mirror_root)
        if defined($mirror_root) && -d $mirror_root && !-l $mirror_root;
}

subtest 'ownership and construction select only exact OSVVM runtime roles' => sub {
    is_deeply($class->owned_shapes, [map {{
        backend_profile => 'vhdl_osvvm_qualified', level => $_,
    }} @levels], 'materializer owns exactly the five OSVVM runtime roles');
    for my $level (@levels) {
        my $construction = $class->construct({
            repository_root => $repo_root, level => $level,
        });
        ok($construction->{ok}, "$level construction succeeds");
        is($construction->{specification}{backend_profile},
            'vhdl_osvvm_qualified', "$level selects only OSVVM");
        is($construction->{specification}{tool_profile},
            'osvvm_2026_05_ghdl_6_0_0_llvm_jit',
            "$level selects the exact qualified tool profile");
        is($construction->{specification}{family}, 'runtime_stream_v1',
            "$level retains the runtime family");
    }
};

subtest 'all five reports close the exact materialization boundary' => sub {
    for my $level (@levels) {
        my $actual;
        if ($level eq 'reference_v1') {
            my $verify = $provider->can('verify');
            my $verify_count = 0;
            {
                no warnings 'redefine';
                local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify =
                    sub { ++$verify_count; return $verify->(@_) };
                $actual = $class->evaluate({
                    repository_root => $repo_root, level => $level,
                });
            }
            is($verify_count, 1,
                'both deterministic emissions reuse one provider verification');
        }
        else {
            $actual = $class->evaluate({
                repository_root => $repo_root, level => $level,
            });
        }
        ok($actual->{ok}, "$level is an accepted qualification outcome");
        is_deeply([sort keys %$actual], [sort @{$class->report_keys}],
            "$level report schema is closed");
        is($actual->{status}, $expected{$level}{status},
            "$level status is exact");
        is($actual->{backend_profile}, 'vhdl_osvvm_qualified',
            "$level retains the exact provider-aware backend");
        is($actual->{tool_profile},
            'osvvm_2026_05_ghdl_6_0_0_llvm_jit',
            "$level retains the exact tool identity");
        is($actual->{trace_projection}{record_count},
            $expected{$level}{records}, "$level record count is exact");
        is($actual->{report_identity}, $expected{$level}{report},
            "$level report identity is frozen");
        ok(!$actual->{claims}{external_tool_executed}
                && !$actual->{claims}{runtime_executed}
                && !$actual->{claims}{trace_materialized}
                && !$actual->{claims}{result_produced}
                && !$actual->{claims}{support_claimed}
                && !$actual->{claims}{performance_claimed}
                && !$actual->{claims}{capacity_claimed}
                && !$actual->{claims}{reached_record_boundary}
                && !$actual->{claims}{public_api_changed},
            "$level preserves runtime, product, and capacity nonclaims");
        is_deeply($actual->{cleanup}{residue}, [],
            "$level leaves no in-memory evaluation residue");

        if ($level =~ /\A(?:limit|over_limit)_v1\z/) {
            check_preflight($level, $actual);
        }
        else {
            check_materialized($level, $actual);
        }
        $report{$level} = $actual;
    }
};

subtest 'preflight roles are provider-free as well as tool-free' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify =
        sub { die "provider verification must not run\n" };
    for my $level (qw(limit_v1 over_limit_v1)) {
        my $actual = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        is($actual->{status}, 'preflight_dominated',
            "$level closes without provider access");
        ok(!$actual->{envelope_projection}{external_tool_eligible},
            "$level remains tool-ineligible");
    }
};

subtest 'reports, private seams, relocation, and source identities fail closed' => sub {
    my $validated = $class->validate_report({
        repository_root => $repo_root,
        report => $report{limit_v1},
    });
    is($json->encode($validated),
        $json->encode($report{limit_v1}),
        'canonical provider-aware report validates defensively');
    $validated->{claims}{runtime_executed} = JSON::PP::true;
    is($report{limit_v1}{claims}{runtime_executed},
        JSON::PP::false, 'validated mutation cannot alter stored evidence');

    my $mutated = clone($report{over_limit_v1});
    $mutated->{claims}{support_claimed} = JSON::PP::true;
    eval {
        $class->validate_report({
            repository_root => $repo_root, report => $mutated,
        });
    };
    like($@, qr/report is not canonical/,
        'product-support substitution is rejected');

    eval {
        $portable->_osvvm_runtime_construction({
            repository_root => $repo_root, level => 'reference_v1',
        });
    };
    like($@, qr/private to the exact materializer/,
        'callers cannot bypass the construction seal');
    eval {
        $portable->_osvvm_runtime_route_inputs({
            repository_root => $repo_root, level => 'reference_v1',
        });
    };
    like($@, qr/private to the exact materializer/,
        'callers cannot inject source or IR through the route seal');
    eval {
        FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM
            ->_runtime_evaluate({});
    };
    like($@, qr/runtime evaluation is caller-sealed/,
        'callers cannot bypass provider-aware graph validation');
    eval {
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization::evaluate(
            $class . '::Subclass',
            {repository_root => $repo_root, level => 'reference_v1'},
        );
    };
    like($@, qr/requires the exact class invocant/,
        'subclass invocants cannot widen materialization');

    build_mirror();
    my $mirror = $class->construct({
        repository_root => $mirror_root, level => 'gate_candidate_v1',
    });
    my $canonical = $class->construct({
        repository_root => $repo_root, level => 'gate_candidate_v1',
    });
    is($mirror->{workload_identity}, $canonical->{workload_identity},
        'same-volume repository relocation preserves construction identity');
    my $path = File::Spec->catfile(
        $mirror_root,
        qw(vial qualification vhdl_portable_ghdl_runtime_gate.vial),
    );
    my $gate = slurp_raw($path);
    $gate =~ s/reset bus 9926/reset bus 9927/
        or die 'mirror mutation anchor is absent';
    write_raw($path, $gate);
    eval {
        $class->construct({
            repository_root => $mirror_root, level => 'gate_candidate_v1',
        });
    };
    like($@, qr/source identity changed/,
        'changed authored source rejects before provider or emission');
    remove_tree($mirror_root);
    ok(!-e $mirror_root && !-l $mirror_root,
        'hostile mirror is removed exactly');
};

subtest 'same-volume staging cleans success, failure, and preflight denial' => sub {
    my $seen;
    my $success = $class->with_staging({
        repository_root => $repo_root,
        level => 'reference_v1',
        consumer => sub {
            my ($context) = @_;
            $seen = $context->{staging_identity};
            ok(-d $context->{staging_root},
                'consumer sees one exact repository-volume stage');
            is($context->{report}{emission_oracle}{artifact_count}, 16,
                'consumer receives regenerated provider-aware evidence');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful staging is same-volume and removed');
    ok(defined($seen) && !-e repo_path(split m{/}, $seen),
        'successful staging identity leaves no residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        level => 'reference_v1',
        consumer => sub { die "intentional materialization failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable workload diagnostic');

    eval {
        $class->with_staging({
            repository_root => $repo_root,
            level => 'limit_v1',
            consumer => sub { die 'must not run' },
        });
    };
    like($@, qr/preflight-dominated OSVVM runtime shapes cannot create staging/,
        'nominal limit rejects before staging, provider, or tool execution');
};

done_testing;

sub check_materialized {
    my ($level, $actual) = @_;
    my $contract = $expected{$level};
    is($actual->{source_identity}{relative_path}, $contract->{source},
        "$level authored source path is exact");
    is($actual->{source_identity}{bytes}, $contract->{source_bytes},
        "$level authored source byte count is exact");
    is($actual->{source_identity}{sha256}, $contract->{source_sha},
        "$level authored source identity is exact");
    is($actual->{portable_authority}{source_identity}{sha256},
        $contract->{source_sha},
        "$level binds the same portable semantic source");
    is($actual->{schedule_oracle}{operation_count}, 21,
        "$level retains exactly 21 operations");
    is($actual->{schedule_oracle}{source_map_count}, 39,
        "$level retains 39 ExecutionIR source maps");
    ok($actual->{claims}{portable_semantic_authority_reused}
            && $actual->{claims}{provider_materialization_verified}
            && $actual->{claims}{provider_verification_reused}
            && $actual->{claims}{advanced_adapter_emitted}
            && $actual->{claims}{artifact_graph_claimed},
        "$level claims only its exact provider-aware structural graph");

    my $oracle = $actual->{emission_oracle};
    is($oracle->{artifact_count}, 16,
        "$level emits exactly sixteen artifacts");
    is($oracle->{source_artifact_count}, 7,
        "$level emits six portable sources plus one adapter");
    is($oracle->{source_bytes}, $contract->{emitted_source_bytes},
        "$level seven-source byte total is exact");
    is($oracle->{source_map_entries}, 66,
        "$level emits exactly 66 source maps");
    is($oracle->{adapter_source_map_entries}, 7,
        "$level retains seven adapter maps");
    is($oracle->{translated_portable_source_map_entries}, 59,
        "$level translates all 59 portable maps");
    is($oracle->{mapped_operation_count}, 21,
        "$level maps every canonical operation");
    is($oracle->{static_validation_checks}, 12,
        "$level passes twelve OSVVM structural checks");
    is($oracle->{advanced_mapping_count}, 7,
        "$level retains seven advanced mappings");
    is($oracle->{semantic_preservation_source_count}, 6,
        "$level preserves all six portable sources byte-for-byte");
    is($oracle->{semantic_preservation_guard_count}, 6,
        "$level retains all six portable semantic guards");
    is_deeply([@{$oracle}{qw(
        provider_repository_count provider_gitlink_count
        provider_license_count provider_notice_count
    )}], [14, 13, 14, 0],
        "$level freezes the provider repository and licence census");
    is($oracle->{provider_manifest_sha256},
        '128e483049521c2d4882bac0a6ceb66d9d127ca3e33109961942662409e06f96',
        "$level freezes the provider manifest identity");
    is($oracle->{artifact_graph_sha256}, $contract->{graph},
        "$level complete graph identity is frozen");
    ok($oracle->{byte_equal_rerun}
            && $oracle->{provider_verification_reused}
            && $oracle->{in_memory_only},
        "$level reuses one verification for a byte-identical rerun");
    is_deeply($oracle->{diagnostics}, [],
        "$level graph is structurally clean");
}

sub check_preflight {
    my ($level, $actual) = @_;
    ok($actual->{claims}{preflight_dominance_proved},
        "$level is closed by the earlier structural cap");
    ok(!$actual->{claims}{ordinary_route_reconstructed}
            && !$actual->{claims}{provider_materialization_verified}
            && !$actual->{claims}{artifact_graph_claimed},
        "$level creates neither route, provider evidence, nor graph");
    ok(!defined($actual->{emission_oracle}),
        "$level has no provider-aware emission oracle");
    is($actual->{trace_projection}{derivation}{minimum_structural_trace_bytes},
        $expected{$level}{bytes},
        "$level retains its minimum truthful byte witness");
    is($actual->{envelope_projection}{status}, 'preflight_dominated',
        "$level cannot start an external tool");
}

sub build_mirror {
    remove_tree($mirror_root) if -d $mirror_root && !-l $mirror_root;
    for my $relative (
        'ppif/ahb_lite_subordinate.ppif',
        'vial/ahb_subordinate_base_output_arbitration.vial',
        'vial/qualification/vhdl_portable_ghdl_runtime_gate.vial',
        'vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial',
    ) {
        my @parts = split m{/}, $relative;
        my $name = pop @parts;
        my $directory = File::Spec->catdir($mirror_root, @parts);
        make_path($directory);
        write_raw(File::Spec->catfile($directory, $name),
            slurp_raw(repo_path(split m{/}, $relative)));
    }
}

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

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!\n";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!\n";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
