#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_claim_verification.pl'
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

my $positive = make_fixture();
my ($positive_ok, $positive_output) = run_set_checker($positive);
subtest 'a finite two-shard registry set preserves one claim namespace' => sub {
    ok($positive_ok, 'complete bounded registry set passes')
        or diag($positive_output);
    like(
        $positive_output,
        qr/shards=2, records=3, published=3, fixtures=0/,
        'positive result reports aggregate shard and classification counts'
    );
};

if (!$positive_ok) {
    diag('remaining hostile controls require registry-set option admission');
    done_testing();
    exit 1;
}

subtest 'manifest bounds and aggregate bounds fail closed' => sub {
    my $hard_manifest = make_fixture();
    write_file(
        $hard_manifest,
        'registry/claim_registries.jsonl',
        'x' x 65_537,
    );
    expect_failure(
        $hard_manifest, qr/exceeds hard byte limit 65536/,
        'manifest pre-read hard-byte excess'
    );

    my $hard_shard = make_fixture();
    write_file(
        $hard_shard,
        'registry/claims-0002.jsonl',
        'x' x 65_537,
    );
    expect_failure(
        $hard_shard, qr/exceeds hard byte limit 65536/,
        'shard pre-read hard-byte excess'
    );

    my $manifest_bytes = make_fixture();
    mutate_manifest($manifest_bytes, sub { $_[0]{max_bytes} = 1; });
    expect_failure(
        $manifest_bytes, qr/registry set size .* exceeds max_bytes 1/,
        'manifest byte excess'
    );

    my $hard_shards = make_fixture();
    mutate_manifest($hard_shards, sub { $_[0]{max_shards} = 65; });
    expect_failure(
        $hard_shards, qr/max_shards must be an integer in 1\.\.64/,
        'data-supplied shard cap above the checker hard bound'
    );

    my $aggregate_records = make_fixture();
    mutate_manifest($aggregate_records, sub { $_[0]{max_total_records} = 2; });
    expect_failure(
        $aggregate_records, qr/aggregate record count 3 exceeds max_total_records 2/,
        'aggregate record excess'
    );

    my $aggregate_bytes = make_fixture();
    my $total_bytes = shard_bytes($aggregate_bytes);
    mutate_manifest(
        $aggregate_bytes,
        sub { $_[0]{max_total_bytes} = $total_bytes - 1; }
    );
    expect_failure(
        $aggregate_bytes,
        qr/aggregate shard size .* exceeds max_total_bytes/,
        'aggregate byte excess'
    );
};

subtest 'manifest, entry, and shard integers preserve JSON scalar type' => sub {
    my $manifest_string = make_fixture();
    mutate_manifest(
        $manifest_string,
        sub { $_[0]{max_total_records} = '16'; }
    );
    expect_failure(
        $manifest_string,
        qr/max_total_records must be an integer in 1\.\.8192/,
        'string-encoded manifest limit'
    );

    my $ordinal_string = make_fixture();
    mutate_manifest($ordinal_string, sub { $_[2]{ordinal} = '2'; });
    expect_failure(
        $ordinal_string,
        qr/line 3 ordinal must be an integer from 1 through 64/,
        'string-encoded shard ordinal'
    );

    my $shard_string = make_fixture();
    mutate_shard_metadata(
        $shard_string,
        'registry/claims-0002.jsonl',
        sub { $_[0]{max_records} = '8'; }
    );
    expect_failure(
        $shard_string,
        qr/claims-0002\.jsonl line 1 max_records must be an integer from 1 through 256/,
        'string-encoded per-shard limit'
    );
};

subtest 'manifest order and complete tracked shard census fail closed' => sub {
    my $reordered = make_fixture();
    mutate_manifest_lines($reordered, sub {
        my ($lines) = @_;
        @{$lines}[1, 2] = @{$lines}[2, 1];
    });
    expect_failure(
        $reordered, qr/line 2 ordinal must equal 1/,
        'reordered manifest entries'
    );

    my $missing_entry = make_fixture();
    mutate_manifest_lines($missing_entry, sub { pop @{$_[0]}; });
    expect_failure(
        $missing_entry, qr/tracked shard census does not match manifest entries/,
        'tracked shard omitted from manifest'
    );

    my $extra_tracked = make_fixture();
    write_shard($extra_tracked, 'registry/claims-0003.jsonl', []);
    git_ok($extra_tracked, 'add', '--', 'registry/claims-0003.jsonl');
    expect_failure(
        $extra_tracked, qr/tracked shard census does not match manifest entries/,
        'unmanifested tracked shard'
    );

    my $untracked = make_fixture();
    write_shard($untracked, 'registry/claims-0003.jsonl', []);
    append_manifest_entry(
        $untracked,
        { ordinal => 3, path => 'registry/claims-0003.jsonl',
          record_type => 'registry_shard', schema_version => 1 }
    );
    expect_failure(
        $untracked, qr/is not tracked: registry\/claims-0003\.jsonl/,
        'manifested but untracked shard'
    );
};

subtest 'shard path locality and regular-file identity fail closed' => sub {
    my $foreign = make_fixture();
    mutate_manifest($foreign, sub {
        $_[2]{path} = '/off-volume/claims-0002.jsonl';
    });
    expect_failure(
        $foreign, qr/is not a repository-relative local path/,
        'absolute shard path'
    );

    my $wrong_name = make_fixture();
    mutate_manifest($wrong_name, sub {
        $_[2]{path} = 'registry/other.jsonl';
    });
    expect_failure(
        $wrong_name, qr/ordinal 2 path must be registry\/claims-0002\.jsonl/,
        'ordinal/name disagreement'
    );

    my $symlink = make_fixture();
    my $second = fixture_path($symlink, 'registry/claims-0002.jsonl');
    unlink $second or die "cannot unlink $second: $!";
    symlink 'claims.jsonl', $second or die "cannot symlink $second: $!";
    expect_failure(
        $symlink, qr/is not a regular non-symlink file/,
        'symlinked shard'
    );
};

subtest 'global duplicate identity and local record order fail closed' => sub {
    my $duplicate = make_fixture();
    my @first = shard_claims($duplicate, 'registry/claims.jsonl');
    my @second = shard_claims($duplicate, 'registry/claims-0002.jsonl');
    push @second, $first[0];
    @second = sort { $a->{claim_id} cmp $b->{claim_id} } @second;
    write_shard($duplicate, 'registry/claims-0002.jsonl', \@second);
    expect_failure(
        $duplicate, qr/duplicates claim_id fixture-alpha-claim/,
        'cross-shard duplicate claim ID'
    );

    my $reordered = make_fixture();
    my @claims = reverse shard_claims(
        $reordered, 'registry/claims-0002.jsonl'
    );
    write_shard($reordered, 'registry/claims-0002.jsonl', \@claims);
    expect_failure(
        $reordered, qr/claim records must be sorted by claim_id/,
        'records reordered inside one shard'
    );
};

subtest 'the repository default consumes the exact finite registry set' => sub {
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker]
    );
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    ok($ok, 'repository default registry set passes') or diag($output);
    like(
        $output,
        qr/shards=2, records=28, published=27, fixtures=1/,
        'default reports the migrated two-shard global census'
    );
};

done_testing();

sub make_fixture {
    my $repo = create_project_tempdir(
        purpose => 'claim-verification-registry-set-tests'
    );
    write_file($repo, '.gitignore', ".artifacts/\n");
    write_file($repo, 'scripts/producer', "fixture producer\n");
    write_file($repo, 'scripts/oracle', "fixture oracle\n");
    write_file($repo, 'scripts/watcher', "fixture watcher\n");
    write_file(
        $repo,
        'docs/tasks/OWNER.md',
        "# Owner\n\n"
            . "- ID: `EXAMPLE.1`\n  Status: `active`\n"
            . "- ID: `EXAMPLE.2`\n  Status: `active`\n"
            . "- ID: `EXAMPLE.3`\n  Status: `active`\n",
    );

    my @claims = (
        claim_record('fixture-alpha-claim', 'docs/alpha.md', 'EXAMPLE.1'),
        claim_record('fixture-omega-claim', 'docs/omega.md', 'EXAMPLE.2'),
        claim_record('fixture-zeta-claim', 'docs/zeta.md', 'EXAMPLE.3'),
    );
    write_shard($repo, 'registry/claims.jsonl', [$claims[0]]);
    write_shard(
        $repo, 'registry/claims-0002.jsonl', [$claims[1], $claims[2]]
    );
    write_manifest($repo);
    write_source($repo, $_) for @claims;

    git_command_ok($repo, 'init', '-q');
    git_command_ok($repo, 'config', 'user.email', 'fixture@example.invalid');
    git_command_ok($repo, 'config', 'user.name', 'Fixture');
    git_command_ok($repo, 'add', '.');
    git_command_ok($repo, 'commit', '-q', '-m', 'fixture baseline');
    return $repo;
}

sub claim_record {
    my ($id, $source_path, $owner_task) = @_;
    return {
        classification => 'published_claim',
        claim => "The $id fixture has complete evidence.",
        claim_id => $id,
        durability => {
            evidence => "Run the tracked $id watcher after publication.",
            gap_owner => undef,
            gap_reason => undef,
            producer_paths => ['registry/claim_registries.jsonl'],
            status => 'available',
            watcher_paths => ['scripts/watcher'],
        },
        falsify => {
            evidence => "Challenge $id with the independent oracle.",
            gap_owner => undef,
            gap_reason => undef,
            oracle_paths => ['scripts/oracle'],
            status => 'available',
        },
        owner_path => 'docs/tasks/OWNER.md',
        owner_task => $owner_task,
        record_type => 'claim',
        rederive => {
            evidence => "Recompute $id with the tracked producer.",
            gap_owner => undef,
            gap_reason => undef,
            producer_paths => ['scripts/producer'],
            status => 'available',
        },
        schema_version => 1,
        source_path => $source_path,
    };
}

sub write_manifest {
    my ($repo) = @_;
    my @records = (
        {
            max_bytes => 8192,
            max_record_bytes => 512,
            max_shards => 8,
            max_total_bytes => 16384,
            max_total_records => 16,
            record_type => 'registry_set',
            schema_version => 1,
        },
        {
            ordinal => 1,
            path => 'registry/claims.jsonl',
            record_type => 'registry_shard',
            schema_version => 1,
        },
        {
            ordinal => 2,
            path => 'registry/claims-0002.jsonl',
            record_type => 'registry_shard',
            schema_version => 1,
        },
    );
    write_jsonl($repo, 'registry/claim_registries.jsonl', \@records);
}

sub write_shard {
    my ($repo, $relative, $claims) = @_;
    my @records = (
        {
            max_bytes => 8192,
            max_record_bytes => 4096,
            max_records => 8,
            record_type => 'registry',
            schema_version => 1,
        },
        @{$claims},
    );
    write_jsonl($repo, $relative, \@records);
}

sub write_jsonl {
    my ($repo, $relative, $records) = @_;
    write_file(
        $repo,
        $relative,
        join("\n", map { $json->encode($_) } @{$records}) . "\n",
    );
}

sub write_source {
    my ($repo, $claim) = @_;
    my $id = $claim->{claim_id};
    write_file(
        $repo,
        $claim->{source_path},
        "# Fixture claim\n\n"
            . "<!-- CLAIM-VERIFICATION:BEGIN $id -->\n"
            . "- Claim: $claim->{claim}\n"
            . "- Re-derive: $claim->{rederive}{evidence}\n"
            . "- Falsify: $claim->{falsify}{evidence}\n"
            . "- Durability: $claim->{durability}{evidence}\n"
            . "<!-- CLAIM-VERIFICATION:END $id -->\n",
    );
}

sub mutate_manifest {
    my ($repo, $mutation) = @_;
    my $path = fixture_path($repo, 'registry/claim_registries.jsonl');
    my @records = map { $json->decode($_) } split /\n/, slurp($path);
    $mutation->(@records);
    write_jsonl($repo, 'registry/claim_registries.jsonl', \@records);
}

sub mutate_manifest_lines {
    my ($repo, $mutation) = @_;
    my $path = fixture_path($repo, 'registry/claim_registries.jsonl');
    my @lines = split /\n/, slurp($path);
    $mutation->(\@lines);
    write_file(
        $repo, 'registry/claim_registries.jsonl', join("\n", @lines) . "\n"
    );
}

sub append_manifest_entry {
    my ($repo, $entry) = @_;
    mutate_manifest_lines($repo, sub {
        push @{$_[0]}, $json->encode($entry);
    });
}

sub shard_claims {
    my ($repo, $relative) = @_;
    my @records = map { $json->decode($_) }
        split /\n/, slurp(fixture_path($repo, $relative));
    shift @records;
    return @records;
}

sub mutate_shard_metadata {
    my ($repo, $relative, $mutation) = @_;
    my $path = fixture_path($repo, $relative);
    my @records = map { $json->decode($_) } split /\n/, slurp($path);
    $mutation->($records[0]);
    write_jsonl($repo, $relative, \@records);
}

sub shard_bytes {
    my ($repo) = @_;
    return (-s fixture_path($repo, 'registry/claims.jsonl'))
        + (-s fixture_path($repo, 'registry/claims-0002.jsonl'));
}

sub expect_failure {
    my ($repo, $expected, $label) = @_;
    my ($ok, $output) = run_set_checker($repo);
    ok(!$ok, "$label fails closed");
    like($output, $expected, "$label reports the separating reason");
}

sub run_set_checker {
    my ($repo) = @_;
    return run_checker(
        $repo, '--registry-set', 'registry/claim_registries.jsonl'
    );
}

sub run_checker {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $repo, @args]
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub fixture_path {
    my ($repo, $relative) = @_;
    return File::Spec->catfile($repo, split m{/}, $relative);
}

sub write_file {
    my ($repo, $relative, $contents) = @_;
    my $path = fixture_path($repo, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub git_ok {
    my ($repo, @args) = @_;
    git_command_ok($repo, @args);
}

sub git_command_ok {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $repo, @args]
    );
    if (!$ok) {
        die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []});
    }
}
