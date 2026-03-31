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

subtest 'external malformed generated child keeps child and parent source context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'external_bad_child_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'child_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'external_bad_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:external_bad_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child child_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:child_src
  (bogus)
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects malformed external generated child source');
    like($exception, qr/Source file:\s+'\Q$child_path\E'/s, 'pipeline keeps the external child source file');
    like($exception, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'pipeline keeps the parent composition source file');
    like($exception, qr/Generated child source:\s+'\?fsmc' 'child_src'/s, 'pipeline names the generated child source context');
    like($exception, qr/Unsupported top-level form '\(bogus undef\)'/s, 'pipeline keeps the underlying malformed child diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects malformed external generated child source');
    ok(!-e $output_path, 'CLI does not emit HDL for malformed external generated child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$child_path\E'/s, 'CLI keeps the external child source file');
    like($combined_output, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'CLI keeps the parent composition source file');
    like($combined_output, qr/Generated child source:\s+'\?fsmc' 'child_src'/s, 'CLI names the generated child source context');
    like($combined_output, qr/Unsupported top-level form '\(bogus undef\)'/s, 'CLI keeps the underlying malformed child diagnostic');
};

subtest 'embedded malformed generated child keeps composition source context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'embedded_bad_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'embedded_bad_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:embedded_bad_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (bogus)
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects malformed embedded generated child source');
    like($exception, qr/Source file:\s+'\Q$composition_path\E'/s, 'pipeline keeps the composition source file for embedded child failures');
    like($exception, qr/Generated child source:\s+'\?fsmc' 'child_src'/s, 'pipeline names the embedded generated child source context');
    like($exception, qr/Unsupported top-level form '\(bogus undef\)'/s, 'pipeline keeps the underlying malformed embedded child diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects malformed embedded generated child source');
    ok(!-e $output_path, 'CLI does not emit HDL for malformed embedded generated child source');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$composition_path\E'/s, 'CLI keeps the composition source file for embedded child failures');
    like($combined_output, qr/Generated child source:\s+'\?fsmc' 'child_src'/s, 'CLI names the embedded generated child source context');
    like($combined_output, qr/Unsupported top-level form '\(bogus undef\)'/s, 'CLI keeps the underlying malformed embedded child diagnostic');
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
