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
my $system_byname_path = File::Spec->catfile($tempdir, 'system_byname_top.fsm');
my $unsupported_endpoint_path = File::Spec->catfile($tempdir, 'unsupported_endpoint_top.fsm');

write_file(
    $system_byname_path,
    <<'FSM'
(?top:system_byname_top
  (?ports:public_io
    =clk
    result_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
);

write_file(
    $unsupported_endpoint_path,
    <<'FSM'
(?top:unsupported_endpoint_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data.extra/result_data/
  )
)

(?fsm:producer_src
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'3)
  )
  (+size
    (final_data 8)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'shared system ports now say declared connect-by-name is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($system_byname_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/marks top port 'clk' for declared connect-by-name, .*declared connect-by-name is blocked because the shared system ports '.*' already use the dedicated system-input contract and must not be declared with '=port' connect-by-name syntax/s,
        'shared system ports now say declared connect-by-name is blocked',
    );
};

subtest 'unsupported explicit endpoint syntax now says endpoint resolution is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($unsupported_endpoint_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses explicit endpoint 'producer\.output_data\.extra', .*explicit link endpoint resolution is blocked because that syntax is unsupported.*accept only top-port names, source-side top-port bit\/slice expressions like 'data_bus\[3\]' or 'data_bus\[7:4\]', source-side child-port bit\/slice expressions like 'producer\.payload\[3\]' or 'producer\.payload\[7:4\]', or 'instance\.port' child endpoints/s,
        'unsupported explicit endpoint syntax now says endpoint resolution is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
