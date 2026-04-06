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

subtest 'pipeline and CLI resolve composition-root aggregate leaves for direct actuals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_aggregate_actuals.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_aggregate_actuals.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_aggregate_actuals
  (+constants
    (BYTES (8'hA5 8'h3C 0))
    (FRAME ((mode 3) (flag 1)))
    (NEST ((header ((nibble 4'hA))) (tail (1 0))))
  )
  (?ports:public_io
    byte_out>8
    flag_out>
    nibble_out>4
    tail_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=BYTES[0]/byte_out/
    /=FRAME.flag/flag_out/
    /=NEST.header.nibble/nibble_out/
    /=NEST.tail[0]/tail_out/
    /=BYTES[1]/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('BYTES[0]'),
        "8'hA5",
        'resolved top symbols expose local aggregate list leaves',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('FRAME.flag'),
        '1',
        'resolved top symbols expose local aggregate hash leaves',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('NEST.header.nibble'),
        "4'hA",
        'resolved top symbols expose local nested aggregate leaves',
    );

    like($hdl, qr/assign\s+byte_out\s*=\s*8'b10100101\s*;/, 'generated HDL emits local aggregate list-leaf top-output assignments');
    like($hdl, qr/assign\s+flag_out\s*=\s*1'b1\s*;/, 'generated HDL emits local aggregate hash-leaf top-output assignments');
    like($hdl, qr/assign\s+nibble_out\s*=\s*4'b1010\s*;/, 'generated HDL emits local nested aggregate top-output assignments');
    like($hdl, qr/assign\s+tail_out\s*=\s*1'b1\s*;/, 'generated HDL emits local nested aggregate list-leaf top-output assignments');
    like($hdl, qr/\.data_in\(8'b00111100\)/, 'generated HDL binds local aggregate leaves into child inputs');

    my @cmd = ('./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts local composition-root aggregate leaves');
    ok(-e $output_path, 'CLI emits HDL for local composition-root aggregate leaves');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for local composition-root aggregate leaves');
    unlike($combined_output, qr/aggregate value support is blocked/s, 'successful local aggregate CLI run does not report aggregate failures');
};

subtest 'pipeline and CLI resolve composition-root aggregate leaves for concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_aggregate_concat.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_aggregate_concat.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_aggregate_concat
  (+constants
    (FRAME ((enable 1)))
    (NIBBLES (4'h5 4'hA))
  )
  (?ports:public_io
    packed_out>5
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=FRAME.enable,=NIBBLES[1]/packed_out/
    /=FRAME.enable,=NIBBLES[0]/uart_tx.header_bus/
  )
)

(?rtlif:uart_tx
  header_bus<5:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    like($hdl, qr/assign\s+packed_out\s*=\s*\{1'b1,\s*4'b1010\}\s*;/, 'generated HDL emits local aggregate concat operands on top outputs');
    like($hdl, qr/\.header_bus\(\{1'b1,\s*4'b0101\}\)/, 'generated HDL emits local aggregate concat operands on child inputs');

    my @cmd = ('./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts local composition-root aggregate concat operands');
    ok(-e $output_path, 'CLI emits HDL for local composition-root aggregate concat operands');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for local composition-root aggregate concat operands');
    unlike($combined_output, qr/aggregate value support is blocked/s, 'successful local aggregate concat CLI run does not report aggregate failures');
};

subtest 'pipeline and CLI reject mixed composition-root aggregate value shapes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_top_aggregate_shape.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_top_aggregate_shape.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_top_aggregate_shape
  (+constants
    (BROKEN ((mode 3) 0))
  )
  (?ports:public_io
    status_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=0/status_out/
  )
)

(?rtlif:uart_tx
  dummy<1:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/mixed aggregate value/s,
        'pipeline rejects mixed composition-root aggregate value shapes explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects mixed composition-root aggregate value shapes');
    ok(!-e $output_path, 'CLI does not emit HDL for mixed composition-root aggregate value shapes');
    like(
        $combined_output,
        qr/mixed aggregate value/s,
        'CLI surfaces the mixed composition-root aggregate value boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for mixed composition-root aggregate value shapes');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
