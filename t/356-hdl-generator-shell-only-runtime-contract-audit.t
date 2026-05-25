#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
    sanitize_composition_report
);
use FSM::Support::HDLGeneratorCompositionPlanContract qw(
    hdl_generator_composition_plan_fallback_surface_map
    hdl_generator_composition_plan_raw_value_class_when_defined
    hdl_generator_composition_plan_summary_surfaces
);
use FSM::Support::HDLGeneratorCompositionSpecContract qw(
    hdl_generator_composition_spec_fallback_surface_map
    hdl_generator_composition_spec_raw_value_class_when_defined
    hdl_generator_composition_spec_summary_surfaces
);
use FSM::Support::HDLGeneratorFSMModuleContract qw(
    hdl_generator_fsm_module_fallback_surface_map
    hdl_generator_fsm_module_raw_value_class_when_defined
    hdl_generator_fsm_module_summary_surfaces
);
use FSM::Support::HDLGeneratorRawASTContract qw(
    hdl_generator_raw_ast_fallback_surface_map
    hdl_generator_raw_ast_summary_surfaces
    hdl_generator_raw_ast_value_shape
);
use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    hdl_generator_resolved_package_imports_fallback_surface_map
    hdl_generator_resolved_package_imports_raw_value_class
    hdl_generator_resolved_package_imports_summary_surface
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'direct HDLGenerator shell-only branches keep bounded runtime shape and fallback surfaces' => sub {
    my ($direct_path, $composition_path, $libdir) = make_package_import_fixtures();
    my $result = generate_result_from_path($direct_path, source_search_paths => [$libdir]);

    isa_ok(
        $result->{fsm_module},
        hdl_generator_fsm_module_raw_value_class_when_defined(),
        'direct result keeps raw fsm_module compatibility object',
    );
    is(
        ref($result->{raw_ast}),
        hdl_generator_raw_ast_value_shape(),
        'direct result keeps raw_ast compatibility branch with the published shape',
    );
    is(
        ref($result->{resolved_package_imports}{shared_external}),
        hdl_generator_resolved_package_imports_raw_value_class(),
        'direct result keeps raw resolved_package_imports package-spec values',
    );
    ok(!exists $result->{composition_spec}, 'direct result omits composition_spec');
    ok(!exists $result->{composition_plan}, 'direct result omits composition_plan');
    ok(!exists $result->{composition_report}, 'direct result omits composition_report');

    assert_surface_paths_exist(
        $result,
        hdl_generator_fsm_module_summary_surfaces(),
        'direct result keeps bounded fsm_module fallback summary surfaces',
    );
    assert_surface_family_paths_exist(
        $result,
        hdl_generator_fsm_module_fallback_surface_map(),
        'direct result keeps grouped fsm_module fallback families',
    );
    assert_surface_paths_exist(
        $result,
        hdl_generator_raw_ast_summary_surfaces(),
        'direct result keeps bounded raw_ast fallback summary surfaces',
    );
    assert_surface_family_paths_exist(
        $result,
        hdl_generator_raw_ast_fallback_surface_map(),
        'direct result keeps grouped raw_ast fallback families',
    );
    assert_surface_paths_exist(
        $result,
        hdl_generator_resolved_package_imports_summary_surface(),
        'direct result keeps bounded resolved_package_imports fallback summary surfaces',
    );
    assert_surface_family_paths_exist(
        $result,
        hdl_generator_resolved_package_imports_fallback_surface_map(),
        'direct result keeps grouped resolved_package_imports fallback families',
    );
};

subtest 'composition HDLGenerator shell-only branches keep bounded runtime shape and semantic fallback surfaces' => sub {
    my ($direct_path, $composition_path, $libdir) = make_package_import_fixtures();
    my $result = generate_result_from_path($composition_path, source_search_paths => [$libdir]);
    my $semantic_report = run_semantic_json($composition_path, $libdir);

    ok(exists $result->{fsm_module}, 'composition result keeps fsm_module compatibility key');
    ok(!defined $result->{fsm_module}, 'composition result leaves fsm_module compatibility key undef');
    is(
        ref($result->{raw_ast}),
        hdl_generator_raw_ast_value_shape(),
        'composition result keeps raw_ast compatibility branch with the published shape',
    );
    is(
        ref($result->{resolved_package_imports}{shared_external}),
        hdl_generator_resolved_package_imports_raw_value_class(),
        'composition result keeps raw resolved_package_imports package-spec values',
    );
    isa_ok(
        $result->{composition_spec},
        hdl_generator_composition_spec_raw_value_class_when_defined(),
        'composition result keeps raw composition_spec compatibility object',
    );
    isa_ok(
        $result->{composition_plan},
        hdl_generator_composition_plan_raw_value_class_when_defined(),
        'composition result keeps raw composition_plan compatibility object',
    );
    is(ref($result->{composition_report}), 'HASH', 'composition result keeps raw composition_report hash');

    assert_surface_paths_exist(
        $result,
        hdl_generator_raw_ast_summary_surfaces(),
        'composition result keeps bounded raw_ast fallback summary surfaces',
    );
    assert_surface_family_paths_exist(
        $result,
        hdl_generator_raw_ast_fallback_surface_map(),
        'composition result keeps grouped raw_ast fallback families',
    );
    assert_surface_paths_exist(
        $result,
        hdl_generator_resolved_package_imports_summary_surface(),
        'composition result keeps bounded resolved_package_imports fallback summary surfaces',
    );
    assert_surface_family_paths_exist(
        $result,
        hdl_generator_resolved_package_imports_fallback_surface_map(),
        'composition result keeps grouped resolved_package_imports fallback families',
    );

    assert_runtime_surface_paths_exist(
        $semantic_report,
        hdl_generator_composition_spec_summary_surfaces(),
        'semantic export keeps bounded composition_spec fallback summary surfaces',
    );
    assert_runtime_surface_family_paths_exist(
        $semantic_report,
        hdl_generator_composition_spec_fallback_surface_map(),
        'semantic export keeps grouped composition_spec fallback families',
    );
    assert_runtime_surface_paths_exist(
        $semantic_report,
        hdl_generator_composition_plan_summary_surfaces(),
        'semantic export keeps bounded composition_plan fallback summary surfaces',
    );
    assert_runtime_surface_family_paths_exist(
        $semantic_report,
        hdl_generator_composition_plan_fallback_surface_map(),
        'semantic export keeps grouped composition_plan fallback families',
    );
    assert_runtime_surface_paths_exist(
        $semantic_report,
        [composition_report_json_fragment_path()],
        'semantic export keeps the composition_report JSON fragment fallback surface',
    );

    my $sanitized = sanitize_composition_report($result->{composition_report});
    my $provenance_report = runtime_surface_value(
        $semantic_report,
        composition_report_json_fragment_path(),
    );
    is_deeply(
        $provenance_report,
        $sanitized,
        'semantic export provenance report matches the sanitized raw composition_report branch',
    );
    is_deeply(
        unknown_top_level_keys($provenance_report),
        [],
        'semantic export provenance report keeps only declared public top-level keys',
    );
};

done_testing();

sub make_package_import_fixtures {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $direct_path = File::Spec->catfile($tempdir, 'direct_package_import_root.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'package_import_top.fsm');
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
    (=shared_external.RESET_BYTE shared_out)
    (=shared_local.mode.BUSY uart_tx.enable)
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

    return ($direct_path, $composition_path, $libdir);
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

sub run_semantic_json {
    my ($path, $libdir) = @_;

    my @cmd = ('./bin/fsmgen', '--strict', '--emit-semantic-json');
    push @cmd, ('--path', $libdir) if defined $libdir;
    push @cmd, $path;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd);
    ok($success, "semantic JSON export succeeds for $path");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $path");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
}

sub assert_surface_family_paths_exist {
    my ($payload, $family_map, $label) = @_;
    for my $family (sort keys %{$family_map || {}}) {
        assert_surface_paths_exist(
            $payload,
            $family_map->{$family},
            "$label: family $family",
        );
    }
}

sub assert_runtime_surface_family_paths_exist {
    my ($payload, $family_map, $label) = @_;
    for my $family (sort keys %{$family_map || {}}) {
        assert_runtime_surface_paths_exist(
            $payload,
            $family_map->{$family},
            "$label: family $family",
        );
    }
}

sub assert_surface_paths_exist {
    my ($payload, $paths, $label) = @_;
    for my $path (@{$paths || []}) {
        ok(surface_path_exists($payload, $path), "$label keeps surface $path");
    }
}

sub assert_runtime_surface_paths_exist {
    my ($payload, $paths, $label) = @_;
    for my $path (@{$paths || []}) {
        ok(defined runtime_surface_value($payload, $path), "$label keeps runtime surface $path");
    }
}

sub runtime_surface_value {
    my ($payload, $path) = @_;
    my $runtime_path = $path;
    $runtime_path =~ s/^semantic_exports\.normalized_semantic_json\.//;
    return surface_path_value($payload, $runtime_path);
}

sub surface_path_exists {
    my ($payload, $path) = @_;
    return defined surface_path_value($payload, $path);
}

sub surface_path_value {
    my ($payload, $path) = @_;
    my @parts = split /\./, $path;
    my $cursor = $payload;

    for my $part (@parts) {
        return undef unless ref($cursor) eq 'HASH';
        return undef unless exists $cursor->{$part};
        $cursor = $cursor->{$part};
    }

    return $cursor;
}

sub unknown_top_level_keys {
    my ($payload) = @_;
    my %known = map { $_ => 1 } @{composition_report_public_top_level_keys()};
    return [grep { !$known{$_} } sort keys %{$payload || {}}];
}
