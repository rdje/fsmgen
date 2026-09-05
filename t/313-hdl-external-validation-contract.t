#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLExternalValidation qw(
    hdl_external_validation_abc_tool_candidates
    hdl_external_validation_process_containment
    hdl_external_validation_required_tools
    hdl_external_validation_step_capture_limit_bytes
    hdl_external_validation_step_timeout_seconds
    hdl_external_validation_tools
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::HDLExternalValidationContract qw(
    hdl_external_validation_abc_mapping_status
    hdl_external_validation_abc_mapping_success_step_names
    build_hdl_external_validation_contract
    hdl_external_validation_contract_source
    hdl_external_validation_execution_failure_modes
    hdl_external_validation_failure_mode_family_map
    hdl_external_validation_failure_mode_names
    hdl_external_validation_failure_text_prefix_map
    hdl_external_validation_input_failure_modes
    hdl_external_validation_optional_tool_names
    hdl_external_validation_required_tool_names
    hdl_external_validation_success_presence_key_family_map
    hdl_external_validation_success_step_keys
    hdl_external_validation_success_step_names
    hdl_external_validation_success_top_level_keys
);

my $perl = abs_path($^X)
    or die "Cannot resolve the running Perl interpreter: $!";

subtest 'contract exposes the bounded external validation surface' => sub {
    my $contract = build_hdl_external_validation_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is(
        $contract->{status},
        'optional_when_tools_installed',
        'contract marks the lane as optional when tools are installed',
    );
    is(
        $contract->{contract_source},
        hdl_external_validation_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::HDLExternalValidation',
        'contract records the validation owner',
    );
    is(
        $contract->{step_timeout_seconds},
        hdl_external_validation_step_timeout_seconds(),
        'contract publishes the fixed per-step wall',
    );
    is(
        $contract->{step_capture_limit_bytes},
        hdl_external_validation_step_capture_limit_bytes(),
        'contract publishes the fixed aggregate capture ceiling',
    );
    is(
        $contract->{process_containment},
        hdl_external_validation_process_containment(),
        'contract publishes the process-group containment identity',
    );
    is(
        $contract->{working_directory},
        'repository_root',
        'contract publishes the repository-derived working-directory policy',
    );
    ok($contract->{shell_free_argv}, 'contract requires shell-free argv');
    ok(
        $contract->{separate_stdout_stderr},
        'contract requires separate stdout and stderr',
    );
    ok(
        $contract->{process_group_cleanup_required},
        'contract requires process-group cleanup proof',
    );
    ok(!$contract->{retry_on_failure}, 'contract forbids retry after failure');
    is(
        $contract->{perl_script_interpreter_handoff},
        'canonical_running_perl',
        'contract publishes deterministic Perl-script interpreter handoff',
    );
    is_deeply(
        $contract->{tools},
        hdl_external_validation_required_tool_names(),
        'contract records the required tools',
    );
    is_deeply(
        $contract->{required_tools},
        hdl_external_validation_required_tool_names(),
        'contract separately records the required external validation tools',
    );
    is_deeply(
        $contract->{optional_tools},
        hdl_external_validation_optional_tool_names(),
        'contract records optional external validation-adjacent tools',
    );
    is_deeply(
        $contract->{abc_tool_candidates},
        [hdl_external_validation_abc_tool_candidates()],
        'contract records optional ABC executable discovery candidates',
    );
    is(
        $contract->{abc_mapping_status},
        hdl_external_validation_abc_mapping_status(),
        'contract records the optional ABC mapping discovery status',
    );
    ok(
        !$contract->{abc_mapping_required},
        'contract says ABC mapping is not a required validation tool',
    );
    ok(
        $contract->{abc_mapping_opt_in_supported},
        'contract records explicit ABC mapping opt-in support',
    );
    ok(
        !$contract->{abc_mapping_default_enabled},
        'contract records that ABC mapping is not enabled by default',
    );
    is(
        $contract->{abc_mapping_invocation},
        'FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)',
        'contract records the in-process ABC mapping opt-in spelling',
    );
    is(
        $contract->{abc_mapping_yosys_stage},
        'read_verilog_sv_noautowire_synth_abc_stat',
        'contract records the ABC-enabled Yosys stage name',
    );
    is_deeply(
        $contract->{abc_mapping_success_step_names},
        hdl_external_validation_abc_mapping_success_step_names(),
        'contract publishes the ABC mapping opt-in success step names',
    );
    is_deeply(
        $contract->{target_languages},
        [qw(systemverilog sv)],
        'contract remains bounded to SystemVerilog target spellings',
    );
    ok(
        $contract->{vhdl_generation_scaffold_active},
        'contract records that direct VHDL generation now has a scaffold subset',
    );
    ok(
        $contract->{vhdl_validation_deferred_until_ghdl_validation_lane},
        'contract records the current GHDL validation deferral boundary',
    );
    ok(
        $contract->{vhdl_validation_deferred_until_vhdl_backend},
        'contract keeps the legacy VHDL-validation deferral flag for compatibility',
    );
    ok(
        grep({ /separate GHDL validation lane/ } @{$contract->{guidance} || []}),
        'contract guidance explains that VHDL validation awaits a separate GHDL lane',
    );
    is_deeply(
        $contract->{success_top_level_presence_keys},
        hdl_external_validation_success_top_level_keys(),
        'contract publishes the bounded success top-level keys',
    );
    is_deeply(
        $contract->{success_step_presence_keys},
        hdl_external_validation_success_step_keys(),
        'contract publishes the bounded success step keys',
    );
    is_deeply(
        $contract->{success_presence_key_family_map},
        hdl_external_validation_success_presence_key_family_map(),
        'contract publishes the bounded grouped success key-family map',
    );
    is_deeply(
        $contract->{success_step_names},
        hdl_external_validation_success_step_names(),
        'contract publishes the bounded success step names',
    );
    is_deeply(
        $contract->{failure_mode_names},
        hdl_external_validation_failure_mode_names(),
        'contract publishes the bounded external validation failure mode names',
    );
    is_deeply(
        $contract->{failure_mode_family_map},
        hdl_external_validation_failure_mode_family_map(),
        'contract publishes the grouped external validation failure mode families',
    );
    is_deeply(
        $contract->{failure_text_prefix_map},
        hdl_external_validation_failure_text_prefix_map(),
        'contract publishes the bounded external validation failure text prefixes',
    );
    ok(!$contract->{yosys_abc_enabled}, 'contract says the ABC algorithm is disabled');
    ok(
        grep({ /ABC executable discovery is optional metadata/ } @{$contract->{guidance} || []}),
        'contract guidance explains that optional ABC discovery does not enable ABC validation',
    );
    ok(
        grep({ /abc_mapping => 1/ } @{$contract->{guidance} || []}),
        'contract guidance records the explicit ABC mapping opt-in',
    );
    ok($contract->{in_process_failures_throw}, 'contract says in-process failures throw');
    ok($contract->{cli_failures_exit_nonzero}, 'contract says CLI failures exit non-zero');
};

subtest 'ABC mapping executable discovery is optional and non-gating' => sub {
    my $tools = hdl_external_validation_tools();

    is_deeply(
        [sort keys %{$tools}],
        [qw(abc_mapping abc_mapping_tool verilator yosys)],
        'tool discovery reports required tools plus optional ABC mapping metadata',
    );
    is_deeply(
        [hdl_external_validation_required_tools()],
        [qw(verilator yosys)],
        'runtime required-tool list stays Verilator/Yosys only',
    );
    is_deeply(
        [hdl_external_validation_abc_tool_candidates()],
        [qw(yosys-abc berkeley-abc abc)],
        'runtime probes the supported ABC executable names in priority order',
    );

    my $success = write_exit_program(tempdir(CLEANUP => 1), 'success', 0);
    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $success,
                yosys => $success,
                abc_mapping => undef,
                abc_mapping_tool => undef,
            };
        };
        is_deeply(
            [missing_systemverilog_validation_tools()],
            [],
            'missing-tool checks do not require optional ABC mapping discovery',
        );
        like(
            capture_error(sub {
                validate_systemverilog_file(
                    source_file => __FILE__,
                    top_module => 'demo_top',
                    abc_mapping => 1,
                );
            }),
            qr/Missing external HDL validation tool\(s\): abc_mapping/,
            'explicit ABC mapping opt-in requires optional ABC discovery',
        );
    }
};

subtest 'deterministic in-process failures keep the bounded prefixes' => sub {
    my $prefixes = hdl_external_validation_failure_text_prefix_map();

    like(
        capture_error(sub {
            validate_systemverilog_file(top_module => 'demo_top');
        }),
        qr/^\Q$prefixes->{missing_source_file}\E/,
        'missing source_file keeps the bounded prefix',
    );

    like(
        capture_error(sub {
            validate_systemverilog_file(source_file => __FILE__);
        }),
        qr/^\Q$prefixes->{missing_top_module}\E/,
        'missing top_module keeps the bounded prefix',
    );

    my $missing_source = File::Spec->catfile(tempdir(CLEANUP => 1), 'missing.sv');
    like(
        capture_error(sub {
            validate_systemverilog_file(
                source_file => $missing_source,
                top_module => 'demo_top',
            );
        }),
        qr/^\Q$prefixes->{source_file_not_found}\E/,
        'missing source path keeps the bounded prefix',
    );

    my $tempdir = tempdir(CLEANUP => 1);
    my $sv_path = File::Spec->catfile($tempdir, 'demo_top.sv');
    write_file(
        $sv_path,
        <<'SV'
module demo_top;
endmodule
SV
    );

    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => undef,
                yosys => undef,
            };
        };
        like(
            capture_error(sub {
                validate_systemverilog_file(
                    source_file => $sv_path,
                    top_module => 'demo_top',
                );
            }),
            qr/^\Q$prefixes->{missing_tools}\E/,
            'missing tools keeps the bounded prefix',
        );
    }

    my $success = write_exit_program($tempdir, 'success', 0);
    my $failure = write_exit_program($tempdir, 'failure', 1);
    my $path_trap = tempdir(CLEANUP => 1);
    write_exit_program($path_trap, 'true', 97);
    write_exit_program($path_trap, 'false', 98);
    local $ENV{PATH} = $path_trap;

    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $success,
                yosys => $success,
            };
        };
        my $report = validate_systemverilog_file(
            source_file => $sv_path,
            top_module => 'demo_top',
        );
        ok(
            $report->{ok},
            'explicit repository-local success fixture ignores hostile PATH aliases',
        );
        is_deeply(
            [map { [@{$_->{command}}[0, 1]] } @{$report->{steps}}],
            [[$perl, $success], [$perl, $success]],
            'plain Perl tool scripts use explicit canonical-interpreter argv',
        );
        like(
            capture_error(sub {
                validate_systemverilog_file(
                    source_file => $sv_path,
                    top_module => 'bad-top-name',
                );
            }),
            qr/^\Q$prefixes->{unsupported_top_module_identifier}\E/,
            'unsupported top-module identifier keeps the bounded prefix',
        );
    }

    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $failure,
                yosys => $success,
            };
        };
        my $failure_text = capture_error(sub {
                validate_systemverilog_file(
                    source_file => $sv_path,
                    top_module => 'demo_top',
                );
            });
        like(
            $failure_text,
            qr/^\Q$prefixes->{tool_step_failed}\E/,
            'tool-step failure keeps the bounded prefix',
        );
        like(
            $failure_text,
            qr/deterministic failure fixture/,
            'explicit repository-local failure fixture keeps its failure truth',
        );
    }
};

subtest 'sealed supervisor policy preserves every first-failure class' => sub {
    my @outcome = (
        [timed_out => 'supervised process exceeded its fixed deadline'],
        [output_limited => 'supervised process exceeded its aggregate capture limit'],
        [exec_error => 'exec failed: deterministic fixture'],
        [signaled => 'supervised process exited after a signal'],
        [nonzero_exit => 'supervised process exited nonzero'],
        [surviving_descendants => 'supervised process left descendants after leader exit'],
        [cleanup_failed => 'supervised process cleanup could not prove leader and group disappearance'],
        [host_error => 'deterministic host failure'],
    );
    my $prefix = hdl_external_validation_failure_text_prefix_map()
        ->{tool_step_failed};

    for my $outcome (@outcome) {
        my ($status, $diagnostic) = @$outcome;
        my @request;
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $perl,
                yosys => $perl,
                abc_mapping => undef,
                abc_mapping_tool => undef,
            };
        };
        local *FSM::Support::HDLExternalValidation::supervise_process = sub {
            my (%args) = @_;
            push @request, \%args;
            return {
                ok => 0,
                status => $status,
                diagnostic => $diagnostic,
                stdout => "bounded stdout\n",
                stderr => "bounded stderr\n",
            };
        };

        my $failure = capture_error(sub {
            validate_systemverilog_file(
                source_file => __FILE__,
                top_module => 'demo_top',
            );
        });
        is(scalar(@request), 1, "$status fails the first step without retry");
        is(
            $request[0]{schema},
            'fsmgen.hdl_external_validation_process_result.v1',
            "$status uses the sealed process-result schema",
        );
        is($request[0]{stage}, 'verilator_lint', "$status retains the stage");
        is(
            $request[0]{bounds}{timeout_seconds},
            120,
            "$status cannot widen the fixed wall",
        );
        is(
            $request[0]{bounds}{capture_limit_bytes},
            8_388_608,
            "$status cannot widen the aggregate capture ceiling",
        );
        is(
            $request[0]{containment},
            'hdl_external_validation_process_group',
            "$status uses the sealed process-group identity",
        );
        is(
            $request[0]{cwd},
            repository_root(),
            "$status launches from the repository-derived cwd",
        );
        is(ref($request[0]{argv}), 'ARRAY', "$status is passed as argv");
        like(
            $failure,
            qr/^\Q$prefix\Everilator_lint' failed/m,
            "$status retains the external step-failure prefix",
        );
        like(
            $failure,
            qr/^Reason: status=\Q$status\E: \Q$diagnostic\E$/m,
            "$status and diagnostic remain explicit",
        );
        like($failure, qr/^stdout:\nbounded stdout$/m, "$status retains stdout");
        like($failure, qr/^stderr:\nbounded stderr$/m, "$status retains stderr");
    }

    my $source = slurp(File::Spec->catfile(
        repository_root(), qw(perl FSM Support HDLExternalValidation.pm),
    ));
    unlike(
        $source,
        qr/use IPC::Cmd qw\([^)]*\brun\b|\bIPC::Cmd::run\b|\brun\s*\(\s*command\s*=>/,
        'HDL validation retains discovery but has no direct IPC::Cmd launch',
    );
};

subtest 'successful in-process external validation conforms to the bounded contract' => sub {
    my @missing_tools = missing_systemverilog_validation_tools();
    plan skip_all => 'External SystemVerilog validation tools are not installed: ' . join(', ', @missing_tools)
        if @missing_tools;

    my $tempdir = tempdir(CLEANUP => 1);
    my $sv_path = File::Spec->catfile($tempdir, 'hdl_external_validation_contract.sv');

    write_file(
        $sv_path,
        <<'SV'
module hdl_external_validation_contract;
endmodule
SV
    );

    my $report = validate_systemverilog_file(
        source_file => $sv_path,
        top_module => 'hdl_external_validation_contract',
    );

    assert_keys_present(
        $report,
        hdl_external_validation_success_top_level_keys(),
        'success report keeps bounded top-level keys',
    );
    ok($report->{ok}, 'success report marks ok true');
    is_deeply(
        [map { $_->{name} } @{$report->{steps}}],
        hdl_external_validation_success_step_names(),
        'success report keeps the bounded step order',
    );

    for my $step (@{$report->{steps} || []}) {
        assert_keys_present(
            $step,
            hdl_external_validation_success_step_keys(),
            "step $step->{name} keeps bounded step keys",
        );
    }
};

done_testing();

sub capture_error {
    my ($code) = @_;
    my $error = eval {
        $code->();
        return undef;
    };
    return "$@" if $@;
    return $error;
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

sub write_exit_program {
    my ($directory, $name, $status) = @_;
    die "Fixture status must be a non-negative integer"
        unless defined($status) && !ref($status) && $status =~ /\A[0-9]+\z/;
    my $path = File::Spec->catfile($directory, $name);
    my $diagnostic = $status
        ? qq{print STDERR "deterministic failure fixture\\n";\n}
        : '';
    write_file(
        $path,
        "#!$perl\nuse strict;\nuse warnings;\n${diagnostic}exit $status;\n",
    );
    chmod 0755, $path or die "Cannot make $path executable: $!";
    return $path;
}
