#!/usr/bin/env perl

use strict;
use warnings;

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
    'scripts/verify_vial_regression_promotion_current_corpus.pl';
my $script = File::Spec->catfile($root, split m{/}, $script_relative);
my $corpus = File::Spec->catdir(
    $root, split m{/},
    '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-corpus-v1',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'verifier is producer-independent and read-only' => sub {
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

    my $before = corpus_census($corpus);
    my $result = run_verifier();
    is($result->{exit}, 0, 'real sealed corpus verifies')
        or diag($result->{stderr});
    is($result->{stderr}, '', 'successful verification is diagnostic-free');
    is_deeply(
        corpus_census($corpus), $before,
        'verification leaves every corpus path and byte identity unchanged',
    );
};

subtest 'bounded canonical result reports the exact independent census' => sub {
    my $result = run_verifier();
    is($result->{exit}, 0, 'verifier succeeds for result inspection')
        or diag($result->{stderr});
    cmp_ok(length($result->{stdout}), '<=', 65_536,
        'result stays within its closed output ceiling');
    my $decoded = eval { $json->decode($result->{stdout}) };
    is($@, '', 'result is JSON');
    is(
        $result->{stdout}, $json->encode($decoded) . "\n",
        'result is canonical newline JSON',
    );
    is(
        $decoded->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_current_corpus_verification.v1',
        'result exposes the independent verification contract',
    );
    is($decoded->{schema_version}, 1, 'verification schema version is exact');
    is(
        $decoded->{corpus_identity},
        'regression-promotion-corpus/'
            . 'ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505',
        'corpus identity is independently reproduced',
    );
    is(
        $decoded->{publication_identity},
        'regression-promotion-corpus-publication/'
            . '865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e',
        'publication identity is independently reproduced',
    );
    is(
        $decoded->{inventory_sha256},
        '94c11e5c81843f412cb8d1af23b7699dbb15b1af19077c1903cab91d8eddbb57',
        'complete thirteen-file inventory identity is exact',
    );
    is_deeply(
        $decoded->{summary},
        {
            profile_count => 11,
            file_count => 13,
            total_bytes => 6_220_126,
            report_bytes => 23_288,
            manifest_bytes => 1_280,
            validation_records => 11,
            raw_measurement_records => 33,
            controller_invocations => 44,
            sample_exclusions => 0,
        },
        'file, byte, profile, record, and exclusion census is exact',
    );
    is(scalar(@{$decoded->{files}}), 13,
        'result inventories all thirteen files');
    is(scalar(@{$decoded->{providers}}), 11,
        'result inventories one provider status per ordered profile');
    my %provider_kinds;
    $provider_kinds{$_->{kind}}++ for @{$decoded->{providers}};
    is_deeply(
        \%provider_kinds,
        {
            not_applicable => 7,
            repository_materialization => 1,
            exact_tool_profile => 3,
        },
        'provider census distinguishes foundation, materialized, and exact routes',
    );
    is(
        $decoded->{common_identity}{git_revision},
        '155aa22ea3099642eb6b7f5de81ea03633e72bcb',
        'common capture revision is exact',
    );
    ok($decoded->{common_identity}{resource_guard}{active},
        'common identity retains the active repository RAM guard');
};

subtest 'closed invocation rejects caller input without a result' => sub {
    my $result = run_verifier('foreign');
    isnt($result->{exit}, 0, 'caller argument rejects');
    like(
        $result->{stderr},
        qr/^usage: scripts\/verify_vial_regression_promotion_current_corpus[.]pl/m,
        'diagnostic publishes the closed invocation',
    );
    is($result->{stdout}, '', 'rejection emits no result');
};

done_testing();

sub corpus_census {
    my ($base) = @_;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat current corpus test path\n" unless @stat;
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
                type => -l _ ? 'symlink' : -d _ ? 'directory' : -f _ ? 'file' : 'other',
            };
            if (-f _) {
                $entry->{sha256} = sha256_hex(read_raw($path));
            }
            push @entries, $entry;
        },
    }, $base);
    @entries = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @entries;
    return \@entries;
}

sub run_verifier {
    my (@arguments) = @_;
    my ($input, $output);
    my $error = gensym;
    my $pid = open3($input, $output, $error, $^X, $script, @arguments);
    close $input or die "cannot close verifier input\n";
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output or die "cannot close verifier output\n";
    close $error or die "cannot close verifier diagnostics\n";
    waitpid($pid, 0) == $pid or die "cannot wait for verifier\n";
    return {
        exit => $? >> 8,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read test path\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close test path\n";
    return $bytes;
}
