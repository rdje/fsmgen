#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $libdir = File::Spec->catdir($tempdir, 'strict_compact_init_lib');
mkdir $libdir or die "Cannot create $libdir: $!";

my $direct_path = File::Spec->catfile($tempdir, 'strict_compact_init_direct.fsm');
my $direct_out_path = File::Spec->catfile($tempdir, 'strict_compact_init_direct.sv');
my $canonical_direct_path = File::Spec->catfile($tempdir, 'strict_canonical_init_direct.fsm');
my $canonical_direct_out_path = File::Spec->catfile($tempdir, 'strict_canonical_init_direct.sv');

my $child_top_path = File::Spec->catfile($tempdir, 'strict_compact_init_child_top.fsm');
my $child_out_path = File::Spec->catfile($tempdir, 'strict_compact_init_child_top.sv');
my $child_path = File::Spec->catfile($libdir, 'child_compact_init_dt.fsm');

write_file(
    $direct_path,
    <<'FSM'
(?fsm:strict_compact_init_direct
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (tester_reset 1)
    (A 1)
  )
  (:= tester_reset=1)
  (idle
    (A = tester_reset)
  )
)
FSM
);

write_file(
    $child_top_path,
    <<'FSM'
(?top:strict_compact_init_child_top
  (?ports:public_io
    clk
    rst_n
    data_in<8
    ACC>8
  )
  (?dtc:router child_compact_init_dt)
)
FSM
);

write_file(
    $child_path,
    <<'FSM'
(?dt:child_compact_init_dt
  (+size
    (ACC 8)
    (data_in 8)
  )
  (:= ACC=8'0)
  (-capture
    (ACC <- data_in)
  )
)
FSM
);

write_file(
    $canonical_direct_path,
    <<'FSM'
(?fsm:strict_canonical_init_direct
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (tester_reset 1)
    (A 1)
  )
  (:= (tester_reset 1))
  (idle
    (A = tester_reset)
  )
)
FSM
);

subtest "default mode still accepts the compact ':=' directive as compatibility residue" => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($direct_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_compact_init_direct\b/s,
        "default-mode pipeline still compiles the compact ':=' form",
    );
};

subtest "strict mode accepts the canonical Lisp-ish ':=' directive" => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($canonical_direct_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_canonical_init_direct\b/s,
        "strict-mode pipeline compiles the canonical ':=' form",
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $canonical_direct_out_path, $canonical_direct_path],
    );

    ok($success, "CLI strict mode accepts the canonical ':=' form");
    ok(-e $canonical_direct_out_path, "CLI strict mode emits HDL for the canonical ':=' form");
};

subtest "shared frontend strict boundary rejects the legacy compact ':=' directive" => sub {
    my $raw_ast = Lispish::multi($direct_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $direct_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects the legacy compact '\(:= signal=value\)' top-level directive in source '\Q$direct_path\E'.*Use the canonical '\(:= \(signal value\)\)' form.*re-run without strict mode if you still need the compact ':=' surface/s,
        "shared frontend keeps the explicit compact ':=' support-tier note",
    );
};

subtest "strict pipeline and CLI reject compact ':=' at the top level" => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($direct_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$direct_path\E'.*Strict mode rejects the legacy compact '\(:= signal=value\)' top-level directive.*Use the canonical '\(:= \(signal value\)\)' form.*compact ':=' surface/s,
        "strict pipeline keeps source-file context around the compact ':=' boundary",
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $direct_out_path, $direct_path],
    );

    ok(!$success, "CLI strict mode rejects the compact ':=' form");
    ok(!-e $direct_out_path, "CLI strict mode does not emit HDL for the compact ':=' form");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$direct_path\E'.*Strict mode rejects the legacy compact '\(:= signal=value\)' top-level directive.*Use the canonical '\(:= \(signal value\)\)' form.*compact ':=' surface/s,
        "CLI strict mode surfaces the same compact ':=' support-tier note",
    );
};

subtest "strict mode also rejects external ?dtc children that use compact ':='" => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($child_top_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_compact_init_dt'.*Strict mode rejects the legacy compact '\(:= signal=value\)' top-level directive in source 'child_compact_init_dt'.*Use the canonical '\(:= \(signal value\)\)' form.*compact ':=' surface/s,
        "strict pipeline keeps full child-source context around the compact ':=' boundary",
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $child_out_path, $child_top_path],
    );

    ok(!$success, "CLI strict mode rejects external ?dtc children that use compact ':='");
    ok(!-e $child_out_path, "CLI strict mode does not emit HDL for external ?dtc children that use compact ':='");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_compact_init_dt'.*Strict mode rejects the legacy compact '\(:= signal=value\)' top-level directive in source 'child_compact_init_dt'.*Use the canonical '\(:= \(signal value\)\)' form.*compact ':=' surface/s,
        "CLI strict mode surfaces the same compact ':=' child-source boundary",
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
