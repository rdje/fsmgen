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
use FSM::Support::HDLExternalValidation qw(
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);

my @missing_tools = missing_systemverilog_validation_tools();
if (@missing_tools) {
    plan skip_all => 'External SystemVerilog validation tools are not installed: ' . join(', ', @missing_tools);
}

subtest 'generated lte_dif_pmaster SystemVerilog passes Verilator lint and Yosys synthesis lowering' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $sv_file = File::Spec->catfile($tempdir, 'lte_dif_pmaster.sv');
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'lte_dif_pmaster.fsm');

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
    my $report = validate_systemverilog_file(
        source_file => $sv_file,
        top_module => $result->{module_info}{module_name},
    );

    ok($report->{ok}, 'external validation report succeeds');
    is_deeply(
        [map { $_->{name} } @{$report->{steps}}],
        [qw(verilator_lint yosys_synthesis)],
        'external validation runs Verilator lint before Yosys synthesis lowering',
    );
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

    ok(!$success, 'CLI rejects --verify-hdl for VHDL while VHDL emission is not active');
    like(
        join('', @{$stderr_buf || []}),
        qr/--verify-hdl currently supports generated SystemVerilog only/,
        'CLI explains the current SV-only validation boundary',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
