#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh standalone dt source_info package summaries per generation' => sub {
    my $fixture = write_package_import_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        source_search_paths => [$fixture->{libdir}],
    );

    my $first = $pipeline->generate_hdl_from_file($fixture->{dt_path});
    is_deeply(
        $first->{source_info}{package_import_names},
        [qw(shared_external)],
        'first standalone dt generation returns the expected source_info package summary',
    );

    $first->{source_info}{package_import_names} = ['mutated_first_import'];
    $first->{source_info}{package_import_count} = 99;

    my $second = $pipeline->generate_hdl_from_file($fixture->{dt_path});
    is(
        $second->{source_info}{package_import_count},
        1,
        'later generation on the same facade does not inherit caller mutation of standalone dt package_import_count',
    );
    is_deeply(
        $second->{source_info}{package_import_names},
        [qw(shared_external)],
        'later generation on the same facade does not inherit caller mutation of standalone dt package_import_names',
    );
};

done_testing();

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $dt_path = File::Spec->catfile($tempdir, 'stateful_standalone_dt_source_info_package_summary_alias_top.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_standalone_dt_source_info_package_summary_alias_top
  (+import shared_external)
  (+size
    (OUT 8)
  )
  (-route
    (OUT> = shared_external.RESET_BYTE)
  )
)
FSM
    );

    return {
        dt_path => $dt_path,
        libdir => $libdir,
    };
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
