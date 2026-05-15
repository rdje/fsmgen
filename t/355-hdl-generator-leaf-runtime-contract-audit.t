#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorModuleInfoContract qw(
    hdl_generator_module_info_identity_keys
    hdl_generator_module_info_optional_composition_summary_keys
    hdl_generator_module_info_presence_key_family_map
    hdl_generator_module_info_stable_subsurfaces
    hdl_generator_module_info_summary_keys
);
use FSM::Support::HDLGeneratorSourceInfoContract qw(
    hdl_generator_source_info_presence_key_family_map
    hdl_generator_source_info_stable_subsurfaces
);
use FSM::Support::HDLGeneratorStatisticsContract qw(
    hdl_generator_statistics_optional_composition_keys
    hdl_generator_statistics_presence_key_family_map
    hdl_generator_statistics_stable_subsurfaces
    hdl_generator_statistics_summary_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'direct HDLGenerator result keeps bounded leaf contracts at runtime' => sub {
    my $result = generate_result('fsm/apb_requester.fsm');

    is($result->{source_info}{kind}, 'fsm', 'direct result records fsm source_info kind');

    assert_payload_matches_key_families(
        $result->{source_info},
        hdl_generator_source_info_presence_key_family_map(),
        'direct source_info keeps bounded key families',
    );

    my %module_families = %{hdl_generator_module_info_presence_key_family_map()};
    delete $module_families{optional_composition_summary_keys};
    assert_payload_matches_key_families(
        $result->{module_info},
        \%module_families,
        'direct module_info keeps bounded identity and summary families',
    );
    assert_keys_absent(
        $result->{module_info},
        hdl_generator_module_info_optional_composition_summary_keys(),
        'direct module_info omits composition-only summary keys',
    );

    my %statistics_families = %{hdl_generator_statistics_presence_key_family_map()};
    delete $statistics_families{optional_composition_summary_keys};
    assert_payload_matches_key_families(
        $result->{statistics},
        \%statistics_families,
        'direct statistics keeps bounded summary family',
    );
    assert_keys_absent(
        $result->{statistics},
        hdl_generator_statistics_optional_composition_keys(),
        'direct statistics omits composition-only summary keys',
    );

    assert_surface_paths_exist(
        $result,
        hdl_generator_source_info_stable_subsurfaces(),
        'direct result keeps stable source_info subsurfaces',
    );
    assert_surface_paths_exist(
        $result,
        surface_paths_for_keys(
            'module_info',
            [
                @{hdl_generator_module_info_identity_keys() || []},
                @{hdl_generator_module_info_summary_keys() || []},
            ],
        ),
        'direct result keeps stable non-composition module_info subsurfaces',
    );
    assert_surface_paths_exist(
        $result,
        surface_paths_for_keys('statistics', hdl_generator_statistics_summary_keys()),
        'direct result keeps stable non-composition statistics subsurfaces',
    );
};

subtest 'composition HDLGenerator result keeps bounded leaf contracts at runtime' => sub {
    my $result = generate_result('fsm/apb_tb.fsm');

    is($result->{source_info}{kind}, 'composition', 'composition result records composition source_info kind');

    assert_payload_matches_key_families(
        $result->{source_info},
        hdl_generator_source_info_presence_key_family_map(),
        'composition source_info keeps bounded key families',
    );
    assert_payload_matches_key_families(
        $result->{module_info},
        hdl_generator_module_info_presence_key_family_map(),
        'composition module_info keeps bounded key families including composition-only keys',
    );
    assert_payload_matches_key_families(
        $result->{statistics},
        hdl_generator_statistics_presence_key_family_map(),
        'composition statistics keeps bounded key families including composition-only keys',
    );

    assert_surface_paths_exist(
        $result,
        hdl_generator_source_info_stable_subsurfaces(),
        'composition result keeps stable source_info subsurfaces',
    );
    assert_surface_paths_exist(
        $result,
        hdl_generator_module_info_stable_subsurfaces(),
        'composition result keeps stable module_info subsurfaces',
    );
    assert_surface_paths_exist(
        $result,
        hdl_generator_statistics_stable_subsurfaces(),
        'composition result keeps stable statistics subsurfaces',
    );
};

subtest 'source_info package import summaries stay bounded on direct and composition roots' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $direct_path = File::Spec->catfile($tempdir, 'direct_package_import_root.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'package_import_top.fsm');

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
        $direct_path,
        <<'FSM'
(?fsm:direct_package_import_root
  (+import shared_local shared_external)
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 8)
  )
  (idle
    (= (OUT shared_external.RESET_BYTE))
  )
)

(?pkg:shared_local
  (+constants
    (BUSY 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:package_import_top
  (+import shared_local shared_external)
  (?ports:public_io
    shared_out>8
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=shared_external.RESET_BYTE/shared_out/
    /=shared_local.mode.BUSY/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)

(?rtlif:uart_tx
  enable<1:data
)
FSM
    );

    my $direct = generate_result_from_path($direct_path, source_search_paths => [$libdir]);
    my $composition = generate_result_from_path($composition_path, source_search_paths => [$libdir]);

    assert_import_summary(
        $direct->{source_info},
        'fsm',
        'direct package-import root keeps bounded source_info import summary',
    );
    assert_import_summary(
        $composition->{source_info},
        'composition',
        'composition package-import root keeps bounded source_info import summary',
    );
};

done_testing();

sub generate_result {
    my ($relpath) = @_;
    return generate_result_from_path(repo_file($relpath));
}

sub generate_result_from_path {
    my ($path, %extra) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        %extra,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
}

sub assert_import_summary {
    my ($source_info, $kind, $label) = @_;

    assert_payload_matches_key_families(
        $source_info,
        hdl_generator_source_info_presence_key_family_map(),
        "$label: source_info keeps bounded key families",
    );
    is($source_info->{kind}, $kind, "$label: source_info keeps kind");
    is($source_info->{package_import_count}, 2, "$label: source_info keeps package import count");
    is_deeply(
        $source_info->{package_import_names},
        [qw(shared_local shared_external)],
        "$label: source_info preserves authored package import order",
    );
    assert_surface_paths_exist(
        { source_info => $source_info },
        hdl_generator_source_info_stable_subsurfaces(),
        "$label: source_info keeps stable import summary subsurfaces",
    );
}

sub assert_payload_matches_key_families {
    my ($payload, $family_map, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $family (sort keys %{$family_map || {}}) {
        assert_keys_present(
            $payload,
            $family_map->{$family},
            "$label: family $family",
        );
    }
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label keeps key $key");
    }
}

sub assert_keys_absent {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(!exists $payload->{$key}, "$label omits key $key");
    }
}

sub surface_paths_for_keys {
    my ($prefix, $keys) = @_;
    return [
        map { "$prefix.$_" } @{$keys || []}
    ];
}

sub assert_surface_paths_exist {
    my ($payload, $paths, $label) = @_;

    for my $path (@{$paths || []}) {
        ok(surface_path_exists($payload, $path), "$label keeps surface $path");
    }
}

sub surface_path_exists {
    my ($payload, $path) = @_;
    my @parts = split /\./, $path;
    my $cursor = $payload;

    for my $part (@parts) {
        return 0 unless ref($cursor) eq 'HASH';
        return 0 unless exists $cursor->{$part};
        $cursor = $cursor->{$part};
    }

    return 1;
}
