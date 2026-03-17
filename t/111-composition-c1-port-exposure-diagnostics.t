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
my $missing_exposure_path = File::Spec->catfile($tempdir, 'c1_missing_exposure_top.fsm');
my $unknown_port_path = File::Spec->catfile($tempdir, 'c1_unknown_port_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'c1_width_mismatch_top.fsm');
my $direction_mismatch_path = File::Spec->catfile($tempdir, 'c1_direction_mismatch_top.fsm');

write_file(
    $missing_exposure_path,
    <<'FSM'
(?top:c1_missing_exposure_top
  (?ports:public_io
    clk
    rstn
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
    $unknown_port_path,
    <<'FSM'
(?top:c1_unknown_port_top
  (?ports:public_io
    clk
    rstn
    output_data>8
    extra_probe>8
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
    $width_mismatch_path,
    <<'FSM'
(?top:c1_width_mismatch_top
  (?ports:public_io
    clk
    rstn
    output_data>4
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
    $direction_mismatch_path,
    <<'FSM'
(?top:c1_direction_mismatch_top
  (?ports:public_io
    clk
    rstn
    output_data<8
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

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'missing child exposure now says C1 passthrough exposure is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($missing_exposure_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/C1 passthrough exposure is blocked because the current active C1 lane requires every child port to be explicitly exposed in '\?ports'.*Missing top exposure for child port 'output_data' on instance 'child'/s,
        'missing child exposure now says C1 passthrough exposure is blocked',
    );
};

subtest 'unknown explicit top port now says C1 passthrough exposure is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($unknown_port_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top port 'extra_probe', .*C1 passthrough exposure is blocked because the realized child interface has no port with that name/s,
        'unknown explicit top port now says C1 passthrough exposure is blocked',
    );
};

subtest 'width mismatch now says C1 passthrough exposure is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($width_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top port 'output_data' with width 4, .*C1 passthrough exposure is blocked because child port 'output_data' has width 8/s,
        'width mismatch now says C1 passthrough exposure is blocked',
    );
};

subtest 'direction mismatch now says C1 passthrough exposure is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($direction_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top port 'output_data' as input, .*C1 passthrough exposure is blocked because child port 'output_data' is output/s,
        'direction mismatch now says C1 passthrough exposure is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
