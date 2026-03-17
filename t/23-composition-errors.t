#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'duplicate_driver_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'explicit_width_mismatch_top.fsm');
my $unknown_rtl_port_path = File::Spec->catfile($tempdir, 'unknown_rtl_port_top.fsm');
my $rtl_direction_mismatch_path = File::Spec->catfile($tempdir, 'rtl_direction_mismatch_top.fsm');
my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

write_file(
    $composition_path,
    <<'FSM'
(?top:duplicate_driver_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer_a producer_a_src)
  (?fsmc:producer_b producer_b_src)
  (?toplink:wiring
    /producer_a.output_data/result_data/
    /producer_b.output_data/result_data/
  )
)

(?fsm:producer_a_src
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

(?fsm:producer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

write_file(
    $width_mismatch_path,
    <<'FSM'
(?top:explicit_width_mismatch_top
  (?ports:public_io
    clk
    rstn
    result_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
);

write_file(
    $unknown_rtl_port_path,
    <<'FSM'
(?top:unknown_rtl_port_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.missing_port/
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
    $rtl_direction_mismatch_path,
    <<'FSM'
(?top:rtl_direction_mismatch_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.txd/
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
    $rtl_metadata_path,
    <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
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
    qr/assigns explicit link driver 'producer_b\.output_data' to target 'result_data', .*explicit link is blocked because that target is already driven by explicit link 'producer_a\.output_data'/s,
    'duplicate explicit drivers now say the explicit link is blocked',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'duplicate-driver diagnostics point to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'duplicate-driver diagnostics point to the legacy mapping note',
);

my $width_mismatch_exception = eval {
    $pipeline->generate_hdl_from_file($width_mismatch_path);
    undef;
};
$width_mismatch_exception = $@;

like(
    $width_mismatch_exception,
    qr/links 'consumer\.final_data' \(width 8\) to 'result_data' \(width 4\), .*explicit link is blocked because the current active composition lanes require exact width agreement/s,
    'explicit width mismatches now say the explicit link is blocked',
);
like(
    $width_mismatch_exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'explicit width-mismatch diagnostics point to the scoped composition doc',
);

my $unknown_rtl_port_exception = eval {
    $pipeline->generate_hdl_from_file($unknown_rtl_port_path);
    undef;
};
$unknown_rtl_port_exception = $@;

like(
    $unknown_rtl_port_exception,
    qr/references child endpoint 'uart_tx\.missing_port', .*explicit link endpoint resolution is blocked because instance 'uart_tx' has no port named 'missing_port'/s,
    'unknown external RTL ports now say explicit link endpoint resolution is blocked',
);
like(
    $unknown_rtl_port_exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'unknown external RTL port diagnostics point to the scoped composition doc',
);

my $rtl_direction_mismatch_exception = eval {
    $pipeline->generate_hdl_from_file($rtl_direction_mismatch_path);
    undef;
};
$rtl_direction_mismatch_exception = $@;

like(
    $rtl_direction_mismatch_exception,
    qr/uses child endpoint 'uart_tx\.txd' as an explicit link target, .*explicit link is blocked because that child port is output instead of input/s,
    'direction-mismatched external RTL targets now say the explicit link is blocked',
);
like(
    $rtl_direction_mismatch_exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'direction-mismatch diagnostics still point to the legacy mapping note',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
