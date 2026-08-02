package FSM::VIAL::Backend::SVUVMExperimentalProbe;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use File::Basename qw(basename dirname);
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

my $JSON = JSON::PP->new->canonical(1);
my $PROFILE_ID =
    'sv_uvm_experimental.verilator_5_046.'
    . 'uvm_verilator_2020_3_1_vlt_656f20d0';
my $VERILATOR_VERSION = 'Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228';
my $UVM_COMMIT = '656f20d087370a7c742e00188d20bbf30fa95339';
my $UVM_TREE = '882930bb7debe79b22234e4a8a53854549046778';
my $STANDARD_COMMIT = 'a457e9c40d5b7af89e4326a9ddab267476318f54';
my $STANDARD_TREE = '82c53f85498fd625a950daa8744d87028e052028';
my $ACCELLERA_COMMIT = '78c06547a2a0a29b3dc9dcafae62b75b2ff61544';
my @SOURCE_ROLES = qw(
    uvm_types_package
    uvm_component_foundations
    uvm_fixture_interface
    uvm_notification_interception
    uvm_stimulus_services
    uvm_checking_results
    uvm_fixture_package
    bound_sva_checker
    generated_hial_dut
    uvm_fixture_top
);

sub profile($class) {
    confess __PACKAGE__ . "->profile requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _clone(_profile());
}

sub classify_output($class, @args) {
    confess __PACKAGE__ . "->classify_output requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "classify_output expects one scalar transcript\n"
        unless @args == 1 && defined($args[0]) && !ref($args[0]);
    return _classify_output($args[0]);
}

sub run($class, @args) {
    return _failure('VIAL_UVM_PROBE_INVOCATION_ERROR',
        'run requires the exact SVUVMExperimentalProbe class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_UVM_PROBE_INVOCATION_ERROR',
        'run expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _run($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::SVUVMExperimentalProbe::Failure');
    return _failure('VIAL_UVM_PROBE_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _run($raw) {
    _require_exact_keys($raw, [qw(repo_root emission uvm_source_root)], 'probe invocation');
    _throw('VIAL_UVM_PROBE_INVOCATION_ERROR',
        'emission must be one successful private Accellera 2020-3.1 result',
        '/emission')
        unless ref($raw->{emission}) eq 'HASH' && !blessed($raw->{emission})
            && $raw->{emission}{ok}
            && ($raw->{emission}{backend_profile} // '')
                eq 'sv_uvm_emit.accellera_2020_3_1';
    _throw('VIAL_UVM_PROBE_INVOCATION_ERROR',
        'repo_root must be a scalar directory path', '/repo_root')
        unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        'repository root is not a readable directory', '/repo_root')
        unless defined($repo_root) && -d $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        'repository filesystem identity is unavailable', '/repo_root')
        unless @root_stat;

    my $source_rel = _safe_relative($raw->{uvm_source_root}, '/uvm_source_root');
    my $source_abs = _safe_existing_directory(
        $repo_root, $source_rel, $root_stat[0], '/uvm_source_root');
    my $uvm_pkg_rel = "$source_rel/src/uvm_pkg.sv";
    my $uvm_pkg_abs = _safe_existing_file(
        $repo_root, $uvm_pkg_rel, $root_stat[0], '/uvm_source_root');

    my $source_commit = _git_identity($repo_root, $source_rel, 'HEAD');
    _throw('VIAL_UVM_PROBE_SOURCE_ERROR',
        'UVM source checkout does not match the immutable selected commit',
        '/source_identity/commit')
        unless $source_commit eq $UVM_COMMIT;
    my $source_tree = _git_identity($repo_root, $source_rel, 'HEAD^{tree}');
    _throw('VIAL_UVM_PROBE_SOURCE_ERROR',
        'UVM source checkout does not match the immutable selected tree',
        '/source_identity/tree')
        unless $source_tree eq $UVM_TREE;

    my ($artifact_by_role, $generated_sha) = _validate_emission($raw->{emission});
    my $probe_id = 'probe-' . sha256_hex(join("\0",
        $PROFILE_ID,
        $raw->{emission}{operation_id} // '',
        $generated_sha,
        sha256_hex(_slurp($uvm_pkg_abs, $uvm_pkg_rel)),
    ));
    my $stage_rel = ".artifacts/tmp/vial-uvm-experimental/$probe_id";
    my $stage_abs = _safe_destination($repo_root, $stage_rel, $root_stat[0]);
    _throw('VIAL_UVM_PROBE_COLLISION',
        "experimental probe staging root '$stage_rel' already exists",
        '/cleanup/staging_identity')
        if -e $stage_abs || -l $stage_abs;

    my (@stages, $workflow_error);
    my $stage_created = 0;
    my $workflow_ok = eval {
        _make_directory($stage_abs, $stage_rel);
        $stage_created = 1;
        my @generated_rel = _materialize_emission(
            $repo_root, $stage_rel, $artifact_by_role);
        my $control_rel = "$stage_rel/input/control/minimal_uvm_smoke.sv";
        _write_exact(
            _rel_abs($repo_root, $control_rel), _control_source(), $control_rel);

        push @stages, _run_stage($repo_root, {
            id => 'tool_identity',
            argv => ['verilator', '--version'],
            timeout_seconds => 10,
            output_limit_bytes => 65_536,
            evaluate => sub ($process) {
                my $version = $process->{output};
                $version =~ s/[\r\n]+\z//;
                return _stage_outcome(
                    $process->{ok} && $process->{exit_code} == 0
                        && $version eq $VERILATOR_VERSION,
                    'host_dependency',
                    $version eq $VERILATOR_VERSION
                        ? 'exact selected Verilator identity'
                        : 'installed Verilator identity differs from the selected profile',
                );
            },
        });

        my @common = (
            '--timing', '--threads', '1', '-sv', '+define+UVM_NO_DPI',
            "-I$source_rel/src",
        );
        push @stages, _run_stage($repo_root, {
            id => 'uvm_library_preprocess',
            argv => ['verilator', '-E', @common, $uvm_pkg_rel],
            timeout_seconds => 30,
            output_limit_bytes => 33_554_432,
            evaluate => \&_ordinary_outcome,
        });
        push @stages, _run_stage($repo_root, {
            id => 'uvm_library_parse',
            argv => ['verilator', '--lint-only', @common, $uvm_pkg_rel],
            timeout_seconds => 60,
            output_limit_bytes => 8_388_608,
            evaluate => \&_ordinary_outcome,
        });

        my $control_obj_rel = "$stage_rel/obj-control";
        _make_directory(_rel_abs($repo_root, $control_obj_rel), $control_obj_rel);
        push @stages, _run_stage($repo_root, {
            id => 'uvm_library_compile_elaboration',
            argv => [
                'verilator', '--binary', '--timing', '--assert', '-j', '1',
                '--threads', '1', '-sv', '+define+UVM_NO_DPI',
                '--output-split', '5000', '--output-split-cfuncs', '5000',
                '-CFLAGS', '-O0',
                '--timescale', '1ns/1ps', "-I$source_rel/src",
                '--top-module', 'fsmgen_uvm_smoke_top',
                '--Mdir', $control_obj_rel, $uvm_pkg_rel, $control_rel,
            ],
            timeout_seconds => 180,
            output_limit_bytes => 16_777_216,
            evaluate => \&_ordinary_outcome,
        });
        my $control_exe_rel = "$control_obj_rel/Vfsmgen_uvm_smoke_top";
        if ($stages[-1]{status} eq 'passed'
                && -f _rel_abs($repo_root, $control_exe_rel)) {
            push @stages, _run_stage($repo_root, {
                id => 'uvm_library_runtime_smoke',
                argv => [$control_exe_rel],
                timeout_seconds => 30,
                output_limit_bytes => 8_388_608,
                evaluate => sub ($process) {
                    return _stage_outcome(
                        $process->{ok} && $process->{exit_code} == 0
                            && index($process->{output}, 'FSMGEN_UVM_SMOKE') >= 0
                            && index($process->{output}, 'UVM_ERROR :    0') >= 0
                            && index($process->{output}, 'UVM_FATAL :    0') >= 0,
                        'tool_or_library',
                        'minimal UVM run_phase smoke completed with zero UVM errors and fatals',
                    );
                },
            });
        }
        else {
            push @stages, _not_run_stage(
                'uvm_library_runtime_smoke',
                'library compile/elaboration prerequisite did not pass');
        }

        push @stages, _run_stage($repo_root, {
            id => 'generated_fixture_preprocess',
            argv => ['verilator', '-E', @common, $uvm_pkg_rel, @generated_rel],
            timeout_seconds => 60,
            output_limit_bytes => 67_108_864,
            evaluate => \&_ordinary_outcome,
        });
        push @stages, _run_stage($repo_root, {
            id => 'generated_fixture_parse',
            argv => [
                'verilator', '--lint-only', '--timing', '--assert',
                '--threads', '1', '-sv', '+define+UVM_NO_DPI',
                "-I$source_rel/src", '--top-module',
                'base_output_arbitration_tb', $uvm_pkg_rel, @generated_rel,
            ],
            timeout_seconds => 90,
            output_limit_bytes => 16_777_216,
            evaluate => sub ($process) {
                return _stage_outcome(1, 'none',
                    'generated fixture parsed without diagnostics')
                    if $process->{ok} && $process->{exit_code} == 0;
                my $owner = _classify_output($process->{output});
                return {
                    status => $owner eq 'tool_limitation' ? 'unsupported' : 'failed',
                    owner => $owner,
                    conclusion => $owner eq 'tool_limitation'
                        ? 'selected tool does not implement the emitted ranged SVA delay'
                        : 'generated fixture did not parse under the selected experiment',
                };
            },
        });

        my $fixture_obj_rel = "$stage_rel/obj-fixture";
        _make_directory(_rel_abs($repo_root, $fixture_obj_rel), $fixture_obj_rel);
        push @stages, _run_stage($repo_root, {
            id => 'generated_fixture_compile_elaboration',
            argv => [
                'verilator', '--binary', '--timing', '--assert', '--bbox-unsup',
                '-j', '1', '--threads', '1', '-sv', '+define+UVM_NO_DPI',
                '--output-split', '5000', '--output-split-cfuncs', '5000',
                '-CFLAGS', '-O0',
                '--timescale', '1ns/1ps', "-I$source_rel/src",
                '--top-module', 'base_output_arbitration_tb',
                '--Mdir', $fixture_obj_rel, $uvm_pkg_rel, @generated_rel,
            ],
            timeout_seconds => 240,
            output_limit_bytes => 16_777_216,
            evaluate => sub ($process) {
                return _stage_outcome(1, 'none',
                    'generated fixture binary compiled and elaborated')
                    if $process->{ok} && $process->{exit_code} == 0;
                my $owner = _classify_output($process->{output});
                return {
                    status => 'failed',
                    owner => $owner,
                    conclusion => $owner eq 'tool_limitation'
                        ? 'unsupported-feature blackboxing reached a selected-tool internal fault'
                        : 'generated fixture compile/elaboration failed',
                };
            },
        });
        my $fixture_exe_rel = "$fixture_obj_rel/Vbase_output_arbitration_tb";
        if ($stages[-1]{status} eq 'passed'
                && -f _rel_abs($repo_root, $fixture_exe_rel)) {
            push @stages, _run_stage($repo_root, {
                id => 'generated_fixture_runtime_smoke',
                argv => [$fixture_exe_rel],
                timeout_seconds => 60,
                output_limit_bytes => 16_777_216,
                evaluate => \&_ordinary_outcome,
            });
        }
        else {
            push @stages, _not_run_stage(
                'generated_fixture_runtime_smoke',
                'fixture compile/elaboration prerequisite did not pass');
        }
        1;
    };
    $workflow_error = $@ unless $workflow_ok;

    if ($stage_created && -d $stage_abs && !-l $stage_abs) {
        my $cleanup_error;
        remove_tree($stage_abs, {error => \$cleanup_error});
        _throw('VIAL_UVM_PROBE_CLEANUP_ERROR',
            "cannot remove experimental staging root '$stage_rel'", '/cleanup')
            if $cleanup_error && @$cleanup_error;
    }
    die $workflow_error unless $workflow_ok;
    _throw('VIAL_UVM_PROBE_CLEANUP_ERROR',
        "experimental staging root '$stage_rel' remains after execution", '/cleanup')
        if -e $stage_abs || -l $stage_abs;

    my $generator_defect = grep {
        $_->{owner} eq 'generator_defect' && $_->{status} ne 'passed'
    } @stages;
    my $tool_limited = grep { $_->{owner} eq 'tool_limitation' } @stages;
    my $all_passed = !grep { $_->{status} ne 'passed' } @stages;
    my $conclusion = $generator_defect ? 'generator_defect_detected'
        : $all_passed ? 'all_experimental_stages_passed'
        : $tool_limited ? 'partial_tool_limited'
        : 'partial_inconclusive';
    my $report = {
        schema => 'fsmgen.vial_uvm_experimental_probe.v1',
        schema_version => 1,
        probe_completed => JSON::PP::true,
        experimental => JSON::PP::true,
        product_support => JSON::PP::false,
        qualification_status => 'unqualified_experimental_evidence_only',
        profile => _profile(),
        source_identity => {
            repository_relative_root => $source_rel,
            commit => $source_commit,
            tree => $source_tree,
            uvm_pkg_sha256 => sha256_hex(_slurp($uvm_pkg_abs, $uvm_pkg_rel)),
        },
        emission => {
            backend_profile => $raw->{emission}{backend_profile},
            operation_id => $raw->{emission}{operation_id},
            generated_source_count => scalar(@SOURCE_ROLES),
            generated_sources_sha256 => $generated_sha,
        },
        deviations => [
            {
                id => 'uvm_no_dpi',
                scope => 'all experimental stages',
                argv => '+define+UVM_NO_DPI',
                consequence => 'DPI-backed UVM facilities are not exercised',
            },
            {
                id => 'bbox_unsupported',
                scope => 'generated fixture compile/elaboration attempt only',
                argv => '--bbox-unsup',
                consequence => 'unsupported constructs may be black-boxed; successful use would not qualify semantics',
            },
        ],
        resource_controls => {
            build_jobs => 1,
            verilator_threads => 1,
            output_split_statements => 5000,
            output_split_cfuncs_statements => 5000,
            cxx_optimization => 'O0',
            stage_timeouts_and_output_limits_recorded_inline => JSON::PP::true,
        },
        stages => \@stages,
        conclusion => $conclusion,
        capabilities => {
            preprocessing => _capability_status(\@stages,
                qw(uvm_library_preprocess generated_fixture_preprocess)),
            uvm_library_parse => _stage_status(\@stages, 'uvm_library_parse'),
            uvm_library_compile_elaboration =>
                _stage_status(\@stages, 'uvm_library_compile_elaboration'),
            uvm_library_runtime_smoke =>
                _stage_status(\@stages, 'uvm_library_runtime_smoke'),
            generated_fixture_parse =>
                _stage_status(\@stages, 'generated_fixture_parse'),
            generated_fixture_compile_elaboration =>
                _stage_status(\@stages, 'generated_fixture_compile_elaboration'),
            generated_fixture_runtime =>
                _stage_status(\@stages, 'generated_fixture_runtime_smoke'),
            normalized_result => 'not_exercised',
            cross_backend_parity => 'not_exercised',
            complete_uvm_breadth => 'not_claimed',
        },
        cleanup => {
            staging_identity => $stage_rel,
            removed => JSON::PP::true,
        },
    };
    return {
        ok => JSON::PP::true,
        status => $conclusion,
        report => $report,
        content => $JSON->pretty(1)->encode($report),
        diagnostics => [],
    };
}

sub _profile() {
    return {
        id => $PROFILE_ID,
        tool => {
            name => 'Verilator',
            version_output => $VERILATOR_VERSION,
        },
        methodology => {
            standard => 'IEEE 1800.2-2020',
            release => 'UVM 2020.3.1',
            canonical_accellera_tag => '2020.3.1',
            canonical_accellera_commit => $ACCELLERA_COMMIT,
        },
        source_variant => {
            provider => 'CHIPS Alliance uvm-verilator',
            repository => 'https://github.com/chipsalliance/uvm-verilator.git',
            ref => 'uvm-2020-3.1-vlt',
            commit => $UVM_COMMIT,
            tree => $UVM_TREE,
            unmodified_ref => 'standard',
            unmodified_commit => $STANDARD_COMMIT,
            unmodified_tree => $STANDARD_TREE,
        },
    };
}

sub _validate_emission($emission) {
    my %by_role;
    for my $artifact (@{$emission->{artifacts} // []}) {
        next unless ref($artifact) eq 'HASH'
            && ($artifact->{kind} // '') eq 'systemverilog_source';
        _throw('VIAL_UVM_PROBE_EMISSION_ERROR',
            'generated SystemVerilog artifact role is missing or duplicated',
            '/emission/artifacts')
            unless defined($artifact->{role}) && !ref($artifact->{role})
                && !exists($by_role{$artifact->{role}});
        $by_role{$artifact->{role}} = $artifact;
    }
    my %expected = map { $_ => 1 } @SOURCE_ROLES;
    my @unknown = grep { !$expected{$_} } keys %by_role;
    my @missing = grep { !exists($by_role{$_}) } @SOURCE_ROLES;
    _throw('VIAL_UVM_PROBE_EMISSION_ERROR',
        'emission SystemVerilog role set differs from the selected fixture',
        '/emission/artifacts')
        if @unknown || @missing;
    my $identity = join("\0", map {
        my $artifact = $by_role{$_};
        _throw('VIAL_UVM_PROBE_EMISSION_ERROR',
            'generated SystemVerilog artifact content is not scalar',
            '/emission/artifacts')
            unless defined($artifact->{content}) && !ref($artifact->{content});
        $_ . "\0" . ($artifact->{relpath} // '') . "\0"
            . sha256_hex($artifact->{content});
    } @SOURCE_ROLES);
    return (\%by_role, sha256_hex($identity));
}

sub _materialize_emission($repo_root, $stage_rel, $by_role) {
    my @relative;
    my %seen_name;
    for my $role (@SOURCE_ROLES) {
        my $artifact = $by_role->{$role};
        my $name = basename($artifact->{relpath} // '');
        _throw('VIAL_UVM_PROBE_EMISSION_ERROR',
            'generated source basename is unsafe', '/emission/artifacts')
            unless $name =~ /\A[A-Za-z_][A-Za-z0-9_.-]*\.sv\z/
                && !$seen_name{$name}++;
        my $relative = "$stage_rel/input/generated/$name";
        _write_exact(_rel_abs($repo_root, $relative),
            $artifact->{content}, $relative);
        push @relative, $relative;
    }
    return @relative;
}

sub _control_source() {
    return <<'SV';
`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"

class fsmgen_uvm_smoke_test extends uvm_test;
  `uvm_component_utils(fsmgen_uvm_smoke_test)

  function new(string name = "fsmgen_uvm_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("FSMGEN_UVM_SMOKE", "minimal run_phase reached", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass

module fsmgen_uvm_smoke_top;
  initial run_test("fsmgen_uvm_smoke_test");
endmodule
SV
}

sub _run_stage($repo_root, $spec) {
    my $process = _capture_process(
        $repo_root, $spec->{argv}, $spec->{timeout_seconds},
        $spec->{output_limit_bytes});
    my $outcome = $spec->{evaluate}->($process);
    my $normalized_output = _normalized_output($process->{output}, $repo_root);
    my $evidence_output = _stage_evidence_output(
        $spec->{id}, $normalized_output);
    return {
        id => $spec->{id},
        status => $outcome->{status},
        owner => $outcome->{owner},
        conclusion => $outcome->{conclusion},
        argv => [@{$spec->{argv}}],
        exit_code => $process->{exit_code},
        timed_out => $process->{timed_out},
        output_limited => $process->{output_limited},
        output_sha256 => sha256_hex($evidence_output),
        diagnostic_summary => _diagnostic_summary($normalized_output),
    };
}

sub _ordinary_outcome($process) {
    return _stage_outcome(
        $process->{ok} && $process->{exit_code} == 0,
        'tool_or_library',
        $process->{ok} && $process->{exit_code} == 0
            ? 'stage completed with zero exit status'
            : 'stage did not complete with zero exit status',
    );
}

sub _stage_outcome($passed, $owner, $conclusion) {
    return {
        status => $passed ? 'passed' : 'failed',
        owner => $passed ? 'none' : $owner,
        conclusion => $conclusion,
    };
}

sub _not_run_stage($id, $reason) {
    return {
        id => $id,
        status => 'not_run',
        owner => 'prerequisite',
        conclusion => $reason,
        argv => [],
        exit_code => undef,
        timed_out => JSON::PP::false,
        output_limited => JSON::PP::false,
        output_sha256 => sha256_hex(''),
        diagnostic_summary => [],
    };
}

sub _classify_output($output) {
    return 'generator_defect'
        if $output =~ /(?:syntax error|Cannot find file containing module|Can't find definition of)/;
    return 'tool_limitation'
        if $output =~ /(?:%Error-UNSUPPORTED:|Verilator internal fault|Unsupported:)/;
    return 'resource_limit'
        if $output =~ /(?:timed out|output limit)/i;
    return 'tool_or_library';
}

sub _diagnostic_summary($output) {
    my @all = split /\n/, $output;
    my @error = grep {
        /%Error(?:-[A-Z0-9_]+)?:|Verilator internal fault/
            || /^\s*UVM_(?:ERROR|FATAL)\s*:\s*[1-9][0-9]*\s*$/
    } @all;
    my @warning = grep {
        /%Warning(?:-[A-Z0-9_]+)?:|\bwarning:/
            || /^\s*UVM_(?:ERROR|FATAL)\s*:\s*0\s*$/
    } @all;
    my %seen;
    my @line = grep { !$seen{$_}++ } (@error, @warning);
    @line = @line[0 .. 5] if @line > 6;
    for my $line (@line) {
        $line =~ s{\.artifacts/tmp/vial-uvm-experimental/probe-[0-9a-f]+}{<probe>}g;
        $line =~ s/[\r\t]+/ /g;
        $line =~ s/\s+/ /g;
        $line = substr($line, 0, 1_024) if length($line) > 1_024;
    }
    return \@line;
}

sub _normalized_output($output, $repo_root) {
    $output =~ s/\Q$repo_root\E/<repo>/g;
    $output =~ s{/opt/homebrew/Cellar/verilator/5\.046[^\s:]*}{<toolchain>}g;
    $output =~ s{(?:/Library/Developer|/Applications/Xcode\.app)[^\s:]*}{<host-toolchain>}g;
    $output =~ s/\b(?:wall|cpu)\s+[0-9]+(?:\.[0-9]+)?\s+s\b/<elapsed>/g;
    $output =~ s/^- Verilator: Built from.*$/<verilator-build-summary>/mg;
    $output =~ s/^- Verilator: Walltime.*$/<verilator-resource-summary>/mg;
    return $output;
}

sub _stage_evidence_output($id, $output) {
    if ($id eq 'uvm_library_runtime_smoke') {
        my @proof = grep {
            /FSMGEN_UVM_SMOKE/
                || /^\s*UVM_(?:ERROR|FATAL)\s*:\s*[0-9]+\s*$/
                || /Simulation finished/
        } split /\n/, $output;
        return join("\n", @proof) . "\n" if @proof;
    }
    return $output;
}

sub _capability_status($stages, @ids) {
    my @status = map { _stage_status($stages, $_) } @ids;
    return 'passed' if !grep { $_ ne 'passed' } @status;
    return 'failed' if grep { $_ eq 'failed' } @status;
    return 'unsupported' if grep { $_ eq 'unsupported' } @status;
    return 'not_run';
}

sub _stage_status($stages, $id) {
    my ($stage) = grep { $_->{id} eq $id } @$stages;
    return $stage ? $stage->{status} : 'not_run';
}

sub _git_identity($repo_root, $source_rel, $revision) {
    my $process = _capture_process(
        $repo_root, ['git', '-C', $source_rel, 'rev-parse', $revision],
        10, 65_536);
    _throw('VIAL_UVM_PROBE_SOURCE_ERROR',
        'cannot inspect the selected UVM source identity', '/source_identity')
        unless $process->{ok} && $process->{exit_code} == 0;
    my $identity = $process->{output};
    $identity =~ s/[\r\n]+\z//;
    _throw('VIAL_UVM_PROBE_SOURCE_ERROR',
        'selected UVM source identity is malformed', '/source_identity')
        unless $identity =~ /\A[0-9a-f]{40}\z/;
    return $identity;
}

sub _capture_process($cwd, $argv, $timeout, $limit) {
    my ($stdin, $stdout);
    my $stderr = gensym;
    my $original = getcwd();
    chdir($cwd) or _throw('VIAL_UVM_PROBE_HOST_ERROR',
        'cannot enter repository root for tool execution', '/repo_root');
    my $pid = eval { open3($stdin, $stdout, $stderr, @$argv) };
    my $spawn_error = $@;
    chdir($original) or _throw('VIAL_UVM_PROBE_HOST_ERROR',
        'cannot restore host working directory', '/repo_root');
    _throw('VIAL_UVM_PROBE_TOOL_ERROR',
        'cannot execute a selected experimental-probe tool', '/tool')
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
    my $result = {
        ok => (!$timed_out && !$limited && ($status & 127) == 0)
            ? JSON::PP::true : JSON::PP::false,
        exit_code => ($status & 127) ? 128 + ($status & 127) : ($status >> 8),
        output => $output,
        timed_out => $timed_out ? JSON::PP::true : JSON::PP::false,
        output_limited => $limited ? JSON::PP::true : JSON::PP::false,
    };
    $? = 0;
    return $result;
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

sub _safe_relative($relative, $path) {
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        'path must be one safe repository-relative identity', $path)
        unless defined($relative) && !ref($relative) && length($relative)
            && $relative !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $relative, -1;
    return $relative;
}

sub _safe_existing_directory($repo_root, $relative, $root_device, $path) {
    my $absolute = _safe_destination($repo_root, $relative, $root_device);
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        "path '$relative' is not one readable non-symlink directory", $path)
        unless -d $absolute && !-l $absolute;
    return $absolute;
}

sub _safe_existing_file($repo_root, $relative, $root_device, $path) {
    my $absolute = _safe_destination($repo_root, $relative, $root_device);
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        "path '$relative' is not one readable non-symlink file", $path)
        unless -f $absolute && !-l $absolute;
    return $absolute;
}

sub _safe_destination($repo_root, $relative, $root_device) {
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catfile($path, $part);
        if (-e $path || -l $path) {
            my @stat = lstat($path);
            _throw('VIAL_UVM_PROBE_PATH_ERROR',
                "path '$relative' contains an unreadable component", '/path')
                unless @stat;
            _throw('VIAL_UVM_PROBE_PATH_ERROR',
                "path '$relative' must not traverse a symlink", '/path')
                if -l _;
            $existing = $path;
        }
    }
    my @existing_stat = stat($existing);
    _throw('VIAL_UVM_PROBE_PATH_ERROR',
        "path '$relative' must remain on the repository filesystem volume",
        '/path')
        unless @existing_stat && $existing_stat[0] == $root_device;
    return $path;
}

sub _rel_abs($repo_root, $relative) {
    _safe_relative($relative, '/path');
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub _make_directory($path, $identity) {
    if (-e $path || -l $path) {
        _throw('VIAL_UVM_PROBE_PATH_ERROR',
            "path '$identity' must be a non-symlink directory", '/cleanup')
            unless -d $path && !-l $path;
        return;
    }
    eval { make_path($path); 1 }
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot create experimental directory '$identity'", '/cleanup');
}

sub _write_exact($path, $content, $identity) {
    _make_directory(dirname($path), dirname($identity));
    open my $fh, '>:raw', $path
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot create experimental input '$identity'", '/inputs');
    print {$fh} $content
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot write experimental input '$identity'", '/inputs');
    close $fh
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot close experimental input '$identity'", '/inputs');
}

sub _slurp($path, $identity) {
    open my $fh, '<:raw', $path
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot read '$identity'", '/source_identity');
    local $/;
    my $text = <$fh>;
    close $fh
        or _throw('VIAL_UVM_PROBE_HOST_ERROR',
            "cannot close '$identity'", '/source_identity');
    return $text;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    _throw('VIAL_UVM_PROBE_INVOCATION_ERROR',
        "$label contains an unknown key", '/')
        if grep { !$expected{$_} } keys %$value;
    _throw('VIAL_UVM_PROBE_INVOCATION_ERROR',
        "$label is missing a required key", '/')
        if grep { !exists($value->{$_}) } @$keys;
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'failed',
        report => undef,
        content => undef,
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _throw($code, $message, $path) {
    die bless {
        code => $code,
        message => $message,
        path => $path,
    }, 'FSM::VIAL::Backend::SVUVMExperimentalProbe::Failure';
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown host error';
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/ at \S+ line \d+\.?\z//;
    $message = 'unknown host error' unless length $message;
    return substr($message, 0, 512);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
