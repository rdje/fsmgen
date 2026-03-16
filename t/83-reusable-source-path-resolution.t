#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);

subtest 'CLI resolves bare standalone-DT sources through repeated --path roots' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'dt_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $dt_path = File::Spec->catfile($libdir, 'lookup_block.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'lookup_block.sv');

    write_file(
        $dt_path,
        <<'FSM'
(?dt:lookup_block_mod
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-drive
    (DATA_OUT = DATA_IN)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, 'lookup_block'],
    );

    ok($success, 'CLI succeeds when bare source name is supplied through --path');
    ok(-e $output_path, 'CLI writes HDL output for a source resolved through --path');

    my $hdl = slurp($output_path);
    like($hdl, qr/\bmodule\s+lookup_block_mod\b/s, 'resolved source generates the expected standalone-DT module');
    unlike($hdl, qr/\binput\s+wire\s+clk\b/s, 'combinational standalone-DT lookup still does not inject implicit clk');
};

subtest 'explicit --path roots win before FSMLIB for bare input lookup' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $explicit_dir = File::Spec->catdir($tempdir, 'explicit_root');
    my $env_dir = File::Spec->catdir($tempdir, 'env_root');
    mkdir $explicit_dir or die "Cannot create $explicit_dir: $!";
    mkdir $env_dir or die "Cannot create $env_dir: $!";

    write_file(
        File::Spec->catfile($explicit_dir, 'priority_lookup.fsm'),
        <<'FSM'
(?dt:from_explicit_root
  (+size
    (OUT 1)
  )
  (-drive
    (OUT = 1)
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($env_dir, 'priority_lookup.fsm'),
        <<'FSM'
(?dt:from_env_root
  (+size
    (OUT 1)
  )
  (-drive
    (OUT = 0)
  )
)
FSM
    );

    my $output_path = File::Spec->catfile($tempdir, 'priority_lookup.sv');
    local $ENV{FSMLIB} = $env_dir;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--path', $explicit_dir, '-o', $output_path, 'priority_lookup'],
    );

    ok($success, 'CLI succeeds when both --path and FSMLIB provide the same bare source name');
    my $hdl = slurp($output_path);
    like($hdl, qr/\bmodule\s+from_explicit_root\b/s, 'explicit --path root wins ahead of FSMLIB');
    unlike($hdl, qr/\bmodule\s+from_env_root\b/s, 'FSMLIB fallback does not override an explicit --path root');
};

subtest '--path roots also feed external RTL interface metadata lookup' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $metadata_dir = File::Spec->catdir($tempdir, 'rtlif_lib');
    mkdir $metadata_dir or die "Cannot create $metadata_dir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'path_lookup_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'path_lookup_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:path_lookup_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'7)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($metadata_dir, 'uart_tx.rtlif'),
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--path', $metadata_dir, '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds when external RTL metadata is found through --path');
    ok(-e $output_path, 'CLI writes HDL output when .rtlif metadata is resolved through --path');

    my $hdl = slurp($output_path);
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top instantiates the external RTL child found through --path');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
