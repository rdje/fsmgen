#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCalibrationDisposition;
use FSM::VIAL::ArchitectureScaleCapConsistency;

my $class = 'FSM::VIAL::ArchitectureScaleCalibrationDisposition';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'disposition is caller-sealed and retains every nonclaim' => sub {
    is_deeply($class->report_keys, [qw(
        schema schema_version disposition_identity cap_consistency
        selected_lineage legacy_lineage closure_publication drift
        vhdl_lineage_drift
        immutable_store measurement_disposition explicit_nonclaims
    )], 'disposition exposes one ordered closed schema');
    my $nonclaims = $class->explicit_nonclaims;
    for my $required (qw(
        promoted_performance_budget public_performance_budget
        cap_implementation architecture_capacity backend_support
        family_support
    )) {
        ok((grep { $_ eq $required } @{$nonclaims}),
            "disposition retains $required as an explicit nonclaim");
    }

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCalibrationDisposition::report_keys(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed invocants fail closed');
    like(dies(sub {
        $class->derive({
            repository_root => $repo_root,
            publication => {},
        });
    }), qr/unknown key 'publication'/,
        'callers cannot inject publication evidence');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->derive({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'revalidation cannot run outside the repository RAM guard');

    my $seal = $class->can('_require_complete_cap_consistency');
    my $consistency = FSM::VIAL::ArchitectureScaleCapConsistency->build;
    my $sealed = $seal->($consistency);
    is($sealed->{verified_dimension_count}, 161,
        'caller-sealed prerequisite independently counts every dimension');
    my $incomplete = clone($consistency);
    my ($group) = sort keys %{$incomplete->{groups}};
    my ($dimension) = @{$incomplete->{required_dimensions}};
    $incomplete->{groups}{$group}{dimensions}{$dimension}{status} =
        'pending_independent_verification';
    like(dies(sub { $seal->($incomplete) }),
        qr/is not verified/,
        'one incomplete cap dimension blocks calibration disposition');
};

subtest 'closure equality and three-way topology fail closed' => sub {
    my $same = $class->can('_require_same_closure');
    my $partition = $class->can('_partition_topology');
    ok(defined($same), 'exact closure comparator is test-visible');
    ok(defined($partition), 'exact topology partition is test-visible');

    my $closure = {
        schema => 'synthetic',
        profiles => [{identity => 'one'}],
    };
    ok($same->($closure, clone($closure)),
        'byte-equivalent canonical closures compare equal');
    my $changed = clone($closure);
    $changed->{profiles}[0]{identity} = 'changed';
    like(dies(sub { $same->($closure, $changed) }),
        qr/current calibration derivation disagrees/,
        'changed current derivation is rejected');

    my $selected = [
        evidence('store/current-a.json', 11, 'a'),
        evidence('store/current-b.json', 13, 'b'),
    ];
    my $legacy = [evidence('store/legacy.json', 17, 'c')];
    my $closure_files = [evidence('store/closure.json', 19, 'd')];
    my $store = [@{$selected}, @{$legacy}, @{$closure_files}];
    my $topology = $partition->({
        selected => $selected,
        legacy => $legacy,
        closure => $closure_files,
        store => $store,
    });
    is($topology->{file_count}, 4,
        'synthetic exact union retains every immutable file');
    is($topology->{bytes}, 60,
        'synthetic exact union retains exact bytes');
    is($topology->{status}, 'exact_partition',
        'three disjoint sets form one exact partition');

    my $overlap = clone($legacy);
    $overlap->[0]{relative_path} = 'store/current-a.json';
    like(dies(sub {
        $partition->({
            selected => $selected,
            legacy => $overlap,
            closure => $closure_files,
            store => $store,
        });
    }), qr/lineage sets overlap/,
        'cross-lineage overlap is rejected');

    my $extra = clone($store);
    push @{$extra}, evidence('store/extra.json', 23, 'e');
    like(dies(sub {
        $partition->({
            selected => $selected,
            legacy => $legacy,
            closure => $closure_files,
            store => $extra,
        });
    }), qr/do not exactly partition/,
        'one injected immutable-store path is rejected');
};

subtest 'guarded exact historical calibration disposition' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_CALIBRATION_DISPOSITION_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_CALIBRATION_DISPOSITION_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact disposition runs below the repository RAM guard');

    my $report = $class->derive({repository_root => $repo_root});
    is($report->{schema},
        'fsmgen.vial_architecture_scale_calibration_disposition.v1',
        'exact derivation returns the selected schema');
    is($report->{cap_consistency}{group_count}, 23,
        'all 23 cap groups are caller-sealed');
    is($report->{cap_consistency}{verified_dimension_count}, 161,
        'all 161 group dimensions remain verified');
    is($report->{selected_lineage}{status},
        'explicitly_versioned_historical',
        'atomic 232-file closure lineage is explicitly versioned');
    is($report->{selected_lineage}{current_revalidation},
        'rejected_expected_post_publication_drift',
        'selected lineage records the expected current-validation rejection');
    is($report->{selected_lineage}{file_count}, 232,
        'selected lineage retains its exact file count');
    is($report->{selected_lineage}{bytes}, 28_398_586,
        'selected lineage retains its exact byte count');
    is($report->{legacy_lineage}{status},
        'explicitly_versioned_superseded',
        'backend-emission v1 remains explicitly superseded');
    is($report->{legacy_lineage}{file_count}, 22,
        'legacy v1 lineage retains its exact file count');
    is($report->{legacy_lineage}{bytes}, 2_232_452,
        'legacy v1 lineage retains its exact byte count');
    is($report->{closure_publication}{file_count}, 2,
        'closure publication remains one exact two-file set');
    is($report->{closure_publication}{bytes}, 1_376_483,
        'closure publication retains its exact byte count');
    is($report->{immutable_store}{status}, 'exact_partition',
        'three lineage classes exactly partition the immutable store');
    is($report->{immutable_store}{file_count}, 256,
        'immutable store retains all 256 files');
    is($report->{immutable_store}{bytes}, 32_007_521,
        'immutable store retains exact aggregate bytes');
    is($report->{measurement_disposition}{evidence_role},
        'historical_measurement_only',
        'measurement evidence remains historical-only');
    is($report->{drift}{selected_profile_count}, 108,
        'current-validator census covers every semantic/bridge profile');
    is($report->{drift}{current_validator_match_count}, 102,
        'exactly 102 semantic/bridge profiles still match current code');
    is($report->{drift}{semantic_current_validator_match_count}, 56,
        'all 56 semantic profiles still match current code');
    is($report->{drift}{bridge_current_validator_match_count}, 46,
        'exactly 46 of 52 bridge profiles still match current code');
    is($report->{drift}{changed_profile_count}, 6,
        'six bridge profiles bind the intentional post-publication drift');
    is($report->{vhdl_lineage_drift}{backend_emission}
            {fixed_source_bytes_added}, 239,
        'two VHDL corrections bind their exact aggregate fixed-source delta');
    is($report->{vhdl_lineage_drift}{backend_emission}
            {source_map_entries_current}, 59,
        'VHDL source-map cardinality remains unchanged across the drift');
    isnt($report->{vhdl_lineage_drift}{portable_vhdl_runtime}
            {materialization_identity_historical},
        $report->{vhdl_lineage_drift}{portable_vhdl_runtime}
            {materialization_identity_current},
        'portable VHDL materialization identity is explicitly versioned');
    isnt($report->{vhdl_lineage_drift}{osvvm_runtime}
            {materialization_identity_historical},
        $report->{vhdl_lineage_drift}{osvvm_runtime}
            {materialization_identity_current},
        'OSVVM materialization identity is explicitly versioned');
    is($report->{measurement_disposition}{status},
        'superseded_after_expected_current_drift',
        'expected drift produces an explicit historical disposition');
    is($report->{measurement_disposition}{recapture_requirement},
        'required_before_current_performance_use',
        'recapture is required only before future current-performance use');
    is($report->{measurement_disposition}{cap_closeout_dependency}, 'none',
        'historical recapture is not a current cap-closeout dependency');

    my $assert = $class->can('_assert_report');
    ok($assert->($report), 'returned report passes its closed validator');
    my $mutated = clone($report);
    $mutated->{immutable_store}{file_count}++;
    like(dies(sub { $assert->($mutated) }),
        qr/disposition identity changed|immutable store census changed/,
        'caller-mutated disposition fails closed');
    my $drift_mutated = clone($report);
    $drift_mutated->{drift}{records}[0]{current_message} =
        'source_map count 65538 exceeds limit 65536';
    like(dies(sub { $assert->($drift_mutated) }),
        qr/calibration disposition drift record changed/,
        'one changed current-drift diagnostic fails closed');
    my $vhdl_mutated = clone($report);
    $vhdl_mutated->{vhdl_lineage_drift}{backend_emission}
        {fixed_source_bytes_added}++;
    like(dies(sub { $assert->($vhdl_mutated) }),
        qr/VHDL backend-emission drift changed/,
        'one changed VHDL lineage delta fails closed');
};

done_testing;

sub evidence {
    my ($relative_path, $bytes, $hex) = @_;
    return {
        relative_path => $relative_path,
        bytes => $bytes,
        sha256 => $hex x 64,
    };
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
