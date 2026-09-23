#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Find qw(find);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $script_relative =
    'scripts/verify_vial_regression_promotion_budget_qualification.pl';
my $script = repo_path($root, $script_relative);
my $publication = repo_path(
    $root,
    '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-budget-qualification-v1/current',
);
my $corpus = repo_path(
    $root,
    '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-corpus-v1',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $ignored_inputs_present = -d $publication && !-l $publication
    && -d $corpus && !-l $corpus;

subtest 'verifier is production-independent and read-only' => sub {
    plan skip_all => 'ignored budget qualification inputs are absent on a fresh checkout'
        unless $ignored_inputs_present;
    ok(-f($script) && !-l($script), 'tracked verifier exists');
    ok(-x($script), 'tracked verifier is executable');
    my $source = read_raw($script);
    unlike(
        $source,
        qr/^\s*(?:use|require)\s+FSM::/m,
        'verifier imports no FSMGEN production module',
    );
    unlike(
        $source,
        qr/^\s*use\s+lib\b/m,
        'verifier does not expose the production library path',
    );

    my $publication_before = tree_census($publication);
    my $corpus_before = tree_census($corpus);
    my $run = run_verifier();
    is($run->{status}, 0, 'real current qualification verifies')
        or diag($run->{stderr});
    is($run->{stderr}, '', 'successful verification is diagnostic-free');
    is_deeply(tree_census($publication), $publication_before,
        'verification leaves the qualification byte-identical');
    is_deeply(tree_census($corpus), $corpus_before,
        'verification leaves the source corpus byte-identical');
};

subtest 'bounded canonical result reports exact independent reconstruction' => sub {
    plan skip_all => 'ignored budget qualification inputs are absent on a fresh checkout'
        unless $ignored_inputs_present;
    my $run = run_verifier();
    is($run->{status}, 0, 'verifier succeeds for result inspection')
        or diag($run->{stderr});
    cmp_ok(bytes::length($run->{stdout}), '<=', 262_144,
        'result stays within its closed output ceiling');
    my $decoded = eval { $json->decode($run->{stdout}) };
    is($@, '', 'result is JSON');
    is($run->{stdout}, $json->encode($decoded) . "\n",
        'result is canonical newline JSON');
    is(
        $decoded->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_verification.v1',
        'result exposes the independent verification contract',
    );
    is($decoded->{schema_version}, 1, 'verification schema version is exact');
    is(
        $decoded->{publication_report_identity},
        'regression-promotion-budget-qualification-report/'
            . '0da2324912a8ffcaa0c167e75a5ecac87911eb3bc44f6d8c2b128d07e869622c',
        'publication report identity is independently reproduced',
    );
    is(
        $decoded->{publication_identity},
        'regression-promotion-budget-qualification-publication/'
            . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f',
        'manifest publication identity is independently reproduced',
    );
    is(
        $decoded->{qualification_identity},
        'regression-promotion-qualification/'
            . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97',
        'embedded qualification identity is independently reproduced',
    );
    is(
        $decoded->{file_set_sha256},
        '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095',
        'two-file publication identity is exact',
    );
    is_deeply(
        $decoded->{summary},
        {
            publication_file_count => 2,
            publication_total_bytes => 792_158,
            profile_count => 11,
            validation_records => 11,
            raw_measurement_records => 33,
            controller_invocations => 44,
            sample_exclusions => 0,
            qualified_profiles => 11,
            reconstructed_profiles => 11,
            reconstructed_run_totals => 33,
            reconstructed_correctness_projections => 11,
            reconstructed_environment_identities => 11,
            reconstructed_applicability_identities => 11,
            reconstructed_budgets => 33,
        },
        'publication, record, projection, applicability, and budget census is exact',
    );
    is($decoded->{formula}{authority}, 'decision-0056',
        'the independently applied formula names Decision 0056');
    is(scalar(@{$decoded->{profiles}}), 11,
        'result reports all ordered qualification profiles');
    is(scalar(@{$decoded->{files}}), 2,
        'result reports the exact two-file publication');
    is(
        $decoded->{source_verification}{file_set_sha256},
        'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f',
        'result binds the independently authenticated source file set',
    );
    is(
        $decoded->{performance_applicability_identity},
        'regression-promotion-performance-applicability/'
            . 'b5976719c47be42095c2bf90e93c2f0bd5e68fff93bb7cd07adbf1172dba8018',
        'performance applicability contract identity is independently reproduced',
    );
};

subtest 'closed invocation rejects caller input without a result' => sub {
    my $run = run_verifier('foreign');
    isnt($run->{status}, 0, 'caller argument rejects');
    like(
        $run->{stderr},
        qr/^usage: scripts\/verify_vial_regression_promotion_budget_qualification[.]pl/m,
        'diagnostic publishes the closed invocation',
    );
    is($run->{stdout}, '', 'rejection emits no result');
    cmp_ok(bytes::length($run->{stderr}), '<=', 4_096,
        'rejection remains inside the diagnostic ceiling');
};

done_testing;

sub run_verifier {
    my (@arguments) = @_;
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error,
        $^X, $script, @arguments);
    close $input;
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output;
    close $error;
    waitpid($pid, 0);
    return {
        status => $? == -1 ? -1 : $? >> 8,
        signal => $? & 127,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub tree_census {
    my ($base) = @_;
    die "ignored budget qualification input is absent\n" unless -d $base;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat verifier test path\n" unless @stat;
            my $relative = File::Spec->abs2rel($path, $base);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            my $entry = {
                relative_path => $relative,
                device => $stat[0],
                inode => $stat[1],
                mode => $stat[2],
                links => $stat[3],
                owner => $stat[4],
                bytes => $stat[7],
                type => -l _ ? 'symlink'
                    : -d _ ? 'directory'
                    : -f _ ? 'file' : 'other',
            };
            $entry->{sha256} = sha256_hex(read_raw($path)) if -f _;
            push @entries, $entry;
        },
    }, $base);
    return [sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @entries];
}

sub repo_path {
    my ($base, @parts) = @_;
    return File::Spec->catfile($base, map { split m{/} } @parts);
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read verifier test path\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "cannot close verifier test path\n";
    return $bytes;
}
