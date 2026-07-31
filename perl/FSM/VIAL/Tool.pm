package FSM::VIAL::Tool;

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::SourceProjection;

our @EXPORT_OK = qw(
    execute_vial_tool_request
    vial_tool_capabilities
);

my @RESULT_KEYS = qw(
    schema schema_version action success status source_identities source_style
    semantic_report formatted_source bridge_manifest plan tool_manifest
    verification_output_manifest result_manifest artifacts capability_evidence
    support_accounting diagnostics implementation
);

my @OPTION_KEYS = qw(
    source_style output_style fixture_id scenario_ids execution_profile
    backend_profile replay_manifest native_extension_catalogs artifact_policy quiet
);

sub vial_tool_capabilities {
    die "vial_tool_capabilities accepts no arguments\n" if @_;
    return _clone(build_vial_tooling_contract());
}

sub execute_vial_tool_request {
    my ($request, $environment, @extra) = @_;
    my $action = ref($request) eq 'HASH' && !blessed($request)
        && defined($request->{action}) && !ref($request->{action})
        ? $request->{action}
        : 'unknown';
    return _error_result($action, _invocation_diagnostic('execute accepts a request and optional environment only'))
        if @extra;

    my $validated = eval { _validate_invocation($request, $environment); };
    if (!$validated) {
        my $message = _sanitize_exception($@);
        return _error_result($action, _invocation_diagnostic($message));
    }

    $action = $validated->{request}{action};
    return _capabilities_result() if $action eq 'capabilities';
    if ($action eq 'plan' || $action eq 'run') {
        my $result = eval { _execute_plan_action($validated); };
        return $result if defined $result;
        return _error_result($action, _host_diagnostic(_sanitize_exception($@)));
    }
    return _error_result(
        $action,
        _invocation_diagnostic("action '$action' is not available in the public source-tooling slice"),
    ) unless $action eq 'check' || $action eq 'format';

    my $result = eval { _execute_source_action($validated); };
    return $result if defined $result;
    return _error_result($action, _host_diagnostic(_sanitize_exception($@)));
}

sub _cli_error_result {
    my ($class, $action, $code, $message) = @_;
    die "VIAL CLI error construction is private to FSM::VIAL::ToolCLI\n"
        unless caller eq 'FSM::VIAL::ToolCLI';
    my %allowed = map { $_ => 1 } qw(VIAL_TOOL_INVOCATION_ERROR VIAL_HOST_ERROR);
    die "unsupported VIAL CLI diagnostic code\n" unless $allowed{$code};
    return _error_result($action, _diagnostic($code, $message, [], '/'));
}

sub _cli_artifact_error_result {
    my ($class, $action, $diagnostics) = @_;
    die "VIAL artifact error construction is private to FSM::VIAL::ToolCLI\n"
        unless caller eq 'FSM::VIAL::ToolCLI';
    die "artifact action must be plan or run\n"
        unless defined($action) && !ref($action) && $action =~ /\A(?:plan|run)\z/;
    die "artifact diagnostics must be a non-empty array\n"
        unless ref($diagnostics) eq 'ARRAY' && @$diagnostics;
    return _finalize_result({
        %{_empty_result($action)},
        success => JSON::PP::false,
        status => 'error',
        capability_evidence => $action eq 'run'
            ? _run_capability_evidence(undef, undef) : _plan_capability_evidence(undef),
        support_accounting => $action eq 'run'
            ? _run_support_accounting() : _plan_support_accounting(),
        diagnostics => _clone($diagnostics),
    });
}

sub _execute_source_action {
    my ($validated) = @_;
    my $request = $validated->{request};
    my $source = $request->{vial_source};
    my $options = $request->{options};
    my $action = $request->{action};
    my $parser_args = {
        text => $source->{text},
        source_name => $source->{source_id},
        source_catalog => $validated->{source_catalog},
    };

    my $checked = FSM::VIAL::Parser->check_source($parser_args);
    if (!$checked->{ok}) {
        return _source_result(
            action => $action,
            success => 0,
            status => 'error',
            source_style => undef,
            diagnostics => [_public_diagnostics($checked->{diagnostics})],
        );
    }

    my $style = FSM::VIAL::SourceProjection->source_style({
        text => $source->{text},
        source_name => $source->{source_id},
    });
    my $requested_style = $options->{source_style};
    if (defined($requested_style) && $requested_style ne 'auto' && $requested_style ne $style) {
        return _source_result(
            action => $action,
            success => 0,
            status => 'error',
            source_style => $style . '_v1',
            diagnostics => [_style_diagnostic(
                $source->{source_id},
                "source is $style but --style requested $requested_style",
            )],
        );
    }

    my $semantic_ir = FSM::VIAL::Parser->parse_source($parser_args);
    my $meaning_sha256 = FSM::VIAL::SourceProjection->semantic_projection_sha256($semantic_ir);
    my $formatted_source;
    if ($action eq 'format') {
        my $formatted = FSM::VIAL::SourceProjection->format_source({
            text => $source->{text},
            source_name => $source->{source_id},
            output_style => $options->{output_style},
        });
        $formatted_source = $formatted->{text};
        my $formatted_ir = FSM::VIAL::Parser->parse_source({
            text => $formatted_source,
            source_name => $source->{source_id},
            source_catalog => $validated->{source_catalog},
        });
        my $formatted_digest = FSM::VIAL::SourceProjection->semantic_projection_sha256($formatted_ir);
        if ($formatted_digest ne $meaning_sha256) {
            return _source_result(
                action => $action,
                success => 0,
                status => 'error',
                source_style => $style . '_v1',
                diagnostics => [_host_diagnostic('formatted source did not preserve the checked semantic projection')],
            );
        }
    }

    my $report = $checked->{semantic_report};
    return _source_result(
        action => $action,
        success => 1,
        status => $action eq 'check' ? 'checked' : 'formatted',
        source_style => $style . '_v1',
        source_identities => [map { _clone($_) } @{$report->{sources}}],
        semantic_report => _clone($report),
        formatted_source => $formatted_source,
        meaning_sha256 => $meaning_sha256,
        diagnostics => [],
    );
}

sub _execute_plan_action {
    my ($validated) = @_;
    my $request = $validated->{request};
    my $action = $request->{action};
    my $source = $request->{vial_source};
    my $options = $request->{options};
    my $parser_args = {
        text => $source->{text},
        source_name => $source->{source_id},
        source_catalog => $validated->{source_catalog},
    };
    my $checked = FSM::VIAL::Parser->check_source($parser_args);
    if (!$checked->{ok}) {
        return _plan_error_result(
            action => $action,
            source_style => undef,
            diagnostics => [_public_diagnostics($checked->{diagnostics})],
        );
    }
    my $style = FSM::VIAL::SourceProjection->source_style({
        text => $source->{text},
        source_name => $source->{source_id},
    });
    if ($options->{source_style} ne 'auto' && $options->{source_style} ne $style) {
        return _plan_error_result(
            action => $action,
            source_style => $style . '_v1',
            diagnostics => [_style_diagnostic(
                $source->{source_id},
                "source is $style but --style requested $options->{source_style}",
            )],
        );
    }
    my $semantic_ir = FSM::VIAL::Parser->parse_source($parser_args);
    my $meaning_sha256 = FSM::VIAL::SourceProjection->semantic_projection_sha256($semantic_ir);
    my $normal = FSM::VIAL::SourceProjection->format_source({
        text => $source->{text},
        source_name => $source->{source_id},
        output_style => 'normal',
    })->{text};

    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => $request->{hial_source},
        fixture_id => $options->{fixture_id},
        scenario_ids => $options->{scenario_ids},
        execution_profile => $options->{execution_profile},
        replay_manifest => $options->{replay_manifest},
        native_extension_catalog => $options->{native_extension_catalogs},
    });
    return _plan_error_result(
        action => $action,
        source_style => $style . '_v1',
        diagnostics => $built->{diagnostics},
    ) unless $built->{ok};

    my $plan = $built->{plan};
    my $fixture_name = $plan->{fixture}{fixture_name};
    my $fixture_slug = _slug($fixture_name);
    my ($plan_digest) = $plan->{plan_id} =~ m{\Aplan/([0-9a-f]{64})\z};
    die 'plan identity is invalid' unless defined $plan_digest;
    my $policy = $options->{artifact_policy};
    my $artifact_root = defined($policy->{artifact_root})
        ? $policy->{artifact_root}
        : ".artifacts/vial/$fixture_slug/$plan_digest";
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => $action,
        plan_id => $plan->{plan_id},
        artifact_root => $artifact_root,
        source_sha256 => sha256_hex($source->{text}),
        hial_sha256 => sha256_hex($request->{hial_source}{text}),
    }));
    my $source_identities = [
        map { _clone($_) } @{$checked->{semantic_report}{sources}},
        _source_identity($request->{hial_source}),
    ];
    my ($artifacts, $tool_manifest) = _build_plan_artifacts(
        normal_source => $normal,
        vial_source_id => $source->{source_id},
        hial_source_id => $request->{hial_source}{source_id},
        bridge => $built->{bridge_report},
        plan => $plan,
        review_artifacts => $built->{review_artifacts},
        source_style => $style . '_v1',
        source_identities => $source_identities,
        artifact_root => $artifact_root,
        operation_id => $operation_id,
        artifact_mode => $policy->{mode},
        meaning_sha256 => $meaning_sha256,
    );
    if (my $diagnostic = _plan_artifact_graph_diagnostic($artifacts)) {
        return _plan_error_result(
            action => $action,
            source_style => $style . '_v1',
            diagnostics => [$diagnostic],
        );
    }

    if ($action eq 'run') {
        return _execute_run_action(
            validated => $validated,
            request => $request,
            checked => $checked,
            built => $built,
            plan => $plan,
            normal_artifacts => $artifacts,
            source_identities => $source_identities,
            source_style => $style . '_v1',
            artifact_root => $artifact_root,
            operation_id => $operation_id,
            meaning_sha256 => $meaning_sha256,
        );
    }

    my $result = _finalize_result({
        %{_empty_result('plan')},
        success => JSON::PP::true,
        status => 'planned',
        source_identities => $source_identities,
        source_style => $style . '_v1',
        semantic_report => _clone($checked->{semantic_report}),
        bridge_manifest => _clone($built->{bridge_report}),
        plan => _clone($plan),
        tool_manifest => _clone($tool_manifest),
        artifacts => _clone($artifacts),
        capability_evidence => _plan_capability_evidence($meaning_sha256),
        support_accounting => _plan_support_accounting(),
        diagnostics => [],
        implementation => {
            component => 'FSM::VIAL::Tool',
            version => 1,
            stage => 'public_planning',
        },
    });
    my $sink = $validated->{artifact_sink};
    push @$sink, map { _clone($_) } @$artifacts;
    return $result;
}

sub _execute_run_action {
    my (%args) = @_;
    my $options = $args{request}{options};
    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $args{built}{execution_ir},
        bridge_manifest => $args{built}{bridge_manifest},
        backend_inputs => $args{built}{backend_inputs},
        artifact_root => $args{artifact_root},
        backend_profile => $options->{backend_profile},
    });
    return _plan_error_result(
        action => 'run',
        source_style => $args{source_style},
        diagnostics => [_backend_diagnostics($emission->{diagnostics})],
    ) unless $emission->{ok};

    my $executed = FSM::VIAL::Backend::Runner->run({
        repo_root => $args{validated}{repository_root},
        execution_ir => $args{built}{execution_ir},
        emission => $emission,
    });
    return _plan_error_result(
        action => 'run',
        source_style => $args{source_style},
        diagnostics => [_backend_diagnostics($executed->{diagnostics})],
    ) unless $executed->{ok};

    my @artifact = grep { $_->{relpath} ne 'vial-tool-manifest.json' }
        @{$args{normal_artifacts}};
    push @artifact, map { _clone($_) } @{$executed->{artifacts}};
    @artifact = sort { $a->{relpath} cmp $b->{relpath} } @artifact;
    if (my $diagnostic = _plan_artifact_graph_diagnostic(\@artifact)) {
        return _plan_error_result(
            action => 'run', source_style => $args{source_style},
            diagnostics => [$diagnostic],
        );
    }

    my @before_output = map { _persisted_artifact($_) } @artifact;
    my ($plan_artifact) = grep { $_->{role} eq 'vial_plan' } @before_output;
    my ($result_artifact) = grep { $_->{role} eq 'verification_result_manifest' } @before_output;
    die 'run artifact graph is missing its plan or result report'
        unless $plan_artifact && $result_artifact;
    my $verification_output = {
        schema => 'fsmgen.verification_output_manifest.v2',
        schema_version => 2,
        manifest_id => undef,
        mode => 'vial_run',
        producer => {
            component => 'FSM::VIAL::Tool',
            version => 1,
        },
        source_set => _clone($args{source_identities}),
        fixture => _clone($args{plan}{fixture}),
        plan => {
            plan_id => $args{plan}{plan_id},
            relpath => $plan_artifact->{relpath},
            sha256 => $plan_artifact->{sha256},
        },
        profile => {
            backend_profile => $executed->{backend_profile},
            execution_profile => $args{plan}{profile},
            tool_name => $executed->{result_manifest}{backend_profile}{tool_name},
            tool_version => $executed->{result_manifest}{backend_profile}{tool_version},
        },
        artifacts => \@before_output,
        validation => {
            compile => 'passed',
            runtime => 'passed',
            result => $executed->{result_manifest}{status},
            parity => 'not_evaluated',
        },
        diagnostics => [],
        compatibility => {
            legacy_schema => 'fsmgen.verification_output_manifest.v1',
            legacy_v1_projection_available => JSON::PP::false,
            reason => 'legacy schema v1 cannot losslessly represent a VIAL plan/backend/result graph',
        },
    };
    my $output_identity = _clone($verification_output);
    delete $output_identity->{manifest_id};
    $verification_output->{manifest_id} = 'verification-output/'
        . sha256_hex(_canonical_json($output_identity));
    push @artifact, _virtual_artifact(
        relpath => 'verification-output-manifest.json',
        kind => 'manifest',
        language => 'json',
        role => 'verification_output_manifest',
        content => _canonical_pretty_json($verification_output),
        source_layer => 'VIAL',
        generated_from => [$args{plan}{plan_id}, $executed->{result_manifest}{result_id}],
    );
    @artifact = sort { $a->{relpath} cmp $b->{relpath} } @artifact;

    my @persisted = map { _persisted_artifact($_) } @artifact;
    my %by_path = map { $_->{relpath} => $_ } @persisted;
    my ($verification_artifact) = grep {
        $_->{role} eq 'verification_output_manifest'
    } @persisted;
    ($result_artifact) = grep { $_->{role} eq 'verification_result_manifest' } @persisted;
    my $capability_evidence = _run_capability_evidence(
        $args{meaning_sha256}, $executed,
    );
    my $support_accounting = _run_support_accounting();
    my $policy = $options->{artifact_policy};
    my $tool_manifest = {
        schema => 'fsmgen.vial_tool_manifest.v1',
        schema_version => 1,
        operation_id => $args{operation_id},
        status => 'executed',
        action => 'run',
        source_style => $args{source_style},
        source_identities => _clone($args{source_identities}),
        fixture_id => $args{plan}{fixture}{fixture_id},
        scenario_ids => _clone($args{plan}{fixture}{scenario_ids}),
        execution_profile => $args{plan}{profile},
        backend_profile => $executed->{backend_profile},
        artifact_root => $args{artifact_root},
        artifacts => \@persisted,
        reports => {
            normal_source => _report_identity($by_path{'source/vial-normal.vial'}),
            bridge => _report_identity($by_path{'hial-vial-bridge.json'}),
            plan => _report_identity($by_path{'vial-plan.json'}),
            verification_output => _report_identity($verification_artifact),
            result => _report_identity($result_artifact),
        },
        capability_evidence => _clone($capability_evidence),
        support_accounting => _clone($support_accounting),
        diagnostics => [],
        cleanup => {
            staging_identity => $policy->{mode} eq 'repository'
                ? ".artifacts/tmp/vial/$args{operation_id}" : undef,
            staging_removed => $policy->{mode} eq 'repository'
                ? JSON::PP::true : JSON::PP::false,
            atomic_commit_completed => $policy->{mode} eq 'repository'
                ? JSON::PP::true : JSON::PP::false,
        },
    };
    push @artifact, _virtual_artifact(
        relpath => 'vial-tool-manifest.json',
        kind => 'manifest', language => 'json', role => 'vial_tool_manifest',
        content => _canonical_pretty_json($tool_manifest), source_layer => 'VIAL',
        generated_from => [$args{plan}{plan_id}, $executed->{result_manifest}{result_id}],
    );
    @artifact = sort { $a->{relpath} cmp $b->{relpath} } @artifact;
    if (my $diagnostic = _plan_artifact_graph_diagnostic(\@artifact)) {
        return _plan_error_result(
            action => 'run', source_style => $args{source_style},
            diagnostics => [$diagnostic],
        );
    }

    my $result = _finalize_result({
        %{_empty_result('run')},
        success => JSON::PP::true,
        status => 'executed',
        source_identities => _clone($args{source_identities}),
        source_style => $args{source_style},
        semantic_report => _clone($args{checked}{semantic_report}),
        bridge_manifest => _clone($args{built}{bridge_report}),
        plan => _clone($args{plan}),
        tool_manifest => _clone($tool_manifest),
        verification_output_manifest => _clone($verification_output),
        result_manifest => _clone($executed->{result_manifest}),
        artifacts => _clone(\@artifact),
        capability_evidence => $capability_evidence,
        support_accounting => $support_accounting,
        diagnostics => [],
        implementation => {
            component => 'FSM::VIAL::Tool',
            version => 1,
            stage => 'public_verilator_runtime',
        },
    });
    push @{$args{validated}{artifact_sink}}, map { _clone($_) } @artifact;
    return $result;
}

sub _build_plan_artifacts {
    my (%args) = @_;
    my @artifacts;
    push @artifacts, _virtual_artifact(
        relpath => 'source/vial-normal.vial',
        kind => 'source',
        language => 'vial',
        role => 'canonical_normal_source',
        content => $args{normal_source},
        source_layer => 'VIAL',
        generated_from => [$args{vial_source_id}],
    );
    for my $review (@{$args{review_artifacts}}) {
        push @artifacts, _virtual_artifact(
            relpath => 'review/' . $review->{artifact_name},
            kind => 'source',
            language => lc($review->{layer}),
            role => 'generated_hial_review',
            content => $review->{text},
            source_layer => $review->{layer},
            generated_from => [$review->{source_id}],
        );
    }
    my $bridge_json = _canonical_pretty_json($args{bridge});
    my $plan_json = _canonical_pretty_json($args{plan});
    push @artifacts, _virtual_artifact(
        relpath => 'hial-vial-bridge.json',
        kind => 'report',
        language => 'json',
        role => 'hial_vial_bridge_manifest',
        content => $bridge_json,
        source_layer => 'HIAL',
        generated_from => [$args{hial_source_id}],
    );
    push @artifacts, _virtual_artifact(
        relpath => 'vial-plan.json',
        kind => 'report',
        language => 'json',
        role => 'vial_plan',
        content => $plan_json,
        source_layer => 'VIAL',
        generated_from => [$args{plan}{plan_id}],
    );
    @artifacts = sort { $a->{relpath} cmp $b->{relpath} } @artifacts;

    my @persisted = map { _persisted_artifact($_) } @artifacts;
    my %by_path = map { $_->{relpath} => $_ } @persisted;
    my $reports = {
        normal_source => _report_identity($by_path{'source/vial-normal.vial'}),
        bridge => _report_identity($by_path{'hial-vial-bridge.json'}),
        plan => _report_identity($by_path{'vial-plan.json'}),
        verification_output => undef,
        result => undef,
    };
    my $tool_manifest = {
        schema => 'fsmgen.vial_tool_manifest.v1',
        schema_version => 1,
        operation_id => $args{operation_id},
        status => 'planned',
        action => 'plan',
        source_style => $args{source_style},
        source_identities => _clone($args{source_identities}),
        fixture_id => $args{plan}{fixture}{fixture_id},
        scenario_ids => _clone($args{plan}{fixture}{scenario_ids}),
        execution_profile => $args{plan}{profile},
        backend_profile => undef,
        artifact_root => $args{artifact_root},
        artifacts => \@persisted,
        reports => $reports,
        capability_evidence => _plan_capability_evidence($args{meaning_sha256}),
        support_accounting => _plan_support_accounting(),
        diagnostics => [],
        cleanup => {
            staging_identity => $args{artifact_mode} eq 'repository'
                ? ".artifacts/tmp/vial/$args{operation_id}" : undef,
            staging_removed => $args{artifact_mode} eq 'repository'
                ? JSON::PP::true : JSON::PP::false,
            atomic_commit_completed => $args{artifact_mode} eq 'repository'
                ? JSON::PP::true : JSON::PP::false,
        },
    };
    push @artifacts, _virtual_artifact(
        relpath => 'vial-tool-manifest.json',
        kind => 'manifest',
        language => 'json',
        role => 'vial_tool_manifest',
        content => _canonical_pretty_json($tool_manifest),
        source_layer => 'VIAL',
        generated_from => [$args{plan}{plan_id}],
    );
    @artifacts = sort { $a->{relpath} cmp $b->{relpath} } @artifacts;
    return (\@artifacts, $tool_manifest);
}

sub _virtual_artifact {
    my (%args) = @_;
    return {
        relpath => $args{relpath},
        kind => $args{kind},
        language => $args{language},
        role => $args{role},
        content => $args{content},
        encoding => 'utf-8',
        source_layer => $args{source_layer},
        generated_from => _clone($args{generated_from}),
    };
}

sub _persisted_artifact {
    my ($artifact) = @_;
    my $sha = sha256_hex($artifact->{content});
    my $entry = {
        id => 'artifact/' . sha256_hex($artifact->{relpath} . "\0" . $sha),
        relpath => $artifact->{relpath},
        kind => $artifact->{kind},
        language => $artifact->{language},
        role => $artifact->{role},
        encoding => $artifact->{encoding},
        source_layer => $artifact->{source_layer},
        generated_from => _clone($artifact->{generated_from}),
        bytes => bytes::length($artifact->{content}),
        sha256 => $sha,
    };
    $entry->{schema} = 'fsmgen.hial_vial_bridge_manifest.v1'
        if $artifact->{role} eq 'hial_vial_bridge_manifest';
    $entry->{schema} = 'fsmgen.vial_plan.v1'
        if $artifact->{role} eq 'vial_plan';
    $entry->{schema} = 'fsmgen.verification_output_manifest.v2'
        if $artifact->{role} eq 'verification_output_manifest';
    $entry->{schema} = 'fsmgen.verification_result_manifest.v1'
        if $artifact->{role} eq 'verification_result_manifest';
    $entry->{backend_profile} = 'sv_portable_verilator'
        if $artifact->{relpath} =~ m{\Abackends/sv_portable_verilator/};
    return $entry;
}

sub _report_identity {
    my ($artifact) = @_;
    return {
        relpath => $artifact->{relpath},
        sha256 => $artifact->{sha256},
    };
}

sub _source_identity {
    my ($source) = @_;
    return {
        source_name => $source->{source_id},
        content_sha256 => sha256_hex($source->{text}),
        byte_length => bytes::length($source->{text}),
        role => 'hial_dut',
    };
}

sub _slug {
    my ($value) = @_;
    my $slug = lc($value // 'fixture');
    $slug =~ s/[^a-z0-9]+/-/g;
    $slug =~ s/\A-+|-+\z//g;
    return length($slug) ? $slug : 'fixture';
}

sub _canonical_json {
    my ($value) = @_;
    return JSON::PP->new->canonical->encode($value);
}

sub _canonical_pretty_json {
    my ($value) = @_;
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _plan_artifact_graph_diagnostic {
    my ($artifacts) = @_;
    my $contract = build_vial_tooling_contract();
    return _diagnostic(
        'VIAL_MANIFEST_SCHEMA_ERROR',
        "artifact count exceeds the limit $contract->{limits}{artifacts}",
        [],
        '/artifacts',
    ) if @$artifacts > $contract->{limits}{artifacts};
    my (%exact, %folded, %directory);
    my $bytes = 0;
    for my $artifact (@$artifacts) {
        my $relpath = $artifact->{relpath};
        return _diagnostic('VIAL_MANIFEST_SCHEMA_ERROR', "duplicate artifact '$relpath'", [], '/artifacts')
            if $exact{$relpath}++;
        my $folded = lc($relpath);
        return _diagnostic('VIAL_ARTIFACT_COLLISION', "case-fold artifact collision at '$relpath'", [], '/artifacts')
            if exists($folded{$folded}) && $folded{$folded} ne $relpath;
        $folded{$folded} = $relpath;
        my @parts = split m{/}, $relpath;
        pop @parts;
        my $prefix = '';
        for my $part (@parts) {
            $prefix = length($prefix) ? "$prefix/$part" : $part;
            return _diagnostic('VIAL_ARTIFACT_COLLISION', "artifact file/directory collision at '$prefix'", [], '/artifacts')
                if $exact{$prefix};
            $directory{$prefix} = 1;
        }
        return _diagnostic('VIAL_ARTIFACT_COLLISION', "artifact file/directory collision at '$relpath'", [], '/artifacts')
            if $directory{$relpath};
        $bytes += bytes::length($artifact->{content});
    }
    return _diagnostic(
        'VIAL_MANIFEST_SCHEMA_ERROR',
        "artifact bytes exceed the limit $contract->{limits}{artifact_bytes}",
        [],
        '/artifacts',
    ) if $bytes > $contract->{limits}{artifact_bytes};
    return undef;
}

sub _validate_invocation {
    my ($request, $environment) = @_;
    die "request must be one unblessed hash"
        unless ref($request) eq 'HASH' && !blessed($request);
    _assert_json_safe($request, 'request');
    my @request_keys = qw(schema schema_version action vial_source hial_source options);
    _require_exact_keys($request, \@request_keys, 'request');
    die "request schema must be fsmgen.vial_tool_request.v1"
        unless defined($request->{schema}) && !ref($request->{schema})
            && $request->{schema} eq 'fsmgen.vial_tool_request.v1';
    die "request schema_version must be 1"
        unless defined($request->{schema_version}) && !ref($request->{schema_version})
            && $request->{schema_version} =~ /\A1\z/;
    die "request action must be a scalar"
        unless defined($request->{action}) && !ref($request->{action});

    my %known_action = map { $_ => 1 } qw(capabilities check format plan run);
    die "request action '$request->{action}' is unknown" unless $known_action{$request->{action}};
    die "hial_source must be null for capabilities, check, and format"
        if $request->{action} =~ /\A(?:capabilities|check|format)\z/ && defined($request->{hial_source});
    _validate_hial_source($request->{hial_source})
        if $request->{action} eq 'plan' || $request->{action} eq 'run';

    die "request options must be one unblessed hash"
        unless ref($request->{options}) eq 'HASH' && !blessed($request->{options});
    _require_exact_keys($request->{options}, \@OPTION_KEYS, 'request options');
    _validate_options($request->{action}, $request->{options});

    if ($request->{action} eq 'capabilities') {
        die "vial_source must be null for capabilities" if defined $request->{vial_source};
    }
    else {
        _validate_vial_source($request->{vial_source});
    }

    $environment = { source_catalog => {}, artifact_sink => [] }
        unless defined $environment;
    die "environment must be one unblessed hash"
        unless ref($environment) eq 'HASH' && !blessed($environment);
    _assert_json_safe($environment, 'environment');
    my %environment_key = map { $_ => 1 } qw(
        source_catalog artifact_sink repository_root
    );
    my @unknown_environment = sort grep { !$environment_key{$_} } keys %$environment;
    die "environment has unknown key '$unknown_environment[0]'" if @unknown_environment;
    die "environment is missing source_catalog or artifact_sink"
        unless exists($environment->{source_catalog}) && exists($environment->{artifact_sink});
    die "source_catalog must be one unblessed hash"
        unless ref($environment->{source_catalog}) eq 'HASH' && !blessed($environment->{source_catalog});
    my %catalog;
    for my $source_name (sort keys %{$environment->{source_catalog}}) {
        die "source_catalog key '$source_name' is unsafe" unless _safe_catalog_source_id($source_name);
        my $text = $environment->{source_catalog}{$source_name};
        die "source_catalog value for '$source_name' must be scalar"
            unless defined($text) && !ref($text);
        $catalog{$source_name} = $text;
    }
    die "artifact_sink must be an empty array"
        unless ref($environment->{artifact_sink}) eq 'ARRAY' && !@{$environment->{artifact_sink}};
    if ($request->{action} eq 'run') {
        die "run environment requires a scalar repository_root"
            unless exists($environment->{repository_root})
                && defined($environment->{repository_root})
                && !ref($environment->{repository_root})
                && length($environment->{repository_root});
    }

    return {
        request => _clone($request),
        source_catalog => \%catalog,
        artifact_sink => $environment->{artifact_sink},
        repository_root => $environment->{repository_root},
    };
}

sub _validate_options {
    my ($action, $options) = @_;
    my $source_style = $options->{source_style};
    if ($action eq 'capabilities') {
        die "capabilities requires null source_style"
            if defined $source_style;
    }
    else {
        die "source_style must be auto, normal, or terse"
            unless defined($source_style) && !ref($source_style)
                && $source_style =~ /\A(?:auto|normal|terse)\z/;
    }
    if ($action eq 'format') {
        die "format output_style must be normal or terse"
            unless defined($options->{output_style}) && !ref($options->{output_style})
                && $options->{output_style} =~ /\A(?:normal|terse)\z/;
    }
    else {
        die "$action requires null output_style" if defined $options->{output_style};
    }

    if ($action eq 'plan' || $action eq 'run') {
        die "fixture_id must be null or a non-empty scalar"
            if defined($options->{fixture_id})
                && (ref($options->{fixture_id}) || !length($options->{fixture_id}));
        die "scenario_ids must be an array"
            unless ref($options->{scenario_ids}) eq 'ARRAY';
        for my $index (0 .. $#{$options->{scenario_ids}}) {
            die "scenario_ids/$index must be a non-empty scalar"
                unless defined($options->{scenario_ids}[$index])
                    && !ref($options->{scenario_ids}[$index])
                    && length($options->{scenario_ids}[$index]);
        }
        die "execution_profile must be core_directed_single_clock_execution_v1"
            unless defined($options->{execution_profile})
                && !ref($options->{execution_profile})
                && $options->{execution_profile} eq 'core_directed_single_clock_execution_v1';
        if ($action eq 'plan') {
            die "plan requires null backend_profile" if defined $options->{backend_profile};
        }
        else {
            die "run requires a non-empty backend_profile"
                unless defined($options->{backend_profile})
                    && !ref($options->{backend_profile})
                    && length($options->{backend_profile});
        }
        die "replay_manifest must be null or an unblessed hash"
            if defined($options->{replay_manifest})
                && (ref($options->{replay_manifest}) ne 'HASH'
                    || blessed($options->{replay_manifest}));
        die "native_extension_catalogs must be an array"
            unless ref($options->{native_extension_catalogs}) eq 'ARRAY';
        die "artifact_policy must be one unblessed hash"
            unless ref($options->{artifact_policy}) eq 'HASH'
                && !blessed($options->{artifact_policy});
        _require_exact_keys($options->{artifact_policy}, [qw(mode artifact_root)], 'artifact_policy');
        die "artifact_policy mode must be virtual or repository"
            unless defined($options->{artifact_policy}{mode})
                && !ref($options->{artifact_policy}{mode})
                && $options->{artifact_policy}{mode} =~ /\A(?:virtual|repository)\z/;
        die "artifact_policy artifact_root must be null or a safe repository-relative directory"
            if defined($options->{artifact_policy}{artifact_root})
                && !_safe_artifact_root($options->{artifact_policy}{artifact_root});
    }
    else {
        for my $key (qw(fixture_id execution_profile backend_profile replay_manifest artifact_policy)) {
            die "$action requires null $key in the source-tooling slice" if defined $options->{$key};
        }
        for my $key (qw(scenario_ids native_extension_catalogs)) {
            die "$key must be an empty array in the source-tooling slice"
                unless ref($options->{$key}) eq 'ARRAY' && !@{$options->{$key}};
        }
    }
    my $quiet_is_boolean = blessed($options->{quiet})
        && blessed($options->{quiet})->isa('JSON::PP::Boolean');
    my $quiet_is_scalar = defined($options->{quiet}) && !ref($options->{quiet})
        && $options->{quiet} =~ /\A(?:0|1)\z/;
    die "quiet must be a JSON Boolean-compatible scalar"
        unless $quiet_is_boolean || $quiet_is_scalar;
}

sub _validate_vial_source {
    my ($source) = @_;
    die "vial_source must be one unblessed hash"
        unless ref($source) eq 'HASH' && !blessed($source);
    my %allowed = map { $_ => 1 } qw(
        source_id source_kind_hint text encoding origin display_name canonical_id
        relative_path metadata
    );
    my @unknown = sort grep { !$allowed{$_} } keys %{$source};
    die "vial_source has unknown key '$unknown[0]'" if @unknown;
    for my $required (qw(source_id text encoding origin display_name metadata)) {
        die "vial_source is missing '$required'" unless exists $source->{$required};
    }
    die "vial_source source_id is unsafe" unless _safe_source_id($source->{source_id});
    die "vial_source text must be scalar" unless defined($source->{text}) && !ref($source->{text});
    die "vial_source encoding must be utf-8"
        unless defined($source->{encoding}) && !ref($source->{encoding}) && lc($source->{encoding}) eq 'utf-8';
    for my $key (qw(origin display_name source_kind_hint canonical_id relative_path)) {
        next unless exists($source->{$key}) && defined($source->{$key});
        die "vial_source $key must be scalar" if ref($source->{$key});
    }
    die "vial_source source_kind_hint must be vial when supplied"
        if defined($source->{source_kind_hint}) && $source->{source_kind_hint} ne 'vial';
    die "vial_source metadata must be one unblessed hash"
        unless ref($source->{metadata}) eq 'HASH' && !blessed($source->{metadata});
}

sub _validate_hial_source {
    my ($source) = @_;
    die "hial_source must be one unblessed hash"
        unless ref($source) eq 'HASH' && !blessed($source);
    my %allowed = map { $_ => 1 } qw(
        source_id source_kind_hint text encoding origin display_name canonical_id
        relative_path metadata
    );
    my @unknown = sort grep { !$allowed{$_} } keys %$source;
    die "hial_source has unknown key '$unknown[0]'" if @unknown;
    for my $required (qw(source_id text encoding origin display_name metadata)) {
        die "hial_source is missing '$required'" unless exists $source->{$required};
    }
    die "hial_source source_id is unsafe" unless _safe_hial_source_id($source->{source_id});
    die "hial_source text must be scalar" unless defined($source->{text}) && !ref($source->{text});
    die "hial_source encoding must be utf-8"
        unless defined($source->{encoding}) && !ref($source->{encoding})
            && lc($source->{encoding}) eq 'utf-8';
    for my $key (qw(origin display_name source_kind_hint canonical_id relative_path)) {
        next unless exists($source->{$key}) && defined($source->{$key});
        die "hial_source $key must be scalar" if ref($source->{$key});
    }
    if (defined $source->{source_kind_hint}) {
        my %hint = map { $_ => 1 } qw(fsm isf ppif ial0 ial1 ial2);
        die "hial_source source_kind_hint is unsupported"
            unless $hint{$source->{source_kind_hint}};
        my %suffix_hint = (
            fsm => {fsm => 1, ial0 => 1},
            isf => {isf => 1, ial1 => 1},
            ppif => {ppif => 1, ial2 => 1},
        );
        my ($suffix) = lc($source->{source_id}) =~ /\.([^.]+)\z/;
        die "hial_source source_kind_hint does not match source_id suffix"
            unless $suffix_hint{$suffix}{$source->{source_kind_hint}};
    }
    die "hial_source metadata must be one unblessed hash"
        unless ref($source->{metadata}) eq 'HASH' && !blessed($source->{metadata});
}

sub _safe_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.vial\z/
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _safe_hial_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.(?:fsm|isf|ppif)\z/i
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _safe_catalog_source_id {
    my ($value) = @_;
    return _safe_source_id($value) || _safe_hial_source_id($value);
}

sub _safe_artifact_root {
    my ($value) = @_;
    return defined($value) && !ref($value) && length($value)
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _capabilities_result {
    my $contract = build_vial_tooling_contract();
    return _finalize_result({
        %{_empty_result('capabilities')},
        success => JSON::PP::true,
        status => 'checked',
        capability_evidence => {
            contract_source => $contract->{contract_source},
            supported_actions => [@{$contract->{supported_actions}}],
            capabilities => [@{$contract->{capabilities}}],
            diagnostics => [@{$contract->{diagnostics}}],
            limits => _clone($contract->{limits}),
            explicit_nonclaims => [@{$contract->{explicit_nonclaims}}],
        },
        support_accounting => _support_accounting(),
        diagnostics => [],
    });
}

sub _source_result {
    my (%args) = @_;
    my $result = {
        %{_empty_result($args{action})},
        success => $args{success} ? JSON::PP::true : JSON::PP::false,
        status => $args{status},
        source_style => $args{source_style},
        source_identities => $args{source_identities} || [],
        semantic_report => $args{semantic_report},
        formatted_source => $args{formatted_source},
        capability_evidence => _source_capability_evidence($args{meaning_sha256}),
        support_accounting => _support_accounting(),
        diagnostics => $args{diagnostics} || [],
    };
    return _finalize_result($result);
}

sub _plan_error_result {
    my (%args) = @_;
    my $action = $args{action} // 'plan';
    return _finalize_result({
        %{_empty_result($action)},
        success => JSON::PP::false,
        status => 'error',
        source_style => $args{source_style},
        capability_evidence => $action eq 'run'
            ? _run_capability_evidence(undef, undef) : _plan_capability_evidence(undef),
        support_accounting => $action eq 'run'
            ? _run_support_accounting() : _plan_support_accounting(),
        diagnostics => _clone($args{diagnostics} || []),
        implementation => {
            component => 'FSM::VIAL::Tool',
            version => 1,
            stage => $action eq 'run' ? 'public_verilator_runtime' : 'public_planning',
        },
    });
}

sub _error_result {
    my ($action, $diagnostic) = @_;
    my $planning = $action eq 'plan' || $action eq 'run';
    return _finalize_result({
        %{_empty_result($action)},
        success => JSON::PP::false,
        status => 'error',
        capability_evidence => $planning
            ? ($action eq 'run'
                ? _run_capability_evidence(undef, undef)
                : _plan_capability_evidence(undef))
            : _source_capability_evidence(undef),
        support_accounting => $planning
            ? ($action eq 'run' ? _run_support_accounting() : _plan_support_accounting())
            : _support_accounting(),
        diagnostics => [$diagnostic],
        implementation => {
            component => 'FSM::VIAL::Tool',
            version => 1,
            stage => $action eq 'run' ? 'public_verilator_runtime'
                : $planning ? 'public_planning' : 'public_source_tooling',
        },
    });
}

sub _empty_result {
    my ($action) = @_;
    return {
        schema => 'fsmgen.vial_tool_result.v1',
        schema_version => 1,
        action => $action,
        success => JSON::PP::false,
        status => 'error',
        source_identities => [],
        source_style => undef,
        semantic_report => undef,
        formatted_source => undef,
        bridge_manifest => undef,
        plan => undef,
        tool_manifest => undef,
        verification_output_manifest => undef,
        result_manifest => undef,
        artifacts => [],
        capability_evidence => {},
        support_accounting => {},
        diagnostics => [],
        implementation => {
            component => 'FSM::VIAL::Tool',
            version => 1,
            stage => 'public_source_tooling',
        },
    };
}

sub _source_capability_evidence {
    my ($meaning_sha256) = @_;
    my $contract = build_vial_tooling_contract();
    return {
        contract_source => $contract->{contract_source},
        capabilities => [@{$contract->{capabilities}}],
        semantic_projection_sha256 => $meaning_sha256,
        writes_files => JSON::PP::false,
    };
}

sub _plan_capability_evidence {
    my ($meaning_sha256) = @_;
    my $contract = build_vial_tooling_contract();
    return {
        contract_source => $contract->{contract_source},
        capabilities => [@{$contract->{capabilities}}],
        semantic_projection_sha256 => $meaning_sha256,
        writes_files => JSON::PP::true,
        atomic_artifacts => JSON::PP::true,
    };
}

sub _run_capability_evidence {
    my ($meaning_sha256, $executed) = @_;
    my $contract = build_vial_tooling_contract();
    return {
        contract_source => $contract->{contract_source},
        capabilities => [@{$contract->{capabilities}}],
        semantic_projection_sha256 => $meaning_sha256,
        writes_files => JSON::PP::true,
        atomic_artifacts => JSON::PP::true,
        backend_profile => $executed ? $executed->{backend_profile} : 'sv_portable_verilator',
        negotiation => $executed
            ? _clone($executed->{backend_manifest}{capability_evidence}{negotiation})
            : undef,
        compile => $executed ? 'passed' : 'not_run',
        runtime => $executed ? 'passed' : 'not_run',
        result => $executed ? $executed->{result_manifest}{status} : 'not_produced',
        parity => 'not_evaluated',
    };
}

sub _support_accounting {
    return {
        feature_id => 'feature.vial_public_check_format',
        coverage => 'vial_public_check_format_cli_api',
        classification => 'supported_smoke',
        evidence => 't/1555-vial-public-source-tooling.t',
    };
}

sub _plan_support_accounting {
    return {
        feature_id => 'feature.vial_public_plan',
        coverage => 'vial_public_plan_cli_api',
        classification => 'supported_smoke',
        evidence => 't/1556-vial-public-planning-artifacts.t',
    };
}

sub _run_support_accounting {
    return {
        feature_id => 'feature.vial_sv_portable_verilator_runtime',
        coverage => 'vial_sv_portable_verilator_runtime_cli_api',
        classification => 'supported_smoke',
        evidence => 't/1558-vial-verilator-run-integration.t',
    };
}

sub _backend_diagnostics {
    my ($diagnostics) = @_;
    return map {
        _diagnostic(
            $_->{code}, $_->{message}, [],
            defined($_->{path}) && !ref($_->{path}) ? $_->{path} : '/',
        )
    } @$diagnostics;
}

sub _public_diagnostics {
    my ($diagnostics) = @_;
    return map {
        {
            code => $_->{code},
            severity => $_->{severity},
            message => $_->{message},
            source_locations => defined($_->{source_location}) ? [_clone($_->{source_location})] : [],
            semantic_path => $_->{semantic_path},
            related => [],
            notes => [map { _clone($_) } @{$_->{notes} || []}],
            hints => [],
        }
    } @{$diagnostics};
}

sub _invocation_diagnostic {
    my ($message) = @_;
    return _diagnostic('VIAL_TOOL_INVOCATION_ERROR', $message, [], '/');
}

sub _style_diagnostic {
    my ($source_id, $message) = @_;
    return _diagnostic('VIAL_SOURCE_STYLE_ERROR', $message, [{
        source_name => $source_id,
        start_byte => 0,
        end_byte_exclusive => 0,
        start_line => 1,
        start_column => 1,
        end_line => 1,
        end_column => 1,
    }], '/');
}

sub _host_diagnostic {
    my ($message) = @_;
    return _diagnostic('VIAL_HOST_ERROR', $message, [], '/');
}

sub _diagnostic {
    my ($code, $message, $locations, $path) = @_;
    $message =~ s/[\r\n]+/ /g;
    return {
        code => $code,
        severity => 'error',
        message => $message,
        source_locations => $locations,
        semantic_path => $path,
        related => [],
        notes => [],
        hints => [],
    };
}

sub _finalize_result {
    my ($result) = @_;
    _require_exact_keys($result, \@RESULT_KEYS, 'result');
    _assert_json_safe($result, 'result');
    return _clone($result);
}

sub _require_exact_keys {
    my ($value, $keys, $label) = @_;
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists $value->{$_} } @{$keys};
    die "$label has unknown key '$unknown[0]'" if @unknown;
    die "$label is missing key '$missing[0]'" if @missing;
}

sub _assert_json_safe {
    my ($value, $path) = @_;
    return unless ref($value);
    die "$path contains a blessed value" if blessed($value) && !blessed($value)->isa('JSON::PP::Boolean');
    if (ref($value) eq 'HASH') {
        _assert_json_safe($value->{$_}, "$path/$_") for sort keys %{$value};
        return;
    }
    if (ref($value) eq 'ARRAY') {
        _assert_json_safe($value->[$_], "$path/$_") for 0 .. $#{$value};
        return;
    }
    return if blessed($value) && blessed($value)->isa('JSON::PP::Boolean');
    die "$path contains unsupported reference data";
}

sub _sanitize_exception {
    my ($exception) = @_;
    my $text = "$exception";
    $text =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return length($text) ? $text : 'invalid VIAL tool invocation';
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return JSON::PP::true if blessed($value) && blessed($value)->isa('JSON::PP::Boolean') && $value;
    return JSON::PP::false if blessed($value) && blessed($value)->isa('JSON::PP::Boolean');
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
