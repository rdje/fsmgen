package FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;

my $JSON = JSON::PP->new->canonical(1);
my $SCHEMA = 'fsmgen.vial_architecture_scale_osvvm_runtime_execution_plan.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'vhdl_osvvm_qualified';
my $TOOL_PROFILE = 'osvvm_2026_05_ghdl_6_0_0_llvm_jit';
my $GALLERY =
    'vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services';
my $GHDL_ROOT =
    '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64';
my $GHDL_ARCHIVE =
    '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-archive/ghdl-llvm-jit-6.0.0-macos15-aarch64.tar.gz';
my $GHDL_BINARY = "$GHDL_ROOT/bin/ghdl";
my $OSVVM_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $PROBE =
    'vial/qualification/vhdl_osvvm_ghdl/osvvm_2026_05_runtime_probe.vhd';
my $CHECKED_REPORT =
    'vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json';
my $ARCHIVE_BYTES = 37_155_806;
my $ARCHIVE_SHA256 =
    'c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769';
my $BINARY_SHA256 =
    '38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d';
my $CHECKED_REPORT_SHA256 =
    'e83c1a346c31cde5b516e1b6d19696f0c63e05902a31f945f011f23e2268f1fa';
my $CHECKED_QUALIFICATION_ID =
    'qualification/67e01b077b3f74c358631262cbf7d76f95bdda83d0855b62dee2d90cd0d8e605';
my $VERSION_OUTPUT = join("\n",
    'GHDL 6.0.0 (6.0.0.r0.ge589c698c) [Dunoon edition]',
    ' Compiled with GNAT Version: 14.2.0',
    ' static elaboration, LLVM JIT code generator',
    'Written by Tristan Gingold.',
    '',
    'Copyright (C) 2003 - 2026 Tristan Gingold.',
    'GHDL is free software, covered by the GNU General Public License.  There is NO',
    'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.');

my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my @GENERATED_SUFFIX = qw(
    portable/fsmgen_vial_types_pkg.vhd
    portable/fsmgen_vial_runtime_pkg.vhd
    portable/base_output_arbitration_metadata_pkg.vhd
    portable/dut/ahb_lite_subordinate.vhd
    portable/base_output_arbitration_tb.vhd
    portable/base_output_arbitration_probe_adapter.vhd
    fsmgen_vial_osvvm_adapter_pkg.vhd
);
my @OSVVM_SOURCE = qw(
    IfElsePkg.vhd
    OsvvmTypesPkg.vhd
    OsvvmScriptSettingsPkg.vhd
    OsvvmSettingsPkg.vhd
    __FSMGEN_GENERATED_SETTINGS__
    OsvvmSettingsPkg_default.vhd
    TextUtilPkg.vhd
    FileUtilPkg.vhd
    ResolutionPkg.vhd
    NamePkg.vhd
    OsvvmGlobalPkg.vhd
    CoverageVendorApiPkg_default.vhd
    TranscriptPkg.vhd
    deprecated/LanguageSupport2019Pkg_c.vhd
    deprecated/FileLinePathPkg_c.vhd
    deprecated/AssertApiPkg_c.vhd
    AlertLogPkg.vhd
    IdFifoPtPkg.vhd
    TbUtilPkg.vhd
    NameStorePkg.vhd
    MessageListPkg.vhd
    SortListPkg_int.vhd
    RandomBasePkg.vhd
    RandomPkg.vhd
    RandomProcedurePkg.vhd
    CoveragePkg.vhd
    CoveragePtPkg.vhd
    DelayCoveragePkg.vhd
    ClockResetPkg.vhd
    ResizePkg.vhd
    deprecated/DynamicVectorPkg_IntV_c.vhd
    deprecated/DynamicVectorPkg_slv_c.vhd
    ScoreboardGenericPkg.vhd
    ScoreboardPkg_IntV.vhd
    ScoreboardPkg_slv.vhd
    ScoreboardPkg_int.vhd
    ScoreboardPkg_signed.vhd
    ScoreboardPkg_unsigned.vhd
    MemorySupportPkg.vhd
    MemoryGenericPkg.vhd
    MemoryPkg.vhd
    ReportPkg.vhd
    deprecated/RandomPkg2019_c.vhd
    OsvvmContext.vhd
);
my @COMMON_SOURCE = qw(
    ModelParametersPtPkg.vhd
    ModelParametersSingletonPkg.vhd
    FifoFillPkg_slv.vhd
    deprecated/StreamTransactionPkg.vhd
    deprecated/StreamTransactionArrayPkg.vhd
    deprecated/AddressBusTransactionPkg.vhd
    deprecated/AddressBusTransactionArrayPkg.vhd
    deprecated/AddressBusResponderTransactionPkg.vhd
    deprecated/AddressBusResponderTransactionArrayPkg.vhd
    AddressBusVersionCompatibilityPkg.vhd
    InterruptGlobalSignalPkg.vhd
    deprecated/InterruptHandler_c.vhd
    deprecated/InterruptHandlerComponentPkg_c.vhd
    InterruptGeneratorBit.vhd
    InterruptGeneratorBitVti.vhd
    InterruptGeneratorComponentPkg.vhd
    OsvvmCommonContext.vhd
);
my @PROVIDER_REPORT = qw(
    OsvvmRun.yml
    AlertLogTop_alerts.yml
    AlertLogTop_cov.yml
    AlertLogTop_sb_slv.yml
);
my @REPORT_KEYS = qw(
    ok status schema schema_version plan_identity family backend_profile
    tool_profile level materialization_identity workload_identity
    provider_authority tool_authority source_authority storage_authority
    generated_settings libraries commands report_inventory resource_controls
    qualifier_oracle claims explicit_nonclaims diagnostics cleanup
);
my @NONCLAIMS = qw(
    external_tool_executed provider_compiled generated_sources_analyzed
    fixture_elaborated fixture_executed provider_probe_elaborated
    provider_probe_executed trace_materialized result_produced
    performance_measured capacity_claimed reached_record_boundary
    support_claimed provider_generality mixed_language public_api_change
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {{backend_profile => $PROFILE, level => $_}} @LEVELS];
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
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
    confess "OSVVM/GHDL execution-plan report is not canonical\n"
        unless _canonical($rebuilt) eq _canonical($raw->{report});
    return _clone($rebuilt);
}

# The checked qualifier consumes this single source-order authority. The seam
# is deliberately unavailable to tests, callers, subclasses, or lifecycle
# code; the provider-aware lifecycle will receive its own sealed admission in
# the next ordered task.
sub _qualification_authority($class) {
    _exact_invocant($class, '_qualification_authority');
    confess "OSVVM/GHDL qualification authority is caller-sealed\n"
        unless (scalar caller) eq
            'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification';
    return {
        ghdl_root => $GHDL_ROOT,
        ghdl_archive => $GHDL_ARCHIVE,
        ghdl_binary => $GHDL_BINARY,
        osvvm_root => $OSVVM_ROOT,
        archive_bytes => $ARCHIVE_BYTES,
        archive_sha256 => $ARCHIVE_SHA256,
        binary_sha256 => $BINARY_SHA256,
        version_output => $VERSION_OUTPUT,
        generated_source => [
            (map { "$GALLERY/src/$_" } @GENERATED_SUFFIX), $PROBE,
        ],
        osvvm_source => [@OSVVM_SOURCE],
        common_source => [@COMMON_SOURCE],
        provider_report => [@PROVIDER_REPORT],
    };
}

sub _qualification_plan($class, @args) {
    _exact_invocant($class, '_qualification_plan');
    confess "OSVVM/GHDL qualification plan is caller-sealed\n"
        unless (scalar caller) eq
            'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification';
    my $raw = _request(
        '_qualification_plan', \@args, [qw(staging_identity)],
    );
    confess "OSVVM/GHDL qualification staging identity is not exact\n"
        unless defined($raw->{staging_identity})
            && !ref($raw->{staging_identity})
            && $raw->{staging_identity} =~
                m{\A[.]artifacts/tmp/vial-osvvm-ghdl-qualification/[0-9a-f]{64}\z};
    return _instantiated_plan(
        $raw->{staging_identity},
        [(map { "$GALLERY/src/$_" } @GENERATED_SUFFIX), $PROBE],
    );
}

# The measurement adapter already holds one independently rebuilt canonical
# plan report.  This seam relocates that closed authority into the exact outer
# controller record without rerunning provider verification in tool stages.
sub _measurement_plan($class, @args) {
    _exact_invocant($class, '_measurement_plan');
    confess "OSVVM/GHDL measurement plan is caller-sealed\n"
        unless (scalar caller) eq
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement';
    my $raw = _request(
        '_measurement_plan', \@args,
        [qw(level staging_identity canonical_plan generated_source_set)],
    );
    _selected_level($raw->{level});
    my $stage = $raw->{staging_identity};
    confess "OSVVM/GHDL measurement staging identity is not exact\n"
        unless defined($stage) && !ref($stage)
            && $stage =~ m{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/(?:validation|gate_measurement|qualification_measurement)/[0-9]{2}/lifecycle\z};

    my $canonical = $raw->{canonical_plan};
    _validate_report_shape($canonical);
    confess "OSVVM/GHDL measurement plan level changed\n"
        unless $canonical->{level} eq $raw->{level};
    my $generated = $raw->{generated_source_set};
    confess "OSVVM/GHDL measurement generated source set is not exact\n"
        unless ref($generated) eq 'ARRAY'
            && @$generated == @GENERATED_SUFFIX;
    my $expected = $canonical->{source_authority}{generated_sources};
    (my $controller_stage = $stage) =~ s{/lifecycle\z}{};
    for my $index (0 .. $#GENERATED_SUFFIX) {
        my $actual = $generated->[$index];
        _exact_keys($actual, [qw(relpath bytes sha256)],
            "OSVVM/GHDL measurement generated source $index");
        my $source_artifact = $expected->[$index]{source_artifact_relpath};
        confess "OSVVM/GHDL measurement generated source identity changed\n"
            unless $actual->{relpath} eq
                    "$controller_stage/outputs/emit/source-graph/$source_artifact"
                && $actual->{bytes} == $expected->[$index]{bytes}
                && $actual->{sha256} eq $expected->[$index]{sha256};
    }

    my $probe = $canonical->{source_authority}{provider_probe};
    my @analysis_source = (
        (map { $_->{relpath} } @$generated), $probe->{relpath},
    );
    my $instantiated = _instantiated_plan($stage, \@analysis_source);
    my $actual_records = _command_records(
        $stage, $instantiated->{commands},
    );
    my $canonical_stage =
        $canonical->{storage_authority}{staging_identity};
    my %relocated_source = map {
        $generated->[$_]{relpath} => $expected->[$_]{relpath}
    } 0 .. $#GENERATED_SUFFIX;
    for my $name (sort keys %$actual_records) {
        my @actual = $name eq 'provider_analyze'
            ? @{$actual_records->{$name}} : ($actual_records->{$name});
        my @sealed = $name eq 'provider_analyze'
            ? @{$canonical->{commands}{$name}}
            : ($canonical->{commands}{$name});
        confess "OSVVM/GHDL normalized command cardinality changed\n"
            unless @actual == @sealed;
        for my $index (0 .. $#actual) {
            my $actual_argv = _clone($actual[$index]{argv});
            for my $argument (@$actual_argv) {
                $argument = $relocated_source{$argument}
                    if exists $relocated_source{$argument};
                $argument =~ s/\Q$stage\E/$canonical_stage/g;
            }
            confess "OSVVM/GHDL normalized command authority changed\n"
                unless _canonical($actual_argv)
                        eq _canonical($sealed[$index]{argv})
                    && $actual[$index]{timeout_seconds}
                        == $sealed[$index]{timeout_seconds}
                    && $actual[$index]{capture_limit_bytes}
                        == $sealed[$index]{capture_limit_bytes}
                    && $actual[$index]{working_directory}
                        eq $sealed[$index]{working_directory}
                    && $actual[$index]{command_sha256}
                        eq sha256_hex(_canonical($actual[$index]{argv}))
                    && $sealed[$index]{command_sha256}
                        eq sha256_hex(_canonical($sealed[$index]{argv}));
        }
    }

    my $canonical_settings = $canonical->{generated_settings}{relpath};
    my @provider_source = grep {
        $_->{relpath} ne $canonical_settings
    } @{$canonical->{provider_authority}{provider_sources}};
    my @source_set = (
        (map {{
            relpath => $_->{relpath}, bytes => 0 + $_->{bytes},
            sha256 => $_->{sha256},
        }} @provider_source),
        (map { _clone($_) } @$generated),
        {
            relpath => $probe->{relpath}, bytes => 0 + $probe->{bytes},
            sha256 => $probe->{sha256},
        },
    );
    confess "OSVVM/GHDL measurement lifecycle source count changed\n"
        unless @source_set == 68;
    my $tool = $canonical->{tool_authority};
    my $commands = {
        schema => 'fsmgen.vial_ghdl_lifecycle_osvvm_command_plan.v2',
        schema_version => 2,
        version => _clone($instantiated->{commands}{version}),
        provider_analyze =>
            _clone($instantiated->{commands}{provider_analyze}),
        analyze_generated =>
            _clone($instantiated->{commands}{analyze_generated}),
        elaborate_fixture =>
            _clone($instantiated->{commands}{elaborate_fixture}),
        elaborate_provider_probe =>
            _clone($instantiated->{commands}{elaborate_provider_probe}),
        run_fixture => _clone($instantiated->{commands}{run_fixture}),
        run_provider_probe =>
            _clone($instantiated->{commands}{run_provider_probe}),
        generated_settings => {
            relpath => $instantiated->{generated_settings_relpath},
            content => $instantiated->{generated_settings_content},
            bytes => bytes::length(
                $instantiated->{generated_settings_content},
            ),
            sha256 => sha256_hex(
                $instantiated->{generated_settings_content},
            ),
        },
        libraries => _clone($instantiated->{libraries}),
        provider_reports => [map {{
            name => $_, relpath => "$stage/provider_reports/$_",
        }} @PROVIDER_REPORT],
        resource_controls => _resource_controls(),
    };
    return {
        plan_identity => $canonical->{plan_identity},
        provider_authority => _clone($canonical->{provider_authority}),
        provider => {
            root => $tool->{root},
            archive => $tool->{archive}{relpath},
            archive_bytes => 0 + $tool->{archive}{bytes},
            archive_sha256 => $tool->{archive}{sha256},
            binary => $tool->{binary}{relpath},
            binary_sha256 => $tool->{binary}{sha256},
            version_output => $tool->{version_output},
        },
        source_set => \@source_set,
        source_identity =>
            'source/' . sha256_hex(_canonical(\@source_set)),
        commands => $commands,
    };
}

sub _evaluate($repo_root, $level) {
    my $materialization =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization->evaluate({
            repository_root => $repo_root, level => $level,
        });
    confess "OSVVM runtime execution plan requires a materialized graph\n"
        unless ($materialization->{status} // '')
            eq 'provider_structurally_qualified'
            && $materialization->{emission_oracle};

    my @root_stat = stat($repo_root);
    confess "repository filesystem identity is unavailable\n" unless @root_stat;
    my $archive = _file_identity(
        $repo_root, $GHDL_ARCHIVE, $root_stat[0], 0,
    );
    my $binary = _file_identity(
        $repo_root, $GHDL_BINARY, $root_stat[0], 1,
    );
    confess "qualified GHDL archive identity changed\n"
        unless $archive->{bytes} == $ARCHIVE_BYTES
            && $archive->{sha256} eq $ARCHIVE_SHA256;
    confess "qualified GHDL binary identity changed\n"
        unless $binary->{sha256} eq $BINARY_SHA256;

    my $emission = $materialization->{emission_oracle};
    my $stage_seed = sha256_hex(_canonical({
        materialization_identity => $materialization->{report_identity},
        provider_manifest_sha256 => $emission->{provider_manifest_sha256},
        tool_binary_sha256 => $BINARY_SHA256,
    }));
    my $stage = ".artifacts/tmp/vial-osvvm-ghdl-plan/$stage_seed";

    my %emitted_by_suffix;
    for my $entry (@{$emission->{source_identities}}) {
        my ($suffix) = ($entry->{relpath} // '') =~
            m{\Abackends/vhdl_osvvm_qualified/src/(.+)\z};
        confess "OSVVM emitted source path is outside its exact root\n"
            unless defined $suffix;
        $emitted_by_suffix{$suffix} = $entry;
    }
    my @generated;
    for my $suffix (@GENERATED_SUFFIX) {
        my $entry = $emitted_by_suffix{$suffix};
        confess "OSVVM execution plan omitted generated source '$suffix'\n"
            unless $entry;
        push @generated, {
            relpath => "$stage/generated/$suffix",
            source_artifact_relpath => $entry->{relpath},
            bytes => 0 + $entry->{bytes},
            sha256 => $entry->{sha256},
        };
    }
    confess "OSVVM execution plan retained an unowned generated source\n"
        unless keys(%emitted_by_suffix) == @GENERATED_SUFFIX;
    my $probe = _file_identity($repo_root, $PROBE, $root_stat[0], 0);
    my @analysis_source = ((map { $_->{relpath} } @generated), $PROBE);
    my $instantiated = _instantiated_plan($stage, \@analysis_source);
    my $settings = {
        relpath => $instantiated->{generated_settings_relpath},
        bytes => bytes::length($instantiated->{generated_settings_content}),
        sha256 => sha256_hex($instantiated->{generated_settings_content}),
        content => $instantiated->{generated_settings_content},
    };

    my @provider_source = _provider_source_identities(
        $repo_root, $root_stat[0], $settings,
    );
    my $checked = _checked_oracle($repo_root, $root_stat[0]);
    my $report = {
        ok => JSON::PP::true,
        status => 'closed_not_executed',
        schema => $SCHEMA,
        schema_version => 1,
        plan_identity => undef,
        family => $FAMILY,
        backend_profile => $PROFILE,
        tool_profile => $TOOL_PROFILE,
        level => $level,
        materialization_identity => $materialization->{report_identity},
        workload_identity => $materialization->{workload_identity},
        provider_authority => {
            provider => 'OSVVM',
            version => '2026.05',
            dependency_root => $OSVVM_ROOT,
            root_commit => $emission->{provider_root_commit},
            root_tree => $emission->{provider_root_tree},
            materialization_manifest_sha256 =>
                $emission->{provider_manifest_sha256},
            provider_sources => \@provider_source,
            provider_source_identity =>
                'source/' . sha256_hex(_canonical(\@provider_source)),
        },
        tool_authority => {
            tool_name => 'ghdl',
            qualified_version => '6.0.0',
            backend => 'llvm_jit',
            language_standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            root => $GHDL_ROOT,
            archive => $archive,
            binary => $binary,
            version_output => $VERSION_OUTPUT,
        },
        source_authority => {
            generated_sources => \@generated,
            provider_probe => $probe,
            ordered_analysis_relpaths => \@analysis_source,
            source_identity => 'source/' . sha256_hex(_canonical({
                generated_sources => \@generated,
                provider_probe => $probe,
            })),
            artifact_graph_sha256 => $emission->{artifact_graph_sha256},
        },
        storage_authority => {
            staging_identity => $stage,
            generated_source_root => "$stage/generated",
            libraries_root => "$stage/libraries",
            reports_root => "$stage/provider_reports",
            same_volume_required => JSON::PP::true,
            provider_read_only => JSON::PP::true,
        },
        generated_settings => $settings,
        libraries => _clone($instantiated->{libraries}),
        commands => _command_records($stage, $instantiated->{commands}),
        report_inventory => [map {{
            name => $_, relpath => "$stage/provider_reports/$_",
        }} @PROVIDER_REPORT],
        resource_controls => _resource_controls(),
        qualifier_oracle => $checked,
        claims => {
            qualification_only => JSON::PP::true,
            canonical_materialization_bound => JSON::PP::true,
            provider_sources_sealed => JSON::PP::true,
            generated_sources_sealed => JSON::PP::true,
            tool_sealed => JSON::PP::true,
            commands_sealed => JSON::PP::true,
            checked_qualifier_is_oracle => JSON::PP::true,
            external_tool_executed => JSON::PP::false,
            staging_created => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            public_api_changed => JSON::PP::false,
        },
        explicit_nonclaims => [@NONCLAIMS],
        diagnostics => [],
        cleanup => {
            staging_created => JSON::PP::false,
            in_memory_only => JSON::PP::true,
            residue => [],
        },
    };
    my $projection = _clone($report);
    delete $projection->{plan_identity};
    $report->{plan_identity} =
        'osvvm-ghdl-execution-plan/' . sha256_hex(_canonical($projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _instantiated_plan($stage, $analysis_source) {
    my $libraries = {
        root => "$stage/libraries",
        osvvm => "$stage/libraries/osvvm/v08",
        osvvm_common => "$stage/libraries/osvvm_common/v08",
        fsmgen_vial => "$stage/libraries/fsmgen_vial/v08",
    };
    my $reports = "$stage/provider_reports";
    my $settings = "$stage/OsvvmScriptSettingsPkg_generated.vhd";
    my @provider;
    for my $source (@OSVVM_SOURCE) {
        my $resolved = $source eq '__FSMGEN_GENERATED_SETTINGS__'
            ? $settings : "$OSVVM_ROOT/osvvm/$source";
        push @provider, [
            $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=osvvm', "--workdir=$libraries->{osvvm}",
            "-P$libraries->{root}", $resolved,
        ];
    }
    for my $source (@COMMON_SOURCE) {
        push @provider, [
            $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=osvvm_common', "--workdir=$libraries->{osvvm_common}",
            "-P$libraries->{root}", "$OSVVM_ROOT/Common/src/$source",
        ];
    }
    my @prefix = (
        $GHDL_BINARY, '--std=08', '--work=fsmgen_vial',
        "--workdir=$libraries->{fsmgen_vial}", "-P$libraries->{root}",
    );
    return {
        generated_settings_relpath => $settings,
        generated_settings_content => _settings_body($stage, $reports),
        libraries => $libraries,
        resource_controls => _resource_controls(),
        commands => {
            version => [$GHDL_BINARY, '--version'],
            provider_analyze => \@provider,
            analyze_generated => [
                $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
                '--work=fsmgen_vial', "--workdir=$libraries->{fsmgen_vial}",
                "-P$libraries->{root}", @$analysis_source,
            ],
            elaborate_fixture => [
                $GHDL_BINARY, '-e', @prefix[1 .. $#prefix],
                'base_output_arbitration_tb',
            ],
            run_fixture => [
                $GHDL_BINARY, '-r', @prefix[1 .. $#prefix],
                'base_output_arbitration_tb', '--assert-level=error',
            ],
            elaborate_provider_probe => [
                $GHDL_BINARY, '-e', @prefix[1 .. $#prefix],
                'fsmgen_vial_osvvm_runtime_probe',
            ],
            run_provider_probe => [
                $GHDL_BINARY, '-r', @prefix[1 .. $#prefix],
                'fsmgen_vial_osvvm_runtime_probe', '--assert-level=error',
            ],
        },
    };
}

sub _command_records($stage, $commands) {
    my $resource = _resource_controls();
    my %policy = (
        version => [
            $resource->{version_timeout_seconds},
            $resource->{version_capture_limit_bytes},
        ],
        provider_analyze => [
            $resource->{provider_analysis_timeout_seconds_per_source},
            $resource->{provider_capture_limit_bytes},
        ],
        analyze_generated => [
            $resource->{generated_analysis_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
        ],
        elaborate_fixture => [
            $resource->{elaboration_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
        ],
        run_fixture => [
            $resource->{execution_timeout_seconds},
            $resource->{fixture_capture_limit_bytes},
        ],
        elaborate_provider_probe => [
            $resource->{elaboration_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
        ],
        run_provider_probe => [
            $resource->{execution_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
        ],
    );
    my %record;
    for my $name (sort keys %$commands) {
        my @argvs = $name eq 'provider_analyze'
            ? @{$commands->{$name}} : ($commands->{$name});
        my @entry = map {
            my $normalized = _clone($_);
            s/\Q$stage\E/<operation-stage>/g for @$normalized;
            {
                argv => _clone($_),
                command_sha256 => sha256_hex(_canonical($_)),
                normalized_command_sha256 => sha256_hex(_canonical($normalized)),
                timeout_seconds => $policy{$name}[0],
                capture_limit_bytes => $policy{$name}[1],
                working_directory => '.',
            }
        } @argvs;
        $record{$name} = $name eq 'provider_analyze' ? \@entry : $entry[0];
    }
    return \%record;
}

sub _resource_controls() {
    return {
        outer_guard =>
            'scripts/run_with_ram_guard.sh --process-max-rss-mb 4096',
        descendant_rss_limit_mib => 4_096,
        host_occupied_cutoff_percent => 88,
        version_timeout_seconds => 10,
        provider_analysis_timeout_seconds_per_source => 120,
        generated_analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        execution_timeout_seconds => 30,
        version_capture_limit_bytes => 65_536,
        provider_capture_limit_bytes => 8_388_608,
        fixture_capture_limit_bytes => 67_108_864,
    };
}

sub _provider_source_identities($repo_root, $root_device, $settings) {
    my @source;
    for my $name (@OSVVM_SOURCE) {
        if ($name eq '__FSMGEN_GENERATED_SETTINGS__') {
            push @source, _clone($settings);
            next;
        }
        push @source, _file_identity(
            $repo_root, "$OSVVM_ROOT/osvvm/$name", $root_device, 0,
        );
    }
    push @source, map {
        _file_identity(
            $repo_root, "$OSVVM_ROOT/Common/src/$_", $root_device, 0,
        )
    } @COMMON_SOURCE;
    return @source;
}

sub _checked_oracle($repo_root, $root_device) {
    my $identity = _file_identity(
        $repo_root, $CHECKED_REPORT, $root_device, 0,
    );
    confess "checked OSVVM/GHDL qualifier report identity changed\n"
        unless $identity->{sha256} eq $CHECKED_REPORT_SHA256;
    my $content = _slurp(_repo_path($repo_root, $CHECKED_REPORT));
    my $checked = eval { $JSON->decode($content) };
    confess "checked OSVVM/GHDL qualifier report is malformed\n"
        unless defined($checked) && !$@ && ref($checked) eq 'HASH'
            && !blessed($checked);
    confess "checked OSVVM/GHDL qualifier identity changed\n"
        unless ($checked->{qualification_id} // '') eq $CHECKED_QUALIFICATION_ID;
    confess "checked qualifier provider source order changed\n"
        unless _canonical($checked->{provider_compilation}{osvvm_source_order})
                eq _canonical(\@OSVVM_SOURCE)
            && _canonical($checked->{provider_compilation}{common_source_order})
                eq _canonical(\@COMMON_SOURCE);
    my $stage = $checked->{cleanup}{staging_identity};
    my $expected = _instantiated_plan(
        $stage, [(map { "$GALLERY/src/$_" } @GENERATED_SUFFIX), $PROBE],
    );
    my $expected_commands = {
        provider_analyze => [map { _oracle_command($_) }
            @{$expected->{commands}{provider_analyze}}],
        analyze_generated =>
            _oracle_command($expected->{commands}{analyze_generated}),
        elaborate_fixture =>
            _oracle_command($expected->{commands}{elaborate_fixture}),
        run_fixture => _oracle_command($expected->{commands}{run_fixture}),
        elaborate_provider_probe =>
            _oracle_command($expected->{commands}{elaborate_provider_probe}),
        run_provider_probe =>
            _oracle_command($expected->{commands}{run_provider_probe}),
    };
    confess "checked qualifier commands diverged from execution-plan authority\n"
        unless _canonical($checked->{commands}) eq _canonical($expected_commands);
    confess "checked qualifier generated settings diverged from plan authority\n"
        unless ($checked->{provider_compilation}{generated_settings_sha256} // '')
            eq sha256_hex($expected->{generated_settings_content});
    return {
        path => $CHECKED_REPORT,
        bytes => $identity->{bytes},
        sha256 => $identity->{sha256},
        qualification_id => $CHECKED_QUALIFICATION_ID,
        command_projection_sha256 =>
            sha256_hex(_canonical($expected_commands)),
        generated_settings_sha256 =>
            sha256_hex($expected->{generated_settings_content}),
        status => 'byte_exact_executable_oracle',
    };
}

sub _oracle_command($argv) {
    return {
        working_directory => '.',
        argv => _clone($argv),
        command_digest => sha256_hex(_canonical($argv)),
        execution_status => 'passed',
    };
}

sub _settings_body($stage, $reports) {
    return join("\n",
        '-- Generated only inside the digest-named FSMGEN qualification stage.',
        'package body OsvvmScriptSettingsPkg is',
        qq{  constant OSVVM_HOME_DIRECTORY : string := "$OSVVM_ROOT" ;},
        qq{  constant OSVVM_TEMP_OUTPUT_DIRECTORY : string := "$reports/" ;},
        qq{  constant OSVVM_BASE_DIRECTORY : string := "$stage/" ;},
        qq{  constant OSVVM_BUILD_YAML_FILE : string := "$reports/OsvvmRun.yml" ;},
        qq{  constant OSVVM_TRANSCRIPT_YAML_FILE : string := "$reports/OSVVM_transcript.yml" ;},
        '  constant OSVVM_REVISION : string := "2026.05" ;',
        '  constant OSVVM_SETTINGS_REVISION : string := "2026.05" ;',
        '  constant ALERT_YAML_VERSION : string := "0.1" ;',
        '  constant SCOREBOARD_YAML_VERSION : string := "0.1" ;',
        '  constant COVERAGE_YAML_VERSION : string := "0.1" ;',
        '  constant REQUIREMENTS_YAML_VERSION : string := "0.1" ;',
        'end package body OsvvmScriptSettingsPkg ;',
        '');
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS, 'OSVVM/GHDL execution-plan report');
    confess "OSVVM/GHDL execution-plan report header is invalid\n"
        unless $report->{ok}
            && ($report->{status} // '') eq 'closed_not_executed'
            && ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{tool_profile} // '') eq $TOOL_PROFILE;
    _selected_level($report->{level});
    confess "OSVVM/GHDL execution-plan identity is invalid\n"
        unless ($report->{plan_identity} // '')
            =~ m{\Aosvvm-ghdl-execution-plan/[0-9a-f]{64}\z};
    confess "OSVVM/GHDL execution-plan nonclaims changed\n"
        unless _canonical($report->{explicit_nonclaims})
            eq _canonical(\@NONCLAIMS);
    confess "OSVVM/GHDL execution-plan diagnostics changed\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
}

sub _file_identity($repo_root, $relpath, $root_device, $executable) {
    _safe_relpath($relpath);
    my $path = _repo_path($repo_root, $relpath);
    confess "required execution-plan path '$relpath' is not a regular file\n"
        unless -f $path && !-l $path;
    my @stat = stat($path);
    confess "required execution-plan path '$relpath' crossed repository volume\n"
        unless @stat && $stat[0] == $root_device;
    confess "required execution-plan binary '$relpath' is not executable\n"
        if $executable && !-x $path;
    return {
        relpath => $relpath,
        bytes => 0 + (-s $path),
        sha256 => _file_sha256($path),
    };
}

sub _repository_root($raw) {
    confess "repository_root must name one existing non-symlink directory\n"
        unless defined($raw) && !ref($raw) && -d $raw && !-l $raw;
    my $root = abs_path($raw);
    confess "repository_root cannot be resolved\n" unless defined $root;
    return $root;
}

sub _selected_level($level) {
    confess "OSVVM/GHDL execution-plan level is not selected\n"
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

sub _safe_relpath($value) {
    confess "execution-plan path is not one safe repository-relative identity\n"
        unless defined($value) && !ref($value) && length($value)
            && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
}

sub _repo_path($root, $relative) {
    _safe_relpath($relative);
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub _file_sha256($path) {
    open my $fh, '<:raw', $path
        or confess "cannot read execution-plan input '$path': $!\n";
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh or confess "cannot close execution-plan input '$path': $!\n";
    return $sha->hexdigest;
}

sub _slurp($path) {
    open my $fh, '<:raw', $path
        or confess "cannot read execution-plan oracle '$path': $!\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close execution-plan oracle '$path': $!\n";
    return $content;
}

sub _canonical($value) {
    return $JSON->encode($value);
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
    confess "OSVVM/GHDL execution-plan projection has unsupported reference\n"
        if ref($value);
    return $value;
}

1;
