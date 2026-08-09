package FSM::VIAL::Backend::VHDLPortableReviewClosure;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $BACKEND_PROFILE = 'vhdl_portable_ghdl';
my $MATRIX_SCHEMA = 'fsmgen.vial_vhdl_selected_mapping_matrix.v1';
my $WORKFLOW_SCHEMA = 'fsmgen.vial_vhdl_review_workflow.v1';
my $MIGRATION_SCHEMA = 'fsmgen.vial_vhdl_migration_proof.v1';
my $LEGACY_PACKAGE_SHA256 =
    '8d587b8dde4b7659290af6720ed4812079f36479d577dd5a0cf787bef2a22d4f';
my $LEGACY_MANIFEST_PROJECTION_SHA256 =
    '29789c0b4b7400de45eec2ac1f62178d2e555f9c3d64ad871a1d87c5d39c5835';

my @RESULT_KEYS = qw(
    ok status backend_profile mapping_matrix review_workflow migration_proof
    checks diagnostics
);
my @MAPPING_KEYS = qw(
    mapping_id foundation_id intent_owner normal_source terse_source typed_ir
    generated_roles vhdl_realization emission_status static_review_status
    visual_review_status qualification_status unsupported_reason
);
my @STAGE_KEYS = qw(stage_id status authority command evidence);

my @MAPPING_DEFINITION = (
    _definition('typed_four_state_values', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(vhdl_types_package)],
        'provider-free VIAL 0/1/X/Z symbols and strong std_logic conversion'),
    _definition('original_symbol_sampling', 'compiler_owned_from_public_vial',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir', [qw(vhdl_types_package vhdl_fixture_top)],
        'stable-barrier sampling with normalized value and original std_logic evidence'),
    _definition('typed_logical_time', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(vhdl_runtime_package)],
        'typed domain, cycle, phase, and operation-rank records'),
    _definition('fixture_metadata', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(vhdl_fixture_metadata)],
        'immutable fixture, operation, scenario, fiber, model, and rank metadata'),
    _definition('hial_dut_binding', 'compiler_owned_from_hial_bridge',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_bridge_manifest',
        [qw(generated_hial_vhdl_dut vhdl_fixture_top)],
        'byte-identical generated HIAL VHDL plus direct entity binding'),
    _definition('public_port_binding', 'compiler_owned_from_hial_bridge',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_bridge_manifest', [qw(vhdl_fixture_top)],
        'named port associations proved by the HIAL/VIAL bridge manifest'),
    _definition('typed_drivers', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_types_package vhdl_fixture_top)],
        'typed scalar/vector drive procedures and statically lowered drive operations'),
    _definition('inactive_edge_scheduler', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir',
        [qw(vhdl_fixture_metadata vhdl_fixture_top)],
        'one inactive-edge SAMPLE/REACT/CHECK/DRIVE semantic scheduler'),
    _definition('scenario_fibers', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_fixture_metadata vhdl_runtime_package vhdl_fixture_top)],
        'bounded scenario/fiber state with exact completion, timeout, and cancellation'),
    _definition('deterministic_models', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_fixture_metadata vhdl_fixture_top)],
        'bounded deterministic event-counter model updates'),
    _definition('plan_time_random_replay', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_fixture_metadata vhdl_fixture_top)],
        'immutable replay of compiler-resolved keyed random decisions'),
    _definition('exact_rank_execution', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir',
        [qw(vhdl_fixture_metadata vhdl_fixture_top)],
        'statically lowered operations in exact ExecutionIR rank order'),
    _definition('bounded_scoreboard', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'capacity-four expected queue and typed in-order comparison'),
    _definition('coverage_counters', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'exact generated counters for the selected VIAL bins'),
    _definition('substitution_faults', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'one-drive-interval substitution seam preserving authored source values'),
    _definition('procedural_properties', 'public_vial_v1_translation',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'bounded procedural success, error, timeout, and unknown checks'),
    _definition('structured_diagnostics', 'compiler_owned_from_public_vial',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'bounded typed diagnostic storage and aggregate severity/outcome counts'),
    _definition('closed_trace_projection', 'compiler_owned_from_public_vial',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'logical-time header/body/footer JSONL projection with explicit closure'),
    _definition('normalized_result_projection', 'compiler_owned_from_public_vial',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir',
        [qw(vhdl_runtime_package vhdl_fixture_top)],
        'full fsmgen.verification_result_manifest.v1 projection without production claim'),
    _definition('declared_probe_adapter', 'compiler_owned_from_hial_bridge',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_bridge_manifest',
        [qw(vhdl_probe_adapter vhdl_fixture_top)],
        'isolated VHDL-2008 external-name adapter for one declared HIAL probe'),
    _definition('osvvm_native_services', 'private_preview_not_selected',
        'not_available_private_preview', 'not_available_private_preview',
        'private_typed_preview_not_selected', [],
        'not emitted by the provider-free profile',
        'OSVVM-native randomization, coverage, scoreboard, and verification-component services belong to separately owned profile vhdl_osvvm_qualified'),
    _definition('psl_properties', 'excluded_portable_boundary',
        'unsupported_in_portable_profile', 'unsupported_in_portable_profile',
        'not_represented_unsupported', [],
        'not emitted by the provider-free profile',
        'portable properties lower procedurally; PSL syntax and tool flags are not selected or claimed'),
    _definition('distinct_nine_state_semantics', 'excluded_portable_boundary',
        'unsupported_in_portable_profile', 'unsupported_in_portable_profile',
        'not_represented_unsupported', [],
        'not emitted by the provider-free profile',
        'VIAL version 1 normalizes std_logic meta-values to four states and does not preserve nine distinct semantic states'),
    _definition('multiple_clock_or_async_semantics', 'excluded_portable_boundary',
        'unsupported_in_portable_profile', 'unsupported_in_portable_profile',
        'not_represented_unsupported', [],
        'not emitted by the provider-free profile',
        'the selected execution profile owns exactly one clock domain and rejects asynchronous semantic events'),
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub mapping_keys($class) {
    confess __PACKAGE__ . "->mapping_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@MAPPING_KEYS];
}

sub stage_keys($class) {
    confess __PACKAGE__ . "->stage_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@STAGE_KEYS];
}

sub build($class, @args) {
    return _failure('VIAL_VHDL_REVIEW_INVOCATION_ERROR',
        'build requires the exact review-closure class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_VHDL_REVIEW_INVOCATION_ERROR',
        'build expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _build($args[0]) };
    return $result if defined $result;
    return _failure('VIAL_VHDL_REVIEW_HOST_ERROR', _sanitize_exception($@), '/');
}

sub _build($raw) {
    _require_exact_keys($raw, [qw(
        plan_id fixture_id emitter_revision source_artifacts review_gallery
        hial_source_identity
    )], 'portable VHDL review closure');
    confess 'plan_id is malformed'
        unless defined($raw->{plan_id}) && !ref($raw->{plan_id})
            && $raw->{plan_id} =~ m{\Aplan/[0-9a-f]{64}\z};
    confess 'fixture_id is malformed'
        unless defined($raw->{fixture_id}) && !ref($raw->{fixture_id})
            && length($raw->{fixture_id});
    confess 'emitter_revision must be 5'
        unless defined($raw->{emitter_revision}) && !ref($raw->{emitter_revision})
            && $raw->{emitter_revision} == 5;
    confess 'source_artifacts must be a non-empty array'
        unless ref($raw->{source_artifacts}) eq 'ARRAY' && @{$raw->{source_artifacts}};
    confess 'review_gallery must be a safe repository-relative path'
        unless _safe_relpath($raw->{review_gallery});
    _require_exact_keys($raw->{hial_source_identity}, [qw(
        source_id content_sha256 byte_length emitted_relpath
    )], 'HIAL source identity');

    my (%role_count, %relpath_count, %artifact_by_role);
    for my $artifact (@{$raw->{source_artifacts}}) {
        confess 'source artifact must be one unblessed hash'
            unless ref($artifact) eq 'HASH' && !blessed($artifact);
        confess 'source artifact role or relpath is malformed'
            unless defined($artifact->{role}) && !ref($artifact->{role})
                && _safe_relpath($artifact->{relpath});
        $role_count{$artifact->{role}}++;
        $relpath_count{$artifact->{relpath}}++;
        $artifact_by_role{$artifact->{role}} = $artifact;
    }

    my %selected_role = map { $_ => 1 }
        map { @{$_->{generated_roles}} } @MAPPING_DEFINITION;
    my @unknown_role = sort grep { !$selected_role{$_} } keys %role_count;
    confess "source artifact role '$unknown_role[0]' is outside the selected matrix"
        if @unknown_role;
    for my $role (sort keys %selected_role) {
        confess "selected source artifact role '$role' must occur exactly once"
            unless ($role_count{$role} // 0) == 1;
    }
    my @duplicate_relpath = sort grep { $relpath_count{$_} != 1 }
        keys %relpath_count;
    confess "source artifact relpath '$duplicate_relpath[0]' is duplicated"
        if @duplicate_relpath;

    my @mappings;
    my %foundation;
    for my $definition (@MAPPING_DEFINITION) {
        confess "duplicate mapping foundation '$definition->{foundation_id}'"
            if $foundation{$definition->{foundation_id}}++;
        for my $role (@{$definition->{generated_roles}}) {
            confess "mapping '$definition->{foundation_id}' lacks exact source role '$role'"
                unless ($role_count{$role} // 0) == 1;
        }
        my $emitted = @{$definition->{generated_roles}} ? 1 : 0;
        push @mappings, {
            mapping_id => 'mapping/' . ($definition->{foundation_id} =~ s/_/-/gr),
            foundation_id => $definition->{foundation_id},
            intent_owner => $definition->{intent_owner},
            normal_source => $definition->{normal_source},
            terse_source => $definition->{terse_source},
            typed_ir => $definition->{typed_ir},
            generated_roles => [@{$definition->{generated_roles}}],
            vhdl_realization => $definition->{vhdl_realization},
            emission_status => $emitted ? 'emitted' : 'not_emitted_unsupported',
            static_review_status => $emitted
                ? 'passed_structural_only' : 'not_applicable_unsupported',
            visual_review_status => $emitted ? 'pending' : 'not_applicable_unsupported',
            qualification_status => $emitted ? 'not_run' : 'not_applicable_unsupported',
            unsupported_reason => $definition->{unsupported_reason},
        };
    }
    @mappings = sort { $a->{mapping_id} cmp $b->{mapping_id} } @mappings;

    my @emitted_foundations = sort map { $_->{foundation_id} }
        grep { $_->{emission_status} eq 'emitted' } @mappings;
    my @unsupported_foundations = sort map { $_->{foundation_id} }
        grep { $_->{emission_status} eq 'not_emitted_unsupported' } @mappings;
    my @examples = map {
        my $artifact = $artifact_by_role{$_};
        {
            role => $_,
            emitted_relpath => $artifact->{relpath},
            gallery_relpath => $raw->{review_gallery} . '/'
                . substr($artifact->{relpath}, length('backends/vhdl_portable_ghdl/')),
        }
    } sort keys %artifact_by_role;

    my $mapping_matrix = {
        schema => $MATRIX_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        emitter_revision => $raw->{emitter_revision},
        plan_id => $raw->{plan_id},
        fixture_id => $raw->{fixture_id},
        scope => 'complete_selected_provider_free_vhdl_matrix_with_exact_rejected_boundaries',
        coverage_rule => 'every selected portable responsibility has emitted role evidence or one exact unsupported reason',
        entrypoint_legend => {
            normal_source => 'normal public VIAL projection, derived compiler-owned intent, unavailable private preview, or exact unsupported boundary',
            terse_source => 'terse public VIAL projection, derived compiler-owned intent, unavailable private preview, or exact unsupported boundary',
            typed_ir => 'public ExecutionIR, compiler-owned ExecutionIR/bridge data, an explicitly unavailable private preview, or an unsupported boundary',
        },
        emitted_foundations => \@emitted_foundations,
        unsupported_foundations => \@unsupported_foundations,
        mappings => \@mappings,
        profile_state => {
            emission => 'emitted',
            static_review => 'reviewed_structurally',
            visual_review => 'pending',
            qualification => 'unqualified_not_run',
        },
        excluded_qualification => [qw(
            vhdl_analysis elaboration runtime produced_result parity
            complete_vhdl_2008 psl osvvm product_support
        )],
    };

    my $regenerate = 'perl scripts/refresh_vial_vhdl_portable_gallery.pl';
    my $check = 'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check';
    my $review_workflow = {
        schema => $WORKFLOW_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        emitter_revision => $raw->{emitter_revision},
        plan_id => $raw->{plan_id},
        fixture_id => $raw->{fixture_id},
        gallery_root => $raw->{review_gallery},
        regenerate_command => $regenerate,
        check_command => $check,
        examples => \@examples,
        evidence_examples => [
            $raw->{review_gallery} . '/evidence/selected-mapping-matrix.json',
            $raw->{review_gallery} . '/evidence/review-workflow.json',
            $raw->{review_gallery} . '/evidence/migration-proof.json',
        ],
        stages => [
            _stage('regenerate', 'ready', 'emitter', $regenerate,
                'refresh the exact source and evidence graph'),
            _stage('byte_compare', 'ready', 'gallery_check', $check,
                'reject missing, extra, or byte-drifted gallery snapshots'),
            _stage('static_shape', 'passed_structural_only', 'static_validator', undef,
                'twenty deterministic provider-free source-shape checks'),
            _stage('visual_review', 'pending', 'director_or_delegate', undef,
                'readability, intent fidelity, and VHDL engineering judgment'),
            _stage('defect_capture', 'ready', 'task_tree', undef,
                'record exact artifact, symbol, source-map ID, severity, and reproduction'),
            _stage('migration_separation', 'passed_regression_contract',
                'legacy_and_hial_regressions', undef,
                'exact inert legacy bytes/schema and byte-identical isolated HIAL DUT'),
            _stage('qualified_runtime', 'not_run', 'future_exact_tool_profile', undef,
                'separate analysis-through-parity qualification under task .15.5'),
        ],
        defect_routing => {
            task_tree => 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md',
            required_fields => [qw(
                artifact_relpath generated_symbol source_map_id observation
                severity reproduction expected_intent disposition
            )],
            conversation_only_is_durable => JSON::PP::false,
        },
        nonclaims => [qw(
            visual_review_complete vhdl_analysis elaboration runtime
            produced_result parity complete_vhdl_2008 psl osvvm product_support
        )],
    };

    my $hial = $artifact_by_role{generated_hial_vhdl_dut};
    confess 'HIAL source identity source_id is malformed'
        unless defined($raw->{hial_source_identity}{source_id})
            && !ref($raw->{hial_source_identity}{source_id})
            && length($raw->{hial_source_identity}{source_id});
    confess 'HIAL source identity digest is malformed'
        unless ($raw->{hial_source_identity}{content_sha256} // '')
            =~ /\A[0-9a-f]{64}\z/;
    confess 'HIAL source identity byte length is malformed'
        unless defined($raw->{hial_source_identity}{byte_length})
            && !ref($raw->{hial_source_identity}{byte_length})
            && $raw->{hial_source_identity}{byte_length} =~ /\A[0-9]+\z/;
    confess 'HIAL emitted relpath disagrees with the source artifact'
        unless ($raw->{hial_source_identity}{emitted_relpath} // '') eq $hial->{relpath};
    confess 'HIAL DUT is not isolated under the portable backend DUT directory'
        unless $hial->{relpath} =~
            m{\Abackends/vhdl_portable_ghdl/src/dut/[^/]+\.vhd\z};
    confess 'HIAL emitted bytes disagree with the private handoff digest'
        unless sha256_hex($hial->{content}) eq $raw->{hial_source_identity}{content_sha256}
            && bytes::length($hial->{content}) == $raw->{hial_source_identity}{byte_length};
    my $legacy_imports = scalar grep {
        $_->{role} ne 'generated_hial_vhdl_dut'
            && $_->{content} =~ /(?:observation_vhdl_pkg|vhdl-observation-package|vhdl_observation_package_skeleton)/i
    } @{$raw->{source_artifacts}};
    my $legacy_artifacts = scalar grep {
        $_->{role} =~ /legacy|observation_package/i
            || $_->{relpath} =~ /observation_vhdl_pkg/i
    } @{$raw->{source_artifacts}};

    my $migration_proof = {
        schema => $MIGRATION_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        plan_id => $raw->{plan_id},
        fixture_id => $raw->{fixture_id},
        legacy_surface => {
            target => 'vhdl_observation_package_skeleton',
            cli_target => 'vhdl-observation-package',
            fixture => 'isf/verification_observation_metadata.isf',
            package_relpath =>
                'vhdl/verification_observation_metadata_observation_vhdl_pkg.vhd',
            package_bytes => 976,
            package_sha256 => $LEGACY_PACKAGE_SHA256,
            manifest_schema_version => 1,
            manifest_projection_sha256 => $LEGACY_MANIFEST_PROJECTION_SHA256,
            manifest_projection_rule =>
                'canonical JSON after removing environment-resolved source.resolved_path',
            compatibility_state => 'exact_fixture_bytes_and_schema_regression_locked',
            consumed_by_successor => JSON::PP::false,
        },
        hial_successor => {
            source_id => $raw->{hial_source_identity}{source_id},
            private_handoff_sha256 => $raw->{hial_source_identity}{content_sha256},
            private_handoff_bytes => 0 + $raw->{hial_source_identity}{byte_length},
            emitted_relpath => $hial->{relpath},
            emitted_sha256 => sha256_hex($hial->{content}),
            emitted_bytes => bytes::length($hial->{content}),
            byte_identical => JSON::PP::true,
            role => 'generated_hial_vhdl_dut',
        },
        separation => {
            migration_kind => 'parallel_versioned_surface',
            successor_profile => $BACKEND_PROFILE,
            legacy_imports_in_successor => $legacy_imports,
            legacy_artifacts_in_successor => $legacy_artifacts,
            hial_dut_role_count => 0 + ($role_count{generated_hial_vhdl_dut} // 0),
            rules => [
                'legacy command, path, inert package bytes, manifest schema, and nonclaims stay unchanged',
                'portable VIAL source never imports or rewrites the legacy observation package',
                'generated HIAL VHDL remains a byte-identical DUT input under src/dut',
                'HIAL synthesis behavior is outside VIAL verification-backend authority',
            ],
        },
        qualification_status => 'emission_review_proof_only_no_analyzer_run',
    };

    my @checks;
    push @checks, _check('selected_mapping_coverage', @mappings == @MAPPING_DEFINITION);
    push @checks, _check('entrypoint_partition', _entrypoints_are_closed(\@mappings));
    push @checks, _check('generated_role_evidence',
        _roles_are_exact(\@mappings, \%role_count));
    push @checks, _check('unsupported_reason_partition',
        _unsupported_reasons_are_exact(\@mappings));
    push @checks, _check('review_workflow', _workflow_is_closed($review_workflow));
    push @checks, _check('migration_separation',
        _migration_is_closed($migration_proof));
    push @checks, _check('qualification_boundary',
        _qualification_is_unclaimed($mapping_matrix, $review_workflow));
    confess 'portable VHDL review closure failed an internal invariant'
        if grep { $_->{status} ne 'passed' } @checks;

    return _result({
        ok => JSON::PP::true,
        status => 'passed',
        backend_profile => $BACKEND_PROFILE,
        mapping_matrix => $mapping_matrix,
        review_workflow => $review_workflow,
        migration_proof => $migration_proof,
        checks => \@checks,
        diagnostics => [],
    });
}

sub _definition($foundation_id, $intent_owner, $normal_source, $terse_source,
        $typed_ir, $generated_roles, $vhdl_realization, $unsupported_reason = undef) {
    return {
        foundation_id => $foundation_id,
        intent_owner => $intent_owner,
        normal_source => $normal_source,
        terse_source => $terse_source,
        typed_ir => $typed_ir,
        generated_roles => $generated_roles,
        vhdl_realization => $vhdl_realization,
        unsupported_reason => $unsupported_reason,
    };
}

sub _stage($stage_id, $status, $authority, $command, $evidence) {
    return {
        stage_id => $stage_id,
        status => $status,
        authority => $authority,
        command => $command,
        evidence => $evidence,
    };
}

sub _check($check_id, $passed) {
    return {check_id => $check_id, status => $passed ? 'passed' : 'failed'};
}

sub _entrypoints_are_closed($mappings) {
    my %source = map { $_ => 1 } qw(
        public_vial_v1 derived_from_public_vial_v1
        not_applicable_compiler_owned not_available_private_preview
        unsupported_in_portable_profile
    );
    my %typed = map { $_ => 1 } qw(
        public_execution_ir compiler_owned_execution_ir
        compiler_owned_bridge_manifest private_typed_preview_not_selected
        not_represented_unsupported
    );
    for my $mapping (@$mappings) {
        return 0 unless $source{$mapping->{normal_source}}
            && $source{$mapping->{terse_source}} && $typed{$mapping->{typed_ir}};
    }
    return 1;
}

sub _roles_are_exact($mappings, $role_count) {
    my %referenced;
    for my $mapping (@$mappings) {
        return 0 unless ref($mapping->{generated_roles}) eq 'ARRAY';
        for my $role (@{$mapping->{generated_roles}}) {
            return 0 unless ($role_count->{$role} // 0) == 1;
            $referenced{$role} = 1;
        }
    }
    return keys(%referenced) == keys(%$role_count)
        && !grep { !$referenced{$_} } keys %$role_count;
}

sub _unsupported_reasons_are_exact($mappings) {
    for my $mapping (@$mappings) {
        my $unsupported = $mapping->{emission_status} eq 'not_emitted_unsupported';
        return 0 if $unsupported != defined($mapping->{unsupported_reason});
        return 0 if $unsupported && @{$mapping->{generated_roles}};
        return 0 if !$unsupported && !@{$mapping->{generated_roles}};
    }
    return 1;
}

sub _workflow_is_closed($workflow) {
    return 0 unless _safe_relpath($workflow->{gallery_root});
    return 0 unless $workflow->{regenerate_command}
        eq 'perl scripts/refresh_vial_vhdl_portable_gallery.pl';
    return 0 unless $workflow->{check_command}
        eq 'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check';
    my %stage = map { $_->{stage_id} => $_ } @{$workflow->{stages}};
    return 0 unless keys(%stage) == 7
        && $stage{static_shape}{status} eq 'passed_structural_only'
        && $stage{visual_review}{status} eq 'pending'
        && $stage{migration_separation}{status} eq 'passed_regression_contract'
        && $stage{qualified_runtime}{status} eq 'not_run';
    return 0 if grep { !_has_exact_keys($_, \@STAGE_KEYS) }
        @{$workflow->{stages}};
    return 1;
}

sub _migration_is_closed($proof) {
    return $proof->{legacy_surface}{package_sha256} eq $LEGACY_PACKAGE_SHA256
        && $proof->{legacy_surface}{manifest_projection_sha256}
            eq $LEGACY_MANIFEST_PROJECTION_SHA256
        && !$proof->{legacy_surface}{consumed_by_successor}
        && $proof->{hial_successor}{byte_identical}
        && $proof->{separation}{legacy_imports_in_successor} == 0
        && $proof->{separation}{legacy_artifacts_in_successor} == 0
        && $proof->{separation}{hial_dut_role_count} == 1
        && $proof->{qualification_status}
            eq 'emission_review_proof_only_no_analyzer_run';
}

sub _qualification_is_unclaimed($matrix, $workflow) {
    return 0 unless $matrix->{profile_state}{emission} eq 'emitted'
        && $matrix->{profile_state}{static_review} eq 'reviewed_structurally'
        && $matrix->{profile_state}{visual_review} eq 'pending'
        && $matrix->{profile_state}{qualification} eq 'unqualified_not_run';
    return 0 if grep {
        $_->{emission_status} eq 'emitted'
            && ($_->{visual_review_status} ne 'pending'
                || $_->{qualification_status} ne 'not_run')
    } @{$matrix->{mappings}};
    my %nonclaim = map { $_ => 1 } @{$workflow->{nonclaims}};
    return $nonclaim{visual_review_complete}
        && $nonclaim{vhdl_analysis}
        && $nonclaim{elaboration}
        && $nonclaim{runtime}
        && $nonclaim{produced_result}
        && $nonclaim{parity}
        && $nonclaim{complete_vhdl_2008}
        && $nonclaim{psl}
        && $nonclaim{osvvm}
        && $nonclaim{product_support};
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _require_exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'" if @unknown;
    confess "$label is missing key '$missing[0]'" if @missing;
}

sub _has_exact_keys($value, $keys) {
    return 0 unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    return 0 unless keys(%$value) == keys(%expected);
    return !grep { !$expected{$_} } keys %$value;
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        backend_profile => $BACKEND_PROFILE,
        mapping_matrix => undef,
        review_workflow => undef,
        migration_proof => undef,
        checks => [],
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'review-closure result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'review-closure result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown review-closure host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown review-closure host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'review-closure result contains unsupported reference data' if ref($value);
    return $value;
}

1;
