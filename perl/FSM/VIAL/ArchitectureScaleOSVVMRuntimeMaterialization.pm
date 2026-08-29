package FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;
use FSM::VIAL::ArchitectureScaleWorkload;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_osvvm_runtime_materialization.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'vhdl_osvvm_qualified';
my $TOOL_PROFILE = 'osvvm_2026_05_ghdl_6_0_0_llvm_jit';
my $PRIMARY_AXIS = 'runtime_trace_records';
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my %MATERIALIZED = map { $_ => 1 } @LEVELS[0 .. 2];
my %EXPECTED = (
    reference_v1 => {
        operations => 21, source_bytes => 122_413, source_maps => 66,
        sources => _expected_sources(
            15_323,
            '2ba00d6481361b3e2d876ff3fffd63b6f5c07417717e4f53f4be24950e142bb3',
            46_262,
            'b327edab233200bc9b8ff1b8e6a22588505749f47363b7bc9c4a0380394f16b3',
        ),
    },
    gate_candidate_v1 => {
        operations => 21, source_bytes => 122_426, source_maps => 66,
        sources => _expected_sources(
            15_325,
            '25abc4e88f8426c092111709247046cdef0c1bd9e2eaadf02e8206b61c93c1e9',
            46_273,
            '4a1cc43d625ec6d352c63a6a0e9b2a2e56a3ae41ea26cf480c9979b21dee2513',
        ),
    },
    qualification_candidate_v1 => {
        operations => 21, source_bytes => 122_438, source_maps => 66,
        sources => _expected_sources(
            15_326,
            'c9da2684f6077c260d4b1650e1f29db126331af864b17f858cf47b04c7ee92da',
            46_284,
            '9e0f2f69389e5bd5e3264dc1aadd220d2bbfa9bf9f35360f2ba692f6ca662b10',
        ),
    },
);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity family backend_profile
    tool_profile level primary_axis workload_identity requested_counts
    source_identity stage_identities structural_equivalence schedule_oracle
    portable_authority emission_oracle trace_projection envelope_projection
    claims explicit_nonclaims diagnostics cleanup
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language full_osvvm native_uvm_runtime
    full_language synthesis general_cross_backend_parity runtime_executed
    trace_materialized result_produced support_claimed performance_budget
    capacity_claimed reached_record_boundary public_api_change
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {{backend_profile => $PROFILE, level => $_}} @LEVELS];
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $raw = _request('construct', \@args, [qw(repository_root level)]);
    my $repo_root = _repository_root($raw->{repository_root});
    _selected_level($raw->{level});
    return FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization
        ->_osvvm_runtime_construction({
            repository_root => $repo_root,
            level => $raw->{level},
        });
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    my $raw = _request('evaluate', \@args, [qw(repository_root level)]);
    my $repo_root = _repository_root($raw->{repository_root});
    _selected_level($raw->{level});
    return _evaluate($repo_root, $raw->{level});
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    my $raw = _request(
        'validate_report', \@args, [qw(repository_root report)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    _validate_report_shape($raw->{report});
    my $rebuilt = _evaluate($repo_root, $raw->{report}{level});
    confess "OSVVM runtime materialization report is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw->{report});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    my $raw = _request(
        'with_staging', \@args,
        [qw(repository_root level consumer)],
    );
    confess "OSVVM runtime materialization consumer must be one code reference\n"
        unless ref($raw->{consumer}) eq 'CODE';
    _selected_level($raw->{level});
    confess "preflight-dominated OSVVM runtime shapes cannot create staging\n"
        unless $MATERIALIZED{$raw->{level}};
    my $repo_root = _repository_root($raw->{repository_root});
    my $construction = $class->construct({
        repository_root => $repo_root, level => $raw->{level},
    });
    my $report = _evaluate($repo_root, $raw->{level});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        construction => $construction,
        repository_root => $repo_root,
        consumer => sub ($context) {
            $raw->{consumer}->({
                staging_root => $context->{staging_root},
                staging_identity => $context->{staging_identity},
                workload_identity => $construction->{workload_identity},
                report => _clone($report),
            });
        },
    });
}

sub _evaluate($repo_root, $level) {
    my $inputs =
        FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization
            ->_osvvm_runtime_route_inputs({
                repository_root => $repo_root, level => $level,
            });
    my $construction = $inputs->{construction};
    my $spec = $construction->{specification};
    my $portable = $inputs->{portable_report};
    confess "OSVVM runtime construction profile changed\n"
        unless ($spec->{backend_profile} // '') eq $PROFILE
            && ($spec->{tool_profile} // '') eq $TOOL_PROFILE;
    confess "OSVVM and portable runtime count authorities diverged\n"
        unless _canonical_json($spec->{requested_counts})
            eq _canonical_json($portable->{requested_counts});

    my $materialized = $MATERIALIZED{$level} ? 1 : 0;
    my $emission;
    if ($materialized) {
        my ($digest) = $inputs->{first_route}{execution_ir}->plan_id
            =~ m{\Aplan/([0-9a-f]{64})\z};
        confess "OSVVM runtime plan identity is invalid\n"
            unless defined $digest;
        my $artifact_root =
            ".artifacts/vial/base-output-arbitration/$digest";
        my $evaluated =
            FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM
                ->_runtime_evaluate({
                    level => $level,
                    first_route => $inputs->{first_route},
                    second_route => $inputs->{second_route},
                    artifact_root => $artifact_root,
                    expected => $EXPECTED{$level},
                });
        confess "OSVVM runtime artifact graph failed its exact oracle\n"
            if @{$evaluated->{diagnostics}};
        confess "OSVVM runtime artifact graph is nondeterministic\n"
            unless $evaluated->{byte_equal};
        $emission = $evaluated->{oracle};
    }

    my $report = {
        ok => JSON::PP::true,
        status => $materialized
            ? 'provider_structurally_qualified' : 'preflight_dominated',
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        family => $FAMILY,
        backend_profile => $PROFILE,
        tool_profile => $TOOL_PROFILE,
        level => $level,
        primary_axis => $PRIMARY_AXIS,
        workload_identity => $construction->{workload_identity},
        requested_counts => _clone($spec->{requested_counts}),
        source_identity => _clone($portable->{source_identity}),
        stage_identities => _clone($portable->{stage_identities}),
        structural_equivalence => _clone($portable->{structural_equivalence}),
        schedule_oracle => _clone($portable->{schedule_oracle}),
        portable_authority => {
            backend_profile => $portable->{backend_profile},
            report_identity => $portable->{report_identity},
            workload_identity => $portable->{workload_identity},
            source_identity => _clone($portable->{source_identity}),
            stage_identities => _clone($portable->{stage_identities}),
            artifact_graph_sha256 => $materialized
                ? $portable->{emission_oracle}{artifact_graph_sha256} : undef,
        },
        emission_oracle => _clone($emission),
        trace_projection => _clone($portable->{trace_projection}),
        envelope_projection => _clone($portable->{envelope_projection}),
        claims => _claims($materialized),
        explicit_nonclaims => [@NONCLAIMS],
        diagnostics => [],
        cleanup => {
            staging_created => JSON::PP::false,
            in_memory_only => JSON::PP::true,
            residue => [],
        },
    };
    _seal_report($report);
    return _clone($report);
}

sub _claims($materialized) {
    return {
        qualification_only => JSON::PP::true,
        canonical_sources_bound => JSON::PP::true,
        portable_semantic_authority_reused => $materialized
            ? JSON::PP::true : JSON::PP::false,
        ordinary_route_reconstructed => $materialized
            ? JSON::PP::true : JSON::PP::false,
        provider_materialization_verified => $materialized
            ? JSON::PP::true : JSON::PP::false,
        provider_verification_reused => $materialized
            ? JSON::PP::true : JSON::PP::false,
        advanced_adapter_emitted => $materialized
            ? JSON::PP::true : JSON::PP::false,
        artifact_graph_claimed => $materialized
            ? JSON::PP::true : JSON::PP::false,
        preflight_dominance_proved => $materialized
            ? JSON::PP::false : JSON::PP::true,
        external_tool_executed => JSON::PP::false,
        runtime_executed => JSON::PP::false,
        trace_materialized => JSON::PP::false,
        result_produced => JSON::PP::false,
        support_claimed => JSON::PP::false,
        performance_claimed => JSON::PP::false,
        capacity_claimed => JSON::PP::false,
        reached_record_boundary => JSON::PP::false,
        public_api_changed => JSON::PP::false,
    };
}

sub _expected_sources(
    $metadata_bytes, $metadata_sha256, $fixture_bytes, $fixture_sha256
) {
    my $base = 'backends/vhdl_osvvm_qualified/src';
    return [
        {
            relpath => "$base/fsmgen_vial_osvvm_adapter_pkg.vhd",
            bytes => 4_351,
            sha256 =>
                '1a547b8de38c072600a76497778758affab25ccd479c0c1dfce7f0e0579c9e94',
        },
        {
            relpath => "$base/portable/base_output_arbitration_metadata_pkg.vhd",
            bytes => $metadata_bytes, sha256 => $metadata_sha256,
        },
        {
            relpath => "$base/portable/base_output_arbitration_probe_adapter.vhd",
            bytes => 591,
            sha256 =>
                '7a7e3b4e81fd222e53e2098653fcf1131f1b58dbeba35698c1cfe67a4fab5b56',
        },
        {
            relpath => "$base/portable/base_output_arbitration_tb.vhd",
            bytes => $fixture_bytes, sha256 => $fixture_sha256,
        },
        {
            relpath => "$base/portable/dut/ahb_lite_subordinate.vhd",
            bytes => 47_670,
            sha256 =>
                '8d93b0ade4d9561d19fdd12ab10b4d8ba1a3dc06de9f911d1c0d8d1bf18518cf',
        },
        {
            relpath => "$base/portable/fsmgen_vial_runtime_pkg.vhd",
            bytes => 2_191,
            sha256 =>
                'de60b5cdbcf2bd2efd9e9ac28938782e3a0df22ca4d7a14183481700f687e1b2',
        },
        {
            relpath => "$base/portable/fsmgen_vial_types_pkg.vhd",
            bytes => 6_025,
            sha256 =>
                '3777706b911ce90c9a3b05107233ec925c1029b175932ed10f1b1a588fb3c08e',
        },
    ];
}

sub _repository_root($raw) {
    confess "repository_root must name one existing directory\n"
        unless defined($raw) && !ref($raw) && -d $raw && !-l $raw;
    return File::Spec->rel2abs($raw);
}

sub _seal_report($report) {
    my $projection = _clone($report);
    delete $projection->{report_identity};
    $report->{report_identity} = 'osvvm-runtime-materialization/'
        . sha256_hex(_canonical_json($projection));
    _validate_report_shape($report);
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS,
        'OSVVM runtime materialization report');
    confess "OSVVM runtime materialization report header is invalid\n"
        unless $report->{ok}
            && ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{tool_profile} // '') eq $TOOL_PROFILE
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS
            && ($report->{status} // '')
                =~ /\A(?:provider_structurally_qualified|preflight_dominated)\z/;
    _selected_level($report->{level});
    confess "OSVVM runtime report identity is invalid\n"
        unless ($report->{report_identity} // '')
            =~ m{\Aosvvm-runtime-materialization/[0-9a-f]{64}\z};
    confess "OSVVM runtime report diagnostics changed\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "OSVVM runtime report nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
}

sub _selected_level($level) {
    confess "OSVVM runtime materialization level is not selected\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
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
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value)
            && ($value->isa('JSON::PP::Boolean')
                || $value->isa('JSON::PP::BooleanBase'));
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "OSVVM runtime projection has an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
