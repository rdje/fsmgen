#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh top-level result containers per direct generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    like(
        $first->{hdl_code},
        qr/\bmodule\s+stateful_result_container_alias_top\b/,
        'first generation returns the expected HDL result',
    );

    $first->{hdl_code} = 'mutated first result hdl';
    $first->{caller_added_top_level_key} = { nested => ['mutated'] };
    delete $first->{statistics};

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    like(
        $second->{hdl_code},
        qr/\bmodule\s+stateful_result_container_alias_top\b/,
        'later generation on the same facade does not inherit caller replacement of top-level hdl_code',
    );
    ok(
        !exists $second->{caller_added_top_level_key},
        'later generation on the same facade does not inherit caller-added top-level keys',
    );
    is(
        ref($second->{statistics}),
        'HASH',
        'later generation on the same facade does not inherit caller deletion of top-level result branches',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_result_container_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_result_container_alias_top
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
