package FSM::VIAL::Backend::SVUVMReviewClosure;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use File::Basename qw(basename);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $BACKEND_PROFILE = 'sv_uvm_emit.accellera_2020_3_1';
my $MATRIX_SCHEMA = 'fsmgen.vial_uvm_selected_mapping_matrix.v1';
my $WORKFLOW_SCHEMA = 'fsmgen.vial_uvm_review_workflow.v1';
my @RESULT_KEYS = qw(
    ok status backend_profile mapping_matrix review_workflow checks diagnostics
);
my @MAPPING_KEYS = qw(
    mapping_id foundation_id intent_owner normal_source terse_source typed_ir
    generated_roles uvm_realization emission_status static_review_status
    visual_review_status qualification_status unsupported_reason
);
my @STAGE_KEYS = qw(stage_id status authority command evidence);

my @MAPPING_DEFINITION = (
    _definition('typed_context', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_types_package)],
        'typed logical-time, lifecycle, and execution-context records'),
    _definition('component_bases', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_component_foundations)],
        'typed UVM object, component, agent, environment, and test bases'),
    _definition('timed_interface', 'compiler_owned_from_public_bindings',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir', [qw(uvm_fixture_interface)],
        'clocking blocks and typed driver/monitor modports'),
    _definition('fixture_config', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package)],
        'typed fixture configuration object'),
    _definition('complete_component_topology', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package)],
        'agent, controller, checking components, environment, and test topology'),
    _definition('lifecycle_execution', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_component_foundations uvm_fixture_package)],
        'root-owned lifecycle, logical time, and one objection pair'),
    _definition('notification_interception',
        'mixed_public_event_private_interceptor_preview',
        'public_vial_v1', 'public_vial_v1',
        'public_events_plus_private_interceptor_preview',
        [qw(uvm_notification_interception uvm_fixture_package)],
        'typed UVM events plus ordered bounded callback interception',
        'native interceptor authoring syntax is not selected'),
    _definition('fixture_environment', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package)],
        'fixture-specific UVM environment'),
    _definition('fixture_test', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package uvm_fixture_top)],
        'fixture-specific UVM test and selected run-test top'),
    _definition('transaction_items', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_stimulus_services)],
        'typed sequence item with explicit copy, compare, and print behavior'),
    _definition('scenario_sequences', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_stimulus_services)],
        'one typed UVM sequence per selected public scenario'),
    _definition('active_agent_driver', 'compiler_owned_from_public_transactions',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package)],
        'typed sequencer and active transaction driver'),
    _definition('analysis_tlm', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_stimulus_services uvm_fixture_package)],
        'typed analysis ports, FIFOs, subscriber, and predictor wiring'),
    _definition('scoped_factory_configuration', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_package uvm_fixture_top)],
        'non-wildcard configuration paths and compiler-selected driver override'),
    _definition('ral_preview', 'private_typed_preview',
        'not_available_private_preview', 'not_available_private_preview',
        'private_typed_preview', [qw(uvm_stimulus_services uvm_fixture_package)],
        'fixture-specific register, block, adapter, and predictor preview',
        'public VIAL RAL authoring syntax is not selected'),
    _definition('constrained_decision_replay',
        'mixed_public_decision_private_solver_preview',
        'public_vial_v1', 'public_vial_v1',
        'portable_replay_plus_private_solver_preview',
        [qw(uvm_stimulus_services uvm_fixture_package)],
        'immutable portable decision replay plus isolated unused native solver',
        'public native-constraint authoring syntax is not selected'),
    _definition('functional_coverage', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_checking_results uvm_fixture_package)],
        'typed covergroup and exact selected bins'),
    _definition('bound_sva_properties', 'public_vial_v1_translation',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(bound_sva_checker)],
        'separately bound review checker for selected temporal intent'),
    _definition('event_models', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_checking_results uvm_fixture_package)],
        'deterministic bounded event-counter model components'),
    _definition('bounded_scoreboard', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_checking_results uvm_fixture_package)],
        'capacity-bounded typed in-order scoreboard'),
    _definition('declared_fault_interception', 'public_vial_v1',
        'public_vial_v1', 'public_vial_v1', 'public_execution_ir',
        [qw(uvm_checking_results uvm_fixture_package)],
        'declared one-drive-interval typed field substitution'),
    _definition('structured_diagnostics', 'compiler_owned_from_public_checks',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir', [qw(uvm_checking_results uvm_fixture_package)],
        'defensively copied typed diagnostics and aggregation'),
    _definition('result_collection', 'compiler_owned_from_public_checks',
        'derived_from_public_vial_v1', 'derived_from_public_vial_v1',
        'compiler_owned_execution_ir', [qw(uvm_checking_results uvm_fixture_package)],
        'structured in-memory review snapshot without a produced result manifest'),
    _definition('dut_binding', 'compiler_owned_from_hial_bridge',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_bridge_manifest', [qw(generated_hial_dut uvm_fixture_top)],
        'source-mapped generated HIAL DUT and exact port binding'),
    _definition('top', 'compiler_owned_backend',
        'not_applicable_compiler_owned', 'not_applicable_compiler_owned',
        'compiler_owned_execution_ir', [qw(uvm_fixture_top)],
        'clock/reset harness, virtual-interface publication, and generated test launch'),
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
    return _failure('VIAL_UVM_REVIEW_INVOCATION_ERROR',
        'build requires the exact review-closure class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_UVM_REVIEW_INVOCATION_ERROR',
        'build expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _build($args[0]) };
    return $result if defined $result;
    return _failure('VIAL_UVM_REVIEW_HOST_ERROR', _sanitize_exception($@), '/');
}

sub _build($raw) {
    _require_exact_keys($raw, [qw(
        plan_id fixture_id emitter_revision source_artifacts review_gallery
    )], 'native UVM review closure');
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
        push @mappings, {
            mapping_id => 'mapping/' . ($definition->{foundation_id} =~ s/_/-/gr),
            foundation_id => $definition->{foundation_id},
            intent_owner => $definition->{intent_owner},
            normal_source => $definition->{normal_source},
            terse_source => $definition->{terse_source},
            typed_ir => $definition->{typed_ir},
            generated_roles => [@{$definition->{generated_roles}}],
            uvm_realization => $definition->{uvm_realization},
            emission_status => 'emitted',
            static_review_status => 'passed_structural_only',
            visual_review_status => 'pending',
            qualification_status => 'not_run',
            unsupported_reason => $definition->{unsupported_reason},
        };
    }
    @mappings = sort { $a->{mapping_id} cmp $b->{mapping_id} } @mappings;

    my @examples = map {
        my $artifact = $artifact_by_role{$_};
        {
            role => $_,
            emitted_relpath => $artifact->{relpath},
            gallery_relpath => $raw->{review_gallery} . '/' . basename($artifact->{relpath}),
        }
    } sort grep { $_ ne 'generated_hial_dut' } keys %artifact_by_role;

    my $mapping_matrix = {
        schema => $MATRIX_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        emitter_revision => $raw->{emitter_revision},
        plan_id => $raw->{plan_id},
        fixture_id => $raw->{fixture_id},
        scope => 'complete_selected_native_uvm_emission_matrix_not_full_uvm_breadth',
        coverage_rule => 'every emitted foundation occurs exactly once with entry, evidence, and qualification states',
        entrypoint_legend => {
            normal_source => 'normal public VIAL formatter projection',
            terse_source => 'terse public VIAL formatter projection',
            typed_ir => 'private compiler entry after public parsing or an explicitly labelled preview',
        },
        mappings => \@mappings,
        excluded_qualification => [qw(
            preprocessing parse uvm_library_compile fixture_compile
            elaboration runtime result parity full_uvm_breadth
        )],
    };

    my $regenerate = 'perl scripts/refresh_vial_native_uvm_gallery.pl';
    my $check = 'perl scripts/refresh_vial_native_uvm_gallery.pl --check';
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
            $raw->{review_gallery} . '/selected-mapping-matrix.json',
            $raw->{review_gallery} . '/review-workflow.json',
        ],
        stages => [
            _stage('regenerate', 'ready', 'emitter', $regenerate,
                'refresh exact source and review-evidence snapshots'),
            _stage('byte_compare', 'ready', 'gallery_check', $check,
                'reject missing, extra, or byte-drifted gallery evidence'),
            _stage('static_shape', 'passed_structural_only', 'static_validator', undef,
                'deterministic source shape and selected UVM structures'),
            _stage('visual_review', 'pending', 'director_or_delegate', undef,
                'readability, intent fidelity, and UVM engineering judgment'),
            _stage('defect_capture', 'ready', 'task_tree', undef,
                'record exact artifact, symbol, source-map ID, severity, and reproduction'),
            _stage('experimental_compile', 'not_run', 'future_open_tool_probe', undef,
                'separate non-product evidence under task .13.2'),
            _stage('qualified_runtime', 'not_run', 'future_qualified_parser_simulator_tuple', undef,
                'separate executable qualification under task .13.3'),
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
            visual_review_complete systemverilog_parse uvm_library_compile
            fixture_compile elaboration runtime result parity full_uvm_breadth
        )],
    };

    my @checks;
    push @checks, _check('selected_mapping_coverage', @mappings == @MAPPING_DEFINITION);
    push @checks, _check('entrypoint_partition', _entrypoints_are_closed(\@mappings));
    push @checks, _check('generated_role_evidence', _roles_are_exact(\@mappings, \%role_count));
    push @checks, _check('review_workflow', _workflow_is_closed($review_workflow));
    push @checks, _check('qualification_boundary', _qualification_is_unclaimed($mapping_matrix, $review_workflow));
    confess 'native UVM review closure failed an internal invariant'
        if grep { $_->{status} ne 'passed' } @checks;

    return _result({
        ok => JSON::PP::true,
        status => 'passed',
        backend_profile => $BACKEND_PROFILE,
        mapping_matrix => $mapping_matrix,
        review_workflow => $review_workflow,
        checks => \@checks,
        diagnostics => [],
    });
}

sub _definition($foundation_id, $intent_owner, $normal_source, $terse_source,
        $typed_ir, $generated_roles, $uvm_realization, $unsupported_reason = undef) {
    return {
        foundation_id => $foundation_id,
        intent_owner => $intent_owner,
        normal_source => $normal_source,
        terse_source => $terse_source,
        typed_ir => $typed_ir,
        generated_roles => $generated_roles,
        uvm_realization => $uvm_realization,
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
    my %normal = map { $_ => 1 } qw(
        public_vial_v1 derived_from_public_vial_v1
        not_applicable_compiler_owned not_available_private_preview
    );
    my %typed = map { $_ => 1 } qw(
        public_execution_ir compiler_owned_execution_ir
        compiler_owned_bridge_manifest private_typed_preview
        public_events_plus_private_interceptor_preview
        portable_replay_plus_private_solver_preview
    );
    for my $mapping (@$mappings) {
        return 0 unless $normal{$mapping->{normal_source}}
            && $normal{$mapping->{terse_source}} && $typed{$mapping->{typed_ir}};
        my $preview = $mapping->{intent_owner} =~ /(?:private|mixed)/;
        return 0 if $preview && !defined($mapping->{unsupported_reason});
        return 0 if !$preview && defined($mapping->{unsupported_reason});
    }
    return 1;
}

sub _roles_are_exact($mappings, $role_count) {
    for my $mapping (@$mappings) {
        return 0 unless ref($mapping->{generated_roles}) eq 'ARRAY'
            && @{$mapping->{generated_roles}};
        return 0 if grep { ($role_count->{$_} // 0) != 1 }
            @{$mapping->{generated_roles}};
    }
    return 1;
}

sub _workflow_is_closed($workflow) {
    return 0 unless _safe_relpath($workflow->{gallery_root});
    return 0 unless $workflow->{regenerate_command}
        eq 'perl scripts/refresh_vial_native_uvm_gallery.pl';
    return 0 unless $workflow->{check_command}
        eq 'perl scripts/refresh_vial_native_uvm_gallery.pl --check';
    my %stage = map { $_->{stage_id} => $_ } @{$workflow->{stages}};
    return 0 unless keys(%stage) == 7
        && $stage{static_shape}{status} eq 'passed_structural_only'
        && $stage{visual_review}{status} eq 'pending'
        && $stage{experimental_compile}{status} eq 'not_run'
        && $stage{qualified_runtime}{status} eq 'not_run';
    return 0 if grep { !_has_exact_keys($_, \@STAGE_KEYS) }
        @{$workflow->{stages}};
    return 1;
}

sub _qualification_is_unclaimed($matrix, $workflow) {
    return 0 if grep {
        $_->{visual_review_status} ne 'pending'
            || $_->{qualification_status} ne 'not_run'
    } @{$matrix->{mappings}};
    my %nonclaim = map { $_ => 1 } @{$workflow->{nonclaims}};
    return $nonclaim{visual_review_complete}
        && $nonclaim{systemverilog_parse}
        && $nonclaim{runtime}
        && $nonclaim{result}
        && $nonclaim{parity}
        && $nonclaim{full_uvm_breadth};
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
