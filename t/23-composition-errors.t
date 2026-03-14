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
    qr/assigns explicit link driver 'producer_b\.output_data' to target 'result_data', .*already driven by explicit link 'producer_a\.output_data'/s,
    'composition planner rejects duplicate explicit drivers to the same target endpoint',
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

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
