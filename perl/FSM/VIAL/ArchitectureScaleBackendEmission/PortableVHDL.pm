package FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL;

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

use FSM::VIAL::Backend::VHDLPortableGHDL;

my $PROFILE = 'vhdl_portable_ghdl';
my $ORACLE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_portable_vhdl_oracle.v1';
my $SCALE_SOURCE =
    'vial/ahb_subordinate_base_output_arbitration_1.vial';
my $IDENTIFIER_LIMIT = 255;
my $OBSERVED_IDENTIFIER_MAXIMUM = 37;
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my @RESULT_KEYS = qw(
    artifact_root byte_equal diagnostics observed_outcome oracle rejected
);
my @ORACLE_KEYS = qw(
    schema schema_version backend_profile level requested_operation_total
    observed_outcome artifact_root artifact_count source_artifact_count
    source_bytes source_map_entries mapped_operation_count
    source_artifact_map_count static_validation_checks
    passed_static_validation_checks static_check_identities artifact_relpaths
    source_identities maximum_generated_identifier_bytes
    generated_identifier_limit_bytes artifact_graph_sha256 byte_equal_rerun
    in_memory_only atomic_rejection diagnostics
);
my @ARTIFACT_RELPATHS = qw(
    backends/vhdl_portable_ghdl/backend-manifest.json
    backends/vhdl_portable_ghdl/backend-source-map.json
    backends/vhdl_portable_ghdl/commands/analyze-command.json
    backends/vhdl_portable_ghdl/commands/elaborate-command.json
    backends/vhdl_portable_ghdl/commands/run-command.json
    backends/vhdl_portable_ghdl/evidence/migration-proof.json
    backends/vhdl_portable_ghdl/evidence/review-workflow.json
    backends/vhdl_portable_ghdl/evidence/selected-mapping-matrix.json
    backends/vhdl_portable_ghdl/evidence/source-order.json
    backends/vhdl_portable_ghdl/evidence/static-validation.json
    backends/vhdl_portable_ghdl/evidence/tool-profile.json
    backends/vhdl_portable_ghdl/src/base_output_arbitration_metadata_pkg.vhd
    backends/vhdl_portable_ghdl/src/base_output_arbitration_probe_adapter.vhd
    backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd
    backends/vhdl_portable_ghdl/src/dut/ahb_lite_subordinate.vhd
    backends/vhdl_portable_ghdl/src/fsmgen_vial_runtime_pkg.vhd
    backends/vhdl_portable_ghdl/src/fsmgen_vial_types_pkg.vhd
);
my @SOURCE_RELPATHS = @ARTIFACT_RELPATHS[11 .. 16];
my @STATIC_CHECKS = qw(
    closed_safe_vhdl_source_graph
    required_vhdl_source_roles
    bounded_static_input
    deterministic_vhdl_text_shape
    simulator_and_methodology_neutral_vhdl
    selected_vhdl_portable_semantic_shape
    closed_std_logic_normalization
    typed_four_state_drivers_and_samplers
    single_inactive_edge_semantic_authority
    stable_sample_react_check_drive_order
    complete_rank_scenario_and_fiber_metadata
    deterministic_model_state_and_updates
    declared_source_mapped_probe_adapters
    bounded_scoreboard_queues_and_comparisons
    portable_coverage_counters
    bounded_substitution_fault_seam
    procedural_property_checks_without_psl
    bounded_diagnostics_and_unknown_evidence
    closed_trace_projection
    one_catalogued_snapshot_per_sample_barrier
    normalized_result_manifest_projection
);
my %EXPECTED = (
    reference_v1 => {
        operations => 21, source_bytes => 118_064, source_maps => 59,
        metadata_bytes => 15_323,
        metadata_sha256 =>
            '59a4f9e1f8a2c9da6b8c5dd36f255ee1edb0b2bce57264906ab916a9141ba8bc',
    },
    gate_candidate_v1 => {
        operations => 128, source_bytes => 176_433, source_maps => 166,
        metadata_bytes => 73_692,
        metadata_sha256 =>
            '922e1ab962d20c12cf24cdd8222a19b3f39fe958e934bcfb93b6a03974e0c9c9',
    },
    qualification_candidate_v1 => {
        operations => 512, source_bytes => 388_401, source_maps => 550,
        metadata_bytes => 285_660,
        metadata_sha256 =>
            '9c77af56b8241f94c4ca2d9fc23ec73c6ad5582ae709dcb1318d0e6716502d7a',
    },
    limit_v1 => {
        operations => 29_506, source_bytes => 16_777_107,
        source_maps => 29_544, metadata_bytes => 16_674_366,
        metadata_sha256 =>
            '321d67b4d78c8ff4c7921b709d8d156787b442f2a4334754860c80a07c7cb167',
    },
    over_limit_v1 => {operations => 29_507},
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
    my $raw = $args[0];
    _exact_keys($raw, [qw(level reference_relative_path reference_text)],
        'portable-VHDL source request');
    _selected_level($raw->{level});
    confess "portable-VHDL reference path must be a scalar\n"
        unless defined($raw->{reference_relative_path})
            && !ref($raw->{reference_relative_path});
    confess "portable-VHDL reference text must be a scalar\n"
        unless defined($raw->{reference_text}) && !ref($raw->{reference_text});

    my $source = $raw->{reference_text};
    if ($raw->{level} ne 'reference_v1') {
        my $repeat_count = $EXPECTED{$raw->{level}}{operations} - 22;
        my $needle = '              (scoreboard_check writes)))';
        my $insertion = "              (repeat $repeat_count"
            . ' (expect scale_response_ok (same (sample response) #b0)))'
            . "\n";
        my $matches = $source =~ s/\Q$needle\E/$insertion$needle/;
        confess "anchored response-expectation insertion point is not unique\n"
            unless $matches == 1;
    }
    return [$SCALE_SOURCE, $source];
}

sub evaluate($class, @args) {
    confess "portable-VHDL profile evaluation is caller-sealed\n"
        unless caller eq 'FSM::VIAL::ArchitectureScaleBackendEmission';
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my $raw = $args[0];
    _exact_keys($raw, [qw(construction first_route second_route)],
        'portable-VHDL evaluation');
    my $construction = $raw->{construction};
    confess "portable-VHDL construction must be one hash\n"
        unless ref($construction) eq 'HASH' && !blessed($construction);
    my $specification = $construction->{specification};
    confess "portable-VHDL construction specification is invalid\n"
        unless ref($specification) eq 'HASH'
            && ($specification->{backend_profile} // '') eq $PROFILE;
    my $level = $specification->{level};
    _selected_level($level);
    my $artifact_root = "$construction->{staging_identity}/backend-output";
    my $first = _emit($raw->{first_route}, $artifact_root);
    my $second = _emit($raw->{second_route}, $artifact_root);
    my $byte_equal = _canonical_json($first) eq _canonical_json($second);
    my ($oracle, $diagnostics) = _artifact_oracle(
        $level, $raw->{first_route}{execution_ir}->as_hashref,
        $first, $artifact_root, $byte_equal,
    );
    push @$diagnostics, _diagnostic(
        'VIAL_SCALE_BACKEND_EMISSION_DETERMINISM_ERROR',
        'independent portable-VHDL emissions were not byte-identical',
        '/artifact_oracle/portable_vhdl',
    ) unless $byte_equal;
    my $rejected = $level eq 'over_limit_v1';
    return _closed_result({
        artifact_root => $artifact_root,
        byte_equal => $byte_equal ? JSON::PP::true : JSON::PP::false,
        diagnostics => $diagnostics,
        observed_outcome =>
            $rejected ? 'backend_limit_rejected' : 'backend_emitted',
        oracle => $oracle,
        rejected => $rejected ? JSON::PP::true : JSON::PP::false,
    });
}

sub _emit($route, $artifact_root) {
    confess "portable-VHDL route must be one hash\n"
        unless ref($route) eq 'HASH' && !blessed($route);
    return FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $PROFILE,
    });
}

sub _artifact_oracle($level, $execution, $emission, $artifact_root, $byte_equal) {
    my $expected = $EXPECTED{$level};
    my $rejected = $level eq 'over_limit_v1';
    my @diagnostics;
    my $add = sub ($message, $path) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_PORTABLE_VHDL_ARTIFACT_ORACLE_ERROR',
            $message, $path,
        );
    };
    my @actual_keys = sort keys %$emission;
    my @result_keys = sort
        @{FSM::VIAL::Backend::VHDLPortableGHDL->result_keys};
    $add->('portable-VHDL result schema is not closed', '/emission')
        unless _canonical_json(\@actual_keys) eq _canonical_json(\@result_keys);
    $add->('portable-VHDL backend profile changed',
        '/emission/backend_profile')
        unless ($emission->{backend_profile} // '') eq $PROFILE;

    my ($artifact_count, $source_count, $source_bytes, $map_count) =
        (0, 0, 0, 0);
    my ($mapped_operations, $mapped_sources, $maximum_identifier) = (0, 0, 0);
    my ($static_count, $passed_static_count) = (0, 0);
    my (@artifact_relpaths, @source_identities, @static_check_identities);
    my $artifact_graph_sha256;

    if ($rejected) {
        my $expected_diagnostics = [{
            code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
            severity => 'error',
            message => 'generated VHDL exceeds the 16 MiB backend cap',
            path => '/artifacts',
        }];
        $add->('adjacent portable-VHDL shape did not reject',
            '/emission/ok') if $emission->{ok};
        $add->('adjacent portable-VHDL status changed',
            '/emission/status') unless ($emission->{status} // '') eq 'error';
        $add->('adjacent portable-VHDL diagnostic changed',
            '/emission/diagnostics')
            unless _canonical_json($emission->{diagnostics})
                eq _canonical_json($expected_diagnostics);
        $add->('adjacent portable-VHDL rejection published artifacts',
            '/emission/artifacts')
            unless ref($emission->{artifacts}) eq 'ARRAY'
                && !@{$emission->{artifacts}};
        for my $field (qw(
            plan_id generated_top operation_id negotiation backend_manifest
            source_map static_validation mapping_matrix review_workflow
            migration_proof
        )) {
            $add->("adjacent rejection retained partial $field evidence",
                "/emission/$field") if defined $emission->{$field};
        }
    }
    else {
        $add->('accepted portable-VHDL shape was rejected',
            '/emission/ok') unless $emission->{ok};
        $add->('accepted portable-VHDL status changed',
            '/emission/status')
            unless ($emission->{status} // '')
                eq 'emitted_structurally_reviewed_unqualified';
        $add->('accepted portable-VHDL emission has diagnostics',
            '/emission/diagnostics')
            unless ref($emission->{diagnostics}) eq 'ARRAY'
                && !@{$emission->{diagnostics}};
        my $artifacts = ref($emission->{artifacts}) eq 'ARRAY'
            ? $emission->{artifacts} : [];
        $add->('portable-VHDL artifacts must be an array',
            '/emission/artifacts') unless ref($emission->{artifacts}) eq 'ARRAY';
        $artifact_count = scalar(@$artifacts);
        @artifact_relpaths = map { $_->{relpath} // '' } @$artifacts;
        $add->('portable-VHDL artifact inventory or order changed',
            '/emission/artifacts')
            unless _canonical_json(\@artifact_relpaths)
                eq _canonical_json(\@ARTIFACT_RELPATHS);
        _validate_artifact_shapes($artifacts, $add);

        my @sources = grep { ($_->{language} // '') eq 'vhdl' } @$artifacts;
        $source_count = scalar(@sources);
        $source_bytes += bytes::length($_->{content}) for @sources;
        @source_identities = map {{
            relpath => $_->{relpath},
            bytes => bytes::length($_->{content}),
            sha256 => sha256_hex($_->{content}),
        }} @sources;
        my @expected_sources = _expected_sources($expected);
        $add->('portable-VHDL source identities changed',
            '/emission/artifacts')
            unless _canonical_json(\@source_identities)
                eq _canonical_json(\@expected_sources);
        $add->('portable-VHDL source byte total changed',
            '/emission/artifacts') unless $source_bytes == $expected->{source_bytes};

        my $source_map = ref($emission->{source_map}) eq 'HASH'
            ? $emission->{source_map} : {artifacts => [], entries => []};
        $add->('portable-VHDL source map is missing',
            '/emission/source_map') unless ref($emission->{source_map}) eq 'HASH';
        my @source_map_keys = sort keys %$source_map;
        my @expected_source_map_keys = sort
            @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_keys};
        $add->('portable-VHDL source-map schema is not closed',
            '/emission/source_map')
            unless _canonical_json(\@source_map_keys)
                eq _canonical_json(\@expected_source_map_keys);
        my $entries = ref($source_map->{entries}) eq 'ARRAY'
            ? $source_map->{entries} : [];
        my $map_artifacts = ref($source_map->{artifacts}) eq 'ARRAY'
            ? $source_map->{artifacts} : [];
        $map_count = scalar(@$entries);
        $mapped_sources = scalar(@$map_artifacts);
        $add->('portable-VHDL source-map count changed',
            '/emission/source_map/entries')
            unless $map_count == $expected->{source_maps};
        my %source_by_path = map { $_->{relpath} => $_ } @sources;
        my %source_line_count = map {
            $_->{relpath} => scalar(() = $_->{content} =~ /\n/g)
        } @sources;
        _validate_source_map_artifacts($map_artifacts, \@sources, $add);
        my ($mapped, $maximum) = _validate_source_map_entries(
            $entries, \%source_by_path, \%source_line_count, $add,
        );
        $mapped_operations = $mapped;
        $maximum_identifier = $maximum;
        my @expected_operation_ids = sort map {
            $_->{operation_id}
        } @{$execution->{operation_graph}{operations}};
        my %mapped_operation_ids = map {
            map { m{\Aoperation/} ? ($_ => 1) : () }
                @{$_->{semantic_paths} || []}
        } @$entries;
        my @mapped_operation_ids = sort keys %mapped_operation_ids;
        $add->('portable-VHDL operation-map identities changed',
            '/emission/source_map/entries')
            unless _canonical_json(\@mapped_operation_ids)
                eq _canonical_json(\@expected_operation_ids);
        my $top = $emission->{generated_top};
        $add->('generated top identifier is not legal',
            '/emission/generated_top') unless _legal_identifier($top);
        my $top_bytes = defined($top) && !ref($top)
            ? bytes::length($top) : 0;
        $maximum_identifier = $top_bytes
            if $top_bytes > $maximum_identifier;
        $add->('portable-VHDL operation maps are incomplete',
            '/emission/source_map/entries')
            unless $mapped_operations == $expected->{operations};
        $add->('portable-VHDL generated identifier maximum changed',
            '/emission/source_map/entries')
            unless $maximum_identifier == $OBSERVED_IDENTIFIER_MAXIMUM;
        $add->('portable-VHDL generated identifier limit was exceeded',
            '/emission/source_map/entries')
            if $maximum_identifier > $IDENTIFIER_LIMIT;

        my $static = ref($emission->{static_validation}) eq 'HASH'
            ? $emission->{static_validation} : {checks => []};
        $add->('portable-VHDL static validation is missing',
            '/emission/static_validation')
            unless ref($emission->{static_validation}) eq 'HASH';
        _validate_static_validation($static, $add);
        my $checks = ref($static->{checks}) eq 'ARRAY' ? $static->{checks} : [];
        $static_count = scalar(@$checks);
        $passed_static_count = scalar(grep {
            ($_->{status} // '') eq 'passed'
        } @$checks);
        @static_check_identities = map { $_->{check} // '' } @$checks;

        _validate_evidence_artifacts(
            $artifacts, $emission, $source_map, $static, $add,
        );
        $artifact_graph_sha256 = sha256_hex(_canonical_json($artifacts));
    }

    return ({
        schema => $ORACLE_SCHEMA,
        schema_version => 1,
        backend_profile => $PROFILE,
        level => $level,
        requested_operation_total => 0 + $expected->{operations},
        observed_outcome =>
            $rejected ? 'backend_limit_rejected' : 'backend_emitted',
        artifact_root => $artifact_root,
        artifact_count => $artifact_count,
        source_artifact_count => $source_count,
        source_bytes => $source_bytes,
        source_map_entries => $map_count,
        mapped_operation_count => $mapped_operations,
        source_artifact_map_count => $mapped_sources,
        static_validation_checks => $static_count,
        passed_static_validation_checks => $passed_static_count,
        static_check_identities => \@static_check_identities,
        artifact_relpaths => \@artifact_relpaths,
        source_identities => \@source_identities,
        maximum_generated_identifier_bytes => $maximum_identifier,
        generated_identifier_limit_bytes => $IDENTIFIER_LIMIT,
        artifact_graph_sha256 => $artifact_graph_sha256,
        byte_equal_rerun => $byte_equal ? JSON::PP::true : JSON::PP::false,
        in_memory_only => JSON::PP::true,
        atomic_rejection => $rejected ? JSON::PP::true : JSON::PP::false,
        diagnostics => _clone($emission->{diagnostics}),
    }, \@diagnostics);
}

sub _validate_artifact_shapes($artifacts, $add) {
    my %seen;
    my @expected_keys = sort qw(
        content encoding generated_from kind language relpath role source_layer
    );
    for my $index (0 .. $#$artifacts) {
        my $artifact = $artifacts->[$index];
        my @keys = sort keys %$artifact;
        $add->('portable-VHDL artifact schema is not closed',
            "/emission/artifacts/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@expected_keys);
        $add->('portable-VHDL artifact path is unsafe',
            "/emission/artifacts/$index/relpath")
            unless _safe_relative_path($artifact->{relpath});
        $add->('portable-VHDL artifact path is duplicated',
            "/emission/artifacts/$index/relpath")
            if $seen{$artifact->{relpath} // ''}++;
    }
}

sub _expected_sources($expected) {
    return (
        {
            relpath => $SOURCE_RELPATHS[0], bytes => $expected->{metadata_bytes},
            sha256 => $expected->{metadata_sha256},
        },
        {
            relpath => $SOURCE_RELPATHS[1], bytes => 591,
            sha256 =>
                '7a7e3b4e81fd222e53e2098653fcf1131f1b58dbeba35698c1cfe67a4fab5b56',
        },
        {
            relpath => $SOURCE_RELPATHS[2], bytes => 46_264,
            sha256 =>
                'bc45987685e0e2fcf1adb5bbb0a20110dbdcc695ee1c556b1bee41c5b953f8d5',
        },
        {
            relpath => $SOURCE_RELPATHS[3], bytes => 47_670,
            sha256 =>
                '8d93b0ade4d9561d19fdd12ab10b4d8ba1a3dc06de9f911d1c0d8d1bf18518cf',
        },
        {
            relpath => $SOURCE_RELPATHS[4], bytes => 2_191,
            sha256 =>
                'de60b5cdbcf2bd2efd9e9ac28938782e3a0df22ca4d7a14183481700f687e1b2',
        },
        {
            relpath => $SOURCE_RELPATHS[5], bytes => 6_025,
            sha256 =>
                '3777706b911ce90c9a3b05107233ec925c1029b175932ed10f1b1a588fb3c08e',
        },
    );
}

sub _validate_source_map_artifacts($actual, $sources, $add) {
    my @expected = map {{
        relpath => $_->{relpath}, kind => $_->{kind}, role => $_->{role},
        sha256 => sha256_hex($_->{content}),
        bytes => bytes::length($_->{content}),
    }} @$sources;
    my @sorted = sort { $a->{relpath} cmp $b->{relpath} } @$actual;
    $add->('portable-VHDL source-map artifact closure changed',
        '/emission/source_map/artifacts')
        unless _canonical_json(\@sorted) eq _canonical_json(\@expected);
}

sub _validate_source_map_entries($entries, $source_by_path, $line_count, $add) {
    my %mapped_operation;
    my $maximum_identifier = 0;
    my @entry_keys = sort
        @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_entry_keys};
    for my $index (0 .. $#$entries) {
        my $entry = $entries->[$index];
        my @keys = sort keys %$entry;
        $add->('portable-VHDL source-map entry is not closed',
            "/emission/source_map/entries/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@entry_keys);
        my $relpath = $entry->{generated_relpath} // '';
        if (!$source_by_path->{$relpath}) {
            $add->('source-map entry names a non-source artifact',
                "/emission/source_map/entries/$index/generated_relpath");
        }
        else {
            $add->('source-map entry has an invalid generated line span',
                "/emission/source_map/entries/$index")
                unless ($entry->{generated_start_line} // 0) >= 1
                    && ($entry->{generated_end_line} // 0)
                        >= $entry->{generated_start_line}
                    && $entry->{generated_end_line} <= $line_count->{$relpath};
        }
        my $symbol = $entry->{generated_symbol};
        $add->('source-map generated identifier is not legal VHDL',
            "/emission/source_map/entries/$index/generated_symbol")
            unless _legal_identifier($symbol);
        my $symbol_bytes = defined($symbol) && !ref($symbol)
            ? bytes::length($symbol) : 0;
        $maximum_identifier = $symbol_bytes
            if $symbol_bytes > $maximum_identifier;
        $mapped_operation{$_} = 1
            for grep { m{\Aoperation/} } @{$entry->{semantic_paths} || []};
    }
    return (scalar(keys %mapped_operation), $maximum_identifier);
}

sub _validate_static_validation($static, $add) {
    my @expected_keys = sort qw(
        artifacts backend_profile checks diagnostics ok status validator_schema
    );
    my @actual_keys = sort keys %$static;
    $add->('portable-VHDL static-validation schema is not closed',
        '/emission/static_validation')
        unless _canonical_json(\@actual_keys) eq _canonical_json(\@expected_keys);
    $add->('portable-VHDL static validation did not pass',
        '/emission/static_validation/ok') unless $static->{ok};
    $add->('portable-VHDL static-validation status changed',
        '/emission/static_validation/status')
        unless ($static->{status} // '') eq 'passed';
    $add->('portable-VHDL static-validation profile changed',
        '/emission/static_validation/backend_profile')
        unless ($static->{backend_profile} // '') eq $PROFILE;
    $add->('portable-VHDL static-validation schema identity changed',
        '/emission/static_validation/validator_schema')
        unless ($static->{validator_schema} // '')
            eq 'fsmgen.vial_vhdl_static_validation.v1';
    $add->('portable-VHDL static validation has diagnostics',
        '/emission/static_validation/diagnostics')
        unless ref($static->{diagnostics}) eq 'ARRAY'
            && !@{$static->{diagnostics}};
    my $checks = ref($static->{checks}) eq 'ARRAY' ? $static->{checks} : [];
    my @actual_checks = map { $_->{check} // '' } @$checks;
    $add->('portable-VHDL static-check inventory changed',
        '/emission/static_validation/checks')
        unless _canonical_json(\@actual_checks) eq _canonical_json(\@STATIC_CHECKS);
    for my $index (0 .. $#$checks) {
        my @keys = sort keys %{$checks->[$index]};
        $add->('portable-VHDL static-check schema is not closed',
            "/emission/static_validation/checks/$index")
            unless _canonical_json(\@keys)
                eq _canonical_json([qw(check status)]);
        $add->('portable-VHDL static check did not pass',
            "/emission/static_validation/checks/$index/status")
            unless ($checks->[$index]{status} // '') eq 'passed';
    }
}

sub _validate_evidence_artifacts($artifacts, $emission, $source_map, $static, $add) {
    my %by_path = map { $_->{relpath} => $_ } @$artifacts;
    my $map_artifact =
        $by_path{'backends/vhdl_portable_ghdl/backend-source-map.json'};
    $add->('source-map artifact does not encode the returned source map',
        '/emission/source_map')
        unless $map_artifact
            && $map_artifact->{content} eq _pretty_json($source_map);
    my $static_artifact =
        $by_path{'backends/vhdl_portable_ghdl/evidence/static-validation.json'};
    $add->('static-validation artifact does not encode the returned result',
        '/emission/static_validation')
        unless $static_artifact
            && $static_artifact->{content} eq _pretty_json($static);
    my $manifest_artifact =
        $by_path{'backends/vhdl_portable_ghdl/backend-manifest.json'};
    $add->('manifest artifact does not encode the returned manifest',
        '/emission/backend_manifest')
        unless $manifest_artifact
            && ref($emission->{backend_manifest}) eq 'HASH'
            && $manifest_artifact->{content}
                eq _pretty_json($emission->{backend_manifest});
    return unless ref($emission->{backend_manifest}) eq 'HASH';
    my @referenced = map {{
        relpath => $_->{relpath}, kind => $_->{kind}, role => $_->{role},
        sha256 => sha256_hex($_->{content}),
        bytes => bytes::length($_->{content}),
    }} grep {
        $_->{relpath} ne 'backends/vhdl_portable_ghdl/backend-manifest.json'
    } @$artifacts;
    $add->('portable-VHDL manifest artifact closure changed',
        '/emission/backend_manifest/artifacts')
        unless _canonical_json($emission->{backend_manifest}{artifacts})
            eq _canonical_json(\@referenced);
    $add->('portable-VHDL manifest source-map count changed',
        '/emission/backend_manifest/source_map/entry_count')
        unless ($emission->{backend_manifest}{source_map}{entry_count} // -1)
            == scalar(@{$source_map->{entries}});
    $add->('portable-VHDL manifest source-map digest changed',
        '/emission/backend_manifest/source_map/sha256')
        unless ($emission->{backend_manifest}{source_map}{sha256} // '')
            eq sha256_hex(_pretty_json($source_map));
}

sub _closed_result($value) {
    _exact_keys($value, \@RESULT_KEYS, 'portable-VHDL evaluation result');
    return _clone($value);
}

sub _selected_level($level) {
    confess "unknown portable-VHDL level\n"
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
    confess "portable-VHDL oracle contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
