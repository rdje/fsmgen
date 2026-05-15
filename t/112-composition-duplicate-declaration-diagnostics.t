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
my $duplicate_top_port_path = File::Spec->catfile($tempdir, 'duplicate_top_port_top.fsm');
my $duplicate_child_instance_path = File::Spec->catfile($tempdir, 'duplicate_child_instance_top.fsm');

write_file(
    $duplicate_top_port_path,
    <<'FSM'
(?top:duplicate_top_port_top
  (?ports:public_io
    clk
    rstn
    output_data>8
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
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
    $duplicate_child_instance_path,
    <<'FSM'
(?top:duplicate_child_instance_top
  (?ports:public_io
    clk
    rstn
    start
    result_data>8
  )
  (?fsmc:dup producer_src)
  (?fsmc:dup consumer_src)
  (?wiring:wiring
    /start/dup.go/
    /dup.output_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'2)
    )
  )
  (+size
    (go 1)
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'3)
    )
  )
  (+size
    (go 1)
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

subtest 'duplicate top ports now say composition shape is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($duplicate_top_port_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares duplicate top port 'output_data' in '\?ports', .*composition shape is blocked because the active composition lanes require each top port name to be unique/s,
        'duplicate top ports now say composition shape is blocked',
    );
};

subtest 'duplicate child instance names now say composition shape is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($duplicate_child_instance_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares duplicate child instance name 'dup', .*composition shape is blocked because the active composition lanes require each realized child instance name to be unique/s,
        'duplicate child instance names now say composition shape is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
