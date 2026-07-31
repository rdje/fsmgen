package FSM::VIAL::Backend::Runner;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IO::Select;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX qw(WNOHANG setpgid);
use Scalar::Util qw(blessed);
use Symbol qw(gensym);
use Time::HiRes qw(time);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::TraceValidator;

my $BASE = 'backends/sv_portable_verilator';
my $PREFIX = "FSMGEN_VIAL_TRACE_V1\t";
my $JSON = JSON::PP->new->canonical(1);
my @RESULT_KEYS = qw(
    ok status operation_id backend_profile backend_manifest result_manifest
    artifacts diagnostics cleanup
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub run($class, @args) {
    return _failure('VIAL_RUN_INVOCATION_ERROR', 'run requires the exact Runner class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_RUN_INVOCATION_ERROR', 'run expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _run($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::Backend::Runner::Failure');
    return _failure('VIAL_RUN_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _run($raw) {
    _require_exact_keys($raw, [qw(repo_root execution_ir emission)], 'runner invocation');
    _throw('VIAL_RUN_INVOCATION_ERROR', 'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_RUN_INVOCATION_ERROR', 'emission must be one successful private backend result', '/emission')
        unless ref($raw->{emission}) eq 'HASH' && !blessed($raw->{emission})
            && $raw->{emission}{ok}
            && ($raw->{emission}{backend_profile} // '') eq 'sv_portable_verilator';
    _throw('VIAL_RUN_INVOCATION_ERROR', 'repo_root must be a scalar directory path', '/repo_root')
        unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_RUN_PATH_ERROR', 'repository root is not a readable directory', '/repo_root')
        unless defined($repo_root) && -d $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_RUN_PATH_ERROR', 'repository filesystem identity is unavailable', '/repo_root')
        unless @root_stat;

    my $emission = _clone($raw->{emission});
    my $operation_id = $emission->{operation_id};
    _throw('VIAL_RUN_INVOCATION_ERROR', 'emission operation identity is invalid', '/emission/operation_id')
        unless defined($operation_id) && !ref($operation_id)
            && $operation_id =~ /\Aop-[0-9a-f]{64}\z/;
    my $stage_rel = ".artifacts/tmp/vial/$operation_id";
    my $stage_abs = _safe_destination($repo_root, $stage_rel, $root_stat[0]);
    _throw('VIAL_RUN_COLLISION', "runtime staging root '$stage_rel' already exists", '/cleanup/staging_identity')
        if -e $stage_abs || -l $stage_abs;

    my %artifact = map { $_->{relpath} => _clone($_) } @{$emission->{artifacts}};
    my $compile = _decode_artifact(\%artifact, "$BASE/commands/compile-command.json");
    my $run = _decode_artifact(\%artifact, "$BASE/commands/run-command.json");
    my $selected_profile = _decode_artifact(\%artifact, "$BASE/evidence/tool-profile.json");
    _validate_command_records($compile, $run, $stage_rel, $emission->{generated_top});

    my $version = _capture_process($repo_root, ['verilator', '--version'], 10, 65_536);
    _throw('VIAL_RUN_TOOL_ERROR', 'Verilator version query failed', '/tool_profile')
        unless $version->{ok} && $version->{exit_code} == 0;
    my $version_output = $version->{output};
    $version_output =~ s/[\r\n]+\z//;
    _throw('VIAL_RUN_TOOL_ERROR', 'installed Verilator identity does not match the qualified 5.046 profile', '/tool_profile')
        unless $version_output eq $selected_profile->{qualified_version_output};

    my ($executed, $workflow_error);
    my $stage_created = 0;
    my $workflow_ok = eval {
        _make_directory($stage_abs, $stage_rel);
        $stage_created = 1;
        _materialize_inputs($repo_root, $stage_rel, $compile, \%artifact);
        my $obj_rel = _command_mdir($compile);
        _make_directory(_rel_abs($repo_root, $obj_rel), $obj_rel);

        my $compile_process = _capture_process(
            $repo_root,
            [$compile->{logical_executable}, @{$compile->{arguments}}],
            120,
            8_388_608,
        );
        _throw('VIAL_RUN_COMPILE_ERROR', 'Verilator compile exceeded its timeout', '/compile')
            if $compile_process->{timed_out};
        _throw('VIAL_RUN_LIMIT_EXCEEDED', 'Verilator compile output exceeded 8 MiB', '/compile')
            if $compile_process->{output_limited};
        unless ($compile_process->{ok} && $compile_process->{exit_code} == 0
                && index($compile_process->{output}, '%Error:') < 0) {
            _throw(
                'VIAL_RUN_COMPILE_ERROR',
                'Verilator compile failed: ' . _process_error_summary($compile_process->{output}),
                '/compile',
            );
        }
        my $executable_rel = $compile->{expected_outputs}[0];
        my $executable_abs = _rel_abs($repo_root, $executable_rel);
        _throw('VIAL_RUN_COMPILE_ERROR', 'Verilator did not produce the exact expected executable', '/compile/expected_outputs')
            unless -f $executable_abs && !-l $executable_abs && -x $executable_abs;

        my $run_process = _capture_process($repo_root, [$executable_rel], 30, 67_108_864);
        _throw('VIAL_RUN_RUNTIME_ERROR', 'generated VIAL runtime exceeded its timeout', '/run')
            if $run_process->{timed_out};
        _throw('VIAL_RUN_LIMIT_EXCEEDED', 'generated VIAL runtime output exceeded 64 MiB', '/run')
            if $run_process->{output_limited};
        _throw('VIAL_RUN_RUNTIME_ERROR', 'generated VIAL runtime exited nonzero', '/run')
            unless $run_process->{ok} && $run_process->{exit_code} == 0;

        my ($trace_text, $trace_jsonl, $ordinary_lines) = _extract_trace($run_process->{output});
        my $trace = FSM::VIAL::Backend::TraceValidator->validate({
            execution_ir => $raw->{execution_ir},
            trace_text => $trace_text,
            simulator_exit_code => $run_process->{exit_code},
        });
        _throw(
            'VIAL_RUN_TRACE_ERROR',
            $trace->{diagnostics}[0]{message} . ' at ' . $trace->{diagnostics}[0]{path},
            '/trace',
        ) unless $trace->{ok};

        my $compile_transcript = _compile_transcript($compile, $version_output);
        my $run_transcript = _run_transcript($run, $trace, $ordinary_lines);
        my $transcript_sha = sha256_hex($compile_transcript . "\0" . $run_transcript);
        my $compile_id = 'compile/' . sha256_hex(
            $compile->{command_digest} . "\0" . $version_output
        );
        my $simulation_id = 'simulation/' . sha256_hex(
            $run->{command_digest} . "\0" . $trace->{projection}{trace_sha256}
        );
        my $backend_manifest_id = 'backend-manifest/' . sha256_hex(
            $emission->{plan_id} . "\0sv_portable_verilator\0" . $version_output
        );
        my @generated_sha = sort map { sha256_hex($_->{content}) }
            grep { $_->{kind} eq 'systemverilog_source' } values %artifact;
        my $tool_profile = {
            %$selected_profile,
            selection_status => 'executed_qualified',
            execution_evidence => JSON::PP::true,
        };
        my $result = FSM::VIAL::Backend::ResultProducer->produce({
            execution_ir => $raw->{execution_ir},
            trace_validation => $trace,
            negotiation => $emission->{negotiation},
            tool_profile => $tool_profile,
            backend_manifest_id => $backend_manifest_id,
            compile_id => $compile_id,
            simulation_id => $simulation_id,
            generated_artifact_sha256s => \@generated_sha,
            transcript_sha256 => $transcript_sha,
        });
        _throw('VIAL_RUN_RESULT_ERROR', $result->{diagnostics}[0]{message}, '/result')
            unless $result->{ok};

        $artifact{"$BASE/evidence/tool-profile.json"}{content} = _json_text($tool_profile);
        $artifact{"$BASE/evidence/compile-transcript.txt"} = _artifact(
            "$BASE/evidence/compile-transcript.txt", 'compile_transcript', 'text',
            'normalized_compile_transcript', $compile_transcript, [$compile_id],
        );
        $artifact{"$BASE/evidence/run-transcript.txt"} = _artifact(
            "$BASE/evidence/run-transcript.txt", 'run_transcript', 'text',
            'normalized_run_transcript', $run_transcript, [$simulation_id],
        );
        $artifact{"$BASE/evidence/runtime-trace.jsonl"} = _artifact(
            "$BASE/evidence/runtime-trace.jsonl", 'runtime_trace', 'jsonl',
            'validated_runtime_trace', $trace_jsonl, [$simulation_id],
        );
        my ($result_digest) = $result->{manifest}{result_id} =~ m{\Aresult/([0-9a-f]{64})\z};
        _throw('VIAL_RUN_RESULT_ERROR', 'normalized result identity is invalid', '/result/result_id')
            unless defined $result_digest;
        my $result_rel = "results/$result_digest/verification-result-manifest.json";
        $artifact{$result_rel} = _artifact(
            $result_rel, 'result_manifest', 'json', 'verification_result_manifest',
            $result->{content}, [$emission->{plan_id}, $simulation_id],
        );
        $executed = {
            trace => $trace,
            tool_profile => $tool_profile,
            compile => $compile,
            run => $run,
            result => $result,
            result_rel => $result_rel,
            backend_manifest_id => $backend_manifest_id,
            compile_id => $compile_id,
            simulation_id => $simulation_id,
        };
        1;
    };
    $workflow_error = $@ unless $workflow_ok;

    if ($stage_created && -d $stage_abs && !-l $stage_abs) {
        my $cleanup_error;
        remove_tree($stage_abs, {error => \$cleanup_error});
        _throw('VIAL_RUN_CLEANUP_ERROR', "cannot remove runtime staging root '$stage_rel'", '/cleanup')
            if $cleanup_error && @$cleanup_error;
    }
    die $workflow_error unless $workflow_ok;
    _throw('VIAL_RUN_CLEANUP_ERROR', "runtime staging root '$stage_rel' remains after execution", '/cleanup')
        if -e $stage_abs || -l $stage_abs;

    my $backend_manifest = _clone($emission->{backend_manifest});
    $backend_manifest->{tool_profile} = {
        relpath => "$BASE/evidence/tool-profile.json",
        sha256 => sha256_hex($artifact{"$BASE/evidence/tool-profile.json"}{content}),
        selection_status => 'executed_qualified',
    };
    $backend_manifest->{capability_evidence}{compile} = 'passed';
    $backend_manifest->{capability_evidence}{runtime} = 'passed';
    $backend_manifest->{capability_evidence}{result} = $executed->{result}{status};
    $backend_manifest->{limitations} = [
        'known-value trace observation only; complete four-state observation is not claimed',
        'one unit, one clock domain, no native extension, and declared probe adapters only',
        'runtime result is produced; cross-backend parity remains unevaluated',
    ];
    $backend_manifest->{commands}{compile}{execution_status} = 'passed';
    $backend_manifest->{commands}{run}{execution_status} = 'passed';
    $backend_manifest->{result} = {
        schema => 'fsmgen.verification_result_manifest.v1',
        status => $executed->{result}{status},
        relpath => $executed->{result_rel},
        sha256 => sha256_hex($executed->{result}{content}),
    };
    $backend_manifest->{cleanup} = {
        staging_identity => $stage_rel,
        state => 'completed_removed',
        removed => JSON::PP::true,
    };
    my @backend_artifacts = grep {
        $_ ne "$BASE/backend-manifest.json" && index($_, 'results/') != 0
    } sort keys %artifact;
    $backend_manifest->{artifacts} = [map { _artifact_ref($artifact{$_}) } @backend_artifacts];
    $artifact{"$BASE/backend-manifest.json"}{content} = _json_text($backend_manifest);
    my @artifacts = map { _clone($artifact{$_}) } sort keys %artifact;

    return _result({
        ok => JSON::PP::true,
        status => $executed->{result}{status},
        operation_id => $operation_id,
        backend_profile => 'sv_portable_verilator',
        backend_manifest => $backend_manifest,
        result_manifest => $executed->{result}{manifest},
        artifacts => \@artifacts,
        diagnostics => [],
        cleanup => {
            staging_identity => $stage_rel,
            removed => JSON::PP::true,
        },
    });
}

sub _materialize_inputs($repo_root, $stage_rel, $compile, $artifact) {
    my $prefix = "$stage_rel/work/sv_portable_verilator/input/";
    for my $input (@{$compile->{inputs}}) {
        _throw('VIAL_RUN_COMMAND_ERROR', 'compile input is outside the exact owned staging input root', '/compile/inputs')
            unless index($input, $prefix) == 0;
        my $relpath = substr($input, length($prefix));
        my $source = $artifact->{$relpath};
        _throw('VIAL_RUN_COMMAND_ERROR', "compile input '$relpath' is not one emitted SystemVerilog artifact", '/compile/inputs')
            unless $source && $source->{kind} eq 'systemverilog_source';
        my $path = _rel_abs($repo_root, $input);
        _make_directory(dirname($path), dirname($input));
        _write_exact($path, $source->{content}, $input);
    }
}

sub _validate_command_records($compile, $run, $stage_rel, $top) {
    my @compile_keys = qw(
        schema schema_version logical_executable arguments working_directory
        inputs expected_outputs command_digest
    );
    _closed_record($compile, \@compile_keys, 'compile command');
    _closed_record($run, \@compile_keys, 'run command');
    for my $pair ([$compile, 'compile'], [$run, 'run']) {
        my ($record, $label) = @$pair;
        _throw('VIAL_RUN_COMMAND_ERROR', "$label command schema is not exact", "/$label/schema")
            unless $record->{schema} eq 'fsmgen.vial_backend_command.v1'
                && $record->{schema_version} == 1;
        my $identity = _clone($record);
        delete $identity->{command_digest};
        _throw('VIAL_RUN_COMMAND_ERROR', "$label command digest does not match its content", "/$label/command_digest")
            unless $record->{command_digest} eq sha256_hex($JSON->encode($identity));
    }
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command executable is not exact', '/compile/logical_executable')
        unless $compile->{logical_executable} eq 'verilator';
    my @prefix = qw(
        --binary --timing --assert -j 1 --threads 1 --x-initial 0 --x-assign 0
        --timescale 1ns/1ps --top-module
    );
    my $object_root = "$stage_rel/work/sv_portable_verilator/obj";
    my $input_root = "$stage_rel/work/sv_portable_verilator/input/";
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command input cardinality is not exact', '/compile/inputs')
        unless @{$compile->{inputs}} == 3;
    my %seen_input;
    for my $input (@{$compile->{inputs}}) {
        _throw('VIAL_RUN_COMMAND_ERROR', 'compile command input is outside the operation-owned SystemVerilog tree', '/compile/inputs')
            unless defined($input) && !ref($input) && index($input, $input_root) == 0
                && $input =~ /\.sv\z/ && !$seen_input{$input}++;
    }
    my @expected_arguments = (@prefix, $top, '--Mdir', $object_root, @{$compile->{inputs}});
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command arguments differ from the exact qualified profile', '/compile/arguments')
        unless $JSON->encode($compile->{arguments}) eq $JSON->encode(\@expected_arguments);
    my $executable = "$object_root/V$top";
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command output identity is not exact', '/compile/expected_outputs')
        unless @{$compile->{expected_outputs}} == 1
            && $compile->{expected_outputs}[0] eq $executable;
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command working directory must be repository root', '/compile/working_directory')
        unless $compile->{working_directory} eq '.' && $run->{working_directory} eq '.';
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command executable identity is wrong', '/run/logical_executable')
        unless $run->{logical_executable} eq "V$top" && !@{$run->{arguments}};
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command input does not match the compile executable', '/run/inputs')
        unless @{$run->{inputs}} == 1 && @{$compile->{expected_outputs}} == 1
            && $run->{inputs}[0] eq $compile->{expected_outputs}[0]
            && $run->{inputs}[0] eq $executable;
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command output identity is not one repository-relative runtime trace', '/run/expected_outputs')
        unless @{$run->{expected_outputs}} == 1
            && defined($run->{expected_outputs}[0]) && !ref($run->{expected_outputs}[0])
            && $run->{expected_outputs}[0] =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*/backends/sv_portable_verilator/evidence/runtime-trace\.jsonl\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $run->{expected_outputs}[0], -1;
}

sub _command_mdir($compile) {
    for my $index (0 .. $#{$compile->{arguments}} - 1) {
        return $compile->{arguments}[$index + 1]
            if $compile->{arguments}[$index] eq '--Mdir';
    }
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command has no object directory', '/compile/arguments');
}

sub _capture_process($cwd, $argv, $timeout, $limit) {
    my ($stdin, $stdout);
    my $stderr = gensym;
    my $original = getcwd();
    chdir($cwd) or _throw('VIAL_RUN_HOST_ERROR', 'cannot enter repository root for tool execution', '/repo_root');
    my $pid = eval { open3($stdin, $stdout, $stderr, @$argv) };
    my $spawn_error = $@;
    chdir($original) or _throw('VIAL_RUN_HOST_ERROR', 'cannot restore host working directory', '/repo_root');
    _throw('VIAL_RUN_TOOL_ERROR', 'cannot execute the selected tool', '/tool')
        unless defined($pid) && !$spawn_error;
    my $process_group = eval { setpgid($pid, $pid); 1 } ? 1 : 0;
    close $stdin;
    for my $fh ($stdout, $stderr) {
        my $flags = fcntl($fh, F_GETFL, 0);
        fcntl($fh, F_SETFL, $flags | O_NONBLOCK) if defined $flags;
    }
    my $select = IO::Select->new($stdout, $stderr);
    my $start = time();
    my $output = '';
    my ($timed_out, $limited) = (0, 0);
    while ($select->count) {
        if (time() - $start > $timeout) {
            $timed_out = 1;
            last;
        }
        for my $fh ($select->can_read(0.05)) {
            my $chunk = '';
            my $read = sysread($fh, $chunk, 65_536);
            if (defined($read) && $read > 0) {
                $output .= $chunk;
                if (bytes::length($output) > $limit) {
                    $limited = 1;
                    last;
                }
            }
            elsif (defined($read) && $read == 0) {
                $select->remove($fh);
                close $fh;
            }
        }
        last if $limited;
    }
    my $status;
    if ($timed_out || $limited) {
        $select->remove($_) for $select->handles;
        close $_ for grep { defined(fileno($_)) } ($stdout, $stderr);
        $status = _terminate_process($pid, $process_group);
    }
    else {
        waitpid($pid, 0);
        $status = $?;
    }
    return {
        ok => (!$timed_out && !$limited && ($status & 127) == 0) ? JSON::PP::true : JSON::PP::false,
        exit_code => ($status & 127) ? 128 + ($status & 127) : ($status >> 8),
        output => $output,
        timed_out => $timed_out ? JSON::PP::true : JSON::PP::false,
        output_limited => $limited ? JSON::PP::true : JSON::PP::false,
    };
}

sub _terminate_process($pid, $process_group) {
    my $target = $process_group ? -$pid : $pid;
    kill 'TERM', $target;
    my $deadline = time() + 2;
    while (time() < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
        return $? if $waited == $pid || $waited == -1;
        select undef, undef, undef, 0.02;
    }
    kill 'KILL', $target;
    waitpid($pid, 0);
    return $?;
}

sub _extract_trace($output) {
    if ($output =~ /\r/) {
        my $offset = index($output, "\r");
        my $start = $offset > 16 ? $offset - 16 : 0;
        my $context = unpack('H*', substr($output, $start, 33));
        _throw(
            'VIAL_RUN_RUNTIME_ERROR',
            "runtime output contains a carriage return at byte $offset (hex context $context)",
            '/run/output',
        );
    }
    my @line = split /\n/, $output;
    my (@trace, @json, @ordinary);
    for my $line (@line) {
        if (index($line, $PREFIX) == 0) {
            push @trace, $line;
            push @json, substr($line, length($PREFIX));
        }
        else {
            push @ordinary, $line if length $line;
        }
    }
    _throw('VIAL_RUN_TRACE_ERROR', 'runtime produced no machine trace', '/trace') unless @trace;
    return (join("\n", @trace) . "\n", join("\n", @json) . "\n", \@ordinary);
}

sub _compile_transcript($command, $version) {
    return join("\n",
        'schema: fsmgen.vial_compile_transcript.v1',
        "command-digest: $command->{command_digest}",
        "tool-version: $version",
        'exit-code: 0',
        'diagnostics: none',
        '',
    );
}

sub _process_error_summary($output) {
    my @line = grep { /%(?:Error|Warning)-|%Error:/ } split /\n/, $output;
    @line = grep { length } split /\n/, $output unless @line;
    my @selected = @line ? @line[0 .. (@line > 3 ? 2 : $#line)] : ();
    my $summary = join(' | ', @selected);
    $summary = 'tool returned no diagnostic text' unless length $summary;
    $summary =~ s/[\r\n\t]+/ /g;
    $summary =~ s/\s+/ /g;
    $summary = substr($summary, 0, 2_048) if length($summary) > 2_048;
    return $summary;
}

sub _run_transcript($command, $trace, $ordinary) {
    my $semantic_lines = scalar grep { /\AVIAL / } @$ordinary;
    return join("\n",
        'schema: fsmgen.vial_run_transcript.v1',
        "command-digest: $command->{command_digest}",
        'exit-code: 0',
        "trace-records: $trace->{projection}{record_count}",
        "trace-sha256: $trace->{projection}{trace_sha256}",
        "semantic-diagnostic-lines: $semantic_lines",
        '',
    );
}

sub _decode_artifact($artifact, $relpath) {
    _throw('VIAL_RUN_COMMAND_ERROR', "emission is missing '$relpath'", '/emission/artifacts')
        unless $artifact->{$relpath};
    my $decoded = eval { JSON::PP->new->decode($artifact->{$relpath}{content}) };
    _throw('VIAL_RUN_COMMAND_ERROR', "artifact '$relpath' is not one JSON object", '/emission/artifacts')
        unless defined($decoded) && !$@ && ref($decoded) eq 'HASH' && !blessed($decoded);
    return $decoded;
}

sub _closed_record($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    _throw('VIAL_RUN_COMMAND_ERROR', "$label has an unknown key", '/commands')
        if grep { !$expected{$_} } keys %$value;
    _throw('VIAL_RUN_COMMAND_ERROR', "$label is missing a key", '/commands')
        if grep { !exists($value->{$_}) } @$keys;
}

sub _safe_destination($repo_root, $relative, $root_device) {
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catfile($path, $part);
        if (-e $path || -l $path) {
            my @stat = lstat($path);
            _throw('VIAL_RUN_PATH_ERROR', "path '$relative' contains an unreadable component", '/cleanup')
                unless @stat;
            _throw('VIAL_RUN_PATH_ERROR', "path '$relative' must not traverse a symlink", '/cleanup') if -l _;
            $existing = $path;
        }
    }
    my @existing_stat = stat($existing);
    _throw('VIAL_RUN_PATH_ERROR', "path '$relative' must remain on the repository filesystem volume", '/cleanup')
        unless @existing_stat && $existing_stat[0] == $root_device;
    return $path;
}

sub _rel_abs($repo_root, $relative) {
    _throw('VIAL_RUN_PATH_ERROR', 'runtime path is not a safe repository-relative identity', '/path')
        unless defined($relative) && !ref($relative) && length($relative)
            && $relative !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $relative, -1;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub _make_directory($path, $identity) {
    if (-e $path || -l $path) {
        _throw('VIAL_RUN_PATH_ERROR', "path '$identity' must be a non-symlink directory", '/cleanup')
            unless -d $path && !-l $path;
        return;
    }
    eval { make_path($path); 1 }
        or _throw('VIAL_RUN_HOST_ERROR', "cannot create runtime directory '$identity'", '/cleanup');
}

sub _write_exact($path, $content, $identity) {
    open my $fh, '>:raw', $path
        or _throw('VIAL_RUN_HOST_ERROR', "cannot create runtime input '$identity'", '/compile/inputs');
    print {$fh} $content
        or _throw('VIAL_RUN_HOST_ERROR', "cannot write runtime input '$identity'", '/compile/inputs');
    close $fh
        or _throw('VIAL_RUN_HOST_ERROR', "cannot close runtime input '$identity'", '/compile/inputs');
}

sub _artifact($relpath, $kind, $language, $role, $content, $generated_from) {
    return {
        relpath => $relpath,
        kind => $kind,
        language => $language,
        role => $role,
        content => $content,
        encoding => 'utf-8',
        source_layer => 'VIAL_BACKEND',
        generated_from => _clone($generated_from),
    };
}

sub _artifact_ref($artifact) {
    return {
        relpath => $artifact->{relpath},
        kind => $artifact->{kind},
        role => $artifact->{role},
        sha256 => sha256_hex($artifact->{content}),
        bytes => bytes::length($artifact->{content}),
    };
}

sub _json_text($value) {
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_RUN_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_RUN_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::Runner::Failure';
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        operation_id => undef,
        backend_profile => 'sv_portable_verilator',
        backend_manifest => undef,
        result_manifest => undef,
        artifacts => [],
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
        cleanup => {staging_identity => undef, removed => JSON::PP::false},
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'runner result has unknown key(s)' if grep { !$expected{$_} } keys %$value;
    confess 'runner result is missing key(s)' if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown runner host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown runner host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'runner projection contains an unsupported reference' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::Runner::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL backend runner failure' }, fallback => 1;

1;
