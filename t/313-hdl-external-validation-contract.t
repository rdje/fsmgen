#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(can_run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLExternalValidation qw(
    hdl_external_validation_abc_tool_candidates
    hdl_external_validation_required_tools
    hdl_external_validation_tools
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);
use FSM::Support::HDLExternalValidationContract qw(
    hdl_external_validation_abc_mapping_status
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

    my $true = can_run('true') || '/usr/bin/true';
    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $true,
                yosys => $true,
                abc_mapping => undef,
                abc_mapping_tool => undef,
            };
        };
        is_deeply(
            [missing_systemverilog_validation_tools()],
            [],
            'missing-tool checks do not require optional ABC mapping discovery',
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

    my $true = can_run('true') || '/usr/bin/true';
    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $true,
                yosys => $true,
            };
        };
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

    my $false = can_run('false') || '/usr/bin/false';
    {
        no warnings 'redefine';
        local *FSM::Support::HDLExternalValidation::hdl_external_validation_tools = sub {
            return {
                verilator => $false,
                yosys => $true,
            };
        };
        like(
            capture_error(sub {
                validate_systemverilog_file(
                    source_file => $sv_path,
                    top_module => 'demo_top',
                );
            }),
            qr/^\Q$prefixes->{tool_step_failed}\E/,
            'tool-step failure keeps the bounded prefix',
        );
    }
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
