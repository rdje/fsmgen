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
use POSIX qw(WNOHANG);
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $independent_relative =
    'scripts/verify_vial_regression_promotion_budget_qualification.pl';
my $production_relative =
    'scripts/run_vial_regression_promotion_budget_qualification.pl';
my $publication_relative = join '/', qw(
    .artifacts qualification vial-scale v2
    regression-promotion-budget-qualification-v1 current
);
my $corpus_relative = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-corpus-v1
);
my @residue_relatives = (
    join('/', qw(
        .artifacts tmp vial-scale
        regression-promotion-budget-qualification-publication v1
    )),
    join('/', qw(
        .artifacts tmp vial-scale
        regression-promotion-profile-publication v1
    )),
    join('/', qw(
        .artifacts tmp vial-scale
        regression-promotion-corpus-publication v1
    )),
);
my $independent_script = repo_path($root, $independent_relative);
my $production_script = repo_path($root, $production_relative);
my $publication = repo_path($root, $publication_relative);
my $corpus = repo_path($root, $corpus_relative);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $publication_before = tree_census($publication);
my $corpus_before = tree_census($corpus);
my ($independent, $production);

subtest 'final evidence commands are closed repository executables' => sub {
    for my $entry (
        [$independent_script, 'independent verifier'],
        [$production_script, 'production qualification CLI'],
    ) {
        ok(-f($entry->[0]) && !-l($entry->[0]),
            "$entry->[1] is a regular repository path");
        ok(-x($entry->[0]), "$entry->[1] is executable");
    }
    my $independent_source = read_raw($independent_script);
    unlike($independent_source, qr/^\s*(?:use|require)\s+FSM::/m,
        'independent verifier imports no production module');
    unlike($independent_source, qr/^\s*use\s+lib\b/m,
        'independent verifier exposes no production library path');
    for my $relative (@residue_relatives) {
        path_absent(repo_path($root, $relative),
            "pre-run residue is absent at $relative");
    }
};

subtest 'independent and production reconstruction agree exactly' => sub {
    my $independent_run = run_command($^X, $independent_script);
    is($independent_run->{status}, 0, 'independent verification succeeds')
        or diag($independent_run->{stderr});
    is($independent_run->{signal}, 0,
        'independent verification exits without a signal');
    is($independent_run->{stderr}, '',
        'independent verification is diagnostic-free');
    cmp_ok(bytes::length($independent_run->{stdout}), '<=', 262_144,
        'independent result stays inside its complete output ceiling');
    $independent = decode_canonical(
        $independent_run->{stdout}, 'independent result',
    );

    my $production_run = run_command(
        $^X, $production_script, '--validate',
    );
    is($production_run->{status}, 0, 'production validation succeeds')
        or diag($production_run->{stderr});
    is($production_run->{signal}, 0,
        'production validation exits without a signal');
    is($production_run->{stderr}, '',
        'production validation is diagnostic-free');
    is(bytes::length($production_run->{stdout}), 793_084,
        'production validation retains the exact complete output length');
    is(sha256_hex($production_run->{stdout}),
        '19ac96edf6ea6aafad80672084bf3f528a4944a6cf5df6264d524bc9e93f9d64',
        'production validation retains the exact complete output digest');
    $production = decode_canonical(
        $production_run->{stdout}, 'production result',
    );
    is(waitpid(-1, WNOHANG), -1,
        'both completed commands leave no child process to reap');

    my $report = $production->{report};
    my $manifest = $production->{manifest};
    my $artifact = $production->{artifact};
    my $qualification = $report->{qualification};
    is($independent->{active_relative_path},
        $artifact->{publication_relative_path},
        'both paths name the same fixed current coordinate');
    is($independent->{publication_report_identity},
        $report->{publication_report_identity},
        'both derive the same publication-report identity');
    is($independent->{publication_identity},
        $manifest->{publication_identity},
        'both derive the same publication identity');
    is($independent->{qualification_identity},
        $qualification->{qualification_identity},
        'both derive the same qualification identity');
    is($independent->{publisher_revision}, $report->{publisher_revision},
        'both bind the same publisher revision');
    is($independent->{file_set_sha256}, $artifact->{file_set_sha256},
        'both derive the same length-delimited publication file set');
    is_deeply($independent->{formula}, $qualification->{formula},
        'both derive the same Decision-0056 formula');
    for my $key (qw(
        profile_count validation_records raw_measurement_records
        controller_invocations sample_exclusions qualified_profiles
    )) {
        is($independent->{summary}{$key}, $qualification->{summary}{$key},
            "both derive the same $key");
    }

    is($independent->{source_verification}{corpus_identity},
        $qualification->{source_evidence}{corpus_identity},
        'independent source and production qualification bind one corpus');
    is($independent->{source_verification}{publication_identity},
        $qualification->{source_evidence}{publication_identity},
        'independent source and production qualification bind one source publication');
    is($independent->{source_verification}{file_set_sha256},
        $qualification->{source_evidence}{file_set_sha256},
        'independent source and production qualification bind one source file set');
    is($independent->{source_verification}{capture_revision},
        $qualification->{source_evidence}{capture_revision},
        'independent source and production qualification bind one capture revision');
    is($independent->{performance_applicability_identity},
        $qualification->{performance_applicability}{applicability_identity},
        'both derive the same performance-applicability contract');
    is_deeply($report->{publication_contract},
        $manifest->{publication_contract},
        'report and manifest bind one immutable publication contract');
    is($report->{publication_contract}{enforcement_state}, 'not_activated',
        'validated publication has not activated performance enforcement');
    ok(!$report->{publication_contract}{replacement_policy}{overwrite},
        'validated publication remains non-overwritable');

    is(scalar(@{$independent->{profiles}}),
        scalar(@{$qualification->{profiles}}),
        'both reconstruct the same ordered profile count');
    for my $index (0 .. $#{$independent->{profiles}}) {
        assert_profile_agreement(
            $index + 1,
            $independent->{profiles}[$index],
            $qualification->{profiles}[$index],
        );
    }

    my %independent_files = map {
        $_->{relative_path} => $_
    } @{$independent->{files}};
    for my $kind (qw(report manifest)) {
        my $filename = $kind eq 'report'
            ? 'regression-promotion-budget-qualification.json'
            : 'qualification-manifest.json';
        my $production_file = $artifact->{"${kind}_artifact"};
        is($independent_files{$filename}{sha256},
            $production_file->{sha256},
            "both authenticate the same $kind bytes");
        is($independent_files{$filename}{bytes},
            $production_file->{bytes},
            "both authenticate the same $kind byte count");
    }
};

subtest 'real artifacts and all owned residue remain exact' => sub {
    is_deeply(tree_census($publication), $publication_before,
        'real qualification retains its exact inode-aware census');
    is_deeply(tree_census($corpus), $corpus_before,
        'real source corpus retains its exact inode-aware census');
    for my $relative (@residue_relatives) {
        path_absent(repo_path($root, $relative),
            "post-run residue is absent at $relative");
    }
    my @hostile_fixtures = glob(repo_path(
        $root,
        '.artifacts/tmp/vial-regression-promotion-budget-qualification-mutations-*',
    ));
    is_deeply(\@hostile_fixtures, [],
        'no copied hostile fixture residue remains');
    is(waitpid(-1, WNOHANG), -1,
        'closeout leaves no child process to reap');
};

done_testing;

sub assert_profile_agreement {
    my ($ordinal, $independent_profile, $production_profile) = @_;
    for my $key (qw(
        ordinal selection_key profile_qualification_identity
        source_report_identity workload_identity evidence_revision
        correctness_projection_identity performance_applicability_identity
        validation_identity
    )) {
        is($independent_profile->{$key}, $production_profile->{$key},
            "profile $ordinal agrees on $key");
    }
    is($independent_profile->{environment_identity},
        $production_profile->{environment_identity}{environment_identity},
        "profile $ordinal agrees on environment identity");
    for my $key (qw(
        raw_measurement_identities accepted_run_totals aggregate_statistics
        qualified_budget provider_status
    )) {
        is_deeply($independent_profile->{$key}, $production_profile->{$key},
            "profile $ordinal agrees on $key");
    }
}

sub run_command {
    my (@command) = @_;
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error, @command);
    close $input or die "cannot close closeout command input\n";
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output or die "cannot close closeout command output\n";
    close $error or die "cannot close closeout command diagnostics\n";
    waitpid($pid, 0) == $pid or die "cannot wait for closeout command\n";
    return {
        status => $? == -1 ? -1 : $? >> 8,
        signal => $? & 127,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub decode_canonical {
    my ($bytes, $label) = @_;
    my $decoded = eval { $json->decode($bytes) };
    is($@, '', "$label is JSON");
    is($bytes, $json->encode($decoded) . "\n",
        "$label is canonical newline JSON");
    return $decoded;
}

sub tree_census {
    my ($base) = @_;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat closeout census path\n" unless @stat;
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

sub path_absent {
    my ($path, $label) = @_;
    ok(!-e($path) && !-l($path), $label);
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read closeout path\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "cannot close closeout path\n";
    return $bytes;
}

sub repo_path {
    my ($base, @parts) = @_;
    return File::Spec->catfile($base, map { split m{/} } @parts);
}
