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

subtest 'pipeline and CLI accept typed-list top expressions on aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_expr_list_target.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_top_expr_list_target.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_expr_list_target
  (+types
    (type status_t (list bit (bits 4)))
  )
  (?ports:public_io
    status_bus<2
    payload_bus<4
    packed_status>status_t
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /status_bus[0],payload_bus[3:0]/packed_status/
    /=0/uart_tx.dummy/
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  dummy<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign packed_status = {status_bus[0], payload_bus[3:0]};',
        ],
        'pipeline keeps the typed top-expression assignment when the aggregate target shape matches',
    );
    like(
        $result->{hdl_code},
        qr/assign packed_status = \{status_bus\[0\], payload_bus\[3:0\]\};/s,
        'generated HDL emits the typed top-expression assignment directly on the aggregate-typed top output',
    );

    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts compatible typed top-expression aggregate targets');
    ok(-e $output_path, 'CLI writes HDL for compatible typed top-expression aggregate targets');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for compatible typed top-expression aggregate targets');
    unlike($combined_output, qr/aggregate-expression binding|declared type/s, 'successful typed top-expression aggregate run does not report aggregate-expression failures');
};

subtest 'pipeline rejects width-equal top expressions across incompatible typed aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_expr_mismatch.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_expr_mismatch
  (+types
    (type wrong_t (record (flag bit) (payload (bits 4))))
  )
  (?ports:public_io
    status_bus<2
    payload_bus<4
    packed_status>wrong_t
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /status_bus[0],payload_bus[3:0]/packed_status/
    /=0/uart_tx.dummy/
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  dummy<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'status_bus\[0\],payload_bus\[3:0\]' as an explicit link source, .* explicit aggregate-expression binding is blocked because expression contract 'list<bit, bits\[4\]>' does not match target declared type 'record\{flag:bit, payload:bits\[4\]\}' on 'packed_status'/s,
        'pipeline blocks width-equal top-expression bindings when aggregate shape conflicts with the target declared type',
    );
};

subtest 'pipeline rejects width-equal child expressions across incompatible typed aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_child_expr_mismatch.fsm');
    my $producer_metadata_path = File::Spec->catfile($tempdir, 'producer.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_child_expr_mismatch
  (+types
    (type wrong_t (record (flag bit) (payload (bits 4))))
  )
  (?ports:public_io
    packed_status>wrong_t
  )
  (?rtl:producer)
  (?toplink:wiring
    /producer.OUT_WORD[4:0]/packed_status/
  )
)
FSM
    );

    write_file(
        $producer_metadata_path,
        <<'RTLIF'
(?rtlif:producer
  OUT_WORD>8:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses child expression 'producer\.OUT_WORD\[4:0\]' as an explicit link source, .* explicit aggregate-expression binding is blocked because expression contract 'bits\[5\]' does not match target declared type 'record\{flag:bit, payload:bits\[4\]\}' on 'packed_status'/s,
        'pipeline blocks width-equal child-expression bindings when aggregate shape conflicts with the target declared type',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
