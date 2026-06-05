#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::RegressionCorpus qw(protocol_fixture_entries);
use FSM::Support::HDLExternalValidation qw(
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);

my @missing_tools = missing_systemverilog_validation_tools();
if (@missing_tools) {
    plan skip_all => 'External SystemVerilog validation tools are not installed: ' . join(', ', @missing_tools);
}

subtest 'generated lte_dif_pmaster SystemVerilog passes Verilator lint and ABC-free Yosys synthesis' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $report = generate_and_validate($tempdir, 'fsm/lte_dif_pmaster.fsm');
    ok($report->{ok}, 'external validation report succeeds for lte_dif_pmaster');
    is_deeply(
        [map { $_->{name} } @{$report->{steps}}],
        [qw(verilator_lint yosys_synthesis)],
        'external validation runs Verilator lint before Yosys synthesis',
    );
    my ($yosys_step) = grep { $_->{name} eq 'yosys_synthesis' } @{$report->{steps}};
    my $yosys_script = $yosys_step->{command}[2];
    like(
        $yosys_script,
        qr/\bsynth\s+-noabc\s+-top\s+lte_dif_pmaster\b/,
        'Yosys validation explicitly synthesizes without ABC',
    );
    unlike(
        $yosys_script,
        qr/(?:^|[;\s])abc[0-9]?(?:\s|;|\z)/i,
        'Yosys validation does not run a standalone ABC pass',
    );
};

subtest 'generated MIPI examples with inferred widths pass external validation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    for my $sample (qw(
        fsm/mipicsi2_byteserial.fsm
        fsm/mipicsi2_configreg.fsm
        fsm/mipicsi2_fifo_4x8.fsm
        fsm/mipicsi2_pkt_nx4B_fifo.fsm
        fsm/mipicsi2_tester_ctrl.fsm
        fsm/mipicsi2_txtimer.fsm
    )) {
        my $report = generate_and_validate($tempdir, $sample);
        ok($report->{ok}, "$sample passes Verilator lint and ABC-free Yosys synthesis");
    }
};

subtest 'historical trial samples pass external validation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    for my $sample (qw(
        fsm/trial_0.fsm
        fsm/trial_1.fsm
    )) {
        my $report = generate_and_validate($tempdir, $sample);
        ok($report->{ok}, "$sample passes Verilator lint and ABC-free Yosys synthesis");
    }
};

subtest 'supported direct protocol fixtures pass external validation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my @direct_protocols = grep {
        ($_->{classification} || '') eq 'supported_smoke'
            && ($_->{coverage} || '') eq 'direct_root_pipeline_cli'
            && ($_->{source_kind} || '') eq 'fsm'
    } protocol_fixture_entries();

    ok(@direct_protocols, 'regression corpus exposes supported direct protocol fixtures');
    for my $entry (@direct_protocols) {
        my $report = generate_and_validate($tempdir, $entry->{relpath});
        ok(
            $report->{ok},
            "$entry->{id} passes Verilator lint and ABC-free Yosys synthesis",
        ) or diag(explain($report));
    }
};

subtest 'CLI --verify-hdl runs the external validation lane after writing SystemVerilog' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $sv_file = File::Spec->catfile($tempdir, 'lte_dif_pmaster_cli.sv');
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'lte_dif_pmaster.fsm');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--verify-hdl',
            '-o',
            $sv_file,
            $fsm_file,
        ],
        verbose => 0,
    );

    ok($success, 'CLI --verify-hdl succeeds for generated SystemVerilog')
        or diag("Error: " . ($error_message || 'unknown') . "\nstdout:\n"
            . join('', @{$stdout_buf || []}) . "\nstderr:\n" . join('', @{$stderr_buf || []}));
    ok(-s $sv_file, 'CLI writes the generated SystemVerilog file before validation');
};

subtest 'CLI --verify-hdl is currently SystemVerilog-only' => sub {
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'lte_dif_pmaster.fsm');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--verify-hdl',
            '--language',
            'vhdl',
            $fsm_file,
        ],
        verbose => 0,
    );

    ok(!$success, 'CLI rejects --verify-hdl for VHDL because validation remains SystemVerilog-only');
    like(
        join('', @{$stderr_buf || []}),
        qr/--verify-hdl currently supports generated SystemVerilog only/,
        'CLI explains the current SV-only validation boundary',
    );
};

done_testing();

sub generate_and_validate {
    my ($tempdir, $relative_fsm_file) = @_;
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', split('/', $relative_fsm_file));
    my ($module_name) = $relative_fsm_file =~ m{([^/]+)\.fsm\z};
    my $sv_file = File::Spec->catfile($tempdir, "$module_name.sv");

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result;
    {
        local $SIG{__WARN__} = sub { };
        $result = $pipeline->generate_hdl_from_file($fsm_file);
    }

    write_file($sv_file, $result->{hdl_code});
    return validate_systemverilog_file(
        source_file => $sv_file,
        top_module => $result->{module_info}{module_name},
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
