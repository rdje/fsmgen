#!/usr/bin/env perl

use strict;
use warnings;

use Config ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Text::ParseWords qw(shellwords);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1);
my $fake_root_rel = ".artifacts/test/vial-ghdl-osvvm-lifecycle-$$";
my $fake_root_abs = repo_path($fake_root_rel);
my @owned_stage;

END {
    for my $relative (@owned_stage) {
        my $absolute = repo_path($relative);
        remove_tree($absolute) if -d $absolute && !-l $absolute;
        unlink $absolute if -l $absolute;
    }
    remove_tree($fake_root_abs)
        if -d $fake_root_abs && !-l $fake_root_abs;
}

my $unsealed = FSM::VIAL::Backend::GHDLLifecycle->begin_session({});
ok(!$unsealed->{ok}, 'OSVVM lifecycle admission remains caller-sealed');
is($unsealed->{diagnostics}[0]{code},
    'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
    'unsealed admission retains the stable diagnostic');

subtest 'v2 plan records every provider-aware phase in exact order' => sub {
    my $request = fake_request('complete');
    my $current = lifecycle_begin($request);
    diag($json->encode($current->{diagnostics})) unless $current->{ok};
    ok($current->{ok}, 'sealed OSVVM qualification caller admits');
    is($current->{handle}{schema},
        'fsmgen.vial_ghdl_lifecycle_handle.v2',
        'OSVVM handle has a distinct versioned identity');
    is($current->{handle}{schema_version}, 2,
        'OSVVM handle schema version is exact');

    $current = lifecycle_advance($request, $current->{handle});
    ok($current->{ok}, 'generated settings and three libraries prepare');
    is($current->{status}, 'prepared', 'prepared state is exact');
    is($current->{stage_evidence}[-1]{evidence}{settings_sha256},
        $request->{commands}{generated_settings}{sha256},
        'prepared evidence seals generated settings bytes');

    $current = lifecycle_advance($request, $current->{handle});
    ok($current->{ok}, 'tool identity verifies through shared supervisor');
    my $tool_capture = $current->{stage_evidence}[-1]{evidence}{capture};
    is($tool_capture->{containment}, 'lifecycle_process_group',
        'OSVVM role owns the sealed lifecycle process group');
    is($tool_capture->{timeout_seconds}, 10,
        'OSVVM version deadline is exact');
    is($tool_capture->{capture_limit_bytes}, 65_536,
        'OSVVM version capture ceiling is exact');

    $current = lifecycle_advance($request, $current->{handle});
    diag($json->encode($current->{diagnostics})) unless $current->{ok};
    ok($current->{ok}, 'ordered provider and generated analyses pass');
    my $analysis = $current->{stage_evidence}[-1]{evidence};
    is(scalar(@{$analysis->{captures}}), 2,
        'every provider analysis has one ordered capture');
    is(scalar(@{$analysis->{command_digests}}), 2,
        'every provider analysis has one ordered command digest');
    is($analysis->{captures}[0]{timeout_seconds}, 120,
        'provider analysis deadline is exact');
    is($analysis->{generated_capture}{capture_limit_bytes}, 8_388_608,
        'generated analysis capture ceiling is exact');

    $current = lifecycle_advance($request, $current->{handle});
    ok($current->{ok}, 'fixture and provider-probe elaborations pass');
    is(scalar(@{$current->{stage_evidence}[-1]{evidence}{captures}}), 2,
        'fixture and probe retain separate elaboration captures');

    $current = lifecycle_advance($request, $current->{handle});
    diag($json->encode($current->{diagnostics})) unless $current->{ok};
    ok($current->{ok}, 'fixture and provider-probe reruns pass');
    my $ran = $current->{stage_evidence}[-1]{evidence};
    is(scalar(@{$ran->{fixture_captures}}), 2,
        'fixture retains two exact captures');
    is(scalar(@{$ran->{provider_captures}}), 2,
        'provider probe retains two exact captures');
    is(scalar(@{$ran->{provider_report_sha256}}), 2,
        'each provider execution retains one report-set identity');
    is($ran->{provider_report_sha256}[0],
        $ran->{provider_report_sha256}[1],
        'supplementary report sets are deterministic');
    ok($ran->{deterministic}, 'all required double-run evidence is exact');
    is($ran->{fixture_captures}[0]{capture_limit_bytes}, 67_108_864,
        'fixture runtime retains the exact 64-MiB capture ceiling');
    is($ran->{provider_captures}[0]{capture_limit_bytes}, 8_388_608,
        'provider runtime retains its separate 8-MiB capture ceiling');
    is_deeply(report_entries($request), [],
        'raw provider reports are sealed then removed between states');

    my $abort = lifecycle_abort($request, $current->{handle});
    ok($abort->{ok} && $abort->{cleanup}{removed},
        'provider-aware lifecycle abort removes its exact owned root');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'provider-aware lifecycle leaves zero residue');
};

subtest 'plan and generated-settings mutations fail closed' => sub {
    my $request = fake_request('plan-mutation');
    $request->{commands}{resource_controls}{execution_timeout_seconds} = 31;
    my $plan = lifecycle_begin($request);
    ok(!$plan->{ok}, 'alternate provider runtime deadline rejects');
    is($plan->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'mutated plan has the stable command diagnostic');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'rejected plan creates no operation root');

    $request = fake_request('settings-mutation');
    my $current = lifecycle_begin($request);
    $current = lifecycle_advance($request, $current->{handle});
    ok($current->{ok}, 'settings mutation control reaches prepared');
    append_raw(repo_path(
        $request->{commands}{generated_settings}{relpath},
    ), 'foreign');
    my $settings = lifecycle_advance($request, $current->{handle});
    ok(!$settings->{ok}, 'mutated generated settings reject on resume');
    is($settings->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'settings mutation has the stable object diagnostic');
    ok($settings->{cleanup}{removed},
        'settings mutation removes the proven lifecycle owner');
};

subtest 'missing supplementary reports reject and clean the operation' => sub {
    my $request = fake_request('missing-reports', 'ghdl-no-reports');
    my $current = lifecycle_begin($request);
    for my $state (qw(prepared tool_verified analyzed elaborated)) {
        $current = lifecycle_advance($request, $current->{handle});
        diag($json->encode($current->{diagnostics})) unless $current->{ok};
        ok($current->{ok}, "missing-report control reaches $state");
        return unless $current->{ok};
    }
    my $failed = lifecycle_advance($request, $current->{handle});
    ok(!$failed->{ok}, 'missing exact provider reports reject');
    is($failed->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'missing report has the stable object diagnostic');
    ok($failed->{cleanup}{removed},
        'missing report failure removes the exact operation root');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'missing report failure leaves zero residue');
};

done_testing();

sub fake_request {
    my ($label, $binary_name) = @_;
    $binary_name //= 'ghdl';
    remove_tree($fake_root_abs)
        if -d $fake_root_abs && !-l $fake_root_abs;
    my $provider_root = "$fake_root_rel/provider";
    my $binary = "$provider_root/bin/$binary_name";
    my $archive = "$provider_root/ghdl.tar.gz";
    my $program_source = "$provider_root/fake-ghdl.c";
    my $provider_source = "$fake_root_rel/source/provider.vhd";
    my $generated_source = "$fake_root_rel/source/generated.vhd";
    write_raw(repo_path($archive), "fake archive\n");
    write_raw(repo_path($program_source), <<'C');
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    int index;
    const char *mode = "";
    const char *top = "";
    char stage[4096] = "";
    char path[4608];
    const char *reports[] = {
        "OsvvmRun.yml", "AlertLogTop_alerts.yml", "AlertLogTop_cov.yml",
        "AlertLogTop_sb_slv.yml"
    };
    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        fputs("fake OSVVM GHDL 1\n", stdout);
        return 0;
    }
    for (index = 1; index < argc; index++) {
        if (strcmp(argv[index], "-a") == 0 || strcmp(argv[index], "-e") == 0
                || strcmp(argv[index], "-r") == 0) {
            mode = argv[index];
        }
        if (strncmp(argv[index], "--workdir=", 10) == 0) {
            char *libraries;
            snprintf(stage, sizeof(stage), "%s", argv[index] + 10);
            libraries = strstr(stage, "/libraries/");
            if (libraries != NULL) {
                *libraries = '\0';
            }
        }
    }
    if (strcmp(mode, "-r") == 0 && argc >= 3) {
        top = argv[argc - 2];
        if (strcmp(top, "fsmgen_vial_osvvm_runtime_probe") == 0) {
            if (strstr(argv[0], "no-reports") == NULL) {
                for (index = 0; index < 4; index++) {
                    FILE *report;
                    snprintf(path, sizeof(path), "%s/provider_reports/%s",
                        stage, reports[index]);
                    report = fopen(path, "wb");
                    if (report == NULL) return 9;
                    fprintf(report, "deterministic report %d\n", index);
                    if (fclose(report) != 0) return 10;
                }
            }
            fputs("fake provider probe\n", stdout);
        } else {
            fputs("fake fixture\n", stdout);
        }
    }
    return 0;
}
C
    my $compiler_tmp = repo_path("$fake_root_rel/compiler-tmp");
    make_path($compiler_tmp, dirname(repo_path($binary)));
    local $ENV{TMPDIR} = $compiler_tmp;
    my @compiler = shellwords($Config::Config{cc} // 'cc');
    system @compiler, repo_path($program_source), '-o', repo_path($binary);
    die "cannot compile native fake OSVVM provider\n" unless $? == 0;
    chmod 0700, repo_path($binary)
        or die "cannot chmod fake OSVVM provider: $!";
    if ($^O eq 'darwin') {
        system '/usr/bin/codesign', '--force', '--sign', '-',
            repo_path($binary);
        die "cannot ad-hoc sign fake OSVVM provider\n" unless $? == 0;
    }
    write_raw(repo_path($provider_source), "entity provider is end entity;\n");
    write_raw(repo_path($generated_source), "entity generated is end entity;\n");

    my $stage = '.artifacts/tmp/vial-osvvm-ghdl-qualification/'
        . sha256_hex("fsmgen-osvvm-ghdl-test-$label-$$");
    push @owned_stage, $stage;
    my $libraries = "$stage/libraries";
    my $settings_rel = "$stage/OsvvmScriptSettingsPkg_generated.vhd";
    my $settings_content = "package generated_settings is end package;\n";
    my @source_relpath = ($provider_source, $generated_source);
    my $source_set = [map {{
        relpath => $_,
        bytes => 0 + (-s repo_path($_)),
        sha256 => file_sha256(repo_path($_)),
    }} @source_relpath];
    my $authority = FSM::VIAL::Backend::VHDLPortableTraceValidator
        ->checked_reference_authority;
    my $commands = {
        schema => 'fsmgen.vial_ghdl_lifecycle_osvvm_command_plan.v2',
        schema_version => 2,
        version => [$binary, '--version'],
        provider_analyze => [
            [$binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
                '--work=osvvm', "--workdir=$libraries/osvvm/v08",
                "-P$libraries", $provider_source],
            [$binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
                '--work=osvvm', "--workdir=$libraries/osvvm/v08",
                "-P$libraries", $settings_rel],
        ],
        analyze_generated => [
            $binary, '-a', '--std=08', '-Wno-library', '-Wno-hide',
            '--work=fsmgen_vial', "--workdir=$libraries/fsmgen_vial/v08",
            "-P$libraries", $generated_source,
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
            bytes => length($settings_content),
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
        resource_controls => {
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
        },
    };
    my $source_identity =
        'source/' . sha256_hex($json->encode($source_set));
    return {
        repo_root => $repo_root,
        provider => {
            root => $provider_root,
            archive => $archive,
            archive_bytes => 0 + (-s repo_path($archive)),
            archive_sha256 => file_sha256(repo_path($archive)),
            binary => $binary,
            binary_sha256 => file_sha256(repo_path($binary)),
            version_output => 'fake OSVVM GHDL 1',
        },
        source_set => $source_set,
        source_identity => $source_identity,
        emission_identity =>
            'emission/' . sha256_hex("emission-$label-$$"),
        commands => $commands,
        validation => {
            expected_record_counts => {
                header => 1, scenario_start => 2, events => 2, samples => 35,
                expectations => 2, scoreboards => 2, coverage => 28, faults => 2,
                scenario_end => 2, footer => 1,
            },
            %$authority,
            run_repetitions => 2,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'osvvm_qualification',
            staging_identity => $stage,
            containment => 'lifecycle_process_group',
        },
    };
}

sub lifecycle_begin {
    return FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::_ghdl_lifecycle_begin_for_test(
        $_[0],
    );
}

sub lifecycle_advance {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::_ghdl_lifecycle_advance_for_test({
            %$request, handle => clone($handle),
        });
}

sub lifecycle_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLOSVVMGHDLQualification::_ghdl_lifecycle_abort_for_test({
            %$request, handle => clone($handle),
        });
}

sub report_entries {
    my ($request) = @_;
    my $root = repo_path(
        $request->{storage_context}{staging_identity} . '/provider_reports',
    );
    opendir my $dh, $root or die "cannot inspect $root: $!";
    my @entry = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return \@entry;
}

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

sub write_raw {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub append_raw {
    my ($path, $content) = @_;
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $content or die "cannot append content to $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot hash $path: $!";
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh or die "cannot close $path: $!";
    return $sha->hexdigest;
}

sub clone {
    return JSON::PP->new->decode($json->encode($_[0]));
}

package FSM::VIAL::Backend::VHDLOSVVMGHDLQualification;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_advance_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->advance_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

package main;
