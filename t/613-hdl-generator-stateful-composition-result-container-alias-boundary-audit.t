#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh top-level result containers per composition generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    like(
        $first->{hdl_code},
        qr/\bmodule\s+stateful_composition_result_container_alias_top\b/,
        'first composition generation returns the expected top HDL result',
    );

    $first->{hdl_code} = 'mutated first composition result hdl';
    $first->{caller_added_composition_key} = { nested => ['mutated'] };
    delete $first->{composition_report};

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    like(
        $second->{hdl_code},
        qr/\bmodule\s+stateful_composition_result_container_alias_top\b/,
        'later generation on the same facade does not inherit caller replacement of composition hdl_code',
    );
    ok(
        !exists $second->{caller_added_composition_key},
        'later generation on the same facade does not inherit caller-added top-level composition keys',
    );
    is(
        ref($second->{composition_report}),
        'HASH',
        'later generation on the same facade does not inherit caller deletion of composition result branches',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_result_container_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_result_container_alias_top
  (+import shared_local)
  (?ports:public_io
    OUT>8
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_local.RESET_BYTE/OUT/
    /=shared_local.RESET_BYTE/uart_tx.data_in/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)

(?rtlif:uart_tx
  data_in<8:data
)
FSM
    );
    return $composition_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
