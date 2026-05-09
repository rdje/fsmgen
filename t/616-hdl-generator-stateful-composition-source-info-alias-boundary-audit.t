#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition source_info containers per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{source_info}{header},
        '?top:stateful_composition_source_info_alias_top',
        'first composition generation returns the expected source_info header',
    );

    $first->{source_info}{header} = '?top:mutated_first_header';
    $first->{source_info}{package_import_names} = ['mutated_first_import'];
    $first->{source_info}{package_import_count} = 1;

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{source_info}{header},
        '?top:stateful_composition_source_info_alias_top',
        'later generation on the same facade does not inherit caller mutation of composition source_info header',
    );
    is(
        $second->{source_info}{package_import_count},
        1,
        'later generation on the same facade does not inherit caller mutation of composition package_import_count',
    );
    is_deeply(
        $second->{source_info}{package_import_names},
        [qw(shared_local)],
        'later generation on the same facade does not inherit caller mutation of composition package_import_names',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_source_info_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_source_info_alias_top
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
