package FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM;

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

use FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Backend::VHDLOSVVMStaticValidator;
use FSM::VIAL::Backend::VHDLPortableGHDL;

my $PROFILE = 'vhdl_osvvm_qualified';
my $ORACLE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_osvvm_oracle.v1';
my $DEPENDENCY_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $IDENTIFIER_LIMIT = 255;
my $OBSERVED_IDENTIFIER_MAXIMUM = 37;
my $PROVIDER_ROOT_COMMIT = '2f7c391051dfb11890fa4bdbda9918d1db492250';
my $PROVIDER_ROOT_TREE = 'bd4fdc594f2c26d564cf8907ff599578b9a39e22';
my $PROVIDER_MANIFEST_SHA256 =
    '128e483049521c2d4882bac0a6ceb66d9d127ca3e33109961942662409e06f96';
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my @REQUIREMENTS = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my @STATIC_CHECKS = qw(
    one_adapter exact_recursive_provider_identity adapter_provider_context
    adapter_randomization adapter_coverage adapter_scoreboard adapter_reporting
    adapter_synchronization adapter_data_structure
    adapter_verification_component closed_mapping_matrix
    portable_semantic_authority
);
my @RESULT_KEYS = qw(
    artifact_root byte_equal diagnostics observed_outcome oracle rejected
);
my @ORACLE_KEYS = qw(
    schema schema_version backend_profile level requested_operation_total
    observed_outcome artifact_root artifact_count source_artifact_count
    source_bytes source_map_entries adapter_source_map_entries
    translated_portable_source_map_entries mapped_operation_count
    source_artifact_map_count static_validation_checks
    passed_static_validation_checks static_check_identities
    portable_foundation_static_validation_checks advanced_mapping_count
    mapping_identities semantic_preservation_source_count
    semantic_preservation_guard_count provider_repository_count
    provider_gitlink_count provider_license_count provider_notice_count
    provider_manifest_sha256 provider_root_commit provider_root_tree
    artifact_relpaths source_identities maximum_generated_identifier_bytes
    generated_identifier_limit_bytes artifact_graph_sha256 byte_equal_rerun
    provider_verification_reused in_memory_only atomic_rejection diagnostics
);
my @ARTIFACT_RELPATHS = qw(
    backends/vhdl_osvvm_qualified/backend-manifest.json
    backends/vhdl_osvvm_qualified/backend-source-map.json
    backends/vhdl_osvvm_qualified/evidence/advanced-mapping-matrix.json
    backends/vhdl_osvvm_qualified/evidence/provider-materialization.json
    backends/vhdl_osvvm_qualified/evidence/qualification-reference.json
    backends/vhdl_osvvm_qualified/evidence/semantic-preservation.json
    backends/vhdl_osvvm_qualified/evidence/source-order.json
    backends/vhdl_osvvm_qualified/evidence/static-validation.json
    backends/vhdl_osvvm_qualified/evidence/tool-profile.json
    backends/vhdl_osvvm_qualified/src/fsmgen_vial_osvvm_adapter_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_metadata_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_probe_adapter.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_tb.vhd
    backends/vhdl_osvvm_qualified/src/portable/dut/ahb_lite_subordinate.vhd
    backends/vhdl_osvvm_qualified/src/portable/fsmgen_vial_runtime_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/fsmgen_vial_types_pkg.vhd
);
my @SOURCE_RELPATHS = @ARTIFACT_RELPATHS[9 .. 15];
my %EXPECTED = (
    reference_v1 => {
        operations => 21, source_bytes => 120_911, source_maps => 66,
        metadata_bytes => 15_323,
        metadata_sha256 =>
            '59a4f9e1f8a2c9da6b8c5dd36f255ee1edb0b2bce57264906ab916a9141ba8bc',
    },
    gate_candidate_v1 => {
        operations => 128, source_bytes => 179_280, source_maps => 173,
        metadata_bytes => 73_692,
        metadata_sha256 =>
            '922e1ab962d20c12cf24cdd8222a19b3f39fe958e934bcfb93b6a03974e0c9c9',
    },
    qualification_candidate_v1 => {
        operations => 512, source_bytes => 391_248, source_maps => 557,
        metadata_bytes => 285_660,
        metadata_sha256 =>
            '9c77af56b8241f94c4ca2d9fc23ec73c6ad5582ae709dcb1318d0e6716502d7a',
    },
    limit_v1 => {
        operations => 29_508, source_bytes => 16_781_090,
        source_maps => 29_553, metadata_bytes => 16_675_502,
        metadata_sha256 =>
            'b678833b74279814a3c5b008116546fe0353362296de32daa487352091a7ee06',
    },
    over_limit_v1 => {operations => 29_509},
);

sub profile($class) {
    _exact_invocant($class, 'profile');
    return $PROFILE;
}

sub owned_levels($class) {
    _exact_invocant($class, 'owned_levels');
    return [@LEVELS];
}

sub oracle_keys($class) {
    _exact_invocant($class, 'oracle_keys');
    return [@ORACLE_KEYS];
}

sub operation_total($class, @args) {
    _exact_invocant($class, 'operation_total');
    confess __PACKAGE__ . "->operation_total expects one level scalar\n"
        unless @args == 1 && defined($args[0]) && !ref($args[0])
            && $LEVEL{$args[0]};
    return 0 + $EXPECTED{$args[0]}{operations};
}

sub canonical_vial_source($class, @args) {
    _exact_invocant($class, 'canonical_vial_source');
    confess __PACKAGE__ . "->canonical_vial_source expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    return FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL
        ->canonical_vial_source($args[0]);
}

sub evaluate($class, @args) {
    confess "OSVVM profile evaluation is caller-sealed\n"
        unless caller eq 'FSM::VIAL::ArchitectureScaleBackendEmission';
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my $raw = $args[0];
    _exact_keys($raw, [qw(construction first_route second_route)],
        'OSVVM evaluation');
    my $construction = $raw->{construction};
    confess "OSVVM construction must be one hash\n"
        unless ref($construction) eq 'HASH' && !blessed($construction);
    my $specification = $construction->{specification};
    confess "OSVVM construction specification is invalid\n"
        unless ref($specification) eq 'HASH'
            && ($specification->{backend_profile} // '') eq $PROFILE;
    my $level = $specification->{level};
    _selected_level($level);
    my $artifact_root = "$construction->{staging_identity}/backend-output";

    my $second;
    my $first = FSM::VIAL::Backend::VHDLOSVVM2026_05
        ->with_provider_evaluation({
            dependency_root => $DEPENDENCY_ROOT,
            consumer => sub ($evaluation) {
                my $first_result = $evaluation->emit(
                    _backend_args($raw->{first_route}, $artifact_root));
                $second = $evaluation->emit(
                    _backend_args($raw->{second_route}, $artifact_root));
                return $first_result;
            },
        });
    my $byte_equal = defined($second)
        && _canonical_json($first) eq _canonical_json($second);
    my ($oracle, $diagnostics) = _artifact_oracle(
        $level, $raw->{first_route}{execution_ir}->as_hashref,
        $first, $artifact_root, $byte_equal,
    );
    push @$diagnostics, _diagnostic(
        'VIAL_SCALE_BACKEND_EMISSION_DETERMINISM_ERROR',
        'callback-scoped OSVVM emissions were not byte-identical',
        '/artifact_oracle/osvvm',
    ) unless $byte_equal;
    my $rejected = $level eq 'over_limit_v1';
    return _closed_result({
        artifact_root => $artifact_root,
        byte_equal => $byte_equal ? JSON::PP::true : JSON::PP::false,
        diagnostics => $diagnostics,
        observed_outcome => $rejected
            ? 'portable_foundation_limit_rejected' : 'backend_emitted',
        oracle => $oracle,
        rejected => $rejected ? JSON::PP::true : JSON::PP::false,
    });
}

sub _backend_args($route, $artifact_root) {
    confess "OSVVM route must be one hash\n"
        unless ref($route) eq 'HASH' && !blessed($route);
    return {
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $PROFILE,
        dependency_root => $DEPENDENCY_ROOT,
        advanced_requirements => [@REQUIREMENTS],
    };
}

sub _artifact_oracle($level, $execution, $emission, $artifact_root, $byte_equal) {
    my $expected = $EXPECTED{$level};
    my $rejected = $level eq 'over_limit_v1';
    my @diagnostics;
    my $add = sub ($message, $path) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_OSVVM_ARTIFACT_ORACLE_ERROR', $message, $path,
        );
    };
    _validate_closed_keys(
        $emission, FSM::VIAL::Backend::VHDLOSVVM2026_05->result_keys,
        'OSVVM result schema is not closed', '/emission', $add,
    );
    $add->('OSVVM backend profile changed', '/emission/backend_profile')
        unless ($emission->{backend_profile} // '') eq $PROFILE;

    my ($artifact_count, $source_count, $source_bytes, $map_count) =
        (0, 0, 0, 0);
    my ($adapter_maps, $portable_maps, $mapped_operations, $mapped_sources) =
        (0, 0, 0, 0);
    my ($static_count, $passed_static_count, $maximum_identifier) = (0, 0, 0);
    my ($mapping_count, $preserved_source_count, $preservation_guard_count) =
        (0, 0, 0);
    my ($provider_repository_count, $provider_gitlink_count) = (0, 0);
    my ($provider_license_count, $provider_notice_count) = (0, 0);
    my ($provider_manifest_sha256, $provider_root_commit, $provider_root_tree);
    my (@artifact_relpaths, @source_identities, @static_check_identities,
        @mapping_identities);
    my $artifact_graph_sha256;

    if ($rejected) {
        my $expected_diagnostics = [{
            code => 'VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR',
            message => 'generated VHDL exceeds the 16 MiB backend cap',
            path => '/portable_foundation',
        }];
        $add->('adjacent OSVVM shape did not reject', '/emission/ok')
            if $emission->{ok};
        $add->('adjacent OSVVM status changed', '/emission/status')
            unless ($emission->{status} // '') eq 'failed';
        $add->('adjacent OSVVM diagnostic changed', '/emission/diagnostics')
            unless _canonical_json($emission->{diagnostics})
                eq _canonical_json($expected_diagnostics);
        $add->('adjacent OSVVM rejection published artifacts',
            '/emission/artifacts')
            unless ref($emission->{artifacts}) eq 'ARRAY'
                && !@{$emission->{artifacts}};
        for my $field (qw(
            plan_id generated_top operation_id negotiation
            provider_materialization mapping_matrix semantic_preservation
            source_map static_validation backend_manifest
        )) {
            $add->("adjacent rejection retained partial $field evidence",
                "/emission/$field") if defined $emission->{$field};
        }
    }
    else {
        $add->('accepted OSVVM shape was rejected', '/emission/ok')
            unless $emission->{ok};
        $add->('accepted OSVVM status changed', '/emission/status')
            unless ($emission->{status} // '')
                eq 'emitted_structurally_reviewed_qualified';
        $add->('accepted OSVVM emission has diagnostics',
            '/emission/diagnostics')
            unless ref($emission->{diagnostics}) eq 'ARRAY'
                && !@{$emission->{diagnostics}};

        my $artifacts = ref($emission->{artifacts}) eq 'ARRAY'
            ? $emission->{artifacts} : [];
        $artifact_count = scalar(@$artifacts);
        @artifact_relpaths = map { $_->{relpath} // '' } @$artifacts;
        $add->('OSVVM artifact inventory or order changed',
            '/emission/artifacts')
            unless _canonical_json(\@artifact_relpaths)
                eq _canonical_json(\@ARTIFACT_RELPATHS);
        _validate_artifact_shapes($artifacts, $add);

        my @sources = grep { ($_->{language} // '') eq 'vhdl' } @$artifacts;
        $source_count = scalar(@sources);
        $source_bytes += bytes::length($_->{content}) for @sources;
        @source_identities = map {{
            relpath => $_->{relpath}, bytes => bytes::length($_->{content}),
            sha256 => sha256_hex($_->{content}),
        }} @sources;
        my @expected_sources = _expected_sources($expected);
        $add->('OSVVM source identities changed', '/emission/artifacts')
            unless _canonical_json(\@source_identities)
                eq _canonical_json(\@expected_sources);
        $add->('OSVVM source byte total changed', '/emission/artifacts')
            unless $source_bytes == $expected->{source_bytes};

        my $source_map = _hash_or_empty($emission->{source_map});
        _validate_closed_keys($source_map,
            [qw(schema schema_version plan_id artifacts entries)],
            'OSVVM source-map schema is not closed',
            '/emission/source_map', $add);
        my $entries = ref($source_map->{entries}) eq 'ARRAY'
            ? $source_map->{entries} : [];
        my $map_artifacts = ref($source_map->{artifacts}) eq 'ARRAY'
            ? $source_map->{artifacts} : [];
        $map_count = scalar(@$entries);
        $adapter_maps = @$entries >= 7 ? 7 : scalar(@$entries);
        $portable_maps = $map_count - $adapter_maps;
        $mapped_sources = scalar(@$map_artifacts);
        $add->('OSVVM source-map count changed',
            '/emission/source_map/entries')
            unless $map_count == $expected->{source_maps};
        _validate_source_map_artifacts($map_artifacts, \@sources, $add);
        my ($mapped, $maximum) = _validate_source_map_entries(
            $entries, \@sources, $execution, $add,
        );
        $mapped_operations = $mapped;
        $maximum_identifier = $maximum;
        my $top = $emission->{generated_top};
        $add->('generated top identifier is not legal',
            '/emission/generated_top') unless _legal_identifier($top);
        my $top_bytes = defined($top) && !ref($top)
            ? bytes::length($top) : 0;
        $maximum_identifier = $top_bytes
            if $top_bytes > $maximum_identifier;
        $add->('OSVVM operation maps are incomplete',
            '/emission/source_map/entries')
            unless $mapped_operations == $expected->{operations};
        $add->('OSVVM generated identifier maximum changed',
            '/emission/source_map/entries')
            unless $maximum_identifier == $OBSERVED_IDENTIFIER_MAXIMUM;
        $add->('OSVVM generated identifier limit was exceeded',
            '/emission/source_map/entries')
            if $maximum_identifier > $IDENTIFIER_LIMIT;

        my $static = _hash_or_empty($emission->{static_validation});
        _validate_static_validation($static, $add);
        my $checks = ref($static->{checks}) eq 'ARRAY' ? $static->{checks} : [];
        $static_count = scalar(@$checks);
        $passed_static_count = scalar grep {
            ($_->{status} // '') eq 'passed'
        } @$checks;
        @static_check_identities = map { $_->{check_id} // '' } @$checks;

        my $matrix = _hash_or_empty($emission->{mapping_matrix});
        my $mapping_identities;
        ($mapping_count, $mapping_identities) =
            _validate_mapping_matrix($matrix, $add);
        @mapping_identities = @$mapping_identities;
        my $preservation = _hash_or_empty($emission->{semantic_preservation});
        ($preserved_source_count, $preservation_guard_count) =
            _validate_semantic_preservation($preservation, \@sources, $add);
        my $provider = _hash_or_empty($emission->{provider_materialization});
        ($provider_repository_count, $provider_gitlink_count,
            $provider_license_count, $provider_notice_count,
            $provider_manifest_sha256, $provider_root_commit,
            $provider_root_tree) = _validate_provider($provider, $add);
        _validate_negotiation($emission->{negotiation}, $add);
        _validate_evidence_artifacts(
            $artifacts, $emission, $source_map, $static, $matrix,
            $preservation, $provider, $add,
        );
        $artifact_graph_sha256 = sha256_hex(_canonical_json($artifacts));
    }

    return ({
        schema => $ORACLE_SCHEMA,
        schema_version => 1,
        backend_profile => $PROFILE,
        level => $level,
        requested_operation_total => 0 + $expected->{operations},
        observed_outcome => $rejected
            ? 'portable_foundation_limit_rejected' : 'backend_emitted',
        artifact_root => $artifact_root,
        artifact_count => $artifact_count,
        source_artifact_count => $source_count,
        source_bytes => $source_bytes,
        source_map_entries => $map_count,
        adapter_source_map_entries => $adapter_maps,
        translated_portable_source_map_entries => $portable_maps,
        mapped_operation_count => $mapped_operations,
        source_artifact_map_count => $mapped_sources,
        static_validation_checks => $static_count,
        passed_static_validation_checks => $passed_static_count,
        static_check_identities => \@static_check_identities,
        portable_foundation_static_validation_checks =>
            $rejected ? 0 : 20,
        advanced_mapping_count => $mapping_count,
        mapping_identities => \@mapping_identities,
        semantic_preservation_source_count => $preserved_source_count,
        semantic_preservation_guard_count => $preservation_guard_count,
        provider_repository_count => $provider_repository_count,
        provider_gitlink_count => $provider_gitlink_count,
        provider_license_count => $provider_license_count,
        provider_notice_count => $provider_notice_count,
        provider_manifest_sha256 => $provider_manifest_sha256,
        provider_root_commit => $provider_root_commit,
        provider_root_tree => $provider_root_tree,
        artifact_relpaths => \@artifact_relpaths,
        source_identities => \@source_identities,
        maximum_generated_identifier_bytes => $maximum_identifier,
        generated_identifier_limit_bytes => $IDENTIFIER_LIMIT,
        artifact_graph_sha256 => $artifact_graph_sha256,
        byte_equal_rerun => $byte_equal ? JSON::PP::true : JSON::PP::false,
        provider_verification_reused =>
            $byte_equal ? JSON::PP::true : JSON::PP::false,
        in_memory_only => JSON::PP::true,
        atomic_rejection => $rejected ? JSON::PP::true : JSON::PP::false,
        diagnostics => _clone($emission->{diagnostics}),
    }, \@diagnostics);
}

sub _validate_artifact_shapes($artifacts, $add) {
    my @expected_keys = sort qw(
        relpath role kind language content byte_length sha256 source_ids
    );
    my %seen;
    for my $index (0 .. $#$artifacts) {
        my $artifact = $artifacts->[$index];
        _validate_closed_keys($artifact, \@expected_keys,
            'OSVVM artifact schema is not closed',
            "/emission/artifacts/$index", $add);
        $add->('OSVVM artifact path is unsafe',
            "/emission/artifacts/$index/relpath")
            unless _safe_relative_path($artifact->{relpath});
        $add->('OSVVM artifact path is duplicated',
            "/emission/artifacts/$index/relpath")
            if $seen{$artifact->{relpath} // ''}++;
        $add->('OSVVM artifact byte length changed',
            "/emission/artifacts/$index/byte_length")
            unless defined($artifact->{content}) && !ref($artifact->{content})
                && ($artifact->{byte_length} // -1)
                    == bytes::length($artifact->{content});
        $add->('OSVVM artifact digest changed',
            "/emission/artifacts/$index/sha256")
            unless defined($artifact->{content}) && !ref($artifact->{content})
                && ($artifact->{sha256} // '')
                    eq sha256_hex($artifact->{content});
        $add->('OSVVM artifact source identities must be an array',
            "/emission/artifacts/$index/source_ids")
            unless ref($artifact->{source_ids}) eq 'ARRAY';
    }
}

sub _expected_sources($expected) {
    return (
        {
            relpath => $SOURCE_RELPATHS[0], bytes => 4_351,
            sha256 =>
                '1a547b8de38c072600a76497778758affab25ccd479c0c1dfce7f0e0579c9e94',
        },
        {
            relpath => $SOURCE_RELPATHS[1], bytes => $expected->{metadata_bytes},
            sha256 => $expected->{metadata_sha256},
        },
        {
            relpath => $SOURCE_RELPATHS[2], bytes => 591,
            sha256 =>
                '7a7e3b4e81fd222e53e2098653fcf1131f1b58dbeba35698c1cfe67a4fab5b56',
        },
        {
            relpath => $SOURCE_RELPATHS[3], bytes => 44_760,
            sha256 =>
                '2570c6349752023e358785156e9739ce76a4dd14bc6d86ad71b1253783ca4b70',
        },
        {
            relpath => $SOURCE_RELPATHS[4], bytes => 47_670,
            sha256 =>
                '8d93b0ade4d9561d19fdd12ab10b4d8ba1a3dc06de9f911d1c0d8d1bf18518cf',
        },
        {
            relpath => $SOURCE_RELPATHS[5], bytes => 2_191,
            sha256 =>
                '82cb0d22e03a661ff88aecbf5b94b89f91381801576d1c683d749ac02e258017',
        },
        {
            relpath => $SOURCE_RELPATHS[6], bytes => 6_025,
            sha256 =>
                '3777706b911ce90c9a3b05107233ec925c1029b175932ed10f1b1a588fb3c08e',
        },
    );
}

sub _validate_source_map_artifacts($actual, $sources, $add) {
    my @expected = map {{
        relpath => $_->{relpath}, role => $_->{role}, kind => $_->{kind},
        language => $_->{language}, byte_length => $_->{byte_length},
        sha256 => $_->{sha256}, source_ids => _clone($_->{source_ids}),
    }} sort { $a->{relpath} cmp $b->{relpath} } @$sources;
    $add->('OSVVM source-map artifact closure changed',
        '/emission/source_map/artifacts')
        unless _canonical_json($actual) eq _canonical_json(\@expected);
}

sub _validate_source_map_entries($entries, $sources, $execution, $add) {
    my %source = map { $_->{relpath} => $_ } @$sources;
    my %shape = map { $_->{relpath} => _source_shape($_->{content}) } @$sources;
    my @adapter_keys = sort qw(
        source_map_id generated_relpath generated_start_line generated_end_line
        generated_symbol role plan_paths semantic_paths source_locations
    );
    my @portable_keys = sort
        @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_entry_keys};
    my (%mapped_operation, %source_map_id);
    my $maximum_identifier = 0;
    for my $index (0 .. $#$entries) {
        my $entry = $entries->[$index];
        my $adapter = $index < 7;
        _validate_closed_keys($entry,
            $adapter ? \@adapter_keys : \@portable_keys,
            'OSVVM source-map entry is not closed',
            "/emission/source_map/entries/$index", $add);
        my $relpath = $entry->{generated_relpath} // '';
        $add->('OSVVM source-map entry names a non-source artifact',
            "/emission/source_map/entries/$index/generated_relpath")
            unless $source{$relpath};
        my $source_shape = $shape{$relpath} || {line_count => 0};
        $add->('OSVVM source-map entry has an invalid generated line span',
            "/emission/source_map/entries/$index")
            unless ($entry->{generated_start_line} // 0) >= 1
                && ($entry->{generated_end_line} // 0)
                    >= ($entry->{generated_start_line} // 0)
                && ($entry->{generated_end_line} // 0)
                    <= $source_shape->{line_count};
        unless ($adapter) {
            $add->('translated portable map has an invalid column span',
                "/emission/source_map/entries/$index")
                unless ($entry->{generated_start_column} // 0) == 1
                    && ($entry->{generated_end_column} // 0)
                        == ($source_shape->{end_columns}
                            [$entry->{generated_end_line} // 0] // -1);
        }
        my $symbol = $entry->{generated_symbol};
        $add->('source-map generated identifier is not legal VHDL',
            "/emission/source_map/entries/$index/generated_symbol")
            unless _legal_identifier($symbol);
        my $symbol_bytes = defined($symbol) && !ref($symbol)
            ? bytes::length($symbol) : 0;
        $maximum_identifier = $symbol_bytes
            if $symbol_bytes > $maximum_identifier;
        $add->('OSVVM source-map identity is duplicated',
            "/emission/source_map/entries/$index/source_map_id")
            if $source_map_id{$entry->{source_map_id} // ''}++;
        $mapped_operation{$_} = 1
            for grep { m{\Aoperation/} } @{$entry->{semantic_paths} || []};
    }
    my @expected_operation_ids = sort map { $_->{operation_id} }
        @{$execution->{operation_graph}{operations}};
    my @actual_operation_ids = sort keys %mapped_operation;
    $add->('OSVVM operation-map identities changed',
        '/emission/source_map/entries')
        unless _canonical_json(\@actual_operation_ids)
            eq _canonical_json(\@expected_operation_ids);
    return (scalar(@actual_operation_ids), $maximum_identifier);
}

sub _validate_static_validation($static, $add) {
    _validate_closed_keys(
        $static, FSM::VIAL::Backend::VHDLOSVVMStaticValidator->result_keys,
        'OSVVM static-validation schema is not closed',
        '/emission/static_validation', $add,
    );
    $add->('OSVVM static validation did not pass',
        '/emission/static_validation/ok') unless $static->{ok};
    $add->('OSVVM static-validation status changed',
        '/emission/static_validation/status')
        unless ($static->{status} // '') eq 'passed_structural_only';
    $add->('OSVVM static-validation schema identity changed',
        '/emission/static_validation/schema')
        unless ($static->{schema} // '')
            eq 'fsmgen.vial_vhdl_osvvm_static_validation.v1';
    $add->('OSVVM static validation has diagnostics',
        '/emission/static_validation/diagnostics')
        unless ref($static->{diagnostics}) eq 'ARRAY'
            && !@{$static->{diagnostics}};
    my $checks = ref($static->{checks}) eq 'ARRAY' ? $static->{checks} : [];
    my @actual = map { $_->{check_id} // '' } @$checks;
    $add->('OSVVM static-check inventory changed',
        '/emission/static_validation/checks')
        unless _canonical_json(\@actual) eq _canonical_json(\@STATIC_CHECKS);
    for my $index (0 .. $#$checks) {
        _validate_closed_keys($checks->[$index], [qw(check_id evidence status)],
            'OSVVM static-check schema is not closed',
            "/emission/static_validation/checks/$index", $add);
        $add->('OSVVM static check did not pass',
            "/emission/static_validation/checks/$index/status")
            unless ($checks->[$index]{status} // '') eq 'passed';
    }
}

sub _validate_mapping_matrix($matrix, $add) {
    _validate_closed_keys($matrix,
        [qw(schema schema_version profile provider mappings profile_state)],
        'OSVVM mapping-matrix schema is not closed',
        '/emission/mapping_matrix', $add);
    my $mappings = ref($matrix->{mappings}) eq 'ARRAY'
        ? $matrix->{mappings} : [];
    my @actual = map { $_->{mapping_id} // '' } @$mappings;
    $add->('OSVVM mapping identities changed', '/emission/mapping_matrix')
        unless _canonical_json(\@actual) eq _canonical_json(\@REQUIREMENTS);
    my @keys = sort qw(
        mapping_id provider_package provider_symbol mode generated_role
        source_map_id generated_start_line generated_end_line emission_status
        static_status qualification_status semantic_guard
    );
    for my $index (0 .. $#$mappings) {
        my $mapping = $mappings->[$index];
        _validate_closed_keys($mapping, \@keys,
            'OSVVM mapping schema is not closed',
            "/emission/mapping_matrix/mappings/$index", $add);
        my $qualification = ($mapping->{mapping_id} // '')
                eq 'verification_component_adapter'
            ? 'passed_analysis_only' : 'passed_runtime_probe';
        $add->('OSVVM mapping status changed',
            "/emission/mapping_matrix/mappings/$index")
            unless ($mapping->{emission_status} // '') eq 'emitted'
                && ($mapping->{static_status} // '') eq 'passed'
                && ($mapping->{qualification_status} // '') eq $qualification;
    }
    return (scalar(@$mappings), \@actual);
}

sub _validate_semantic_preservation($preservation, $sources, $add) {
    _validate_closed_keys($preservation, [qw(
        schema schema_version portable_profile advanced_profile
        portable_plan_id portable_sources guards provider_role
    )], 'OSVVM semantic-preservation schema is not closed',
        '/emission/semantic_preservation', $add);
    my $preserved = ref($preservation->{portable_sources}) eq 'ARRAY'
        ? $preservation->{portable_sources} : [];
    my @keys = sort qw(
        role portable_relpath advanced_relpath byte_length portable_sha256
        advanced_sha256 byte_identical
    );
    my %source = map { $_->{relpath} => $_ } @$sources;
    for my $index (0 .. $#$preserved) {
        my $entry = $preserved->[$index];
        _validate_closed_keys($entry, \@keys,
            'OSVVM preservation entry schema is not closed',
            "/emission/semantic_preservation/portable_sources/$index", $add);
        my $artifact = $source{$entry->{advanced_relpath} // ''};
        $add->('OSVVM preservation source is not byte-identical',
            "/emission/semantic_preservation/portable_sources/$index")
            unless $artifact && $entry->{byte_identical}
                && ($entry->{portable_sha256} // '')
                    eq ($entry->{advanced_sha256} // '')
                && ($entry->{advanced_sha256} // '') eq $artifact->{sha256}
                && ($entry->{byte_length} // -1) == $artifact->{byte_length};
    }
    my $guards = ref($preservation->{guards}) eq 'HASH'
        ? $preservation->{guards} : {};
    my @guard_keys = sort qw(
        portable_random_replay_unchanged phase_order_unchanged
        comparison_semantics_unchanged coverage_semantics_unchanged
        closed_trace_unchanged normalized_result_unchanged
    );
    _validate_closed_keys($guards, \@guard_keys,
        'OSVVM semantic guard schema is not closed',
        '/emission/semantic_preservation/guards', $add);
    $add->('OSVVM semantic guard changed',
        '/emission/semantic_preservation/guards')
        if grep { !$guards->{$_} } @guard_keys;
    return (scalar(@$preserved), scalar(@guard_keys));
}

sub _validate_provider($provider, $add) {
    _validate_closed_keys(
        $provider,
        FSM::VIAL::Backend::OSVVM2026_05Materialization->manifest_keys,
        'OSVVM provider schema is not closed',
        '/emission/provider_materialization', $add,
    );
    my $digest = sha256_hex(_canonical_json($provider));
    $add->('OSVVM provider manifest digest changed',
        '/emission/provider_materialization')
        unless $digest eq $PROVIDER_MANIFEST_SHA256;
    $add->('OSVVM provider root identity changed',
        '/emission/provider_materialization')
        unless ($provider->{root_commit} // '') eq $PROVIDER_ROOT_COMMIT
            && ($provider->{root_tree} // '') eq $PROVIDER_ROOT_TREE;
    my $repositories = ref($provider->{repositories}) eq 'ARRAY'
        ? scalar(@{$provider->{repositories}}) : 0;
    my $gitlinks = ref($provider->{recursive_gitlinks}) eq 'ARRAY'
        ? scalar(@{$provider->{recursive_gitlinks}}) : 0;
    my $licenses = ref($provider->{license_notice_files}) eq 'ARRAY'
        ? scalar(grep { ($_->{kind} // '') eq 'license' }
            @{$provider->{license_notice_files}}) : 0;
    my $notices = ref($provider->{license_notice_files}) eq 'ARRAY'
        ? scalar(grep { ($_->{kind} // '') eq 'notice' }
            @{$provider->{license_notice_files}}) : 0;
    $add->('OSVVM provider census changed',
        '/emission/provider_materialization')
        unless $repositories == 14 && $gitlinks == 13
            && $licenses == 14 && $notices == 0;
    return ($repositories, $gitlinks, $licenses, $notices, $digest,
        $provider->{root_commit}, $provider->{root_tree});
}

sub _validate_negotiation($negotiation, $add) {
    my $value = _hash_or_empty($negotiation);
    _validate_closed_keys($value,
        [qw(required satisfied unsatisfied semantic_authority)],
        'OSVVM negotiation schema is not closed',
        '/emission/negotiation', $add);
    $add->('OSVVM negotiation changed', '/emission/negotiation')
        unless _canonical_json($value->{required})
                eq _canonical_json(\@REQUIREMENTS)
            && _canonical_json($value->{satisfied})
                eq _canonical_json(\@REQUIREMENTS)
            && ref($value->{unsatisfied}) eq 'ARRAY'
            && !@{$value->{unsatisfied}}
            && ($value->{semantic_authority} // '')
                eq 'portable_vhdl_execution_and_result_oracles';
}

sub _validate_evidence_artifacts(
    $artifacts, $emission, $source_map, $static, $matrix,
    $preservation, $provider, $add,
) {
    my %by_path = map { $_->{relpath} => $_ } @$artifacts;
    my @encoded = (
        ['backends/vhdl_osvvm_qualified/backend-source-map.json', $source_map],
        ['backends/vhdl_osvvm_qualified/evidence/static-validation.json', $static],
        ['backends/vhdl_osvvm_qualified/evidence/advanced-mapping-matrix.json',
            $matrix],
        ['backends/vhdl_osvvm_qualified/evidence/semantic-preservation.json',
            $preservation],
        ['backends/vhdl_osvvm_qualified/evidence/provider-materialization.json',
            $provider],
    );
    for my $item (@encoded) {
        $add->('OSVVM evidence artifact does not encode returned evidence',
            "/emission/artifacts/$item->[0]")
            unless $by_path{$item->[0]}
                && $by_path{$item->[0]}{content} eq _pretty_json($item->[1]);
    }
    my $manifest_artifact =
        $by_path{'backends/vhdl_osvvm_qualified/backend-manifest.json'};
    my $manifest = $emission->{backend_manifest};
    $add->('OSVVM manifest artifact does not encode the returned manifest',
        '/emission/backend_manifest')
        unless $manifest_artifact && ref($manifest) eq 'HASH'
            && $manifest_artifact->{content} eq _pretty_json($manifest);
    return unless ref($manifest) eq 'HASH';
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} } map {{
        relpath => $_->{relpath}, role => $_->{role}, kind => $_->{kind},
        language => $_->{language}, byte_length => $_->{byte_length},
        sha256 => $_->{sha256}, source_ids => _clone($_->{source_ids}),
    }} grep {
        $_->{relpath} ne 'backends/vhdl_osvvm_qualified/backend-manifest.json'
    } @$artifacts;
    $add->('OSVVM manifest artifact closure changed',
        '/emission/backend_manifest/artifacts')
        unless _canonical_json($manifest->{artifacts})
            eq _canonical_json(\@referenced);
    $add->('OSVVM manifest source-map count changed',
        '/emission/backend_manifest/source_map/entry_count')
        unless ($manifest->{source_map}{entry_count} // -1)
            == scalar(@{$source_map->{entries} || []});
    $add->('OSVVM manifest source-map digest changed',
        '/emission/backend_manifest/source_map/sha256')
        unless ($manifest->{source_map}{sha256} // '')
            eq sha256_hex(_pretty_json($source_map));
}

sub _validate_closed_keys($value, $keys, $message, $path, $add) {
    if (ref($value) ne 'HASH' || blessed($value)) {
        $add->($message, $path);
        return;
    }
    my @actual = sort keys %$value;
    my @expected = sort @$keys;
    $add->($message, $path)
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
}

sub _source_shape($content) {
    my @line = split /\n/, $content, -1;
    pop @line if @line && $line[-1] eq '';
    return {
        line_count => scalar(@line),
        end_columns => [undef, map { bytes::length($_) + 1 } @line],
    };
}

sub _closed_result($value) {
    _exact_keys($value, \@RESULT_KEYS, 'OSVVM evaluation result');
    return _clone($value);
}

sub _selected_level($level) {
    confess "unknown OSVVM level\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _legal_identifier($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z](?:[A-Za-z0-9]|_(?=[A-Za-z0-9]))*\z/;
}

sub _diagnostic($code, $message, $path) {
    return {code => $code, severity => 'error', message => $message, path => $path};
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _safe_relative_path($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my @part = split m{/}, $value, -1;
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @part;
}

sub _hash_or_empty($value) {
    return ref($value) eq 'HASH' && !blessed($value) ? $value : {};
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _pretty_json($value) {
    return JSON::PP->new->canonical(1)->pretty(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "OSVVM oracle contains an unsupported reference\n" if ref($value);
    return $value;
}

1;
