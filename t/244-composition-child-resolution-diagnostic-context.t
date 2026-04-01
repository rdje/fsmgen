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

subtest 'wrong-kind external generated child keeps resolved child and parent context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'wrong_dtc_kind_context_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'child_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'wrong_dtc_kind_context_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:wrong_dtc_kind_context_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?dtc:child child_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:child_src
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects wrong-kind external generated child source');
    like($exception, qr/Source file:\s+'\Q$child_path\E'/s, 'pipeline keeps the resolved external child source file');
    like($exception, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'pipeline keeps the parent composition source file');
    like($exception, qr/Generated child source:\s+'\?dtc' 'child_src'/s, 'pipeline names the generated child source context');
    like($exception, qr/child-source realization is blocked because that resolved file is not an active standalone-DT child source/s, 'pipeline keeps the blocked wrong-kind diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects wrong-kind external generated child source');
    ok(!-e $output_path, 'CLI does not emit HDL for wrong-kind external generated child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$child_path\E'/s, 'CLI keeps the resolved external child source file');
    like($combined_output, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'CLI keeps the parent composition source file');
    like($combined_output, qr/Generated child source:\s+'\?dtc' 'child_src'/s, 'CLI names the generated child source context');
    like($combined_output, qr/child-source realization is blocked because that resolved file is not an active standalone-DT child source/s, 'CLI keeps the blocked wrong-kind diagnostic');
};

subtest 'missing external generated child keeps composition source context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_context_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_child_context_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_context_top
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

    ok($exception, 'pipeline rejects missing external generated child source');
    like($exception, qr/Source file:\s+'\Q$composition_path\E'/s, 'pipeline keeps the composition source file');
    unlike($exception, qr/Parent composition source:/s, 'pipeline does not invent a separate parent line when no external child file was resolved');
    like($exception, qr/Generated child source:\s+'\?fsmc' 'missing_src'/s, 'pipeline names the missing generated child source context');
    like($exception, qr/child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s, 'pipeline keeps the blocked missing-child diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects missing external generated child source');
    ok(!-e $output_path, 'CLI does not emit HDL for missing external generated child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$composition_path\E'/s, 'CLI keeps the composition source file');
    unlike($combined_output, qr/Parent composition source:/s, 'CLI does not invent a separate parent line when no external child file was resolved');
    like($combined_output, qr/Generated child source:\s+'\?fsmc' 'missing_src'/s, 'CLI names the missing generated child source context');
    like($combined_output, qr/child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s, 'CLI keeps the blocked missing-child diagnostic');
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
