#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $JSON = JSON::PP->new->canonical(1);
my $repo_root = abs_path('.');
my $test_rel = ".artifacts/tmp/tests/vial-ghdl-request-types-$$";
my $test_abs = repo_path($test_rel);
my $portable_source_rel = "$test_rel/source/portable.vhd";
my $provider_source_rel = "$test_rel/source/provider.vhd";
my $generated_source_rel = "$test_rel/source/generated.vhd";
my $case = 0;
my @stage_rel;

END {
    for my $stage (@stage_rel) {
        my $absolute = repo_path($stage);
        remove_tree($absolute)
            if -d $absolute && !-l $absolute;
    }
    remove_tree($test_abs)
        if defined($test_abs) && -d $test_abs && !-l $test_abs;
}

write_file($portable_source_rel, "entity portable is end entity;\n");
write_file($provider_source_rel, "entity provider is end entity;\n");
write_file($generated_source_rel, "entity generated is end entity;\n");

subtest 'portable caller request retains canonical JSON integers' => sub {
    my $request = portable_request('numeric-control');
    my @control = (
        [$request->{provider}{archive_bytes}, 'provider archive bytes'],
        [$request->{source_set}[0]{bytes}, 'source bytes'],
        [$request->{validation}{expected_record_counts}{header},
            'expected record count'],
        [$request->{validation}{expected_observation_catalog}{entries}[0]{width},
            'observation width'],
        [$request->{validation}{expected_observation_catalog}{total_width},
            'observation total width'],
        [$request->{validation}{run_repetitions}, 'run repetitions'],
        [$request->{storage_context}{schema_version},
            'storage schema version'],
    );
    for my $control (@control) {
        like($JSON->encode($control->[0]), qr/\A[0-9]+\z/,
            "$control->[1] is a JSON number");
    }
    my $begin = portable_begin($request);
    diag($JSON->encode($begin->{diagnostics})) unless $begin->{ok};
    ok($begin->{ok}, 'exact portable caller request admits');
    cleanup_admitted($request, $begin, \&portable_abort) if $begin->{ok};
};

subtest 'numeric-looking portable request values do not impersonate numbers' => sub {
    my @control = (
        ['provider archive bytes', undef, sub {
            $_[0]{provider}{archive_bytes} =
                sprintf('%d', $_[0]{provider}{archive_bytes});
            return $_[0]{provider}{archive_bytes};
        }],
        ['source bytes', undef, sub {
            $_[0]{source_set}[0]{bytes} =
                sprintf('%d', $_[0]{source_set}[0]{bytes});
            return $_[0]{source_set}[0]{bytes};
        }],
        ['expected record count', '"1"', sub {
            $_[0]{validation}{expected_record_counts}{header} =
                sprintf('%d', 1);
            return $_[0]{validation}{expected_record_counts}{header};
        }],
        ['observation width', '"1"', sub {
            $_[0]{validation}{expected_observation_catalog}{entries}[0]{width}
                = sprintf('%d', 1);
            return $_[0]{validation}{expected_observation_catalog}
                {entries}[0]{width};
        }],
        ['observation total width', undef, sub {
            my $catalog =
                $_[0]{validation}{expected_observation_catalog};
            $catalog->{total_width} = sprintf('%d', $catalog->{total_width});
            return $catalog->{total_width};
        }],
        ['run repetitions', '"2"', sub {
            $_[0]{validation}{run_repetitions} = sprintf('%d', 2);
            return $_[0]{validation}{run_repetitions};
        }],
        ['storage schema version string', '"1"', sub {
            $_[0]{storage_context}{schema_version} = sprintf('%d', 1);
            return $_[0]{storage_context}{schema_version};
        }],
        ['storage schema version boolean', 'true', sub {
            $_[0]{storage_context}{schema_version} = JSON::PP::true;
            return $_[0]{storage_context}{schema_version};
        }],
    );

    for my $control (@control) {
        my ($label, $encoded, $mutate) = @$control;
        my $request = portable_request($label);
        my $cleanup_request = clone($request);
        my $forged = $mutate->($request);
        $encoded //= '"' . $forged . '"';
        is($JSON->encode($forged), $encoded,
            "$label uses the intended foreign JSON type");
        my $result = portable_begin($request);
        rejects_begin($request, $result, $label, \&portable_abort,
            'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR', $cleanup_request);
    }
};

subtest 'OSVVM command plan retains canonical JSON integers' => sub {
    my $request = osvvm_request('numeric-control');
    is($JSON->encode($request->{commands}{schema_version}), '2',
        'OSVVM command-plan schema version is a JSON number');
    like($JSON->encode($request->{commands}{generated_settings}{bytes}),
        qr/\A[1-9][0-9]*\z/,
        'OSVVM generated-settings byte count is a JSON number');
    is($JSON->encode(
            $request->{commands}{resource_controls}
                {execution_timeout_seconds}), '30',
        'OSVVM resource control is a JSON number');
    my $begin = osvvm_begin($request);
    diag($JSON->encode($begin->{diagnostics})) unless $begin->{ok};
    ok($begin->{ok}, 'exact OSVVM command plan admits');
    cleanup_admitted($request, $begin, \&osvvm_abort) if $begin->{ok};
};

subtest 'numeric-looking OSVVM command-plan values reject' => sub {
    my @control = (
        ['command-plan schema version', '"2"', sub {
            $_[0]{commands}{schema_version} = sprintf('%d', 2);
            return $_[0]{commands}{schema_version};
        }],
        ['generated-settings bytes', undef, sub {
            my $settings = $_[0]{commands}{generated_settings};
            $settings->{bytes} = sprintf('%d', $settings->{bytes});
            return $settings->{bytes};
        }],
    );
    for my $control (@control) {
        my ($label, $encoded, $mutate) = @$control;
        my $request = osvvm_request($label);
        my $cleanup_request = clone($request);
        my $forged = $mutate->($request);
        $encoded //= '"' . $forged . '"';
        is($JSON->encode($forged), $encoded,
            "$label uses a JSON string control");
        my $result = osvvm_begin($request);
        rejects_begin($request, $result, $label, \&osvvm_abort,
            'VIAL_GHDL_LIFECYCLE_COMMAND_ERROR', $cleanup_request);
    }
};

ok(!grep({ -e repo_path($_) || -l repo_path($_) } @stage_rel),
    'all focused lifecycle roots are removed exactly');

done_testing();

sub portable_request {
    my ($label) = @_;
    my $provider_root = 't/data/vial_fake_ghdl_provider';
    my $binary = "$provider_root/bin/ghdl";
    my $archive = "$provider_root/ghdl.tar.gz";
    my $stage = stage_for('vial-ghdl-qualification', $label);
    my $source_set = [source_entry($portable_source_rel)];
    my $authority = reference_authority();
    return {
        repo_root => $repo_root,
        provider => provider($provider_root, $archive, $binary),
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity =>
            'emission/' . sha256_hex("request-types-$label-$$"),
        commands => {
            version => [$binary, '--version'],
            analyze => [
                $binary, '-a', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", $portable_source_rel,
            ],
            elaborate => [
                $binary, '-e', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'portable',
            ],
            run => [
                $binary, '-r', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'portable',
                '--assert-level=error',
            ],
        },
        validation => {
            expected_record_counts => reference_counts(),
            %$authority,
            run_repetitions => 2,
        },
        storage_context => storage(
            'qualification', $stage, 'lifecycle_process_group',
        ),
    };
}

sub osvvm_request {
    my ($label) = @_;
    my $provider_root = 't/data/vial_fake_ghdl_provider';
    my $binary = "$provider_root/bin/ghdl";
    my $archive = "$provider_root/ghdl.tar.gz";
    my $stage = stage_for('vial-osvvm-ghdl-qualification', $label);
    my $libraries = "$stage/libraries";
    my $settings_rel =
        "$stage/OsvvmScriptSettingsPkg_generated.vhd";
    my $settings_content = "package generated_settings is end package;\n";
    my $source_set = [
        source_entry($provider_source_rel),
        source_entry($generated_source_rel),
    ];
    my $authority = reference_authority();
    my $commands = {
        schema => 'fsmgen.vial_ghdl_lifecycle_osvvm_command_plan.v2',
        schema_version => 2,
        version => [$binary, '--version'],
        provider_analyze => [
            [$binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
                '--work=osvvm', "--workdir=$libraries/osvvm/v08",
                "-P$libraries", $provider_source_rel],
            [$binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
                '--work=osvvm', "--workdir=$libraries/osvvm/v08",
                "-P$libraries", $settings_rel],
        ],
        analyze_generated => [
            $binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=fsmgen_vial', "--workdir=$libraries/fsmgen_vial/v08",
            "-P$libraries", $generated_source_rel,
        ],
        elaborate_fixture => [
            $binary, '-e', '--std=08', '--work=fsmgen_vial',
            "--workdir=$libraries/fsmgen_vial/v08", "-P$libraries",
            'base_output_arbitration_tb',
        ],
        elaborate_provider_probe => [
            $binary, '-e', '--std=08', '--work=fsmgen_vial',
            "--workdir=$libraries/fsmgen_vial/v08", "-P$libraries",
            'fsmgen_vial_osvvm_runtime_probe',
        ],
        run_fixture => [
            $binary, '-r', '--std=08', '--work=fsmgen_vial',
            "--workdir=$libraries/fsmgen_vial/v08", "-P$libraries",
            'base_output_arbitration_tb', '--assert-level=error',
        ],
        run_provider_probe => [
            $binary, '-r', '--std=08', '--work=fsmgen_vial',
            "--workdir=$libraries/fsmgen_vial/v08", "-P$libraries",
            'fsmgen_vial_osvvm_runtime_probe', '--assert-level=error',
        ],
        generated_settings => {
            relpath => $settings_rel,
            content => $settings_content,
            bytes => bytes::length($settings_content),
            sha256 => sha256_hex($settings_content),
        },
        libraries => {
            root => $libraries,
            osvvm => "$libraries/osvvm/v08",
            osvvm_common => "$libraries/osvvm_common/v08",
            fsmgen_vial => "$libraries/fsmgen_vial/v08",
        },
        provider_reports => [map {{
            name => $_, relpath => "$stage/provider_reports/$_",
        }} qw(
            OsvvmRun.yml AlertLogTop_alerts.yml AlertLogTop_cov.yml
            AlertLogTop_sb_slv.yml
        )],
        resource_controls => resource_controls(),
    };
    return {
        repo_root => $repo_root,
        provider => provider($provider_root, $archive, $binary),
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity =>
            'emission/' . sha256_hex("osvvm-request-types-$label-$$"),
        commands => $commands,
        validation => {
            expected_record_counts => reference_counts(),
            %$authority,
            run_repetitions => 2,
        },
        storage_context => storage(
            'osvvm_qualification', $stage,
            'lifecycle_process_group',
        ),
    };
}

sub rejects_begin {
    my ($request, $result, $label, $abort, $code, $cleanup_request) = @_;
    my $rejected = ok(!$result->{ok}, "$label rejects before admission");
    if ($rejected) {
        is($result->{diagnostics}[0]{code}, $code,
            "$label uses the exact admission diagnostic");
        ok(!-e stage_path($request) && !-l stage_path($request),
            "$label creates no lifecycle root");
        return;
    }
    cleanup_admitted($request, $result, $abort, $cleanup_request);
}

sub cleanup_admitted {
    my ($request, $result, $abort, $fallback_request) = @_;
    my $cleanup = $abort->($request, $result->{handle});
    $cleanup = $abort->($fallback_request, $result->{handle})
        if !$cleanup->{ok} && defined($fallback_request);
    ok($cleanup->{ok} && $cleanup->{cleanup}{removed},
        'admitted control remains exactly abortable');
    ok(!-e stage_path($request) && !-l stage_path($request),
        'admitted control leaves no lifecycle residue');
}

sub provider {
    my ($root, $archive, $binary) = @_;
    return {
        root => $root,
        archive => $archive,
        archive_bytes => 0 + (-s repo_path($archive)),
        archive_sha256 => file_sha256($archive),
        binary => $binary,
        binary_sha256 => file_sha256($binary),
        version_output => 'fake GHDL 1',
    };
}

sub source_entry {
    my ($relpath) = @_;
    return {
        relpath => $relpath,
        bytes => 0 + (-s repo_path($relpath)),
        sha256 => file_sha256($relpath),
    };
}

sub storage {
    my ($mode, $stage, $containment) = @_;
    return {
        schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
        schema_version => 1,
        mode => $mode,
        staging_identity => $stage,
        containment => $containment,
    };
}

sub reference_authority {
    return FSM::VIAL::Backend::VHDLPortableTraceValidator
        ->checked_reference_authority;
}

sub reference_counts {
    return {
        header => 1, scenario_start => 2, events => 2, samples => 35,
        expectations => 2, scoreboards => 2, coverage => 28, faults => 2,
        scenario_end => 2, footer => 1,
    };
}

sub resource_controls {
    return {
        outer_guard =>
            'scripts/run_with_ram_guard.sh --process-max-rss-mb 4096',
        descendant_rss_limit_mib => 4_096,
        host_occupied_cutoff_percent => 88,
        version_timeout_seconds => 10,
        provider_analysis_timeout_seconds_per_source => 120,
        generated_analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        execution_timeout_seconds => 30,
        version_capture_limit_bytes => 65_536,
        provider_capture_limit_bytes => 8_388_608,
        fixture_capture_limit_bytes => 67_108_864,
    };
}

sub stage_for {
    my ($root, $label) = @_;
    my $stage = ".artifacts/tmp/$root/"
        . sha256_hex("request-json-$label-" . ++$case . "-$$");
    push @stage_rel, $stage;
    return $stage;
}

sub portable_begin {
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_begin_for_test(
        $_[0],
    );
}

sub portable_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_abort_for_test({
            %$request, handle => clone($handle),
        });
}

sub osvvm_begin {
    return FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::_ghdl_lifecycle_begin_for_test(
        $_[0],
    );
}

sub osvvm_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::_ghdl_lifecycle_abort_for_test({
            %$request, handle => clone($handle),
        });
}

sub stage_path {
    return repo_path($_[0]{storage_context}{staging_identity});
}

sub write_file {
    my ($relpath, $content) = @_;
    my $path = repo_path($relpath);
    make_path(dirname($path));
    open my $fh, '>:raw', $path
        or die "cannot create focused GHDL file '$path': $!\n";
    print {$fh} $content
        or die "cannot write focused GHDL file '$path': $!\n";
    close $fh
        or die "cannot close focused GHDL file '$path': $!\n";
    chmod 0600, $path
        or die "cannot seal focused GHDL file '$path': $!\n";
}

sub file_sha256 {
    my ($relpath) = @_;
    my $path = repo_path($relpath);
    open my $fh, '<:raw', $path
        or die "cannot hash focused GHDL file '$path': $!\n";
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh
        or die "cannot close focused GHDL file '$path': $!\n";
    return $sha->hexdigest;
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

package FSM::VIAL::Backend::VHDLPortableGHDLQualification;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

package FSM::VIAL::Backend::VHDLOSVVMGHDLQualification;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

package main;
