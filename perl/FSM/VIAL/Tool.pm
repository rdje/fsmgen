package FSM::VIAL::Tool;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Parser;
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
    _require_exact_keys($environment, [qw(source_catalog artifact_sink)], 'environment');
    die "source_catalog must be one unblessed hash"
        unless ref($environment->{source_catalog}) eq 'HASH' && !blessed($environment->{source_catalog});
    my %catalog;
    for my $source_name (sort keys %{$environment->{source_catalog}}) {
        die "source_catalog key '$source_name' is unsafe" unless _safe_source_id($source_name);
        my $text = $environment->{source_catalog}{$source_name};
        die "source_catalog value for '$source_name' must be scalar"
            unless defined($text) && !ref($text);
        $catalog{$source_name} = $text;
    }
    die "artifact_sink must be an empty array for source-only actions"
        unless ref($environment->{artifact_sink}) eq 'ARRAY' && !@{$environment->{artifact_sink}};

    return {
        request => _clone($request),
        source_catalog => \%catalog,
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

    for my $key (qw(fixture_id execution_profile backend_profile replay_manifest artifact_policy)) {
        die "$action requires null $key in the source-tooling slice" if defined $options->{$key};
    }
    for my $key (qw(scenario_ids native_extension_catalogs)) {
        die "$key must be an empty array in the source-tooling slice"
            unless ref($options->{$key}) eq 'ARRAY' && !@{$options->{$key}};
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

sub _safe_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.vial\z/
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

sub _error_result {
    my ($action, $diagnostic) = @_;
    return _finalize_result({
        %{_empty_result($action)},
        success => JSON::PP::false,
        status => 'error',
        capability_evidence => _source_capability_evidence(undef),
        support_accounting => _support_accounting(),
        diagnostics => [$diagnostic],
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

sub _support_accounting {
    return {
        feature_id => 'feature.vial_public_check_format',
        coverage => 'vial_public_check_format_cli_api',
        classification => 'supported_smoke',
        evidence => 't/1555-vial-public-source-tooling.t',
    };
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
