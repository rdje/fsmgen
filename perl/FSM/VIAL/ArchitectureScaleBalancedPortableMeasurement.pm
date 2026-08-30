package FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;

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

use FSM::VIAL::ArchitectureScaleBalancedPortable;
use FSM::VIAL::ArchitectureScaleBalancedPortableEmission;
use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_measurement_set.v1';
my $WORKLOAD_SCHEMA = 'fsmgen.vial_architecture_scale_workload.v1';
my $COMPOSITION_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_report.v1';
my $EMISSION_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_emission_report.v1';
my $FAMILY = 'balanced_portable_v1';
my $BACKEND_PROFILE = 'sv_portable_verilator';
my $LEVEL = 'gate_candidate_v1';
my $PRIMARY_AXIS = 'interaction_profile';
my $MODE = 'gate_measurement';
my $SAMPLES = 3;
my $PRODUCER = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $EMITTER = 'FSM::VIAL::ArchitectureScaleBalancedPortableEmission';
my $OWNERSHIP =
    'FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification';
my $HIAL_ANCHOR = 'ppif/ahb_lite_subordinate.ppif';
my $VIAL_ANCHOR = 'vial/ahb_subordinate_base_output_arbitration.vial';
my @STAGE_ORDER = qw(construct parse_validate bridge bind_plan emit);
my @REPORT_KEYS = qw(
    schema schema_version report_identity family backend_profile level
    primary_axis workload_identity mode requested_counts member_authority
    controller_applicability measurement_applicability execution_applicability
    canonical_composition canonical_emission validation_record
    measurement_records sample_exclusions outcome diagnostics cleanup
    explicit_nonclaims
);
my @AUTHORITY_KEYS = qw(
    family backend_profile level primary_axis producer_class emitter_class
    stage_order workload_schema composition_schema emission_schema
    structural_emission_only private_revision_2
    external_execution_applicable authority_identity
);
my @APPLICABILITY_KEYS = qw(applicable reason);
my @EXCLUSION_KEYS = qw(
    run_ordinal reason measurement_identity diagnostic
);
my @CLEANUP_KEYS = qw(records_total ephemeral_removed residue);
my @NONCLAIMS = (
    @{FSM::VIAL::ArchitectureScaleMeasurement->explicit_nonclaims},
    qw(
        external_verification_tool compile_analyze_elaborate_run_trace_result
        backend_support backend_capacity reached_boundary
        provider_performance public_api_change revision_1_public_bridge
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

sub member_authority($class) {
    _exact_invocant($class, 'member_authority');
    return _clone(_authority());
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $request = _request('construct', \@args, [qw(repository_root)]);
    my $repo_root = _repository_root($request->{repository_root});
    return _clone(_canonical_construction($repo_root));
}

sub validate_member($class, @args) {
    _exact_invocant($class, 'validate_member');
    my $request = _request(
        'validate_member', \@args, [qw(repository_root)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $composition, $emission) =
        _canonical_bundle($repo_root);
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        composition => $composition,
        emission => $emission,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        composition => $composition,
        emission => $emission,
        mode => 'validation',
        validation_record => $validation,
        measurement_records => [],
    });
}

sub measure_member($class, @args) {
    _exact_invocant($class, 'measure_member');
    my $request = _request(
        'measure_member', \@args, [qw(repository_root)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $composition, $emission) =
        _canonical_bundle($repo_root);
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        composition => $composition,
        emission => $emission,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    my @measured;
    if ($validation->{outcome} eq 'accepted') {
        for my $ordinal (1 .. $SAMPLES) {
            my $record = _run_record({
                repository_root => $repo_root,
                construction => $construction,
                composition => $composition,
                emission => $emission,
                run_class => $MODE,
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
        composition => $composition,
        emission => $emission,
        mode => $MODE,
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
        construction => $raw->{construction}{workload},
        run_class => $raw->{run_class},
        run_ordinal => $raw->{run_ordinal},
        validation_record => $raw->{validation_record},
        stage_plan => _stage_plan(
            $raw->{repository_root}, $raw->{construction},
            $raw->{composition}, $raw->{emission},
        ),
    });
}

sub _stage_plan($repo_root, $construction, $composition, $emission) {
    my $specification = $construction->{workload}{specification};
    my $source_counts = _source_counts($construction);
    my @plan;
    for my $stage (@STAGE_ORDER) {
        my $input_counts = $stage eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json($specification)),
                objects => 1,
            }
            : _clone($source_counts);
        push @plan, {
            stage => $stage,
            classification => 'fsmgen_owned',
            command_identity => {
                logical_name => "vial_scale_balanced_portable_$stage",
                arguments => [
                    $FAMILY, $BACKEND_PROFILE, $LEVEL, $PRIMARY_AXIS,
                ],
                thread_count => 1,
                job_count => 1,
            },
            input_counts => $input_counts,
            backend_timeout_seconds => undef,
            worker => sub {
                my ($context) = @_;
                my $stage_construction = $stage eq 'construct'
                    ? _canonical_construction($repo_root)
                    : _clone($construction);
                confess "balanced-portable construction changed in '$stage'\n"
                    unless _canonical_json($stage_construction)
                        eq _canonical_json($construction);
                my $first = _stage_payload(
                    $stage_construction, $composition, $emission, $stage,
                );
                return _materialize_payload($context, $first);
            },
        };
    }
    return \@plan;
}

sub _stage_payload($construction, $composition, $emission, $stage) {
    if ($stage eq 'construct') {
        my $rebuilt = _clone($construction);
        confess "balanced-portable construct stage changed canonical bytes\n"
            unless _canonical_json($rebuilt)
                eq _canonical_json($construction);
        return _expected_stage_payload(
            $construction, $composition, $emission, $stage,
        );
    }
    if ($stage eq 'emit') {
        my $rebuilt = $EMITTER->_measurement_evaluate({
            construction => $construction,
            composition => $composition,
        });
        confess "canonical balanced emission failed in emit stage\n"
            unless $rebuilt->{ok};
        confess "canonical balanced emission changed after admission\n"
            unless _canonical_json($rebuilt) eq _canonical_json($emission);
        return _expected_stage_payload(
            $construction, $composition, $emission, $stage,
        );
    }

    my $inputs = $PRODUCER->_measurement_inputs({
        construction => $construction,
        stage => $stage,
    });
    my $semantic_sha = sha256_hex(_canonical_json($inputs->{semantic_ir}));
    confess "canonical balanced semantic identity changed\n"
        unless $semantic_sha
            eq $composition->{stage_identities}{semantic_ir_sha256};
    confess "canonical balanced VIAL source identity changed\n"
        unless ($inputs->{source}{sha256} // '')
            eq $composition->{stage_identities}{vial_source_sha256};
    if ($stage ne 'parse_validate') {
        my $bridge_sha = sha256_hex(
            _canonical_json($inputs->{bridge_manifest}),
        );
        confess "canonical balanced bridge identity changed\n"
            unless $bridge_sha eq $composition->{stage_identities}
                {bridge_manifest_sha256};
    }
    if ($stage eq 'bind_plan') {
        my $execution_sha = sha256_hex(
            _canonical_json($inputs->{execution_ir}),
        );
        my $plan_sha = sha256_hex(_canonical_json($inputs->{plan}));
        confess "canonical balanced execution identity changed\n"
            unless $execution_sha eq $composition->{stage_identities}
                {execution_ir_sha256};
        confess "canonical balanced plan identity changed\n"
            unless $plan_sha eq $composition->{stage_identities}{plan_sha256};
    }
    return _expected_stage_payload(
        $construction, $composition, $emission, $stage,
    );
}

sub _expected_stage_payload($construction, $composition, $emission, $stage) {
    my $workload = $construction->{workload};
    if ($stage eq 'construct') {
        my $projection = _construction_projection($construction);
        my @artifacts = ({
            suffix => 'construction.json',
            kind => 'balanced_portable_construction_manifest',
            content => _canonical_json($projection) . "\n",
        });
        for my $input (@{$workload->{inputs}}) {
            push @artifacts, {
                suffix => 'sources/'
                    . _safe_relative_path($input->{relative_path}),
                kind => $input->{role},
                content => $input->{content},
            };
        }
        return {
            status => 'balanced_portable_construct_completed',
            oracle_id => 'balanced_portable_construct_canonical',
            evidence => $projection,
            semantic_counts => {
                constructed_inputs => scalar(@{$workload->{inputs}}),
                construction_identity_records => 1,
            },
            artifacts => \@artifacts,
        };
    }

    my $stage_identities = $composition->{stage_identities};
    my $gate_identity = sha256_hex(
        _canonical_json($composition->{gate_evidence}),
    );
    if ($stage eq 'parse_validate') {
        my $vial = _role_input($workload, 'vial_source');
        my $evidence = {
            family => $FAMILY,
            backend_profile => $BACKEND_PROFILE,
            level => $LEVEL,
            workload_identity => $workload->{workload_identity},
            gate_evidence_sha256 => $gate_identity,
            source => {
                relative_path => $vial->{relative_path},
                bytes => bytes::length($vial->{content}),
                sha256 => sha256_hex($vial->{content}),
            },
            semantic_ir_sha256 => $stage_identities->{semantic_ir_sha256},
            status => 'accepted',
            diagnostics => [],
        };
        return {
            status => 'balanced_portable_parse_validate_accepted',
            oracle_id => 'balanced_portable_parse_validate_canonical',
            evidence => $evidence,
            semantic_counts => {
                prerequisite_gate_reports =>
                    scalar(@{$composition->{gate_evidence}}),
                parse_diagnostics => 0,
            },
            artifacts => [{
                suffix => 'parse-validation.json',
                kind => 'balanced_portable_parse_validation',
                content => _canonical_json($evidence) . "\n",
            }],
        };
    }
    if ($stage eq 'bridge') {
        my $evidence = {
            family => $FAMILY,
            backend_profile => $BACKEND_PROFILE,
            level => $LEVEL,
            workload_identity => $workload->{workload_identity},
            gate_evidence_sha256 => $gate_identity,
            semantic_ir_sha256 => $stage_identities->{semantic_ir_sha256},
            bridge_manifest_sha256 =>
                $stage_identities->{bridge_manifest_sha256},
            selected_units => 0 + $composition->{metrics}{selected_units},
            selected_domains =>
                0 + $composition->{metrics}{selected_domains},
            endpoints => 0 + $composition->{metrics}{endpoints},
            status => 'accepted',
            diagnostics => [],
        };
        return {
            status => 'balanced_portable_bridge_accepted',
            oracle_id => 'balanced_portable_bridge_canonical',
            evidence => $evidence,
            semantic_counts => {
                prerequisite_gate_reports =>
                    scalar(@{$composition->{gate_evidence}}),
                selected_units => $evidence->{selected_units},
                selected_domains => $evidence->{selected_domains},
                endpoints => $evidence->{endpoints},
                bridge_diagnostics => 0,
            },
            artifacts => [{
                suffix => 'bridge-validation.json',
                kind => 'balanced_portable_bridge_validation',
                content => _canonical_json($evidence) . "\n",
            }],
        };
    }
    if ($stage eq 'bind_plan') {
        my $evidence = {
            family => $FAMILY,
            backend_profile => $BACKEND_PROFILE,
            level => $LEVEL,
            workload_identity => $workload->{workload_identity},
            gate_evidence_sha256 => $gate_identity,
            semantic_ir_sha256 => $stage_identities->{semantic_ir_sha256},
            bridge_manifest_sha256 =>
                $stage_identities->{bridge_manifest_sha256},
            execution_ir_sha256 =>
                $stage_identities->{execution_ir_sha256},
            plan_sha256 => $stage_identities->{plan_sha256},
            bindings => 0 + $composition->{metrics}{bindings},
            operations_total =>
                0 + $composition->{metrics}{operations_total},
            source_map_records =>
                0 + $composition->{metrics}{source_map_records},
            status => 'accepted',
            diagnostics => [],
        };
        return {
            status => 'balanced_portable_bind_plan_accepted',
            oracle_id => 'balanced_portable_bind_plan_canonical',
            evidence => $evidence,
            semantic_counts => {
                prerequisite_gate_reports =>
                    scalar(@{$composition->{gate_evidence}}),
                bindings => $evidence->{bindings},
                operations_total => $evidence->{operations_total},
                source_map_records => $evidence->{source_map_records},
                bind_plan_diagnostics => 0,
            },
            artifacts => [{
                suffix => 'bind-plan-validation.json',
                kind => 'balanced_portable_bind_plan_validation',
                content => _canonical_json($evidence) . "\n",
            }],
        };
    }

    confess "balanced-portable stage '$stage' is not owned\n"
        unless $stage eq 'emit';
    my $oracle = $emission->{artifact_oracle};
    my $evidence = _measurement_evidence_projection($emission);
    return {
        status => 'balanced_portable_emit_structural_emission_qualified',
        oracle_id => 'balanced_portable_emit_canonical',
        evidence => $evidence,
        semantic_counts => {
            prerequisite_gate_reports =>
                scalar(@{$composition->{gate_evidence}}),
            artifact_count => 0 + $oracle->{artifact_count},
            source_artifact_count => 0 + $oracle->{source_artifact_count},
            source_bytes => 0 + $oracle->{source_bytes},
            source_map_entries => 0 + $oracle->{source_map_entries},
            mapped_binding_count => 0 + $oracle->{mapped_binding_count},
            mapped_operation_count => 0 + $oracle->{mapped_operation_count},
            emission_diagnostics => 0,
        },
        artifacts => [{
            suffix => 'emission-evaluation.json',
            kind => 'balanced_portable_emission_evaluation',
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
            or die "cannot create balanced measurement artifact: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close balanced measurement artifact: $!\n";
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
    my $workload = $construction->{workload};
    my $validation = $raw->{validation_record};
    my @measured = @{$raw->{measurement_records}};
    my $controller = {
        applicable => JSON::PP::true,
        reason => undef,
    };
    my $measurement = $raw->{mode} eq 'validation'
        ? {applicable => JSON::PP::false,
            reason => 'correctness_only_requested'}
        : $validation->{outcome} ne 'accepted'
            ? {applicable => JSON::PP::false,
                reason => 'correctness_validation_failed'}
            : {applicable => JSON::PP::true, reason => undef};
    my $execution = {
        applicable => JSON::PP::false,
        reason => 'no_qualified_private_revision_2_runtime_route',
    };
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
    elsif (@exclusions || @measured != $SAMPLES) {
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
        backend_profile => $BACKEND_PROFILE,
        level => $LEVEL,
        primary_axis => $PRIMARY_AXIS,
        workload_identity => $workload->{workload_identity},
        mode => $raw->{mode},
        requested_counts =>
            _clone($workload->{specification}{requested_counts}),
        member_authority => _authority(),
        controller_applicability => $controller,
        measurement_applicability => $measurement,
        execution_applicability => $execution,
        canonical_composition =>
            _measurement_evidence_projection($raw->{composition}),
        canonical_emission =>
            _measurement_evidence_projection($raw->{emission}),
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
    _validate_report(
        $raw->{repository_root}, $report,
        [$construction, $raw->{composition}, $raw->{emission}],
    );
    return _clone($report);
}

sub _validate_report($repo_root, $report, $canonical = undef) {
    confess "balanced measurement report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    _exact_keys($report, \@REPORT_KEYS, 'balanced measurement report');
    confess "balanced measurement report schema is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1;
    confess "balanced measurement member identity changed\n"
        unless ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $BACKEND_PROFILE
            && ($report->{level} // '') eq $LEVEL
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS;
    confess "balanced measurement mode is invalid\n"
        unless ($report->{mode} // '') eq 'validation'
            || ($report->{mode} // '') eq $MODE;
    my $expected_execution = {
        applicable => JSON::PP::false,
        reason => 'no_qualified_private_revision_2_runtime_route',
    };
    confess "balanced execution applicability changed\n"
        unless ref($report->{execution_applicability}) eq 'HASH'
            && _canonical_json($report->{execution_applicability})
                eq _canonical_json($expected_execution);
    my ($construction, $composition, $emission) = defined($canonical)
        ? map { _clone($_) } @$canonical
        : _canonical_bundle($repo_root);
    my $workload = $construction->{workload};
    confess "balanced measurement workload identity changed\n"
        unless ($report->{workload_identity} // '')
            eq $workload->{workload_identity};
    confess "balanced measurement requested counts changed\n"
        unless _canonical_json($report->{requested_counts})
            eq _canonical_json(
                $workload->{specification}{requested_counts},
            );
    _exact_keys(
        $report->{member_authority}, \@AUTHORITY_KEYS,
        'balanced member authority',
    );
    confess "balanced member authority changed\n"
        unless _canonical_json($report->{member_authority})
            eq _canonical_json(_authority());
    _validate_applicability(
        $report->{controller_applicability},
        'controller applicability',
    );
    _validate_applicability(
        $report->{measurement_applicability},
        'measurement applicability',
    );
    _validate_applicability(
        $report->{execution_applicability},
        'execution applicability',
    );
    my $expected_controller = {
        applicable => JSON::PP::true, reason => undef,
    };
    confess "balanced controller applicability changed\n"
        unless _canonical_json($report->{controller_applicability})
            eq _canonical_json($expected_controller);
    confess "balanced execution applicability changed\n"
        unless _canonical_json($report->{execution_applicability})
            eq _canonical_json($expected_execution);
    confess "canonical balanced composition changed\n"
        unless _canonical_json($report->{canonical_composition})
            eq _canonical_json(
                _measurement_evidence_projection($composition),
            );
    confess "canonical balanced emission changed\n"
        unless _canonical_json($report->{canonical_emission})
            eq _canonical_json(
                _measurement_evidence_projection($emission),
            );
    confess "balanced measurement records must be one array\n"
        unless ref($report->{measurement_records}) eq 'ARRAY';
    confess "balanced sample exclusions must be one array\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY';
    confess "balanced diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    confess "balanced nonclaims must be one array\n"
        unless ref($report->{explicit_nonclaims}) eq 'ARRAY';
    my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
    my $validation = $report->{validation_record};
    confess "balanced report has no validation record\n"
        unless ref($validation) eq 'HASH' && !blessed($validation);
    $foundation->validate_record({record => $validation});
    my @measured = @{$report->{measurement_records}};
    $foundation->validate_record({record => $_}) for @measured;
    confess "balanced validation ordinal changed\n"
        unless $validation->{run_class} eq 'validation'
            && $validation->{run_ordinal} == 0;
    for my $index (0 .. $#measured) {
        confess "balanced sample ordinal or class changed\n"
            unless $measured[$index]{run_class} eq $MODE
                && $measured[$index]{run_ordinal} == $index + 1;
    }
    my @records = ($validation, @measured);
    for my $record (@records) {
        confess "balanced record workload changed\n"
            unless $record->{workload_identity}
                    eq $workload->{workload_identity}
                && _canonical_json($record->{workload_specification})
                    eq _canonical_json($workload->{specification});
        _validate_record_member_evidence(
            $record, $construction, $composition, $emission,
        );
    }
    if ($report->{mode} eq 'validation') {
        confess "validation-only balanced report retained samples\n"
            if @measured;
    }
    my $expected_measurement = $report->{mode} eq 'validation'
        ? {applicable => JSON::PP::false,
            reason => 'correctness_only_requested'}
        : $validation->{outcome} ne 'accepted'
            ? {applicable => JSON::PP::false,
                reason => 'correctness_validation_failed'}
            : {applicable => JSON::PP::true, reason => undef};
    confess "balanced measurement applicability changed\n"
        unless _canonical_json($report->{measurement_applicability})
            eq _canonical_json($expected_measurement);
    my @expected_exclusions = map {
        {
            run_ordinal => $_->{run_ordinal},
            reason => $_->{outcome},
            measurement_identity => $_->{measurement_identity},
            diagnostic => _clone($_->{diagnostic}),
        }
    } grep { $_->{outcome} ne 'accepted' } @measured;
    _exact_keys($_, \@EXCLUSION_KEYS, 'balanced sample exclusion')
        for @{$report->{sample_exclusions}};
    confess "balanced sample exclusion evidence changed\n"
        unless _canonical_json($report->{sample_exclusions})
            eq _canonical_json(\@expected_exclusions);
    confess "applicable balanced measurement lacks an exclusion\n"
        if $expected_measurement->{applicable}
            && @measured != $SAMPLES && !@expected_exclusions;
    _exact_keys($report->{cleanup}, \@CLEANUP_KEYS,
        'balanced measurement cleanup');
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my $expected_cleanup = {
        records_total => scalar(@records),
        ephemeral_removed => $removed
            ? JSON::PP::true : JSON::PP::false,
        residue => \@residue,
    };
    confess "balanced measurement cleanup evidence changed\n"
        unless _canonical_json($report->{cleanup})
            eq _canonical_json($expected_cleanup);
    confess "balanced measurement nonclaim boundary changed\n"
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
    elsif (@expected_exclusions || @measured != $SAMPLES) {
        $expected_outcome = 'rejected';
        push @expected_diagnostics,
            _clone($expected_exclusions[0]{diagnostic})
            if @expected_exclusions;
    }
    else {
        $expected_outcome = 'accepted';
    }
    confess "balanced measurement report outcome changed\n"
        unless ($report->{outcome} // '') eq $expected_outcome;
    confess "balanced measurement diagnostics changed\n"
        unless _canonical_json($report->{diagnostics})
            eq _canonical_json(\@expected_diagnostics);
    confess "balanced measurement report identity changed\n"
        unless ($report->{report_identity} // '')
            eq _report_identity($report);
    return;
}

sub _validate_record_member_evidence(
    $record, $construction, $composition, $emission,
) {
    my %measurement = map { $_->{stage} => $_ }
        @{$record->{stage_measurements}};
    my %oracle = map { $_->{oracle_id} => $_ }
        @{$record->{correctness_oracles}};
    my @expected_artifacts;
    my $stage_failed = 0;
    for my $stage (@STAGE_ORDER) {
        my $entry = $measurement{$stage};
        confess "balanced record is missing stage '$stage'\n"
            unless defined $entry;
        if ($entry->{status} eq 'not_run') {
            confess "planned balanced stage was skipped before failure\n"
                unless $stage_failed
                    && $entry->{not_run_reason} eq 'prior_stage_failed';
            next;
        }
        confess "balanced stage executed after failure\n" if $stage_failed;
        my $expected_command = {
            logical_name => "vial_scale_balanced_portable_$stage",
            arguments => [
                $FAMILY, $BACKEND_PROFILE, $LEVEL, $PRIMARY_AXIS,
            ],
            thread_count => 1,
            job_count => 1,
        };
        confess "balanced stage command identity changed\n"
            unless _canonical_json($entry->{command_identity})
                eq _canonical_json($expected_command);
        my $expected_input = $stage eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json(
                    $construction->{workload}{specification},
                )),
                objects => 1,
            }
            : _source_counts($construction);
        confess "balanced stage input counts changed\n"
            unless _canonical_json($entry->{input_counts})
                eq _canonical_json($expected_input);
        if ($entry->{status} eq 'validation_rejected'
                || $entry->{status} eq 'measured_rejected') {
            confess "rejected balanced stage conflicts with accepted record\n"
                if $record->{outcome} eq 'accepted';
            confess "rejected balanced stage retained output evidence\n"
                unless _canonical_json($entry->{output_counts})
                        eq _canonical_json({
                            files => 0, lines => 0,
                            bytes => 0, objects => 0,
                        })
                    && _canonical_json($entry->{semantic_object_counts})
                        eq '{}'
                    && @{$entry->{correctness_oracle_ids}} == 0
                    && !grep { $_->{stage} eq $stage }
                        @{$record->{artifacts}{records}};
            $stage_failed = 1;
            next;
        }
        confess "balanced stage has a non-success status\n"
            unless $entry->{status} eq 'validated_unmeasured'
                || $entry->{status} eq 'measured';
        my $payload = _expected_stage_payload(
            $construction, $composition, $emission, $stage,
        );
        my $materialized = _materialized_projection($stage, $payload);
        confess "balanced stage output counts changed\n"
            unless _canonical_json($entry->{output_counts})
                eq _canonical_json($materialized->{output_counts});
        confess "balanced stage semantic counts changed\n"
            unless _canonical_json($entry->{semantic_object_counts})
                eq _canonical_json($payload->{semantic_counts});
        my $owned = $oracle{$payload->{oracle_id}};
        confess "balanced stage oracle is missing\n"
            unless defined($owned) && $owned->{stage} eq $stage
                && $owned->{ok};
        confess "balanced stage oracle evidence changed\n"
            unless _canonical_json($owned->{evidence})
                eq _canonical_json($payload->{evidence});
        push @expected_artifacts, @{$materialized->{artifact_records}};
    }
    my %owned = map { $_ => 1 } @STAGE_ORDER;
    for my $stage (@{$record->{stage_measurements}}) {
        next if $owned{$stage->{stage}} || $stage->{stage} eq 'cleanup';
        confess "non-structural balanced stage executed\n"
            unless $stage->{status} eq 'not_run';
        my $reason = $stage_failed
            ? 'prior_stage_failed' : 'not_applicable_to_invocation';
        confess "non-structural balanced stage reason changed\n"
            unless ($stage->{not_run_reason} // '') eq $reason;
    }
    confess "accepted balanced record contains a failed stage\n"
        if $record->{outcome} eq 'accepted' && $stage_failed;
    confess "balanced artifact evidence changed\n"
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

sub _canonical_bundle($repo_root) {
    my $construction = _canonical_construction($repo_root);
    my $composition = $PRODUCER->evaluate({construction => $construction});
    confess "canonical balanced composition failed its oracle\n"
        unless $composition->{ok};
    confess "canonical balanced composition schema changed\n"
        unless ($composition->{schema} // '') eq $COMPOSITION_SCHEMA
            && ($composition->{schema_version} // -1) == 1;
    my $emission = $EMITTER->evaluate({construction => $construction});
    confess "canonical balanced emission failed its oracle\n"
        unless $emission->{ok};
    confess "canonical balanced emission schema changed\n"
        unless ($emission->{schema} // '') eq $EMISSION_SCHEMA
            && ($emission->{schema_version} // -1) == 1;
    confess "balanced composition and emission workload identities differ\n"
        unless $composition->{workload_identity}
            eq $construction->{workload}{workload_identity}
            && $emission->{workload_identity}
                eq $construction->{workload}{workload_identity};
    confess "balanced emission does not retain the composition authority\n"
        unless $emission->{composition_report_identity}
            eq $composition->{report_identity};
    return (
        _clone($construction), _clone($composition), _clone($emission),
    );
}

sub _canonical_construction($repo_root) {
    my $hial = _slurp_repository_file($repo_root, $HIAL_ANCHOR);
    my $vial = _slurp_repository_file($repo_root, $VIAL_ANCHOR);
    my $first = $PRODUCER->construct({
        reference_hial_text => $hial,
        reference_vial_text => $vial,
    });
    my $second = $PRODUCER->construct({
        reference_hial_text => $hial,
        reference_vial_text => $vial,
    });
    confess "canonical balanced construction is nondeterministic\n"
        unless _canonical_json($second) eq _canonical_json($first);
    confess "canonical balanced construction failed\n" unless $first->{ok};
    my $specification = $first->{workload}{specification};
    confess "canonical balanced construction shape changed\n"
        unless ($specification->{family} // '') eq $FAMILY
            && ($specification->{backend_profile} // '') eq $BACKEND_PROFILE
            && ($specification->{level} // '') eq $LEVEL
            && ($specification->{primary_axis} // '') eq $PRIMARY_AXIS
            && !defined($specification->{tool_profile});
    return _clone($first);
}

sub _construction_projection($construction) {
    my $workload = $construction->{workload};
    return {
        schema => $construction->{schema},
        schema_version => $construction->{schema_version},
        status => $construction->{status},
        workload_identity => $workload->{workload_identity},
        construction_sha256 => sha256_hex(_canonical_json($construction)),
        specification => _clone($workload->{specification}),
        input_identities => _clone($workload->{input_identities}),
        reference_source_identities => {
            hial => _source_identity($construction->{reference_sources}{hial}),
            vial => _source_identity($construction->{reference_sources}{vial}),
        },
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
    confess "balanced measurement evidence contains a non-JSON reference\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    confess "balanced measurement evidence aliases path and semantic_path\n"
        if exists($value->{path}) && exists($value->{semantic_path});
    my %projection;
    for my $key (sort keys %$value) {
        my $projected = $key eq 'path' ? 'semantic_path' : $key;
        confess "balanced evidence projection collides at '$projected'\n"
            if exists $projection{$projected};
        $projection{$projected} =
            _measurement_evidence_projection($value->{$key});
    }
    return \%projection;
}

sub _authority() {
    my @balanced = grep { $_->{family} eq $FAMILY }
        @{$OWNERSHIP->owned_shapes};
    confess "balanced measurement ownership partition changed\n"
        unless @balanced == 1
            && ($balanced[0]{backend_profile} // '') eq $BACKEND_PROFILE
            && ($balanced[0]{level} // '') eq $LEVEL;
    my $authority = {
        family => $FAMILY,
        backend_profile => $BACKEND_PROFILE,
        level => $LEVEL,
        primary_axis => $PRIMARY_AXIS,
        producer_class => $PRODUCER,
        emitter_class => $EMITTER,
        stage_order => [@STAGE_ORDER],
        workload_schema => $WORKLOAD_SCHEMA,
        composition_schema => $COMPOSITION_SCHEMA,
        emission_schema => $EMISSION_SCHEMA,
        structural_emission_only => JSON::PP::true,
        private_revision_2 => JSON::PP::true,
        external_execution_applicable => JSON::PP::false,
        authority_identity => undef,
    };
    my %identity = %$authority;
    delete $identity{authority_identity};
    $authority->{authority_identity} =
        'balanced-portable-measurement-authority/'
        . sha256_hex(_canonical_json(\%identity));
    return $authority;
}

sub _source_counts($construction) {
    my $inputs = $construction->{workload}{inputs};
    my $counts = {
        files => scalar(@$inputs), lines => 0, bytes => 0,
        objects => scalar(@$inputs),
    };
    for my $input (@$inputs) {
        $counts->{lines} += _line_count($input->{content});
        $counts->{bytes} += bytes::length($input->{content});
    }
    return $counts;
}

sub _source_identity($source) {
    return {
        relative_path => $source->{relative_path},
        bytes => bytes::length($source->{content}),
        sha256 => sha256_hex($source->{content}),
    };
}

sub _role_input($workload, $role) {
    my @selected = grep { $_->{role} eq $role } @{$workload->{inputs}};
    confess "balanced workload role '$role' is not unique\n"
        unless @selected == 1;
    return $selected[0];
}

sub _report_identity($report) {
    my %identity = %$report;
    delete $identity{report_identity};
    return 'balanced-portable-measurement/'
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
    confess "balanced measurement anchor is not one regular repository file\n"
        unless -f $path && !-l $path;
    open my $fh, '<:raw', $path
        or confess "cannot read balanced measurement anchor\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close balanced measurement anchor\n";
    return $content;
}

sub _require_active_guard() {
    confess "balanced measurement requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "active balanced guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _validate_applicability($value, $label) {
    _exact_keys($value, \@APPLICABILITY_KEYS, $label);
    _validate_boolean($value->{applicable}, "$label applicable");
    confess "$label reason is invalid\n"
        if defined($value->{reason}) && !_safe_token($value->{reason});
}

sub _line_count($content) {
    return 0 unless bytes::length($content);
    my $count = () = $content =~ /\n/g;
    $count++ unless $content =~ /\n\z/;
    return $count;
}

sub _safe_relative_path($value) {
    confess "balanced measurement path must be repository-relative\n"
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
