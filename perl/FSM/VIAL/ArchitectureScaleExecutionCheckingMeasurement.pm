package FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement;

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

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::Parser;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_execution_checking_measurement_set.v1';
my $WORKLOAD_SCHEMA = 'fsmgen.vial_architecture_scale_workload.v1';
my @REPORT_KEYS = qw(
    schema schema_version report_identity family level primary_axis
    workload_identity mode requested_counts family_authority
    controller_applicability measurement_applicability canonical_evaluation
    validation_record measurement_records sample_exclusions outcome
    diagnostics cleanup explicit_nonclaims
);
my @AUTHORITY_KEYS = qw(
    family producer_class stage_order workload_schema evaluation_schema
    external_verification_tool authority_identity
);
my @APPLICABILITY_KEYS = qw(applicable reason);
my @EXCLUSION_KEYS = qw(
    run_ordinal reason measurement_identity diagnostic
);
my @CLEANUP_KEYS = qw(records_total ephemeral_removed residue);
my @NONCLAIMS = (
    @{FSM::VIAL::ArchitectureScaleMeasurement->explicit_nonclaims},
    qw(
        external_verification_tool backend_emission_measurement
        compile_run_trace_result family_performance_budget family_support
        family_capacity reached_boundary public_api_change
    ),
);
my %FAMILY = (
    execution_graph_v1 => {
        producer_class => 'FSM::VIAL::ArchitectureScaleExecutionGraph',
        stage_order => [qw(construct parse_validate bridge bind_plan)],
        evaluation_schema =>
            'fsmgen.vial_architecture_scale_execution_evaluation.v1',
    },
    checking_state_v1 => {
        producer_class => 'FSM::VIAL::ArchitectureScaleCheckingState',
        stage_order => [qw(construct parse_validate bridge bind_plan)],
        evaluation_schema =>
            'fsmgen.vial_architecture_scale_checking_evaluation.v1',
    },
);
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

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub family_authorities($class) {
    _exact_invocant($class, 'family_authorities');
    return {map { $_ => _authority($_) } sort keys %FAMILY};
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $request = _request(
        'construct', \@args,
        [qw(repository_root family level primary_axis)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    return _clone(_canonical_construction(
        $repo_root, @{$request}{qw(family level primary_axis)},
    ));
}

sub validate_profile($class, @args) {
    _exact_invocant($class, 'validate_profile');
    my $request = _request(
        'validate_profile', \@args,
        [qw(repository_root family level primary_axis)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $evaluation) = _canonical_family_pair(
        $repo_root, @{$request}{qw(family level primary_axis)},
    );
    my $validation = $construction->{ok}
        ? _run_record({
            repository_root => $repo_root,
            construction => $construction,
            evaluation => $evaluation,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
        })
        : undef;
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
        [qw(repository_root family level primary_axis)],
    );
    my $mode = $LEVEL_MODE{$request->{level}};
    confess "only gate_candidate_v1 and qualification_candidate_v1 are measured\n"
        unless defined $mode;
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $evaluation) = _canonical_family_pair(
        $repo_root, @{$request}{qw(family level primary_axis)},
    );
    my $validation = $construction->{ok}
        ? _run_record({
            repository_root => $repo_root,
            construction => $construction,
            evaluation => $evaluation,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
        })
        : undef;
    my @measured;
    if (defined($validation)
            && $validation->{outcome} eq 'accepted'
            && $evaluation->{status} eq 'accepted') {
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
    my ($family, $level, $axis) =
        @{$spec}{qw(family level primary_axis)};
    my $source_counts = _source_counts($construction);
    my @selected = @{_planned_stages($construction, $evaluation)};
    my @plan;
    for my $stage (@selected) {
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
                logical_name => join('_',
                    'vial_scale', $family, $stage,
                ),
                arguments => [$family, $level, $axis],
                thread_count => 1,
                job_count => 1,
            },
            input_counts => $input_counts,
            backend_timeout_seconds => undef,
            worker => sub {
                my ($context) = @_;
                my $stage_construction = $stage eq 'construct'
                    ? _canonical_construction(
                        $repo_root, $family, $level, $axis,
                    )
                    : _clone($construction);
                confess "family construction identity changed in '$stage'\n"
                    unless _canonical_json($stage_construction)
                        eq _canonical_json($construction);
                my $first = _stage_payload(
                    $stage_construction, $evaluation, $stage,
                );
                my $second = _stage_payload(
                    $stage_construction, $evaluation, $stage,
                );
                confess "family stage '$stage' is nondeterministic\n"
                    unless _canonical_json($second)
                        eq _canonical_json($first);
                return _materialize_payload($context, $first);
            },
        };
    }
    return \@plan;
}

sub _planned_stages($construction, $evaluation) {
    return [] unless $construction->{ok};
    return [qw(construct bind_plan)]
        if $evaluation->{status} eq 'preflight_dominated';
    my $terminal = _terminal_stage($evaluation);
    return [qw(construct parse_validate)]
        if $terminal eq 'parse_validate';
    return [qw(construct parse_validate bridge)]
        if $terminal eq 'bridge';
    return [qw(construct parse_validate bridge bind_plan)];
}

sub _terminal_stage($evaluation) {
    return 'none' if $evaluation->{status} eq 'envelope_unconstructible';
    return 'bind_plan' if $evaluation->{status} eq 'accepted'
        || $evaluation->{status} eq 'preflight_dominated';
    confess "canonical family outcome is not measurement-admissible\n"
        unless $evaluation->{status} eq 'expected_rejection';
    my $diagnostics = $evaluation->{diagnostics};
    confess "expected family rejection has no diagnostic\n"
        unless ref($diagnostics) eq 'ARRAY' && @$diagnostics;
    my $code = $diagnostics->[0]{code} // '';
    return 'parse_validate' if $code eq 'VIAL_LIMIT_ERROR'
        || $code eq 'VIAL_PARSE_ERROR'
        || $code eq 'VIAL_SEMANTIC_ERROR';
    return 'bridge' if $code =~ /\AHIAL_VIAL_BRIDGE_/;
    return 'bind_plan' if $code =~ /\AVIAL_(?:EXECUTION|RANDOM)_/;
    confess "expected family rejection has no selected terminal stage\n";
}

sub _stage_payload($construction, $evaluation, $stage) {
    my $family = $construction->{specification}{family};
    if ($stage eq 'construct') {
        my $projection = _construction_projection($construction);
        my @artifacts = ({
            suffix => 'construction.json',
            kind => 'family_construction_manifest',
            content => _canonical_json($projection) . "\n",
        });
        for my $input (@{$construction->{inputs}}) {
            my $relative = _safe_relative_path($input->{relative_path});
            push @artifacts, {
                suffix => "sources/$relative",
                kind => $input->{role},
                content => $input->{content},
            };
        }
        return {
            status => "${family}_construct_completed",
            oracle_id => "${family}_construct_canonical",
            evidence => $projection,
            semantic_counts => {
                constructed_inputs => scalar(@{$construction->{inputs}}),
                construction_identity_records => 1,
            },
            artifacts => \@artifacts,
        };
    }
    return _parse_payload($construction, $evaluation)
        if $stage eq 'parse_validate';
    return _bridge_payload($construction, $evaluation)
        if $stage eq 'bridge';
    return _bind_plan_payload($construction, $evaluation)
        if $stage eq 'bind_plan';
    confess "family stage '$family/$stage' is not owned\n";
}

sub _parse_payload($construction, $evaluation) {
    my $family = $construction->{specification}{family};
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$construction->{inputs}};
    confess "canonical family workload has no VIAL input\n"
        unless defined $vial;
    my $checked = FSM::VIAL::Parser->check_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $terminal = _terminal_stage($evaluation);
    if ($terminal eq 'parse_validate') {
        confess "canonical parse rejection was unexpectedly accepted\n"
            if $checked->{ok};
        confess "canonical parse diagnostic changed from family authority\n"
            unless _canonical_json(
                _measurement_evidence_projection($checked->{diagnostics}),
            ) eq _canonical_json(
                _measurement_evidence_projection($evaluation->{diagnostics}),
            );
    }
    else {
        confess "canonical parse/validation stage rejected unexpectedly\n"
            unless $checked->{ok};
    }
    my $projection = {
        family => $family,
        level => $construction->{specification}{level},
        primary_axis => $construction->{specification}{primary_axis},
        workload_identity => $construction->{workload_identity},
        status => $checked->{ok} ? 'accepted' : 'expected_rejection',
        semantic_report_sha256 =>
            sha256_hex(_canonical_json($checked->{semantic_report})),
        diagnostics =>
            _measurement_evidence_projection($checked->{diagnostics}),
        vial_input_identity => _clone($vial->{content_identity}),
    };
    return {
        status => join('_', $family, 'parse_validate', $projection->{status}),
        oracle_id => "${family}_parse_validate_canonical",
        evidence => $projection,
        semantic_counts => {
            parsed_vial_nodes =>
                _json_node_count($checked->{semantic_report}),
            parse_diagnostics => scalar(@{$checked->{diagnostics}}),
        },
        artifacts => [{
            suffix => 'parse-validation.json',
            kind => 'family_parse_validation',
            content => _canonical_json($projection) . "\n",
        }],
    };
}

sub _bridge_payload($construction, $evaluation) {
    my $family = $construction->{specification}{family};
    my $producer = $FAMILY{$family}{producer_class};
    my $inputs = $producer->_measurement_inputs({
        construction => $construction,
    });
    my $terminal = _terminal_stage($evaluation);
    if ($terminal eq 'bridge') {
        confess "canonical bridge rejection was unexpectedly accepted\n"
            unless ref($inputs->{bridge_rejection}) eq 'ARRAY';
        confess "canonical bridge diagnostic changed from family authority\n"
            unless _canonical_json(
                _measurement_evidence_projection($inputs->{bridge_rejection}),
            ) eq _canonical_json(
                _measurement_evidence_projection($evaluation->{diagnostics}),
            );
        my $projection = {
            family => $family,
            level => $construction->{specification}{level},
            primary_axis => $construction->{specification}{primary_axis},
            workload_identity => $construction->{workload_identity},
            status => 'expected_rejection',
            semantic_ir_sha256 => _semantic_identity($inputs->{semantic_ir}),
            bridge_manifest_sha256 => undef,
            diagnostics => _measurement_evidence_projection(
                $inputs->{bridge_rejection},
            ),
        };
        return {
            status => "${family}_bridge_expected_rejection",
            oracle_id => "${family}_bridge_canonical",
            evidence => $projection,
            semantic_counts => {
                bridge_manifest_nodes => 0,
                bridge_diagnostics => scalar(@{$inputs->{bridge_rejection}}),
            },
            artifacts => [{
                suffix => 'bridge-validation.json',
                kind => 'family_bridge_validation',
                content => _canonical_json($projection) . "\n",
            }],
        };
    }
    confess "canonical bridge stage did not produce SemanticIR and manifest\n"
        unless defined($inputs->{semantic_ir})
            && defined($inputs->{bridge_manifest});
    my $semantic_sha = _semantic_identity($inputs->{semantic_ir});
    my $manifest = $inputs->{bridge_manifest}->as_hashref;
    my $manifest_sha = sha256_hex(_canonical_json($manifest));
    my $expected_semantic = _evaluation_stage_identity(
        $evaluation, 'semantic_ir_sha256',
    );
    my $expected_bridge = _evaluation_stage_identity(
        $evaluation, 'bridge_manifest_sha256',
    );
    confess "canonical semantic identity changed before bridge measurement\n"
        if defined($expected_semantic) && $semantic_sha ne $expected_semantic;
    confess "canonical bridge identity changed before bind/plan measurement\n"
        if defined($expected_bridge) && $manifest_sha ne $expected_bridge;
    my $projection = {
        family => $family,
        level => $construction->{specification}{level},
        primary_axis => $construction->{specification}{primary_axis},
        workload_identity => $construction->{workload_identity},
        status => 'accepted',
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $manifest_sha,
        manifest_id => $manifest->{manifest_id},
        diagnostics => [],
    };
    return {
        status => "${family}_bridge_accepted",
        oracle_id => "${family}_bridge_canonical",
        evidence => $projection,
        semantic_counts => {
            bridge_manifest_nodes => _json_node_count($manifest),
            bridge_diagnostics => 0,
        },
        artifacts => [{
            suffix => 'bridge-validation.json',
            kind => 'family_bridge_validation',
            content => _canonical_json($projection) . "\n",
        }],
    };
}

sub _bind_plan_payload($construction, $expected) {
    my $family = $construction->{specification}{family};
    # The stage worker invokes every payload twice and compares the complete
    # results.  One validated producer evaluation per invocation therefore
    # supplies the two independent bind/plan reruns; nesting the admission
    # helper here would multiply each invocation by another canonical pair.
    my $evaluation = _validated_evaluation_once($family, $construction);
    confess "canonical bind/plan evaluation changed from admission evidence\n"
        unless _canonical_json($evaluation) eq _canonical_json($expected);
    my %counts;
    for my $key (sort keys %{$evaluation->{metrics}}) {
        my $value = $evaluation->{metrics}{$key};
        next unless defined($value) && !ref($value)
            && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
        my $safe = $key;
        $safe =~ s/[^A-Za-z0-9_]/_/g;
        $counts{"${family}_$safe"} = 0 + $value;
    }
    $counts{"${family}_evaluation_records"} = 1;
    return {
        status => join('_', $family, 'bind_plan', $evaluation->{status}),
        oracle_id => "${family}_bind_plan_canonical",
        evidence => _measurement_evidence_projection($evaluation),
        semantic_counts => \%counts,
        artifacts => [{
            suffix => 'bind-plan-evaluation.json',
            kind => 'family_bind_plan_evaluation',
            content => _canonical_json($evaluation) . "\n",
        }],
    };
}

sub _materialize_payload($context, $payload) {
    my @records;
    make_path($context->{output_root});
    for my $artifact (@{$payload->{artifacts}}) {
        my $suffix = _safe_relative_path($artifact->{suffix});
        my @parts = split m{/}, $suffix;
        my $path = File::Spec->catfile(
            $context->{output_root}, @parts,
        );
        my @parent = @parts;
        pop @parent;
        make_path(File::Spec->catdir($context->{output_root}, @parent))
            if @parent;
        open my $fh, '>:raw', $path
            or die "cannot create family measurement artifact: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close family measurement artifact: $!\n";
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
        files => scalar(@records),
        lines => 0,
        bytes => 0,
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
    my $controller = $construction->{ok}
        ? {applicable => JSON::PP::true, reason => undef}
        : {applicable => JSON::PP::false, reason => 'source_free_construction'};
    my $applicability = !$controller->{applicable}
        ? {applicable => JSON::PP::false, reason => 'source_free_construction'}
        : $raw->{mode} eq 'validation'
            ? {applicable => JSON::PP::false, reason => 'correctness_only_requested'}
            : $validation->{outcome} ne 'accepted'
                ? {applicable => JSON::PP::false, reason => 'correctness_validation_failed'}
                : $evaluation->{status} ne 'accepted'
                    ? {applicable => JSON::PP::false, reason => 'authoritative_family_outcome'}
                    : {applicable => JSON::PP::true, reason => undef};
    my @exclusions = map {
        {
            run_ordinal => $_->{run_ordinal},
            reason => $_->{outcome},
            measurement_identity => $_->{measurement_identity},
            diagnostic => _clone($_->{diagnostic}),
        }
    } grep { $_->{outcome} ne 'accepted' } @measured;
    my @records = defined($validation) ? ($validation, @measured) : ();
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my ($outcome, @diagnostics);
    if (!$controller->{applicable}) {
        $outcome = $raw->{mode} eq 'validation'
            ? 'accepted_source_free_validation' : 'validated_not_measured';
    }
    elsif ($validation->{outcome} ne 'accepted') {
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
        push @diagnostics,
            _clone($exclusions[0]{diagnostic}) if @exclusions;
    }
    else {
        $outcome = 'accepted';
    }
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        family => $spec->{family},
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        workload_identity => $construction->{workload_identity},
        mode => $raw->{mode},
        requested_counts => _clone($evaluation->{requested_counts}),
        family_authority => _authority($spec->{family}),
        controller_applicability => $controller,
        measurement_applicability => $applicability,
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
    confess "execution/checking measurement report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    _exact_keys($report, \@REPORT_KEYS, 'execution/checking measurement report');
    confess "execution/checking measurement report schema is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1;
    confess "execution/checking measurement family is not selected\n"
        unless defined($report->{family}) && exists $FAMILY{$report->{family}};
    confess "execution/checking measurement mode is invalid\n"
        unless ($report->{mode} // '') eq 'validation'
            || exists $MODE_SAMPLES{$report->{mode}};
    my ($construction, $evaluation) = _canonical_family_pair(
        $repo_root,
        @{$report}{qw(family level primary_axis)},
    );
    confess "execution/checking measurement workload identity changed\n"
        unless _canonical_json($report->{workload_identity})
            eq _canonical_json($construction->{workload_identity});
    confess "execution/checking requested counts changed\n"
        unless _canonical_json($report->{requested_counts})
            eq _canonical_json($evaluation->{requested_counts});
    _exact_keys(
        $report->{family_authority},
        \@AUTHORITY_KEYS, 'execution/checking family authority',
    );
    confess "execution/checking family authority changed\n"
        unless _canonical_json($report->{family_authority})
            eq _canonical_json(_authority($report->{family}));
    _validate_applicability(
        $report->{controller_applicability}, 'controller applicability',
    );
    _validate_applicability(
        $report->{measurement_applicability}, 'measurement applicability',
    );
    confess "canonical execution/checking evaluation changed\n"
        unless _canonical_json($report->{canonical_evaluation})
            eq _canonical_json(
                _measurement_evidence_projection($evaluation),
            );
    confess "execution/checking measurement records must be one array\n"
        unless ref($report->{measurement_records}) eq 'ARRAY';
    confess "execution/checking sample exclusions must be one array\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY';
    confess "execution/checking diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    confess "execution/checking nonclaims must be one array\n"
        unless ref($report->{explicit_nonclaims}) eq 'ARRAY';
    my $expected_controller = $construction->{ok}
        ? {applicable => JSON::PP::true, reason => undef}
        : {applicable => JSON::PP::false, reason => 'source_free_construction'};
    confess "controller applicability changed\n"
        unless _canonical_json($report->{controller_applicability})
            eq _canonical_json($expected_controller);
    my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
    my $validation = $report->{validation_record};
    if ($expected_controller->{applicable}) {
        confess "controller-applicable report has no validation record\n"
            unless ref($validation) eq 'HASH' && !blessed($validation);
        $foundation->validate_record({record => $validation});
    }
    else {
        confess "source-free report invented a controller validation record\n"
            if defined $validation;
    }
    my @measured = @{$report->{measurement_records}};
    $foundation->validate_record({record => $_}) for @measured;
    my @records = defined($validation) ? ($validation, @measured) : ();
    if (defined $validation) {
        confess "execution/checking validation ordinal changed\n"
            unless $validation->{run_class} eq 'validation'
                && $validation->{run_ordinal} == 0;
    }
    for my $record (@records) {
        confess "execution/checking record workload changed\n"
            unless $record->{workload_identity}
                eq $construction->{workload_identity}
            && _canonical_json($record->{workload_specification})
                eq _canonical_json($construction->{specification});
        _validate_record_family_evidence(
            $record, $construction, $evaluation,
        );
    }
    if ($report->{mode} eq 'validation') {
        confess "validation-only report retained measured samples\n"
            if @measured;
    }
    else {
        my $expected_class = $MODE_CLASS{$report->{mode}};
        for my $index (0 .. $#measured) {
            confess "measured sample ordinal or class changed\n"
                unless $measured[$index]{run_class} eq $expected_class
                    && $measured[$index]{run_ordinal} == $index + 1;
        }
    }
    my $expected_applicability = !$expected_controller->{applicable}
        ? {applicable => JSON::PP::false, reason => 'source_free_construction'}
        : $report->{mode} eq 'validation'
            ? {applicable => JSON::PP::false, reason => 'correctness_only_requested'}
            : $validation->{outcome} ne 'accepted'
                ? {applicable => JSON::PP::false, reason => 'correctness_validation_failed'}
                : $evaluation->{status} ne 'accepted'
                    ? {applicable => JSON::PP::false, reason => 'authoritative_family_outcome'}
                    : {applicable => JSON::PP::true, reason => undef};
    confess "measurement applicability changed\n"
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
        $_, \@EXCLUSION_KEYS, 'execution/checking sample exclusion',
    ) for @{$report->{sample_exclusions}};
    confess "sample exclusion evidence changed\n"
        unless _canonical_json($report->{sample_exclusions})
            eq _canonical_json(\@expected_exclusions);
    confess "applicable measurement ended without a recorded exclusion\n"
        if $expected_applicability->{applicable}
            && @measured != $MODE_SAMPLES{$report->{mode}}
            && !@expected_exclusions;
    _exact_keys($report->{cleanup}, \@CLEANUP_KEYS, 'measurement cleanup');
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my $expected_cleanup = {
        records_total => scalar(@records),
        ephemeral_removed => $removed
            ? JSON::PP::true : JSON::PP::false,
        residue => \@residue,
    };
    confess "aggregate cleanup evidence changed\n"
        unless _canonical_json($report->{cleanup})
            eq _canonical_json($expected_cleanup);
    confess "execution/checking nonclaim boundary changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    my ($expected_outcome, @expected_diagnostics);
    if (!$expected_controller->{applicable}) {
        $expected_outcome = $report->{mode} eq 'validation'
            ? 'accepted_source_free_validation' : 'validated_not_measured';
    }
    elsif ($validation->{outcome} ne 'accepted') {
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
    confess "execution/checking report outcome changed\n"
        unless ($report->{outcome} // '') eq $expected_outcome;
    confess "execution/checking report diagnostics changed\n"
        unless _canonical_json($report->{diagnostics})
            eq _canonical_json(\@expected_diagnostics);
    confess "execution/checking report identity changed\n"
        unless ($report->{report_identity} // '')
            eq _report_identity($report);
    return;
}

sub _validate_record_family_evidence($record, $construction, $evaluation) {
    my $family = $construction->{specification}{family};
    my %planned = map { $_ => 1 }
        @{_planned_stages($construction, $evaluation)};
    my %measurement = map { $_->{stage} => $_ }
        @{$record->{stage_measurements}};
    my %oracle = map { $_->{oracle_id} => $_ }
        @{$record->{correctness_oracles}};
    my @expected_artifacts;
    my $family_stage_failed = 0;
    for my $stage (@{$FAMILY{$family}{stage_order}}) {
        my $entry = $measurement{$stage};
        confess "family record is missing stage '$stage'\n"
            unless defined $entry;
        if (!$planned{$stage}) {
            confess "inapplicable family stage '$stage' executed\n"
                unless $entry->{status} eq 'not_run';
            my $expected_reason = $family_stage_failed
                ? 'prior_stage_failed' : 'not_applicable_to_invocation';
            confess "inapplicable family stage '$stage' reason changed\n"
                unless $entry->{not_run_reason} eq $expected_reason;
            next;
        }
        if ($entry->{status} eq 'not_run') {
            confess "planned family stage '$stage' was skipped before failure\n"
                unless $family_stage_failed
                    && $entry->{not_run_reason} eq 'prior_stage_failed';
            next;
        }
        confess "family stage '$stage' executed after a family failure\n"
            if $family_stage_failed;
        my $expected_command = {
            logical_name => join('_', 'vial_scale', $family, $stage),
            arguments => [
                $family,
                $construction->{specification}{level},
                $construction->{specification}{primary_axis},
            ],
            thread_count => 1,
            job_count => 1,
        };
        confess "family stage '$stage' command identity changed\n"
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
        confess "family stage '$stage' input counts changed\n"
            unless _canonical_json($entry->{input_counts})
                eq _canonical_json($expected_input);
        if ($entry->{status} eq 'validation_rejected'
                || $entry->{status} eq 'measured_rejected') {
            confess "rejected family stage '$stage' conflicts with an accepted record\n"
                if $record->{outcome} eq 'accepted';
            confess "rejected family stage '$stage' retained output evidence\n"
                unless _canonical_json($entry->{output_counts})
                    eq _canonical_json({
                        files => 0, lines => 0, bytes => 0, objects => 0,
                    })
                    && _canonical_json($entry->{semantic_object_counts}) eq '{}'
                    && @{$entry->{correctness_oracle_ids}} == 0
                    && !grep { $_->{stage} eq $stage }
                        @{$record->{artifacts}{records}};
            $family_stage_failed = 1;
            next;
        }
        confess "family stage '$stage' has a non-success status\n"
            unless $entry->{status} eq 'validated_unmeasured'
                || $entry->{status} eq 'measured';
        my $payload = _stage_payload($construction, $evaluation, $stage);
        my $materialized = _materialized_projection($stage, $payload);
        confess "family stage '$stage' output counts changed\n"
            unless _canonical_json($entry->{output_counts})
                eq _canonical_json($materialized->{output_counts});
        confess "family stage '$stage' semantic counts changed\n"
            unless _canonical_json($entry->{semantic_object_counts})
                eq _canonical_json($payload->{semantic_counts});
        my $owned_oracle = $oracle{$payload->{oracle_id}};
        confess "family stage '$stage' oracle is missing\n"
            unless defined($owned_oracle)
                && $owned_oracle->{stage} eq $stage
                && $owned_oracle->{ok};
        confess "family stage '$stage' oracle evidence changed\n"
            unless _canonical_json($owned_oracle->{evidence})
                eq _canonical_json($payload->{evidence});
        push @expected_artifacts, @{$materialized->{artifact_records}};
    }
    confess "accepted family record contains a failed family stage\n"
        if $record->{outcome} eq 'accepted' && $family_stage_failed;
    confess "family artifact evidence changed\n"
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
        files => scalar(@records),
        lines => 0,
        bytes => 0,
        objects => scalar(@records),
    };
    for my $record (@records) {
        $counts->{lines} += $record->{lines};
        $counts->{bytes} += $record->{bytes};
    }
    return {output_counts => $counts, artifact_records => \@records};
}

sub _canonical_family_pair($repo_root, $family, $level, $axis) {
    my $construction = _canonical_construction(
        $repo_root, $family, $level, $axis,
    );
    my $evaluation = _canonical_evaluation($family, $construction);
    confess "canonical family/evaluation identity is inconsistent\n"
        unless _canonical_json($evaluation->{workload_identity})
            eq _canonical_json($construction->{workload_identity});
    return (_clone($construction), _clone($evaluation));
}

sub _canonical_construction($repo_root, $family, $level, $axis) {
    _validate_family_axis_level($family, $level, $axis);
    my $first = _construct_once($repo_root, $family, $level, $axis);
    my $second = _construct_once($repo_root, $family, $level, $axis);
    confess "canonical family construction is nondeterministic\n"
        unless _canonical_json($first) eq _canonical_json($second);
    confess "canonical family construction returned an invalid outcome\n"
        unless $first->{ok}
            || (($first->{status} // '') eq 'error'
                && !defined($first->{workload_identity})
                && @{$first->{inputs}} == 0);
    return _clone($first);
}

sub _canonical_evaluation($family, $construction) {
    my $first = _validated_evaluation_once($family, $construction);
    my $second = _validated_evaluation_once($family, $construction);
    confess "canonical family evaluation is nondeterministic\n"
        unless _canonical_json($first) eq _canonical_json($second);
    return _clone($first);
}

sub _validated_evaluation_once($family, $construction) {
    my $producer = $FAMILY{$family}{producer_class};
    my $evaluation = $producer->evaluate({construction => $construction});
    confess "canonical family evaluation did not satisfy its oracle\n"
        unless $evaluation->{ok};
    confess "canonical family evaluation schema changed\n"
        unless ($evaluation->{schema} // '')
                eq $FAMILY{$family}{evaluation_schema}
            && ($evaluation->{schema_version} // -1) == 1;
    return _clone($evaluation);
}

sub _construct_once($repo_root, $family, $level, $axis) {
    my $producer = $FAMILY{$family}{producer_class};
    if ($family eq 'execution_graph_v1') {
        my %request = (primary_axis => $axis, level => $level);
        $request{reference_hial_text} = _slurp_repository_file(
            $repo_root, 'ppif/ahb_lite_subordinate.ppif',
        ) unless $axis eq 'bindings' || $axis eq 'execution_types';
        return $producer->construct(\%request);
    }
    return $producer->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => _slurp_repository_file(
            $repo_root, 'ppif/ahb_lite_subordinate.ppif',
        ),
    });
}

sub _validate_family_axis_level($family, $level, $axis) {
    confess "execution/checking family is not selected\n"
        unless defined($family) && !ref($family) && exists $FAMILY{$family};
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $axes = $catalog->{families}{$family}{axes};
    confess "execution/checking primary axis is not selected\n"
        unless defined($axis) && !ref($axis) && exists $axes->{$axis};
    confess "execution/checking level is not selected\n"
        unless defined($level) && !ref($level)
            && exists $axes->{$axis}{levels}{$level};
    my $producer = $FAMILY{$family}{producer_class};
    my %owned = map {
        ("$_->{primary_axis}/$_->{level}" => 1)
    } @{$producer->owned_shapes};
    confess "execution/checking shape is not owned by its canonical producer\n"
        unless $owned{"$axis/$level"};
}

sub _construction_projection($construction) {
    return {
        schema => $construction->{schema},
        schema_version => $construction->{schema_version},
        family => $construction->{specification}{family},
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
    if (ref($value) eq 'ARRAY') {
        return [map { _measurement_evidence_projection($_) } @$value];
    }
    confess "family evaluation evidence contains a non-JSON reference\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    confess "family evaluation evidence aliases path and semantic_path\n"
        if exists($value->{path}) && exists($value->{semantic_path});
    my %projection;
    for my $key (sort keys %$value) {
        my $projected_key = $key eq 'path' ? 'semantic_path' : $key;
        confess "family evaluation evidence projection collides at '$projected_key'\n"
            if exists $projection{$projected_key};
        $projection{$projected_key} =
            _measurement_evidence_projection($value->{$key});
    }
    return \%projection;
}

sub _evaluation_stage_identity($evaluation, $key) {
    return $evaluation->{$key}
        if exists $evaluation->{$key};
    return $evaluation->{stage_identities}{$key}
        if ref($evaluation->{stage_identities}) eq 'HASH';
    return undef;
}

sub _semantic_identity($semantic_ir) {
    return undef unless defined $semantic_ir;
    return sha256_hex(_canonical_json($semantic_ir->as_hashref));
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

sub _authority($family) {
    confess "family authority is unavailable\n" unless exists $FAMILY{$family};
    my $authority = {
        family => $family,
        producer_class => $FAMILY{$family}{producer_class},
        stage_order => [@{$FAMILY{$family}{stage_order}}],
        workload_schema => $WORKLOAD_SCHEMA,
        evaluation_schema => $FAMILY{$family}{evaluation_schema},
        external_verification_tool => JSON::PP::false,
        authority_identity => undef,
    };
    my %identity = %$authority;
    delete $identity{authority_identity};
    $authority->{authority_identity} =
        'family-authority/' . sha256_hex(_canonical_json(\%identity));
    return $authority;
}

sub _report_identity($report) {
    my %identity = %$report;
    delete $identity{report_identity};
    return 'execution-checking-measurement/'
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
    confess "checked family anchor is not one regular repository file\n"
        unless -f $path && !-l $path;
    open my $fh, '<:raw', $path
        or confess "cannot read checked family anchor\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close checked family anchor\n";
    return $content;
}

sub _require_active_guard() {
    confess "execution/checking measurement requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "active execution/checking guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
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
    confess "family artifact path must be repository-relative\n"
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
