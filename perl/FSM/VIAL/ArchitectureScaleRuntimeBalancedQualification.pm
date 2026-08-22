package FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification;

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
use FSM::VIAL::ArchitectureScaleBalancedPortableEmission;
use FSM::VIAL::ArchitectureScaleRuntimeStream;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_balanced_qualification_report.v1';
my $OWNERSHIP_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_balanced_ownership.v1';
my $STAGING_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_balanced_staging.v1';
my $RUNTIME = 'FSM::VIAL::ArchitectureScaleRuntimeStream';
my $BALANCED = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $BALANCED_EMISSION =
    'FSM::VIAL::ArchitectureScaleBalancedPortableEmission';
my $HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $HIAL_BYTES = 1_326;
my $HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $VIAL_SOURCE = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $VIAL_BYTES = 4_986;
my $VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';

my @PROFILES = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
);
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);
my @EVALUATE_KEYS = qw(reference_hial_text reference_vial_text);
my @VALIDATE_KEYS = qw(reference_hial_text reference_vial_text report);
my @STAGING_KEYS = qw(
    reference_hial_text reference_vial_text repository_root consumer
);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity rerun_identity
    source_identity ownership members oracle_applicability claims
    explicit_nonclaims diagnostics
);
my @SOURCE_KEYS = qw(relative_path bytes sha256);
my @OWNERSHIP_KEYS = qw(
    schema schema_version runtime_family runtime_profile_count
    runtime_level_count runtime_member_count balanced_family
    balanced_member_count total_member_count ownership_identity
);
my @MEMBER_KEYS = qw(
    member_id family backend_profile level construction_identity
    construction_sha256 report_sha256 report_identity rerun_identity
    applicability_sha256 claims_sha256 nonclaims_sha256 report
);
my @APPLICABILITY_KEYS = qw(
    stage status applicable_members completed_members deferred_members
    authority
);
my @CLAIM_KEYS = qw(
    qualification_only ownership_partition_closed all_members_constructed
    all_member_reports_qualified all_member_reruns_qualified
    checked_reference_sources_bound balanced_revision_2_structurally_emitted
    provider_accessed external_tool_executed compile_executed
    runtime_executed trace_materialized result_produced support_claimed
    performance_claimed capacity_claimed structural_boundary_reached
);
my @STAGING_RESULT_KEYS = qw(
    ok status schema schema_version runtime_workload_identity
    balanced_workload_identity same_volume removed diagnostics
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return _clone(_owned_shapes());
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@EVALUATE_KEYS,
        'runtime-balanced qualification evaluation');
    return _evaluate($args[0]);
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    confess __PACKAGE__ . "->validate_report expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@VALIDATE_KEYS,
        'runtime-balanced qualification report validation');
    _validate_report_shape($args[0]{report});
    my $rebuilt = _evaluate({
        reference_hial_text => $args[0]{reference_hial_text},
        reference_vial_text => $args[0]{reference_vial_text},
    });
    confess "runtime-balanced qualification report is not canonical\n"
        unless _canonical_json($rebuilt)
            eq _canonical_json($args[0]{report});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], \@STAGING_KEYS,
        'runtime-balanced qualification staging');
    confess "runtime-balanced staging consumer must be one code reference\n"
        unless ref($args[0]{consumer}) eq 'CODE';

    my $runtime = $RUNTIME->construct({
        backend_profile => 'sv_portable_verilator',
        level => 'reference_v1',
        reference_hial_text => $args[0]{reference_hial_text},
        reference_vial_text => $args[0]{reference_vial_text},
    });
    my $balanced = $BALANCED->construct({
        reference_hial_text => $args[0]{reference_hial_text},
        reference_vial_text => $args[0]{reference_vial_text},
    });
    my ($balanced_result, $consumer_diagnostic);
    my $runtime_result = $RUNTIME->with_staging({
        construction => $runtime,
        repository_root => $args[0]{repository_root},
        consumer => sub ($runtime_context) {
            $balanced_result = $BALANCED_EMISSION->with_staging({
                construction => $balanced,
                repository_root => $args[0]{repository_root},
                consumer => sub ($balanced_context) {
                    my $ok = eval {
                        $args[0]{consumer}->({
                            runtime => _clone_staging_context($runtime_context),
                            balanced =>
                                _clone_staging_context($balanced_context),
                        });
                        1;
                    };
                    return if $ok;
                    $consumer_diagnostic = _sanitized_consumer_diagnostic(
                        $@, $args[0]{repository_root},
                    );
                    die "unified staging consumer rejected\n";
                },
            });
            die "unified balanced staging rejected\n"
                unless $balanced_result->{ok};
        },
    });
    my $ok = $runtime_result->{ok}
        && defined($balanced_result) && $balanced_result->{ok};
    my $diagnostics = $ok ? [] : [
        $consumer_diagnostic // _nested_staging_diagnostic(
            $balanced_result, $runtime_result,
        ),
    ];
    return _staging_result({
        ok => $ok ? JSON::PP::true : JSON::PP::false,
        status => $ok ? 'consumed_unmeasured' : 'error',
        schema => $STAGING_SCHEMA,
        schema_version => 1,
        runtime_workload_identity => $runtime->{workload_identity},
        balanced_workload_identity =>
            $balanced->{workload}{workload_identity},
        same_volume => $ok ? JSON::PP::true : JSON::PP::false,
        removed => $ok ? JSON::PP::true : JSON::PP::false,
        diagnostics => $diagnostics,
    });
}

sub _evaluate($raw) {
    _validate_reference(
        $raw->{reference_hial_text}, $HIAL_BYTES, $HIAL_SHA256,
        'checked-AHB HIAL',
    );
    _validate_reference(
        $raw->{reference_vial_text}, $VIAL_BYTES, $VIAL_SHA256,
        'checked-AHB VIAL',
    );
    _assert_runtime_ownership();

    my @members;
    for my $profile (@PROFILES) {
        for my $level (@LEVELS) {
            my $construction = $RUNTIME->construct({
                backend_profile => $profile,
                level => $level,
                reference_hial_text => $raw->{reference_hial_text},
                reference_vial_text => $raw->{reference_vial_text},
            });
            my $report = $RUNTIME->evaluate({
                construction => $construction,
            });
            push @members, _member({
                family => 'runtime_stream_v1',
                backend_profile => $profile,
                level => $level,
                construction => $construction,
                construction_identity => $construction->{workload_identity},
                applicability => $report->{stage_expectations},
                report => $report,
            });
        }
    }

    my $balanced_construction = $BALANCED->construct({
        reference_hial_text => $raw->{reference_hial_text},
        reference_vial_text => $raw->{reference_vial_text},
    });
    my $balanced_report = $BALANCED_EMISSION->evaluate({
        construction => $balanced_construction,
    });
    push @members, _member({
        family => 'balanced_portable_v1',
        backend_profile => 'sv_portable_verilator',
        level => 'gate_candidate_v1',
        construction => $balanced_construction,
        construction_identity =>
            $balanced_construction->{workload}{workload_identity},
        applicability => $balanced_report->{oracle_applicability},
        report => $balanced_report,
    });

    my $ownership = _ownership();
    my $report = {
        ok => JSON::PP::true,
        status => 'provider_free_construction_qualified',
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => 'runtime-balanced-reruns/' . sha256_hex(
            _canonical_json([map {{
                member_id => $_->{member_id},
                construction_sha256 => $_->{construction_sha256},
                report_sha256 => $_->{report_sha256},
                rerun_identity => $_->{rerun_identity},
            }} @members]),
        ),
        source_identity => {
            hial => {
                relative_path => $HIAL_SOURCE,
                bytes => bytes::length($raw->{reference_hial_text}),
                sha256 => sha256_hex($raw->{reference_hial_text}),
            },
            vial => {
                relative_path => $VIAL_SOURCE,
                bytes => bytes::length($raw->{reference_vial_text}),
                sha256 => sha256_hex($raw->{reference_vial_text}),
            },
        },
        ownership => $ownership,
        members => \@members,
        oracle_applicability => _oracle_applicability(),
        claims => _claims(),
        explicit_nonclaims => [@NONCLAIMS],
        diagnostics => [],
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'runtime-balanced-qualification/'
        . sha256_hex(_canonical_json($identity_projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _member($raw) {
    my $report = $raw->{report};
    confess "runtime-balanced member report was rejected\n"
        unless ref($report) eq 'HASH' && $report->{ok}
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "runtime-balanced member nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    _validate_child_report($raw->{family}, $raw->{backend_profile},
        $raw->{level}, $raw->{construction_identity}, $report);
    return {
        member_id => join('/', @{$raw}{
            qw(family backend_profile level)}),
        family => $raw->{family},
        backend_profile => $raw->{backend_profile},
        level => $raw->{level},
        construction_identity => $raw->{construction_identity},
        construction_sha256 =>
            sha256_hex(_canonical_json($raw->{construction})),
        report_sha256 => sha256_hex(_canonical_json($report)),
        report_identity => $report->{report_identity},
        rerun_identity => $report->{rerun_identity},
        applicability_sha256 =>
            sha256_hex(_canonical_json($raw->{applicability})),
        claims_sha256 => sha256_hex(_canonical_json($report->{claims})),
        nonclaims_sha256 =>
            sha256_hex(_canonical_json($report->{explicit_nonclaims})),
        report => _clone($report),
    };
}

sub _validate_child_report($family, $profile, $level, $identity, $report) {
    my $authority = $family eq 'runtime_stream_v1'
        ? $RUNTIME : $BALANCED_EMISSION;
    _exact_keys($report, $authority->report_keys,
        "$family member report");
    confess "$family member workload identity changed\n"
        unless ($report->{workload_identity} // '') eq $identity;
    if ($family eq 'runtime_stream_v1') {
        confess "runtime member selection changed\n"
            unless ($report->{family} // '') eq $family
                && ($report->{backend_profile} // '') eq $profile
                && ($report->{level} // '') eq $level
                && ($report->{status} // '')
                    eq 'provider_free_runtime_inputs_constructed';
        confess "runtime member overclaims completed work\n"
            if $report->{claims}{provider_accessed}
                || $report->{claims}{external_tool_executed}
                || $report->{claims}{backend_artifacts_emitted}
                || $report->{claims}{runtime_executed}
                || $report->{claims}{trace_materialized}
                || $report->{claims}{result_materialized}
                || $report->{claims}{support_claimed}
                || $report->{claims}{performance_claimed}
                || $report->{claims}{capacity_claimed}
                || $report->{claims}{structural_boundary_reached};
        return;
    }
    confess "balanced member selection changed\n"
        unless $family eq 'balanced_portable_v1'
            && $profile eq 'sv_portable_verilator'
            && $level eq 'gate_candidate_v1'
            && ($report->{status} // '') eq 'structural_emission_qualified';
    confess "balanced member overclaims completed work\n"
        if $report->{claims}{external_tool_executed}
            || $report->{claims}{compile_executed}
            || $report->{claims}{runtime_executed}
            || $report->{claims}{trace_materialized}
            || $report->{claims}{result_produced}
            || $report->{claims}{support_claimed}
            || $report->{claims}{performance_claimed}
            || $report->{claims}{capacity_claimed};
    confess "balanced revision-2 structural emission is incomplete\n"
        unless $report->{claims}{exact_revision_2_negotiated}
            && $report->{claims}{structural_emission_qualified};
}

sub _owned_shapes() {
    my @owned = map {
        my $profile = $_;
        map {{
            family => 'runtime_stream_v1',
            backend_profile => $profile,
            level => $_,
        }} @LEVELS
    } @PROFILES;
    push @owned, {
        family => 'balanced_portable_v1',
        backend_profile => 'sv_portable_verilator',
        level => 'gate_candidate_v1',
    };
    return \@owned;
}

sub _assert_runtime_ownership() {
    my @expected = map {
        my $profile = $_;
        map {{backend_profile => $profile, level => $_}} @LEVELS
    } @PROFILES;
    confess "runtime-stream ownership partition changed\n"
        unless _canonical_json($RUNTIME->owned_shapes)
            eq _canonical_json(\@expected);
}

sub _ownership() {
    my $ownership = {
        schema => $OWNERSHIP_SCHEMA,
        schema_version => 1,
        runtime_family => 'runtime_stream_v1',
        runtime_profile_count => scalar(@PROFILES),
        runtime_level_count => scalar(@LEVELS),
        runtime_member_count => scalar(@PROFILES) * scalar(@LEVELS),
        balanced_family => 'balanced_portable_v1',
        balanced_member_count => 1,
        total_member_count => scalar(@{_owned_shapes()}),
        ownership_identity => undef,
    };
    my $projection = _clone($ownership);
    delete $projection->{ownership_identity};
    $ownership->{ownership_identity} = 'runtime-balanced-ownership/'
        . sha256_hex(_canonical_json({
            contract => $projection,
            members => _owned_shapes(),
        }));
    return $ownership;
}

sub _oracle_applicability() {
    my @rows = (
        [construct => 'completed', 16, 16, 0],
        [semantic => 'completed', 16, 16, 0],
        [bridge => 'completed', 16, 16, 0],
        [plan => 'completed', 16, 16, 0],
        [backend_inputs => 'completed', 16, 16, 0],
        [emit => 'family_partial', 16, 1, 15],
        [compile => 'not_run', 16, 0, 16],
        [runtime => 'not_run', 16, 0, 16],
        [trace => 'not_materialized', 16, 0, 16],
        [result => 'not_produced', 16, 0, 16],
        [failure => 'specified_not_observed', 15, 0, 15],
    );
    return [map {{
        stage => $_->[0],
        status => $_->[1],
        applicable_members => $_->[2],
        completed_members => $_->[3],
        deferred_members => $_->[4],
        authority => 'embedded_member_reports',
    }} @rows];
}

sub _claims() {
    return {
        qualification_only => JSON::PP::true,
        ownership_partition_closed => JSON::PP::true,
        all_members_constructed => JSON::PP::true,
        all_member_reports_qualified => JSON::PP::true,
        all_member_reruns_qualified => JSON::PP::true,
        checked_reference_sources_bound => JSON::PP::true,
        balanced_revision_2_structurally_emitted => JSON::PP::true,
        provider_accessed => JSON::PP::false,
        external_tool_executed => JSON::PP::false,
        compile_executed => JSON::PP::false,
        runtime_executed => JSON::PP::false,
        trace_materialized => JSON::PP::false,
        result_produced => JSON::PP::false,
        support_claimed => JSON::PP::false,
        performance_claimed => JSON::PP::false,
        capacity_claimed => JSON::PP::false,
        structural_boundary_reached => JSON::PP::false,
    };
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS, 'runtime-balanced report');
    confess "runtime-balanced report status is invalid\n"
        unless $report->{ok}
            && ($report->{status} // '')
                eq 'provider_free_construction_qualified'
            && ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1;
    _exact_keys($report->{source_identity}, [qw(hial vial)],
        'runtime-balanced source identity');
    _exact_keys($report->{source_identity}{hial}, \@SOURCE_KEYS,
        'runtime-balanced HIAL identity');
    _exact_keys($report->{source_identity}{vial}, \@SOURCE_KEYS,
        'runtime-balanced VIAL identity');
    my $expected_sources = {
        hial => {
            relative_path => $HIAL_SOURCE,
            bytes => $HIAL_BYTES,
            sha256 => $HIAL_SHA256,
        },
        vial => {
            relative_path => $VIAL_SOURCE,
            bytes => $VIAL_BYTES,
            sha256 => $VIAL_SHA256,
        },
    };
    confess "runtime-balanced source identity changed\n"
        unless _canonical_json($report->{source_identity})
            eq _canonical_json($expected_sources);

    _exact_keys($report->{ownership}, \@OWNERSHIP_KEYS,
        'runtime-balanced ownership');
    confess "runtime-balanced ownership changed\n"
        unless _canonical_json($report->{ownership})
            eq _canonical_json(_ownership());
    confess "runtime-balanced members must be one array\n"
        unless ref($report->{members}) eq 'ARRAY';
    my $owned = _owned_shapes();
    confess "runtime-balanced member count changed\n"
        unless @{$report->{members}} == @$owned;
    for my $index (0 .. $#$owned) {
        my $member = $report->{members}[$index];
        my $shape = $owned->[$index];
        _exact_keys($member, \@MEMBER_KEYS,
            "runtime-balanced member $index");
        my $member_id = join('/', @{$shape}{
            qw(family backend_profile level)});
        confess "runtime-balanced member order changed\n"
            unless ($member->{member_id} // '') eq $member_id
                && ($member->{family} // '') eq $shape->{family}
                && ($member->{backend_profile} // '')
                    eq $shape->{backend_profile}
                && ($member->{level} // '') eq $shape->{level};
        _validate_child_report(
            @{$shape}{qw(family backend_profile level)},
            $member->{construction_identity}, $member->{report},
        );
        confess "runtime-balanced member report digest changed\n"
            unless ($member->{report_sha256} // '')
                eq sha256_hex(_canonical_json($member->{report}));
        confess "runtime-balanced member report authority changed\n"
            unless ($member->{report_identity} // '')
                    eq ($member->{report}{report_identity} // '')
                && ($member->{rerun_identity} // '')
                    eq ($member->{report}{rerun_identity} // '');
        my $applicability = $shape->{family} eq 'runtime_stream_v1'
            ? $member->{report}{stage_expectations}
            : $member->{report}{oracle_applicability};
        confess "runtime-balanced member applicability changed\n"
            unless ($member->{applicability_sha256} // '')
                eq sha256_hex(_canonical_json($applicability));
        confess "runtime-balanced member claims changed\n"
            unless ($member->{claims_sha256} // '')
                eq sha256_hex(_canonical_json($member->{report}{claims}));
        confess "runtime-balanced member nonclaims changed\n"
            unless ($member->{nonclaims_sha256} // '')
                eq sha256_hex(
                    _canonical_json($member->{report}{explicit_nonclaims}));
        confess "runtime-balanced member construction identity is invalid\n"
            unless ($member->{construction_identity} // '')
                    =~ m{\Aworkload/[0-9a-f]{64}\z}
                && ($member->{construction_sha256} // '')
                    =~ /\A[0-9a-f]{64}\z/;
    }

    confess "runtime-balanced oracle applicability must be one array\n"
        unless ref($report->{oracle_applicability}) eq 'ARRAY';
    _exact_keys($_, \@APPLICABILITY_KEYS,
        'runtime-balanced oracle applicability')
        for @{$report->{oracle_applicability}};
    confess "runtime-balanced oracle applicability changed\n"
        unless _canonical_json($report->{oracle_applicability})
            eq _canonical_json(_oracle_applicability());
    _exact_keys($report->{claims}, \@CLAIM_KEYS,
        'runtime-balanced claims');
    confess "runtime-balanced claim boundary changed\n"
        unless _canonical_json($report->{claims})
            eq _canonical_json(_claims());
    confess "runtime-balanced explicit nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "runtime-balanced diagnostics must be an empty array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};

    my $rerun = 'runtime-balanced-reruns/' . sha256_hex(
        _canonical_json([map {{
            member_id => $_->{member_id},
            construction_sha256 => $_->{construction_sha256},
            report_sha256 => $_->{report_sha256},
            rerun_identity => $_->{rerun_identity},
        }} @{$report->{members}}]),
    );
    confess "runtime-balanced rerun identity is invalid\n"
        unless ($report->{rerun_identity} // '') eq $rerun;
    my $projection = _clone($report);
    my $identity = delete $projection->{report_identity};
    confess "runtime-balanced report identity is invalid\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'runtime-balanced-qualification/'
                . sha256_hex(_canonical_json($projection));
}

sub _validate_reference($text, $bytes, $sha256, $label) {
    confess "$label must be scalar source text\n"
        unless defined($text) && !ref($text);
    confess "$label byte length changed\n"
        unless bytes::length($text) == $bytes;
    confess "$label SHA-256 changed\n"
        unless sha256_hex($text) eq $sha256;
}

sub _clone_staging_context($context) {
    return {
        staging_identity => $context->{staging_identity},
        staging_root => $context->{staging_root},
        inputs => [map {{%$_}} @{$context->{inputs}}],
    };
}

sub _sanitized_consumer_diagnostic($error, $repository_root) {
    my $message = defined($error) && !ref($error) ? $error
        : 'unified staging consumer rejected';
    $message =~ s/[\r\n]+\z//;
    $message =~ s{\Q$repository_root\E}{<repo>}g
        if defined($repository_root) && !ref($repository_root)
            && length($repository_root);
    $message = 'unified staging consumer rejected' unless length($message);
    return {
        code => 'VIAL_SCALE_UNIFIED_CONSUMER_ERROR',
        severity => 'error',
        message => $message,
        path => '/consumer',
    };
}

sub _nested_staging_diagnostic($balanced_result, $runtime_result) {
    my $source = defined($balanced_result) && !$balanced_result->{ok}
        ? $balanced_result : $runtime_result;
    my $message = ref($source->{diagnostics}) eq 'ARRAY'
            && ref($source->{diagnostics}[0]) eq 'HASH'
        ? $source->{diagnostics}[0]{message}
        : 'unified nested staging rejected';
    return {
        code => 'VIAL_SCALE_UNIFIED_STAGING_ERROR',
        severity => 'error',
        message => $message,
        path => '/staging',
    };
}

sub _staging_result($result) {
    _exact_keys($result, \@STAGING_RESULT_KEYS,
        'runtime-balanced staging result');
    return _clone($result);
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
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "runtime-balanced qualification contains unsupported data\n"
        if ref($value);
    return $value;
}

1;
