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

subtest 'external rtl metadata failures keep metadata and parent source context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'external_bad_rtlif_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'external_bad_rtlif_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:external_bad_rtlif_top
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
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    write_file(
        $metadata_path,
        <<'RTLIF'
@@@
RTLIF
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects malformed external rtl metadata');
    like($exception, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'pipeline keeps the sidecar metadata file');
    like($exception, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'pipeline keeps the parent composition source');
    like($exception, qr/RTL child module:\s+'\?rtl' 'uart_tx'/s, 'pipeline names the rtl child module');
    like($exception, qr/RTL interface metadata structure is blocked because declared interface metadata '\Q$metadata_path\E' does not contain a '\?rtlif:uart_tx' root\./s, 'pipeline keeps the underlying rtlif diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects malformed external rtl metadata');
    ok(!-e $output_path, 'CLI does not emit HDL for malformed external rtl metadata');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI keeps the sidecar metadata file');
    like($combined_output, qr/Parent composition source:\s+'\Q$composition_path\E'/s, 'CLI keeps the parent composition source');
    like($combined_output, qr/RTL child module:\s+'\?rtl' 'uart_tx'/s, 'CLI names the rtl child module');
    like($combined_output, qr/RTL interface metadata structure is blocked because declared interface metadata '\Q$metadata_path\E' does not contain a '\?rtlif:uart_tx' root\./s, 'CLI keeps the underlying rtlif diagnostic');
};

subtest 'embedded rtl metadata failures keep composition source context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'embedded_bad_rtlif_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'embedded_bad_rtlif_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:embedded_bad_rtlif_top
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
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)

(?rtlif:uart_tx
  clk:clock
  rstn:reset
  (group
    data_in<8:data
  )
  txd>:data
)
FSM
    );

    my $pipeline = new_pipeline();
    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    ok($exception, 'pipeline rejects malformed embedded rtl metadata');
    like($exception, qr/Source file:\s+'\Q$composition_path\E'/s, 'pipeline keeps the composition source file');
    like($exception, qr/RTL child module:\s+'\?rtl' 'uart_tx'/s, 'pipeline names the rtl child module');
    like($exception, qr/RTL interface metadata flatness is blocked because declared interface metadata '\Q$composition_path\E:\?rtlif:uart_tx' contains nested structure under '\?rtlif:uart_tx'\./s, 'pipeline keeps the underlying embedded rtlif diagnostic');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects malformed embedded rtl metadata');
    ok(!-e $output_path, 'CLI does not emit HDL for malformed embedded rtl metadata');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Source file:\s+'\Q$composition_path\E'/s, 'CLI keeps the composition source file');
    like($combined_output, qr/RTL child module:\s+'\?rtl' 'uart_tx'/s, 'CLI names the rtl child module');
    like($combined_output, qr/RTL interface metadata flatness is blocked because declared interface metadata '\Q$composition_path\E:\?rtlif:uart_tx' contains nested structure under '\?rtlif:uart_tx'\./s, 'CLI keeps the underlying embedded rtlif diagnostic');
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
