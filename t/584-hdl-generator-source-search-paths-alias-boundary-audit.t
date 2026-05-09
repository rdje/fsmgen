#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'facade source_search_paths are copied before caller mutation can affect resolution' => sub {
    my $fixture = make_source_search_path_fixture();
    my $source_search_paths = [$fixture->{lib_a}];
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        source_search_paths => $source_search_paths,
    );

    $source_search_paths->[0] = $fixture->{lib_b};
    push @$source_search_paths, $fixture->{lib_c};

    my $result = $pipeline->generate_hdl_from_file($fixture->{root_path});
    like(
        $result->{hdl_code},
        qr/8'hA5/,
        'generation uses the constructor-time source_search_paths snapshot',
    );
    unlike(
        $result->{hdl_code},
        qr/8'h3C/,
        'generation does not follow later caller mutation to a different package root',
    );
    unlike(
        $result->{hdl_code},
        qr/8'h7E/,
        'generation does not follow later caller appends to source_search_paths',
    );
    is_deeply(
        $pipeline->{source_path_resolver}->extra_search_paths,
        [$fixture->{lib_a}],
        'resolver exposes the constructor-time source path snapshot',
    );
};

done_testing();

sub make_source_search_path_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $lib_a = File::Spec->catdir($tempdir, 'pkg_lib_a');
    my $lib_b = File::Spec->catdir($tempdir, 'pkg_lib_b');
    my $lib_c = File::Spec->catdir($tempdir, 'pkg_lib_c');
    mkdir $lib_a or die "Cannot create $lib_a: $!";
    mkdir $lib_b or die "Cannot create $lib_b: $!";
    mkdir $lib_c or die "Cannot create $lib_c: $!";

    my $package_name = 'facade_source_search_paths_alias_pkg';
    my $root_path = File::Spec->catfile($tempdir, 'facade_source_search_paths_alias_root.fsm');
    write_file(
        File::Spec->catfile($lib_a, "$package_name.fsm"),
        package_source($package_name, "8'hA5"),
    );
    write_file(
        File::Spec->catfile($lib_b, "$package_name.fsm"),
        package_source($package_name, "8'h3C"),
    );
    write_file(
        File::Spec->catfile($lib_c, "$package_name.fsm"),
        package_source($package_name, "8'h7E"),
    );
    write_file($root_path, direct_root_source($package_name));

    return {
        lib_a => $lib_a,
        lib_b => $lib_b,
        lib_c => $lib_c,
        root_path => $root_path,
    };
}

sub package_source {
    my ($package_name, $reset_byte) = @_;
    return <<"FSM";
(?pkg:$package_name
  (+constants
    (RESET_BYTE $reset_byte)
  )
)
FSM
}

sub direct_root_source {
    my ($package_name) = @_;
    return <<"FSM";
(?fsm:facade_source_search_paths_alias_root
  (+import $package_name)
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 8)
  )
  (idle
    (= (OUT $package_name.RESET_BYTE))
  )
)
FSM
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
