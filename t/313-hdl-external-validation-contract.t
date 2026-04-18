#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLExternalValidation qw(
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);
use FSM::Support::HDLExternalValidationContract qw(
    build_hdl_external_validation_contract
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
        'FSM::Support::HDLExternalValidationContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::HDLExternalValidation',
        'contract records the validation owner',
    );
    is_deeply(
        $contract->{tools},
        [qw(verilator yosys)],
        'contract records the required tools',
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
        $contract->{success_step_names},
        hdl_external_validation_success_step_names(),
        'contract publishes the bounded success step names',
    );
    ok(!$contract->{yosys_abc_enabled}, 'contract says the ABC algorithm is disabled');
    ok($contract->{in_process_failures_throw}, 'contract says in-process failures throw');
    ok($contract->{cli_failures_exit_nonzero}, 'contract says CLI failures exit non-zero');
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
