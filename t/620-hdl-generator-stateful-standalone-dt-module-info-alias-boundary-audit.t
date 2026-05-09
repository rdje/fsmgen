#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh standalone dt module_info containers per generation' => sub {
    my $dt_path = write_dt_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $first->{module_info}{module_name},
        'stateful_standalone_dt_module_info_alias_top',
        'first standalone dt generation returns the expected module_info summary',
    );

    $first->{module_info}{module_name} = 'mutated_first_dt_module_info';
    $first->{module_info}{signal_analysis}{outputs}[0]{name} = 'mutated_first_output';
    push @{$first->{module_info}{signal_names}}, 'mutated_first_signal';

    my $second = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $second->{module_info}{module_name},
        'stateful_standalone_dt_module_info_alias_top',
        'later generation on the same facade does not inherit caller mutation of standalone dt module_name',
    );
    is(
        $second->{module_info}{signal_analysis}{outputs}[0]{name},
        'DATA_OUT',
        'later generation on the same facade does not inherit caller mutation of standalone dt signal_analysis',
    );
    is_deeply(
        $second->{module_info}{signal_names},
        [qw(DATA_IN DATA_OUT ZERO_FLAG)],
        'later generation on the same facade does not inherit caller mutation of standalone dt signal_names',
    );
};

done_testing();

sub write_dt_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'stateful_standalone_dt_module_info_alias_top.fsm');
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_standalone_dt_module_info_alias_top
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
