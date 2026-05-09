#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'standalone dt generation separates source_info package summaries from raw fsm_module attributes' => sub {
    my $fixture = write_package_import_fixture();

    my $result = generate_result($fixture);
    is_deeply(
        $result->{source_info}{package_import_names},
        $result->{fsm_module}{attributes}{package_imports},
        'source_info package_import_names starts equivalent to fsm_module package_imports',
    );
    isnt(
        refaddr($result->{source_info}{package_import_names}),
        refaddr($result->{fsm_module}{attributes}{package_imports}),
        'source_info package_import_names does not reuse fsm_module package_imports array',
    );

    push @{$result->{source_info}{package_import_names}}, 'mutated_source_info_import';
    is_deeply(
        $result->{fsm_module}{attributes}{package_imports},
        [qw(shared_external)],
        'mutating source_info package_import_names does not contaminate fsm_module package_imports',
    );

    my $second_result = generate_result($fixture);
    push @{$second_result->{fsm_module}{attributes}{package_imports}}, 'mutated_fsm_module_import';
    is_deeply(
        $second_result->{source_info}{package_import_names},
        [qw(shared_external)],
        'mutating fsm_module package_imports does not contaminate source_info package_import_names',
    );
};

done_testing();

sub generate_result {
    my ($fixture) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        source_search_paths => [$fixture->{libdir}],
    );
    return $pipeline->generate_hdl_from_file($fixture->{dt_path});
}

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $dt_path = File::Spec->catfile($tempdir, 'standalone_dt_package_import_summary_alias_top.fsm');
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
(?dt:standalone_dt_package_import_summary_alias_top
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
