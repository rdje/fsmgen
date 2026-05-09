#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh top-level result containers per standalone dt generation' => sub {
    my $dt_path = write_dt_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($dt_path);
    like(
        $first->{hdl_code},
        qr/\bmodule\s+stateful_standalone_dt_result_container_alias_top\b/,
        'first standalone dt generation returns the expected HDL result',
    );

    $first->{hdl_code} = 'mutated first standalone dt result hdl';
    $first->{caller_added_standalone_dt_key} = { nested => ['mutated'] };
    delete $first->{module_info};

    my $second = $pipeline->generate_hdl_from_file($dt_path);
    like(
        $second->{hdl_code},
        qr/\bmodule\s+stateful_standalone_dt_result_container_alias_top\b/,
        'later generation on the same facade does not inherit caller replacement of standalone dt hdl_code',
    );
    ok(
        !exists $second->{caller_added_standalone_dt_key},
        'later generation on the same facade does not inherit caller-added standalone dt top-level keys',
    );
    is(
        ref($second->{module_info}),
        'HASH',
        'later generation on the same facade does not inherit caller deletion of standalone dt result branches',
    );
};

done_testing();

sub write_dt_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'stateful_standalone_dt_result_container_alias_top.fsm');
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_standalone_dt_result_container_alias_top
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
