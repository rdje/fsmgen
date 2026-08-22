package FSM::VIAL::ArchitectureScaleBalancedPortableEmission;

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

use FSM::VIAL::ArchitectureScaleBalancedPortable;
use FSM::VIAL::Backend::SVPortableVerilator;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_emission_report.v1';
my $BACKEND_PROFILE = 'sv_portable_verilator';
my $COMPOSER = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $EMITTER = 'FSM::VIAL::Backend::SVPortableVerilator';
my @EVALUATE_KEYS = qw(construction);
my @VALIDATE_KEYS = qw(construction report);
my @STAGING_KEYS = qw(construction repository_root consumer);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity rerun_identity
    composition_report_identity workload_identity stage_identities
    negotiation artifact_oracle oracle_applicability claims explicit_nonclaims
    diagnostics
);
my @STAGE_KEYS = qw(
    bridge_manifest_sha256 execution_ir_sha256 backend_inputs_sha256
    plan_sha256 negotiation_sha256 source_map_sha256 backend_manifest_sha256
    artifact_graph_sha256
);
my @ORACLE_KEYS = qw(
    backend_profile artifact_root artifact_count source_artifact_count
    source_bytes source_map_entries mapped_operation_count mapped_binding_count
    artifact_relpaths source_identities maximum_generated_identifier_bytes
    generated_identifier_limit_bytes artifact_graph_sha256 byte_equal_rerun
    in_memory_only public_bypass_rejected atomic_rejection diagnostics
);
my @CLAIM_KEYS = qw(
    qualification_only all_six_gate_reports_consumed canonical_sources_constructed
    canonical_execution_constructed canonical_backend_inputs_constructed
    exact_revision_2_negotiated structural_emission_qualified
    external_tool_executed compile_executed runtime_executed trace_materialized
    result_produced support_claimed performance_claimed capacity_claimed
);
my @ARTIFACT_RELPATHS = qw(
    backends/sv_portable_verilator/backend-manifest.json
    backends/sv_portable_verilator/backend-source-map.json
    backends/sv_portable_verilator/commands/compile-command.json
    backends/sv_portable_verilator/commands/run-command.json
    backends/sv_portable_verilator/evidence/tool-profile.json
    backends/sv_portable_verilator/src/balanced_gate_tb.sv
    backends/sv_portable_verilator/src/dut/vial-architecture-scale-balanced-portable.sv
    backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
);
my $IDENTIFIER_LIMIT = 255;

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@EVALUATE_KEYS,
        'balanced portable-emission evaluation');
    return _evaluate($args[0]{construction});
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    confess __PACKAGE__ . "->validate_report expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@VALIDATE_KEYS,
        'balanced portable-emission report validation');
    _validate_report_shape($args[0]{report});
    my $rebuilt = _evaluate($args[0]{construction});
    confess "balanced portable-emission report is not canonical\n"
        unless _canonical_json($rebuilt)
            eq _canonical_json($args[0]{report});
    return _clone($rebuilt);
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@STAGING_KEYS,
        'balanced portable-emission staging');
    return $COMPOSER->with_staging({
        construction => $args[0]{construction},
        repository_root => $args[0]{repository_root},
        consumer => $args[0]{consumer},
    });
}

sub _evaluate($construction) {
    my $composition = $COMPOSER->evaluate({construction => $construction});
    return _failed_report(
        $construction, 'composition_prerequisite_failure', $composition,
        $composition->{diagnostics},
    ) unless $composition->{ok};

    my $first_route = $COMPOSER->_build_emission_route({
        construction => $construction,
    });
    return _failed_report(
        $construction, 'emission_route_failure', $composition,
        $first_route->{diagnostics},
    ) unless $first_route->{ok};
    my $second_route = $COMPOSER->_build_emission_route({
        construction => $construction,
    });
    return _failed_report(
        $construction, 'emission_rerun_route_failure', $composition,
        $second_route->{diagnostics},
    ) unless $second_route->{ok};

    my $artifact_root =
        "$construction->{workload}{staging_identity}/backend-output";
    my $first_emission = _emit_route($first_route, $artifact_root);
    my $second_emission = _emit_route($second_route, $artifact_root);
    my @diagnostics;
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_EMISSION_REJECTED',
        'the exact balanced portable-SystemVerilog emission was rejected',
        '/artifact_oracle',
    ) unless $first_emission->{ok} && $second_emission->{ok};

    my $first_projection = _route_projection($first_route);
    my $second_projection = _route_projection($second_route);
    for my $stage (qw(
        bridge_manifest execution_ir backend_inputs plan review_artifacts
    )) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_EMISSION_DETERMINISM_ERROR',
            "independent balanced $stage production changed bytes",
            "/stage_identities/$stage",
        ) unless _canonical_json($first_projection->{$stage})
            eq _canonical_json($second_projection->{$stage});
    }
    my $byte_equal = _canonical_json($first_emission)
        eq _canonical_json($second_emission);
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_EMISSION_DETERMINISM_ERROR',
        'independent balanced emissions changed bytes',
        '/artifact_oracle/byte_equal_rerun',
    ) unless $byte_equal;

    my ($oracle, $oracle_diagnostics) = _artifact_oracle(
        $first_route, $first_emission, $artifact_root, $byte_equal,
    );
    push @diagnostics, @$oracle_diagnostics;
    my $stage_identities = {
        bridge_manifest_sha256 => sha256_hex(
            _canonical_json($first_projection->{bridge_manifest}),
        ),
        execution_ir_sha256 => sha256_hex(
            _canonical_json($first_projection->{execution_ir}),
        ),
        backend_inputs_sha256 => sha256_hex(
            _canonical_json($first_projection->{backend_inputs}),
        ),
        plan_sha256 => sha256_hex(
            _canonical_json($first_projection->{plan}),
        ),
        negotiation_sha256 => defined($first_emission->{negotiation})
            ? sha256_hex(_canonical_json($first_emission->{negotiation}))
            : undef,
        source_map_sha256 => defined($first_emission->{source_map})
            ? sha256_hex(_canonical_json($first_emission->{source_map}))
            : undef,
        backend_manifest_sha256 =>
            defined($first_emission->{backend_manifest})
                ? sha256_hex(
                    _canonical_json($first_emission->{backend_manifest}),
                ) : undef,
        artifact_graph_sha256 => $oracle->{artifact_graph_sha256},
    };
    my $second_identities = {
        bridge_manifest_sha256 => sha256_hex(
            _canonical_json($second_projection->{bridge_manifest}),
        ),
        execution_ir_sha256 => sha256_hex(
            _canonical_json($second_projection->{execution_ir}),
        ),
        backend_inputs_sha256 => sha256_hex(
            _canonical_json($second_projection->{backend_inputs}),
        ),
        plan_sha256 => sha256_hex(
            _canonical_json($second_projection->{plan}),
        ),
        negotiation_sha256 => defined($second_emission->{negotiation})
            ? sha256_hex(_canonical_json($second_emission->{negotiation}))
            : undef,
        source_map_sha256 => defined($second_emission->{source_map})
            ? sha256_hex(_canonical_json($second_emission->{source_map}))
            : undef,
        backend_manifest_sha256 =>
            defined($second_emission->{backend_manifest})
                ? sha256_hex(
                    _canonical_json($second_emission->{backend_manifest}),
                ) : undef,
        artifact_graph_sha256 => defined($second_emission->{artifacts})
            ? sha256_hex(_canonical_json($second_emission->{artifacts}))
            : undef,
    };
    my $rerun_identity = 'rerun/' . sha256_hex(_canonical_json({
        first => $stage_identities,
        second => $second_identities,
    }));

    my $report = {
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'emission_oracle_failure'
            : 'structural_emission_qualified',
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => $rerun_identity,
        composition_report_identity => $composition->{report_identity},
        workload_identity => $construction->{workload}{workload_identity},
        stage_identities => $stage_identities,
        negotiation => _clone($first_emission->{negotiation}),
        artifact_oracle => $oracle,
        oracle_applicability => [
            {stage => 'construct', status => 'completed'},
            {stage => 'semantic', status => 'completed'},
            {stage => 'bridge', status => 'completed'},
            {stage => 'plan', status => 'completed'},
            {stage => 'backend_inputs', status => 'completed'},
            {stage => 'emit', status => 'completed'},
            {stage => 'compile', status => 'not_run'},
            {stage => 'runtime', status => 'not_run'},
            {stage => 'trace', status => 'not_materialized'},
            {stage => 'result', status => 'not_produced'},
        ],
        claims => {
            qualification_only => JSON::PP::true,
            all_six_gate_reports_consumed => JSON::PP::true,
            canonical_sources_constructed => JSON::PP::true,
            canonical_execution_constructed => JSON::PP::true,
            canonical_backend_inputs_constructed => JSON::PP::true,
            exact_revision_2_negotiated => JSON::PP::true,
            structural_emission_qualified => @diagnostics
                ? JSON::PP::false : JSON::PP::true,
            external_tool_executed => JSON::PP::false,
            compile_executed => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            trace_materialized => JSON::PP::false,
            result_produced => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
        },
        explicit_nonclaims => _clone($composition->{explicit_nonclaims}),
        diagnostics => \@diagnostics,
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'balanced-emission/'
        . sha256_hex(_canonical_json($identity_projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _emit_route($route, $artifact_root) {
    confess "balanced portable-emission route call is private\n"
        unless caller eq __PACKAGE__;
    return $EMITTER->emit_balanced_portable_qualification({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $BACKEND_PROFILE,
    });
}

sub _artifact_oracle($route, $emission, $artifact_root, $byte_equal) {
    my @diagnostics;
    my $add = sub ($message, $path) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_ARTIFACT_ORACLE_ERROR', $message, $path,
        );
    };
    my @result_keys = sort keys %$emission;
    my @expected_result_keys = sort @{$EMITTER->result_keys};
    $add->('portable-SystemVerilog result schema is not closed', '/emission')
        unless _canonical_json(\@result_keys)
            eq _canonical_json(\@expected_result_keys);
    $add->('balanced portable-SystemVerilog emission was not accepted',
        '/emission/ok') unless $emission->{ok}
            && ($emission->{status} // '') eq 'emitted'
            && ($emission->{backend_profile} // '') eq $BACKEND_PROFILE
            && ref($emission->{diagnostics}) eq 'ARRAY'
            && !@{$emission->{diagnostics}};

    my $negotiation = $emission->{negotiation} || {};
    $add->('revision-2 negotiation is not completely satisfied',
        '/emission/negotiation')
        unless ref($negotiation->{required}) eq 'ARRAY'
            && ref($negotiation->{satisfied}) eq 'ARRAY'
            && _canonical_json($negotiation->{required})
                eq _canonical_json($negotiation->{satisfied})
            && ref($negotiation->{unsatisfied}) eq 'ARRAY'
            && !@{$negotiation->{unsatisfied}}
            && ref($negotiation->{native_only}) eq 'ARRAY'
            && !@{$negotiation->{native_only}}
            && scalar(grep {
                $_ eq 'hial_vial.bridge_qualification.balanced_portable_v2'
            } @{$negotiation->{satisfied}}) == 1;

    my $artifacts = ref($emission->{artifacts}) eq 'ARRAY'
        ? $emission->{artifacts} : [];
    my @relpaths = map { $_->{relpath} // '' } @$artifacts;
    $add->('balanced artifact inventory or order changed',
        '/emission/artifacts')
        unless _canonical_json(\@relpaths)
            eq _canonical_json(\@ARTIFACT_RELPATHS);
    my %seen;
    my @artifact_keys = sort qw(
        content encoding generated_from kind language relpath role source_layer
    );
    for my $index (0 .. $#$artifacts) {
        my $artifact = $artifacts->[$index];
        my @keys = sort keys %$artifact;
        $add->('balanced artifact schema is not closed',
            "/emission/artifacts/$index")
            unless _canonical_json(\@keys)
                eq _canonical_json(\@artifact_keys);
        $add->('balanced artifact path is unsafe',
            "/emission/artifacts/$index/relpath")
            unless _safe_relative_path($artifact->{relpath});
        $add->('balanced artifact path is duplicated',
            "/emission/artifacts/$index/relpath")
            if $seen{$artifact->{relpath} // ''}++;
    }

    my @sources = grep {
        ($_->{language} // '') eq 'systemverilog'
    } @$artifacts;
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content}) for @sources;
    my @source_identities = map {{
        relpath => $_->{relpath},
        bytes => bytes::length($_->{content}),
        sha256 => sha256_hex($_->{content}),
    }} @sources;
    $add->('balanced source count or byte total changed',
        '/emission/artifacts')
        unless @sources == 3 && $source_bytes == 503_279;

    my $source_map = ref($emission->{source_map}) eq 'HASH'
        ? $emission->{source_map} : {artifacts => [], entries => []};
    my @source_map_keys = sort keys %$source_map;
    my @expected_source_map_keys = sort @{$EMITTER->source_map_keys};
    $add->('balanced source-map schema is not closed',
        '/emission/source_map')
        unless _canonical_json(\@source_map_keys)
            eq _canonical_json(\@expected_source_map_keys);
    my $entries = ref($source_map->{entries}) eq 'ARRAY'
        ? $source_map->{entries} : [];
    $add->('balanced source-map entry count changed',
        '/emission/source_map/entries') unless @$entries == 3_605;
    my %source_by_path = map { $_->{relpath} => $_ } @sources;
    my %line_count = map {
        $_->{relpath} => scalar(() = $_->{content} =~ /\n/g)
    } @sources;
    my @entry_keys = sort @{$EMITTER->source_map_entry_keys};
    my (%mapped_operation, %mapped_binding);
    my $maximum_identifier = 0;
    for my $index (0 .. $#$entries) {
        my $entry = $entries->[$index];
        my @keys = sort keys %$entry;
        $add->('balanced source-map entry schema is not closed',
            "/emission/source_map/entries/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@entry_keys);
        my $relpath = $entry->{generated_relpath} // '';
        $add->('balanced source-map entry names a non-source artifact',
            "/emission/source_map/entries/$index/generated_relpath")
            unless $source_by_path{$relpath};
        $add->('balanced source-map entry has an invalid line span',
            "/emission/source_map/entries/$index")
            unless ($entry->{generated_start_line} // 0) >= 1
                && ($entry->{generated_end_line} // 0)
                    >= $entry->{generated_start_line}
                && ($entry->{generated_end_line} // 0)
                    <= ($line_count{$relpath} // 0);
        my $symbol = $entry->{generated_symbol};
        $add->('balanced source-map symbol is not a legal identifier',
            "/emission/source_map/entries/$index/generated_symbol")
            unless _legal_identifier($symbol);
        my $bytes = defined($symbol) && !ref($symbol)
            ? bytes::length($symbol) : 0;
        $maximum_identifier = $bytes if $bytes > $maximum_identifier;
        for my $semantic (@{$entry->{semantic_paths} || []}) {
            $mapped_operation{$semantic} = 1
                if $semantic =~ m{\Aoperation/};
            $mapped_binding{$semantic} = 1
                if $semantic =~ m{\Abinding/};
        }
    }
    my $top = $emission->{generated_top};
    $add->('balanced generated top is not a legal identifier',
        '/emission/generated_top') unless _legal_identifier($top);
    my $top_bytes = defined($top) && !ref($top)
        ? bytes::length($top) : 0;
    $maximum_identifier = $top_bytes
        if $top_bytes > $maximum_identifier;
    $add->('balanced generated identifier limit was exceeded',
        '/emission/source_map/entries')
        if $maximum_identifier > $IDENTIFIER_LIMIT;

    my $execution = $route->{execution_ir}->as_hashref;
    my @expected_operations = sort map { $_->{operation_id} }
        @{$execution->{operation_graph}{operations}};
    my @actual_operations = sort keys %mapped_operation;
    $add->('balanced operation source-map coverage is incomplete',
        '/emission/source_map/entries')
        unless _canonical_json(\@actual_operations)
            eq _canonical_json(\@expected_operations);
    my @expected_bindings = _execution_binding_ids($execution);
    my @actual_bindings = sort grep {
        my $candidate = $_;
        scalar(grep { $_ eq $candidate } @expected_bindings)
    } keys %mapped_binding;
    $add->('balanced binding source-map coverage is incomplete',
        '/emission/source_map/entries')
        unless _canonical_json(\@actual_bindings)
            eq _canonical_json(\@expected_bindings);

    my %by_path = map { $_->{relpath} => $_ } @$artifacts;
    my $map_artifact = $by_path{
        'backends/sv_portable_verilator/backend-source-map.json'};
    $add->('balanced source-map artifact changed returned source-map bytes',
        '/emission/source_map')
        unless $map_artifact
            && $map_artifact->{content} eq _pretty_json($source_map);
    my $manifest_artifact = $by_path{
        'backends/sv_portable_verilator/backend-manifest.json'};
    $add->('balanced manifest artifact changed returned manifest bytes',
        '/emission/backend_manifest')
        unless $manifest_artifact
            && ref($emission->{backend_manifest}) eq 'HASH'
            && $manifest_artifact->{content}
                eq _pretty_json($emission->{backend_manifest});

    my $public = $EMITTER->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $BACKEND_PROFILE,
    });
    my $public_rejected = !$public->{ok}
        && ($public->{diagnostics}[0]{code} // '') eq 'VIAL_BACKEND_UNSUPPORTED'
        && ref($public->{artifacts}) eq 'ARRAY' && !@{$public->{artifacts}}
        && ref($public->{negotiation}) eq 'HASH'
        && scalar(grep {
            $_ eq 'hial_vial.bridge_qualification.balanced_portable_v2'
        } @{$public->{negotiation}{unsatisfied} || []}) == 1;
    $add->('public emitter path admitted the private revision-2 shape',
        '/emission/public_bypass') unless $public_rejected;

    my $artifact_graph_sha256 = sha256_hex(_canonical_json($artifacts));
    return ({
        backend_profile => $BACKEND_PROFILE,
        artifact_root => $artifact_root,
        artifact_count => scalar(@$artifacts),
        source_artifact_count => scalar(@sources),
        source_bytes => $source_bytes,
        source_map_entries => scalar(@$entries),
        mapped_operation_count => scalar(@actual_operations),
        mapped_binding_count => scalar(@actual_bindings),
        artifact_relpaths => \@relpaths,
        source_identities => \@source_identities,
        maximum_generated_identifier_bytes => $maximum_identifier,
        generated_identifier_limit_bytes => $IDENTIFIER_LIMIT,
        artifact_graph_sha256 => $artifact_graph_sha256,
        byte_equal_rerun => $byte_equal
            ? JSON::PP::true : JSON::PP::false,
        in_memory_only => JSON::PP::true,
        public_bypass_rejected => $public_rejected
            ? JSON::PP::true : JSON::PP::false,
        atomic_rejection => $public_rejected
            ? JSON::PP::true : JSON::PP::false,
        diagnostics => _clone($emission->{diagnostics}),
    }, \@diagnostics);
}

sub _execution_binding_ids($execution) {
    my @binding = (
        $execution->{bindings}{unit}{binding_id},
        map({ $_->{binding_id} } @{$execution->{bindings}{domains} || []}),
        map({ $_->{binding_id} } @{$execution->{bindings}{endpoints} || []}),
        map({ $_->{binding_id} } @{$execution->{bindings}{probes} || []}),
    );
    for my $transaction (@{$execution->{bindings}{transactions} || []}) {
        push @binding, $transaction->{binding_id};
        push @binding, map { $_->{binding_id} }
            @{$transaction->{fields} || []};
    }
    push @binding, map { $_->{binding_id} } @{$execution->{events} || []};
    my %seen;
    return sort grep { defined($_) && !$seen{$_}++ } @binding;
}

sub _route_projection($route) {
    return {
        bridge_manifest => $route->{bridge_manifest}->as_hashref,
        execution_ir => $route->{execution_ir}->as_hashref,
        backend_inputs => _clone($route->{backend_inputs}),
        plan => _clone($route->{plan}),
        review_artifacts => _clone($route->{review_artifacts}),
    };
}

sub _failed_report($construction, $status, $composition, $diagnostics) {
    my $report = {
        ok => JSON::PP::false,
        status => $status,
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => undef,
        composition_report_identity => $composition->{report_identity},
        workload_identity => $construction->{workload}{workload_identity},
        stage_identities => {map { $_ => undef } @STAGE_KEYS},
        negotiation => undef,
        artifact_oracle => undef,
        oracle_applicability => [
            {stage => 'emit', status => 'not_run_prerequisite_failure'},
        ],
        claims => {
            qualification_only => JSON::PP::true,
            all_six_gate_reports_consumed => JSON::PP::false,
            canonical_sources_constructed => JSON::PP::true,
            canonical_execution_constructed => JSON::PP::false,
            canonical_backend_inputs_constructed => JSON::PP::false,
            exact_revision_2_negotiated => JSON::PP::false,
            structural_emission_qualified => JSON::PP::false,
            external_tool_executed => JSON::PP::false,
            compile_executed => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            trace_materialized => JSON::PP::false,
            result_produced => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
        },
        explicit_nonclaims => _clone(
            $construction->{workload}{specification}{explicit_nonclaims},
        ),
        diagnostics => _clone($diagnostics),
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'balanced-emission/'
        . sha256_hex(_canonical_json($identity_projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS,
        'balanced portable-emission report');
    _exact_keys($report->{stage_identities}, \@STAGE_KEYS,
        'balanced portable-emission stage identities');
    _exact_keys($report->{claims}, \@CLAIM_KEYS,
        'balanced portable-emission claims');
    _exact_keys($report->{artifact_oracle}, \@ORACLE_KEYS,
        'balanced portable-emission artifact oracle')
        if defined $report->{artifact_oracle};
    confess "balanced portable-emission oracle applicability must be an array\n"
        unless ref($report->{oracle_applicability}) eq 'ARRAY';
    confess "balanced portable-emission explicit nonclaims must be an array\n"
        unless ref($report->{explicit_nonclaims}) eq 'ARRAY';
    confess "balanced portable-emission diagnostics must be an array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    my $projection = _clone($report);
    my $identity = delete $projection->{report_identity};
    confess "balanced portable-emission report identity is invalid\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'balanced-emission/'
                . sha256_hex(_canonical_json($projection));
}

sub _diagnostic($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
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

sub _legal_identifier($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
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
    confess "balanced portable-emission report contains unsupported data\n"
        if ref($value);
    return $value;
}

1;
