#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;
use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::BackendEmissionAuthority qw(
    backend_emission_profile_authorities
);

my $class =
    'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement';
my $producer = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @profiles = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
    sv_uvm_emit.accellera_2020_3_1
);
my @report_keys = qw(
    schema schema_version report_identity family backend_profile level
    primary_axis workload_identity mode requested_counts profile_authority
    controller_applicability measurement_applicability provider_verification
    canonical_evaluation validation_record measurement_records
    sample_exclusions outcome diagnostics cleanup explicit_nonclaims
);
my @nonclaims = (
    @{$foundation->explicit_nonclaims},
    qw(
        external_verification_tool compile_analyze_elaborate_run_trace_result
        backend_support backend_capacity reached_boundary
        provider_performance public_api_change
    ),
);

subtest 'profile authorities and report contracts are closed' => sub {
    is_deeply($class->report_keys, \@report_keys,
        'measurement report has one exact closed schema');
    is_deeply($class->explicit_nonclaims, \@nonclaims,
        'adapter closes external-tool, runtime, support, and capacity claims');
    my $authorities = $class->profile_authorities;
    is_deeply([sort keys %$authorities], [sort @profiles],
        'only the four completed structural profiles are admitted');
    my $selected = backend_emission_profile_authorities();
    for my $profile (@profiles) {
        my $authority = $authorities->{$profile};
        is_deeply($authority->{stage_order},
            [qw(construct parse_validate bridge bind_plan emit)],
            "$profile owns only the five structural stages");
        is_deeply($authority->{structural_authority}, $selected->{$profile},
            "$profile retains the shared structural authority");
        ok($authority->{structural_emission_only},
            "$profile is explicitly structural-emission-only");
        ok(!$authority->{external_verification_tool},
            "$profile is not reclassified as external verification");
        like($authority->{authority_identity},
            qr{\Abackend-emission-authority/[0-9a-f]{64}\z},
            "$profile authority is content-addressed");
    }
    $authorities->{sv_portable_verilator}{stage_order}[0] = 'forged';
    is($class->profile_authorities
        ->{sv_portable_verilator}{stage_order}[0], 'construct',
        'authority projections are defensive');
};

subtest 'construction is caller-sealed to repository anchors' => sub {
    for my $profile (@profiles) {
        my $construction = $class->construct({
            repository_root => $repo_root,
            backend_profile => $profile,
            level => 'reference_v1',
        });
        ok($construction->{ok}, "$profile reference constructs");
        is($construction->{specification}{family}, 'backend_emission_v1',
            "$profile cannot escape the structural family");
        is($construction->{specification}{primary_axis}, 'artifact_graph',
            "$profile cannot escape the structural axis");
        is_deeply([map { $_->{role} } @{$construction->{inputs}}],
            [qw(hial_source vial_source)],
            "$profile receives only the checked repository source pair");
    }
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            execution_ir => {},
        });
    }), qr/unknown key 'execution_ir'/,
        'caller-created ExecutionIR cannot enter the adapter');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_vial_text => 'forged',
        });
    }), qr/unknown key 'reference_vial_text'/,
        'caller-created source cannot enter the adapter');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            backend_profile => 'unknown_backend',
            level => 'reference_v1',
        });
    }), qr/profile is not selected/,
        'unknown profiles fail before construction');

    my $construction = $class->construct({
        repository_root => $repo_root,
        backend_profile => 'sv_portable_verilator',
        level => 'reference_v1',
    });
    like(dies(sub {
        $producer->_measurement_inputs({
            construction => $construction,
            stage => 'parse_validate',
        });
    }), qr/private to the exact adapter/,
        'canonical stage-product seam rejects direct callers');
};

subtest 'validation and measurement require the bounded real-run contract' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
        });
    }), qr/active repository RAM guard/,
        'structural validation cannot begin outside the real guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'gate_candidate_v1',
        });
    }), qr/active repository RAM guard/,
        'structural measurement cannot begin outside the real guard');
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => {},
        });
    }), qr/active repository RAM guard/,
        'independent regeneration cannot bypass the guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'limit_v1',
        });
    }), qr/only gate_candidate_v1 and qualification_candidate_v1/,
        'limit conformance cannot masquerade as a timing sample');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 89;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
        });
    }), qr/guard thresholds are invalid/,
        'over-wide host guard fails closed');
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4097;
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
        });
    }), qr/guard thresholds are invalid/,
        'over-wide descendant guard fails closed');
};

subtest 'guarded emitted and non-emitted routes retain exact evidence' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MEASUREMENT_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact adapter proof executes below the repository guard');

    my $reference = $class->validate_profile({
        repository_root => $repo_root,
        backend_profile => 'sv_portable_verilator',
        level => 'reference_v1',
    });
    is($reference->{outcome}, 'accepted_validation',
        'portable reference is complete correctness evidence');
    is_deeply($reference->{measurement_records}, [],
        'reference validation retains no timing samples');
    check_stage_statuses($reference->{validation_record}, {
        map { $_ => 'validated_unmeasured' }
            qw(construct parse_validate bridge bind_plan emit),
    });

    my $gate = $class->measure_profile({
        repository_root => $repo_root,
        backend_profile => 'sv_portable_verilator',
        level => 'gate_candidate_v1',
    });
    is($gate->{outcome}, 'accepted',
        'portable-SystemVerilog gate sample set is complete');
    is(scalar(@{$gate->{measurement_records}}), 3,
        'gate retains exactly three raw records');
    check_measured_records($gate);

    my $osvvm = $class->measure_profile({
        repository_root => $repo_root,
        backend_profile => 'vhdl_osvvm_qualified',
        level => 'qualification_candidate_v1',
    });
    is($osvvm->{outcome}, 'accepted',
        'OSVVM qualification sample set is complete');
    is(scalar(@{$osvvm->{measurement_records}}), 5,
        'qualification retains exactly five raw records');
    check_measured_records($osvvm);
    ok($osvvm->{provider_verification}{applicable}
            && $osvvm->{provider_verification}{included_in_emit}
            && $osvvm->{provider_verification}{read_only},
        'OSVVM provider verification is explicit and included in emit');
    ok(!$osvvm->{provider_verification}{external_verification_tool},
        'provider verification is not external tool execution');

    my $native_gate = $class->measure_profile({
        repository_root => $repo_root,
        backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
        level => 'gate_candidate_v1',
    });
    is($native_gate->{outcome}, 'validated_not_measured',
        'native-UVM adjacent negotiation rejection is never timed');
    ok(!$native_gate->{measurement_applicability}{applicable},
        'native-UVM rejection is measurement-inapplicable');
    is($native_gate->{measurement_applicability}{reason},
        'authoritative_non_emission',
        'native-UVM applicability names the authoritative reason');
    is_deeply($native_gate->{measurement_records}, [],
        'native-UVM rejection invents no sample');

    my $native_dominated = $class->validate_profile({
        repository_root => $repo_root,
        backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
        level => 'qualification_candidate_v1',
    });
    is($native_dominated->{canonical_evaluation}{observed_outcome},
        'preflight_dominated_not_constructed',
        'native-UVM larger shape retains preflight dominance');
    check_stage_statuses($native_dominated->{validation_record}, {
        construct => 'validated_unmeasured',
        parse_validate => 'not_run',
        bridge => 'not_run',
        bind_plan => 'not_run',
        emit => 'validated_unmeasured',
    });

    for my $report (
        $reference, $gate, $osvvm, $native_gate, $native_dominated,
    ) {
        is($json->encode($class->validate_report({
            repository_root => $repo_root,
            report => $report,
        })), $json->encode($report),
            'complete report independently regenerates exactly');
    }

    my $provider_mutation = clone($osvvm);
    $provider_mutation->{provider_verification}{included_in_emit} =
        JSON::PP::false;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $provider_mutation,
        });
    }), qr/provider verification classification changed/,
        'contradictory provider classification fails closed');

    my $missing_provider = clone($osvvm);
    delete $missing_provider->{provider_verification}{classification};
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $missing_provider,
        });
    }), qr/provider verification is missing key 'classification'/,
        'missing provider evidence fails at the closed schema');

    my $applicability_mutation = clone($native_gate);
    $applicability_mutation->{measurement_applicability}{applicable} =
        JSON::PP::true;
    $applicability_mutation->{measurement_applicability}{reason} = undef;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $applicability_mutation,
        });
    }), qr/measurement applicability changed/,
        'contradictory applicability fails independent regeneration');

    my $evaluation_mutation = clone($gate);
    $evaluation_mutation->{canonical_evaluation}{route_metrics}
        {operations_total}++;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $evaluation_mutation,
        });
    }), qr/canonical backend-emission evaluation changed/,
        'mutated canonical evaluation fails closed');
    my $defensive = $class->validate_report({
        repository_root => $repo_root,
        report => $reference,
    });
    $defensive->{canonical_evaluation}{observed_outcome} = 'forged';
    isnt($reference->{canonical_evaluation}{observed_outcome}, 'forged',
        'validated report data is returned defensively');
    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'all guarded sample sets leave no measurement staging');
};

subtest 'guarded stage failures remain explicit and clean' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MEASUREMENT_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MEASUREMENT_EXACT};
    my $original =
        \&FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::_stage_payload;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::_stage_payload = sub {
        my ($construction, $evaluation, $stage) = @_;
        die "forced bridge worker failure\n" if $stage eq 'bridge';
        return $original->($construction, $evaluation, $stage);
    };
    my $report = $class->validate_profile({
        repository_root => $repo_root,
        backend_profile => 'sv_portable_verilator',
        level => 'reference_v1',
    });
    is($report->{outcome}, 'rejected',
        'stage worker failure rejects the adapter report');
    is($report->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
        'adapter preserves the foundation failure family');
    is($report->{diagnostics}[0]{semantic_path},
        '/stage_measurements/bridge',
        'adapter preserves the exact failed stage');
    check_stage_statuses($report->{validation_record}, {
        construct => 'validated_unmeasured',
        parse_validate => 'validated_unmeasured',
        bridge => 'validation_rejected',
        bind_plan => 'not_run',
        emit => 'not_run',
    });
    ok($report->{cleanup}{ephemeral_removed}
            && !-e repo_path('.artifacts/tmp/vial-scale'),
        'failed worker removes exact staging');
};

done_testing;

sub check_measured_records {
    my ($report) = @_;
    is_deeply($report->{sample_exclusions}, [],
        'accepted sample set discards no raw record');
    ok($report->{measurement_applicability}{applicable},
        'accepted emission admits timing evidence');
    my %identity;
    for my $record (@{$report->{measurement_records}}) {
        ok($record->{resource_guard}{active},
            'raw record retains active guard evidence');
        ok(!$identity{$record->{measurement_identity}}++,
            'every raw record has one distinct complete identity');
        for my $stage (@{$record->{stage_measurements}}) {
            next unless grep { $_ eq $stage->{stage} }
                qw(construct parse_validate bridge bind_plan emit);
            is($stage->{status}, 'measured',
                "$stage->{stage} is measured independently");
            ok(defined($stage->{wall_time_ns}),
                "$stage->{stage} retains monotonic wall time");
            cmp_ok(scalar(@{$stage->{raw_samples}}), '>=', 1,
                "$stage->{stage} retains raw process-tree samples");
        }
        ok($record->{cleanup}{ephemeral_removed},
            'raw record removes its exact staging root');
    }
}

sub check_stage_statuses {
    my ($record, $expected) = @_;
    my %all = map { $_->{stage} => $_->{status} }
        @{$record->{stage_measurements}};
    my %actual = map { $_ => $all{$_} } sort keys %$expected;
    is_deeply(\%actual, $expected,
        'stage statuses preserve the authoritative structural route');
    for my $stage (@{$foundation->stage_order}) {
        next if exists $expected->{$stage};
        my $status = $stage eq 'cleanup'
            ? 'validated_unmeasured' : 'not_run';
        is($all{$stage}, $status,
            $stage eq 'cleanup'
                ? 'foundation cleanup remains explicitly successful'
                : "$stage remains outside structural emission");
    }
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
