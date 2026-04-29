#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

subtest 'facade contract advertises source_search_paths as a public constructor option' => sub {
    my $contract = build_hdl_generator_facade_contract();

    ok(
        contains_value(
            $contract->{public_constructor_option_names},
            'source_search_paths',
        ),
        'emitted facade contract includes source_search_paths in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'source_search_paths',
        ),
        'builder-owned public constructor list includes source_search_paths',
    );
    ok(
        contains_value(
            $contract->{constructor_option_family_map}{core_constructor_option_names},
            'source_search_paths',
        ),
        'grouped core constructor family includes source_search_paths',
    );
};

subtest 'facade source_search_paths option is required for external package resolution' => sub {
    my $fixture = make_source_search_path_fixture();

    my ($missing_ok, $missing_error) = eval_generate(
        source_path => $fixture->{root_path},
    );

    ok(!$missing_ok, 'generation fails when the external package is not on source_search_paths');
    like(
        $missing_error,
        qr/package-source resolution is blocked/s,
        'missing source_search_paths failure preserves the package-resolution boundary',
    );
    like(
        $missing_error,
        qr/\Q$fixture->{package_name}\E/s,
        'missing source_search_paths failure names the unresolved package',
    );

    my ($found_ok, $found_error, $found_result) = eval_generate(
        source_path => $fixture->{root_path},
        source_search_paths => [$fixture->{lib_a}],
    );

    ok($found_ok, 'generation succeeds when source_search_paths contains the external package directory')
        or diag($found_error);
    like(
        $found_result->{hdl_code},
        qr/8'hA5/,
        'source_search_paths-backed package constant reaches generated HDL',
    );
    is_deeply(
        $found_result->{source_info}{package_import_names},
        [$fixture->{package_name}],
        'source_info keeps the authored external package import name',
    );
};

subtest 'facade source_search_paths resolution stays scoped to each facade object' => sub {
    my $fixture = make_source_search_path_fixture();

    my $result_a = generate_with_paths(
        $fixture->{root_path},
        [$fixture->{lib_a}],
    );
    my $result_b = generate_with_paths(
        $fixture->{root_path},
        [$fixture->{lib_b}],
    );

    like(
        $result_a->{hdl_code},
        qr/8'hA5/,
        'first facade object resolves the package from its own search path',
    );
    unlike(
        $result_a->{hdl_code},
        qr/8'h3C/,
        'first facade object does not use the second search path package',
    );
    like(
        $result_b->{hdl_code},
        qr/8'h3C/,
        'second facade object resolves the same package name from its own search path',
    );
    unlike(
        $result_b->{hdl_code},
        qr/8'hA5/,
        'second facade object does not retain the first search path package',
    );

    my ($missing_ok, $missing_error) = eval_generate(
        source_path => $fixture->{root_path},
    );
    ok(!$missing_ok, 'a later facade object without source_search_paths still fails');
    like(
        $missing_error,
        qr/\Q$fixture->{package_name}\E/s,
        'no-path facade failure still reports the unresolved package after prior successful resolutions',
    );
};

done_testing();

sub make_source_search_path_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $lib_a = File::Spec->catdir($tempdir, 'pkg_lib_a');
    my $lib_b = File::Spec->catdir($tempdir, 'pkg_lib_b');
    mkdir $lib_a or die "Cannot create $lib_a: $!";
    mkdir $lib_b or die "Cannot create $lib_b: $!";

    my $package_name = 'facade_source_search_paths_audit_pkg';
    my $root_path = File::Spec->catfile($tempdir, 'facade_source_search_paths_root.fsm');

    write_file(
        File::Spec->catfile($lib_a, "$package_name.fsm"),
        package_source($package_name, "8'hA5"),
    );
    write_file(
        File::Spec->catfile($lib_b, "$package_name.fsm"),
        package_source($package_name, "8'h3C"),
    );
    write_file(
        $root_path,
        direct_root_source($package_name),
    );

    return {
        tempdir => $tempdir,
        lib_a => $lib_a,
        lib_b => $lib_b,
        package_name => $package_name,
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
(?fsm:facade_source_search_paths_root
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

sub eval_generate {
    my (%args) = @_;
    my $result;
    my $ok = eval {
        $result = generate_with_paths(
            $args{source_path},
            $args{source_search_paths} || [],
        );
        1;
    };
    my $error = $@ unless $ok;

    return ($ok, $error, $result);
}

sub generate_with_paths {
    my ($source_path, $source_search_paths) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        source_search_paths => $source_search_paths,
    );

    return $pipeline->generate_hdl_from_file($source_path);
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
