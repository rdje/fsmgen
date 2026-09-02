#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBalancedPortable;
use FSM::VIAL::ArchitectureScaleBalancedPortableEmission;
use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;
use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification;

my $class =
    'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement';
my $producer = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $emitter = 'FSM::VIAL::ArchitectureScaleBalancedPortableEmission';
my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $ownership = 'FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @report_keys = qw(
    schema schema_version report_identity family backend_profile level
    primary_axis workload_identity mode requested_counts member_authority
    controller_applicability measurement_applicability execution_applicability
    canonical_composition canonical_emission validation_record
    measurement_records sample_exclusions outcome diagnostics cleanup
    explicit_nonclaims
);
my @nonclaims = (
    @{$foundation->explicit_nonclaims},
    qw(
        external_verification_tool compile_analyze_elaborate_run_trace_result
        backend_support backend_capacity reached_boundary
        provider_performance public_api_change revision_1_public_bridge
    ),
);

subtest 'one producer-owned structural member has a closed contract' => sub {
    is_deeply($class->report_keys, \@report_keys,
        'measurement report has one exact closed schema');
    is_deeply($class->explicit_nonclaims, \@nonclaims,
        'adapter closes runtime, support, capacity, and public-bridge claims');
    my $authority = $class->member_authority;
    is_deeply(
        [@{$authority}{qw(family backend_profile level primary_axis)}],
        [qw(
            balanced_portable_v1 sv_portable_verilator
            gate_candidate_v1 interaction_profile
        )],
        'authority selects the sole balanced portable member');
    is_deeply($authority->{stage_order},
        [qw(construct parse_validate bridge bind_plan emit)],
        'authority owns only the five structural stages');
    ok($authority->{structural_emission_only},
        'member is explicitly structural-emission-only');
    ok($authority->{private_revision_2},
        'member retains the private revision-2 bridge');
    ok(!$authority->{external_execution_applicable},
        'member cannot borrow the public runtime route');
    like($authority->{authority_identity},
        qr{\Abalanced-portable-measurement-authority/[0-9a-f]{64}\z},
        'member authority is content-addressed');
    is_deeply(
        [grep { $_->{family} eq 'balanced_portable_v1' }
            @{$ownership->owned_shapes}],
        [{
            family => 'balanced_portable_v1',
            backend_profile => 'sv_portable_verilator',
            level => 'gate_candidate_v1',
        }],
        'authority agrees with the producer-owned qualification partition');
    $authority->{stage_order}[0] = 'forged';
    is($class->member_authority->{stage_order}[0], 'construct',
        'authority projection is defensive');
};

subtest 'construction is sealed to checked repository anchors' => sub {
    my $construction = $class->construct({repository_root => $repo_root});
    ok($construction->{ok}, 'balanced member constructs');
    is($construction->{workload}{specification}{family},
        'balanced_portable_v1', 'construction cannot escape the family');
    is($construction->{workload}{specification}{backend_profile},
        'sv_portable_verilator',
        'construction cannot escape the portable-SystemVerilog backend');
    is($construction->{workload}{specification}{level},
        'gate_candidate_v1', 'construction cannot escape the gate level');
    is_deeply(
        [map { $_->{role} } @{$construction->{workload}{inputs}}],
        [qw(hial_source vial_source)],
        'construction retains only the generated checked source pair');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            execution_ir => {},
        });
    }), qr/unknown key 'execution_ir'/,
        'caller-created ExecutionIR cannot enter the adapter');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            reference_vial_text => 'forged',
        });
    }), qr/unknown key 'reference_vial_text'/,
        'caller-created source cannot enter the adapter');
    like(dies(sub {
        $producer->_measurement_inputs({
            construction => $construction,
            stage => 'parse_validate',
        });
    }), qr/private to the exact adapter/,
        'canonical stage-product seam rejects direct callers');
    like(dies(sub {
        $emitter->_measurement_evaluate({
            construction => $construction,
            composition => {},
        });
    }), qr/private to the exact adapter/,
        'prevalidated structural-emission seam rejects direct callers');
};

subtest 'validation and measurement require the bounded real-run contract' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->validate_member({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'balanced validation cannot begin outside the real guard');
    like(dies(sub {
        $class->measure_member({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'balanced measurement cannot begin outside the real guard');
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => {},
        });
    }), qr/active repository RAM guard/,
        'independent regeneration cannot bypass the guard');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 89;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    like(dies(sub {
        $class->validate_member({repository_root => $repo_root});
    }), qr/guard thresholds are invalid/,
        'over-wide host guard fails closed');
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4097;
    like(dies(sub {
        $class->validate_member({repository_root => $repo_root});
    }), qr/guard thresholds are invalid/,
        'over-wide descendant guard fails closed');
};

subtest 'guarded member retains validation plus three raw records' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MEASUREMENT_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact adapter proof executes below the repository guard');

    my $report = $class->measure_member({repository_root => $repo_root});
    diag($json->encode($report->{diagnostics}))
        unless $report->{outcome} eq 'accepted';
    is($report->{outcome}, 'accepted',
        'balanced structural sample set is complete');
    is(scalar(@{$report->{measurement_records}}), 3,
        'gate measurement retains exactly three raw records');
    is_deeply($report->{sample_exclusions}, [],
        'accepted sample set excludes no raw record');
    ok($report->{measurement_applicability}{applicable},
        'structural measurement is applicable');
    ok(!$report->{execution_applicability}{applicable},
        'external execution remains inapplicable');
    is($report->{execution_applicability}{reason},
        'no_qualified_private_revision_2_runtime_route',
        'execution boundary names its exact authority gap');
    is($report->{canonical_emission}{artifact_oracle}{artifact_count}, 8,
        'canonical emission retains eight artifacts');
    is($report->{canonical_emission}{artifact_oracle}{source_artifact_count}, 3,
        'canonical emission retains three generated sources');
    is($report->{canonical_emission}{artifact_oracle}{source_bytes}, 503_279,
        'canonical emission retains exact generated source bytes');
    is($report->{canonical_emission}{artifact_oracle}{source_map_entries}, 3_605,
        'canonical emission retains exact source-map cardinality');
    is($report->{canonical_emission}{artifact_oracle}{mapped_binding_count},
        2_048, 'canonical emission retains exact binding cardinality');
    is($report->{canonical_emission}{artifact_oracle}{mapped_operation_count},
        1_024, 'canonical emission retains exact operation cardinality');
    check_record($report->{validation_record}, 'validated_unmeasured');
    check_record($_, 'measured') for @{$report->{measurement_records}};
    my $producer_evaluate = $producer->can('evaluate');
    my $public_emitter_evaluate = $emitter->can('evaluate');
    my $measurement_emitter_evaluate = $emitter->can('_measurement_evaluate');
    my ($producer_calls, $public_emitter_calls, $measurement_emitter_calls) =
        (0, 0, 0);
    my $validated;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleBalancedPortable::evaluate = sub {
            $producer_calls++;
            goto &$producer_evaluate;
        };
        local *FSM::VIAL::ArchitectureScaleBalancedPortableEmission::evaluate = sub {
            $public_emitter_calls++;
            goto &$public_emitter_evaluate;
        };
        local *FSM::VIAL::ArchitectureScaleBalancedPortableEmission::_measurement_evaluate = sub {
            $measurement_emitter_calls++;
            goto &$measurement_emitter_evaluate;
        };
        $validated = $class->validate_report({
            repository_root => $repo_root,
            report => $report,
        });
    }
    is($json->encode($validated), $json->encode($report),
        'complete report independently regenerates exactly');
    is($producer_calls, 1,
        'independent regeneration evaluates the six-gate composition once');
    is($public_emitter_calls, 0,
        'independent regeneration does not rebuild through public emission');
    is($measurement_emitter_calls, 1,
        'independent regeneration uses the exact-caller emission seam once');

    my $mutated = clone($report);
    $mutated->{canonical_emission}{artifact_oracle}{source_map_entries}++;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $mutated,
        });
    }), qr/canonical balanced emission changed/,
        'mutated emission evidence fails closed');
    my $applicability = clone($report);
    $applicability->{execution_applicability}{applicable} = JSON::PP::true;
    $applicability->{execution_applicability}{reason} = undef;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $applicability,
        });
    }), qr/execution applicability changed/,
        'forged external execution fails closed');
    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'complete sample set leaves no measurement staging');
};

subtest 'guarded stage failures remain explicit and clean' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MEASUREMENT_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MEASUREMENT_EXACT};
    my $original =
        \&FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::_stage_payload;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::_stage_payload = sub {
        my ($construction, $composition, $emission, $stage) = @_;
        die "forced bridge worker failure\n" if $stage eq 'bridge';
        return $original->($construction, $composition, $emission, $stage);
    };
    my $report = $class->validate_member({repository_root => $repo_root});
    is($report->{outcome}, 'rejected',
        'stage worker failure rejects the adapter report');
    is($report->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
        'adapter preserves the foundation failure family');
    is($report->{diagnostics}[0]{semantic_path},
        '/stage_measurements/bridge',
        'adapter preserves the exact failed stage');
    ok($report->{cleanup}{ephemeral_removed}
            && !-e repo_path('.artifacts/tmp/vial-scale'),
        'failed worker removes exact staging');
};

done_testing;

sub check_record {
    my ($record, $expected_status) = @_;
    my %stage = map { $_->{stage} => $_ }
        @{$record->{stage_measurements}};
    for my $name (qw(construct parse_validate bridge bind_plan emit)) {
        is($stage{$name}{status}, $expected_status,
            "$name retains its exact measurement classification");
        if ($expected_status eq 'measured') {
            ok(defined($stage{$name}{wall_time_ns}),
                "$name retains monotonic wall time");
            cmp_ok(scalar(@{$stage{$name}{raw_samples}}), '>=', 1,
                "$name retains raw process-tree samples");
        }
    }
    for my $name (qw(
        compile_analyze elaborate run trace_validate result_produce publish
    )) {
        is($stage{$name}{status}, 'not_run',
            "$name remains explicitly inapplicable");
        is($stage{$name}{not_run_reason}, 'not_applicable_to_invocation',
            "$name retains the structural-only reason");
    }
    is($stage{cleanup}{status}, $expected_status,
        'foundation cleanup retains the run classification');
    ok($record->{cleanup}{ephemeral_removed},
        'record removes its exact staging root');
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
