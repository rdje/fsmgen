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
        public_integration_control conclusion boundaries claim_verification
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
is(scalar(@observation), 3, 'three bounded controlled observations are retained');
my ($concurrent) = grep { $_->{condition} eq 'concurrent_link' } @observation;
my @quiet = grep { $_->{condition} eq 'quiet_no_compiler' } @observation;
ok($concurrent->{compiler_process_count} > 0, 'concurrent observation names active compiler orchestration');
ok(
    $concurrent->{syspolicyd_cpu_percent_before} >= 49,
    'concurrent observation retains policy-daemon activity',
);
is(scalar(@quiet), 2, 'two independent quiet observations are retained');
is($_->{compiler_process_count}, 0, 'quiet observation has zero compiler process') for @quiet;
ok($_->{primary}{ok}, 'every controlled primary run succeeds') for @observation;
ok(!$_->{primary}{timed_out}, 'no controlled primary run is relabeled timeout') for @observation;
ok($_->{primary}{cleanup_removed}, 'every controlled primary run cleans exactly') for @observation;

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

is(
    $evidence->{conclusion}{selected_project_response},
    'guarded host qualification watcher',
    'selected response is diagnostic qualification, not a backend workaround',
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
