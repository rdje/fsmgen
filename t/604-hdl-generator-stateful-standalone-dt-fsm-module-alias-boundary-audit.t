#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh fsm_module objects per standalone dt generation' => sub {
    my $dt_path = write_dt_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $first->{fsm_module}->source_root_kind,
        'dt',
        'first generation returns a standalone dt fsm_module',
    );
    is(
        scalar(@{$first->{fsm_module}->states}),
        2,
        'first generation returns the expected standalone dt state entries',
    );

    $first->{fsm_module}{name} = 'mutated_first_dt_module';
    $first->{fsm_module}->signals->{DATA_OUT}{name} = 'mutated_first_data_out';
    pop @{$first->{fsm_module}->states};

    my $second = $pipeline->generate_hdl_from_file($dt_path);
    is(
        $second->{fsm_module}->name,
        'stateful_standalone_dt_fsm_module_alias_top',
        'later generation on the same facade does not inherit caller mutation of dt module name',
    );
    is(
        $second->{fsm_module}->signals->{DATA_OUT}->name,
        'DATA_OUT',
        'later generation on the same facade does not inherit caller mutation of nested dt signal object',
    );
    is(
        scalar(@{$second->{fsm_module}->states}),
        2,
        'later generation on the same facade does not inherit caller mutation of dt states array',
    );
};

done_testing();

sub write_dt_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'stateful_standalone_dt_fsm_module_alias_top.fsm');
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_standalone_dt_fsm_module_alias_top
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
