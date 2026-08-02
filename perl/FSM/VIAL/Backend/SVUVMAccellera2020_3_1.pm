package FSM::VIAL::Backend::SVUVMAccellera2020_3_1;

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

use FSM::VIAL::Backend::SVUVMStaticValidator;
use FSM::VIAL::Backend::SVUVMReviewClosure;

my $BACKEND_PROFILE = 'sv_uvm_emit.accellera_2020_3_1';
my $BACKEND_SCHEMA = 'fsmgen.vial_backend.sv_uvm_emit.accellera_2020_3_1.v1';
my $SOURCE_MAP_SCHEMA = 'fsmgen.vial_uvm_backend_source_map.v1';
my $STATIC_SCHEMA = 'fsmgen.vial_uvm_static_validation.v1';
my $BASE = 'backends/sv_uvm_emit.accellera_2020_3_1';
my $CONTRACT = 'docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md';
my $EMITTER_REVISION = 5;
my $JSON = JSON::PP->new->canonical(1);

my @RESULT_KEYS = qw(
    ok status backend_profile plan_id generated_top operation_id negotiation
    backend_manifest source_map static_validation mapping_matrix review_workflow
    artifacts diagnostics
);
my @MANIFEST_KEYS = qw(
    schema schema_version backend_profile emitter_revision plan_id fixture_id
    generated_top execution_profile methodology_profile capability_evidence
    limitations limits artifacts source_map static_validation mapping_matrix
    review_workflow result cleanup diagnostics
);
my @SOURCE_MAP_KEYS = qw(schema schema_version plan_id artifacts entries);
my @SOURCE_MAP_ENTRY_KEYS = qw(
    source_map_id generated_relpath generated_start_line generated_start_column
    generated_end_line generated_end_column generated_symbol role plan_paths
    semantic_paths bridge_fact_paths source_locations
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub manifest_keys($class) {
    confess __PACKAGE__ . "->manifest_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@MANIFEST_KEYS];
}

sub source_map_keys($class) {
    confess __PACKAGE__ . "->source_map_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@SOURCE_MAP_KEYS];
}

sub source_map_entry_keys($class) {
    confess __PACKAGE__ . "->source_map_entry_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@SOURCE_MAP_ENTRY_KEYS];
}

sub emit($class, @args) {
    return _failure('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'emit requires the exact backend class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'emit expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _emit($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa(__PACKAGE__ . '::Failure');
    return _failure('VIAL_UVM_BACKEND_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _emit($raw) {
    _require_exact_keys($raw, [qw(
        execution_ir bridge_manifest backend_inputs artifact_root backend_profile
    )], 'native UVM emission');
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'bridge_manifest must be an exact HIAL/VIAL bridge manifest object', '/bridge_manifest')
        unless blessed($raw->{bridge_manifest})
            && ref($raw->{bridge_manifest}) eq 'FSM::HIAL::VIALBridge::Manifest';
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'backend_inputs must be one unblessed hash', '/backend_inputs')
        unless ref($raw->{backend_inputs}) eq 'HASH' && !blessed($raw->{backend_inputs});
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'artifact_root must be a safe repository-relative directory', '/artifact_root')
        unless _safe_relpath($raw->{artifact_root});
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        "backend profile must be '$BACKEND_PROFILE'", '/backend_profile')
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;

    my $execution = $raw->{execution_ir}->as_hashref;
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    my $negotiation = _negotiate($execution, $bridge, $raw->{backend_inputs});
    if (@{$negotiation->{unsatisfied}}) {
        return _failure(
            'VIAL_UVM_BACKEND_UNSUPPORTED',
            'native UVM foundation negotiation rejected one or more requirements',
            '/negotiation', $negotiation,
        );
    }

    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $unit = $bridge->{units}[0];
    my $module_name = _backend_name($bridge, $unit->{unit_id}, 'module');
    my $interface_name = $fixture_slug . '_if';
    my $fixture_package = $fixture_slug . '_pkg';
    my $top = $fixture_slug . '_tb';
    my ($plan_digest) = $execution->{plan_id} =~ m{\Aplan/([0-9a-f]{64})\z};
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'execution plan identity is malformed', '/execution_ir/plan_id')
        unless defined $plan_digest;
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => 'emit_native_uvm_matrix_review_closure',
        artifact_root => $raw->{artifact_root},
        backend_profile => $BACKEND_PROFILE,
        bridge_manifest_id => $bridge->{manifest_id},
        emitter_revision => $EMITTER_REVISION,
        plan_id => $execution->{plan_id},
    }));

    my $types_rel = "$BASE/src/fsmgen_vial_uvm_types_pkg.sv";
    my $components_rel = "$BASE/src/fsmgen_vial_uvm_components_pkg.sv";
    my $interface_rel = "$BASE/src/$interface_name.sv";
    my $notification_package = $fixture_slug . '_notifications_pkg';
    my $notification_rel = "$BASE/src/$notification_package.sv";
    my $services_package = $fixture_slug . '_services_pkg';
    my $services_rel = "$BASE/src/$services_package.sv";
    my $checking_package = $fixture_slug . '_checking_pkg';
    my $checking_rel = "$BASE/src/$checking_package.sv";
    my $checker_module = $fixture_slug . '_sva_checker';
    my $checker_rel = "$BASE/src/$checker_module.sv";
    my $fixture_rel = "$BASE/src/$fixture_package.sv";
    my $top_rel = "$BASE/src/$top.sv";
    my $dut_rel = "$BASE/src/dut/" . _slug($module_name) . '.sv';

    my ($types, $types_specs) = _render_types_package($types_rel);
    my ($components, $component_specs) = _render_components_package($components_rel);
    my ($interface, $interface_specs) = _render_interface(
        bridge => $bridge,
        interface_name => $interface_name,
        relpath => $interface_rel,
    );
    my ($notifications, $notification_specs) = _render_notification_package(
        execution => $execution,
        bridge => $bridge,
        package_name => $notification_package,
        relpath => $notification_rel,
    );
    my ($services, $service_specs) = _render_services_package(
        execution => $execution,
        bridge => $bridge,
        package_name => $services_package,
        relpath => $services_rel,
    );
    my ($checking, $checking_specs) = _render_checking_package(
        execution => $execution,
        bridge => $bridge,
        package_name => $checking_package,
        services_package => $services_package,
        relpath => $checking_rel,
    );
    my ($checker, $checker_specs) = _render_sva_checker(
        execution => $execution,
        bridge => $bridge,
        checker_module => $checker_module,
        module_name => $module_name,
        relpath => $checker_rel,
    );
    my ($fixture, $fixture_specs) = _render_fixture_package(
        execution => $execution,
        bridge => $bridge,
        interface_name => $interface_name,
        notification_package => $notification_package,
        services_package => $services_package,
        checking_package => $checking_package,
        package_name => $fixture_package,
        relpath => $fixture_rel,
    );
    my ($top_source, $top_specs) = _render_top(
        execution => $execution,
        bridge => $bridge,
        interface_name => $interface_name,
        package_name => $fixture_package,
        module_name => $module_name,
        top => $top,
        relpath => $top_rel,
    );
    my $dut_input = $raw->{backend_inputs}{dut_systemverilog}[0];

    my @source_artifacts = (
        _artifact($dut_rel, 'systemverilog_source', 'systemverilog',
            'generated_hial_dut', $dut_input->{text}, [$dut_input->{source_id}]),
        _artifact($types_rel, 'systemverilog_source', 'systemverilog',
            'uvm_types_package', $types, [$CONTRACT]),
        _artifact($components_rel, 'systemverilog_source', 'systemverilog',
            'uvm_component_foundations', $components, [$CONTRACT]),
        _artifact($interface_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_interface', $interface, [$execution->{plan_id}, $bridge->{manifest_id}]),
        _artifact($notification_rel, 'systemverilog_source', 'systemverilog',
            'uvm_notification_interception', $notifications, [$execution->{plan_id}, $CONTRACT]),
        _artifact($services_rel, 'systemverilog_source', 'systemverilog',
            'uvm_stimulus_services', $services, [$execution->{plan_id}, $bridge->{manifest_id}, $CONTRACT]),
        _artifact($checking_rel, 'systemverilog_source', 'systemverilog',
            'uvm_checking_results', $checking, [$execution->{plan_id}, $bridge->{manifest_id}, $CONTRACT]),
        _artifact($checker_rel, 'systemverilog_source', 'systemverilog',
            'bound_sva_checker', $checker, [$execution->{plan_id}, $bridge->{manifest_id}, $CONTRACT]),
        _artifact($fixture_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_package', $fixture, [$execution->{plan_id}, $bridge->{manifest_id}]),
        _artifact($top_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_top', $top_source, [$execution->{plan_id}, $bridge->{manifest_id}]),
    );
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content}) for @source_artifacts;
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'generated native UVM source exceeds the 16 MiB backend cap', '/artifacts')
        if $source_bytes > 16_777_216;

    my @spec = (
        @$types_specs, @$component_specs, @$interface_specs, @$notification_specs, @$service_specs,
        @$checking_specs, @$checker_specs, @$fixture_specs, @$top_specs,
        _map_spec(
            relpath => $dut_rel, start => 1, end => _line_count($dut_input->{text}),
            symbol => $module_name, role => 'generated_hial_dut',
            plan_paths => ['/bindings/unit'], semantic_paths => [$unit->{unit_id}],
            bridge_paths => ['/units/0'], locations => [],
        ),
    );
    my %source_text = map { $_->{relpath} => $_->{content} } @source_artifacts;
    my $source_map = {
        schema => $SOURCE_MAP_SCHEMA,
        schema_version => 1,
        plan_id => $execution->{plan_id},
        artifacts => [sort {$a->{relpath} cmp $b->{relpath}}
            map { _artifact_ref($_) } @source_artifacts],
        entries => _source_map_entries(\@spec, \%source_text),
    };
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'native UVM source map exceeds its record cap', '/source_map/entries')
        if @{$source_map->{entries}} > 1_000_000;

    my $static = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => $BACKEND_PROFILE,
        artifacts => \@source_artifacts,
    });
    if (!$static->{ok}) {
        my $detail = join('; ', map { "$_->{code}: $_->{message}" }
            @{$static->{diagnostics}});
        return _failure(
            'VIAL_UVM_BACKEND_STATIC_VALIDATION_ERROR',
            'generated native UVM foundation failed static shape validation: ' . $detail,
            '/static_validation', $negotiation,
        );
    }

    my $review = FSM::VIAL::Backend::SVUVMReviewClosure->build({
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        emitter_revision => $EMITTER_REVISION,
        source_artifacts => \@source_artifacts,
        review_gallery => join('/', qw(
            vial review_gallery sv_uvm_emit.accellera_2020_3_1
            ahb_base_output_foundation
        )),
    });
    if (!$review->{ok}) {
        my $detail = join('; ', map { "$_->{code}: $_->{message}" }
            @{$review->{diagnostics}});
        return _failure(
            'VIAL_UVM_BACKEND_REVIEW_CLOSURE_ERROR',
            'generated native UVM foundation failed matrix/review closure: ' . $detail,
            '/review_closure', $negotiation,
        );
    }

    my $methodology = _methodology_profile();
    my @support_artifacts = (
        _artifact("$BASE/backend-source-map.json", 'source_map', 'json',
            'backend_source_map', _json_text($source_map), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/methodology-profile.json", 'methodology_profile', 'json',
            'selected_methodology_profile', _json_text($methodology), [$CONTRACT]),
        _artifact("$BASE/evidence/static-validation.json", 'validation_report', 'json',
            'static_validation', _json_text($static), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/selected-mapping-matrix.json", 'mapping_matrix', 'json',
            'selected_mapping_matrix', _json_text($review->{mapping_matrix}),
            [$execution->{plan_id}, $CONTRACT]),
        _artifact("$BASE/evidence/review-workflow.json", 'review_workflow', 'json',
            'review_workflow', _json_text($review->{review_workflow}),
            [$execution->{plan_id}, $CONTRACT]),
    );
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} }
        map { _artifact_ref($_) } (@source_artifacts, @support_artifacts);
    my $manifest = {
        schema => $BACKEND_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        emitter_revision => $EMITTER_REVISION,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        generated_top => $top,
        execution_profile => $execution->{profile},
        methodology_profile => {
            relpath => "$BASE/evidence/methodology-profile.json",
            sha256 => sha256_hex(_json_text($methodology)),
            api_target => 'IEEE 1800.2-2020 / Accellera UVM 2020-3.1',
            library_materialization => 'not_required_for_emission',
        },
        capability_evidence => {
            negotiation => _clone($negotiation),
            emission => 'passed',
            static_validation => 'passed_structural_only',
            selected_mapping_matrix => 'passed_selected_scope',
            review_workflow => 'available_review_pending',
            manual_review => 'workflow_available_review_pending',
            preprocessing => 'not_run',
            parse => 'not_run',
            library_compile => 'not_run',
            fixture_compile => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
            library_materialization => 'not_required_for_emission',
            emitted_foundations => [qw(
                typed_context component_bases timed_interface fixture_config
                complete_component_topology lifecycle_execution
                notification_interception fixture_environment fixture_test
                transaction_items scenario_sequences active_agent_driver
                analysis_tlm scoped_factory_configuration ral_preview
                constrained_decision_replay
                functional_coverage bound_sva_properties event_models
                bounded_scoreboard declared_fault_interception
                structured_diagnostics result_collection
                dut_binding top
            )],
            deferred_to_later_emission_slices => [],
            public_authoring_boundary => {
                execution_events => 'public_vial_v1',
                portable_scenarios_transactions_decisions => 'public_vial_v1',
                coverage_models_scoreboards_faults_expectations => 'public_vial_v1',
                bound_sva_translation => 'generated_review_structure',
                structured_result_collection => 'generated_review_structure_not_result_manifest',
                native_interceptor_tables => 'private_typed_preview',
                native_role_substitution => 'private_typed_preview',
                native_ral => 'private_typed_preview',
                native_constraint_solving => 'private_typed_preview_not_executed',
            },
        },
        limitations => [
            'static validation checks deterministic structure only; it is not a SystemVerilog parser or compiler',
            'the selected mapping matrix is complete for the emitted foundations; it is not a claim of full UVM breadth',
            'the deterministic gallery workflow is available, but director or delegated visual review remains pending',
            'the gallery emits selected checking and result-collection structures, but no generated verification result manifest exists until an executed backend qualifies and runs them',
            'native interceptor, role-substitution, and RAL records are private typed previews until public VIAL syntax is selected',
            'portable decisions are replayed from the immutable plan; the emitted native constraint solver preview is not invoked',
            'verification-probe-backed expectations remain source-mapped review structures until a qualified adapter supplies runtime observation',
            'UVM library bytes are intentionally absent from and unnecessary for ordinary emission',
            'preprocessing, parse, library compile, fixture compile, elaboration, runtime, result, and parity have not run',
            'one HIAL unit and one VIAL clock domain are selected for the first review gallery',
        ],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_source_artifacts => 10,
            generated_source_bytes => 16_777_216,
            total_artifacts => 16,
            source_map_entries => 1_000_000,
            identifier_bytes => 255,
        },
        artifacts => \@referenced,
        source_map => {
            schema => $SOURCE_MAP_SCHEMA,
            relpath => "$BASE/backend-source-map.json",
            sha256 => sha256_hex(_json_text($source_map)),
            entry_count => scalar(@{$source_map->{entries}}),
        },
        static_validation => {
            schema => $STATIC_SCHEMA,
            relpath => "$BASE/evidence/static-validation.json",
            sha256 => sha256_hex(_json_text($static)),
            status => $static->{status},
            check_count => scalar(@{$static->{checks}}),
        },
        mapping_matrix => {
            schema => $review->{mapping_matrix}{schema},
            relpath => "$BASE/evidence/selected-mapping-matrix.json",
            sha256 => sha256_hex(_json_text($review->{mapping_matrix})),
            mapping_count => scalar(@{$review->{mapping_matrix}{mappings}}),
            status => 'passed_selected_scope',
        },
        review_workflow => {
            schema => $review->{review_workflow}{schema},
            relpath => "$BASE/evidence/review-workflow.json",
            sha256 => sha256_hex(_json_text($review->{review_workflow})),
            stage_count => scalar(@{$review->{review_workflow}{stages}}),
            check_count => scalar(@{$review->{checks}}),
            status => 'available_review_pending',
        },
        result => {
            schema => 'fsmgen.verification_result_manifest.v1',
            status => 'not_produced',
            relpath => undef,
            sha256 => undef,
        },
        cleanup => {
            staging_identity => ".artifacts/tmp/vial/$operation_id",
            state => 'not_created',
            removed => JSON::PP::false,
        },
        diagnostics => [],
    };
    my $manifest_artifact = _artifact(
        "$BASE/backend-manifest.json", 'backend_manifest', 'json', 'backend_manifest',
        _json_text($manifest), [$execution->{plan_id}, $bridge->{manifest_id}],
    );
    my @artifacts = sort { $a->{relpath} cmp $b->{relpath} }
        ($manifest_artifact, @source_artifacts, @support_artifacts);
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'native UVM artifact graph does not match its sixteen-artifact matrix/review contract', '/artifacts')
        unless @artifacts == 16;

    return _result({
        ok => JSON::PP::true,
        status => 'emitted_unqualified',
        backend_profile => $BACKEND_PROFILE,
        plan_id => $execution->{plan_id},
        generated_top => $top,
        operation_id => $operation_id,
        negotiation => $negotiation,
        backend_manifest => $manifest,
        source_map => $source_map,
        static_validation => $static,
        mapping_matrix => $review->{mapping_matrix},
        review_workflow => $review->{review_workflow},
        artifacts => \@artifacts,
        diagnostics => [],
    });
}

sub _negotiate($execution, $bridge, $backend_inputs) {
    my (@required, @satisfied, @unsatisfied, @deferred);
    push @required, qw(
        fsmgen.vial_execution_ir.v1
        core_directed_single_clock_execution_v1
        fsmgen.hial_vial_bridge_manifest.v1
        one_bound_hial_unit_v1
        one_selected_clock_domain_v1
        deterministic_hial_systemverilog_source_v1
        complete_component_topology_v1
        root_owned_lifecycle_v1
        ordered_notification_interception_v1
        typed_stimulus_sequences_v1
        analysis_tlm_wiring_v1
        scoped_factory_configuration_v1
        ral_preview_v1
        constrained_decision_replay_v1
        functional_coverage_v1
        bound_sva_properties_v1
        deterministic_event_models_v1
        bounded_in_order_scoreboard_v1
        declared_substitution_fault_v1
        structured_diagnostic_result_collection_v1
        selected_mapping_matrix_v1
        deterministic_review_workflow_v1
    );
    push @unsatisfied, 'execution schema must be fsmgen.vial_execution_ir.v1'
        unless ($execution->{schema} // '') eq 'fsmgen.vial_execution_ir.v1';
    push @unsatisfied, 'execution profile must be core_directed_single_clock_execution_v1'
        unless ($execution->{profile} // '') eq 'core_directed_single_clock_execution_v1';
    push @unsatisfied, 'bridge schema must be fsmgen.hial_vial_bridge_manifest.v1'
        unless ($bridge->{schema} // '') eq 'fsmgen.hial_vial_bridge_manifest.v1';
    push @unsatisfied, 'exactly one bound HIAL unit is required'
        unless ref($bridge->{units}) eq 'ARRAY' && @{$bridge->{units}} == 1;
    push @unsatisfied, 'exactly one selected execution domain is required'
        unless ref($execution->{domains}) eq 'ARRAY' && @{$execution->{domains}} == 1;
    push @unsatisfied, 'exactly one typed transaction is required by the first services gallery'
        unless ref($execution->{transactions}) eq 'ARRAY'
            && @{$execution->{transactions}} == 1;
    push @unsatisfied, 'exactly one bridge transaction is required by the first services gallery'
        unless ref($bridge->{transactions}) eq 'ARRAY'
            && @{$bridge->{transactions}} == 1
            && ref($bridge->{transactions}[0]{fields}) eq 'ARRAY';
    push @unsatisfied, 'at least one public start operation is required by the first services gallery'
        unless grep { ($_->{kind} // '') eq 'start' }
            @{$execution->{operation_graph}{operations} || []};
    push @unsatisfied, 'exactly one fixed portable decision is required by the first services gallery'
        unless ref($execution->{randomness}{decisions}) eq 'ARRAY'
            && @{$execution->{randomness}{decisions}} == 1;
    push @unsatisfied, 'exactly one declared verification probe is required by the first RAL preview'
        unless ref($bridge->{probes}) eq 'ARRAY' && @{$bridge->{probes}} == 1;
    if (ref($execution->{transactions}) eq 'ARRAY'
            && @{$execution->{transactions}} == 1
            && ref($bridge->{transactions}) eq 'ARRAY'
            && @{$bridge->{transactions}} == 1
            && ref($bridge->{transactions}[0]{fields}) eq 'ARRAY') {
        my (%bridge_field, %bridge_field_count);
        for my $field (@{$bridge->{transactions}[0]{fields}}) {
            my $name = $field->{name} // '';
            $bridge_field{$name} = $field;
            $bridge_field_count{$name}++;
        }
        for my $field (@{$execution->{transactions}[0]{fields} || []}) {
            my $name = $field->{name} // '';
            push @unsatisfied, "transaction field '$name' lacks one bridge carrier"
                unless ($bridge_field_count{$name} // 0) == 1
                    && ref($bridge_field{$name}) eq 'HASH'
                    && defined($bridge_field{$name}{endpoint_id});
        }
    }
    my (%endpoint_role, %endpoint_role_count);
    for my $endpoint (@{$bridge->{endpoints} || []}) {
        my $role = $endpoint->{role} // '';
        $endpoint_role{$role} = $endpoint;
        $endpoint_role_count{$role}++;
    }
    for my $role (qw(select ready_in ready_out)) {
        push @unsatisfied, "required interface role '$role' lacks one endpoint"
            unless ($endpoint_role_count{$role} // 0) == 1
                && ref($endpoint_role{$role}) eq 'HASH'
                && defined($endpoint_role{$role}{endpoint_id});
    }
    push @unsatisfied, 'native extensions are deferred beyond the first UVM foundation'
        if ref($execution->{native_extensions}) ne 'ARRAY' || @{$execution->{native_extensions} || []};

    my $inputs_ok = eval {
        _require_exact_keys($backend_inputs, [qw(dut_systemverilog)], 'backend inputs');
        confess 'exactly one deterministic DUT source is required'
            unless ref($backend_inputs->{dut_systemverilog}) eq 'ARRAY'
                && @{$backend_inputs->{dut_systemverilog}} == 1;
        my $dut = $backend_inputs->{dut_systemverilog}[0];
        confess 'DUT source must be one unblessed hash'
            unless ref($dut) eq 'HASH' && !blessed($dut);
        confess 'DUT source text or digest is malformed'
            unless defined($dut->{text}) && !ref($dut->{text})
                && defined($dut->{content_sha256}) && !ref($dut->{content_sha256})
                && sha256_hex($dut->{text}) eq $dut->{content_sha256};
        1;
    };
    push @unsatisfied, 'one exact deterministic DUT SystemVerilog source is required'
        unless $inputs_ok;

    my %sv_binding = map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings} || []};
    for my $endpoint (@{$bridge->{endpoints} || []}) {
        my $binding = $sv_binding{$endpoint->{endpoint_id}};
        push @unsatisfied, "endpoint '$endpoint->{endpoint_id}' lacks one declared SystemVerilog binding"
            unless $binding && ($binding->{status} // '') eq 'declared'
                && ($binding->{target_kind} // '') eq 'port'
                && _identifier($binding->{target_name});
    }
    @satisfied = @required unless @unsatisfied;
    @deferred = qw(
        preprocessing parse library_compile fixture_compile elaboration runtime
        result parity
    );
    return {
        negotiation_scope => 'native_uvm_selected_matrix_review_v1',
        required => [sort @required],
        satisfied => [sort @satisfied],
        unsatisfied => [sort @unsatisfied],
        deferred => [sort @deferred],
        limitations => [
            'negotiation covers every foundation in the complete selected review-gallery mapping matrix; full UVM breadth remains explicitly unclaimed',
            'library-dependent and executable gates are deliberately outside ordinary emission',
        ],
    };
}

sub _render_types_package($relpath) {
    my @line;
    my $push = sub (@text) { push @line, @text };
    $push->('// Simulator-neutral native VIAL UVM support.');
    $push->('package fsmgen_vial_uvm_types_pkg;');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_DRIVE_PHASE = 0,');
    $push->('    VIAL_SAMPLE_PHASE = 1,');
    $push->('    VIAL_REACT_PHASE = 2,');
    $push->('    VIAL_CHECK_PHASE = 3');
    $push->('  } vial_phase_e;');
    $push->('');
    $push->('  typedef struct {');
    $push->('    longint unsigned cycle;');
    $push->('    int unsigned ordinal;');
    $push->('    vial_phase_e phase;');
    $push->('  } vial_logical_time_s;');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_LIFECYCLE_CONSTRUCTED = 0,');
    $push->('    VIAL_LIFECYCLE_CONFIGURED = 1,');
    $push->('    VIAL_LIFECYCLE_READY = 2,');
    $push->('    VIAL_LIFECYCLE_RUNNING = 3,');
    $push->('    VIAL_LIFECYCLE_DRAINING = 4,');
    $push->('    VIAL_LIFECYCLE_COMPLETED = 5,');
    $push->('    VIAL_LIFECYCLE_FINALIZED = 6');
    $push->('  } vial_lifecycle_state_e;');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_LIFETIME_FIXTURE = 0,');
    $push->('    VIAL_LIFETIME_SCENARIO = 1,');
    $push->('    VIAL_LIFETIME_TRANSACTION = 2,');
    $push->('    VIAL_LIFETIME_NOTIFICATION = 3,');
    $push->('    VIAL_LIFETIME_OPERATION = 4');
    $push->('  } vial_lifetime_e;');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_REENTRANCY_REJECT = 0,');
    $push->('    VIAL_REENTRANCY_QUEUE = 1');
    $push->('  } vial_reentrancy_e;');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_FILTER_ALWAYS = 0,');
    $push->('    VIAL_FILTER_NEVER = 1,');
    $push->('    VIAL_FILTER_RESPONSE_ERROR = 2');
    $push->('  } vial_filter_e;');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_EFFECT_OBSERVE = 0,');
    $push->('    VIAL_EFFECT_CANCEL = 1,');
    $push->('    VIAL_EFFECT_TRANSFORM_DECLARED_VALUE = 2,');
    $push->('    VIAL_EFFECT_NOTIFY_DECLARED = 3,');
    $push->('    VIAL_EFFECT_RECORD_COVERAGE = 4,');
    $push->('    VIAL_EFFECT_APPEND_DIAGNOSTIC = 5');
    $push->('  } vial_effect_e;');
    $push->('');
    my $class_start = @line + 1;
    $push->('  class fsmgen_vial_execution_context extends uvm_object;');
    $push->('    `uvm_object_utils(fsmgen_vial_execution_context)');
    $push->('');
    $push->('    string plan_id;');
    $push->('    vial_logical_time_s logical_time;');
    $push->('    vial_lifecycle_state_e lifecycle_state;');
    $push->('');
    $push->('    function new(string name = "fsmgen_vial_execution_context");');
    $push->('      super.new(name);');
    $push->('      logical_time = \'{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};');
    $push->('      lifecycle_state = VIAL_LIFECYCLE_CONSTRUCTED;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void set_logical_time(');
    $push->('      longint unsigned cycle,');
    $push->('      vial_phase_e phase,');
    $push->('      int unsigned ordinal = 0');
    $push->('    );');
    $push->('      logical_time.cycle = cycle;');
    $push->('      logical_time.phase = phase;');
    $push->('      logical_time.ordinal = ordinal;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void transition_lifecycle(');
    $push->('      vial_lifecycle_state_e expected,');
    $push->('      vial_lifecycle_state_e next_state');
    $push->('    );');
    $push->('      if (lifecycle_state != expected)');
    $push->('        `uvm_fatal("VIAL/LIFECYCLE", $sformatf("illegal lifecycle transition %0d -> %0d; expected %0d", lifecycle_state, next_state, expected))');
    $push->('      lifecycle_state = next_state;');
    $push->('    endfunction');
    $push->('  endclass');
    $push->('endpackage');
    my $text = join("\n", @line) . "\n";
    return ($text, [_map_spec(
        relpath => $relpath, start => $class_start, end => _line_count($text) - 1,
        symbol => 'fsmgen_vial_execution_context', role => 'typed_execution_context',
        plan_paths => ['/profile', '/operation_graph'], semantic_paths => [],
        bridge_paths => [$CONTRACT], locations => [],
    )]);
}

sub _render_components_package($relpath) {
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Simulator-neutral native VIAL UVM component foundations.');
    $push->('package fsmgen_vial_uvm_components_pkg;');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('');
    my $base_start = @line + 1;
    $push->('  class fsmgen_vial_component_base extends uvm_component;');
    $push->('    `uvm_component_utils(fsmgen_vial_component_base)');
    $push->('');
    $push->('    fsmgen_vial_execution_context vial_context;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->('      if (!uvm_config_db#(fsmgen_vial_execution_context)::get(this, "", "vial_context", vial_context))');
    $push->('        `uvm_fatal("VIAL/CONTEXT", "missing VIAL execution context")');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $base_start, end => scalar(@line),
        symbol => 'fsmgen_vial_component_base', role => 'uvm_component_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');
    my $agent_start = @line + 1;
    $push->('  class fsmgen_vial_agent_base extends uvm_agent;');
    $push->('    `uvm_component_utils(fsmgen_vial_agent_base)');
    $push->('');
    $push->('    fsmgen_vial_execution_context vial_context;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->('      if (!uvm_config_db#(fsmgen_vial_execution_context)::get(this, "", "vial_context", vial_context))');
    $push->('        `uvm_fatal("VIAL/CONTEXT", "missing VIAL execution context")');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $agent_start, end => scalar(@line),
        symbol => 'fsmgen_vial_agent_base', role => 'uvm_agent_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');
    my $env_start = @line + 1;
    $push->('  class fsmgen_vial_env_base extends fsmgen_vial_component_base;');
    $push->('    `uvm_component_utils(fsmgen_vial_env_base)');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $env_start, end => scalar(@line),
        symbol => 'fsmgen_vial_env_base', role => 'uvm_environment_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');
    my $test_start = @line + 1;
    $push->('  class fsmgen_vial_test_base extends uvm_test;');
    $push->('    `uvm_component_utils(fsmgen_vial_test_base)');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $test_start, end => scalar(@line),
        symbol => 'fsmgen_vial_test_base', role => 'uvm_test_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_interface(%arg) {
    my $bridge = $arg{bridge};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = _sv_binding_map($bridge);
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $inactive = $domain->{active_edge} eq 'rising' ? 'negedge' : 'posedge';
    my $active = $domain->{active_edge} eq 'rising' ? 'posedge' : 'negedge';
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated VIAL timed-interface foundation; simulator-neutral IEEE SystemVerilog.');
    $push->("interface $arg{interface_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $endpoint = $bridge->{endpoints}[$index];
        my $name = $binding{$endpoint->{endpoint_id}}{target_name};
        my $record = $type{$endpoint->{type_id}};
        my $start = @line + 1;
        $push->('  logic ' . _packed_type($record) . "$name;");
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => $start,
            symbol => $name, role => $endpoint->{direction} eq 'input'
                ? 'driver_signal_binding' : 'monitor_signal_binding',
            plan_paths => ["/bindings/endpoints/$index"],
            semantic_paths => [$endpoint->{endpoint_id}],
            bridge_paths => ["/endpoints/$index"], locations => [],
        );
    }
    my @driven = map { $binding{$_->{endpoint_id}}{target_name} }
        grep { $_->{direction} eq 'input'
            && $_->{endpoint_id} ne $domain->{clock_endpoint_id}
            && $_->{endpoint_id} ne $domain->{reset_endpoint_id}
            && ($_->{role} // '') ne 'ready_in' }
        @{$bridge->{endpoints}};
    my @sampled = map { $binding{$_->{endpoint_id}}{target_name} }
        grep { $_->{endpoint_id} ne $domain->{clock_endpoint_id} } @{$bridge->{endpoints}};
    $push->('');
    my $driver_start = @line + 1;
    $push->("  clocking driver_cb @($inactive $clock);");
    $push->('    default input #1step output #0;');
    $push->('    output ' . join(', ', @driven) . ';') if @driven;
    $push->('    input ' . join(', ', grep {
        my $candidate = $_;
        !grep { $_ eq $candidate } @driven
    } @sampled) . ';') if grep {
        my $candidate = $_;
        !grep { $_ eq $candidate } @driven
    } @sampled;
    $push->('  endclocking');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $driver_start, end => scalar(@line),
        symbol => 'driver_cb', role => 'logical_drive_clocking_block',
        plan_paths => ['/domains/0', '/operation_graph'],
        semantic_paths => [$domain->{domain_id}], bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    my $monitor_start = @line + 1;
    $push->("  clocking monitor_cb @($active $clock);");
    $push->('    default input #1step;');
    $push->('    input ' . join(', ', @sampled) . ';') if @sampled;
    $push->('  endclocking');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $monitor_start, end => scalar(@line),
        symbol => 'monitor_cb', role => 'logical_sample_clocking_block',
        plan_paths => ['/domains/0', '/operation_graph'],
        semantic_paths => [$domain->{domain_id}], bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    $push->("  modport driver_mp(clocking driver_cb, input $clock);");
    $push->("  modport monitor_mp(clocking monitor_cb, input $clock);");
    $push->('endinterface');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_notification_package(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $payload = $fixture_slug . '_notification_payload';
    my $interceptor = $fixture_slug . '_interceptor';
    my $dispatcher = $fixture_slug . '_notification_dispatcher';
    my $channel = $fixture_slug . '_notification_channel';
    my $registry = $fixture_slug . '_notification_registry';
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = _sv_binding_map($bridge);
    my $clock_endpoint_id = $bridge->{domains}[0]{clock_endpoint_id};
    my @payload_endpoint;
    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $endpoint = $bridge->{endpoints}[$index];
        next if $endpoint->{endpoint_id} eq $clock_endpoint_id;
        my $target_name = $binding{$endpoint->{endpoint_id}}{target_name};
        push @payload_endpoint, {
            %$endpoint,
            bridge_index => $index,
            field_name => _sv_slug($target_name),
            target_name => $target_name,
            type_record => $type{$endpoint->{type_id}},
        };
    }
    my ($response_endpoint) = grep {
        $_->{field_name} eq 'hresp' || ($_->{semantic_id} // '') =~ /::response\z/
    } @payload_endpoint;
    my $response_filter = $response_endpoint
        ? '(data.' . $response_endpoint->{field_name} . " === 1'b1)"
        : "1'b0";

    my (@line, @spec);
    my $push = sub (@text) { push @line, @text };
    my $close_class = sub ($start, $symbol, $role, $plan_paths, $semantic_paths, $locations) {
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => scalar(@line),
            symbol => $symbol, role => $role, plan_paths => $plan_paths,
            semantic_paths => $semantic_paths, bridge_paths => [$CONTRACT],
            locations => $locations,
        );
    };

    $push->('// Generated native VIAL notification/interception structures.');
    $push->('// Interceptor tables are a private typed preview until public VIAL syntax is selected.');
    $push->("package $arg{package_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('');

    my $payload_start = @line + 1;
    $push->("  class $payload extends uvm_object;");
    $push->("    `uvm_object_utils($payload)");
    $push->('');
    $push->('    string notification_id;');
    $push->('    string semantic_id;');
    $push->('    vial_logical_time_s logical_time;');
    for my $endpoint (@payload_endpoint) {
        $push->('    logic ' . _packed_type($endpoint->{type_record}) . $endpoint->{field_name} . ';');
    }
    $push->('');
    $push->("    function new(string name = \"$payload\");");
    $push->('      super.new(name);');
    $push->('      notification_id = "";');
    $push->('      semantic_id = "";');
    $push->("      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};");
    $push->('    endfunction');
    $push->('');
    $push->("    function $payload clone_payload(string suffix = \"copy\");");
    $push->("      $payload copy;");
    $push->('      copy = new({get_name(), "_", suffix});');
    $push->('      copy.notification_id = notification_id;');
    $push->('      copy.semantic_id = semantic_id;');
    $push->('      copy.logical_time = logical_time;');
    for my $endpoint (@payload_endpoint) {
        $push->("      copy.$endpoint->{field_name} = $endpoint->{field_name};");
    }
    $push->('      return copy;');
    $push->('    endfunction');
    $push->('  endclass');
    $close_class->($payload_start, $payload, 'typed_notification_payload',
        ['/events', '/bindings/endpoints'], [$execution->{fixture}{fixture_id}],
        [$execution->{fixture}{source_location}]);
    $push->('');

    my $interceptor_start = @line + 1;
    $push->("  class $interceptor extends uvm_object;");
    $push->("    `uvm_object_utils($interceptor)");
    $push->('');
    $push->('    string semantic_id;');
    $push->('    string registration_scope_id;');
    $push->('    int unsigned rank;');
    $push->('    vial_filter_e filter_kind;');
    $push->('    vial_effect_e effect_kind;');
    $push->('    vial_lifetime_e lifetime;');
    $push->('');
    $push->("    function new(string name = \"$interceptor\");");
    $push->('      super.new(name);');
    $push->('      semantic_id = "";');
    $push->('      registration_scope_id = "";');
    $push->('      rank = 0;');
    $push->('      filter_kind = VIAL_FILTER_NEVER;');
    $push->('      effect_kind = VIAL_EFFECT_OBSERVE;');
    $push->('      lifetime = VIAL_LIFETIME_SCENARIO;');
    $push->('    endfunction');
    $push->('  endclass');
    $close_class->($interceptor_start, $interceptor, 'typed_interceptor_record',
        ['/native_extensions'], [], []);
    $push->('');

    my $dispatcher_start = @line + 1;
    $push->("  class $dispatcher extends uvm_event_callback#($payload);");
    $push->("    `uvm_object_utils($dispatcher)");
    $push->('');
    $push->('    string notification_id;');
    $push->("    protected $interceptor ordered_interceptors[\$];");
    $push->('    protected bit registration_frozen;');
    $push->('    protected bit dispatch_live;');
    $push->("    $payload effective_payload;");
    $push->('    longint unsigned evaluated_count;');
    $push->('    longint unsigned skipped_count;');
    $push->('    longint unsigned observation_count;');
    $push->('    longint unsigned cancellation_count;');
    $push->('    longint unsigned diagnostic_count;');
    $push->('    longint unsigned committed_count;');
    $push->('');
    $push->("    function new(string name = \"$dispatcher\");");
    $push->('      super.new(name);');
    $push->('      registration_frozen = 0;');
    $push->('      dispatch_live = 0;');
    $push->('      evaluated_count = 0;');
    $push->('      skipped_count = 0;');
    $push->('      observation_count = 0;');
    $push->('      cancellation_count = 0;');
    $push->('      diagnostic_count = 0;');
    $push->('      committed_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->("    function void register_interceptor($interceptor candidate);");
    $push->('      int unsigned insert_index;');
    $push->('      if (candidate == null)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/REGISTER", "null interceptor registration")');
    $push->('      if (registration_frozen)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/REGISTER", "late interceptor registration")');
    $push->('      foreach (ordered_interceptors[i]) begin');
    $push->('        if (ordered_interceptors[i].semantic_id == candidate.semantic_id) begin');
    $push->('          if (ordered_interceptors[i].rank == candidate.rank &&');
    $push->('              ordered_interceptors[i].filter_kind == candidate.filter_kind &&');
    $push->('              ordered_interceptors[i].effect_kind == candidate.effect_kind)');
    $push->('            return;');
    $push->('          `uvm_fatal("VIAL/NOTIFY/REGISTER", "non-idempotent duplicate interceptor identity")');
    $push->('        end');
    $push->('        if (ordered_interceptors[i].rank == candidate.rank)');
    $push->('          `uvm_fatal("VIAL/NOTIFY/REGISTER", "duplicate interceptor rank")');
    $push->('      end');
    $push->('      insert_index = ordered_interceptors.size();');
    $push->('      foreach (ordered_interceptors[i]) begin');
    $push->('        if (candidate.rank < ordered_interceptors[i].rank ||');
    $push->('            (candidate.rank == ordered_interceptors[i].rank &&');
    $push->('             candidate.semantic_id < ordered_interceptors[i].semantic_id)) begin');
    $push->('          insert_index = i;');
    $push->('          break;');
    $push->('        end');
    $push->('      end');
    $push->('      ordered_interceptors.insert(insert_index, candidate);');
    $push->('    endfunction');
    $push->('');
    $push->('    function void freeze_registration();');
    $push->('      registration_frozen = 1;');
    $push->('    endfunction');
    $push->('');
    $push->("    protected function bit filter_matches(vial_filter_e filter_kind, $payload data);");
    $push->('      case (filter_kind)');
    $push->("        VIAL_FILTER_ALWAYS: return 1'b1;");
    $push->("        VIAL_FILTER_NEVER: return 1'b0;");
    $push->("        VIAL_FILTER_RESPONSE_ERROR: return $response_filter;");
    $push->("        default: return 1'b0;");
    $push->('      endcase');
    $push->('    endfunction');
    $push->('');
    $push->('    protected function void apply_effect(vial_effect_e effect_kind, ref bit cancelled);');
    $push->('      case (effect_kind)');
    $push->('        VIAL_EFFECT_OBSERVE: observation_count++;');
    $push->("        VIAL_EFFECT_CANCEL: cancelled = 1'b1;");
    $push->('        VIAL_EFFECT_APPEND_DIAGNOSTIC: diagnostic_count++;');
    $push->('        default: `uvm_fatal("VIAL/NOTIFY/EFFECT", "effect is not selected by this typed preview")');
    $push->('      endcase');
    $push->('    endfunction');
    $push->('');
    $push->("    virtual function bit pre_trigger(uvm_event#($payload) event_h, $payload data);");
    $push->('      bit cancelled;');
    $push->('      if (!registration_frozen)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "notification triggered before registration freeze")');
    $push->('      if (dispatch_live)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "target-stack callback recursion is forbidden")');
    $push->('      if (data == null)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "notification payload is null")');
    $push->("      dispatch_live = 1'b1;");
    $push->("      cancelled = 1'b0;");
    $push->('      effective_payload = data.clone_payload("effective");');
    $push->('      foreach (ordered_interceptors[i]) begin');
    $push->('        if (cancelled) begin');
    $push->('          skipped_count++;');
    $push->('          continue;');
    $push->('        end');
    $push->('        evaluated_count++;');
    $push->('        if (filter_matches(ordered_interceptors[i].filter_kind, effective_payload))');
    $push->('          apply_effect(ordered_interceptors[i].effect_kind, cancelled);');
    $push->('      end');
    $push->('      if (cancelled) begin');
    $push->('        cancellation_count++;');
    $push->("        dispatch_live = 1'b0;");
    $push->("        return 1'b1;");
    $push->('      end');
    $push->("      return 1'b0;");
    $push->('    endfunction');
    $push->('');
    $push->("    virtual function void post_trigger(uvm_event#($payload) event_h, $payload data);");
    $push->('      committed_count++;');
    $push->("      dispatch_live = 1'b0;");
    $push->('    endfunction');
    $push->('  endclass');
    $close_class->($dispatcher_start, $dispatcher, 'ordered_notification_dispatcher',
        ['/events', '/native_extensions'], [], []);
    $push->('');

    my $channel_start = @line + 1;
    $push->("  class $channel extends uvm_object;");
    $push->("    `uvm_object_utils($channel)");
    $push->('');
    $push->('    string notification_id;');
    $push->('    string scope_id;');
    $push->('    string persistence;');
    $push->('    string trigger_policy;');
    $push->('    vial_lifetime_e lifetime;');
    $push->('    vial_reentrancy_e reentrancy;');
    $push->('    int unsigned queue_bound;');
    $push->('    longint unsigned occurrence_bound;');
    $push->('    longint unsigned occurrence_count;');
    $push->("    uvm_event#($payload) event_h;");
    $push->("    $dispatcher dispatcher_h;");
    $push->("    protected $payload pending[\$];");
    $push->('    protected bit trigger_live;');
    $push->('');
    $push->("    function new(string name = \"$channel\");");
    $push->('      super.new(name);');
    $push->("      trigger_live = 1'b0;");
    $push->('      occurrence_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void configure(');
    $push->('      string configured_notification_id,');
    $push->('      string configured_scope_id,');
    $push->('      vial_reentrancy_e configured_reentrancy,');
    $push->('      int unsigned configured_queue_bound = 16,');
    $push->('      longint unsigned configured_occurrence_bound = 4096');
    $push->('    );');
    $push->('      notification_id = configured_notification_id;');
    $push->('      scope_id = configured_scope_id;');
    $push->('      persistence = "transient";');
    $push->('      trigger_policy = configured_reentrancy == VIAL_REENTRANCY_QUEUE ? "queued" : "single";');
    $push->('      lifetime = VIAL_LIFETIME_SCENARIO;');
    $push->('      reentrancy = configured_reentrancy;');
    $push->('      queue_bound = configured_queue_bound;');
    $push->('      occurrence_bound = configured_occurrence_bound;');
    $push->("      event_h = new({get_name(), \"_event\"});");
    $push->("      dispatcher_h = ${dispatcher}::type_id::create({get_name(), \"_dispatcher\"});");
    $push->('      dispatcher_h.notification_id = notification_id;');
    $push->('      event_h.add_callback(dispatcher_h);');
    $push->('    endfunction');
    $push->('');
    $push->("    function void register_interceptor($interceptor candidate);");
    $push->('      dispatcher_h.register_interceptor(candidate);');
    $push->('    endfunction');
    $push->('');
    $push->('    function void freeze_registration();');
    $push->('      dispatcher_h.freeze_registration();');
    $push->('    endfunction');
    $push->('');
    $push->("    task trigger_notification($payload data);");
    $push->("      $payload current;");
    $push->('      if (data == null)');
    $push->('        `uvm_fatal("VIAL/NOTIFY/TRIGGER", "notification payload is null")');
    $push->('      if (trigger_live) begin');
    $push->('        if (reentrancy == VIAL_REENTRANCY_REJECT)');
    $push->('          `uvm_fatal("VIAL/NOTIFY/REENTRANCY", "nested notification rejected")');
    $push->('        if (pending.size() >= queue_bound)');
    $push->('          `uvm_fatal("VIAL/NOTIFY/QUEUE", "notification queue bound exceeded")');
    $push->('        pending.push_back(data.clone_payload("queued"));');
    $push->('        return;');
    $push->('      end');
    $push->('      current = data;');
    $push->('      while (current != null) begin');
    $push->('        if (occurrence_count >= occurrence_bound)');
    $push->('          `uvm_fatal("VIAL/NOTIFY/OCCURRENCES", "notification occurrence bound exceeded")');
    $push->("        trigger_live = 1'b1;");
    $push->('        occurrence_count++;');
    $push->('        event_h.trigger(current);');
    $push->("        trigger_live = 1'b0;");
    $push->('        current = pending.size() ? pending.pop_front() : null;');
    $push->('      end');
    $push->('    endtask');
    $push->('  endclass');
    $close_class->($channel_start, $channel, 'bounded_notification_channel',
        ['/events', '/limits'], [], []);
    $push->('');

    my $registry_start = @line + 1;
    $push->("  class $registry extends uvm_object;");
    $push->("    `uvm_object_utils($registry)");
    $push->('');
    $push->("    protected $channel channels[\$];");
    for my $event (@{$execution->{events}}) {
        my $field = _sv_slug($event->{name}) . '_notification';
        my $start = @line + 1;
        $push->("    $channel $field;");
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => $start,
            symbol => $field, role => 'notification_channel_instance',
            plan_paths => ['/events'], semantic_paths => [$event->{semantic_id}],
            bridge_paths => [$event->{event_id}], locations => [$event->{source_location}],
        );
    }
    $push->('');
    $push->("    function new(string name = \"$registry\");");
    $push->('      super.new(name);');
    $push->('    endfunction');
    $push->('');
    $push->("    protected function $interceptor make_interceptor(");
    $push->('      string semantic_id,');
    $push->('      string registration_scope_id,');
    $push->('      int unsigned rank,');
    $push->('      vial_filter_e filter_kind,');
    $push->('      vial_effect_e effect_kind');
    $push->('    );');
    $push->("      $interceptor item;");
    $push->("      item = ${interceptor}::type_id::create({\"interceptor_\", semantic_id});");
    $push->('      item.semantic_id = semantic_id;');
    $push->('      item.registration_scope_id = registration_scope_id;');
    $push->('      item.rank = rank;');
    $push->('      item.filter_kind = filter_kind;');
    $push->('      item.effect_kind = effect_kind;');
    $push->('      item.lifetime = VIAL_LIFETIME_SCENARIO;');
    $push->('      return item;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void configure_preview();');
    for my $index (0 .. $#{$execution->{events}}) {
        my $event = $execution->{events}[$index];
        my $field = _sv_slug($event->{name}) . '_notification';
        my $policy = $index % 2 ? 'VIAL_REENTRANCY_REJECT' : 'VIAL_REENTRANCY_QUEUE';
        my $semantic_id = _sv_string($event->{semantic_id});
        my $event_id = _sv_string($event->{event_id});
        my $scope_id = _sv_string($execution->{fixture}{fixture_id});
        $push->("      $field = ${channel}::type_id::create(\"$field\");");
        $push->("      $field.configure(\"$event_id\", \"$scope_id\", $policy, 16, 4096);");
        $push->("      $field.register_interceptor(make_interceptor(\"${semantic_id}::observe\", \"$scope_id\", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));");
        if (($event->{name} // '') eq 'completed') {
            my $filter = $response_endpoint ? 'VIAL_FILTER_RESPONSE_ERROR' : 'VIAL_FILTER_NEVER';
            $push->("      $field.register_interceptor(make_interceptor(\"${semantic_id}::cancel_error\", \"$scope_id\", 20, $filter, VIAL_EFFECT_CANCEL));");
            $push->("      $field.register_interceptor(make_interceptor(\"${semantic_id}::diagnostic\", \"$scope_id\", 30, VIAL_FILTER_ALWAYS, VIAL_EFFECT_APPEND_DIAGNOSTIC));");
        }
        $push->("      $field.freeze_registration();");
        $push->("      channels.push_back($field);");
    }
    $push->('    endfunction');
    $push->('');
    $push->("    function $channel by_notification_id(string notification_id);");
    $push->('      foreach (channels[i]) begin');
    $push->('        if (channels[i].notification_id == notification_id)');
    $push->('          return channels[i];');
    $push->('      end');
    $push->('      `uvm_fatal("VIAL/NOTIFY/LOOKUP", {"unknown notification ", notification_id})');
    $push->('      return null;');
    $push->('    endfunction');
    $push->('');
    $push->('    function longint unsigned total_occurrences();');
    $push->('      longint unsigned total;');
    $push->('      total = 0;');
    $push->('      foreach (channels[i]) total += channels[i].occurrence_count;');
    $push->('      return total;');
    $push->('    endfunction');
    $push->('  endclass');
    $close_class->($registry_start, $registry, 'generated_notification_registry',
        ['/events', '/fixture'], [$execution->{fixture}{fixture_id}],
        [$execution->{fixture}{source_location}]);

    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_services_package(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the first native UVM services gallery requires exactly one transaction',
        '/execution_ir/transactions')
        unless ref($execution->{transactions}) eq 'ARRAY'
            && @{$execution->{transactions}} == 1;
    my $transaction = $execution->{transactions}[0];
    my %type = map { $_->{type_id} => $_->{semantic_type} }
        @{$execution->{type_table}};
    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $item = $fixture_slug . '_' . _sv_slug($transaction->{definition}{name}) . '_item';
    my $decision_class = $fixture_slug . '_native_wait_decision';
    my $observer = $fixture_slug . '_transaction_observer';
    my $register = $fixture_slug . '_reg_data_reg';
    my $block = $fixture_slug . '_reg_block';
    my $adapter = $fixture_slug . '_reg_adapter';
    my $predictor = $fixture_slug . '_reg_predictor';
    my $probe = $bridge->{probes}[0];
    my $decision = $execution->{randomness}{decisions}[0];
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the first native UVM services gallery requires one declared probe and one fixed decision',
        '/execution_ir')
        unless ref($probe) eq 'HASH' && ref($decision) eq 'HASH';

    my (@line, @spec);
    my $push = sub (@text) { push @line, @text };
    my $map_class = sub ($start, $symbol, $role, $plan_paths, $semantic_paths,
            $bridge_paths, $locations) {
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => scalar(@line),
            symbol => $symbol, role => $role, plan_paths => $plan_paths,
            semantic_paths => $semantic_paths, bridge_paths => $bridge_paths,
            locations => $locations,
        );
    };

    $push->('// Generated native VIAL stimulus and service structures.');
    $push->('// Native role-substitution, RAL, and constraint forms are private typed previews.');
    $push->("package $arg{package_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('');

    my $item_start = @line + 1;
    $push->("  class $item extends uvm_sequence_item;");
    $push->("    `uvm_object_utils($item)");
    $push->('');
    $push->('    string semantic_id;');
    $push->('    string scenario_id;');
    $push->('    string handle_id;');
    for my $field (@{$transaction->{fields}}) {
        my $field_start = @line + 1;
        $push->('    ' . _execution_sv_type($type{$field->{type_id}})
            . _sv_slug($field->{name}) . ';');
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $field_start, end => $field_start,
            symbol => _sv_slug($field->{name}), role => 'transaction_item_field',
            plan_paths => ['/transactions/0/fields'],
            semantic_paths => [$field->{semantic_id}],
            bridge_paths => [$field->{binding_id}], locations => [],
        );
    }
    $push->('');
    $push->("    function new(string name = \"$item\");");
    $push->('      super.new(name);');
    $push->('      semantic_id = "";');
    $push->('      scenario_id = "";');
    $push->('      handle_id = "";');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void do_copy(uvm_object rhs);');
    $push->("      $item rhs_item;");
    $push->('      super.do_copy(rhs);');
    $push->('      if (!$cast(rhs_item, rhs))');
    $push->('        `uvm_fatal("VIAL/ITEM/COPY", "transaction-item type mismatch")');
    $push->('      semantic_id = rhs_item.semantic_id;');
    $push->('      scenario_id = rhs_item.scenario_id;');
    $push->('      handle_id = rhs_item.handle_id;');
    for my $field (@{$transaction->{fields}}) {
        my $name = _sv_slug($field->{name});
        $push->("      $name = rhs_item.$name;");
    }
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);');
    $push->("      $item rhs_item;");
    $push->('      if (!$cast(rhs_item, rhs)) return 0;');
    $push->('      if (!super.do_compare(rhs, comparer)) return 0;');
    $push->('      if (semantic_id != rhs_item.semantic_id ||');
    $push->('          scenario_id != rhs_item.scenario_id ||');
    $push->('          handle_id != rhs_item.handle_id) return 0;');
    for my $index (0 .. $#{$transaction->{fields}}) {
        my $name = _sv_slug($transaction->{fields}[$index]{name});
        my $suffix = $index == $#{$transaction->{fields}} ? ';' : ' ||';
        $push->('      ' . ($index ? '    ' : 'if (')
            . "$name !== rhs_item.$name$suffix");
    }
    $line[-1] =~ s/;\z/\) return 0;/;
    $push->('      return 1;');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void do_print(uvm_printer printer);');
    $push->('      super.do_print(printer);');
    $push->('      printer.print_string("semantic_id", semantic_id);');
    $push->('      printer.print_string("scenario_id", scenario_id);');
    $push->('      printer.print_string("handle_id", handle_id);');
    for my $field (@{$transaction->{fields}}) {
        my $name = _sv_slug($field->{name});
        my $shape = $type{$field->{type_id}};
        my $width = $shape->{kind} eq 'enum'
            ? $shape->{base_type}{width} : $shape->{width};
        $push->("      printer.print_field(\"$name\", $name, $width, UVM_HEX);");
    }
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($item_start, $item, 'typed_sequence_item',
        ['/transactions/0', '/bindings/transactions/0'],
        [$transaction->{semantic_id}], [$transaction->{binding_id}], []);
    $push->('');

    my $decision_start = @line + 1;
    my $decision_type = _execution_sv_type($type{$decision->{type_id}});
    my $low = _sv_scalar_literal($decision->{distribution}{low});
    my $high = _sv_scalar_literal($decision->{distribution}{high});
    $push->("  class $decision_class extends uvm_object;");
    $push->("    `uvm_object_utils($decision_class)");
    $push->('');
    $push->('    string decision_id;');
    $push->('    int unsigned seed;');
    $push->('    int unsigned attempt_bound;');
    $push->('    int unsigned attempt_count;');
    $push->("    rand ${decision_type}candidate;");
    $push->("    ${decision_type}accepted_value;");
    $push->('    bit replayed;');
    $push->('');
    $push->('    constraint selected_domain_c {');
    $push->("      candidate inside {[$low:$high]};");
    $push->('    }');
    $push->('');
    $push->("    function new(string name = \"$decision_class\");");
    $push->('      super.new(name);');
    $push->('      attempt_bound = 64;');
    $push->('      attempt_count = 0;');
    $push->("      accepted_value = $low;");
    $push->("      replayed = 1'b0;");
    $push->('    endfunction');
    $push->('');
    $push->('    function void configure(string configured_id, int unsigned configured_seed);');
    $push->('      decision_id = configured_id;');
    $push->('      seed = configured_seed;');
    $push->('    endfunction');
    $push->('');
    my $replay_start = @line + 1;
    $push->("    function void replay_selected(${decision_type}selected);");
    $push->("      if (!(selected inside {[$low:$high]}))");
    $push->('        `uvm_fatal("VIAL/DECISION/REPLAY", "replayed decision is outside its selected domain")');
    $push->('      accepted_value = selected;');
    $push->("      replayed = 1'b1;");
    $push->('    endfunction');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $replay_start, end => scalar(@line),
        symbol => 'replay_selected', role => 'portable_decision_replay',
        plan_paths => ['/randomness/decisions/0'],
        semantic_paths => [$decision->{occurrence_id}, $decision->{declaration_semantic_id}],
        bridge_paths => [], locations => [$decision->{source_location}],
    );
    $push->('');
    $push->('    function bit solve_native_preview();');
    $push->('      this.srandom(seed);');
    $push->('      for (attempt_count = 1; attempt_count <= attempt_bound; attempt_count++) begin');
    $push->('        if (randomize()) begin');
    $push->('          accepted_value = candidate;');
    $push->("          replayed = 1'b0;");
    $push->('          return 1;');
    $push->('        end');
    $push->('      end');
    $push->('      return 0;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($decision_start, $decision_class,
        'native_constrained_decision_preview', ['/randomness/decisions/0'],
        [$decision->{occurrence_id}, $decision->{declaration_semantic_id}], [],
        [$decision->{source_location}]);
    $push->('');

    my %operation = map { $_->{operation_id} => $_ }
        @{$execution->{operation_graph}{operations}};
    for my $scenario_index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$scenario_index];
        my $sequence = $fixture_slug . '_' . _sv_slug($scenario->{name}) . '_sequence';
        my @start = map { $operation{$_} }
            grep { $operation{$_}{kind} eq 'start' } @{$scenario->{operation_ids}};
        my $sequence_start = @line + 1;
        $push->("  class $sequence extends uvm_sequence#($item);");
        $push->("    `uvm_object_utils($sequence)");
        $push->('');
        $push->("    function new(string name = \"$sequence\");");
        $push->('      super.new(name);');
        $push->('    endfunction');
        $push->('');
        $push->('    virtual task body();');
        $push->("      $item request;");
        my $uses_decision = grep { _operation_uses_decision($_, $decision->{occurrence_id}) } @start;
        $push->("      $decision_class decision;") if $uses_decision;
        if ($uses_decision) {
            my $accepted = _sv_scalar_literal($decision->{value});
            $push->("      decision = ${decision_class}::type_id::create(\"decision\");");
            $push->('      decision.configure("' . _sv_string($decision->{decision_id})
                . '", ' . $decision->{seed} . ');');
            $push->("      decision.replay_selected($accepted);");
        }
        for my $start_index (0 .. $#start) {
            my $op = $start[$start_index];
            my %input = map { $_->{name} => $_->{value} } @{$op->{typed_inputs}};
            my %field = map { $_->{field_id} => $_->{value} } @{$input{fields}};
            $push->("      request = ${item}::type_id::create(\"request_$start_index\");");
            $push->('      start_item(request);');
            $push->('      request.semantic_id = "' . _sv_string($transaction->{semantic_id}) . '";');
            $push->('      request.scenario_id = "' . _sv_string($scenario->{scenario_id}) . '";');
            $push->('      request.handle_id = "' . _sv_string($input{handle_id}) . '";');
            for my $field_record (@{$transaction->{fields}}) {
                my $value = $field{$field_record->{semantic_id}};
                _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
                    "start operation lacks field '$field_record->{semantic_id}'",
                    '/execution_ir/operation_graph') unless ref($value) eq 'HASH';
                my $expression = ($value->{kind} // '') eq 'decision_reference'
                    && ($value->{occurrence_id} // '') eq $decision->{occurrence_id}
                    ? 'decision.accepted_value'
                    : _sv_scalar_literal($value->{value});
                $push->('      request.' . _sv_slug($field_record->{name})
                    . " = $expression;");
            }
            $push->('      finish_item(request);');
        }
        $push->('    endtask');
        $push->('  endclass');
        $map_class->($sequence_start, $sequence, 'scenario_sequence',
            ["/scenarios/$scenario_index", '/operation_graph'],
            [$scenario->{scenario_id}, map { $_->{operation_id} } @start], [],
            [$scenario->{source_location}, map { $_->{source_location} } @start]);
        $push->('');
    }

    my $observer_start = @line + 1;
    $push->("  class $observer extends uvm_subscriber#($item);");
    $push->("    `uvm_component_utils($observer)");
    $push->('');
    $push->('    longint unsigned observation_count;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      observation_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->("    virtual function void write($item transaction);");
    $push->('      if (transaction == null)');
    $push->('        `uvm_fatal("VIAL/TLM/WRITE", "analysis subscriber received a null transaction")');
    $push->('      observation_count++;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($observer_start, $observer, 'analysis_transaction_subscriber',
        ['/transactions/0'], [$transaction->{semantic_id}],
        [$transaction->{binding_id}], []);
    $push->('');

    my $register_start = @line + 1;
    $push->("  class $register extends uvm_reg;");
    $push->("    `uvm_object_utils($register)");
    $push->('');
    $push->('    rand uvm_reg_field value;');
    $push->('');
    $push->("    function new(string name = \"$register\");");
    $push->('      super.new(name, 32, UVM_NO_COVERAGE);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build();');
    $push->('      value = uvm_reg_field::type_id::create("value");');
    $push->('      value.configure(this, 32, 0, "RO", 0, 32\'h00000000, 1, 0, 0);');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($register_start, $register, 'ral_register_preview',
        ['/bindings/probes/0'], [$probe->{probe_id}], ['/probes/0'], []);
    $push->('');

    my $block_start = @line + 1;
    $push->("  class $block extends uvm_reg_block;");
    $push->("    `uvm_object_utils($block)");
    $push->('');
    $push->("    rand $register reg_data;");
    $push->('');
    $push->("    function new(string name = \"$block\");");
    $push->('      super.new(name, UVM_NO_COVERAGE);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build();');
    $push->("      reg_data = ${register}::type_id::create(\"reg_data\");");
    $push->('      reg_data.configure(this);');
    $push->('      reg_data.build();');
    $push->('      default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 1);');
    $push->('      default_map.add_reg(reg_data, 0, "RO");');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($block_start, $block, 'ral_block_preview',
        ['/bindings/probes/0', '/transactions/0'],
        [$probe->{probe_id}, $transaction->{semantic_id}],
        ['/probes/0', '/transactions/0'], []);
    $push->('');

    my $adapter_start = @line + 1;
    my %field_name = map { $_->{name} => _sv_slug($_->{name}) }
        @{$transaction->{fields}};
    $push->("  class $adapter extends uvm_reg_adapter;");
    $push->("    `uvm_object_utils($adapter)");
    $push->('');
    $push->("    function new(string name = \"$adapter\");");
    $push->('      super.new(name);');
    $push->("      supports_byte_enable = 1'b0;");
    $push->("      provides_responses = 1'b0;");
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);');
    $push->("      $item transaction;");
    $push->("      transaction = ${item}::type_id::create(\"ral_request\");");
    $push->('      transaction.semantic_id = "' . _sv_string($transaction->{semantic_id}) . '";');
    $push->("      transaction.$field_name{address} = rw.addr[31:0];");
    $push->("      transaction.$field_name{transfer} = 2'h2;");
    $push->("      transaction.$field_name{write} = (rw.kind == UVM_WRITE);");
    $push->("      transaction.$field_name{size} = 3'h2;");
    $push->("      transaction.$field_name{data} = rw.data[31:0];");
    $push->("      transaction.$field_name{wait_cycles} = 4'h1;");
    $push->('      return transaction;');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);');
    $push->("      $item transaction;");
    $push->('      if (!$cast(transaction, bus_item))');
    $push->('        `uvm_fatal("VIAL/RAL/ADAPTER", "RAL adapter received an incompatible item")');
    $push->("      rw.kind = transaction.$field_name{write} ? UVM_WRITE : UVM_READ;");
    $push->("      rw.addr = transaction.$field_name{address};");
    $push->("      rw.data = transaction.$field_name{data};");
    $push->('      rw.status = UVM_IS_OK;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($adapter_start, $adapter, 'ral_adapter_preview',
        ['/transactions/0'], [$transaction->{semantic_id}],
        [$transaction->{binding_id}], []);
    $push->('');

    my $predictor_start = @line + 1;
    $push->("  class $predictor extends uvm_reg_predictor#($item);");
    $push->("    `uvm_component_utils($predictor)");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($predictor_start, $predictor, 'ral_predictor_preview',
        ['/transactions/0', '/bindings/probes/0'],
        [$transaction->{semantic_id}, $probe->{probe_id}],
        [$transaction->{binding_id}, '/probes/0'], []);
    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _operation_uses_decision($operation, $occurrence_id) {
    return 0 unless ref($operation) eq 'HASH';
    for my $input (@{$operation->{typed_inputs} || []}) {
        next unless ($input->{name} // '') eq 'fields';
        for my $field (@{$input->{value} || []}) {
            my $value = $field->{value};
            return 1 if ref($value) eq 'HASH'
                && ($value->{kind} // '') eq 'decision_reference'
                && ($value->{occurrence_id} // '') eq $occurrence_id;
        }
    }
    return 0;
}

sub _execution_sv_type($shape) {
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'native UVM stimulus fields require one bounded scalar or enum type',
        '/execution_ir/type_table') unless ref($shape) eq 'HASH';
    my $base = ($shape->{kind} // '') eq 'enum' ? $shape->{base_type} : $shape;
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'native UVM stimulus fields require a positive bounded width',
        '/execution_ir/type_table') unless ref($base) eq 'HASH'
            && ($base->{kind} // '') eq 'scalar'
            && defined($base->{width}) && $base->{width} =~ /\A[1-9][0-9]*\z/;
    my $keyword = ($base->{state_domain} // '') eq 'two_state' ? 'bit' : 'logic';
    my $signed = $base->{signed} ? ' signed' : '';
    my $packed = $base->{width} > 1 ? ' [' . ($base->{width} - 1) . ':0]' : '';
    return "$keyword$signed$packed ";
}

sub _sv_scalar_literal($value) {
    my $fully_known = 0;
    if (ref($value) eq 'HASH' && defined($value->{width})
            && $value->{width} =~ /\A[1-9][0-9]*\z/
            && defined($value->{known_hex}) && !ref($value->{known_hex})) {
        my $nibbles = int(($value->{width} + 3) / 4);
        my $leading_bits = $value->{width} % 4;
        my $leading = $leading_bits ? sprintf('%x', (1 << $leading_bits) - 1) : 'f';
        my $expected = $leading . ('f' x ($nibbles - 1));
        $fully_known = lc($value->{known_hex}) eq $expected;
    }
    my $summary = ref($value) eq 'HASH'
        ? join(',', map { $_ . '=' . (defined($value->{$_}) && !ref($value->{$_})
            ? $value->{$_} : '<invalid>') }
            qw(kind width value_hex known_hex z_hex))
        : 'not-a-hash';
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        "native UVM stimulus values require one fully known scalar ($summary)",
        '/execution_ir') unless ref($value) eq 'HASH'
            && ($value->{kind} // '') eq 'scalar'
            && defined($value->{width}) && $value->{width} =~ /\A[1-9][0-9]*\z/
            && defined($value->{value_hex}) && $value->{value_hex} =~ /\A[0-9a-f]+\z/i
            && $fully_known
            && defined($value->{z_hex}) && $value->{z_hex} =~ /\A0+\z/;
    return $value->{width} . "'h" . lc($value->{value_hex});
}

sub _render_checking_package(%arg) {
    my $execution = $arg{execution};
    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $transaction = $execution->{transactions}[0];
    my $item = $fixture_slug . '_' . _sv_slug($transaction->{definition}{name}) . '_item';
    my $diagnostic = $fixture_slug . '_diagnostic';
    my $snapshot = $fixture_slug . '_result_snapshot';
    my $coverage = $fixture_slug . '_coverage_collector';
    my $model = $fixture_slug . '_event_counter_model';
    my $scoreboard = $fixture_slug . '_write_scoreboard';
    my $fault_controller = $fixture_slug . '_fault_controller';
    my $property_checker = $fixture_slug . '_property_checker';

    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the checking gallery requires exactly two event-counter model instances',
        '/execution_ir/models') unless ref($execution->{models}) eq 'ARRAY'
            && @{$execution->{models}} == 2;
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the checking gallery requires exactly one bounded in-order scoreboard',
        '/execution_ir/scoreboards') unless ref($execution->{scoreboards}) eq 'ARRAY'
            && @{$execution->{scoreboards}} == 1
            && ($execution->{scoreboards}[0]{definition}{policy} // '') eq 'in_order'
            && ($execution->{scoreboards}[0]{definition}{capacity} // 0) == 4;
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the checking gallery requires exactly one two-bin coverpoint and no cross',
        '/execution_ir/coverage') unless ref($execution->{coverage}{coverpoints}) eq 'ARRAY'
            && @{$execution->{coverage}{coverpoints}} == 1
            && @{$execution->{coverage}{coverpoints}[0]{bins} || []} == 2
            && ref($execution->{coverage}{crosses}) eq 'ARRAY'
            && !@{$execution->{coverage}{crosses}};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the checking gallery requires exactly one one-cycle substitution fault',
        '/execution_ir/faults') unless ref($execution->{faults}) eq 'ARRAY'
            && @{$execution->{faults}} == 1
            && ($execution->{faults}[0]{duration_cycles} // 0) == 1
            && ($execution->{faults}[0]{field_name} // '') eq 'size';

    my $scoreboard_record = $execution->{scoreboards}[0];
    my $coverpoint = $execution->{coverage}{coverpoints}[0];
    my $fault = $execution->{faults}[0];
    my ($expected_operation) = grep { ($_->{kind} // '') eq 'scoreboard_expect' }
        @{$execution->{operation_graph}{operations}};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the checking gallery requires exactly one public scoreboard expectation',
        '/execution_ir/operation_graph') unless $expected_operation
            && 1 == grep { ($_->{kind} // '') eq 'scoreboard_expect' }
                @{$execution->{operation_graph}{operations}};
    my %expected_input = map { $_->{name} => $_->{value} }
        @{$expected_operation->{typed_inputs}};
    my %expected_field = map { $_->{field_id} => $_->{value} }
        @{$expected_input{fields} || []};
    my ($success_start) = grep {
        ($_->{kind} // '') eq 'start'
            && ($_->{scenario_id} // '') eq $expected_operation->{scenario_id}
    } @{$execution->{operation_graph}{operations}};
    my %success_input = map { $_->{name} => $_->{value} }
        @{$success_start->{typed_inputs} || []};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        'the scoreboard expectation lacks one matching public transaction start',
        '/execution_ir/operation_graph') unless $success_start
            && defined($success_input{handle_id});

    my (@line, @spec);
    my $push = sub (@text) { push @line, @text };
    my $map_class = sub ($start, $symbol, $role, $plan_paths, $semantic_paths,
            $bridge_paths, $locations) {
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => scalar(@line),
            symbol => $symbol, role => $role, plan_paths => $plan_paths,
            semantic_paths => $semantic_paths, bridge_paths => $bridge_paths,
            locations => $locations,
        );
    };

    $push->('// Generated native VIAL checking, diagnostic, and result-collection structures.');
    $push->('// These structures are emitted for review; no runtime result is claimed.');
    $push->("package $arg{package_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->("  import $arg{services_package}::*;");
    $push->('  `uvm_analysis_imp_decl(_vial_diagnostic)');
    $push->('');

    my $diagnostic_start = @line + 1;
    $push->("  class $diagnostic extends uvm_object;");
    $push->("    `uvm_object_utils($diagnostic)");
    $push->('');
    $push->('    string diagnostic_id;');
    $push->('    string semantic_id;');
    $push->('    uvm_severity severity;');
    $push->('    string message;');
    $push->('    vial_logical_time_s logical_time;');
    $push->('');
    $push->("    function new(string name = \"$diagnostic\");");
    $push->('      super.new(name);');
    $push->('      diagnostic_id = "";');
    $push->('      semantic_id = "";');
    $push->('      severity = UVM_INFO;');
    $push->('      message = "";');
    $push->("      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_CHECK_PHASE};");
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void do_copy(uvm_object rhs);');
    $push->("      $diagnostic rhs_item;");
    $push->('      super.do_copy(rhs);');
    $push->('      if (!$cast(rhs_item, rhs))');
    $push->('        `uvm_fatal("VIAL/DIAGNOSTIC/COPY", "diagnostic type mismatch")');
    $push->('      diagnostic_id = rhs_item.diagnostic_id;');
    $push->('      semantic_id = rhs_item.semantic_id;');
    $push->('      severity = rhs_item.severity;');
    $push->('      message = rhs_item.message;');
    $push->('      logical_time = rhs_item.logical_time;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($diagnostic_start, $diagnostic, 'structured_diagnostic_record',
        ['/diagnostics', '/fixture'], [$execution->{fixture}{fixture_id}], [],
        [$execution->{fixture}{source_location}]);
    $push->('');

    my $snapshot_start = @line + 1;
    $push->("  class $snapshot extends uvm_object;");
    $push->("    `uvm_object_utils($snapshot)");
    $push->('');
    $push->('    string plan_id;');
    $push->('    string status;');
    $push->('    longint unsigned notification_count;');
    $push->('    longint unsigned diagnostic_count;');
    $push->('    longint unsigned expectation_count;');
    $push->('    longint unsigned expectation_failure_count;');
    $push->('    longint unsigned model_record_count;');
    $push->('    longint unsigned scoreboard_record_count;');
    $push->('    longint unsigned coverage_sample_count;');
    $push->('    longint unsigned fault_record_count;');
    $push->('');
    $push->("    function new(string name = \"$snapshot\");");
    $push->('      super.new(name);');
    $push->('      plan_id = "";');
    $push->('      status = "emitted_unqualified";');
    $push->('      notification_count = 0;');
    $push->('      diagnostic_count = 0;');
    $push->('      expectation_count = 0;');
    $push->('      expectation_failure_count = 0;');
    $push->('      model_record_count = 0;');
    $push->('      scoreboard_record_count = 0;');
    $push->('      coverage_sample_count = 0;');
    $push->('      fault_record_count = 0;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($snapshot_start, $snapshot, 'normalized_result_snapshot_structure',
        ['/fixture', '/events', '/models', '/scoreboards', '/coverage', '/faults'],
        [$execution->{fixture}{fixture_id}], [$CONTRACT],
        [$execution->{fixture}{source_location}]);
    $push->('');

    my $coverage_start = @line + 1;
    my $covergroup = _sv_slug($coverpoint->{name}) . '_cg';
    $push->("  class $coverage extends uvm_component;");
    $push->("    `uvm_component_utils($coverage)");
    $push->('');
    $push->("    uvm_analysis_port#($diagnostic) diagnostic_ap;");
    $push->('    longint unsigned sample_count;');
    $push->("    covergroup $covergroup with function sample(bit stalled);");
    $push->('      option.per_instance = 1;');
    $push->('      stall_seen: coverpoint stalled {');
    $push->("        bins " . _sv_slug($coverpoint->{bins}[0]{name}) . " = {1'b0};");
    $push->("        bins " . _sv_slug($coverpoint->{bins}[1]{name}) . " = {1'b1};");
    $push->('      }');
    $push->('    endgroup');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      diagnostic_ap = new("diagnostic_ap", this);');
    $push->("      $covergroup = new();");
    $push->('      sample_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void sample_ready(logic ready_out, vial_logical_time_s logical_time);');
    $push->("      $diagnostic item;");
    $push->('      if ($isunknown(ready_out)) begin');
    $push->("        item = ${diagnostic}::type_id::create(\"coverage_unknown\");");
    $push->('        item.diagnostic_id = "diagnostic/coverage/stall_seen/unknown";');
    $push->('        item.semantic_id = "' . _sv_string($coverpoint->{semantic_id}) . '";');
    $push->('        item.severity = UVM_ERROR;');
    $push->('        item.message = "stall_seen requires a known ready_out sample";');
    $push->('        item.logical_time = logical_time;');
    $push->('        diagnostic_ap.write(item);');
    $push->('        return;');
    $push->('      end');
    $push->("      $covergroup.sample(ready_out === 1'b0);");
    $push->('      sample_count++;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($coverage_start, $coverage, 'functional_coverage_collector',
        ['/coverage/coverpoints/0'], [$coverpoint->{semantic_id},
            map { $_->{semantic_id} } @{$coverpoint->{bins}}], [], []);
    $push->('');

    my $model_start = @line + 1;
    $push->("  class $model extends uvm_component;");
    $push->("    `uvm_component_utils($model)");
    $push->('');
    $push->("    uvm_analysis_port#($diagnostic) diagnostic_ap;");
    $push->('    string instance_id;');
    $push->('    string event_id;');
    $push->('    bit [31:0] count;');
    $push->('    longint unsigned record_count;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      diagnostic_ap = new("diagnostic_ap", this);');
    $push->('      count = 0;');
    $push->('      record_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void configure(string configured_instance_id, string configured_event_id);');
    $push->('      instance_id = configured_instance_id;');
    $push->('      event_id = configured_event_id;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void observe_event(vial_logical_time_s logical_time);');
    $push->("      $diagnostic item;");
    $push->("      if (count == 32'hffffffff) begin");
    $push->("        item = ${diagnostic}::type_id::create(\"model_overflow\");");
    $push->('        item.diagnostic_id = {"diagnostic/model/overflow/", instance_id};');
    $push->('        item.semantic_id = instance_id;');
    $push->('        item.severity = UVM_ERROR;');
    $push->('        item.message = "event-counter model overflow";');
    $push->('        item.logical_time = logical_time;');
    $push->('        diagnostic_ap.write(item);');
    $push->('        return;');
    $push->('      end');
    $push->('      count++;');
    $push->('      record_count++;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($model_start, $model, 'deterministic_event_counter_model',
        ['/models'], [map { $_->{instance_id} } @{$execution->{models}}], [],
        [map { $_->{source_location} } @{$execution->{models}}]);
    $push->('');

    my $scoreboard_start = @line + 1;
    $push->("  class $scoreboard extends uvm_component;");
    $push->("    `uvm_component_utils($scoreboard)");
    $push->('');
    $push->('    localparam int unsigned CAPACITY = 4;');
    $push->("    uvm_analysis_imp#($item, $scoreboard) actual_export;");
    $push->("    uvm_analysis_port#($diagnostic) diagnostic_ap;");
    $push->("    protected $item expected_queue[\$];");
    $push->("    protected $item actual_queue[\$];");
    $push->('    longint unsigned match_count;');
    $push->('    longint unsigned mismatch_count;');
    $push->('    longint unsigned record_count;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      actual_export = new("actual_export", this);');
    $push->('      diagnostic_ap = new("diagnostic_ap", this);');
    $push->('      match_count = 0;');
    $push->('      mismatch_count = 0;');
    $push->('      record_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->("    protected function $item checked_clone($item source, string name);");
    $push->("      $item copy;");
    $push->('      if (source == null)');
    $push->('        `uvm_fatal("VIAL/SCOREBOARD", "scoreboard received a null transaction")');
    $push->('      if (!$cast(copy, source.clone()))');
    $push->('        `uvm_fatal("VIAL/SCOREBOARD", "scoreboard transaction clone has an incompatible type")');
    $push->('      copy.set_name(name);');
    $push->('      return copy;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void enqueue_expected(' . $item . ' transaction);');
    $push->('      if (expected_queue.size() >= CAPACITY)');
    $push->('        `uvm_fatal("VIAL/SCOREBOARD/BOUND", "expected queue capacity exceeded")');
    $push->('      expected_queue.push_back(checked_clone(transaction, "expected"));');
    $push->('      record_count++;');
    $push->('      compare_ready();');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void write(' . $item . ' transaction);');
    $push->('      if (actual_queue.size() >= CAPACITY)');
    $push->('        `uvm_fatal("VIAL/SCOREBOARD/BOUND", "actual queue capacity exceeded")');
    $push->('      actual_queue.push_back(checked_clone(transaction, "actual"));');
    $push->('      record_count++;');
    $push->('      compare_ready();');
    $push->('    endfunction');
    $push->('');
    $push->('    protected function void compare_ready();');
    $push->("      $item expected;");
    $push->("      $item actual;");
    $push->("      $diagnostic item;");
    $push->('      while (expected_queue.size() && actual_queue.size()) begin');
    $push->('        expected = expected_queue.pop_front();');
    $push->('        actual = actual_queue.pop_front();');
    $push->('        record_count++;');
    $push->('        if (expected.compare(actual)) begin');
    $push->('          match_count++;');
    $push->('          continue;');
    $push->('        end');
    $push->('        mismatch_count++;');
    $push->("        item = ${diagnostic}::type_id::create(\"scoreboard_mismatch\");");
    $push->('        item.diagnostic_id = "diagnostic/scoreboard/writes/mismatch";');
    $push->('        item.semantic_id = "' . _sv_string($scoreboard_record->{instance_id}) . '";');
    $push->('        item.severity = UVM_ERROR;');
    $push->('        item.message = "in-order transaction mismatch";');
    $push->('        diagnostic_ap.write(item);');
    $push->('      end');
    $push->('    endfunction');
    $push->('');
    $push->('    function bit check_empty();');
    $push->("      $diagnostic item;");
    $push->('      record_count++;');
    $push->('      if (!expected_queue.size() && !actual_queue.size() && mismatch_count == 0)');
    $push->("        return 1'b1;");
    $push->("      item = ${diagnostic}::type_id::create(\"scoreboard_pending\");");
    $push->('      item.diagnostic_id = "diagnostic/scoreboard/writes/not_empty";');
    $push->('      item.semantic_id = "' . _sv_string($scoreboard_record->{instance_id}) . '";');
    $push->('      item.severity = UVM_ERROR;');
    $push->('      item.message = $sformatf("scoreboard check failed: expected=%0d actual=%0d mismatches=%0d", expected_queue.size(), actual_queue.size(), mismatch_count);');
    $push->('      diagnostic_ap.write(item);');
    $push->("      return 1'b0;");
    $push->('    endfunction');
    $push->('');
    $push->('    function void reset_scenario();');
    $push->('      expected_queue.delete();');
    $push->('      actual_queue.delete();');
    $push->('      mismatch_count = 0;');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($scoreboard_start, $scoreboard, 'bounded_in_order_scoreboard',
        ['/scoreboards/0', '/operation_graph'],
        [$scoreboard_record->{instance_id}, $scoreboard_record->{scoreboard_id},
            $expected_operation->{operation_id}], [$transaction->{binding_id}],
        [$scoreboard_record->{source_location}, $expected_operation->{source_location}]);
    $push->('');

    my $expected_start = @line + 1;
    $push->("  function automatic $item make_success_expected();");
    $push->("    $item expected;");
    $push->("    expected = ${item}::type_id::create(\"success_expected\");");
    $push->('    expected.semantic_id = "' . _sv_string($transaction->{semantic_id}) . '";');
    $push->('    expected.scenario_id = "' . _sv_string($expected_operation->{scenario_id}) . '";');
    $push->('    expected.handle_id = "' . _sv_string($success_input{handle_id}) . '";');
    for my $field (@{$transaction->{fields}}) {
        my $value = $expected_field{$field->{semantic_id}};
        _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
            "scoreboard expectation lacks field '$field->{semantic_id}'",
            '/execution_ir/operation_graph') unless ref($value) eq 'HASH'
                && ref($value->{value}) eq 'HASH';
        $push->('    expected.' . _sv_slug($field->{name}) . ' = '
            . _sv_scalar_literal($value->{value}) . ';');
    }
    $push->('    return expected;');
    $push->('  endfunction');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $expected_start, end => scalar(@line),
        symbol => 'make_success_expected', role => 'public_scoreboard_expectation',
        plan_paths => ['/operation_graph'], semantic_paths => [$expected_operation->{operation_id}],
        bridge_paths => [$transaction->{binding_id}], locations => [$expected_operation->{source_location}],
    );
    $push->('');

    my $fault_start = @line + 1;
    my $fault_literal = _sv_scalar_literal($fault->{substitute}{value});
    $push->("  class $fault_controller extends uvm_component;");
    $push->("    `uvm_component_utils($fault_controller)");
    $push->('');
    $push->("    uvm_analysis_port#($diagnostic) diagnostic_ap;");
    $push->('    bit armed;');
    $push->('    int unsigned remaining_drive_intervals;');
    $push->('    longint unsigned record_count;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      diagnostic_ap = new("diagnostic_ap", this);');
    $push->("      armed = 1'b0;");
    $push->('      remaining_drive_intervals = 0;');
    $push->('      record_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void arm();');
    $push->('      if (armed)');
    $push->('        `uvm_fatal("VIAL/FAULT/ARM", "substitution fault is already armed")');
    $push->("      armed = 1'b1;");
    $push->('      remaining_drive_intervals = 1;');
    $push->('      record_count++;');
    $push->('    endfunction');
    $push->('');
    $push->("    function void apply_next_drive(ref $item transaction);");
    $push->('      if (!armed) return;');
    $push->("      transaction." . _sv_slug($fault->{field_name}) . " = $fault_literal;");
    $push->('      record_count++;');
    $push->('      remaining_drive_intervals--;');
    $push->('      if (remaining_drive_intervals == 0) begin');
    $push->("        armed = 1'b0;");
    $push->('        record_count++;');
    $push->('      end');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($fault_start, $fault_controller, 'declared_substitution_fault_controller',
        ['/faults/0', '/operation_graph'], [$fault->{semantic_id}],
        [$fault->{transaction_id}], []);
    $push->('');

    my $property_start = @line + 1;
    my @expectation = map { $_->{effects}[0]{target_id} }
        grep { ($_->{kind} // '') eq 'expect' }
        @{$execution->{operation_graph}{operations}};
    $push->("  class $property_checker extends uvm_component;");
    $push->("    `uvm_component_utils($property_checker)");
    $push->('');
    $push->("    uvm_analysis_port#($diagnostic) diagnostic_ap;");
    $push->('    longint unsigned expectation_count;');
    $push->('    longint unsigned failure_count;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      diagnostic_ap = new("diagnostic_ap", this);');
    $push->('      expectation_count = 0;');
    $push->('      failure_count = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    function void record(string expectation_id, bit passed, string detail, vial_logical_time_s logical_time);');
    $push->("      $diagnostic item;");
    $push->('      expectation_count++;');
    $push->('      if (passed) return;');
    $push->('      failure_count++;');
    $push->("      item = ${diagnostic}::type_id::create(\"expectation_failure\");");
    $push->('      item.diagnostic_id = {"diagnostic/expectation/", expectation_id};');
    $push->('      item.semantic_id = expectation_id;');
    $push->('      item.severity = UVM_ERROR;');
    $push->('      item.message = detail;');
    $push->('      item.logical_time = logical_time;');
    $push->('      diagnostic_ap.write(item);');
    $push->('    endfunction');
    $push->('  endclass');
    $map_class->($property_start, $property_checker, 'property_expectation_collector',
        ['/operation_graph'], \@expectation, [],
        [map { $_->{source_location} } grep { ($_->{kind} // '') eq 'expect' }
            @{$execution->{operation_graph}{operations}}]);

    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_sva_checker(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my %binding = _sv_binding_map($bridge);
    my %role = map { ($_->{role} // '') => $_ } @{$bridge->{endpoints}};
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $reset = $binding{$domain->{reset_endpoint_id}}{target_name};
    my $select = $binding{$role{select}{endpoint_id}}{target_name};
    my $ready_in = $binding{$role{ready_in}{endpoint_id}}{target_name};
    my $ready_out = $binding{$role{ready_out}{endpoint_id}}{target_name};
    my ($transfer_field) = grep { ($_->{name} // '') eq 'transfer' }
        @{$bridge->{transactions}[0]{fields}};
    my $transfer = $binding{$transfer_field->{endpoint_id}}{target_name};
    my $reset_inactive = $domain->{reset_polarity} eq 'active_low' ? "1'b1" : "1'b0";
    my @await = grep { ($_->{kind} // '') eq 'await' }
        @{$execution->{operation_graph}{operations}};

    my @line;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated bound SVA review checker for selected public VIAL temporal intent.');
    $push->("module $arg{checker_module} (");
    $push->('  input logic clock,');
    $push->('  input logic reset,');
    $push->('  input logic select,');
    $push->('  input logic ready_in,');
    $push->('  input logic [1:0] transfer,');
    $push->('  input logic ready_out');
    $push->(');');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  default clocking checker_cb @(posedge clock);');
    $push->('  endclocking');
    $push->("  default disable iff (reset !== $reset_inactive);");
    $push->('');
    my $property_start = @line + 1;
    $push->('  property started_transfer_completes_within_256;');
    $push->("    (select && ready_in && transfer == 2'h2) |-> ##[1:256] ready_out;");
    $push->('  endproperty');
    $push->('');
    $push->('  selected_completion_bound: assert property (started_transfer_completes_within_256)');
    $push->('    else $error("VIAL temporal completion bound failed");');
    $push->('endmodule');
    $push->('');
    my $bind_start = @line + 1;
    $push->("bind $arg{module_name} $arg{checker_module} ${\($arg{checker_module} . '_i')} (");
    $push->("  .clock($clock),");
    $push->("  .reset($reset),");
    $push->("  .select($select),");
    $push->("  .ready_in($ready_in),");
    $push->("  .transfer($transfer),");
    $push->("  .ready_out($ready_out)");
    $push->(');');

    my @locations = map { $_->{source_location} } @await;
    my @semantic = map { $_->{operation_id} } @await;
    my @spec = (
        _map_spec(
            relpath => $arg{relpath}, start => 1, end => scalar(@line),
            symbol => $arg{checker_module}, role => 'bound_sva_checker',
            plan_paths => ['/operation_graph'], semantic_paths => \@semantic,
            bridge_paths => ['/units/0', '/domains/0'], locations => \@locations,
        ),
        _map_spec(
            relpath => $arg{relpath}, start => $property_start,
            end => $bind_start - 2, symbol => 'started_transfer_completes_within_256',
            role => 'public_temporal_property', plan_paths => ['/operation_graph'],
            semantic_paths => \@semantic, bridge_paths => ['/domains/0'],
            locations => \@locations,
        ),
    );
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_fixture_package(%arg) {
    my $fixture_slug = _sv_slug($arg{execution}{fixture}{fixture_name});
    my $transaction = $arg{execution}{transactions}[0];
    my $config = $fixture_slug . '_config';
    my $payload = $fixture_slug . '_notification_payload';
    my $registry = $fixture_slug . '_notification_registry';
    my $item = $fixture_slug . '_' . _sv_slug($transaction->{definition}{name}) . '_item';
    my $sequencer = $fixture_slug . '_sequencer';
    my $driver_base = $fixture_slug . '_driver_base';
    my $driver = $fixture_slug . '_driver';
    my $observer = $fixture_slug . '_transaction_observer';
    my $reg_block = $fixture_slug . '_reg_block';
    my $reg_adapter = $fixture_slug . '_reg_adapter';
    my $reg_predictor = $fixture_slug . '_reg_predictor';
    my $diagnostic = $fixture_slug . '_diagnostic';
    my $snapshot = $fixture_slug . '_result_snapshot';
    my $coverage = $fixture_slug . '_coverage_collector';
    my $model = $fixture_slug . '_event_counter_model';
    my $scoreboard = $fixture_slug . '_write_scoreboard';
    my $fault_controller = $fixture_slug . '_fault_controller';
    my $property_checker = $fixture_slug . '_property_checker';
    my $monitor = $fixture_slug . '_monitor';
    my $agent = $fixture_slug . '_agent';
    my $controller = $fixture_slug . '_controller';
    my $collector = $fixture_slug . '_result_collector';
    my $env = $fixture_slug . '_env';
    my $test = $fixture_slug . '_test';
    my %binding = _sv_binding_map($arg{bridge});
    my %endpoint_by_role = map { ($_->{role} // '') => $_ }
        @{$arg{bridge}{endpoints}};
    my %transaction_field = map { $_->{name} => $_ }
        @{$arg{bridge}{transactions}[0]{fields}};
    my $select_name = $binding{$endpoint_by_role{select}{endpoint_id}}{target_name};
    my $ready_out_name = $binding{$endpoint_by_role{ready_out}{endpoint_id}}{target_name};
    my $response_name = $binding{$endpoint_by_role{response}{endpoint_id}}{target_name};
    my $read_data_name = $binding{$endpoint_by_role{read_data}{endpoint_id}}{target_name};
    my $domain = $arg{bridge}{domains}[0];
    my $clock_endpoint_id = $domain->{clock_endpoint_id};
    my $reset_name = $binding{$domain->{reset_endpoint_id}}{target_name};
    my $reset_inactive = $domain->{reset_polarity} eq 'active_low' ? "1'b1" : "1'b0";
    my @payload_endpoint = grep { $_->{endpoint_id} ne $clock_endpoint_id }
        @{$arg{bridge}{endpoints}};
    my %event_by_name = map { $_->{name} => $_ } @{$arg{execution}{events}};
    my %expectation_by_scenario_name;
    for my $operation (@{$arg{execution}{operation_graph}{operations}}) {
        next unless ($operation->{kind} // '') eq 'expect';
        my $expectation_id = $operation->{effects}[0]{target_id};
        my ($name) = $expectation_id =~ /::expectation::([^:]+)\z/;
        $expectation_by_scenario_name{$operation->{scenario_id} . "\0" . $name}
            = $expectation_id if defined $name;
    }
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated native VIAL UVM fixture foundation.');
    $push->("package $arg{package_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('  import fsmgen_vial_uvm_components_pkg::*;');
    $push->("  import $arg{notification_package}::*;");
    $push->("  import $arg{services_package}::*;");
    $push->("  import $arg{checking_package}::*;");
    $push->('');
    my $config_start = @line + 1;
    $push->("  class $config extends uvm_object;");
    $push->("    `uvm_object_utils($config)");
    $push->('');
    $push->("    virtual $arg{interface_name} vif;");
    $push->('    int unsigned scenario_timeout_cycles;');
    $push->('    string role_substitution_id;');
    $push->('    string ral_preview_id;');
    $push->('');
    $push->("    function new(string name = \"$config\");");
    $push->('      super.new(name);');
    $push->('      scenario_timeout_cycles = 256;');
    $push->('      role_substitution_id = "private-preview/driver/default";');
    $push->('      ral_preview_id = "private-preview/ral/reg_data";');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $config_start, end => scalar(@line),
        symbol => $config, role => 'fixture_configuration_foundation',
        plan_paths => ['/fixture', '/bindings'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0', '/domains/0'], locations => [],
    );
    $push->('');

    my $sequencer_start = @line + 1;
    $push->("  class $sequencer extends uvm_sequencer#($item);");
    $push->("    `uvm_component_utils($sequencer)");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $sequencer_start, end => scalar(@line),
        symbol => $sequencer, role => 'typed_transaction_sequencer',
        plan_paths => ['/transactions/0', '/scenarios'],
        semantic_paths => [$transaction->{semantic_id}],
        bridge_paths => [$transaction->{binding_id}], locations => [],
    );
    $push->('');

    my $driver_base_start = @line + 1;
    $push->("  class $driver_base extends uvm_driver#($item);");
    $push->("    `uvm_component_utils($driver_base)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $fault_controller faults;");
    $push->("    uvm_analysis_port#($item) driven_ap;");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      driven_ap = new("driven_ap", this);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "driver is missing generated fixture configuration")');
    $push->("      if (!uvm_config_db#($fault_controller)::get(this, \"\", \"faults\", faults))");
    $push->('        `uvm_fatal("VIAL/FAULT", "driver is missing generated fault controller")');
    $push->('    endfunction');
    $push->('');
    $push->("    virtual task drive_item($item request);");
    $push->('      `uvm_fatal("VIAL/DRIVER", "compiler-selected driver override is missing")');
    $push->('    endtask');
    $push->('');
    $push->('    virtual task run_phase(uvm_phase phase);');
    $push->("      $item request;");
    $push->("      $item published;");
    $push->('      forever begin');
    $push->('        seq_item_port.get_next_item(request);');
    $push->('        if (request == null)');
    $push->('          `uvm_fatal("VIAL/DRIVER", "sequencer supplied a null transaction item")');
    $push->('        faults.apply_next_drive(request);');
    $push->('        drive_item(request);');
    $push->('        if (!$cast(published, request.clone()))');
    $push->('          `uvm_fatal("VIAL/DRIVER", "transaction clone has an incompatible type")');
    $push->('        driven_ap.write(published);');
    $push->('        seq_item_port.item_done();');
    $push->('      end');
    $push->('    endtask');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $driver_base_start, end => scalar(@line),
        symbol => $driver_base, role => 'typed_transaction_driver_base',
        plan_paths => ['/transactions/0', '/operation_graph'],
        semantic_paths => [$transaction->{semantic_id}],
        bridge_paths => [$transaction->{binding_id}], locations => [],
    );
    $push->('');

    my $driver_start = @line + 1;
    $push->("  class $driver extends $driver_base;");
    $push->("    `uvm_component_utils($driver)");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->("    virtual task drive_item($item request);");
    $push->('      @(cfg.vif.driver_cb);');
    for my $field (@{$transaction->{fields}}) {
        my $carrier = $transaction_field{$field->{name}};
        my $target = $binding{$carrier->{endpoint_id}}{target_name};
        my $field_name = _sv_slug($field->{name});
        $push->("      cfg.vif.driver_cb.$target <= request.$field_name;");
    }
    $push->("      cfg.vif.driver_cb.$select_name <= 1'b1;");
    $push->('      do @(cfg.vif.driver_cb);');
    $push->("      while (cfg.vif.driver_cb.$ready_out_name !== 1'b1);");
    $push->("      cfg.vif.driver_cb.$select_name <= 1'b0;");
    my $transfer_name = $binding{$transaction_field{transfer}{endpoint_id}}{target_name};
    $push->("      cfg.vif.driver_cb.$transfer_name <= '0;");
    $push->('    endtask');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $driver_start, end => scalar(@line),
        symbol => $driver, role => 'compiler_selected_transaction_driver',
        plan_paths => ['/transactions/0', '/bindings/transactions/0', '/operation_graph'],
        semantic_paths => [$transaction->{semantic_id},
            map { $_->{operation_id} }
                grep { $_->{kind} eq 'start' } @{$arg{execution}{operation_graph}{operations}}],
        bridge_paths => [$transaction->{binding_id}, '/transactions/0'],
        locations => [map { $_->{source_location} }
            grep { $_->{kind} eq 'start' } @{$arg{execution}{operation_graph}{operations}}],
    );
    $push->('');

    my $monitor_start = @line + 1;
    $push->("  class $monitor extends fsmgen_vial_component_base;");
    $push->("    `uvm_component_utils($monitor)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $registry notifications;");
    $push->("    $coverage coverage_collector;");
    $push->("    $model accepts_model;");
    $push->("    $model completions_model;");
    $push->("    uvm_analysis_port#($item) observed_ap;");
    $push->('    longint unsigned sampled_cycle;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      observed_ap = new("observed_ap", this);');
    $push->('      sampled_cycle = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "monitor is missing generated fixture configuration")');
    $push->("      if (!uvm_config_db#($registry)::get(this, \"\", \"notifications\", notifications))");
    $push->('        `uvm_fatal("VIAL/NOTIFY", "monitor is missing notification registry")');
    $push->("      if (!uvm_config_db#($coverage)::get(this, \"\", \"coverage\", coverage_collector))");
    $push->('        `uvm_fatal("VIAL/COVERAGE", "monitor is missing generated coverage collector")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"accepts_model\", accepts_model))");
    $push->('        `uvm_fatal("VIAL/MODEL", "monitor is missing accepts model")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"completions_model\", completions_model))");
    $push->('        `uvm_fatal("VIAL/MODEL", "monitor is missing completions model")');
    $push->('    endfunction');
    $push->('');
    $push->("    protected function $payload sample_payload(string notification_id, string semantic_id);");
    $push->("      $payload item;");
    $push->("      item = new(\"sampled_notification\");");
    $push->('      item.notification_id = notification_id;');
    $push->('      item.semantic_id = semantic_id;');
    $push->('      item.logical_time = vial_context.logical_time;');
    for my $endpoint (@payload_endpoint) {
        my $target = $binding{$endpoint->{endpoint_id}}{target_name};
        my $field = _sv_slug($target);
        $push->("      item.$field = cfg.vif.monitor_cb.$target;");
    }
    $push->('      return item;');
    $push->('    endfunction');
    $push->('');
    $push->("    protected function $item sample_transaction();");
    $push->("      $item transaction;");
    $push->("      transaction = ${item}::type_id::create(\"observed_transaction\");");
    $push->('      transaction.semantic_id = "' . _sv_string($transaction->{semantic_id}) . '";');
    for my $field (@{$transaction->{fields}}) {
        my $carrier = $transaction_field{$field->{name}};
        my $target = $binding{$carrier->{endpoint_id}}{target_name};
        my $field_name = _sv_slug($field->{name});
        $push->("      transaction.$field_name = cfg.vif.monitor_cb.$target;");
    }
    $push->('      return transaction;');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual task run_phase(uvm_phase phase);');
    $push->("      $payload item;");
    $push->('      forever begin');
    $push->('        @(cfg.vif.monitor_cb);');
    $push->("        if (cfg.vif.monitor_cb.$reset_name !== $reset_inactive)");
    $push->('          continue;');
    $push->('        vial_context.set_logical_time(sampled_cycle, VIAL_SAMPLE_PHASE, 0);');
    for my $event (@{$arg{execution}{events}}) {
        next unless ($event->{phase} // '') eq 'sample';
        my $predicate = _notification_predicate($event->{expression}, $arg{execution}, $arg{bridge});
        my $field = _sv_slug($event->{name}) . '_notification';
        if (defined $predicate) {
            my $event_id = _sv_string($event->{event_id});
            my $semantic_id = _sv_string($event->{semantic_id});
            $push->("        if ($predicate) begin");
            $push->("          item = sample_payload(\"$event_id\", \"$semantic_id\");");
            $push->("          notifications.$field.trigger_notification(item);");
            $push->('          accepts_model.observe_event(vial_context.logical_time);')
                if ($event->{name} // '') eq 'accepted';
            $push->('          completions_model.observe_event(vial_context.logical_time);')
                if ($event->{name} // '') eq 'completed';
            $push->('          observed_ap.write(sample_transaction());')
                if ($event->{name} // '') eq 'completed';
            $push->('        end');
        } else {
            $push->("        // '$event->{name}' keeps a typed channel; its adapter-state predicate is not executed by this emission-only slice.");
        }
    }
    $push->("        coverage_collector.sample_ready(cfg.vif.monitor_cb.$ready_out_name, vial_context.logical_time);");
    $push->('        sampled_cycle++;');
    $push->('      end');
    $push->('    endtask');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $monitor_start, end => scalar(@line),
        symbol => $monitor, role => 'timed_interface_monitor',
        plan_paths => ['/events', '/domains/0', '/bindings'],
        semantic_paths => [map { $_->{semantic_id} } @{$arg{execution}{events}}],
        bridge_paths => ['/domains/0', '/endpoints'],
        locations => [map { $_->{source_location} } @{$arg{execution}{events}}],
    );
    $push->('');

    my $agent_start = @line + 1;
    $push->("  class $agent extends fsmgen_vial_agent_base;");
    $push->("    `uvm_component_utils($agent)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $registry notifications;");
    $push->("    $coverage coverage_collector;");
    $push->("    $model accepts_model;");
    $push->("    $model completions_model;");
    $push->("    $fault_controller faults;");
    $push->("    $sequencer sequencer;");
    $push->("    $driver_base driver;");
    $push->("    $monitor monitor;");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "agent is missing generated fixture configuration")');
    $push->("      if (!uvm_config_db#($registry)::get(this, \"\", \"notifications\", notifications))");
    $push->('        `uvm_fatal("VIAL/NOTIFY", "agent is missing notification registry")');
    $push->("      if (!uvm_config_db#($coverage)::get(this, \"\", \"coverage\", coverage_collector))");
    $push->('        `uvm_fatal("VIAL/COVERAGE", "agent is missing generated coverage collector")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"accepts_model\", accepts_model))");
    $push->('        `uvm_fatal("VIAL/MODEL", "agent is missing accepts model")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"completions_model\", completions_model))");
    $push->('        `uvm_fatal("VIAL/MODEL", "agent is missing completions model")');
    $push->("      if (!uvm_config_db#($fault_controller)::get(this, \"\", \"faults\", faults))");
    $push->('        `uvm_fatal("VIAL/FAULT", "agent is missing generated fault controller")');
    $push->("      uvm_config_db#($config)::set(this, \"monitor\", \"cfg\", cfg);");
    $push->("      uvm_config_db#($registry)::set(this, \"monitor\", \"notifications\", notifications);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "monitor", "vial_context", vial_context);');
    $push->("      uvm_config_db#($coverage)::set(this, \"monitor\", \"coverage\", coverage_collector);");
    $push->("      uvm_config_db#($model)::set(this, \"monitor\", \"accepts_model\", accepts_model);");
    $push->("      uvm_config_db#($model)::set(this, \"monitor\", \"completions_model\", completions_model);");
    $push->("      uvm_config_db#($config)::set(this, \"driver\", \"cfg\", cfg);");
    $push->("      uvm_config_db#($fault_controller)::set(this, \"driver\", \"faults\", faults);");
    $push->("      sequencer = ${sequencer}::type_id::create(\"sequencer\", this);");
    $push->("      driver = ${driver_base}::type_id::create(\"driver\", this);");
    $push->("      monitor = ${monitor}::type_id::create(\"monitor\", this);");
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void connect_phase(uvm_phase phase);');
    $push->('      super.connect_phase(phase);');
    $push->('      driver.seq_item_port.connect(sequencer.seq_item_export);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $agent_start, end => scalar(@line),
        symbol => $agent, role => 'active_timed_interface_agent',
        plan_paths => ['/bindings', '/events', '/transactions', '/scenarios'],
        semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0', '/domains/0'], locations => [],
    );
    $push->('');

    my $controller_start = @line + 1;
    $push->("  class $controller extends fsmgen_vial_component_base;");
    $push->("    `uvm_component_utils($controller)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $registry notifications;");
    $push->("    $sequencer sequencer;");
    $push->("    $scoreboard writes_scoreboard;");
    $push->("    $fault_controller faults;");
    $push->("    $property_checker properties;");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "controller is missing generated fixture configuration")');
    $push->("      if (!uvm_config_db#($registry)::get(this, \"\", \"notifications\", notifications))");
    $push->('        `uvm_fatal("VIAL/NOTIFY", "controller is missing notification registry")');
    $push->("      if (!uvm_config_db#($scoreboard)::get(this, \"\", \"scoreboard\", writes_scoreboard))");
    $push->('        `uvm_fatal("VIAL/SCOREBOARD", "controller is missing generated scoreboard")');
    $push->("      if (!uvm_config_db#($fault_controller)::get(this, \"\", \"faults\", faults))");
    $push->('        `uvm_fatal("VIAL/FAULT", "controller is missing generated fault controller")');
    $push->("      if (!uvm_config_db#($property_checker)::get(this, \"\", \"properties\", properties))");
    $push->('        `uvm_fatal("VIAL/PROPERTY", "controller is missing generated property checker")');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void start_of_simulation_phase(uvm_phase phase);');
    $push->('      super.start_of_simulation_phase(phase);');
    $push->('      if (cfg == null || cfg.vif == null || notifications == null || sequencer == null ||');
    $push->('          writes_scoreboard == null || faults == null || properties == null)');
    $push->('        `uvm_fatal("VIAL/READY", "generated controller is not ready")');
    $push->('    endfunction');
    $push->('');
    $push->('    task run_selected_lifecycle();');
    for my $scenario (@{$arg{execution}{scenarios}}) {
        my $sequence = $fixture_slug . '_' . _sv_slug($scenario->{name}) . '_sequence';
        my $variable = _sv_slug($scenario->{name}) . '_sequence';
        $push->("      $sequence $variable;");
    }
    $push->("      $item expected;");
    $push->('      longint unsigned accepted_before;');
    $push->('      longint unsigned completed_before;');
    $push->('      longint unsigned error_before;');
    if ($event_by_name{requested}) {
        my $requested = $event_by_name{requested};
        my $requested_id = _sv_string($requested->{event_id});
        my $requested_semantic = _sv_string($requested->{semantic_id});
        my $requested_field = _sv_slug($requested->{name}) . '_notification';
        $push->("      $payload requested;");
    }
    $push->("      wait (cfg.vif.$reset_name === $reset_inactive);");
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_READY, VIAL_LIFECYCLE_RUNNING);');
    $push->('      vial_context.set_logical_time(0, VIAL_DRIVE_PHASE, 0);');
    if ($event_by_name{requested}) {
        my $requested = $event_by_name{requested};
        my $requested_id = _sv_string($requested->{event_id});
        my $requested_semantic = _sv_string($requested->{semantic_id});
        my $requested_field = _sv_slug($requested->{name}) . '_notification';
        $push->("      requested = new(\"requested_notification\");");
        $push->("      requested.notification_id = \"$requested_id\";");
        $push->("      requested.semantic_id = \"$requested_semantic\";");
        $push->('      requested.logical_time = vial_context.logical_time;');
        $push->("      notifications.$requested_field.trigger_notification(requested);");
    }
    for my $scenario (@{$arg{execution}{scenarios}}) {
        my $sequence = $fixture_slug . '_' . _sv_slug($scenario->{name}) . '_sequence';
        my $variable = _sv_slug($scenario->{name}) . '_sequence';
        my $scenario_id = $scenario->{scenario_id};
        $push->('      accepted_before = notifications.accepted_notification.occurrence_count;');
        $push->('      completed_before = notifications.completed_notification.occurrence_count;');
        $push->('      error_before = notifications.error_notification.occurrence_count;');
        if (($scenario->{name} // '') eq 'success') {
            $push->('      writes_scoreboard.reset_scenario();');
            $push->('      expected = make_success_expected();');
            $push->('      writes_scoreboard.enqueue_expected(expected);');
        }
        if (($scenario->{name} // '') eq 'unsupported_size') {
            $push->('      faults.arm();');
        }
        $push->("      $variable = ${sequence}::type_id::create(\"$variable\");");
        $push->("      $variable.start(sequencer);");
        my $accepted_id = $expectation_by_scenario_name{$scenario_id . "\0accepted_once"};
        if (defined $accepted_id) {
            $push->('      properties.record("' . _sv_string($accepted_id) . '",');
            $push->("        notifications.accepted_notification.occurrence_count - accepted_before == 1,");
            $push->('        "accepted event count differs from one", vial_context.logical_time);');
        }
        my $completed_id = $expectation_by_scenario_name{$scenario_id . "\0completed_once"};
        if (defined $completed_id) {
            $push->('      properties.record("' . _sv_string($completed_id) . '",');
            $push->("        notifications.completed_notification.occurrence_count - completed_before == 1,");
            $push->('        "completed event count differs from one", vial_context.logical_time);');
        }
        my $error_id = $expectation_by_scenario_name{$scenario_id . "\0two_error_cycles"};
        if (defined $error_id) {
            $push->('      properties.record("' . _sv_string($error_id) . '",');
            $push->("        notifications.error_notification.occurrence_count - error_before == 2,");
            $push->('        "error event count differs from two", vial_context.logical_time);');
        }
        my $response_key = ($scenario->{name} // '') eq 'success'
            ? 'response_ok' : 'response_returns_ok';
        my $response_id = $expectation_by_scenario_name{$scenario_id . "\0$response_key"};
        if (defined $response_id) {
            $push->('      properties.record("' . _sv_string($response_id) . '",');
            $push->("        cfg.vif.monitor_cb.$response_name === 1'b0,");
            $push->('        "response did not return to the expected value", vial_context.logical_time);');
        }
        my $read_id = $expectation_by_scenario_name{$scenario_id . "\0read_zero"};
        if (defined $read_id) {
            $push->('      properties.record("' . _sv_string($read_id) . '",');
            $push->("        cfg.vif.monitor_cb.$read_data_name === 32'h00000000,");
            $push->('        "read data differs from zero", vial_context.logical_time);');
        }
        $push->('      void\'(writes_scoreboard.check_empty());')
            if ($scenario->{name} // '') eq 'success';
    }
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_RUNNING, VIAL_LIFECYCLE_DRAINING);');
    $push->('    endtask');
    $push->('');
    $push->('    function void complete_lifecycle();');
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_DRAINING, VIAL_LIFECYCLE_COMPLETED);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $controller_start, end => scalar(@line),
        symbol => $controller, role => 'root_owned_lifecycle_controller',
        plan_paths => ['/operation_graph', '/domains/0'],
        semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/domains/0'],
        locations => [$arg{execution}{fixture}{source_location}],
    );
    $push->('');

    my $collector_start = @line + 1;
    $push->("  class $collector extends fsmgen_vial_component_base;");
    $push->("    `uvm_component_utils($collector)");
    $push->('');
    $push->("    $registry notifications;");
    $push->("    $coverage coverage_collector;");
    $push->("    $model accepts_model;");
    $push->("    $model completions_model;");
    $push->("    $scoreboard writes_scoreboard;");
    $push->("    $fault_controller faults;");
    $push->("    $property_checker properties;");
    $push->("    uvm_analysis_imp_vial_diagnostic#($diagnostic, $collector) diagnostic_export;");
    $push->("    protected $diagnostic diagnostics[\$];");
    $push->("    $snapshot snapshot;");
    $push->('    longint unsigned notification_occurrences;');
    $push->('    bit sealed;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('      diagnostic_export = new("diagnostic_export", this);');
    $push->("      sealed = 1'b0;");
    $push->('      notification_occurrences = 0;');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($registry)::get(this, \"\", \"notifications\", notifications))");
    $push->('        `uvm_fatal("VIAL/NOTIFY", "result collector is missing notification registry")');
    $push->("      if (!uvm_config_db#($coverage)::get(this, \"\", \"coverage\", coverage_collector))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing coverage collector")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"accepts_model\", accepts_model))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing accepts model")');
    $push->("      if (!uvm_config_db#($model)::get(this, \"\", \"completions_model\", completions_model))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing completions model")');
    $push->("      if (!uvm_config_db#($scoreboard)::get(this, \"\", \"scoreboard\", writes_scoreboard))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing scoreboard")');
    $push->("      if (!uvm_config_db#($fault_controller)::get(this, \"\", \"faults\", faults))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing fault controller")');
    $push->("      if (!uvm_config_db#($property_checker)::get(this, \"\", \"properties\", properties))");
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector is missing property checker")');
    $push->("      snapshot = ${snapshot}::type_id::create(\"snapshot\");");
    $push->('    endfunction');
    $push->('');
    $push->("    virtual function void write_vial_diagnostic($diagnostic item);");
    $push->("      $diagnostic copy;");
    $push->('      if (item == null)');
    $push->('        `uvm_fatal("VIAL/RESULT/DIAGNOSTIC", "result collector received a null diagnostic")');
    $push->('      if (!$cast(copy, item.clone()))');
    $push->('        `uvm_fatal("VIAL/RESULT/DIAGNOSTIC", "diagnostic clone has an incompatible type")');
    $push->('      diagnostics.push_back(copy);');
    $push->('    endfunction');
    $push->('');
    $push->('    function void seal();');
    $push->('      if (sealed)');
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector sealed more than once")');
    $push->('      notification_occurrences = notifications.total_occurrences();');
    $push->('      snapshot.plan_id = vial_context.plan_id;');
    $push->('      snapshot.notification_count = notification_occurrences;');
    $push->('      snapshot.diagnostic_count = diagnostics.size();');
    $push->('      snapshot.expectation_count = properties.expectation_count;');
    $push->('      snapshot.expectation_failure_count = properties.failure_count;');
    $push->('      snapshot.model_record_count = accepts_model.record_count + completions_model.record_count;');
    $push->('      snapshot.scoreboard_record_count = writes_scoreboard.record_count;');
    $push->('      snapshot.coverage_sample_count = coverage_collector.sample_count;');
    $push->('      snapshot.fault_record_count = faults.record_count;');
    $push->("      sealed = 1'b1;");
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void extract_phase(uvm_phase phase);');
    $push->('      super.extract_phase(phase);');
    $push->('      if (!sealed)');
    $push->('        `uvm_fatal("VIAL/RESULT", "result collector reached extract before seal")');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void check_phase(uvm_phase phase);');
    $push->('      super.check_phase(phase);');
    $push->('      if (!sealed)');
    $push->('        `uvm_error("VIAL/RESULT", "result collector is unsealed")');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void report_phase(uvm_phase phase);');
    $push->('      super.report_phase(phase);');
    $push->('      `uvm_info("VIAL/RESULT", $sformatf("emission-review status=%s notifications=%0d diagnostics=%0d expectations=%0d failures=%0d model-records=%0d scoreboard-records=%0d coverage-samples=%0d fault-records=%0d", snapshot.status, snapshot.notification_count, snapshot.diagnostic_count, snapshot.expectation_count, snapshot.expectation_failure_count, snapshot.model_record_count, snapshot.scoreboard_record_count, snapshot.coverage_sample_count, snapshot.fault_record_count), UVM_LOW)');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $collector_start, end => scalar(@line),
        symbol => $collector, role => 'closed_result_collector_structure',
        plan_paths => ['/events', '/models', '/scoreboards', '/coverage', '/faults', '/fixture'],
        semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');

    my $env_start = @line + 1;
    $push->("  class $env extends fsmgen_vial_env_base;");
    $push->("    `uvm_component_utils($env)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $registry notifications;");
    $push->("    $agent agent;");
    $push->("    $controller controller;");
    $push->("    $collector result_collector;");
    $push->("    $coverage coverage_collector;");
    $push->("    $model accepts_model;");
    $push->("    $model completions_model;");
    $push->("    $scoreboard writes_scoreboard;");
    $push->("    $fault_controller faults;");
    $push->("    $property_checker properties;");
    $push->("    uvm_tlm_analysis_fifo#($item) driven_fifo;");
    $push->("    $observer transaction_observer;");
    $push->("    $reg_block ral_model;");
    $push->("    $reg_adapter ral_adapter;");
    $push->("    $reg_predictor ral_predictor;");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "missing generated fixture configuration")');
    $push->("      if (!uvm_config_db#($registry)::get(this, \"\", \"notifications\", notifications))");
    $push->('        `uvm_fatal("VIAL/NOTIFY", "environment is missing notification registry")');
    $push->("      coverage_collector = ${coverage}::type_id::create(\"coverage_collector\", this);");
    $push->("      accepts_model = ${model}::type_id::create(\"accepts_model\", this);");
    $push->('      accepts_model.configure("' . _sv_string($arg{execution}{models}[0]{instance_id})
        . '", "' . _sv_string($arg{execution}{models}[0]{bindings}[0]{value}{semantic_id}) . '");');
    $push->("      completions_model = ${model}::type_id::create(\"completions_model\", this);");
    $push->('      completions_model.configure("' . _sv_string($arg{execution}{models}[1]{instance_id})
        . '", "' . _sv_string($arg{execution}{models}[1]{bindings}[0]{value}{semantic_id}) . '");');
    $push->("      writes_scoreboard = ${scoreboard}::type_id::create(\"writes_scoreboard\", this);");
    $push->("      faults = ${fault_controller}::type_id::create(\"faults\", this);");
    $push->("      properties = ${property_checker}::type_id::create(\"properties\", this);");
    $push->("      uvm_config_db#($config)::set(this, \"agent\", \"cfg\", cfg);");
    $push->("      uvm_config_db#($registry)::set(this, \"agent\", \"notifications\", notifications);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "agent", "vial_context", vial_context);');
    $push->("      uvm_config_db#($coverage)::set(this, \"agent\", \"coverage\", coverage_collector);");
    $push->("      uvm_config_db#($model)::set(this, \"agent\", \"accepts_model\", accepts_model);");
    $push->("      uvm_config_db#($model)::set(this, \"agent\", \"completions_model\", completions_model);");
    $push->("      uvm_config_db#($fault_controller)::set(this, \"agent\", \"faults\", faults);");
    $push->("      uvm_config_db#($config)::set(this, \"controller\", \"cfg\", cfg);");
    $push->("      uvm_config_db#($registry)::set(this, \"controller\", \"notifications\", notifications);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "controller", "vial_context", vial_context);');
    $push->("      uvm_config_db#($scoreboard)::set(this, \"controller\", \"scoreboard\", writes_scoreboard);");
    $push->("      uvm_config_db#($fault_controller)::set(this, \"controller\", \"faults\", faults);");
    $push->("      uvm_config_db#($property_checker)::set(this, \"controller\", \"properties\", properties);");
    $push->("      uvm_config_db#($registry)::set(this, \"result_collector\", \"notifications\", notifications);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "result_collector", "vial_context", vial_context);');
    $push->("      uvm_config_db#($coverage)::set(this, \"result_collector\", \"coverage\", coverage_collector);");
    $push->("      uvm_config_db#($model)::set(this, \"result_collector\", \"accepts_model\", accepts_model);");
    $push->("      uvm_config_db#($model)::set(this, \"result_collector\", \"completions_model\", completions_model);");
    $push->("      uvm_config_db#($scoreboard)::set(this, \"result_collector\", \"scoreboard\", writes_scoreboard);");
    $push->("      uvm_config_db#($fault_controller)::set(this, \"result_collector\", \"faults\", faults);");
    $push->("      uvm_config_db#($property_checker)::set(this, \"result_collector\", \"properties\", properties);");
    $push->("      agent = ${agent}::type_id::create(\"agent\", this);");
    $push->("      controller = ${controller}::type_id::create(\"controller\", this);");
    $push->("      result_collector = ${collector}::type_id::create(\"result_collector\", this);");
    $push->('      driven_fifo = new("driven_fifo", this);');
    $push->("      transaction_observer = ${observer}::type_id::create(\"transaction_observer\", this);");
    $push->("      ral_model = ${reg_block}::type_id::create(\"ral_model\");");
    $push->('      ral_model.build();');
    $push->('      ral_model.lock_model();');
    $push->("      ral_adapter = ${reg_adapter}::type_id::create(\"ral_adapter\");");
    $push->("      ral_predictor = ${reg_predictor}::type_id::create(\"ral_predictor\", this);");
    $push->('    endfunction');
    $push->('');
    my $connect_start = @line + 1;
    $push->('    virtual function void connect_phase(uvm_phase phase);');
    $push->('      super.connect_phase(phase);');
    $push->('      agent.driver.driven_ap.connect(driven_fifo.analysis_export);');
    $push->('      agent.driver.driven_ap.connect(writes_scoreboard.actual_export);');
    $push->('      agent.monitor.observed_ap.connect(transaction_observer.analysis_export);');
    $push->('      agent.monitor.observed_ap.connect(ral_predictor.bus_in);');
    $push->('      ral_predictor.map = ral_model.default_map;');
    $push->('      ral_predictor.adapter = ral_adapter;');
    $push->('      controller.sequencer = agent.sequencer;');
    $push->('      coverage_collector.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('      accepts_model.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('      completions_model.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('      writes_scoreboard.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('      faults.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('      properties.diagnostic_ap.connect(result_collector.diagnostic_export);');
    $push->('    endfunction');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $connect_start, end => scalar(@line),
        symbol => 'connect_phase', role => 'analysis_tlm_and_ral_connections',
        plan_paths => ['/transactions/0', '/bindings/transactions/0', '/bindings/probes/0',
            '/models', '/scoreboards', '/coverage', '/faults'],
        semantic_paths => [$transaction->{semantic_id}, $arg{bridge}{probes}[0]{probe_id},
            (map { $_->{instance_id} } @{$arg{execution}{models}}),
            $arg{execution}{scoreboards}[0]{instance_id},
            $arg{execution}{coverage}{coverpoints}[0]{semantic_id},
            $arg{execution}{faults}[0]{semantic_id}],
        bridge_paths => [$transaction->{binding_id}, '/probes/0'], locations => [],
    );
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $connect_start, end => scalar(@line),
        symbol => 'checking_result_connections', role => 'analysis_checking_result_connections',
        plan_paths => ['/models', '/scoreboards', '/coverage', '/faults', '/diagnostics'],
        semantic_paths => [(map { $_->{instance_id} } @{$arg{execution}{models}}),
            $arg{execution}{scoreboards}[0]{instance_id},
            $arg{execution}{coverage}{coverpoints}[0]{semantic_id},
            $arg{execution}{faults}[0]{semantic_id}],
        bridge_paths => [$transaction->{binding_id}], locations => [],
    );
    $push->('');
    $push->('    virtual function void end_of_elaboration_phase(uvm_phase phase);');
    $push->('      super.end_of_elaboration_phase(phase);');
    $push->('      if (agent == null || controller == null || result_collector == null ||');
    $push->('          coverage_collector == null || accepts_model == null || completions_model == null ||');
    $push->('          writes_scoreboard == null || faults == null || properties == null ||');
    $push->('          driven_fifo == null || transaction_observer == null ||');
    $push->('          ral_model == null || ral_adapter == null || ral_predictor == null)');
    $push->('        `uvm_fatal("VIAL/TOPOLOGY", "generated component topology is incomplete")');
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_CONFIGURED, VIAL_LIFECYCLE_READY);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $env_start, end => scalar(@line),
        symbol => $env, role => 'fixture_environment_foundation',
        plan_paths => ['/fixture'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('');
    my $test_start = @line + 1;
    $push->("  class $test extends fsmgen_vial_test_base;");
    $push->("    `uvm_component_utils($test)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $registry notifications;");
    $push->("    $env env;");
    $push->('    fsmgen_vial_execution_context vial_context;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    my $factory_override_start = @line + 1;
    $push->('      uvm_factory::get().set_inst_override_by_type(');
    $push->("        ${driver_base}::get_type(), ${driver}::get_type(),");
    $push->('        "uvm_test_top.env.agent.driver"');
    $push->('      );');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $factory_override_start,
        end => scalar(@line), symbol => 'driver_type_override',
        role => 'scoped_factory_role_substitution',
        plan_paths => ['/transactions/0', '/fixture'],
        semantic_paths => [$transaction->{semantic_id}],
        bridge_paths => [$transaction->{binding_id}, $CONTRACT], locations => [],
    );
    $push->("      cfg = ${config}::type_id::create(\"cfg\");");
    $push->("      if (!uvm_config_db#(virtual $arg{interface_name})::get(this, \"\", \"vif\", cfg.vif))");
    $push->('        `uvm_fatal("VIAL/VIF", "missing generated virtual interface")');
    $push->('      vial_context = fsmgen_vial_execution_context::type_id::create("vial_context");');
    $push->('      vial_context.plan_id = "' . _sv_string($arg{execution}{plan_id}) . '";');
    $push->("      notifications = ${registry}::type_id::create(\"notifications\");");
    $push->('      notifications.configure_preview();');
    $push->('      cfg.scenario_timeout_cycles = 256;');
    $push->('      cfg.role_substitution_id = "private-preview/driver/base-output-arbitration";');
    $push->('      cfg.ral_preview_id = "private-preview/ral/reg-data-at-zero";');
    $push->("      uvm_config_db#($config)::set(this, \"env\", \"cfg\", cfg);");
    $push->("      uvm_config_db#($registry)::set(this, \"env\", \"notifications\", notifications);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "env", "vial_context", vial_context);');
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_CONSTRUCTED, VIAL_LIFECYCLE_CONFIGURED);');
    $push->("      env = ${env}::type_id::create(\"env\", this);");
    $push->('    endfunction');
    $push->('');
    $push->('    virtual task run_phase(uvm_phase phase);');
    $push->('      phase.raise_objection(this, "VIAL root lifecycle");');
    $push->('      env.controller.run_selected_lifecycle();');
    $push->('      env.result_collector.seal();');
    $push->('      env.controller.complete_lifecycle();');
    $push->('      phase.drop_objection(this, "VIAL root lifecycle complete");');
    $push->('    endtask');
    $push->('');
    $push->('    virtual function void final_phase(uvm_phase phase);');
    $push->('      super.final_phase(phase);');
    $push->('      vial_context.transition_lifecycle(VIAL_LIFECYCLE_COMPLETED, VIAL_LIFECYCLE_FINALIZED);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $test_start, end => scalar(@line),
        symbol => $test, role => 'fixture_test_foundation',
        plan_paths => ['/fixture', '/profile'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _notification_predicate($node, $execution, $bridge) {
    return undef unless ref($node) eq 'HASH' && !blessed($node);
    my %backend_binding = _sv_binding_map($bridge);
    my %target_by_binding;
    for my $endpoint (@{$execution->{bindings}{endpoints} || []}) {
        my $binding = $backend_binding{$endpoint->{endpoint_id}};
        $target_by_binding{$endpoint->{binding_id}} = $binding->{target_name}
            if $binding && _identifier($binding->{target_name});
    }
    for my $transaction (@{$execution->{bindings}{transactions} || []}) {
        for my $entry (@{$transaction->{fields} || []}, @{$transaction->{event_input_bindings} || []}) {
            my $binding = $backend_binding{$entry->{endpoint_id}};
            $target_by_binding{$entry->{binding_id}} = $binding->{target_name}
                if $binding && _identifier($binding->{target_name});
        }
    }

    my $kind = $node->{kind} // '';
    if ($kind eq 'binding_reference') {
        return undef unless ($node->{reference_kind} // '') eq 'endpoint';
        my $target = $target_by_binding{$node->{binding_id}};
        return defined($target) ? "cfg.vif.monitor_cb.$target" : undef;
    }
    if ($kind eq 'literal') {
        my $value = $node->{value};
        my $literal = eval { _sv_scalar_literal($value) };
        return defined($literal) && !$@ ? $literal : undef;
    }
    if ($kind eq 'operator') {
        return undef unless ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}};
        my @operand = map { _notification_predicate($_, $execution, $bridge) }
            @{$node->{operands}};
        return undef if grep { !defined($_) } @operand;
        my $operator = $node->{operator} // '';
        return '(' . join(' && ', @operand) . ')' if $operator eq 'logical_all_v1';
        return '(' . join(' || ', @operand) . ')' if $operator eq 'logical_any_v1';
        return '(' . join(' === ', @operand) . ')' if $operator eq 'same_bits_v1';
        return '(' . join(' !== ', @operand) . ')' if $operator eq 'different_bits_v1';
    }
    return undef;
}

sub _render_top(%arg) {
    my $bridge = $arg{bridge};
    my %binding = _sv_binding_map($bridge);
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $reset = $binding{$domain->{reset_endpoint_id}}{target_name};
    my ($ready_in_endpoint) = grep { ($_->{role} // '') eq 'ready_in' }
        @{$bridge->{endpoints}};
    my ($ready_out_endpoint) = grep { ($_->{role} // '') eq 'ready_out' }
        @{$bridge->{endpoints}};
    my $ready_in = $binding{$ready_in_endpoint->{endpoint_id}}{target_name};
    my $ready_out = $binding{$ready_out_endpoint->{endpoint_id}}{target_name};
    my $reset_active = $domain->{reset_polarity} eq 'active_low' ? "1'b0" : "1'b1";
    my $reset_inactive = $domain->{reset_polarity} eq 'active_low' ? "1'b1" : "1'b0";
    my $fixture_slug = _sv_slug($arg{execution}{fixture}{fixture_name});
    my $test = $fixture_slug . '_test';
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated native VIAL UVM top foundation; emission is not compile qualification.');
    $push->("module $arg{top};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->("  import $arg{package_name}::*;");
    $push->('');
    $push->("  $arg{interface_name} vial_if();");
    $push->('');
    my @ports = map {
        my $name = $binding{$_->{endpoint_id}}{target_name};
        "    .$name(vial_if.$name)"
    } @{$bridge->{endpoints}};
    my $dut_start = @line + 1;
    $push->("  $arg{module_name} dut (");
    for my $index (0 .. $#ports) {
        $push->($ports[$index] . ($index == $#ports ? '' : ','));
    }
    $push->('  );');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $dut_start, end => scalar(@line),
        symbol => 'dut', role => 'bound_dut_instance',
        plan_paths => ['/bindings/unit'], semantic_paths => [$bridge->{units}[0]{unit_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('');
    my $ready_start = @line + 1;
    $push->("  assign vial_if.$ready_in = vial_if.$ready_out;");
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $ready_start, end => $ready_start,
        symbol => 'ready_loopback', role => 'declared_ready_loopback',
        plan_paths => ['/bindings/endpoints'],
        semantic_paths => [$ready_in_endpoint->{endpoint_id}, $ready_out_endpoint->{endpoint_id}],
        bridge_paths => ['/endpoints'], locations => [],
    );
    $push->('');
    my $clock_start = @line + 1;
    $push->('  initial begin');
    $push->("    vial_if.$clock = 1'b0;");
    $push->('    forever #5ns vial_if.' . $clock . ' = ~vial_if.' . $clock . ';');
    $push->('  end');
    $push->('');
    $push->('  initial begin');
    $push->("    vial_if.$reset = $reset_active;");
    $push->('    repeat (2) @(posedge vial_if.' . $clock . ');');
    $push->("    vial_if.$reset = $reset_inactive;");
    $push->('  end');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $clock_start, end => scalar(@line),
        symbol => 'vial_clock_reset_foundation', role => 'clock_reset_foundation',
        plan_paths => ['/domains/0'], semantic_paths => [$domain->{domain_id}],
        bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    my $uvm_start = @line + 1;
    $push->('  initial begin');
    $push->("    uvm_config_db#(virtual $arg{interface_name})::set(null, \"uvm_test_top\", \"vif\", vial_if);");
    $push->("    run_test(\"$test\");");
    $push->('  end');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $uvm_start, end => scalar(@line),
        symbol => $arg{top}, role => 'uvm_top_foundation',
        plan_paths => ['/fixture', '/profile'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0', '/domains/0'], locations => [],
    );
    $push->('endmodule');
    return (join("\n", @line) . "\n", \@spec);
}

sub _methodology_profile() {
    return {
        schema => 'fsmgen.vial_uvm_methodology_profile.v1',
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        target_language => 'IEEE SystemVerilog',
        methodology_standard => {
            organization => 'IEEE',
            designation => 'IEEE 1800.2-2020',
            revision => '2020',
        },
        reference_implementation => {
            organization => 'Accellera Systems Initiative',
            name => 'Universal Verification Methodology',
            release => '2020-3.1',
            git_tag => '2020.3.1',
            git_commit => '78c06547a2a0a29b3dc9dcafae62b75b2ff61544',
            license => 'Apache-2.0',
        },
        api_target => 'IEEE 1800.2-2020 / Accellera UVM 2020-3.1',
        canonical_source_policy => 'simulator_neutral_no_provider_conditionals',
        library_materialization => {
            emission_requirement => 'not_required',
            current_state => 'not_requested_or_inspected',
            required_before => [qw(
                library_dependent_preprocessing library_compile fixture_compile
                elaboration runtime
            )],
            project_local_verified_copy_required => JSON::PP::true,
            network_fetch_during_emission => JSON::PP::false,
        },
        execution_evidence => JSON::PP::false,
    };
}

sub _source_map_entries($specs, $source_text) {
    my @entries;
    for my $spec (sort {
        $a->{generated_relpath} cmp $b->{generated_relpath}
            || $a->{generated_start_line} <=> $b->{generated_start_line}
            || $a->{generated_symbol} cmp $b->{generated_symbol}
    } @$specs) {
        my $text = $source_text->{$spec->{generated_relpath}};
        confess "source-map artifact '$spec->{generated_relpath}' is unavailable"
            unless defined $text;
        my $entry = {
            %$spec,
            generated_start_column => 1,
            generated_end_column => _line_bytes($text, $spec->{generated_end_line}) + 1,
        };
        my $identity = join('|', map { defined($_) ? $_ : '' }
            @$entry{qw(generated_relpath generated_start_line generated_start_column generated_end_line generated_end_column generated_symbol role)});
        push @entries, {
            source_map_id => 'source-map/' . sha256_hex($identity),
            map { $_ => _clone($entry->{$_}) }
                grep { $_ ne 'source_map_id' } @SOURCE_MAP_ENTRY_KEYS,
        };
    }
    return \@entries;
}

sub _map_spec(%arg) {
    return {
        generated_relpath => $arg{relpath},
        generated_start_line => 0 + $arg{start},
        generated_end_line => 0 + $arg{end},
        generated_symbol => $arg{symbol},
        role => $arg{role},
        plan_paths => _clone($arg{plan_paths}),
        semantic_paths => _clone($arg{semantic_paths}),
        bridge_fact_paths => _clone($arg{bridge_paths}),
        source_locations => [map { defined($_) ? _clone($_) : () } @{$arg{locations}}],
    };
}

sub _sv_binding_map($bridge) {
    return map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
}

sub _backend_name($bridge, $semantic_id, $target_kind) {
    my @binding = grep {
        ($_->{target_language} // '') eq 'systemverilog'
            && ($_->{semantic_id} // '') eq $semantic_id
            && ($_->{target_kind} // '') eq $target_kind
            && ($_->{status} // '') eq 'declared'
    } @{$bridge->{backend_bindings}};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        "missing exact SystemVerilog $target_kind binding for '$semantic_id'",
        '/bridge_manifest/backend_bindings')
        unless @binding == 1 && _identifier($binding[0]{target_name});
    return $binding[0]{target_name};
}

sub _packed_type($record) {
    my $width = $record->{width};
    my $signed = $record->{signed} ? 'signed ' : '';
    return $signed . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '');
}

sub _artifact($relpath, $kind, $language, $role, $content, $generated_from) {
    return {
        relpath => $relpath,
        kind => $kind,
        language => $language,
        role => $role,
        content => $content,
        encoding => 'utf-8',
        source_layer => 'VIAL_BACKEND',
        generated_from => _clone($generated_from),
    };
}

sub _artifact_ref($artifact) {
    return {
        relpath => $artifact->{relpath},
        kind => $artifact->{kind},
        role => $artifact->{role},
        sha256 => sha256_hex($artifact->{content}),
        bytes => bytes::length($artifact->{content}),
    };
}

sub _identifier($value) {
    return defined($value) && !ref($value)
        && bytes::length($value) <= 255
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}

sub _sv_slug($value) {
    my $slug = lc($value // 'unnamed');
    $slug =~ s/[^a-z0-9_]+/_/g;
    $slug =~ s/\A_+|_+\z//g;
    $slug = "n_$slug" if $slug !~ /\A[a-z_]/;
    return length($slug) ? $slug : 'unnamed';
}

sub _slug($value) {
    my $slug = lc($value // 'unnamed');
    $slug =~ s/[^a-z0-9]+/-/g;
    $slug =~ s/\A-+|-+\z//g;
    return length($slug) ? $slug : 'unnamed';
}

sub _sv_string($value) {
    $value //= '';
    $value =~ s/([\\"])/\\$1/g;
    return $value;
}

sub _line_count($text) {
    return scalar(() = $text =~ /\n/g);
}

sub _line_bytes($text, $line_number) {
    confess 'source-map line number must be positive'
        unless defined($line_number) && !ref($line_number) && $line_number =~ /\A[1-9][0-9]*\z/;
    my @line = split /\n/, $text, -1;
    confess "source-map line $line_number is outside generated source"
        if $line_number > @line - 1;
    return bytes::length($line[$line_number - 1]);
}

sub _json_text($value) {
    return JSON::PP->new->canonical(1)->pretty(1)->encode($value);
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        __PACKAGE__ . '::Failure';
}

sub _failure($code, $message, $path, $negotiation = undef) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        backend_profile => $BACKEND_PROFILE,
        plan_id => undef,
        generated_top => undef,
        operation_id => undef,
        negotiation => defined($negotiation) ? _clone($negotiation) : undef,
        backend_manifest => undef,
        source_map => undef,
        static_validation => undef,
        mapping_matrix => undef,
        review_workflow => undef,
        artifacts => [],
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'native UVM backend result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'native UVM backend result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown native UVM backend host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown native UVM backend host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'native UVM backend projection contains unsupported reference data' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::SVUVMAccellera2020_3_1::Failure;

use overload '""' => sub { $_[0]{message} // 'native UVM backend failure' }, fallback => 1;

1;
