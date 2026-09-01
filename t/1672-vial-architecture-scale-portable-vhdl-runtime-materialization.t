#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;

my $class =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1);
my $mirror_rel = ".artifacts/test/vial-portable-vhdl-materialization-$$";
my $mirror_root = repo_path(split m{/}, $mirror_rel);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %expected = (
    reference_v1 => {
        status => 'structurally_qualified', records => 77,
        reset => 3, timeout => 256,
        source => 'vial/ahb_subordinate_base_output_arbitration.vial',
        source_bytes => 4_986,
        source_sha =>
            '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        artifact_bytes => 238_857, vhdl_bytes => 118_301,
        fixture_bytes => 46_501,
        fixture_sha =>
            'e1639212cb7c0152ce3e6cdfb6829916e4ff3b181f1d4490f70dc48fe62f32b6',
        report =>
            'portable-vhdl-runtime-materialization/6f12ab75b1ea1e57d3446ef714669daecdc5d2b56f9ff58d6c7fe755147d83bb',
    },
    gate_candidate_v1 => {
        status => 'structurally_qualified', records => 10_000,
        reset => 9_926, timeout => 16_384,
        source =>
            'vial/qualification/vhdl_portable_ghdl_runtime_gate.vial',
        source_bytes => 4_991,
        source_sha =>
            'ce1374f97dcf992e823273d70ebcf1014813ff926a103fea53800797cf304959',
        artifact_bytes => 239_140, vhdl_bytes => 118_314,
        fixture_bytes => 46_512,
        fixture_sha =>
            'b283e1a2be9fc2c39353347d84537d628dc09cd92de786ce0a7620013f7805e0',
        report =>
            'portable-vhdl-runtime-materialization/1cf26e647d3c95f47b14747b068d1f6c94e9e917ecced7e1f035ed519702e305',
    },
    qualification_candidate_v1 => {
        status => 'structurally_qualified', records => 100_000,
        reset => 99_926, timeout => 131_072,
        source =>
            'vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial',
        source_bytes => 4_993,
        source_sha =>
            'cbf752abb62d0b88e5411cde979d0e6eb91a5f0e23a1b2eece8c633edad4b7ca',
        artifact_bytes => 239_557, vhdl_bytes => 118_326,
        fixture_bytes => 46_523,
        fixture_sha =>
            '929006e97de7852e8e3a9b0031de12da098f4cafea49293f69fdcddcc8276561',
        report =>
            'portable-vhdl-runtime-materialization/8ebff4364b5ca10b4fb6ad1cd639116e3986ed61747ae93f8da469dfc287effe',
    },
    limit_v1 => {
        status => 'preflight_dominated', records => 8_000_002,
        bytes => 67_108_864,
        report =>
            'portable-vhdl-runtime-materialization/6a28590a0c4c6edc4f5e45b3466c7889fa38c4f9b23fbb3a8750f3bd20663791',
    },
    over_limit_v1 => {
        status => 'preflight_dominated', records => 8_000_003,
        bytes => 67_108_865,
        report =>
            'portable-vhdl-runtime-materialization/550683655ccbf59ec2464d4982c333a0eb9e3e2176bcda7426565a7c570c45fe',
    },
);
my %report;

END {
    remove_tree($mirror_root)
        if defined($mirror_root) && -d $mirror_root && !-l $mirror_root;
}

subtest 'ownership and tracked sources retain exactly two authored deltas' => sub {
    is_deeply($class->owned_shapes, [map {{
        backend_profile => 'vhdl_portable_ghdl', level => $_,
    }} @levels], 'materializer owns exactly the five portable-VHDL roles');

    my $reference = slurp_raw(repo_path(
        'vial', 'ahb_subordinate_base_output_arbitration.vial'));
    for my $level (qw(gate_candidate_v1 qualification_candidate_v1)) {
        my $contract = $expected{$level};
        my $candidate = slurp_raw(repo_path(
            split m{/}, $contract->{source}));
        my $projected = $reference;
        replace_once(\$projected,
            "(scenario success\n            (timeout (cycles bus 256))",
            '(scenario success' . "\n            (timeout (cycles bus "
                . $contract->{timeout} . '))');
        replace_once(\$projected,
            "              (reset bus 3)\n"
                . '              (scoreboard_expect writes',
            '              (reset bus ' . $contract->{reset} . ")\n"
                . '              (scoreboard_expect writes');
        is($candidate, $projected,
            "$level changes only success timeout and reset literals");
    }
};

subtest 'all five levels reconstruct exact canonical evidence twice' => sub {
    for my $level (@levels) {
        my $first = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        my $second = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        is($json->encode($second), $json->encode($first),
            "$level evaluation is byte-identical");
        ok($first->{ok}, "$level is an accepted qualification outcome");
        is_deeply([sort keys %$first], [sort @{$class->report_keys}],
            "$level report schema is closed");
        is($first->{status}, $expected{$level}{status},
            "$level status is exact");
        is($first->{backend_profile}, 'vhdl_portable_ghdl',
            "$level retains the exact provider-free backend");
        is($first->{trace_projection}{record_count},
            $expected{$level}{records}, "$level record count is exact");
        is($first->{report_identity}, $expected{$level}{report},
            "$level report identity is frozen");
        ok(!$first->{claims}{external_tool_executed}
                && !$first->{claims}{runtime_executed}
                && !$first->{claims}{trace_materialized}
                && !$first->{claims}{result_produced}
                && !$first->{claims}{support_claimed}
                && !$first->{claims}{performance_claimed}
                && !$first->{claims}{capacity_claimed}
                && !$first->{claims}{reached_record_boundary}
                && !$first->{claims}{public_api_changed},
            "$level preserves every runtime and product nonclaim");
        is_deeply($first->{cleanup}{residue}, [],
            "$level leaves no in-memory evaluation residue");

        if ($level =~ /\A(?:limit|over_limit)_v1\z/) {
            ok($first->{claims}{preflight_dominance_proved},
                "$level is closed by the earlier structural cap");
            ok(!$first->{claims}{ordinary_route_reconstructed},
                "$level does not reconstruct an oversized route");
            is($first->{trace_projection}{derivation}
                    {minimum_structural_trace_bytes},
                $expected{$level}{bytes},
                "$level preserves its minimum truthful byte witness");
            is($first->{envelope_projection}{status},
                'preflight_dominated',
                "$level cannot start an external tool");
            ok(!$first->{envelope_projection}{external_tool_eligible},
                "$level is tool-free");
        }
        else {
            check_materialized($level, $first);
        }
        $report{$level} = $first;
    }
};

subtest 'N+74 projection closes every exact v2 family and envelope' => sub {
    my %candidate_samples = (
        gate_candidate_v1 => 9_958,
        qualification_candidate_v1 => 99_958,
    );
    for my $level (sort keys %candidate_samples) {
        my $trace = $report{$level}{trace_projection};
        is($trace->{equation}, 'N+74', "$level retains the selected equation");
        is_deeply($trace->{record_families}, {
            coverage => 28,
            events => 2,
            expectations => 2,
            faults => 2,
            footer => 1,
            header => 1,
            samples => $candidate_samples{$level},
            scenario_end => 2,
            scenario_start => 2,
            scoreboards => 2,
        }, "$level closes all exact v2 record families");
        is($report{$level}{envelope_projection}{record_limit}, 8_000_002,
            "$level retains the unchanged record envelope");
        is($report{$level}{envelope_projection}{byte_limit}, 67_108_864,
            "$level retains the unchanged 64-MiB byte envelope");
        is($report{$level}{envelope_projection}{status},
            'structurally_admitted_runtime_unmeasured',
            "$level is admitted structurally without inventing runtime bytes");
        ok(!defined($report{$level}{envelope_projection}{actual_trace_bytes}),
            "$level makes no pre-measurement trace-byte claim");
    }
};

subtest 'reports, private route, and tracked sources fail closed' => sub {
    my $validated = $class->validate_report({
        repository_root => $repo_root,
        report => $report{gate_candidate_v1},
    });
    is($json->encode($validated),
        $json->encode($report{gate_candidate_v1}),
        'canonical report validates defensively');
    $validated->{trace_projection}{record_count} = 9_999;
    is($report{gate_candidate_v1}{trace_projection}{record_count}, 10_000,
        'validated mutation cannot alter stored evidence');

    my $mutated = clone($report{qualification_candidate_v1});
    $mutated->{claims}{runtime_executed} = JSON::PP::true;
    eval {
        $class->validate_report({
            repository_root => $repo_root, report => $mutated,
        });
    };
    like($@, qr/report is not canonical/,
        'runtime-claim substitution is rejected');

    eval {
        FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization::_canonical_route(
            undef, undef, undef,
        );
    };
    like($@, qr/canonical route is caller-sealed/,
        'callers cannot inject source or IR through the private route');
    eval {
        FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization::evaluate(
            $class . '::Subclass',
            {repository_root => $repo_root, level => 'reference_v1'},
        );
    };
    like($@, qr/requires the exact class invocant/,
        'subclass invocants cannot widen materialization');

    build_mirror();
    my $mirror = $class->evaluate({
        repository_root => $mirror_root, level => 'gate_candidate_v1',
    });
    is($mirror->{report_identity},
        $report{gate_candidate_v1}{report_identity},
        'same-volume repository relocation preserves canonical evidence');
    my $path = File::Spec->catfile(
        $mirror_root,
        qw(vial qualification vhdl_portable_ghdl_runtime_gate.vial),
    );
    my $gate = slurp_raw($path);
    $gate =~ s/reset bus 9926/reset bus 9927/
        or die 'mirror mutation anchor is absent';
    write_raw($path, $gate);
    eval {
        $class->evaluate({
            repository_root => $mirror_root, level => 'gate_candidate_v1',
        });
    };
    like($@, qr/source identity changed/,
        'changed tracked source rejects before parse, plan, or emission');
    remove_tree($mirror_root);
    ok(!-e $mirror_root && !-l $mirror_root,
        'hostile mirror is removed exactly');
};

subtest 'same-volume staging cleans success, failure, and preflight denial' => sub {
    my $seen;
    my $success = $class->with_staging({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
        consumer => sub {
            my ($context) = @_;
            $seen = $context->{staging_identity};
            ok(-d $context->{staging_root},
                'consumer sees one exact repository-volume stage');
            is($context->{report}{trace_projection}{record_count}, 10_000,
                'consumer receives regenerated canonical evidence');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful staging is same-volume and removed');
    ok(defined($seen) && !-e repo_path(split m{/}, $seen),
        'successful staging identity leaves no residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
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
    like($@, qr/preflight-dominated portable-VHDL shapes cannot create staging/,
        'nominal limit rejects before staging or external execution');
};

done_testing;

sub check_materialized {
    my ($level, $actual) = @_;
    my $contract = $expected{$level};
    is($actual->{source_identity}{relative_path}, $contract->{source},
        "$level source path is exact");
    is($actual->{source_identity}{bytes}, $contract->{source_bytes},
        "$level source byte count is exact");
    is($actual->{source_identity}{sha256}, $contract->{source_sha},
        "$level source identity is exact");
    is($actual->{schedule_oracle}{success_reset_cycles}, $contract->{reset},
        "$level ExecutionIR reset count is exact");
    is($actual->{schedule_oracle}{success_timeout_cycles},
        $contract->{timeout}, "$level ExecutionIR timeout is exact");
    is_deeply($actual->{schedule_oracle}{success_await_max_cycles},
        [256, 256], "$level await windows remain unchanged");
    is($actual->{schedule_oracle}{unsupported_size_reset_cycles}, 3,
        "$level sibling reset remains unchanged");
    is($actual->{schedule_oracle}{unsupported_size_timeout_cycles}, 256,
        "$level sibling timeout remains unchanged");
    is($actual->{schedule_oracle}{operation_count}, 21,
        "$level retains 21 operations");
    is($actual->{schedule_oracle}{source_map_count}, 39,
        "$level retains 39 ExecutionIR source maps");
    ok($actual->{structural_equivalence}{only_selected_source_deltas}
            && $actual->{structural_equivalence}{bridge_manifest_preserved}
            && $actual->{structural_equivalence}{execution_topology_preserved}
            && $actual->{structural_equivalence}{backend_inputs_preserved}
            && $actual->{structural_equivalence}{source_map_topology_preserved},
        "$level closes exact structural equivalence");
    is($actual->{emission_oracle}{artifact_count}, 17,
        "$level emits exactly 17 artifacts");
    is($actual->{emission_oracle}{artifact_bytes},
        $contract->{artifact_bytes}, "$level artifact bytes are exact");
    is($actual->{emission_oracle}{source_artifact_count}, 6,
        "$level emits exactly six VHDL sources");
    is($actual->{emission_oracle}{source_artifact_bytes},
        $contract->{vhdl_bytes}, "$level VHDL bytes are exact");
    is($actual->{emission_oracle}{source_map_entries}, 59,
        "$level emits exactly 59 source maps");
    is($actual->{emission_oracle}{static_check_count}, 21,
        "$level passes exactly 21 structural checks");
    is($actual->{emission_oracle}{fixture_bytes},
        $contract->{fixture_bytes}, "$level fixture bytes are exact");
    is($actual->{emission_oracle}{fixture_sha256},
        $contract->{fixture_sha}, "$level fixture identity is exact");
    ok($actual->{emission_oracle}{byte_equal_rerun},
        "$level emission is byte-identical");
    like($actual->{emission_oracle}{artifact_root},
        qr{\A[.]artifacts/vial/base-output-arbitration/[0-9a-f]{64}\z},
        "$level artifact root is repository-relative and content-addressed");
}

sub replace_once {
    my ($text_ref, $before, $after) = @_;
    my $count = () = $$text_ref =~ /\Q$before\E/g;
    is($count, 1, "source projection anchor '$before' is unique");
    $$text_ref =~ s/\Q$before\E/$after/;
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
