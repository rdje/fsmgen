#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh standalone dt statistics containers per generation' => sub {
    my $dt_path = write_dt_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $first->{statistics}{intermediate_signals},
        0,
        'first standalone dt generation returns the expected statistics summary',
    );

    $first->{statistics}{intermediate_signals} = 99;
    $first->{statistics}{factoring_enabled} = 88;
    $first->{statistics}{raw_intermediate_signals}{mutated_first_signal} = 1;

    my $second = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $second->{statistics}{intermediate_signals},
        0,
        'later generation on the same facade does not inherit caller mutation of standalone dt scalar statistics',
    );
    is(
        $second->{statistics}{factoring_enabled},
        0,
        'later generation on the same facade does not inherit caller mutation of standalone dt factoring flag',
    );
    ok(
        !exists $second->{statistics}{raw_intermediate_signals}{mutated_first_signal},
        'later generation on the same facade does not inherit caller mutation of nested standalone dt statistics maps',
    );
};

done_testing();

sub write_dt_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'stateful_standalone_dt_statistics_alias_top.fsm');
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_standalone_dt_statistics_alias_top
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
    (ZERO_FLAG 1)
  )
  (-route_data
    (DATA_OUT> = DATA_IN)
  )
  (-flag_zero
    (<DATA_IN==8'0
      (ZERO_FLAG> = 1)
    )
  )
)
FSM
    );
    return $dt_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
