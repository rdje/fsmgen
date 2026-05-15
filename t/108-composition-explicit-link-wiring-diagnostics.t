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
my $unused_top_input_path = File::Spec->catfile($tempdir, 'unused_top_input_link_top.fsm');
my $unused_top_output_path = File::Spec->catfile($tempdir, 'unused_top_output_link_top.fsm');
my $unconnected_child_path = File::Spec->catfile($tempdir, 'unconnected_child_link_top.fsm');

write_file(
    $unused_top_input_path,
    <<'FSM'
(?top:unused_top_input_link_top
  (?ports:public_io
    clk
    rstn
    start
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
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
    (output_data> <= 8'3)
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
    $unused_top_output_path,
    <<'FSM'
(?top:unused_top_output_link_top
  (?ports:public_io
    clk
    rstn
    status>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /producer.output_data/consumer.input_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
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
    $unconnected_child_path,
    <<'FSM'
(?top:unconnected_child_link_top
  (?ports:public_io
    clk
    rstn
    =go
  )
  (?fsmc:consumer consumer_src)
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (final_data> <= 8'3)
    )
  )
  (+size
    (go 1)
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

subtest 'unused declared top inputs now say explicit-link top wiring is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($unused_top_input_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top input 'start', .*explicit-link top wiring is blocked because the current active C2 lane requires explicit '\?wiring' usage for every non-system top input/s,
        'unused declared top input now says explicit-link top wiring is blocked',
    );
};

subtest 'unused declared top outputs now say explicit-link top wiring is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($unused_top_output_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top output 'status', .*explicit-link top wiring is blocked because the current active C2 lane requires explicit '\?wiring' usage for every top output/s,
        'unused declared top output now says explicit-link top wiring is blocked',
    );
};

subtest 'still-unconnected child ports now say realized child wiring is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($unconnected_child_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/leaves child port 'consumer\.final_data' unconnected, .*realized child wiring is blocked because the current active C4 lane requires every realized child port to be wired explicitly/s,
        'unconnected realized child ports now say realized child wiring is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
