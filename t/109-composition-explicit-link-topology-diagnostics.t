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
my $missing_toplink_path = File::Spec->catfile($tempdir, 'missing_toplink_top.fsm');

write_file(
    $missing_toplink_path,
    <<'FSM'
(?top:missing_toplink_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
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
    (final_data> <= 8'5)
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

subtest 'missing explicit toplink now says lane entry is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($missing_toplink_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/recognized and parsed into typed composition IR, .*explicit-link lane entry is blocked because the current active C2 lane requires explicit '\?toplink' wiring/s,
        'missing explicit toplink now says explicit-link lane entry is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
