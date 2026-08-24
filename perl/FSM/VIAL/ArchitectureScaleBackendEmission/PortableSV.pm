package FSM::VIAL::ArchitectureScaleBackendEmission::PortableSV;

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

use FSM::VIAL::Backend::SVPortableVerilator;

my $PROFILE = 'sv_portable_verilator';
my $ORACLE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_portable_sv_oracle.v2';
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
    maximum_generated_identifier_bytes generated_identifier_limit_bytes
    artifact_graph_sha256 byte_equal_rerun in_memory_only atomic_rejection
    diagnostics
);
my @ARTIFACT_RELPATHS = qw(
    backends/sv_portable_verilator/backend-manifest.json
    backends/sv_portable_verilator/backend-source-map.json
    backends/sv_portable_verilator/commands/compile-command.json
    backends/sv_portable_verilator/commands/run-command.json
    backends/sv_portable_verilator/evidence/tool-profile.json
    backends/sv_portable_verilator/src/base_output_arbitration_tb.sv
    backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv
    backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
);
my @SOURCE_RELPATHS = @ARTIFACT_RELPATHS[5 .. 7];
my %EXPECTED = (
    reference_v1 => {
        operations => 21, source_bytes => 164_507, source_maps => 54,
        fixture_bytes => 106_181,
        fixture_sha256 =>
            '1839aae7d65c3394442a4b26538b9ea73ab35ae142ca32e29177775919d0f730',
    },
    gate_candidate_v1 => {
        operations => 1_024, source_bytes => 2_803_857,
        source_maps => 1_057, fixture_bytes => 2_745_531,
        fixture_sha256 =>
            'ec5a91968cea2bb5f88994188517cc8b506bf49d6a4ec984fc6b0ad4ee367481',
    },
    qualification_candidate_v1 => {
        operations => 4_096, source_bytes => 10_910_865,
        source_maps => 4_129, fixture_bytes => 10_852_539,
        fixture_sha256 =>
            'd7087673e824dc18e6a91d7a41f819483428650049fc92a0bd28e3a1737065e8',
    },
    limit_v1 => {
        operations => 6_318, source_bytes => 16_774_723,
        source_maps => 6_351, fixture_bytes => 16_716_397,
        fixture_sha256 =>
            'f05f90e1a730b187e2eb6f2f15925c92b1a5f4a6dd12268d705297410dc7eb21',
    },
    over_limit_v1 => {operations => 6_319},
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
        'portable-SystemVerilog source request');
    _selected_level($raw->{level});
    confess "portable-SystemVerilog reference path must be a scalar\n"
        unless defined($raw->{reference_relative_path})
            && !ref($raw->{reference_relative_path});
    confess "portable-SystemVerilog reference text must be a scalar\n"
        unless defined($raw->{reference_text}) && !ref($raw->{reference_text});
    return [$raw->{reference_relative_path}, $raw->{reference_text}]
        if $raw->{level} eq 'reference_v1';

    my $repeat_count = $EXPECTED{$raw->{level}}{operations} - 22;
    my $needle = '              (scoreboard_check writes)))';
    my $insertion = "              (repeat $repeat_count"
        . ' (expect scale_response_zero (same (sample response) #b0)))'
        . "\n";
    my $source = $raw->{reference_text};
    my $matches = $source =~ s/\Q$needle\E/$insertion$needle/;
    confess "anchored response-expectation insertion point is not unique\n"
        unless $matches == 1;
    return [$SCALE_SOURCE, $source];
}

sub evaluate($class, @args) {
    confess "portable-SystemVerilog profile evaluation is caller-sealed\n"
        unless caller eq 'FSM::VIAL::ArchitectureScaleBackendEmission';
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my $raw = $args[0];
    _exact_keys($raw, [qw(construction first_route second_route)],
        'portable-SystemVerilog evaluation');
    my $construction = $raw->{construction};
    confess "portable-SystemVerilog construction must be one hash\n"
        unless ref($construction) eq 'HASH' && !blessed($construction);
    my $specification = $construction->{specification};
    confess "portable-SystemVerilog construction specification is invalid\n"
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
        'independent portable-SystemVerilog emissions were not byte-identical',
        '/artifact_oracle/portable_sv',
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
    confess "portable-SystemVerilog route must be one hash\n"
        unless ref($route) eq 'HASH' && !blessed($route);
    return FSM::VIAL::Backend::SVPortableVerilator->emit({
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
            'VIAL_SCALE_PORTABLE_SV_ARTIFACT_ORACLE_ERROR',
            $message, $path,
        );
    };
    my @actual_keys = sort keys %$emission;
    my @result_keys = sort
        @{FSM::VIAL::Backend::SVPortableVerilator->result_keys};
    $add->('portable-SystemVerilog result schema is not closed', '/emission')
        unless _canonical_json(\@actual_keys) eq _canonical_json(\@result_keys);
    $add->('portable-SystemVerilog backend profile changed',
        '/emission/backend_profile')
        unless ($emission->{backend_profile} // '') eq $PROFILE;

    my ($artifact_count, $source_count, $source_bytes, $map_count) =
        (0, 0, 0, 0);
    my ($mapped_operations, $mapped_sources, $maximum_identifier) = (0, 0, 0);
    my (@artifact_relpaths, @source_identities);
    my $artifact_graph_sha256;

    if ($rejected) {
        my $expected_diagnostics = [{
            code => 'VIAL_BACKEND_LIMIT_EXCEEDED',
            severity => 'error',
            message =>
                'generated SystemVerilog exceeds the 16 MiB backend cap',
            path => '/artifacts',
        }];
        $add->('adjacent portable-SystemVerilog shape did not reject',
            '/emission/ok') if $emission->{ok};
        $add->('adjacent portable-SystemVerilog diagnostic changed',
            '/emission/diagnostics')
            unless _canonical_json($emission->{diagnostics})
                eq _canonical_json($expected_diagnostics);
        $add->('adjacent portable-SystemVerilog rejection published artifacts',
            '/emission/artifacts')
            unless ref($emission->{artifacts}) eq 'ARRAY'
                && !@{$emission->{artifacts}};
        for my $field (qw(
            plan_id generated_top operation_id backend_manifest source_map
            trace_contract negotiation
        )) {
            $add->("adjacent rejection retained partial $field evidence",
                "/emission/$field") if defined $emission->{$field};
        }
    }
    else {
        $add->('accepted portable-SystemVerilog shape was rejected',
            '/emission/ok') unless $emission->{ok};
        $add->('accepted portable-SystemVerilog status changed',
            '/emission/status') unless ($emission->{status} // '') eq 'emitted';
        $add->('accepted portable-SystemVerilog emission has diagnostics',
            '/emission/diagnostics')
            unless ref($emission->{diagnostics}) eq 'ARRAY'
                && !@{$emission->{diagnostics}};
        my $artifacts = ref($emission->{artifacts}) eq 'ARRAY'
            ? $emission->{artifacts} : [];
        $add->('portable-SystemVerilog artifacts must be an array',
            '/emission/artifacts') unless ref($emission->{artifacts}) eq 'ARRAY';
        $artifact_count = scalar(@$artifacts);
        @artifact_relpaths = map { $_->{relpath} // '' } @$artifacts;
        $add->('portable-SystemVerilog artifact inventory or order changed',
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
        my @expected_sources = _expected_sources($expected);
        $add->('portable-SystemVerilog source identities changed',
            '/emission/artifacts')
            unless _canonical_json(\@source_identities)
                eq _canonical_json(\@expected_sources);
        $add->('portable-SystemVerilog source byte total changed',
            '/emission/artifacts') unless $source_bytes == $expected->{source_bytes};

        my $source_map = ref($emission->{source_map}) eq 'HASH'
            ? $emission->{source_map} : {artifacts => [], entries => []};
        $add->('portable-SystemVerilog source map is missing',
            '/emission/source_map') unless ref($emission->{source_map}) eq 'HASH';
        my @source_map_keys = sort keys %$source_map;
        my @expected_source_map_keys = sort
            @{FSM::VIAL::Backend::SVPortableVerilator->source_map_keys};
        $add->('portable-SystemVerilog source-map schema is not closed',
            '/emission/source_map')
            unless _canonical_json(\@source_map_keys)
                eq _canonical_json(\@expected_source_map_keys);
        my $entries = ref($source_map->{entries}) eq 'ARRAY'
            ? $source_map->{entries} : [];
        my $map_artifacts = ref($source_map->{artifacts}) eq 'ARRAY'
            ? $source_map->{artifacts} : [];
        $map_count = scalar(@$entries);
        $mapped_sources = scalar(@$map_artifacts);
        $add->('portable-SystemVerilog source-map count changed',
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
        $add->('portable-SystemVerilog operation-map identities changed',
            '/emission/source_map/entries')
            unless _canonical_json(\@mapped_operation_ids)
                eq _canonical_json(\@expected_operation_ids);
        my $top = $emission->{generated_top};
        $add->('generated top identifier is not legal',
            '/emission/generated_top')
            unless _legal_identifier($top);
        my $top_bytes = defined($top) && !ref($top)
            ? bytes::length($top) : 0;
        $maximum_identifier = $top_bytes
            if $top_bytes > $maximum_identifier;
        $add->('portable-SystemVerilog operation maps are incomplete',
            '/emission/source_map/entries')
            unless $mapped_operations == $expected->{operations};
        $add->('portable-SystemVerilog generated identifier maximum changed',
            '/emission/source_map/entries')
            unless $maximum_identifier == 113;
        $add->('portable-SystemVerilog generated identifier limit was exceeded',
            '/emission/source_map/entries')
            if $maximum_identifier > $IDENTIFIER_LIMIT;
        _validate_evidence_artifacts($artifacts, $emission, $source_map, $add);
        $artifact_graph_sha256 = sha256_hex(_canonical_json($artifacts));
    }

    return ({
        schema => $ORACLE_SCHEMA,
        schema_version => 2,
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
        $add->('portable-SystemVerilog artifact schema is not closed',
            "/emission/artifacts/$index")
            unless _canonical_json(\@keys) eq _canonical_json(\@expected_keys);
        $add->('portable-SystemVerilog artifact path is unsafe',
            "/emission/artifacts/$index/relpath")
            unless _safe_relative_path($artifact->{relpath});
        $add->('portable-SystemVerilog artifact path is duplicated',
            "/emission/artifacts/$index/relpath")
            if $seen{$artifact->{relpath} // ''}++;
    }
}

sub _expected_sources($expected) {
    return (
        {
            relpath => $SOURCE_RELPATHS[0], bytes => $expected->{fixture_bytes},
            sha256 => $expected->{fixture_sha256},
        },
        {
            relpath => $SOURCE_RELPATHS[1], bytes => 57_531,
            sha256 =>
                'eeaa8a687a3a1ce010446f848ca6785538dd907e4c567a91ee6049cc4e079f82',
        },
        {
            relpath => $SOURCE_RELPATHS[2], bytes => 795,
            sha256 =>
                '9ceb9f62a768cf36785674752d10fc9505a3ab20798041eed76dbb53c6203903',
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
    $add->('portable-SystemVerilog source-map artifact closure changed',
        '/emission/source_map/artifacts')
        unless _canonical_json(\@sorted) eq _canonical_json(\@expected);
}

sub _validate_source_map_entries($entries, $source_by_path, $line_count, $add) {
    my %mapped_operation;
    my $maximum_identifier = 0;
    my @entry_keys = sort
        @{FSM::VIAL::Backend::SVPortableVerilator->source_map_entry_keys};
    for my $index (0 .. $#$entries) {
        my $entry = $entries->[$index];
        my @keys = sort keys %$entry;
        $add->('portable-SystemVerilog source-map entry is not closed',
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
        $add->('source-map generated identifier is not legal',
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

sub _validate_evidence_artifacts($artifacts, $emission, $source_map, $add) {
    my %by_path = map { $_->{relpath} => $_ } @$artifacts;
    my $map_artifact = $by_path{
        'backends/sv_portable_verilator/backend-source-map.json'};
    $add->('source-map artifact does not encode the returned source map',
        '/emission/source_map')
        unless $map_artifact && $map_artifact->{content} eq _pretty_json($source_map);
    my $manifest_artifact = $by_path{
        'backends/sv_portable_verilator/backend-manifest.json'};
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
        $_->{relpath} ne
            'backends/sv_portable_verilator/backend-manifest.json'
    } @$artifacts;
    $add->('portable-SystemVerilog manifest artifact closure changed',
        '/emission/backend_manifest/artifacts')
        unless _canonical_json($emission->{backend_manifest}{artifacts})
            eq _canonical_json(\@referenced);
}

sub _closed_result($value) {
    _exact_keys($value, \@RESULT_KEYS,
        'portable-SystemVerilog evaluation result');
    return _clone($value);
}

sub _selected_level($level) {
    confess "unknown portable-SystemVerilog level\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _legal_identifier($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
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
    confess "portable-SystemVerilog oracle contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
