package FSM::VIAL::Backend::VHDLOSVVMGHDLQualification;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IPC::Cmd qw(run);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::Backend::OSVVM2026_05Materialization;

my $JSON = JSON::PP->new->canonical(1);
my $SCHEMA = 'fsmgen.vial_vhdl_osvvm_ghdl_qualification.v1';
my $PROFILE = 'vhdl_osvvm_qualified';
my $TASK_ID = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7';
my $GALLERY = 'vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services';
my $GHDL_ROOT = '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64';
my $GHDL_ARCHIVE = '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-archive/ghdl-llvm-jit-6.0.0-macos15-aarch64.tar.gz';
my $GHDL_BINARY = "$GHDL_ROOT/bin/ghdl";
my $OSVVM_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $PROBE = 'vial/qualification/vhdl_osvvm_ghdl/osvvm_2026_05_runtime_probe.vhd';
my $ARCHIVE_SHA256 = 'c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769';
my $BINARY_SHA256 = '38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d';
my $VERSION_OUTPUT = join("\n",
    'GHDL 6.0.0 (6.0.0.r0.ge589c698c) [Dunoon edition]',
    ' Compiled with GNAT Version: 14.2.0',
    ' static elaboration, LLVM JIT code generator',
    'Written by Tristan Gingold.',
    '',
    'Copyright (C) 2003 - 2026 Tristan Gingold.',
    'GHDL is free software, covered by the GNU General Public License.  There is NO',
    'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.');

my @GENERATED_SOURCE = (
    "$GALLERY/src/portable/fsmgen_vial_types_pkg.vhd",
    "$GALLERY/src/portable/fsmgen_vial_runtime_pkg.vhd",
    "$GALLERY/src/portable/base_output_arbitration_metadata_pkg.vhd",
    "$GALLERY/src/portable/dut/ahb_lite_subordinate.vhd",
    "$GALLERY/src/portable/base_output_arbitration_tb.vhd",
    "$GALLERY/src/portable/base_output_arbitration_probe_adapter.vhd",
    "$GALLERY/src/fsmgen_vial_osvvm_adapter_pkg.vhd",
    $PROBE,
);

# Exact GHDL/VHDL-2008 resolution of OSVVM 2026.05 osvvm/osvvm.pro.
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

# Exact GHDL/VHDL-2008 resolution of OSVVM 2026.05 Common/build.pro.
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

my @RESULT_KEYS = qw(ok status report content diagnostics cleanup);
my @REPORT_KEYS = qw(
    schema schema_version qualification_id task_id status backend_profile
    tool_profile provider_profile source_set provider_compilation commands
    execution trace result deterministic_rerun portable_result_parity
    supplementary_provider_reports capability_support resource_controls
    cleanup limitations
);

sub result_keys($class) {
    _exact_class($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub report_keys($class) {
    _exact_class($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub default_ghdl_provider_root($class) {
    _exact_class($class, 'default_ghdl_provider_root');
    return $GHDL_ROOT;
}

sub default_osvvm_dependency_root($class) {
    _exact_class($class, 'default_osvvm_dependency_root');
    return $OSVVM_ROOT;
}

sub qualify($class, @args) {
    return _failure('VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        'qualify requires the exact qualification class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        'qualify expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _qualify($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::Failure');
    return _failure('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
        _sanitize_exception($error), '/');
}

sub _qualify($raw) {
    _require_exact_keys($raw,
        [qw(repo_root ghdl_provider_root osvvm_dependency_root)],
        'qualification invocation');
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        'repo_root must be a scalar directory path', '/repo_root')
        unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'ghdl_provider_root must be the exact repository-relative qualified root',
        '/ghdl_provider_root')
        unless defined($raw->{ghdl_provider_root})
            && !ref($raw->{ghdl_provider_root})
            && $raw->{ghdl_provider_root} eq $GHDL_ROOT;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'osvvm_dependency_root must be the exact repository-relative provider root',
        '/osvvm_dependency_root')
        unless defined($raw->{osvvm_dependency_root})
            && !ref($raw->{osvvm_dependency_root})
            && $raw->{osvvm_dependency_root} eq $OSVVM_ROOT;

    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'repository root is not a readable directory', '/repo_root')
        unless defined($repo_root) && -d $repo_root && !-l $repo_root;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'qualification must execute with the repository root as current directory',
        '/repo_root')
        unless abs_path('.') eq $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'repository filesystem identity is unavailable', '/repo_root')
        unless @root_stat;

    my $archive_abs = _repo_path($repo_root, $GHDL_ARCHIVE);
    my $binary_abs = _repo_path($repo_root, $GHDL_BINARY);
    my $osvvm_abs = _repo_path($repo_root, $OSVVM_ROOT);
    _regular_same_volume($archive_abs, $GHDL_ARCHIVE, $root_stat[0]);
    _regular_same_volume($binary_abs, $GHDL_BINARY, $root_stat[0]);
    _directory_same_volume($osvvm_abs, $OSVVM_ROOT, $root_stat[0]);
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TOOL_ERROR',
        'qualified GHDL binary is not executable', '/tool_profile/binary')
        unless -x $binary_abs;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TOOL_ERROR',
        'official GHDL archive byte size differs from the selected release asset',
        '/tool_profile/archive_bytes')
        unless (-s $archive_abs) == 37_155_806;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TOOL_ERROR',
        'official GHDL archive digest differs from the selected release asset',
        '/tool_profile/archive_sha256')
        unless _file_sha256($archive_abs) eq $ARCHIVE_SHA256;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TOOL_ERROR',
        'materialized GHDL binary digest differs from the qualified profile',
        '/tool_profile/binary_sha256')
        unless _file_sha256($binary_abs) eq $BINARY_SHA256;

    my $materialization =
        FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
            dependency_root => $OSVVM_ROOT,
        });
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_ERROR',
        $materialization->{diagnostics}[0]{message}, '/provider_profile')
        unless $materialization->{ok};
    my $materialization_digest =
        sha256_hex($JSON->encode($materialization->{manifest}));

    my @source_set;
    for my $rel (@GENERATED_SOURCE) {
        my $abs = _repo_path($repo_root, $rel);
        _regular_same_volume($abs, $rel, $root_stat[0]);
        push @source_set, {
            relpath => $rel,
            bytes => 0 + (-s $abs),
            sha256 => _file_sha256($abs),
        };
    }
    my $identity_input = {
        schema => $SCHEMA,
        backend_profile => $PROFILE,
        archive_sha256 => $ARCHIVE_SHA256,
        binary_sha256 => $BINARY_SHA256,
        version_output => $VERSION_OUTPUT,
        osvvm_root_commit => $materialization->{manifest}{root_commit},
        osvvm_root_tree => $materialization->{manifest}{root_tree},
        materialization_digest => $materialization_digest,
        osvvm_source_order => \@OSVVM_SOURCE,
        common_source_order => \@COMMON_SOURCE,
        source_set => \@source_set,
    };
    my $digest = sha256_hex($JSON->encode($identity_input));
    my $qualification_id = "qualification/$digest";
    my $stage_rel = ".artifacts/tmp/vial-osvvm-ghdl-qualification/$digest";
    my $stage_abs = _repo_path($repo_root, $stage_rel);
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_COLLISION',
        "qualification staging root '$stage_rel' already exists",
        '/cleanup/staging_identity')
        if -e $stage_abs || -l $stage_abs;

    my $library_rel = "$stage_rel/libraries";
    my $library_abs = _repo_path($repo_root, $library_rel);
    my $osvvm_work_rel = "$library_rel/osvvm/v08";
    my $osvvm_work_abs = _repo_path($repo_root, $osvvm_work_rel);
    my $common_work_rel = "$library_rel/osvvm_common/v08";
    my $common_work_abs = _repo_path($repo_root, $common_work_rel);
    my $fixture_work_rel = "$library_rel/fsmgen_vial/v08";
    my $fixture_work_abs = _repo_path($repo_root, $fixture_work_rel);
    my $reports_rel = "$stage_rel/provider_reports";
    my $reports_abs = _repo_path($repo_root, $reports_rel);
    my $settings_rel = "$stage_rel/OsvvmScriptSettingsPkg_generated.vhd";
    my $settings_abs = _repo_path($repo_root, $settings_rel);

    my @provider_commands;
    my @osvvm_resolved = map {
        $_ eq '__FSMGEN_GENERATED_SETTINGS__'
            ? $settings_rel : "$OSVVM_ROOT/osvvm/$_"
    } @OSVVM_SOURCE;
    my @common_resolved = map { "$OSVVM_ROOT/Common/src/$_" } @COMMON_SOURCE;
    for my $source (@osvvm_resolved) {
        push @provider_commands, [
            $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=osvvm', "--workdir=$osvvm_work_rel", "-P$library_rel",
            $source,
        ];
    }
    for my $source (@common_resolved) {
        push @provider_commands, [
            $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=osvvm_common', "--workdir=$common_work_rel", "-P$library_rel",
            $source,
        ];
    }
    my @analyze_generated = (
        $GHDL_BINARY, '-a', '--std=08', '-Wno-library', '-Wno-hide',
        '--work=fsmgen_vial', "--workdir=$fixture_work_rel", "-P$library_rel",
        @GENERATED_SOURCE,
    );
    my @elaborate_fixture = (
        $GHDL_BINARY, '-e', '--std=08', '--work=fsmgen_vial',
        "--workdir=$fixture_work_rel", "-P$library_rel",
        'base_output_arbitration_tb',
    );
    my @run_fixture = (
        $GHDL_BINARY, '-r', '--std=08', '--work=fsmgen_vial',
        "--workdir=$fixture_work_rel", "-P$library_rel",
        'base_output_arbitration_tb', '--assert-level=error',
    );
    my @elaborate_probe = (
        $GHDL_BINARY, '-e', '--std=08', '--work=fsmgen_vial',
        "--workdir=$fixture_work_rel", "-P$library_rel",
        'fsmgen_vial_osvvm_runtime_probe',
    );
    my @run_probe = (
        $GHDL_BINARY, '-r', '--std=08', '--work=fsmgen_vial',
        "--workdir=$fixture_work_rel", "-P$library_rel",
        'fsmgen_vial_osvvm_runtime_probe', '--assert-level=error',
    );

    my ($version, $generated_analysis, $fixture_elaboration, $fixture_one,
        $fixture_two, $probe_elaboration, $probe_one, $probe_two,
        $reports_one, $reports_two, $provider_output_bytes, $settings_sha256,
        $workflow_error);
    my $stage_created = 0;
    my $workflow_ok = eval {
        $stage_created = 1;
        make_path($osvvm_work_abs, $common_work_abs, $fixture_work_abs,
            $reports_abs);
        _write_temp_file($settings_abs,
            _settings_package_body($stage_rel, $reports_rel));
        $settings_sha256 = _file_sha256($settings_abs);
        $version = _capture($repo_root, [$GHDL_BINARY, '--version'],
            10, 65_536, 'version');
        my $normalized_version = $version->{output};
        $normalized_version =~ s/[\r\n]+\z//;
        _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TOOL_ERROR',
            'installed GHDL identity does not match the exact 6.0.0 LLVM-JIT profile',
            '/tool_profile/version_output')
            unless $normalized_version eq $VERSION_OUTPUT;

        $provider_output_bytes = 0;
        for my $index (0 .. $#provider_commands) {
            my $capture = _capture($repo_root, $provider_commands[$index],
                120, 8_388_608, "provider analysis $index");
            $provider_output_bytes += $capture->{output_bytes};
        }
        $generated_analysis = _capture($repo_root, \@analyze_generated,
            120, 8_388_608, 'adapter and generated-fixture analysis');
        $fixture_elaboration = _capture($repo_root, \@elaborate_fixture,
            60, 8_388_608, 'fixture elaboration');
        $fixture_one = _capture($repo_root, \@run_fixture,
            30, 67_108_864, 'fixture execution');
        $fixture_two = _capture($repo_root, \@run_fixture,
            30, 67_108_864, 'fixture deterministic rerun');
        $probe_elaboration = _capture($repo_root, \@elaborate_probe,
            60, 8_388_608, 'provider probe elaboration');
        $probe_one = _capture($repo_root, \@run_probe,
            30, 8_388_608, 'provider probe execution');
        $reports_one = _snapshot_provider_reports($reports_abs, $reports_rel);
        _remove_provider_reports($reports_abs);
        $probe_two = _capture($repo_root, \@run_probe,
            30, 8_388_608, 'provider probe deterministic rerun');
        $reports_two = _snapshot_provider_reports($reports_abs, $reports_rel);
        1;
    };
    $workflow_error = $@ unless $workflow_ok;
    if ($stage_created && -d $stage_abs && !-l $stage_abs) {
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        _throw('VIAL_OSVVM_GHDL_QUALIFICATION_CLEANUP_ERROR',
            "cannot remove qualification staging root '$stage_rel'", '/cleanup')
            if $errors && @$errors;
    }
    die $workflow_error unless $workflow_ok;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_CLEANUP_ERROR',
        "qualification staging root '$stage_rel' remains after execution", '/cleanup')
        if -e $stage_abs || -l $stage_abs;

    my $post_materialization =
        FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
            dependency_root => $OSVVM_ROOT,
        });
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_ERROR',
        $post_materialization->{diagnostics}[0]{message}, '/provider_profile')
        unless $post_materialization->{ok};
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_ERROR',
        'provider materialization identity changed during qualification',
        '/provider_profile/materialization_manifest_sha256')
        unless sha256_hex($JSON->encode($post_materialization->{manifest}))
            eq $materialization_digest;

    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_DETERMINISM_ERROR',
        'fixture runtime output differs across identical executions',
        '/deterministic_rerun/fixture_stdout_identical')
        unless $fixture_one->{output} eq $fixture_two->{output};
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_DETERMINISM_ERROR',
        'provider runtime output differs across identical executions',
        '/deterministic_rerun/provider_stdout_identical')
        unless $probe_one->{output} eq $probe_two->{output};
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_DETERMINISM_ERROR',
        'supplementary OSVVM reports differ across identical executions',
        '/deterministic_rerun/provider_reports_identical')
        unless $JSON->encode($reports_one) eq $JSON->encode($reports_two);

    my $runtime = _validate_runtime_output($fixture_one->{output});
    my $provider_reports = _validate_provider_evidence(
        $probe_one->{output}, $reports_one);
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        qualification_id => $qualification_id,
        task_id => $TASK_ID,
        status => 'qualified',
        backend_profile => $PROFILE,
        tool_profile => {
            tool_name => 'ghdl',
            qualified_version => '6.0.0',
            backend => 'llvm_jit',
            build_commit => 'e589c698c351369ac5bcfe7abe1f1152ac5d4727',
            language_standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            binary => $GHDL_BINARY,
            binary_sha256 => $BINARY_SHA256,
            archive => $GHDL_ARCHIVE,
            archive_bytes => 37_155_806,
            archive_sha256 => $ARCHIVE_SHA256,
            version_output => $VERSION_OUTPUT,
            selection_status => 'executed_qualified',
        },
        provider_profile => {
            provider => 'OSVVM',
            version => '2026.05',
            release_tag => '2026.05',
            dependency_root => $OSVVM_ROOT,
            root_commit => $materialization->{manifest}{root_commit},
            root_tree => $materialization->{manifest}{root_tree},
            repository_count => $materialization->{manifest}{materialization}{repository_count},
            recursive_gitlink_count => $materialization->{manifest}{materialization}{gitlink_count},
            licence_file_count => $materialization->{manifest}{license_notice_summary}{license_file_count},
            notice_file_count => $materialization->{manifest}{license_notice_summary}{notice_file_count},
            documentation_licence_notice_absence_explicit => JSON::PP::true,
            materialization_manifest_sha256 => $materialization_digest,
            selection_status => 'executed_qualified',
        },
        source_set => \@source_set,
        provider_compilation => {
            status => 'passed',
            basis => 'exact OSVVM 2026.05 project-file order resolved for GHDL VHDL-2008',
            osvvm_library => 'osvvm',
            common_library => 'osvvm_common',
            osvvm_source_order => \@OSVVM_SOURCE,
            common_source_order => \@COMMON_SOURCE,
            osvvm_analyzed_source_count => scalar(@OSVVM_SOURCE),
            common_analyzed_source_count => scalar(@COMMON_SOURCE),
            total_analyzed_source_count => scalar(@provider_commands),
            generated_settings_sha256 => $settings_sha256,
            compiler_output_bytes => 0 + $provider_output_bytes,
        },
        commands => {
            provider_analyze => [map { _command_record($_) } @provider_commands],
            analyze_generated => _command_record(\@analyze_generated),
            elaborate_fixture => _command_record(\@elaborate_fixture),
            run_fixture => _command_record(\@run_fixture),
            elaborate_provider_probe => _command_record(\@elaborate_probe),
            run_provider_probe => _command_record(\@run_probe),
        },
        execution => {
            provider_analysis => 'passed',
            adapter_analysis => 'passed',
            generated_fixture_analysis => 'passed',
            fixture_elaboration => 'passed',
            fixture_execution => 'passed',
            provider_probe_elaboration => 'passed',
            provider_probe_execution => 'passed',
        },
        trace => $runtime->{trace},
        result => $runtime->{result},
        deterministic_rerun => {
            status => 'passed',
            fixture_stdout_identical => JSON::PP::true,
            provider_stdout_identical => JSON::PP::true,
            provider_reports_identical => JSON::PP::true,
            fixture_stdout_sha256 => sha256_hex($fixture_one->{output}),
            provider_stdout_sha256 => sha256_hex($probe_one->{output}),
        },
        portable_result_parity => $runtime->{portable_result_parity},
        supplementary_provider_reports => $provider_reports,
        capability_support => {
            status => 'qualified_private_fixture_profile_not_public_api',
            profile => $PROFILE,
            exercised_runtime_mappings => [qw(
                advanced_coverage advanced_data_structure advanced_randomization
                advanced_reporting advanced_scoreboard advanced_synchronization
            )],
            analysis_only_mappings => ['verification_component_adapter'],
            portable_semantic_authority => 'unchanged',
            normalized_result_authority => 'fsmgen.verification_result_manifest.v1',
            product_support => 'qualified_private_fixture_profile_not_public_api',
        },
        resource_controls => {
            outer_guard => 'scripts/run_with_ram_guard.sh --process-max-rss-mb 4096',
            descendant_rss_limit_mib => 4096,
            host_occupied_cutoff_percent => 88,
            version_timeout_seconds => 10,
            provider_analysis_timeout_seconds_per_source => 120,
            generated_analysis_timeout_seconds => 120,
            elaboration_timeout_seconds => 60,
            execution_timeout_seconds => 30,
            maximum_fixture_output_bytes => 67_108_864,
            maximum_provider_output_bytes => 8_388_608,
        },
        cleanup => {
            staging_identity => $stage_rel,
            state => 'completed_removed',
            removed => JSON::PP::true,
            same_volume => JSON::PP::true,
            provider_tree_clean => JSON::PP::true,
        },
        limitations => [
            'qualification covers one bounded generated single-unit single-clock fixture and one supplementary adapter probe',
            'the OSVVM Common address-bus transaction type is analyzed through the adapter but no OSVVM verification-component transaction executes',
            'OSVVM reports are supplementary evidence and do not redefine portable scheduling, comparison, coverage meaning, trace, normalized results, or parity',
            'the pinned Documentation repository has no tracked licence or notice file; no licence coverage is inferred',
            'UVVM, PSL, complete VHDL-2008, another simulator, mixed-language execution, legacy observation-package analysis, general parity, and scale are not inferred',
        ],
    };
    _closed_record($report, \@REPORT_KEYS, 'qualification report');
    my $content = _json_text($report);
    return _result({
        ok => JSON::PP::true,
        status => 'qualified',
        report => $report,
        content => $content,
        diagnostics => [],
        cleanup => _clone($report->{cleanup}),
    });
}

sub _settings_package_body($stage_rel, $reports_rel) {
    return join("\n",
        '-- Generated only inside the digest-named FSMGEN qualification stage.',
        'package body OsvvmScriptSettingsPkg is',
        qq{  constant OSVVM_HOME_DIRECTORY : string := "$OSVVM_ROOT" ;},
        qq{  constant OSVVM_TEMP_OUTPUT_DIRECTORY : string := "$reports_rel/" ;},
        qq{  constant OSVVM_BASE_DIRECTORY : string := "$stage_rel/" ;},
        qq{  constant OSVVM_BUILD_YAML_FILE : string := "$reports_rel/OsvvmRun.yml" ;},
        qq{  constant OSVVM_TRANSCRIPT_YAML_FILE : string := "$reports_rel/OSVVM_transcript.yml" ;},
        '  constant OSVVM_REVISION : string := "2026.05" ;',
        '  constant OSVVM_SETTINGS_REVISION : string := "2026.05" ;',
        '  constant ALERT_YAML_VERSION : string := "0.1" ;',
        '  constant SCOREBOARD_YAML_VERSION : string := "0.1" ;',
        '  constant COVERAGE_YAML_VERSION : string := "0.1" ;',
        '  constant REQUIREMENTS_YAML_VERSION : string := "0.1" ;',
        'end package body OsvvmScriptSettingsPkg ;',
        '');
}

sub _snapshot_provider_reports($reports_abs, $reports_rel) {
    my @snapshot;
    for my $name (@PROVIDER_REPORT) {
        my $path = File::Spec->catfile($reports_abs, $name);
        _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_REPORT_ERROR',
            "supplementary provider report '$name' was not produced",
            '/supplementary_provider_reports')
            unless -f $path && !-l $path;
        my $content = _slurp_raw($path);
        push @snapshot, {
            relpath => "$reports_rel/$name",
            name => $name,
            bytes => bytes::length($content),
            sha256 => sha256_hex($content),
            content => $content,
        };
    }
    return \@snapshot;
}

sub _remove_provider_reports($reports_abs) {
    for my $name (@PROVIDER_REPORT) {
        my $path = File::Spec->catfile($reports_abs, $name);
        _throw('VIAL_OSVVM_GHDL_QUALIFICATION_CLEANUP_ERROR',
            "supplementary provider report '$name' changed type before rerun",
            '/cleanup')
            unless -f $path && !-l $path;
        unlink($path) or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_CLEANUP_ERROR',
            "cannot remove supplementary provider report '$name' before rerun",
            '/cleanup');
    }
}

sub _validate_provider_evidence($output, $reports) {
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_RUNTIME_ERROR',
        'provider probe did not produce its exact deterministic pass marker',
        '/supplementary_provider_reports/runtime_marker')
        unless $output =~ /FSMGEN_VIAL_OSVVM_PROVIDER_PROBE_V1 pass random=3/;
    my %by_name = map { $_->{name} => $_ } @$reports;
    my $run = $by_name{'OsvvmRun.yml'}{content};
    my $alerts = $by_name{'AlertLogTop_alerts.yml'}{content};
    my $coverage = $by_name{'AlertLogTop_cov.yml'}{content};
    my $scoreboard = $by_name{'AlertLogTop_sb_slv.yml'}{content};
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_REPORT_ERROR',
        'OSVVM run summary does not record the exact passing result',
        '/supplementary_provider_reports/run_summary')
        unless $run =~ /FunctionalCoverage: 25\.00/
            && $run =~ /Status: PASSED/
            && $run =~ /TotalErrors: 0/
            && $run =~ /PassedCount: 3/
            && $run =~ /AffirmCount: 3/;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_REPORT_ERROR',
        'OSVVM alert report does not record three clean affirmations',
        '/supplementary_provider_reports/alerts')
        unless $alerts =~ /Status: PASSED/
            && $alerts =~ /TotalErrors: 0/
            && $alerts =~ /PassedCount: 3/
            && $alerts =~ /AffirmCount: 3/;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_REPORT_ERROR',
        'OSVVM coverage report does not record the deterministic four-bin sample',
        '/supplementary_provider_reports/coverage')
        unless $coverage =~ /Coverage: 25\.00/
            && $coverage =~ /Name: "fsmgen_adapter_coverage"/
            && $coverage =~ /TotalCovCount: 1/
            && $coverage =~ /TotalCovGoal: 4/;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PROVIDER_REPORT_ERROR',
        'OSVVM scoreboard report does not record one clean checked item',
        '/supplementary_provider_reports/scoreboard')
        unless $scoreboard =~ /Name:\s+"fsmgen_adapter_scoreboard"/
            && $scoreboard =~ /ErrorCount:\s+0/
            && $scoreboard =~ /ItemsChecked:\s+1/
            && $scoreboard =~ /FifoCount:\s+0/;
    return {
        status => 'passed_supplementary_only',
        runtime_marker => 'FSMGEN_VIAL_OSVVM_PROVIDER_PROBE_V1 pass random=3',
        report_count => scalar(@$reports),
        reports => [map {
            +{name => $_->{name}, bytes => $_->{bytes}, sha256 => $_->{sha256}}
        } @$reports],
        alert_status => 'passed_three_affirmations_zero_errors',
        coverage_status => 'passed_one_of_four_bins_25_percent',
        scoreboard_status => 'passed_one_checked_item_zero_errors',
        semantic_authority => 'supplementary_not_normalized_result',
    };
}

sub _validate_runtime_output($output) {
    my @trace;
    my @result;
    for my $line (split /\r?\n/, $output) {
        push @trace, substr($line, length("FSMGEN_VIAL_TRACE_V1\t"))
            if index($line, "FSMGEN_VIAL_TRACE_V1\t") == 0;
        push @result, substr($line, length("FSMGEN_VIAL_RESULT_V1\t"))
            if index($line, "FSMGEN_VIAL_RESULT_V1\t") == 0;
    }
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TRACE_ERROR',
        'runtime must emit exactly one normalized result record', '/result')
        unless @result == 1;
    my @decoded_trace = map { _decode_json($_, '/trace') } @trace;
    my $decoded_result = _decode_json($result[0], '/result');
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TRACE_ERROR',
        'runtime trace must contain exactly 42 records', '/trace/record_count')
        unless @decoded_trace == 42;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_TRACE_ERROR',
        'runtime trace must open with one header and close with one footer', '/trace')
        unless $decoded_trace[0]{record_kind} eq 'header'
            && $decoded_trace[-1]{record_kind} eq 'footer'
            && scalar(grep { $_->{record_kind} eq 'header' } @decoded_trace) == 1
            && scalar(grep { $_->{record_kind} eq 'footer' } @decoded_trace) == 1;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_RESULT_ERROR',
        'runtime normalized result did not pass', '/result/status')
        unless ($decoded_result->{schema} // '') eq 'fsmgen.verification_result_manifest.v1'
            && ($decoded_result->{schema_version} // 0) == 1
            && ($decoded_result->{status} // '') eq 'pass';
    my $projection = $decoded_result->{parity_projection};
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PARITY_ERROR',
        'runtime result has no exact two-scenario VHDL outcome projection',
        '/result/parity_projection')
        unless ref($projection) eq 'HASH'
            && ($projection->{schema} // '') eq 'fsmgen.vial_vhdl_portable_outcomes.v1'
            && ref($projection->{outcomes}) eq 'ARRAY'
            && @{$projection->{outcomes}} == 2;
    my @expected = (
        {
            scenario => 'success', bus_accepts => 1, ready_low_cycles => 15,
            response_error_cycles => 0, nonzero_read_data_cycles => 0,
            final_ready => 1, final_response => 0,
            final_read_data_bits => '0' x 32,
            storage_bits => '11001010111111101011101010111110', status => 'pass',
        },
        {
            scenario => 'unsupported_size', bus_accepts => 1,
            response_error_cycles => 2, nonzero_read_data_cycles => 0,
            final_ready => 1, final_response => 0,
            final_read_data_bits => '0' x 32, storage_bits => '0' x 32,
            status => 'pass',
        },
    );
    my @compared;
    for my $index (0, 1) {
        my $actual = $projection->{outcomes}[$index];
        for my $key (sort keys %{$expected[$index]}) {
            my $actual_value = $key eq 'scenario'
                ? (($actual->{scenario_id} // '') =~ /::scenario::([^:]+)\z/)[0]
                : $actual->{$key};
            _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PARITY_ERROR',
                "OSVVM-qualified VHDL outcome differs from the portable-SystemVerilog oracle at scenario $index field $key",
                "/portable_result_parity/outcomes/$index/$key")
                unless defined($actual_value)
                    && $JSON->encode($actual_value)
                        eq $JSON->encode($expected[$index]{$key});
            push @compared, "/outcomes/$index/$key";
        }
    }
    return {
        trace => {
            schema => 'fsmgen.vial_vhdl_runtime_trace.v1',
            status => 'closed_validated',
            record_count => 0 + @decoded_trace,
            header_count => 1,
            footer_count => 1,
            scenario_start_count => scalar(grep { $_->{record_kind} eq 'scenario_start' } @decoded_trace),
            scenario_end_count => scalar(grep { $_->{record_kind} eq 'scenario_end' } @decoded_trace),
            stdout_sha256 => sha256_hex($output),
        },
        result => {
            schema => $decoded_result->{schema},
            schema_version => 0 + $decoded_result->{schema_version},
            status => $decoded_result->{status},
            plan_id => $decoded_result->{plan_id},
            outcomes => _clone($projection->{outcomes}),
            result_record_sha256 => sha256_hex($result[0]),
        },
        portable_result_parity => {
            status => 'equivalent',
            eligible => JSON::PP::true,
            equivalent => JSON::PP::true,
            oracle => 't/1559-vial-ahb-runtime-parity.t',
            oracle_profile => 'sv_portable_verilator/5.046',
            portable_vhdl_qualification =>
                'vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json',
            compared_paths => \@compared,
            mismatches => [],
            exclusions => [
                'unsupported_size.ready_low_cycles is not part of the qualified handwritten AHB oracle',
                'supplementary OSVVM reports have no portable-SystemVerilog parity meaning',
            ],
        },
    };
}

sub _capture($repo_root, $argv, $timeout, $limit, $label) {
    my @absolute = @$argv;
    $absolute[0] = _repo_path($repo_root, $absolute[0]);
    my ($ok, $error, undef, $stdout, $stderr) = run(
        command => \@absolute,
        timeout => $timeout,
    );
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_LIMIT_ERROR',
        "$label output exceeded its exact byte limit", '/resource_controls')
        if bytes::length($output) > $limit;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_EXECUTION_ERROR',
        "$label failed: " . _process_summary($output, $error), '/execution')
        unless $ok;
    return {output => $output, output_bytes => bytes::length($output)};
}

sub _command_record($argv) {
    return {
        working_directory => '.',
        argv => _clone($argv),
        command_digest => sha256_hex($JSON->encode($argv)),
        execution_status => 'passed',
    };
}

sub _write_temp_file($path, $content) {
    open my $fh, '>:raw', $path
        or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
            'cannot create generated provider settings in the staging root',
            '/provider_compilation');
    print {$fh} $content
        or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
            'cannot populate generated provider settings in the staging root',
            '/provider_compilation');
    close $fh
        or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
            'cannot close generated provider settings in the staging root',
            '/provider_compilation');
}

sub _regular_same_volume($path, $identity, $root_device) {
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not one regular non-symlink file", '/path')
        unless -f $path && !-l $path;
    my @stat = stat($path);
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not on the repository filesystem volume", '/path')
        unless @stat && $stat[0] == $root_device;
}

sub _directory_same_volume($path, $identity, $root_device) {
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not one non-symlink directory", '/path')
        unless -d $path && !-l $path;
    my @stat = stat($path);
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not on the repository filesystem volume", '/path')
        unless @stat && $stat[0] == $root_device;
}

sub _repo_path($root, $relative) {
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'qualification path is not a safe repository-relative identity', '/path')
        unless _safe_relpath($relative);
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value)
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
        split m{/}, $value, -1;
    return 1;
}

sub _file_sha256($path) {
    open my $fh, '<:raw', $path
        or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
            'cannot read one qualification input', '/path');
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;
    return $sha->hexdigest;
}

sub _slurp_raw($path) {
    open my $fh, '<:raw', $path
        or _throw('VIAL_OSVVM_GHDL_QUALIFICATION_HOST_ERROR',
            'cannot read one generated provider report',
            '/supplementary_provider_reports');
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub _decode_json($text, $path) {
    my $value = eval { JSON::PP->new->decode($text) };
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_RESULT_ERROR',
        'runtime emitted malformed JSON evidence', $path)
        unless defined($value) && !$@ && ref($value) eq 'HASH' && !blessed($value);
    return $value;
}

sub _json_text($value) {
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _process_summary($output, $error) {
    my $summary = length($output) ? $output : ($error // 'unknown process failure');
    $summary =~ s/[\r\n\t]+/ /g;
    $summary =~ s/\s+/ /g;
    $summary = substr($summary, 0, 1_024) if length($summary) > 1_024;
    return $summary;
}

sub _closed_record($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    confess "$label has unknown key(s)" if grep { !$expected{$_} } keys %$value;
    confess "$label is missing key(s)" if grep { !exists($value->{$_}) } @$keys;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::Failure';
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        report => undef,
        content => undef,
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
        cleanup => {
            staging_identity => undef,
            state => 'not_started',
            removed => JSON::PP::false,
            same_volume => JSON::PP::false,
            provider_tree_clean => JSON::PP::false,
        },
    });
}

sub _result($value) {
    _closed_record($value, \@RESULT_KEYS, 'qualification result');
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown qualification host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown qualification host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'qualification projection contains an unsupported reference' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::Failure;

use overload '""' => sub {
    $_[0]{message} // 'OSVVM GHDL qualification failure'
}, fallback => 1;

1;
