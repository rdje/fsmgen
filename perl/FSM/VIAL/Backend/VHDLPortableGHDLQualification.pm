package FSM::VIAL::Backend::VHDLPortableGHDLQualification;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IPC::Cmd qw(run);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $JSON = JSON::PP->new->canonical(1);
my $SCHEMA = 'fsmgen.vial_vhdl_portable_ghdl_qualification.v1';
my $PROFILE = 'vhdl_portable_ghdl';
my $GALLERY = 'vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics';
my $PROVIDER_ROOT = '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64';
my $ARCHIVE = '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-archive/ghdl-llvm-jit-6.0.0-macos15-aarch64.tar.gz';
my $BINARY = "$PROVIDER_ROOT/bin/ghdl";
my $PROBE = 'vial/qualification/vhdl_portable_ghdl/ghdl_6_0_0_four_state_probe.vhd';
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
my @SOURCE = map { "$GALLERY/src/$_" } (
    'fsmgen_vial_types_pkg.vhd',
    'fsmgen_vial_runtime_pkg.vhd',
    'base_output_arbitration_metadata_pkg.vhd',
    'dut/ahb_lite_subordinate.vhd',
    'base_output_arbitration_tb.vhd',
    'base_output_arbitration_probe_adapter.vhd',
);
my @RESULT_KEYS = qw(ok status report content diagnostics cleanup);
my @REPORT_KEYS = qw(
    schema schema_version qualification_id task_id status backend_profile
    tool_profile provider source_set commands execution trace result
    four_state_probe deterministic_rerun portable_sv_parity resource_controls
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

sub default_provider_root($class) {
    _exact_class($class, 'default_provider_root');
    return $PROVIDER_ROOT;
}

sub qualify($class, @args) {
    return _failure('VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        'qualify requires the exact qualification class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        'qualify expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _qualify($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure');
    return _failure('VIAL_VHDL_QUALIFICATION_HOST_ERROR',
        _sanitize_exception($error), '/');
}

sub _qualify($raw) {
    _require_exact_keys($raw, [qw(repo_root provider_root)], 'qualification invocation');
    _throw('VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        'repo_root must be a scalar directory path', '/repo_root')
        unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        'provider_root must be the exact repository-relative qualified root',
        '/provider_root')
        unless defined($raw->{provider_root}) && !ref($raw->{provider_root})
            && $raw->{provider_root} eq $PROVIDER_ROOT;

    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        'repository root is not a readable directory', '/repo_root')
        unless defined($repo_root) && -d $repo_root && !-l $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        'repository filesystem identity is unavailable', '/repo_root')
        unless @root_stat;

    my $archive_abs = _repo_path($repo_root, $ARCHIVE);
    my $binary_abs = _repo_path($repo_root, $BINARY);
    _regular_same_volume($archive_abs, $ARCHIVE, $root_stat[0]);
    _regular_same_volume($binary_abs, $BINARY, $root_stat[0]);
    _throw('VIAL_VHDL_QUALIFICATION_TOOL_ERROR',
        'qualified GHDL binary is not executable', '/provider/binary')
        unless -x $binary_abs;
    my $archive_bytes = -s $archive_abs;
    _throw('VIAL_VHDL_QUALIFICATION_TOOL_ERROR',
        'official GHDL archive byte size differs from the selected release asset',
        '/provider/archive_bytes')
        unless $archive_bytes == 37_155_806;
    _throw('VIAL_VHDL_QUALIFICATION_TOOL_ERROR',
        'official GHDL archive digest differs from the selected release asset',
        '/provider/archive_sha256')
        unless _file_sha256($archive_abs) eq $ARCHIVE_SHA256;
    _throw('VIAL_VHDL_QUALIFICATION_TOOL_ERROR',
        'materialized GHDL binary digest differs from the qualified profile',
        '/provider/binary_sha256')
        unless _file_sha256($binary_abs) eq $BINARY_SHA256;

    my @source_set;
    for my $rel (@SOURCE, $PROBE) {
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
        source_set => \@source_set,
    };
    my $digest = sha256_hex($JSON->encode($identity_input));
    my $qualification_id = "qualification/$digest";
    my $stage_rel = ".artifacts/tmp/vial-ghdl-qualification/$digest";
    my $stage_abs = _repo_path($repo_root, $stage_rel);
    _throw('VIAL_VHDL_QUALIFICATION_COLLISION',
        "qualification staging root '$stage_rel' already exists", '/cleanup/staging_identity')
        if -e $stage_abs || -l $stage_abs;

    my $library_rel = "$stage_rel/library";
    my $library_abs = _repo_path($repo_root, $library_rel);
    my @analyze = ($BINARY, '-a', '--std=08', '--work=fsmgen_vial',
        "--workdir=$library_rel", @SOURCE, $PROBE);
    my @elaborate_fixture = ($BINARY, '-e', '--std=08', '--work=fsmgen_vial',
        "--workdir=$library_rel", 'base_output_arbitration_tb');
    my @run_fixture = ($BINARY, '-r', '--std=08', '--work=fsmgen_vial',
        "--workdir=$library_rel", 'base_output_arbitration_tb', '--assert-level=error');
    my @elaborate_probe = ($BINARY, '-e', '--std=08', '--work=fsmgen_vial',
        "--workdir=$library_rel", 'ghdl_6_0_0_four_state_probe');
    my @run_probe = ($BINARY, '-r', '--std=08', '--work=fsmgen_vial',
        "--workdir=$library_rel", 'ghdl_6_0_0_four_state_probe', '--assert-level=error');

    my ($version, $analysis, $elaboration, $run_one, $run_two,
        $probe_elaboration, $probe_one, $probe_two, $workflow_error);
    my $stage_created = 0;
    my $workflow_ok = eval {
        make_path($library_abs);
        $stage_created = 1;
        $version = _capture($repo_root, [$BINARY, '--version'], 10, 65_536, 'version');
        my $normalized_version = $version->{output};
        $normalized_version =~ s/[\r\n]+\z//;
        _throw('VIAL_VHDL_QUALIFICATION_TOOL_ERROR',
            'installed GHDL identity does not match the exact 6.0.0 LLVM-JIT profile',
            '/tool_profile/version_output')
            unless $normalized_version eq $VERSION_OUTPUT;
        $analysis = _capture($repo_root, \@analyze, 120, 8_388_608, 'analysis');
        $elaboration = _capture($repo_root, \@elaborate_fixture, 60, 8_388_608,
            'fixture elaboration');
        $run_one = _capture($repo_root, \@run_fixture, 30, 67_108_864,
            'fixture execution');
        $run_two = _capture($repo_root, \@run_fixture, 30, 67_108_864,
            'fixture deterministic rerun');
        $probe_elaboration = _capture($repo_root, \@elaborate_probe, 60, 8_388_608,
            'four-state probe elaboration');
        $probe_one = _capture($repo_root, \@run_probe, 30, 8_388_608,
            'four-state probe execution');
        $probe_two = _capture($repo_root, \@run_probe, 30, 8_388_608,
            'four-state probe deterministic rerun');
        1;
    };
    $workflow_error = $@ unless $workflow_ok;
    if ($stage_created && -d $stage_abs && !-l $stage_abs) {
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        _throw('VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR',
            "cannot remove qualification staging root '$stage_rel'", '/cleanup')
            if $errors && @$errors;
    }
    die $workflow_error unless $workflow_ok;
    _throw('VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR',
        "qualification staging root '$stage_rel' remains after execution", '/cleanup')
        if -e $stage_abs || -l $stage_abs;

    _throw('VIAL_VHDL_QUALIFICATION_DETERMINISM_ERROR',
        'fixture runtime output differs across identical executions',
        '/deterministic_rerun/fixture_stdout_identical')
        unless $run_one->{output} eq $run_two->{output};
    _throw('VIAL_VHDL_QUALIFICATION_DETERMINISM_ERROR',
        'four-state probe output differs across identical executions',
        '/deterministic_rerun/four_state_stdout_identical')
        unless $probe_one->{output} eq $probe_two->{output};
    my $runtime = _validate_runtime_output($run_one->{output});
    _throw('VIAL_VHDL_QUALIFICATION_FOUR_STATE_ERROR',
        'four-state timed probe did not produce its exact pass marker',
        '/four_state_probe')
        unless $probe_one->{output}
            =~ /^FSMGEN_VIAL_FOUR_STATE_PROBE_V1 pass$/m;

    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        qualification_id => $qualification_id,
        task_id => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5',
        status => 'qualified',
        backend_profile => $PROFILE,
        tool_profile => {
            tool_name => 'ghdl',
            qualified_version => '6.0.0',
            backend => 'llvm_jit',
            build_commit => 'e589c698c351369ac5bcfe7abe1f1152ac5d4727',
            language_standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            version_output => $VERSION_OUTPUT,
            selection_status => 'executed_qualified',
        },
        provider => {
            root => $PROVIDER_ROOT,
            binary => $BINARY,
            binary_sha256 => $BINARY_SHA256,
            archive => $ARCHIVE,
            archive_bytes => 37_155_806,
            archive_sha256 => $ARCHIVE_SHA256,
            official_asset => 'ghdl-llvm-jit-6.0.0-macos15-aarch64.tar.gz',
            release_url => 'https://github.com/ghdl/ghdl/releases/tag/v6.0.0',
        },
        source_set => \@source_set,
        commands => {
            analyze => _command_record(\@analyze),
            elaborate_fixture => _command_record(\@elaborate_fixture),
            run_fixture => _command_record(\@run_fixture),
            elaborate_four_state_probe => _command_record(\@elaborate_probe),
            run_four_state_probe => _command_record(\@run_probe),
        },
        execution => {
            analysis => 'passed',
            fixture_elaboration => 'passed',
            fixture_execution => 'passed',
            four_state_probe_elaboration => 'passed',
            four_state_probe_execution => 'passed',
        },
        trace => $runtime->{trace},
        result => $runtime->{result},
        four_state_probe => {
            status => 'passed',
            timed_wait => '1_ns',
            original_symbols_exercised => [qw(0 1 X Z)],
            normalized_values_exercised => [qw(VIAL_VALUE_0 VIAL_VALUE_1 VIAL_VALUE_X VIAL_VALUE_Z)],
            stdout_sha256 => sha256_hex($probe_one->{output}),
        },
        deterministic_rerun => {
            status => 'passed',
            fixture_stdout_identical => JSON::PP::true,
            four_state_stdout_identical => JSON::PP::true,
            fixture_stdout_sha256 => sha256_hex($run_one->{output}),
            four_state_stdout_sha256 => sha256_hex($probe_one->{output}),
        },
        portable_sv_parity => $runtime->{portable_sv_parity},
        resource_controls => {
            outer_guard => 'scripts/run_with_ram_guard.sh --process-max-rss-mb 4096',
            descendant_rss_limit_mib => 4096,
            host_occupied_cutoff_percent => 88,
            version_timeout_seconds => 10,
            analysis_timeout_seconds => 120,
            elaboration_timeout_seconds => 60,
            execution_timeout_seconds => 30,
            maximum_runtime_output_bytes => 67_108_864,
        },
        cleanup => {
            staging_identity => $stage_rel,
            state => 'completed_removed',
            removed => JSON::PP::true,
            same_volume => JSON::PP::true,
        },
        limitations => [
            'qualification covers only the emitted bounded single-unit single-clock provider-free fixture and its declared probe adapter',
            'GHDL VHDL-2008 and PSL implementations are partial; complete VHDL-2008 and PSL are not claimed',
            'the LLVM AOT macOS package analyzed and elaborated this fixture but its external-name adapter dereferenced null at runtime; only LLVM-JIT is qualified',
            'OSVVM, UVVM, another simulator, mixed-language execution, and legacy observation-package analysis are not inferred',
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

sub _validate_runtime_output($output) {
    my @trace;
    my @result;
    for my $line (split /\r?\n/, $output) {
        push @trace, substr($line, length("FSMGEN_VIAL_TRACE_V1\t"))
            if index($line, "FSMGEN_VIAL_TRACE_V1\t") == 0;
        push @result, substr($line, length("FSMGEN_VIAL_RESULT_V1\t"))
            if index($line, "FSMGEN_VIAL_RESULT_V1\t") == 0;
    }
    _throw('VIAL_VHDL_QUALIFICATION_TRACE_ERROR',
        'runtime must emit exactly one normalized result record', '/result')
        unless @result == 1;
    my @decoded_trace = map { _decode_json($_, '/trace') } @trace;
    my $decoded_result = _decode_json($result[0], '/result');
    _throw('VIAL_VHDL_QUALIFICATION_TRACE_ERROR',
        'runtime trace must contain exactly 42 records', '/trace/record_count')
        unless @decoded_trace == 42;
    _throw('VIAL_VHDL_QUALIFICATION_TRACE_ERROR',
        'runtime trace must open with one header and close with one footer', '/trace')
        unless $decoded_trace[0]{record_kind} eq 'header'
            && $decoded_trace[-1]{record_kind} eq 'footer'
            && scalar(grep { $_->{record_kind} eq 'header' } @decoded_trace) == 1
            && scalar(grep { $_->{record_kind} eq 'footer' } @decoded_trace) == 1;
    _throw('VIAL_VHDL_QUALIFICATION_RESULT_ERROR',
        'runtime normalized result did not pass', '/result/status')
        unless ($decoded_result->{schema} // '') eq 'fsmgen.verification_result_manifest.v1'
            && ($decoded_result->{schema_version} // 0) == 1
            && ($decoded_result->{status} // '') eq 'pass';
    my $projection = $decoded_result->{parity_projection};
    _throw('VIAL_VHDL_QUALIFICATION_PARITY_ERROR',
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
            _throw('VIAL_VHDL_QUALIFICATION_PARITY_ERROR',
                "portable VHDL outcome differs from the qualified SystemVerilog oracle at scenario $index field $key",
                "/portable_sv_parity/outcomes/$index/$key")
                unless defined($actual_value)
                    && $JSON->encode($actual_value) eq $JSON->encode($expected[$index]{$key});
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
        portable_sv_parity => {
            status => 'equivalent',
            eligible => JSON::PP::true,
            equivalent => JSON::PP::true,
            oracle => 't/1559-vial-ahb-runtime-parity.t',
            oracle_profile => 'sv_portable_verilator/5.046',
            compared_paths => \@compared,
            mismatches => [],
            exclusions => [
                'unsupported_size.ready_low_cycles is not part of the qualified handwritten AHB oracle',
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
    _throw('VIAL_VHDL_QUALIFICATION_LIMIT_ERROR',
        "$label output exceeded its exact byte limit", '/resource_controls')
        if bytes::length($output) > $limit;
    _throw('VIAL_VHDL_QUALIFICATION_EXECUTION_ERROR',
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

sub _regular_same_volume($path, $identity, $root_device) {
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not one regular non-symlink file", '/provider')
        unless -f $path && !-l $path;
    my @stat = stat($path);
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        "required path '$identity' is not on the repository filesystem volume", '/provider')
        unless @stat && $stat[0] == $root_device;
}

sub _repo_path($root, $relative) {
    _throw('VIAL_VHDL_QUALIFICATION_PATH_ERROR',
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
        or _throw('VIAL_VHDL_QUALIFICATION_HOST_ERROR',
            'cannot read one qualification input', '/provider');
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;
    return $sha->hexdigest;
}

sub _decode_json($text, $path) {
    my $value = eval { JSON::PP->new->decode($text) };
    _throw('VIAL_VHDL_QUALIFICATION_RESULT_ERROR',
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
    _throw('VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure';
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        report => undef,
        content => undef,
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
        cleanup => {staging_identity => undef, state => 'not_started', removed => JSON::PP::false, same_volume => JSON::PP::false},
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

package FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure;

use overload '""' => sub {
    $_[0]{message} // 'portable VHDL GHDL qualification failure'
}, fallback => 1;

1;
