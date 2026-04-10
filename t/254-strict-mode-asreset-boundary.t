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
my $libdir = File::Spec->catdir($tempdir, 'strict_asreset_lib');
mkdir $libdir or die "Cannot create $libdir: $!";

my $direct_path = File::Spec->catfile($tempdir, 'strict_asreset_direct.fsm');
my $direct_out_path = File::Spec->catfile($tempdir, 'strict_asreset_direct.sv');
my $sync_low_name_path = File::Spec->catfile($tempdir, 'strict_sreset_low_name_direct.fsm');

my $child_top_path = File::Spec->catfile($tempdir, 'strict_asreset_child_top.fsm');
my $child_out_path = File::Spec->catfile($tempdir, 'strict_asreset_child_top.sv');
my $child_path = File::Spec->catfile($libdir, 'child_async_reset.fsm');

write_file(
    $direct_path,
    <<'FSM'
(?fsm:strict_asreset_direct
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (A 1)
  )
  (-dt
    (A = 1)
  )
)
FSM
);

write_file(
    $sync_low_name_path,
    <<'FSM'
(?fsm:strict_sreset_low_name_direct
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
  )
  (-dt
    (A = 1)
  )
)
FSM
);

write_file(
    $child_top_path,
    <<'FSM'
(?top:strict_asreset_child_top
  (?ports:public_io
    clk<1
    rstn<1
    data_in<1
    data_out>1
  )
  (?fsmc:child child_async_reset)
)
FSM
);

write_file(
    $child_path,
    <<'FSM'
(?fsm:child_async_reset
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (data_in 1)
    (data_out 1)
  )
  (-dt
    (data_out> = data_in)
  )
)
FSM
);

subtest 'default mode still accepts explicit asreset as compatibility residue' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($direct_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_asreset_direct\b/s,
        'default-mode pipeline still compiles the explicit asreset form',
    );
};

subtest 'shared frontend strict boundary rejects the legacy explicit asreset spelling' => sub {
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
        qr/Strict mode rejects the legacy or misleading '\(asreset rstn\)' \+system spelling in source '\Q$direct_path\E'.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'shared frontend keeps the canonical explicit +system migration hint',
    );
};

subtest 'shared frontend strict boundary rejects misleading active-low-looking sreset names' => sub {
    my $raw_ast = Lispish::multi($sync_low_name_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $sync_low_name_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects the legacy or misleading '\(sreset rstn\)' \+system spelling in source '\Q$sync_low_name_path\E'.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'shared frontend rejects sreset with active-low-looking reset names in strict mode',
    );
};

subtest 'strict pipeline and CLI reject explicit asreset at the top level' => sub {
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
        qr/Source file:\s+'\Q$direct_path\E'.*Strict mode rejects the legacy or misleading '\(asreset rstn\)' \+system spelling.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'strict pipeline keeps source-file context around the explicit asreset boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $direct_out_path, $direct_path],
    );

    ok(!$success, 'CLI strict mode rejects the explicit asreset form');
    ok(!-e $direct_out_path, 'CLI strict mode does not emit HDL for the explicit asreset form');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$direct_path\E'.*Strict mode rejects the legacy or misleading '\(asreset rstn\)' \+system spelling.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'CLI strict mode surfaces the same explicit asreset migration hint',
    );
};

subtest 'strict mode also rejects external ?fsmc children that use explicit asreset' => sub {
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
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?fsmc' 'child_async_reset'.*Strict mode rejects the legacy or misleading '\(asreset rstn\)' \+system spelling in source 'child_async_reset'.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'strict pipeline keeps full child-source context around the explicit asreset boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $child_out_path, $child_top_path],
    );

    ok(!$success, 'CLI strict mode rejects external ?fsmc children that use explicit asreset');
    ok(!-e $child_out_path, 'CLI strict mode does not emit HDL for external ?fsmc children that use explicit asreset');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?fsmc' 'child_async_reset'.*Strict mode rejects the legacy or misleading '\(asreset rstn\)' \+system spelling in source 'child_async_reset'.*Use '\(sreset reset\)' for synchronous active-high reset or '\(areset rst_n\)' for asynchronous active-low reset/s,
        'CLI strict mode surfaces the same explicit asreset child-source boundary',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
