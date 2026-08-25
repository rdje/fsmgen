#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $evidence_rel =
    'vial/qualification/sv_portable_verilator/'
    . 'macos-premain-qualification-2026-08-24.json';
my $evidence = decode(repo_path($evidence_rel));

is_deeply(
    [sort keys %{$evidence}],
    [sort qw(
        schema schema_version work_unit producer host
        historical_failure_evidence controlled_observations
        public_integration_control locality_recovery conclusion boundaries
        claim_verification
    )],
    'macOS pre-main evidence has one closed top-level schema',
);
is(
    $evidence->{schema},
    'fsmgen.vial_macos_premain_qualification_evidence.v1',
    'macOS pre-main evidence schema is exact',
);
is(
    $evidence->{producer}{sha256},
    sha256_hex(slurp(repo_path($evidence->{producer}{path}))),
    'evidence names the exact guarded qualification watcher',
);
is(
    $evidence->{producer}{bytes},
    -s repo_path($evidence->{producer}{path}),
    'evidence names the exact guarded watcher byte count',
);

my $historical = $evidence->{historical_failure_evidence};
is($historical->{fresh_generated_executables}, 3, 'three historical stalls remain explicit');
is($historical->{output_bytes}, 0, 'historical stalls observed zero output');
is($historical->{deadline_seconds}, 30, 'historical stalls retain the fixed run wall');
is(
    $historical->{sample}{main_thread_samples},
    $historical->{sample}{dyld_start_samples},
    'historical sample localizes every main-thread sample to dyld start',
);
ok(
    !$historical->{sample}{binary_image_map_present},
    'historical sample remains pre-image-map evidence',
);

my @observation = @{$evidence->{controlled_observations}};
is(scalar(@observation), 4, 'four bounded controlled observations are retained');
my ($concurrent) = grep {
    $_->{label} eq 'concurrent-link-policy-active'
} @observation;
my @quiet = grep { $_->{condition} eq 'quiet_no_compiler' } @observation;
my ($recovery) = grep {
    $_->{label} eq 'ci-recovery-concurrent-link-timeout'
} @observation;
ok($concurrent->{compiler_process_count} > 0, 'concurrent observation names active compiler orchestration');
ok(
    $concurrent->{syspolicyd_cpu_percent_before} >= 49,
    'concurrent observation retains policy-daemon activity',
);
is(scalar(@quiet), 2, 'two independent quiet observations are retained');
is($_->{compiler_process_count}, 0, 'quiet observation has zero compiler process') for @quiet;
my @passing = grep { $_->{label} ne 'ci-recovery-concurrent-link-timeout' } @observation;
ok($_->{primary}{ok}, 'each earlier controlled primary success remains explicit') for @passing;
ok(!$_->{primary}{timed_out}, 'each earlier controlled success remains non-timeout') for @passing;
ok($_->{primary}{cleanup_removed}, 'every controlled primary run cleans exactly') for @observation;

ok(!$recovery->{primary}{ok}, 'fresh failed primary remains failed');
ok($recovery->{primary}{timed_out}, 'fresh failed primary retains its timeout');
is($recovery->{primary}{output_bytes}, 0, 'fresh failed primary produced zero output');
is($recovery->{primary}{execution_ns}, 30058109000, 'fresh failed primary retains its exact run wall');
is($recovery->{sample}{main_thread_samples}, 895, 'fresh sample retains its main-thread count');
is(
    $recovery->{sample}{dyld_start_samples},
    $recovery->{sample}{main_thread_samples},
    'fresh sample places every main-thread frame at dyld start',
);
ok(!$recovery->{sample}{binary_image_map_present}, 'fresh sample precedes the image map');
ok($recovery->{byte_identical_different_path_control}{ok}, 'fresh byte-identical control executes');
ok($recovery->{fresh_minimal_cpp_control}{ok}, 'fresh minimal C++ control executes');
ok($recovery->{platform_true_control_ok}, 'fresh platform control executes');

for my $observation (grep { exists $_->{generated_binary} } @observation) {
    is($observation->{generated_binary}{bytes}, 1847672, 'generated binary size is exact');
    is($observation->{generated_binary}{mode}, '0755', 'generated binary mode is exact');
    is($observation->{generated_binary}{codesign_verify_status}, 0, 'linker signature verifies');
    is(
        $observation->{byte_identical_different_path_control}{sha256},
        $observation->{generated_binary}{sha256},
        'different-path control is byte-identical to its primary',
    );
    ok($observation->{byte_identical_different_path_control}{ok}, 'different-path control executes');
    ok($observation->{fresh_minimal_cpp_control}{ok}, 'fresh minimal C++ control executes');
    ok($observation->{platform_true_control_ok}, 'platform control executes');
}

my ($logged_quiet) = grep {
    $_->{label} eq 'quiet-no-compiler-log-correlated'
} @observation;
is(
    $logged_quiet->{exact_syspolicyd_log_window}{all_lines}, 0,
    'exact quiet-primary window retains zero syspolicyd log events',
);
is(
    $evidence->{public_integration_control}{result}, 'PASS',
    'full repeated public integration control passes',
);
ok(
    $evidence->{public_integration_control}{repeated_direct_drive_ok},
    'quiet public control includes the formerly failing repeated direct drive',
);

my $integration_source = slurp(repo_path(
    $evidence->{public_integration_control}{path},
));
my $guard_at = index(
    $integration_source, 'FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION',
);
my $discovery_at = index(
    $integration_source, "capture_command('verilator', '--version')",
);
ok($guard_at >= 0, 'Darwin public integration requires an explicit guard');
ok(
    $discovery_at >= 0 && $guard_at < $discovery_at,
    'Darwin guard precedes tool discovery and generated execution',
);

my $producer_source = slurp(repo_path($evidence->{producer}{path}));
my $sample_invocations = () = $producer_source =~ m{/usr/bin/sample}g;
is($sample_invocations, 1, 'guarded producer has one stack-sampler invocation');
ok(
    index($producer_source, "'-file', \$sample_abs") >= 0,
    'guarded producer directs sample to its repository-derived sidecar',
);
ok(
    index($producer_source, 'write_exclusive($sample_abs') < 0,
    'guarded producer reads the tool-owned sidecar instead of republishing captured output',
);

my $locality = $evidence->{locality_recovery};
is($locality->{off_volume_residue}{bytes}, 992, 'recovered residue byte count is exact');
is(
    $locality->{off_volume_residue}{sha256},
    '0e96ecabc3d27e171ada695c2e73492c9cabbf28d06a45c1f7e6fc2a3662447e',
    'recovered residue identity is exact',
);
ok($locality->{copy_verify_use_delete}{copy_verified}, 'same-volume copy was verified');
ok($locality->{copy_verify_use_delete}{exact_source_deleted}, 'exact off-volume source was deleted');
is($locality->{copy_verify_use_delete}{residue_census}, 0, 'off-volume residue census is empty');
is($locality->{repair}, 'sample -file repository-derived sidecar', 'locality repair is exact');

is(
    $evidence->{conclusion}{selected_project_response},
    'explicit Darwin runtime qualification plus default bounded evidence',
    'selected response preserves qualification without a backend workaround',
);
is($evidence->{conclusion}{backend_change}, 'none', 'backend remains unchanged');
is($evidence->{conclusion}{public_contract_change}, 'none', 'public contract remains unchanged');
is($evidence->{boundaries}{retry_count}, 0, 'evidence admits no retry');
is($evidence->{boundaries}{run_deadline_seconds}, 30, 'evidence retains the run wall');
ok(!$evidence->{boundaries}{signing_changed}, 'evidence changes no signing');
ok(!$evidence->{boundaries}{security_changed}, 'evidence changes no security setting');
ok(!$evidence->{boundaries}{unrelated_process_changed}, 'evidence changes no unrelated process');
ok(!$evidence->{boundaries}{failed_result_promoted}, 'evidence promotes no failed result');

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $content;
}

sub decode {
    my ($path) = @_;
    return JSON::PP->new->decode(slurp($path));
}
