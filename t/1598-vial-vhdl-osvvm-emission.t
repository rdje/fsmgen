#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Backend::VHDLOSVVMStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $json = JSON::PP->new->canonical(1);
my $pretty_json = JSON::PP->new->canonical(1)->pretty(1);
my $dependency_root = '.artifacts/cache/providers/osvvm/2026.05/source';
my $gallery_rel =
    'vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services';
my @requirements = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my $built = build_plan();
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches OSVVM backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};

my $materialization =
    FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
        dependency_root => $dependency_root,
    });
ok($materialization->{ok}, 'exact recursive OSVVM 2026.05 materialization verifies');
diag($json->encode($materialization->{diagnostics})) unless $materialization->{ok};

subtest 'provider graph, gitlinks, licences, notices, and missing metadata are exact' => sub {
    my $manifest = $materialization->{manifest};
    is_deeply(
        [sort keys %$manifest],
        [sort @{FSM::VIAL::Backend::OSVVM2026_05Materialization->manifest_keys}],
        'materialization manifest is closed',
    );
    is($manifest->{version}, '2026.05', 'provider version is exact');
    is($manifest->{root_commit},
        '2f7c391051dfb11890fa4bdbda9918d1db492250',
        'release tag resolves to the selected exact root commit');
    is($manifest->{root_tree},
        'bd4fdc594f2c26d564cf8907ff599578b9a39e22',
        'root content tree identity is exact');
    is(scalar(@{$manifest->{repositories}}), 14,
        'superproject plus thirteen submodule repositories are verified');
    is(scalar(@{$manifest->{recursive_gitlinks}}), 13,
        'all thirteen recursive gitlinks are verified');
    ok(!scalar(grep { !$_->{clean} } @{$manifest->{repositories}}),
        'all exact provider worktrees are clean');
    is(scalar(@{$manifest->{license_notice_files}}), 14,
        'all fourteen tracked licence files are identity locked');
    is($manifest->{license_notice_summary}{notice_file_count}, 0,
        'the selected release contains no tracked notice file');
    is_deeply(
        $manifest->{license_notice_summary}
            {repositories_without_tracked_license_or_notice},
        ['Documentation'],
        'the exact Documentation metadata absence is explicit',
    );
    ok(!$manifest->{license_notice_summary}{inferred_license_coverage},
        'no licence coverage is inferred for the Documentation repository');
    is($manifest->{materialization}{state}, 'complete_recursive_verified',
        'materialization state is complete and recursively verified');
    ok($manifest->{materialization}{same_volume_repository_local},
        'provider data is explicitly repository-local and same-volume');
    ok(!$manifest->{materialization}{network_fetch_during_emission},
        'ordinary adapter emission performs no network fetch');

    my $bad_root = FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
        dependency_root => '../outside',
    });
    ok(!$bad_root->{ok}, 'off-contract dependency root fails closed');
    is($bad_root->{diagnostics}[0]{code},
        'OSVVM_MATERIALIZATION_VERIFICATION_ERROR',
        'off-contract dependency root has the exact diagnostic family');

    my $unknown = FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
        dependency_root => $dependency_root,
        invented => 1,
    });
    ok(!$unknown->{ok}, 'unknown materialization input fails closed');
};

my $emission = emit_backend();
ok($emission->{ok}, 'exact OSVVM adapter/gallery emission succeeds');
diag($json->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'advanced negotiation and profile claims are exact and bounded' => sub {
    is_deeply(
        [sort keys %$emission],
        [sort @{FSM::VIAL::Backend::VHDLOSVVM2026_05->result_keys}],
        'backend result is closed',
    );
    is($emission->{status}, 'emitted_structurally_reviewed_unqualified',
        'status separates emission/static review from qualification');
    is_deeply($emission->{negotiation}{required}, \@requirements,
        'seven exact advanced requirements are negotiated');
    is_deeply($emission->{negotiation}{satisfied}, \@requirements,
        'all seven selected requirements have emitted mappings');
    is_deeply($emission->{negotiation}{unsatisfied}, [],
        'canonical advanced profile has no unsatisfied mapping');
    is($emission->{negotiation}{semantic_authority},
        'portable_vhdl_execution_and_result_oracles',
        'portable execution/results remain semantic authority');

    my $manifest = $emission->{backend_manifest};
    is($manifest->{schema}, 'fsmgen.vial_backend.vhdl_osvvm.v1',
        'advanced backend schema is exact');
    is($manifest->{emitter_revision}, 1, 'advanced emitter revision is exact');
    is($manifest->{profile_state}{materialization},
        'complete_recursive_verified', 'profile records complete provider graph');
    is($manifest->{profile_state}{qualification},
        'not_run_separate_leaf_15_7', 'combined qualification remains separate');
    is($manifest->{capability_evidence}{analysis}, 'not_run',
        'provider presence is not analysis evidence');
    is($manifest->{capability_evidence}{runtime}, 'not_run',
        'provider presence is not runtime evidence');
    is($manifest->{capability_evidence}{result}, 'not_produced',
        'provider emission produces no normalized runtime result');
    is($manifest->{capability_evidence}{product_support}, 'not_claimed',
        'provider emission makes no product-support claim');

    my $contract = build_capability_manifest()->{language_surface}{vial_vhdl_emission};
    is($contract->{methodology_identity}{advanced_provider_status},
        'exact_recursive_materialization_adapter_emitted_structurally_reviewed_unqualified',
        'support discovery reports the exact bounded advanced-provider state');
    is($contract->{library_materialization}{root_commit},
        '2f7c391051dfb11890fa4bdbda9918d1db492250',
        'support discovery reports the exact provider root commit');
    is($contract->{limits}{osvvm_recursive_gitlinks}, 13,
        'support discovery reports all recursive gitlinks');
    is($contract->{limits}{osvvm_advanced_mappings}, 7,
        'support discovery reports the exact advanced mapping count');
    is($contract->{backend_stage_status}{osvvm_combined_qualification},
        'not_run_separate_profile',
        'support discovery does not promote structural evidence to qualification');
};

subtest 'adapter maps seven provider families without changing portable semantics' => sub {
    my $matrix = $emission->{mapping_matrix};
    is($matrix->{schema}, 'fsmgen.vial_vhdl_osvvm_mapping_matrix.v1',
        'advanced mapping-matrix schema is exact');
    is(scalar(@{$matrix->{mappings}}), 7,
        'mapping matrix contains seven exact advanced families');
    my @mapping_id = map { $_->{mapping_id} } @{$matrix->{mappings}};
    is_deeply(\@mapping_id, \@requirements,
        'advanced mapping identities are sorted and complete');
    for my $mapping (@{$matrix->{mappings}}) {
        is($mapping->{emission_status}, 'emitted',
            "mapping '$mapping->{mapping_id}' is emitted");
        is($mapping->{static_status}, 'passed',
            "mapping '$mapping->{mapping_id}' passes structural checks");
        is($mapping->{qualification_status}, 'not_run',
            "mapping '$mapping->{mapping_id}' remains unqualified");
        ok(length($mapping->{semantic_guard}),
            "mapping '$mapping->{mapping_id}' carries an exact semantic guard");
    }

    my $preservation = $emission->{semantic_preservation};
    is(scalar(@{$preservation->{portable_sources}}), 6,
        'semantic-preservation proof covers all six portable VHDL sources');
    for my $source (@{$preservation->{portable_sources}}) {
        ok($source->{byte_identical},
            "portable source '$source->{role}' remains byte-identical");
        is($source->{advanced_sha256}, $source->{portable_sha256},
            "portable source '$source->{role}' digest remains identical");
    }
    ok($preservation->{guards}{portable_random_replay_unchanged},
        'portable random replay remains unchanged');
    ok($preservation->{guards}{phase_order_unchanged},
        'drive/sample/react/check phase order remains unchanged');
    ok($preservation->{guards}{comparison_semantics_unchanged},
        'portable comparison meaning remains unchanged');
    ok($preservation->{guards}{coverage_semantics_unchanged},
        'portable coverage meaning remains unchanged');
    ok($preservation->{guards}{closed_trace_unchanged},
        'closed trace remains unchanged');
    ok($preservation->{guards}{normalized_result_unchanged},
        'normalized result remains unchanged');

    my $adapter = artifact('vhdl_osvvm_adapter_package');
    like($adapter->{content}, qr/library osvvm;/,
        'adapter imports the exact provider library');
    like($adapter->{content}, qr/library osvvm_common;/,
        'adapter imports the exact common verification-component library');
    like($adapter->{content}, qr/osvvm\.RandomPkg\.RandomPType/,
        'adapter exposes isolated native randomization');
    like($adapter->{content}, qr/osvvm\.CoveragePkg\.ICover/,
        'adapter exposes supplementary provider coverage');
    like($adapter->{content}, qr/osvvm\.ScoreboardGenericPkg/,
        'adapter identifies the exact generic-scoreboard basis');
    like($adapter->{content}, qr/osvvm\.AlertLogPkg\.AffirmIf/,
        'adapter exposes supplementary provider reporting');
    like($adapter->{content}, qr/osvvm\.TbUtilPkg\.WaitForBarrier/,
        'adapter exposes bounded component coordination');
    like($adapter->{content}, qr/osvvm\.MemoryPkg\.MemWrite/,
        'adapter exposes negotiated provider memory');
    like($adapter->{content},
        qr/osvvm_common\.AddressBusTransactionPkg\.AddressBusRecType/,
        'adapter exposes the exact MIT address-bus transaction type');
};

subtest 'artifact graph, source map, static checks, and gallery bytes are exact' => sub {
    is(scalar(@{$emission->{artifacts}}), 15,
        'advanced graph contains seven VHDL and eight evidence artifacts');
    is(scalar(grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}}), 7,
        'advanced graph contains six portable sources plus one adapter');
    is(scalar(@{$emission->{source_map}{entries}}), 13,
        'source map covers seven mappings and six portable sources');
    is(scalar(@{$emission->{static_validation}{checks}}), 12,
        'static validator records twelve exact checks');
    is($emission->{static_validation}{status}, 'passed_structural_only',
        'static status remains explicitly structural');

    for my $artifact (@{$emission->{artifacts}}) {
        my $tail = $artifact->{relpath};
        $tail =~ s{\Abackends/vhdl_osvvm_qualified/}{} or
            die "artifact is outside the advanced backend root: $tail\n";
        is($artifact->{content}, slurp_raw(repo_path(
            (split m{/}, $gallery_rel), split m{/}, $tail)),
            "gallery artifact '$tail' is byte-identical to fresh emission");
        is($artifact->{sha256}, sha256_hex($artifact->{content}),
            "artifact '$tail' digest covers exact bytes");
    }

    open my $check_fh, '-|', $^X,
        'scripts/refresh_vial_vhdl_osvvm_gallery.pl', '--check'
        or die "cannot start OSVVM gallery check: $!\n";
    local $/;
    my $check_output = <$check_fh> // '';
    close $check_fh;
    is($? >> 8, 0, 'non-mutating OSVVM gallery check succeeds');
    is($check_output,
        "OSVVM 2026.05 VHDL gallery current: 7 VHDL sources; 8 evidence artifacts; 7 advanced mappings; 13 source-map entries; 12 static checks\n",
        'gallery check reports the exact closed graph');

    is(artifact('provider_materialization')->{content},
        $pretty_json->encode($emission->{provider_materialization}),
        'provider evidence is canonical pretty JSON');
    is(artifact('advanced_mapping_matrix')->{content},
        $pretty_json->encode($emission->{mapping_matrix}),
        'mapping evidence is canonical pretty JSON');
    is(artifact('semantic_preservation')->{content},
        $pretty_json->encode($emission->{semantic_preservation}),
        'semantic-preservation evidence is canonical pretty JSON');
};

subtest 'provider and semantic mutations fail closed' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}};
    my $base = {
        artifacts => \@source,
        materialization => clone($emission->{provider_materialization}),
        mapping_matrix => clone($emission->{mapping_matrix}),
        semantic_preservation => clone($emission->{semantic_preservation}),
    };
    my $valid = FSM::VIAL::Backend::VHDLOSVVMStaticValidator->validate(clone($base));
    ok($valid->{ok}, 'direct static validator accepts the canonical graph');
    is_deeply([sort keys %$valid],
        [sort @{FSM::VIAL::Backend::VHDLOSVVMStaticValidator->result_keys}],
        'direct static-validator result is closed');

    my $provider_drift = clone($base);
    $provider_drift->{materialization}{root_commit} = '0' x 40;
    static_failure($provider_drift, 'VIAL_OSVVM_STATIC_PROVIDER_IDENTITY_ERROR',
        'provider commit substitution');

    my $license_inference = clone($base);
    $license_inference->{materialization}{license_notice_summary}
        {inferred_license_coverage} = JSON::PP::true;
    static_failure($license_inference, 'VIAL_OSVVM_STATIC_PROVIDER_LICENCE_ERROR',
        'invented Documentation licence coverage');

    my $random_api = clone($base);
    adapter_in($random_api)->{content} =~ s/\.Uniform\(minimum, maximum\)/.NextInt(minimum, maximum)/;
    static_failure($random_api, 'VIAL_OSVVM_STATIC_MAPPING_ERROR',
        'native random API substitution');

    my $qualification = clone($base);
    $qualification->{mapping_matrix}{mappings}[0]{qualification_status} = 'passed';
    static_failure($qualification, 'VIAL_OSVVM_STATIC_MAPPING_MATRIX_ERROR',
        'invented provider qualification');

    my $phase_guard = clone($base);
    $phase_guard->{semantic_preservation}{guards}{phase_order_unchanged} =
        JSON::PP::false;
    static_failure($phase_guard, 'VIAL_OSVVM_STATIC_SEMANTIC_PRESERVATION_ERROR',
        'removed phase-order guard');

    my $provider_leak = clone($base);
    my ($portable) = grep { $_->{role} =~ /\Aportable_/ }
        @{$provider_leak->{artifacts}};
    $portable->{content} .= "-- osvvm provider leakage\n";
    static_failure($provider_leak, 'VIAL_OSVVM_STATIC_SEMANTIC_PRESERVATION_ERROR',
        'provider API leakage into portable source');
};

subtest 'backend invocation rejects incomplete or substituted profiles' => sub {
    my $missing = backend_args();
    pop @{$missing->{advanced_requirements}};
    backend_failure($missing, qr/seven unique sorted exact requirements/,
        'incomplete advanced requirement set');

    my $profile = backend_args();
    $profile->{backend_profile} = 'vhdl_osvvm_qualified.other';
    backend_failure($profile, qr/backend_profile must be 'vhdl_osvvm_qualified'/,
        'substituted profile');

    my $root = backend_args();
    $root->{dependency_root} = '../outside';
    backend_failure($root, qr/exact repository-local OSVVM 2026.05 root/,
        'traversing dependency root');

    my $unknown = backend_args();
    $unknown->{invented} = 1;
    backend_failure($unknown, qr/key set is not closed/,
        'unknown backend input');
};

done_testing;

sub build_plan {
    my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
    my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub backend_args {
    return {
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/gallery/vial-vhdl-osvvm-advanced-services',
        backend_profile => 'vhdl_osvvm_qualified',
        dependency_root => $dependency_root,
        advanced_requirements => [@requirements],
    };
}

sub emit_backend {
    return FSM::VIAL::Backend::VHDLOSVVM2026_05->emit(backend_args());
}

sub artifact {
    my ($role) = @_;
    my @artifact = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub adapter_in {
    my ($args) = @_;
    my @adapter = grep { $_->{role} eq 'vhdl_osvvm_adapter_package' }
        @{$args->{artifacts}};
    die "adapter is not unique\n" unless @adapter == 1;
    return $adapter[0];
}

sub static_failure {
    my ($args, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::VHDLOSVVMStaticValidator->validate($args);
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code}, $code,
        "$label has the exact diagnostic code");
}

sub backend_failure {
    my ($args, $message_re, $label) = @_;
    my $result = FSM::VIAL::Backend::VHDLOSVVM2026_05->emit($args);
    ok(!$result->{ok}, "$label fails closed");
    like($result->{diagnostics}[0]{message}, $message_re,
        "$label retains an actionable diagnostic");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if ref($value) eq 'JSON::PP::Boolean';
    return {map { $_ => clone($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
