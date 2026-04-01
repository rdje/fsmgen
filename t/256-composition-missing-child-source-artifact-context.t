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

subtest 'missing external ?fsmc child keeps expected child artifact context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_fsmc_child_artifact_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_fsmc_child_artifact_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_fsmc_child_artifact_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child missing_src)
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects missing external ?fsmc child source');
    like($exception, qr/Source file:\s+'\Q$composition_path\E'/s, 'pipeline keeps the composition source file');
    like($exception, qr/Expected child source file:\s+'missing_src\.fsm'/s, 'pipeline keeps the expected child source file artifact');
    like($exception, qr/Generated child source:\s+'\?fsmc' 'missing_src'/s, 'pipeline keeps the missing ?fsmc child identity');
    like($exception, qr/child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s, 'pipeline keeps the blocked ?fsmc resolution diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects missing external ?fsmc child source');
    ok(!-e $output_path, 'CLI does not emit HDL for missing external ?fsmc child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$composition_path\E'/s, 'CLI keeps the composition source file');
    like($combined_output, qr/Expected child source file:\s+'missing_src\.fsm'/s, 'CLI keeps the expected child source file artifact');
    like($combined_output, qr/Generated child source:\s+'\?fsmc' 'missing_src'/s, 'CLI keeps the missing ?fsmc child identity');
    like($combined_output, qr/child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s, 'CLI keeps the blocked ?fsmc resolution diagnostic');
};

subtest 'missing external ?dtc child keeps expected child artifact context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_dtc_child_artifact_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_dtc_child_artifact_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_dtc_child_artifact_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?dtc:child missing_dt_src)
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects missing external ?dtc child source');
    like($exception, qr/Source file:\s+'\Q$composition_path\E'/s, 'pipeline keeps the composition source file');
    like($exception, qr/Expected child source file:\s+'missing_dt_src\.fsm'/s, 'pipeline keeps the expected child source file artifact');
    like($exception, qr/Generated child source:\s+'\?dtc' 'missing_dt_src'/s, 'pipeline keeps the missing ?dtc child identity');
    like($exception, qr/child-source resolution is blocked because no active standalone-DT child source was found either embedded in the same file or in an external '\.fsm' file/s, 'pipeline keeps the blocked ?dtc resolution diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects missing external ?dtc child source');
    ok(!-e $output_path, 'CLI does not emit HDL for missing external ?dtc child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$composition_path\E'/s, 'CLI keeps the composition source file');
    like($combined_output, qr/Expected child source file:\s+'missing_dt_src\.fsm'/s, 'CLI keeps the expected child source file artifact');
    like($combined_output, qr/Generated child source:\s+'\?dtc' 'missing_dt_src'/s, 'CLI keeps the missing ?dtc child identity');
    like($combined_output, qr/child-source resolution is blocked because no active standalone-DT child source was found either embedded in the same file or in an external '\.fsm' file/s, 'CLI keeps the blocked ?dtc resolution diagnostic');
};

done_testing();

sub new_pipeline {
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
