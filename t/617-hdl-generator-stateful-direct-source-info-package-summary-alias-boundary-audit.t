#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh direct source_info package summaries per generation' => sub {
    my $fsm_path = write_package_import_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is_deeply(
        $first->{source_info}{package_import_names},
        [qw(shared_local)],
        'first direct generation returns the expected source_info package summary',
    );

    $first->{source_info}{package_import_names} = ['mutated_first_import'];
    $first->{source_info}{package_import_count} = 99;

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{source_info}{package_import_count},
        1,
        'later generation on the same facade does not inherit caller mutation of direct package_import_count',
    );
    is_deeply(
        $second->{source_info}{package_import_names},
        [qw(shared_local)],
        'later generation on the same facade does not inherit caller mutation of direct package_import_names',
    );
};

done_testing();

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_direct_source_info_package_summary_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_direct_source_info_package_summary_alias_top
  (+import shared_local)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = shared_local.RESET_BYTE)
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
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
