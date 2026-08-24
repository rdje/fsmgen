package FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::BackendEmissionAuthority qw(
    backend_emission_profile_authorities
);

my $SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_measurement_set.v1';
my $WORKLOAD_SCHEMA = 'fsmgen.vial_architecture_scale_workload.v1';
my $EVALUATION_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_evaluation.v1';
my $FAMILY = 'backend_emission_v1';
my $PRIMARY_AXIS = 'artifact_graph';
my $PRODUCER = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my @STAGE_ORDER = qw(
    construct parse_validate bridge bind_plan emit
);
my @PROFILES = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
    sv_uvm_emit.accellera_2020_3_1
);
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %PROFILE = map { $_ => 1 } @PROFILES;
my %LEVEL = map { $_ => 1 } @LEVELS;
my %MODE_CLASS = (
    gate_measurement => 'gate_measurement',
    qualification_measurement => 'qualification_measurement',
);
my %MODE_SAMPLES = (
    gate_measurement => 3,
    qualification_measurement => 5,
);
my %LEVEL_MODE = (
    gate_candidate_v1 => 'gate_measurement',
    qualification_candidate_v1 => 'qualification_measurement',
);
my @REPORT_KEYS = qw(
    schema schema_version report_identity family backend_profile level
    primary_axis workload_identity mode requested_counts profile_authority
    controller_applicability measurement_applicability provider_verification
    canonical_evaluation validation_record measurement_records
    sample_exclusions outcome diagnostics cleanup explicit_nonclaims
);
my @AUTHORITY_KEYS = qw(
    family backend_profile producer_class stage_order workload_schema
    evaluation_schema structural_authority structural_emission_only
    external_verification_tool authority_identity
);
my @APPLICABILITY_KEYS = qw(applicable reason);
my @PROVIDER_KEYS = qw(
    applicable included_in_emit read_only external_verification_tool
    classification
);
my @EXCLUSION_KEYS = qw(
    run_ordinal reason measurement_identity diagnostic
);
my @CLEANUP_KEYS = qw(records_total ephemeral_removed residue);
my @NONCLAIMS = (
    @{FSM::VIAL::ArchitectureScaleMeasurement->explicit_nonclaims},
    qw(
        external_verification_tool compile_analyze_elaborate_run_trace_result
        backend_support backend_capacity reached_boundary
        provider_performance public_api_change
    ),
);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub profile_authorities($class) {
    _exact_invocant($class, 'profile_authorities');
    return {map { $_ => _authority($_) } @PROFILES};
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $request = _request(
        'construct', \@args,
        [qw(repository_root backend_profile level)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    return _clone(_canonical_construction(
        $repo_root, $request->{backend_profile}, $request->{level},
    ));
}

sub validate_profile($class, @args) {
    _exact_invocant($class, 'validate_profile');
    my $request = _request(
        'validate_profile', \@args,
        [qw(repository_root backend_profile level)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $evaluation) = _canonical_pair(
        $repo_root, $request->{backend_profile}, $request->{level},
    );
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        evaluation => $evaluation,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        evaluation => $evaluation,
        mode => 'validation',
        validation_record => $validation,
        measurement_records => [],
    });
}

sub measure_profile($class, @args) {
    _exact_invocant($class, 'measure_profile');
    my $request = _request(
        'measure_profile', \@args,
        [qw(repository_root backend_profile level)],
    );
    my $mode = $LEVEL_MODE{$request->{level}};
    confess "only gate_candidate_v1 and qualification_candidate_v1 are measurement requests; authoritative non-emission remains validation-only\n"
        unless defined $mode;
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $evaluation) = _canonical_pair(
        $repo_root, $request->{backend_profile}, $request->{level},
    );
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        evaluation => $evaluation,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    my $applicable = $validation->{outcome} eq 'accepted'
        && $evaluation->{outcome_contract}{artifacts_emitted};
    my @measured;
    if ($applicable) {
        for my $ordinal (1 .. $MODE_SAMPLES{$mode}) {
            my $record = _run_record({
                repository_root => $repo_root,
                construction => $construction,
                evaluation => $evaluation,
                run_class => $MODE_CLASS{$mode},
                run_ordinal => $ordinal,
                validation_record => $validation,
            });
            push @measured, $record;
            last unless $record->{outcome} eq 'accepted';
        }
    }
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        evaluation => $evaluation,
        mode => $mode,
        validation_record => $validation,
        measurement_records => \@measured,
    });
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    my $request = _request(
        'validate_report', \@args, [qw(repository_root report)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    _validate_report($repo_root, $request->{report});
    return _clone($request->{report});
}

sub _run_record($raw) {
    return FSM::VIAL::ArchitectureScaleMeasurement->measure({
        repository_root => $raw->{repository_root},
        construction => $raw->{construction},
        run_class => $raw->{run_class},
        run_ordinal => $raw->{run_ordinal},
        validation_record => $raw->{validation_record},
        stage_plan => _stage_plan(
            $raw->{repository_root}, $raw->{construction}, $raw->{evaluation},
        ),
    });
}

sub _stage_plan($repo_root, $construction, $evaluation) {
    my $spec = $construction->{specification};
    my ($profile, $level) = @{$spec}{qw(backend_profile level)};
    my $source_counts = _source_counts($construction);
    my @plan;
    for my $stage (@{_planned_stages($evaluation)}) {
        my $input_counts = $stage eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json($spec)),
                objects => 1,
            }
            : _clone($source_counts);
        push @plan, {
            stage => $stage,
            classification => 'fsmgen_owned',
            command_identity => {
                logical_name => "vial_scale_backend_emission_$stage",
                arguments => [$profile, $level, $PRIMARY_AXIS],
                thread_count => 1,
                job_count => 1,
            },
            input_counts => $input_counts,
            backend_timeout_seconds => undef,
            worker => sub {
                my ($context) = @_;
                my $stage_construction = $stage eq 'construct'
                    ? _canonical_construction($repo_root, $profile, $level)
                    : _clone($construction);
                confess "backend-emission construction changed in '$stage'\n"
                    unless _canonical_json($stage_construction)
                        eq _canonical_json($construction);
                my $first = _stage_payload(
                    $stage_construction, $evaluation, $stage,
                );
                my $second = _stage_payload(
                    $stage_construction, $evaluation, $stage,
                );
                confess "backend-emission stage '$stage' is nondeterministic\n"
                    unless _canonical_json($second) eq _canonical_json($first);
                return _materialize_payload($context, $first);
            },
        };
    }
    return \@plan;
}

sub _planned_stages($evaluation) {
    return [qw(construct emit)]
        if $evaluation->{observed_outcome}
            eq 'preflight_dominated_not_constructed';
    return [@STAGE_ORDER];
}

sub _stage_payload($construction, $expected, $stage) {
    my $spec = $construction->{specification};
    my ($profile, $level) = @{$spec}{qw(backend_profile level)};
    if ($stage eq 'construct') {
        my $projection = _construction_projection($construction);
        my @artifacts = ({
            suffix => 'construction.json',
            kind => 'backend_emission_construction_manifest',
            content => _canonical_json($projection) . "\n",
        });
        for my $input (@{$construction->{inputs}}) {
            push @artifacts, {
                suffix => 'sources/' . _safe_relative_path(
                    $input->{relative_path}),
                kind => $input->{role},
                content => $input->{content},
            };
        }
        return {
            status => 'backend_emission_construct_completed',
            oracle_id => 'backend_emission_construct_canonical',
            evidence => $projection,
            semantic_counts => {
                constructed_inputs => scalar(@{$construction->{inputs}}),
                construction_identity_records => 1,
            },
            artifacts => \@artifacts,
        };
    }

    if ($stage eq 'emit') {
        my $evaluation = $PRODUCER->evaluate({
            construction => $construction,
        });
        confess "canonical backend-emission evaluation failed in emit stage\n"
            unless $evaluation->{ok};
        confess "canonical backend-emission evaluation changed after admission\n"
            unless _canonical_json($evaluation) eq _canonical_json($expected);
        my $projection = _measurement_evidence_projection($evaluation);
        my $oracle = _selected_artifact_oracle($evaluation);
        my %counts = (backend_emission_evaluation_records => 1);
        for my $key (sort keys %$oracle) {
            my $value = $oracle->{$key};
            next unless defined($value) && !ref($value)
                && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
            my $safe = $key;
            $safe =~ s/[^A-Za-z0-9_]/_/g;
            $counts{"backend_emission_$safe"} = 0 + $value;
        }
        $counts{backend_emission_provider_verification_records} = 1
            if $profile eq 'vhdl_osvvm_qualified';
        return {
            status => 'backend_emission_emit_' . $evaluation->{observed_outcome},
            oracle_id => 'backend_emission_emit_canonical',
            evidence => $projection,
            semantic_counts => \%counts,
            artifacts => [{
                suffix => 'emission-evaluation.json',
                kind => 'backend_emission_evaluation',
                content => _canonical_json($evaluation) . "\n",
            }],
        };
    }

    my $inputs = $PRODUCER->_measurement_inputs({
        construction => $construction,
        stage => $stage,
    });
    my $semantic_sha = sha256_hex(_canonical_json($inputs->{semantic_ir}));
    confess "canonical backend-emission semantic identity changed\n"
        unless $semantic_sha eq $expected->{stage_identities}
            {semantic_ir_sha256};
    if ($stage eq 'parse_validate') {
        my $evidence = {
            backend_profile => $profile,
            level => $level,
            workload_identity => $construction->{workload_identity},
            source => _clone($inputs->{source}),
            semantic_ir_sha256 => $semantic_sha,
            status => 'accepted',
            diagnostics => [],
        };
        return {
            status => 'backend_emission_parse_validate_accepted',
            oracle_id => 'backend_emission_parse_validate_canonical',
            evidence => $evidence,
            semantic_counts => {
                semantic_ir_nodes => _json_node_count($inputs->{semantic_ir}),
                parse_diagnostics => 0,
            },
            artifacts => [{
                suffix => 'parse-validation.json',
                kind => 'backend_emission_parse_validation',
                content => _canonical_json($evidence) . "\n",
            }],
        };
    }

    my $bridge_sha = sha256_hex(
        _canonical_json($inputs->{bridge_manifest}),
    );
    my $backend_inputs_sha = sha256_hex(
        _canonical_json($inputs->{backend_inputs}),
    );
    confess "canonical backend-emission bridge identity changed\n"
        unless $bridge_sha eq $expected->{stage_identities}
            {bridge_manifest_sha256};
    confess "canonical backend-emission backend-input identity changed\n"
        unless $backend_inputs_sha eq $expected->{stage_identities}
            {backend_inputs_sha256};
    if ($stage eq 'bridge') {
        my $evidence = {
            backend_profile => $profile,
            level => $level,
            workload_identity => $construction->{workload_identity},
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            backend_inputs_sha256 => $backend_inputs_sha,
            backend_input_artifacts =>
                _backend_input_artifact_count($inputs->{backend_inputs}),
            status => 'accepted',
            diagnostics => [],
        };
        return {
            status => 'backend_emission_bridge_accepted',
            oracle_id => 'backend_emission_bridge_canonical',
            evidence => $evidence,
            semantic_counts => {
                bridge_manifest_nodes =>
                    _json_node_count($inputs->{bridge_manifest}),
                backend_input_artifacts =>
                    _backend_input_artifact_count($inputs->{backend_inputs}),
                bridge_diagnostics => 0,
            },
            artifacts => [{
                suffix => 'bridge-validation.json',
                kind => 'backend_emission_bridge_validation',
                content => _canonical_json($evidence) . "\n",
            }],
        };
    }

    confess "backend-emission stage '$stage' is not owned\n"
        unless $stage eq 'bind_plan';
    my $execution_sha = sha256_hex(
        _canonical_json($inputs->{execution_ir}),
    );
    my $plan_sha = sha256_hex(_canonical_json($inputs->{plan}));
    confess "canonical backend-emission execution identity changed\n"
        unless $execution_sha eq $expected->{stage_identities}
            {execution_ir_sha256};
    confess "canonical backend-emission plan identity changed\n"
        unless $plan_sha eq $expected->{stage_identities}{plan_sha256};
    my $evidence = {
        backend_profile => $profile,
        level => $level,
        workload_identity => $construction->{workload_identity},
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        backend_inputs_sha256 => $backend_inputs_sha,
        execution_ir_sha256 => $execution_sha,
        plan_sha256 => $plan_sha,
        route_metrics => _clone($expected->{route_metrics}),
        status => 'accepted',
        diagnostics => [],
    };
    my %semantic_counts = (
        execution_ir_nodes => _json_node_count($inputs->{execution_ir}),
        plan_nodes => _json_node_count($inputs->{plan}),
    );
    for my $key (sort keys %{$expected->{route_metrics}}) {
        $semantic_counts{"backend_emission_$key"} =
            0 + $expected->{route_metrics}{$key};
    }
    return {
        status => 'backend_emission_bind_plan_accepted',
        oracle_id => 'backend_emission_bind_plan_canonical',
        evidence => $evidence,
        semantic_counts => \%semantic_counts,
        artifacts => [{
            suffix => 'bind-plan-validation.json',
            kind => 'backend_emission_bind_plan_validation',
            content => _canonical_json($evidence) . "\n",
        }],
    };
}

sub _materialize_payload($context, $payload) {
    my @records;
    make_path($context->{output_root});
    for my $artifact (@{$payload->{artifacts}}) {
        my $suffix = _safe_relative_path($artifact->{suffix});
        my @parts = split m{/}, $suffix;
        my $path = File::Spec->catfile($context->{output_root}, @parts);
        my @parent = @parts;
        pop @parent;
        make_path(File::Spec->catdir($context->{output_root}, @parent))
            if @parent;
        open my $fh, '>:raw', $path
            or die "cannot create backend-emission measurement artifact: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close backend-emission measurement artifact: $!\n";
        push @records, {
            relative_path => "$context->{output_identity}/$suffix",
            kind => $artifact->{kind},
            bytes => bytes::length($artifact->{content}),
            lines => _line_count($artifact->{content}),
            sha256 => sha256_hex($artifact->{content}),
        };
    }
    @records = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @records;
    my $counts = {
        files => scalar(@records), lines => 0, bytes => 0,
        objects => scalar(@records),
    };
    for my $record (@records) {
        $counts->{lines} += $record->{lines};
        $counts->{bytes} += $record->{bytes};
    }
    return {
        ok => JSON::PP::true,
        status => $payload->{status},
        output_counts => $counts,
        semantic_object_counts => _clone($payload->{semantic_counts}),
        correctness_oracles => [{
            oracle_id => $payload->{oracle_id},
            ok => JSON::PP::true,
            evidence => _clone($payload->{evidence}),
        }],
        artifacts => \@records,
        diagnostic => undef,
    };
}

sub _finalize_report($raw) {
    my $construction = $raw->{construction};
    my $evaluation = $raw->{evaluation};
    my $spec = $construction->{specification};
    my $validation = $raw->{validation_record};
    my @measured = @{$raw->{measurement_records}};
    my $controller = {
        applicable => JSON::PP::true,
        reason => undef,
    };
    my $applicability = $raw->{mode} eq 'validation'
        ? {applicable => JSON::PP::false, reason => 'correctness_only_requested'}
        : $validation->{outcome} ne 'accepted'
            ? {applicable => JSON::PP::false, reason => 'correctness_validation_failed'}
            : !$evaluation->{outcome_contract}{artifacts_emitted}
                ? {applicable => JSON::PP::false, reason => 'authoritative_non_emission'}
                : {applicable => JSON::PP::true, reason => undef};
    my @exclusions = map {
        {
            run_ordinal => $_->{run_ordinal},
            reason => $_->{outcome},
            measurement_identity => $_->{measurement_identity},
            diagnostic => _clone($_->{diagnostic}),
        }
    } grep { $_->{outcome} ne 'accepted' } @measured;
    my @records = ($validation, @measured);
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my ($outcome, @diagnostics);
    if ($validation->{outcome} ne 'accepted') {
        $outcome = 'rejected';
        push @diagnostics, _clone($validation->{diagnostic});
    }
    elsif ($raw->{mode} eq 'validation') {
        $outcome = 'accepted_validation';
    }
    elsif (!$applicability->{applicable}) {
        $outcome = 'validated_not_measured';
    }
    elsif (@exclusions || @measured != $MODE_SAMPLES{$raw->{mode}}) {
        $outcome = 'rejected';
        push @diagnostics, _clone($exclusions[0]{diagnostic})
            if @exclusions;
    }
    else {
        $outcome = 'accepted';
    }
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        family => $FAMILY,
        backend_profile => $spec->{backend_profile},
        level => $spec->{level},
        primary_axis => $PRIMARY_AXIS,
        workload_identity => $construction->{workload_identity},
        mode => $raw->{mode},
        requested_counts => _clone($evaluation->{requested_counts}),
        profile_authority => _authority($spec->{backend_profile}),
        controller_applicability => $controller,
        measurement_applicability => $applicability,
        provider_verification => _provider_verification(
            $spec->{backend_profile}, $evaluation,
        ),
        canonical_evaluation =>
            _measurement_evidence_projection($evaluation),
        validation_record => _clone($validation),
        measurement_records => _clone(\@measured),
        sample_exclusions => \@exclusions,
        outcome => $outcome,
        diagnostics => \@diagnostics,
        cleanup => {
            records_total => scalar(@records),
            ephemeral_removed => $removed
                ? JSON::PP::true : JSON::PP::false,
            residue => \@residue,
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{report_identity} = _report_identity($report);
    _validate_report($raw->{repository_root}, $report);
    return _clone($report);
}

sub _validate_report($repo_root, $report) {
    confess "backend-emission measurement report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    _exact_keys($report, \@REPORT_KEYS, 'backend-emission measurement report');
    confess "backend-emission measurement report schema is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1;
    _validate_profile_level($report->{backend_profile}, $report->{level});
    confess "backend-emission measurement family or axis changed\n"
        unless ($report->{family} // '') eq $FAMILY
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS;
    confess "backend-emission measurement mode is invalid\n"
        unless ($report->{mode} // '') eq 'validation'
            || exists $MODE_SAMPLES{$report->{mode}};
    my ($construction, $evaluation) = _canonical_pair(
        $repo_root, $report->{backend_profile}, $report->{level},
    );
    confess "backend-emission measurement workload identity changed\n"
        unless ($report->{workload_identity} // '')
            eq $construction->{workload_identity};
    confess "backend-emission requested counts changed\n"
        unless _canonical_json($report->{requested_counts})
            eq _canonical_json($evaluation->{requested_counts});
    _exact_keys(
        $report->{profile_authority}, \@AUTHORITY_KEYS,
        'backend-emission profile authority',
    );
    confess "backend-emission profile authority changed\n"
        unless _canonical_json($report->{profile_authority})
            eq _canonical_json(_authority($report->{backend_profile}));
    _validate_applicability(
        $report->{controller_applicability}, 'controller applicability',
    );
    _validate_applicability(
        $report->{measurement_applicability}, 'measurement applicability',
    );
    _exact_keys(
        $report->{provider_verification}, \@PROVIDER_KEYS,
        'provider verification',
    );
    _validate_boolean(
        $report->{provider_verification}{applicable},
        'provider verification applicability',
    );
    _validate_boolean(
        $report->{provider_verification}{included_in_emit},
        'provider verification inclusion',
    );
    _validate_boolean(
        $report->{provider_verification}{read_only},
        'provider verification read-only classification',
    );
    _validate_boolean(
        $report->{provider_verification}{external_verification_tool},
        'provider external-tool classification',
    );
    confess "provider verification classification changed\n"
        unless _canonical_json($report->{provider_verification})
            eq _canonical_json(_provider_verification(
                $report->{backend_profile}, $evaluation,
            ));
    confess "canonical backend-emission evaluation changed\n"
        unless _canonical_json($report->{canonical_evaluation})
            eq _canonical_json(
                _measurement_evidence_projection($evaluation),
            );
    confess "backend-emission measurement records must be one array\n"
        unless ref($report->{measurement_records}) eq 'ARRAY';
    confess "backend-emission sample exclusions must be one array\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY';
    confess "backend-emission diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    confess "backend-emission nonclaims must be one array\n"
        unless ref($report->{explicit_nonclaims}) eq 'ARRAY';
    my $expected_controller = {
        applicable => JSON::PP::true, reason => undef,
    };
    confess "backend-emission controller applicability changed\n"
        unless _canonical_json($report->{controller_applicability})
            eq _canonical_json($expected_controller);
    my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
    my $validation = $report->{validation_record};
    confess "backend-emission report has no validation record\n"
        unless ref($validation) eq 'HASH' && !blessed($validation);
    $foundation->validate_record({record => $validation});
    my @measured = @{$report->{measurement_records}};
    $foundation->validate_record({record => $_}) for @measured;
    my @records = ($validation, @measured);
    confess "backend-emission validation ordinal changed\n"
        unless $validation->{run_class} eq 'validation'
            && $validation->{run_ordinal} == 0;
    for my $record (@records) {
        confess "backend-emission record workload changed\n"
            unless $record->{workload_identity}
                    eq $construction->{workload_identity}
                && _canonical_json($record->{workload_specification})
                    eq _canonical_json($construction->{specification});
        _validate_record_profile_evidence(
            $record, $construction, $evaluation,
        );
    }
    if ($report->{mode} eq 'validation') {
        confess "validation-only backend-emission report retained samples\n"
            if @measured;
    }
    else {
        confess "backend-emission mode does not match selected level\n"
            unless ($LEVEL_MODE{$report->{level}} // '') eq $report->{mode};
        my $expected_class = $MODE_CLASS{$report->{mode}};
        for my $index (0 .. $#measured) {
            confess "backend-emission sample ordinal or class changed\n"
                unless $measured[$index]{run_class} eq $expected_class
                    && $measured[$index]{run_ordinal} == $index + 1;
        }
    }
    my $expected_applicability = $report->{mode} eq 'validation'
        ? {applicable => JSON::PP::false, reason => 'correctness_only_requested'}
        : $validation->{outcome} ne 'accepted'
            ? {applicable => JSON::PP::false, reason => 'correctness_validation_failed'}
            : !$evaluation->{outcome_contract}{artifacts_emitted}
                ? {applicable => JSON::PP::false, reason => 'authoritative_non_emission'}
                : {applicable => JSON::PP::true, reason => undef};
    confess "backend-emission measurement applicability changed\n"
        unless _canonical_json($report->{measurement_applicability})
            eq _canonical_json($expected_applicability);
    my @expected_exclusions = map {
        {
            run_ordinal => $_->{run_ordinal},
            reason => $_->{outcome},
            measurement_identity => $_->{measurement_identity},
            diagnostic => _clone($_->{diagnostic}),
        }
    } grep { $_->{outcome} ne 'accepted' } @measured;
    _exact_keys(
        $_, \@EXCLUSION_KEYS, 'backend-emission sample exclusion',
    ) for @{$report->{sample_exclusions}};
    confess "backend-emission sample exclusion evidence changed\n"
        unless _canonical_json($report->{sample_exclusions})
            eq _canonical_json(\@expected_exclusions);
    confess "applicable backend-emission measurement lacks an exclusion\n"
        if $expected_applicability->{applicable}
            && @measured != $MODE_SAMPLES{$report->{mode}}
            && !@expected_exclusions;
    _exact_keys($report->{cleanup}, \@CLEANUP_KEYS,
        'backend-emission cleanup');
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my $expected_cleanup = {
        records_total => scalar(@records),
        ephemeral_removed => $removed
            ? JSON::PP::true : JSON::PP::false,
        residue => \@residue,
    };
    confess "backend-emission cleanup evidence changed\n"
        unless _canonical_json($report->{cleanup})
            eq _canonical_json($expected_cleanup);
    confess "backend-emission nonclaim boundary changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    my ($expected_outcome, @expected_diagnostics);
    if ($validation->{outcome} ne 'accepted') {
        $expected_outcome = 'rejected';
        push @expected_diagnostics, _clone($validation->{diagnostic});
    }
    elsif ($report->{mode} eq 'validation') {
        $expected_outcome = 'accepted_validation';
    }
    elsif (!$expected_applicability->{applicable}) {
        $expected_outcome = 'validated_not_measured';
    }
    elsif (@expected_exclusions
            || @measured != $MODE_SAMPLES{$report->{mode}}) {
        $expected_outcome = 'rejected';
        push @expected_diagnostics,
            _clone($expected_exclusions[0]{diagnostic})
            if @expected_exclusions;
    }
    else {
        $expected_outcome = 'accepted';
    }
    confess "backend-emission report outcome changed\n"
        unless ($report->{outcome} // '') eq $expected_outcome;
    confess "backend-emission report diagnostics changed\n"
        unless _canonical_json($report->{diagnostics})
            eq _canonical_json(\@expected_diagnostics);
    confess "backend-emission report identity changed\n"
        unless ($report->{report_identity} // '') eq _report_identity($report);
    return;
}

sub _validate_record_profile_evidence($record, $construction, $evaluation) {
    my %planned = map { $_ => 1 } @{_planned_stages($evaluation)};
    my %measurement = map { $_->{stage} => $_ }
        @{$record->{stage_measurements}};
    my %oracle = map { $_->{oracle_id} => $_ }
        @{$record->{correctness_oracles}};
    my @expected_artifacts;
    my $stage_failed = 0;
    for my $stage (@STAGE_ORDER) {
        my $entry = $measurement{$stage};
        confess "backend-emission record is missing stage '$stage'\n"
            unless defined $entry;
        if (!$planned{$stage}) {
            confess "inapplicable backend-emission stage '$stage' executed\n"
                unless $entry->{status} eq 'not_run';
            my $reason = $stage_failed
                ? 'prior_stage_failed' : 'not_applicable_to_invocation';
            confess "inapplicable backend-emission stage reason changed\n"
                unless $entry->{not_run_reason} eq $reason;
            next;
        }
        if ($entry->{status} eq 'not_run') {
            confess "planned backend-emission stage was skipped before failure\n"
                unless $stage_failed
                    && $entry->{not_run_reason} eq 'prior_stage_failed';
            next;
        }
        confess "backend-emission stage executed after failure\n"
            if $stage_failed;
        my $expected_command = {
            logical_name => "vial_scale_backend_emission_$stage",
            arguments => [
                $construction->{specification}{backend_profile},
                $construction->{specification}{level},
                $PRIMARY_AXIS,
            ],
            thread_count => 1,
            job_count => 1,
        };
        confess "backend-emission stage command identity changed\n"
            unless _canonical_json($entry->{command_identity})
                eq _canonical_json($expected_command);
        my $expected_input = $stage eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json(
                    $construction->{specification},
                )),
                objects => 1,
            }
            : _source_counts($construction);
        confess "backend-emission stage input counts changed\n"
            unless _canonical_json($entry->{input_counts})
                eq _canonical_json($expected_input);
        if ($entry->{status} eq 'validation_rejected'
                || $entry->{status} eq 'measured_rejected') {
            confess "rejected backend-emission stage conflicts with accepted record\n"
                if $record->{outcome} eq 'accepted';
            confess "rejected backend-emission stage retained output evidence\n"
                unless _canonical_json($entry->{output_counts})
                        eq _canonical_json({
                            files => 0, lines => 0, bytes => 0, objects => 0,
                        })
                    && _canonical_json($entry->{semantic_object_counts}) eq '{}'
                    && @{$entry->{correctness_oracle_ids}} == 0
                    && !grep { $_->{stage} eq $stage }
                        @{$record->{artifacts}{records}};
            $stage_failed = 1;
            next;
        }
        confess "backend-emission stage has a non-success status\n"
            unless $entry->{status} eq 'validated_unmeasured'
                || $entry->{status} eq 'measured';
        my $payload = _stage_payload($construction, $evaluation, $stage);
        my $materialized = _materialized_projection($stage, $payload);
        confess "backend-emission stage output counts changed\n"
            unless _canonical_json($entry->{output_counts})
                eq _canonical_json($materialized->{output_counts});
        confess "backend-emission stage semantic counts changed\n"
            unless _canonical_json($entry->{semantic_object_counts})
                eq _canonical_json($payload->{semantic_counts});
        my $owned = $oracle{$payload->{oracle_id}};
        confess "backend-emission stage oracle is missing\n"
            unless defined($owned) && $owned->{stage} eq $stage
                && $owned->{ok};
        confess "backend-emission stage oracle evidence changed\n"
            unless _canonical_json($owned->{evidence})
                eq _canonical_json($payload->{evidence});
        push @expected_artifacts, @{$materialized->{artifact_records}};
    }
    confess "accepted backend-emission record contains a failed stage\n"
        if $record->{outcome} eq 'accepted' && $stage_failed;
    confess "backend-emission artifact evidence changed\n"
        unless _canonical_json($record->{artifacts}{records})
            eq _canonical_json(\@expected_artifacts);
}

sub _materialized_projection($stage, $payload) {
    my @records = map {
        {
            stage => $stage,
            relative_path => "outputs/$stage/$_->{suffix}",
            kind => $_->{kind},
            bytes => bytes::length($_->{content}),
            lines => _line_count($_->{content}),
            sha256 => sha256_hex($_->{content}),
        }
    } @{$payload->{artifacts}};
    @records = sort { $a->{relative_path} cmp $b->{relative_path} } @records;
    my $counts = {
        files => scalar(@records), lines => 0, bytes => 0,
        objects => scalar(@records),
    };
    for my $record (@records) {
        $counts->{lines} += $record->{lines};
        $counts->{bytes} += $record->{bytes};
    }
    return {output_counts => $counts, artifact_records => \@records};
}

sub _canonical_pair($repo_root, $profile, $level) {
    my $construction = _canonical_construction($repo_root, $profile, $level);
    my $evaluation = $PRODUCER->evaluate({construction => $construction});
    confess "canonical backend-emission evaluation failed its oracle\n"
        unless $evaluation->{ok};
    my $validated = $PRODUCER->validate_evaluation({
        construction => $construction,
        evaluation => $evaluation,
    });
    confess "canonical backend-emission evaluation validation changed evidence\n"
        unless _canonical_json($validated) eq _canonical_json($evaluation);
    confess "canonical backend-emission evaluation schema changed\n"
        unless ($evaluation->{schema} // '') eq $EVALUATION_SCHEMA
            && ($evaluation->{schema_version} // -1) == 1;
    return (_clone($construction), _clone($evaluation));
}

sub _canonical_construction($repo_root, $profile, $level) {
    _validate_profile_level($profile, $level);
    my $hial = _slurp_repository_file(
        $repo_root, 'ppif/ahb_lite_subordinate.ppif',
    );
    my $vial = _slurp_repository_file(
        $repo_root, 'vial/ahb_subordinate_base_output_arbitration.vial',
    );
    my $first = $PRODUCER->construct({
        backend_profile => $profile,
        level => $level,
        reference_hial_text => $hial,
        reference_vial_text => $vial,
    });
    my $second = $PRODUCER->construct({
        backend_profile => $profile,
        level => $level,
        reference_hial_text => $hial,
        reference_vial_text => $vial,
    });
    confess "canonical backend-emission construction is nondeterministic\n"
        unless _canonical_json($second) eq _canonical_json($first);
    confess "canonical backend-emission construction failed\n"
        unless $first->{ok};
    return _clone($first);
}

sub _construction_projection($construction) {
    return {
        schema => $construction->{schema},
        schema_version => $construction->{schema_version},
        family => $construction->{specification}{family},
        backend_profile => $construction->{specification}{backend_profile},
        level => $construction->{specification}{level},
        primary_axis => $construction->{specification}{primary_axis},
        status => $construction->{status},
        workload_identity => $construction->{workload_identity},
        construction_sha256 => sha256_hex(_canonical_json($construction)),
        specification => _clone($construction->{specification}),
        input_identities => _clone($construction->{input_identities}),
        diagnostics => _measurement_evidence_projection(
            $construction->{diagnostics},
        ),
    };
}

sub _measurement_evidence_projection($value) {
    return $value unless ref($value);
    return $value
        if blessed($value)
            && ($value->isa('JSON::PP::Boolean')
                || $value->isa('JSON::PP::BooleanBase'));
    return [map { _measurement_evidence_projection($_) } @$value]
        if ref($value) eq 'ARRAY';
    confess "backend-emission evidence contains a non-JSON reference\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    confess "backend-emission evidence aliases path and semantic_path\n"
        if exists($value->{path}) && exists($value->{semantic_path});
    my %projection;
    for my $key (sort keys %$value) {
        my $projected = $key eq 'path' ? 'semantic_path' : $key;
        confess "backend-emission evidence projection collides at '$projected'\n"
            if exists $projection{$projected};
        $projection{$projected} =
            _measurement_evidence_projection($value->{$key});
    }
    return \%projection;
}

sub _selected_artifact_oracle($evaluation) {
    my @selected = grep { defined $_ }
        @{$evaluation->{artifact_oracle}}
            {qw(portable_sv portable_vhdl osvvm native_uvm)};
    confess "backend-emission evaluation must select exactly one artifact oracle\n"
        unless @selected == 1 && ref($selected[0]) eq 'HASH';
    return $selected[0];
}

sub _provider_verification($profile, $evaluation) {
    my $is_osvvm = $profile eq 'vhdl_osvvm_qualified';
    if ($is_osvvm) {
        my $oracle = $evaluation->{artifact_oracle}{osvvm};
        confess "OSVVM evaluation lacks provider-verification evidence\n"
            unless ref($oracle) eq 'HASH'
                && $oracle->{provider_verification_reused};
    }
    return {
        applicable => $is_osvvm ? JSON::PP::true : JSON::PP::false,
        included_in_emit => $is_osvvm
            ? JSON::PP::true : JSON::PP::false,
        read_only => $is_osvvm ? JSON::PP::true : JSON::PP::false,
        external_verification_tool => JSON::PP::false,
        classification => $is_osvvm
            ? 'sealed_osvvm_2026_05_provider_materialization'
            : 'not_applicable',
    };
}

sub _authority($profile) {
    _validate_profile_level($profile, 'reference_v1');
    my $authorities = backend_emission_profile_authorities();
    my $authority = {
        family => $FAMILY,
        backend_profile => $profile,
        producer_class => $PRODUCER,
        stage_order => [@STAGE_ORDER],
        workload_schema => $WORKLOAD_SCHEMA,
        evaluation_schema => $EVALUATION_SCHEMA,
        structural_authority => _clone($authorities->{$profile}),
        structural_emission_only => JSON::PP::true,
        external_verification_tool => JSON::PP::false,
        authority_identity => undef,
    };
    my %identity = %$authority;
    delete $identity{authority_identity};
    $authority->{authority_identity} = 'backend-emission-authority/'
        . sha256_hex(_canonical_json(\%identity));
    return $authority;
}

sub _source_counts($construction) {
    my $counts = {
        files => scalar(@{$construction->{inputs}}),
        lines => 0,
        bytes => 0,
        objects => scalar(@{$construction->{inputs}}),
    };
    for my $input (@{$construction->{inputs}}) {
        $counts->{lines} += _line_count($input->{content});
        $counts->{bytes} += bytes::length($input->{content});
    }
    return $counts;
}

sub _backend_input_artifact_count($inputs) {
    confess "backend-emission inputs must be one hash\n"
        unless ref($inputs) eq 'HASH';
    my $count = 0;
    for my $key (sort keys %$inputs) {
        confess "backend-emission input family '$key' must be an array\n"
            unless ref($inputs->{$key}) eq 'ARRAY';
        $count += @{$inputs->{$key}};
    }
    return $count;
}

sub _report_identity($report) {
    my %identity = %$report;
    delete $identity{report_identity};
    return 'backend-emission-measurement/'
        . sha256_hex(_canonical_json(\%identity));
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
}

sub _repository_root($raw) {
    confess "repository_root must name one existing directory\n"
        unless defined($raw) && !ref($raw) && -d $raw;
    return File::Spec->rel2abs($raw);
}

sub _slurp_repository_file($repo_root, $relative) {
    my @parts = split m{/}, _safe_relative_path($relative);
    my $path = File::Spec->catfile($repo_root, @parts);
    confess "backend-emission anchor is not one regular repository file\n"
        unless -f $path && !-l $path;
    open my $fh, '<:raw', $path
        or confess "cannot read backend-emission anchor\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close backend-emission anchor\n";
    return $content;
}

sub _require_active_guard() {
    confess "backend-emission measurement requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "active backend-emission guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _validate_profile_level($profile, $level) {
    confess "backend-emission measurement profile is not selected\n"
        unless defined($profile) && !ref($profile) && $PROFILE{$profile};
    confess "backend-emission measurement level is not selected\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
    my %owned = map {
        (join('/', $_->{backend_profile}, $_->{level}) => 1)
    }
        @{$PRODUCER->owned_shapes};
    confess "backend-emission measurement shape is not producer-owned\n"
        unless $owned{"$profile/$level"};
}

sub _validate_applicability($value, $label) {
    _exact_keys($value, \@APPLICABILITY_KEYS, $label);
    _validate_boolean($value->{applicable}, $label);
    confess "$label reason is invalid\n"
        if defined($value->{reason}) && !_safe_token($value->{reason});
}

sub _json_node_count($value) {
    return 0 unless ref($value);
    return 1 + _sum(map { _json_node_count($value->{$_}) }
        sort keys %$value) if ref($value) eq 'HASH';
    return 1 + _sum(map { _json_node_count($_) } @$value)
        if ref($value) eq 'ARRAY';
    return 1;
}

sub _sum(@values) {
    my $sum = 0;
    $sum += $_ for @values;
    return $sum;
}

sub _line_count($content) {
    return 0 unless bytes::length($content);
    my $count = () = $content =~ /\n/g;
    $count++ unless $content =~ /\n\z/;
    return $count;
}

sub _safe_relative_path($value) {
    confess "backend-emission artifact path must be repository-relative\n"
        unless defined($value) && !ref($value) && length($value)
            && $value !~ m{\A/}
            && $value !~ m{\A[A-Za-z]:[\\/]}
            && $value !~ m{(?:\A|/)\.\.(?:/|\z)}
            && $value !~ m{//}
            && $value !~ /[\x00-\x1f\x7f]/;
    return $value;
}

sub _safe_token($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9][A-Za-z0-9_.:-]*\z/;
}

sub _validate_boolean($value, $label) {
    confess "$label must be one JSON boolean\n"
        unless blessed($value)
            && ($value->isa('JSON::PP::Boolean')
                || $value->isa('JSON::PP::BooleanBase'));
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

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->utf8(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return JSON::PP->new->canonical(1)->utf8(1)
        ->decode(_canonical_json($value));
}

1;
