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
    hdl_generator_facade_method_names
);
use FSM::Support::HDLGeneratorSourceInfoContract qw(
    hdl_generator_source_info_presence_key_family_map
    hdl_generator_source_info_stable_subsurfaces
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

{
    package Test::FacadeMarkerExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            parse_calls => [],
            result_calls => [],
        }, $class;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{parse_calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            source_path => $context->source_path,
        };
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            module_name => $context->result->{module_info}{module_name},
        };

        $context->result->{facade_extension_marker} = {
            call_index => scalar(@{$self->{result_calls}}),
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            module_name => $context->result->{module_info}{module_name},
        };
    }

    sub parse_calls {
        my ($self) = @_;
        return $self->{parse_calls};
    }

    sub result_calls {
        my ($self) = @_;
        return $self->{result_calls};
    }
}

subtest 'facade method family stays callable and supports repeated generation with direct extensions' => sub {
    for my $method (@{hdl_generator_facade_method_names() || []}) {
        ok(FSM::Pipeline::HDLGenerator->can($method), "HDLGenerator keeps method $method");
    }

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'extension_smoke.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'extension_comp_top.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:extension_smoke
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (OUT 1))
  )
  (+size
    (OUT 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:extension_comp_top
  (?ports:public_io
    clk
    reset
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (output_data> 8'1))
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $extension = Test::FacadeMarkerExtension->new();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        extensions => [$extension],
    );

    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator', 'constructor returns the public facade object');

    my $fsm_result = $pipeline->generate_hdl_from_file($fsm_path);
    my $composition_result = $pipeline->generate_hdl_from_file($composition_path);

    is(
        $fsm_result->{module_info}{module_name},
        'extension_smoke',
        'direct generation keeps the expected module name',
    );
    is(
        $composition_result->{module_info}{module_name},
        'extension_comp_top',
        'composition generation keeps the expected top module name',
    );
    is(
        $fsm_result->{facade_extension_marker}{target_language},
        'systemverilog',
        'omitted target_language still defaults to systemverilog for direct generation',
    );
    is(
        $composition_result->{facade_extension_marker}{target_language},
        'systemverilog',
        'omitted target_language still defaults to systemverilog for composition generation',
    );
    is(
        $fsm_result->{facade_extension_marker}{source_kind},
        'fsm',
        'direct generation preserves source classification through the facade hook context',
    );
    is(
        $composition_result->{facade_extension_marker}{source_kind},
        'composition',
        'composition generation preserves source classification through the facade hook context',
    );

    is(scalar(@{$extension->parse_calls}), 2, 'parse hook runs once per facade generation call');
    is(scalar(@{$extension->result_calls}), 2, 'result hook runs once per facade generation call');
    is($extension->parse_calls->[0]{stage}, 'after_parse_source', 'parse hook keeps the shipped stage name');
    is($extension->result_calls->[0]{stage}, 'after_generate_result', 'result hook keeps the shipped stage name');
    is($extension->result_calls->[0]{module_name}, 'extension_smoke', 'first result hook sees the direct module name');
    is($extension->result_calls->[1]{module_name}, 'extension_comp_top', 'second result hook sees the composition module name');
};

subtest 'facade source_search_paths stays runtime-backed through source_info summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $direct_path = File::Spec->catfile($tempdir, 'direct_package_import_root.fsm');

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

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($direct_path);
    my $source_info = $result->{source_info};

    assert_payload_matches_key_families(
        $source_info,
        hdl_generator_source_info_presence_key_family_map(),
        'source_info keeps the bounded key families after source_search_paths resolution',
    );
    is($source_info->{kind}, 'fsm', 'source_info keeps the direct root kind');
    is($source_info->{package_import_count}, 2, 'source_info keeps the authored package import count');
    is_deeply(
        $source_info->{package_import_names},
        [qw(shared_local shared_external)],
        'source_info preserves authored package import order',
    );
    assert_surface_paths_exist(
        { source_info => $source_info },
        hdl_generator_source_info_stable_subsurfaces(),
        'source_info keeps the bounded stable import summary subsurfaces',
    );
    ok($result->{hdl_code}, 'generation still succeeds through the source_search_paths facade option');
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
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
