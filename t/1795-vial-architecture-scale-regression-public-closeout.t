#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fsmgen = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $ci = File::Spec->catfile($repo_root, 'bin', 'ci-regression');
my $readme = slurp(File::Spec->catfile($repo_root, 'README.md'));
my $book_path = File::Spec->catfile(
    $repo_root,
    qw(docs book src 16df-vial-architecture-scale-cap-closeout.md),
);
my $book = slurp($book_path);

my ($vial_status, $vial_stdout, $vial_stderr) = run_command(
    $^X, $fsmgen, qw(vial capabilities --json),
);
is($vial_status, 0, 'public VIAL capability command succeeds');
is($vial_stderr, '', 'public VIAL capability command is quiet on stderr');
my $vial_result = JSON::PP->new->decode($vial_stdout);
my $contract =
    $vial_result->{capability_evidence}{architecture_scale_regression};

my ($manifest_status, $manifest_stdout, $manifest_stderr) = run_command(
    $^X, $fsmgen, '--capability-manifest',
);
is($manifest_status, 0, 'complete capability-manifest command succeeds');
is($manifest_stderr, '', 'complete capability manifest is quiet on stderr');
my $manifest = JSON::PP->new->decode($manifest_stdout);

subtest 'public machine entrypoints agree exactly' => sub {
    is(ref($contract), 'HASH', 'VIAL JSON carries the regression contract');
    is(
        $contract->{capability},
        'vial.architecture_scale.regression_gate.v1',
        'the public capability identity is exact',
    );
    is_deeply(
        $manifest->{language_surface}{vial_tooling}
            {architecture_scale_regression},
        $contract,
        'complete manifest and VIAL JSON publish one contract',
    );
};

subtest 'human guide is an exact projection of public machine truth' => sub {
    like(
        $readme,
        qr{^\./bin/ci-regression vial-gate --dry-run --no-book$}m,
        'bounded README signpost exposes the dry-run command',
    );
    my @errors = guide_errors($book, $contract);
    is_deeply(\@errors, [], 'the complete guide matches public machine truth');
};

subtest 'documented dry-run is executable and side-effect free' => sub {
    my $latest_path = File::Spec->catfile(
        $repo_root,
        split(m{/}, $contract->{latest_result}{publication_relative_path}),
    );
    my $before = file_state($latest_path);
    my ($status, $stdout, $stderr) = run_command(
        $ci, qw(vial-gate --dry-run --no-book),
    );
    is($status, 0, 'documented dry-run succeeds');
    is($stderr, '', 'documented dry-run is quiet on stderr');

    my @steps = (
        'materialize_vial_regression_promotion_gate_evidence.pl    materialize',
        'verify_vial_regression_promotion_current_corpus.pl',
        'verify_vial_regression_promotion_budget_qualification.pl',
        'run_with_ram_guard.sh    --    scripts/run_vial_regression_promotion_gate.pl    --run',
        'materialize_vial_regression_promotion_gate_evidence.pl    cleanup',
    );
    my $cursor = -1;
    for my $step (@steps) {
        my $at = index($stdout, $step, $cursor + 1);
        ok($at > $cursor, "dry-run orders $step");
        $cursor = $at;
    }
    is_deeply(
        file_state($latest_path),
        $before,
        'dry-run does not create or mutate the latest observation',
    );
};

subtest 'human projection mutations fail closed' => sub {
    my @cases = (
        [
            'missing profile',
            sub {
                my ($text) = @_;
                my $row = profile_row($contract->{profiles}[0]);
                $text =~ s/\Q$row\E\n//
                    or die "missing-profile mutation did not match\n";
                return $text;
            },
        ],
        [
            'reordered profiles',
            sub {
                my ($text) = @_;
                my $first = profile_row($contract->{profiles}[0]);
                my $second = profile_row($contract->{profiles}[1]);
                my $pair = "$first\n$second";
                my $at = index($text, $pair);
                die "reorder mutation did not match\n" if $at < 0;
                substr($text, $at, length($pair), "$second\n$first");
                return $text;
            },
        ],
        [
            'mixed provider identity',
            sub {
                my ($text) = @_;
                $text =~ s/
                    (`portable_runtime\\\|runtime_stream_v1\\\|
                     gate_candidate_v1\\\|-\\\|sv_portable_verilator`\s*\|\s*)
                    `qualified_verilator_5_046`
                /$1`qualified_ghdl_6_0_0_llvm_jit`/x
                    or die "provider mutation did not match\n";
                return $text;
            },
        ],
        [
            'changed immutable budget',
            sub {
                my ($text) = @_;
                $text =~ s/429\.258 s/429.259 s/
                    or die "budget mutation did not match\n";
                return $text;
            },
        ],
        [
            'stale host envelope',
            sub {
                my ($text) = @_;
                $text =~ s/Darwin 25\.5\.0, arm64/Darwin 25.4.0, arm64/
                    or die "host mutation did not match\n";
                return $text;
            },
        ],
        [
            'capacity nonclaim inversion',
            sub {
                my ($text) = @_;
                $text =~ s/It does \*\*not\*\* claim/It does claim/
                    or die "nonclaim mutation did not match\n";
                return $text;
            },
        ],
    );

    for my $case (@cases) {
        my ($name, $mutate) = @{$case};
        my $mutated = $mutate->($book);
        ok(scalar(guide_errors($mutated, $contract)), "$name is rejected");
    }
};

done_testing;

sub guide_errors {
    my ($text, $expected) = @_;
    my @errors;
    my ($guide) = $text =~ /(### Run the bounded gate\n.*?)(?=\nRe-derive the authenticated transport)/s;
    return ('missing bounded-gate guide') unless defined $guide;

    my $commands = $guide;
    $commands =~ s/\\\n\s*/ /g;
    $commands =~ s/[ \t]+/ /g;
    for my $command (
        './bin/fsmgen vial capabilities --json',
        './bin/ci-regression vial-gate --dry-run --no-book',
        './bin/ci-regression vial-gate --no-book',
        './bin/ci-regression --no-book',
        'scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_gate.pl --validate-result',
        'perl scripts/verify_vial_regression_promotion_evidence_transport.pl',
    ) {
        push @errors, "missing command $command"
            if index($commands, $command) < 0;
    }

    my @rows;
    while ($guide =~ /^\| (\d+) \| `(.+?)` \| `([^`]+)` \| ([0-9.]+) s \| ([0-9.]+) s \| (\d+) MiB \|$/mg) {
        my ($ordinal, $selection, $provider, $wall, $cpu, $rss) =
            ($1, $2, $3, $4, $5, $6);
        $selection =~ s/\\\|/|/g;
        push @rows, [$ordinal, $selection, $provider, $wall, $cpu, $rss];
    }
    push @errors, 'profile row count differs'
        unless @rows == @{$expected->{profiles}};
    if (@rows == @{$expected->{profiles}}) {
        for my $index (0 .. $#rows) {
            my $profile = $expected->{profiles}[$index];
            my $provider =
                $profile->{provider_requirement}{provider_identity}
                // 'not_applicable';
            my @want = (
                $profile->{ordinal},
                $profile->{selection_key},
                $provider,
                sprintf('%.3f',
                    $profile->{qualified_budget}{wall_time_ns} / 1_000_000_000),
                sprintf('%.3f',
                    $profile->{qualified_budget}{cpu_time_ns} / 1_000_000_000),
                $profile->{qualified_budget}{peak_tree_rss_bytes} / 1_048_576,
            );
            push @errors, "profile row $profile->{ordinal} differs"
                unless join("\0", @{$rows[$index]}) eq join("\0", @want);
        }
    }

    my $host = $expected->{qualified_reference_environment}{host_profile};
    my $flat_guide = $guide;
    $flat_guide =~ s/\s+/ /g;
    for my $token (
        "$host->{os_name} $host->{os_version}, $host->{architecture}",
        "$host->{cpu_model}, $host->{logical_core_count} logical cores",
        commify($host->{physical_memory_bytes}) . ' bytes',
        uc($host->{filesystem_type}),
        $host->{measurement_implementation},
    ) {
        push @errors, "missing host token $token" if index($guide, $token) < 0;
    }
    my $guard = $expected->{qualified_reference_environment}{resource_guard};
    for my $token (
        "host maximum $guard->{host_max_percent}%",
        "one descendant maximum $guard->{single_descendant_max_mib} MiB",
        'sample interval ' . commify($guard->{sampler_interval_ns}) . ' ns',
    ) {
        push @errors, "missing guard token $token" if index($guide, $token) < 0;
    }

    for my $provider (@{$expected->{qualified_reference_environment}{provider_profiles}}) {
        for my $field (qw(provider_identity version revision tool_profile_identity)) {
            next unless defined $provider->{$field};
            push @errors, "missing provider $field $provider->{$field}"
                if index($guide, $provider->{$field}) < 0;
        }
    }

    for my $token (
        'producing 11 validation,',
        '33 raw, and 44 controller records with zero sample exclusions',
        'Correctness is always the first decision.',
        'deterministic drift',
        'Every wall, CPU, and RSS maximum must be at or below its budget',
        'performance is informational',
        '`unavailable`, never pass',
        'provider is present but its pinned identity drifts | fail',
        'There is no performance override',
        'recalibration requires a separately owned',
        $expected->{latest_result}{publication_relative_path},
        commify($expected->{latest_result}{maximum_bytes}) . ' bytes',
        'It does **not** claim',
        'architecture-scale capacity',
        '“big” or “really big”',
        'multi-unit or multi-domain capacity',
        'mixed-language capacity',
        'native UVM runtime',
        'full-language coverage',
        'synthesis capacity',
        'arbitrary-tool capacity',
        'support promotion',
        'general cross-backend parity',
        'performance enforcement on unmatched hosts',
        'pass when a provider is unavailable',
    ) {
        push @errors, "missing guide token $token"
            if index($flat_guide, $token) < 0;
    }

    return @errors;
}

sub run_command {
    my (@command) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, @command);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}

sub file_state {
    my ($path) = @_;
    return { exists => JSON::PP::false } unless -e $path;
    open my $handle, '<:raw', $path or die "cannot open $path: $!\n";
    local $/;
    my $bytes = <$handle>;
    close $handle or die "cannot close $path: $!\n";
    return {
        exists => JSON::PP::true,
        bytes => length($bytes),
        sha256 => sha256_hex($bytes),
    };
}

sub slurp {
    my ($path) = @_;
    open my $handle, '<:raw', $path or die "cannot open $path: $!\n";
    local $/;
    my $bytes = <$handle>;
    close $handle or die "cannot close $path: $!\n";
    return $bytes;
}

sub commify {
    my ($value) = @_;
    my $text = "$value";
    1 while $text =~ s/^(-?\d+)(\d{3})/$1,$2/;
    return $text;
}

sub profile_row {
    my ($profile) = @_;
    my $selection = $profile->{selection_key};
    $selection =~ s/\|/\\|/g;
    my $provider =
        $profile->{provider_requirement}{provider_identity}
        // 'not_applicable';
    return sprintf(
        '| %d | `%s` | `%s` | %.3f s | %.3f s | %d MiB |',
        $profile->{ordinal},
        $selection,
        $provider,
        $profile->{qualified_budget}{wall_time_ns} / 1_000_000_000,
        $profile->{qualified_budget}{cpu_time_ns} / 1_000_000_000,
        $profile->{qualified_budget}{peak_tree_rss_bytes} / 1_048_576,
    );
}
