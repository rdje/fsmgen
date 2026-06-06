#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'pipeline and CLI do not emit HDL for unknown top-level + directives' => sub {
    my $fsm_path = write_fsm('unknown_top_level_directive.fsm', <<'FSM');
(?fsm:bad_top_level_directive
  (+bogus
    (foo bar)
  )
  (-dt
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects unknown top-level + directive');
    like($pipeline_error, qr/Unsupported top-level directive '\+bogus'/, 'pipeline surfaces the explicit unknown-+directive boundary');

    my $out_path = File::Spec->catfile($tempdir, 'unknown_top_level_directive.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects unknown top-level + directive');
    ok(!-e $out_path, 'CLI does not emit output for unknown top-level + directive');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported top-level directive '\+bogus'/, 'CLI surfaces the explicit unknown-+directive boundary');
};

subtest 'pipeline and CLI do not emit HDL for unsupported future-style top-level directives' => sub {
    my $fsm_path = write_fsm('future_style_top_level_directive.fsm', <<'FSM');
(?fsm:future_clock_directive
  (+clock clk)
  (+asreset rstn)
  (-dt
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects unsupported future-style + directive');
    like($pipeline_error, qr/Unsupported top-level directive '\+clock'/, 'pipeline surfaces the explicit unsupported-future-directive boundary');

    my $out_path = File::Spec->catfile($tempdir, 'future_style_top_level_directive.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects unsupported future-style + directive');
    ok(!-e $out_path, 'CLI does not emit output for unsupported future-style + directive');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported top-level directive '\+clock'/, 'CLI surfaces the explicit unsupported-future-directive boundary');
};

subtest 'pipeline and CLI do not emit HDL directly for package roots' => sub {
    my $pkg_path = write_fsm('package_root_no_direct_hdl.fsm', <<'FSM');
(?pkg:shared
  (+constants
    (WIDTH 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($pkg_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects direct HDL generation for package roots');
    like(
        $pipeline_error,
        qr/Package source '\?pkg:shared' does not generate HDL directly.*not as standalone HDL-generation roots/s,
        'pipeline surfaces the import-only package-root boundary',
    );

    my $sv_out_path = File::Spec->catfile($tempdir, 'package_root_no_direct_hdl.sv');
    my ($sv_success, $sv_error_message, $sv_full_buf, $sv_stdout_buf, $sv_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $sv_out_path, '--quiet', $pkg_path],
    );

    ok(!$sv_success, 'CLI rejects default HDL generation for package roots');
    ok(!-e $sv_out_path, 'CLI does not emit SystemVerilog output for package roots');

    my $sv_combined_output = join(
        '',
        @{ $sv_stdout_buf || [] },
        @{ $sv_stderr_buf || [] },
        ($sv_error_message || ''),
    );

    like(
        $sv_combined_output,
        qr/Package source '\?pkg:shared' does not generate HDL directly.*not as standalone HDL-generation roots/s,
        'CLI surfaces the import-only package-root boundary for the default target',
    );

    my $vhdl_out_path = File::Spec->catfile($tempdir, 'package_root_no_direct_hdl.vhd');
    my ($vhdl_success, $vhdl_error_message, $vhdl_full_buf, $vhdl_stdout_buf, $vhdl_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '-o', $vhdl_out_path, '--quiet', $pkg_path],
    );

    ok(!$vhdl_success, 'CLI rejects VHDL generation for package roots');
    ok(!-e $vhdl_out_path, 'CLI does not emit VHDL package output for package roots');

    my $vhdl_combined_output = join(
        '',
        @{ $vhdl_stdout_buf || [] },
        @{ $vhdl_stderr_buf || [] },
        ($vhdl_error_message || ''),
    );

    like(
        $vhdl_combined_output,
        qr/Package source '\?pkg:shared' does not generate HDL directly.*not as standalone HDL-generation roots/s,
        'CLI surfaces the import-only package-root boundary for VHDL',
    );
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
