#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh statistics containers per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{statistics}{intermediate_signals},
        0,
        'first generation returns the expected statistics summary',
    );

    $first->{statistics}{intermediate_signals} = 99;
    $first->{statistics}{raw_intermediate_signals}{mutated_first_signal} = 1;

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{statistics}{intermediate_signals},
        0,
        'later generation on the same facade does not inherit caller mutation of scalar statistics',
    );
    ok(
        !exists $second->{statistics}{raw_intermediate_signals}{mutated_first_signal},
        'later generation on the same facade does not inherit caller mutation of nested statistics maps',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_statistics_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_statistics_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (<= (OUT> 1))
  )
)
FSM
    );
    return $fsm_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
