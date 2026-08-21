package FSM::VIAL::ArchitectureScaleBackendEmission::NativeUVM;

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

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMStaticValidator;

my $PROFILE = 'sv_uvm_emit.accellera_2020_3_1';
my $ORACLE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_native_uvm_oracle.v1';
my $SCALE_SOURCE =
    'vial/ahb_subordinate_base_output_arbitration_1.vial';
my $IDENTIFIER_LIMIT = 255;
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
    source_artifact_map_count artifact_relpaths source_identities
    static_validation_checks passed_static_validation_checks
    static_check_identities selected_mapping_count selected_mapping_identities
    review_workflow_stage_count review_workflow_stage_identities
    review_workflow_check_count maximum_generated_identifier_bytes
    generated_identifier_limit_bytes artifact_graph_sha256 byte_equal_rerun
    in_memory_only atomic_rejection preflight_dominated
    preprocessing_executed compile_executed runtime_executed result_produced
    manual_review_complete diagnostics
);
my @ARTIFACT_RELPATHS = qw(
    backends/sv_uvm_emit.accellera_2020_3_1/backend-manifest.json
    backends/sv_uvm_emit.accellera_2020_3_1/backend-source-map.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/methodology-profile.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/review-workflow.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/selected-mapping-matrix.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/static-validation.json
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_checking_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_if.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_notifications_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_services_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_sva_checker.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_tb.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/dut/ahb-lite-subordinate.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_components_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_types_pkg.sv
);
my @STATIC_CHECKS = qw(
    closed_safe_artifact_graph required_source_roles bounded_input
    deterministic_text_shape simulator_neutral_source
    balanced_generated_constructs selected_uvm_foundation_shape
    selected_notification_interception_shape
    selected_lifecycle_topology_shape selected_stimulus_service_shape
    selected_checking_result_shape selected_bound_sva_shape
    selected_tlm_factory_config_ral_wiring root_owned_objection_policy
);
my @MAPPING_IDS = qw(
    mapping/active-agent-driver mapping/analysis-tlm
    mapping/bound-sva-properties mapping/bounded-scoreboard
    mapping/complete-component-topology mapping/component-bases
    mapping/constrained-decision-replay mapping/declared-fault-interception
    mapping/dut-binding mapping/event-models mapping/fixture-config
    mapping/fixture-environment mapping/fixture-test
    mapping/functional-coverage mapping/lifecycle-execution
    mapping/notification-interception mapping/ral-preview
    mapping/result-collection mapping/scenario-sequences
    mapping/scoped-factory-configuration mapping/structured-diagnostics
    mapping/timed-interface mapping/top mapping/transaction-items
    mapping/typed-context
);
my @WORKFLOW_STAGES = qw(
    regenerate byte_compare static_shape visual_review defect_capture
    experimental_compile qualified_runtime
);
my @SOURCE_IDENTITIES = (
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_checking_pkg.sv',
        12_061,
        '95d357b400fdc0de288127c21b4fa5e6aa6f7705ca25fb1d7bd98dffcad6ecd1'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_if.sv',
        920,
        'ff0c9a77f2d4b523b6a39befd99fbac47fbec7670a2c355058ba1352373cfa28'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_notifications_pkg.sv',
        17_020,
        'b8d7c392e91728bce5003c7dfc59cf71bc52c79151ca2ef3cd7f40bad5008000'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_pkg.sv',
        34_481,
        'b8106068cc4e575fc54c42a69fb14a28c3853c68e023a87aa26616079c22de67'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_services_pkg.sv',
        9_999,
        '085f636d502a8d9941252d1280c91add416861e6473582b97117faa6bf7ef98e'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_sva_checker.sv',
        920,
        '28897c83fcc8d6ff2472958c828f032de761a2b756921e409d0938b8c3e2a0f7'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_tb.sv',
        1_099,
        'b7bd24c204605d88c4a75a6ae1debecdf4b80e5c3f51b00bca975becb98f5bdf'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/dut/ahb-lite-subordinate.sv',
        57_531,
        'eeaa8a687a3a1ce010446f848ca6785538dd907e4c567a91ee6049cc4e079f82'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_components_pkg.sv',
        1_759,
        'bcc02c2564ed999e7e42eb29c0d72ad48162a261e41495bed7ab5e7a61c08e42'),
    _identity(
        'backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_types_pkg.sv',
        2_555,
        '38adc9b28875bc5b1d27a8118cb7460c0792609b6af41eee7ec32a4b7f6e61b4'),
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
    return $args[0] eq 'reference_v1' ? 21 : 22;
}

sub canonical_vial_source($class, @args) {
    _exact_invocant($class, 'canonical_vial_source');
    confess __PACKAGE__ . "->canonical_vial_source expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my $raw = $args[0];
    _exact_keys($raw, [qw(level reference_relative_path reference_text)],
        'native-UVM source request');
    _selected_level($raw->{level});
    confess "native-UVM reference path must be a scalar\n"
        unless defined($raw->{reference_relative_path})
            && !ref($raw->{reference_relative_path});
    confess "native-UVM reference text must be a scalar\n"
        unless defined($raw->{reference_text}) && !ref($raw->{reference_text});
    return [$raw->{reference_relative_path}, $raw->{reference_text}]
        if $raw->{level} eq 'reference_v1';

    my $needle = '              (scoreboard_check writes)))';
    my $insertion =
        '              (expect scale_response_00000000'
        . ' (same (sample response) #b0))' . "\n";
    my $source = $raw->{reference_text};
    my $matches = $source =~ s/\Q$needle\E/$insertion$needle/;
    confess "anchored native-UVM rejection insertion point is not unique\n"
        unless $matches == 1;
    return [$SCALE_SOURCE, $source];
}

sub evaluate($class, @args) {
    confess "native-UVM profile evaluation is caller-sealed\n"
        unless caller eq 'FSM::VIAL::ArchitectureScaleBackendEmission';
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my $raw = $args[0];
    _exact_keys($raw, [qw(construction first_route second_route)],
        'native-UVM evaluation');
    my $construction = $raw->{construction};
    confess "native-UVM construction must be one hash\n"
        unless ref($construction) eq 'HASH' && !blessed($construction);
    my $specification = $construction->{specification};
    confess "native-UVM construction specification is invalid\n"
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
        'independent native-UVM emissions were not byte-identical',
        '/artifact_oracle/native_uvm',
    ) unless $byte_equal;
    my $rejected = $level ne 'reference_v1';
    my $observed = $rejected
        ? ($level eq 'gate_candidate_v1'
            ? 'backend_negotiation_rejected'
            : 'preflight_dominated_not_constructed')
        : 'backend_emitted_review_only';
    return _closed_result({
        artifact_root => $artifact_root,
        byte_equal => $byte_equal ? JSON::PP::true : JSON::PP::false,
        diagnostics => $diagnostics,
        observed_outcome => $observed,
        oracle => $oracle,
        rejected => $rejected ? JSON::PP::true : JSON::PP::false,
    });
}

sub _emit($route, $artifact_root) {
    confess "native-UVM route must be one hash\n"
        unless ref($route) eq 'HASH' && !blessed($route);
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $PROFILE,
    });
}

sub _artifact_oracle($level, $execution, $emission, $artifact_root, $byte_equal) {
    my $rejected = $level ne 'reference_v1';
    my @diagnostics;
    my $add = sub ($message, $path) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_NATIVE_UVM_ARTIFACT_ORACLE_ERROR', $message, $path,
        );
    };
    my @actual_keys = sort keys %$emission;
    my @result_keys = sort
        @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->result_keys};
    $add->('native-UVM result schema is not closed', '/emission')
        unless _canonical_json(\@actual_keys) eq _canonical_json(\@result_keys);
    $add->('native-UVM backend profile changed', '/emission/backend_profile')
        unless ($emission->{backend_profile} // '') eq $PROFILE;

    my ($artifact_count, $source_count, $source_bytes, $map_count) =
        (0, 0, 0, 0);
    my ($mapped_operations, $mapped_sources, $maximum_identifier) = (0, 0, 0);
    my ($static_count, $passed_static, $mapping_count) = (0, 0, 0);
    my ($workflow_stage_count, $workflow_check_count) = (0, 0);
    my (@artifact_relpaths, @source_identities, @static_ids, @mapping_ids,
        @workflow_ids);
    my $artifact_graph_sha256;

    if ($rejected) {
        my $expected_diagnostics = [{
            code => 'VIAL_UVM_BACKEND_UNSUPPORTED',
            severity => 'error',
            message =>
                'native UVM foundation negotiation rejected one or more requirements',
            path => '/negotiation',
        }];
        $add->('unsupported native-UVM shape did not reject', '/emission/ok')
            if $emission->{ok};
        $add->('unsupported native-UVM status changed', '/emission/status')
            unless ($emission->{status} // '') eq 'error';
        $add->('unsupported native-UVM diagnostic changed',
            '/emission/diagnostics')
            unless _canonical_json($emission->{diagnostics})
                eq _canonical_json($expected_diagnostics);
        $add->('unsupported native-UVM rejection published artifacts',
            '/emission/artifacts')
            unless ref($emission->{artifacts}) eq 'ARRAY'
                && !@{$emission->{artifacts}};
        for my $field (qw(
            plan_id generated_top operation_id backend_manifest source_map
            static_validation mapping_matrix review_workflow
        )) {
            $add->("unsupported rejection retained partial $field evidence",
                "/emission/$field") if defined $emission->{$field};
        }
        my $negotiation = $emission->{negotiation};
        my $expected_unsatisfied = [
            'native UVM selected review matrix requires the exact 21-operation reference shape'
        ];
        $add->('unsupported native-UVM negotiation evidence is missing',
            '/emission/negotiation') unless ref($negotiation) eq 'HASH';
        $add->('unsupported native-UVM requirement changed',
            '/emission/negotiation/unsatisfied')
            unless ref($negotiation) eq 'HASH'
                && _canonical_json($negotiation->{unsatisfied})
                    eq _canonical_json($expected_unsatisfied);
        $add->('unsupported native-UVM negotiation claimed satisfaction',
            '/emission/negotiation/satisfied')
            unless ref($negotiation) eq 'HASH'
                && ref($negotiation->{satisfied}) eq 'ARRAY'
                && !@{$negotiation->{satisfied}};
    }
    else {
        $add->('selected native-UVM shape was rejected', '/emission/ok')
            unless $emission->{ok};
        $add->('selected native-UVM status changed', '/emission/status')
            unless ($emission->{status} // '') eq 'emitted_unqualified';
        $add->('selected native-UVM emission has diagnostics',
            '/emission/diagnostics')
            unless ref($emission->{diagnostics}) eq 'ARRAY'
                && !@{$emission->{diagnostics}};
        my $artifacts = ref($emission->{artifacts}) eq 'ARRAY'
            ? $emission->{artifacts} : [];
        $add->('native-UVM artifacts must be an array', '/emission/artifacts')
            unless ref($emission->{artifacts}) eq 'ARRAY';
        $artifact_count = scalar(@$artifacts);
        @artifact_relpaths = map { $_->{relpath} // '' } @$artifacts;
        $add->('native-UVM artifact inventory or order changed',
            '/emission/artifacts')
            unless _canonical_json(\@artifact_relpaths)
                eq _canonical_json(\@ARTIFACT_RELPATHS);
        _validate_artifact_shapes($artifacts, $add);

        my @sources = grep {
            ($_->{language} // '') eq 'systemverilog'
        } @$artifacts;
        $source_count = scalar(@sources);
        $source_bytes += bytes::length($_->{content}) for @sources;
        @source_identities = map {{
            relpath => $_->{relpath},
            bytes => bytes::length($_->{content}),
            sha256 => sha256_hex($_->{content}),
        }} @sources;
        $add->('native-UVM source identities changed', '/emission/artifacts')
            unless _canonical_json(\@source_identities)
                eq _canonical_json(\@SOURCE_IDENTITIES);
        $add->('native-UVM source byte total changed', '/emission/artifacts')
            unless $source_bytes == 138_345;

        my $source_map = ref($emission->{source_map}) eq 'HASH'
            ? $emission->{source_map} : {artifacts => [], entries => []};
        $add->('native-UVM source map is missing', '/emission/source_map')
            unless ref($emission->{source_map}) eq 'HASH';
        my @source_map_keys = sort keys %$source_map;
        my @expected_source_map_keys = sort
            @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->source_map_keys};
        $add->('native-UVM source-map schema is not closed',
            '/emission/source_map')
            unless _canonical_json(\@source_map_keys)
                eq _canonical_json(\@expected_source_map_keys);
        my $entries = ref($source_map->{entries}) eq 'ARRAY'
            ? $source_map->{entries} : [];
        my $map_artifacts = ref($source_map->{artifacts}) eq 'ARRAY'
            ? $source_map->{artifacts} : [];
        $map_count = scalar(@$entries);
        $mapped_sources = scalar(@$map_artifacts);
        $add->('native-UVM source-map count changed',
            '/emission/source_map/entries') unless $map_count == 75;
        my %source_by_path = map { $_->{relpath} => $_ } @sources;
        my %source_line_count = map {
            $_->{relpath} => scalar(() = $_->{content} =~ /\n/g)
        } @sources;
        _validate_source_map_artifacts($map_artifacts, \@sources, $add);
        ($mapped_operations, $maximum_identifier) =
            _validate_source_map_entries(
                $entries, \%source_by_path, \%source_line_count,
                $execution, $add,
            );
        $add->('native-UVM selected operation associations changed',
            '/emission/source_map/entries') unless $mapped_operations == 6;
        $add->('native-UVM generated identifier maximum changed',
            '/emission/source_map/entries') unless $maximum_identifier == 49;
        $add->('native-UVM generated identifier limit was exceeded',
            '/emission/source_map/entries')
            if $maximum_identifier > $IDENTIFIER_LIMIT;

        my $static = $emission->{static_validation};
        my @static_keys = ref($static) eq 'HASH' ? sort keys %$static : ();
        my @expected_static_keys = sort
            @{FSM::VIAL::Backend::SVUVMStaticValidator->result_keys};
        $add->('native-UVM static-validation schema is not closed',
            '/emission/static_validation')
            unless ref($static) eq 'HASH'
                && _canonical_json(\@static_keys)
                    eq _canonical_json(\@expected_static_keys);
        my $checks = ref($static) eq 'HASH'
                && ref($static->{checks}) eq 'ARRAY' ? $static->{checks} : [];
        $static_count = scalar(@$checks);
        $passed_static = scalar(grep { ($_->{status} // '') eq 'passed' } @$checks);
        @static_ids = map { $_->{check_id} // '' } @$checks;
        $add->('native-UVM static-check identities changed',
            '/emission/static_validation/checks')
            unless _canonical_json(\@static_ids)
                eq _canonical_json(\@STATIC_CHECKS);
        $add->('native-UVM static validation did not pass exactly',
            '/emission/static_validation')
            unless ref($static) eq 'HASH' && $static->{ok}
                && ($static->{status} // '') eq 'passed'
                && $static_count == 14 && $passed_static == 14;

        my $mappings = ref($emission->{mapping_matrix}) eq 'HASH'
                && ref($emission->{mapping_matrix}{mappings}) eq 'ARRAY'
            ? $emission->{mapping_matrix}{mappings} : [];
        $mapping_count = scalar(@$mappings);
        @mapping_ids = map { $_->{mapping_id} // '' } @$mappings;
        $add->('native-UVM selected-mapping identities changed',
            '/emission/mapping_matrix/mappings')
            unless _canonical_json(\@mapping_ids)
                eq _canonical_json(\@MAPPING_IDS);
        for my $index (0 .. $#$mappings) {
            my $mapping = $mappings->[$index];
            $add->('native-UVM selected-mapping status changed',
                "/emission/mapping_matrix/mappings/$index")
                unless ($mapping->{emission_status} // '') eq 'emitted'
                    && ($mapping->{static_review_status} // '')
                        eq 'passed_structural_only'
                    && ($mapping->{visual_review_status} // '') eq 'pending'
                    && ($mapping->{qualification_status} // '') eq 'not_run';
        }

        my $workflow = $emission->{review_workflow};
        my $stages = ref($workflow) eq 'HASH'
                && ref($workflow->{stages}) eq 'ARRAY'
            ? $workflow->{stages} : [];
        $workflow_stage_count = scalar(@$stages);
        @workflow_ids = map { $_->{stage_id} // '' } @$stages;
        $add->('native-UVM review-workflow stages changed',
            '/emission/review_workflow/stages')
            unless _canonical_json(\@workflow_ids)
                eq _canonical_json(\@WORKFLOW_STAGES);
        my @expected_stage_status = qw(
            ready ready passed_structural_only pending ready not_run not_run
        );
        my @stage_status = map { $_->{status} // '' } @$stages;
        $add->('native-UVM review-workflow status partition changed',
            '/emission/review_workflow/stages')
            unless _canonical_json(\@stage_status)
                eq _canonical_json(\@expected_stage_status);

        my $manifest = $emission->{backend_manifest};
        _validate_manifest_and_evidence(
            $artifacts, $emission, $source_map, $static, $manifest, $add,
        );
        $workflow_check_count = ref($manifest) eq 'HASH'
            ? 0 + ($manifest->{review_workflow}{check_count} // 0) : 0;
        _validate_nonclaims($manifest, $add);
        $artifact_graph_sha256 = sha256_hex(_canonical_json($artifacts));
    }

    my $observed = $rejected
        ? ($level eq 'gate_candidate_v1'
            ? 'backend_negotiation_rejected'
            : 'preflight_dominated_not_constructed')
        : 'backend_emitted_review_only';
    return ({
        schema => $ORACLE_SCHEMA,
        schema_version => 1,
        backend_profile => $PROFILE,
        level => $level,
        requested_operation_total => $rejected ? 22 : 21,
        observed_outcome => $observed,
        artifact_root => $artifact_root,
        artifact_count => $artifact_count,
        source_artifact_count => $source_count,
        source_bytes => $source_bytes,
        source_map_entries => $map_count,
        mapped_operation_count => $mapped_operations,
        source_artifact_map_count => $mapped_sources,
        artifact_relpaths => \@artifact_relpaths,
        source_identities => \@source_identities,
        static_validation_checks => $static_count,
        passed_static_validation_checks => $passed_static,
        static_check_identities => \@static_ids,
        selected_mapping_count => $mapping_count,
        selected_mapping_identities => \@mapping_ids,
        review_workflow_stage_count => $workflow_stage_count,
        review_workflow_stage_identities => \@workflow_ids,
        review_workflow_check_count => $workflow_check_count,
        maximum_generated_identifier_bytes => $maximum_identifier,
        generated_identifier_limit_bytes => $IDENTIFIER_LIMIT,
        artifact_graph_sha256 => $artifact_graph_sha256,
        byte_equal_rerun => $byte_equal ? JSON::PP::true : JSON::PP::false,
        in_memory_only => JSON::PP::true,
        atomic_rejection => $rejected ? JSON::PP::true : JSON::PP::false,
        preflight_dominated => $rejected
            && $level ne 'gate_candidate_v1'
                ? JSON::PP::true : JSON::PP::false,
        preprocessing_executed => JSON::PP::false,
        compile_executed => JSON::PP::false,
        runtime_executed => JSON::PP::false,
        result_produced => JSON::PP::false,
        manual_review_complete => JSON::PP::false,
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
        $add->('native-UVM artifact schema is not closed',
            "/emission/artifacts/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@expected_keys);
        $add->('native-UVM artifact path is unsafe',
            "/emission/artifacts/$index/relpath")
            unless _safe_relative_path($artifact->{relpath});
        $add->('native-UVM artifact path is duplicated',
            "/emission/artifacts/$index/relpath")
            if $seen{$artifact->{relpath} // ''}++;
    }
}

sub _validate_source_map_artifacts($actual, $sources, $add) {
    my @expected = sort { $a->{relpath} cmp $b->{relpath} } map {{
        relpath => $_->{relpath}, kind => $_->{kind}, role => $_->{role},
        sha256 => sha256_hex($_->{content}),
        bytes => bytes::length($_->{content}),
    }} @$sources;
    $add->('native-UVM source-map artifact closure changed',
        '/emission/source_map/artifacts')
        unless _canonical_json($actual) eq _canonical_json(\@expected);
}

sub _validate_source_map_entries(
        $entries, $source_by_path, $line_count, $execution, $add) {
    my %mapped_operation;
    my %operation = map { $_->{operation_id} => 1 }
        @{$execution->{operation_graph}{operations}};
    my %map_id;
    my $maximum_identifier = 0;
    my @entry_keys = sort
        @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->source_map_entry_keys};
    for my $index (0 .. $#$entries) {
        my $entry = $entries->[$index];
        my @keys = sort keys %$entry;
        $add->('native-UVM source-map entry is not closed',
            "/emission/source_map/entries/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@entry_keys);
        my $map_id = $entry->{source_map_id} // '';
        $add->('native-UVM source-map identity is duplicated',
            "/emission/source_map/entries/$index/source_map_id")
            if $map_id{$map_id}++;
        my $relpath = $entry->{generated_relpath} // '';
        if (!$source_by_path->{$relpath}) {
            $add->('source-map entry names a non-source artifact',
                "/emission/source_map/entries/$index/generated_relpath");
        }
        else {
            $add->('source-map entry has an invalid generated span',
                "/emission/source_map/entries/$index")
                unless ($entry->{generated_start_line} // 0) >= 1
                    && ($entry->{generated_end_line} // 0)
                        >= $entry->{generated_start_line}
                    && $entry->{generated_end_line} <= $line_count->{$relpath}
                    && ($entry->{generated_start_column} // 0) >= 1
                    && ($entry->{generated_end_column} // 0)
                        >= $entry->{generated_start_column};
        }
        my $symbol = $entry->{generated_symbol};
        $add->('source-map generated identifier is not legal',
            "/emission/source_map/entries/$index/generated_symbol")
            unless _legal_identifier($symbol);
        my $symbol_bytes = defined($symbol) && !ref($symbol)
            ? bytes::length($symbol) : 0;
        $maximum_identifier = $symbol_bytes
            if $symbol_bytes > $maximum_identifier;
        for my $semantic (@{$entry->{semantic_paths} || []}) {
            next unless $semantic =~ m{\Aoperation/};
            $add->('source-map entry names an unknown operation',
                "/emission/source_map/entries/$index/semantic_paths")
                unless $operation{$semantic};
            $mapped_operation{$semantic} = 1;
        }
    }
    return (scalar(keys %mapped_operation), $maximum_identifier);
}

sub _validate_manifest_and_evidence(
        $artifacts, $emission, $source_map, $static, $manifest, $add) {
    $add->('native-UVM backend manifest is missing',
        '/emission/backend_manifest') unless ref($manifest) eq 'HASH';
    return unless ref($manifest) eq 'HASH';
    my @manifest_keys = sort keys %$manifest;
    my @expected_manifest_keys = sort
        @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->manifest_keys};
    $add->('native-UVM manifest schema is not closed',
        '/emission/backend_manifest')
        unless _canonical_json(\@manifest_keys)
            eq _canonical_json(\@expected_manifest_keys);
    my $expected_limits = {
        selected_units => 1,
        selected_domains => 1,
        generated_source_artifacts => 10,
        generated_source_bytes => 16_777_216,
        total_artifacts => 16,
        source_map_entries => 1_000_000,
        identifier_bytes => 255,
    };
    $add->('native-UVM manifest limits changed',
        '/emission/backend_manifest/limits')
        unless _canonical_json($manifest->{limits})
            eq _canonical_json($expected_limits);
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} } map {{
        relpath => $_->{relpath}, kind => $_->{kind}, role => $_->{role},
        sha256 => sha256_hex($_->{content}),
        bytes => bytes::length($_->{content}),
    }} grep { $_->{role} ne 'backend_manifest' } @$artifacts;
    $add->('native-UVM manifest artifact closure changed',
        '/emission/backend_manifest/artifacts')
        unless _canonical_json($manifest->{artifacts})
            eq _canonical_json(\@referenced);
    my %by_path = map { $_->{relpath} => $_ } @$artifacts;
    my %encoded = (
        'backends/sv_uvm_emit.accellera_2020_3_1/backend-manifest.json'
            => $manifest,
        'backends/sv_uvm_emit.accellera_2020_3_1/backend-source-map.json'
            => $source_map,
        'backends/sv_uvm_emit.accellera_2020_3_1/evidence/static-validation.json'
            => $static,
        'backends/sv_uvm_emit.accellera_2020_3_1/evidence/selected-mapping-matrix.json'
            => $emission->{mapping_matrix},
        'backends/sv_uvm_emit.accellera_2020_3_1/evidence/review-workflow.json'
            => $emission->{review_workflow},
    );
    for my $path (sort keys %encoded) {
        $add->('native-UVM evidence artifact does not encode its returned value',
            "/emission/artifacts/$path")
            unless $by_path{$path}
                && $by_path{$path}{content} eq _pretty_json($encoded{$path});
    }
}

sub _validate_nonclaims($manifest, $add) {
    return unless ref($manifest) eq 'HASH';
    my $capability = $manifest->{capability_evidence};
    $add->('native-UVM capability evidence is missing',
        '/emission/backend_manifest/capability_evidence')
        unless ref($capability) eq 'HASH';
    return unless ref($capability) eq 'HASH';
    my %expected = (
        preprocessing => 'not_run', parse => 'not_run',
        library_compile => 'not_run', fixture_compile => 'not_run',
        elaboration => 'not_run', runtime => 'not_run',
        result => 'not_produced', parity => 'not_evaluated',
        manual_review => 'workflow_available_review_pending',
        review_workflow => 'available_review_pending',
        static_validation => 'passed_structural_only',
        selected_mapping_matrix => 'passed_selected_scope',
    );
    for my $field (sort keys %expected) {
        $add->("native-UVM capability boundary '$field' changed",
            "/emission/backend_manifest/capability_evidence/$field")
            unless ($capability->{$field} // '') eq $expected{$field};
    }
}

sub _identity($relpath, $bytes, $sha256) {
    return {relpath => $relpath, bytes => $bytes, sha256 => $sha256};
}

sub _closed_result($value) {
    _exact_keys($value, \@RESULT_KEYS, 'native-UVM evaluation result');
    return _clone($value);
}

sub _selected_level($level) {
    confess "unknown native-UVM level\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _legal_identifier($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_\$]*\z/;
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
    confess "native-UVM oracle contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
